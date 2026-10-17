-- ForsakenVisual 本地音效链路专项片段（R34）。
-- 生产函数体由 run_audio_r34.mjs 按行区间原样注入（__AUDIO_*__ 标记），本文件只提供确定性 Roblox mock、驱动与断言。
local checks, assertions = 0, 0
local function check(cond, msg)
	checks = checks + 1
	if not cond then error("audio_r34: " .. tostring(msg), 2) end
	assertions = assertions + 1
end
local function equal(got, want, msg)
	checks = checks + 1
	if got ~= want then error(("audio_r34: %s (got %s, want %s)"):format(tostring(msg), tostring(got), tostring(want)), 2) end
	assertions = assertions + 1
end

local now = 0
local function signal()
	local s = {handlers = {}}
	function s:Connect(fn)
		local c = {Connected = true, FN = fn}
		table.insert(s.handlers, c)
		function c:Disconnect()
			c.Connected = false
			for i, h in ipairs(s.handlers) do
				if h == c then table.remove(s.handlers, i); break end
			end
		end
		return c
	end
	function s:Fire(...)
		local snapshot = {}
		for _, c in ipairs(s.handlers) do table.insert(snapshot, c) end
		for _, c in ipairs(snapshot) do
			if c.Connected then pcall(c.FN, ...) end
		end
	end
	function s:Count()
		local n = 0
		for _, c in ipairs(s.handlers) do if c.Connected then n = n + 1 end end
		return n
	end
	return s
end

local function inst(class, name)
	local node = {ClassName = class, Name = name or class, Parent = nil, Destroyed = false, children = {}, plays = 0, stops = 0, destroys = 0}
	function node:IsA(want) return want == self.ClassName end
	function node:FindFirstChild(want)
		for _, child in ipairs(self.children) do if child.Name == want then return child end end
		return nil
	end
	function node:FindFirstChildOfClass(want)
		for _, child in ipairs(self.children) do if child.ClassName == want then return child end end
		return nil
	end
	function node:GetChildren()
		local out = {}
		for _, child in ipairs(self.children) do table.insert(out, child) end
		return out
	end
	function node:IsDescendantOf(root)
		local cursor = self.Parent
		while cursor do
			if cursor == root then return true end
			cursor = cursor.Parent
		end
		return false
	end
	function node:Destroy()
		node.Destroyed = true
		node.destroys = node.destroys + 1
		node.Parent = nil
	end
	if class == "Animator" then node.AnimationPlayed = signal() end
	if class == "Sound" then
		node.Ended = signal()
		node.SoundId, node.PlaybackSpeed, node.Volume, node.Playing = "", 1, 1, false
		function node:Play()
			node.plays = node.plays + 1
			node.Playing = true
			if node.onPlay then node.onPlay() end
		end
		function node:Stop()
			node.stops = node.stops + 1
			node.Playing = false
		end
	end
	return node
end
local Instance = {new = function(class) return inst(class) end}

local function attach(parent, child)
	child.Parent = parent
	table.insert(parent.children, child)
end
local function detach(node)
	local parent = node.Parent
	if not parent then return end
	for i, child in ipairs(parent.children) do
		if child == node then table.remove(parent.children, i); break end
	end
	node.Parent = nil
end

local workspaceNode = inst("Workspace")
local playerGuiNode = inst("PlayerGui")
local playerNode = inst("Player")
attach(playerNode, playerGuiNode)
local char = inst("Model", "Elliot")
local hum = inst("Humanoid")
hum.Health = 100
local animator = inst("Animator")
attach(hum, animator)
attach(char, hum)
attach(workspaceNode, char)

local ctx = {
	LocalPlayer = playerNode,
	RunService = inst("RunService"),
	Workspace = workspaceNode,
	clock = function() return now end,
	sessionEnv = nil,
	thisSessionId = nil,
	isfile = nil,
	getcustomasset = nil,
}
local LocalPlayer, RunService, Workspace = ctx.LocalPlayer, ctx.RunService, ctx.Workspace
local clock = ctx.clock or os.clock
local destroyed = false
local state = {Resources = false}
local degraded = {}
local resourceProfiles = {
	["Sil / 衣饰"] = {},
	["Sil / 鞭影衣饰"] = {PulseAnimation = {Id = "116814116277716", Delay = 0.45, Hold = 0.75}},
	["Terio / Manchegan衣饰"] = {},
	["Terio / 异装衣饰"] = {},
}
local resourceSerial, resourceRecord, resourceAttempt, resourcePending = 0, nil, nil, nil
local resourceRemovingChar, resourceRestoreDepth, resourceStatus, resourceProfile = nil, 0, "", "Sil / 鞭影衣饰"
local nextAppearance, objects = -math.huge, {}
local ensureLoopCalls = 0
local ensureLoop = function() ensureLoopCalls = ensureLoopCalls + 1 end
__AUDIO_CHARACTER__
__AUDIO_DEFS__
__AUDIO_DISPOSE__
__AUDIO_RELEASE__
__AUDIO_CURRENT__
__AUDIO_PULSE__
__AUDIO_UPDATE__
__AUDIO_ACTION__

local function resetWorld()
	now = 0
	destroyed = false
	state.Resources = true
	resourceSerial = 0
	resourceRecord, resourceAttempt, resourcePending = nil, nil, nil
	resourceRemovingChar = nil
	resourceStatus = ""
	hum.Health = 100
	-- Remove the previous scene's replacement before rebinding the baseline animator.
	for _, child in ipairs(hum:GetChildren()) do
		if child:IsA("Animator") and child ~= animator then detach(child) end
	end
	if animator.Parent ~= hum then attach(hum, animator) end
	animator.AnimationPlayed = signal()
	if playerGuiNode.Parent ~= playerNode then attach(playerNode, playerGuiNode) end
	LocalPlayer.Character = char
	ctx.sessionEnv, ctx.thisSessionId = nil, nil
	ctx.isfile, ctx.getcustomasset = nil, nil
end
local function arm(profile)
	resourceSerial = resourceSerial + 1
	local record = {char = char, profile = profile, serial = resourceSerial, items = {}, parked = {}, saved = {}, journal = {}, audioAssets = {}, audioSounds = {}}
	resourceRecord = record
	resourceAttempt = char
	resourceProfile = profile
	return record
end
local function scene(profile)
	resetWorld()
	resourceAudioEnabled = true
	ctx.isfile = function() return true end
	ctx.getcustomasset = function(file) return "rbxassetid://local/" .. file end
	local record = arm(profile)
	prepareResourceAudio(record)
	-- 生产在方案载入时即绑定 Animator；先绑定再排队，避免首次 tick 的 unbind 吃掉 cue。
	updateResourceAction(record)
	return record
end
local function tick(record)
	updateResourceAction(record)
	updateResourceAudio(record)
end
local function live(record)
	local n = 0
	for _ in pairs(record.audioSounds or {}) do n = n + 1 end
	return n
end
local function firstSound(record)
	for sound in pairs(record.audioSounds or {}) do return sound end
	return nil
end

-- A: prepareResourceAudio 能力 / 文件 / 取消
do
	resetWorld()
	local record = arm("Sil / 鞭影衣饰")
	prepareResourceAudio(record)
	equal(record.audioStatus, "本地音效已关闭", "audio off by default")
	check(next(record.audioAssets) == nil, "no assets while audio off")

	resourceAudioEnabled = true
	local record2 = arm("Sil / 鞭影衣饰")
	ctx.isfile, ctx.getcustomasset = nil, nil
	prepareResourceAudio(record2)
	equal(record2.audioStatus, "缺少 isfile / getcustomasset", "missing capability reported")

	local record3 = arm("Sil / 鞭影衣饰")
	ctx.isfile = function() return true end
	ctx.getcustomasset = function(file) return "rbxassetid://local/" .. file end
	prepareResourceAudio(record3)
	equal(record3.audioStatus, "本地音效就绪 3/3", "all three local files ready")
	equal(record3.audioAssets["挥鞭"], "rbxassetid://local/TerioThings/sil_whip.mp3", "whip uri resolved")

	local record4 = arm("Sil / 鞭影衣饰")
	ctx.isfile = function(file) return file ~= "TerioThings/lance_swing.mp3" end
	prepareResourceAudio(record4)
	check(record4.audioStatus:find("本地音效就绪 2/3", 1, true) ~= nil, "one missing file reported")
	check(record4.audioStatus:find("TerioThings/lance_swing.mp3", 1, true) ~= nil, "missing file listed")
	check(record4.audioAssets["斩击"] == nil, "missing slash asset not registered")

	local record5 = arm("Sil / 鞭影衣饰")
	ctx.isfile = function() return true end
	ctx.getcustomasset = function(file)
		if file == "TerioThings/coagulate.mp3" then error("injected asset error") end
		return "rbxassetid://local/" .. file
	end
	prepareResourceAudio(record5)
	check(record5.audioStatus:find("本地音效就绪 2/3", 1, true) ~= nil, "asset throw counted as missing")

	local record6 = arm("Sil / 鞭影衣饰")
	local probes = 0
	ctx.isfile = function()
		probes = probes + 1
		if probes >= 2 then state.Resources = false end
		return true
	end
	ctx.getcustomasset = function(file) return "rbxassetid://local/" .. file end
	prepareResourceAudio(record6)
	equal(record6.audioStatus, nil, "cancelled load leaves status untouched")
	local prepared = 0
	for _ in pairs(record6.audioAssets) do prepared = prepared + 1 end
	equal(prepared, 1, "cancelled load stops after current file")

	local record7 = arm("Sil / 鞭影衣饰")
	ctx.sessionEnv, ctx.thisSessionId = {VortexionSessionId = "S1"}, "S2"
	prepareResourceAudio(record7)
	equal(record7.audioStatus, nil, "stale session cancels preparation")
	check(next(record7.audioAssets) == nil, "stale session prepares nothing")
end

-- B: 队列延时与斩击零延时
do
	local record = scene("Sil / 鞭影衣饰")
	check(queueResourceAudio(record, "挥鞭", 0.45, nil), "whip cue queued")
	equal(record.audioCue.name, "挥鞭", "cue name")
	equal(record.audioCue.due, now + 0.45, "whip holds 0.45s")
	equal(nextAppearance, -math.huge, "queue forces appearance tick")
	tick(record)
	check(live(record) == 0, "whip not played before delay")
	now = 0.45
	tick(record)
	equal(live(record), 1, "whip plays after delay")
	local sound = firstSound(record)
	equal(sound.Name, "VortexionLocalActionSound", "sound name")
	equal(sound.SoundId, "rbxassetid://local/TerioThings/sil_whip.mp3", "sound id")
	equal(sound.PlaybackSpeed, 1, "whip playback speed")
	equal(sound.Volume, 1.5, "whip volume")
	equal(sound.Parent, playerGuiNode, "sound parented to PlayerGui")

	local record2 = scene("Terio / Manchegan衣饰")
	check(queueResourceAudio(record2, "斩击", 0, nil), "slash cue queued")
	equal(record2.audioCue.due, now, "slash has no delay")
	tick(record2)
	equal(live(record2), 1, "slash plays immediately")
	equal(firstSound(record2).PlaybackSpeed, 2, "slash playback speed")

	local record3 = scene("Sil / 鞭影衣饰")
	check(not queueResourceAudio(record3, "不存在", 0, nil), "unknown sound rejected")
	local record4 = scene("Sil / 鞭影衣饰")
	record4.audioAssets["挥鞭"] = nil
	check(not queueResourceAudio(record4, "挥鞭", 0, nil), "unprepared asset rejected")

	local record5 = scene("Sil / 鞭影衣饰")
	local stopped = {IsPlaying = false}
	check(queueResourceAudio(record5, "挥鞭", 0, stopped), "cue queued with stopped track")
	tick(record5)
	check(record5.audioCue == nil, "stopped track cancels cue")
	check(live(record5) == 0, "stopped track plays nothing")
end

-- C: 死亡 / 会话 / 卸载栅栏
do
	local record = scene("Sil / 鞭影衣饰")
	queueResourceAudio(record, "挥鞭", 0, nil)
	tick(record)
	equal(live(record), 1, "sound live before death")
	hum.Health = 0
	tick(record)
	equal(live(record), 0, "death reclaims live sounds")
	check(record.audioCue == nil, "death clears cue")
	check(not queueResourceAudio(record, "挥鞭", 0, nil), "no queue while dead")

	local record2 = scene("Sil / 鞭影衣饰")
	queueResourceAudio(record2, "挥鞭", 0, nil)
	tick(record2)
	equal(live(record2), 1, "sound live before session switch")
	ctx.sessionEnv, ctx.thisSessionId = {VortexionSessionId = "S1"}, "S2"
	tick(record2)
	equal(live(record2), 0, "stale session reclaims sounds")

	local record3 = scene("Sil / 鞭影衣饰")
	queueResourceAudio(record3, "挥鞭", 0, nil)
	tick(record3)
	equal(live(record3), 1, "sound live before unload")
	destroyed = true
	resourceRecord = nil
	tick(record3)
	equal(live(record3), 0, "unload reclaims sounds")
	check(not queueResourceAudio(record3, "挥鞭", 0, nil), "no queue after unload")
end

-- D: 4 并发上限 / Ended / 2 秒回收 / 重复回收
do
	local record = scene("Sil / 鞭影衣饰")
	for i = 1, 4 do
		check(queueResourceAudio(record, "挥鞭", 0, nil), "concurrent cue " .. i)
		tick(record)
	end
	equal(live(record), 4, "four concurrent local sounds")
	check(queueResourceAudio(record, "挥鞭", 0, nil), "fifth cue queued")
	tick(record)
	equal(live(record), 4, "fifth cue dropped at cap")
	check(record.audioCue == nil, "dropped cue consumed")

	local record2 = scene("Sil / 鞭影衣饰")
	queueResourceAudio(record2, "挥鞭", 0, nil)
	tick(record2)
	local sound = firstSound(record2)
	equal(sound.Ended:Count(), 1, "single Ended reclaimer")
	sound.Ended:Fire()
	equal(live(record2), 0, "Ended reclaims sound")
	equal(sound.Ended:Count(), 0, "Ended reclaimer disconnected")
	check(sound.Destroyed, "Ended destroys sound")
	equal(sound.stops, 1, "Ended stops sound")

	local record3 = scene("Sil / 鞭影衣饰")
	queueResourceAudio(record3, "挥鞭", 0, nil)
	tick(record3)
	equal(live(record3), 1, "sound live")
	now = 1.9
	tick(record3)
	equal(live(record3), 1, "sound alive before lifetime")
	now = 2
	tick(record3)
	equal(live(record3), 0, "2s lifetime reclaims sound")

	local record4 = scene("Sil / 鞭影衣饰")
	queueResourceAudio(record4, "挥鞭", 0, nil)
	tick(record4)
	local twice = firstSound(record4)
	disposeResourceSound(record4, twice)
	disposeResourceSound(record4, twice)
	equal(live(record4), 0, "double dispose clears table")
	equal(twice.Ended:Count(), 0, "double dispose keeps single disconnect")

	local record5 = scene("Sil / 鞭影衣饰")
	queueResourceAudio(record5, "挥鞭", 0, nil)
	tick(record5)
	equal(live(record5), 1, "sound live before toggle off")
	resourceAudioEnabled = false
	stopResourceAudio(record5)
	equal(live(record5), 0, "toggle off reclaims sounds")
	check(record5.audioCue == nil, "toggle off clears cue")
end

-- E: PlayerGui 缺失 / Connect 与 Play 期间失效
do
	local record = scene("Sil / 鞭影衣饰")
	detach(playerGuiNode)
	queueResourceAudio(record, "挥鞭", 0, nil)
	tick(record)
	equal(live(record), 0, "no sound without PlayerGui")
	equal(record.audioStatus, "等待 PlayerGui；下次动作重试", "PlayerGui wait status")
	check(record.audioCue == nil, "cue consumed while waiting")
	attach(playerNode, playerGuiNode)
	queueResourceAudio(record, "挥鞭", 0, nil)
	tick(record)
	equal(live(record), 1, "next action retries after PlayerGui returns")

	local record2 = scene("Sil / 鞭影衣饰")
	local realNew = Instance.new
	local created, createdEnded
	Instance.new = function(class)
		local node = realNew(class)
		if class == "Sound" then
			created = node
			createdEnded = node.Ended
			node.Ended = {Connect = function(_, fn)
				resourceRecord = nil
				return createdEnded:Connect(fn)
			end}
		end
		return node
	end
	queueResourceAudio(record2, "挥鞭", 0, nil)
	tick(record2)
	Instance.new = realNew
	equal(live(record2), 0, "superseded at connect is reclaimed")
	equal(created.plays, 0, "superseded sound never plays")
	equal(createdEnded:Count(), 0, "superseded sound connection dropped")
	check(created.Destroyed, "superseded sound destroyed")

	local record3 = scene("Sil / 鞭影衣饰")
	local realNew2 = Instance.new
	local played
	Instance.new = function(class)
		local node = realNew2(class)
		if class == "Sound" then
			played = node
			node.onPlay = function() resourceRecord = nil end
		end
		return node
	end
	queueResourceAudio(record3, "挥鞭", 0, nil)
	tick(record3)
	Instance.new = realNew2
	equal(live(record3), 0, "superseded during play is reclaimed")
	equal(played.plays, 1, "play attempted once")
	check(played.Destroyed, "superseded play destroyed")
	equal(record3.audioStatus, "本地音效就绪 3/3", "superseded play keeps ready status")
end

-- F: 动画监听匹配 / 脉冲 / epoch
do
	local record = scene("Sil / 鞭影衣饰")
	updateResourceAction(record)
	check(record.actionConnection ~= nil, "animator bound")
	equal(record.actionStatus, "已绑定", "bound status")
	equal(animator.AnimationPlayed:Count(), 1, "single AnimationPlayed binding")
	animator.AnimationPlayed:Fire({Animation = {AnimationId = "rbxassetid://999999999"}, IsPlaying = true})
	check(record.audioCue == nil, "non-matching animation queues nothing")
	animator.AnimationPlayed:Fire({Animation = {AnimationId = "rbxassetid://116814116277716"}, IsPlaying = false})
	check(record.audioCue == nil, "paused animation queues nothing")
	animator.AnimationPlayed:Fire({Animation = {AnimationId = 12345}, IsPlaying = true})
	check(record.audioCue == nil, "non-string animation id queues nothing")
	animator.AnimationPlayed:Fire({Animation = {AnimationId = "rbxassetid://116814116277716"}, IsPlaying = true})
	check(record.audioCue ~= nil, "whip animation queues cue")
	equal(record.audioCue.name, "挥鞭", "whip cue name from profile")
	equal(record.audioCue.due, now + 0.45, "whip cue delay from profile")
	updateResourceAction(record)
	equal(animator.AnimationPlayed:Count(), 1, "no duplicate AnimationPlayed binding")

	local record2 = scene("Terio / Manchegan衣饰")
	updateResourceAction(record2)
	animator.AnimationPlayed:Fire({Animation = {AnimationId = "84413781229733"}, IsPlaying = true})
	check(record2.audioCue ~= nil, "slash animation queues cue")
	equal(record2.audioCue.due, now, "slash cue has no delay")

	local record3 = scene("Sil / 鞭影衣饰")
	updateResourceAction(record3)
	queueResourceAudio(record3, "挥鞭", 0, nil)
	record3.audioCue.epoch = (record3.actionEpoch or 0) + 5
	tick(record3)
	check(record3.audioCue == nil, "stale epoch cue dropped")
	check(live(record3) == 0, "stale epoch cue plays nothing")

	local record4 = scene("Sil / 鞭影衣饰")
	updateResourceAction(record4)
	queueResourceAudio(record4, "挥鞭", 0, nil)
	tick(record4)
	equal(live(record4), 1, "sound live before animator swap")
	local replacement = inst("Animator")
	detach(animator)
	attach(hum, replacement)
	updateResourceAction(record4)
	check(record4.actionConnection ~= nil, "rebound after animator swap")
	equal(animator.AnimationPlayed:Count(), 0, "old animator connection dropped")
	check(record4.audioCue == nil, "animator swap clears cue")
	equal(live(record4), 0, "animator swap plays nothing")

	local record5 = scene("Sil / 鞭影衣饰")
	local handle = inst("MeshPart")
	attach(char, handle)
	record5.pulseHandle = handle
	-- pulseHandle 在方案载入后才挂上：重放一次完整绑定，让 pulse 入口生效。
	unbindResourceAction(record5)
	resourceRecord = record5
	updateResourceAction(record5)
	check(record5.actionConnection ~= nil, "pulse profile rebinds animator")
	local before = record5.pulseRequest or 0
	animator.AnimationPlayed:Fire({Animation = {AnimationId = "116814116277716"}, IsPlaying = true})
	check((record5.pulseRequest or 0) > before, "matching animation requests pulse")
	check(record5.pulseStarted ~= nil, "pulse started")
	check(record5.audioCue ~= nil, "whip cue queued alongside pulse")
	detach(handle)
	animator.AnimationPlayed:Fire({Animation = {AnimationId = "116814116277716"}, IsPlaying = true})
	equal(record5.actionStatus, "鞭影触发失效，可重新应用", "detached pulse handle reported")
end

print("test_audio_r34 assertions: " .. assertions .. " (checks " .. checks .. ")")
return true
