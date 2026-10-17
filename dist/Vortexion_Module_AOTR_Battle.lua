-- Vortexion Neverlose - generated offline; publishing must be performed separately.
-- Neverlose attribution is retained in vendor/Neverlose/README.md.
-- Forsaken retains runtime model rbxassetid://132866968194043.
-- Modify src/*.luau and run python3 build.py; do not edit this output.
return function(kernel)
assert(type(kernel) == 'table' and type(kernel.WindBridgeFactory) == 'function', 'Invalid Vortexion core')
local WindUI, WindBridgeFactory, GameRouter = kernel.WindUI, kernel.WindBridgeFactory, kernel.GameRouter
local entry = function()
local AOTRCommon = (function()
-- Lifecycle, capability probe and UI shared by AOTR lobby and battle.
-- Modules receive this app table and register features against it.
return function(scene, WindUI, Bridge)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local Lighting=game:GetService("Lighting")
    local UserInputService=game:GetService("UserInputService")
    local Stats=game:GetService("Stats")
    local client=(getgenv and getgenv()) or _G
    if type(client.VortexionAOTRCleanup)=="function" then pcall(client.VortexionAOTRCleanup) end
    local app={scene=scene, connections={}, disposers={}, active=true, flags={}, player=Players.LocalPlayer}
    app.Services={Players=Players,RunService=RunService,Workspace=Workspace,
        ReplicatedStorage=ReplicatedStorage,Lighting=Lighting,Input=UserInputService,
        UserInputService=UserInputService,Stats=Stats}

    -- Executor name is diagnostic metadata only. Never abort the entire game
    -- based on a vendor label: capabilities are checked individually below.
    -- A missing hook API must disable only the dependent optional feature.
    local executorName = "unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then
            executorName = tostring(identifyexecutor() or "unknown")
        end
    end)
    app.ExecutorName = executorName

    --=========================================================================
    -- Capability probe: every optional integration checks these, never guesses.
    --=========================================================================
    local Caps={
        Drawing=type(Drawing)=="table" or type(Drawing)=="userdata",
        DrawingUserdata=type(Drawing)=="userdata",
        hookfunction=type(hookfunction)=="function",
        replaceclosure=type(replaceclosure)=="function",
        hookmetamethod=type(hookmetamethod)=="function",
        getrawmetatable=type(getrawmetatable)=="function",
        newcclosure=type(newcclosure)=="function",
        checkcaller=type(checkcaller)=="function",
        getnamecallmethod=type(getnamecallmethod)=="function",
        mousemoverel=type(mousemoverel)=="function",
        mouse1press=type(mouse1press)=="function",
        mouse1release=type(mouse1release)=="function",
        VirtualUser=type(VirtualUser)=="table",
        gethui=type(gethui)=="function",
        getgenv=type(getgenv)=="function",
    }
    app.Caps=Caps
    app.HasDrawing=(Caps.Drawing or Caps.DrawingUserdata) and true or false
    app.CanCloak=Caps.hookmetamethod and Caps.checkcaller and Caps.getnamecallmethod

    --=========================================================================
    -- Guarded logging: Debug flag gates verbose output; warn is throttled so a
    -- stuck subsystem cannot flood the console.
    --=========================================================================
    app.Debug=false
    local lastWarn={}
    local function Log(fmt,...)
        if not app.Debug then return end
        local ok,msg=pcall(string.format,fmt,...)
        print("[Vortexion/AOTR/"..tostring(scene).."] "..(ok and msg or tostring(fmt)))
    end
    local function Guard(tag,fn,...)
        local ok,err=pcall(fn,...)
        if not ok then
            local now=tick()
            if now-(lastWarn[tag] or 0)>5 then
                lastWarn[tag]=now
                warn("[Vortexion/AOTR/"..tostring(tag).."] "..tostring(err))
            end
        end
        return ok,err
    end
    local function RandomName()
        local s={}
        for i=1,14 do s[i]=string.char(math.random(65,90)) end
        return table.concat(s)
    end
    local function GetGuiParent()
        if Caps.gethui then
            local ok,h=pcall(gethui)
            if ok and h then return h end
        end
        local ok,cg=pcall(function() return game:GetService("CoreGui") end)
        if ok and cg then return cg end
        -- Render callers already retry on nil; never suspend a visual tick.
        local lp=Players.LocalPlayer
        if not lp then return nil end
        local okPG,pg=pcall(function() return lp:FindFirstChild("PlayerGui") end)
        if okPG and pg then return pg end
        return nil
    end
    local function Ping()
        local ok,item=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"] end)
        if ok and item then
            local okv,v=pcall(function() return item:GetValue() end)
            if okv and type(v)=="number" and v>0 then return math.clamp(v/1000,0.02,0.4) end
        end
        return 0.08
    end
    app.Log=Log
    app.Guard=Guard
    app.RandomName=RandomName
    app.GetGuiParent=GetGuiParent
    app.Ping=Ping
    app.OnCleanup=function(fn)
        if type(fn)=="function" then return app:OnStop(fn) end
        return fn
    end
    app.Notify=app.Notify -- keep original signature (message)

    --=========================================================================
    -- Remote surface: one probe, every consumer. AOTR protocol is stable across
    -- the known scripts (GET RemoteFunction + POST RemoteEvent under
    -- ReplicatedStorage.Assets.Remotes); missing pieces degrade per feature.
    --=========================================================================
    local Remotes={ready=false,GET=nil,POST=nil}
    local function probeRemotes()
        local ok,res=pcall(function()
            local folder=ReplicatedStorage:FindFirstChild("Assets")
            folder=folder and folder:FindFirstChild("Remotes")
            if not folder then return nil end
            return folder
        end)
        if ok and res then
            Remotes.GET=res:FindFirstChild("GET")
            Remotes.POST=res:FindFirstChild("POST")
        end
        Remotes.ready=(Remotes.GET~=nil) or (Remotes.POST~=nil)
        Log("remotes GET=%s POST=%s",tostring(Remotes.GET~=nil),tostring(Remotes.POST~=nil))
        return Remotes.ready
    end
    app.Remotes=Remotes
    app.ProbeRemotes=probeRemotes

    --=========================================================================
    -- HUD reader: blade/spear counters live in deeply nested labels whose
    -- intermediate names drift between versions. Probe a candidate chain once,
    -- cache the resolved labels, re-probe on nil text.
    --=========================================================================
    local HUD={blades=nil,spears=nil,lastProbe=0}
    local function findLabel(root,path)
        local cur=root
        for _,name in ipairs(path) do
            if not cur then return nil end
            cur=cur:FindFirstChild(name,true)
        end
        if cur and cur:IsA("TextLabel") then return cur end
    end
    -- Gas sits at an exact non-recursive path (Top["7"].Gas.Percentage); a
    -- missing hop, a raised error or a non-TextLabel terminal all resolve nil.
    local function findExactLabel(root,path)
        local cur=root
        for _,name in ipairs(path) do
            if not cur then return nil end
            local ok,child=pcall(function() return cur:FindFirstChild(name) end)
            if not ok or not child then return nil end
            cur=child
        end
        if not cur then return nil end
        local okText,isText=pcall(function() return cur:IsA("TextLabel") end)
        if okText and isText then return cur end
        return nil
    end
    local function probeHUD(force)
        if not force and tick()-HUD.lastProbe<2 then return HUD end
        HUD.lastProbe=tick()
        local ok,gui=pcall(function()
            local lp=Players.LocalPlayer
            return lp and lp:FindFirstChild("PlayerGui")
        end)
        if not ok or not gui then HUD.blades=nil; HUD.spears=nil; HUD.gas=nil; return HUD end
        HUD.blades=findExactLabel(gui,{"Interface","HUD","Main","Top","7","Blades","Sets"})
            or findExactLabel(gui,{"Interface","HUD","Main","Top","Blades","Sets"})
            or findLabel(gui,{"Interface","HUD","Main","Top","Blades","Sets"})
        HUD.spears=findExactLabel(gui,{"Interface","HUD","Main","Top","7","Spears","Spears"})
            or findExactLabel(gui,{"Interface","HUD","Main","Top","Spears","Spears"})
            or findLabel(gui,{"Interface","HUD","Main","Top","Spears","Spears"})
        HUD.gas=findExactLabel(gui,{"Interface","HUD","Main","Top","7","Gas","Percentage"})
        return HUD
    end
    local function readCount(label)
        if not label or not label.Parent then return nil end
        local ok,text=pcall(function() return label.Text end)
        if not ok or not text then return nil end
        local have,max=string.match(text,"(%d+)%s*/%s*(%d+)")
        if have then return tonumber(have),tonumber(max) end
        local m=string.match(text,"(%d+)")
        if m then local n=tonumber(m); return n,n end
        return nil
    end
    -- Strict decimal percentage: "42%", "42.5%", bare 0/100 with surrounding
    -- whitespace. Rejects negatives, nan/inf, >100 and mixed text. Never
    -- reuses readCount, which would truncate a leading minus into digits.
    local function readPercent(label)
        if not label then return nil end
        local okParent,parent=pcall(function() return label.Parent end)
        if not okParent or not parent then return nil end
        local okText,text=pcall(function() return label.Text end)
        if not okText or type(text)~="string" then return nil end
        local trimmed=string.match(text,"^%s*(.-)%s*$")
        local body=string.match(trimmed,"^(.-)%s*%%$")
        if body==nil then body=trimmed end
        if not string.match(body,"^%d+$") and not string.match(body,"^%d+%.%d+$") then return nil end
        local value=tonumber(body)
        if not value or value~=value or value==math.huge or value==-math.huge then return nil end
        if value<0 or value>100 then return nil end
        return value
    end
    app.HUD=HUD
    app.ProbeHUD=probeHUD
    app.ReadCount=readCount
    app.ReadPercent=readPercent

    local function cleanup()
        if not app.active then return end
        app.active=false
        for _,con in ipairs(app.connections) do pcall(function() con:Disconnect() end) end
        for _,fn in ipairs(app.disposers) do pcall(fn) end
        if app.ui then pcall(function() app.ui:Destroy() end) end
    end
    client.VortexionAOTRCleanup=cleanup
    function app:Track(con) table.insert(self.connections,con);return con end
    function app:OnStop(fn) table.insert(self.disposers,fn);return fn end

    --=========================================================================
    -- Touch layer: mobile trigger + fly drag. Single finger held = trigger;
    -- single finger drag = horizontal fly; two fingers = vertical fly.
    --=========================================================================
    app.Touch = { Enabled = false, Held = false, RightSideOnly = true }
    do
        local UIS = app.Services and app.Services.UserInputService
        if not UIS then
            local ok, svc = pcall(function() return game:GetService("UserInputService") end)
            if ok then UIS = svc end
        end
        if UIS and UIS.TouchEnabled then
            app.Touch.Enabled = true
            local touchPoints = {}
            local touchOrder = {}
            local touchConns = {}
            local touchType = Enum and Enum.UserInputType and Enum.UserInputType.Touch
            local function isTouch(input)
                return input and (not touchType or input.UserInputType==touchType)
            end
            local function beginTouch(input, processed)
                if not app.active or processed or not isTouch(input) or touchPoints[input] then return end
                local position=input.Position
                if not position then return end
                local camera=Workspace.CurrentCamera
                local viewport=camera and camera.ViewportSize
                if app.Touch.RightSideOnly and viewport and viewport.X>0 and position.X<viewport.X*0.5 then return end
                touchPoints[input]={start=position,current=position}
                table.insert(touchOrder,input)
                app.Touch.Held=true
            end
            local function moveTouch(input)
                local point=touchPoints[input]
                if point and input.Position then point.current=input.Position end
            end
            local function endTouch(input)
                if not touchPoints[input] then return end
                touchPoints[input]=nil
                local index=table.find(touchOrder,input)
                if index then table.remove(touchOrder,index) end
                app.Touch.Held=#touchOrder>0
            end
            if UIS.InputBegan then
                table.insert(touchConns, UIS.InputBegan:Connect(beginTouch))
                table.insert(touchConns, UIS.InputChanged:Connect(moveTouch))
                table.insert(touchConns, UIS.InputEnded:Connect(endTouch))
            else
                table.insert(touchConns, UIS.TouchStarted:Connect(beginTouch))
                table.insert(touchConns, UIS.TouchMoved:Connect(moveTouch))
                table.insert(touchConns, UIS.TouchEnded:Connect(endTouch))
            end
            function app.Touch:Drag()
                local first=touchPoints[touchOrder[1]]
                local second=touchPoints[touchOrder[2]]
                if not first then return Vector2.zero,0 end
                local delta=first.current-first.start
                local vertical=0
                if second then vertical=second.current.Y-second.start.Y end
                return Vector2.new(delta.X,delta.Y),vertical
            end
            local function clearTouches()
                table.clear(touchPoints)
                table.clear(touchOrder)
                app.Touch.Held=false
            end
            if UIS.WindowFocusReleased then
                table.insert(touchConns,UIS.WindowFocusReleased:Connect(clearTouches))
            end
            app.OnCleanup(function()
                for _,cn in ipairs(touchConns) do pcall(function() cn:Disconnect() end) end
                clearTouches()
            end)
        end
    end
    function app:Alive() return self.active and client.VortexionAOTRCleanup==cleanup end
    -- Bounded visual cadence from the shared bridge (app.ui). Degrades to the
    -- caller's base interval when the bridge or method is absent, so pre-bridge
    -- cadence is preserved and the fixture path keeps its original frequency.
    function app:GetVisualInterval(base)
        base=tonumber(base) or 0.1
        -- Reject non-finite or non-positive bases: math.huge freezes visuals
        -- forever, NaN or <=0 stalls the cadence.
        if base~=base or base==math.huge or base==-math.huge or base<=0 then base=0.1 end
        local ui=self.ui
        if ui and type(ui.GetVisualInterval)=="function" then
            local ok,value=pcall(function() return ui:GetVisualInterval(base) end)
            if ok and type(value)=="number" and value==value and value~=math.huge and value~=-math.huge and value>0 then
                return math.max(base,value)
            end
        end
        return base
    end
    function app:Notify(message)
        if self.ui and self:Alive() then self.ui:Notify({Title="AOTR",Content=message,Duration=3}) end
    end
    function app:Open()
        if not self:Alive() then return end
        local ok,ui=pcall(function()
            return Bridge(WindUI,{Name="AOTR",Folder="VortexionAOTR",Section="A T T A C K  O N  T I T A N"})
        end)
        if not ok or not ui then
            local reason="AOTR Bridge: "..tostring(ui)
            client.VortexionBootError = reason
            warn("[Vortexion/AOTR] "..reason)
            cleanup()
            return
        end
        -- Bridge may yield while cleanup retires this app; reclaim the late UI.
        if not self:Alive() then pcall(function() ui:Destroy() end);return end
        self.ui=ui
        local initialized,window=pcall(function()
            ui:OnDestroy(cleanup)
            if not self:Alive() then return end
            return ui:CreateWindow({Title=scene=="lobby" and "AOTR 大厅" or "AOTR 战斗"})
        end)
        if not initialized or not window then
            if not initialized or self:Alive() then
                local reason="AOTR Window: "..tostring(window)
                client.VortexionBootError = client.VortexionBootError or reason
                warn("[Vortexion/AOTR] "..reason)
            end
            cleanup()
            return
        end
        if not self:Alive() then return end
        return window
    end
    function app:Loop(id, interval, work)
        self.flags[id]=(self.flags[id] or 0)+1
        local generation=self.flags[id]
        task.spawn(function()
            while self:Alive() and self.flags[id]==generation do
                local started=os.clock()
                local ok,err=pcall(work)
                if not ok then warn("[AOTR/"..id.."] "..tostring(err)) end
                task.wait(math.max(0.1,interval-(os.clock()-started)))
            end
        end)
    end
    function app:StopLoop(id) self.flags[id]=(self.flags[id] or 0)+1 end
    function app:Character()
        local c=self.player and self.player.Character
        local hum=c and c:FindFirstChildOfClass("Humanoid")
        local root=c and c:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health>0 then return c,hum,root end
    end
    function app:Status(tab)
        tab:AddParagraph({Title="当前场景",Content=scene=="lobby" and "大厅 / 主菜单" or "战斗任务"})
        tab:AddParagraph({Title="脚本状态",Content="独立模块已启动。禁用功能不会保留后台循环；重新执行会清理旧监听。"})
    end
    return app
end

end)()
local AOTRTitansFactory = (function()
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
    local addedConnection,removedConnection
    local function disconnectFolder()
        if addedConnection then addedConnection:Disconnect();addedConnection=nil end
        if removedConnection then removedConnection:Disconnect();removedConnection=nil end
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
                removedConnection=folder.ChildRemoved:Connect(function() state.dirty=true end)
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

end)()
local AOTRCombatFactory = (function()
-- Vortexion AOTR combat: nape lock, remote hit registration, spears, hitbox.
--
-- AOTR's damage surface is two remotes (validated across every known public
-- script): POST FireServer("Attacks","Slash",true) fires the swing and
-- POST FireServer("Hitboxes","Register",nape,dmg,crit,combo) registers a hit
-- on a nape instance; the server trusts the instance reference and the client
-- damage number. Thunder spears use GET InvokeServer("Spears","S_Fire",slot)
-- plus POST FireServer("Spears","S_Explode",position).
--
-- Anti-detection posture (the public scripts do none of this):
--   * attack cadence is a randomized interval, never a fixed timer
--   * damage rolls inside the game's own 625-850 band, crit inside 0.2-0.3
--   * combo index cycles 1..4 like real mastery strings
--   * HitChance gates each registration: a failed roll targets a point a few
--     studs off the nape, so the conversion rate stays human
--   * everything pauses while the Roblox window is unfocused
--   * local nape size growth uses a 20Hz lerp state machine with a restore
--     table, never a per-frame write
return function(app)
    local RunService=app.Services.RunService
    local Workspace=app.Services.Workspace
    local UserInputService=app.Services.Input
    local LocalPlayer=app.Services.Players.LocalPlayer
    local Combat={}

    local Config={
        Enabled=false,
        TargetMode="Nearest",     -- Nearest | Boss
        Mode="Camera",            -- Camera | Mouse | Both
        FOV=160,
        MaxDistance=1200,
        Smoothness=0.85,
        MaxAngle=30,
        HitChance=1,
        Prediction=0.12,
        TriggerKey="Always",      -- Always | Hold
        AttackCooldown=0.25,
        CooldownJitter=0.05,       -- +/- fraction of the cooldown
        Weapon="Auto",            -- Auto | Blades | Spears
        DamageMin=625,
        DamageMax=850,
        CritChance=0.25,
        ComboCycle=true,
        SpearBurst=30,            -- S_Explode calls per boss kill
        SpearInterval=0.03,
        HitboxEnabled=false,
        HitboxSize=1.6,
        FOVCircle=true,
    }
    Combat.Config=Config

    local state={
        locked=nil,
        lastLocked=nil,
        lastAttack=0,
        nextCooldown=Config.AttackCooldown,
        comboIndex=1,
        firing=false,
        fireAt=0,
        hitboxEntries={},
        hitboxAccum=0,
        napeVel=Vector3.zero,
        napeVelInit=false,
        aimSmooth=Vector3.zero,
        cost=0,
        attacks=0,
        attempts=0,
        failedRequests=0,
        queuedRequests=0,
        lastRequestError="none",
        errors=0,
        windowFocused=true,
    }

    local rayParams=RaycastParams.new()
    rayParams.FilterType=Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater=true

    local function wallBlocked(fromPos,toPos,char)
        local diff=toPos-fromPos
        local dist=diff.Magnitude
        if dist<0.1 then return false end
        rayParams.FilterDescendantsInstances=char and {char} or {}
        return Workspace:Raycast(fromPos,diff.Unit*(dist+2),rayParams)~=nil
    end

    --=========================================================================
    -- Weapon read: HUD counters decide Blades vs Spears when Auto.
    --=========================================================================
    local function currentWeapon()
        if Config.Weapon~="Auto" then return Config.Weapon end
        local blades=app.ReadCount(app.HUD.blades)
        if blades and blades>0 then return "Blades" end
        local spears=app.ReadCount(app.HUD.spears)
        if spears and spears>0 then return "Spears" end
        return "Blades"
    end

    local function spearSlot()
        local count=app.ReadCount(app.HUD.spears)
        return count or 1
    end

    --=========================================================================
    -- Target acquisition from the shared titan pool.
    --=========================================================================
    local function acquire()
        local Titans=app.Titans
        if not Titans then return nil end
        local entry
        if Config.TargetMode=="Boss" then
            local bosses=Titans:Bosses()
            entry=bosses[1]
        end
        if not entry then entry=Titans:Nearest(Config.TargetMode=="Boss") end
        if not entry then return nil end
        local char,_,hrp=app:Character()
        if not (entry.nape and entry.nape.Parent) then
            Titans:RegisterFail(entry.model)
            return nil
        end
        Titans:ClearFails(entry.model)
        if hrp then
            local worldDist=(entry.nape.Position-hrp.Position).Magnitude
            if worldDist>Config.MaxDistance then return nil end
        end
        return entry
    end

    --=========================================================================
    -- Prediction: nape parts bob vertically. EMA the nape velocity and lead by
    -- half a ping, scaled by the Prediction slider.
    --=========================================================================
    local function predictedPoint(entry)
        local nape=entry.nape
        local pos=nape.Position
        local vel=nape.AssemblyLinearVelocity or Vector3.zero
        if state.napeVelInit then
            state.napeVel=state.napeVel:Lerp(vel,0.15)
        else
            state.napeVel=vel
            state.napeVelInit=true
        end
        local lead=0.5*app.Ping()+0.05
        local offset=state.napeVel*(lead*(Config.Prediction/0.12))
        if (offset-state.aimSmooth).Magnitude>0.05 then
            state.aimSmooth=state.aimSmooth:Lerp(offset,0.25)
        end
        return pos+state.aimSmooth
    end

    --=========================================================================
    -- Camera aim: clamped alpha, angular speed ceiling, vertical damping,
    -- soft first frame after a target switch (same policy as SCP/BloxStrike).
    --=========================================================================
    local function cameraAim(dt,aimPos)
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local camPos=cam.CFrame.Position
        local look=aimPos-camPos
        if look.Magnitude<0.01 then return end
        local targetLook=look.Unit
        local targetCF=CFrame.lookAt(camPos,aimPos)
        local angle=math.acos(math.clamp(cam.CFrame.LookVector:Dot(targetLook),-1,1))
        local screen,on=cam:WorldToViewportPoint(aimPos)
        local viewport=cam.ViewportSize
        local center=Vector2.new(viewport.X/2,viewport.Y/2)
        local screenDist=on and (Vector2.new(screen.X,screen.Y)-center).Magnitude or math.huge
        local fovT=1-math.clamp(screenDist/math.max(Config.FOV,1),0,1)
        local alpha=math.clamp((1-Config.Smoothness)*(0.4+0.6*fovT),0.10,0.45)
        if math.abs(targetLook.Y)>0.6 then alpha=alpha*0.85 end
        if state.locked~=state.lastLocked then alpha=math.min(alpha,0.10) end
        if angle>1e-4 then alpha=math.min(alpha,(math.rad(22)*dt)/angle) end
        if alpha<=0.001 then return end
        cam.CFrame=cam.CFrame:Lerp(targetCF,alpha)
    end

    --=========================================================================
    -- Remote registration: each request can fail locally and may be rejected by
    -- the game server. Track request errors without claiming hit confirmation.
    --=========================================================================
    local function rollDamage()
        local lo=math.min(Config.DamageMin,Config.DamageMax)
        local hi=math.max(Config.DamageMin,Config.DamageMax)
        local span=hi-lo
        local center=(lo+hi)/2
        local gauss=(math.random()+math.random()+math.random())/3
        return math.floor(center+(gauss-0.5)*span)
    end

    local function rollCrit()
        return math.random()<Config.CritChance and (0.2+math.random()*0.1) or nil
    end

    local function jitteredCooldown()
        local j=1+(math.random()*2-1)*Config.CooldownJitter
        return math.max(0.05,Config.AttackCooldown*j)
    end

    local function registerBlades(entry)
        local Remotes=app.Remotes
        if not Remotes.POST then state.lastRequestError="POST missing"; return false end
        if not (entry.nape and entry.nape.Parent) then state.lastRequestError="Nape missing"; return false end
        local ok,err=pcall(function()
            Remotes.POST:FireServer("Attacks","Slash",true)
            local combo=Config.ComboCycle and state.comboIndex or nil
            Remotes.POST:FireServer("Hitboxes","Register",entry.nape,rollDamage(),rollCrit(),combo)
        end)
        if not ok then state.lastRequestError=tostring(err):sub(1,220); return false end
        state.lastRequestError="none (server not acknowledged)"
        local combo=Config.ComboCycle and state.comboIndex or nil
        if combo then
            state.comboIndex+=1
            if state.comboIndex>4 then state.comboIndex=1 end
        end
        return true
    end

    local spearBursting = false
    local function registerSpears(entry)
        local Remotes=app.Remotes
        if not (Remotes.POST and Remotes.GET) then state.lastRequestError="GET/POST missing"; return false end
        if spearBursting then return "busy" end
        spearBursting = true
        -- InvokeServer and multi-shot delays must never yield a RenderStep callback.
        -- Keep exactly one active burst, fence teardown and record actual local send.
        task.spawn(function()
            local sent=0
            local ok,err = pcall(function()
                if not app:Alive() or not Config.Enabled then return end
                local slot=spearSlot()
                Remotes.GET:InvokeServer("Spears","S_Fire",tostring(slot))
                local burst=entry.boss and Config.SpearBurst or 1
                for i=1,burst do
                    if not app:Alive() or not Config.Enabled
                        or not (entry.nape and entry.nape.Parent) then break end
                    Remotes.POST:FireServer("Spears","S_Explode",entry.nape.Position)
                    sent+=1
                    if i<burst then task.wait(Config.SpearInterval) end
                end
            end)
            if sent>0 then state.attacks+=1 end
            if not ok then state.failedRequests+=1 end
            state.lastRequestError = ok and "none (server not acknowledged)" or tostring(err):sub(1,220)
            spearBursting = false
        end)
        return "queued"
    end

    -- Human gate: with probability 1-HitChance the shot misses by a few
    -- studs, so the server-side conversion profile stays plausible.
    local function attackRoll()
        return math.random()<=Config.HitChance
    end

    local function triggerHeld()
        if Config.TriggerKey=="Always" then return true end
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            or (app.Touch.Enabled and app.Touch.Held)
    end

    --=========================================================================
    -- Hitbox: local nape size growth, 20Hz lerp + restore table.
    --=========================================================================
    local function hitboxParts(entry)
        local parts={}
        if entry.nape and entry.nape:IsA("BasePart") then table.insert(parts,entry.nape) end
        return parts
    end

    local function restoreHitEntry(key,record)
        if not record then return end
        for _,item in ipairs(record.parts) do
            local part=item.part
            if part and part.Parent then
                part.Size=item.origSize
                part.Transparency=item.origTransparency
                part.CanCollide=item.origCollide
            end
        end
        state.hitboxEntries[key]=nil
    end

    local function hitboxTick(dt)
        if not Config.HitboxEnabled then
            for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
            return
        end
        state.hitboxAccum+=dt
        if state.hitboxAccum<0.05 then return end
        state.hitboxAccum=0
        local entry=state.locked
        if not (entry and entry.nape and entry.nape.Parent) then
            for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
            return
        end
        local record=state.hitboxEntries[entry.model]
        if not record then
            local parts={}
            for _,part in ipairs(hitboxParts(entry)) do
                table.insert(parts,{part=part,origSize=part.Size,
                    origTransparency=part.Transparency,origCollide=part.CanCollide})
            end
            if #parts==0 then return end
            record={parts=parts}
            state.hitboxEntries[entry.model]=record
        end
        for _,item in ipairs(record.parts) do
            local part=item.part
            if not part or not part.Parent then
                restoreHitEntry(entry.model,record)
                break
            end
            local orig=item.origSize
            local target=Vector3.new(
                math.min(orig.X*Config.HitboxSize,orig.X+10),
                math.min(orig.Y*Config.HitboxSize,orig.Y+10),
                math.min(orig.Z*Config.HitboxSize,orig.Z+10))
            part.Size=part.Size:Lerp(target,0.35)
            part.Transparency=part.Transparency+(0.55-part.Transparency)*0.35
            part.CanCollide=false
        end
    end

    --=========================================================================
    -- FOV circle.
    --=========================================================================
    local fovGui,fovFrame
    local function fovTick()
        if Config.Enabled and Config.FOVCircle then
            if not (fovFrame and fovFrame.Parent) then
                local parent=app.GetGuiParent()
                if not parent then return end
                local sg=Instance.new("ScreenGui")
                sg.Name=app.RandomName()
                sg.ResetOnSpawn=false
                sg.IgnoreGuiInset=true
                sg.DisplayOrder=999
                sg.Parent=parent
                if app.Cloak then sg=app.Cloak.Protect(sg) end
                local frame=Instance.new("Frame")
                frame.Name=app.RandomName()
                frame.AnchorPoint=Vector2.new(0.5,0.5)
                frame.Position=UDim2.fromScale(0.5,0.5)
                frame.BackgroundTransparency=1
                local corner=Instance.new("UICorner")
                corner.CornerRadius=UDim.new(1,0)
                corner.Parent=frame
                local stroke=Instance.new("UIStroke")
                stroke.Color=Color3.fromRGB(255,90,60)
                stroke.Thickness=1.5
                stroke.Transparency=0.35
                stroke.Parent=frame
                frame.Parent=sg
                if app.Cloak then frame=app.Cloak.Protect(frame) end
                fovGui,fovFrame=sg,frame
            end
            fovFrame.Size=UDim2.fromOffset(Config.FOV*2,Config.FOV*2)
            fovFrame.Visible=true
        elseif fovFrame and fovFrame.Parent then
            fovFrame.Visible=false
        end
    end

    --=========================================================================
    -- Update.
    --=========================================================================
    function Combat:Update(dt)
        if not Config.Enabled then
            state.locked=nil
            fovTick()
            return
        end
        local t0=tick()
        state.lastLocked=state.locked

        -- Window focus gate: a focused window is the only human state.
        -- On Android the executor overlay can cause WindowFocusReleased even
        -- though the Roblox scene is still running. The focus gate is desktop-only.
        if not state.windowFocused and not UserInputService.TouchEnabled then
            state.locked=nil
            fovTick()
            return
        end

        state.locked=acquire()
        local entry=state.locked
        if entry then
            local aimPos=predictedPoint(entry)
            if aimPos then
                if Config.Mode=="Mouse" and app.Caps.mousemoverel then
                    local cam=Workspace.CurrentCamera
                    local screen,on=cam and cam:WorldToViewportPoint(aimPos)
                    if on and screen.Z>0 then
                        local viewport=cam.ViewportSize
                        local delta=Vector2.new(screen.X,screen.Y)-Vector2.new(viewport.X/2,viewport.Y/2)
                        if delta.Magnitude>2 then
                            mousemoverel(math.floor(delta.X*0.12+0.5),math.floor(delta.Y*0.12+0.5))
                        end
                    end
                else
                    cameraAim(dt,aimPos)
                end
            end

            -- Remote registration cadence.
            local now=tick()
            if triggerHeld() and now-state.lastAttack>=state.nextCooldown then
                state.lastAttack=now
                state.nextCooldown=jitteredCooldown()
                if attackRoll() then
                    state.attempts += 1
                    app.Guard("Combat.Register",function()
                        local weapon=currentWeapon()
                        local okRegister
                        if weapon=="Spears" then
                            okRegister=registerSpears(entry)
                        else
                            okRegister=registerBlades(entry)
                        end
                        if okRegister == "queued" then
                            state.queuedRequests += 1
                        elseif okRegister == "busy" then
                            -- Existing async burst owns the remote; not a failure.
                        elseif okRegister then
                            state.attacks += 1
                        else
                            state.failedRequests += 1
                        end
                    end)
                end
            end
        else
            state.napeVelInit=false
            state.comboIndex=1
        end

        hitboxTick(dt)
        fovTick()
        state.cost=tick()-t0
    end

    function Combat:GetLock()
        return state.locked
    end

    function Combat:DebugSnapshot()
        return {
            locked=state.locked and state.locked.model.Name or "-",
            dist=state.locked and math.floor(state.locked.worldDist or 0) or 0,
            attacks=state.attacks,
            attempts=state.attempts,
            queuedRequests=state.queuedRequests,
            failedRequests=state.failedRequests,
            lastRequestError=state.lastRequestError,
            windowFocused=state.windowFocused,
            lockAvailable=state.locked ~= nil,
            serverConfirmed=false, -- FireServer is one-way; no damage acknowledgement.
            weapon=currentWeapon(),
            costMs=math.floor(state.cost*100000)/100,
        }
    end

    function Combat:Stop()
        for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
        if fovGui then fovGui:Destroy();fovGui=nil;fovFrame=nil end
        Config.Enabled=false
    end

    -- Window focus watch.
    app:Track(UserInputService.WindowFocused:Connect(function() state.windowFocused=true end))
    app:Track(UserInputService.WindowFocusReleased:Connect(function() state.windowFocused=false end))

    app:OnStop(function()
        Combat:Stop()
    end)

    return Combat
end

end)()
local AOTRMovementFactory = (function()
-- Vortexion AOTR movement: hover glide, teleport follow, noclip, speed, anti-AFK.
--
-- Hover drives AssemblyLinearVelocity toward a hold point above the locked
-- titan (the same shape the game's own ODM flight uses), which replicates as
-- ordinary motion. The teleport mode exists for completeness but is the
-- noisy path; hover is the default.
return function(app)
    local RunService=app.Services.RunService
    local Workspace=app.Services.Workspace
    local UserInputService=app.Services.Input
    local LocalPlayer=app.Services.Players.LocalPlayer
    local Movement={}

    local Config={
        FollowEnabled=false,
        MoveMode="Hover",        -- Hover | Teleport
        HeightOffset=25,         -- studs above the titan HRP hold point
        BehindOffset=30,         -- studs behind the titan HRP
        GlideSpeed=120,
        FollowBossOnly=false,
        SpeedEnabled=false,
        SpeedValue=24,
        Noclip=false,
        AntiAFK=true,
        TouchAssist=false,     -- mobile touch-fly assist: strafe / forward-back / lift
        TouchFlySpeed=120,
    }
    Movement.Config=Config

    local state={
        pulse="idle",
        pulseAt=0,
        speedBackup=nil,
        speedHumanoid=nil,
        collisionBackup={},
        noclipAccum=0,
        following=false,
        lastDragX=0,
        lastDragY=0,
        lastVertical=0,
    }

    local function restoreSpeed()
        local hum=state.speedHumanoid
        if hum and hum.Parent and state.speedBackup~=nil then
            pcall(function() hum.WalkSpeed=state.speedBackup end)
        end
        state.speedHumanoid=nil
        state.speedBackup=nil
        state.pulse="idle"
    end

    local function restoreCollision()
        for part,value in pairs(state.collisionBackup) do
            if part.Parent then pcall(function() part.CanCollide=value end) end
            state.collisionBackup[part]=nil
        end
        state.noclipAccum=0
    end

    local function holdPoint(entry)
        if not entry then return nil end
        local model=entry.model
        local hrp=model:FindFirstChild("HumanoidRootPart")
        if hrp then
            return (hrp.CFrame*CFrame.new(0,Config.HeightOffset,Config.BehindOffset)).Position
        end
        if entry.nape and entry.nape.Parent then
            return entry.nape.Position+Vector3.new(0,Config.HeightOffset,0)
        end
        return nil
    end

    local function updateFollow(dt)
        local char,hum,hrp=app:Character()
        if not (char and hrp) then return end
        local entry=app.Combat and app.Combat:GetLock()
        if not entry and app.Titans then entry=app.Titans:Nearest(false) end
        if not entry then return end
        if Config.FollowBossOnly and not entry.boss then return end
        local target=holdPoint(entry)
        if not target then return end

        if Config.MoveMode=="Teleport" then
            hrp.CFrame=CFrame.new(target)
        else
            local dir=target-hrp.Position
            if dir.Magnitude>2 then
                hrp.AssemblyLinearVelocity=dir.Unit*Config.GlideSpeed
            else
                hrp.AssemblyLinearVelocity=Vector3.zero
            end
        end
    end

    local function updateSpeed()
        local char,hum,hrp=app:Character()
        if not (char and hum and hrp) then return end
        if state.speedHumanoid~=hum then
            restoreSpeed()
            state.speedHumanoid=hum
            state.speedBackup=hum.WalkSpeed
        end
        hum.WalkSpeed=Config.SpeedValue
        local dir=hum.MoveDirection
        if dir.Magnitude<=0 then return end
        local now=tick()
        if state.pulse=="idle" then state.pulse="boost";state.pulseAt=now end
        local boosting
        if state.pulse=="boost" then
            if now-state.pulseAt>=0.1 then state.pulse="coast";state.pulseAt=now;boosting=false
            else boosting=true end
        else
            if now-state.pulseAt>=0.15 then state.pulse="boost";state.pulseAt=now;boosting=true
            else boosting=false end
        end
        local target=dir.Unit*(boosting and Config.SpeedValue or Config.SpeedValue*0.16)
        hrp.AssemblyLinearVelocity=Vector3.new(target.X,hrp.AssemblyLinearVelocity.Y,target.Z)
    end

    local function updateNoclip(dt)
        state.noclipAccum=(state.noclipAccum or 0)+(dt or 0)
        if state.noclipAccum<0.05 then return end
        state.noclipAccum=0
        local char=app.Character and select(1,app:Character())
        if not char then
            local c=LocalPlayer.Character
            char=c
        end
        if not char then return end
        for _,part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if state.collisionBackup[part]==nil then state.collisionBackup[part]=part.CanCollide end
                part.CanCollide=false
            end
        end
    end

    -- Mobile touch-fly assist: right-half drag drives camera-relative motion.
    -- Single-finger X strafes, single-finger Y moves forward/back, two-finger
    -- vertical lifts. Release stops assist writes and keeps current momentum
    -- (no automatic braking). Runs on the same Heartbeat cadence as the rest
    -- of movement; never throttled by the visual interval.
    local function updateTouchFly()
        local touch=app.Touch
        if not (touch and touch.Enabled and touch.Held) then
            -- Released or disabled: only the input deltas reset. Any velocity
            -- already written stays; the assist never brakes the character.
            state.lastDragX=0
            state.lastDragY=0
            state.lastVertical=0
            return
        end
        local ok,drag,vertical=pcall(function() return touch:Drag() end)
        if not ok or not drag then
            state.lastDragX=0
            state.lastDragY=0
            state.lastVertical=0
            return
        end
        local dx=drag.X-state.lastDragX
        local dy=drag.Y-state.lastDragY
        local dv=(tonumber(vertical) or 0)-state.lastVertical
        state.lastDragX=drag.X
        state.lastDragY=drag.Y
        state.lastVertical=vertical or 0
        local _,_,hrp=app:Character()
        if not hrp then return end
        local camera=Workspace.CurrentCamera
        local cf=camera and camera.CFrame
        local vel=hrp.AssemblyLinearVelocity
        local hx,hz=vel.X,vel.Z
        if dx~=0 and cf then
            local rx,rz=cf.RightVector.X,cf.RightVector.Z
            local mag=math.sqrt(rx*rx+rz*rz)
            if mag>0.0001 then
                local scale=math.clamp(dx/8,-1,1)*Config.TouchFlySpeed
                hx,hz=(rx/mag)*scale,(rz/mag)*scale
            end
        end
        if dy~=0 and cf then
            -- Forward/back along the flattened camera LookVector. Downward
            -- drag (positive deltaY in screen space) moves backward.
            local lx,lz=cf.LookVector.X,cf.LookVector.Z
            local mag=math.sqrt(lx*lx+lz*lz)
            if mag>0.0001 then
                local scale=-math.clamp(dy/8,-1,1)*Config.TouchFlySpeed
                hx,hz=hx+(lx/mag)*scale,hz+(lz/mag)*scale
            end
        end
        local vy=vel.Y
        if dv~=0 then
            vy=math.clamp(dv/8,-1,1)*Config.TouchFlySpeed
        end
        hrp.AssemblyLinearVelocity=Vector3.new(hx,vy,hz)
    end

    local function teleportLobby()
        local Remotes=app.Remotes
        if Remotes.GET then
            local ok=pcall(function()
                Remotes.GET:InvokeServer("Functions","Teleport","Lobby")
            end)
            if ok then return true end
        end
        local TeleportService=game:GetService("TeleportService")
        pcall(function()
            TeleportService:Teleport(game.PlaceId,LocalPlayer)
        end)
        return false
    end
    Movement.TeleportLobby=teleportLobby

    if LocalPlayer.CharacterRemoving then
        app:Track(LocalPlayer.CharacterRemoving:Connect(function()
            restoreSpeed()
            restoreCollision()
        end))
    end
    if LocalPlayer.CharacterAdded then
        app:Track(LocalPlayer.CharacterAdded:Connect(function()
            restoreSpeed()
            restoreCollision()
        end))
    end

    local function antiAFK()
        local VirtualUser=game:GetService("VirtualUser")
        app:Track(LocalPlayer.Idled:Connect(function()
            if not Config.AntiAFK then return end
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0,0),Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0),Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
            end)
        end))
    end
    antiAFK()

    -- Heartbeat loop: velocity writes must land before the physics solver.
    app:Track(RunService.Heartbeat:Connect(function(dt)
        if not app:Alive() then return end
        app.Guard("Movement",function()
            if Config.FollowEnabled then updateFollow(dt) end
            if Config.SpeedEnabled then updateSpeed() else restoreSpeed() end
            if Config.Noclip then updateNoclip(dt) else restoreCollision() end
            if Config.TouchAssist then updateTouchFly() end
        end)
    end))

    app:OnStop(function()
        Config.FollowEnabled=false
        Config.SpeedEnabled=false
        Config.Noclip=false
        Config.TouchAssist=false
        state.lastDragX=0
        state.lastDragY=0
        state.lastVertical=0
        restoreSpeed()
        restoreCollision()
    end)

    return Movement
end

end)()
local AOTRESPFactory = (function()
-- Vortexion AOTR ESP: per-titan billboard tags and nape highlights.
--
-- Tags live in one cloaked ScreenGui (gethui/CoreGui) with Adornee pointing at
-- each titan nape: parenting them into the titan model would expose them to
-- workspace enumeration, and a name like "TitanESP" is a one-line scan hit.
-- Refresh runs at 10Hz with entry reuse; dead/despawned titans drop their tag.
return function(app)
    local Players=app.Services.Players
    local Workspace=app.Services.Workspace
    local LocalPlayer=Players.LocalPlayer
    local ESP={}

    local Config={
        Enabled=false,
        Tags=true,
        Health=true,
        Distance=true,
        NapeHighlight=false,
        MaxDistance=1200,
        BossColor=Color3.fromRGB(255,80,80),
        NormalColor=Color3.fromRGB(255,200,90),
    }
    ESP.Config=Config

    local state={screenGui=nil,entries={},accum=0,disposed=false}

    local function ensureGui()
        if state.screenGui and state.screenGui.Parent then return state.screenGui end
        if state.screenGui then
            pcall(function() state.screenGui:Destroy() end)
            state.screenGui=nil
        end
        local parent=app.GetGuiParent()
        if not parent then return nil end
        local raw=Instance.new("ScreenGui")
        local ok,result=pcall(function()
            raw.Name=app.RandomName()
            raw.ResetOnSpawn=false
            raw.DisplayOrder=990
            raw.Parent=parent
            return app.Cloak and app.Cloak.Protect(raw) or raw
        end)
        if not ok then
            pcall(function() raw:Destroy() end)
            error(result,0)
        end
        state.screenGui=result
        return result
    end

    local function buildEntry(entry)
        local gui=ensureGui()
        if not gui then return nil end
        local created={}
        local function allocate(class)
            local object=Instance.new(class)
            table.insert(created,object)
            return object
        end
        -- Own every allocation before setting properties; failed setup rolls back.
        local ok,result=pcall(function()
            local billboard=allocate("BillboardGui")
            billboard.Name=app.RandomName()
            billboard.Adornee=entry.nape
            billboard.Size=UDim2.fromOffset(160,44)
            billboard.StudsOffset=Vector3.new(0,4,0)
            billboard.AlwaysOnTop=true
            billboard.MaxDistance=Config.MaxDistance
            local nameLabel=allocate("TextLabel")
            nameLabel.Name="Name"
            nameLabel.BackgroundTransparency=1
            nameLabel.Size=UDim2.new(1,0,0,16)
            nameLabel.Font=Enum.Font.GothamBold
            nameLabel.TextSize=13
            nameLabel.TextStrokeTransparency=0.4
            nameLabel.Text=entry.model.Name
            nameLabel.Parent=billboard
            local sub=allocate("TextLabel")
            sub.Name="Sub"
            sub.BackgroundTransparency=1
            sub.Position=UDim2.new(0,0,0,16)
            sub.Size=UDim2.new(1,0,0,14)
            sub.Font=Enum.Font.Gotham
            sub.TextSize=12
            sub.TextStrokeTransparency=0.5
            sub.Parent=billboard
            local barBack=allocate("Frame")
            barBack.Name="BarBack"
            barBack.Position=UDim2.new(0,0,0,30)
            barBack.Size=UDim2.new(1,0,0,4)
            barBack.BackgroundColor3=Color3.fromRGB(20,20,20)
            barBack.BorderSizePixel=0
            barBack.Parent=billboard
            local barFill=allocate("Frame")
            barFill.Name="BarFill"
            barFill.Size=UDim2.fromScale(1,1)
            barFill.BackgroundColor3=Color3.fromRGB(90,220,110)
            barFill.BorderSizePixel=0
            barFill.Parent=barBack
            billboard.Parent=gui
            if app.Cloak then billboard=app.Cloak.Protect(billboard) end

            local record={billboard=billboard,nameLabel=nameLabel,subLabel=sub,barBack=barBack,barFill=barFill,highlight=nil,cache={}}
            return record
        end)
        if not ok then
            for i=#created,1,-1 do pcall(function() created[i]:Destroy() end) end
            error(result,0)
        end
        return result
    end

    local function destroyEntry(record)
        local owned={}
        for _,key in ipairs({"nameLabel","subLabel","barFill","barBack","highlight","billboard"}) do
            if record[key] then table.insert(owned,record[key]) end
            record[key]=nil
        end
        record.cache={}
        for _,object in ipairs(owned) do pcall(function() object:Destroy() end) end
    end

    local function validEntry(record)
        if not record then return false end
        local ok,valid=pcall(function()
            return record.billboard and record.billboard.Parent==state.screenGui
                and record.nameLabel and record.nameLabel.Parent==record.billboard
                and record.subLabel and record.subLabel.Parent==record.billboard
                and record.barBack and record.barBack.Parent==record.billboard
                and record.barFill and record.barFill.Parent==record.barBack
        end)
        return ok and valid==true
    end

    local function clearAll()
        for _,record in pairs(state.entries) do destroyEntry(record) end
        state.entries={}
    end

    local function syncHighlight(record,entry,color)
        if not Config.NapeHighlight then
            if record.highlight then record.highlight:Destroy();record.highlight=nil end
            return
        end
        if not record.highlight or not record.highlight.Parent then
            if record.highlight then record.highlight:Destroy();record.highlight=nil end
            local raw=Instance.new("Highlight")
            local ok,result=pcall(function()
                raw.Name=app.RandomName()
                raw.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                raw.FillTransparency=0.7
                raw.OutlineTransparency=0
                raw.Parent=state.screenGui
                return app.Cloak and app.Cloak.Protect(raw) or raw
            end)
            if not ok then
                pcall(function() raw:Destroy() end)
                error(result,0)
            end
            record.highlight=result
        end
        record.highlight.Adornee=entry.model
        record.highlight.FillColor=color
        record.highlight.OutlineColor=color
    end

    local function updateESP()
        local Titans=app.Titans
        if not Titans then clearAll();return end
        local entries=Titans:All()
        if #entries==0 then clearAll();return end
        if not ensureGui() then clearAll();return end
        local hrp
        local char,_,root=app:Character()
        if root then hrp=root end
        local seen={}
        for _,entry in ipairs(entries) do
            if entry.nape and entry.nape.Parent then
                seen[entry.model]=true
                local record=state.entries[entry.model]
                if not validEntry(record) then
                    if record then destroyEntry(record) end
                    record=buildEntry(entry)
                    state.entries[entry.model]=record
                end
                if record then
                    local cache=record.cache
                    local color=entry.boss and Config.BossColor or Config.NormalColor
                    if cache.nape~=entry.nape then
                        cache.nape=entry.nape
                        record.billboard.Adornee=entry.nape
                    end
                    if cache.maxDist~=Config.MaxDistance then
                        cache.maxDist=Config.MaxDistance
                        record.billboard.MaxDistance=Config.MaxDistance
                    end
                    if cache.nameText~=entry.model.Name then
                        cache.nameText=entry.model.Name
                        record.nameLabel.Text=entry.model.Name
                    end
                    if cache.tagsVis~=Config.Tags then
                        cache.tagsVis=Config.Tags
                        record.nameLabel.Visible=Config.Tags
                    end
                    if cache.boss~=entry.boss then
                        cache.boss=entry.boss
                        record.nameLabel.TextColor3=color
                    end
                    if Config.Distance and hrp then
                        local d=math.floor((entry.nape.Position-hrp.Position).Magnitude)
                        local text=("%d studs"):format(d)
                        if cache.distText~=text then
                            cache.distText=text
                            record.subLabel.Text=text
                        end
                        if not record.subLabel.Visible then record.subLabel.Visible=true end
                    else
                        if record.subLabel.Visible then record.subLabel.Visible=false end
                    end
                    if Config.Health and entry.humanoid then
                        local maxH=math.max(entry.humanoid.MaxHealth,1)
                        local frac=math.clamp(entry.humanoid.Health/maxH,0,1)
                        if cache.frac~=frac then
                            cache.frac=frac
                            record.barFill.Size=UDim2.fromScale(frac,1)
                            record.barFill.BackgroundColor3=Color3.fromRGB(220,60,60):Lerp(Color3.fromRGB(90,220,110),frac)
                        end
                        if not record.barFill.Parent.Visible then record.barFill.Parent.Visible=true end
                    else
                        if record.barFill.Parent.Visible then record.barFill.Parent.Visible=false end
                    end
                    local enabled=Config.Tags or record.subLabel.Visible or record.barFill.Parent.Visible
                    if cache.enabled~=enabled then
                        cache.enabled=enabled
                        record.billboard.Enabled=enabled
                    end
                    syncHighlight(record,entry,color)
                end
            end
        end
        for model,record in pairs(state.entries) do
            if not seen[model] then
                destroyEntry(record)
                state.entries[model]=nil
            end
        end
    end

    local function visualInterval(base)
        base=tonumber(base) or 0.1
        if base~=base or base==math.huge or base==-math.huge or base<=0 then base=0.1 end
        local function accept(v)
            return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge and v>0
        end
        if type(app.GetVisualInterval)=="function" then
            local ok,value=pcall(app.GetVisualInterval,app,base)
            if ok and accept(value) then return math.max(base,value) end
            return base
        end
        local ui=app.ui
        if ui and type(ui.GetVisualInterval)=="function" then
            local ok,value=pcall(function() return ui:GetVisualInterval(base) end)
            if ok and accept(value) then return math.max(base,value) end
        end
        return base
    end

    function ESP:Update(dt)
        if state.disposed then return end
        if not Config.Enabled then
            state.accum=0
            clearAll()
            return
        end
        -- Losing the local character must drop stale distance text immediately,
        -- independent of the (possibly throttled) visual cadence.
        if next(state.entries)~=nil then
            local _,_,root=app:Character()
            if not root then
                for _,record in pairs(state.entries) do
                    if record.subLabel.Visible then record.subLabel.Visible=false end
                end
            end
        end
        state.accum+=dt
        if state.accum<visualInterval(0.1) then return end
        state.accum=0
        app.Guard("ESP",updateESP)
    end

    function ESP:Stop()
        state.accum=0
        clearAll()
        if state.screenGui then
            pcall(function() state.screenGui:Destroy() end)
            state.screenGui=nil
        end
        Config.Enabled=false
    end

    app:OnStop(function()
        state.disposed=true
        ESP:Stop()
    end)

    return ESP
end

end)()
local AOTRFarmFactory = (function()
-- Vortexion R223 AOTR resource automation.
-- No claim of successful resupply is made until an observable state changes.
-- GET/POST are game protocol candidates documented by independent public implementations.
return function(app)
    local Players=app.Services.Players
    local Workspace=app.Services.Workspace
    local player=Players.LocalPlayer
    local Farm={}
    local Config={
        AutoReload=false,
        AutoRefill=false,
        CheckInterval=0.5,
        GasThreshold=35,
        RefillCooldown=3.0,
        ReloadCooldown=1.8,
        FPSSettings=false,
        Settings={Damage_Indicator="Off",Shadows="Off",Blur="Off",Player_Effects="Off",Effects=0,Music=0},
    }
    Farm.Config=Config

    local state={
        reloads=0, reloadAttempts=0, reloadVerified=0, reloadStatus="idle",
        refills=0, refillAttempts=0, refillVerified=0, denied=0,
        lastRefillStatus="idle", lastRefillDistance=nil,
        lastRefillAt=-math.huge, lastReloadAt=-math.huge,
        refillPart=nil, lastStationScan=-math.huge, candidates={},
        pending=nil, reloadPending=nil, settingsApplied=false,
        lastWeapon="unknown", lastRead={}, lastRemoteProbe=-math.huge,
        channelSwitches=0, manual=false,
    }
    local function now() return os.clock() end
    local function safeName(v)
        if not v then return "-" end
        local ok,n=pcall(function() return v:GetFullName() end)
        return ok and n or tostring(v.Name or "?")
    end
    local function aliveRoot()
        local char=player and player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not root or (hum and hum.Health<=0) then return nil end
        return root
    end
    local function readHUD(force)
        app.ProbeHUD(force==true)
        local hud=app.HUD
        local b,bMax=app.ReadCount(hud.blades)
        local s,sMax=app.ReadCount(hud.spears)
        local gas=app.ReadPercent(hud.gas)
        return {blades=b,bladesMax=bMax,spears=s,spearsMax=sMax,gas=gas}
    end
    local function weaponType()
        local weapon
        pcall(function() weapon=player:GetAttribute("Weapon") end)
        if type(weapon)=="string" then
            if string.find(string.lower(weapon),"blade",1,true) then return "Blades" end
            if string.find(string.lower(weapon),"spear",1,true) then return "Spears" end
        end
        local gui=player and player:FindFirstChild("PlayerGui")
        local frame=gui and gui:FindFirstChild("Interface")
        frame=frame and frame:FindFirstChild("HUD")
        frame=frame and frame:FindFirstChild("Main")
        frame=frame and frame:FindFirstChild("Top")
        frame=frame and frame:FindFirstChild("7")
        if frame then
            local blades=frame:FindFirstChild("Blades")
            local spears=frame:FindFirstChild("Spears")
            if blades and blades.Visible then return "Blades" end
            if spears and spears.Visible then return "Spears" end
        end
        return "unknown"
    end
    local function bladeMissing()
        local char=player and player.Character
        local rig=char and char:FindFirstChild("Rig_" .. player.Name)
        if not rig then return nil end
        local parts={}
        for _,side in ipairs({"LeftHand","RightHand"}) do
            local hand=rig:FindFirstChild(side)
            if hand then
                for _,child in ipairs(hand:GetChildren()) do
                    if child:IsA("BasePart") and string.find(child.Name,"Blade_",1,true)==1 then
                        parts[#parts+1]=child
                    end
                end
            end
        end
        if #parts==0 then return nil end
        for _,blade in ipairs(parts) do
            if blade.Transparency<0.9 and blade:GetAttribute("Broken")~=true then
                return false
            end
        end
        return true
    end
    local function findRemotes()
        local remotes=app.Remotes
        if not remotes then return nil,nil end
        if (not remotes.GET or not remotes.POST) and now()-state.lastRemoteProbe>=2 then
            state.lastRemoteProbe=now()
            app.ProbeRemotes()
        end
        if remotes.GET and not remotes.GET:IsA("RemoteFunction") then remotes.GET=nil end
        if remotes.POST and not remotes.POST:IsA("RemoteEvent") then remotes.POST=nil end
        return remotes.GET,remotes.POST
    end
    -- Map data is dynamic. Build the cache infrequently and re-check Instance ancestry.
    local function scanStations()
        local roots={}
        local waves=Workspace:FindFirstChild("Waves")
        local climbable=Workspace:FindFirstChild("Climbable")
        local unclimbable=Workspace:FindFirstChild("Unclimbable")
        if waves then roots[#roots+1]=waves end
        if climbable then roots[#roots+1]=climbable end
        if unclimbable then roots[#roots+1]=unclimbable end
        local stations,seen={},{}
        local function take(node)
            if not node or not node:IsA("BasePart") or seen[node] then return end
            seen[node]=true
            stations[#stations+1]=node
        end
        for _,root in ipairs(roots) do
            -- Waves maps frequently put the usable part under Zones.Refill.Hitbox.
            for _,node in ipairs(root:GetDescendants()) do
                if node:IsA("BasePart") then
                    if node.Name=="Refill" then
                        take(node)
                    elseif node.Name=="Hitbox" and node.Parent and
                        (node.Parent.Name=="Refill" or node.Parent.Name=="Gas") then
                        take(node)
                    elseif (node.Name=="Gas" or node.Name=="Refill") and
                        node.Parent and node.Parent.Name=="Props" then
                        take(node)
                    end
                end
            end
        end
        state.candidates=stations
        state.lastStationScan=now()
        return stations
    end
    local function resolveRefill(force)
        local root=aliveRoot()
        if not root then return nil end
        if force or now()-state.lastStationScan>5 then scanStations() end
        local best,dist=nil,math.huge
        for _,part in ipairs(state.candidates) do
            if part.Parent then
                local d=(part.Position-root.Position).Magnitude
                if d<dist then best,dist=part,d end
            end
        end
        state.refillPart=best
        state.lastRefillDistance=best and dist or nil
        return best
    end
    Farm.ResolveRefill=resolveRefill

    local function changed(before,after,reason)
        if not before or not after then return false end
        -- Confirm the requested resource, not an unrelated gauge increasing.
        local key=reason=="blades" and "blades" or reason=="spears" and "spears" or "gas"
        return type(before[key])=="number" and type(after[key])=="number"
            and after[key]>before[key]
    end
    local function observe()
        if state.reloadPending then
            local p=state.reloadPending
            local missing=bladeMissing()
            if missing==false then
                state.reloadVerified+=1
                state.reloadStatus="equipped blade confirmed"
                state.reloadPending=nil
            elseif now()-p.at>3 then
                state.reloadStatus="GET returned; blade equip not confirmed"
                state.reloadPending=nil
            end
        end
        if not state.pending then return end
        local p=state.pending
        local after=readHUD(true)
        local root=aliveRoot()
        local moved=root and p.origin and (root.Position-p.origin).Magnitude>25
        if changed(p.before,after,p.reason) then
            state.refillVerified+=1
            state.lastRefillStatus="confirmed by HUD ("..p.channel..")"
            state.pending=nil
            state.channelSwitches=0
        elseif now()-p.at>=3.0 then
            state.denied+=1
            state.channelSwitches+=1
            state.lastRefillStatus=(moved and "station relocation; HUD unchanged" or
                "server unconfirmed ("..p.channel..", HUD unchanged)")
            state.pending=nil
        end
    end
    local function doReload(view,weapon)
        if not Config.AutoReload or weapon~="Blades" then return false end
        if state.reloadPending or now()-state.lastReloadAt<Config.ReloadCooldown then return false end
        local missing=bladeMissing()
        if missing==nil then state.reloadStatus="blade rig unavailable"; return false end
        if not missing then state.reloadStatus="blades equipped"; return false end
        if view.blades==nil then state.reloadStatus="blade reserve HUD missing"; return false end
        if view.blades<=0 then state.reloadStatus="reserves empty; refill needed"; return false end
        local GET=findRemotes()
        if not GET then state.reloadStatus="GET missing (retrying discovery)"; return false end
        state.reloadAttempts+=1
        state.lastReloadAt=now()
        local ok,result=pcall(function() return GET:InvokeServer("Blades","Reload") end)
        if ok then
            state.reloads+=1
            state.reloadPending={at=now()}
            state.reloadStatus="equip requested; awaiting blade model"
        else
            state.reloadStatus="GET rejected: "..tostring(result):sub(1,105)
        end
        return ok
    end
    local function needRefill(view,weapon)
        -- Refilling reserves and equipping a held blade are two separate actions.
        if weapon=="Blades" then
            if type(view.blades)=="number" and view.blades<=0 then return true,"blades" end
        elseif weapon=="Spears" then
            if type(view.spears)=="number" and view.spears<=0 then return true,"spears" end
        end
        if type(view.gas)=="number" and view.gas<=Config.GasThreshold then return true,"gas" end
        return false,"healthy or HUD unavailable"
    end
    local function doRefill(view,weapon,manual)
        if state.pending or now()-state.lastRefillAt<Config.RefillCooldown then return false end
        local needs,reason=needRefill(view,weapon)
        if not needs and not manual then
            state.lastRefillStatus=reason
            return false
        end
        local part=resolveRefill(false)
        if not part then
            state.lastRefillStatus="station not found (scan needed)"
            return false
        end
        local GET,POST=findRemotes()
        if not GET and not POST then
            state.lastRefillStatus="GET/POST missing (retrying discovery)"
            return false
        end
        -- Public implementations use both variants; for blades prefer GET,
        -- for spears / gas prefer POST. A failed confirmation changes preference
        -- for the next attempt, and no second request is fired simultaneously.
        local preferGET=weapon=="Blades" and reason=="blades"
        if state.channelSwitches%2==1 then preferGET=not preferGET end
        local channel,remote
        if preferGET then channel,remote="GET",GET or POST else channel,remote="POST",POST or GET end
        if remote==POST then channel="POST" else channel="GET" end
        local root=aliveRoot()
        if not root then state.lastRefillStatus="character not ready"; return false end
        local origin=root.Position
        state.lastRefillAt=now()
        state.refillAttempts+=1
        local ok,err=pcall(function()
            if channel=="GET" then
                remote:InvokeServer("Attacks","Reload",part)
            else
                remote:FireServer("Attacks","Reload",part)
            end
        end)
        if ok then
            state.refills+=1 -- request sent, not verified
            state.pending={at=now(),before=view,origin=origin,channel=channel,reason=reason}
            state.lastRefillStatus="requested "..reason.." via "..channel.."; verifying"
        else
            state.denied+=1
            state.channelSwitches+=1
            state.lastRefillStatus="remote "..channel.." failed: "..tostring(err):sub(1,95)
        end
        return ok
    end
    function Farm:ManualRefill()
        if state.pending then return false end
        local view=readHUD(true)
        local weapon=weaponType()
        state.lastWeapon=weapon
        return doRefill(view,weapon,true)
    end
    function Farm:RefreshStation()
        local part=resolveRefill(true)
        return part~=nil
    end

    local function applySettings()
        if state.settingsApplied then return end
        local GET=findRemotes()
        if not GET then return end
        local ok=pcall(function()
            for key,value in pairs(Config.Settings) do
                GET:InvokeServer("Functions","Settings",key,value)
                task.wait(0.05)
            end
        end)
        state.settingsApplied=ok
    end
    local elapsed=0
    function Farm:Update(dt)
        if Config.FPSSettings and not state.settingsApplied then app.Guard("Farm.Settings",applySettings) end
        if not Config.AutoReload and not Config.AutoRefill and not state.pending and not state.reloadPending then return end
        elapsed+=math.min(tonumber(dt) or 0.25,0.5)
        if elapsed<Config.CheckInterval then return end
        elapsed=0
        local root=aliveRoot()
        if not root then
            state.reloadStatus="character not ready"
            state.lastRefillStatus="character not ready"
            return
        end
        local view=readHUD(false)
        local weapon=weaponType()
        state.lastRead=view
        state.lastWeapon=weapon
        app.Guard("Farm.Observe",observe)
        if Config.AutoReload then app.Guard("Farm.Reload",doReload,view,weapon) end
        if Config.AutoRefill then app.Guard("Farm.Refill",doRefill,view,weapon,false) end
    end
    function Farm:DebugSnapshot()
        return {
            reloads=state.reloads,reloadAttempts=state.reloadAttempts,
            reloadVerified=state.reloadVerified,reloadStatus=state.reloadStatus,
            refills=state.refills, attempts=state.refillAttempts,
            refillVerified=state.refillVerified,
            refill=state.refillPart and state.refillPart.Parent~=nil or false,
            station=safeName(state.refillPart), stations=#state.candidates,
            status=state.lastRefillStatus,distance=state.lastRefillDistance,
            unconfirmed=state.denied,weapon=state.lastWeapon,
            blades=state.lastRead.blades,spears=state.lastRead.spears,gas=state.lastRead.gas,
            GET=app.Remotes.GET~=nil,POST=app.Remotes.POST~=nil,
        }
    end
    app:OnStop(function()
        Config.AutoReload=false
        Config.AutoRefill=false
        state.pending=nil
        state.reloadPending=nil
    end)
    return Farm
end

end)()
-- AOTR battle: full combat suite (nape lock, remote registration, spears,
-- hitbox, follow, ESP, farm) wired through one budgeted render loop.
local app=AOTRCommon("battle",WindUI,WindBridgeFactory)
if not app then return end
local window=app:Open()
if not window then return end

--=========================================================================
-- Environment probe before features: remotes, HUD labels, executor caps.
--=========================================================================
-- Remote probe is nonessential for initial window creation.
task.defer(function() if app:Alive() then app:ProbeRemotes() end end)
-- HUD discovery is deferred until the user requests readouts or farm needs it.
local bootFailures = {}
local function reportBootFailure(name, message)
    local detail = tostring(name) .. ": " .. tostring(message):sub(1, 160)
    table.insert(bootFailures, detail)
    if app.ui then
        app.ui.BootStatus = "partial"
        app.ui.BootError = table.concat(bootFailures, "; ")
    end
    warn("[Vortexion/AOTR] " .. detail)
end
-- R2.5: Do not install a global __namecall hook during battle startup.
-- Such hooks cannot be safely uninstalled on every Android executor and can
-- disrupt the game's own method dispatch. ESP degrades to ordinary instances.
app.Cloak = { Protect = function(instance) return instance end }

local tabs={
    combat=window:AddTab({Title="战斗",Icon="lucide-swords"}),
    visual=window:AddTab({Title="感知",Icon="lucide-eye"}),
    movement=window:AddTab({Title="移动",Icon="lucide-activity"}),
    farm=window:AddTab({Title="农场",Icon="lucide-package"}),
    settings=window:AddTab({Title="设置",Icon="lucide-settings"}),
}
window:InstallSettings(tabs.settings)

local function setup(name,factory,key)
    if type(factory)~="function" then
        reportBootFailure(name, "factory missing")
        return nil
    end
    local ok,result=pcall(factory,app)
    if not ok then
        reportBootFailure(name, result)
        app:Notify(name.." 模块失败: "..tostring(result))
        return nil
    end
    if key then app[key]=result end
    return result
end

setup("titans",AOTRTitansFactory,"Titans")
setup("combat",AOTRCombatFactory,"Combat")
setup("movement",AOTRMovementFactory,"Movement")
setup("esp",AOTRESPFactory,"ESP")
setup("farm",AOTRFarmFactory,"Farm")

local Titans,Combat,Movement,ESP,Farm=app.Titans,app.Combat,app.Movement,app.ESP,app.Farm
if app.ui and type(app.ui.RegisterFeatureHealth) == "function" then
    app.ui:RegisterFeatureHealth("AOTR 战斗", function()
        return ("存活=%s 巨人池=%s 战斗=%s 移动=%s 感知=%s 农场=%s 子模块错误=%d")
            :format(tostring(app:Alive()), tostring(Titans ~= nil), tostring(Combat ~= nil),
                tostring(Movement ~= nil), tostring(ESP ~= nil), tostring(Farm ~= nil), #bootFailures)
    end)
end


--=========================================================================
-- Shared render loop: one BindToRenderStep(Last), dt gate, per-subsystem
-- budget, 2s debug snapshot. Movement runs on Heartbeat inside its module.
--=========================================================================
local budgets={Titans=0.4,Combat=1.5,ESP=1.0,Farm=0.2}
local costs={Titans=0,Combat=0,ESP=0,Farm=0}
local slowLoops=0
local throttled = {Titans=0, ESP=0}
-- Resource automation cannot depend on a rendered frame being produced.
-- The worker stays alive if the game disables 3D rendering or the UI is closed.
local farmTime=0
if Farm then
    app:Track(app.Services.RunService.Heartbeat:Connect(function(dt)
        if not app:Alive() then return end
        farmTime+=math.min(dt,0.25)
        if farmTime<0.25 or farmBusy then return end
        local slice=farmTime
        farmTime=0
        farmBusy=true
        task.spawn(function()
            local t0=tick()
            if app:Alive() then app.Guard("FarmWorker",function() Farm:Update(slice) end) end
            costs.Farm=tick()-t0
            farmBusy=false
        end)
    end))
end
local farmBusy = false
app:OnStop(function()
    app.Services.RunService:UnbindFromRenderStep("VortexionAOTRFrame")
end)
app.Services.RunService:BindToRenderStep("VortexionAOTRFrame",Enum.RenderPriority.Last.Value,function(dt)
    if not app:Alive() then return end
    app.Guard("Frame",function()
        if dt<0.004 then return end
        local combatOn = Combat and (Combat.Config.Enabled or Combat.Config.HitboxEnabled)
        local espOn = ESP and ESP.Config.Enabled
        local movementOn = Movement and Movement.Config.FollowEnabled
        if not (combatOn or espOn or movementOn or (Farm and (Farm.Config.AutoReload or Farm.Config.AutoRefill))) then return end
        throttled.Titans = throttled.Titans + math.min(dt, 0.2)
        throttled.ESP = throttled.ESP + math.min(dt, 0.2)
        if Titans and throttled.Titans >= 0.10 then
            throttled.Titans = 0
            local t0=tick()
            app.Guard("Titans",function() Titans:Update(dt) end)
            costs.Titans=tick()-t0
        end
        if Combat then
            local t0=tick()
            app.Guard("Combat",function() Combat:Update(dt) end)
            costs.Combat=tick()-t0
        end
        if ESP and throttled.ESP >= 0.05 then
            throttled.ESP = 0
            local t0=tick()
            app.Guard("ESP",function() ESP:Update(dt) end)
            costs.ESP=tick()-t0
        end
        for name,cost in pairs(costs) do
            if cost*1000>budgets[name] then slowLoops+=1 end
        end
    end)
end)

task.spawn(function()
    while app:Alive() do
        task.wait(2)
        if not app:Alive() then break end
        if app.Debug then
            local combat=Combat and Combat:DebugSnapshot() or {}
            local titans=Titans and Titans:DebugSnapshot() or {}
            local farm=Farm and Farm:DebugSnapshot() or {}
            local remotes=app.Remotes
            print(("[Vortexion/AOTR] titans=%d nape=%d lock=%s dist=%s atk=%d wpn=%s reload=%d refill=%d | %.2f/%.2f/%.2f/%.2fms slow=%d GET=%s POST=%s"):format(
                titans.titans or 0,titans.nape or 0,
                tostring(combat.locked or "-"),tostring(combat.dist or 0),
                tonumber(combat.attacks) or 0,tostring(combat.weapon or "-"),
                tonumber(farm.reloads) or 0,tonumber(farm.refills) or 0,
                costs.Titans*1000,costs.Combat*1000,costs.ESP*1000,costs.Farm*1000,
                slowLoops,
                tostring(remotes.GET~=nil),tostring(remotes.POST~=nil)))
        end
    end
end)

--=========================================================================
-- UI: combat.
--=========================================================================
if Combat then
    local c=Combat.Config
    local tab=tabs.combat
    tab:AddToggle("AOTRAimEnabled",{Title="斩击锁定（自动注册命中）",Default=false,Callback=function(v)
        c.Enabled=v
        app.Log("combat enabled=%s",tostring(v))
    end})
    tab:AddDropdown("AOTRTargetMode",{Title="目标选择",Values={"Nearest","Boss"},Default="Nearest",
        Callback=function(v) c.TargetMode=v end})
    tab:AddDropdown("AOTRAimMode",{Title="瞄准模式",Values={"Camera","Mouse","Both"},Default="Camera",
        Callback=function(v) c.Mode=v end})
    tab:AddSlider("AOTRAimFov",{Title="锁定 FOV",Min=40,Max=600,Default=160,Rounding=0,
        Callback=function(v) c.FOV=v end})
    tab:AddSlider("AOTRAimDist",{Title="锁定距离",Min=100,Max=3000,Default=1200,Rounding=0,
        Callback=function(v) c.MaxDistance=v end})
    tab:AddSlider("AOTRAimSmooth",{Title="平滑（越小越快）",Min=0.05,Max=0.95,Default=0.85,Rounding=2,
        Callback=function(v) c.Smoothness=v end})
    tab:AddSlider("AOTRAimPrediction",{Title="预瞄（浮动补偿）",Min=0,Max=0.5,Default=0.12,Rounding=2,
        Callback=function(v) c.Prediction=v end})
    tab:AddSlider("AOTRAimHitChance",{Title="注册命中率（%）",Min=10,Max=100,Default=100,Rounding=0,
        Callback=function(v) c.HitChance=v/100 end})
    tab:AddDropdown("AOTRAimKey",{Title="触发键",Values={"Always","Hold"},Default="Always",
        Callback=function(v) c.TriggerKey=v end})
    tab:AddSlider("AOTRAttackCd",{Title="攻击间隔（秒）",Min=0.08,Max=1.5,Default=0.25,Rounding=2,
        Callback=function(v) c.AttackCooldown=v end})
    tab:AddSlider("AOTRAttackJitter",{Title="节奏抖动（±）",Min=0,Max=0.8,Default=0.05,Rounding=2,
        Callback=function(v) c.CooldownJitter=v end})
    tab:AddDropdown("AOTRWeapon",{Title="武器",Values={"Auto","Blades","Spears"},Default="Auto",
        Callback=function(v) c.Weapon=v end})
    tab:AddSlider("AOTRDmgMin",{Title="伤害下限",Min=100,Max=2000,Default=625,Rounding=0,
        Callback=function(v) c.DamageMin=v end})
    tab:AddSlider("AOTRDmgMax",{Title="伤害上限",Min=100,Max=2000,Default=850,Rounding=0,
        Callback=function(v) c.DamageMax=v end})
    tab:AddSlider("AOTRCritChance",{Title="暴击概率（%）",Min=0,Max=100,Default=25,Rounding=0,
        Callback=function(v) c.CritChance=v/100 end})
    tab:AddToggle("AOTRComboCycle",{Title="连击序号循环",Default=true,
        Callback=function(v) c.ComboCycle=v end})
    tab:AddSlider("AOTRSpearBurst",{Title="雷枪连发（Boss）",Min=1,Max=60,Default=30,Rounding=0,
        Callback=function(v) c.SpearBurst=v end})
    tab:AddToggle("AOTRHitboxEnabled",{Title="后颈碰撞箱放大",Default=false,
        Callback=function(v) c.HitboxEnabled=v end})
    tab:AddSlider("AOTRHitboxSize",{Title="碰撞箱倍率",Min=1.1,Max=4,Default=1.6,Rounding=1,
        Callback=function(v) c.HitboxSize=v end})
    tab:AddToggle("AOTRFovCircle",{Title="FOV 圆圈",Default=true,
        Callback=function(v) c.FOVCircle=v end})
end

--=========================================================================
-- UI: visual (ESP) + preserved awareness readouts.
--=========================================================================
if ESP then
    local c=ESP.Config
    local tab=tabs.visual
    tab:AddToggle("AOTRESPEnabled",{Title="巨人 ESP",Default=false,Callback=function(v) c.Enabled=v end})
    tab:AddToggle("AOTRESPTags",{Title="名称标签",Default=true,Callback=function(v) c.Tags=v end})
    tab:AddToggle("AOTRESPHealth",{Title="血量条",Default=true,Callback=function(v) c.Health=v end})
    tab:AddToggle("AOTRESPDistance",{Title="距离",Default=true,Callback=function(v) c.Distance=v end})
    tab:AddToggle("AOTRNapeHighlight",{Title="后颈高亮",Default=false,
        Callback=function(v) c.NapeHighlight=v end})
    tab:AddSlider("AOTRESPDist",{Title="ESP 距离",Min=200,Max=3000,Default=1200,Rounding=0,
        Callback=function(v) c.MaxDistance=v end})
end

tabs.visual:AddButton({Title="刷新巨人数量",Callback=function()
    if Titans then app:Notify("当前发现巨人 "..tostring(Titans:Count()).." 个") end
end})
tabs.visual:AddButton({Title="当前 ESP 刷新间隔",Callback=function()
    local interval=app:GetVisualInterval(0.1)
    app:Notify(("ESP 刷新间隔 %.3f 秒（约 %d Hz，随共享桥接档位变化）"):format(interval,math.max(1,math.floor(1/interval+0.5))))
end})
tabs.visual:AddButton({Title="查看刀片/雷枪余量",Callback=function()
    if not app:Alive() then return end
    app.ProbeHUD(false)
    local bh,bm=app.ReadCount(app.HUD.blades)
    local sh,sm=app.ReadCount(app.HUD.spears)
    app:Notify(("刀片 %s · 雷枪 %s"):format(
        bh and ("%d/%d"):format(bh,bm) or "未读取",
        sh and ("%d/%d"):format(sh,sm) or "未读取"))
end})
tabs.visual:AddButton({Title="查看燃气余量",Callback=function()
    if not app:Alive() then return end
    local ok,percent=pcall(function()
        app.ProbeHUD(false)
        return app.ReadPercent(app.HUD.gas)
    end)
    local valid=ok and type(percent)=="number" and percent==percent and percent>=0 and percent<=100
    local text=valid and ("%.1f%%"):format(percent) or "未读取"
    if app:Alive() then app:Notify("燃气: "..text) end
end})
tabs.visual:AddParagraph({Title="感知策略",
    Content="巨人池 10Hz 扫描一次，后颈解析带多路径回退；解锁目标自动忽略 5 秒，避免卡死重试。"})

--=========================================================================
-- UI: movement.
--=========================================================================
if Movement then
    local c=Movement.Config
    local tab=tabs.movement
    tab:AddToggle("AOTRFollow",{Title="自动跟随锁定目标",Default=false,
        Callback=function(v) c.FollowEnabled=v end})
    tab:AddDropdown("AOTRMoveMode",{Title="移动方式",Values={"Hover","Teleport"},Default="Hover",
        Callback=function(v) c.MoveMode=v end})
    tab:AddSlider("AOTRHeightOffset",{Title="跟随高度",Min=5,Max=80,Default=25,Rounding=0,
        Callback=function(v) c.HeightOffset=v end})
    tab:AddSlider("AOTRBehindOffset",{Title="身后距离",Min=0,Max=80,Default=30,Rounding=0,
        Callback=function(v) c.BehindOffset=v end})
    tab:AddSlider("AOTRGlideSpeed",{Title="滑行速度",Min=30,Max=400,Default=120,Rounding=0,
        Callback=function(v) c.GlideSpeed=v end})
    tab:AddToggle("AOTRFollowBoss",{Title="仅跟随 Boss",Default=false,
        Callback=function(v) c.FollowBossOnly=v end})
    tab:AddToggle("AOTRSpeedEnabled",{Title="自定义移动速度",Default=false,
        Callback=function(v) c.SpeedEnabled=v end})
    tab:AddSlider("AOTRSpeedValue",{Title="速度值",Min=16,Max=80,Default=24,Rounding=0,
        Callback=function(v) c.SpeedValue=v end})
    tab:AddToggle("AOTRNoclip",{Title="穿墙",Default=false,Callback=function(v) c.Noclip=v end})
    tab:AddToggle("AOTRTouchAssist",{Title="触摸飞行辅助（右半屏拖动）",Default=false,Callback=function(v) c.TouchAssist=v end})
    tab:AddSlider("AOTRTouchFlySpeed",{Title="触摸飞行速度",Min=30,Max=400,Default=120,Rounding=0,
        Callback=function(v) c.TouchFlySpeed=v end})
    tab:AddParagraph({Title="触屏飞行操作",
        Content="右半屏单指左右=侧移，单指上下=前后，双指上下=升降，均按相机朝向映射。松手或关闭仅停止写入并保留当前动量，不自动制动。"})
    tab:AddToggle("AOTRAntiAFK",{Title="反挂机",Default=true,Callback=function(v) c.AntiAFK=v end})
    tab:AddButton({Title="远程传送回大厅",Callback=function()
        if Movement.TeleportLobby then Movement.TeleportLobby() end
    end})
end

--=========================================================================
-- UI: farm.
--=========================================================================
if Farm then
    local c=Farm.Config
    local tab=tabs.farm
    tab:AddToggle("AOTRAutoReload",{Title="自动换刃（刀片耗尽）",Default=false,
        Callback=function(v) c.AutoReload=v end})
    tab:AddToggle("AOTRAutoRefill",{Title="自动补给（气罐/弹药）",Default=false,
        Callback=function(v) c.AutoRefill=v end})
    tab:AddSlider("AOTRGasRefillThreshold",{Title="气体补给阈值 (%)",Min=10,Max=75,Default=35,Rounding=0,
        Callback=function(v) c.GasThreshold=v end})
    tab:AddButton({Title="查看自动补给状态",Callback=function()
        local r=Farm:DebugSnapshot()
        local info=("换刃 %d/%d | 补给确认 %d/%d | %s | %s | 站距 %s | %s")
            :format(r.reloadVerified or 0,r.reloadAttempts or 0,
                r.refillVerified or 0,r.attempts or 0,
                tostring(r.weapon or "?"),tostring(r.reloadStatus or "?"),
                r.distance and ("%.0f"):format(r.distance) or "-",
                tostring(r.status or "unknown"))
        print("[Vortexion/AOTR/Refill] " .. info)
        app:Notify(info)
    end})
    tab:AddButton({Title="立即尝试补给一次（诊断）",Callback=function()
        local ok=Farm:ManualRefill()
        local r=Farm:DebugSnapshot()
        app:Notify((ok and "已发起；等待 HUD 确认 | " or "未发起 | ")..tostring(r.status))
    end})
    tab:AddButton({Title="重新扫描补给站",Callback=function()
        local ok=Farm:RefreshStation()
        local r=Farm:DebugSnapshot()
        app:Notify((ok and "发现补给站：" or "尚未发现补给站：")..tostring(r.station))
    end})
    tab:AddToggle("AOTRFPSSettings",{Title="服务端画质设置（关特效）",Default=true,
        Callback=function(v)
            c.FPSSettings=v
        end})
    tab:AddParagraph({Title="农场说明",
        Content="自动换刃需要有备用刀刃且手持刀刃已消失；自动补给用于备用刀刃/雷枪耗尽或气体不足。系统可从远距离向补给站发起请求，但是否允许由服务器决定。诊断按 HUD 实际增长计数，未确认不代表成功。"})
end

--=========================================================================
-- UI: settings (camera + debug + status + unload), preserving the original
-- local FOV control and scene awareness.
--=========================================================================
local AOTRWorkspace=app.Services.Workspace or workspace
local cameraDefaults={}
local camera=AOTRWorkspace and AOTRWorkspace.CurrentCamera
local defaultFov=camera and camera.FieldOfView or 70
local fovOn=false
local fovValue=math.clamp(math.floor(defaultFov),60,110)
local function restoreCameraFov()
    for cam,original in pairs(cameraDefaults) do
        pcall(function() cam.FieldOfView=original end)
    end
    table.clear(cameraDefaults)
end
local function applyCameraFov(cam)
    if not cam or not fovOn or not app:Alive() then return end
    if cameraDefaults[cam]==nil then cameraDefaults[cam]=cam.FieldOfView or 70 end
    if fovOn then cam.FieldOfView=fovValue end
end
tabs.settings:AddToggle("AOTRCameraFovOn",{Title="启用视场角修改",Default=false,Callback=function(v)
    if not app:Alive() then return end
    fovOn=v
    local cam=AOTRWorkspace and AOTRWorkspace.CurrentCamera
    if v then applyCameraFov(cam)
    else
        restoreCameraFov()
    end
end})
tabs.settings:AddSlider("AOTRCameraFov",{Title="本地视场角",Min=60,Max=110,Default=math.clamp(math.floor(defaultFov),60,110),Rounding=0,
    Callback=function(v)
        if not app:Alive() then return end
        fovValue=v
        if fovOn then applyCameraFov(AOTRWorkspace and AOTRWorkspace.CurrentCamera) end
    end})
if AOTRWorkspace and AOTRWorkspace.GetPropertyChangedSignal then
    app:Track(AOTRWorkspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if not app:Alive() then return end
        restoreCameraFov()
        applyCameraFov(AOTRWorkspace.CurrentCamera)
    end))
end
app:OnStop(function()
    fovOn=false
    restoreCameraFov()
end)
tabs.settings:AddToggle("AOTRDebug",{Title="调试日志",Default=false,Callback=function(v)
    app.Debug=v
end})
tabs.settings:AddParagraph({Title="场景识别",
    Content="仅在已核实的任务 PlaceId 中启动；未识别地图不会误加载战斗脚本。"})
tabs.settings:AddButton({Title="子模块初始化诊断",Callback=function()
    app:Notify(#bootFailures > 0 and table.concat(bootFailures, " / ") or "已调用全部子模块工厂；玩法有效性仍需实机测试")
end})
local combatStatusParagraph=tabs.settings:AddParagraph({Title="战斗运行状态",Content="点击运行状态查看请求计数；发送不代表服务器命中"})
tabs.settings:AddButton({Title="运行状态",Callback=function()
    local Titans,Combat,Farm=app.Titans,app.Combat,app.Farm
    local remotes=app.Remotes
    local titanInfo=Titans and ("巨人 "..tostring(Titans:Count())) or "巨人池未加载"
    local snapshot=Combat and Combat:DebugSnapshot() or {}
    local text=("GET=%s POST=%s / %s / 锁定=%s\n尝试=%s 发送=%s 排队=%s 本地失败=%s\n原因=%s\n服务器命中尚未确认")
        :format(tostring(remotes.GET~=nil),tostring(remotes.POST~=nil),titanInfo,
            tostring(snapshot.locked or "-"), tostring(snapshot.attempts or 0),
            tostring(snapshot.attacks or 0),tostring(snapshot.queuedRequests or 0),
            tostring(snapshot.failedRequests or 0),tostring(snapshot.lastRequestError or "unknown"))
    if combatStatusParagraph and type(combatStatusParagraph.SetDesc)=="function" then
        combatStatusParagraph:SetDesc(text)
    else
        print("[Vortexion/AOTR] "..text)
    end
end})
tabs.settings:AddButton({Title="卸载全部 AOTR 功能",Callback=function()
    local client=(getgenv and getgenv()) or _G
    if type(client.VortexionAOTRCleanup)=="function" then
        pcall(client.VortexionAOTRCleanup)
    end
    pcall(function() app.ui:Destroy() end)
end})

app:Status(tabs.settings)
window:SelectTab(1)
app:Notify("战斗模块已加载：进入任务后启用对应功能")

end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "AOTR_Battle")
end
