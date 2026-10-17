-- Vortexion SCP hitbox expander (anti-detection tuned).
--
-- Scope: BasePart.Size writes are local-only. They never enter the replication
-- stream (replication is server -> client), so the server and other clients
-- keep seeing the original size while local raycasts/projections immediately
-- use the expanded one. That makes this feature purely a local-targeting
-- surface; server-validated hit points are SilentAim's job, which clamps its
-- rewrite back into the original envelope (see SCPSilentAim + Hitbox:GetEnvelope).
--
-- Throttling (a per-frame Size write rebuilds broadphase AABBs and physics
-- islands, so the original Heartbeat loop over every player was both jittery
-- and expensive):
--   * 20 Hz tick accumulator, decoupled from the render frame rate
--   * only candidates inside FOV px and MaxDistance studs are touched
--   * at most MaxActive characters per tick, nearest-first
--   * Size is lerped toward the target (0.35), never stepped
--
-- State machine per character: expanding -> pending (250 ms grace after the
-- target leaves the gate, so re-entry does not oscillate) -> collapsing
-- (lerp back at 0.5/tick) -> cleaned. CharacterRemoving / PlayerRemoving
-- bypass pending and restore immediately.
--
-- Stealth defaults: distance-decayed scale (1.5x max at contact, 1x at 250
-- studs), anisotropic XZ 1.6 / Y 1.3, Transparency 0.55 (local-only visual),
-- CanCollide false with restore. lockedOnly couples to the aimbot lock: only
-- the locked character is expanded, which keeps the number of simultaneous
-- Size writers at one in the default configuration.
return function(common)
	local Players = common.Services.Players

	local Hitbox = {}
	local Config = {
		Enabled = false,
		ScaleMax = 1.8,
		HeadScale = 1,
		TorsoScale = 1,          -- peak multiplier at point blank
		MaxDistance = 500,       -- studs; beyond this no expansion
		FOV = 600,               -- px; only on/near-screen candidates
		TickRate = 12,           -- Hz
		MaxActive = 8,           -- simultaneous characters per tick
		GrowAlpha = 0.35,        -- lerp toward target size
		ShrinkAlpha = 0.5,       -- lerp back during collapsing
		PendingMs = 250,         -- grace period before collapsing
		Transparency = 0.55,
		AnisoXZ = 1.6,
		AnisoY = 1.3,
		MaxEdge = 10,            -- studs, hard clamp on any axis
		MaxRatio = 2.2,          -- multiplier clamp on any axis
		Mode = "all",     -- lockedOnly | fullBody | all
        TargetNPCs = true, OnlyHostile = false,
		RigParts = {
			R15 = { "Head", "UpperTorso", "LowerTorso" },
			R15Full = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" },
			R6 = { "Head", "Torso" },
			R6Full = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart" },
		},
	}
	Hitbox.Config = Config
    Hitbox.Stats = { Eligible=0, Expanded=0, LastError="" }

	-- key: Player (or Model for NPCs) -> state
	local states = {}
	local accumulator = 0

	local function rigKey(character)
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then return nil end
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			return Config.Mode == "fullBody" and "R6Full" or "R6"
		end
		return Config.Mode == "fullBody" and "R15Full" or "R15"
	end

	local function captureOriginal(state, part)
		if state.parts[part] then return end
		state.parts[part] = {
			size = part.Size,
			transparency = part.Transparency,
			canCollide = part.CanCollide,
		}
	end

	local function targetSizeFor(orig, distance, partName)
		-- Distance decay: full scale at contact, 1x at MaxDistance.
		local falloff = math.clamp(1 - distance / math.max(Config.MaxDistance, 1), 0, 1)
		local regionScale = partName == "Head" and Config.HeadScale or ((partName == "Torso" or partName == "UpperTorso" or partName == "LowerTorso") and Config.TorsoScale or 1)
		local scale = 1 + (Config.ScaleMax * regionScale - 1) * falloff
		local target = Vector3.new(
			orig.X * Config.AnisoXZ,
			orig.Y * Config.AnisoY,
			orig.Z * Config.AnisoXZ
		) * scale
		-- Hard clamps: never exceed MaxEdge studs on any axis or MaxRatio x.
		local maxSize = Vector3.new(
			math.min(Config.MaxEdge, orig.X * Config.MaxRatio),
			math.min(Config.MaxEdge, orig.Y * Config.MaxRatio),
			math.min(Config.MaxEdge, orig.Z * Config.MaxRatio)
		)
		return Vector3.new(
			math.min(target.X, maxSize.X),
			math.min(target.Y, maxSize.Y),
			math.min(target.Z, maxSize.Z)
		)
	end

	local function newState(key, character, rig)
		return {
			key = key,
			character = character,
			rig = rig,
			parts = {},
			phase = "expanding",
			phaseTime = 0,
			distance = 0,
		}
	end

	local function collapseState(state, dt)
		local done = true
		for part, orig in pairs(state.parts) do
			if part.Parent then
				local size = part.Size:Lerp(orig.size, Config.ShrinkAlpha)
				part.Size = size
				part.CanCollide = orig.canCollide
				part.Transparency += (orig.transparency - part.Transparency) * Config.ShrinkAlpha
				if (size - orig.size).Magnitude > 0.02 then
					done = false
				else
					part.Size = orig.size
					part.Transparency = orig.transparency
				end
			end
		end
		if done then
			states[state.key] = nil
		end
	end

	local function restoreState(state)
		for part, orig in pairs(state.parts) do
			if part.Parent then
				part.Size = orig.size
				part.Transparency = orig.transparency
				part.CanCollide = orig.canCollide
			end
		end
		states[state.key] = nil
	end

	local function expandState(state, distance, dt)
		state.phase = "expanding"
		state.phaseTime = 0
		state.distance = distance
		local names = Config.RigParts[state.rig] or Config.RigParts.R15
		for _, name in ipairs(names) do
			local part = state.character:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				captureOriginal(state, part)
				local orig = state.parts[part]
				local target = targetSizeFor(orig.size, distance, part.Name)
				part.Size = part.Size:Lerp(target, Config.GrowAlpha)
				part.Transparency += (Config.Transparency - part.Transparency) * Config.GrowAlpha
				part.CanCollide = false
			end
		end
	end

	--=========================================================================
	-- Candidate gating: screen distance from the shared pool projection,
	-- world distance, liveness. Returns eligible candidates sorted nearest.
	--=========================================================================
	local function gatherEligible()
		local cam = common.Services.Workspace.CurrentCamera
		if not cam then return {} end
		local center = cam.ViewportSize / 2
		local locked = common.Camera and common.Camera:GetCurrentTarget()

		local eligible = {}
		for _, cand in ipairs(common.Candidates:Get()) do
			if (not Config.OnlyHostile or not common.Candidates.IsHostile
                or common.Candidates:IsHostile(cand))
                and (cand.Player or Config.TargetNPCs)
                and (Config.Mode ~= "lockedOnly" or (locked and cand.Character == locked.Character)) then
				if cand.Character.Parent and cand.Humanoid.Health > 0 and (not cand.Player or cand.Player.Character == cand.Character)
					and cand.WorldDistance <= Config.MaxDistance and cand.TopOnScreen then
					local screen = Vector2.new(cand.AnchorScreen.X, cand.AnchorScreen.Y)
					local screenDist = (screen - center).Magnitude
					if screenDist <= Config.FOV then
						table.insert(eligible, { cand = cand, screenDist = screenDist })
					end
				end
			end
		end
		table.sort(eligible, function(a, b) return a.screenDist < b.screenDist end)
		return eligible
	end

	--=========================================================================
	-- Public envelope query for SilentAim's server-side clamp: the ORIGINAL
	-- size of a part, so rewritten hit points stay inside what the server
	-- can validate.
	--=========================================================================
	function Hitbox:GetEnvelope(part)
		for _, state in pairs(states) do
			local orig = state.parts[part]
			if orig then return orig.size end
		end
		return part.Size
	end

	function Hitbox:GetEnvelopeMargin(part)
		for _, state in pairs(states) do
			local orig = state.parts[part]
			if orig then return orig.size * 0.5 + Vector3.new(0.5, 0.5, 0.5) end
		end
		return part.Size * 0.5 + Vector3.new(0.5, 0.5, 0.5)
	end

	--=========================================================================
	-- Update: dt-gated tick.
	--=========================================================================
	function Hitbox:Update(dt)
		if not Config.Enabled then
			Hitbox:Cleanup()
			accumulator = 0
			return
		end

		accumulator += dt
		local interval = 1 / math.clamp(Config.TickRate, 1, 60)
		if accumulator < interval then return end
		local elapsed = accumulator
		accumulator %= interval

        local eligible = gatherEligible()
        Hitbox.Stats.Eligible = #eligible
        local seen = {}

		-- Expand nearest-first, capped at MaxActive.
		local expanded = 0
		for _, entry in ipairs(eligible) do
			if expanded >= Config.MaxActive then break end
			local cand = entry.cand
			local key = cand.Player or cand.Character
			seen[key] = true
			local state = states[key]
			if state and (state.character ~= cand.Character or state.rig ~= rigKey(cand.Character)) then
				restoreState(state)
				state = nil
			end
			if not state then
				local rig = rigKey(cand.Character)
				if rig then
					state = newState(key, cand.Character, rig)
					states[key] = state
				end
			end
			if state then
				expandState(state, cand.WorldDistance, dt)
				expanded += 1
			end
		end

        Hitbox.Stats.Expanded=expanded
        -- Grace/collapse the rest.
		for key, state in pairs(states) do
			if not seen[key] then
				if state.phase == "expanding" then
					state.phase = "pending"
					state.phaseTime = 0
				elseif state.phase == "pending" then
					state.phaseTime += elapsed * 1000
					if state.phaseTime >= Config.PendingMs then
						state.phase = "collapsing"
					end
				else
					collapseState(state, interval)
				end
			end
		end
	end

	--=========================================================================
	-- Hard cleanup paths: character/player removal restores immediately.
	--=========================================================================
	local hookConns = {}
	local function hookRemovals()
		local function hookCharacter(player)
			if hookConns[player] then return end
			local hooks = {}
			hookConns[player] = hooks
			table.insert(hooks, player.CharacterRemoving:Connect(function(character)
				for key, state in pairs(states) do
					if state.character == character then
						restoreState(state)
					end
				end
			end))
			table.insert(hooks, player:GetPropertyChangedSignal("Character"):Connect(function()
				for key, state in pairs(states) do
					if state.key == player then
						restoreState(state)
					end
				end
			end))
		end
		for _, player in ipairs(Players:GetPlayers()) do
			hookCharacter(player)
		end
		local conn = Players.PlayerRemoving:Connect(function(player)
			for _, hook in ipairs(hookConns[player] or {}) do hook:Disconnect() end
			hookConns[player] = nil
			for key, state in pairs(states) do
				if state.key == player then
					restoreState(state)
				end
			end
		end)
		local conn2 = Players.PlayerAdded:Connect(hookCharacter)
		common.OnCleanup(function()
			conn:Disconnect()
			for _, hooks in pairs(hookConns) do
				for _, hook in ipairs(hooks) do pcall(function() hook:Disconnect() end) end
			end
			table.clear(hookConns)
			conn2:Disconnect()
		end)
	end
	hookRemovals()

	function Hitbox:Cleanup()
		for _, state in pairs(states) do
			restoreState(state)
		end
	end

	common.OnCleanup(function()
		Hitbox:Cleanup()
	end)

	return Hitbox
end
