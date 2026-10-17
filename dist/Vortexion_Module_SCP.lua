-- Vortexion WindUI - generated offline; publishing must be performed separately.
-- WindUI attribution and license are retained in vendor/WindUI/.
-- Forsaken retains runtime model rbxassetid://132866968194043.
-- Modify src/*.luau and run python3 build.py; do not edit this output.
return function(kernel)
assert(type(kernel) == 'table' and type(kernel.WindBridgeFactory) == 'function', 'Invalid Vortexion core')
local WindUI, WindBridgeFactory, GameRouter = kernel.WindUI, kernel.WindBridgeFactory, kernel.GameRouter
local entry = function()
local SCPCommonFactory = (function()
-- Vortexion SCP common runtime: capability probe, debug channel, guards.
-- Every SCP module receives this singleton as `common` and never globals state.
return function(common)
	common = common or {}
	common.Version = "3.0.0"
	common.Name = "SCP"

	--=========================================================================
	-- Executor capability probe. Each feature degrades instead of hard-failing.
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
	detect("mousemoverel", function() return type(mousemoverel) == "function" end)
	detect("gethui", function() return type(gethui) == "function" end)
	detect("getgenv", function() return type(getgenv) == "function" end)
	detect("setclipboard", function() return type(setclipboard) == "function" end)
	common.Caps = Caps
	-- ESP gate: Drawing API present in either userdata or table form.
	common.HasDrawing = (Caps.Drawing or Caps.DrawingUserdata) and true or false

	--=========================================================================
	-- Debug channel: one prefix per module, gated by the Settings/Debug toggle.
	--=========================================================================
	common.Debug = false
	function common.Log(module, ...)
		if not common.Debug then return end
		print(("[Vortexion/SCP/%s]"):format(module), ...)
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
				warn(("[Vortexion/SCP/%s] %s"):format(module, tostring(err)))
			end
		end
		return ok
	end

	--=========================================================================
	-- Visual cadence: consume the shared bridge interval clamp when present.
	-- The bridge returns max(baseSeconds, 1/VisualHz); a missing method, a
	-- non-function field or a failing call keeps the original beat untouched.
	--=========================================================================
	function common.VisualInterval(baseSeconds)
		local base = tonumber(baseSeconds) or 0
		if base <= 0 or base ~= base then return baseSeconds end
		local bridge = common.UI
		if type(bridge) == "table" and type(bridge.GetVisualInterval) == "function" then
			local ok, value = pcall(bridge.GetVisualInterval, bridge, base)
			-- the shared clamp may only slow visuals down, never speed them up:
			-- reject NaN / +-inf / non-positive and never return below base.
			if ok and type(value) == "number" and value == value
				and value < math.huge and value > -math.huge and value > 0 then
				return math.max(base, value)
			end
		end
		return base
	end

	--=========================================================================
	-- RandomName: short identifiers for module-owned GUI instances.
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
	-- getGuiParent: capability-based GUI parent with PlayerGui fallback.
	--=========================================================================
	function common.GetGuiParent()
		if Caps.gethui then
			local ok, hui = pcall(gethui)
			if ok and hui then return hui end
		end
		local coreGui = game:FindService("CoreGui")
		if coreGui then return coreGui end
		local lp = game:GetService("Players").LocalPlayer
		return lp and lp:FindFirstChild("PlayerGui")
	end

	--=========================================================================
	-- Cleanup registry: modules push disposers; Core:Stop() runs them all so a
	-- reload/respawn never leaks connections, drawings or patched closures.
	--=========================================================================
	common.Disposers = common.Disposers or {}
	if not common.OnCleanup then
		function common.OnCleanup(fn)
			table.insert(common.Disposers, fn)
		end
	end

	--=========================================================================
	-- Touch layer: mobile trigger + fly drag. Single finger held = trigger;
	-- single finger drag = horizontal fly; two fingers = vertical fly.
	--=========================================================================
	common.Touch = { Enabled = false, Held = false, Presses = 0, Region = "Right" }
	do
		local UIS = common.Services and (common.Services.UserInputService or common.Services.Input)
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
				local cam = (common.Services.Workspace or workspace).CurrentCamera
				if common.Touch.Region == "Right" and cam and input.Position.X < cam.ViewportSize.X * 0.5 then return end
				sequence += 1
				touchPoints[input] = { Origin = input.Position, Position = input.Position, Order = sequence }
				if not common.Touch.Held then common.Touch.Presses += 1 end
				common.Touch.Held = true
			end))
			table.insert(touchConns, UIS.TouchMoved:Connect(function(input)
				if touchPoints[input] then touchPoints[input].Position = input.Position end
			end))
			table.insert(touchConns, UIS.TouchEnded:Connect(function(input)
				touchPoints[input] = nil
				common.Touch.Held = next(touchPoints) ~= nil
			end))
			local function resetTouch()
				table.clear(touchPoints)
				common.Touch.Held = false
				common.Touch.FocusEpoch = (common.Touch.FocusEpoch or 0) + 1
			end
			if UIS.WindowFocusReleased then
				table.insert(touchConns, UIS.WindowFocusReleased:Connect(resetTouch))
			end
			function common.Touch:Drag()
				local first, second
				for _, point in pairs(touchPoints) do
					if not first or point.Order < first.Order then
						second, first = first, point
					elseif not second or point.Order < second.Order then second = point end
				end
				if not first then return Vector2.zero, 0 end
				local d = first.Position - first.Origin
				local vertical = second and second.Position.Y - second.Origin.Y or 0
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
	-- Safe service cache (executor-agnostic direct GetService).
	--=========================================================================
	common.Services = common.Services or {
		Players = game:GetService("Players"),
		RunService = game:GetService("RunService"),
		UserInputService = game:GetService("UserInputService"),
		HttpService = game:GetService("HttpService"),
		Lighting = game:GetService("Lighting"),
		TeleportService = game:GetService("TeleportService"),
		VirtualUser = game:GetService("VirtualUser"),
		TweenService = game:GetService("TweenService"),
		Workspace = workspace,
	}
	common.Services.UserInputService = common.Services.UserInputService or common.Services.Input
	common.Services.Input = common.Services.Input or common.Services.UserInputService
	common.LocalPlayer = common.LocalPlayer or common.Services.Players.LocalPlayer

	return common
end

end)()
local SCPCandidatesFactory = (function()
-- Vortexion SCP candidates: event-cached roster and bounded nearest pool.
-- Discovery runs once plus events; geometry refresh uses a configurable tick.
-- All consumers share validated character references.
--
-- R15/R6 rigs are both covered through REGION_PARTS: SCP roleplay mixes
-- custom rigs, and the original UpperTorso-or-Torso check silently skipped
-- every R15 arm/leg region.
return function(common)
	local Players = common.Services.Players
	local Workspace = common.Services.Workspace
	local Camera = Workspace.CurrentCamera

	local Candidates = {}
	Candidates.MAX_CANDIDATES = 24
	Candidates.REGION_PARTS = {
		Head = { "Head" },
		Torso = { "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" },
		Arms = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "Left Arm", "Right Arm" },
		Legs = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Left Leg", "Right Leg" },
	}
	Candidates.REGION_ORDER = { "Head", "Torso", "Arms", "Legs" }

	local pool = {}
	local roster = Players:GetPlayers()
	local accumulator = 0
	local dirty = true
	Candidates.Config = { TickRate = 20 }
	local rosterConns = {
		Players.PlayerAdded:Connect(function(player) table.insert(roster, player) dirty = true end),
		Players.PlayerRemoving:Connect(function(player)
			local index = table.find(roster, player)
			if index then table.remove(roster, index) end
			dirty = true
		end),
	}
	common.OnCleanup(function()
		for _, conn in ipairs(rosterConns) do conn:Disconnect() end
		table.clear(pool)
	end)
	Candidates.LocalRootPos = nil
	Candidates.LocalCharacter = nil
	Candidates.Frame = 0

	local function pickRegionPart(character, region)
		local names = Candidates.REGION_PARTS[region]
		if not names then return nil end
		for _, name in ipairs(names) do
			local part = character:FindFirstChild(name)
			if part and part:IsA("BasePart") then return part end
		end
		return nil
	end
	Candidates.pickPartFromRegion = pickRegionPart

	function Candidates.pickAnyPart(character)
		for _, region in ipairs(Candidates.REGION_ORDER) do
			local part = pickRegionPart(character, region)
			if part then return part end
		end
		return nil
	end

	local function resolveCandidate(player, character, humanoid)
		if not character.Parent then return nil end
		local head = character:FindFirstChild("Head")
		local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
		if not (head and hrp and head:IsA("BasePart") and hrp:IsA("BasePart")) then return nil end
		if humanoid.Health <= 0 then return nil end

		local cand = {
			Player = player,
			Character = character,
			Humanoid = humanoid,
			Head = head,
			HRP = hrp,
			Velocity = hrp.AssemblyLinearVelocity,
			WorldDistance = (hrp.Position - Camera.CFrame.Position).Magnitude,
			Anchor = head,
			AnchorScreen = Vector3.zero,
			TopScreen = Vector3.zero,
			BotScreen = Vector3.zero,
			TopOnScreen = false,
		}

		local localPos = Candidates.LocalRootPos
		if localPos then
			cand.WorldDistance = (hrp.Position - localPos).Magnitude
		end

		return cand
	end

	-- Refresh the pool at its own cadence; camera/character changes bypass the timer.
	function Candidates:Update(dt)
		local nextCamera = Workspace.CurrentCamera
		local nextCharacter = Players.LocalPlayer and Players.LocalPlayer.Character
		local changed = nextCamera ~= Camera or nextCharacter ~= Candidates.LocalCharacter
		Camera = nextCamera
		if not Camera then
			table.clear(pool)
			Candidates.LocalRootPos, Candidates.LocalCharacter = nil, nil
			return
		end
		accumulator += dt or 1 / math.clamp(Candidates.Config.TickRate, 1, 60)
		local interval = 1 / math.clamp(Candidates.Config.TickRate, 1, 60)
		if not dirty and not changed and accumulator < interval then return end
		accumulator %= interval
		dirty = false
		Candidates.Frame += 1

		local localPlayer = Players.LocalPlayer
		local localChar = localPlayer and localPlayer.Character
		Candidates.LocalCharacter = localChar
		local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
		Candidates.LocalRootPos = localHRP and localHRP.Position or nil

		table.clear(pool)
		self.Pool = pool

		local count = 0
		for _, player in ipairs(roster) do
			if player ~= localPlayer then
				local character = player.Character
				local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					local cand = resolveCandidate(player, character, humanoid)
					if cand then
						count += 1
						pool[count] = cand
					end
				end
			end
		end

		-- NPC models are cached by descendant events and validated on refresh.
		if Candidates.NPCs then
			for model, _ in pairs(Candidates.NPCs) do
				if model.Parent and not Players:GetPlayerFromCharacter(model) and model ~= localChar then
					local humanoid = model:FindFirstChildWhichIsA("Humanoid")
					if humanoid and humanoid.Health > 0 then
						local cand = resolveCandidate(nil, model, humanoid)
						if cand then
							count += 1
							pool[count] = cand
						end
					end
				else
					Candidates.NPCs[model] = nil
				end
			end
		end
		table.sort(pool, function(a, b) return a.WorldDistance < b.WorldDistance end)
		for i = #pool, Candidates.MAX_CANDIDATES + 1, -1 do pool[i] = nil end
		-- Only project the bounded nearest pool, not every player in the server.
		for _, cand in ipairs(pool) do
			cand.AnchorScreen = Camera:WorldToViewportPoint(cand.Anchor.Position)
			cand.TopScreen, cand.TopOnScreen = Camera:WorldToViewportPoint(cand.Head.Position + Vector3.new(0, 1.5, 0))
			cand.BotScreen = Camera:WorldToViewportPoint(cand.HRP.Position - Vector3.new(0, 1.5, 0))
		end
	end

	function Candidates:Get()
		return self.Pool or pool
	end

	--=========================================================================
	-- NPC discovery: one nested walk, then descendant lifecycle events.
	-- The original script never targeted NPCs; SCP roleplay needs it, but a
	-- per-frame GetDescendants is unaffordable, hence the cache.
	--=========================================================================
	function Candidates:StartNPCScan()
		if Candidates.NPCs then return end
		Candidates.NPCs = {}

		local function consider(model)
			if not model:IsA("Model") then return end
			if Players:GetPlayerFromCharacter(model) then return end
			local humanoid = model:FindFirstChildWhichIsA("Humanoid")
			if humanoid then Candidates.NPCs[model] = true end
		end

		local connAdded = Workspace.DescendantAdded:Connect(function(inst)
			if inst:IsA("Model") then consider(inst)
			elseif inst:IsA("Humanoid") and inst.Parent then consider(inst.Parent) end
		end)
		local connRemoved = Workspace.DescendantRemoving:Connect(function(inst)
			Candidates.NPCs[inst] = nil
			if inst:IsA("Humanoid") and inst.Parent then Candidates.NPCs[inst.Parent] = nil end
		end)
		-- One initial nested walk; subsequent discovery is event-driven.
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst:IsA("Humanoid") and inst.Parent then consider(inst.Parent) end
		end
		common.OnCleanup(function()
			connAdded:Disconnect()
			connRemoved:Disconnect()
			Candidates.NPCs = nil
		end)
	end

	return Candidates
end

end)()
local SCPCloakFactory = (function()
-- Vortexion SCP cloak: hides script-created instances from game scripts.
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
	local hookTarget = nil
	local originalNamecall = nil
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
			originalNamecall = gameMetatable.__namecall
			hookTarget = game
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
					local method = getnamecallmethod and getnamecallmethod() or nil
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
			warn("[Vortexion/SCP/Cloak] install failed: " .. tostring(err))
		end
	end

	function Cloak.Start()
		installHook()
	end

	function Cloak.Stop()
		table.clear(protectedSet)
		if hookInstalled and hookTarget and originalNamecall and common.Caps.hookmetamethod then
			pcall(function()
				hookmetamethod(hookTarget, "__namecall", originalNamecall)
			end)
		end
		hookInstalled = false
		namecallConnection = nil
		hookTarget = nil
		originalNamecall = nil
		inFilter = false
	end

	if type(common.OnCleanup) == "function" then
		common.OnCleanup(function() Cloak:Stop() end)
	end

	return Cloak
end

end)()
local SCPCameraFactory = (function()
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

end)()
local SCPSilentAimFactory = (function()
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

end)()
local SCPHitboxFactory = (function()
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
		ScaleMax = 1.5,
		HeadScale = 1,
		TorsoScale = 1,          -- peak multiplier at point blank
		MaxDistance = 250,       -- studs; beyond this no expansion
		FOV = 120,               -- px; only on/near-screen candidates
		TickRate = 20,           -- Hz
		MaxActive = 3,           -- simultaneous characters per tick
		GrowAlpha = 0.35,        -- lerp toward target size
		ShrinkAlpha = 0.5,       -- lerp back during collapsing
		PendingMs = 250,         -- grace period before collapsing
		Transparency = 0.55,
		AnisoXZ = 1.6,
		AnisoY = 1.3,
		MaxEdge = 10,            -- studs, hard clamp on any axis
		MaxRatio = 2.2,          -- multiplier clamp on any axis
		Mode = "lockedOnly",     -- lockedOnly | fullBody | all
		RigParts = {
			R15 = { "Head", "UpperTorso", "LowerTorso" },
			R15Full = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" },
			R6 = { "Head", "Torso" },
			R6Full = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart" },
		},
	}
	Hitbox.Config = Config

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
			if Config.Mode ~= "lockedOnly" or (locked and cand.Character == locked.Character) then
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

end)()
local SCPMovementFactory = (function()
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

end)()
local SCPESPFactory = (function()
-- Vortexion SCP ESP: box / health / skeleton / tracer + chams.
--
-- Pooling: character entries lazily allocate each selected drawing feature.
-- Players and NPCs share geometry without sharing incompatible object fields.
-- Partial allocations roll back; removal and unload dispose owned resources.
--
-- Projection refresh defaults to 20 Hz; disabling any feature hides it immediately.
--
-- Drawing has two shapes across executors: the classic userdata form and the
-- plain-table form. SCPCommon.HasDrawing detects the API; a small wrapper
-- normalizes property access so the rest of the module stays agnostic.
--
-- Highlight accepts Model adornments and works independently of Drawing.
return function(common)
	local Players = common.Services.Players
	local Workspace = common.Services.Workspace

	local ESP = {}
	local Config = {
		Enabled = false,
		Box = true,
		Health = true,
		Skeleton = false,
		Tracer = false,
		Chams = false,
		Labels = false,
		-- OffScreen draws an edge arrow for valid targets behind the camera or
		-- outside the viewport, so a culled box never means a lost target.
		OffScreen = false,
		-- OffScreenDistance writes the stud distance onto the edge arrow label.
		OffScreenDistance = false,
		-- MaxOffScreen caps simultaneous edge arrows with its own finite 1..64
		-- budget, so a crowd of off-screen targets can never starve on-screen ESP.
		MaxOffScreen = 16,
		-- OffScreenSize / OffScreenMargin drive the edge arrow geometry: wing
		-- length in pixels and the viewport edge inset, both finite-cleaned.
		OffScreenSize = 14,
		OffScreenMargin = 28,
		-- NativeLabels replaces Drawing text with a BillboardGui + TextLabel,
		-- which keeps working on executors without the Drawing API.
		NativeLabels = false,
		LabelTextSize = 14,
		LabelFont = "GothamBold",
		LabelStroke = true,
		LabelBackgroundTransparency = 1,
		TracerOrigin = "Bottom",
		MaxEntries = 64,
		MaxDistance = 500,
		TeamCheck = false,
		TargetNPCs = false,
		TickRate = 20,
		ColorEnemy = Color3.fromRGB(255, 60, 60),
		ColorAlly = Color3.fromRGB(60, 160, 255),
		ColorLowHealth = Color3.fromRGB(255, 140, 0),
	}
	-- Distance validity matches the native label contract: a usable value is a
	-- finite number greater than zero. Anything else degrades to the default
	-- loaded from the table above instead of reaching a comparison.
	local function validDistance(value)
		local n = tonumber(value)
		if n and n == n and math.abs(n) ~= math.huge and n > 0 then return n end
		return nil
	end
	local DEFAULT_MAX_DISTANCE = validDistance(Config.MaxDistance)
	local function labelStyle()
		local size = tonumber(Config.LabelTextSize)
		if not size or size ~= size or math.abs(size) == math.huge then size = 14 end
		size = math.floor(math.clamp(size, 10, 28) + 0.5)
		local alpha = tonumber(Config.LabelBackgroundTransparency)
		if not alpha or alpha ~= alpha or math.abs(alpha) == math.huge then alpha = 1 end
		alpha = math.clamp(alpha, 0, 1)
		local name = Config.LabelFont
		local allowed = name == "GothamBold" or name == "Gotham" or name == "SourceSans" or name == "Code"
		local font = allowed and Enum.Font[name] or Enum.Font.GothamBold
		return size, font, Config.LabelStroke ~= false, alpha
	end
	ESP.Config = Config

	--=========================================================================
	-- Drawing wrapper: userdata or table, never crash on either.
	--=========================================================================
	local function createLine()
		if not common.HasDrawing then return nil end
		local obj
		local ok = pcall(function()
			obj = Drawing.new("Line")
			obj.Visible = false
			obj.Thickness = 1
		end)
		if not ok then
			if obj then pcall(function() obj:Remove() end) end
			return nil
		end
		return {
			set = function(self, from, to, color, thickness)
				pcall(function()
					obj.From = from
					obj.To = to
					obj.Color = color
					obj.Thickness = thickness or 1
					obj.Visible = true
				end)
			end,
			hide = function()
				pcall(function() obj.Visible = false end)
			end,
			remove = function()
				pcall(function() obj:Remove() end)
			end,
		}
	end

	local function createBox()
		local lines = {}
		for i = 1, 4 do
			lines[i] = createLine()
			if not lines[i] then
				for _, line in ipairs(lines) do line:remove() end
				return nil
			end
		end
		return lines
	end

	local function drawBox(lines, topLeft, bottomRight, color, thickness)
		local topRight = Vector2.new(bottomRight.X, topLeft.Y)
		local bottomLeft = Vector2.new(topLeft.X, bottomRight.Y)
		lines[1]:set(topLeft, topRight, color, thickness)
		lines[2]:set(topRight, bottomRight, color, thickness)
		lines[3]:set(bottomRight, bottomLeft, color, thickness)
		lines[4]:set(bottomLeft, topLeft, color, thickness)
	end

	local function drawHealthBar(lines, topLeft, bottomRight, health, maxHealth)
		local ratio = math.clamp(health / math.max(maxHealth, 1), 0, 1)
		local x = topLeft.X - 4
		local top = Vector2.new(x, topLeft.Y)
		local bottom = Vector2.new(x, bottomRight.Y)
		local mid = Vector2.new(x, topLeft.Y + (bottomRight.Y - topLeft.Y) * (1 - ratio))
		lines[1]:set(top, bottom, Color3.fromRGB(0, 0, 0), 3)
		lines[2]:set(mid, bottom, ratio < 0.3 and Config.ColorLowHealth or Color3.fromRGB(60, 255, 90), 2)
	end

	local SKELETON_PAIRS = {
		{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
		{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
	}
	local SKELETON_R6 = {
		{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
		{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
	}

	local function skeletonPairsFor(character)
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
			return SKELETON_R6
		end
		return SKELETON_PAIRS
	end

	local function drawSkeleton(lines, character, color)
		local pairs = skeletonPairsFor(character)
		local cam = Workspace.CurrentCamera
		if not cam then return end
		for _, line in ipairs(lines) do line:hide() end
		for i, pair in ipairs(pairs) do
			local line = lines[i]
			if line then
				local a = character:FindFirstChild(pair[1])
				local b = character:FindFirstChild(pair[2])
				if a and b then
					local ap, onA = cam:WorldToViewportPoint(a.Position)
					local bp, onB = cam:WorldToViewportPoint(b.Position)
					if onA and onB then
						line:set(Vector2.new(ap.X, ap.Y), Vector2.new(bp.X, bp.Y), color, 1)
					else
						line:hide()
					end
				else
					line:hide()
				end
			end
		end
	end

	--=========================================================================
	-- Pool.
	--=========================================================================
	local pool = {}
	local disposed = false

	local function hideEntry(entry)
		for _, line in ipairs(entry.box or {}) do line:hide() end
		for _, line in ipairs(entry.health or {}) do line:hide() end
		for _, line in ipairs(entry.skeleton or {}) do line:hide() end
		for _, line in ipairs(entry.indicator or {}) do line:hide() end
		if entry.tracer then entry.tracer:hide() end
		if entry.label then entry.label:hide() end
		if entry.arrowLabel then entry.arrowLabel:hide() end
		-- native billboards must never survive a hide: disable, destroy, respawn,
		-- team filter, budget and distance culls all funnel through here
		if entry.nativeLabel then pcall(function() entry.nativeLabel.Enabled = false end) end
		if entry.chams then pcall(function() entry.chams.Enabled = false end) end
	end

	local function destroyNativeLabel(entry)
		local billboard, text = entry.nativeLabel, entry.nativeText
		entry.nativeLabel, entry.nativeText, entry.labelText, entry.labelColor, entry.labelDistance = nil, nil, nil, nil, nil
		entry.labelSize, entry.labelFont, entry.labelStroke, entry.labelAlpha = nil, nil, nil, nil
		if text then pcall(function() text:Destroy() end) end
		if billboard then pcall(function() billboard:Destroy() end) end
	end

	local function destroyEntry(entry)
		for _, key in ipairs({"box", "health", "skeleton", "indicator"}) do
			local lines = entry[key] or {}
			entry[key] = {}
			for _, line in ipairs(lines) do pcall(function() line:remove() end) end
		end
		for _, key in ipairs({"tracer", "label", "arrowLabel"}) do
			local object = entry[key]
			entry[key] = nil
			if object then pcall(function() object:remove() end) end
		end
		destroyNativeLabel(entry)
		local chams = entry.chams
		entry.chams = nil
		if chams then pcall(function() chams:Destroy() end) end
	end

	local function newEntry(character, player)
		return {
			character = character, player = player,
			box = {}, health = {}, skeleton = {}, indicator = {},
			nativeLabel = nil, nativeText = nil, labelText = nil, labelColor = nil, labelDistance = nil,
		}
	end

	local function ensureLines(entry, key, count)
		if entry[key][1] or not common.HasDrawing then return end
		if key == "box" then entry.box = createBox() or {} return end
		local result = {}
		for i = 1, count do
			local line = createLine()
			if not line then
				for _, allocated in ipairs(result) do allocated:remove() end
				return
			end
			result[i] = line
		end
		entry[key] = result
	end

	local function createLabel()
		if not common.HasDrawing then return nil end
		local obj
		local size, _, stroke = labelStyle()
		local ok = pcall(function()
			obj = Drawing.new("Text")
			obj.Visible, obj.Center, obj.Outline, obj.Size = false, true, stroke, size
		end)
		if not ok then
			if obj then pcall(function() obj:Remove() end) end
			return nil
		end
		local lastSize, lastStroke = size, stroke
		return {
			set = function(_, position, text, color)
				local wantSize, _, wantStroke = labelStyle()
				local applied = pcall(function()
					if lastSize ~= wantSize then obj.Size = wantSize end
					if lastStroke ~= wantStroke then obj.Outline = wantStroke end
					obj.Position, obj.Text, obj.Color, obj.Visible = position, text, color, true
				end)
				if applied then lastSize, lastStroke = wantSize, wantStroke end
			end,
			hide = function() pcall(function() obj.Visible = false end) end,
			remove = function() pcall(function() obj:Remove() end) end,
		}
	end

	local function ensureChams(entry, character)
		if entry.chams then
			local ok, valid = pcall(function()
				if Config.Chams and entry.chams.Parent == character then
					entry.chams.Enabled = true
					return true
				end
			end)
			if ok and valid then return end
			local old = entry.chams
			entry.chams = nil
			pcall(function() old:Destroy() end)
		end
		if not Config.Chams then return end
		local box
		local ok = pcall(function()
			box = Instance.new("Highlight")
			box.Name = common.RandomName()
			box.FillTransparency, box.OutlineTransparency = 0.75, 0
			box.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			box.FillColor, box.OutlineColor = Config.ColorEnemy, Config.ColorEnemy
			box.Adornee, box.Parent = character, character
			if common.Cloak then common.Cloak.Protect(box) end
		end)
		if ok then entry.chams = box
		elseif box then pcall(function() box:Destroy() end) end
	end

	--=========================================================================
	-- Native labels: BillboardGui + TextLabel rendered by the engine instead
	-- of the Drawing overlay. Works without the Drawing API and only writes
	-- Text when the string or the colour actually changed.
	--=========================================================================
	-- BillboardGui.Adornee only accepts a BasePart or Attachment in the real
	-- engine, so the label binds to the head (falling back to the root) and is
	-- rebuilt whenever the adorned part changes identity.
	local function nativeAdornee(character)
		local head = character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then return head end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then return root end
		return nil
	end

	local function styleNativeLabel(entry)
		local size, font, stroke, alpha = labelStyle()
		local ok = pcall(function()
			if entry.labelSize ~= size then
				entry.nativeText.TextSize = size
				entry.nativeLabel.Size = UDim2.fromOffset(220, math.max(32, size + 12))
			end
			if entry.labelFont ~= font then entry.nativeText.Font = font end
			if entry.labelStroke ~= stroke then entry.nativeText.TextStrokeTransparency = stroke and 0 or 1 end
			if entry.labelAlpha ~= alpha then entry.nativeText.BackgroundTransparency = alpha end
		end)
		if ok then
			entry.labelSize, entry.labelFont, entry.labelStroke, entry.labelAlpha = size, font, stroke, alpha
		end
	end

	local function ensureNativeLabel(entry, character)
		local parentOK, parent = pcall(common.GetGuiParent)
		local adorneeOK, adornee = pcall(nativeAdornee, character)
		if not adorneeOK then adornee = nil end
		if entry.nativeLabel or entry.nativeText then
			local validOK, valid = pcall(function()
				return parentOK and parent ~= nil and adornee ~= nil
					and entry.nativeLabel and entry.nativeLabel.Parent == parent
					and entry.nativeLabel.Adornee == adornee
					and entry.nativeText and entry.nativeText.Parent == entry.nativeLabel
			end)
			if validOK and valid then
				local ok = pcall(function()
					entry.nativeLabel.Enabled = true
					local want = validDistance(Config.MaxDistance)
					if want and entry.labelDistance ~= want then
						entry.nativeLabel.MaxDistance = want
						entry.labelDistance = want
					end
				end)
				if ok then styleNativeLabel(entry); return end
			end
			destroyNativeLabel(entry)
		end
		if not parentOK or not parent or not adornee then return end
		local size, font, stroke, alpha = labelStyle()
		local gui, label
		local ok = pcall(function()
			gui = Instance.new("BillboardGui")
			gui.Name = common.RandomName()
			gui.AlwaysOnTop = true
			gui.Size = UDim2.fromOffset(220, math.max(32, size + 12))
			gui.StudsOffset = Vector3.new(0, 3.2, 0)
			gui.MaxDistance = validDistance(Config.MaxDistance) or DEFAULT_MAX_DISTANCE
			label = Instance.new("TextLabel")
			label.Name = "Label"
			label.BackgroundTransparency = alpha
			label.BackgroundColor3 = Color3.new(0, 0, 0)
			label.Size = UDim2.fromScale(1, 1)
			label.Font, label.TextSize = font, size
			label.TextColor3 = Config.ColorEnemy
			label.TextStrokeTransparency = stroke and 0 or 1
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.Text = ""
			label.Parent = gui
			gui.Adornee, gui.Parent = adornee, parent
			if common.Cloak then common.Cloak.Protect(gui) end
		end)
		if ok and gui and label then
			entry.nativeLabel, entry.nativeText = gui, label
			entry.labelText, entry.labelColor = nil, nil
			entry.labelDistance = validDistance(Config.MaxDistance)
			entry.labelSize, entry.labelFont, entry.labelStroke, entry.labelAlpha = size, font, stroke, alpha
		else
			if label then pcall(function() label:Destroy() end) end
			if gui then pcall(function() gui:Destroy() end) end
		end
	end

	local function drawNativeLabel(entry, character, worldDist, color)
		ensureNativeLabel(entry, character)
		local label = entry.nativeText
		if not label then return end
		local text = (entry.player and entry.player.Name or character.Name) .. " [" .. math.floor(worldDist) .. "]"
		if entry.labelText == text and entry.labelColor == color then return end
		local ok = pcall(function()
			label.Text = text
			label.TextColor3 = color
		end)
		if ok then entry.labelText, entry.labelColor = text, color end
	end

	--=========================================================================
	-- Off-screen direction: a 3-line arrow pinned to the viewport edge. It
	-- reuses the Drawing line pool, carries its own MaxOffScreen budget and
	-- never consumes the on-screen entry budget.
	--=========================================================================
	-- Independent finite 1..64 integer budget for edge arrows: a missing, NaN
	-- or infinite MaxOffScreen falls back to 16, 0 clamps up to 1.
	local function offScreenBudget()
		local value = tonumber(Config.MaxOffScreen)
		if not value or value ~= value or math.abs(value) == math.huge then value = 16 end
		return math.clamp(math.floor(value), 1, 64)
	end

	-- Finite-number cleaning for the arrow geometry: a missing, NaN or
	-- infinite value falls back to its default, then clamps into the safe
	-- range (size 8..30, margin 8..80).
	local function offScreenStyle()
		local size = tonumber(Config.OffScreenSize)
		if not size or size ~= size or math.abs(size) == math.huge then size = 14 end
		size = math.clamp(math.floor(size), 8, 30)
		local margin = tonumber(Config.OffScreenMargin)
		if not margin or margin ~= margin or math.abs(margin) == math.huge then margin = 28 end
		margin = math.clamp(math.floor(margin), 8, 80)
		return size, margin
	end

	local function drawOffscreenArrow(lines, viewport, screen, color)
		local size, margin = offScreenStyle()
		local cx, cy = viewport.X / 2, viewport.Y / 2
		local dx, dy = screen.X - cx, screen.Y - cy
		if dx == 0 and dy == 0 then return nil end
		local angle = math.atan(dy, dx)
		local cos, sin = math.cos(angle), math.sin(angle)
		-- a margin wider than a tiny viewport must never flip the arrow to the
		-- opposite side: clamp the usable half-extents at zero so the reach
		-- stays non-negative and the tip keeps pointing at the target
		local ex, ey = math.max(cx - margin, 0), math.max(cy - margin, 0)
		local reach = math.min(ex / math.max(math.abs(cos), 1e-4), ey / math.max(math.abs(sin), 1e-4))
		local tip = Vector2.new(cx + cos * reach, cy + sin * reach)
		local back = angle + math.pi
		local left = Vector2.new(tip.X + math.cos(back - 0.5) * size, tip.Y + math.sin(back - 0.5) * size)
		local right = Vector2.new(tip.X + math.cos(back + 0.5) * size, tip.Y + math.sin(back + 0.5) * size)
		lines[1]:set(tip, left, color, 2)
		lines[2]:set(left, right, color, 2)
		lines[3]:set(right, tip, color, 2)
		return tip
	end

	--=========================================================================
	-- Per-frame visibility cull + 20 Hz geometry refresh.
	--=========================================================================
	local accumulator = 0

	local lastCamera = nil
	function ESP:Update(dt)
		if disposed then return end
		local cam = Workspace.CurrentCamera
		if not Config.Enabled or not cam then
			for _, entry in pairs(pool) do hideEntry(entry) end
			accumulator = 0
			return
		end
		accumulator += dt or 0
		local interval = 1 / math.clamp(Config.TickRate, 1, 60)
		-- shared performance clamp: the bridge may only slow this beat down,
		-- and a missing bridge keeps the original tick rate untouched
		if common.VisualInterval then interval = common.VisualInterval(interval) end
		local refresh = cam ~= lastCamera or accumulator >= interval
		lastCamera = cam
		if refresh then accumulator %= interval end
		local npcs = common.Candidates.NPCs or {}
		if refresh then
			for key, entry in pairs(pool) do
				if not entry.player and (not Config.TargetNPCs or not npcs[key] or not key.Parent) then
					destroyEntry(entry) pool[key] = nil
				end
			end
			if Config.TargetNPCs then
				for npc in pairs(npcs) do
					if npc.Parent and not Players:GetPlayerFromCharacter(npc) and not pool[npc] then pool[npc] = newEntry(npc, nil) end
				end
			end
		end
		local localTeam = common.LocalPlayer.Team
		local viewport, origin = cam.ViewportSize, cam.CFrame.Position
		local shown, arrows = 0, 0
		local arrowLimit = offScreenBudget()
		-- one finite distance per batch: an unusable Config.MaxDistance degrades
		-- to the loaded default here, so no per-entry comparison sees a bad value
		local maxDistance = validDistance(Config.MaxDistance) or DEFAULT_MAX_DISTANCE
		for _, entry in pairs(pool) do
			local character = entry.player and entry.player.Character or entry.character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
			local ally = entry.player and localTeam ~= nil and entry.player.Team == localTeam
			if not Config.Box then for _, line in ipairs(entry.box) do line:hide() end end
			if not Config.Health then for _, line in ipairs(entry.health) do line:hide() end end
			if not Config.Skeleton then for _, line in ipairs(entry.skeleton) do line:hide() end end
			if not Config.Tracer and entry.tracer then entry.tracer:hide() end
			if not Config.Labels and entry.label then entry.label:hide() end
			if Config.NativeLabels and entry.label then entry.label:hide() end
			if not Config.Labels or not Config.NativeLabels then destroyNativeLabel(entry) end
			if not Config.OffScreen then
				for _, line in ipairs(entry.indicator or {}) do line:hide() end
				if entry.arrowLabel then entry.arrowLabel:hide() end
			end
			if not Config.OffScreenDistance and entry.arrowLabel then entry.arrowLabel:hide() end
			if not Config.Chams and entry.chams then entry.chams.Enabled = false end
			if not (character and character.Parent and hrp and humanoid and humanoid.Health > 0)
				or (Config.TeamCheck and ally) or (not entry.player and not Config.TargetNPCs) then
				hideEntry(entry)
			elseif refresh then
				local worldDist = (hrp.Position - origin).Magnitude
				local screen, onScreen = cam:WorldToViewportPoint(hrp.Position)
				local color = ally and Config.ColorAlly or Config.ColorEnemy
				if worldDist > maxDistance or not onScreen or screen.Z <= 0 then
					-- culled box: keep the target readable with an edge arrow while
					-- it is still in front of the camera and inside the distance budget
					if Config.OffScreen and worldDist <= maxDistance and screen.Z > 0
						and arrows < arrowLimit then
						hideEntry(entry)
						ensureLines(entry, "indicator", 3)
						if entry.indicator[1] then
							arrows += 1
							local tip = drawOffscreenArrow(entry.indicator, viewport, screen, color)
							if Config.OffScreenDistance and tip then
								entry.arrowLabel = entry.arrowLabel or createLabel()
								if entry.arrowLabel then
									local ccx, ccy = viewport.X / 2, viewport.Y / 2
									local ox, oy = tip.X - ccx, tip.Y - ccy
									local len = math.sqrt(ox * ox + oy * oy)
									local inset = len > 0
										and Vector2.new(tip.X - ox / len * 24, tip.Y - oy / len * 24)
										or tip
									entry.arrowLabel:set(inset, tostring(math.floor(worldDist)), color)
								end
							end
						end
					else
						hideEntry(entry)
					end
				elseif shown >= Config.MaxEntries then
					hideEntry(entry)
				else
					shown += 1
					for _, line in ipairs(entry.indicator or {}) do line:hide() end
					if entry.arrowLabel then entry.arrowLabel:hide() end
					local head = character:FindFirstChild("Head")
					local top = head and cam:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0)) or screen
					local bottom = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
					local height = math.abs(bottom.Y - top.Y)
					local width = math.clamp(height * 0.55, 8, viewport.X * 0.2)
					local topLeft = Vector2.new(screen.X - width / 2, math.min(top.Y, bottom.Y))
					local bottomRight = Vector2.new(screen.X + width / 2, math.max(top.Y, bottom.Y))
					if Config.Box then ensureLines(entry, "box", 4) if entry.box[1] then drawBox(entry.box, topLeft, bottomRight, color, 1) end end
					if Config.Health then ensureLines(entry, "health", 2) if entry.health[2] then drawHealthBar(entry.health, topLeft, bottomRight, humanoid.Health, humanoid.MaxHealth) end end
					if Config.Skeleton then ensureLines(entry, "skeleton", #SKELETON_PAIRS) if entry.skeleton[1] then drawSkeleton(entry.skeleton, character, color) end end
					if Config.Tracer then
						entry.tracer = entry.tracer or createLine()
						if entry.tracer then entry.tracer:set(Vector2.new(viewport.X / 2, Config.TracerOrigin == "Center" and viewport.Y / 2 or viewport.Y), Vector2.new(screen.X, bottomRight.Y), color, 1) end
					end
					if Config.Labels then
						if Config.NativeLabels then
							drawNativeLabel(entry, character, worldDist, color)
						else
							entry.label = entry.label or createLabel()
							if entry.label then entry.label:set(Vector2.new(screen.X, topLeft.Y - 16), (entry.player and entry.player.Name or character.Name) .. " [" .. math.floor(worldDist) .. "]", color) end
						end
					end
					if Config.Chams then
						ensureChams(entry, character)
						if entry.chams then entry.chams.FillColor, entry.chams.OutlineColor = color, color end
					end
				end
			end
		end
	end


	--=========================================================================
	-- Pool lifecycle.
	--=========================================================================
	local trackConns = {}
	local function trackPlayer(player)
		if disposed then return end
		if player == common.LocalPlayer or trackConns[player] then return end
		local hooks = {}
		trackConns[player] = hooks
		local function bindCharacter(character)
			if disposed then return end
			if pool[player] then destroyEntry(pool[player]) end
			pool[player] = newEntry(character, player)
		end
		table.insert(hooks, player.CharacterAdded:Connect(bindCharacter))
		if player.Character then bindCharacter(player.Character) end
		table.insert(hooks, player.CharacterRemoving:Connect(function()
			if disposed then return end
			local entry = pool[player]
			if entry then
				hideEntry(entry)
				destroyEntry(entry)
				pool[player] = nil
			end
		end))
	end

	for _, player in ipairs(Players:GetPlayers()) do
		trackPlayer(player)
	end
	local conn = Players.PlayerAdded:Connect(trackPlayer)
	local conn2 = Players.PlayerRemoving:Connect(function(player)
		if disposed then return end
		for _, hook in ipairs(trackConns[player] or {}) do hook:Disconnect() end
		trackConns[player] = nil
		local entry = pool[player]
		if entry then
			destroyEntry(entry)
			pool[player] = nil
		end
	end)

	function ESP:Cleanup()
		if disposed then return end
		disposed = true
		conn:Disconnect()
		conn2:Disconnect()
		for _, hooks in pairs(trackConns) do
			for _, hook in ipairs(hooks) do pcall(function() hook:Disconnect() end) end
		end
		table.clear(trackConns)
		for _, entry in pairs(pool) do
			destroyEntry(entry)
		end
		pool = {}
	end

	common.OnCleanup(function()
		ESP:Cleanup()
	end)

	return ESP
end

end)()
-- Vortexion - SCP v3: game-specific entry, unified WindUI UI.
-- Reference-informed feature coverage: modular subsystems, one
-- budgeted render loop, capability probing and version adaptation instead of
-- the original single mixed RenderStepped/Heartbeat loop.
-- Do not copy source implementations: use lifecycle-managed services in separate modules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--=========================================================================
-- Lifecycle: one live generation. A re-execute of the loader bumps the
-- generation and tears the previous instance down instead of stacking loops.
--=========================================================================
local global = (getgenv and getgenv()) or _G
if type(global.VortexionSCPCleanup) == "function" then
    pcall(global.VortexionSCPCleanup)
end
global.VortexionSCPGeneration = (global.VortexionSCPGeneration or 0) + 1
local generation = global.VortexionSCPGeneration
local connections = {}
local cleanups = {}
local function isCurrent()
    return global.VortexionSCPGeneration == generation
end
local function ownConnection(conn)
    if conn then table.insert(connections, conn) end
    return conn
end
local function ownCleanup(fn)
    table.insert(cleanups, fn)
end
local function cleanup()
    if global.VortexionSCPGeneration == generation then
        global.VortexionSCPGeneration += 1
    end
    for i = #connections, 1, -1 do
        pcall(function() connections[i]:Disconnect() end)
        connections[i] = nil
    end
    for i = #cleanups, 1, -1 do
        pcall(cleanups[i])
        cleanups[i] = nil
    end
end
global.VortexionSCPCleanup = cleanup

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
-- UI: WindUI bridge (vendored, zero network). The original script loaded
-- Rayfield over HttpGet, which is both a dependency risk and a client-side
-- trace; the vendored UI keeps the whole hub self-contained.
--=========================================================================
local ok, ui = pcall(function() return WindBridgeFactory(WindUI) end)
if not ok or not ui then
    global.VortexionBootError = "SCP Bridge: " .. tostring(ui)
    warn("[Vortexion/SCP] WindUI initialization failed: " .. tostring(ui))
    return
end
local window = ui:CreateWindow({ Title = "VoidPath V3 | SCP", Size = UDim2.fromOffset(640, 460) })
ui:OnDestroy(cleanup)
local tabs = {
    Aim = window:AddTab({ Title = "自瞄", Icon = "lucide-crosshair" }),
    Silent = window:AddTab({ Title = "静默", Icon = "lucide-target" }),
    Hitbox = window:AddTab({ Title = "碰撞箱", Icon = "lucide-box" }),
    Visual = window:AddTab({ Title = "视觉", Icon = "lucide-eye" }),
    Move = window:AddTab({ Title = "移动", Icon = "lucide-activity" }),
    World = window:AddTab({ Title = "世界", Icon = "lucide-globe" }),
    Info = window:AddTab({ Title = "信息", Icon = "lucide-info" }),
}

--=========================================================================
-- common singleton: every subsystem reads capabilities and shared state from
-- this table; nothing module-private leaks into the global environment.
--=========================================================================
local common = {
    Services = {
        Players = Players,
        RunService = RunService,
        Workspace = Workspace,
        HttpService = HttpService,
        TeleportService = TeleportService,
        VirtualUser = VirtualUser,
        Lighting = Lighting,
        Input = UserInputService,
    },
    LocalPlayer = LocalPlayer,
    UI = ui,
    Window = window,
    Tabs = tabs,
    IsCurrent = isCurrent,
    Own = ownConnection,
    OnCleanup = ownCleanup,
    Debug = false,
    PlaceId = game.PlaceId,
    GameVersion = "scp-v3",
}

local bootFailures = {}
local function reportBootFailure(component, message)
    local detail = tostring(component) .. ": " .. tostring(message):sub(1, 160)
    table.insert(bootFailures, detail)
    ui.BootStatus, ui.BootError = "partial", table.concat(bootFailures, "; ")
    warn("[Vortexion/SCP] " .. detail)
end
local function setup(name, factory)
    if type(factory) ~= "function" then
        reportBootFailure(name, "factory missing")
        return nil
    end
    local passed, result = pcall(factory, common)
    if not passed then
        reportBootFailure(name, result)
        return nil
    end
    return result
end

-- Order matters: capabilities first, then the shared candidate pool, then
-- consumers (cloak protects instances the aim/visual layers create).
setup("common", SCPCommonFactory)
common.Log = common.Log or function() end
common.Guard = common.Guard or function(_, fn, ...) local ok, err = pcall(fn, ...) if not ok then warn(tostring(err)) end return ok end
common.Cloak = setup("cloak", SCPCloakFactory) or { Protect = function(object) return object end, Stop = function() end, Start = function() end }
-- Cloak is inert until its enumeration hook is installed; start it here so
-- every later module (ESP chams, aim highlight) is already protected.
if type(common.Cloak.Start) == "function" then
    common.Guard("Cloak", common.Cloak.Start)
end
common.Candidates = setup("candidates", SCPCandidatesFactory) or { Update = function() end, Get = function() return {} end, NPCs = nil }
common.Camera = setup("camera", SCPCameraFactory) or { Update = function() end, GetCurrentTarget = function() end, Config = { Enabled = false } }
common.SilentAim = setup("silentaim", SCPSilentAimFactory) or { Update = function() end, Config = { Enabled = false } }
common.Hitbox = setup("hitbox", SCPHitboxFactory) or { Update = function() end, Config = { Enabled = false } }
common.Movement = setup("movement", SCPMovementFactory) or { Update = function() end, Start = function() end, Config = { SpeedEnabled = false } }
common.ESP = setup("esp", SCPESPFactory) or { Update = function() end, Config = { Enabled = false } }

local Camera = common.Camera
local SilentAim = common.SilentAim
local Hitbox = common.Hitbox
local Movement = common.Movement
local ESP = common.ESP
local Candidates = common.Candidates

--=========================================================================
-- NPC scan: SCP roleplay populates the map with humanoid NPCs; without the
-- scanner they are invisible to every targeting feature.
--=========================================================================
common.Guard("Candidates", function()
    if Candidates.StartNPCScan then Candidates:StartNPCScan() end
end)

--=========================================================================
-- Movement runs on Heartbeat (physics step), not the render step: velocity
-- writes land before the physics solver reads them.
--=========================================================================
common.Guard("Movement", function() Movement:Start() end)
ownConnection(RunService.Heartbeat:Connect(function(dt)
    if not isCurrent() then return end
    common.Guard("Movement", function() Movement:Update(dt) end)
end))

--=========================================================================
-- World features preserved from the original script, re-hosted on the shared
-- loop with low-frequency timers instead of per-frame work.
--=========================================================================
local world = {
    Fullbright = false,
    AntiRagdoll = false,
    AntiAFK = true,
    DeleteDoors = false,
}
local origLighting = nil
local function captureLighting()
    origLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
end

local function applyFullbright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 12
    Lighting.FogEnd = 1e10
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
end

local function restoreLighting()
    if not origLighting then return end
    Lighting.Brightness = origLighting.Brightness
    Lighting.ClockTime = origLighting.ClockTime
    Lighting.FogEnd = origLighting.FogEnd
    Lighting.Ambient = origLighting.Ambient
    Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
    origLighting = nil
end
ownCleanup(restoreLighting)

local afkHeld = false
ownCleanup(function()
    if afkHeld then pcall(function() VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end) afkHeld = false end
end)
ownConnection(LocalPlayer.Idled:Connect(function()
    if not isCurrent() or not world.AntiAFK or afkHeld then return end
    pcall(function()
        afkHeld = true
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
        task.wait(1)
        if afkHeld then
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
            afkHeld = false
        end
    end)
end))

--=========================================================================
-- Triggerbot: fires while the aimbot holds a lock. Uses executor mouse
-- functions when present, VirtualUser otherwise.
--=========================================================================
local trigger = {
    Enabled = false,
    Mode = "Locked",        -- Locked | Always
    IntervalMs = 180,
    lastFire = 0,
    firing = false,
}
local function mouseDown()
    if type(mouse1press) == "function" then
        mouse1press()
    else
        pcall(function() VirtualUser:Button1Down(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end)
    end
end
local function mouseUp()
    if type(mouse1release) == "function" then
        mouse1release()
    else
        pcall(function() VirtualUser:Button1Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end)
    end
end
local function updateTrigger()
    if not trigger.Enabled then
        if trigger.firing then mouseUp() trigger.firing = false end
        return
    end
    local locked = Camera.GetCurrentTarget and Camera:GetCurrentTarget()
    local shouldFire = (trigger.Mode == "Always") or (locked ~= nil)
    local now = tick() * 1000
    if shouldFire and now - trigger.lastFire >= trigger.IntervalMs then
        trigger.lastFire = now
        if not trigger.firing then
            mouseDown()
            trigger.firing = true
            task.delay(0.08, function()
                if trigger.firing then
                    mouseUp()
                    trigger.firing = false
                end
            end)
        end
    elseif not shouldFire and trigger.firing then
        mouseUp()
        trigger.firing = false
    end
end

--=========================================================================
-- Single render loop: one BindToRenderStep(Last) drives every visual-side
-- subsystem. Per-subsystem costs and over-budget streaks are reported in
-- the debug snapshot; Guard isolates errors and throttles warnings.
--
-- Candidate/ESP/hitbox accumulators handle cadence independently of render FPS.
--=========================================================================
local budgets = { Aim = 1.2, Hitbox = 0.6, ESP = 1.0 }
local costs = { Aim = 0, Hitbox = 0, ESP = 0, Candidates = 0 }
local slowLoops = { Aim = 0, Hitbox = 0, ESP = 0 }
local lastSnapshot = 0
local lowFreqTimer = 0

RunService:BindToRenderStep("VortexionSCPFrame", Enum.RenderPriority.Last.Value, function(dt)
    if not isCurrent() then return end
    common.Guard("Frame", function()
        -- Low-frequency world features (0.5 s cadence).
        lowFreqTimer += dt
        if lowFreqTimer >= 0.5 then
            lowFreqTimer = 0
            if world.Fullbright then applyFullbright() end
            if world.AntiRagdoll and LocalPlayer.Character then
                local rag = LocalPlayer.Character:FindFirstChild("Ragdoll")
                if rag then pcall(function() rag:Destroy() end) end
            end
        end


        local t0 = tick()
        common.Guard("Candidates", function() Candidates:Update(dt) end)
        costs.Candidates = (tick() - t0) * 1000

        t0 = tick()
        common.Guard("Camera", function() Camera:Update(dt) end)
        costs.Aim = (tick() - t0) * 1000

        common.Guard("SilentAim", function() SilentAim:Update() end)

        t0 = tick()
        common.Guard("Hitbox", function() Hitbox:Update(dt) end)
        costs.Hitbox = (tick() - t0) * 1000

        t0 = tick()
        common.Guard("ESP", function() ESP:Update(dt) end)
        costs.ESP = (tick() - t0) * 1000

        common.Guard("Trigger", updateTrigger)

        -- Budget watchdog: count consecutive over-budget frames per
        -- subsystem; the snapshot surfaces them for tuning.
        for name, cost in pairs(costs) do
            local budget = budgets[name]
            if budget and cost > budget then
                slowLoops[name] = (slowLoops[name] or 0) + 1
            elseif slowLoops[name] then
                slowLoops[name] = 0
            end
        end

        -- Debug snapshot: 2 s cadence, one line per subsystem.
        if common.Debug and tick() - lastSnapshot >= 2 then
            lastSnapshot = tick()
            local locked = Camera.GetCurrentTarget and Camera:GetCurrentTarget()
            common.Log("Frame", ("cand=%.2fms aim=%.2fms hitbox=%.2fms esp=%.2fms slow(a/h/e)=%d/%d/%d lock=%s")
                :format(costs.Candidates, costs.Aim, costs.Hitbox, costs.ESP,
                    slowLoops.Aim or 0, slowLoops.Hitbox or 0, slowLoops.ESP or 0,
                    locked and tostring(locked.Player and locked.Player.Name or "NPC") or "-"))
        end
    end)
end)
ownCleanup(function() RunService:UnbindFromRenderStep("VortexionSCPFrame") end)
ownCleanup(function() if trigger.firing then mouseUp() trigger.firing = false end end)

--=========================================================================
-- UI wiring.
--=========================================================================
tabs.Aim:AddToggle("SCPAimEnabled", { Title = "自瞄总开关", Default = false, Callback = function(v) Camera.Config.Enabled = v if not v then Camera:Update(0) end end })
tabs.Aim:AddDropdown("SCPAimMode", { Title = "模式", Values = { "Camera", "Mouse", "Both" }, Default = "Camera", Callback = function(v) Camera.Config.Mode = v end })
tabs.Aim:AddSlider("SCPAimFov", { Title = "FOV (px)", Min = 20, Max = 400, Default = 120, Rounding = 0, Callback = function(v) Camera.Config.FOV = v end })
tabs.Aim:AddSlider("SCPAimDist", { Title = "最大距离 (studs)", Min = 50, Max = 1000, Default = 300, Rounding = 0, Callback = function(v) Camera.Config.MaxDistance = v end })
tabs.Aim:AddSlider("SCPAimSmooth", { Title = "平滑度", Min = 50, Max = 99, Default = 85, Rounding = 0, Callback = function(v) Camera.Config.Smoothness = v / 100 end })
tabs.Aim:AddDropdown("SCPAimPart", { Title = "部位", Values = { "Head", "Torso", "Arms", "Legs", "Random" }, Default = "Head", Callback = function(v) Camera.Config.Hitbox = v end })
tabs.Aim:AddSlider("SCPAimAngle", { Title = "最大夹角 (度)", Min = 5, Max = 90, Default = 30, Rounding = 0, Callback = function(v) Camera.Config.MaxAngle = v end })
tabs.Aim:AddSlider("SCPAimPrediction", { Title = "预瞄", Min = 0, Max = 50, Default = 12, Rounding = 0, Callback = function(v) Camera.Config.Prediction = v / 100 end })
tabs.Aim:AddSlider("SCPAimHitChance", { Title = "锁定命中率", Min = 10, Max = 100, Default = 90, Rounding = 0, Callback = function(v) Camera.Config.HitChance = v / 100 end })
tabs.Aim:AddToggle("SCPAimWall", { Title = "遮挡检查", Default = true, Callback = function(v) Camera.Config.WallCheck = v end })
tabs.Aim:AddToggle("SCPAimTeam", { Title = "队伍过滤", Default = false, Callback = function(v) Camera.Config.TeamCheck = v end })
tabs.Aim:AddToggle("SCPAimNPC", { Title = "锁定 NPC", Default = true, Callback = function(v) Camera.Config.TargetNPCs = v end })
tabs.Aim:AddDropdown("SCPAimKey", { Title = "触发键", Values = { "Right", "Left", "None", "Touch", "Always" }, Default = Camera.Config.TriggerKey or "Right", Callback = function(v) Camera.Config.TriggerKey = v if Camera.ResetTrigger then Camera:ResetTrigger() end end })
tabs.Aim:AddToggle("SCPAimFovCircle", { Title = "FOV 圈", Default = true, Callback = function(v) Camera.Config.FOVCircle = v end })
tabs.Aim:AddToggle("SCPTrigger", { Title = "自动开火（锁定时）", Default = false, Callback = function(v) trigger.Enabled = v if not v then updateTrigger() end end })

tabs.Silent:AddToggle("SCPSilentEnabled", { Title = "静默瞄准总开关", Default = false, Callback = function(v) SilentAim.Config.Enabled = v end })
tabs.Silent:AddSlider("SCPSilentAngle", { Title = "最大夹角 (度)", Min = 5, Max = 60, Default = 15, Rounding = 0, Callback = function(v) SilentAim.Config.MaxAngle = v end })
tabs.Silent:AddSlider("SCPSilentChance", { Title = "命中率", Min = 10, Max = 100, Default = 72, Rounding = 0, Callback = function(v) SilentAim.Config.HitChance = v / 100 end })
tabs.Silent:AddToggle("SCPSilentWall", { Title = "遮挡检查", Default = true, Callback = function(v) SilentAim.Config.WallCheck = v end })
tabs.Silent:AddToggle("SCPSilentTeam", { Title = "队伍过滤", Default = false, Callback = function(v) SilentAim.Config.TeamCheck = v end })
tabs.Silent:AddParagraph({ Title = "静默瞄准说明", Content = "改写客户端发往服务端的命中参数；参数按单位方向/世界坐标两种形态标定，命中点限制在服务端可判定的原始包络内。" })

tabs.Hitbox:AddToggle("SCPHitboxEnabled", { Title = "碰撞箱扩展", Default = false, Callback = function(v) Hitbox.Config.Enabled = v if not v then Hitbox:Update(0) end end })
tabs.Hitbox:AddDropdown("SCPHitboxMode", { Title = "模式", Values = { "lockedOnly", "fullBody", "all" }, Default = "lockedOnly", Callback = function(v) Hitbox.Config.Mode = v end })
tabs.Hitbox:AddSlider("SCPHitboxScale", { Title = "峰值倍率", Min = 10, Max = 30, Default = 15, Rounding = 0, Callback = function(v) Hitbox.Config.ScaleMax = v / 10 end })
tabs.Hitbox:AddSlider("SCPHitboxDist", { Title = "作用距离 (studs)", Min = 50, Max = 500, Default = 250, Rounding = 0, Callback = function(v) Hitbox.Config.MaxDistance = v end })
tabs.Hitbox:AddSlider("SCPHitboxFov", { Title = "屏幕门 (px)", Min = 20, Max = 400, Default = 120, Rounding = 0, Callback = function(v) Hitbox.Config.FOV = v end })
tabs.Hitbox:AddSlider("SCPHitboxActive", { Title = "同帧目标数", Min = 1, Max = 8, Default = 3, Rounding = 0, Callback = function(v) Hitbox.Config.MaxActive = v end })
tabs.Hitbox:AddParagraph({ Title = "碰撞箱说明", Content = "20Hz 节流、尺寸平滑与距离衰减；关闭或角色替换时恢复尺寸、透明度和碰撞属性。" })

tabs.Visual:AddToggle("SCPESPEnabled", { Title = "ESP 总开关", Default = false, Callback = function(v) ESP.Config.Enabled = v if not v then ESP:Update(0) end end })
tabs.Visual:AddToggle("SCPESPBox", { Title = "方框", Default = true, Callback = function(v) ESP.Config.Box = v end })
tabs.Visual:AddToggle("SCPESPHealth", { Title = "血条", Default = true, Callback = function(v) ESP.Config.Health = v end })
tabs.Visual:AddToggle("SCPSkeleton", { Title = "骨骼", Default = false, Callback = function(v) ESP.Config.Skeleton = v end })
tabs.Visual:AddToggle("SCPTracer", { Title = "射线", Default = false, Callback = function(v) ESP.Config.Tracer = v end })
tabs.Visual:AddToggle("SCPChams", { Title = "Chams", Default = false, Callback = function(v) ESP.Config.Chams = v end })
tabs.Visual:AddToggle("SCPESPNPC", { Title = "包含 NPC", Default = false, Callback = function(v) ESP.Config.TargetNPCs = v end })
tabs.Visual:AddSlider("SCPESPDist", { Title = "ESP 距离 (studs)", Min = 50, Max = 2000, Default = 500, Rounding = 0, Callback = function(v) ESP.Config.MaxDistance = v end })
tabs.Visual:AddToggle("SCPESPTeam", { Title = "显示队友", Default = false, Callback = function(v) ESP.Config.TeamCheck = not v end })
tabs.Visual:AddColorpicker("SCPESPColorEnemy", { Title = "敌人颜色", Default = ESP.Config.ColorEnemy, Callback = function(v)
    if not isCurrent() then return end
    if typeof(v) ~= "Color3" then return end
    local r, g, b = v.R, v.G, v.B
    if type(r) ~= "number" or r ~= r or r < 0 or r > 1 or type(g) ~= "number" or g ~= g or g < 0 or g > 1 or type(b) ~= "number" or b ~= b or b < 0 or b > 1 then return end
    ESP.Config.ColorEnemy = v
end })
tabs.Visual:AddColorpicker("SCPESPColorAlly", { Title = "队友颜色", Default = ESP.Config.ColorAlly, Callback = function(v)
    if not isCurrent() then return end
    if typeof(v) ~= "Color3" then return end
    local r, g, b = v.R, v.G, v.B
    if type(r) ~= "number" or r ~= r or r < 0 or r > 1 or type(g) ~= "number" or g ~= g or g < 0 or g > 1 or type(b) ~= "number" or b ~= b or b < 0 or b > 1 then return end
    ESP.Config.ColorAlly = v
end })
tabs.Visual:AddColorpicker("SCPESPColorLowHealth", { Title = "低血量颜色", Default = ESP.Config.ColorLowHealth, Callback = function(v)
    if not isCurrent() then return end
    if typeof(v) ~= "Color3" then return end
    local r, g, b = v.R, v.G, v.B
    if type(r) ~= "number" or r ~= r or r < 0 or r > 1 or type(g) ~= "number" or g ~= g or g < 0 or g > 1 or type(b) ~= "number" or b ~= b or b < 0 or b > 1 then return end
    ESP.Config.ColorLowHealth = v
end })

tabs.Move:AddToggle("SCPSpeed", { Title = "加速", Default = false, Callback = function(v) Movement.Config.SpeedEnabled = v end })
tabs.Move:AddSlider("SCPSpeedVal", { Title = "速度值", Min = 16, Max = 150, Default = 16, Rounding = 0, Callback = function(v) Movement.Config.SpeedValue = v end })
tabs.Move:AddToggle("SCPFly", { Title = "飞行", Default = false, Callback = function(v) Movement.Config.FlyEnabled = v end })
tabs.Move:AddToggle("SCPTouchFly", { Title = "触屏拖动飞行", Default = true, Callback = function(v) Movement.Config.TouchFly = v end })
tabs.Move:AddSlider("SCPFlySpeed", { Title = "飞行速度", Min = 10, Max = 300, Default = 60, Rounding = 0, Callback = function(v) Movement.Config.FlySpeed = v end })
tabs.Move:AddToggle("SCPNoclip", { Title = "穿墙", Default = false, Callback = function(v) if Movement.SetNoclip then Movement:SetNoclip(v) else Movement.Config.Noclip = v end end })
tabs.Move:AddToggle("SCPJump", { Title = "超级跳", Default = false, Callback = function(v) Movement.Config.JumpEnabled = v end })
tabs.Move:AddSlider("SCPJumpVal", { Title = "跳跃力", Min = 20, Max = 250, Default = 50, Rounding = 0, Callback = function(v) Movement.Config.JumpValue = v end })

tabs.World:AddToggle("SCPFullbright", { Title = "全亮", Default = false, Callback = function(v)
    if v and not world.Fullbright then captureLighting() end
    world.Fullbright = v
    if v then applyFullbright() else restoreLighting() end
end })
tabs.World:AddToggle("SCPAntiRagdoll", { Title = "反布娃娃", Default = false, Callback = function(v) world.AntiRagdoll = v end })
tabs.World:AddToggle("SCPAntiAFK", { Title = "反挂机", Default = true, Callback = function(v) world.AntiAFK = v end })
tabs.World:AddButton({ Title = "删除门", Callback = function()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if string.lower(obj.Name):find("door") then
            pcall(function() obj:Destroy() end)
        end
    end
end })
tabs.World:AddButton({ Title = "重新加入", Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end })
tabs.World:AddButton({ Title = "低延迟切服（通用）", Callback = function()
    if not ui.ServerSwitch then return end
    local ok, reason = ui.ServerSwitch:Switch()
    if not ok then ui:Notify({Title = "低延迟切服", Content = reason, Duration = 4}) end
end })

tabs.Info:AddToggle("SCPDebug", { Title = "调试输出", Default = false, Callback = function(v) common.Debug = v end })
tabs.Info:AddParagraph({ Title = "兼容性说明",
    Content = ("PlaceId %d / 构建 scp-v3。R15 与 R6 角色自适应；Drawing 缺失时线条停用、Chams 可独立工作；元表钩子缺失时静默瞄准自动停用；候选与绘制刷新率独立于帧率；触屏默认右侧按住。")
        :format(game.PlaceId) })
tabs.Info:AddButton({ Title = "子模块初始化诊断", Callback = function()
    pcall(function() ui:Notify({Title = "SCP 启动诊断",
        Content = #bootFailures > 0 and table.concat(bootFailures, " / ") or "模块工厂未报告失败；功能运行仍需实际测试", Duration = 6}) end)
end })
tabs.Info:AddButton({ Title = "检查运行状态", Callback = function()
    local caps = common.Caps or {}
    pcall(function()
        ui:Notify({ Title = "Vortexion SCP", Content = ("Drawing=%s 钩子=%s 鼠标=%s gethui=%s 目标=%d")
            :format(tostring(caps.Drawing or caps.DrawingUserdata), tostring(caps.hookmetamethod or caps.getrawmetatable),
                tostring(caps.mousemoverel), tostring(caps.gethui), #(Candidates:Get() or {})), Duration = 5 })
    end)
end })
tabs.Info:AddButton({ Title = "卸载全部 SCP 功能", Callback = function()
    cleanup()
    pcall(function() ui:Destroy() end)
end })
tabs.Info:AddButton({ Title = "一键恢复普通视角", Callback = function()
    if not isCurrent() then return end
    Camera.Config.Enabled = false
    pcall(function() Camera:ResetTrigger() end)
    pcall(function() Camera:Update(0) end)
    local aimOption = ui and ui.Options and ui.Options.SCPAimEnabled
    if aimOption and type(aimOption.SetValue) == "function" then pcall(function() aimOption:SetValue(false) end) end
    if not isCurrent() then return end
    local ready, cam, hum = pcall(function()
        local char = LocalPlayer and LocalPlayer.Character
        return Workspace.CurrentCamera, char and char:FindFirstChildWhichIsA("Humanoid")
    end)
    if not ready or not cam or not hum then
        pcall(function() ui:Notify({ Title = "Vortexion SCP", Content = "已关闭视角辅助；角色或相机尚未就绪", Duration = 4 }) end)
        return
    end
    local restored = pcall(function()
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    end)
    if not isCurrent() then return end
    pcall(function() ui:Notify({ Title = "Vortexion SCP", Content = restored and "已恢复普通视角" or "视角属性更新未完成", Duration = 4 }) end)
end })

tabs.Aim:AddDropdown("SCPTouchMode", { Title = "触屏触发方式", Values = { "Hold", "Toggle" }, Default = "Hold", Callback = function(v) Camera.Config.TouchMode = v if Camera.ResetTrigger then Camera:ResetTrigger() end end })
tabs.Aim:AddDropdown("SCPTouchRegion", { Title = "触屏区域（避开摇杆）", Values = { "Right", "Full" }, Default = "Right", Callback = function(v) common.Touch.Region = v end })
tabs.Aim:AddSlider("SCPAimAttraction", { Title = "鼠标吸附力度", Min = 10, Max = 100, Default = 60, Rounding = 0, Callback = function(v) Camera.Config.Attraction = v / 100 end })
tabs.Aim:AddToggle("SCPAimDampening", { Title = "近准星减速", Default = true, Callback = function(v) Camera.Config.Dampening = v end })
tabs.Aim:AddSlider("SCPTriggerInterval", { Title = "开火间隔 (ms)", Min = 100, Max = 1000, Default = 180, Rounding = 0, Callback = function(v) trigger.IntervalMs = v end })
tabs.Hitbox:AddSlider("SCPHitboxHeadScale", { Title = "头部独立倍率", Min = 10, Max = 30, Default = 10, Rounding = 0, Callback = function(v) Hitbox.Config.HeadScale = v / 10 end })
tabs.Hitbox:AddSlider("SCPHitboxTorsoScale", { Title = "躯干独立倍率", Min = 10, Max = 25, Default = 10, Rounding = 0, Callback = function(v) Hitbox.Config.TorsoScale = v / 10 end })
tabs.Visual:AddToggle("SCPESPLabels", { Title = "名字 / 距离", Default = false, Callback = function(v) ESP.Config.Labels = v end })
tabs.Visual:AddDropdown("SCPTracerOrigin", { Title = "射线起点", Values = { "Bottom", "Center" }, Default = "Bottom", Callback = function(v) ESP.Config.TracerOrigin = v end })
tabs.Visual:AddSlider("SCPESPRefresh", { Title = "绘制刷新率 (Hz)", Min = 5, Max = 60, Default = 20, Rounding = 0, Callback = function(v) ESP.Config.TickRate = v end })
tabs.Visual:AddSlider("SCPESPBudget", { Title = "显示目标上限", Min = 8, Max = 96, Default = 64, Rounding = 0, Callback = function(v) ESP.Config.MaxEntries = v end })
tabs.Move:AddSlider("SCPTouchDeadzone", { Title = "触屏拖动死区 (px)", Min = 5, Max = 50, Default = 10, Rounding = 0, Callback = function(v) Movement.Config.TouchDeadzone = v end })
tabs.Move:AddSlider("SCPTouchSensitivity", { Title = "满速拖动距离 (px)", Min = 40, Max = 240, Default = 120, Rounding = 0, Callback = function(v) Movement.Config.TouchSensitivity = v end })
tabs.Info:AddSlider("SCPCandidateRefresh", { Title = "候选刷新率 (Hz)", Min = 5, Max = 60, Default = 20, Rounding = 0, Callback = function(v) if Candidates.Config then Candidates.Config.TickRate = v end end })
tabs.Visual:AddToggle("SCPESPOffScreen", { Title = "屏外方向箭头", Default = false, Callback = function(v) ESP.Config.OffScreen = v if not v then ESP:Update(0) end end })
tabs.Visual:AddToggle("SCPESPOffScreenDistance", { Title = "屏外距离数字（需Drawing）", Default = false, Callback = function(v) ESP.Config.OffScreenDistance = v if not v then ESP:Update(0) end end })
tabs.Visual:AddSlider("SCPESPOffScreenBudget", { Title = "屏外目标独立上限", Min = 1, Max = 64, Default = 16, Rounding = 0, Callback = function(v) ESP.Config.MaxOffScreen = v end })
tabs.Visual:AddSlider("SCPESPOffScreenSize", { Title = "屏外箭头尺寸(px)", Min = 8, Max = 30, Default = 14, Rounding = 0, Callback = function(v)
    if not isCurrent() then return end
    local n = tonumber(v)
    if not n or n ~= n or math.abs(n) == math.huge then n = 14 end
    ESP.Config.OffScreenSize = math.floor(math.clamp(n, 8, 30) + 0.5)
end })
tabs.Visual:AddSlider("SCPESPOffScreenMargin", { Title = "屏外箭头边距(px)", Min = 8, Max = 80, Default = 28, Rounding = 0, Callback = function(v)
    if not isCurrent() then return end
    local n = tonumber(v)
    if not n or n ~= n or math.abs(n) == math.huge then n = 28 end
    ESP.Config.OffScreenMargin = math.floor(math.clamp(n, 8, 80) + 0.5)
end })
tabs.Visual:AddToggle("SCPESPNativeLabels", { Title = "原生标签（无 Drawing 可用）", Default = false, Callback = function(v) ESP.Config.NativeLabels = v if not v then ESP:Update(0) end end })
tabs.Visual:AddSlider("SCPESPLabelTextSize", { Title = "标签字号", Min = 10, Max = 28, Default = 14, Rounding = 0, Callback = function(v) ESP.Config.LabelTextSize = v end })
tabs.Visual:AddDropdown("SCPESPLabelFont", { Title = "原生标签字体", Values = { "GothamBold", "Gotham", "SourceSans", "Code" }, Default = "GothamBold", Callback = function(v) ESP.Config.LabelFont = v end })
tabs.Visual:AddToggle("SCPESPLabelStroke", { Title = "标签文字描边", Default = true, Callback = function(v) ESP.Config.LabelStroke = v end })
tabs.Visual:AddSlider("SCPESPLabelBackground", { Title = "原生标签背景透明度", Min = 0, Max = 100, Default = 100, Rounding = 0, Callback = function(v) ESP.Config.LabelBackgroundTransparency = v / 100 end })
tabs.Move:AddButton({ Title = "立即起跳", Callback = function() Movement:RequestJump(true) end })
tabs.Move:AddSlider("SCPTeleportDist", { Title = "前向传送距离 (studs)", Min = 10, Max = 200, Default = 50, Rounding = 0, Callback = function(v) Movement.Config.TeleportDistance = v end })
tabs.Move:AddButton({ Title = "向前传送", Callback = function() Movement:TeleportForward() end })

window:SelectTab(1)
pcall(function()
    ui:Notify({ Title = "Vortexion - SCP", Content = "模块已加载；进入场景后启用对应功能", Duration = 4 })
end)
common.Log("Core", "loaded place=" .. tostring(game.PlaceId) .. " gen=" .. tostring(generation))

end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "SCP")
end
