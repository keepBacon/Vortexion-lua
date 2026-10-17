-- Vortexion Forsaken R2.5: deliberately small, lifecycle-owned client runtime.
-- The legacy 3,800-line menu, external code loaders and speculative remotes
-- have been retired. Every remaining control owns its side effects.
local WindBridgeFactory = nil
local WindUI = nil
local ForsakenEnhancementsFactory = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local user = Players.LocalPlayer
assert(user, "Forsaken: LocalPlayer not ready")
local gui = user:FindFirstChildOfClass("PlayerGui") or user:WaitForChild("PlayerGui", 8)
assert(gui, "Forsaken: PlayerGui unavailable")
local env = (getgenv and getgenv()) or _G
if type(env.VortexionForsakenCleanup) == "function" then
    pcall(env.VortexionForsakenCleanup)
end

local bridge = WindBridgeFactory(WindUI, {Name = "Forsaken", Folder = "VortexionForsaken"})
assert(bridge and bridge.Active, "Forsaken: WindUI bridge unavailable")
local window = bridge:CreateWindow({Title = "Forsaken · R2.8"})
assert(window, "Forsaken: window creation failed")
local tabs = {
    vision = window:AddTab({Title = "感知", Icon = "lucide-eye"}),
    player = window:AddTab({Title = "角色", Icon = "lucide-user"}),
    defense = window:AddTab({Title = "防御", Icon = "lucide-shield"}),
    generators = window:AddTab({Title = "发电机", Icon = "lucide-wrench"}),
    system = window:AddTab({Title = "系统", Icon = "lucide-settings"}),
}
window:InstallSettings(tabs.system)

local enhancements = ForsakenEnhancementsFactory({Player=user, Bridge=bridge, Tabs=tabs})

local state = {alive = true, killers = false, survivors = false,
    generators = false, alert = false, fovEnabled = false, fov = 80,
    maxDistance = 240, alertDistance = 35, markers = {}, lastAlert = 0,
    ticker = nil, originalFov = setmetatable({}, {__mode="k"}),
    scans = 0, objects = 0, lastProblem = "none"}
local function report(tag, err)
    local message = tostring(tag) .. ": " .. tostring(err)
    state.lastProblem = message:sub(1, 350)
    warn("[Vortexion/Forsaken] " .. state.lastProblem)
end
local function safe(tag, fn)
    local ok, result = pcall(fn)
    if not ok then report(tag, result) end
    return ok, result
end
local function clearMarker(model)
    local marker = state.markers[model]
    if marker then
        state.markers[model] = nil
        safe("marker cleanup", function() marker:Destroy() end)
    end
end
local function clearMarkers()
    for model in pairs(state.markers) do clearMarker(model) end
    state.objects = 0
end
local function restoreFov()
    for camera, fov in pairs(state.originalFov) do
        safe("restore FOV", function() if camera.Parent then camera.FieldOfView = fov end end)
        state.originalFov[camera] = nil
    end
end
local function applyFov()
    if not state.fovEnabled then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    if state.originalFov[camera] == nil then
        state.originalFov[camera] = camera.FieldOfView
    end
    camera.FieldOfView = math.clamp(state.fov, 60, 120)
end
local function getRoot(model)
    if not model or not model.Parent then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso")
end
local function sourceFolders()
    local root = Workspace:FindFirstChild("Players")
    if not root then return nil, nil end
    return root:FindFirstChild("Killers"), root:FindFirstChild("Survivors")
end
local function countReadyCharacters(folder)
    if not folder then return 0, 0 end
    local total, ready = 0, 0
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            total += 1
            if getRoot(child) and child ~= user.Character then
                ready += 1
            end
        end
    end
    return total, ready
end

local function addCandidate(target, model, kind)
    if not model or not model:IsA("Model") or model == user.Character then return end
    if getRoot(model) then target[model] = kind end
end
local function candidates()
    local selected = {}
    local killers, survivors = sourceFolders()
    if state.killers or state.alert then
        if killers then for _, model in ipairs(killers:GetChildren()) do addCandidate(selected, model, "Killer") end end
    end
    if state.survivors then
        if survivors then for _, model in ipairs(survivors:GetChildren()) do addCandidate(selected, model, "Survivor") end end
    end
    if state.generators then
        local map = Workspace:FindFirstChild("Map")
        local inGame = map and map:FindFirstChild("Ingame")
        local candidates = {
            map and map:FindFirstChild("Generators"),
            inGame and inGame:FindFirstChild("Generators"),
            inGame and inGame:FindFirstChild("Map") and inGame.Map:FindFirstChild("Generators"),
        }
        for _, folder in pairs(candidates) do
            if folder then
                for _, model in ipairs(folder:GetChildren()) do
                    if model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) then
                        selected[model] = "Generator"
                    end
                end
            end
        end
    end
    return selected
end
local function markerFor(model, kind)
    local existing = state.markers[model]
    if existing then return existing end
    local highlight = Instance.new("Highlight")
    highlight.Name = "VortexionMarker"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.85
    highlight.OutlineTransparency = 0.08
    highlight.Adornee = model
    highlight.FillColor = kind == "Killer" and Color3.fromRGB(235, 78, 78)
        or kind == "Survivor" and Color3.fromRGB(78, 176, 121)
        or Color3.fromRGB(245, 191, 85)
    highlight.OutlineColor = highlight.FillColor
    highlight.Parent = gui
    state.markers[model] = highlight
    return highlight
end
local function tickVisual()
    state.scans += 1
    local playerRoot = getRoot(user.Character)
    if not playerRoot then clearMarkers(); return end
    local required = candidates()
    local visible = {}
    local budget = 32 -- Bound per-refresh allocations on mobile.
    local nearestThreat
    for model, kind in pairs(required) do
        local root = getRoot(model) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if root and root:IsA("BasePart") then
            local distance = (root.Position - playerRoot.Position).Magnitude
            if kind == "Killer" and distance <= state.alertDistance then
                nearestThreat = math.min(nearestThreat or math.huge, distance)
            end
            local show = (kind == "Killer" and state.killers)
                or (kind == "Survivor" and state.survivors)
                or (kind == "Generator" and state.generators)
            if show and distance <= state.maxDistance and budget > 0 then
                budget -= 1
                visible[model] = true
                safe("highlight", function() markerFor(model, kind) end)
            end
        end
    end
    for model in pairs(state.markers) do
        if not visible[model] or not model.Parent then clearMarker(model) end
    end
    local count = 0
    for _ in pairs(state.markers) do count += 1 end
    state.objects = count
    if state.alert and nearestThreat and os.clock() - state.lastAlert > 5 then
        state.lastAlert = os.clock()
        bridge:Notify({Title="附近有杀手", Content=("距离约 %d studs"):format(nearestThreat), Duration=2})
    end
end
local function refreshScheduler()
    local enabled = state.killers or state.survivors or state.generators or state.alert or state.fovEnabled
    if not enabled and state.ticker then state.ticker:Disconnect(); state.ticker=nil end
    if not enabled then clearMarkers(); return end
    if state.ticker then return end
    local accumulated = 0
    state.ticker = RunService.Heartbeat:Connect(function(dt)
        if not state.alive then return end
        accumulated += math.min(dt, 0.3)
        if accumulated < 0.25 then return end -- 4Hz max, disabled = zero listeners.
        accumulated = 0
        safe("refresh", function()
            applyFov()
            if state.killers or state.survivors or state.generators or state.alert then tickVisual() end
        end)
    end)
end
local function shutdown()
    if not state.alive then return end
    state.alive = false
    if enhancements then enhancements:Destroy() end
    if state.ticker then state.ticker:Disconnect(); state.ticker = nil end
    clearMarkers()
    restoreFov()
    if env.VortexionForsakenCleanup == shutdown then env.VortexionForsakenCleanup = nil end
end
env.VortexionForsakenCleanup = shutdown
bridge:OnDestroy(shutdown)

tabs.vision:AddParagraph({Title="运行架构", Content="感知与新增角色/防御/发电机功能均可独立开关，关闭后释放临时资源。"})
tabs.vision:AddToggle("FsKillerESP", {Title="杀手高亮", Default=false,
    Callback=function(v) state.killers=v; refreshScheduler() end})
tabs.vision:AddToggle("FsSurvivorESP", {Title="幸存者高亮", Default=false,
    Callback=function(v) state.survivors=v; refreshScheduler() end})
tabs.vision:AddToggle("FsGeneratorESP", {Title="发电机高亮", Default=false,
    Callback=function(v) state.generators=v; refreshScheduler() end})
tabs.vision:AddSlider("FsVisionDistance", {Title="高亮距离", Min=40, Max=600, Default=240, Rounding=0,
    Callback=function(v) state.maxDistance=v end})
tabs.vision:AddToggle("FsKillerWarning", {Title="附近杀手预警", Default=false,
    Callback=function(v) state.alert=v; refreshScheduler() end})
tabs.vision:AddSlider("FsWarningDistance", {Title="预警距离", Min=10, Max=100, Default=35, Rounding=0,
    Callback=function(v) state.alertDistance=v end})

tabs.player:AddToggle("FsCameraFov", {Title="自定义视场角", Default=false,
    Callback=function(v) state.fovEnabled=v; if not v then restoreFov() end; refreshScheduler(); if v then safe("FOV",applyFov) end end})
tabs.player:AddSlider("FsCameraFovValue", {Title="视场角 (60–120)", Min=60, Max=120, Default=80, Rounding=0,
    Callback=function(v) state.fov=v; if state.fovEnabled then safe("FOV", applyFov) end end})

tabs.system:AddButton({Title="检查游戏结构", Callback=function()
    local killers,survivors=sourceFolders()
    local kTotal,kReady=countReadyCharacters(killers)
    local sTotal,sReady=countReadyCharacters(survivors)
    local enabled=state.killers or state.survivors or state.generators or state.alert
    local mode=enabled and "扫描中" or "感知开关关闭（不扫描）"
    local msg = ("Killers=%s %d/%d Survivors=%s %d/%d Markers=%d Refresh=%d %s Error=%s")
        :format(tostring(killers~=nil), kReady, kTotal,
            tostring(survivors~=nil), sReady, sTotal,
            state.objects, state.scans, mode, state.lastProblem)
    bridge:Notify({Title="Forsaken 诊断", Content=msg, Duration=8})
end})
tabs.system:AddButton({Title="重进当前游戏", Callback=function()
    safe("rejoin",function() TeleportService:Teleport(game.PlaceId, user) end)
end})
tabs.system:AddButton({Title="卸载 Forsaken 功能", Callback=function()
    shutdown()
    bridge:Destroy()
end})
tabs.system:AddParagraph({Title="运行限制", Content="场景结构可能随游戏更新变化。检测不到目标时会保持空状态，不会伪造功能成功；未进行 Roblox 安卓实测。"})
window:SelectTab(1)
bridge:Notify({Title="Forsaken", Content="R2.9 已加载；感知功能需手动开启，菜单场景没有角色模型时不会生成标记", Duration=5})
