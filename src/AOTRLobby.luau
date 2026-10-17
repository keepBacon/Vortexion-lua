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
