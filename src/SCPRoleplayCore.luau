-- Vortexion / SCP: Roleplay visual identity panel.
-- Only replicated information is displayed. No combat or network hooks.
local StarlightBridgeFactory = nil
local Starlight = nil
local MetadataFactory = nil
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
if tonumber(game.GameId) ~= 1742264997 and tonumber(game.PlaceId) ~= 5041144419 then return end
local env = (getgenv and getgenv()) or _G
if type(env.VortexionSCPCleanup) == "function" then pcall(env.VortexionSCPCleanup) end
local metadata = MetadataFactory()
local connections, labels = {}, {}
local state = {Show=false,Team=true,Rank=true,Distance=250,UpdateHz=4}
local alive = true
local windowUI
local function bind(signal,fn)
    local c = signal:Connect(fn)
    table.insert(connections,c)
    return c
end
local function clear(player)
    local label = labels[player]
    if label then label:Destroy();labels[player]=nil end
end
local function clearAll()
    for player in pairs(labels) do clear(player) end
end
local function getAdornee(player)
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end
local function update()
    if not state.Show then clearAll();return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local head = getAdornee(p)
            local dist = head and (camera.CFrame.Position-head.Position).Magnitude or math.huge
            if not head or dist>state.Distance then
                clear(p)
            else
                local ui = labels[p]
                if not ui or ui.Adornee~=head then
                    clear(p)
                    ui=Instance.new("BillboardGui")
                    ui.Name="VortexionSCPIdentity"
                    ui.Size=UDim2.fromOffset(200,66)
                    ui.StudsOffset=Vector3.new(0,2.8,0)
                    ui.AlwaysOnTop=true
                    ui.Adornee=head
                    ui.MaxDistance=state.Distance
                    local title=Instance.new("TextLabel")
                    title.Name="Label"
                    title.BackgroundTransparency=1
                    title.Size=UDim2.fromScale(1,1)
                    title.Font=Enum.Font.GothamMedium
                    title.TextSize=13
                    title.TextStrokeTransparency=0.4
                    title.TextWrapped=true
                    title.TextYAlignment=Enum.TextYAlignment.Center
                    title.Parent=ui
                    ui.Parent=LocalPlayer:WaitForChild("PlayerGui")
                    labels[p]=ui
                end
                local info=metadata.Snapshot(p)
                local pieces={p.DisplayName}
                if state.Team then table.insert(pieces,info.team) end
                if state.Rank then table.insert(pieces,info.rank) end
                local text=ui:FindFirstChild("Label")
                if text then
                    text.Text=table.concat(pieces,"\n")
                    text.TextColor3=info.color
                end
            end
        end
    end
end
local function cleanup()
    if not alive then return end
    alive=false
    for _,c in ipairs(connections) do c:Disconnect() end
    clearAll()
    if windowUI then pcall(function() windowUI:Destroy() end) end
    if env.VortexionSCPCleanup==cleanup then env.VortexionSCPCleanup=nil end
end
env.VortexionSCPCleanup=cleanup
bind(Players.PlayerRemoving,clear)
bind(Players.PlayerAdded,function(p)
    bind(p.CharacterRemoving,function() clear(p) end)
end)
local accumulator=0
bind(RunService.Heartbeat,function(dt)
    if not alive then return end
    accumulator+=dt
    if accumulator>=1/state.UpdateHz then accumulator=0;update() end
end)
local ok,bridge=pcall(function() return StarlightBridgeFactory(Starlight) end)
if not ok or not bridge then
    warn("[Vortexion/SCP] UI initialization failed: "..tostring(bridge))
    cleanup()
    return
end
windowUI=bridge
local window=bridge:CreateWindow({Title="SCP: Roleplay",ConfigFolder="VortexionSCP"})
local visual=window:AddTab({Title="角色信息"})
local settings=window:AddTab({Title="设置"})
visual:AddParagraph({Title="阵营与职位显示",Content="读取游戏客户端提供的 Team、Attribute 和 leaderstats。未知职位不作推断。"})
visual:AddToggle("SCPShowIdentity",{Title="显示角色标签",Default=false,Callback=function(v) state.Show=v;if not v then clearAll() end end})
visual:AddToggle("SCPShowTeam",{Title="显示阵营",Default=true,Callback=function(v) state.Team=v end})
visual:AddToggle("SCPShowRank",{Title="显示职位",Default=true,Callback=function(v) state.Rank=v end})
visual:AddSlider("SCPIdentityDistance",{Title="最大显示距离",Min=50,Max=700,Default=250,Rounding=0,Callback=function(v) state.Distance=v end})
visual:AddSlider("SCPIdentityRate",{Title="刷新频率 Hz",Min=1,Max=10,Default=4,Rounding=0,Callback=function(v) state.UpdateHz=v end})
settings:AddParagraph({Title="SCP 分支",Content="Universe 1742264997；Place 5041144419。当前版本提供角色身份标签，不包含绕过检测或修改游戏战斗结果的功能。"})
settings:AddButton({Title="卸载 SCP 界面和标签",Callback=cleanup})
window:SelectTab(1)
