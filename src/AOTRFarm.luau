-- Vortexion AOTR farm: reload/refill automation, server-side FPS settings.
--
-- Reload triggers read the HUD blade counter; refills resolve once from
-- workspace.Unclimbable.Reloads and are re-resolved when the part leaves.
-- The FPS settings go through the game's own settings remote
-- (Functions/Settings), which is a server-side change: no local lighting or
-- render hacks that a client-side scan could notice.
return function(app)
    local Workspace=app.Services.Workspace
    local Players=app.Services.Players
    local Farm={}

    local Config={
        AutoReload=false,
        AutoRefill=false,
        CheckInterval=0.5,
        FPSSettings=false,
        Settings={
            Damage_Indicator="Off",
            Shadows="Off",
            Blur="Off",
            Player_Effects="Off",
            Effects=0,
            Music=0,
        },
    }
    Farm.Config=Config

    local state={
        refillPart=nil,
        settingsApplied=false,
        reloads=0,
        refills=0,
        refillAttempts=0,
        lastRefillStatus="idle",
        lastRefillAt=-math.huge,
        lastFuel=nil,
        lastSpears=nil,
        lastRefillDistance=nil,
        denied=0,
    }

    --=========================================================================
    -- Refill point: workspace.Unclimbable.Reloads.<something>.Refill
    --=========================================================================
    local function resolveRefill()
        -- Map-dependent refill locations found in the uploaded AOTR scripts.
        -- Select a nearby station; the old implementation always returned
        -- the first station, often on a completely different map/zone.
        local folders = {}
        local unclimbable = Workspace:FindFirstChild("Unclimbable")
        local climbable = Workspace:FindFirstChild("Climbable")
        local function path(root, ...)
            for _, key in ipairs({...}) do
                root = root and root:FindFirstChild(key)
            end
            return root
        end
        folders[#folders+1] = path(unclimbable,"Reloads")
        folders[#folders+1] = path(unclimbable,"Camps","Camp","GasTanks")
        folders[#folders+1] = path(climbable,"Walls","Gate","GasTanks")
        folders[#folders+1] = path(climbable,"_Walls","Gate","GasTanks")
        local localPlayer = Players.LocalPlayer
        local character = localPlayer and localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local best, distance = nil, math.huge
        for _, folder in pairs(folders) do
            if folder then
                local options = {folder}
                for _, child in ipairs(folder:GetDescendants()) do
                    if child:IsA("BasePart") and child.Name == "Refill" then
                        options[#options+1] = child
                    end
                end
                for _, node in ipairs(options) do
                    local candidate = node.Name == "Refill" and node:IsA("BasePart") and node or node:FindFirstChild("Refill")
                    if candidate and candidate:IsA("BasePart") then
                        local delta = (candidate.Position-root.Position).Magnitude
                        if delta < distance then best, distance = candidate, delta end
                    end
                end
            end
        end
        state.lastRefillDistance = best and distance or nil
        return best
    end
    Farm.ResolveRefill=resolveRefill

    local function doReload()
        local Remotes=app.Remotes
        if not Remotes.GET then return false end
        local have,max=app.ReadCount(app.HUD.blades)
        if not have then return false end
        if have>0 then return false end
        local ok=pcall(function()
            Remotes.GET:InvokeServer("Blades","Reload")
        end)
        if ok then state.reloads+=1 end
        return ok
    end

    local function doRefill()
        local Remotes=app.Remotes
        if not Remotes.POST then state.lastRefillStatus="POST missing"; return false end
        local now=os.clock()
        if now-state.lastRefillAt<2.5 then return false end
        app.ProbeHUD(false)
        local gas=app.ReadPercent(app.HUD.gas)
        local spears=app.ReadCount(app.HUD.spears)
        local blades=app.ReadCount(app.HUD.blades)
        -- Do not spam refill every 0.5s when already full.
        local needsGas=type(gas)=="number" and gas<85
        local needsSpears=type(spears)=="number" and spears<=0
        local needsBlades=type(blades)=="number" and blades<=0
        if type(gas)=="number" or type(spears)=="number" or type(blades)=="number" then
            if not needsGas and not needsSpears and not needsBlades then
                state.lastRefillStatus="supply healthy"
                return false
            end
        end
        local refill=state.refillPart
        if not refill or not refill.Parent then refill=resolveRefill() end
        if not refill then state.lastRefillStatus="station not found"; return false end
        state.refillPart=refill
        local char=Players.LocalPlayer and Players.LocalPlayer.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then state.lastRefillStatus="character not ready"; return false end
        local dist=(refill.Position-root.Position).Magnitude
        state.lastRefillDistance=dist
        if dist>18 then
            state.lastRefillStatus=("station too far (%.0f studs)"):format(dist)
            return false
        end
        state.lastRefillAt=now
        state.refillAttempts+=1
        state.lastFuel,state.lastSpears=gas,spears
        local ok,err=pcall(function()
            Remotes.POST:FireServer("Attacks","Reload",refill)
        end)
        if ok then
            state.refills+=1 -- request counter, NOT proof of success
            state.lastRefillStatus="request sent, awaiting resource change"
        else
            state.denied+=1
            state.lastRefillStatus=tostring(err):sub(1,150)
        end
        return ok
    end
    local function observeRefill()
        if state.lastRefillStatus~="request sent, awaiting resource change" then return end
        app.ProbeHUD(false)
        local gas=app.ReadPercent(app.HUD.gas)
        local spears=app.ReadCount(app.HUD.spears)
        if (type(gas)=="number" and type(state.lastFuel)=="number" and gas>state.lastFuel)
            or (type(spears)=="number" and type(state.lastSpears)=="number" and spears>state.lastSpears) then
            state.lastRefillStatus="confirmed by HUD"
        elseif os.clock()-state.lastRefillAt>3 then
            state.denied+=1
            state.lastRefillStatus="server unconfirmed (HUD unchanged)"
        end
    end

    --=========================================================================
    -- Server-side settings: one-shot per session, idempotent.
    --=========================================================================
    local function applySettings()
        if state.settingsApplied then return end
        local Remotes=app.Remotes
        if not Remotes.GET then return end
        local ok=pcall(function()
            for key,value in pairs(Config.Settings) do
                Remotes.GET:InvokeServer("Functions","Settings",key,value)
                task.wait(0.05)
            end
        end)
        state.settingsApplied=ok
        app.Log("farm settings applied=%s",tostring(ok))
    end

    local accum=0
    local function tickFarm(dt)
        if Config.AutoRefill then app.Guard("Farm.RefillObserve",observeRefill) end
        if Config.AutoReload then app.Guard("Farm.Reload",doReload) end
        if Config.AutoRefill then app.Guard("Farm.Refill",doRefill) end
    end

    function Farm:Update(dt)
        if Config.FPSSettings and not state.settingsApplied then
            app.Guard("Farm.Settings",applySettings)
        end
        accum+=dt
        if accum<Config.CheckInterval then return end
        accum=0
        app.Guard("Farm",tickFarm,dt)
    end

    function Farm:DebugSnapshot()
        return {reloads=state.reloads,refills=state.refills,
            refill=state.refillPart and state.refillPart.Parent and true or false,
            attempts=state.refillAttempts, status=state.lastRefillStatus,
            distance=state.lastRefillDistance, unconfirmed=state.denied}
    end

    app:OnStop(function()
        Config.AutoReload=false
        Config.AutoRefill=false
    end)

    return Farm
end
