-- Vortexion - BloxStrike v3: game-specific entry, unified WindUI UI.
-- Do not copy source implementations: use lifecycle-managed services in separate modules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local BloxCommonFactory = nil
local BloxCloakFactory = nil
local BloxCombatFactory = nil
local BloxBulletFactory = nil
local BloxVisualFactory = nil
local BloxCosmeticFactory = nil
local WindBridgeFactory = nil
local WindUI = nil

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
local cleaned = false
local function cleanup()
    if cleaned then return end
    cleaned = true
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

--=========================================================================
-- Executor floor: blacklist the known-incompatible executors early, the same
-- policy Forsaken and SCP use, so a broken environment fails loudly instead
-- of half-loading subsystems.
--=========================================================================
do
    local executorName = "unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then
            executorName = tostring(identifyexecutor() or "unknown")
        end
    end)
    for _, bad in ipairs({ "Xeno", "Velocity", "LX63" }) do
        if string.find(executorName, bad, 1, true) then
            global.VortexionBootError = "BloxStrike executor unsupported: " .. executorName
            warn("[Vortexion/BloxStrike] unsupported executor: " .. executorName)
            return
        end
    end
end

--=========================================================================
-- UI: WindUI bridge (vendored, zero network).
--=========================================================================
local ok,ui=pcall(function() return WindBridgeFactory(WindUI) end)
if not ok or not ui then
    global.VortexionBootError = "BloxStrike Bridge: " .. tostring(ui)
    warn("[Vortexion/BloxStrike] WindUI initialization failed: "..tostring(ui))
    return
end
global.VortexionBloxNotify=function(title,content)
    pcall(function() ui:Notify({Title=title, Content=content, Duration=4}) end)
end
local function notify(title, content)
    if global.VortexionBloxNotify then
        global.VortexionBloxNotify(title,content)
    end
end
local okWindow, window = pcall(function()
    return ui:CreateWindow({Title="BloxStrike", Size=UDim2.fromOffset(580,460)})
end)
if not okWindow or not window then
    global.VortexionBootError = "BloxStrike/CreateWindow: " .. tostring(window)
    warn("[Vortexion/BloxStrike] " .. global.VortexionBootError)
    pcall(function() ui:Destroy() end)
    cleanup()
    return
end
ui:OnDestroy(cleanup)
ownCleanup(function()
    if global.VortexionBloxCleanup == cleanup then
        global.VortexionBloxCleanup = nil
        global.VortexionBloxNotify = nil
    end
    pcall(function() ui:Destroy() end)
end)
local bootFailures = {}
local function reportBootFailure(component, message)
    local detail = tostring(component) .. ": " .. tostring(message):sub(1, 160)
    table.insert(bootFailures, detail)
    ui.BootStatus, ui.BootError = "partial", table.concat(bootFailures, "; ")
    warn("[Vortexion/BloxStrike] " .. detail)
end
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

--=========================================================================
-- Team folder cache: the old code re-walked Workspace.Characters twice per
-- player per frame. One 250ms map rebuild serves every caller.
--=========================================================================
local folderCache = { at = 0, map = {} }
local function rebuildFolderMap()
    folderCache.map = {}
    local root=Workspace:FindFirstChild("Characters")
    if root then
        for _,name in ipairs({"Terrorists","Counter-Terrorists"}) do
            local folder=root:FindFirstChild(name)
            if folder then
                for _,child in ipairs(folder:GetChildren()) do
                    folderCache.map[child.Name]=folder
                end
            end
        end
    end
    folderCache.at = tick()
end
local function teamFolder(player)
    if tick()-folderCache.at > 0.25 then rebuildFolderMap() end
    return folderCache.map[player.Name]
end
local function characterOf(player)
    if not player then return LocalPlayer and LocalPlayer.Character end
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

local ctx={
    Players=Players,RunService=RunService,Workspace=Workspace,
    ReplicatedStorage=ReplicatedStorage,Lighting=Lighting,Input=UserInputService,
    LocalPlayer=LocalPlayer,UI=ui,Window=window,Tabs=tabs,
    Notify=notify,IsCurrent=isCurrent,Own=ownConnection,OnCleanup=ownCleanup,
    Character=characterOf,Living=livingCharacter,TeamFolder=teamFolder,
    Enemy=isEnemy,PlayerFromModel=playerFromModel,
}

--=========================================================================
-- Module assembly. Common first (capability probe, guards, cloak target),
-- then cloak, then features. A failed factory leaves a no-op stub behind so
-- one broken subsystem never takes the UI down.
--=========================================================================
local function emptyModule()
    local empty = {}
    function empty:Update() end
    function empty:Start() end
    function empty:Stop() end
    function empty:GetLock() return nil end
    function empty:GetCandidates() return {} end
    function empty:PredictPoint(_, part) return part and part.Position or nil end
    function empty:GetEnvelope() return Vector3.zero end
    function empty:GetEnvelopeMargin() return 0.5 end
    function empty:Status() return {} end
    function empty:Rescan() end
    function empty:DebugSnapshot() return {} end
    return empty
end

local function setup(name, factory, key)
    if type(factory) ~= "function" then
        reportBootFailure(name, "factory missing")
        if key then ctx[key] = emptyModule() end
        return
    end
    local passed, result = pcall(factory, ctx)
    if not passed then
        reportBootFailure(name, result)
        notify(name.." 模块失败", tostring(result))
        if key then ctx[key] = emptyModule() end
    elseif type(result) == "table" and key then
        ctx[key] = result
    end
end

setup("Common", BloxCommonFactory)
local common = ctx
ownCleanup(function()
    if type(common.Cloak) == "table" and type(common.Cloak.Stop) == "function" then pcall(common.Cloak.Stop) end
    for i = #(common.Disposers or {}), 1, -1 do
        pcall(common.Disposers[i])
        common.Disposers[i] = nil
    end
end)
local passedCloak, cloak = false, "cloak factory missing"
if type(BloxCloakFactory) == "function" then
    passedCloak, cloak = pcall(BloxCloakFactory, common)
end
if passedCloak and type(cloak) == "table" then
    common.Cloak = cloak
else
    reportBootFailure("Cloak", cloak)
    common.Cloak = nil
end

setup("战斗", BloxCombatFactory, "Combat")
setup("子弹追踪", BloxBulletFactory, "Bullet")
setup("视觉", BloxVisualFactory)
setup("皮肤", BloxCosmeticFactory)

-- R2.6: no global __namecall/metatable hook during boot.  Some mobile
-- executors can terminate the host process inside hookmetamethod, where
-- pcall cannot recover. Protect() remains an optional weak registry, but
-- does NOT claim to hide instances from game code in this safe mode.
common.CloakAutoHookDisabled = true

--=========================================================================
-- Shared render loop: one BindToRenderStep(Last) drives Combat and Bullet.
-- Per-frame dt below 4ms-worth is skipped (physics hiccups), each subsystem
-- is guard-wrapped, and over-budget frames are counted for the debug channel.
--=========================================================================
local budgets = { Combat = 1.2, Bullet = 0.6 }
local costs = { Combat = 0, Bullet = 0 }
local slowLoops = 0
local frameName = "VortexionBloxFrame_" .. tostring(generation)
RunService:BindToRenderStep(frameName, Enum.RenderPriority.Last.Value, function(dt)
    if not isCurrent() then return end
    if dt < 0.004 then return end
    -- Idle load is deliberately zero: off means no combat/projectile scans.
    local combatActive = ctx.Combat and type(ctx.Combat.IsActive) == "function" and ctx.Combat:IsActive()
    if combatActive then
        local t0 = tick()
        common.Guard("Frame.Combat", function() ctx.Combat:Update(dt) end)
        costs.Combat = tick() - t0
    else
        costs.Combat = 0
    end
    local bulletActive = ctx.Bullet and type(ctx.Bullet.IsActive) == "function" and ctx.Bullet:IsActive()
    if bulletActive then
        local t0 = tick()
        common.Guard("Frame.Bullet", function() ctx.Bullet:Update(dt) end)
        costs.Bullet = tick() - t0
    else
        costs.Bullet = 0
    end
    for name, cost in pairs(costs) do
        if cost * 1000 > budgets[name] then slowLoops += 1 end
    end
end)
ownCleanup(function() RunService:UnbindFromRenderStep(frameName) end)

task.spawn(function()
    while isCurrent() do
        task.wait(2)
        if not isCurrent() then break end
        if common.Debug then
            local combat = ctx.Combat and ctx.Combat:DebugSnapshot() or {}
            local bullet = ctx.Bullet and ctx.Bullet:Status() or {}
            print(("[Vortexion/BloxStrike] frame combat=%s cand=%d hit=%d(%.2fms) bullet path=%s bullets=%d(%.2fms) slow=%d hooks=%d remotes=%d/%d"):format(
                tostring(combat.locked or "-"), tonumber(combat.candidates) or 0, tonumber(combat.hitEntries) or 0, costs.Combat * 1000,
                tostring(bullet.path or "-"), tonumber(bullet.bullets) or 0, costs.Bullet * 1000,
                slowLoops,
                tonumber(bullet.hooks) or 0,
                tonumber(bullet.remotes) or 0, tonumber(bullet.totalRemotes) or 0))
        end
    end
end)

--=========================================================================
-- Settings tab: debug channel, performance readout, environment probe,
-- unload.
--=========================================================================
tabs.Settings:AddToggle("BloxDebug",{Title="调试日志",Default=false,Callback=function(v)
    common.Debug = v
end})
tabs.Settings:AddParagraph({Title="BloxStrike 兼容说明",
    Content="R2.6 稳定启动模式：默认不安装全局枚举 Hook。战斗/追踪全部关闭时跳过其帧计算；皮肤分类延后限量生成。武器页手动开启的高级追踪仍依赖执行器能力，异常时应关闭。"})
tabs.Settings:AddButton({Title="子模块初始化诊断",Callback=function()
    notify("BloxStrike 启动诊断",#bootFailures > 0 and table.concat(bootFailures, " / ")
        or "模块工厂未报告失败；功能运行仍需实际测试")
end})
tabs.Settings:AddButton({Title="检查运行状态",Callback=function()
    local assets=ReplicatedStorage:FindFirstChild("Assets")
    local skins=assets and assets:FindFirstChild("Skins")
    local characters=Workspace:FindFirstChild("Characters")
    local components=ReplicatedStorage:FindFirstChild("Components")
    local weapon=components and components:FindFirstChild("Weapon")
    local bullet=weapon and weapon:FindFirstChild("Classes") and weapon.Classes:FindFirstChild("Bullet")
    local status=ctx.Bullet and ctx.Bullet:Status() or {}
    notify("运行环境检查",(characters and "角色目录正常" or "角色目录未加载")
        .." / "..(skins and "皮肤目录正常" or "皮肤目录未加载")
        .." / "..(weapon and "武器组件正常" or "武器组件未加载")
        .." / "..(bullet and "Bullet 模块存在" or "Bullet 模块未找到")
        .." / 追踪路径 "..tostring(status.path or "-"))
end})
tabs.Settings:AddButton({Title="性能状态",Callback=function()
    notify("性能状态",("战斗 %.2fms / 子弹 %.2fms，超预算帧 %d"):format(
        costs.Combat*1000, costs.Bullet*1000, slowLoops))
end})
tabs.Settings:AddButton({Title="卸载全部 BloxStrike 功能",Callback=function()
    cleanup()
    pcall(function() ui:Destroy() end)
end})

window:SelectTab(1)
notify("Vortexion - BloxStrike","功能模块已加载；进入对局后启用对应功能")
