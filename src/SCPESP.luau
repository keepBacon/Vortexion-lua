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
