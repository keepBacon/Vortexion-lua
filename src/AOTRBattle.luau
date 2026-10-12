-- AOTR battle: throttled titan awareness, local camera controls and manual recovery.
local app=AOTRCommon("battle",Starlight,StarlightBridgeFactory)
local window=app:Open()
if not window then return end
local battle=window:AddTab({Title="战斗",Icon="lucide-swords"})
local awareness=window:AddTab({Title="感知",Icon="lucide-eye"})
local cameraTab=window:AddTab({Title="视角",Icon="lucide-camera"})
local settings=window:AddTab({Title="设置",Icon="lucide-settings"})
window:InstallSettings(settings)
app:Status(battle)
local titanFolder=workspace:FindFirstChild("Titans")
local tracked={}
local titanCount=0
local function countTitans()
    local folder=workspace:FindFirstChild("Titans")
    if not folder then return 0 end
    local count=0
    for _,titan in ipairs(folder:GetChildren()) do
        local hum=titan:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health>0 then count+=1 end
    end
    return count
end
battle:AddButton({Title="刷新巨人数量",Callback=function()
    app:Notify("当前发现巨人 "..tostring(countTitans()).." 个")
end})
battle:AddButton({Title="查看角色状态",Callback=function()
    local _,hum=app:Character()
    app:Notify(hum and ("当前生命值 "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)) or "角色未就绪")
end})
local monitored=false
awareness:AddToggle("AOTRTitanMonitor",{Title="巨人数量监控",Default=false,Callback=function(on)
    monitored=on
    if on then app:Loop("titans",1,function()
        local now=countTitans()
        if now~=titanCount then titanCount=now;app:Notify("巨人数量更新: "..tostring(now)) end
    end) else app:StopLoop("titans") end
end})
awareness:AddParagraph({Title="性能策略",Content="巨人统计每秒最多刷新一次，关闭监控后不再遍历。"})
local savedFov=(workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70
local desiredFov=math.clamp(savedFov,60,110)
local enabledFov=false
cameraTab:AddSlider("AOTRBattleFov",{Title="本地视场角",Default=desiredFov,Min=60,Max=110,Rounding=0,Callback=function(v)
    desiredFov=v
    if enabledFov and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=v end
end})
cameraTab:AddToggle("AOTRBattleFovOn",{Title="启用视场角",Default=false,Callback=function(v)
    enabledFov=v
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=v and desiredFov or savedFov end
end})
app:OnStop(function()
    if enabledFov and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=savedFov end
end)
settings:AddParagraph({Title="场景识别",Content="仅在已核实的任务 PlaceId 中启动；未识别地图不会误加载战斗脚本。"})
window:SelectTab(1)
app:Notify("战斗脚本加载完成")
