-- Vortexion WindUI - generated offline; publishing must be performed separately.
-- WindUI attribution and license are retained in vendor/WindUI/.
-- Forsaken retains runtime model rbxassetid://132866968194043.
-- Modify src/*.luau and run python3 build.py; do not edit this output.
return function(kernel)
assert(type(kernel) == 'table' and type(kernel.WindBridgeFactory) == 'function', 'Invalid Vortexion core')
local WindUI, WindBridgeFactory, GameRouter = kernel.WindUI, kernel.WindBridgeFactory, kernel.GameRouter
local entry = function()
local BloxCommonFactory = (function()
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

end)()
local BloxCloakFactory = (function()
-- Vortexion BloxStrike cloak: hides script-created instances from game scripts.
--
-- Adapted from the Vanity-General-Roblox design (local sandbox study). Game
-- anti-cheat / anti-ESP logic that enumerates children cannot see instances
-- registered here. The hook only rewrites enumeration calls made by game
-- threads (checkcaller() == false); executor-side reads are untouched.
--
-- Two defenses compose:
--   1. Enumeration filter - GetChildren/GetDescendants/FindFirstChild* skip
--      protected instances for game-thread callers.
--   2. RandomName - every created instance gets a 14-letter random name so
--      static name signatures ("_chams", "ESP") never match.
return function(common)
    local Workspace = common.Services.Workspace
    local Players = common.Services.Players

    local Cloak = {}
    local protectedSet = setmetatable({}, { __mode = "k" })
    local hookInstalled = false
    local namecallConnection = nil
    local inFilter = false

    local FILTERED_METHODS = {
        GetChildren = true,
        GetDescendants = true,
        FindFirstChild = true,
        FindFirstChildOfClass = true,
        FindFirstChildWhichIsA = true,
    }

    local function isHidden(instance)
        local current = instance
        local depth = 0
        while current and depth < 64 do
            if protectedSet[current] then return true end
            current = current.Parent
            depth += 1
        end
        return false
    end
    Cloak.IsHidden = isHidden

    -- Instances parented into Workspace or PlayerGui are game-visible surfaces:
    -- a hidden instance there still needs its enumeration filtered (handled by
    -- the hook), but gethui-parented instances are outside the game tree and
    -- need nothing. This distinction keeps the hook's hot path short.
    local function exposedToGame(instance)
        local current = instance
        local depth = 0
        while current and depth < 64 do
            if current == Workspace then return true end
            local playerGui = current == Players.LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then return true end
            current = current.Parent
            depth += 1
        end
        return false
    end
    Cloak.ExposedToGame = exposedToGame

    function Cloak.Protect(instance)
        if typeof(instance) ~= "Instance" then return instance end
        protectedSet[instance] = true
        return instance
    end

    function Cloak.Unprotect(instance)
        protectedSet[instance] = nil
    end

    --=========================================================================
    -- Hook. newcclosure wrapping keeps the hook invisible to islclosure /
    -- getinfo / string.dump probing (looks like a C closure). hookmetamethod
    -- is preferred over getrawmetatable + __namecall assignment because it
    -- restores cleanly and does not disturb other executor hooks.
    --=========================================================================
    local function installHook()
        if hookInstalled then return end
        if not (common.Caps.hookmetamethod and common.Caps.checkcaller) then
            common.Log("Cloak", "hook unavailable; enumeration filter disabled")
            return
        end

        local ok, err = pcall(function()
            local gameMetatable = getrawmetatable(game)
            local originalNamecall = gameMetatable.__namecall
            local namecallHook

            namecallHook = hookmetamethod(game, "__namecall", function(self, ...)
                -- Only game threads are filtered. Executor threads (this
                -- script, the UI library) must see everything or the UI dies.
                local fromGameScript = false
                if common.Caps.checkcaller then
                    local okCaller, caller = pcall(checkcaller)
                    fromGameScript = okCaller and (caller == false)
                end

                if fromGameScript and not inFilter then
                    local methodOk, methodRaw = pcall(getnamecallmethod)
                    local method = methodOk and methodRaw or nil
                    if method and FILTERED_METHODS[method] then
                        inFilter = true
                        local arguments = table.pack(...)
                        local okFilter, result = pcall(function()
                            if isHidden(self) then
                                -- The container itself is hidden: report it empty.
                                if method == "GetChildren" or method == "GetDescendants" then
                                    return {}
                                end
                                return nil
                            end
                            local children = originalNamecall(self, table.unpack(arguments, 1, arguments.n))
                            if method == "GetChildren" or method == "GetDescendants" then
                                local visible = {}
                                for _, child in ipairs(children) do
                                    if not isHidden(child) then
                                        table.insert(visible, child)
                                    end
                                end
                                return visible
                            end
                            return children
                        end)
                        inFilter = false
                        if okFilter then return result end
                    end
                end
                return originalNamecall(self, ...)
            end)

            if common.Caps.newcclosure then
                namecallHook = newcclosure(namecallHook)
            end
            namecallConnection = namecallHook
            hookInstalled = true
            common.Log("Cloak", "enumeration hook installed")
        end)

        if not ok then
            warn("[Vortexion/Blox/Cloak] install failed: " .. tostring(err))
        end
    end

    function Cloak.Start()
        installHook()
    end

    function Cloak.Stop()
        -- The metatable hook cannot be surgically removed without the original
        -- reference on every executor; the filter is inert once protectedSet is
        -- cleared, so clearing is the supported teardown.
        table.clear(protectedSet)
        hookInstalled = false
        namecallConnection = nil
    end

    return Cloak
end

end)()
local BloxCombatFactory = (function()
-- Vortexion BloxStrike combat: aimbot, triggerbot, local hitbox envelope.
--
-- Design notes (why, not what):
--   * The old aim loop lerped with alpha=1-exp(-smooth*25*dt) which at the
--     default smooth=0.35 lands at ~0.58 per frame - a snap, not a track. The
--     new alpha is clamped to (1-Smoothness) scaled by on-screen angular
--     distance, with a per-frame angular-speed ceiling (22 deg/s) so long
--     flicks stay human and short corrections stay sticky.
--   * Locking re-validates every frame (dead / health / distance / on-screen)
--     instead of trusting a cached model reference.
--   * Prediction uses an EMA of target velocity plus half the measured ping;
--     without it a strafing target is always chased from behind.
--   * Triggerbot presses mouse1 (executor) with VirtualUser fallback instead
--     of the previous notify-only stub.
--   * Hitbox grows local part sizes through a 20Hz state machine with lerp,
--     distance-scaled magnitude and a per-player restore table, so nothing is
--     left mutated after a respawn or reload. Client-side sizes never reach
--     the server; the value here is visual consistency plus the envelope the
--     Bullet module feeds back into weapon remotes.
return function(c)
    local Players = c.Services.Players
    local RunService = c.Services.RunService
    local Workspace = c.Services.Workspace
    local LocalPlayer = c.LocalPlayer

    --=========================================================================
    -- Configuration (UI flags kept backwards-compatible where they existed).
    --=========================================================================
    local Config = {
        Enabled = false,
        Mode = "Camera",          -- Camera | Mouse | Both
        TriggerKey = "Always",    -- Always | Hold (RMB2 / touch)
        FOV = 240,
        MaxDistance = 500,
        Smoothness = 0.35,
        Hitbox = "Head",          -- Head | Torso | Arms | Legs | Random
        WallCheck = true,
        TeamCheck = true,
        Prediction = 0.12,
        MaxAngle = 35,
        HitChance = 1,
        AimTurnRate = 120,
        Priority = "Crosshair",     -- Crosshair | Distance | LowHealth
        FOVCircle = true,
        Attraction = 0.6,
        -- triggerbot
        TriggerEnabled = false,
        TriggerMode = "Locked",   -- Locked | Always
        TriggerDelay = 0.12,
        -- hitbox
        HitboxEnabled = false,
        HitboxSize = 1.6,
        HitboxMode = "lockedOnly", -- lockedOnly | fullBody
        HitboxMaxActive = 3,
    }

    local Combat_PredictPoint

    local state = {
        locked = nil,
        lastLocked = nil,
        candidates = {},
        velEMA = {},
        scanAccum = 0,
        aimSmooth = Vector3.zero,
        aimSmoothValid = false,
        lastPredictOffset = nil,
        mouseNoise = nil,
        fireAt = 0,
        firing = false,
        hitAccum = 0,
        hitEntries = {},          -- [player] = hit entry (restore keyed by player)
        rollCache = {},
        rollAt = {},
        cost = 0,
        scans = 0,
        candidatesSeen = 0,
    }

    --=========================================================================
    -- Raycast setup for wall checks.
    --=========================================================================
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    local function wallBlocked(fromPos, toPos, character, target)
        local diff = toPos - fromPos
        local dist = diff.Magnitude
        if dist < 0.1 then return false end
        rayParams.FilterDescendantsInstances = character and { character } or {}
        local result = Workspace:Raycast(fromPos, diff, rayParams)
        return result ~= nil and not (target and result.Instance and result.Instance:IsDescendantOf(target))
    end

    --=========================================================================
    -- Candidate scan (10Hz). Entries carry screen/world distance so target
    -- selection and eligibility gates share one traversal.
    --=========================================================================
    local function scan()
        state.scans += 1
        state.candidates = {}
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local camPos = camera.CFrame.Position
        local viewport = camera.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local model, humanoid = c.Living(player)
                if model and humanoid and humanoid.Health > 0 then
                    if (not Config.TeamCheck) or c.Enemy(player, true) then
                        local root = model:FindFirstChild("HumanoidRootPart")
                            or model:FindFirstChild("Torso")
                            or model:FindFirstChildWhichIsA("BasePart")
                        if root then
                            local pos = root.Position
                            local worldDist = (pos - camPos).Magnitude
                            if worldDist <= Config.MaxDistance then
                                local screen, onScreen = camera:WorldToViewportPoint(pos)
                                if screen.Z > 0 then
                                    local screenVec = Vector2.new(screen.X, screen.Y)
                                    local screenDist = onScreen and (screenVec - center).Magnitude or math.huge
                                    if screenDist <= Config.FOV then
                                        local vel = root.AssemblyLinearVelocity or Vector3.zero
                                        local ema = state.velEMA[player]
                                        if not ema then
                                            state.velEMA[player] = vel
                                        else
                                            ema = ema:Lerp(vel, 0.15)
                                            state.velEMA[player] = ema
                                        end
                                        table.insert(state.candidates, {
                                            player = player,
                                            model = model,
                                            humanoid = humanoid,
                                            root = root,
                                            head = model:FindFirstChild("Head"),
                                            screenDist = screenDist,
                                            worldDist = worldDist,
                                            screen = screenVec,
                                            onScreen = onScreen,
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        state.candidatesSeen = #state.candidates
        -- Drop EMA state for players that left.
        for player in pairs(state.velEMA) do
            if not player.Parent then state.velEMA[player] = nil end
        end
    end

    --=========================================================================
    -- Target part selection per aim mode.
    --=========================================================================
    local RANDOM_PARTS = { "Head", "UpperTorso", "Torso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" }

    local function pickPart(entry)
        local model = entry.model
        local mode = Config.Hitbox
        if mode == "Random" then
            if entry.randomPart and entry.randomPart.Parent == model then return entry.randomPart end
            for _ = 1, 6 do
                local part = model:FindFirstChild(RANDOM_PARTS[math.random(1, #RANDOM_PARTS)])
                if part then entry.randomPart = part; return part end
            end
            entry.randomPart = entry.head or entry.root
            return entry.randomPart
        elseif mode == "Torso" then
            return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or entry.root
        elseif mode == "Arms" then
            return model:FindFirstChild("LeftUpperArm") or model:FindFirstChild("Left Arm")
                or model:FindFirstChild("RightUpperArm") or model:FindFirstChild("Right Arm")
                or entry.root
        elseif mode == "Legs" then
            return model:FindFirstChild("LeftUpperLeg") or model:FindFirstChild("Left Leg")
                or model:FindFirstChild("RightUpperLeg") or model:FindFirstChild("Right Leg")
                or entry.root
        end
        return entry.head or entry.root
    end

    --=========================================================================
    -- Prediction: EMA velocity * (half ping + fixed lead), intensity-scaled
    -- by Config.Prediction, then smoothed once more so the aim point does not
    -- jitter when the target's velocity estimate flips sign.
    --=========================================================================
    function Combat_PredictPoint(entry, forcePart)
        local part = forcePart or pickPart(entry)
        if not part then return nil end
        local pos = part.Position
        local ema = state.velEMA[entry.player]
        if not ema then return pos end
        local lead = 0.5 * c.Ping() + 0.05
        local offset = ema * (lead * (Config.Prediction / 0.12))
        if state.aimSmoothValid and state.lastPredictOffset then
            if (offset - state.lastPredictOffset).Magnitude > 0.05 then
                state.aimSmooth = state.aimSmooth:Lerp(offset, 0.25)
            end
        else
            state.aimSmooth = offset
            state.aimSmoothValid = true
        end
        state.lastPredictOffset = offset
        return pos + state.aimSmooth
    end

    --=========================================================================
    -- Target selection + per-frame lock validation.
    --=========================================================================
    local function entryValid(entry)
        if not entry or not entry.player.Parent or not entry.model.Parent or not entry.root.Parent then return false end
        local model, humanoid = c.Living(entry.player)
        if model ~= entry.model or humanoid ~= entry.humanoid or humanoid.Health <= 0 then return false end
        if Config.TeamCheck and not c.Enemy(entry.player, true) then return false end
        local camera = Workspace.CurrentCamera
        if not camera then return false end
        local delta = entry.root.Position - camera.CFrame.Position
        if delta.Magnitude > Config.MaxDistance or delta.Magnitude < 0.01 then return false end
        local angle = math.deg(math.acos(math.clamp(camera.CFrame.LookVector:Dot(delta.Unit), -1, 1)))
        if angle > Config.MaxAngle then return false end
        local screen, visible = camera:WorldToViewportPoint(entry.root.Position)
        if not visible or screen.Z <= 0 then return false end
        local center = camera.ViewportSize * 0.5
        entry.screen = Vector2.new(screen.X, screen.Y)
        entry.screenDist = (entry.screen - center).Magnitude
        entry.worldDist = delta.Magnitude
        if entry.screenDist > Config.FOV then return false end
        return not Config.WallCheck or not wallBlocked(camera.CFrame.Position, entry.root.Position, c.Character(), entry.model)
    end

    local function chanceFor(entry)
        local now = tick()
        local player = entry.player
        if not state.rollAt[player] or now - state.rollAt[player] >= 0.15 then
            state.rollAt[player] = now
            state.rollCache[player] = math.random()
        end
        return state.rollCache[player] <= Config.HitChance
    end

    local function selectTarget()
        local camera = Workspace.CurrentCamera
        if not camera or #state.candidates == 0 then
            state.locked = nil
            return
        end
        local camPos = camera.CFrame.Position
        local character = c.Character()
        local best, bestScore
        for _, entry in ipairs(state.candidates) do
            if entryValid(entry) then
                local score
                if Config.Priority == "Distance" then score = entry.worldDist
                elseif Config.Priority == "LowHealth" then
                    score = (type(entry.humanoid) == "table" and entry.humanoid.HealthKnown == false) and (entry.screenDist + 10000)
                        or ((entry.humanoid.Health / math.max(entry.humanoid.MaxHealth, 1)) * 400 + entry.screenDist * 0.2)
                else score = entry.screenDist + entry.worldDist * 0.15 end
                if not bestScore or score < bestScore then
                    best, bestScore = entry, score
                end
            end
        end
        state.locked = best
    end

    local function lockStillValid()
        return entryValid(state.locked)
    end

    --=========================================================================
    -- Camera aim: clamped alpha, angular-speed ceiling, vertical damping,
    -- first-frame softness after target switch.
    --=========================================================================
    local function cameraAim(dt, aimPos)
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local camPos = camera.CFrame.Position
        local look = aimPos - camPos
        if look.Magnitude < 0.01 then return end
        local targetLook = look.Unit
        local targetCF = CFrame.lookAt(camPos, aimPos)
        local angle = math.acos(math.clamp(camera.CFrame.LookVector:Dot(targetLook), -1, 1))

        local screen, onScreen = camera:WorldToViewportPoint(aimPos)
        local viewport = camera.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
        local screenDist = onScreen and (Vector2.new(screen.X, screen.Y) - center).Magnitude or math.huge
        local fovT = 1 - math.clamp(screenDist / math.max(Config.FOV, 1), 0, 1)
        local alpha = math.clamp((1 - Config.Smoothness) * (0.4 + 0.6 * fovT), 0.10, 0.45)
        if math.abs(targetLook.Y) > 0.6 then alpha = alpha * 0.85 end
        if state.locked ~= state.lastLocked then alpha = math.min(alpha, 0.10) end
        if angle > 1e-4 then
            alpha = math.min(alpha, (math.rad(Config.AimTurnRate) * dt) / angle)
        end
        if alpha <= 0.001 then return end
        camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
    end

    --=========================================================================
    -- Mouse aim: relative movement scaled by attraction and a near-center
    -- damping band, EMA-smoothed noise, integer snapping.
    --=========================================================================
    local function mouseAim(dt, aimPos)
        if not c.Caps.mousemoverel then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local screen, onScreen = camera:WorldToViewportPoint(aimPos)
        if not onScreen or screen.Z <= 0 then return end
        local viewport = camera.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
        local target = Vector2.new(screen.X, screen.Y)
        local delta = target - center
        local mag = delta.Magnitude
        if mag < 1 then return end
        local factor = 0.2 * Config.Attraction * (0.4 + 0.6 * (1 - math.clamp(mag / math.max(Config.FOV, 1), 0, 1)))
        if mag <= Config.FOV * 0.25 then factor = factor * 0.5 end
        if mag <= 2 then
            mousemoverel(math.floor(delta.X + 0.5), math.floor(delta.Y + 0.5))
            return
        end
        local step = delta * factor
        local noise = Vector2.new((math.random() - 0.5) * 1.6, (math.random() - 0.5) * 1.6)
        if state.mouseNoise then
            state.mouseNoise = state.mouseNoise:Lerp(noise, 0.3)
        else
            state.mouseNoise = noise
        end
        step = step + state.mouseNoise
        if step ~= step then return end -- NaN guard
        mousemoverel(math.floor(step.X + 0.5), math.floor(step.Y + 0.5))
    end

    --=========================================================================
    -- Triggerbot: real mouse1 press (executor) with VirtualUser fallback.
    --=========================================================================
    local releaseFire, releaseAt
    local stopped = false
    local function finishFire()
        if releaseFire then pcall(releaseFire) end
        releaseFire, releaseAt = nil, nil
        state.firing = false
    end
    local function pressFire(now)
        local camera = Workspace.CurrentCamera
        local position = Vector2.zero
        if c.Caps.mouse1press and c.Caps.mouse1release then
            releaseFire = mouse1release
            if not pcall(mouse1press) then finishFire(); return end
        else
            local user = c.Services.VirtualUser
            if not user or not camera then return end
            releaseFire = function() user:Button1Up(position, camera.CFrame) end
            if not pcall(function() user:Button1Down(position, camera.CFrame) end) then finishFire(); return end
        end
        state.firing = true
        releaseAt = now + math.max(Config.TriggerDelay, 0.02)
    end

    local UserInputService = game:GetService("UserInputService")

    -- Hold gate: when TriggerKey == "Hold" the aim assist and the triggerbot
    -- only run while RMB2 is held (or a single touch point is held on mobile).
    local function gateHeld()
        if Config.TriggerKey ~= "Hold" then return true end
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return true end
        return c.Touch.Enabled and c.Touch.Held
    end

    local function triggerTick(now)
        if not Config.TriggerEnabled or state.firing then return end
        if not gateHeld() then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local allowed = false
        if Config.TriggerMode == "Locked" then
            local entry = state.locked
            if entry and entryValid(entry) and chanceFor(entry) then
                local screen, onScreen = camera:WorldToViewportPoint(entry.root.Position)
                if onScreen and screen.Z > 0 then
                    local viewport = camera.ViewportSize
                    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
                    local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                    allowed = dist <= math.max(60, Config.FOV * 0.25)
                end
            end
        else
            for _, entry in ipairs(state.candidates) do
                if entryValid(entry) and entry.screenDist <= math.max(60, Config.FOV * 0.25) then
                    if chanceFor(entry) then
                        allowed = true
                        break
                    end
                end
            end
        end
        if not allowed then return end
        if now - state.fireAt < 0.18 then return end
        state.fireAt = now
        c.Guard("Combat.Trigger", function() pressFire(now) end)
    end

    --=========================================================================
    -- Hitbox: 20Hz state machine. Local size edits never replicate; the point
    -- is (a) a visually consistent growth the player can see, (b) the restore
    -- table that guarantees no leftover mutation, (c) the envelope query the
    -- Bullet module uses when it rewrites weapon remotes.
    --=========================================================================
    local function hitboxParts(entry)
        local parts = {}
        local root = entry.root
        if root and root:IsA("BasePart") then table.insert(parts, root) end
        if entry.head and entry.head:IsA("BasePart") and entry.head ~= root then
            table.insert(parts, entry.head)
        end
        return parts
    end

    local function hitboxEligible(entry)
        if not entryValid(entry) then return false end
        if entry.worldDist > 250 then return false end
        if entry.screenDist > 120 then return false end
        return true
    end

    local function targetSizeFor(orig, dist)
        local base = Vector3.new(orig.X * 1.6, orig.Y * 1.3, orig.Z * 1.6)
        local scale = 1 + (Config.HitboxSize - 1) * math.clamp(1 - dist / 250, 0, 1)
        local maxEdge = math.min(10, math.min(orig.X, orig.Z) * 2.2)
        return Vector3.new(
            math.min(base.X * scale, orig.X + maxEdge),
            math.min(base.Y * scale, orig.Y + maxEdge),
            math.min(base.Z * scale, orig.Z + maxEdge)
        )
    end

    local function beginHitEntry(entry)
        local parts = {}
        for _, part in ipairs(hitboxParts(entry)) do
            table.insert(parts, {
                part = part,
                origSize = part.Size,
                origTransparency = part.Transparency,
                origCollide = part.CanCollide,
                phase = "expanding",
                since = tick(),
            })
        end
        if #parts > 0 then
            state.hitEntries[entry.player] = { parts = parts, entry = entry }
        end
    end

    local function restoreHitEntry(player, record)
        if not record then return end
        for _, item in ipairs(record.parts) do
            local part = item.part
            if part and part.Parent then
                part.Size = item.origSize
                part.Transparency = item.origTransparency
                part.CanCollide = item.origCollide
            end
        end
        state.hitEntries[player] = nil
    end

    local function hitboxTick(dt)
        if not Config.HitboxEnabled then
            if next(state.hitEntries) then
                for player, record in pairs(state.hitEntries) do
                    restoreHitEntry(player, record)
                end
            end
            return
        end
        state.hitAccum += dt
        if state.hitAccum < 0.05 then return end
        state.hitAccum = 0
        local now = tick()

        local wanted = {}
        if Config.HitboxMode == "lockedOnly" then
            local entry = state.locked
            if entry and hitboxEligible(entry) then
                table.insert(wanted, entry)
            end
        else
            for i = 1, math.min(Config.HitboxMaxActive, #state.candidates) do
                local entry = state.candidates[i]
                if hitboxEligible(entry) then
                    table.insert(wanted, entry)
                    if #wanted >= Config.HitboxMaxActive then break end
                end
            end
        end

        local wantedSet = {}
        for _, entry in ipairs(wanted) do wantedSet[entry.player] = entry end

        -- Entries no longer wanted collapse back.
        for player, record in pairs(state.hitEntries) do
            if not wantedSet[player] then
                local done = true
                for _, item in ipairs(record.parts) do
                    local part = item.part
                    if part and part.Parent then
                        part.Size = part.Size:Lerp(item.origSize, 0.5)
                        part.Transparency = part.Transparency + (item.origTransparency - part.Transparency) * 0.5
                        if (part.Size - item.origSize).Magnitude > 0.01 then done = false end
                    end
                end
                if done then
                    restoreHitEntry(player, record)
                end
            end
        end

        for _, entry in ipairs(wanted) do
            local record = state.hitEntries[entry.player]
            if record and record.parts[1] and record.parts[1].part ~= entry.root then
                restoreHitEntry(entry.player, record)
                record = nil
            end
            if not record then
                beginHitEntry(entry)
                record = state.hitEntries[entry.player]
            end
            if record then
                for _, item in ipairs(record.parts) do
                    local part = item.part
                    if not part or not part.Parent then
                        restoreHitEntry(entry.player, record)
                        break
                    end
                    if item.phase == "expanding" then
                        local target = targetSizeFor(item.origSize, entry.worldDist)
                        part.Size = part.Size:Lerp(target, 0.35)
                        part.Transparency = part.Transparency + (0.55 - part.Transparency) * 0.35
                        if (part.Size - target).Magnitude < 0.02 then
                            item.phase = "pending"
                            item.since = now
                        end
                    elseif item.phase == "pending" then
                        part.Transparency = part.Transparency + (0.55 - part.Transparency) * 0.35
                        if now - item.since >= 0.25 then
                            item.phase = "expanding"
                        end
                    end
                    part.CanCollide = false
                end
            end
        end
    end

    -- Immediate restore on character/player changes: a stale entry would
    -- otherwise keep mutating a respawned character's parts.
    local function hookLifecycle()
        local function onCharacterRemoving(character)
            local player = Players:GetPlayerFromCharacter(character)
            if player and state.hitEntries[player] then
                restoreHitEntry(player, state.hitEntries[player])
            end
        end
        local conns = {}
        conns[#conns + 1] = Workspace.DescendantRemoving:Connect(function(inst)
            if inst:IsA("Model") then onCharacterRemoving(inst) end
        end)
        conns[#conns + 1] = Players.PlayerRemoving:Connect(function(player)
            if state.hitEntries[player] then
                restoreHitEntry(player, state.hitEntries[player])
            end
            state.velEMA[player], state.rollCache[player], state.rollAt[player] = nil, nil, nil
            if state.locked and state.locked.player == player then state.locked = nil end
            if state.lastLocked and state.lastLocked.player == player then state.lastLocked = nil end
            for i=#state.candidates,1,-1 do
                if state.candidates[i].player == player then table.remove(state.candidates,i) end
            end
        end)
        c.OnCleanup(function()
            for _, con in ipairs(conns) do pcall(function() con:Disconnect() end) end
        end)
    end
    hookLifecycle()

    --=========================================================================
    -- FOV circle (ScreenGui, random name, cloaked).
    --=========================================================================
    local fovGui, fovFrame, fovStroke
    local fovColors = { Red = Color3.fromRGB(255,90,90), Green = Color3.fromRGB(80,230,140), Cyan = Color3.fromRGB(0,180,255) }
    local fovColor = "Red"
    local function ensureFovCircle()
        if fovFrame and fovFrame.Parent then return fovFrame end
        local parent = c.GetGuiParent()
        if not parent then return nil end
        local sg = Instance.new("ScreenGui")
        sg.Name = c.RandomName()
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 999
        sg.Parent = parent
        if c.Cloak then sg = c.Cloak.Protect(sg) end
        local frame = Instance.new("Frame")
        frame.Name = c.RandomName()
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        frame.BackgroundTransparency = 1
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = frame
        local stroke = Instance.new("UIStroke")
        stroke.Color = fovColors[fovColor]
        fovStroke = stroke
        stroke.Thickness = 1.5
        stroke.Transparency = 0.35
        stroke.Parent = frame
        frame.Parent = sg
        if c.Cloak then frame = c.Cloak.Protect(frame) end
        fovGui, fovFrame = sg, frame
        return frame
    end

    local function fovTick()
        if Config.Enabled and Config.FOVCircle then
            local frame = ensureFovCircle()
            if frame then
                frame.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
                frame.Visible = true
            end
        elseif fovFrame and fovFrame.Parent then
            fovFrame.Visible = false
        end
    end

    --=========================================================================
    -- Public interface (consumed by Core and the Bullet module).
    --=========================================================================
    local Combat = {}

    function Combat:IsActive()
        return not stopped and (Config.Enabled or Config.TriggerEnabled or Config.HitboxEnabled or state.firing)
    end

    function Combat:Update(dt)
        if stopped then return end
        local t0 = tick()
        if state.firing and (not Config.TriggerEnabled or not gateHeld() or t0 >= releaseAt) then finishFire() end
        local active = Config.Enabled or Config.TriggerEnabled or Config.HitboxEnabled
        if not active then
            state.locked = nil
            state.candidates = {}
            hitboxTick(dt)
            fovTick()
            return
        end
        state.scanAccum += dt
        if state.scanAccum >= 0.1 then
            state.scanAccum = 0
            scan()
        end
        state.lastLocked = state.locked
        if not lockStillValid() then
            selectTarget()
        end
        local entry = state.locked
        if Config.Enabled and gateHeld() and entry and chanceFor(entry) then
            local part = pickPart(entry)
            if part then
                local aimPos = Combat_PredictPoint(entry, part)
                if aimPos then
                    if Config.Mode == "Camera" then
                        cameraAim(dt, aimPos)
                    elseif Config.Mode == "Mouse" then
                        mouseAim(dt, aimPos)
                    else
                        local camera = Workspace.CurrentCamera
                        local screen, onScreen
                        if camera then screen, onScreen = camera:WorldToViewportPoint(aimPos) end
                        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
                        local dist = onScreen and (Vector2.new(screen.X, screen.Y) - Vector2.new(viewport.X / 2, viewport.Y / 2)).Magnitude or math.huge
                        if dist > Config.FOV * 0.25 then
                            cameraAim(dt, aimPos)
                        else
                            mouseAim(dt, aimPos)
                        end
                    end
                end
            end
        end
        triggerTick(tick())
        hitboxTick(dt)
        fovTick()
        state.cost = tick() - t0
    end

    -- Lock accessor for the Bullet module and trigger integration.
    function Combat:GetLock()
        if not Config.Enabled or not gateHeld() or not lockStillValid() then return nil end
        local entry = state.locked
        if not entry or not chanceFor(entry) then return nil end
        local part = pickPart(entry)
        if not part then return nil end
        local point = Combat_PredictPoint(entry, part)
        if not point then return nil end
        return { player = entry.player, part = part, point = point, entry = entry }
    end

    -- Public prediction entry (player, part) -> Vector3.
    function Combat:PredictPoint(player, part)
        if not part then return nil end
        local ema = state.velEMA[player]
        local pos = part.Position
        if not ema then return pos end
        local lead = 0.5 * c.Ping() + 0.05
        return pos + ema * (lead * (Config.Prediction / 0.12))
    end

    function Combat:GetEnvelope(part)
        if not part then return Vector3.zero end
        return part.Size * 0.5 + Vector3.new(0.5, 0.5, 0.5)
    end

    function Combat:GetEnvelopeMargin(part)
        if not part then return 0.5 end
        return 0.5
    end

    function Combat:GetCandidates()
        return state.candidates
    end

    function Combat:DebugSnapshot()
        return {
            locked = state.locked and state.locked.player.Name or "-",
            candidates = #state.candidates,
            hitEntries = (function() local n = 0; for _ in pairs(state.hitEntries) do n += 1 end; return n end)(),
            firing = state.firing,
            costMs = math.floor(state.cost * 100000) / 100,
            scans = state.scans,
            active = Config.Enabled,
            gate = Config.TriggerKey,
            turnRate = Config.AimTurnRate,
        }
    end

    function Combat:Stop()
        for player, record in pairs(state.hitEntries) do
            restoreHitEntry(player, record)
        end
        if fovGui then fovGui:Destroy(); fovGui = nil; fovFrame = nil end
        stopped = true
        finishFire()
        state.locked, state.lastLocked = nil, nil
        state.candidates, state.velEMA, state.rollCache, state.rollAt = {}, {}, {}, {}
        Config.Enabled = false
        Config.TriggerEnabled = false
        Config.HitboxEnabled = false
    end

    c.OnCleanup(function()
        Combat:Stop()
    end)

    --=========================================================================
    -- UI (Combat tab). Original flag names preserved.
    --=========================================================================
    local tab = c.Tabs.Combat
    tab:AddToggle("BloxAimEnabled", { Title = "自瞄辅助", Default = false, Callback = function(v)
        Config.Enabled = v
        c.Log("Combat", "aim", v, Config.Mode)
    end })
    tab:AddDropdown("BloxAimMode", { Title = "瞄准模式", Values = { "Camera", "Mouse", "Both" }, Default = "Camera",
        Callback = function(v) Config.Mode = v end })
    tab:AddDropdown("BloxAimPart", { Title = "瞄准部位", Values = { "Head", "Torso", "Arms", "Legs", "Random" }, Default = "Head",
        Callback = function(v) Config.Hitbox = v end })
    tab:AddToggle("BloxTouchAim", { Title = "按住瞄准（右键/触屏）", Default = false, Callback = function(v)
        Config.TriggerKey = v and "Hold" or "Always"
    end })
    tab:AddToggle("BloxWallCheck", { Title = "墙体检查", Default = true, Callback = function(v) Config.WallCheck = v end })
    tab:AddToggle("BloxTeamCheck", { Title = "仅敌方", Default = true, Callback = function(v) Config.TeamCheck = v end })
    tab:AddSlider("BloxAimFov", { Title = "自瞄 FOV", Min = 50, Max = 600, Default = 240, Rounding = 0,
        Callback = function(v) Config.FOV = v end })
    tab:AddSlider("BloxAimSmooth", { Title = "平滑（越小越快）", Min = 0.05, Max = 0.95, Default = 0.35, Rounding = 2,
        Callback = function(v) Config.Smoothness = v end })
    tab:AddSlider("BloxAimPrediction", { Title = "预测强度", Min = 0, Max = 0.5, Default = 0.12, Rounding = 2,
        Callback = function(v) Config.Prediction = v end })
    tab:AddSlider("BloxAimMaxAngle", { Title = "最大锁定角（度）", Min = 5, Max = 90, Default = 35, Rounding = 0,
        Callback = function(v) Config.MaxAngle = v end })
    tab:AddSlider("BloxAimHitChance", { Title = "本地辅助触发概率（%）", Min = 10, Max = 100, Default = 100, Rounding = 0,
        Callback = function(v) Config.HitChance = v / 100 end })
    tab:AddSlider("BloxAimTurnRate", {Title = "镜头最大转速（度/秒）", Min = 20, Max = 360,
        Default = 120, Rounding = 0, Callback = function(v) Config.AimTurnRate = v end})
    tab:AddDropdown("BloxAimPriority", {Title = "目标优先级", Values = {"Crosshair", "Distance", "LowHealth"},
        Default = "Crosshair", Callback = function(v) Config.Priority = v end})
    tab:AddButton({Title = "打印战斗识别诊断", Callback = function()
        local snapshot = Combat:DebugSnapshot()
        print(("[Vortexion/BloxCombat] 自瞄=%s 扫描=%d 目标=%d 锁定=%s 门控=%s 角度=%d")
            :format(tostring(snapshot.active), snapshot.scans, snapshot.candidates,
                snapshot.locked, snapshot.gate, Config.MaxAngle))
    end})
    tab:AddSlider("BloxAimAttraction", { Title = "鼠标吸附强度", Min = 0.1, Max = 1, Default = 0.6, Rounding = 2,
        Callback = function(v) Config.Attraction = v end })
    tab:AddSlider("BloxAimDistance", { Title = "最大锁定距离", Min = 50, Max = 2000, Default = 500, Rounding = 0,
        Callback = function(v) Config.MaxDistance = v end })
    tab:AddDropdown("BloxTouchRegion", { Title = "触屏控制区域", Values = { "Right", "All" }, Default = "Right",
        Callback = function(v) c.Touch.Region = v end })
    tab:AddDropdown("BloxFovColor", { Title = "FOV 配色", Values = { "Red", "Green", "Cyan" }, Default = "Red",
        Callback = function(v) fovColor = v; if fovStroke then fovStroke.Color = fovColors[v] or fovColors.Red end end })
    tab:AddToggle("BloxFovCircle", { Title = "FOV 圆圈", Default = true, Callback = function(v) Config.FOVCircle = v end })

    tab:AddToggle("BloxTriggerAssist", { Title = "自动开火", Default = false, Callback = function(v)
        Config.TriggerEnabled = v
        if not v then finishFire() end
        c.Log("Combat", "trigger", v, Config.TriggerMode)
    end })
    tab:AddDropdown("BloxTriggerMode", { Title = "开火条件", Values = { "Locked", "Always" }, Default = "Locked",
        Callback = function(v) Config.TriggerMode = v end })
    tab:AddSlider("BloxTriggerDelay", { Title = "开火按压时长", Min = 0.02, Max = 0.5, Default = 0.12, Rounding = 2,
        Callback = function(v) Config.TriggerDelay = v end })

    tab:AddToggle("BloxHitbox", { Title = "本地碰撞箱扩展", Default = false, Callback = function(v)
        Config.HitboxEnabled = v
        if not v then hitboxTick(0) end
        c.Log("Combat", "hitbox", v)
    end })
    tab:AddDropdown("BloxHitboxMode", { Title = "碰撞箱范围", Values = { "lockedOnly", "fullBody" }, Default = "lockedOnly",
        Callback = function(v) Config.HitboxMode = v end })
    tab:AddSlider("BloxHitboxSize", { Title = "碰撞箱倍率", Min = 1.1, Max = 3, Default = 1.6, Rounding = 1,
        Callback = function(v) Config.HitboxSize = v end })
    tab:AddParagraph({ Title = "碰撞箱说明",
        Content = "本地 Size 修改不会复制到服务器；扩展仅本地可见，并在角色离开/重开时自动还原。命中改写见武器页签的子弹追踪。" })

    return Combat
end

end)()
local BloxBulletFactory = (function()
-- Vortexion BloxStrike bullet tracking.
--
-- Four paths, auto-selected by capability probe and live game structure:
--   A LeadOnly   - prediction already lives in Combat (velocity EMA + ping).
--                  Always on when aimbot prediction > 0; no hooks needed.
--   B Hitscan    - require the weapon module (ReplicatedStorage.Components.
--                  Weapon.Classes.Bullet and siblings), hook its raycast/fire
--                  functions and rewrite the direction argument so the local
--                  ray lands on the locked target. RaycastResult cannot be
--                  forged from Lua, so the input is the only honest lever.
--   C Remote     - hook __namecall and rewrite Vector3 arguments of weapon
--                  remotes (FireServer / InvokeServer): unit directions are
--                  re-pointed at the target, world-space hit points are
--                  clamped into the target's original-size envelope so the
--                  server-side check still sees a plausible hit.
--   D Projectile - watch Workspace for freshly spawned bullet parts and steer
--                  their velocity toward the predicted intercept point.
--
-- Every hook is pcall-wrapped, uninstallable, and skips executor-originated
-- calls (checkcaller) so this script's own remotes are never rewritten.
return function(c)
    local Players = c.Services.Players
    local Workspace = c.Services.Workspace
    local ReplicatedStorage = c.Services.ReplicatedStorage
    local RunService = c.Services.RunService
    local LocalPlayer = c.LocalPlayer

    local Config = {
        Enabled = false,
        Mode = "LeadOnly",      -- safe startup: no metatable or function hooks
        HitChance = 0.72,
        MaxAngle = 15,
        WallCheck = true,
        TeamCheck = true,
        Envelope = true,         -- clamp rewritten world points into orig size
        ProjectileTrack = true,
        ProjectileLerp = 0.35,
        ProjectileMax = 8,
        Debug = false,
    }

    local state = {
        activePath = "LeadOnly",
        remoteHookOriginal = nil,
        remoteHookInstalled = false,
        weaponFunctions = {},     -- [original fn] = true (for uninstall)
        watchedRemotes = setmetatable({}, { __mode = "k" }), -- [remote] = true
        remoteCount = 0,
        bullets = {},             -- tracked projectile entries
        rollCache = {},
        rollAt = {},
        cost = 0,
        errors = 0,
    }

    --=========================================================================
    -- Aim resolution: prefer the Combat lock, else the on-screen candidate
    -- nearest the crosshair. Shared by every rewrite path.
    --=========================================================================
    local function resolveAim()
        local combat = c.Combat
        if combat and combat.GetLock then
            local lock = combat.GetLock()
            if lock then
                return lock.point, lock.part, lock.player
            end
        end
        if combat and combat.GetCandidates then
            local camera = Workspace.CurrentCamera
            if not camera then return nil end
            local viewport = camera.ViewportSize
            local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
            local best, bestDist
            for _, entry in ipairs(combat.GetCandidates()) do
                local part = entry.head or entry.root
                if part then
                    local pos = combat.PredictPoint and combat.PredictPoint(entry.player, part) or part.Position
                    local screen, onScreen = camera:WorldToScreenPoint(pos)
                    if onScreen and screen.Z > 0 then
                        local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                        if not bestDist or dist < bestDist then
                            best, bestDist = pos, dist
                        end
                    end
                end
            end
            if best then return best, nil, nil end
        end
        return nil
    end

    --=========================================================================
    -- Gates: angle between current view and aim point, plus a per-shot roll
    -- so the server never sees a 100% conversion profile.
    --=========================================================================
    local function withinAngle(aimPos)
        local camera = Workspace.CurrentCamera
        if not camera then return false end
        local look = aimPos - camera.CFrame.Position
        if look.Magnitude < 0.01 then return true end
        local angle = math.acos(math.clamp(camera.CFrame.LookVector:Dot(look.Unit), -1, 1))
        return math.deg(angle) <= Config.MaxAngle
    end

    local function hitRoll(key)
        local now = tick()
        if not state.rollAt[key] or now - state.rollAt[key] > 0.5 then
            state.rollAt[key] = now
            state.rollCache[key] = math.random()
        end
        return state.rollCache[key] <= Config.HitChance
    end

    local function envelopeClamp(point, part)
        if not Config.Envelope or not part then return point end
        local center = part.Position
        local half = part.Size * 0.5 + Vector3.new(0.5, 0.5, 0.5)
        local offset = point - center
        return center + Vector3.new(
            math.clamp(offset.X, -half.X, half.X),
            math.clamp(offset.Y, -half.Y, half.Y),
            math.clamp(offset.Z, -half.Z, half.Z)
        )
    end

    --=========================================================================
    -- Path B: hitscan input rewrite.
    --=========================================================================
    local WEAPON_NAME_HINTS = { "raycast", "cast", "fire", "perform", "shoot", "trace" }

    local function nameLooksWeapon(name)
        local lower = name:lower()
        for _, hint in ipairs(WEAPON_NAME_HINTS) do
            if lower:find(hint, 1, true) then return true end
        end
        return false
    end

    local function rewriteHitscanArgs(original, ...)
        if not Config.Enabled then return nil end
        local packed = table.pack(...)
        local vectors = {}
        for i = 1, math.min(packed.n, 8) do
            if typeof(packed[i]) == "Vector3" then
                table.insert(vectors, { index = i, value = packed[i] })
            end
        end
        if #vectors == 0 then return nil end

        local origin, direction
        for _, entry in ipairs(vectors) do
            local mag = entry.value.Magnitude
            if not origin and mag > 1.5 then
                origin = entry.value
            elseif not direction and mag > 0.95 and mag < 1.05 then
                direction = entry
            end
        end
        if not direction and #vectors >= 1 then
            for _, entry in ipairs(vectors) do
                if entry.value.Magnitude > 0.95 and entry.value.Magnitude < 1.05 then
                    direction = entry
                    break
                end
            end
        end
        if not direction then return nil end
        if not origin then
            local camera = Workspace.CurrentCamera
            if not camera then return nil end
            origin = camera.CFrame.Position
        end

        local aimPos, aimPart = resolveAim()
        if not aimPos then return nil end
        if not withinAngle(aimPos) then return nil end
        if not hitRoll("hitscan") then return nil end
        aimPos = envelopeClamp(aimPos, aimPart)

        local dir = (aimPos - origin)
        if dir.Magnitude < 0.01 then return nil end
        packed[direction.index] = dir.Unit * direction.value.Magnitude
        c.Log("Bullet", "hitscan rewrite idx", direction.index)
        return packed
    end

    local function installHitscanHooks()
        if not c.Caps.hookfunction then return false end
        local ok, err = pcall(function()
            local components = ReplicatedStorage:FindFirstChild("Components")
            local weaponRoot = components and components:FindFirstChild("Weapon")
            if not weaponRoot then
                c.Log("Bullet", "no Components.Weapon; hitscan unavailable")
                return
            end
            local classes = weaponRoot:FindFirstChild("Classes")
            local scanRoots = classes and { classes } or { weaponRoot }
            local hooked = 0
            for _, root in ipairs(scanRoots) do
                for _, module in ipairs(root:GetDescendants()) do
                    if module:IsA("ModuleScript") and hooked < 12 then
                        local okRequire, result = pcall(require, module)
                        if okRequire and type(result) == "table" then
                            for key, value in pairs(result) do
                                if type(value) == "function" and nameLooksWeapon(key) and hooked < 12 and not state.weaponFunctions[value] then
                                    local original
                                    local okHook = pcall(function()
                                        original = hookfunction(value, function(...)
                                            local okRw, rewritten = pcall(rewriteHitscanArgs, ...)
                                            if okRw and rewritten then
                                                return original(unpack(rewritten, 1, rewritten.n))
                                            end
                                            return original(...)
                                        end)
                                    end)
                                    if okHook and original then
                                        state.weaponFunctions[value] = original
                                        hooked += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
            c.Log("Bullet", "hitscan hooks", hooked)
        end)
        if not ok then
            state.errors += 1
            c.Log("Bullet", "hitscan install failed", err)
        end
        return ok and next(state.weaponFunctions) ~= nil
    end

    --=========================================================================
    -- Path C: remote argument rewrite via __namecall hook.
    --=========================================================================
    local REMOTE_NAME_HINTS = { "fire", "shoot", "bullet", "weapon", "hit", "damage", "replicate", "raycast" }

    local function remoteLooksWatched(name)
        local lower = name:lower()
        for _, hint in ipairs(REMOTE_NAME_HINTS) do
            if lower:find(hint, 1, true) then return true end
        end
        return false
    end

    local function scanRemotes()
        local count = 0
        for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
            if count >= 400 then break end
            if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
                count += 1
                if remoteLooksWatched(inst.Name) then
                    state.watchedRemotes[inst] = true
                end
            end
        end
        state.remoteCount = count
        c.Log("Bullet", "watched remotes", count)
    end

    local function rewriteRemoteArgs(...)
        local packed = table.pack(...)
        local aimPos, aimPart = resolveAim()
        if not aimPos then return nil end
        if not withinAngle(aimPos) then return nil end
        if not hitRoll("remote") then return nil end
        aimPos = envelopeClamp(aimPos, aimPart)
        local camera = Workspace.CurrentCamera
        if not camera then return nil end
        local camPos = camera.CFrame.Position
        local changed = false
        for i = 1, packed.n do
            local v = packed[i]
            if typeof(v) == "Vector3" then
                local mag = v.Magnitude
                if mag > 0.95 and mag < 1.05 then
                    local dir = aimPos - camPos
                    if dir.Magnitude > 0.01 then
                        packed[i] = dir.Unit * mag
                        changed = true
                    end
                elseif mag > 5 then
                    -- World-space point: clamp into the target envelope only
                    -- when it already sits near the target (hit report).
                    if (v - aimPos).Magnitude < 200 then
                        packed[i] = aimPos
                        changed = true
                    end
                end
            end
        end
        if changed then
            c.Log("Bullet", "remote rewrite")
            return packed
        end
        return nil
    end

    local function installRemoteHook()
        if not (c.Caps.hookmetamethod and c.Caps.getrawmetatable and c.Caps.checkcaller and c.Caps.getnamecallmethod) then
            return false
        end
        local ok, err = pcall(function()
            local metatable = getrawmetatable(game)
            local original = metatable.__namecall
            state.remoteHookOriginal = original
            local replacement = function(self, ...)
                if Config.Enabled and state.watchedRemotes[self] then
                    local methodOk, method = pcall(getnamecallmethod)
                    if methodOk and (method == "FireServer" or method == "InvokeServer") then
                        local callerOk, fromExecutor = pcall(checkcaller)
                        if not (callerOk and fromExecutor) then
                            local okRw, rewritten = pcall(rewriteRemoteArgs, ...)
                            if okRw and rewritten then
                                return original(self, unpack(rewritten, 1, rewritten.n))
                            end
                        end
                    end
                end
                return original(self, ...)
            end
            if c.Caps.newcclosure then
                replacement = newcclosure(replacement)
            end
            hookmetamethod(game, "__namecall", replacement)
            state.remoteHookInstalled = true
        end)
        if not ok then
            state.errors += 1
            c.Log("Bullet", "remote hook failed", err)
        end
        return ok
    end

    local function uninstallRemoteHook()
        if not state.remoteHookInstalled then return end
        pcall(function()
            hookmetamethod(game, "__namecall", state.remoteHookOriginal)
        end)
        state.remoteHookInstalled = false
        c.Log("Bullet", "remote hook removed")
    end

    --=========================================================================
    -- Path D: projectile tracking. A part spawned close to the camera with
    -- velocity and no anchor is treated as a local bullet for 3 seconds.
    --=========================================================================
    local bulletConns = {}

    local function trackBullet(inst)
        if #state.bullets >= Config.ProjectileMax then return end
        local part = inst
        if inst:IsA("Model") then
            part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        end
        if not part or not part:IsA("BasePart") then return end
        if part.Anchored then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        if (part.Position - camera.CFrame.Position).Magnitude > 60 then return end
        local localChar = LocalPlayer and LocalPlayer.Character
        if localChar and part:IsDescendantOf(localChar) then return end
        table.insert(state.bullets, { part = part, since = tick() })
        c.Log("Bullet", "tracking projectile", part:GetFullName())
    end

    local function projectileTick(dt)
        if not (Config.Enabled and Config.ProjectileTrack) then
            if #state.bullets > 0 then state.bullets = {} end
            return
        end
        local now = tick()
        for i = #state.bullets, 1, -1 do
            local bullet = state.bullets[i]
            local part = bullet.part
            if not part or not part.Parent or now - bullet.since > 3 then
                table.remove(state.bullets, i)
            else
                local aimPos = resolveAim()
                if aimPos then
                    local pos = part.Position
                    local dir = aimPos - pos
                    if dir.Magnitude > 0.5 then
                        local current = part.AssemblyLinearVelocity
                        if current and current.Magnitude > 1 then
                            local speed = current.Magnitude
                            local desired = dir.Unit * speed
                            part.AssemblyLinearVelocity = current:Lerp(desired, math.clamp(Config.ProjectileLerp, 0.05, 1))
                        end
                    end
                end
            end
        end
    end

    local function installProjectileWatch()
        local conn = Workspace.DescendantAdded:Connect(function(inst)
            if not Config.Enabled then return end
            if inst:IsA("BasePart") then
                trackBullet(inst)
            elseif inst:IsA("Model") then
                task.defer(function()
                    if inst.Parent then trackBullet(inst) end
                end)
            end
        end)
        table.insert(bulletConns, conn)
    end

    --=========================================================================
    -- Mode resolution.
    --=========================================================================
    local function resolveMode()
        if Config.Mode ~= "Auto" then
            return Config.Mode
        end
        local hitscan = next(state.weaponFunctions) ~= nil
        local remote = next(state.watchedRemotes) ~= nil
        if hitscan then return "Hitscan" end
        if remote then return "Remote" end
        return "LeadOnly"
    end

    --=========================================================================
    -- Public interface.
    --=========================================================================
    local Bullet = {}

    function Bullet:Start()
        if Config.Enabled then return end
        Config.Enabled = true
        -- On mobile, never attempt native/global hooks merely because the
        -- user enables the generic toggle. Explicit high-risk modes can be
        -- selected separately; LeadOnly remains a hook-free safe default.
        local mode = Config.Mode
        local mobile = c.Services.UserInputService and c.Services.UserInputService.TouchEnabled
        if mode == "Hitscan" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Hitscan", installHitscanHooks)
        end
        if mode == "Remote" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Scan", scanRemotes)
            c.Guard("Bullet.Remote", installRemoteHook)
        end
        if mode == "Projectile" or mode == "Auto" then
            if #bulletConns == 0 then installProjectileWatch() end
        end
        state.activePath = resolveMode()
        c.Log("Bullet", "started, path", state.activePath)
    end

    function Bullet:Stop()
        Config.Enabled = false
        uninstallRemoteHook()
        for value, original in pairs(state.weaponFunctions) do
            pcall(hookfunction, value, original)
        end
        state.weaponFunctions = {}
        for k in pairs(state.watchedRemotes) do state.watchedRemotes[k] = nil end
        state.bullets = {}
        state.activePath = "LeadOnly"
        c.Log("Bullet", "stopped")
    end

    function Bullet:IsActive()
        return Config.Enabled
    end

    function Bullet:Update(dt)
        if not Config.Enabled then
            if #state.bullets > 0 then state.bullets = {} end
            return
        end
        local t0 = tick()
        c.Guard("Bullet.Projectile", projectileTick, dt)
        state.cost = tick() - t0
    end

    function Bullet:Status()
        return {
            path = state.activePath,
            hooks = (function() local n = 0; for _ in pairs(state.weaponFunctions) do n += 1 end; return n end)(),
            remotes = (function() local n = 0; for _ in pairs(state.watchedRemotes) do n += 1 end; return n end)(),
            totalRemotes = state.remoteCount,
            bullets = #state.bullets,
            errors = state.errors,
            costMs = math.floor(state.cost * 100000) / 100,
        }
    end

    function Bullet:Rescan()
        for k in pairs(state.watchedRemotes) do state.watchedRemotes[k] = nil end
        local mode = Config.Mode
        local mobile = c.Services.UserInputService and c.Services.UserInputService.TouchEnabled
        if mode == "Remote" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Scan", scanRemotes)
        end
        if mode == "Hitscan" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Hitscan", installHitscanHooks)
        end
        state.activePath = resolveMode()
    end

    c.OnCleanup(function()
        Bullet:Stop()
        for _, conn in ipairs(bulletConns) do
            pcall(function() conn:Disconnect() end)
        end
        bulletConns = {}
    end)

    --=========================================================================
    -- UI (Weapon tab): bullet tracking controls replace the old placeholder.
    --=========================================================================
    local tab = c.Tabs.Weapon
    tab:AddParagraph({ Title = "子弹追踪",
        Content = "四条路径自动选择：预测提前量（始终）、武器射线输入改写、远程事件参数改写、投射物速度追踪。能力不足时自动降级。" })
    tab:AddToggle("BloxBulletEnabled", { Title = "启用子弹追踪", Default = false, Callback = function(v)
        if v then Bullet:Start() else Bullet:Stop() end
    end })
    tab:AddDropdown("BloxBulletMode", { Title = "追踪路径", Values = { "Auto", "LeadOnly", "Hitscan", "Remote", "Projectile" },
        Default = "LeadOnly", Callback = function(v)
            -- Switching path while active must release the old hook first.
            local wasEnabled = Config.Enabled
            if wasEnabled then Bullet:Stop() end
            Config.Mode = v
            state.activePath = resolveMode()
            if wasEnabled then Bullet:Start() end
        end })
    tab:AddSlider("BloxBulletHitChance", { Title = "改写命中率（%）", Min = 10, Max = 100, Default = 72, Rounding = 0,
        Callback = function(v) Config.HitChance = v / 100 end })
    tab:AddSlider("BloxBulletMaxAngle", { Title = "改写最大角（度）", Min = 5, Max = 90, Default = 15, Rounding = 0,
        Callback = function(v) Config.MaxAngle = v end })
    tab:AddToggle("BloxBulletEnvelope", { Title = "命中点包络回投", Default = true, Callback = function(v)
        Config.Envelope = v end })
    tab:AddToggle("BloxBulletWallCheck", { Title = "墙体检查", Default = true, Callback = function(v)
        Config.WallCheck = v end })
    tab:AddToggle("BloxBulletProjectile", { Title = "投射物追踪", Default = true, Callback = function(v)
        Config.ProjectileTrack = v end })
    tab:AddSlider("BloxBulletLerp", { Title = "投射物转向强度", Min = 0.05, Max = 1, Default = 0.35, Rounding = 2,
        Callback = function(v) Config.ProjectileLerp = v end })
    tab:AddToggle("BloxBulletDebug", { Title = "调试日志", Default = false, Callback = function(v)
        Config.Debug = v
        c.Debug = v
    end })
    tab:AddButton({ Title = "重新扫描武器接口", Callback = function()
        Bullet:Rescan()
        local status = Bullet:Status()
        c.Notify("子弹追踪", ("路径 %s · 钩子 %d · 监听远程 %d/%d"):format(
            status.path, status.hooks, status.remotes, status.totalRemotes))
    end })

    return Bullet
end

end)()
local BloxVisualFactory = (function()
-- Vortexion BloxStrike visual: player ESP, fullbright, movement helpers.
--
-- ESP highlights now use random names and cloak protection (the old fixed
-- "VortexionBloxESP" name was a one-line scan signature), refresh at 20Hz
-- with distance/team filtering, and tear down on PlayerRemoving.
--
-- Speed keeps the WalkSpeed writer for game compatibility but adds the
-- pulse/coast AssemblyLinearVelocity cycle from the SCP branch: a constant
-- max-speed stream is a lagback signature, 100ms boost + 150ms coast is not.
return function(c)
    local Players = c.Services.Players
    local Workspace = c.Services.Workspace
    local RunService = c.Services.RunService
    local UserInputService = c.Services.UserInputService
    local LocalPlayer = c.LocalPlayer

    local Config = {
        ESPEnabled = false,
        ESPTeam = true,
        ESPDistance = 500,
        ESPNames = true,
        ESPHealth = true,
        ESPRange = true,
        ESPVisibility = true,
        ESPBox = false,
        ESPTracer = false,
        Fullbright = false,
        SpeedEnabled = false,
        SpeedValue = 24,
        PulseBoostMs = 100,
        PulseCoastMs = 150,
        CoastFactor = 0.16,
        FlyEnabled = false,
        TouchFly = true,
        FlySpeed = 60,
        Noclip = false,
    }

    --=========================================================================
    -- ESP: pooled highlights, random names, cloaked, lifecycle-aware.
    --=========================================================================
    local highlights = {}
    local espStats = { refreshes = 0, scanned = 0, eligible = 0, markers = 0, noHumanoid = 0, lastError = "none" }
    local ESP_GRACE_SECONDS = 0.8
    local espAccum = 0
    local visibilityParams = RaycastParams.new()
    visibilityParams.FilterType = Enum.RaycastFilterType.Blacklist
    visibilityParams.IgnoreWater = true

    local function clearEntry(player)
        local entry = highlights[player]
        if not entry then return end
        if entry.model then pcall(function() entry.model:Destroy() end) end
        if entry.labelGui then pcall(function() entry.labelGui:Destroy() end) end
        if entry.box then pcall(function() entry.box:Remove() end) end
        if entry.tracer then pcall(function() entry.tracer:Remove() end) end
        if entry.nativeBox then entry.nativeBox:Destroy() end
        if entry.adorneeConn then pcall(function() entry.adorneeConn:Disconnect() end) end
        highlights[player] = nil
    end

    local function clearESP()
        for player in pairs(highlights) do clearEntry(player) end
    end

    local function updateESP()
        if not Config.ESPEnabled then clearESP(); return end
        espStats.scanned, espStats.eligible, espStats.noHumanoid = 0, 0, 0
        local now = os.clock()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then
                clearEntry(player)
            else
                espStats.scanned += 1
                local model, humanoid = c.Living(player)
                if model and humanoid and not model:FindFirstChildOfClass("Humanoid") then
                    espStats.noHumanoid += 1
                end
                local valid = model and humanoid and humanoid.Health > 0
                    and ((not Config.ESPTeam) or c.Enemy(player, true))
                if valid then
                    local camera = Workspace.CurrentCamera
                    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChildWhichIsA("BasePart")
                    if not camera or not root then valid = false end
                    if camera and root then
                        local dist = (root.Position - camera.CFrame.Position).Magnitude
                        if dist > Config.ESPDistance then valid = false end
                    end
                end
                if valid then
                    espStats.eligible += 1
                    local entry = highlights[player]
                    if not entry or entry.model.Parent ~= model then
                        clearEntry(player)
                        local highlight = Instance.new("Highlight")
                        highlight.Name = c.RandomName()
                        highlight.Adornee = model
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.FillTransparency = 0.75
                        highlight.OutlineTransparency = 0.08
                        highlight.FillColor = Color3.fromRGB(240, 90, 90)
                        highlight.OutlineColor = Color3.fromRGB(255, 160, 100)
                        highlight.Parent = model
                        if c.Cloak then highlight = c.Cloak.Protect(highlight) end
                        local conn
                        conn = model.AncestryChanged:Connect(function(_, parent)
                            if not parent then
                                clearEntry(player)
                            end
                        end)
                        local labelGui = Instance.new("BillboardGui")
                        labelGui.Name = c.RandomName()
                        labelGui.Adornee = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
                            or model:FindFirstChildWhichIsA("BasePart", true)
                        labelGui.AlwaysOnTop = true
                        labelGui.Size = UDim2.fromOffset(180, 48)
                        labelGui.StudsOffset = Vector3.new(0, 2.5, 0)
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.fromScale(1, 1)
                        label.BackgroundTransparency = 1
                        label.TextSize = 14
                        label.TextStrokeTransparency = 0.35
                        label.Parent = labelGui
                        labelGui.Parent = model
                        if c.Cloak then c.Cloak.Protect(labelGui) end
                        highlights[player] = { model = highlight, labelGui = labelGui, label = label, adorneeConn = conn }
                    end
                    local entry = highlights[player]
                    entry.lastSeen = now
                    local camera = Workspace.CurrentCamera
                    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                    local color = Color3.fromRGB(240, 90, 90)
                    if Config.ESPVisibility and camera and root then
                        visibilityParams.FilterDescendantsInstances = { c.Character() }
                        local hit = Workspace:Raycast(camera.CFrame.Position, root.Position - camera.CFrame.Position, visibilityParams)
                        if not hit or (hit.Instance and hit.Instance:IsDescendantOf(model)) then color = Color3.fromRGB(80, 230, 140) end
                    end
                    entry.model.FillColor = color
                    entry.model.OutlineColor = color
                    entry.label.TextColor3 = color
                    local lines = {}
                    if Config.ESPNames then table.insert(lines, player.DisplayName or player.Name) end
                    if Config.ESPHealth and (type(humanoid) ~= "table" or humanoid.HealthKnown ~= false) then
                        table.insert(lines, ("HP %d/%d"):format(math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)))
                    end
                    if Config.ESPRange and camera and root then table.insert(lines, ("%d studs"):format(math.floor((root.Position - camera.CFrame.Position).Magnitude))) end
                    entry.label.Text = table.concat(lines, "\n")
                    entry.labelGui.Enabled = #lines > 0
                    if c.HasDrawing then
                        if Config.ESPBox and not entry.box then
                            entry.box = Drawing.new("Square")
                            entry.box.Filled = false
                            entry.box.Thickness = 1.5
                        end
                        if Config.ESPTracer and not entry.tracer then
                            entry.tracer = Drawing.new("Line")
                            entry.tracer.Thickness = 1
                        end
                        if entry.box then entry.box.Visible = false end
                        if entry.tracer then entry.tracer.Visible = false end
                        if camera and root then
                            local point, onScreen = camera:WorldToViewportPoint(root.Position)
                            if onScreen and point.Z > 0 then
                                if Config.ESPTracer and entry.tracer then
                                    entry.tracer.From = Vector2.new(camera.ViewportSize.X / 2, 0)
                                    entry.tracer.To = Vector2.new(point.X, point.Y)
                                    entry.tracer.Color = color
                                    entry.tracer.Visible = true
                                end
                                if Config.ESPBox and entry.box then
                                    local cf, size = model:GetBoundingBox()
                                    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                                    local inFront = true
                                    for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
                                        local corner = camera:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(size.X*x/2,size.Y*y/2,size.Z*z/2)))
                                        if corner.Z <= 0 then inFront = false end
                                        minX = math.min(minX,corner.X); minY = math.min(minY,corner.Y)
                                        maxX = math.max(maxX,corner.X); maxY = math.max(maxY,corner.Y)
                                    end end end
                                    if inFront then
                                        entry.box.Position = Vector2.new(minX,minY)
                                        entry.box.Size = Vector2.new(maxX-minX,maxY-minY)
                                        entry.box.Color = color
                                        entry.box.Visible = true
                                    end
                                end
                            end
                        end
                    else
                        if Config.ESPBox and not entry.nativeBox then
                            entry.nativeBox = Instance.new("SelectionBox")
                            entry.nativeBox.Name = c.RandomName()
                            entry.nativeBox.Adornee = model
                            entry.nativeBox.LineThickness = 0.025
                            entry.nativeBox.SurfaceTransparency = 1
                            entry.nativeBox.Parent = model
                            if c.Cloak then c.Cloak.Protect(entry.nativeBox) end
                        end
                        if entry.nativeBox then entry.nativeBox.Visible = Config.ESPBox; entry.nativeBox.Color3 = color end
                    end
                else
                    local existing = highlights[player]
                    -- A roster swap or a brief camera/view-distance miss must
                    -- not destroy/recreate ESP several times per second.
                    if not existing or not existing.lastSeen or now - existing.lastSeen > ESP_GRACE_SECONDS
                        or (existing.labelGui and not existing.labelGui.Parent) then
                        clearEntry(player)
                    end
                end
            end
        end
        local count = 0
        for pl in pairs(highlights) do
            if not pl.Parent then clearEntry(pl) else count += 1 end
        end
        espStats.markers = count
    end

    local function startESP()
        espAccum = 0
        c.Guard("Visual.ESP", updateESP)
    end

    --=========================================================================
    -- Fullbright with a full backup/restore cycle.
    --=========================================================================
    local lightingBackup
    local function setLight(on)
        local Lighting = c.Lighting
        if on then
            if not lightingBackup then
                lightingBackup = {
                    Brightness = Lighting.Brightness,
                    ClockTime = Lighting.ClockTime,
                    Ambient = Lighting.Ambient,
                    OutdoorAmbient = Lighting.OutdoorAmbient,
                    GlobalShadows = Lighting.GlobalShadows,
                    FogEnd = Lighting.FogEnd,
                }
            end
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.Ambient = Color3.fromRGB(175, 175, 175)
            Lighting.OutdoorAmbient = Color3.fromRGB(175, 175, 175)
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e10
        elseif lightingBackup then
            for key, value in pairs(lightingBackup) do
                pcall(function() Lighting[key] = value end)
            end
            lightingBackup = nil
        end
    end

    --=========================================================================
    -- Movement: speed (pulse/coast), fly, noclip.
    --=========================================================================
    local speedBackup = nil
    local origWalkSpeed = nil
    local speedRoot, speedVelocity
    local pulseState = "idle"
    local pulseStart = 0

    local function restoreSpeed()
        if speedBackup and speedBackup.Parent and origWalkSpeed then
            pcall(function() speedBackup.WalkSpeed = origWalkSpeed end)
        end
        if speedRoot and speedRoot.Parent and speedVelocity then speedRoot.AssemblyLinearVelocity = speedVelocity end
        speedRoot, speedVelocity = nil, nil
        speedBackup = nil
        origWalkSpeed = nil
        pulseState = "idle"
    end

    local function updateSpeed()
        local model, humanoid = c.Living(LocalPlayer)
        if not (model and humanoid) then restoreSpeed(); return end
        -- Virtual HP records support target discovery only. They are NOT
        -- actual movement controllers; never write fake WalkSpeed onto them.
        if model:FindFirstChildOfClass("Humanoid") ~= humanoid then
            restoreSpeed()
            return
        end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then restoreSpeed(); return end
        if speedBackup ~= humanoid then
            restoreSpeed()
            speedBackup = humanoid
            origWalkSpeed = humanoid.WalkSpeed
            speedRoot, speedVelocity = hrp, hrp.AssemblyLinearVelocity
        end
        if humanoid.WalkSpeed ~= Config.SpeedValue then
            humanoid.WalkSpeed = Config.SpeedValue
        end
        local direction = humanoid.MoveDirection
        if direction.Magnitude <= 0 then return end

        local now = tick()
        if pulseState == "idle" then
            pulseState = "boost"
            pulseStart = now
        end
        local boosting
        if pulseState == "boost" then
            if now - pulseStart >= Config.PulseBoostMs / 1000 then
                pulseState = "coast"
                pulseStart = now
                boosting = false
            else
                boosting = true
            end
        else
            if now - pulseStart >= Config.PulseCoastMs / 1000 then
                pulseState = "boost"
                pulseStart = now
                boosting = true
            else
                boosting = false
            end
        end

        local target = direction.Unit * (boosting and Config.SpeedValue or Config.SpeedValue * Config.CoastFactor)
        hrp.AssemblyLinearVelocity = Vector3.new(target.X, hrp.AssemblyLinearVelocity.Y, target.Z)
    end

    local flyRoot, flyVelocity
    local function restoreFly()
        if flyRoot and flyRoot.Parent and flyVelocity then flyRoot.AssemblyLinearVelocity = flyVelocity end
        flyRoot, flyVelocity = nil, nil
    end

    local function updateFly()
        local model, humanoid = c.Living(LocalPlayer)
        if not (model and humanoid) then restoreFly(); return end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then restoreFly(); return end
        if flyRoot ~= hrp then
            restoreFly()
            flyRoot, flyVelocity = hrp, hrp.AssemblyLinearVelocity
        end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
        if Config.TouchFly and c.Touch.Enabled and c.Touch.Held then
            local drag, vertical = c.Touch:Drag()
            if drag.Magnitude > 10 then
                move += camera.CFrame.RightVector * math.clamp(drag.X / 120, -1, 1)
                move -= camera.CFrame.LookVector * math.clamp(-drag.Y / 120, -1, 1)
            end
            if math.abs(vertical) > 30 then
                move += Vector3.new(0, math.clamp(-vertical / 120, -1, 1), 0)
            end
        end
        if move.Magnitude > 0 then
            hrp.AssemblyLinearVelocity = move.Unit * Config.FlySpeed
        else
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    local collisionBackup = {}
    local collisionModel
    local function restoreNoclip()
        for part, value in pairs(collisionBackup) do
            if part.Parent then part.CanCollide = value end
            collisionBackup[part] = nil
        end
        collisionModel = nil
    end
    local function updateNoclip()
        local model = c.Character()
        if model ~= collisionModel then restoreNoclip(); collisionModel = model end
        if not model then return end
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                if collisionBackup[part] == nil then collisionBackup[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end

    -- Third person: native Roblox camera settings, with reversible ownership.
    -- A game-controlled Scriptable camera can override these values; report
    -- that instead of pretending the toggle guarantees third person.
    local thirdPerson = {enabled = false, distance = 12, saved = nil, accumulator = 0, overrides = 0}
    local function restoreThirdPerson()
        local saved = thirdPerson.saved
        thirdPerson.saved = nil
        if not saved then return end
        pcall(function() LocalPlayer.CameraMode = saved.mode end)
        pcall(function()
            LocalPlayer.CameraMaxZoomDistance = math.max(saved.maxZoom, saved.minZoom)
            LocalPlayer.CameraMinZoomDistance = saved.minZoom
            LocalPlayer.CameraMaxZoomDistance = saved.maxZoom
        end)
        local cam = saved.camera
        if cam and cam.Parent then
            pcall(function() cam.CameraType = saved.cameraType end)
            if saved.subject and saved.subject.Parent then
                pcall(function() cam.CameraSubject = saved.subject end)
            end
        end
    end
    local function updateThirdPerson()
        if not thirdPerson.enabled then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        if not thirdPerson.saved then
            thirdPerson.saved = {
                mode = LocalPlayer.CameraMode,
                minZoom = LocalPlayer.CameraMinZoomDistance,
                maxZoom = LocalPlayer.CameraMaxZoomDistance,
                camera = camera,
                cameraType = camera.CameraType,
                subject = camera.CameraSubject,
            }
        end
        local d = thirdPerson.distance
        if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            thirdPerson.overrides += 1
        end
        -- Set max before min to avoid automatic Roblox min/max clamping.
        if LocalPlayer.CameraMaxZoomDistance ~= d then LocalPlayer.CameraMaxZoomDistance = d end
        if LocalPlayer.CameraMinZoomDistance ~= d then LocalPlayer.CameraMinZoomDistance = d end
        if camera.CameraType == Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Custom
            thirdPerson.overrides += 1
        end
        local model = c.Character(LocalPlayer)
        if model then
            local target = model:FindFirstChildOfClass("Humanoid")
                or model:FindFirstChild("HumanoidRootPart")
                or model:FindFirstChildWhichIsA("BasePart", true)
            if target and camera.CameraSubject ~= target then
                camera.CameraSubject = target
            end
        end
    end
    local function setThirdPerson(enabled)
        thirdPerson.enabled = enabled == true
        if not thirdPerson.enabled then restoreThirdPerson()
        else thirdPerson.accumulator = 0; c.Guard("Visual.ThirdPerson", updateThirdPerson) end
    end
    c.OnCleanup(restoreThirdPerson)
    local cameraChanged = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if thirdPerson.enabled then thirdPerson.accumulator = 0 end
    end)
    c.OnCleanup(function() cameraChanged:Disconnect() end)

    local moveAccum = 0
    local espInterval = 0.05
    local espRefreshes = 0
    local function visualInterval()
        if c.VisualInterval then
            local ok, value = pcall(c.VisualInterval, 0.05)
            if ok and type(value) == "number" and value == value and value > 0 then return value end
        end
        return 0.05
    end
    local function refreshESP()
        espRefreshes += 1
        espStats.refreshes = espRefreshes
        local ok, err = pcall(updateESP)
        if not ok then
            espStats.lastError = tostring(err):sub(1, 240)
            warn("[Vortexion/Blox/ESP] " .. espStats.lastError)
        end
    end
    local function forceESPTeardown()
        -- A camera swap must not wait for the throttled slot: stale highlights
        -- on a replaced camera are an immediate correctness bug, not pacing.
        clearESP()
        espAccum = espInterval
    end
    local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(forceESPTeardown)
    local frameConnection = RunService.Heartbeat:Connect(function(dt)
        if not c.IsCurrent() then return end
        -- Before enabling any feature, skip ALL camera, raycast, or movement
        -- calculations. The Heartbeat connection stays lightweight for toggles.
        if not Config.ESPEnabled and not Config.SpeedEnabled and not Config.FlyEnabled and not Config.Noclip and not thirdPerson.enabled then
            espAccum, moveAccum = 0, 0
            return
        end
        if thirdPerson.enabled then
            thirdPerson.accumulator += dt
            if thirdPerson.accumulator >= 0.25 then
                thirdPerson.accumulator = 0
                c.Guard("Visual.ThirdPerson", updateThirdPerson)
            end
        end
        -- Non-critical visual pacing is owned by the shared bridge (ctx.UI),
        -- re-read every frame so a VisualHz switch takes effect immediately.
        -- Movement, input and recovery paths below keep their original cadence.
        espInterval = visualInterval()
        espAccum += dt
        if Config.ESPEnabled and espAccum >= espInterval then
            espAccum = 0
            refreshESP()
        end
        moveAccum += dt
        if moveAccum >= 0.05 then
            moveAccum = 0
            if Config.SpeedEnabled and not Config.FlyEnabled then c.Guard("Visual.Speed", updateSpeed) end
            if Config.Noclip then c.Guard("Visual.Noclip", updateNoclip) end
        end
        if Config.FlyEnabled then c.Guard("Visual.Fly", updateFly) end
    end)
    c.OnCleanup(function() frameConnection:Disconnect() end)
    c.OnCleanup(function() pcall(function() cameraConnection:Disconnect() end) end)

    c.OnCleanup(function()
        Config.ESPEnabled = false
        Config.SpeedEnabled = false
        Config.FlyEnabled = false
        Config.Noclip = false
        clearESP()
        restoreSpeed()
        restoreFly()
        restoreNoclip()
        setLight(false)
        setThirdPerson(false)
    end)
    function Config:Status()
        return {
            markers = espStats.markers, scanned = espStats.scanned,
            eligible = espStats.eligible, refreshes = espStats.refreshes,
            noHumanoid = espStats.noHumanoid, error = espStats.lastError,
            thirdPerson = thirdPerson.enabled, thirdOverrides = thirdPerson.overrides,
        }
    end
    function Config.ESPRefreshCount() return espRefreshes end
    function Config.ESPInterval() return espInterval end

    --=========================================================================
    -- UI.
    --=========================================================================
    local tab = c.Tabs.Visual
    tab:AddToggle("BloxESP", { Title = "玩家高亮 ESP", Default = false, Callback = function(v)
        Config.ESPEnabled = v
        if v then startESP() else clearESP() end
    end })
    tab:AddToggle("BloxESPTeam", { Title = "仅显示敌方", Default = true, Callback = function(v)
        Config.ESPTeam = v
        c.Guard("Visual.ESP", updateESP)
    end })
    tab:AddSlider("BloxESPDistance", { Title = "ESP 距离", Min = 100, Max = 2000, Default = 500, Rounding = 0,
        Callback = function(v) Config.ESPDistance = v end })
    tab:AddToggle("BloxESPNames", { Title = "ESP 名称", Default = true, Callback = function(v) Config.ESPNames = v end })
    tab:AddToggle("BloxESPHealth", { Title = "ESP 血量", Default = true, Callback = function(v) Config.ESPHealth = v end })
    tab:AddToggle("BloxESPRange", { Title = "ESP 距离标签", Default = true, Callback = function(v) Config.ESPRange = v end })
    tab:AddToggle("BloxESPVisibility", { Title = "ESP 可见性配色", Default = true, Callback = function(v) Config.ESPVisibility = v end })
    tab:AddToggle("BloxESPBox", { Title = "ESP 方框（无 Drawing 时为原生框）", Default = false, Callback = function(v) Config.ESPBox = v end })
    tab:AddToggle("BloxESPTracer", { Title = "ESP 追踪线（需 Drawing）", Default = false, Callback = function(v) Config.ESPTracer = v end })
    tab:AddToggle("BloxFullbright", { Title = "全亮", Default = false, Callback = function(v)
        Config.Fullbright = v
        setLight(v)
    end })
    tab:AddButton({Title = "打印 ESP 目标诊断", Callback = function()
        local status = Config:Status()
        print(("[Vortexion/BloxESP] 开关=%s 玩家=%d 合格=%d 无Humanoid=%d 高亮=%d 刷新=%d 错误=%s")
            :format(tostring(Config.ESPEnabled), status.scanned, status.eligible,
                status.noHumanoid, status.markers, status.refreshes, status.error))
    end})
    tab:AddParagraph({ Title = "视觉刷新节流",
        Content = "ESP 属于非关键视觉刷新，节拍由共享桥接 ctx.UI:GetVisualInterval(0.05) 决定（VisualHz 5..60 有界）；桥接未提供该方法时保持 20Hz。移动、输入、重生恢复与飞行不受该节流影响；摄像机更换、关闭与卸载立即清理，不等节流槽。" })

    local movement = c.Tabs.Movement
    movement:AddToggle("BloxThirdPerson", {Title = "第三人称视角", Default = false,
        Callback = setThirdPerson})
    movement:AddSlider("BloxThirdDistance", {Title = "第三人称镜头距离", Min = 5, Max = 24,
        Default = 12, Rounding = 0, Callback = function(value)
            thirdPerson.distance = value
            if thirdPerson.enabled then c.Guard("Visual.ThirdPerson", updateThirdPerson) end
        end})
    movement:AddParagraph({Title="第三人称说明", Content="基于 Roblox Classic 镜头与缩放距离；关闭时恢复原相机属性。若游戏主动强制接管相机，可能被覆盖。"})
    movement:AddToggle("BloxSpeedEnabled", { Title = "自定义移动速度", Default = false, Callback = function(v)
        Config.SpeedEnabled = v
        if not v then restoreSpeed() end
    end })
    movement:AddSlider("BloxWalkSpeed", { Title = "移动速度", Min = 16, Max = 65, Default = 24, Rounding = 0,
        Callback = function(v)
            Config.SpeedValue = v
            if speedBackup and speedBackup.Parent then
                speedBackup.WalkSpeed = v
            end
        end })
    movement:AddToggle("BloxFlyEnabled", { Title = "飞行", Default = false, Callback = function(v)
        Config.FlyEnabled = v
        if v then restoreSpeed() else restoreFly() end
    end })
    movement:AddSlider("BloxFlySpeed", { Title = "飞行速度", Min = 20, Max = 200, Default = 60, Rounding = 0,
        Callback = function(v) Config.FlySpeed = v end })
    movement:AddToggle("BloxTouchFly", { Title = "触屏拖动飞行", Default = true, Callback = function(v)
        Config.TouchFly = v
    end })
    movement:AddToggle("BloxNoclip", { Title = "穿墙", Default = false, Callback = function(v)
        Config.Noclip = v
        if not v then restoreNoclip() end
    end })
    movement:AddParagraph({ Title = "移动兼容性",
        Content = "速度与穿墙按 20Hz 更新；飞行优先于速度并逐帧更新。关闭与重生恢复原始属性；右半屏未被界面消费的拖动控制飞行，两指控制升降。" })

    return Config
end

end)()
local BloxCosmeticFactory = (function()
-- BloxStrike camera appearance, capability-based local previews.
return function(c)
    local tab,knifeTab=c.Tabs.Appearance,c.Tabs.Knife
    local state={enabled=false,selected={},wear="Factory New",knife=false,knifeName="Butterfly Knife",touchButtons=false,gloveMode="自动",sleeves=true}
    local original={}
    local applied={}
    local dirty = false
    local reconcileKnife
    local knifeSource, knifeCamera
    local cameraConnection
    local stopNative, tryNative, updateNative
    local nativeTrack, nativeMode, nativeStarted
    local actionSerial, swingIndex = 0, 0
    local stopKnifeSounds, destroyAttachments, refreshButtons, destroyButtons, knifeApi
    -- Procedural local preview state: pose animation, one-shot sounds, arm attachments.
    local anim={mode="idle",started=0,duration=0}
    local activeSounds={}
    local attached={}
    local buttonGui, inspectButton, swingButton, stopButton
    local ANIM={equip=0.35,inspect=1.1,swing=0.28}
    local supportedKnives={"Butterfly Knife","Karambit","M9 Bayonet","Flip Knife","Gut Knife"}
    local knifeOffsets={
        ["Butterfly Knife"]=CFrame.new(0,-1.5,1.5),Karambit=CFrame.new(0,-1.5,1.5),
        ["M9 Bayonet"]=CFrame.new(0,-1.5,1),["Flip Knife"]=CFrame.new(0,-1.5,1.25),
        ["Gut Knife"]=CFrame.new(0,-1.5,0.5)
    }
    local knifeModel
    local hidden={}
    local knifeFollow
    local function roots()
        local assets=c.ReplicatedStorage:FindFirstChild("Assets")
        return assets,assets and assets:FindFirstChild("Skins")
    end
    -- Find a native view-model animation for a preview mode without loading it:
    -- hop-by-hop pcall lookups only, returns (animator,animation) or nil. Never
    -- creates a controller/animator, never waits, never loads the animation.
    local function findNativeAnimation(model,mode)
        if mode~="Equip" and mode~="Idle" and mode~="Inspect" and mode~="Heavy Swing" and mode~="Swing1" and mode~="Swing2" then return nil end
        if not c.IsCurrent() then return nil end
        if not model or not model.Parent then return nil end
        if model~=knifeModel then return nil end
        local animation
        local ok=pcall(function()
            local assets=c.ReplicatedStorage:FindFirstChild("Assets")
            local weaponAnimations=assets and assets:FindFirstChild("WeaponAnimations")
            local perKnife=weaponAnimations and weaponAnimations:FindFirstChild(state.knifeName)
            local cameraAnimations=perKnife and perKnife:FindFirstChild("CameraAnimations")
            animation=cameraAnimations and cameraAnimations:FindFirstChild(mode)
            if not (animation and animation:IsA("Animation")) then animation=nil end
        end)
        if not ok or not animation then return nil end
        local animator
        ok=pcall(function()
            animator=model:FindFirstChildWhichIsA("Animator",true)
            if not (animator and animator:IsA("Animator") and animator.Parent) then animator=nil end
        end)
        if not ok or not animator then return nil end
        if not c.IsCurrent() or model~=knifeModel or not model or not model.Parent then return nil end
        return animator,animation
    end
    local function restoreParts()
        for part,data in pairs(original) do
            if applied[part] then applied[part]:Destroy(); applied[part]=nil end
            if data and data.Parent==nil then
                if part and part.Parent then data.Parent=part else data:Destroy() end
            end
            original[part]=nil
        end
    end
    local function restoreKnife()
        knifeSource, knifeCamera = nil, nil
        actionSerial += 1
        if stopNative then stopNative() end
        if knifeModel then knifeModel:Destroy();knifeModel=nil end
        if stopKnifeSounds then stopKnifeSounds() end
        if destroyAttachments then destroyAttachments() end
        anim.mode="idle"
        if refreshButtons then refreshButtons() end
        for part,transparency in pairs(hidden) do
            if part and part.Parent then part.Transparency=transparency end
            hidden[part]=nil
        end
    end
    -- One-shot knife sounds: clone ReplicatedStorage/Sounds/<knife>/<folder>/<index>,
    -- parent under the view model, reclaim on Ended, on a bounded lifetime, or on any
    -- teardown path (disable/respawn/camera/cleanup).
    local SOUND_MAX_LIFETIME=5
    local previewSpeed,previewVolume=1,1
    local soundConnections={}
    local function disposeSound(sound)
        local connection=soundConnections[sound]
        local owned=activeSounds[sound]~=nil or connection~=nil
        activeSounds[sound],soundConnections[sound]=nil,nil
        if connection then pcall(function() connection:Disconnect() end) end
        if owned then pcall(function() sound:Destroy() end) end
    end
    local function playKnifeSound(folder,index)
        if not knifeModel then return nil end
        local sounds,perKnife,group,template
        local ok=pcall(function()
            sounds=c.ReplicatedStorage:FindFirstChild("Sounds")
            perKnife=sounds and sounds:FindFirstChild(state.knifeName)
            group=perKnife and perKnife:FindFirstChild(folder)
            template=group and group:FindFirstChild(index or "1")
        end)
        if not ok or not template then return nil end
        local clone
        local ok=pcall(function()
            clone=template:Clone()
            clone.Name=c.RandomName()
            clone.Parent=knifeModel
            if previewVolume~=1 and type(previewVolume)=="number" and previewVolume==previewVolume then
                local vol=tonumber(clone.Volume)
                if vol then clone.Volume=math.clamp(vol*previewVolume,0,10) end
            end
            clone:Play()
        end)
        if not ok or not clone then
            if clone then pcall(function() clone:Destroy() end) end
            return nil
        end
        activeSounds[clone]=tick()
        local connected,connection=pcall(function()
            local ended=clone.Ended
            if ended and type(ended.Connect)=="function" then
                return ended:Connect(function() disposeSound(clone) end)
            end
        end)
        if connected and connection then
            if activeSounds[clone]~=nil then soundConnections[clone]=connection
            else pcall(function() connection:Disconnect() end) end
        end
        return clone
    end
    -- A missing Ended capability still has a bounded lifetime.
    local function reclaimSounds(maxAge)
        for sound,born in pairs(activeSounds) do
            local ok,parent=pcall(function() return sound.Parent end)
            if not ok or not parent or tick()-born>=(maxAge or SOUND_MAX_LIFETIME) then
                disposeSound(sound)
            end
        end
    end
    function stopKnifeSounds()
        for sound in pairs(activeSounds) do disposeSound(sound) end
        for sound in pairs(soundConnections) do disposeSound(sound) end
    end
    -- Motor6D needs real BaseParts on both sides; a Model exposes PrimaryPart, a
    -- BasePart does not, so never read PrimaryPart unconditionally.
    local function firstBasePart(inst)
        if not inst then return nil end
        if inst:IsA("BasePart") then return inst end
        if inst:IsA("Model") then
            local primary=inst.PrimaryPart
            if primary and primary:IsA("BasePart") then return primary end
            return inst:FindFirstChildWhichIsA("BasePart",true)
        end
        return nil
    end
    -- Glove / sleeve attachment: clone the arm asset onto the view model arms with a
    -- Motor6D. Missing assets are skipped silently instead of fabricating ids, and a
    -- half-finished clone/motor pair is rolled back before anything is committed.
    local function attachArmAsset(folder,armName,assetName,offset)
        if not knifeModel or not folder then return nil end
        local arm=firstBasePart(knifeModel:FindFirstChild(armName,true))
        if not arm then return nil end
        local template=folder:FindFirstChild(assetName)
        if not template then return nil end
        local clone,motor
        local ok=pcall(function()
            clone=template:Clone()
            clone.Name=c.RandomName()
            clone.Parent=arm
            motor=Instance.new("Motor6D")
            motor.Name=c.RandomName()
            motor.Part0=arm
            motor.Part1=firstBasePart(clone)
            motor.C0=offset
            motor.Parent=arm
        end)
        if not ok or not clone or not motor then
            if motor then motor:Destroy() end
            if clone then clone:Destroy() end
            return nil
        end
        attached[clone]=true
        attached[motor]=true
        return clone
    end
    local function attachGloves()
        if not knifeModel then return end
        local living=c.Living(c.LocalPlayer)
        if not living then return end
        local assets=c.ReplicatedStorage:FindFirstChild("Assets")
        local weapons=assets and assets:FindFirstChild("Weapons")
        local sleeves=assets and assets:FindFirstChild("Sleeves")
        -- Glove source: 自动 follows the live team, T/CT force that branch, 不附着
        -- attaches nothing; any unrecognized value falls back to 自动, never invented.
        local mode=state.gloveMode
        if mode~="T Glove" and mode~="CT Glove" and mode~="不附着" then
            mode=living.Parent and living.Parent.Name=="Terrorists" and "T Glove" or "CT Glove"
        end
        if mode=="不附着" then return end
        local gloveOffset=CFrame.new(0,0,-1.5)
        local sleeveOffset=CFrame.new(0,0,0.5)
        if mode=="T Glove" then
            local gloves=weapons and weapons:FindFirstChild("T Glove")
            attachArmAsset(gloves,"Left Arm","Left Arm",gloveOffset)
            attachArmAsset(gloves,"Right Arm","Right Arm",gloveOffset)
        else
            local ctGloves=weapons and weapons:FindFirstChild("CT Glove")
            local sleeve=state.sleeves and sleeves and sleeves:FindFirstChild("IDF")
            attachArmAsset(sleeve,"Left Arm","Left Arm",sleeveOffset)
            attachArmAsset(ctGloves,"Left Arm","Left Arm",gloveOffset)
            attachArmAsset(sleeve,"Right Arm","Right Arm",sleeveOffset)
            attachArmAsset(ctGloves,"Right Arm","Right Arm",gloveOffset)
        end
    end
    function destroyAttachments()
        for obj in pairs(attached) do
            if obj then obj:Destroy() end
            attached[obj]=nil
        end
    end
    -- Own only tracks and rig changes on the disposable camera clone.
    local nativeSerial, nativeRig = 0, {}
    local function disposeNative(track)
        if track then
            pcall(function() track:Stop(0) end)
            pcall(function() track:Destroy() end)
        end
    end
    stopNative = function()
        nativeSerial += 1
        local track, rig = nativeTrack, nativeRig
        nativeTrack, nativeMode, nativeStarted, nativeRig = nil, nil, nil, {}
        disposeNative(track)
        for object, saved in pairs(rig) do
            pcall(function()
                if object.Parent then
                    if saved.transform then object.Transform = saved.transform
                    else object.Anchored = saved.anchored end
                end
            end)
        end
    end
    tryNative = function(name)
        local model = knifeModel
        stopNative()
        local serial = nativeSerial
        local animator, animation = findNativeAnimation(model, name)
        if not animator then return false end
        local function current()
            local ok, value = pcall(function()
                return c.IsCurrent() and state.knife and serial == nativeSerial and model == knifeModel
                    and model.Parent == knifeCamera and knifeCamera == c.Workspace.CurrentCamera
                    and animator:IsDescendantOf(model)
            end)
            return ok and value == true
        end
        local track
        local loaded = pcall(function() track = animator:LoadAnimation(animation) end)
        if not loaded or not track or not current() then disposeNative(track); return false end
        local prepared = pcall(function()
            for _, joint in ipairs(model:GetDescendants()) do
                if joint:IsA("Motor6D") then
                    nativeRig[joint] = {transform = joint.Transform}
                    local part = joint.Part1
                    if part and part ~= model.PrimaryPart and part:IsDescendantOf(model) then
                        if not nativeRig[part] then nativeRig[part] = {anchored = part.Anchored} end
                        part.Anchored = false
                    end
                end
            end
        end)
        if not prepared or not current() then
            if serial == nativeSerial then stopNative() end
            disposeNative(track)
            return false
        end
        nativeTrack, nativeMode, nativeStarted = track, name, tick()
        local played = pcall(function()
            track.Looped = name == "Idle"
            track:Play(0.05, 1, previewSpeed)
        end)
        if not played or not current() or nativeTrack ~= track then
            if nativeTrack == track then stopNative() else disposeNative(track) end
            return false
        end
        return true
    end
    updateNative = function()
        if not nativeTrack then return false end
        local playing, age = false, tick() - nativeStarted
        local ok = pcall(function() playing = nativeTrack.IsPlaying end)
        if not ok or (not playing and age >= 0.1) or (nativeMode ~= "Idle" and age >= 30) then
            local wasIdle = nativeMode == "Idle"
            stopNative()
            anim.mode = "idle"
            if not wasIdle then tryNative("Idle") end
        end
        return nativeTrack ~= nil
    end

    -- Procedural preview poses: local-only motion derived from tick(), never presented
    -- as the original animation set. Idle keeps the previous static offset exactly.
    local function startAnim(mode,duration,nativeName)
        actionSerial += 1
        local request, model = actionSerial, knifeModel
        anim.mode=mode
        anim.started=tick()
        local speed=previewSpeed
        if type(speed)~="number" or speed~=speed or not (speed>0 and speed<math.huge) then speed=1 end
        anim.duration=(duration or ANIM[mode] or 0)/math.clamp(speed,0.25,2)
        if not nativeName then
            if mode=="swing" then swingIndex=swingIndex%2+1; nativeName="Swing"..swingIndex
            else nativeName=mode=="equip" and "Equip" or "Inspect" end
        end
        tryNative(nativeName)
        return request==actionSerial and model==knifeModel and c.IsCurrent()
    end
    local function knifePose()
        local base=knifeOffsets[state.knifeName] or CFrame.new(0,-1.5,1.5)
        if nativeTrack or anim.mode=="idle" or anim.duration<=0 then return base end
        local t=tick()-anim.started
        if t>=anim.duration then return base end
        local k=t/anim.duration
        local p=base.Position
        if anim.mode=="equip" then
            local ease=1-(1-k)*(1-k)*(1-k)
            local from=CFrame.new(0,-1.9,0.9).Position
            return CFrame.new(from.X+(p.X-from.X)*ease,from.Y+(p.Y-from.Y)*ease,from.Z+(p.Z-from.Z)*ease)
        elseif anim.mode=="inspect" then
            local wave=math.sin(k*math.pi*2)
            local tilt=math.sin(k*math.pi*4)
            return CFrame.new(p.X+0.12*wave,p.Y+0.06*tilt,p.Z+0.05*math.sin(k*math.pi*2+1.5708))
        end
        local arc=math.sin(k*math.pi)
        return CFrame.new(p.X,p.Y-0.55*arc,p.Z+0.35*arc)
    end
    -- Touch actions: real production callbacks, built only when a touch device and a
    -- permissioned GUI parent exist; otherwise the buttons are simply not created.
    local function makeButton(parent,text,onClick)
        local btn=Instance.new("TextButton")
        btn.Name=c.RandomName()
        btn.Text=text
        btn.Size=UDim2.new(0,110,0,44)
        btn.Parent=parent
        local conn=btn.MouseButton1Click or btn.Activated
        if conn then pcall(function()conn:Connect(onClick) end) end
        return btn
    end
    local function buildButtons()
        if buttonGui or not state.touchButtons or not knifeModel then return end
        if not (c.Touch and c.Touch.Enabled) then return end
        local parent=c.GetGuiParent and c.GetGuiParent()
        if not parent then return end
        local gui,inspect,swing,stop
        local ok=pcall(function()
            gui=Instance.new("ScreenGui")
            gui.Name=c.RandomName()
            gui.Parent=parent
            inspect=makeButton(gui,"Inspect",function()knifeApi.Inspect() end)
            swing=makeButton(gui,"Swing",function()knifeApi.Swing() end)
            stop=makeButton(gui,"Stop",function()knifeApi.Stop() end)
            inspect.Position=UDim2.new(0,12,1,-56)
            swing.Position=UDim2.new(0,130,1,-56)
            stop.Position=UDim2.new(0,248,1,-56)
        end)
        if not ok or not gui or not inspect or not swing or not stop then
            if gui then gui:Destroy() end
            return
        end
        buttonGui=gui
        inspectButton,swingButton,stopButton=inspect,swing,stop
    end
    function refreshButtons()
        if state.touchButtons and knifeModel then
            buildButtons()
        elseif buttonGui then
            destroyButtons()
        end
    end
    function destroyButtons()
        if buttonGui then buttonGui:Destroy();buttonGui=nil end
        inspectButton,swingButton,stopButton=nil,nil,nil
    end
    knifeApi={
        Inspect=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("inspect",ANIM.inspect) then return false end
            playKnifeSound("Inspect","1")
            return true
        end,
        Swing=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("swing",ANIM.swing) then return false end
            local roll=math.random(2,3)
            playKnifeSound(roll==2 and "HitTwo" or "HitThree","1")
            return true
        end,
        HeavySwing=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("swing",ANIM.swing,"Heavy Swing") then return false end
            playKnifeSound("HitThree","1")
            return true
        end,
        Stop=function()
            actionSerial += 1
            stopNative()
            stopKnifeSounds()
            anim.mode="idle"
            return true
        end,
        State=function()return anim.mode,knifeModel~=nil,next(activeSounds)~=nil end,
    }
    local function applySurface(part,source)
        if not part:IsA("BasePart") then return end
        local texture=source
        if source and not source:IsA("SurfaceAppearance") then
            texture=source:FindFirstChildOfClass("SurfaceAppearance")
        end
        if not texture then return end
        if original[part]==nil then
            local old=part:FindFirstChildOfClass("SurfaceAppearance")
            original[part]=old or false
            if old then old.Parent=nil end
        end
        if applied[part] then applied[part]:Destroy();applied[part]=nil end
        local clone=texture:Clone()
        clone.Name=c.RandomName()
        clone.Parent=part
        if c.Cloak then clone=c.Cloak.Protect(clone) end
        applied[part]=clone
    end
    local function applyModel(model, categoryName)
        if not state.enabled or not model or not model:IsA("Model") then return end
        local _,skins=roots()
        if not skins then return end
        local gloveCategory = skins:FindFirstChild("Sports Gloves")
        local gloveSkin = gloveCategory and gloveCategory:FindFirstChild(state.selected["Sports Gloves"] or "")
        local gloveCamera = gloveSkin and gloveSkin:FindFirstChild("Camera")
        local gloveWear = gloveCamera and (gloveCamera:FindFirstChild(state.wear) or gloveCamera:FindFirstChild("Factory New"))
        if gloveWear then
            for _, side in ipairs({"Left Arm", "Right Arm"}) do
                local arm = model:FindFirstChild(side, true)
                local glove = arm and arm:FindFirstChild("Glove", true)
                local source = gloveWear:FindFirstChild(side)
                if glove and source then applySurface(glove, source) end
            end
        end
        categoryName = categoryName or model.Name
        local selectedName=state.selected[categoryName]
        if not selectedName then return end
        local category=skins:FindFirstChild(categoryName)
        local skin=category and category:FindFirstChild(selectedName)
        local camera=skin and skin:FindFirstChild("Camera")
        local source=camera and (camera:FindFirstChild(state.wear) or camera:FindFirstChild("Factory New"))
        if not source then return end
        local weapon=model:FindFirstChild("Weapon")
        if not weapon then weapon=model end
        for _,part in ipairs(weapon:GetDescendants()) do
            if part:IsA("BasePart") then
                local match=source:FindFirstChild(part.Name)
                if match then applySurface(part,match) end
            end
        end
    end
    local function updateCamera()
        restoreParts()
        if not state.enabled then return end
        local camera=c.Workspace.CurrentCamera
        if camera then
            for _,model in ipairs(camera:GetChildren()) do
                applyModel(model, model == knifeModel and state.knifeName or nil)
            end
        end
    end
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
        local camera=c.Workspace.CurrentCamera
        if camera then
            cameraConnection=camera.ChildAdded:Connect(function(model)
                if c.IsCurrent() and model ~= knifeModel then dirty = true end
            end)
        end
    end
    local skinEnabledOption = tab:AddToggle("BloxSkinEnabled",{Title="启用本地皮肤替换",Default=false,Callback=function(v)
        state.enabled=v
        updateCamera()
        dirty = true
        watchCamera()
    end})
    tab:AddDropdown("BloxSkinWear",{Title="磨损版本",Values={"Factory New","Minimal Wear","Field-Tested","Well-Worn","Battle-Scarred"},
        Default="Factory New",Callback=function(v)state.wear=v;updateCamera() end})
    local created, usedIds = {}, {}
    local skinFolderConn, resourcesConn
    local refreshing, queuedRefresh = false, false
    local function skinValues(category)
        local values = {}
        for _, skin in ipairs(category:GetChildren()) do
            if skin:IsA("Folder") or skin:IsA("Model") then table.insert(values, skin.Name) end
        end
        table.sort(values)
        return values
    end
    local function addCategory(category)
        if not c.IsCurrent() or not category or not category:IsA("Folder") then return false end
        local values = skinValues(category)
        if #values == 0 then return false end
        local categoryName = category.Name
        local existing = created[categoryName]
        if existing then
            -- Newly replicated skins extend the current dropdown in place.
            if existing.option and type(existing.option.SetValues) == "function" then
                local changed = #existing.values ~= #values
                if not changed then
                    for i, v in ipairs(values) do
                        if existing.values[i] ~= v then changed = true; break end
                    end
                end
                if changed then
                    local ok = pcall(function() existing.option:SetValues(values) end)
                    if ok then existing.values = values end
                end
            end
            return false
        end
        local optionId = "BloxSkin_" .. categoryName:gsub("[^%w]", "_")
        if usedIds[optionId] and usedIds[optionId] ~= categoryName then
            local suffix = ""
            for i = 1, #categoryName do suffix ..= ("%02x"):format(categoryName:byte(i)) end
            optionId ..= "_" .. suffix
        end
        local default = state.selected[categoryName]
        if not default or not table.find(values, default) then default = values[1] end
        local targetTab = tab
        if categoryName:find("Knife") or categoryName:find("Glove") or categoryName == "Karambit" then
            targetTab = knifeTab
        end
        -- Reserve id before creating the native option; restore on exception so refresh can retry.
        created[categoryName] = {values = values}
        local ok, option = pcall(function()
            return targetTab:AddDropdown(optionId, {Title = categoryName .. " · 皮肤", Values = values,
                Default = default, Callback = function(v)
                    state.selected[categoryName] = v
                    if state.enabled then updateCamera() end
                end})
        end)
        if not ok or not option then
            created[categoryName] = nil
            warn("[Vortexion/BloxStrike] skin dropdown " .. categoryName .. ": " .. tostring(option))
            return false
        end
        created[categoryName].option = option
        usedIds[optionId] = categoryName
        state.selected[categoryName] = default
        return true
    end
    local createSkinControls
    local function queueSkinRefresh()
        if queuedRefresh or not c.IsCurrent() then return end
        queuedRefresh = true
        task.defer(function()
            queuedRefresh = false
            if c.IsCurrent() and createSkinControls then createSkinControls(false) end
        end)
    end
    createSkinControls = function(manual)
        if not c.IsCurrent() or refreshing then return end
        local _, skins = roots()
        if not skins then
            if manual then c.Notify("皮肤资源", "Assets/Skins 尚未加载，正在等待资源出现") end
            return
        end
        refreshing = true
        local list = skins:GetChildren()
        table.sort(list, function(a, b) return a.Name < b.Name end)
        local createdCount = 0
        -- Bound startup UI allocation on mobile. Remaining categories can
        -- still be loaded manually after the current batch completes.
        local addedThisPass = 0
        local maxPerPass = manual and 64 or 24
        for _, category in ipairs(list) do
            if not c.IsCurrent() or addedThisPass >= maxPerPass then break end
            if addCategory(category) then
                createdCount += 1
                addedThisPass += 1
                -- Keep each frame below the UI allocation budget.
                if addedThisPass % 2 == 0 then task.wait() end
            end
        end
        refreshing = false
        if skinFolderConn then skinFolderConn:Disconnect(); skinFolderConn = nil end
        if skins.DescendantAdded then
            skinFolderConn = skins.DescendantAdded:Connect(queueSkinRefresh)
        else
            skinFolderConn = skins.ChildAdded:Connect(queueSkinRefresh)
        end
        if manual and c.IsCurrent() then
            c.Notify("皮肤菜单", ("当前 %d 个分类，新增 %d 个控件"):format(#list, createdCount))
        end
    end
    -- No busy polling: react only when Assets/Skins is replicated or its children change.
    if c.ReplicatedStorage.DescendantAdded then
        resourcesConn = c.ReplicatedStorage.DescendantAdded:Connect(function(obj)
            if obj.Name == "Skins" or (obj.Parent and obj.Parent.Name == "Skins") then
                queueSkinRefresh()
            end
        end)
    else
        resourcesConn = c.ReplicatedStorage.ChildAdded:Connect(queueSkinRefresh)
    end
    tab:AddButton({Title="刷新皮肤分类与下拉框",Callback=function()
        task.spawn(function() createSkinControls(true) end)
    end})
    tab:AddButton({Title="查看皮肤资源状态",Callback=function()
        local assets, skins = roots()
        local total = skins and #skins:GetChildren() or 0
        local selectors = 0
        for _ in pairs(created) do selectors += 1 end
        c.Notify("皮肤资源状态", ("Assets=%s · Skins=%s · 分类=%d · 控件=%d"):format(
            assets and "就绪" or "缺失", skins and "就绪" or "缺失", total, selectors))
    end})
    tab:AddButton({Title="恢复默认皮肤",Callback=function()
        -- Synchronize the visible toggle and the internal state (avoids stale UI).
        if skinEnabledOption and type(skinEnabledOption.SetValue) == "function" then
            skinEnabledOption:SetValue(false)
        else
            state.enabled = false
        end
        restoreParts()
        c.Notify("已恢复","本地已修改的材质已撤销")
    end})
    reconcileKnife = function()
        local cam = c.Workspace.CurrentCamera
        local old = cam and (cam:FindFirstChild("T Knife") or cam:FindFirstChild("CT Knife"))
        local living = c.Living(c.LocalPlayer)
        if not state.knife or not cam or not old or not living then
            if knifeModel then restoreParts(); restoreKnife() end
            return
        end
        if knifeModel and knifeSource == old and knifeCamera == cam then return end
        restoreParts()
        restoreKnife()
        local assets = c.ReplicatedStorage:FindFirstChild("Assets")
        local weapons = assets and assets:FindFirstChild("Weapons")
        local template = weapons and weapons:FindFirstChild(state.knifeName)
        local cameraModel = template and template:FindFirstChild("Camera")
        if not cameraModel then return end
        local clone = cameraModel:Clone()
        clone.Name = c.RandomName()
        if not clone.PrimaryPart then clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true) end
        if not clone.PrimaryPart then clone:Destroy(); return end
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.Anchored=true
            end
        end
        knifeModel, knifeSource, knifeCamera = clone, old, cam
        clone.Parent = cam
        if c.Cloak then c.Cloak.Protect(clone) end
        for _, part in ipairs(old:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Texture") then
                hidden[part]=part.Transparency; part.Transparency=1
            end
        end
        attachGloves()
        if not startAnim("equip",ANIM.equip) then return end
        playKnifeSound("Equip","1")
        refreshButtons()
        dirty = true
    end
    -- Local preview only: no weapon hooks, raycasts or remote calls.
    local TRAIL_LIFETIME, TRAIL_LIMIT = 0.5, 32
    local trailEnabled, trailStopped = false, false
    local trailColor = Color3.new(1, 1, 1)
    local trailEntries = {}
    local function removeTrail(index)
        local entry = trailEntries[index]
        if not entry then return end
        table.remove(trailEntries, index)
        local part = entry.part
        entry.part = nil
        if part then pcall(function() part:Destroy() end) end
    end
    local function clearTrailPreview()
        while #trailEntries > 0 do removeTrail(#trailEntries) end
    end
    local function finiteTrailNumber(n)
        return type(n) == "number" and n == n and math.abs(n) < math.huge
    end
    local function validTrailVector(v)
        return typeof(v) == "Vector3" and finiteTrailNumber(v.X) and finiteTrailNumber(v.Y) and finiteTrailNumber(v.Z)
    end
    local function previewTrail()
        if trailStopped or not trailEnabled or not c.IsCurrent() then return false end
        local camera = c.Workspace.CurrentCamera
        if not camera then return false end
        local ok, origin, direction = pcall(function() return camera.CFrame.Position, camera.CFrame.LookVector end)
        if not ok or not validTrailVector(origin) or not validTrailVector(direction) then return false end
        local magnitude = direction.Magnitude
        if not finiteTrailNumber(magnitude) or magnitude < 0.000001 then return false end
        direction = direction / magnitude
        origin = origin + direction * 2
        if #trailEntries >= TRAIL_LIMIT then removeTrail(1) end
        if #trailEntries >= TRAIL_LIMIT or trailStopped or not trailEnabled or not c.IsCurrent() then return false end
        local entry = {camera = camera, born = tick()}
        local success, committed = pcall(function()
            local part = Instance.new("Part")
            entry.part = part
            table.insert(trailEntries, entry)
            if trailStopped or not trailEnabled or not c.IsCurrent() or camera ~= c.Workspace.CurrentCamera then return false end
            part.Name = "VortexionTrailPreview"
            part.Anchored = true
            part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = false, false, false, false
            part.Material, part.Color, part.Transparency = Enum.Material.Neon, trailColor, 0
            part.Size = Vector3.new(0.1, 0.1, 50)
            local midpoint = origin + direction * 25
            part.CFrame = CFrame.lookAt(midpoint, midpoint + direction)
            if not entry.part or trailStopped or not trailEnabled or not c.IsCurrent() or camera ~= c.Workspace.CurrentCamera then return false end
            part.Parent = camera
            return entry.part == part and not trailStopped and trailEnabled and c.IsCurrent() and camera == c.Workspace.CurrentCamera and part.Parent == camera
        end)
        if not success or not committed then
            for i = #trailEntries, 1, -1 do if trailEntries[i] == entry then removeTrail(i); break end end
            return false
        end
        return true
    end
    local function updateTrailPreview()
        if #trailEntries == 0 then return end
        if trailStopped or not trailEnabled or not c.IsCurrent() then clearTrailPreview(); return end
        local now, camera = tick(), c.Workspace.CurrentCamera
        for i = #trailEntries, 1, -1 do
            local entry = trailEntries[i]
            if entry then
                local age = now - entry.born
                if age >= TRAIL_LIFETIME or age < 0 or camera ~= entry.camera then
                    removeTrail(i)
                else
                    local updated, kept = pcall(function()
                        local part = entry.part
                        if not part or part.Parent ~= entry.camera then return false end
                        local fade = (1 - age / TRAIL_LIFETIME) ^ 2
                        part.Transparency = 1 - fade
                        part.Size = Vector3.new(0.1 * fade, 0.1 * fade, 50)
                        return true
                    end)
                    if not updated or not kept then removeTrail(i) end
                end
            end
        end
    end
    tab:AddToggle("BloxTrailPreview", {Title = "本地拖尾预览", Default = false, Callback = function(v)
        if trailStopped or not c.IsCurrent() then return end
        trailEnabled = v == true
        if not trailEnabled then clearTrailPreview() end
    end})
    tab:AddColorpicker("BloxTrailPreviewColor", {Title = "预览拖尾颜色", Default = trailColor, Callback = function(v)
        if trailStopped or not c.IsCurrent() or typeof(v) ~= "Color3" then return end
        local r, g, b = v.R, v.G, v.B
        if not finiteTrailNumber(r) or not finiteTrailNumber(g) or not finiteTrailNumber(b) or r < 0 or r > 1 or g < 0 or g > 1 or b < 0 or b > 1 then return end
        trailColor = v
    end})
    tab:AddButton({Title = "预览本地拖尾", Callback = previewTrail})
    tab:AddParagraph({Title = "拖尾预览范围", Content = "先开启预览，再点击按钮显示50 studs本地拖尾，0.5秒消退。仅手动预览，不连接真实开火、命中重写或网络事件。"})
    knifeTab:AddToggle("BloxCustomKnife",{Title="启用本地刀具模型",Default=false,Callback=function(v)
        state.knife=v
        if not v then restoreParts(); restoreKnife() end
        reconcileKnife()
        updateCamera()
    end})
    knifeTab:AddDropdown("BloxKnifeType",{Title="自定义刀具",Values=supportedKnives,
        Default="Butterfly Knife",Callback=function(v)
            state.knifeName=v
            if state.knife then
                restoreParts(); restoreKnife()
                reconcileKnife(); updateCamera()
            end
        end})
    knifeTab:AddToggle("BloxKnifeTouch",{Title="触屏刀具动作按钮",Default=false,Callback=function(v)
        state.touchButtons=v
        refreshButtons()
        c.Notify("刀具按钮",v and "触屏检视/挥动按钮已开启" or "触屏刀具按钮已关闭")
    end})
    knifeTab:AddSlider("BloxKnifePreviewSpeed",{Title="预览速度 %",Min=25,Max=200,Default=100,Callback=function(v)
        if not c.IsCurrent() then return end
        local n=tonumber(v)
        previewSpeed=(type(n)=="number" and n==n and n~=math.huge and n~=-math.huge and n>0) and math.clamp(n,25,200)/100 or 1
    end})
    knifeTab:AddSlider("BloxKnifeSoundVolume",{Title="音效音量 %",Min=0,Max=100,Default=100,Callback=function(v)
        if not c.IsCurrent() then return end
        local n=tonumber(v)
        previewVolume=(type(n)=="number" and n==n and n~=math.huge and n~=-math.huge and n>=0) and math.clamp(n,0,100)/100 or 1
    end})
    knifeTab:AddDropdown("BloxKnifeGloveMode",{Title="本地手套来源",Values={"自动","T Glove","CT Glove","不附着"},
        Default="自动",Callback=function(v)
            if not c.IsCurrent() then return end
            local mode=(v=="T Glove" or v=="CT Glove" or v=="不附着") and v or "自动"
            if state.gloveMode==mode then return end
            state.gloveMode=mode
            if knifeModel then destroyAttachments();if c.IsCurrent() and knifeModel then attachGloves() end end
        end})
    knifeTab:AddToggle("BloxKnifeSleeves",{Title="袖套开关（仅 CT 有效）",Default=true,Callback=function(v)
        if not c.IsCurrent() then return end
        local enabled=v==true
        if state.sleeves==enabled then return end
        state.sleeves=enabled
        if knifeModel then destroyAttachments();if c.IsCurrent() and knifeModel then attachGloves() end end
    end})
    knifeTab:AddButton({Title="刀具检视动画",Callback=function()knifeApi.Inspect() end})
    knifeTab:AddButton({Title="刀具挥动动画",Callback=function()knifeApi.Swing() end})
    knifeTab:AddButton({Title="刀具重挥动画",Callback=function()knifeApi.HeavySwing() end})
    knifeTab:AddButton({Title="停止动画与声音",Callback=function()knifeApi.Stop() end})
    knifeTab:AddParagraph({Title="刀具预览说明",
        Content="优先读取 Assets/WeaponAnimations/<刀具>/CameraAnimations 的 Equip、Idle、Inspect、Heavy Swing、Swing1、Swing2，只在本地模型自带 Animator 时播放；缺资源或加载失败则降级为程序式姿态。速度用于下一次本地预览，停止同时回收动画与声音。声音及手套/袖套按实际存在的资源使用；这些选项不修改服务器伤害、库存或游戏全局动画设置。"})
    knifeTab:AddParagraph({Title="外观规则",
        Content="皮肤由游戏 Assets/Skins 目录生成选择项。武器材质和刀具只作客户端视觉更改，不更改库存或服务器伤害。"})
    watchCamera()
    local cameraChanged = c.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        clearTrailPreview(); restoreParts(); restoreKnife(); watchCamera(); dirty = true
    end)
    local elapsed = 0
    knifeFollow = c.RunService.RenderStepped:Connect(function(dt)
        if not c.IsCurrent() then clearTrailPreview(); return end
        -- Avoid allocations, effects and camera work while appearance is off.
        if not state.enabled and not state.knife and not knifeModel and next(activeSounds)==nil and anim.mode=="idle" and #trailEntries==0 then
            elapsed=0
            return
        end
        updateTrailPreview()
        if not state.enabled and not state.knife and not knifeModel and next(activeSounds)==nil and anim.mode=="idle" then
            elapsed=0
            return
        end
        elapsed += dt
        if elapsed >= 0.1 then
            elapsed = 0
            reconcileKnife()
            if dirty then dirty = false; updateCamera() end
        end
        reclaimSounds()
        local nativePlaying = updateNative()
        if not nativePlaying and anim.mode~="idle" and tick()-anim.started>=anim.duration then
            anim.mode="idle"
            tryNative("Idle")
        end
        local cam = c.Workspace.CurrentCamera
        if knifeModel and knifeModel.PrimaryPart and cam then
            knifeModel:PivotTo(cam.CFrame * knifePose())
        end
    end)
    c.OnCleanup(function()
        trailStopped = true
        trailEnabled = false
        clearTrailPreview()
        knifeFollow:Disconnect(); cameraChanged:Disconnect()
        state.enabled=false;state.knife=false
        if cameraConnection then cameraConnection:Disconnect() end
        if skinFolderConn then skinFolderConn:Disconnect() end
        if resourcesConn then resourcesConn:Disconnect() end
        destroyButtons()
        restoreParts();restoreKnife()
    end)
    -- Give the UI and replicated game resources time to settle before the
    -- first skin category build. Reentrancy and generation guards remain.
    task.delay(3, function()
        if c.IsCurrent() then createSkinControls(false) end
    end)
end

end)()
-- Vortexion - BloxStrike v3: game-specific entry, unified WindUI UI.
-- Do not copy source implementations: use lifecycle-managed services in separate modules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

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

-- Executor identity is telemetry, not a compatibility oracle.
-- Earlier builds blacklisted Xeno/Velocity/LX63 and returned before creating
-- any UI, making all game features appear broken. Capability-dependent
-- features must degrade individually, not terminate the complete script.
local executorName = "unknown"
pcall(function()
    if type(identifyexecutor) == "function" then
        executorName = tostring(identifyexecutor() or "unknown")
    end
end)
global.VortexionExecutorName = executorName

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
-- In BloxStrike the authoritative client roster is Workspace.Characters.
-- Counter-Strike style character models do not necessarily use a Humanoid.
-- Requiring one removed EVERY target from ESP, aim assist and trigger logic.
local virtualVitals = setmetatable({}, {__mode = "k"})
local renderPartCache = setmetatable({}, {__mode = "k"})
local function numberVitals(model, player)
    local health = model:GetAttribute("Health")
    local maximum = model:GetAttribute("MaxHealth")
    local healthObject = model:FindFirstChild("Health")
    if health == nil and healthObject and healthObject:IsA("NumberValue") then health = healthObject.Value end
    if maximum == nil then
        local maxObject = model:FindFirstChild("MaxHealth")
        if maxObject and maxObject:IsA("NumberValue") then maximum = maxObject.Value end
    end
    local known = type(health) == "number"
    if known and health <= 0 then return nil end
    local vitals = virtualVitals[model]
    if not vitals then
        vitals = { Health = 1, MaxHealth = 1, HealthKnown = false }
        virtualVitals[model] = vitals
    end
    vitals.Health = known and health or 1
    vitals.MaxHealth = (type(maximum) == "number" and maximum > 0) and maximum or (known and math.max(health, 1) or 1)
    vitals.HealthKnown = known
    return vitals
end
local function livingCharacter(player)
    local model = characterOf(player)
    if not model or not model.Parent or not model:IsA("Model") or model:GetAttribute("Dead") == true then return nil end
    if model:GetAttribute("Alive") == false then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 then return nil end
        return model, hum
    end
    -- Cache the renderable-part probe: Combat revalidates locked targets
    -- every frame, and recursive FindFirstChildWhichIsA is not free on mobile.
    local part = renderPartCache[model]
    if not part or not part.Parent then
        part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            or model:FindFirstChildWhichIsA("BasePart", true)
        renderPartCache[model] = part
    end
    if not part then return nil end
    local vitals = numberVitals(model, player)
    if vitals then return model, vitals end
    return nil
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
    local empty = {Failed = true}
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
setup("视觉", BloxVisualFactory, "Visual")
setup("皮肤", BloxCosmeticFactory)
if type(ui.RegisterFeatureHealth) == "function" then
    ui:RegisterFeatureHealth("BloxStrike", function()
        local function status(key)
            local item = common[key]
            return item == nil and "missing" or (item.Failed and "failed" or "ready")
        end
        local visual = common.Visual
        local snapshot = visual and type(visual.Status) == "function" and visual:Status() or {}
        local combat = common.Combat and type(common.Combat.DebugSnapshot) == "function" and common.Combat:DebugSnapshot() or {}
        return ("存活=%s 战斗=%s 子弹=%s 视觉=%s 失败=%d 阵营=%d 目标=%d ESP=%d/%d/%.0f 倍镜=%s")
            :format(tostring(isCurrent()), status("Combat"), status("Bullet"), status("Visual"),
                #bootFailures, (function() local n=0; for _ in pairs(folderCache.map) do n = n + 1 end; return n end)(),
                tonumber(combat.candidates) or 0, tonumber(snapshot.markers) or 0,
                tonumber(snapshot.scanned) or 0, tonumber(snapshot.refreshes) or 0,
                tostring(snapshot.thirdPerson or false))
    end)
end

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

end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "BloxStrike")
end
