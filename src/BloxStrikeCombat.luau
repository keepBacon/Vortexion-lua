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
