-- Vortexion BloxStrike common runtime: capability probe, debug channel, guards.
-- Every BloxStrike module receives this singleton through ctx.c and never
-- touches globals. Degrades per-feature instead of hard-failing.
return function(c)
    local common = c or {}
    common.Version = "3.0.0"
    common.Name = "BloxStrike"

    --=========================================================================
    -- Executor capability probe. Bullet tracking paths and the cloak select
    -- themselves from these flags at runtime.
    --=========================================================================
    local Caps = {}
    local function detect(name, test)
        local ok, result = pcall(test)
        Caps[name] = ok and result and true or false
    end

    detect("Drawing", function() return type(Drawing) == "table" and type(Drawing.new) == "function" end)
    detect("DrawingUserdata", function() return type(Drawing) == "userdata" end)
    detect("hookfunction", function() return type(hookfunction) == "function" end)
    detect("replaceclosure", function() return type(replaceclosure) == "function" end)
    detect("hookmetamethod", function() return type(hookmetamethod) == "function" end)
    detect("getrawmetatable", function() return type(getrawmetatable) == "function" end)
    detect("newcclosure", function() return type(newcclosure) == "function" end)
    detect("checkcaller", function() return type(checkcaller) == "function" end)
    detect("getnamecallmethod", function() return type(getnamecallmethod) == "function" end)
    detect("mousemoverel", function() return type(mousemoverel) == "function" end)
    detect("mouse1click", function() return type(mouse1click) == "function" end)
    detect("mouse1press", function() return type(mouse1press) == "function" end)
    detect("mouse1release", function() return type(mouse1release) == "function" end)
    detect("gethui", function() return type(gethui) == "function" end)
    detect("getgenv", function() return type(getgenv) == "function" end)
    detect("setclipboard", function() return type(setclipboard) == "function" end)
    common.Caps = Caps
    common.HasDrawing = (Caps.Drawing or Caps.DrawingUserdata) and true or false
    -- Cloak gate: the enumeration filter needs the metatable hook plus the
    -- caller discriminator; RandomName-only mode stays available otherwise.
    common.CanCloak = (Caps.hookmetamethod and Caps.checkcaller and Caps.getnamecallmethod) and true or false

    --=========================================================================
    -- Debug channel: gated by the Settings/Debug toggle.
    --=========================================================================
    common.Debug = false
    function common.Log(module, ...)
        if not common.Debug then return end
        print(("[Vortexion/Blox/%s]"):format(module), ...)
    end

    --=========================================================================
    -- Guarded execution with 5s warn throttle: one broken subsystem must never
    -- spam the console or stall the shared render loop.
    --=========================================================================
    local lastWarn = {}
    function common.Guard(module, fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then
            local now = tick()
            if not lastWarn[module] or now - lastWarn[module] > 5 then
                lastWarn[module] = now
                warn(("[Vortexion/Blox/%s] %s"):format(module, tostring(err)))
            end
        end
        return ok
    end

    --=========================================================================
    -- RandomName: 14 random letters. Blocks name-signature scans of anything
    -- this script parents into Workspace/PlayerGui (ESP highlights, skins).
    --=========================================================================
    local NAME_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    function common.RandomName(len)
        len = len or 14
        local out = table.create(len)
        for i = 1, len do
            local ci = math.random(1, #NAME_CHARS)
            out[i] = NAME_CHARS:sub(ci, ci)
        end
        return table.concat(out)
    end

    --=========================================================================
    -- getGuiParent: gethui (hidden) first, then CoreGui, then PlayerGui.
    --=========================================================================
    local function writableGuiParent(parent)
        if not parent then return false end
        local probe = Instance.new("Folder")
        local ok = pcall(function() probe.Parent = parent end)
        probe:Destroy()
        return ok
    end
    function common.GetGuiParent()
        if Caps.gethui then
            local ok, hui = pcall(gethui)
            if ok and writableGuiParent(hui) then return hui end
        end
        local coreGui = game:FindService("CoreGui")
        if writableGuiParent(coreGui) then return coreGui end
        return game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    end

    --=========================================================================
    -- Cleanup registry: Core:Stop() runs every disposer so a reload never
    -- leaks connections, restored sizes or patched closures.
    --=========================================================================
    common.Disposers = {}
    function common.OnCleanup(fn)
        table.insert(common.Disposers, fn)
    end

    --=========================================================================
    -- Shared bridge pacing: ctx.UI may expose GetVisualInterval(baseSeconds)
    -- so non-critical visual work (ESP refresh) follows the bridge's bounded
    -- VisualHz. A missing method, an error or a bad return keeps the original
    -- cadence, which is what every offline fixture and older bridge does.
    --=========================================================================
    local FALLBACK_INTERVAL = 0.05
    local function finitePositive(value)
        return type(value) == "number" and value == value and value > 0 and value < math.huge
    end
    function common.VisualInterval(base)
        if not finitePositive(base) then return FALLBACK_INTERVAL end
        local ui = common.UI
        if type(ui) == "table" and type(ui.GetVisualInterval) == "function" then
            local ok, value = pcall(ui.GetVisualInterval, ui, base)
            -- Only ever slow the cadence down: a bridge that answers faster
            -- than base, or with a non-finite value, is ignored.
            if ok and finitePositive(value) and value > base then
                return value
            end
        end
        return base
    end

    --=========================================================================
    -- Touch layer: mobile trigger + fly drag. Single finger held = trigger;
    -- single finger drag = horizontal fly; two fingers = vertical fly.
    --=========================================================================
    common.Touch = { Enabled = false, Held = false, Region = "Right" }
    do
        local UIS = common.Services and common.Services.UserInputService
        if not UIS then
            local ok, svc = pcall(function() return game:GetService("UserInputService") end)
            if ok then UIS = svc end
        end
        if UIS and UIS.TouchEnabled then
            common.Touch.Enabled = true
            local touchPoints = {}
            local touchConns = {}
            local sequence = 0
            table.insert(touchConns, UIS.TouchStarted:Connect(function(input, processed)
                if processed then return end
                local camera = workspace.CurrentCamera
                if common.Touch.Region == "Right" and camera and input.Position.X < camera.ViewportSize.X / 2 then return end
                sequence += 1
                touchPoints[input] = { origin = input.Position, pos = input.Position, order = sequence }
                common.Touch.Held = true
            end))
            table.insert(touchConns, UIS.TouchMoved:Connect(function(input)
                if touchPoints[input] then touchPoints[input].pos = input.Position end
            end))
            table.insert(touchConns, UIS.TouchEnded:Connect(function(input)
                touchPoints[input] = nil
                common.Touch.Held = next(touchPoints) ~= nil
            end))
            if UIS.WindowFocusReleased then
                table.insert(touchConns, UIS.WindowFocusReleased:Connect(function()
                    touchPoints = {}
                    common.Touch.Held = false
                end))
            end
            function common.Touch:Drag()
                local first, second
                for _, point in pairs(touchPoints) do
                    if not first or point.order < first.order then
                        second, first = first, point
                    elseif not second or point.order < second.order then
                        second = point
                    end
                end
                if not first then return Vector2.zero, 0 end
                local d = first.pos - first.origin
                local vertical = second and (second.pos.Y - second.origin.Y) or 0
                return Vector2.new(d.X, d.Y), vertical
            end
            common.OnCleanup(function()
                for _, cn in ipairs(touchConns) do pcall(function() cn:Disconnect() end) end
                touchPoints = {}
                common.Touch.Held = false
            end)
        end
    end

    --=========================================================================
    -- Ping in seconds. Used by prediction and trigger timing.
    --=========================================================================
    local pingAt, pingValue = -math.huge, 0.08
    function common.Ping()
        local now = tick()
        if now - pingAt < 0.5 then return pingValue end
        pingAt = now
        local ok, stats = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
        end)
        if ok and stats then
            local okValue, value = pcall(function() return stats:GetValue() end)
            if okValue and type(value) == "number" then
                pingValue = math.clamp(value / 1000, 0.02, 0.4)
                return pingValue
            end
        end
        return pingValue
    end

    --=========================================================================
    -- Safe service cache.
    --=========================================================================
    common.Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        UserInputService = game:GetService("UserInputService"),
        HttpService = game:GetService("HttpService"),
        Lighting = game:GetService("Lighting"),
        TeleportService = game:GetService("TeleportService"),
        VirtualUser = game:GetService("VirtualUser"),
        TweenService = game:GetService("TweenService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        Stats = game:GetService("Stats"),
        Workspace = workspace,
    }
    common.LocalPlayer = common.Services.Players.LocalPlayer

    return common
end
