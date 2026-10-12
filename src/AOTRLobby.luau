-- AOTR lobby: local observation and controlled UI, no remote spam.
local app=AOTRCommon("lobby",Starlight,StarlightBridgeFactory)
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
profile:AddParagraph({Title="角色数据",Content="只读取已同步到客户端的角色属性；不修改服务器背包、货币和抽取结果。"})
profile:AddButton({Title="检查当前角色",Callback=function()
    local character,hum=app:Character()
    app:Notify(character and ("角色已载入，生命值 "..math.floor(hum.Health)) or "角色尚未载入")
end})
local camera=workspace.CurrentCamera
local defaultFov=camera and camera.FieldOfView or 70
local fov=defaultFov
local fovOn=false
local function applyFov()
    local cam=workspace.CurrentCamera
    if cam and fovOn then cam.FieldOfView=fov end
end
tools:AddSlider("AOTRLobbyFov",{Title="本地视场角",Min=60,Max=110,Default=math.clamp(math.floor(defaultFov),60,110),Rounding=0,Callback=function(v) fov=v;applyFov() end})
tools:AddToggle("AOTRLobbyFovEnabled",{Title="启用视场角设置",Default=false,Callback=function(v)
    fovOn=v
    local cam=workspace.CurrentCamera
    if cam then cam.FieldOfView=v and fov or defaultFov end
end})
app:OnStop(function()
    if fovOn and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=defaultFov end
end)
status:AddParagraph({Title="兼容说明",Content="大厅模块独立于战斗模块；不会在交易中心自动启动。"})
window:SelectTab(1)
app:Notify("大厅脚本加载完成")
