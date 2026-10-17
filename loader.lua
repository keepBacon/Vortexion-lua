-- Vortexion Loader V2 / P0: visible bootstrap diagnostics only.
-- The unified WindUI bundle and per-game routing are intentionally unchanged.
local VERSION = "2.0.0-p0"
local DEFAULT_BASE = "https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/"
local BUNDLE_PATH = "dist/Vortexion_Wind.lua"
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
            or state.status == "success" and "初始化完成" or "正在加载 / " .. state.stage
        ui.detail.Text = state.error and (state.error:sub(1, 260))
            or (state.detail or "正在检查加载环境…")
        ui.detail.TextColor3 = state.error and Color3.fromRGB(248, 165, 161)
            or Color3.fromRGB(163, 170, 181)
        ui.retry.Visible = state.status == "failed"
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
        frame.Size = UDim2.new(1, -24, 0, 187)
        frame.BackgroundColor3 = Color3.fromRGB(26, 29, 35)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        local sizeConstraint = Instance.new("UISizeConstraint")
        sizeConstraint.MaxSize = Vector2.new(332, 187)
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

local function run()
    if state.cancelled or state.busy then return end
    state.busy = true
    state.startedAt = os.clock()
    state.error = nil
    local function work()
        stage("preflight", "检查脚本执行环境")
        if game == nil then
            error("Roblox game object unavailable")
        end
        if type(loadstring) ~= "function" then error("loadstring unavailable in this executor") end
        if type(task) ~= "table" or type(task.wait) ~= "function" then
            error("Roblox task scheduler unavailable")
        end
        local loadedOk, loaded = pcall(function() return game:IsLoaded() end)
        if loadedOk and not loaded then
            stage("game-ready", "等待 Roblox 游戏就绪（最多 15 秒）")
            local deadline = os.clock() + 15
            repeat
                if state.cancelled then return end
                task.wait(0.25)
                loadedOk, loaded = pcall(function() return game:IsLoaded() end)
            until not loadedOk or loaded or os.clock() >= deadline
            if not loadedOk or not loaded then error("Game not loaded within 15 seconds") end
        end
        state.gameId = stringify(game.GameId)
        state.placeId = stringify(game.PlaceId)
        stage("source", "确定代码来源")
        local base = env.VortexionSourceBase or DEFAULT_BASE
        if type(base) ~= "string" or not base:match("^https?://[^%s]+$") then
            error("VortexionSourceBase must be a valid HTTP(S) base URL")
        end
        state.url = base:gsub("/+$", "") .. "/" .. BUNDLE_PATH

        stage("download", "正在下载统一入口脚本（约 2.2 MB）")
        -- Let the loader panel paint before a potentially blocking network call.
        task.wait()
        local downloaded, source = pcall(function() return game:HttpGet(state.url) end)
        if state.cancelled then return end
        if not downloaded then error("HTTP request failed: " .. stringify(source)) end
        if type(source) ~= "string" or #source < 128 then
            error("HTTP response is empty or unexpectedly short")
        end
        if source:sub(1, 128):lower():match("^%s*<[%w!]?") then
            error("Server returned HTML instead of Luau source")
        end
        stage("compile", "已下载 " .. tostring(#source) .. " 字节，正在编译")
        local compiled, entry = pcall(loadstring, source)
        if not compiled then error("Compiler exception: " .. stringify(entry)) end
        if type(entry) ~= "function" then error("Luau compile error: " .. stringify(entry)) end

        stage("runtime", "正在执行游戏入口并创建 WindUI")
        local executed, result = xpcall(entry, traceError)
        if state.cancelled then return end
        if not executed then error("Runtime error: " .. stringify(result)) end
        local bridge = env.VortexionWindBridge
        if type(bridge) ~= "table" or bridge.Active ~= true then
            error("Entry returned but no active VortexionWindBridge was registered. Check executor console for GameRouter warnings")
        end
        state.stage = "complete"
        state.status = "success"
        state.error = nil
        state.detail = "WindUI 桥接已注册；如果仍看不到窗口，请复制诊断信息。"
        log("complete", "Active WindUI bridge registered; visual rendering not verified")
        refresh()
    end
    local ok, err = xpcall(work, traceError)
    state.busy = false
    if not ok then fail(state.stage, err) end
end
state.Retry = run
createPanel()
-- Defer to avoid blocking first-frame rendering of the diagnostic panel.
if type(task) == "table" and type(task.spawn) == "function" then
    task.spawn(run)
else
    fail("preflight", "task.spawn unavailable; cannot start asynchronous loader")
end
