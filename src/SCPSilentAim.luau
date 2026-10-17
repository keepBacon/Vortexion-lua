-- Vortexion SCP silent aim: rewrites outgoing shot parameters without
-- moving the camera or the mouse. Nothing local observes the correction; the
-- server only ever receives the rewritten values.
--
-- Two interception points (Vanity-General-Roblox study, local sandbox):
--   __namecall - FireServer / InvokeServer on RemoteEvents/Functions:
--       * a Vector3 with |v| in (0.5, 1.5) is a unit direction -> replaced
--         with the direction toward the resolved aim point
--       * any other Vector3 world coordinate -> replaced with the aim point
--   __index (mouse metatable) - Mouse.Hit / Mouse.Target spoofing so
--     client-side raycast logic that reads the mouse agrees with the aim.
--
-- Gates: MaxAngle cone + HitChance roll + occlusion arc fallback. Only game
-- threads are rewritten (checkcaller() == false); the executor's own calls
-- and UI library traffic pass through untouched.
return function(common)
	local Workspace = common.Services.Workspace
	local LocalPlayer = common.LocalPlayer

	local SilentAim = {}
	local Config = {
		Enabled = false,
		MaxAngle = 15,
		HitChance = 0.72,
		WallCheck = true,
		TeamCheck = true,
		ArcFallback = true,       -- arc over cover when the direct line is blocked
		ARC_PROBE_HEIGHT = 500,
		CLEARANCE = 12,
		MAX_LIFT = 200,
	}
	SilentAim.Config = Config

	local installed = false
	local namecallOriginal = nil
	local indexOriginal = nil
	local mouseMetatable = nil
	local hooked = false
	local saRoll = math.random()
	local lastResolved = nil

	local function fromGameScript()
		if not common.Caps.checkcaller then return false end
		local ok, caller = pcall(checkcaller)
		return ok and (caller == false)
	end

	--=========================================================================
	-- Aim point resolution: prefer the aimbot's current lock, otherwise the
	-- closest candidate to the crosshair (no wall check for the look target,
	-- matching the original aim-highlight behavior).
	--=========================================================================
	local function resolveAimPoint()
		local locked = common.Camera and common.Camera:GetCurrentTarget()
		local cand = locked
		if not cand then
			local cam = Workspace.CurrentCamera
			if not cam then return nil end
			local center = cam.ViewportSize / 2
			local best, bestDistance = nil, math.huge
			for _, candidate in ipairs(common.Candidates:Get()) do
				if Config.TeamCheck and candidate.Player and candidate.Player.Team ~= nil
					and candidate.Player.Team == LocalPlayer.Team then
					continue
				end
				local screen = Vector2.new(candidate.AnchorScreen.X, candidate.AnchorScreen.Y)
				local distance = (screen - center).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					best = candidate
				end
			end
			cand = best
		end
		if not cand then return nil end

		local cam = Workspace.CurrentCamera
		if not cam then return nil end

		local part = common.Candidates.pickPartFromRegion(cand.Character, "Head")
			or common.Candidates.pickAnyPart(cand.Character)
		if not part or not part:IsDescendantOf(Workspace) then return nil end

		local aimPosition = part.Position + part.AssemblyLinearVelocity * 0.1

		-- Cone gate relative to where the camera actually looks.
		local toTarget = aimPosition - cam.CFrame.Position
		if toTarget.Magnitude < 0.1 then return nil end
		if cam.CFrame.LookVector:Dot(toTarget.Unit) < math.cos(math.rad(Config.MaxAngle)) then
			return nil
		end

		-- Occlusion arc: if the direct line is blocked, probe lifted positions
		-- for a clear lane instead of silently shooting the wall.
		if Config.WallCheck or Config.ArcFallback then
			local origin = cam.CFrame.Position
			local function blocked(target)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				local filterChars = {}
				if LocalPlayer.Character then table.insert(filterChars, LocalPlayer.Character) end
				if cand.Character then table.insert(filterChars, cand.Character) end
				params.FilterDescendantsInstances = filterChars
				local result = Workspace:Raycast(origin, target - origin, params)
				return result ~= nil
			end
			if blocked(aimPosition) then
				if not Config.ArcFallback then return nil end
				local lift = Config.CLEARANCE
				local resolved = nil
				while lift <= Config.MAX_LIFT do
					local probe = aimPosition + Vector3.new(0, lift, 0)
					if not blocked(probe) then
						resolved = probe
						break
					end
					lift += Config.CLEARANCE
				end
				if not resolved then return nil end
				aimPosition = resolved
			end
		end

		return aimPosition, cand.Character
	end

	local function rewriteDirection(direction, aimPosition)
		local cam = Workspace.CurrentCamera
		if not cam then return direction end
		return (aimPosition - cam.CFrame.Position).Unit
	end

	--=========================================================================
	-- Install / remove.
	--=========================================================================
	local function install()
		if installed or hooked then return end
		if not (common.Caps.hookmetamethod or common.Caps.getrawmetatable) then
			common.Log("SilentAim", "metatable hooks unavailable; disabled")
			return
		end

		local ok, err = pcall(function()
			local gameMetatable = getrawmetatable(game)
			namecallOriginal = gameMetatable.__namecall

			local hook = function(self, ...)
				if fromGameScript() then
					local method = getnamecallmethod and getnamecallmethod() or nil
					if method == "FireServer" or method == "InvokeServer" then
						local aimPosition, aimCharacter = resolveAimPoint()
						if aimPosition and aimCharacter and self:IsDescendantOf(aimCharacter) == false then
							local args = { ... }
							local rewritten = false
							for i, arg in ipairs(args) do
								if typeof(arg) == "Vector3" then
									if not rewritten then
										saRoll = math.random()
										rewritten = true
									end
									if saRoll <= Config.HitChance then
										local magnitude = arg.Magnitude
										if magnitude > 0.5 and magnitude < 1.5 then
											args[i] = rewriteDirection(arg, aimPosition)
										else
											args[i] = aimPosition
										end
									end
								end
							end
							return namecallOriginal(self, table.unpack(args))
						end
					end
				end
				return namecallOriginal(self, ...)
			end

			if common.Caps.newcclosure then
				hook = newcclosure(hook)
			end
			hookmetamethod(game, "__namecall", hook)

			-- Mouse.Hit / Mouse.Target spoof through the mouse metatable.
			local mouse = LocalPlayer:GetMouse()
			mouseMetatable = getrawmetatable(mouse)
			indexOriginal = mouseMetatable.__index
			local indexHook = function(self, key)
				local value = indexOriginal(self, key)
				if (key == "Hit" or key == "Target") and fromGameScript() then
					local aimPosition = resolveAimPoint()
					if aimPosition then
						if key == "Hit" then
							value = CFrame.new(aimPosition)
						else
							local cam = Workspace.CurrentCamera
							local params = RaycastParams.new()
							params.FilterType = Enum.RaycastFilterType.Exclude
							params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
							local result = cam and Workspace:Raycast(
								cam.CFrame.Position, aimPosition - cam.CFrame.Position, params)
							value = result and result.Instance or value
						end
					end
				end
				return value
			end
			if common.Caps.newcclosure then
				indexHook = newcclosure(indexHook)
			end
			hookmetamethod(mouse, "__index", indexHook)

			installed = true
			common.Log("SilentAim", "hooks installed")
		end)

		if not ok then
			warn("[Vortexion/SCP/SilentAim] install failed: " .. tostring(err))
		end
	end

	local function uninstall()
		if not installed then return end
		pcall(function()
			if namecallOriginal then
				hookmetamethod(game, "__namecall", namecallOriginal)
			end
			if mouseMetatable and indexOriginal then
				hookmetamethod(mouseMetatable, "__index", indexOriginal)
			end
		end)
		installed = false
		common.Log("SilentAim", "hooks removed")
	end

	function SilentAim:Update()
		if Config.Enabled then
			install()
		else
			uninstall()
		end
	end

	function SilentAim:Cleanup()
		uninstall()
	end

	common.OnCleanup(function()
		SilentAim:Cleanup()
	end)

	return SilentAim
end
