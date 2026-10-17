-- Vortexion Loader V2.1 / modular routing and diagnostic bootstrap.
-- Keep V1 standalone fallback available for controlled compatibility tests.
local VERSION = "2.12.0-runtime-evidence"
local DEFAULT_BASE = "https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/"
local LEGACY_BUNDLE = "dist/Vortexion_Wind.lua"
local MANIFEST_PATH = "dist/runtime-manifest.json"
local MAX_MANIFEST_SIZE = 32768
local MAX_BUNDLE_SIZE = 4 * 1024 * 1024
local env = (type(getgenv) == "function" and getgenv()) or _G

-- Destroy only the previous bootstrap panel. The game window owns its own lifecycle.
local previous = env.VortexionLoaderV2
if type(previous) == "table" and type(previous.Destroy) == "function" then
    pcall(function() previous:Destroy() end)
end

local state = {
    version = VERSION, stage = "bootstrap", status = "starting",
    error = nil, url = nil, logs = {}, cancelled = false, busy = false,
    gui = nil, ui = {}, startedAt = os.clock(), gameId = "?", placeId = "?",
    route = nil, routeReason = nil, downloadedBytes = 0, cacheHits = 0,
    legacyOnce = false, manifestTag = "unresolved",
}
env.VortexionLoaderV2 = state

local function stringify(value)
    local ok, result = pcall(tostring, value)
    return ok and result or "<unprintable error>"
end

local function traceError(err)
    local msg = stringify(err)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        local ok, trace = pcall(debug.traceback, msg, 2)
        if ok and type(trace) == "string" then return trace end
    end
    return msg
end

local function log(stage, message)
    local line = "[Vortexion/Loader V2][" .. stage .. "] " .. stringify(message)
    table.insert(state.logs, line)
    if #state.logs > 24 then table.remove(state.logs, 1) end
    warn(line)
end

function state:Destroy()
    self.cancelled = true
    if self.gui then pcall(function() self.gui:Destroy() end) end
    self.gui = nil
    self.ui = {}
    if env.VortexionLoaderV2 == self then env.VortexionLoaderV2 = nil end
end

local function diagnostic()
    local parts = {
        "Vortexion Loader " .. VERSION,
        "Stage: " .. state.stage,
        "Status: " .. state.status,
        "GameId: " .. state.gameId,
        "PlaceId: " .. state.placeId,
        "Route: " .. tostring(state.route or "unsupported"),
        "RouteReason: " .. tostring(state.routeReason or "unresolved"),
        "Build: " .. state.manifestTag,
        "Downloaded bytes: " .. tostring(state.downloadedBytes),
        "Cache hits: " .. tostring(state.cacheHits),
        "URL: " .. (state.url or "unresolved"),
        "Error: " .. (state.error or "none"),
        "Elapsed: " .. string.format("%.1fs", os.clock() - state.startedAt),
        "Recent logs:",
    }
    for _, line in ipairs(state.logs) do table.insert(parts, line) end
    return table.concat(parts, "\n")
end
state.GetDiagnostics = diagnostic

local function refresh()
    local ui = state.ui
    if not ui.status then return end
    pcall(function()
        ui.status.Text = state.status == "failed" and "加载失败 / " .. state.stage
            or state.status == "partial" and "部分功能初始化失败 / " .. state.stage
            or state.status == "success" and "初始化完成" or "正在加载 / " .. state.stage
        ui.detail.Text = state.error and (state.error:sub(1, 260))
            or (state.detail or "正在检查加载环境…")
        ui.detail.TextColor3 = state.error and Color3.fromRGB(248, 165, 161)
            or Color3.fromRGB(163, 170, 181)
        ui.retry.Visible = state.status == "failed" or state.status == "partial"
        if ui.legacy then ui.legacy.Visible = state.status == "failed" or state.status == "partial" end
        ui.copy.Visible = true
        ui.indicator.BackgroundColor3 = state.status == "failed" and Color3.fromRGB(229, 100, 94)
            or state.status == "success" and Color3.fromRGB(77, 185, 132)
            or Color3.fromRGB(231, 180, 91)
    end)
end

local function stage(name, detail)
    if state.cancelled then return false end
    state.stage = name
    state.detail = detail
    state.status = "running"
    state.error = nil
    log(name, detail)
    refresh()
    return true
end

local function fail(name, detail)
    if state.cancelled then return end
    state.stage = name
    state.status = "failed"
    state.error = stringify(detail):sub(1, 1800)
    log(name, "FAILED: " .. state.error)
    refresh()
end

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function label(parent, text, pos, size, font, color, wrap)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Text = text
    item.TextColor3 = color
    item.Font = font
    item.TextSize = size
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.TextWrapped = wrap == true
    item.Position = pos
    item.Size = UDim2.new(1, -32, 0, wrap and 58 or 24)
    item.Parent = parent
    return item
end

local function button(parent, text, xScale, xOffset, widthScale, widthOffset)
    local item = Instance.new("TextButton")
    item.Name = text
    item.Text = text
    item.TextSize = 12
    item.Font = Enum.Font.GothamMedium
    item.AutoButtonColor = true
    item.TextColor3 = Color3.fromRGB(232, 236, 240)
    item.BackgroundColor3 = Color3.fromRGB(53, 58, 67)
    item.Position = UDim2.new(xScale, xOffset, 0, 146)
    item.Size = UDim2.new(widthScale, widthOffset, 0, 29)
    item.Parent = parent
    addCorner(item, 6)
    return item
end

-- UI creation is best-effort: unsupported GUI permissions must never mask the real error.
local function createPanel()
    if type(Instance) ~= "table" or type(Instance.new) ~= "function" then
        log("ui", "Instance.new unavailable; fallback to executor console")
        return
    end
    local ok, reason = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionLoaderDiagnostics"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 10000
        state.gui = gui

        local roots = {}
        if type(gethui) == "function" then
            local got, root = pcall(gethui)
            if got and root then table.insert(roots, root) end
        end
        local serviceOk, core = pcall(function() return game:GetService("CoreGui") end)
        if serviceOk and core then table.insert(roots, core) end
        local playersOk, players = pcall(function() return game:GetService("Players") end)
        if playersOk and players and players.LocalPlayer then
            local got, playerGui = pcall(function() return players.LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
            if got and playerGui then table.insert(roots, playerGui) end
        end
        local parented = false
        for _, root in ipairs(roots) do
            local placed = pcall(function() gui.Parent = root end)
            if placed and gui.Parent == root then parented = true break end
        end
        if not parented then error("Unable to attach ScreenGui to gethui/CoreGui/PlayerGui") end

        local frame = Instance.new("Frame")
        frame.Name = "Panel"
        frame.AnchorPoint = Vector2.new(0, 1)
        frame.Position = UDim2.new(0, 12, 1, -18)
        frame.Size = UDim2.new(1, -24, 0, 222)
        frame.BackgroundColor3 = Color3.fromRGB(26, 29, 35)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        local sizeConstraint = Instance.new("UISizeConstraint")
        sizeConstraint.MaxSize = Vector2.new(332, 222)
        sizeConstraint.Parent = frame
        addCorner(frame, 9)

        local indicator = Instance.new("Frame")
        indicator.Name = "StatusIndicator"
        indicator.Size = UDim2.new(0, 7, 0, 7)
        indicator.Position = UDim2.new(0, 16, 0, 22)
        indicator.BorderSizePixel = 0
        indicator.Parent = frame
        addCorner(indicator, 4)
        state.ui.indicator = indicator

        local heading = label(frame, "VORTEXION  /  LOADER", UDim2.new(0, 30, 0, 10), 13,
            Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), false)
        heading.Size = UDim2.new(1, -68, 0, 30)
        local status = label(frame, "准备中", UDim2.new(0, 16, 0, 45), 13,
            Enum.Font.GothamMedium, Color3.fromRGB(225, 230, 235), false)
        local detail = label(frame, "正在检查加载环境…", UDim2.new(0, 16, 0, 76), 12,
            Enum.Font.Gotham, Color3.fromRGB(163, 170, 181), true)
        detail.TextYAlignment = Enum.TextYAlignment.Top
        state.ui.status = status
        state.ui.detail = detail

        local retry = button(frame, "重新尝试", 0, 16, 0.32, -18)
        local copy = button(frame, "复制诊断", 0.32, 7, 0.32, -13)
        local close = button(frame, "关闭提示", 0.64, 5, 0.36, -21)
        state.ui.retry, state.ui.copy = retry, copy
        local legacy = button(frame, "兼容单包加载（排障）", 0, 16, 1, -32)
        legacy.Position = UDim2.new(0, 16, 0, 184)
        legacy.Visible = false
        state.ui.legacy = legacy
        legacy.MouseButton1Click:Connect(function()
            if state.cancelled or state.busy then return end
            state.legacyOnce = true
            if type(state.Retry) == "function" then task.spawn(state.Retry) end
        end)
        retry.Visible = false
        retry.MouseButton1Click:Connect(function()
            if state.cancelled or state.busy then return end
            if type(state.Retry) == "function" then task.spawn(state.Retry) end
        end)
        copy.MouseButton1Click:Connect(function()
            local clip = type(setclipboard) == "function" and setclipboard
                or type(toclipboard) == "function" and toclipboard or nil
            if clip then
                local worked, err = pcall(clip, diagnostic())
                if worked then log("diagnostics", "copied to clipboard")
                else log("diagnostics", "copy failed: " .. stringify(err)) end
            else
                log("diagnostics", "Clipboard API unavailable; diagnostics follow")
                warn(diagnostic())
            end
        end)
        close.MouseButton1Click:Connect(function() state:Destroy() end)
    end)
    if not ok then
        log("ui", "Diagnostic panel unavailable: " .. stringify(reason))
        if state.gui then pcall(function() state.gui:Destroy() end) end
        state.gui = nil
        state.ui = {}
    end
end

-- Session cache avoids repeated network and compilation input downloads after a retry.
-- Entries are keyed by published SHA and size, and confined to the current executor VM.
local cache = env.VortexionLoaderCache
if type(cache) ~= "table" then cache = {}; env.VortexionLoaderCache = cache end

local function fetchText(base, artifact, useCache)
    assert(type(artifact) == "table" and type(artifact.path) == "string", "Invalid bundle descriptor")
    local path = artifact.path
    assert(path:match("^dist/[%w_%-%.]+$") and not path:find("..", 1, true), "Unsafe bundle path")
    local bytes = tonumber(artifact.bytes)
    assert(bytes and bytes >= 64 and bytes <= MAX_BUNDLE_SIZE, "Invalid bundle length")
    local url = base .. path
    state.url = url
    local key = artifact.sha256
    if useCache and type(key) == "string" then
        local item = cache[key]
        if type(item) == "string" and #item == bytes then
            state.cacheHits += 1
            if state.cacheKeys then table.insert(state.cacheKeys, key) end
            return item
        end
    end
    local source, lastError
    for attempt = 1, 3 do
        if state.cancelled then return nil end
        local ok, result = pcall(function() return game:HttpGet(url) end)
        if state.cancelled then return nil end
        if ok and type(result) == "string" and #result == bytes then
            source = result
            break
        end
        lastError = ok and ("unexpected byte count: " .. tostring(type(result) == "string" and #result or -1)
            .. ", expected " .. tostring(bytes)) or stringify(result)
        if attempt < 3 then
            log("network", "Attempt " .. attempt .. ": " .. lastError)
            task.wait(attempt * 0.35)
        end
    end
    if not source then error("Network/data error (3 attempts): " .. tostring(lastError)) end
    if source:sub(1, 128):lower():match("^%s*<") then
        error("Received HTML instead of Luau script")
    end
    state.downloadedBytes += #source
    -- Opportunistic SHA-256 check when the executor exposes a compatible hash API.
    -- The manifest itself is HTTPS-delivered but is not a signed release index.
    if type(key) == "string" and #key == 64 and key:match("^%x+$") then
        local crypto = (type(crypt) == "table" and crypt)
            or (type(syn) == "table" and type(syn.crypt) == "table" and syn.crypt)
        local hash = crypto and crypto.hash
        if type(hash) == "function" then
            local valid, digest = pcall(hash, source, "sha256")
            if valid and type(digest) == "string" and #digest == 64 and digest:match("^%x+$") then
                if digest:lower() ~= key:lower() then error("SHA-256 mismatch: " .. path) end
            else
                log("integrity", "Hash API incompatible; size verified only: " .. path)
            end
        else
            log("integrity", "SHA-256 unavailable; size verified only: " .. path)
        end
    end
    if type(key) == "string" and key:match("^%x+$") and #key == 64 then
        cache[key] = source
        -- Cache only the two blobs of the current successful loader generation.
        -- Old versions must not accumulate indefinitely in long sessions.
        if state.cacheKeys then table.insert(state.cacheKeys, key) end
        if state.newCacheKeys then table.insert(state.newCacheKeys, key) end
    end
    return source
end

local function compileSource(textSource, what)
    local ok, fn = pcall(loadstring, textSource)
    if not ok then error(what .. " compiler exception: " .. stringify(fn)) end
    if type(fn) ~= "function" then error(what .. " compile error: " .. stringify(fn)) end
    return fn
end

local function selectRoute(routes)
    assert(type(routes) == "table", "Route table missing")
    local universe, place = state.gameId, state.placeId
    if universe == tostring(routes.aotr_universe) then
        local name = type(routes.aotr_places) == "table" and routes.aotr_places[place]
        return name, name and "aotr-place" or "unsupported-aotr-scene"
    end
    local name = type(routes.universes) == "table" and routes.universes[universe]
    if name then return name, "universe" end
    name = type(routes.places) == "table" and routes.places[place]
    return name, name and "place-fallback" or "unsupported-experience"
end

local function run()
    if state.cancelled or state.busy then return end
    state.busy = true
    state.startedAt = os.clock()
    state.error = nil
    state.downloadedBytes, state.cacheHits = 0, 0
    state.cacheKeys = {}
    state.newCacheKeys = {}
    env.VortexionBootError = nil
    env.VortexionTextCompatCount = 0
    env.VortexionTextCompatLast = nil
    local function work()
        stage("preflight", "检查 Roblox 环境与执行器 API")
        if game == nil then error("Roblox game object unavailable") end
        if type(loadstring) ~= "function" then error("loadstring API unavailable") end
        if type(task) ~= "table" or type(task.wait) ~= "function" then
            error("Roblox task scheduler unavailable")
        end
        local readyOk, loaded = pcall(function() return game:IsLoaded() end)
        if readyOk and not loaded then
            stage("game-ready", "等待游戏就绪（最多 15 秒）")
            local deadline = os.clock() + 15
            repeat
                if state.cancelled then return end
                task.wait(0.25)
                readyOk, loaded = pcall(function() return game:IsLoaded() end)
            until not readyOk or loaded or os.clock() >= deadline
            if not readyOk or not loaded then error("Game not ready within 15 seconds") end
        end
        state.gameId, state.placeId = stringify(game.GameId), stringify(game.PlaceId)
        local base = env.VortexionSourceBase or DEFAULT_BASE
        if type(base) ~= "string" or not base:match("^https?://[^%s]+$") then
            error("VortexionSourceBase must be HTTP(S) URL")
        end
        base = base:gsub("/+$", "") .. "/"
        local kernel, entry
        if not state.legacyOnce then
            stage("manifest", "获取轻量模块清单")
            state.url = base .. MANIFEST_PATH
            task.wait() -- allow the progress panel to paint
            local okGet, raw = pcall(function() return game:HttpGet(state.url) end)
            if state.cancelled then return end
            if not okGet then error("Manifest download failed: " .. stringify(raw)) end
            if type(raw) ~= "string" or #raw < 100 or #raw > MAX_MANIFEST_SIZE then
                error("Invalid manifest size")
            end
            state.downloadedBytes += #raw
            local service = game:GetService("HttpService")
            local okJson, manifest = pcall(function() return service:JSONDecode(raw) end)
            if not okJson or type(manifest) ~= "table" or manifest.schema ~= 2 then
                error("Manifest schema invalid; publish dist/runtime-manifest.json together with loader.lua")
            end
            state.manifestTag = tostring(manifest.build_tag or "unknown")
            stage("route", "在下载游戏模块前识别 GameId/PlaceId")
            local route, reason = selectRoute(manifest.routes)
            state.route, state.routeReason = route, reason
            if route and (type(manifest.modules) ~= "table" or type(manifest.modules[route]) ~= "table") then
                error("No module artifact for route " .. tostring(route))
            end
            stage("download-core", "下载共享 UI 与运行时核心")
            local core = fetchText(base, manifest.core, true)
            if state.cancelled then return end
            stage("compile-core", "编译共享 UI 核心")
            local coreEntry = compileSource(core, "Core")
            stage("init-core", "初始化共享运行时")
            local okCore, result = xpcall(coreEntry, traceError)
            if not okCore then error("Core init failed: " .. stringify(result)) end
            if type(result) ~= "table" or type(result.GameRouter) ~= "table" then
                error("Core did not return a valid runtime kernel")
            end
            kernel = result
            if route then
                stage("download-module", "仅下载 " .. route .. " 模块")
                local source = fetchText(base, manifest.modules[route], true)
                if state.cancelled then return end
                stage("compile-module", "编译游戏模块")
                entry = compileSource(source, "Module")
                stage("runtime", "初始化 " .. route .. " 模块与 WindUI")
                local okModule, moduleFactory = xpcall(entry, traceError)
                if not okModule or type(moduleFactory) ~= "function" then
                    error("Module factory invalid: " .. stringify(moduleFactory))
                end
                local okRuntime, resultRuntime = xpcall(function() return moduleFactory(kernel) end, traceError)
                if not okRuntime then error("Module runtime error: " .. stringify(resultRuntime)) end
            else
                stage("runtime", "当前地图未支持；显示通用说明和设置")
                local okRuntime, resultRuntime = xpcall(function()
                    return kernel.GameRouter.Run(kernel.WindUI, kernel.WindBridgeFactory, nil,
                        game.GameId, game.PlaceId, reason)
                end, traceError)
                if not okRuntime then error("Generic runtime error: " .. stringify(resultRuntime)) end
            end
        else
            state.legacyOnce = false
            state.route, state.routeReason = "legacy", "manual-compatibility-check"
            state.manifestTag = "legacy-single-bundle"
            stage("download-legacy", "下载完整兼容包（约 2.2 MB）")
            -- Explicit manual compatibility fallback only. It never masks modular errors automatically.
            state.url = base .. LEGACY_BUNDLE
            task.wait()
            local okGet, source = pcall(function() return game:HttpGet(state.url) end)
            if state.cancelled then return end
            if not okGet or type(source) ~= "string" or #source < 128 or #source > MAX_BUNDLE_SIZE then
                error("Standalone bundle download failed: " .. stringify(source))
            end
            state.downloadedBytes += #source
            stage("compile-legacy", "编译兼容包")
            local fn = compileSource(source, "Legacy")
            stage("runtime", "启动兼容包")
            local okRuntime, err = xpcall(fn, traceError)
            if not okRuntime then error("Legacy runtime error: " .. stringify(err)) end
        end
        if state.cancelled then return end
        stage("validate", "校验 UI 桥接与活动窗口")
        local bridge = env.VortexionWindBridge
        if type(bridge) ~= "table" or bridge.Active ~= true then
            local root = env.VortexionBootError or (type(bridge) == "table" and bridge.LastError)
            error("No active WindUI bridge. Root cause: " .. tostring(root or "not yet reported; check executor console"))
        end
        local validWindow = false
        if type(bridge.Window) == "function" then
            local ok, value = pcall(bridge.Window, bridge)
            validWindow = ok and value ~= nil
        else
            validWindow = bridge.Window ~= nil
        end
        if not validWindow then
            error("WindUI bridge is active but no window was created")
        end
        local partial = bridge.BootStatus == "partial"
        state.stage, state.status = "complete", partial and "partial" or "success"
        state.detail = partial and "界面可用，但部分子模块异常。请查看 UI 调试页和诊断。"
            or (state.route == nil and "已打开通用 UI；当前游戏未适配。" or "已创建 UI 窗口；需实机验证功能。")
        state.error = partial and tostring(bridge.BootError or "unknown submodule error"):sub(1, 1500) or nil
        log("complete", partial and ("Partial module initialization: " .. tostring(state.error))
            or "UI bridge and window registered; game functions not yet validated")
        refresh()
        -- Keep only one active source version cached after a successful load.
        local current = {}
        for _, key in ipairs(state.cacheKeys) do
            if type(cache[key]) == "string" then current[key] = cache[key] end
        end
        env.VortexionLoaderCache = current
        cache = current
    end
    local ok, err = xpcall(work, traceError)
    state.busy = false
    if not ok then
        -- Only discard downloads first observed during this failed attempt.
        -- Previously validated session cache hits must remain available on retry.
        for _, key in ipairs(state.newCacheKeys or {}) do cache[key] = nil end
        fail(state.stage, err)
    end
end
state.Retry = run
createPanel()
if type(task) == "table" and type(task.spawn) == "function" then
    task.spawn(run)
else
    fail("preflight", "task.spawn unavailable; cannot start asynchronous loader")
end
