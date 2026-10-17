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
        ESPVisibility = false, -- avoid a raycast per target on mobile; optional diagnostics
        ESPWorldHighlight = false, -- 2D projected overlay is reliable through walls
        ESPOverlay = true,
        ESPBox = true,
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
    local ESP_GRACE_SECONDS = 1.4
    local MAX_ESP_TARGETS = 24
    -- 2D projected labels do not rely on 3D Highlight rendering, which can
    -- be culled even when HighlightDepthMode is AlwaysOnTop.
    local overlayGui
    local function ensureOverlay()
        if overlayGui and overlayGui.Parent then return overlayGui end
        local parent = (c.GetGuiParent and c.GetGuiParent()) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not parent then return nil end
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionBloxReadOnlyESP"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 24
        gui.Enabled = true
        gui.Parent = parent
        overlayGui = gui
        return gui
    end
    local function makeOverlay(entry)
        local gui = ensureOverlay()
        if not gui then return end
        local frame = Instance.new("Frame")
        frame.Name = "Target"
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Active = false
        frame.Visible = false
        frame.Parent = gui
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = Color3.fromRGB(255, 90, 90)
        stroke.Parent = frame
        local text = Instance.new("TextLabel")
        text.Name = "Info"
        text.BackgroundTransparency = 1
        text.BorderSizePixel = 0
        text.Active = false
        text.TextSize = 13
        text.TextStrokeTransparency = 0.4
        text.TextColor3 = stroke.Color
        text.Size = UDim2.fromOffset(174, 43)
        text.AnchorPoint = Vector2.new(0.5, 1)
        text.Position = UDim2.new(0.5, 0, 0, -3)
        text.Parent = frame
        entry.overlay, entry.overlayStroke, entry.overlayText = frame, stroke, text
    end
    local function projectOverlay(entry, camera, root, model, color, lines, distance)
        local frame = entry.overlay
        if not frame or not camera or not root then return end
        local point, onScreen = camera:WorldToViewportPoint(root.Position)
        if not onScreen or point.Z <= 0 then frame.Visible = false; return end
        local head = model:FindFirstChild("Head")
        local height
        if head and head:IsA("BasePart") then
            local hp = camera:WorldToViewportPoint(head.Position)
            height = math.abs(hp.Y - point.Y) * 3.0
        end
        if not height or height < 20 then height = 880 / math.max(distance, 4) end
        height = math.clamp(height, 25, 210)
        local width = math.clamp(height * 0.45, 16, 100)
        frame.Position = UDim2.fromOffset(math.floor(point.X - width / 2), math.floor(point.Y - height * 0.65))
        frame.Size = UDim2.fromOffset(width, height)
        frame.Visible = Config.ESPOverlay
        entry.overlayStroke.Color = color
        entry.overlayStroke.Enabled = Config.ESPBox
        entry.overlayText.TextColor3 = color
        local label = table.concat(lines, "\n")
        if entry.overlayText.Text ~= label then entry.overlayText.Text = label end
        entry.overlayText.Visible = #lines > 0
    end
    local espAccum = 0
    local visibilityParams = RaycastParams.new()
    visibilityParams.FilterType = Enum.RaycastFilterType.Blacklist
    visibilityParams.IgnoreWater = true

    local function clearEntry(player)
        local entry = highlights[player]
        if not entry then return end
        if entry.model then pcall(function() entry.model:Destroy() end) end
        if entry.overlay then pcall(function() entry.overlay:Destroy() end) end
        if entry.labelGui then pcall(function() entry.labelGui:Destroy() end) end
        if entry.box then pcall(function() entry.box:Remove() end) end
        if entry.tracer then pcall(function() entry.tracer:Remove() end) end
        if entry.nativeBox then entry.nativeBox:Destroy() end
        if entry.adorneeConn then pcall(function() entry.adorneeConn:Disconnect() end) end
        highlights[player] = nil
    end

    local function clearESP()
        for player in pairs(highlights) do clearEntry(player) end
        if overlayGui then pcall(function() overlayGui:Destroy() end); overlayGui = nil end
    end

    local function updateESP()
        if not Config.ESPEnabled then clearESP(); return end
        espStats.scanned, espStats.eligible, espStats.noHumanoid = 0, 0, 0
        local now = os.clock()
        local budget = MAX_ESP_TARGETS
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
                if valid and budget > 0 then
                    budget -= 1
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
                        highlight.Enabled = Config.ESPWorldHighlight
                        highlight.Parent = model
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
                        labelGui.Enabled = false -- 2D labels avoid occlusion/culling differences
                        labelGui.Parent = model
                        local entry = { model = highlight, labelGui = labelGui, label = label, adorneeConn = conn }
                        highlights[player] = entry
                        makeOverlay(entry)
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
                    entry.model.Enabled = Config.ESPWorldHighlight
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
                    entry.labelGui.Enabled = (not entry.overlay) and (#lines > 0)
                    if entry.overlay then
                        local dist = camera and root and (root.Position - camera.CFrame.Position).Magnitude or 0
                        projectOverlay(entry, camera, root, model, color, lines, dist)
                    end
                    if c.HasDrawing and Config.ESPTracer then -- bounded, opt-in 3D projection work
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
                    end
                else
                    local existing = highlights[player]
                    -- A roster swap or a brief camera/view-distance miss must
                    -- not destroy/recreate ESP several times per second.
                    if existing and existing.overlay then existing.overlay.Visible = false end
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
    local espInterval = 0.12
    local espRefreshes = 0
    local function visualInterval()
        if c.VisualInterval then
            local ok, value = pcall(c.VisualInterval, 0.12)
            if ok and type(value) == "number" and value == value and value > 0 then return math.max(0.12, value) end
        end
        return 0.12
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
    tab:AddToggle("BloxESPVisibility", { Title = "ESP 可见性配色（额外射线开销）", Default = false, Callback = function(v) Config.ESPVisibility = v end })
    tab:AddToggle("BloxESPBox", { Title = "ESP 穿墙屏幕投影框", Default = true, Callback = function(v) Config.ESPBox = v end })
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
        Content = "默认使用每秒最多 8 次的非交互式屏幕投影，墙后仍可显示框与标签；3D 高亮和可见性射线需手动开启。上限 24 目标；关闭后立即清理。" })

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
