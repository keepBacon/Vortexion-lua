-- Vortexion - BloxStrike
-- Independent game-specific feature set. Uses the same Starlight UI as Forsaken.
-- Built by build.py; never automatically runs when the game ID is unsupported.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local uid = (getgenv and getgenv()) or _G
uid.VortexionBloxSession = (uid.VortexionBloxSession or 0) + 1
local token = uid.VortexionBloxSession
local function active() return uid.VortexionBloxSession == token end
local Window, Tabs
local StarlightBridgeFactory = nil
local Starlight = nil
local successful, UI = pcall(function() return StarlightBridgeFactory(Starlight) end)
if not successful or not UI then
    warn("[Vortexion/BloxStrike] UI unavailable: " .. tostring(UI))
    return
end
Window = UI:CreateWindow({Title = "BloxStrike", Size = UDim2.fromOffset(580, 460)})
Tabs = {
    Combat = Window:AddTab({Title="战斗", Icon="lucide-crosshair"}),
    Visual = Window:AddTab({Title="视觉", Icon="lucide-eye"}),
    Appearance = Window:AddTab({Title="外观", Icon="lucide-palette"}),
    Movement = Window:AddTab({Title="移动", Icon="lucide-activity"}),
    Settings = Window:AddTab({Title="设置", Icon="lucide-settings"}),
}
Window:InstallSettings(Tabs.Settings)
local state = {Fov=220, AimEnabled=false, Hold=false, TeamCheck=true,
    WallCheck=true, AimSmooth=0.25, ESP=false, ESPDetail=true, ESPDistance=true,
    Tracers=false, ScanHz=12, Fullbright=false, SkinEnabled=false,
    SkinName="", WeaponName="", KnifeName="Karambit"}
local currentTarget = nil
local targetCache = {}
local function isAlive(player)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    return char and humanoid and humanoid.Health > 0 and char:GetAttribute("Dead") ~= true
end
local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not state.TeamCheck then return true end
    if Workspace:GetAttribute("Gamemode") == "Deathmatch" then return true end
    local a, b = LocalPlayer:GetAttribute("Team"), player:GetAttribute("Team")
    if a ~= nil and b ~= nil then return a ~= b end
    if LocalPlayer.Team and player.Team then return LocalPlayer.Team ~= player.Team end
    return true
end
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local function isVisible(char, part, camera)
    if not state.WallCheck then return true end
    local ignore = {camera}
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    raycastParams.FilterDescendantsInstances = ignore
    local origin = camera.CFrame.Position
    local result = Workspace:Raycast(origin, part.Position-origin, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(char)
end
local function findTarget(camera)
    local vp = camera.ViewportSize
    local center = Vector2.new(vp.X/2,vp.Y/2)
    local best, d2 = nil, state.Fov*state.Fov
    for _, player in ipairs(Players:GetPlayers()) do
        if isAlive(player) and isEnemy(player) then
            local character = player.Character
            local part = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
            if part then
                local pos,onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z > 0 then
                    local dx,dy=pos.X-center.X,pos.Y-center.Y
                    local radius=dx*dx+dy*dy
                    if radius<d2 and isVisible(character,part,camera) then
                        d2,best=radius,part
                    end
                end
            end
        end
    end
    return best
end
local nextAimScan=0
local function aimFrame(dt)
    if not active() then return end
    if not state.AimEnabled or not state.Hold then return end
    local camera=Workspace.CurrentCamera
    if not camera then return end
    local now=os.clock()
    if now>=nextAimScan then
        nextAimScan=now+0.1
        currentTarget=findTarget(camera)
    end
    if not currentTarget or not currentTarget.Parent then return end
    local direction=currentTarget.Position-camera.CFrame.Position
    if direction.Magnitude<0.1 then return end
    local alpha=1-math.exp(-math.max(0.1, state.AimSmooth*20)*dt)
    camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position,currentTarget.Position),alpha)
end
local aimConnection
local function syncAim()
    if aimConnection then aimConnection:Disconnect();aimConnection=nil end
    currentTarget=nil
    if state.AimEnabled then aimConnection=RunService.RenderStepped:Connect(aimFrame) end
end
Tabs.Combat:AddToggle("BloxAimEnabled", {Title="镜头瞄准辅助",Default=false,
    Description="按住右键时平滑转向可见的敌方角色；不修改命中数据",
    Callback=function(v) state.AimEnabled=v;syncAim() end})
Tabs.Combat:AddSlider("BloxAimFov", {Title="目标搜索半径",Default=220,Min=50,Max=500,Rounding=0,
    Callback=function(v) state.Fov=v end})
Tabs.Combat:AddSlider("BloxAimSmooth", {Title="镜头跟随强度",Default=25,Min=5,Max=100,Rounding=0,
    Callback=function(v) state.AimSmooth=v/100 end})
Tabs.Combat:AddToggle("BloxWallCheck", {Title="遮挡检查",Default=true,
    Callback=function(v) state.WallCheck=v end})
Tabs.Combat:AddToggle("BloxTeamCheck", {Title="阵营过滤",Default=true,
    Callback=function(v) state.TeamCheck=v end})
local began=UserInputService.InputBegan:Connect(function(input,processed)
    if processed or not active() then return end
    if input.UserInputType==Enum.UserInputType.MouseButton2 then state.Hold=true end
end)
local ended=UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then state.Hold=false end
end)
-- ESP does not depend on Drawing API. Highlights are lightweight and removed on disable.
local highlights={}
local function removeHighlights()
    for player,h in pairs(highlights) do
        if h then pcall(function() h:Destroy() end) end
        highlights[player]=nil
    end
end
local function updateHighlights()
    if not state.ESP or not active() then return end
    for _,player in ipairs(Players:GetPlayers()) do
        local char=player.Character
        local valid=char and isAlive(player) and isEnemy(player)
        local h=highlights[player]
        if not valid then
            if h then h:Destroy();highlights[player]=nil end
        else
            if not h or h.Parent~=char then
                if h then h:Destroy() end
                h=Instance.new("Highlight")
                h.Name="VortexionBloxHighlight"
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.FillTransparency=0.78
                h.OutlineTransparency=0.08
                h.Adornee=char
                h.Parent=char
                highlights[player]=h
            end
            h.FillColor=Color3.fromRGB(255,90,90)
            h.OutlineColor=Color3.fromRGB(255,120,120)
        end
    end
end
local espThread
local function syncESP()
    if not state.ESP then
        removeHighlights()
        return
    end
    if espThread then return end
    espThread=task.spawn(function()
        while state.ESP and active() do
            updateHighlights()
            task.wait(0.3)
        end
        espThread=nil
    end)
end
Tabs.Visual:AddToggle("BloxESP", {Title="角色高亮 ESP",Default=false,
    Callback=function(v) state.ESP=v;syncESP() end})
Tabs.Visual:AddToggle("BloxESPTeam", {Title="阵营过滤（与瞄准共享）",Default=true,
    Callback=function(v) state.TeamCheck=v;updateHighlights() end})
local prevLighting
Tabs.Visual:AddToggle("BloxFullbright", {Title="明亮场景",Default=false,
    Callback=function(on)
        if on then
            if not prevLighting then
                prevLighting={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,
                    OutdoorAmbient=Lighting.OutdoorAmbient,ClockTime=Lighting.ClockTime}
            end
            Lighting.Brightness=2
            Lighting.Ambient=Color3.fromRGB(160,160,160)
            Lighting.OutdoorAmbient=Color3.fromRGB(180,180,180)
            Lighting.ClockTime=14
        elseif prevLighting then
            for k,v in pairs(prevLighting) do Lighting[k]=v end
            prevLighting=nil
        end
    end})
local originalWalkSpeed, speedConnection
local requestedSpeed=20
local function disableSpeed()
    if speedConnection then speedConnection:Disconnect(); speedConnection=nil end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and originalWalkSpeed then hum.WalkSpeed=originalWalkSpeed end
    originalWalkSpeed=nil
end
Tabs.Movement:AddSlider("BloxWalkSpeed", {Title="移动速度",Min=16,Max=60,Default=20,Rounding=0,
    Callback=function(v)
        requestedSpeed=v
    end})
Tabs.Movement:AddToggle("BloxSpeedEnabled", {Title="自定义移动速度",Default=false,
    Callback=function(on)
        disableSpeed()
        if not on then return end
        local nextCheck=0
        speedConnection=RunService.Heartbeat:Connect(function()
            if not active() then disableSpeed();return end
            local now=os.clock()
            if now<nextCheck then return end
            nextCheck=now+0.25
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if not originalWalkSpeed then originalWalkSpeed=hum.WalkSpeed end
                hum.WalkSpeed=requestedSpeed
            end
        end)
    end})
Tabs.Appearance:AddParagraph({Title="BloxStrike 外观",
    Content="本地皮肤资源需要核对 Assets/Skins 结构。此版本不写入库存或服务器经济数据。"})
Tabs.Appearance:AddButton({Title="扫描可用的游戏皮肤资源",Callback=function()
    local assets=ReplicatedStorage:FindFirstChild("Assets")
    local skins=assets and assets:FindFirstChild("Skins")
    if not skins then
        UI:Notify({Title="资源不可用",Content="当前版本未找到 Assets/Skins。",Duration=3})
        return
    end
    local count=0
    for _,folder in ipairs(skins:GetChildren()) do
        count+=1
    end
    UI:Notify({Title="皮肤资源扫描",Content="检测到 "..tostring(count).." 个类别。",Duration=4})
end})
Tabs.Settings:AddParagraph({Title="BloxStrike 模式",
    Content="根据 GameId=7633926880 加载；界面与 Forsaken 共用 Starlight 资源。功能按需执行，未在真机及线上对战中验证。"})
Window:SelectTab(1)
UI:Notify({Title="Vortexion - BloxStrike",Content="独立 BloxStrike 模块已启动",Duration=4})
