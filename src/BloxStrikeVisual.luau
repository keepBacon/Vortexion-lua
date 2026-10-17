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
        ESPWorldHighlight = false, -- optional 3D GPU highlight; used as fallback if 2D is unavailable
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
    -- Declare the diagnostics table BEFORE any rendering closures capture it.
    -- R232 defined this table after projectOverlay(), making espStats global/nil
    -- inside the fallback branch on real Luau runtimes.
    local espStats = {refreshes=0, scanned=0, eligible=0, markers=0,
        noHumanoid=0, noModel=0, noRoot=0, teamFiltered=0,
        rangeFiltered=0, guiFailed=0, rendered2D=0, fallback3D=0,
        creates=0, writes=0, lastError="none"}
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
        if not entry.overlay then
            -- Without a writable ScreenGui parent, never hide the billboard.
            entry.gui.Enabled = Config.ESPEnabled
            espStats.lastError = "2D overlay unavailable; fallback to billboard"
            return
        end
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
            entry.gui.Enabled = Config.ESPEnabled
            return false
        end
        local rawTop, rawBottom = math.min(a.Y, b.Y), math.max(a.Y, b.Y)
        local vw, vh = camera.ViewportSize.X, camera.ViewportSize.Y
        local rawHeight = math.max(rawBottom - rawTop, 18)
        local rawWidth = math.clamp(rawHeight * 0.52, 14, vw * 0.3)
        local rawLeft = (a.X + b.X - rawWidth) * 0.5
        if not inView and (rawBottom < 0 or rawTop > vh or rawLeft > vw or rawLeft + rawWidth < 0) then
            entry.overlay.Visible = false
            entry.gui.Enabled = Config.ESPEnabled
            return false
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
        espStats.rendered2D += 1
        return true
    end
    local function hideOverlay(entry)
        if entry and entry.overlay then entry.overlay.Visible = false end
    end
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
        espStats.noModel, espStats.noRoot, espStats.teamFiltered = 0, 0, 0
        espStats.rangeFiltered, espStats.guiFailed = 0, 0
        espStats.rendered2D, espStats.fallback3D = 0, 0
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
        local rosterOK, roster = pcall(function()
            return type(c.Targets) == "function" and c.Targets() or Players:GetPlayers()
        end)
        if not rosterOK or type(roster) ~= "table" then
            espStats.lastError = "target roster failure: " .. tostring(roster):sub(1, 160)
            roster = Players:GetPlayers()
        end
        for _, player in ipairs(roster) do
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
                if not model then espStats.noModel += 1
                elseif not root then espStats.noRoot += 1
                elseif not permitted then espStats.teamFiltered += 1
                elseif dist > Config.ESPDistance then espStats.rangeFiltered += 1 end
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
                        if entry then highlights[player] = entry
                        else espStats.guiFailed += 1 end
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
                        local projectionOK, projectionResult = pcall(projectOverlay, entry, camera)
                        if not projectionOK then
                            espStats.lastError = "2D projection: " .. tostring(projectionResult):sub(1, 150)
                            hideOverlay(entry)
                            entry.gui.Enabled = Config.ESPEnabled
                        end
                        -- When screen projection is unavailable, do not turn off
                        -- every renderer. Billboard stays on; use native Highlight
                        -- as a secondary visible fallback (no Drawing API needed).
                        local needsFallback = not Config.ESPOverlay
                            or not projectionOK or projectionResult ~= true
                        local wantHighlight = Config.ESPWorldHighlight or needsFallback
                        if wantHighlight then
                            if not entry.highlight then
                                local okHighlight, h = pcall(function()
                                    local item = Instance.new("Highlight")
                                    item.Adornee = model
                                    item.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    item.FillTransparency = 0.92
                                    item.OutlineTransparency = 0.05
                                    item.Parent = model
                                    return item
                                end)
                                if okHighlight then entry.highlight = h
                                else espStats.lastError = "Highlight: " .. tostring(h):sub(1, 150) end
                            end
                            if entry.highlight then
                                entry.highlight.Enabled = true
                                espStats.fallback3D += 1
                            end
                        elseif entry.highlight then
                            entry.highlight.Enabled = false
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
            noHumanoid = espStats.noHumanoid, noModel = espStats.noModel,
            noRoot = espStats.noRoot, teamFiltered = espStats.teamFiltered,
            rangeFiltered = espStats.rangeFiltered, guiFailed = espStats.guiFailed,
            rendered2D = espStats.rendered2D, fallback3D = espStats.fallback3D,
            error = espStats.lastError,
            creates = espStats.creates, writes = espStats.writes,
            renderer = Config.ESPOverlay and "Viewport2D+BillboardFallback" or "NativeBillboard",
            overlayCreates = overlayCreates, overlayDraws = overlayDraws,
            overlayParent = overlayGui ~= nil and overlayGui.Parent ~= nil,
            guiMode = Config.ESPEnabled and (Config.ESPOverlay and "2D" or "Billboard") or "Off",
            thirdPerson = thirdPerson.enabled, thirdOverrides = thirdPerson.overrides,
        }
    end
    -- Read-only evidence for Android executors: tells us whether the blocker is
    -- roster discovery, health/team metadata, viewport, or GUI rendering.
    function Config:DiagnosticText()
        local state = self:Status()
        local lines = {
            "[Vortexion R233 / BloxStrike ESP diagnostic]",
            "GameId=" .. tostring(game.GameId) .. " PlaceId=" .. tostring(game.PlaceId),
            "Enabled=" .. tostring(self.ESPEnabled) .. " TeamOnly=" .. tostring(self.ESPTeam)
                .. " 2D=" .. tostring(self.ESPOverlay) .. " Range=" .. tostring(self.ESPDistance),
            ("scanned=%d eligible=%d markers=%d 2dVisible=%d nativeFallback=%d"):format(
                state.scanned, state.eligible, state.markers, state.rendered2D, state.fallback3D),
            ("noModel=%d noRoot=%d teamFiltered=%d rangeFiltered=%d guiFailed=%d"):format(
                state.noModel, state.noRoot, state.teamFiltered, state.rangeFiltered, state.guiFailed),
            "Camera=" .. tostring(Workspace.CurrentCamera ~= nil) .. " ScreenGui="
                .. tostring(state.overlayParent) .. " lastError=" .. tostring(state.error),
        }
        local ok, roster = pcall(function() return type(c.Targets) == "function" and c.Targets() or Players:GetPlayers() end)
        if not ok or type(roster) ~= "table" then
            lines[#lines + 1] = "roster failed: " .. tostring(roster)
        else
            lines[#lines + 1] = "rosterCount=" .. tostring(#roster)
            for i, actor in ipairs(roster) do
                if i > 6 then break end
                local okActor, info = pcall(function()
                    local model, vitals = c.Living(actor)
                    local root = model and renderRoot(model)
                    local team = type(c.TeamOf) == "function" and c.TeamOf(actor) or nil
                    local hostile = type(c.Enemy) == "function" and c.Enemy(actor, true) or nil
                    return tostring(actor.Name or "?") .. " model=" .. tostring(model and model.Name or "nil")
                        .. " part=" .. tostring(root and root.Name or "nil") .. " team=" .. tostring(team)
                        .. " enemy=" .. tostring(hostile) .. " hp=" .. tostring(vitals and vitals.Health or "nil")
                end)
                lines[#lines + 1] = okActor and info or ("actorError=" .. tostring(info))
            end
        end
        return table.concat(lines, "\n")
    end
    local sharedEnv = (getgenv and getgenv()) or _G
    local diagnose = function() return Config:DiagnosticText() end
    sharedEnv.VortexionBloxESPDiagnostics = diagnose
    c.OnCleanup(function()
        if sharedEnv.VortexionBloxESPDiagnostics == diagnose then
            sharedEnv.VortexionBloxESPDiagnostics = nil
        end
    end)
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
        print(("[Vortexion/BloxESP] 无模型=%d 无根部件=%d 阵营过滤=%d 距离过滤=%d GUI失败=%d 可见2D=%d 3D回退=%d")
            :format(status.noModel, status.noRoot, status.teamFiltered, status.rangeFiltered,
                status.guiFailed, status.rendered2D, status.fallback3D))
        if c.Notify then
            c.Notify("ESP 诊断", ("扫描 %d / 合格 %d / 标记 %d / 绘制 %d / %s"):
                format(status.scanned, status.eligible, status.markers, status.overlayDraws, tostring(status.error)))
        end
    end})
    tab:AddButton({Title = "复制完整 ESP 运行诊断", Callback = function()
        local report = Config:DiagnosticText()
        print(report)
        if type(setclipboard) == "function" then
            local ok = pcall(setclipboard, report)
            if c.Notify then c.Notify("ESP 诊断", ok and "已复制到剪贴板" or "复制失败，见执行器日志") end
        elseif c.Notify then
            c.Notify("ESP 诊断", "执行器不支持剪贴板，请复制控制台的 Vortexion 诊断")
        end
    end})
    tab:AddButton({Title = "ESP 画面自检（独立于敌人识别）", Callback = function()
        local screen = ensureOverlay()
        if not screen then
            espStats.lastError = "ESP 自检无法挂载 ScreenGui: PlayerGui unavailable"
            if c.Notify then c.Notify("ESP 自检", espStats.lastError) end
            return
        end
        local testFrame = Instance.new("Frame")
        testFrame.Name = "VortexionESPProbe"
        testFrame.Position = UDim2.fromOffset(54, 90)
        testFrame.Size = UDim2.fromOffset(110, 160)
        testFrame.BackgroundTransparency = 0.85
        testFrame.BackgroundColor3 = Color3.fromRGB(63, 215, 173)
        testFrame.BorderSizePixel = 2
        testFrame.BorderColor3 = Color3.fromRGB(63, 215, 173)
        testFrame.Active = false
        testFrame.ZIndex = 150
        testFrame.Parent = screen
        screen.Enabled = true
        if c.Notify then c.Notify("ESP 自检", "左上角应出现 110x160 青色测试框，持续 3 秒") end
        task.delay(3, function()
            pcall(function() testFrame:Destroy() end)
            if overlayGui == screen then screen.Enabled = Config.ESPEnabled and Config.ESPOverlay end
        end)
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
