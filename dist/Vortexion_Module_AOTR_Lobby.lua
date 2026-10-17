-- Vortexion WindUI - generated offline; publishing must be performed separately.
-- WindUI attribution and license are retained in vendor/WindUI/.
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
-- AOTR lobby: local observation and controlled UI, no remote spam.
local app=AOTRCommon("lobby",WindUI,WindBridgeFactory)
local window=app:Open()
if not window then return end
local overview=window:AddTab({Title="大厅",Icon="lucide-house"})
local profile=window:AddTab({Title="角色",Icon="lucide-user"})
local tools=window:AddTab({Title="辅助",Icon="lucide-settings"})
local status=window:AddTab({Title="设置",Icon="lucide-settings"})
window:InstallSettings(status)
app:Status(overview)
local player=app.player
local function value(name)
    local v=player and player:GetAttribute(name)
    return v==nil and "未提供" or tostring(v)
end
overview:AddButton({Title="查看角色基础信息",Callback=function()
    app:Notify("等级: "..value("Level").." · 经验: "..value("EXP"))
end})
overview:AddButton({Title="查看当前地点",Callback=function()
    app:Notify("PlaceId: "..tostring(game.PlaceId))
end})
overview:AddButton({Title="查看刀片/雷枪余量",Callback=function()
    if not app:Alive() then return end
    app.ProbeHUD(false)
    local bh,bm=app.ReadCount(app.HUD.blades)
    local sh,sm=app.ReadCount(app.HUD.spears)
    app:Notify(("刀片 %s · 雷枪 %s"):format(
        bh and ("%d/%d"):format(bh,bm) or "未读取",
        sh and ("%d/%d"):format(sh,sm) or "未读取"))
end})
local function finite(v)
    return type(v)=="number" and v==v and v>-math.huge and v<math.huge
end
local function snapshotValue(name)
    local ok,text=pcall(value,name)
    return ok and text or "未读取"
end
local function fovText()
    local ok,v=pcall(function()
        local cam=workspace.CurrentCamera
        return cam and cam.FieldOfView
    end)
    if ok and v==nil then return "未提供" end
    if ok and finite(v) then return ("%d"):format(math.floor(v)) end
    return "未读取"
end
local function healthText()
    local ok,character,hum=pcall(function() return app:Character() end)
    if not ok or not character then return "未提供" end
    if hum==nil then return "未读取" end
    local hok,hp=pcall(function() return hum.Health end)
    if hok and finite(hp) then return ("%d"):format(math.floor(hp)) end
    return "未读取"
end
local function hudText(label)
    local ok,have,max=pcall(app.ReadCount,label)
    if ok and finite(have) and finite(max) and have>=0 and max>=0 then
        return ("%d/%d"):format(have,max)
    end
    return "未读取"
end
local function gasText(hud)
    local ok,percent=pcall(function() return app.ReadPercent(hud and hud.gas) end)
    if ok and finite(percent) and percent>=0 and percent<=100 then
        return ("%.1f%%"):format(percent)
    end
    return "未读取"
end
overview:AddButton({Title="查看燃气余量",Callback=function()
    if not app:Alive() then return end
    local ok=pcall(app.ProbeHUD,false)
    local text=ok and gasText(app.HUD) or "未读取"
    if app:Alive() then app:Notify("燃气: "..text) end
end})
overview:AddButton({Title="立即刷新全部余量",Callback=function()
    if not app:Alive() then return end
    local ok=pcall(app.ProbeHUD,true)
    local hud=ok and type(app.HUD)=="table" and app.HUD or nil
    local blades=hud and hudText(hud.blades) or "未读取"
    local spears=hud and hudText(hud.spears) or "未读取"
    local gas=hud and gasText(hud) or "未读取"
    if not app:Alive() then return end
    app:Notify(("刀片 %s · 雷枪 %s · 燃气 %s"):format(blades,spears,gas))
end})
local function lobbySnapshot()
    local ok,hud=pcall(function() app.ProbeHUD(false); return app.HUD end)
    if not ok or type(hud)~="table" then hud={} end
    return table.concat({
        "GameId: "..(game.GameId and tostring(game.GameId) or "未提供"),
        "PlaceId: "..(game.PlaceId and tostring(game.PlaceId) or "未提供"),
        "等级: "..snapshotValue("Level").." · 经验: "..snapshotValue("EXP"),
        "角色/生命: "..healthText(),
        "视场角: "..fovText(),
        "刀片: "..hudText(hud.blades).." · 雷枪: "..hudText(hud.spears),
        "燃气: "..gasText(hud),
    },"\n")
end
overview:AddButton({Title="复制大厅状态",Callback=function()
    if not app:Alive() then return end
    local snapshot=lobbySnapshot()
    if not app:Alive() then return end
    local clipboard=setclipboard
    if type(clipboard)~="function" then clipboard=toclipboard end
    local copied=false
    if type(clipboard)=="function" then
        local ok,result=pcall(clipboard,snapshot)
        copied=ok and result~=false
    end
    if not app:Alive() then return end
    if copied then
        app:Notify("大厅状态已复制到剪贴板")
    else
        app:Notify("剪贴板不可用，大厅状态：\n"..snapshot)
    end
end})
profile:AddParagraph({Title="角色数据",Content="只读取已同步到客户端的角色属性；不修改服务器背包、货币和抽取结果。"})
profile:AddButton({Title="检查当前角色",Callback=function()
    local character,hum=app:Character()
    app:Notify(character and ("角色已载入，生命值 "..math.floor(hum.Health)) or "角色尚未载入")
end})
local cameraDefaults={}
local camera=workspace.CurrentCamera
local defaultFov=camera and camera.FieldOfView or 70
local fov=math.clamp(math.floor(defaultFov),60,110)
local fovOn=false
if app.ui and type(app.ui.RegisterFeatureHealth) == "function" then
    app.ui:RegisterFeatureHealth("AOTR 大厅", function()
        local character = app.player and app.player.Character
        return ("存活=%s 角色=%s 视场角开关=%s 当前相机=%s")
            :format(tostring(app:Alive()), tostring(character ~= nil),
                tostring(fovOn), tostring(workspace.CurrentCamera ~= nil))
    end)
end
local function restoreCameraFov()
    for cam,original in pairs(cameraDefaults) do
        pcall(function() cam.FieldOfView=original end)
    end
    table.clear(cameraDefaults)
end
local function applyFov(cam)
    if not cam or not fovOn or not app:Alive() then return end
    if cameraDefaults[cam]==nil then cameraDefaults[cam]=cam.FieldOfView or 70 end
    if fovOn then cam.FieldOfView=fov end
end
tools:AddSlider("AOTRLobbyFov",{Title="本地视场角",Min=60,Max=110,Default=math.clamp(math.floor(defaultFov),60,110),Rounding=0,Callback=function(v) if not app:Alive() then return end;fov=v;applyFov(workspace.CurrentCamera) end})
tools:AddToggle("AOTRLobbyFovEnabled",{Title="启用视场角设置",Default=false,Callback=function(v)
    if not app:Alive() then return end
    fovOn=v
    local cam=workspace.CurrentCamera
    if v then applyFov(cam)
    else
        restoreCameraFov()
    end
end})
if workspace.GetPropertyChangedSignal then
    app:Track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if not app:Alive() then return end
        restoreCameraFov()
        applyFov(workspace.CurrentCamera)
    end))
end
app:OnStop(function()
    fovOn=false
    restoreCameraFov()
end)
status:AddParagraph({Title="兼容说明",Content="大厅模块独立于战斗模块；不会在交易中心自动启动。"})
window:SelectTab(1)
app:Notify("大厅脚本加载完成")

end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "AOTR_Lobby")
end
