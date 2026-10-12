-- Vortexion - BloxStrike v2: game-specific entry, unified Starlight UI.
-- Do not copy source implementations: use lifecycle-managed services in separate modules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local BloxCombatFactory = nil
local BloxVisualFactory = nil
local BloxCosmeticFactory = nil
local StarlightBridgeFactory = nil
local Starlight = nil

local global = (getgenv and getgenv()) or _G
if type(global.VortexionBloxCleanup) == "function" then
    pcall(global.VortexionBloxCleanup)
end
global.VortexionBloxGeneration = (global.VortexionBloxGeneration or 0) + 1
local generation = global.VortexionBloxGeneration
local connections = {}
local cleanups = {}
local function isCurrent()
    return global.VortexionBloxGeneration == generation
end
local function ownConnection(conn)
    if conn then table.insert(connections,conn) end
    return conn
end
local function ownCleanup(fn)
    table.insert(cleanups,fn)
end
local function cleanup()
    if global.VortexionBloxGeneration == generation then
        global.VortexionBloxGeneration += 1
    end
    for i=#connections,1,-1 do
        pcall(function() connections[i]:Disconnect() end)
        connections[i]=nil
    end
    for i=#cleanups,1,-1 do
        pcall(cleanups[i])
        cleanups[i]=nil
    end
end
global.VortexionBloxCleanup=cleanup

-- BloxStrike uses Workspace.Characters/Terrorists and Counter-Terrorists;
-- Player.Character alone is not a reliable source while spectating/spawning.
local function getCharacterRoot()
    return Workspace:FindFirstChild("Characters")
end
local function teamFolder(player)
    local root=getCharacterRoot()
    if not root then return nil end
    for _,name in ipairs({"Terrorists","Counter-Terrorists"}) do
        local folder=root:FindFirstChild(name)
        if folder and folder:FindFirstChild(player.Name) then return folder end
    end
    return nil
end
local function characterOf(player)
    local team=teamFolder(player)
    local candidate=team and team:FindFirstChild(player.Name)
    if candidate and candidate:IsA("Model") then return candidate end
    return player.Character
end
local function livingCharacter(player)
    local model=characterOf(player)
    if not model or not model.Parent or model:GetAttribute("Dead")==true then return nil end
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    return model,humanoid
end
local function isEnemy(player,checkTeam)
    if player==LocalPlayer then return false end
    if checkTeam==false or Workspace:GetAttribute("Gamemode")=="Deathmatch" then return true end
    local localTeam=teamFolder(LocalPlayer)
    local otherTeam=teamFolder(player)
    if localTeam and otherTeam then return localTeam~=otherTeam end
    local a,b=LocalPlayer:GetAttribute("Team"),player:GetAttribute("Team")
    if a~=nil and b~=nil then return a~=b end
    if LocalPlayer.Team and player.Team then return LocalPlayer.Team~=player.Team end
    return true
end
local function playerFromModel(model)
    if not model then return nil end
    local byName=Players:FindFirstChild(model.Name)
    if byName and byName:IsA("Player") then return byName end
    return Players:GetPlayerFromCharacter(model)
end
local function notify(title, content)
    if global.VortexionBloxNotify then
        global.VortexionBloxNotify(title,content)
    end
end

local ok,ui=pcall(function() return StarlightBridgeFactory(Starlight) end)
if not ok or not ui then
    warn("[Vortexion/BloxStrike] Starlight initialization failed: "..tostring(ui))
    return
end
global.VortexionBloxNotify=function(title,content)
    pcall(function() ui:Notify({Title=title, Content=content, Duration=4}) end)
end
local window=ui:CreateWindow({Title="BloxStrike", Size=UDim2.fromOffset(580,460)})
pcall(function()
    local header=Starlight.Instance.MainWindow.Sidebar.Header
    header.Text="BloxStrike"
end)
local tabs={
    Combat=window:AddTab({Title="战斗",Icon="lucide-crosshair"}),
    Weapon=window:AddTab({Title="武器",Icon="lucide-target"}),
    Visual=window:AddTab({Title="视觉",Icon="lucide-eye"}),
    Appearance=window:AddTab({Title="枪械皮肤",Icon="lucide-palette"}),
    Knife=window:AddTab({Title="刀具与手套",Icon="lucide-swords"}),
    Movement=window:AddTab({Title="移动",Icon="lucide-activity"}),
    Settings=window:AddTab({Title="设置",Icon="lucide-settings"}),
}
window:InstallSettings(tabs.Settings)

local ctx={
    Players=Players,RunService=RunService,Workspace=Workspace,
    ReplicatedStorage=ReplicatedStorage,Lighting=Lighting,Input=UserInputService,
    LocalPlayer=LocalPlayer,UI=ui,Window=window,Tabs=tabs,
    Notify=notify,IsCurrent=isCurrent,Own=ownConnection,OnCleanup=ownCleanup,
    Character=characterOf,Living=livingCharacter,TeamFolder=teamFolder,
    Enemy=isEnemy,PlayerFromModel=playerFromModel,
}
local function setup(name,factory)
    local passed,err=pcall(factory,ctx)
    if not passed then
        warn("[Vortexion/BloxStrike] "..name.." failed: "..tostring(err))
        notify(name.." 模块失败",tostring(err))
    end
end
setup("战斗",BloxCombatFactory)
setup("视觉",BloxVisualFactory)
setup("皮肤",BloxCosmeticFactory)
tabs.Settings:AddParagraph({Title="BloxStrike 兼容说明",
    Content="独立模块；角色优先识别 Workspace.Characters。所有皮肤仅本地预览；服务器命中与武器模块兼容性依赖游戏版本。"})
tabs.Settings:AddButton({Title="检查运行状态",Callback=function()
    local assets=ReplicatedStorage:FindFirstChild("Assets")
    local skins=assets and assets:FindFirstChild("Skins")
    local characters=getCharacterRoot()
    local components=ReplicatedStorage:FindFirstChild("Components")
    local weapon=components and components:FindFirstChild("Weapon")
    notify("运行环境检查",(characters and "角色目录正常" or "角色目录未加载")
        .." / "..(skins and "皮肤目录正常" or "皮肤目录未加载")
        .." / "..(weapon and "武器组件正常" or "武器组件未加载"))
end})
tabs.Settings:AddButton({Title="卸载全部 BloxStrike 功能",Callback=function()
    cleanup()
    pcall(function() ui:Destroy() end)
end})
window:SelectTab(1)
notify("Vortexion - BloxStrike","功能模块已加载；进入对局后启用对应功能")
