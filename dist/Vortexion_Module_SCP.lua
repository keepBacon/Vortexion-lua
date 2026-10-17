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
	Candidates.MAX_CANDIDATES = 56
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
	Candidates.Config = { TickRate = 30 }
    local function normalize(value)
        return tostring(value or ""):lower():gsub("[^%w]", "")
    end
    local function teamName(player)
        if not player then return "" end
        local team=player.Team
        return team and team.Name or player:GetAttribute("Team") or player:GetAttribute("Faction") or ""
    end
    function Candidates:GetSide(player)
        if not player then return "SCP" end
        local raw=normalize(teamName(player))
        if raw:find("chaos") or raw:find("insurgenc") or raw:find("hostile") then return "HOSTILE" end
        if raw:find("classd") or raw:find("prisoner") or raw:find("neutral") then return "NEUTRAL" end
        if raw:find("foundation") or raw:find("security") or raw:find("scientific")
            or raw:find("taskforce") or raw:find("intelligence") or raw:find("response")
            or raw:find("medical") or raw:find("administrative") or raw:find("o5") then
            return "FOUNDATION"
        end
        return "UNKNOWN"
    end
    -- UNKNOWN falls back to exact Team comparison; do not mark all unrecognized teams hostile.
    function Candidates:IsHostile(cand)
        if not cand.Player then return true end
        local targetSide=self:GetSide(cand.Player)
        local localSide=self:GetSide(Players.LocalPlayer)
        if targetSide=="NEUTRAL" or localSide=="NEUTRAL" then return false end
        if targetSide~="UNKNOWN" and localSide~="UNKNOWN" and localSide~="NEUTRAL" then
            return targetSide~=localSide
        end
        if cand.Player.Team and Players.LocalPlayer.Team then
            return cand.Player.Team~=Players.LocalPlayer.Team
        end
        return false
    end
    function Candidates:GetJob(cand)
        if not cand.Player then return "SCP收容体" end
        local player=cand.Player
        for _,attr in ipairs({"Job", "Role", "TeamRole", "Rank", "TeamRank", "Title"}) do
            local value=player:GetAttribute(attr)
            if type(value)=="string" and value~="" then return value end
        end
        local stats=player:FindFirstChild("leaderstats")
        if stats then
            for _,name in ipairs({"Rank","Role","Job"}) do
                local item=stats:FindFirstChild(name)
                if item and item:IsA("StringValue") and item.Value~="" then return item.Value end
            end
        end
        local name=teamName(player)
        return name~="" and tostring(name) or "未知职位"
    end
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
		local hrp = character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        local head = character:FindFirstChild("Head") or hrp
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
        for _,cand in ipairs(pool) do
            cand.AnchorScreen = Camera:WorldToViewportPoint(cand.Anchor.Position)
            cand.TopOnScreen = cand.AnchorScreen.Z>0
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
            -- A few SCP anomaly entities do not have a Humanoid. Include only
            -- explicitly named/tagged SCP Models with an immediate BasePart;
            -- do not treat arbitrary environmental props as NPCs.
            local labeledSCP = model.Name:lower():match("^scp[%s%-_]?%d+") ~= nil
                or model:GetAttribute("IsSCP") == true
            local customBody = false
            if labeledSCP and not humanoid then
                for _,child in ipairs(model:GetChildren()) do
                    if child:IsA("BasePart") then customBody = true break end
                end
            end
			if humanoid or customBody then Candidates.NPCs[model] = true end
		end

		local connAdded = Workspace.DescendantAdded:Connect(function(inst)
			if inst:IsA("Model") then consider(inst)
			elseif inst:IsA("Humanoid") and inst.Parent then consider(inst.Parent) end
		end)
		local connRemoved = Workspace.DescendantRemoving:Connect(function(inst)
			Candidates.NPCs[inst] = nil
			if inst:IsA("Humanoid") and inst.Parent then Candidates.NPCs[inst.Parent] = nil end
		end)
		-- R224: budgeted BFS avoids a blocking GetDescendants allocation on
		-- enormous SCP maps. Pause every 160 nodes (including non-NPC props).
		local stopped=false
		task.spawn(function()
			local queue={Workspace}
			local front,last=1,1
			while front<=last and not stopped do
				local node=queue[front]
				queue[front]=nil -- release processed scene references immediately
				front+=1
				if node then
					if node:IsA("Humanoid") and node.Parent then consider(node.Parent) end
					local ok,children=pcall(function()return node:GetChildren() end)
					if ok and children then
						for _,child in ipairs(children) do last+=1;queue[last]=child end
					end
				end
				if front%160==0 then task.wait() end
			end
		end)
		common.OnCleanup(function()
			stopped=true
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
		FOV = 240,
		MaxDistance = 700,
		WallCheck = true,
		TeamCheck = true,        -- R226: game has FOUNDATION / HOSTILE / NEUTRAL
		Smoothness = 0.85,        -- alpha = 1 - smoothness (0.15 -> gradual)
		Hitbox = "Head",          -- Head | Torso | Arms | Legs | Random
		Prediction = 0.12,        -- seconds of velocity extrapolation
		MaxAngle = 30,            -- degrees cone around look vector
		HitChance = 1,          -- per-acquisition roll
		FOVCircle = true,
		TriggerKey = common.Touch.Enabled and "Always" or "Right",     -- None | Left | Right | Touch | Always
		Attraction = 0.6,         -- mouse-mode pull multiplier
		Dampening = true,         -- ease off inside the dampening threshold
		TargetNPCs = true,
		TouchMode = "Hold",
	}
	Camera.Config = Config
    Camera.Stats={ Candidates=0, Rejected=0, Locked="", Reason="disabled" }

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
		if Config.TeamCheck and common.Candidates.IsHostile
            and not common.Candidates:IsHostile(cand) then
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
            Camera.Stats.Reason="disabled or no camera"
            Camera:ResetTrigger()
			clearHighlight()
			lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
			return nil
		end

        if not triggerHeld() then
            Camera.Stats.Reason="trigger not held"
            clearHighlight()
			lockedChar, lockedPlayer, lockedRegion = nil, nil, nil
			smoothedVelocity = Vector3.zero
			hitRoll = 1
			return nil
		end

		local cand = Camera:ResolveTarget()
        if not cand then
            Camera.Stats.Reason="no valid enemy in FOV / distance / visibility"
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
        Camera.Stats.Locked=cand.Player and cand.Player.Name or "SCP收容体"
        Camera.Stats.Reason="locked"

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
-- R232: SCP: Roleplay client-side hitbox adapter.
-- Independent of the crosshair candidate pool (which has a 56-target cap).
-- IMPORTANT: changing BasePart.Size on the client cannot enlarge the server's
-- authoritative hit registration. This adapter verifies LOCAL part writes and
-- optionally shows the enlarged local bounds; it does not claim server hits.
return function(common)
    local Players = common.Services.Players
    local Workspace = common.Services.Workspace
    local LocalPlayer = common.LocalPlayer or Players.LocalPlayer

    local Hitbox = {}
    local Config = {
        Enabled = false,
        Mode = "all", -- all / fullBody / lockedOnly
        ScaleMax = 1.8,
        HeadScale = 1,
        TorsoScale = 1,
        MaxDistance = 500,
        FOV = 600,
        UseFOV = false, -- mobile default: do not silently exclude side targets
        MaxActive = 8,
        TickRate = 12,
        GrowAlpha = 0.65,
        ShrinkAlpha = 0.7,
        PendingMs = 180,
        Transparency = 0.55,
        AnisoXZ = 1.0,
        AnisoY = 1.0,
        MaxEdge = 18,
        MaxRatio = 4,
        OnlyHostile = false,
        TargetNPCs = true,
        ShowBounds = true,
        BoundsColor = Color3.fromRGB(0, 195, 210),
        BoundsTransparency = 0.5,
    }
    Hitbox.Config = Config
    Hitbox.Stats = {
        Eligible = 0, Expanded = 0, PartsChanged = 0, Verified = 0,
        Preview = 0, Rejected = 0, ExternalResets = 0, LastError = "", Reason = "未开启",
        ServerVerified = false,
    }
    local states = {} -- key = Model; preserves original sizes across re-spawns
    local accumulator = 0
    local conns = {}

    local function isPart(inst)
        return inst and inst:IsA("BasePart") and inst.Parent ~= nil
    end
    local function findPart(model, names)
        for _,name in ipairs(names) do
            local part = model:FindFirstChild(name)
            if not part then part = model:FindFirstChild(name, true) end
            if isPart(part) then return part end
        end
        return nil
    end
    local function anchorFor(model)
        local anchor = findPart(model, {"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head"})
            or (isPart(model.PrimaryPart) and model.PrimaryPart or nil)
        if anchor then return anchor end
        -- Some SCP entities are custom Models without a PrimaryPart. Limit
        -- the fallback to direct children; never traverse the whole map.
        for _,child in ipairs(model:GetChildren()) do
            if isPart(child) then return child end
        end
        local nested = model:FindFirstChildWhichIsA("BasePart", true)
        return isPart(nested) and nested or nil
    end
    local function isAlive(model)
        if not model or not model.Parent then return false end
        if model:GetAttribute("Dead") == true then return false end
        local hp = model:GetAttribute("Health")
        if type(hp) == "number" and hp <= 0 then return false end
        local humanoid = model:FindFirstChildWhichIsA("Humanoid")
        return not humanoid or humanoid.Health > 0
    end
    local function targetsFor(model)
        local selected = {}
        local seen = {}
        local function add(part)
            if isPart(part) and not seen[part] then
                seen[part] = true
                selected[#selected + 1] = part
            end
        end
        for _,name in ipairs({"Head", "UpperTorso", "LowerTorso", "Torso"}) do
            add(findPart(model, {name}))
        end
        if Config.Mode == "fullBody" then
            for _,name in ipairs({
                "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
                "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
                "Left Arm", "Right Arm", "Left Leg", "Right Leg"
            }) do add(findPart(model, {name})) end
        end
        -- SCP custom entity models can lack Humanoid and standard torso names.
        -- Prefer their PrimaryPart as a bounded fallback, without touching
        -- HumanoidRootPart for standard player rigs (avoids physics instability).
        if #selected == 0 then add(anchorFor(model)) end
        return selected
    end
    local function multiplier(name, distance)
        local region = name == "Head" and Config.HeadScale
            or ((name == "Torso" or name == "UpperTorso" or name == "LowerTorso") and Config.TorsoScale or 1)
        local peak = math.max(1, Config.ScaleMax * region)
        local decay = math.clamp(1 - distance / math.max(1, Config.MaxDistance), 0, 1)
        return 1 + (peak - 1) * decay
    end
    local function expandedSize(original, part, distance)
        local factor = multiplier(part.Name, distance)
        local bounds = Vector3.new(
            original.X * factor * Config.AnisoXZ,
            original.Y * factor * Config.AnisoY,
            original.Z * factor * Config.AnisoXZ
        )
        return Vector3.new(
            math.max(original.X, math.min(bounds.X, original.X * Config.MaxRatio, Config.MaxEdge)),
            math.max(original.Y, math.min(bounds.Y, original.Y * Config.MaxRatio, Config.MaxEdge)),
            math.max(original.Z, math.min(bounds.Z, original.Z * Config.MaxRatio, Config.MaxEdge))
        )
    end
    local function removePreview(original)
        if original.preview then
            pcall(function() original.preview:Destroy() end)
            original.preview = nil
        end
    end
    local function restore(model)
        local state = states[model]
        if not state then return end
        for part,original in pairs(state.parts) do
            removePreview(original)
            if part.Parent then
                pcall(function()
                    part.Size = original.size
                    part.Transparency = original.transparency
                    part.CanCollide = original.canCollide
                end)
            end
        end
        states[model] = nil
    end
    local function createPreview(part, original)
        if original.preview or not Config.ShowBounds then return end
        local ok, adorn = pcall(function()
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "VortexionSCPHitboxBounds"
            box.Adornee = part
            box.AlwaysOnTop = true
            box.Color3 = Config.BoundsColor
            box.Transparency = Config.BoundsTransparency
            box.Size = part.Size
            box.Parent = part
            return box
        end)
        if ok then original.preview = adorn
        else Hitbox.Stats.LastError = "碰撞箱预览创建失败: " .. tostring(adorn) end
    end
    local function apply(model, parts, distance)
        local state = states[model]
        if not state then
            state = {parts = {}, lastSeen = os.clock()}
            states[model] = state
        end
        state.lastSeen = os.clock()
        local verified = 0
        for _,part in ipairs(parts) do
            local original = state.parts[part]
            if not original then
                original = {size = part.Size, transparency = part.Transparency, canCollide = part.CanCollide}
                state.parts[part] = original
            end
            local desired = expandedSize(original.size, part, distance)
            if original.lastApplied and (part.Size - original.size).Magnitude < 0.02
                and (original.lastApplied - original.size).Magnitude > 0.1 then
                Hitbox.Stats.ExternalResets += 1
            end
            local ok, err = pcall(function()
                part.Size = part.Size:Lerp(desired, Config.GrowAlpha)
                part.CanCollide = false
                part.Transparency = original.transparency + (Config.Transparency - original.transparency) * 0.35
            end)
            if ok then
                Hitbox.Stats.PartsChanged += 1
                original.lastApplied = part.Size
                if (part.Size - original.size).Magnitude > 0.025 then
                    verified += 1
                end
                if Config.ShowBounds then createPreview(part, original) else removePreview(original) end
                if original.preview then
                    pcall(function()
                        original.preview.Size = part.Size
                        original.preview.Color3 = Config.BoundsColor
                        original.preview.Transparency = Config.BoundsTransparency
                        original.preview.Visible = Config.ShowBounds
                    end)
                    Hitbox.Stats.Preview += 1
                end
            else
                Hitbox.Stats.LastError = "部件写入失败: " .. tostring(err)
                Hitbox.Stats.Rejected += 1
            end
        end
        return verified
    end
    local function addModel(list, model, owner, camera, origin, locked)
        if not isAlive(model) then return end
        if owner and owner.Character ~= model then return end
        if Config.OnlyHostile and common.Candidates and common.Candidates.IsHostile then
            if not common.Candidates:IsHostile({Player = owner, Character = model}) then return end
        end
        if Config.Mode == "lockedOnly" and (not locked or locked.Character ~= model) then return end
        local anchor = anchorFor(model)
        if not anchor then return end
        local distance = (anchor.Position - origin).Magnitude
        if distance > Config.MaxDistance then return end
        local screen, onScreen = camera:WorldToViewportPoint(anchor.Position)
        if not onScreen and screen.Z <= 0 then return end
        local center = camera.ViewportSize * 0.5
        if Config.UseFOV and (Vector2.new(screen.X, screen.Y) - center).Magnitude > Config.FOV then return end
        local parts = targetsFor(model)
        if #parts == 0 then return end
        list[#list + 1] = { model = model, parts = parts, distance = distance }
    end
    local function gather()
        local camera = Workspace.CurrentCamera
        if not camera then return {}, "摄像机未就绪" end
        local localChar = LocalPlayer and LocalPlayer.Character
        local localRoot = localChar and anchorFor(localChar)
        local origin = localRoot and localRoot.Position or camera.CFrame.Position
        local locked = common.Camera and common.Camera.GetCurrentTarget and common.Camera:GetCurrentTarget()
        local eligible = {}
        for _,player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                addModel(eligible, player.Character, player, camera, origin, locked)
            end
        end
        if Config.TargetNPCs and common.Candidates and common.Candidates.NPCs then
            for model in pairs(common.Candidates.NPCs) do
                if model ~= localChar and model.Parent and not Players:GetPlayerFromCharacter(model) then
                    addModel(eligible, model, nil, camera, origin, locked)
                end
            end
        end
        table.sort(eligible, function(a,b) return a.distance < b.distance end)
        return eligible, #eligible == 0 and "没有符合距离/FOV/阵营的目标" or "正常"
    end
    function Hitbox:GetEnvelope(part)
        for _,state in pairs(states) do
            local original = state.parts[part]
            if original then return original.size end
        end
        return part.Size
    end
    function Hitbox:GetEnvelopeMargin(part)
        return self:GetEnvelope(part) * 0.5 + Vector3.new(0.5, 0.5, 0.5)
    end
    function Hitbox:Cleanup()
        local keys = {}
        for model in pairs(states) do keys[#keys + 1] = model end
        for _,model in ipairs(keys) do restore(model) end
        Hitbox.Stats.Expanded, Hitbox.Stats.Preview = 0, 0
    end
    function Hitbox:Update(dt)
        if not Config.Enabled then
            self:Cleanup()
            accumulator = 0
            Hitbox.Stats.Reason = "未开启"
            return
        end
        accumulator += (dt or 0)
        local interval = 1 / math.clamp(Config.TickRate, 1, 60)
        if accumulator < interval then return end
        accumulator %= interval
        local eligible, reason = gather()
        Hitbox.Stats.Eligible = #eligible
        Hitbox.Stats.Reason = reason
        Hitbox.Stats.PartsChanged, Hitbox.Stats.Verified = 0, 0
        Hitbox.Stats.Preview, Hitbox.Stats.Rejected = 0, 0
        local active = {}
        local count = 0
        for _,item in ipairs(eligible) do
            if count >= Config.MaxActive then break end
            count += 1
            active[item.model] = true
            Hitbox.Stats.Verified += apply(item.model, item.parts, item.distance)
        end
        Hitbox.Stats.Expanded = count
        local expired = {}
        for model,state in pairs(states) do
            if not active[model] and (not model.Parent or (os.clock() - state.lastSeen) * 1000 > Config.PendingMs) then
                expired[#expired + 1] = model
            end
        end
        for _,model in ipairs(expired) do restore(model) end
        if count > 0 and Hitbox.Stats.Verified == 0 then
            Hitbox.Stats.Reason = "已选中目标，但本地尺寸未变化（被还原或尺寸受限）"
        end
    end
    conns[#conns+1] = Players.PlayerRemoving:Connect(function(player)
        if player.Character then restore(player.Character) end
    end)
    conns[#conns+1] = Workspace.DescendantRemoving:Connect(function(inst)
        if states[inst] then restore(inst) end
    end)
    common.OnCleanup(function()
        Hitbox:Cleanup()
        for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
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
-- R226: native, pooled SCP collision-envelope ESP.
-- 3D: BoxHandleAdornment (engine tracks part transforms without Lua projection).
-- 2D: ScreenGui+UIStroke frames, projected only on a bounded refresh beat.
-- No Drawing API, global hooks, per-frame Workspace scans or per-tick allocations.
return function(common)
    local Workspace = common.Services.Workspace
    local Players = common.Services.Players
    local Config = {
        Enabled = false, Style = "3D", Box = true, Labels = true, ShowNames = true,
        NameFormat = "用户名", ShowJob = false, OnlyHostile = false,
        TargetNPCs = true, TeamCheck = false, MaxDistance = 850,
        MaxEntries = 36, TickRate = 20,
        Transparency3D = 0.30, Transparency2D = 0.15,
        BoxThickness = 1.6, NameSize = 14, JobSize = 13,
        LabelOffset = 2.4, ShowDistance = false, ShowHealth = false,
        JobTeamColor = true, JobTranslate = true,
        ColorEnemy = Color3.fromRGB(245, 80, 80),
        ColorAlly = Color3.fromRGB(75, 175, 225),
        ColorSCP = Color3.fromRGB(0, 0, 0),
        ColorLowHealth = Color3.fromRGB(255, 160, 0),
        Health = false, Skeleton = false, Tracer = false,
        Chams = false, OffScreen = false, NativeLabels = true,
    }
    local ESP = { Config = Config, Stats = { Seen = 0, Visible = 0, Ms = 0, Hz = 20, Failures = 0 } }
    local entries = {}
    local screen, layer, accumulator, lastCamera = nil, nil, 0, nil
    local stopped, serial, avg = false, 0, 0
    local wasEnabled = false
    local function dispose(entry)
        for _, component in ipairs(entry.parts or {}) do
            if component.adorn then pcall(function() component.adorn:Destroy() end) end
            if component.frame then pcall(function() component.frame:Destroy() end) end
        end
        if entry.label then pcall(function() entry.label:Destroy() end) end
    end
    local function hide(entry)
        for _, component in ipairs(entry.parts or {}) do
            if component.adorn then component.adorn.Visible = false end
            if component.frame then component.frame.Visible = false end
        end
        if entry.label then entry.label.Enabled = false end
    end
    local function clear()
        for key,entry in pairs(entries) do dispose(entry); entries[key]=nil end
    end
    local function mountScreen()
        if screen and screen.Parent then return screen end
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionSCPESP2D"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 940
        local parent = common.GetGuiParent and common.GetGuiParent()
        if not parent then
            parent = common.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end
        if not parent then gui:Destroy() return nil end
        local ok = pcall(function() gui.Parent=parent end)
        if not ok then gui:Destroy() return nil end
        screen = gui
        return screen
    end
    -- SCP: Roleplay community team/rank vocabulary. Unmapped values remain original.
    local ROLE_ZH = {
        ["Class-D"]="D级人员", ["Class - D"]="D级人员", ["Class D"]="D级人员",
        ["Chaos Insurgency"]="混沌分裂者", ["Scientific Department"]="科研部",
        ["Security Department"]="安保部", ["Medical Department"]="医疗部",
        ["Administrative Department"]="行政部", ["Intelligence Agency"]="情报局",
        ["Internal Security Department"]="内部安全部",
        ["Rapid Response Team"]="快速反应部队", ["Mobile Task Forces"]="机动特遣队",
        ["Mobile Task Force"]="机动特遣队", ["O5 Council"]="O5议会",
        ["Foundation"]="基金会", ["Neutral"]="中立", ["Hostile"]="敌对",
        ["Recruit"]="新兵", ["Cadet"]="学员", ["Private"]="列兵",
        ["Corporal"]="下士", ["Sergeant"]="中士", ["Staff Sergeant"]="上士",
        ["Lieutenant"]="中尉", ["Captain"]="上尉", ["Commander"]="指挥官",
        ["Director"]="主管", ["Deputy Director"]="副主管",
        ["Supervisor"]="监督员", ["Special Agent"]="特工",
        ["Entry Agent"]="初级特工", ["Internal Agent"]="内部特工",
        ["Senior Supervisor"]="高级监督员", ["Lead Supervisor"]="首席监督员",
        ["Researcher"]="研究员", ["Junior Researcher"]="初级研究员",
        ["Senior Researcher"]="高级研究员", ["Intern"]="实习生",
        ["Doctor"]="医生", ["Nurse"]="护士", ["Veteran Class - D"]="资深D级人员",
        ["Conscript"]="征召兵", ["Trained Conscript"]="训练征召兵",
        ["Senior Conscript"]="高级征召兵", ["Alpha"]="阿尔法",
        ["Nu-7"]="Nu-7机动特遣队", ["Epsilon-11"]="Epsilon-11机动特遣队",
        ["Beta-7"]="Beta-7机动特遣队", ["Alpha-1"]="Alpha-1机动特遣队",
        ["Dedicated Class - D"]="资深D级人员", ["Adept Class - D"]="熟练D级人员",
        ["Advanced Class - D"]="高级D级人员", ["Board Director"]="董事会主管",
        ["Head Researcher"]="首席研究员", ["Trainee Researcher"]="见习研究员",
        ["General"]="将军", ["Major"]="少校", ["Colonel"]="上校",
        ["Task Force Leader"]="特遣队队长", ["Head Commander"]="总指挥官",
        ["Insurgency Command"]="叛乱指挥官", ["The Engineer"]="工程师",
        ["Intelligence Director"]="情报局局长", ["Internal Security Manager"]="内部安全经理",
        ["Medical Director"]="医疗部主管", ["Site Manager"]="站点经理",
        ["Junior Manager"]="初级经理", ["Senior Manager"]="高级经理",
        ["Site Assistant Manager"]="站点助理经理", ["Site Senior Manager"]="站点高级经理",
        ["Site Director"]="站点主管", ["Site Council"]="站点议会",
        ["Administrative Council"]="行政议会", ["Administrative Regulator"]="行政监察员",
    }
    local function translatedRank(raw)
        if not Config.JobTranslate then return raw end
        if ROLE_ZH[raw] then return ROLE_ZH[raw] end
        local normalized=tostring(raw):gsub("^%s+",""):gsub("%s+$","")
        return ROLE_ZH[normalized] or normalized
    end
    local function roleColor(player)
        if not player then return Config.ColorSCP end
        if not Config.JobTeamColor then return Config.ColorAlly end
        -- Prefer explicit live role color when a game version provides it.
        for _,key in ipairs({"JobColor", "RoleColor", "RankColor", "TeamColor"}) do
            local ok,value=pcall(function()return player:GetAttribute(key)end)
            if ok and typeof(value)=="Color3" then return value end
        end
        local team=player.Team
        if team then
            local ok,color=pcall(function()return team.TeamColor.Color end)
            if ok and typeof(color)=="Color3" then return color end
        end
        return Config.ColorAlly
    end
    local function role(player, cand)
        if not player then return "SCP收容体" end
        if common.Candidates and common.Candidates.GetJob then
            return translatedRank(common.Candidates:GetJob(cand))
        end
        return translatedRank(player.Team and player.Team.Name or "未知职位")
    end
    local function displayName(player,cand)
        if not Config.ShowNames then return "" end
        if not player then return "SCP收容体" end
        local name=(Config.NameFormat=="实体名" and cand.Character and cand.Character.Name) or player.Name
        return tostring(name or "")
    end
    local function labelExtra(cand)
        local info={}
        if Config.ShowDistance then
            info[#info+1] = tostring(math.floor(cand.WorldDistance or 0)) .. " studs"
        end
        if Config.ShowHealth and cand.Humanoid then
            local hp=math.max(0,math.floor(cand.Humanoid.Health or 0))
            local max=math.max(1,math.floor(cand.Humanoid.MaxHealth or 100))
            info[#info+1] = ("%d/%d HP"):format(hp,max)
        end
        return table.concat(info, " · ")
    end
    local function attachLabel(entry, head)
        if entry.label then return end
        local gui=Instance.new("BillboardGui")
        gui.Name="SCPLabel"
        gui.Size=UDim2.fromOffset(260,72)
        gui.StudsOffsetWorldSpace=Vector3.new(0,Config.LabelOffset,0)
        gui.AlwaysOnTop=true
        gui.ResetOnSpawn=false
        gui.Adornee=head
        local function addLine(name)
            local text=Instance.new("TextLabel")
            text.Name=name
            text.Size=UDim2.new(1,0,0,21)
            text.BackgroundTransparency=1
            text.Font=Enum.Font.GothamBold
            text.TextScaled=false
            text.TextSize=14
            text.TextStrokeTransparency=Config.LabelStroke == false and 1 or 0.2
            text.TextStrokeColor3=Color3.fromRGB(10,15,18)
            text.TextTruncate=Enum.TextTruncate.AtEnd
            if Config.LabelFont and Enum.Font[Config.LabelFont] then text.Font=Enum.Font[Config.LabelFont] end
            text.Parent=gui
            return text
        end
        local nameText=addLine("ESPName")
        local jobText=addLine("ESPJob")
        local metaText=addLine("ESPMeta")
        metaText.TextSize=12
        local parent=mountScreen()
        if not parent then gui:Destroy() return end
        gui.Parent=parent
        entry.label,entry.text,entry.roleText,entry.metaText=gui,nameText,jobText,metaText
    end
    local function discoverParts(cand)
        local model=cand.Character
        local parts={}
        local head=model:FindFirstChild("Head")
        if head and head:IsA("BasePart") then parts[#parts+1]=head end
        local torso=model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
            or model:FindFirstChild("HumanoidRootPart")
        if torso and torso:IsA("BasePart") and torso~=head then parts[#parts+1]=torso end
        -- SCP variants may lack a traditional rig.
        if #parts==0 and cand.HRP and cand.HRP:IsA("BasePart") then parts[1]=cand.HRP end
        return parts
    end
    local function construct(cand)
        local key=cand.Character
        local entry=entries[key]
        if entry then return entry end
        entry={parts={},character=key}
        entries[key]=entry
        for _, part in ipairs(discoverParts(cand)) do
            entry.parts[#entry.parts+1]={part=part}
        end
        return entry
    end
    local function ensureAdornment(component)
        if component.adorn and component.adorn.Parent then return component.adorn end
        local part=component.part
        if not part or not part.Parent then return nil end
        local adorn=Instance.new("BoxHandleAdornment")
        adorn.Name="SCP3DCollisionBox"
        adorn.Adornee=part
        adorn.Size=part.Size
        adorn.AlwaysOnTop=true
        adorn.ZIndex=4
        adorn.Transparency=Config.Transparency3D
        adorn.Visible=false
        adorn.Parent=screen or mountScreen() or part
        component.adorn=adorn
        return adorn
    end
    local function ensureFrame(component)
        if component.frame and component.frame.Parent then return component.frame end
        local gui=mountScreen()
        if not gui then return nil end
        local frame=Instance.new("Frame")
        frame.Name="SCP2DCollisionBox"
        frame.BackgroundTransparency=1
        frame.BorderSizePixel=0
        frame.Visible=false
        local stroke=Instance.new("UIStroke")
        stroke.Thickness=Config.BoxThickness
        stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        stroke.Parent=frame
        frame.Parent=gui
        component.frame,component.stroke=frame,stroke
        return frame
    end
    -- Exact projected rectangle of an oriented BasePart, not a guessed player height.
    local function projectBounds(cam,part)
        local cf,sz=part.CFrame,part.Size*0.5
        local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
        local hasFront=false
        for sx=-1,1,2 do for sy=-1,1,2 do for szSign=-1,1,2 do
            local world=cf:PointToWorldSpace(Vector3.new(sz.X*sx,sz.Y*sy,sz.Z*szSign))
            local p=cam:WorldToViewportPoint(world)
            if p.Z>0.05 then
                hasFront=true
                left=math.min(left,p.X);right=math.max(right,p.X)
                top=math.min(top,p.Y);bottom=math.max(bottom,p.Y)
            end
        end end end
        if not hasFront or right-left<2 or bottom-top<2 then return nil end
        local v=cam.ViewportSize
        if right<0 or bottom<0 or left>v.X or top>v.Y then return nil end
        return left,top,right,bottom
    end
    function ESP:Update(dt)
        if stopped then return end
        if not Config.Enabled or (not Config.Box and not Config.ShowNames and not Config.ShowJob and not Config.ShowDistance and not Config.ShowHealth) then
            if wasEnabled then
                for _,entry in pairs(entries) do hide(entry) end
                wasEnabled=false
            end
            return
        end
        wasEnabled=true
        local cam=Workspace.CurrentCamera
        if not cam then return end
        accumulator += dt or 1/60
        local minHz=math.clamp(tonumber(Config.TickRate) or 20,8,30)
        local interval=1/minHz
        if avg>3 then interval=math.max(interval,1/12) end
        if common.VisualInterval then interval=common.VisualInterval(interval) end
        if accumulator<interval and cam==lastCamera then return end
        lastCamera=cam
        accumulator=0
        serial+=1
        local start=os.clock()
        local visible=0
        local roster=common.Candidates:Get()
        local seen=0
        for _,cand in ipairs(roster) do
            seen+=1
            if visible>=Config.MaxEntries then break end
            local character=cand.Character
            if not (character and character.Parent and cand.Humanoid and cand.Humanoid.Health>0) then continue end
            if not cand.Player and not Config.TargetNPCs then continue end
            if Config.OnlyHostile and common.Candidates.IsHostile and not common.Candidates:IsHostile(cand) then continue end
            if cand.WorldDistance>Config.MaxDistance then continue end
            local anchor=cand.Anchor
            if not anchor or not anchor.Parent then continue end
            local projected=cam:WorldToViewportPoint(anchor.Position)
            if projected.Z<=0 then continue end
            local entry=construct(cand)
            entry.seen=serial
            visible+=1
            local color = not cand.Player and Config.ColorSCP
                or ((common.Candidates.IsHostile and common.Candidates:IsHostile(cand)) and Config.ColorEnemy or Config.ColorAlly)
            local mode=Config.Style
            for _,component in ipairs(entry.parts) do
                local part=component.part
                if part and part.Parent then
                    if mode=="3D" then
                        if component.frame then component.frame.Visible=false end
                        local adorn=ensureAdornment(component)
                        if adorn then
                            adorn.Adornee=part
                            if adorn.Size~=part.Size then adorn.Size=part.Size end
                            adorn.Color3=color
                            adorn.Transparency=Config.Transparency3D
                            adorn.Visible=Config.Box
                        end
                    else
                        if component.adorn then component.adorn.Visible=false end
                        local frame=ensureFrame(component)
                        if frame then
                            local x,y,rx,by=projectBounds(cam,part)
                            if x then
                                frame.Position=UDim2.fromOffset(x,y)
                                frame.Size=UDim2.fromOffset(rx-x,by-y)
                                component.stroke.Color=color
                                component.stroke.Transparency=Config.Transparency2D
                                component.stroke.Thickness=Config.BoxThickness
                                frame.Visible=Config.Box
                            else frame.Visible=false end
                        end
                    end
                end
            end
            local nameText=displayName(cand.Player,cand)
            local jobText=(Config.ShowJob and cand.Player) and role(cand.Player,cand) or ""
            local metaText=labelExtra(cand)
            if (nameText~="" or jobText~="" or metaText~="") and cand.Head then
                attachLabel(entry,cand.Head)
                if entry.label then
                    entry.label.Adornee=cand.Head
                    entry.label.Enabled=true
                    entry.label.StudsOffsetWorldSpace=Vector3.new(0,Config.LabelOffset,0)
                    local y=0
                    for _,line in ipairs({
                        {entry.text,nameText,Config.NameSize,color},
                        {entry.roleText,jobText,Config.JobSize,roleColor(cand.Player)},
                        {entry.metaText,metaText,math.max(10,Config.JobSize-2),color},
                    }) do
                        local label,text,size,tint=line[1],line[2],line[3],line[4]
                        label.Visible=text~=""
                        if label.Visible then
                            label.Position=UDim2.fromOffset(0,y)
                            label.Size=UDim2.new(1,0,0,size+4)
                            label.TextSize=size
                            label.TextStrokeTransparency=Config.LabelStroke == false and 1 or 0.2
                            if Config.LabelFont and Enum.Font[Config.LabelFont] then label.Font=Enum.Font[Config.LabelFont] end
                            label.Text=text
                            label.TextColor3=tint
                            y+=size+4
                        end
                    end
                    entry.label.Size=UDim2.fromOffset(260,math.max(y,18))
                end
            elseif entry.label then entry.label.Enabled=false end
        end
        for key,entry in pairs(entries) do
            if entry.seen~=serial or not key.Parent then
                -- Keep no stale ESP references after death, cull or team changes.
                dispose(entry);entries[key]=nil
            end
        end
        local elapsed=(os.clock()-start)*1000
        avg=avg==0 and elapsed or (avg*.8+elapsed*.2)
        ESP.Stats={Seen=seen,Visible=visible,Ms=elapsed,AverageMs=avg,Hz=1/interval,
            Mode=Config.Style,Failures=ESP.Stats.Failures or 0}
    end
    function ESP:Cleanup()
        if stopped then return end
        stopped=true
        clear()
        if screen then pcall(function()screen:Destroy()end) end
        screen=nil
    end
    common.OnCleanup(function()ESP:Cleanup()end)
    return ESP
end

end)()
local SCPInteractFactory = (function()
-- R226 instant prompt: event-driven HoldDuration=0, never spam remote calls.
-- Server validation, range and authorization are not bypassed.
return function(common)
    local promptService=game:GetService("ProximityPromptService")
    local Interact={Config={Enabled=false},Stats={Modified=0,Triggered=0,Visible=0}}
    local originals={}
    local shown={}
    local conns={}
    local function modify(prompt)
        if not prompt or not prompt.Parent or not prompt:IsA("ProximityPrompt") then return end
        if originals[prompt]==nil then originals[prompt]=prompt.HoldDuration end
        local ok=pcall(function()prompt.HoldDuration=0 end)
        if ok then Interact.Stats.Modified+=1 end
    end
    local function restore(prompt)
        local orig=originals[prompt]
        if orig~=nil then
            pcall(function()if prompt.Parent then prompt.HoldDuration=orig end end)
            originals[prompt]=nil
        end
    end
    function Interact:SetEnabled(value)
        self.Config.Enabled=value==true
        for prompt in pairs(shown) do
            if self.Config.Enabled then modify(prompt) else restore(prompt) end
        end
    end
    conns[#conns+1]=promptService.PromptShown:Connect(function(prompt)
        shown[prompt]=true
        if Interact.Config.Enabled then modify(prompt) end
        local count=0 for _ in pairs(shown) do count+=1 end
        Interact.Stats.Visible=count
    end)
    conns[#conns+1]=promptService.PromptHidden:Connect(function(prompt)
        shown[prompt]=nil
        restore(prompt)
        local count=0 for _ in pairs(shown) do count+=1 end
        Interact.Stats.Visible=count
    end)
    conns[#conns+1]=promptService.PromptTriggered:Connect(function()
        if Interact.Config.Enabled then Interact.Stats.Triggered+=1 end
    end)
    function Interact:Cleanup()
        for _,conn in ipairs(conns) do pcall(function()conn:Disconnect()end) end
        for prompt in pairs(originals) do restore(prompt) end
        table.clear(shown)
    end
    common.OnCleanup(function()Interact:Cleanup()end)
    return Interact
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
-- R224: a UI constructor or Page registration may fail on an unsupported
-- Android executor. Fail closed with a readable bootstrap reason rather than
-- allowing the entire SCP entrypoint to abort halfway through initialization.
local windowOK, windowResult = pcall(function()
    return ui:CreateWindow({ Title = "Vortexion | SCP", Size = UDim2.fromOffset(790, 590) })
end)
if not windowOK or type(windowResult) ~= "table" or type(windowResult.AddTab) ~= "function" then
    local detail = windowOK and "invalid UI window" or tostring(windowResult)
    global.VortexionBootError = "SCP UI Window: " .. detail
    warn("[Vortexion/SCP] UI window unavailable: " .. detail)
    pcall(function() ui:Destroy() end)
    cleanup()
    return
end
local window = windowResult
ui:OnDestroy(cleanup)
local tabsOK, tabsResult = pcall(function()
    return {
        Aim = window:AddTab({ Title = "自瞄", Icon = "lucide-crosshair" }),
        Silent = window:AddTab({ Title = "静默", Icon = "lucide-target" }),
        Hitbox = window:AddTab({ Title = "碰撞箱", Icon = "lucide-box" }),
        Visual = window:AddTab({ Title = "视觉", Icon = "lucide-eye" }),
        Move = window:AddTab({ Title = "移动", Icon = "lucide-activity" }),
        World = window:AddTab({ Title = "世界", Icon = "lucide-globe" }),
        Info = window:AddTab({ Title = "信息", Icon = "lucide-info" }),
    }
end)
if not tabsOK or type(tabsResult) ~= "table" then
    local detail = tabsOK and "invalid page registry" or tostring(tabsResult)
    global.VortexionBootError = "SCP UI Pages: " .. detail
    warn("[Vortexion/SCP] UI pages unavailable: " .. detail)
    pcall(function() ui:Destroy() end)
    cleanup()
    return
end
local tabs = tabsResult

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
-- R224: never install global __namecall interception during SCP bootstrap.
-- Previous code hooked the entire game BEFORE UI/render setup; on some
-- executors this is a process-level crash, not a catchable Luau exception.
-- Runtime hooking is optional and is not a prerequisite for ESP/UI startup.
common.CloakStatus = "disabled by default (safe bootstrap)"
common.Candidates = setup("candidates", SCPCandidatesFactory) or { Update = function() end, Get = function() return {} end, NPCs = nil }
common.Camera = setup("camera", SCPCameraFactory) or { Update = function() end, GetCurrentTarget = function() end, Config = { Enabled = false } }
common.SilentAim = setup("silentaim", SCPSilentAimFactory) or { Update = function() end, Config = { Enabled = false } }
common.Hitbox = setup("hitbox", SCPHitboxFactory) or { Update = function() end, Config = { Enabled = false } }
common.Movement = setup("movement", SCPMovementFactory) or { Update = function() end, Start = function() end, Config = { SpeedEnabled = false } }
common.ESP = setup("esp", SCPESPFactory) or { Update = function() end, Config = { Enabled = false } }
common.Interact = (type(SCPInteractFactory)=="function" and setup("interact", SCPInteractFactory)) or {SetEnabled=function()end,Stats={Visible=0}}

local Camera = common.Camera
local SilentAim = common.SilentAim
local Hitbox = common.Hitbox
local Movement = common.Movement
local ESP = common.ESP
local Interact = common.Interact
local Candidates = common.Candidates
if type(ui.RegisterFeatureHealth) == "function" then
    ui:RegisterFeatureHealth("SCP", function()
        local frame = Candidates and Candidates.Frame or 0
        return ("存活=%s 角色=%s 候选扫描=%s 模块失败=%d")
            :format(tostring(isCurrent()), tostring(LocalPlayer.Character ~= nil),
                tostring(frame), #bootFailures)
    end)
end


--=========================================================================
-- NPC scan: SCP roleplay populates the map with humanoid NPCs; without the
-- scanner they are invisible to every targeting feature.
--=========================================================================
task.defer(function()
    if isCurrent() then
        common.Guard("Candidates", function()
            if Candidates.StartNPCScan then Candidates:StartNPCScan() end
        end)
    end
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

-- R232: hitbox evaluation is independent of the render/ESP loop. On mobile,
-- RenderStep can be paused/rebound while Heartbeat continues updating parts.
local hitboxOnHeartbeat = false
local heartbeatOk, heartbeatConn = pcall(function()
    return RunService.Heartbeat:Connect(function(dt)
        if not isCurrent() or not Hitbox.Config or not Hitbox.Config.Enabled then return end
        common.Guard("HitboxHeartbeat", function() Hitbox:Update(dt) end)
    end)
end)
if heartbeatOk and heartbeatConn then
    hitboxOnHeartbeat = true
    ownConnection(heartbeatConn)
end
local renderName = "VortexionSCPFrame"
local function renderFrame(dt)
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


        -- R226: keep idle frame cost near zero. Each disabled module's toggle
        -- synchronously calls its own reset/restore entrypoint.
        local needCandidates = (Camera.Config and Camera.Config.Enabled)
            or (SilentAim.Config and SilentAim.Config.Enabled)
            -- R232 hitbox has its own roster; avoid expensive duplicate scan.
            or (ESP.Config and ESP.Config.Enabled)
        local t0=tick()
        if needCandidates then common.Guard("Candidates", function() Candidates:Update(dt) end) end
        costs.Candidates=needCandidates and (tick()-t0)*1000 or 0
        t0=tick()
        if Camera.Config and Camera.Config.Enabled then
            common.Guard("Camera", function() Camera:Update(dt) end)
        end
        costs.Aim=(Camera.Config and Camera.Config.Enabled) and (tick()-t0)*1000 or 0
        if SilentAim.Config and SilentAim.Config.Enabled then
            common.Guard("SilentAim", function() SilentAim:Update() end)
        end
        t0=tick()
        if not hitboxOnHeartbeat and Hitbox.Config and Hitbox.Config.Enabled then
            common.Guard("Hitbox", function() Hitbox:Update(dt) end)
        end
        costs.Hitbox=(Hitbox.Config and Hitbox.Config.Enabled and not hitboxOnHeartbeat) and (tick()-t0)*1000 or 0
        t0=tick()
        if ESP.Config and ESP.Config.Enabled then
            common.Guard("ESP", function() ESP:Update(dt) end)
        end
        costs.ESP=(ESP.Config and ESP.Config.Enabled) and (tick()-t0)*1000 or 0
        if trigger.Enabled or trigger.firing then common.Guard("Trigger", updateTrigger) end

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
end
local renderOk,renderErr=pcall(function()
    RunService:BindToRenderStep(renderName, Enum.RenderPriority.Last.Value, renderFrame)
end)
if not renderOk then
    reportBootFailure("render", renderErr)
    ownConnection(RunService.RenderStepped:Connect(renderFrame))
else
    ownCleanup(function() pcall(function() RunService:UnbindFromRenderStep(renderName) end) end)
end
ownCleanup(function() if trigger.firing then mouseUp() trigger.firing = false end end)

--=========================================================================
-- UI wiring.
--=========================================================================
tabs.Aim:AddToggle("SCPAimEnabled", { Title = "自瞄总开关", Default = false, Callback = function(v) Camera.Config.Enabled = v if not v then Camera:Update(0) end end })
tabs.Aim:AddDropdown("SCPAimMode", { Title = "模式", Values = { "Camera", "Mouse", "Both" }, Default = "Camera", Callback = function(v) Camera.Config.Mode = v end })
tabs.Aim:AddSlider("SCPAimFov", { Title = "FOV (px)", Min = 20, Max = 650, Default = 240, Rounding = 0, Callback = function(v) Camera.Config.FOV = v end })
tabs.Aim:AddSlider("SCPAimDist", { Title = "最大距离 (studs)", Min = 50, Max = 2000, Default = 700, Rounding = 0, Callback = function(v) Camera.Config.MaxDistance = v end })
tabs.Aim:AddSlider("SCPAimSmooth", { Title = "平滑度", Min = 50, Max = 99, Default = 85, Rounding = 0, Callback = function(v) Camera.Config.Smoothness = v / 100 end })
tabs.Aim:AddDropdown("SCPAimPart", { Title = "部位", Values = { "Head", "Torso", "Arms", "Legs", "Random" }, Default = "Head", Callback = function(v) Camera.Config.Hitbox = v end })
tabs.Aim:AddSlider("SCPAimAngle", { Title = "最大夹角 (度)", Min = 5, Max = 90, Default = 30, Rounding = 0, Callback = function(v) Camera.Config.MaxAngle = v end })
tabs.Aim:AddSlider("SCPAimPrediction", { Title = "预瞄", Min = 0, Max = 50, Default = 12, Rounding = 0, Callback = function(v) Camera.Config.Prediction = v / 100 end })
tabs.Aim:AddSlider("SCPAimHitChance", { Title = "锁定命中率", Min = 10, Max = 100, Default = 100, Rounding = 0, Callback = function(v) Camera.Config.HitChance = v / 100 end })
tabs.Aim:AddToggle("SCPAimWall", { Title = "遮挡检查", Default = true, Callback = function(v) Camera.Config.WallCheck = v end })
tabs.Aim:AddToggle("SCPAimTeam", { Title = "只锁定敌对阵营", Default = true, Callback = function(v) Camera.Config.TeamCheck = v end })
tabs.Aim:AddToggle("SCPAimNPC", { Title = "锁定 NPC", Default = true, Callback = function(v) Camera.Config.TargetNPCs = v end })
tabs.Aim:AddDropdown("SCPAimKey", { Title = "触发键", Values = { "Right", "Left", "None", "Touch", "Always" }, Default = Camera.Config.TriggerKey or "Always", Callback = function(v) Camera.Config.TriggerKey = v if Camera.ResetTrigger then Camera:ResetTrigger() end end })
tabs.Aim:AddToggle("SCPAimFovCircle", { Title = "FOV 圈", Default = true, Callback = function(v) Camera.Config.FOVCircle = v end })
tabs.Aim:AddToggle("SCPTrigger", { Title = "自动开火（锁定时）", Default = false, Callback = function(v) trigger.Enabled = v if not v then updateTrigger() end end })

tabs.Silent:AddToggle("SCPSilentEnabled", { Title = "静默瞄准总开关", Default = false, Callback = function(v) SilentAim.Config.Enabled = v end })
tabs.Silent:AddSlider("SCPSilentAngle", { Title = "最大夹角 (度)", Min = 5, Max = 60, Default = 15, Rounding = 0, Callback = function(v) SilentAim.Config.MaxAngle = v end })
tabs.Silent:AddSlider("SCPSilentChance", { Title = "命中率", Min = 10, Max = 100, Default = 72, Rounding = 0, Callback = function(v) SilentAim.Config.HitChance = v / 100 end })
tabs.Silent:AddToggle("SCPSilentWall", { Title = "遮挡检查", Default = true, Callback = function(v) SilentAim.Config.WallCheck = v end })
tabs.Silent:AddToggle("SCPSilentTeam", { Title = "队伍过滤", Default = false, Callback = function(v) SilentAim.Config.TeamCheck = v end })
tabs.Silent:AddParagraph({ Title = "静默瞄准说明", Content = "改写客户端发往服务端的命中参数；参数按单位方向/世界坐标两种形态标定，命中点限制在服务端可判定的原始包络内。" })

tabs.Hitbox:AddToggle("SCPHitboxEnabled", { Title = "碰撞箱扩展", Default = false, Callback = function(v) Hitbox.Config.Enabled = v if not v then Hitbox:Update(0) end end })
tabs.Hitbox:AddDropdown("SCPHitboxMode", { Title = "模式", Values = { "all", "fullBody", "lockedOnly" }, Default = "all", Callback = function(v) Hitbox.Config.Mode = v end })
tabs.Hitbox:AddSlider("SCPHitboxScale", { Title = "峰值倍率", Min = 10, Max = 30, Default = 18, Rounding = 0, Callback = function(v) Hitbox.Config.ScaleMax = v / 10 end })
tabs.Hitbox:AddSlider("SCPHitboxDist", { Title = "作用距离 (studs)", Min = 50, Max = 1000, Default = 500, Rounding = 0, Callback = function(v) Hitbox.Config.MaxDistance = v end })
tabs.Hitbox:AddSlider("SCPHitboxFov", { Title = "屏幕门 (px)", Min = 50, Max = 1000, Default = 600, Rounding = 0, Callback = function(v) Hitbox.Config.FOV = v end })
tabs.Hitbox:AddSlider("SCPHitboxActive", { Title = "同帧目标数", Min = 1, Max = 16, Default = 8, Rounding = 0, Callback = function(v) Hitbox.Config.MaxActive = v end })
tabs.Hitbox:AddToggle("SCPHitboxHostile", {Title="只处理敌对阵营",Default=false,Callback=function(v)Hitbox.Config.OnlyHostile=v end})
tabs.Hitbox:AddToggle("SCPHitboxNPC", {Title="包含SCP收容体",Default=true,Callback=function(v)Hitbox.Config.TargetNPCs=v end})
tabs.Hitbox:AddToggle("SCPHitboxUseFov", {Title="限制屏幕 FOV（默认不限制）",Default=false,Callback=function(v)Hitbox.Config.UseFOV=v end})
tabs.Hitbox:AddToggle("SCPHitboxBounds", {Title="显示实际本地碰撞边界",Default=true,Callback=function(v)Hitbox.Config.ShowBounds=v end})
tabs.Hitbox:AddSlider("SCPHitboxBoundsAlpha", {Title="碰撞框透明度 (%)",Min=0,Max=95,Default=50,Rounding=0,Callback=function(v)Hitbox.Config.BoundsTransparency=v/100 end})
tabs.Hitbox:AddColorpicker("SCPHitboxBoundsColor", {Title="碰撞边界颜色",Default=Hitbox.Config.BoundsColor,Callback=function(v)if typeof(v)=="Color3" then Hitbox.Config.BoundsColor=v end end})
tabs.Hitbox:AddParagraph({ Title = "碰撞箱说明", Content = "独立 Heartbeat 与角色目标池；启用后默认显示青色边界。修改仅对客户端有效，服务端命中仍可能采用原尺寸。" })

-- R226 five essential ESP diagnostics: faction, names, hitbox style, role, SCP classification/color.
tabs.Visual:AddToggle("SCPESPEnabled", {Title="ESP 总开关",Default=false,Callback=function(v)ESP.Config.Enabled=v if not v then ESP:Update(0) end end})
tabs.Visual:AddToggle("SCPESPHostile", {Title="仅显示敌对阵营",Default=false,Callback=function(v)ESP.Config.OnlyHostile=v end})
tabs.Visual:AddToggle("SCPESPNames", {Title="显示名称",Default=true,Callback=function(v)ESP.Config.ShowNames=v end})
tabs.Visual:AddDropdown("SCPESPNameFormat", {Title="名称类型",Values={"用户名","实体名"},Default="用户名",Callback=function(v)ESP.Config.NameFormat=v end})
tabs.Visual:AddDropdown("SCPESPStyle", {Title="ESP 样式（碰撞箱）",Values={"3D","2D"},Default="3D",Callback=function(v)ESP.Config.Style=v end})
tabs.Visual:AddToggle("SCPESPJob", {Title="显示职位 / 军衔",Default=false,Callback=function(v)ESP.Config.ShowJob=v end})
tabs.Visual:AddToggle("SCPESPNPC", {Title="显示 SCP收容体",Default=true,Callback=function(v)ESP.Config.TargetNPCs=v end})
tabs.Visual:AddColorpicker("SCPESPColorSCP", {Title="SCP收容体颜色（默认黑）",Default=ESP.Config.ColorSCP,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorSCP=v end end})
tabs.Visual:AddColorpicker("SCPESPColorEnemy", {Title="敌对阵营颜色",Default=ESP.Config.ColorEnemy,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorEnemy=v end end})
tabs.Visual:AddColorpicker("SCPESPColorAlly", {Title="其他阵营颜色",Default=ESP.Config.ColorAlly,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorAlly=v end end})
tabs.Visual:AddSlider("SCPESPDist", {Title="显示距离",Min=100,Max=2000,Default=850,Rounding=0,Callback=function(v)ESP.Config.MaxDistance=v end})
tabs.Visual:AddSlider("SCPESPFPS", {Title="刷新率（Hz）",Min=8,Max=30,Default=20,Rounding=0,Callback=function(v)ESP.Config.TickRate=v end})
-- R228: ESP appearance controls preserve existing IDs and add separate label/color settings.
tabs.Visual:AddSlider("SCPESPAlpha3D", {Title="3D 盒子透明度 (%)",Min=0,Max=100,Default=30,Rounding=0,Callback=function(v)ESP.Config.Transparency3D=v/100 end})
tabs.Visual:AddSlider("SCPESPAlpha2D", {Title="2D 方框透明度 (%)",Min=0,Max=100,Default=15,Rounding=0,Callback=function(v)ESP.Config.Transparency2D=v/100 end})
tabs.Visual:AddToggle("SCPESPJobColor", {Title="职位跟随游戏队伍颜色",Default=true,Callback=function(v)ESP.Config.JobTeamColor=v end})
tabs.Visual:AddToggle("SCPESPJobZH", {Title="职位中文翻译",Default=true,Callback=function(v)ESP.Config.JobTranslate=v end})
tabs.Visual:AddSlider("SCPESPNameFont", {Title="名称文字大小",Min=10,Max=26,Default=14,Rounding=0,Callback=function(v)ESP.Config.NameSize=v end})
tabs.Visual:AddSlider("SCPESPJobFont", {Title="职位文字大小",Min=10,Max=26,Default=13,Rounding=0,Callback=function(v)ESP.Config.JobSize=v end})
tabs.Visual:AddSlider("SCPESPBoxWidth", {Title="2D 方框线宽",Min=1,Max=4,Default=2,Rounding=0,Callback=function(v)ESP.Config.BoxThickness=v end})
tabs.Visual:AddSlider("SCPESPLabelOffset", {Title="文字显示高度",Min=0,Max=60,Default=24,Rounding=0,Callback=function(v)ESP.Config.LabelOffset=v/10 end})
tabs.Visual:AddToggle("SCPESPDistance", {Title="显示目标距离",Default=false,Callback=function(v)ESP.Config.ShowDistance=v end})
tabs.Visual:AddToggle("SCPESPHealth", {Title="显示目标生命值",Default=false,Callback=function(v)ESP.Config.ShowHealth=v end})
tabs.Visual:AddSlider("SCPESPMaxTargets", {Title="ESP 最大目标数",Min=8,Max=64,Default=36,Rounding=0,Callback=function(v)ESP.Config.MaxEntries=v end})
tabs.Visual:AddParagraph({Title="性能与模式",Content="3D原生渲染自动跟随碰撞部件；2D按刷新率投影实际头/躯干碰撞框，默认不依赖Drawing；关闭后清理全部对象。"})

tabs.Move:AddToggle("SCPSpeed", { Title = "加速", Default = false, Callback = function(v) Movement.Config.SpeedEnabled = v end })
tabs.Move:AddSlider("SCPSpeedVal", { Title = "速度值", Min = 16, Max = 150, Default = 16, Rounding = 0, Callback = function(v) Movement.Config.SpeedValue = v end })
tabs.Move:AddToggle("SCPFly", { Title = "飞行", Default = false, Callback = function(v) Movement.Config.FlyEnabled = v end })
tabs.Move:AddToggle("SCPTouchFly", { Title = "触屏拖动飞行", Default = true, Callback = function(v) Movement.Config.TouchFly = v end })
tabs.Move:AddSlider("SCPFlySpeed", { Title = "飞行速度", Min = 10, Max = 300, Default = 60, Rounding = 0, Callback = function(v) Movement.Config.FlySpeed = v end })
tabs.Move:AddToggle("SCPNoclip", { Title = "穿墙", Default = false, Callback = function(v) if Movement.SetNoclip then Movement:SetNoclip(v) else Movement.Config.Noclip = v end end })
tabs.Move:AddToggle("SCPJump", { Title = "超级跳", Default = false, Callback = function(v) Movement.Config.JumpEnabled = v end })
tabs.Move:AddSlider("SCPJumpVal", { Title = "跳跃力", Min = 20, Max = 250, Default = 50, Rounding = 0, Callback = function(v) Movement.Config.JumpValue = v end })

tabs.World:AddToggle("SCPInstantInteract", {Title="秒交互（ProximityPrompt）",Default=false,Callback=function(v)Interact:SetEnabled(v) end})
tabs.World:AddParagraph({Title="秒交互说明",Content="仅对当前显示的交互提示清零按住时间；不增加交互距离、不越过权限或服务端验证。"})
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

tabs.Hitbox:AddButton({Title="检查碰撞箱实际生效情况",Callback=function()
    local hs=Hitbox.Stats or {}
    local detail=("目标 %d | 扩展 %d | 修改部件 %d | 实际尺寸变化 %d | 边界 %d | 拒绝 %d | 外部重置 %d\n%s\n客户端尺寸变化不代表服务器命中扩展")
        :format(hs.Eligible or 0,hs.Expanded or 0,hs.PartsChanged or 0,
            hs.Verified or 0,hs.Preview or 0,hs.Rejected or 0,hs.ExternalResets or 0,
            tostring(hs.LastError ~= "" and hs.LastError or hs.Reason or "等待刷新"))
    pcall(function() ui:Notify({Title="SCP 碰撞箱诊断",Content=detail,Duration=9}) end)
end})
tabs.Info:AddButton({Title="ESP / 自瞄 / 碰撞箱诊断",Callback=function()
    local es=ESP.Stats or {} local cs=Camera.Stats or {} local hs=Hitbox.Stats or {}
    local text=("ESP %s: %d/%d, %.2fms; 自瞄: %s (%s); 碰撞箱: %d/%d; 秒交互: %d")
        :format(tostring(es.Mode or "3D"),es.Visible or 0,es.Seen or 0,es.AverageMs or 0,
          tostring(cs.Reason or "未知"),tostring(cs.Locked or "-"),hs.Expanded or 0,hs.Eligible or 0,
          Interact.Stats and Interact.Stats.Modified or 0)
    pcall(function()ui:Notify({Title="SCP R226 运行诊断",Content=text,Duration=8})end)
end})
tabs.Info:AddToggle("SCPDebug", { Title = "调试输出", Default = false, Callback = function(v) common.Debug = v end })
tabs.Info:AddParagraph({ Title = "兼容性说明",
    Content = ("PlaceId %d / 构建 scp-v3。R15 与 R6 角色自适应；Drawing 缺失时线条停用、Chams 可独立工作；元表钩子缺失时静默瞄准自动停用；候选与绘制刷新率独立于帧率；触屏默认右侧按住。")
        :format(game.PlaceId) })
tabs.Info:AddToggle("SCPAdvancedCloak", {Title="高级隐藏 Hook（兼容性风险，默认关闭）",Default=false,Callback=function(v)
    if type(common.Cloak.Start)~="function" then return end
    if v then
        common.CloakStatus="user enabled"
        common.Guard("Cloak",function() common.Cloak.Start() end)
    else
        common.CloakStatus="user disabled"
        common.Guard("Cloak",function() common.Cloak.Stop() end)
    end
end})
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
