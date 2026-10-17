-- Vortexion SCP movement: speed, fly, noclip, teleport, jump.
--
-- One shared physics driver preserves the existing pulse/coast settings.
-- Collision state is captured once per character and restored on every exit.
-- Deferred jump/teleport work validates the same live character and generation.
return function(common)
	local UserInputService = common.Services.UserInputService
	local Workspace = common.Services.Workspace
	local LocalPlayer = common.LocalPlayer

	local Movement = {}
	local Config = {
		SpeedEnabled = false,
		SpeedValue = 16,
		PulseBoostMs = 100,
		PulseCoastMs = 150,
		CoastFactor = 0.16,       -- coast-frame velocity factor
		FlyEnabled = false,
		TouchFly = true,
		TouchDeadzone = 10,
		TouchSensitivity = 120,
		FlySpeed = 60,
		Noclip = false,
		JumpEnabled = false,
		JumpValue = 50,
		TeleportStep = 10,        -- studs per step
		TeleportInterval = 0.05,  -- seconds between steps
		TeleportDistance = 50,    -- studs covered by the one-tap forward teleport
	}
	Movement.Config = Config

	local pulseState = "idle"
	local pulseStart = 0
	local connections = {}
	local active = false
	local epoch = 0
	local jumpPending = false
	local collisionParts = {}
	local collisionCharacter, addedConnection, removedConnection = nil, nil, nil
	local noclipAccum = 0
	local velocityRoot, velocityOriginal, velocityWritten = nil, nil, nil

	local function releaseVelocity()
		if velocityRoot and velocityRoot.Parent and velocityWritten
			and (velocityRoot.AssemblyLinearVelocity - velocityWritten).Magnitude < 0.01 then
			velocityRoot.AssemblyLinearVelocity = velocityOriginal
		end
		velocityRoot, velocityOriginal, velocityWritten = nil, nil, nil
	end
	local function writeVelocity(root, value)
		if velocityRoot ~= root then
			releaseVelocity()
			velocityRoot, velocityOriginal = root, root.AssemblyLinearVelocity
		end
		root.AssemblyLinearVelocity = value
		velocityWritten = value
	end
	local function restoreCollisions()
		for part, original in pairs(collisionParts) do if part.Parent then part.CanCollide = original end end
		table.clear(collisionParts)
		if addedConnection then addedConnection:Disconnect() addedConnection = nil end
		if removedConnection then removedConnection:Disconnect() removedConnection = nil end
		collisionCharacter, noclipAccum = nil, 0
	end

	local function localCharacter()
		local char = LocalPlayer.Character
		if not char then return nil, nil end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		if not (hrp and humanoid) or humanoid.Health <= 0 then return nil, nil end
		return char, hrp
	end

	--=========================================================================
	-- Speed: pulse/coast.
	--=========================================================================
	local function updateSpeed()
		local char, hrp = localCharacter()
		if not char then releaseVelocity() pulseState = "idle" return end
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		local direction = humanoid.MoveDirection
		if direction.Magnitude <= 0 then releaseVelocity() pulseState = "idle" return end

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

		local target = direction.Unit * Config.SpeedValue
		if not boosting then
			target = direction.Unit * (Config.SpeedValue * Config.CoastFactor)
		end
		writeVelocity(hrp, Vector3.new(target.X, hrp.AssemblyLinearVelocity.Y, target.Z))
	end

	--=========================================================================
	-- Fly: camera-relative directional control on the Heartbeat physics step.
	--=========================================================================
	local function updateFly()
		local char, hrp = localCharacter()
		if not char then releaseVelocity() return end
		local cam = Workspace.CurrentCamera
		if not cam then releaseVelocity() return end
		if UserInputService.GetFocusedTextBox and UserInputService:GetFocusedTextBox() then releaseVelocity() return end

		local move = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
		if Config.TouchFly and common.Touch.Enabled and common.Touch.Held then
			local drag, vertical = common.Touch:Drag()
			if drag.Magnitude > Config.TouchDeadzone then
				move += cam.CFrame.RightVector * math.clamp(drag.X / math.max(Config.TouchSensitivity, 1), -1, 1)
				move += cam.CFrame.LookVector * math.clamp(-drag.Y / math.max(Config.TouchSensitivity, 1), -1, 1)
			end
			if math.abs(vertical) > 30 then
				move += Vector3.new(0, math.clamp(-vertical / math.max(Config.TouchSensitivity, 1), -1, 1), 0)
			end
		end

		if move.Magnitude > 0 then
			move = move.Unit * Config.FlySpeed
			writeVelocity(hrp, Vector3.new(move.X, move.Y, move.Z))
		else
			writeVelocity(hrp, Vector3.zero)
		end
	end

	--=========================================================================
	-- Noclip: cache descendants once, then re-assert owned parts at 20 Hz.
	--=========================================================================
	local function updateNoclip(dt)
		local char = LocalPlayer.Character
		if not Config.Noclip or not char then restoreCollisions() return end
		if collisionCharacter ~= char then
			restoreCollisions()
			collisionCharacter = char
			local function capture(part)
				if part:IsA("BasePart") and collisionParts[part] == nil then collisionParts[part] = part.CanCollide end
			end
			for _, part in ipairs(char:GetDescendants()) do capture(part) end
			addedConnection = char.DescendantAdded:Connect(capture)
			removedConnection = char.DescendantRemoving:Connect(function(part)
				if collisionParts[part] ~= nil then part.CanCollide = collisionParts[part] collisionParts[part] = nil end
			end)
			noclipAccum = 0.05
		end
		noclipAccum += dt or 0
		if noclipAccum < 0.05 then return end
		noclipAccum %= 0.05
		for part in pairs(collisionParts) do
			if part.Parent then part.CanCollide = false else collisionParts[part] = nil end
		end
	end
	function Movement:SetNoclip(value)
		Config.Noclip = value
		if not value then restoreCollisions() end
	end

	--=========================================================================
	-- Teleport: stepped motion with replacement, respawn and unload cancellation.
	--=========================================================================
	function Movement:TeleportTo(position)
		if not active then return end
		epoch += 1
		jumpPending = false
		local token = epoch
		local char, hrp = localCharacter()
		if not char then return end
		task.spawn(function()
			local origin = hrp.Position
			local delta = position - origin
			local distance = delta.Magnitude
			if distance < 0.1 then return end
			local direction = delta.Unit
			local step = math.max(Config.TeleportStep, 0.1)
			for i = 1, math.ceil(distance / step) do
				local curChar, curHrp = localCharacter()
				if not active or epoch ~= token or curChar ~= char or curHrp ~= hrp then return end
				hrp.CFrame = CFrame.new(origin + direction * math.min(distance, i * step))
				task.wait(math.max(Config.TeleportInterval, 0.01))
			end
		end)
	end

	-- One-tap forward teleport: the mobile button path, reusing the same
	-- stepped motion and cancellation guarantees as an explicit destination.
	function Movement:TeleportForward()
		if not active then return false end
		local char, hrp = localCharacter()
		if not (char and hrp) then return false end
		local distance = math.clamp(tonumber(Config.TeleportDistance) or 0, 1, 1000)
		Movement:TeleportTo(hrp.Position + hrp.CFrame.LookVector * distance)
		return true
	end

	--=========================================================================
	-- Jump: preserve the Freefall-then-velocity order without yielding input callbacks.
	--=========================================================================
	-- force=true is the explicit mobile button path: it still runs the same
	-- deferred, respawn-cancelled sequence and falls back to the humanoid's own
	-- jump when the super-jump multiplier is switched off.
	function Movement:RequestJump(force)
		if not active or jumpPending or (not Config.JumpEnabled and not force) then return end
		local char, hrp = localCharacter()
		if not char then return end
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		local token = epoch
		jumpPending = true
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		task.delay(0.02, function()
			if token ~= epoch then return end
			jumpPending = false
			local curChar, curHrp = localCharacter()
			if active and curChar == char and curHrp == hrp and humanoid.Health > 0 then
				if Config.JumpEnabled then
					hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, Config.JumpValue, hrp.AssemblyLinearVelocity.Z)
				else
					humanoid.Jump = true
				end
			end
		end)
	end

	function Movement:Update(dt)
		if not active then return end
		if Config.FlyEnabled then
			common.Guard("Movement", updateFly)
		elseif Config.SpeedEnabled then
			common.Guard("Movement", updateSpeed)
		else
			releaseVelocity()
			pulseState = "idle"
		end
		common.Guard("Movement", updateNoclip, dt)
	end

	function Movement:Start()
		if active then return end
		active = true
		table.insert(connections, UserInputService.JumpRequest:Connect(function() common.Guard("Movement", function() Movement:RequestJump() end) end))
		table.insert(connections, LocalPlayer.CharacterRemoving:Connect(function()
			epoch += 1
			jumpPending = false
			restoreCollisions()
			releaseVelocity()
			pulseState = "idle"
		end))
	end

	function Movement:Cleanup()
		active = false
		epoch += 1
		jumpPending = false
		for _, conn in ipairs(connections) do conn:Disconnect() end
		table.clear(connections)
		restoreCollisions()
		releaseVelocity()
		pulseState = "idle"
	end

	common.OnCleanup(function()
		Movement:Cleanup()
	end)

	return Movement
end
