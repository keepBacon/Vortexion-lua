-- Vortexion Neverlose - generated offline; publishing must be performed separately.
-- Neverlose attribution is retained in vendor/Neverlose/README.md.
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
        RageEnabled = false,
        RageMode = "Fast", -- Fast | Instant
        RageDelivery = "Auto", -- detect camera rewrites; fall back to mouse input
        RageAutoFire = true,
        RageFOV = 700,
        RageDistance = 900,
        RageMaxAngle = 85,
        RagePart = "Head",
        RageWallCheck = true,
        RageFireInterval = 0.14,
        RageLead = 0.09,
        RageSwitchDelay = 0.09,
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
        HitboxMode = "fullBody", -- lockedOnly | fullBody
        HitboxMaxActive = 8,
    }

    local Combat_PredictPoint

    local state = {
        locked = nil,
        rageTarget = nil,
        rageLastSwitch = 0,
        rageAttempts = 0,
        rageSent = 0,
        rageReason = "off",
        rageAimBackend = "none",
        rageExpectedLook = nil,
        rageCameraMisses = 0,
        rageCameraHits = 0,
        rageMouseMoves = 0,
        rageLastMouseError = 0,
        fireBackend = "none",
        fireOwner = nil,
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
        rosterSeen = 0,
        liveSeen = 0,
        enemySeen = 0,
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
        local filter = {}
        if character then filter[#filter + 1] = character end
        local actors = Workspace:FindFirstChild("Characters")
        if actors then filter[#filter + 1] = actors end
        rayParams.FilterDescendantsInstances = filter
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

        local searchDistance = Config.RageEnabled and math.max(Config.RageDistance, Config.MaxDistance) or Config.MaxDistance
        local searchFov = Config.RageEnabled and math.max(Config.RageFOV, Config.FOV) or Config.FOV
        state.rosterSeen, state.liveSeen, state.enemySeen = 0, 0, 0
        for _, player in ipairs(type(c.Targets) == "function" and c.Targets() or Players:GetPlayers()) do
            state.rosterSeen += 1
            if player ~= LocalPlayer then
                local model, humanoid = c.Living(player)
                if model and humanoid and humanoid.Health > 0 then
                    state.liveSeen += 1
                    if (not Config.TeamCheck) or c.Enemy(player, true) then
                        state.enemySeen += 1
                        local root = model:FindFirstChild("HumanoidRootPart")
                            or model:FindFirstChild("Torso")
                            or model:FindFirstChild("Head")
                            or model.PrimaryPart
                            or model:FindFirstChildWhichIsA("BasePart", true)
                        if root then
                            local head = model:FindFirstChild("Head")
                            if head and not head:IsA("BasePart") then head = nil end
                            local pos = (head or root).Position
                            local worldDist = (pos - camPos).Magnitude
                            if worldDist <= searchDistance then
                                local screen, onScreen = camera:WorldToViewportPoint(pos)
                                if screen.Z > 0 then
                                    local screenVec = Vector2.new(screen.X, screen.Y)
                                    local screenDist = onScreen and (screenVec - center).Magnitude or math.huge
                                    if screenDist <= searchFov then
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
                                            head = head,
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
            if not player.Parent or (player.IsVortexionNPC and
                (not player.Character or not player.Character.Parent)) then
                state.velEMA[player] = nil
            end
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
    local function entryValid(entry, rage)
        if not entry or not entry.player.Parent or not entry.model.Parent or not entry.root.Parent then return false end
        local model, humanoid = c.Living(entry.player)
        if model ~= entry.model or humanoid ~= entry.humanoid or humanoid.Health <= 0 then return false end
        if Config.TeamCheck and not c.Enemy(entry.player, true) then return false end
        local camera = Workspace.CurrentCamera
        if not camera then return false end
        local delta = entry.root.Position - camera.CFrame.Position
        local limitDistance = rage and Config.RageDistance or Config.MaxDistance
        if delta.Magnitude > limitDistance or delta.Magnitude < 0.01 then return false end
        local angle = math.deg(math.acos(math.clamp(camera.CFrame.LookVector:Dot(delta.Unit), -1, 1)))
        if angle > (rage and Config.RageMaxAngle or Config.MaxAngle) then return false end
        local screen, visible = camera:WorldToViewportPoint(entry.root.Position)
        if not visible or screen.Z <= 0 then return false end
        local center = camera.ViewportSize * 0.5
        entry.screen = Vector2.new(screen.X, screen.Y)
        entry.screenDist = (entry.screen - center).Magnitude
        entry.worldDist = delta.Magnitude
        if entry.screenDist > (rage and Config.RageFOV or Config.FOV) then return false end
        local blocked = rage and Config.RageWallCheck or (not rage and Config.WallCheck)
        return not blocked or not wallBlocked(camera.CFrame.Position, entry.root.Position, c.Character(), entry.model)
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
        state.fireOwner = nil
    end
    local function pressFire(now, owner)
        local camera = Workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local position = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
        if c.Caps.mouse1press and c.Caps.mouse1release then
            state.fireBackend = "mouse1press"
            releaseFire = mouse1release
            if not pcall(mouse1press) then finishFire(); return end
        elseif type(mouse1click) == "function" then
            -- Some mobile executors expose click but not a sustained press.
            state.fireBackend = "mouse1click"
            if not pcall(mouse1click) then return false end
            state.fireOwner = owner
            return true
        else
            -- BloxStrike uses InputBegan semantics for the weapon controller.
            -- VirtualUser may not reach them on Android; try VIM first.
            local vimOK, vim = pcall(function() return game:GetService("VirtualInputManager") end)
            local delivered = false
            if vimOK and vim then
                delivered = pcall(function()
                    vim:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 0)
                end)
                if delivered then
                    state.fireBackend = "VirtualInputManager"
                    releaseFire = function()
                        vim:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 0)
                    end
                end
            end
            if not delivered then
                local user = c.Services.VirtualUser
                if user and camera then
                    delivered = pcall(function() user:Button1Down(position, camera.CFrame) end)
                    if delivered then
                        state.fireBackend = "VirtualUser (unverified)"
                        releaseFire = function() user:Button1Up(position, camera.CFrame) end
                    end
                end
            end
            if not delivered then
                state.fireBackend = "unavailable: no supported mouse input"
                return false
            end
        end
        state.firing = true
        state.fireOwner = owner
        releaseAt = now + (owner == "rage" and 0.035 or math.max(Config.TriggerDelay, 0.02))
        return true
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
        c.Guard("Combat.Trigger", function() pressFire(now, "trigger") end)
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
        if entry.worldDist > math.min(Config.MaxDistance, 600) then return false end
        -- Full-body visual target envelopes are not limited to the central 120 pixels.
        -- The server retains authority over hit validation.
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
    -- R2.22 RageBot: independent selection + direct camera lock + gated fire.
    -- No arbitrary remote injection: only normal input paths are attempted.
    -- Real damage remains server-authoritative and must be checked in-game.
    --=========================================================================
    local function ragePart(entry)
        local model = entry.model
        if Config.RagePart == "Torso" then
            return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or entry.root
        elseif Config.RagePart == "Nearest" then
            return entry.head or entry.root
        end
        return entry.head or model:FindFirstChild("Head") or entry.root
    end

    local function selectRage(now)
        local previous = state.rageTarget
        if previous and entryValid(previous, true) and now - state.rageLastSwitch < Config.RageSwitchDelay then
            return previous
        end
        local best, scoreBest
        for _, entry in ipairs(state.candidates) do
            if entryValid(entry, true) then
                local score = entry.screenDist + entry.worldDist * 0.025
                if entry == previous then score -= 12 end -- stable lock, no target thrash
                if not scoreBest or score < scoreBest then
                    best, scoreBest = entry, score
                end
            end
        end
        if best ~= previous then state.rageLastSwitch = now end
        state.rageTarget = best
        return best
    end

    -- BloxStrike may rebuild CurrentCamera from its own input yaw/pitch every
    -- frame. Test whether last frame's camera write survived; if not, use the
    -- executor's *input* path rather than repeatedly fighting the controller.
    -- 0% inferred server hits: a successful camera write or mouse event is
    -- only a delivery event, not confirmation that a bullet was accepted.
    local function resolveRageMouse()
        if type(mousemoverel) == "function" then return mousemoverel end
        for _, fetch in ipairs({
            function() return getgenv and getgenv().mousemoverel end,
            function() return getfenv and getfenv().mousemoverel end,
        }) do
            local ok, fn = pcall(fetch)
            if ok and type(fn) == "function" then return fn end
        end
        return nil
    end
    local rageMoveMouse = resolveRageMouse()
    local function rageDeliverAim(dt, camera, targetPoint, targetCF)
        if state.rageExpectedLook then
            local observed = camera.CFrame.LookVector
            local dot = math.clamp(observed:Dot(state.rageExpectedLook), -1, 1)
            local drift = math.deg(math.acos(dot))
            if drift > 2.5 then
                state.rageCameraMisses = (state.rageCameraMisses or 0) + 1
                state.rageCameraHits = 0
            else
                state.rageCameraHits = (state.rageCameraHits or 0) + 1
                state.rageCameraMisses = math.max(0, (state.rageCameraMisses or 0) - 1)
            end
            state.rageExpectedLook = nil
        end
        local delivery = Config.RageDelivery or "Auto"
        local useMouse = delivery == "Mouse"
            or (delivery == "Auto" and (state.rageCameraMisses or 0) >= 4)
        if useMouse and not rageMoveMouse then
            state.rageAimBackend = "Mouse unavailable / Camera"
            if delivery == "Mouse" then
                return false, "mousemoverel unavailable"
            end
            useMouse = false
        end
        if useMouse then
            state.rageAimBackend = "Mouse"
            local point, visible = camera:WorldToViewportPoint(targetPoint)
            if not visible or point.Z <= 0 then return false, "aim off screen" end
            local centre = camera.ViewportSize * 0.5
            local dx = point.X - centre.X
            local dy = point.Y - centre.Y
            local errorPx = math.sqrt(dx * dx + dy * dy)
            state.rageLastMouseError = errorPx
            -- Game input sensitivity varies. Bound every packet and only fire
            -- when the next frame confirms that the target reached the crosshair.
            if errorPx > 2 then
                local speed = Config.RageMode == "Instant" and 0.85 or 0.46
                local mx = math.floor(math.clamp(dx * speed, -120, 120) + 0.5)
                local my = math.floor(math.clamp(dy * speed, -120, 120) + 0.5)
                if mx ~= 0 or my ~= 0 then
                    local ok = pcall(rageMoveMouse, mx, my)
                    if not ok then return false, "mousemoverel error" end
                    state.rageMouseMoves = (state.rageMouseMoves or 0) + 1
                end
                return false, "mouse tracking"
            end
            return true, "mouse converged"
        end
        state.rageAimBackend = "Camera"
        local alpha = Config.RageMode == "Instant" and 1 or math.clamp(dt * 25, 0.45, 0.95)
        camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
        state.rageExpectedLook = camera.CFrame.LookVector
        local direction = (targetPoint - camera.CFrame.Position).Unit
        local error = math.deg(math.acos(math.clamp(camera.CFrame.LookVector:Dot(direction), -1, 1)))
        if delivery == "Auto" and rageMoveMouse and (state.rageCameraHits or 0) < 2 then
            return false, "camera stability probe"
        end
        return error <= 3, "camera tracking"
    end

    local function rageTick(dt, now)
        if not Config.RageEnabled then
            state.rageTarget = nil
            state.rageReason = "off"
            state.rageAimBackend = "none"
            state.rageExpectedLook = nil
            state.rageCameraMisses = 0
            state.rageCameraHits = 0
            return
        end
        if not gateHeld() then
            state.rageReason = "hold gate"
            state.rageTarget = nil
            return
        end
        local camera = Workspace.CurrentCamera
        if not camera then state.rageReason = "camera missing"; return end
        local entry = selectRage(now)
        if not entry then state.rageReason = "no visible candidate"; return end
        local part = ragePart(entry)
        if not part then state.rageReason = "target part unavailable"; return end
        local ping = type(c.Ping) == "function" and c.Ping() or 0
        local lead = math.clamp(Config.RageLead + ping * 0.5, 0, 0.3)
        local velocity = state.velEMA[entry.player] or part.AssemblyLinearVelocity or Vector3.zero
        local targetPoint = part.Position + velocity * lead
        local delta = targetPoint - camera.CFrame.Position
        if delta.Magnitude < 0.1 then return end
        local targetCF = CFrame.lookAt(camera.CFrame.Position, targetPoint)
        local aligned, deliveryReason = rageDeliverAim(dt, camera, targetPoint, targetCF)
        if not Config.RageAutoFire then
            state.rageReason = "tracking / auto-fire off: " .. deliveryReason
            return
        end
        if not aligned then state.rageReason = deliveryReason; return end
        if state.firing then state.rageReason = "fire pulse active"; return end
        if now - state.fireAt < Config.RageFireInterval then
            state.rageReason = "fire cooldown"
            return
        end
        state.fireAt = now
        state.rageAttempts += 1
        local ok, sent = pcall(pressFire, now, "rage")
        if ok and sent then
            state.rageSent += 1
            state.rageReason = "input sent (hit unverified)"
        else
            state.rageReason = "fire unavailable: " .. tostring(state.fireBackend)
        end
    end

    --=========================================================================
    -- Public interface (consumed by Core and the Bullet module).
    --=========================================================================
    local Combat = {}

    function Combat:IsActive()
        return not stopped and (Config.Enabled or Config.RageEnabled or Config.TriggerEnabled or Config.HitboxEnabled or state.firing)
    end

    function Combat:Update(dt)
        if stopped then return end
        local t0 = tick()
        if state.firing and ((not Config.TriggerEnabled and not Config.RageEnabled) or not gateHeld() or t0 >= (releaseAt or 0)) then finishFire() end
        local active = Config.Enabled or Config.RageEnabled or Config.TriggerEnabled or Config.HitboxEnabled
        if not active then
            state.locked = nil
            state.candidates = {}
            hitboxTick(dt)
            fovTick()
            return
        end
        state.scanAccum += dt
        if state.scanAccum >= (Config.RageEnabled and 0.05 or 0.1) then
            state.scanAccum = 0
            scan()
        end
        state.lastLocked = state.locked
        if not lockStillValid() then
            selectTarget()
        end
        local entry = state.locked
        if Config.Enabled and not Config.RageEnabled and gateHeld() and entry and chanceFor(entry) then
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
        rageTick(dt, t0)
        if not Config.RageEnabled then triggerTick(t0) end
        hitboxTick(dt)
        fovTick()
        state.cost = tick() - t0
    end

    -- Lock accessor for the Bullet module and trigger integration.
    function Combat:GetLock()
        if not gateHeld() then return nil end
        if Config.RageEnabled then
            local entry = state.rageTarget
            if not entry or not entryValid(entry, true) then return nil end
            local part = ragePart(entry)
            if not part then return nil end
            local offset = (state.velEMA[entry.player] or Vector3.zero)
                * math.clamp(Config.RageLead + (type(c.Ping) == "function" and c.Ping() or 0) * 0.5, 0, 0.3)
            return {player=entry.player, part=part, point=part.Position + offset, entry=entry}
        end
        if not Config.Enabled or not lockStillValid() then return nil end
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

    local function originalSize(part)
        if not part then return nil end
        for _, record in pairs(state.hitEntries) do
            for _, item in ipairs(record.parts) do
                if item.part == part then return item.origSize end
            end
        end
        return part.Size
    end
    function Combat:GetEnvelope(part)
        -- Never enlarge the bullet target envelope just because local visual
        -- parts were expanded: the server still validates original collision.
        local size = originalSize(part)
        if not size then return Vector3.zero end
        return size * 0.5 + Vector3.new(0.5, 0.5, 0.5)
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
            rageLocked = state.rageTarget and state.rageTarget.player.Name or "-",
            rageEnabled = Config.RageEnabled, rageAttempts = state.rageAttempts,
            rageSent = state.rageSent, rageReason = state.rageReason,
            rageAimBackend = state.rageAimBackend,
            rageCameraMisses = state.rageCameraMisses,
            rageMouseMoves = state.rageMouseMoves,
            rageMouseError = state.rageLastMouseError,
            fireBackend = state.fireBackend,
            candidates = #state.candidates,
            rosterSeen = state.rosterSeen,
            liveSeen = state.liveSeen,
            enemySeen = state.enemySeen,
            hitEntries = (function() local n = 0; for _ in pairs(state.hitEntries) do n += 1 end; return n end)(),
            hitboxScope = Config.HitboxMode, hitboxEnabled = Config.HitboxEnabled,
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
        state.locked, state.lastLocked, state.rageTarget = nil, nil, nil
        state.rageExpectedLook = nil
        state.candidates, state.velEMA, state.rollCache, state.rollAt = {}, {}, {}, {}
        Config.Enabled = false
        Config.RageEnabled = false
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
    tab:AddParagraph({ Title = "RageBot · 游戏内输入驱动",
        Content = "独立目标扫描、快速镜头锁定、自动开火；Android 将按执行器能力尝试模拟射击。输入成功不等于服务器实际命中。" })
    tab:AddToggle("BloxRageEnabled", {Title="RageBot 总开关", Default=false, Callback=function(v)
        Config.RageEnabled = v
        if not v then
            state.rageTarget = nil
            state.rageReason = "off"
            state.rageExpectedLook = nil
            state.rageCameraMisses, state.rageCameraHits = 0, 0
            if state.fireOwner == "rage" then finishFire() end
        end
    end})
    tab:AddDropdown("BloxRageMode", {Title="Rage 锁定", Values={"Fast", "Instant"}, Default="Fast",
        Callback=function(v) Config.RageMode = v end})
    tab:AddDropdown("BloxRageDelivery", {Title="Rage 瞄准输入", Values={"Auto", "Mouse", "Camera"}, Default="Auto",
        Callback=function(v)
            Config.RageDelivery = v
            state.rageExpectedLook = nil
            state.rageCameraMisses, state.rageCameraHits = 0, 0
        end})
    tab:AddDropdown("BloxRagePart", {Title="Rage 部位", Values={"Head", "Torso", "Nearest"}, Default="Head",
        Callback=function(v) Config.RagePart = v end})
    tab:AddToggle("BloxRageAutoFire", {Title="Rage 自动射击", Default=true,
        Callback=function(v) Config.RageAutoFire = v; if not v and state.fireOwner=="rage" then finishFire() end end})
    tab:AddToggle("BloxRageWallCheck", {Title="Rage 遮挡检查", Default=true,
        Callback=function(v) Config.RageWallCheck = v end})
    tab:AddSlider("BloxRageFOV", {Title="Rage 屏幕半径", Min=100, Max=1300, Default=700, Rounding=0,
        Callback=function(v) Config.RageFOV=v end})
    tab:AddSlider("BloxRageDistance", {Title="Rage 距离", Min=100, Max=2000, Default=900, Rounding=0,
        Callback=function(v) Config.RageDistance=v end})
    tab:AddSlider("BloxRageMaxAngle", {Title="Rage 最大夹角", Min=15, Max=120, Default=85, Rounding=0,
        Callback=function(v) Config.RageMaxAngle=v end})
    tab:AddSlider("BloxRageFireInterval", {Title="Rage 开火间隔 (s)", Min=0.08, Max=0.5, Default=0.14, Rounding=2,
        Callback=function(v) Config.RageFireInterval=v end})
    tab:AddSlider("BloxRageLead", {Title="Rage 运动预测 (s)", Min=0, Max=0.25, Default=0.09, Rounding=2,
        Callback=function(v) Config.RageLead=v end})
    tab:AddButton({Title="RageBot 状态诊断", Callback=function()
        local d=Combat:DebugSnapshot()
        print(("[Vortexion/Rage] enabled=%s roster=%d alive=%d enemy=%d candidates=%d target=%s attempts=%d sent=%d aim=%s fire=%s reason=%s")
            :format(tostring(d.rageEnabled), d.rosterSeen, d.liveSeen, d.enemySeen,
                d.candidates, d.rageLocked, d.rageAttempts, d.rageSent,
                d.rageAimBackend, d.fireBackend, d.rageReason))
    end})
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
    tab:AddDropdown("BloxHitboxMode", { Title = "碰撞箱范围", Values = { "lockedOnly", "fullBody" }, Default = "fullBody",
        Callback = function(v) Config.HitboxMode = v end })
    tab:AddSlider("BloxHitboxSize", { Title = "碰撞箱倍率", Min = 1.1, Max = 3, Default = 1.6, Rounding = 1,
        Callback = function(v) Config.HitboxSize = v end })
    tab:AddParagraph({ Title = "碰撞箱说明",
        Content = "默认对视距内最多 8 个目标显示本地碰撞包络；服务器命中范围不会随 Size 扩大。子弹目标仍以原始部件大小约束，避免虚假命中。" })

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
        HitChance = 1,
        MaxAngle = 35,
        WallCheck = true,
        TeamCheck = true,
        Envelope = true,         -- clamp rewritten world points into orig size
        ProjectileTrack = true,
        ProjectileLerp = 0.35,
        ProjectileMax = 8,
        Debug = false,
        LinkCombat = true, -- LeadOnly needs aim prediction to be running
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
        weaponProbe = "not run",
        hitscanCalls = 0,
        hitscanRewrites = 0,
    }

    --==========================================================================
    -- R2.19: reversible game-specific weapon effect adapters.
    -- Based on observed BloxStrike class signatures, NOT a generic hook of
    -- every remote or every function. Enabled only after user toggles a mod.
    -- No server acceptance is presumed from local camera/spread changes.
    --==========================================================================
    local mods = {recoil=false, spread=false, patches={}, candidates=0,
        checked=0, status="not scanned", patchErrors=0, calls=0,
        nativeHooks=0, tablePatches=0, enabledAt=0, lastCallAt=0,
        retries=0, lastScan=0, workerRunning=false}
    -- R225: changing owner[key] alone does NOT affect functions captured by
    -- BloxStrike's controller at startup. Prefer a real executor hookfunction
    -- when supported. Record the original trampoline for explicit teardown.
    local function recordPatch(owner, key, replacement)
        if type(owner) ~= "table" or type(rawget(owner, key)) ~= "function" then return false end
        for _, item in ipairs(mods.patches) do
            if item.owner == owner and item.key == key then return true end
        end
        local target = rawget(owner, key)
        local hookOriginal
        local function forward(...)
            return (hookOriginal or target)(...)
        end
        local wrapper = replacement(forward)
        if c.Caps and c.Caps.hookfunction and type(hookfunction) == "function" then
            local ok, original = pcall(function()
                return hookfunction(target, wrapper)
            end)
            if ok and type(original) == "function" then
                hookOriginal = original
                mods.nativeHooks += 1
                mods.patches[#mods.patches + 1] = {
                    owner=owner, key=key, original=target, originalTrampoline=original,
                    wrapper=wrapper, native=true,
                }
                return true
            end
            mods.patchErrors += 1
        end
        -- Fallback for executors without hookfunction. Mark explicitly as a
        -- TABLE patch; it may be ineffective if the controller cached methods.
        local ok = pcall(function() owner[key] = wrapper end)
        if not ok then mods.patchErrors += 1; return false end
        mods.tablePatches += 1
        mods.patches[#mods.patches + 1] = {
            owner=owner, key=key, original=target, wrapper=wrapper, native=false,
        }
        return true
    end
    local function restoreWeaponMods()
        for i = #mods.patches, 1, -1 do
            local patch = mods.patches[i]
            if patch.native then
                -- Restoring only hooks we installed; never reset arbitrary
                -- unrelated functions or the global __namecall chain.
                if type(hookfunction) == "function" then
                    pcall(hookfunction, patch.original, patch.originalTrampoline)
                end
            else
                pcall(function()
                    if patch.owner[patch.key] == patch.wrapper then
                        patch.owner[patch.key] = patch.original
                    end
                end)
            end
            mods.patches[i] = nil
        end
        mods.nativeHooks, mods.tablePatches = 0, 0
    end
    local function findWeaponTables()
        local results, dedup = {}, {}
        local function add(item)
            if type(item) ~= "table" or dedup[item] then return end
            dedup[item] = true
            results[#results+1] = item
        end
        local function requireAt(start, ...)
            local path = start
            for _, name in ipairs({...}) do
                path = path and path:FindFirstChild(name)
            end
            if path and path:IsA("ModuleScript") then
                local ok, value = pcall(require, path)
                if ok then add(value) end
            end
        end
        requireAt(ReplicatedStorage, "Controllers", "CameraController")
        requireAt(ReplicatedStorage, "Components", "Weapon", "Classes", "Bullet")
        -- Current community sources use a second, structurally different path.
        -- Probe only known ModuleScripts; never require arbitrary descendants.
        requireAt(ReplicatedStorage, "Classes", "WeaponComponent", "Classes", "Bullet")
        requireAt(ReplicatedStorage, "Controllers", "InventoryController")
        local scanGC = type(getgc) == "function" and getgc
        if scanGC then
            local ok, items = pcall(scanGC, true)
            if ok and type(items) == "table" then
                local seen = 0
                for _, item in pairs(items) do
                    seen += 1
                    if seen > 12000 or #results >= 24 then break end
                    if type(item) == "table" then
                        if type(rawget(item,"weaponKick")) == "function"
                            or type(rawget(item,"getTrueSpread")) == "function"
                            or type(rawget(item,"getSpreadForConfig")) == "function"
                            or type(rawget(item,"shoot")) == "function" then
                            add(item)
                        end
                    end
                end
                mods.checked = seen
            end
        end
        mods.candidates = #results
        return results
    end
    local function installWeaponMods()
        if not (mods.recoil or mods.spread) then
            restoreWeaponMods()
            mods.status = "disabled"
            return
        end
        -- Install once; wrappers read current flags. This avoids churn and
        -- avoids leaking closures cached by the game's own controller.
        if #mods.patches > 0 then
            mods.status = "hooks=" .. tostring(mods.nativeHooks)
                .. " table=" .. tostring(mods.tablePatches)
                .. " calls=" .. tostring(mods.calls)
            return
        end
        local tables = findWeaponTables()
        local patched = 0
        for _, owner in ipairs(tables) do
            do
                for _, key in ipairs({"weaponKick", "setWeaponRecoil", "getWeaponKickRotation"}) do
                    local name = key
                    if recordPatch(owner, name, function(original)
                        return function(...)
                            if mods.recoil then
                                mods.calls += 1
                                mods.lastCallAt = os.clock()
                                if name == "getWeaponKickRotation" then return Vector3.zero end
                                return nil
                            end
                            return original(...)
                        end
                    end) then patched += 1 end
                end
            end
            do
                for _, key in ipairs({"getTrueSpread", "getSpreadForConfig", "getMovementSpreadForConfig",
                    "getBaseSpreadForConfig", "getBaseSpread"}) do
                    if recordPatch(owner, key, function(original)
                        return function(...)
                            local value = original(...)
                            if mods.spread then
                                if type(value) == "number" then
                                    mods.calls += 1
                                    mods.lastCallAt = os.clock()
                                    return 0
                                end
                                if typeof(value) == "Vector3" then
                                    mods.calls += 1
                                    mods.lastCallAt = os.clock()
                                    return Vector3.zero
                                end
                            end
                            return value
                        end
                    end) then patched += 1 end
                end
            end
        end
        mods.status = patched > 0
            and ("hooks=" .. tostring(mods.nativeHooks) .. " table=" .. tostring(mods.tablePatches)
                .. " observed calls=" .. tostring(mods.calls))
            or "unsupported: weapon methods not located"
    end
    local function setWeaponMod(kind, enabled)
        mods[kind] = enabled == true
        mods.enabledAt = os.clock()
        installWeaponMods()
        if not (mods.recoil or mods.spread) then return end
        -- Controller and gun modules often appear only after a match begins.
        -- Rescan at most eight times, bounded, without per-frame getgc calls.
        if mods.workerRunning or type(task) ~= "table" then return end
        if type(task.spawn) ~= "function" or type(task.wait) ~= "function" then return end
        mods.workerRunning = true
        task.spawn(function()
            for attempt = 1, 8 do
                task.wait(2.5)
                if not (mods.recoil or mods.spread) or not c.IsCurrent() then break end
                if #mods.patches == 0 then
                    mods.retries += 1
                    installWeaponMods()
                end
            end
            mods.workerRunning = false
        end)
    end
    c.OnCleanup(function()
        mods.recoil, mods.spread = false, false
        restoreWeaponMods()
    end)

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
        local combat = c.Combat
        local half = combat and type(combat.GetEnvelope) == "function"
            and combat:GetEnvelope(part) or (part.Size * 0.5 + Vector3.new(0.5, 0.5, 0.5))
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
        state.hitscanRewrites += 1
        c.Log("Bullet", "hitscan rewrite idx", direction.index)
        return packed
    end

    -- R225: the old module-only path no longer locates gun/bullet classes in
    -- modern BloxStrike. The game may instantiate them into GC tables before
    -- exposing a stable ReplicatedStorage.Components.Weapon class hierarchy.
    -- Only opt-in Hitscan/Auto (desktop) paths call this; no global hooks on boot.
    local function installHitscanHooks()
        if not c.Caps.hookfunction then return false end
        local function hookMethod(owner, key)
            if type(owner) ~= "table" then return false end
            local fn = rawget(owner, key)
            if type(fn) ~= "function" or state.weaponFunctions[fn] then return false end
            local original
            local ok = pcall(function()
                original = hookfunction(fn, function(...)
                    state.hitscanCalls += 1
                    local didRewrite, rewritten = pcall(rewriteHitscanArgs, ...)
                    if didRewrite and rewritten then
                        return original(table.unpack(rewritten, 1, rewritten.n))
                    end
                    return original(...)
                end)
            end)
            if ok and type(original) == "function" then
                state.weaponFunctions[fn] = original
                return true
            end
            state.errors += 1
            return false
        end
        local function hookClass(owner)
            if type(owner) ~= "table" then return 0 end
            -- 'shoot' / 'create' match current GunClass and Bullet signatures;
            -- do not blindly hook every function from game GC.
            local matched = 0
            for _, name in ipairs({"create", "shoot", "raycast", "cast", "trace"}) do
                if hookMethod(owner, name) then matched += 1 end
            end
            return matched
        end
        local hooked = 0
        local roots = {}
        local function addModule(start, ...)
            local node = start
            for _, key in ipairs({...}) do node = node and node:FindFirstChild(key) end
            if node and node:IsA("ModuleScript") then
                local ok, result = pcall(require, node)
                if ok and type(result) == "table" then roots[#roots + 1] = result end
            end
        end
        addModule(ReplicatedStorage, "Components", "Weapon", "Classes", "Bullet")
        addModule(ReplicatedStorage, "Controllers", "CameraController")
        if type(getgc) == "function" then
            local ok, items = pcall(getgc, true)
            if ok and type(items) == "table" then
                local examined = 0
                for _, item in pairs(items) do
                    examined += 1
                    if examined > 12000 or #roots >= 30 then break end
                    if type(item) == "table" then
                        local isGun = type(rawget(item, "shoot")) == "function"
                            and (type(rawget(item, "setupRecoil")) == "function"
                                 or type(rawget(item, "getSpread")) == "function")
                        local isBullet = type(rawget(item, "create")) == "function"
                            and (type(rawget(item, "getTrueSpread")) == "function"
                                 or type(rawget(item, "getSpreadForConfig")) == "function")
                        if isGun or isBullet then roots[#roots + 1] = item end
                    end
                end
            end
        end
        for _, owner in ipairs(roots) do
            hooked += hookClass(owner)
            if hooked >= 12 then break end
        end
        c.Log("Bullet", "game class hooks", hooked, "calls", state.hitscanCalls)
        return hooked > 0
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

    -- Recent public BloxStrike Luau sources identify runtime weapon classes
    -- by getgc tables (shoot/setupRecoil/getSpread), not solely by a fixed
    -- ReplicatedStorage.Components.Weapon path. Read-only and bounded: native
    -- hooking is intentionally never initiated by this diagnostic probe.
    local function probeRuntimeWeapon()
        local seen = 0
        local gun, bullet, camera = false, false, false
        if type(getgc) ~= "function" then
            state.weaponProbe = "getgc unavailable; only game hierarchy can be inspected"
            return state.weaponProbe
        end
        local ok, items = pcall(getgc, true)
        if not ok or type(items) ~= "table" then
            state.weaponProbe = "getgc unsupported or returned non-table"
            return state.weaponProbe
        end
        for _, item in pairs(items) do
            seen += 1
            if seen > 2500 then break end
            if type(item) == "table" then
                if rawget(item, "shoot") and rawget(item, "setupRecoil") then gun = true end
                if rawget(item, "getTrueSpread") and rawget(item, "getSpreadForConfig") then bullet = true end
                if rawget(item, "weaponKick") and rawget(item, "setWeaponRecoil") then camera = true end
            end
        end
        state.weaponProbe = ("runtime classes: gun=%s bullet=%s camera=%s scanned=%d")
            :format(tostring(gun), tostring(bullet), tostring(camera), seen)
        return state.weaponProbe
    end

    local function linkAimAssistant()
        if not Config.LinkCombat then return end
        local bridge = c.UI
        local option = bridge and bridge.Options and bridge.Options.BloxAimEnabled
        if option and option.Value ~= true and type(option.SetValue) == "function" then
            -- Native SetValue keeps the actual control and game state aligned.
            option:SetValue(true)
        end
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
        linkAimAssistant()
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
            probe = state.weaponProbe,
            needsAim = state.activePath == "LeadOnly" and not (c.Combat and c.Combat.IsActive and c.Combat:IsActive()),
            hitscanCalls = state.hitscanCalls,
            hitscanRewrites = state.hitscanRewrites,
            weaponMods = mods.status, weaponCalls = mods.calls,
            weaponNativeHooks = mods.nativeHooks, weaponTablePatches = mods.tablePatches,
            weaponObserved = mods.calls > 0,
            weaponLastCallAt = mods.lastCallAt,
            weaponEnabled = mods.recoil or mods.spread,
            weaponRetries = mods.retries,
            weaponCandidates = mods.candidates, weaponPatchErrors = mods.patchErrors,
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
    tab:AddParagraph({Title="BloxStrike 武器模块 R225", Content="按实战 controller/GC 类定位；优先 native hookfunction，失败才替换表方法。界面开关不等于武器方法被调用；可用下方诊断检查实时调用计数。"})
    tab:AddToggle("BloxWeaponNoRecoilR219", {Title="降低本地枪械后坐力", Default=false,
        Callback=function(v) setWeaponMod("recoil", v) end})
    tab:AddToggle("BloxWeaponNoSpreadR219", {Title="本地枪械散布控制", Default=false,
        Callback=function(v) setWeaponMod("spread", v) end})
    tab:AddButton({Title="检查武器修改器状态", Callback=function()
        local snapshot = Bullet:Status()
        print(("[Vortexion/WeaponMods] status=%s candidates=%d native=%d table=%d calls=%d retries=%d errors=%d")
            :format(snapshot.weaponMods, snapshot.weaponCandidates, snapshot.weaponNativeHooks,
                snapshot.weaponTablePatches, snapshot.weaponCalls, snapshot.weaponRetries, snapshot.weaponPatchErrors))
        if c.Notify then
            local detail = snapshot.weaponObserved and "调用已命中；服务器效果待实测"
                or (snapshot.weaponNativeHooks > 0 and "已 Hook 但尚无实际调用"
                or (snapshot.weaponTablePatches > 0 and "仅替换表方法，游戏可能已缓存函数"
                or "没有定位到武器方法；请在战斗中重试"))
            c.Notify("武器诊断", detail)
        end
    end})
    tab:AddParagraph({ Title = "子弹追踪",
        Content = "默认 LeadOnly 只提供瞄准预测，不会改写子弹；联动开启瞄准辅助后才有客户端可见效果。Hitscan/Remote 需有效游戏接口和执行器权限，未确认服务器命中。" })
    tab:AddToggle("BloxBulletLinkCombat", { Title = "子弹追踪联动开启瞄准辅助", Default = true,
        Callback = function(v) Config.LinkCombat = v end })
    tab:AddButton({ Title = "检查实际子弹 Hook 调用次数", Callback = function()
        local s = Bullet:Status()
        local info = ("路径=%s Hook=%d / 类方法调用=%d / 参数修改=%d / 错误=%d"):
            format(tostring(s.path),s.hooks,s.hitscanCalls,s.hitscanRewrites,s.errors)
        print("[Vortexion/Blox/Bullet] " .. info)
        if c.Notify then c.Notify("子弹 Hook 诊断",info) end
    end })
    tab:AddButton({ Title = "检查真实武器类（只读安全扫描）", Callback = function()
        local msg = probeRuntimeWeapon()
        print("[Vortexion/Blox/Weapon] " .. msg)
        if c.Notify then c.Notify("武器接口", msg) end
    end })
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
    tab:AddSlider("BloxBulletHitChance", { Title = "改写命中率（%）", Min = 10, Max = 100, Default = 100, Rounding = 0,
        Callback = function(v) Config.HitChance = v / 100 end })
    tab:AddSlider("BloxBulletMaxAngle", { Title = "改写最大角（度）", Min = 5, Max = 90, Default = 35, Rounding = 0,
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
            status.path, status.hooks, status.remotes, status.totalRemotes)
            .. " / " .. tostring(status.probe))
    end })

    return Bullet
end

end)()
local BloxVisualFactory = (function()
-- Vortexion BloxStrike visual: player ESP, fullbright, movement helpers.
--
-- R2.22: primary 2D ScreenGui projection plus optional native Billboard fallback.
-- One non-interactive entry per valid player, throttled update and cleanup.
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
        ESPVisibility = false, -- optional visibility tint: rays are OFF by default
        ESPWorldHighlight = false, -- optional 3D GPU highlight; native billboard is default
        ESPWeapon = true,
        ESPBox = true,
        ESPTracer = false,
        ESPOverlay = true, -- independent 2D ScreenGui projection; billboard fallback
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
    -- R2.19: native BillboardGui ESP. Roblox positions billboards in its
    -- renderer: no per-frame WorldToViewportPoint / GetBoundingBox / 3D
    -- Highlight allocations. One billboard per live replicated character.
    -- Only roster reconciliation and text are throttled in Lua.
    --=========================================================================
    local highlights = {}
    local overlayGui
    local overlayCreates = 0
    local overlayDraws = 0
    local function ensureOverlay()
        if overlayGui and overlayGui.Parent then return overlayGui end
        local parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not parent and type(c.GetGuiParent) == "function" then
            local ok, fallback = pcall(c.GetGuiParent)
            if ok then parent = fallback end
        end
        if not parent then return nil end
        local screen = Instance.new("ScreenGui")
        screen.Name = "VortexionBloxESP2D222"
        screen.ResetOnSpawn = false
        screen.IgnoreGuiInset = true -- WorldToViewportPoint is viewport-local.
        screen.DisplayOrder = 70
        screen.Enabled = Config.ESPEnabled and Config.ESPOverlay
        screen.Parent = parent
        overlayGui = screen
        return screen
    end
    local function makeOverlay(entry)
        if entry.overlay and entry.overlay.Parent then return end
        local screen = ensureOverlay()
        if not screen then return end
        local bounds = Instance.new("Frame")
        bounds.Name = "Target"
        bounds.BackgroundTransparency = 1
        bounds.BorderSizePixel = 0
        bounds.Active = false
        bounds.Visible = false
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(243, 93, 93)
        stroke.Thickness = 1.25
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = bounds
        local label = Instance.new("TextLabel")
        label.Name = "Info"
        label.AnchorPoint = Vector2.new(0.5, 1)
        label.Position = UDim2.new(0.5, 0, 0, -3)
        label.Size = UDim2.fromOffset(190, 65)
        label.BackgroundTransparency = 1
        label.TextColor3 = stroke.Color
        label.TextStrokeTransparency = 0.3
        label.TextSize = 13
        label.TextWrapped = false
        label.Active = false
        label.Text = ""
        label.Parent = bounds
        bounds.Parent = screen
        entry.overlay, entry.overlayStroke, entry.overlayText = bounds, stroke, label
        overlayCreates += 1
    end
    local function projectOverlay(entry, camera)
        if not Config.ESPOverlay then
            if entry.overlay then entry.overlay.Visible = false end
            entry.gui.Enabled = Config.ESPEnabled
            return
        end
        -- Keep the independent 2D path authoritative on Android; the existing
        -- BillboardGui survives as a fallback when viewport projection fails.
        if not camera or not camera.WorldToViewportPoint then return end
        makeOverlay(entry)
        if not entry.overlay then return end
        local root = entry.root
        if not root or not root.Parent then
            entry.overlay.Visible = false
            return
        end
        local upper = entry.model:FindFirstChild("Head")
        local top = upper and upper:IsA("BasePart") and (upper.Position + Vector3.new(0, 0.65, 0))
            or (root.Position + Vector3.new(0, 2.7, 0))
        local bottom = root.Position - Vector3.new(0, 2.8, 0)
        local a = camera:WorldToViewportPoint(top)
        local b = camera:WorldToViewportPoint(bottom)
        local middle, inView = camera:WorldToViewportPoint(root.Position)
        -- On mobile a nearby character's head can project above the screen
        -- even while the torso is visible. Testing the head's inView here
        -- removed valid targets. Cull by depth and the actual box instead.
        if a.Z <= 0 or b.Z <= 0 or middle.Z <= 0 then
            entry.overlay.Visible = false
            entry.gui.Enabled = false
            return
        end
        local rawTop, rawBottom = math.min(a.Y, b.Y), math.max(a.Y, b.Y)
        local vw, vh = camera.ViewportSize.X, camera.ViewportSize.Y
        local rawHeight = math.max(rawBottom - rawTop, 18)
        local rawWidth = math.clamp(rawHeight * 0.52, 14, vw * 0.3)
        local rawLeft = (a.X + b.X - rawWidth) * 0.5
        if not inView and (rawBottom < 0 or rawTop > vh or rawLeft > vw or rawLeft + rawWidth < 0) then
            entry.overlay.Visible = false
            entry.gui.Enabled = false
            return
        end
        local topY = math.clamp(rawTop, 0, vh)
        local bottomY = math.clamp(rawBottom, 0, vh)
        local height = math.max(1, bottomY - topY)
        local width = rawWidth
        entry.overlay.Position = UDim2.fromOffset(math.floor(rawLeft), math.floor(topY))
        entry.overlay.Size = UDim2.fromOffset(math.floor(width), math.floor(height))
        entry.overlay.Visible = true
        entry.gui.Enabled = false
        entry.overlayStroke.Enabled = Config.ESPBox
        entry.overlayText.Text = entry.text.Text
        entry.overlayText.Visible = entry.text.Visible
        entry.overlayStroke.Color = entry.stroke.Color
        entry.overlayText.TextColor3 = entry.stroke.Color
        overlayDraws += 1
    end
    local function hideOverlay(entry)
        if entry and entry.overlay then entry.overlay.Visible = false end
    end
    local espStats = {refreshes=0, scanned=0, eligible=0, markers=0,
        noHumanoid=0, creates=0, writes=0, lastError="none"}
    local MAX_ESP_TARGETS = 24
    local ESP_GRACE_SECONDS = 1.25
    -- Distances are hysteretic: existing labels survive small camera offsets.
    local ESP_DISTANCE_SLACK = 35
    local espAccum = 0
    local visibilityParams = RaycastParams.new()
    visibilityParams.FilterType = Enum.RaycastFilterType.Exclude
    visibilityParams.IgnoreWater = true
    local function renderRoot(model)
        local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("LowerTorso")
            or model:FindFirstChild("Torso") or model:FindFirstChild("Head") or model.PrimaryPart
        if part and part:IsA("BasePart") then return part end
        return model:FindFirstChildWhichIsA("BasePart", true)
    end
    local function clearEntry(player)
        local entry = highlights[player]
        if not entry then return end
        highlights[player] = nil
        if entry.overlay then pcall(function() entry.overlay:Destroy() end) end
        if entry.gui then pcall(function() entry.gui:Destroy() end) end
        if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
        if entry.tracer then pcall(function() entry.tracer:Remove() end) end
    end
    local function clearESP()
        for player in pairs(highlights) do clearEntry(player) end
        espStats.markers = 0
        if overlayGui then
            pcall(function() overlayGui:Destroy() end)
            overlayGui = nil
        end
    end
    local function makeEntry(player, model, root)
        local parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not parent and type(c.GetGuiParent) == "function" then
            local ok, fallback = pcall(c.GetGuiParent)
            if ok then parent = fallback end
        end
        if not parent then return nil end
        local gui = Instance.new("BillboardGui")
        gui.Name = "VortexionBloxESP219"
        gui.Adornee = root
        gui.AlwaysOnTop = true
        gui.LightInfluence = 0
        gui.Size = UDim2.new(4, 0, 6, 0)
        gui.StudsOffsetWorldSpace = Vector3.new(0, 1.15, 0)
        gui.MaxDistance = Config.ESPDistance + ESP_DISTANCE_SLACK
        gui.Active = false
        gui.Enabled = Config.ESPEnabled
        local box = Instance.new("Frame")
        box.Name = "Bounds"
        box.Size = UDim2.fromScale(1, 1)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Active = false
        box.Parent = gui
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.25
        stroke.Color = Color3.fromRGB(243, 93, 93)
        stroke.Parent = box
        local text = Instance.new("TextLabel")
        text.Name = "Info"
        text.AnchorPoint = Vector2.new(0.5, 1)
        text.Position = UDim2.new(0.5, 0, 0, -4)
        text.Size = UDim2.fromOffset(190, 54)
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 0.3
        text.TextColor3 = stroke.Color
        text.TextSize = 13
        text.TextWrapped = false
        text.Active = false
        text.Text = ""
        text.Parent = box
        local healthBack = Instance.new("Frame")
        healthBack.Name = "HealthBackground"
        healthBack.AnchorPoint = Vector2.new(1, 0)
        healthBack.Position = UDim2.fromScale(0, 0)
        healthBack.Size = UDim2.new(0, 3, 1, 0)
        healthBack.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
        healthBack.BorderSizePixel = 0
        healthBack.Visible = false
        healthBack.Active = false
        healthBack.Parent = box
        local healthFill = Instance.new("Frame")
        healthFill.Name = "HealthFill"
        healthFill.AnchorPoint = Vector2.new(0, 1)
        healthFill.Position = UDim2.fromScale(0, 1)
        healthFill.Size = UDim2.fromScale(1, 1)
        healthFill.BackgroundColor3 = Color3.fromRGB(92, 222, 132)
        healthFill.BorderSizePixel = 0
        healthFill.Active = false
        healthFill.Parent = healthBack
        gui.Parent = parent
        espStats.creates += 1
        return {gui=gui, box=box, stroke=stroke, text=text, healthBack=healthBack,
            healthFill=healthFill, model=model, root=root, lastSeen=os.clock(), nextInfo=0}
    end
    local function modelWeapon(model)
        local weapon = model:GetAttribute("Weapon") or model:GetAttribute("CurrentWeapon")
            or model:GetAttribute("EquippedWeapon")
        if type(weapon) == "string" and #weapon > 0 then return weapon end
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("Tool") then return child.Name end
        end
        return nil
    end
    local function updateInfo(entry, player, model, vitals, distance)
        local now = os.clock()
        if now < entry.nextInfo then return end
        entry.nextInfo = now + 0.3
        local info = {}
        if Config.ESPNames then info[#info+1] = tostring(player.DisplayName or player.Name) end
        local health, maximum
        if vitals then
            local h = vitals.Health
            local mx = vitals.MaxHealth
            if type(h) == "number" and type(mx) == "number" and mx > 0
                and (type(vitals) ~= "table" or vitals.HealthKnown ~= false) then
                health, maximum = math.max(0, h), mx
            end
        end
        if Config.ESPHealth and health then info[#info+1] = ("HP %d/%d"):format(math.floor(health), math.floor(maximum)) end
        if Config.ESPRange then info[#info+1] = ("%d studs"):format(math.floor(distance)) end
        if Config.ESPWeapon then
            local weapon = modelWeapon(model)
            if weapon then info[#info+1] = "W " .. weapon:sub(1, 26) end
        end
        local newText = table.concat(info, "\n")
        if entry.text.Text ~= newText then
            entry.text.Text = newText
            espStats.writes += 1
        end
        if entry.text.Visible ~= (#info > 0) then entry.text.Visible = #info > 0 end
        local visible = health ~= nil and Config.ESPHealth
        if entry.healthBack.Visible ~= visible then entry.healthBack.Visible = visible end
        if visible then
            local fraction = math.clamp(health / maximum, 0, 1)
            if fraction ~= entry.lastHealth then
                entry.healthFill.Size = UDim2.fromScale(1, fraction)
                entry.lastHealth = fraction
            end
        end
    end
    local function updateESP()
        if not Config.ESPEnabled then clearESP(); return end
        espStats.scanned, espStats.eligible, espStats.noHumanoid = 0, 0, 0
        local camera = Workspace.CurrentCamera
        local parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not parent and type(c.GetGuiParent) == "function" then
            local ok, fallback = pcall(c.GetGuiParent)
            if ok then parent = fallback end
        end
        if not camera or not parent then
            espStats.lastError = "camera or GUI parent unavailable"
            return
        end
        local now = os.clock()
        local left = MAX_ESP_TARGETS
        local origin = camera.CFrame.Position
        for _, player in ipairs(type(c.Targets) == "function" and c.Targets() or Players:GetPlayers()) do
            if player ~= LocalPlayer then
                espStats.scanned += 1
                local model, vitals = c.Living(player)
                if model and vitals and not model:FindFirstChildOfClass("Humanoid") then
                    espStats.noHumanoid += 1
                end
                local permitted = (not Config.ESPTeam) or c.Enemy(player, true)
                local root = model and renderRoot(model)
                local dist = root and (root.Position - origin).Magnitude or math.huge
                local valid = model and vitals and vitals.Health > 0 and root and permitted
                    and dist <= Config.ESPDistance + (highlights[player] and ESP_DISTANCE_SLACK or 0) and left > 0
                local entry = highlights[player]
                if valid then
                    left -= 1
                    espStats.eligible += 1
                    if entry and (entry.model ~= model or entry.root ~= root or not entry.gui.Parent) then
                        clearEntry(player)
                        entry = nil
                    end
                    if not entry then
                        entry = makeEntry(player, model, root)
                        if entry then highlights[player] = entry end
                    end
                    if entry then
                        entry.lastSeen = now
                        if not entry.gui.Enabled then entry.gui.Enabled = true end
                        local maxDistance = Config.ESPDistance + ESP_DISTANCE_SLACK
                        if entry.gui.MaxDistance ~= maxDistance then
                            entry.gui.MaxDistance = maxDistance
                        end
                        if entry.stroke.Enabled ~= Config.ESPBox then
                            entry.stroke.Enabled = Config.ESPBox
                        end
                        updateInfo(entry, player, model, vitals, dist)
                        if Config.ESPVisibility then
                            local ignore = c.Character(LocalPlayer)
                            visibilityParams.FilterDescendantsInstances = ignore and {ignore} or {}
                            local hit = Workspace:Raycast(origin, root.Position - origin, visibilityParams)
                            local unobstructed = not hit or (hit.Instance and hit.Instance:IsDescendantOf(model))
                            local color = unobstructed and Color3.fromRGB(86, 231, 144)
                                or Color3.fromRGB(243, 93, 93)
                            if entry.stroke.Color ~= color then
                                entry.stroke.Color = color
                                entry.text.TextColor3 = color
                            end
                        elseif entry.visibilityTinted then
                            local color = Color3.fromRGB(243, 93, 93)
                            entry.stroke.Color = color
                            entry.text.TextColor3 = color
                        end
                        entry.visibilityTinted = Config.ESPVisibility
                        -- The native Billboard alone is not reliable for all
                        -- custom rigs/mobile renderers; mirror into 2D.
                        local projected, projectionError = pcall(projectOverlay, entry, camera)
                        if not projected then
                            espStats.lastError = "2D projection: " .. tostring(projectionError):sub(1, 150)
                            hideOverlay(entry)
                            entry.gui.Enabled = Config.ESPEnabled
                        end
                        if Config.ESPWorldHighlight then
                            if not entry.highlight then
                                local h = Instance.new("Highlight")
                                h.Adornee = model
                                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                h.FillTransparency = 0.85
                                h.OutlineTransparency = 0.15
                                h.Parent = model
                                entry.highlight = h
                            end
                        elseif entry.highlight then
                            entry.highlight:Destroy()
                            entry.highlight = nil
                        end
                        if Config.ESPTracer and c.HasDrawing then
                            if not entry.tracer then
                                entry.tracer = Drawing.new("Line")
                                entry.tracer.Thickness = 1
                            end
                            local point, onScreen = camera:WorldToViewportPoint(root.Position)
                            entry.tracer.Visible = onScreen and point.Z > 0
                            if entry.tracer.Visible then
                                entry.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                                entry.tracer.To = Vector2.new(point.X, point.Y)
                                entry.tracer.Color = entry.stroke.Color
                            end
                        elseif entry.tracer then
                            entry.tracer:Remove()
                            entry.tracer = nil
                        end
                    end
                elseif entry then
                    -- Preserve the instance for brief replication and roster swaps;
                    -- never leave a ghost marker visible during that grace period.
                    -- Hide immediately only if the target really disappeared or is no
                    -- longer an allowed team; transient distance/replication misses
                    -- remain visible until the grace window expires.
                    if (not model or not root or not permitted or now - entry.lastSeen >= ESP_GRACE_SECONDS)
                        and entry.gui.Enabled then entry.gui.Enabled = false end
                    hideOverlay(entry)
                    if entry.tracer then entry.tracer.Visible = false end
                    if now - entry.lastSeen >= ESP_GRACE_SECONDS or not entry.model.Parent then
                        clearEntry(player)
                    end
                end
            end
        end
        for player in pairs(highlights) do
            if not player.Parent or (player.IsVortexionNPC and
                (not player.Character or not player.Character.Parent)) then
                clearEntry(player)
            end
        end
        local count = 0
        for _ in pairs(highlights) do count += 1 end
        espStats.markers = count
    end
    local function startESP()
        espAccum = 0
        c.Guard("Visual.ESP", updateESP)
        -- Show a diagnostic when a requested ESP cannot find any enemy. This
        -- prevents a silent no-op on an unsupported map/round.
        if espStats.scanned > 0 and espStats.eligible == 0 and c.Notify then
            c.Notify("BloxStrike ESP", "未找到有效敌方目标；请检查阵营、对局状态与距离。")
        end
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

    -- Third-person ownership: one post-camera render pass, not periodic
    -- CameraMode/CameraType writes fighting the game's first-person controller.
    local thirdPerson = {enabled = false, distance = 12, saved = nil,
        overrides = 0, lastApplied = nil, lastBase = nil, bound = false}
    local cameraBindName = "VortexionBloxThirdPerson_" .. tostring(LocalPlayer.UserId)
    local function restoreThirdPerson()
        if thirdPerson.bound then
            RunService:UnbindFromRenderStep(cameraBindName)
            thirdPerson.bound = false
        end
        local saved = thirdPerson.saved
        thirdPerson.saved = nil
        local cam = Workspace.CurrentCamera
        if cam and thirdPerson.lastBase and thirdPerson.lastApplied
            and cam.CFrame == thirdPerson.lastApplied then
            pcall(function() cam.CFrame = thirdPerson.lastBase end)
        end
        thirdPerson.lastApplied, thirdPerson.lastBase = nil, nil
        if not saved then return end
        pcall(function()
            LocalPlayer.CameraMaxZoomDistance = math.max(saved.maxZoom, saved.minZoom)
            LocalPlayer.CameraMinZoomDistance = saved.minZoom
            LocalPlayer.CameraMaxZoomDistance = saved.maxZoom
            LocalPlayer.CameraMode = saved.mode
        end)
    end
    local function updateThirdPerson()
        if not thirdPerson.enabled then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local observed = cam.CFrame
        -- If the native camera didn't update, never apply the offset twice.
        local base = observed
        if thirdPerson.lastApplied and observed == thirdPerson.lastApplied then
            base = thirdPerson.lastBase or observed
        end
        local d = math.clamp(thirdPerson.distance, 5, 24)
        local origin = base.Position
        local goal = origin - base.LookVector * d + Vector3.new(0, 1.3, 0)
        local filter = c.Character(LocalPlayer)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = filter and {filter} or {}
        params.IgnoreWater = true
        local hit = Workspace:Raycast(origin, goal-origin, params)
        if hit then goal = origin + (hit.Position-origin)*0.85 end
        local placed = CFrame.lookAt(goal, goal + base.LookVector)
        thirdPerson.lastBase, thirdPerson.lastApplied = base, placed
        cam.CFrame = placed
        thirdPerson.overrides += 1
    end
    local function setThirdPerson(enabled)
        enabled = enabled == true
        if not enabled then
            thirdPerson.enabled = false
            restoreThirdPerson()
            return
        end
        if not thirdPerson.saved then
            thirdPerson.saved = {
                mode = LocalPlayer.CameraMode,
                minZoom = LocalPlayer.CameraMinZoomDistance,
                maxZoom = LocalPlayer.CameraMaxZoomDistance,
            }
            -- One-time setup. The per-frame pass only changes the final CFrame.
            pcall(function() LocalPlayer.CameraMode = Enum.CameraMode.Classic end)
            pcall(function()
                LocalPlayer.CameraMaxZoomDistance = math.max(thirdPerson.distance, LocalPlayer.CameraMaxZoomDistance)
                LocalPlayer.CameraMinZoomDistance = math.min(thirdPerson.distance, LocalPlayer.CameraMaxZoomDistance)
            end)
        end
        thirdPerson.enabled = true
        if not thirdPerson.bound then
            RunService:BindToRenderStep(cameraBindName, Enum.RenderPriority.Last.Value + 5, function()
                if c.IsCurrent() then c.Guard("Visual.ThirdPerson", updateThirdPerson) end
            end)
            thirdPerson.bound = true
        end
    end
    c.OnCleanup(function() thirdPerson.enabled = false; restoreThirdPerson() end)
    local cameraChanged = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        thirdPerson.lastApplied, thirdPerson.lastBase = nil, nil
    end)
    c.OnCleanup(function() cameraChanged:Disconnect() end)

    local moveAccum = 0
    local espInterval = 0.25
    local espRefreshes = 0
    local function visualInterval()
        local base = Config.ESPOverlay and 0.08 or 0.25
        if c.VisualInterval then
            local ok, value = pcall(c.VisualInterval, base)
            if ok and type(value) == "number" and value == value and value > 0 then return math.max(base, value) end
        end
        return base
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
    local function cameraESPRebind()
        -- Native billboards track world parts independently of CurrentCamera.
        -- Never destroy/recreate every marker on a game camera replacement.
        espAccum = espInterval
    end
    local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraESPRebind)
    local frameConnection = RunService.Heartbeat:Connect(function(dt)
        if not c.IsCurrent() then return end
        -- Before enabling any feature, skip ALL camera, raycast, or movement
        -- calculations. The Heartbeat connection stays lightweight for toggles.
        if not Config.ESPEnabled and not Config.SpeedEnabled and not Config.FlyEnabled and not Config.Noclip and not thirdPerson.enabled then
            espAccum, moveAccum = 0, 0
            return
        end
        -- Third-person camera is bound at Camera+10, not polled on Heartbeat.
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
            creates = espStats.creates, writes = espStats.writes,
            renderer = Config.ESPOverlay and "Viewport2D+BillboardFallback" or "NativeBillboard",
            overlayCreates = overlayCreates, overlayDraws = overlayDraws,
            overlayParent = overlayGui ~= nil and overlayGui.Parent ~= nil,
            thirdPerson = thirdPerson.enabled, thirdOverrides = thirdPerson.overrides,
        }
    end
    function Config.ESPRefreshCount() return espRefreshes end
    function Config.ESPInterval() return espInterval end

    --=========================================================================
    -- UI.
    --=========================================================================
    local tab = c.Tabs.Visual
    tab:AddToggle("BloxESP", { Title = "原生穿墙 ESP（低负载）", Default = false, Callback = function(v)
        Config.ESPEnabled = v
        if v then startESP() else clearESP() end
    end })
    tab:AddToggle("BloxESP2D", { Title = "2D 屏幕 ESP（手机推荐）", Default = true,
        Callback = function(v)
            Config.ESPOverlay = v
            if overlayGui then overlayGui.Enabled = v and Config.ESPEnabled end
            if v then c.Guard("Visual.ESP2D", updateESP)
            else for _, entry in pairs(highlights) do hideOverlay(entry); entry.gui.Enabled = Config.ESPEnabled end end
        end })
    tab:AddToggle("BloxESPWorldHighlight", { Title = "额外启用 3D 高亮（性能消耗较高）", Default = false,
        Callback = function(v) Config.ESPWorldHighlight = v end })
    tab:AddToggle("BloxESPTeam", { Title = "仅显示敌方", Default = true, Callback = function(v)
        Config.ESPTeam = v
        c.Guard("Visual.ESP", updateESP)
    end })
    tab:AddSlider("BloxESPDistance", { Title = "ESP 距离", Min = 100, Max = 2000, Default = 500, Rounding = 0,
        Callback = function(v) Config.ESPDistance = v end })
    tab:AddToggle("BloxESPNames", { Title = "ESP 名称", Default = true, Callback = function(v) Config.ESPNames = v end })
    tab:AddToggle("BloxESPHealth", { Title = "ESP 血量", Default = true, Callback = function(v) Config.ESPHealth = v end })
    tab:AddToggle("BloxESPRange", { Title = "ESP 距离标签", Default = true, Callback = function(v) Config.ESPRange = v end })
    tab:AddToggle("BloxESPWeapon", { Title = "ESP 显示当前武器", Default = true, Callback = function(v) Config.ESPWeapon = v end })
    tab:AddToggle("BloxESPVisibility", { Title = "ESP 可见性配色（额外射线开销）", Default = false, Callback = function(v) Config.ESPVisibility = v end })
    tab:AddToggle("BloxESPBox", { Title = "ESP 穿墙原生方框", Default = true, Callback = function(v) Config.ESPBox = v end })
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
        print(("[Vortexion/BloxESP] 渲染=%s 2D创建=%d 2D绘制=%d 2D容器=%s")
            :format(status.renderer, status.overlayCreates, status.overlayDraws, tostring(status.overlayParent)))
        if c.Notify then
            c.Notify("ESP 诊断", ("扫描 %d / 合格 %d / 标记 %d / 绘制 %d / %s"):
                format(status.scanned, status.eligible, status.markers, status.overlayDraws, tostring(status.error)))
        end
    end})
    tab:AddParagraph({ Title = "视觉刷新节流",
        Content = "默认将目标投影到不拦截触控的 2D ScreenGui（独立于 3D Highlight 的可见性）；保留可切换的 BillboardGui 作为兼容兜底。2D 投影约 12Hz、目标文字约 3Hz，最多 24 个，关闭立即清理。" })

    local movement = c.Tabs.Movement
    movement:AddToggle("BloxThirdPerson", {Title = "第三人称视角", Default = false,
        Callback = setThirdPerson})
    movement:AddSlider("BloxThirdDistance", {Title = "第三人称镜头距离", Min = 5, Max = 24,
        Default = 12, Rounding = 0, Callback = function(value)
            thirdPerson.distance = value
            if thirdPerson.enabled then thirdPerson.lastApplied = nil end
        end})
    movement:AddParagraph({Title="第三人称说明", Content="启用后每帧于相机和战斗更新之后只偏移最终镜头，不再周期抢写 CameraMode；关闭后解绑并恢复。游戏强制镜头仍可能影响实际观感。"})
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
local folderCache = { at = 0, map = {}, roster = {}, npcs = 0 }
local npcByModel = setmetatable({}, {__mode="k"})
local function rebuildFolderMap()
    local map = {}
    local roster = Players:GetPlayers()
    local root = Workspace:FindFirstChild("Characters")
    local count = 0
    if root then
        local function visit(model, folder)
            if not model:IsA("Model") then return end
            map[model.Name] = folder
            local owner = Players:FindFirstChild(model.Name)
            if owner and not owner:IsA("Player") then owner = nil end
            if not owner then
                local ok, player = pcall(function() return Players:GetPlayerFromCharacter(model) end)
                if ok then owner = player end
            end
            if not owner then
                local id = model:GetAttribute("UserId") or model:GetAttribute("PlayerUserId")
                if type(id) == "number" and id > 0 then
                    local ok, player = pcall(function() return Players:GetPlayerByUserId(id) end)
                    if ok then owner = player end
                end
            end
            if owner then return end
            -- The latest BloxStrike rounds may add bots as bare Models under
            -- Workspace.Characters; Players:GetPlayers() omits these actors.
            local proxy = npcByModel[model]
            if not proxy then
                proxy = {IsVortexionNPC=true, Name=model.Name, DisplayName=model.Name, Character=model}
                function proxy:GetAttribute(key) return self.Character:GetAttribute(key) end
                npcByModel[model] = proxy
            end
            proxy.Parent = model.Parent
            proxy.TeamFolder = folder
            proxy.Name, proxy.DisplayName = model.Name, model.Name
            roster[#roster + 1] = proxy
            count = count + 1
        end
        for _, container in ipairs(root:GetChildren()) do
            if container:IsA("Model") then
                visit(container, root)
            elseif container:IsA("Folder") then
                for _, model in ipairs(container:GetChildren()) do
                    visit(model, container)
                end
            end
        end
    end
    folderCache.map, folderCache.roster, folderCache.npcs = map, roster, count
    folderCache.at = tick()
end
local function ensureRoster()
    if tick()-folderCache.at > 0.25 then rebuildFolderMap() end
end
local function targets()
    ensureRoster()
    return folderCache.roster
end
local function teamFolder(player)
    if not player then return nil end
    ensureRoster()
    if player.IsVortexionNPC then return player.TeamFolder end
    return folderCache.map[player.Name]
end
local function characterOf(player)
    if not player then return LocalPlayer and LocalPlayer.Character end
    if player.IsVortexionNPC then return player.Character end
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
    -- BloxStrike's health state is sometimes on the owning Player instead.
    if health == nil and player and type(player.GetAttribute) == "function" then
        health = player:GetAttribute("Health")
    end
    if maximum == nil and player and type(player.GetAttribute) == "function" then
        maximum = player:GetAttribute("MaxHealth")
    end
    if type(health) == "string" then health = tonumber(health) end
    if type(maximum) == "string" then maximum = tonumber(maximum) end
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
    if not model or not model.Parent or not model:IsA("Model") then return nil end
    if tostring(model:GetAttribute("Dead")) == "true" then return nil end
    if player and type(player.GetAttribute) == "function"
        and tostring(player:GetAttribute("Dead")) == "true" then return nil end
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

-- R225: Characters is a character *container*, NOT a team. In modern
-- BloxStrike, all players/bots sit directly under this folder. Its common
-- parent made teamFolder(LocalPlayer)==teamFolder(enemy), silently filtering
-- every target from ESP, RageBot and aim. Resolve game attributes first.
local function teamOf(player)
    if not player then return nil end
    local model = characterOf(player)
    local function attribute(obj, key)
        if not obj or type(obj.GetAttribute) ~= "function" then return nil end
        local ok, value = pcall(function() return obj:GetAttribute(key) end)
        return ok and value or nil
    end
    local direct = attribute(player, "Team") or attribute(model, "Team")
    if direct ~= nil and tostring(direct) ~= "" then return tostring(direct) end
    local look = attribute(model, "CharacterName")
    if look ~= nil then
        if look == Workspace:GetAttribute("CTCharacter") then return "Counter-Terrorists" end
        if look == Workspace:GetAttribute("TCharacter") then return "Terrorists" end
    end
    local team = player.Team
    if team then return tostring(team.Name or team) end
    local folder = teamFolder(player)
    local characters = Workspace:FindFirstChild("Characters")
    -- A genuine CT/T grouping folder can act as a last-resort team hint.
    if folder and folder ~= characters and folder.Name then return tostring(folder.Name) end
    return nil
end
local function isEnemy(player, checkTeam)
    if player == LocalPlayer then return false end
    if checkTeam == false then return true end
    local mode = tostring(Workspace:GetAttribute("Gamemode") or "")
    if mode:find("Deathmatch", 1, true) then return true end
    local mine, theirs = teamOf(LocalPlayer), teamOf(player)
    if mine ~= nil and theirs ~= nil then return mine ~= theirs end
    -- Unknown is not 'same team'. The caller may offer a manual override.
    return true
end
local function playerFromModel(model)
    if not model then return nil end
    local byName=Players:FindFirstChild(model.Name)
    if byName and byName:IsA("Player") then return byName end
    local player = Players:GetPlayerFromCharacter(model)
    return player or npcByModel[model]
end

local ctx={
    Players=Players,RunService=RunService,Workspace=Workspace,
    ReplicatedStorage=ReplicatedStorage,Lighting=Lighting,Input=UserInputService,
    LocalPlayer=LocalPlayer,UI=ui,Window=window,Tabs=tabs,
    Notify=notify,IsCurrent=isCurrent,Own=ownConnection,OnCleanup=ownCleanup,
    Character=characterOf,Living=livingCharacter,TeamFolder=teamFolder,
    Enemy=isEnemy,TeamOf=teamOf,PlayerFromModel=playerFromModel,Targets=targets,
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
        return ("存活=%s 战斗=%s 子弹=%s 视觉=%s 失败=%d NPC=%d 目标=%d ESP=%d/%d/%.0f 倍镜=%s")
            :format(tostring(isCurrent()), status("Combat"), status("Bullet"), status("Visual"),
                #bootFailures, (function() ensureRoster(); return folderCache.npcs end)(),
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
    ensureRoster()
    local sample, enemies = {}, 0
    for _, person in ipairs(folderCache.roster) do
        if person ~= LocalPlayer then
            if isEnemy(person, true) then enemies = enemies + 1 end
            if #sample < 3 then
                sample[#sample + 1] = tostring(person.Name) .. "=" .. tostring(teamOf(person))
            end
        end
    end
    notify("运行环境检查",(characters and "角色目录正常" or "角色目录未加载")
        .." / "..(skins and "皮肤目录正常" or "皮肤目录未加载")
        .." / "..(weapon and "武器组件正常" or "武器组件未加载")
        .." / "..(bullet and "Bullet 模块存在" or "Bullet 模块未找到")
        .." / 队伍=" .. tostring(teamOf(LocalPlayer))
        .." / 角色=" .. tostring(#folderCache.roster) .." 敌人="..tostring(enemies)
        .." / 样本="..table.concat(sample, ",")
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
