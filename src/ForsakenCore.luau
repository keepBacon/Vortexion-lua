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
local window = bridge:CreateWindow({Title = "Forsaken · R2.13"})
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
    maxDistance = 400, alertDistance = 35, markers = {}, lastAlert = 0,
    occludedTransparency = 65, visibleTransparency = 20,
    markerSeen = setmetatable({}, {__mode = "k"}),
    markerKinds = setmetatable({}, {__mode = "k"}),
    visibilityCache = setmetatable({}, {__mode = "k"}),
    blockedCount = 0, clearCount = 0, stalenessGrace = 1.25,
    ticker = nil, originalFov = setmetatable({}, {__mode="k"}),
    scans = 0, objects = 0, lastProblem = "none",
    candidateCount = 0, inRangeCount = 0, markerFailures = 0,
    lastScanReason = "尚未开始", scanMode = "idle", stateRepairs = 0,
    characterGeneration = 0, spectatorScans = 0, reconcileElapsed = 0,
    watchConnection = nil, lifecycleConnections = {}}
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
        state.markerSeen[model] = nil
        state.markerKinds[model] = nil
        state.visibilityCache[model] = nil
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
    if state.generators and enhancements and type(enhancements.EnumerateGenerators) == "function" then
        for _, model in ipairs(enhancements.EnumerateGenerators()) do
            if model.Parent and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) then
                selected[model] = "Generator"
            end
        end
    end
    return selected
end
-- Roblox Highlight has one FillTransparency value. It cannot directly assign
-- separate transparency for occluded and unobstructed pixels simultaneously.
-- A bounded camera raycast selects the applicable alpha per target (4 Hz),
-- while DepthMode=AlwaysOnTop allows the occluded highlight to remain visible.
local function blockedByWorld(model, part, camera)
    if not camera or not camera.CFrame then return false end
    local origin = camera.CFrame.Position
    local direction = part.Position - origin
    if direction.Magnitude <= 0.25 then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = user.Character and {user.Character} or {}
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, params)
    return result ~= nil and not result.Instance:IsDescendantOf(model)
end
local function alphaFor(model, part, camera)
    local now = os.clock()
    local cache = state.visibilityCache[model]
    local ok, obstructed = safe("occlusion raycast", function()
        return blockedByWorld(model, part, camera)
    end)
    if not ok then return state.visibleTransparency / 100 end
    if cache and cache.blocked ~= obstructed then
        if cache.pending == obstructed then
            cache.samples = cache.samples + 1
        else
            cache.pending, cache.samples = obstructed, 1
        end
        if cache.samples >= 2 then
            cache.blocked, cache.pending, cache.samples = obstructed, nil, 0
        end
    elseif not cache then
        cache = {blocked = obstructed, pending = nil, samples = 0}
        state.visibilityCache[model] = cache
    else
        cache.pending, cache.samples = nil, 0
    end
    if cache.blocked then
        state.blockedCount += 1
    else
        state.clearCount += 1
    end
    return (cache.blocked and state.occludedTransparency or state.visibleTransparency) / 100
end
local function markerFor(model, kind, part, camera)
    local existing = state.markers[model]
    if existing and not existing.Parent then
        state.markers[model] = nil
        existing = nil
    end
    local highlight = existing
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "VortexionMarker"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = model
        highlight.FillColor = kind == "Killer" and Color3.fromRGB(235, 78, 78)
            or kind == "Survivor" and Color3.fromRGB(78, 176, 121)
            or Color3.fromRGB(245, 191, 85)
        highlight.OutlineColor = highlight.FillColor
        highlight.Parent = model
        state.markers[model] = highlight
    end
    local alpha = alphaFor(model, part, camera)
    highlight.FillTransparency = alpha
    highlight.OutlineTransparency = alpha
    state.markerKinds[model] = kind
    return highlight
end
local function tickVisual()
    state.scans += 1
    state.candidateCount, state.inRangeCount = 0, 0
    state.blockedCount, state.clearCount = 0, 0
    -- The camera is an independent observer during death/spectate. Do not
    -- disable ESP merely because the player's previous character was removed.
    local playerRoot = getRoot(user.Character)
    local humanoid = user.Character and user.Character:FindFirstChildOfClass("Humanoid")
    local aliveCharacter = playerRoot and (not humanoid or humanoid.Health > 0)
    local camera = Workspace.CurrentCamera
    local origin = aliveCharacter and playerRoot.Position
        or (camera and camera.CFrame and camera.CFrame.Position)
    if not origin then
        state.scanMode = "no-origin"
        state.lastScanReason = "没有有效角色或观战相机"
        clearMarkers()
        return
    end
    if aliveCharacter then
        state.scanMode = "character"
        state.lastScanReason = "存活角色扫描"
    else
        state.scanMode = "spectator"
        state.spectatorScans += 1
        state.lastScanReason = "观战相机扫描"
    end
    local required = candidates()
    local visible = {}
    local now = os.clock()
    local budget = 32 -- Bound per-refresh allocations on mobile.
    local nearestThreat
    for model, kind in pairs(required) do
        state.candidateCount += 1
        local root = getRoot(model) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if root and root:IsA("BasePart") then
            local distance = (root.Position - origin).Magnitude
            if kind == "Killer" and distance <= state.alertDistance then
                nearestThreat = math.min(nearestThreat or math.huge, distance)
            end
            local show = (kind == "Killer" and state.killers)
                or (kind == "Survivor" and state.survivors)
                or (kind == "Generator" and state.generators)
            local exitHysteresis = state.markers[model] and 40 or 0
            if show and distance <= state.maxDistance + exitHysteresis then
                state.inRangeCount += 1
                if budget > 0 then
                    budget -= 1
                    local ok = safe("highlight", function() markerFor(model, kind, root, camera) end)
                    if ok then
                        visible[model] = true
                        state.markerSeen[model] = now
                    else state.markerFailures = state.markerFailures + 1 end
                end
            end
        end
    end
    for model in pairs(state.markers) do
        -- A temporary missing model, camera switch, or distance crossing should
        -- not destroy/recreate the highlight on every 250 ms scan.
        local kind = state.markerKinds[model]
        local enabled = (kind == "Killer" and state.killers)
            or (kind == "Survivor" and state.survivors)
            or (kind == "Generator" and state.generators)
        if not model.Parent or not enabled or
            (not visible[model] and now - (state.markerSeen[model] or 0) > state.stalenessGrace) then
            clearMarker(model)
        end
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
    if not enabled then
        state.scanMode = "off"
        state.lastScanReason = "感知功能关闭"
        clearMarkers()
        return
    end
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
    if state.watchConnection then state.watchConnection:Disconnect(); state.watchConnection = nil end
    for _, connection in ipairs(state.lifecycleConnections) do
        connection:Disconnect()
    end
    table.clear(state.lifecycleConnections)
    clearMarkers()
    restoreFov()
    if env.VortexionForsakenCleanup == shutdown then env.VortexionForsakenCleanup = nil end
end
env.VortexionForsakenCleanup = shutdown
bridge:OnDestroy(shutdown)
if type(bridge.RegisterFeatureHealth) == "function" then
    bridge:RegisterFeatureHealth("Forsaken", function()
        return ("活跃=%s 杀手=%s 幸存者=%s 发电机=%s 扫描=%d 标记=%d 观战扫描=%d 最近问题=%s")
            :format(tostring(state.alive), tostring(state.killers), tostring(state.survivors),
                tostring(state.generators), state.scans, state.objects, state.spectatorScans,
                tostring(state.lastProblem))
    end)
end

tabs.vision:AddParagraph({Title="运行架构", Content="感知与新增角色/防御/发电机功能均可独立开关，关闭后释放临时资源。"})
tabs.vision:AddToggle("FsKillerESP", {Title="杀手高亮", Default=false,
    Callback=function(v) state.killers=v; refreshScheduler() end})
tabs.vision:AddToggle("FsSurvivorESP", {Title="幸存者高亮", Default=false,
    Callback=function(v) state.survivors=v; refreshScheduler() end})
tabs.vision:AddToggle("FsGeneratorESP", {Title="发电机高亮", Default=false,
    Callback=function(v) state.generators=v; refreshScheduler() end})
-- Reconcile the three layers (native WindUI, bridge option, gameplay state).
-- The user's preference is intentionally NOT cleared on CharacterRemoving,
-- Humanoid.Died or spectator camera transitions.
local function synchronizeVisionOptions()
    local settings = {
        {"FsKillerESP", "killers"},
        {"FsSurvivorESP", "survivors"},
        {"FsGeneratorESP", "generators"},
        {"FsKillerWarning", "alert"},
    }
    local changed = false
    for _, entry in ipairs(settings) do
        local option = bridge.Options and bridge.Options[entry[1]]
        if option then
            if type(option.SyncFromNative) == "function" then
                safe("native sync " .. entry[1], function() option:SyncFromNative() end)
            end
            if type(option.Value) == "boolean" and state[entry[2]] ~= option.Value then
                state[entry[2]] = option.Value
                state.stateRepairs += 1
                changed = true
            end
        end
    end
    if changed then refreshScheduler() end
end

local function bindCharacterLifecycle(character)
    state.characterGeneration += 1
    clearMarkers()
    state.lastScanReason = "角色变化，等待重新扫描"
    -- The scanner and preferences remain alive through spectator transitions.
end
if user.CharacterAdded then
    table.insert(state.lifecycleConnections, user.CharacterAdded:Connect(bindCharacterLifecycle))
end
if user.CharacterRemoving then
    table.insert(state.lifecycleConnections, user.CharacterRemoving:Connect(function()
        clearMarkers()
        state.scanMode = "spectator"
        state.lastScanReason = "角色已移除，等待观战相机"
    end))
end
state.watchConnection = RunService.Heartbeat:Connect(function(dt)
    if not state.alive then return end
    state.reconcileElapsed += math.min(dt, 0.5)
    if state.reconcileElapsed < 1 then return end
    state.reconcileElapsed = 0
    synchronizeVisionOptions()
end)

tabs.vision:AddSlider("FsVisionDistance", {Title="高亮距离", Min=40, Max=600, Default=400, Rounding=0,
    Callback=function(v) state.maxDistance=v end})
tabs.vision:AddSlider("FsOccludedAlphaR213", {Title="ESP 遮挡时透明度 (%)", Min=0, Max=100,
    Default=65, Rounding=0, Callback=function(v) state.occludedTransparency = math.clamp(v, 0, 100) end})
tabs.vision:AddSlider("FsVisibleAlphaR213", {Title="ESP 无遮挡时透明度 (%)", Min=0, Max=100,
    Default=20, Rounding=0, Callback=function(v) state.visibleTransparency = math.clamp(v, 0, 100) end})
tabs.vision:AddParagraph({Title="ESP 透明度说明", Content="0% 完全不透明，100% 完全透明。通过限频射线检测遮挡，并提供短暂保留以减少闪烁。"})
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
    synchronizeVisionOptions()
    enabled=state.killers or state.survivors or state.generators or state.alert
    local mode=enabled and "扫描中" or "感知开关关闭（不扫描）"
    local function optionInfo(id, field)
        local option = bridge.Options and bridge.Options[id]
        local native = nil
        if option and type(option.GetNativeValue) == "function" then
            native = option:GetNativeValue()
        end
        return string.format("%s:UI=%s Bridge=%s Runtime=%s", field,
            tostring(native), tostring(option and option.Value), tostring(state[field]))
    end
    local msg = ("Killers=%s %d/%d Survivors=%s %d/%d Markers=%d Refresh=%d %s Error=%s\n" ..
        "%s / %s / %s\n模式=%s 原因=%s 状态修复=%d 角色代次=%d 观战扫描=%d 候选=%d 范围内=%d 高亮异常=%d")
        :format(tostring(killers~=nil), kReady, kTotal,
            tostring(survivors~=nil), sReady, sTotal,
            state.objects, state.scans, mode, state.lastProblem,
            optionInfo("FsKillerESP", "Killer"),
            optionInfo("FsSurvivorESP", "Survivor"),
            optionInfo("FsGeneratorESP", "Generator"),
            state.scanMode, state.lastScanReason, state.stateRepairs,
            state.characterGeneration, state.spectatorScans,
            state.candidateCount, state.inRangeCount, state.markerFailures)
    msg = msg .. string.format("\n遮挡检测=%d 无遮挡检测=%d 遮挡透明度=%d%% 无遮挡透明度=%d%%",
        state.blockedCount, state.clearCount, state.occludedTransparency, state.visibleTransparency)
    bridge:Notify({Title="Forsaken 诊断", Content=msg, Duration=12})
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
bridge:Notify({Title="Forsaken", Content="R2.13 已加载；感知功能需手动开启，菜单场景没有角色模型时不会生成标记", Duration=5})
