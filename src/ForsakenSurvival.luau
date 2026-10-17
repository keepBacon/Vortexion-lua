-- Vortexion - Forsaken · 生存组模块 (Survival Group)
-- 借鉴来源: forsakenMenu main.lua (safePos) / Auto-Block-V4 (无限体力单例) /
--           Auto-Backstab-V3 (killerTrack 清理) / forsaken_hub (InfStamina 防重入)
return function(ctx)
	local Players = ctx.Players
	local LocalPlayer = ctx.LocalPlayer
	local RunService = ctx.RunService
	local Workspace = ctx.Workspace
	local track = ctx.track
	local Fluent = ctx.Fluent
	local Tabs = ctx.Tabs
	local sessionEnv = ctx.sessionEnv
	local thisSessionId = ctx.thisSessionId

	local function notify(title, content)
		if Fluent then
			pcall(function()
				Fluent:Notify({ Title = title, Content = content, Duration = 5 })
			end)
		end
	end

	---------------------------------------------------------------------------
	-- 无限体力: 单例协程 + enabled 门 + 字段门
	-- (修附件 Auto-Block-V4:96-102 CharacterAdded 重复调用的协程累积)
	---------------------------------------------------------------------------
	local staminaConn, cachedChar, cachedSource, cachedModule = nil, nil, nil, nil
	local staminaActive, loading, destroyed = false, false, false
	local generation, staminaTarget = 0, 100
	local clock = ctx.clock or os.clock
	local savedStamina = {}
	local function restoreStamina()
		for mod, props in pairs(savedStamina) do
			for key, value in pairs(props) do
				pcall(function()
					if key == "Stamina" and type(mod.SetStamina) == "function" then mod:SetStamina(value) else mod[key] = value end
				end)
			end
		end
		table.clear(savedStamina)
	end
	local function staminaSource(char)
		local source = char and char:FindFirstChild("Stamina")
		if source then return source end
		local folder = game:GetService("ReplicatedStorage")
		for _, name in ipairs({"Systems", "Character", "Game", "Sprinting"}) do
			folder = folder and folder:FindFirstChild(name)
		end
		return folder
	end
	local function getStaminaModule()
		if destroyed then return nil end
		local char = LocalPlayer and LocalPlayer.Character
		if not char then
			if cachedChar then
				restoreStamina(); generation += 1
				loading, cachedChar, cachedSource, cachedModule = false, nil, nil, nil
			end
			return nil
		end
		local source = staminaSource(char)
		if char ~= cachedChar or source ~= cachedSource then
			restoreStamina()
			generation += 1
			loading, cachedModule = false, nil
			cachedChar, cachedSource = char, source
		end
		if cachedModule then return cachedModule end
		if not source or loading then return nil end
		loading = true
		local token = generation
		task.spawn(function()
			local ok, mod = pcall(ctx.requireModule or require, source)
			if token ~= generation then return end
			loading = false
			if ok and type(mod) == "table" then cachedModule = mod end
		end)
		return cachedModule
	end
	local function stopInfiniteStamina()
		staminaActive = false
		generation += 1
		loading = false
		if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
		restoreStamina()
	end
	local function startInfiniteStamina()
		stopInfiniteStamina()
		if destroyed then return end
		staminaActive = true
		local nextAt = -math.huge
		staminaConn = RunService.Heartbeat:Connect(function()
			if not staminaActive or clock() < nextAt then return end
			nextAt = clock() + 0.2
			local mod = getStaminaModule()
			if not mod then return end
			if not savedStamina[mod] then
				local saved = {}
				for _, key in ipairs({"Stamina", "StaminaLossDisabled"}) do
					if mod[key] ~= nil then saved[key] = mod[key] end
				end
				savedStamina[mod] = saved
			end
			pcall(function()
				local maximum = type(mod.MaxStamina) == "number" and mod.MaxStamina or 100
				local value = math.clamp(staminaTarget, 0, maximum)
				if mod.StaminaLossDisabled ~= nil then mod.StaminaLossDisabled = true end
				if type(mod.Stamina) == "number" then
					if type(mod.SetStamina) == "function" then mod:SetStamina(value) else mod.Stamina = value end
				end
			end)
		end)
		track(staminaConn)
	end

	---------------------------------------------------------------------------
	-- killerTrack 自动清理: 附件 Auto-Backstab-V3:66 永续累积的内存泄漏
	---------------------------------------------------------------------------
	local killerTrack = {}
	local killerTrackAge = {}

	local function pruneKillerTrack()
		local now = os.clock()
		for hrp, data in pairs(killerTrack) do
			local stale = (not hrp.Parent) or (not data.pos)
			if killerTrackAge[hrp] and now - killerTrackAge[hrp] > 5 then stale = true end
			if stale then
				killerTrack[hrp] = nil
				killerTrackAge[hrp] = nil
			end
		end
	end

	local function trackKiller(hrp)
		if not (hrp and hrp:IsA("BasePart")) then return end
		if not killerTrack[hrp] then
			killerTrack[hrp] = { pos = hrp.Position, vel = Vector3.zero }
			killerTrackAge[hrp] = os.clock()
		else
			local d = killerTrack[hrp]
			local now = hrp.Position
			d.vel = (now - d.pos) / math.max(os.clock() - killerTrackAge[hrp], 0.016)
			d.pos = now
			killerTrackAge[hrp] = os.clock()
		end
	end

	---------------------------------------------------------------------------
	-- 安全传送点: GetTouchingParts + CanCollide + IsDescendantOf 三门
	-- 附件 forsakenMenu main.lua:341-351
	---------------------------------------------------------------------------
	local function isSafePosition(char, pos)
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or typeof(pos) ~= "Vector3" then return false end
		if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z or pos.Magnitude == math.huge then return false end
		if pos.Y <= Workspace.FallenPartsDestroyHeight + 10 then return false end
		local ok, clear = pcall(function()
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = {char}
			params.RespectCanCollide = true
			for _, part in ipairs(Workspace:GetPartBoundsInBox(CFrame.new(pos), root.Size, params)) do
				if part.CanCollide and not part:IsDescendantOf(char) then return false end
			end
			local ray = RaycastParams.new()
			ray.FilterType = Enum.RaycastFilterType.Exclude
			ray.FilterDescendantsInstances = {char}
			ray.RespectCanCollide = true
			return Workspace:Raycast(pos, Vector3.new(0, -(root.Size.Y / 2 + 6), 0), ray) ~= nil
		end)
		return ok and clear == true
	end
	local safeCFrame, safeCharacter = nil, nil
	local safeTp = true
	local function saveSafePoint()
		if destroyed then return false, "模块已关闭" end
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not isSafePosition(char, root.Position) then return false, "当前点碰撞或无地面" end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return false, "角色未存活" end
		safeCFrame, safeCharacter = root.CFrame, char
		return true
	end
	local function returnSafePoint()
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if destroyed or not safeCFrame or safeCharacter ~= char or not root or not hum or hum.Health <= 0 then
			return false, "本角色尚未保存点"
		end
		if safeTp and not isSafePosition(char, safeCFrame.Position) then return false, "保存点已被阻挡" end
		root.CFrame = safeCFrame
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		return true
	end
	local function findTrickBehavior()
		local ok, behavior = pcall(function()
			local storage = game:GetService("ReplicatedStorage")
			local assets = storage:FindFirstChild("Assets")
			local survivors = assets and assets:FindFirstChild("Survivors")
			local veeronica = survivors and survivors:FindFirstChild("Veeronica")
			return veeronica and veeronica:FindFirstChild("Behavior")
		end)
		if ok then return behavior end
	end
	local function findTrickButton()
		local ok, button = pcall(function()
			local gui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
			local main = gui and gui:FindFirstChild("MainUI")
			return main and main:FindFirstChild("SprintingButton")
		end)
		if ok then return button end
	end
	local function trickMatchesCharacter(highlight, character)
		local ok, result = pcall(function()
			if not highlight or not character then return false end
			if not highlight.Parent or not character.Parent then return false end
			local adornee = highlight.Adornee
			if not adornee then return false end
			if adornee == character then return true end
			return adornee:IsDescendantOf(character)
		end)
		return ok and result == true
	end
	local function invokeTrickSprint(button, isCurrent)
		local getConnections = type(ctx.getConnections) == "function" and ctx.getConnections or getconnections
		if type(getConnections) ~= "function" then return false, "当前环境缺少按钮回调枚举" end
		local okList, connections = pcall(function() return getConnections(button.MouseButton1Down) end)
		if not okList or type(connections) ~= "table" then return false, "按钮回调读取失败" end
		local function member(object, key)
			local ok, value = pcall(function() return object[key] end)
			if ok then return value end
		end
		local invoked, seen = false, {}
		for _, connection in ipairs(connections) do
			local okNow, current = pcall(isCurrent)
			if not okNow or not current then break end
			if not seen[connection] then
				seen[connection] = true
				local okRun, ran = pcall(function()
					if member(connection, "Connected") == false or member(connection, "Enabled") == false then return false end
					local fire = member(connection, "Fire")
					if type(fire) == "function" then if isCurrent() then fire(connection); return true end; return false end
					local callback = member(connection, "Function")
					if type(callback) == "function" and isCurrent() then callback(); return true end
					return false
				end)
				if okRun and ran then invoked = true end
			end
		end
		if not invoked then return false, "本次没有触发可用回调" end
		return true
	end

	local function formatTrickStatus(s)
		return ("开关: %s | 模式: %s | 状态: %s | 监控: %d | 尝试/成功/失败/去重: %d/%d/%d/%d | 间隔: %d ms"):format(
			s.enabled and "开" or "关", s.touchOnly and "仅触屏" or "不限设备", s.status,
			s.monitors, s.attempts, s.successes, s.failures, s.debounced, s.debounceMs)
	end
	-- Auto-Trick owns its listeners; disabling leaves no frame or resource scans.
	local trickEnabled, trickTouchOnly, trickDebounce = false, true, 0.15
	local trickEpoch, trickFolder, trickCharacter, trickRemovedCharacter = 0, nil, nil, nil
	local trickMonitors, trickConnections, trickFolderConnections = {}, {}, {}
	local trickNextProbe, trickLastAt, trickMessage = 0, -math.huge, "已关闭"
	local trickAttempts, trickSuccesses, trickFailures, trickDebounced = 0, 0, 0, 0
	local function disconnectTrickConnections(bucket)
		for i = #bucket, 1, -1 do
			local connection = bucket[i]; bucket[i] = nil
			pcall(function() connection:Disconnect() end)
		end
	end
	local function trickSessionCurrent()
		return not destroyed and (not sessionEnv or thisSessionId == nil or sessionEnv.VortexionSessionId == thisSessionId)
	end
	local function removeTrickMonitor(highlight, record)
		if trickMonitors[highlight] ~= record then return end
		trickMonitors[highlight] = nil
		disconnectTrickConnections(record.connections)
	end
	local function clearTrickFolder()
		trickFolder = nil
		disconnectTrickConnections(trickFolderConnections)
		for highlight, record in pairs(trickMonitors) do removeTrickMonitor(highlight, record) end
	end
	local function stopAutoTrick()
		trickEnabled = false; trickEpoch += 1
		clearTrickFolder(); disconnectTrickConnections(trickConnections)
		trickCharacter, trickRemovedCharacter, trickMessage = nil, nil, "已关闭"
	end
	local function connectTrick(bucket, signal, callback, current)
		local ok, connection = pcall(function() return signal:Connect(callback) end)
		if not ok or not connection then return false end
		if not current() then pcall(function() connection:Disconnect() end); return false end
		table.insert(bucket, connection)
		return true
	end
	local function trickTouchReady()
		if not trickTouchOnly then return true end
		local ok, value = pcall(function()
			local input = ctx.UserInputService or game:GetService("UserInputService")
			return input.TouchEnabled
		end)
		return ok and value == true
	end
	local function watchTrickHighlight(highlight)
		local folder, epoch = trickFolder, trickEpoch
		local ok, valid = pcall(function() return highlight:IsA("Highlight") and highlight:IsDescendantOf(folder) end)
		if not ok or not valid or trickMonitors[highlight] then return end
		local record = {previous = false, connections = {}}
		trickMonitors[highlight] = record
		local function current()
			return trickEnabled and trickSessionCurrent() and epoch == trickEpoch and folder == trickFolder and trickMonitors[highlight] == record
		end
		local function evaluate()
			if not current() then return end
			local alive, inside = pcall(function() return highlight:IsDescendantOf(folder) end)
			if not alive or not inside then removeTrickMonitor(highlight, record); return end
			local character = trickCharacter
			local matches = character == LocalPlayer.Character and trickMatchesCharacter(highlight, character)
			local rising = matches and (not record.previous or record.pending == true)
			record.previous, record.pending = matches, false
			if not rising then return end
			if not trickTouchReady() then trickMessage = "当前不是触屏设备"; return end
			local now = clock()
			if now - trickLastAt < trickDebounce then trickDebounced += 1; return end
			local button = findTrickButton()
			if not button then record.pending = true; trickMessage = "等待冲刺按钮"; return end
			trickLastAt = now; trickAttempts += 1
			local function canInvoke()
				return current() and character == trickCharacter and character == LocalPlayer.Character
					and findTrickBehavior() == folder and findTrickButton() == button and trickTouchReady()
					and trickMatchesCharacter(highlight, character)
			end
			local success, reason = invokeTrickSprint(button, canInvoke)
			if not current() then return end
			if success then trickSuccesses += 1; trickMessage = "已触发本地冲刺回调"
			else trickFailures += 1; trickMessage = reason end
		end
		record.evaluate = evaluate
		local allocated, ready = pcall(function()
			return connectTrick(record.connections, highlight:GetPropertyChangedSignal("Adornee"), evaluate, current)
				and connectTrick(record.connections, highlight.AncestryChanged, evaluate, current)
		end)
		if not allocated or not ready or not current() then removeTrickMonitor(highlight, record); return end
		evaluate()
	end
	local function probeAutoTrick()
		if not trickEnabled or not trickSessionCurrent() then return end
		local character = LocalPlayer.Character
		if character == trickRemovedCharacter then character = nil end
		local changedCharacter = trickCharacter ~= character
		if changedCharacter then
			trickCharacter, trickLastAt = character, -math.huge
			for _, record in pairs(trickMonitors) do record.previous = false end
		end
		local folder = findTrickBehavior()
		if not folder then
			if trickFolder then clearTrickFolder() end
			trickMessage = "等待 Veeronica 行为资源"; return
		end
		if folder == trickFolder then
			for _, record in pairs(trickMonitors) do if changedCharacter or record.pending then record.evaluate() end end
			return
		end
		clearTrickFolder()
		trickFolder = folder
		local epoch = trickEpoch
		local function current() return trickEnabled and trickSessionCurrent() and epoch == trickEpoch and trickFolder == folder end
		local ok, ready = pcall(function()
			return connectTrick(trickFolderConnections, folder.DescendantAdded, watchTrickHighlight, current)
		end)
		if not ok or not ready then clearTrickFolder(); trickMessage = "资源监听暂不可用"; return end
		local listed, descendants = pcall(function() return folder:GetDescendants() end)
		if not listed or not current() then if current() then clearTrickFolder() end; return end
		trickMessage = "监听中"
		for _, descendant in ipairs(descendants) do
			if not current() then break end
			watchTrickHighlight(descendant)
		end
	end
	local function refreshAutoTrick()
		if destroyed then return end
		clearTrickFolder(); trickNextProbe = 0
		probeAutoTrick()
	end
	local function setAutoTrick(enabled)
		if destroyed or not trickSessionCurrent() then return end
		if enabled == trickEnabled then return end
		stopAutoTrick()
		if not enabled then return end
		trickEnabled = true; trickLastAt = -math.huge; trickNextProbe = 0
		trickCharacter = LocalPlayer.Character
		local epoch = trickEpoch
		local function current() return trickEnabled and trickSessionCurrent() and epoch == trickEpoch end
		local function characterChanged(character)
			if not current() then return end
			trickRemovedCharacter, trickCharacter, trickLastAt = nil, character, -math.huge
			for _, record in pairs(trickMonitors) do record.previous = false; record.evaluate() end
			trickNextProbe = 0
		end
		local ok, ready = pcall(function()
			if not connectTrick(trickConnections, LocalPlayer.CharacterAdded, characterChanged, current) then return false end
			if LocalPlayer.CharacterRemoving and not connectTrick(trickConnections, LocalPlayer.CharacterRemoving, function(character)
				if not current() then return end
				trickRemovedCharacter = character; trickCharacter = nil
				for _, record in pairs(trickMonitors) do record.previous = false end
			end, current) then return false end
			return connectTrick(trickConnections, RunService.Heartbeat, function()
				if not current() then if trickEnabled and epoch == trickEpoch then stopAutoTrick() end; return end
				local now = clock(); if now < trickNextProbe then return end
				trickNextProbe = now + 1; probeAutoTrick()
			end, current)
		end)
		if not ok or not ready then
			if epoch == trickEpoch then stopAutoTrick(); trickMessage = "生命周期监听暂不可用" end
			return
		end
		probeAutoTrick()
	end
	local function getTrickStatus()
		local count = 0; for _ in pairs(trickMonitors) do count += 1 end
		return {enabled = trickEnabled, touchOnly = trickTouchOnly, status = trickMessage, monitors = count,
			attempts = trickAttempts, successes = trickSuccesses, failures = trickFailures, debounced = trickDebounced,
			debounceMs = math.floor(trickDebounce * 1000 + 0.5)}
	end
	local function destroy()
		if destroyed then return end
		destroyed = true
		stopAutoTrick()
		stopInfiniteStamina()
		cachedModule, cachedSource, cachedChar, safeCFrame, safeCharacter = nil, nil, nil, nil, nil
		table.clear(killerTrack); table.clear(killerTrackAge)
	end

	---------------------------------------------------------------------------
	-- UI: 生存增强 (挂 Game tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Survival then
		Tabs.Survival:AddToggle("SurvivalInfStaminaSafe", {
			Title = "无限体力（单例协程·防重生累积）",
			Default = false,
			Callback = function(state)
				if state then startInfiniteStamina() else stopInfiniteStamina() end
			end
		})

		Tabs.Survival:AddButton({
			Title = "清理失效杀手追踪缓存",
			Callback = function()
				local before = 0
				for _ in pairs(killerTrack) do before = before + 1 end
				pruneKillerTrack()
				local after = 0
				for _ in pairs(killerTrack) do after = after + 1 end
				notify("缓存清理", ("追踪条目 %d → %d"):format(before, after))
			end
		})
	end

	---------------------------------------------------------------------------
	-- UI: 生存增强 (挂 Blatant tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Survival then
		Tabs.Survival:AddToggle("SurvivalSafeTp", {
			Title = "安全传送校验（碰撞检测）",
			Default = true,
			Callback = function(state)
				safeTp = state == true
				_G.VortexionSafeTp = state or nil
			end
		})
	end

	if Tabs and Tabs.Survival then
		Tabs.Survival:AddSlider("SurvivalStaminaTarget", {Title = "体力目标（上限由模块限制）", Default = 100, Min = 1, Max = 200, Rounding = 0, Callback = function(v) staminaTarget = v end})
		Tabs.Survival:AddButton({Title = "保存安全点（当前角色）", Callback = function()
			local ok, err = saveSafePoint(); notify("安全点", ok and "已保存" or err)
		end})
		Tabs.Survival:AddButton({Title = "返回保存点（重新校验）", Callback = function()
			local ok, err = returnSafePoint(); notify("安全点", ok and "已返回" or err)
		end})
	end

	if Tabs and Tabs.Survival then
		Tabs.Survival:AddToggle("SurvivalAutoTrick", {Title = "Auto-Trick（Veeronica）", Default = false, Callback = function(v) setAutoTrick(v == true) end})
		Tabs.Survival:AddToggle("SurvivalTrickTouchOnly", {Title = "Auto-Trick 仅触屏触发", Default = true, Callback = function(v)
			if destroyed then return end; trickTouchOnly = v == true
		end})
		Tabs.Survival:AddSlider("SurvivalTrickDebounceMs", {Title = "Auto-Trick 去重间隔 (ms)", Min = 0, Max = 1000, Default = 150, Rounding = 0, Callback = function(v)
			if destroyed then return end
			local n = tonumber(v)
			if not n or n ~= n or math.abs(n) == math.huge then return end
			trickDebounce = math.clamp(n, 0, 1000) / 1000
		end})
		Tabs.Survival:AddButton({Title = "刷新 Auto-Trick 资源", Callback = function() if not destroyed then refreshAutoTrick() end end})
		Tabs.Survival:AddButton({Title = "查看 Auto-Trick 状态", Callback = function()
			if not destroyed then notify("Auto-Trick", formatTrickStatus(getTrickStatus())) end
		end})
	end
	return {
		Destroy = destroy,
		setAutoTrick = setAutoTrick,
		refreshAutoTrick = refreshAutoTrick,
		getTrickStatus = getTrickStatus,
		saveSafePoint = saveSafePoint,
		returnSafePoint = returnSafePoint,
		getStaminaModule = getStaminaModule,
		startInfiniteStamina = startInfiniteStamina,
		stopInfiniteStamina = stopInfiniteStamina,
		trackKiller = trackKiller,
		pruneKillerTrack = pruneKillerTrack,
		isSafePosition = isSafePosition,
	}
end
