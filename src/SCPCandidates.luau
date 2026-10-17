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
