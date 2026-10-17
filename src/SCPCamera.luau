-- Vortexion SCP aimbot: three modalities behind one target selector.
--
--   Camera  - CFrame:Lerp toward the target (alpha = 1 - smoothness, floored
--             at 0.02 so the smoothest setting still tracks).
--   Mouse   - mousemoverel with BASE_PULL * attraction * dampening; the camera
--             never moves, so nothing camera-side observes the snap.
--   Both    - camera for coarse motion, mouse for sub-FOV micro-correction.
--
-- Human-likeness gates (adapted from the Vanity-General-Roblox study):
--   MaxAngle   - only track when the target is already within a cone around
--                the look vector (default 30 degrees); no 180-degree flicks.
--   HitChance  - per-acquisition random roll; a failed roll idles the frame.
--   Prediction - velocity extrapolation with a low-pass on the smoothed
--                velocity so the aim point never jitters frame to frame.
--
-- Target persistence: once acquired, a lock survives while the target stays
-- alive, inside MaxDistance*1.2 and within FOV*1.5 on screen. The original
-- script re-selected every frame and never re-locked after a loss mid-hold.
return function(common)
	local Players = common.Services.Players
	local Workspace = common.Services.Workspace
	local UserInputService = common.Services.UserInputService
	local LocalPlayer = common.LocalPlayer
	local Cloak = common.Cloak

	local Camera = {}
	local Config = {
		Enabled = false,
		Mode = "Camera",          -- Camera | Mouse | Both
		FOV = 120,
		MaxDistance = 300,
		WallCheck = true,
		TeamCheck = false,       -- SCP roleplay has no factions by default
		Smoothness = 0.85,        -- alpha = 1 - smoothness (0.15 -> gradual)
		Hitbox = "Head",          -- Head | Torso | Arms | Legs | Random
		Prediction = 0.12,        -- seconds of velocity extrapolation
		MaxAngle = 30,            -- degrees cone around look vector
		HitChance = 0.9,          -- per-acquisition roll
		FOVCircle = true,
		TriggerKey = common.Touch.Enabled and "Touch" or "Right",     -- None | Left | Right | Touch | Always
		Attraction = 0.6,         -- mouse-mode pull multiplier
		Dampening = true,         -- ease off inside the dampening threshold
		TargetNPCs = true,
		TouchMode = "Hold",
	}
	Camera.Config = Config

	local cam = Workspace.CurrentCamera
	local lockedChar = nil
	local lockedPlayer = nil
	local lockedRegion = nil
	local smoothedVelocity = Vector3.zero
	local hitRoll = 1
	local lastMouseMode = nil
	local lastCrosshair = Vector2.zero
	local aimHighlight = nil

	--=========================================================================
	-- FOV ring: a GUI Frame + UICorner + UIStroke. The original used
	-- Drawing.new("Circle"), which silently no-ops on executors exposing
	-- Drawing as userdata; a ring renders everywhere.
	--=========================================================================
	local fovGui, fovRing
	local disposed = false

	local function ensureFovRing()
		if disposed then return nil end
		if fovRing and fovGui and fovGui.Parent and fovRing.Parent == fovGui then return fovRing end
		if fovGui then fovGui:Destroy() end
		fovGui = Instance.new("ScreenGui")
		fovGui.Name = common.RandomName()
		fovGui.ResetOnSpawn = false
		fovGui.IgnoreGuiInset = true
		fovGui.DisplayOrder = 998
		local ok = pcall(function() fovGui.Parent = common.GetGuiParent() end)
		if disposed then return nil end
		if not ok or not fovGui.Parent then
			-- Missing PlayerGui is retried by the next visual tick, never awaited.
			local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
			if not playerGui then
				fovGui:Destroy(); fovGui, fovRing = nil, nil
				return nil
			end
			fovGui.Parent = playerGui
		end
		if Cloak then Cloak.Protect(fovGui) end
		if disposed then return nil end

		fovRing = Instance.new("Frame")
		fovRing.Name = "Ring"
		fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
		fovRing.Position = UDim2.fromScale(0.5, 0.5)
		fovRing.BackgroundTransparency = 1
		fovRing.BorderSizePixel = 0
		fovRing.Parent = fovGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = fovRing

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Transparency = 0.2
		stroke.Color = Color3.fromRGB(255, 60, 60)
		stroke.Parent = fovRing
		return fovRing
	end

	local function updateFovCircle()
		if not Config.FOVCircle or not Config.Enabled or not cam then
			if fovRing then fovRing.Visible = false end
			return
		end
		local ring = ensureFovRing()
		if not ring then return end
		local diameter = math.max(0, Config.FOV) * 2
		ring.Size = UDim2.fromOffset(diameter, diameter)
		ring.Visible = Config.Enabled
	end

	--=========================================================================
	-- Reuse one highlight marker across lock transitions.
	--=========================================================================
	local function ensureHighlight()
		if aimHighlight then return aimHighlight end
		aimHighlight = Instance.new("Highlight")
		aimHighlight.Name = common.RandomName()
		aimHighlight.FillColor = Color3.fromRGB(255, 0, 0)
		aimHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		aimHighlight.FillTransparency = 0.55
		aimHighlight.OutlineTransparency = 0
		aimHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		if Cloak then Cloak.Protect(aimHighlight) end
		return aimHighlight
	end

	local function clearHighlight()
		if aimHighlight then
			aimHighlight.Adornee = nil
			aimHighlight.Parent = nil
		end
	end

	--=========================================================================
	-- Target selection from the shared per-frame pool.
	--=========================================================================
	local function isVisible(position, character)
		local origin = cam.CFrame.Position
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
		local result = Workspace:Raycast(origin, position - origin, params)
		return not result or result.Instance:IsDescendantOf(character)
	end

	local function screenDistance(cand)
		local projected, visible = cam:WorldToViewportPoint(cand.Anchor.Position)
		if not visible or projected.Z <= 0 then return math.huge end
		local screen = Vector2.new(projected.X, projected.Y)
		local center = cam.ViewportSize / 2
		return (screen - center).Magnitude
	end

	local function candidateEligible(cand, fovFactor, distanceFactor)
		if not (cand.Character.Parent and cand.Humanoid.Health > 0 and cand.Anchor.Parent) then return nil end
		if cand.Player and cand.Player.Character ~= cand.Character then return nil end
		if Config.TeamCheck and cand.Player and cand.Player.Team ~= nil
			and cand.Player.Team == LocalPlayer.Team then
			return nil
		end
		if not Config.TargetNPCs and not cand.Player then return nil end
		local distance = screenDistance(cand)
		if distance >= Config.FOV * (fovFactor or 1) then return nil end
		if cand.WorldDistance > Config.MaxDistance * (distanceFactor or 1) then return nil end
		if Config.WallCheck and not isVisible(cand.Anchor.Position, cand.Character) then return nil end
		return distance
	end

	function Camera:FindBestTarget()
		local best, bestDistance = nil, math.huge
		for _, cand in ipairs(common.Candidates:Get()) do
			local distance = candidateEligible(cand)
			if distance and distance < bestDistance then
				bestDistance = distance
				best = cand
			end
		end
		return best
	end

	--=========================================================================
	-- Lock persistence. Returns the candidate to aim at this frame, reusing
	-- the previous lock while it stays valid.
	--=========================================================================
	function Camera:ResolveTarget()
		if lockedChar and lockedChar.Parent then
			for _, cand in ipairs(common.Candidates:Get()) do
				if cand.Character == lockedChar then
					if candidateEligible(cand, 1.5, 1.2) then
						return cand
					end
					break
				end
			end
		end
		lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
		smoothedVelocity = Vector3.zero
		hitRoll = math.random()
		local best = Camera:FindBestTarget()
		if best then lockedChar, lockedPlayer = best.Character, best.Player end
		return best
	end

	local lastRegionMode = nil
	local function resolveRegion(character)
		if lastRegionMode ~= Config.Hitbox then lockedRegion = nil lastRegionMode = Config.Hitbox end
		if Config.Hitbox ~= "Random" and common.Candidates.REGION_PARTS[Config.Hitbox] then return Config.Hitbox end
		if not lockedRegion then
			local available = {}
			for _, region in ipairs(common.Candidates.REGION_ORDER) do
				if common.Candidates.pickPartFromRegion(character, region) then table.insert(available, region) end
			end
			lockedRegion = #available > 0 and available[math.random(#available)] or "Head"
		end
		return lockedRegion
	end

	--=========================================================================
	-- Human-likeness gates.
	--=========================================================================
	local function withinCone(aimPosition)
		local toTarget = aimPosition - cam.CFrame.Position
		if toTarget.Magnitude < 0.1 then return false end
		toTarget = toTarget.Unit
		return cam.CFrame.LookVector:Dot(toTarget) >= math.cos(math.rad(Config.MaxAngle))
	end

	local touchLatch, lastPress, lastEpoch, lastKey = false, common.Touch.Presses or 0, common.Touch.FocusEpoch or 0, Config.TriggerKey
	function Camera:ResetTrigger()
		touchLatch = false
		lastPress, lastEpoch, lastKey = common.Touch.Presses or 0, common.Touch.FocusEpoch or 0, Config.TriggerKey
	end
	local function triggerHeld()
		if UserInputService.GetFocusedTextBox and UserInputService:GetFocusedTextBox() then Camera:ResetTrigger() return false end
		if lastKey ~= Config.TriggerKey or lastEpoch ~= (common.Touch.FocusEpoch or 0) then Camera:ResetTrigger() end
		if Config.TriggerKey == "Always" then return true end
		if Config.TriggerKey == "None" then return false end
		if Config.TriggerKey == "Touch" then
			local press = common.Touch.Presses or 0
			if Config.TouchMode == "Toggle" and (press - lastPress) % 2 == 1 then touchLatch = not touchLatch end
			lastPress = press
			return common.Touch.Enabled and (Config.TouchMode == "Toggle" and touchLatch or Config.TouchMode ~= "Toggle" and common.Touch.Held)
		end
		local button = Config.TriggerKey == "Left" and Enum.UserInputType.MouseButton1 or Enum.UserInputType.MouseButton2
		return UserInputService:IsMouseButtonPressed(button)
	end

	--=========================================================================
	-- Camera modality.
	--=========================================================================
	local function pointCamera(aimPosition, dt)
		local desired = CFrame.lookAt(cam.CFrame.Position, aimPosition)
		local alpha = math.clamp(1 - Config.Smoothness, 0.02, 1)
		alpha = 1 - (1 - alpha) ^ (math.clamp(dt or 1 / 60, 0, 0.25) * 60)
		cam.CFrame = cam.CFrame:Lerp(desired, alpha)
	end

	--=========================================================================
	-- Mouse modality: relative mouse deltas with
	-- dampening near the target and NaN/clamp guards. The camera is untouched.
	--=========================================================================
	local function pointMouse(aimPosition, screenPos)
		local viewport = cam.ViewportSize
		local mouseLocation = UserInputService:GetMouseLocation()
		if not UserInputService.TouchEnabled then
			local dx, dy = screenPos.X - mouseLocation.X, screenPos.Y - mouseLocation.Y
			local mag = math.sqrt(dx * dx + dy * dy)
			if mag < 1 or mag > Config.FOV then return end

			local attraction = Config.Attraction
			if Config.Dampening then
				local threshold = math.max(12, Config.FOV * 0.25)
				if mag < threshold then
					local dampening = math.max(0.25, mag / threshold)
					attraction *= dampening
				end
			end

			local deltaX = dx * 0.2 * attraction
			local deltaY = dy * 0.2 * attraction
			if deltaX ~= deltaX or deltaY ~= deltaY then return end -- NaN guard
			deltaX = math.clamp(deltaX, -viewport.X * 0.5, viewport.X * 0.5)
			deltaY = math.clamp(deltaY, -viewport.Y * 0.5, viewport.Y * 0.5)
			mousemoverel(math.floor(deltaX + 0.5), math.floor(deltaY + 0.5))
		end
	end

	--=========================================================================
	-- Update.
	--=========================================================================
	function Camera:Update(dt)
		if disposed then return nil end
		Camera.CurrentTarget = nil
		clearHighlight()
		cam = Workspace.CurrentCamera
		updateFovCircle()

		if not Config.Enabled or not cam then
			Camera:ResetTrigger()
			clearHighlight()
			lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
			return nil
		end

		if not triggerHeld() then
			clearHighlight()
			lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
			smoothedVelocity = Vector3.zero
			hitRoll = 1
			return nil
		end

		local cand = Camera:ResolveTarget()
		if not cand then
			clearHighlight()
			return nil
		end

		local region = resolveRegion(cand.Character)
		local aimPart = common.Candidates.pickPartFromRegion(cand.Character, region)
			or common.Candidates.pickAnyPart(cand.Character)
		if not aimPart or not aimPart:IsDescendantOf(Workspace) then
			return nil
		end

		-- Low-pass the velocity so prediction never jitters.
		smoothedVelocity = smoothedVelocity:Lerp(aimPart.AssemblyLinearVelocity, 1 - 0.7 ^ (math.clamp(dt or 1 / 60, 0, 0.25) * 60))
		local aimPosition = aimPart.Position + smoothedVelocity * Config.Prediction

		-- Gates: cone + per-acquisition roll.
		if (Config.WallCheck and not isVisible(aimPart.Position, cand.Character)) or not withinCone(aimPosition) or hitRoll > Config.HitChance then
			return cand
		end

		local projected = cam:WorldToViewportPoint(aimPosition)
		local aimMode = Config.Mode
		if aimMode ~= "Camera" and (not common.Caps.mousemoverel or UserInputService.TouchEnabled) then
			aimMode = "Camera" -- executor lacks mousemoverel: degrade to camera aim
		end
		if aimMode == "Camera" then
			pointCamera(aimPosition, dt)
		elseif aimMode == "Mouse" then
			pointMouse(aimPosition, Vector2.new(projected.X, projected.Y))
		else -- Both: camera for coarse error, mouse for micro
			local center = cam.ViewportSize / 2
			local screen = Vector2.new(projected.X, projected.Y)
			local mag = (screen - center).Magnitude
			if mag > Config.FOV * 0.25 then
				pointCamera(aimPosition, dt)
			else
				pointMouse(aimPosition, screen)
			end
		end

		lockedPlayer = cand.Player
		Camera.CurrentTarget = cand

		local highlight = ensureHighlight()
		if highlight then
			highlight.Adornee = cand.Character
			highlight.Parent = common.GetGuiParent() or cand.Character
		end

		common.Log("Camera", ("lock=%s region=%s dist=%d"):format(
			cand.Player and cand.Player.Name or "NPC", region, math.floor(cand.WorldDistance)))
		return cand
	end

	function Camera:GetCurrentTarget()
		return Camera.CurrentTarget
	end

	function Camera:Cleanup()
		if disposed then return end
		disposed = true
		pcall(clearHighlight)
		if aimHighlight then pcall(function() aimHighlight:Destroy() end) end
		aimHighlight = nil
		if fovGui then pcall(function() fovGui:Destroy() end) end
		fovGui, fovRing = nil, nil
		lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
		Camera.CurrentTarget = nil
	end

	common.OnCleanup(function() Camera:Cleanup() end)
	return Camera
end
