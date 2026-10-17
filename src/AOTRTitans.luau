-- Vortexion AOTR titan awareness: shared candidate pool.
--
-- One 10Hz scan resolves every titan into a cached entry (humanoid / HRP /
-- nape / type / boss flag); consumers read live fields without touching the
-- tree. Nape resolution tries several known layouts so version drift degrades
-- to a slower probe instead of a dead feature.
return function(app)
    local Workspace=app.Services.Workspace
    local Players=app.Services.Players
    local Titans={}

    local Config={
        MaxDistance=1200,
        ScanInterval=0.1,
        MaxTitans=32,
        IgnoreAfterFails=3,
        IgnoreDuration=5,
    }

    local state={
        entries={},           -- model -> entry
        lastScan=0,
        dirty=true,
        folder=nil,
        failCount={},         -- model -> fails (nape unreachable)
        ignoredUntil={},      -- model -> os.clock()
    }

    local BOSS_NAMES={
        Attack_Titan=true,Armored_Titan=true,Female_Titan=true,
        Colossal_Titan=true,Beast_Titan=true,Jaw_Titan=true,Cart_Titan=true,
    }

    --=========================================================================
    -- Path resolution: nape lives at Hitboxes.Hit.Nape in every known layout;
    -- the fallbacks cover renamed containers from older/newer builds.
    --=========================================================================
    local function resolveNape(titan)
        local hitboxes=titan:FindFirstChild("Hitboxes")
        if hitboxes then
            local hit=hitboxes:FindFirstChild("Hit")
            if hit then
                local nape=hit:FindFirstChild("Nape")
                if nape and nape:IsA("BasePart") then return nape end
                local any=hit:FindFirstChildWhichIsA("BasePart")
                if any then return any end
            end
            local direct=hitboxes:FindFirstChild("Nape")
            if direct and direct:IsA("BasePart") then return direct end
        end
        local loose=titan:FindFirstChild("Nape",true)
        if loose and loose:IsA("BasePart") then return loose end
        return nil
    end
    Titans.ResolveNape=resolveNape

    local function resolveRoot(titan)
        local root=titan:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then return root end
        root=titan:FindFirstChild("UpperTorso")
        if root and root:IsA("BasePart") then return root end
        root=titan:FindFirstChild("Torso")
        if root and root:IsA("BasePart") then return root end
        for _,child in ipairs(titan:GetChildren()) do
            if child:IsA("BasePart") then return child end
        end
        return nil
    end
    Titans.ResolveRoot=resolveRoot

    local function isIgnored(model)
        local until_=state.ignoredUntil[model]
        if not until_ then return false end
        if os.clock()>=until_ then
            state.ignoredUntil[model]=nil
            state.failCount[model]=nil
            return false
        end
        return true
    end
    Titans.IsIgnored=isIgnored

    function Titans:RegisterFail(model)
        local n=(state.failCount[model] or 0)+1
        state.failCount[model]=n
        if n>=Config.IgnoreAfterFails then
            state.ignoredUntil[model]=os.clock()+Config.IgnoreDuration
            app.Log("titan %s ignored %.0fs after %d fails",model.Name,Config.IgnoreDuration,n)
        end
    end

    function Titans:ClearFails(model)
        state.failCount[model]=nil
        state.ignoredUntil[model]=nil
    end

    --=========================================================================
    -- Scan: rebuild the entry set on a fixed cadence, refresh live fields
    -- every scan. Watches the Titans folder for spawn/despawn.
    --=========================================================================
    local stopped=false
    local addedConnection,removingConnection
    local function disconnectFolder()
        if addedConnection then addedConnection:Disconnect();addedConnection=nil end
        if removingConnection then removingConnection:Disconnect();removingConnection=nil end
    end

    local function ensureFolder()
        if stopped then return nil end
        local folder=Workspace:FindFirstChild("Titans")
        if folder~=state.folder then
            disconnectFolder()
            state.folder=folder
            state.dirty=true
            if folder then
                -- Replaceable handles belong to this module, not the app registry.
                addedConnection=folder.ChildAdded:Connect(function() state.dirty=true end)
                removingConnection=folder.ChildRemoving:Connect(function() state.dirty=true end)
            end
        end
        return folder
    end

    local function clearVisual(entry)
        entry.screenPos=nil
        entry.onScreen=false
        entry.worldDist=nil
        entry.outOfRange=false
    end

    local function retireEntry(entry)
        clearVisual(entry)
        entry.alive=false
        entry.health=nil
        entry.nape=nil
    end

    local function buildEntry(model)
        local humanoid=model:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        local root=resolveRoot(model)
        if not root then return nil end
        local entry=state.entries[model]
        if not entry then
            entry={model=model,humanoid=humanoid,root=root,nape=nil}
            state.entries[model]=entry
        else
            entry.humanoid=humanoid
            entry.root=root
        end
        if not entry.nape or not entry.nape:IsDescendantOf(model) then
            entry.nape=resolveNape(model)
        end
        entry.boss= BOSS_NAMES[model.Name] and true or false
        local ok,kind=pcall(function() return model:GetAttribute("Type") end)
        entry.type=(ok and type(kind)=="string" and kind) or (entry.boss and "Boss" or "Normal")
        return entry
    end

    local function scan(force)
        if stopped then return end
        local now=tick()
        if not force and now-state.lastScan<Config.ScanInterval then return end
        state.lastScan=now
        local folder=ensureFolder()
        if not folder then
            for _,entry in pairs(state.entries) do retireEntry(entry) end
            state.entries={}
            state.dirty=false
            return
        end
        local rootPos
        local char,_,hrp=app:Character()
        if hrp then rootPos=hrp.Position end
        local seen={}
        local n=0
        for _,model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and n<Config.MaxTitans then
                local entry=buildEntry(model)
                -- Derived fields need fresh inputs on every scan.
                if entry then clearVisual(entry) end
                if entry and entry.nape and entry.humanoid.Health>0 then
                    seen[model]=true
                    n+=1
                    if rootPos then
                        entry.worldDist=(entry.nape.Position-rootPos).Magnitude
                        if Config.MaxDistance>0 and entry.worldDist>Config.MaxDistance then
                            entry.nape=nil -- out of range: drop so consumers skip it
                            entry.outOfRange=true
                        else
                            entry.outOfRange=false
                            local cam=Workspace.CurrentCamera
                            if cam then
                                local sp,on=cam:WorldToViewportPoint(entry.nape.Position)
                                entry.screenPos=Vector2.new(sp.X,sp.Y)
                                entry.onScreen=on and sp.Z>0
                            else
                                entry.screenPos=nil
                                entry.onScreen=false
                            end
                        end
                    end
                    entry.health=entry.humanoid.Health
                    entry.alive=true
                elseif entry then
                    retireEntry(entry)
                    entry.health=entry.humanoid.Health
                    seen[model]=true
                end
            end
        end
        for model,entry in pairs(state.entries) do
            if not seen[model] then
                retireEntry(entry)
                state.entries[model]=nil
            end
        end
        state.dirty=false
    end
    Titans.Scan=scan

    -- folder lifecycle: mark dirty on spawn/despawn; scan picks it up next tick.
    -- The folder itself appears late (it parents after load), so Update retries
    -- the watch until it sticks.
    ensureFolder()

    function Titans:Update(dt)
        if stopped then return end
        ensureFolder()
        if state.dirty then
            scan(true)
        else
            scan(false)
        end
    end

    --=========================================================================
    -- Selection: nearest nape by world distance; boss priority optional.
    --=========================================================================
    function Titans:Nearest(preferBoss)
        scan(false)
        local rootPos
        local char,_,hrp=app:Character()
        if hrp then rootPos=hrp.Position end
        if not rootPos then return nil end
        local best,bestDist=nil,math.huge
        local bossBest,bossDist=nil,math.huge
        for model,entry in pairs(state.entries) do
            if entry.nape and entry.alive and not isIgnored(model) and not entry.outOfRange then
                local d=(entry.nape.Position-rootPos).Magnitude
                if entry.boss and d<bossDist then bossBest,bossDist=entry,d end
                if d<bestDist then best,bestDist=entry,d end
            end
        end
        if preferBoss and bossBest then return bossBest,bossDist end
        return best,bestDist
    end

    function Titans:All()
        local out={}
        for model,entry in pairs(state.entries) do
            if entry.nape and entry.alive and not isIgnored(model) and not entry.outOfRange then
                table.insert(out,entry)
            end
        end
        return out
    end

    function Titans:Bosses()
        local out={}
        for _,entry in ipairs(self:All()) do
            if entry.boss then table.insert(out,entry) end
        end
        return out
    end

    function Titans:Count()
        scan(false)
        local n=0
        for _,entry in pairs(state.entries) do
            if entry.alive then n+=1 end
        end
        return n
    end

    function Titans:DebugSnapshot()
        local total,withNape=0,0
        for _,entry in pairs(state.entries) do
            total+=1
            if entry.nape then withNape+=1 end
        end
        return {titans=total,nape=withNape,dirty=state.dirty}
    end

    app:OnStop(function()
        if stopped then return end
        stopped=true
        disconnectFolder()
        for _,entry in pairs(state.entries) do retireEntry(entry) end
        state.entries={}
        state.failCount={}
        state.ignoredUntil={}
        state.folder=nil
        state.dirty=false
    end)

    return Titans
end
