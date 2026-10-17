-- ForsakenGuest 参考同步链路专项片段（R35）。
-- 生产 helper 段由 run_sync_r35.mjs 从 src/ForsakenGuest.luau 的
-- "-- Reference chat sync:" 到 "-- End reference chat sync." 区间原样注入；
-- 本文件只提供确定性 Roblox mock、ctx 依赖与断言。
local checks, assertions = 0, 0
local function check(cond, msg)
	checks = checks + 1
	if not cond then error("sync_r35: " .. tostring(msg), 2) end
	assertions = assertions + 1
end
local function equal(got, want, msg)
	checks = checks + 1
	if got ~= want then error(("sync_r35: %s (got %s, want %s)"):format(tostring(msg), tostring(got), tostring(want)), 2) end
	assertions = assertions + 1
end

-- 仅在生产环境缺少对应全局时补齐确定性替身；luau-web 已提供则沿用真实实现。
if not Vector3 then Vector3 = {new = function(x, y, z) return {X = x, Y = y, Z = z} end} end
if not Color3 then Color3 = {new = function(r, g, b) return {R = r, G = g, B = b} end} end
if not CFrame then CFrame = {new = function(...) return {Args = {...}} end} end
local Enum = Enum or {NormalId = {Front = "Front", Back = "Back"}}
if not table.clone then
	table.clone = function(source)
		local out = {}
		for key, value in pairs(source) do out[key] = value end
		return out
	end
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
local function recordingSignal(store)
	local s = signal()
	local baseConnect = s.Connect
	s.Connect = function(self, fn)
		local ok, c = pcall(baseConnect, self, fn)
		if not ok then error("signal connect failed: " .. tostring(c), 0) end
		table.insert(store, c)
		return c
	end
	return s
end
local tracedSignals = {}
local function traceSignal(label, s)
	tracedSignals[label] = s
	return s
end

-- 真实 Instance 语义：Parent 赋值即同步子表，Destroy 即脱离父级。
local function detachFrom(parent, node)
	if not parent then return end
	for i, child in ipairs(parent.children) do
		if child == node then table.remove(parent.children, i); break end
	end
end
local function inst(class, name)
	local node = {ClassName = class, Name = name or class, Destroyed = false, children = {}, destroys = 0}
	local parentValue = nil
	local baseClasses = {Part = "BasePart", MeshPart = "BasePart", Accessory = "Instance", Attachment = "Instance"}
	function node:IsA(want)
		if want == self.ClassName then return true end
		return baseClasses[self.ClassName] == want
	end
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
		local cursor = node.Parent
		while cursor do
			if cursor == root then return true end
			cursor = cursor.Parent
		end
		return false
	end
	function node:Destroy()
		node.Destroyed = true
		node.destroys = node.destroys + 1
		detachFrom(parentValue, node)
		parentValue = nil
		node.children = {}
	end
	setmetatable(node, {
		__index = function(_, key)
			if key == "Parent" then return parentValue end
			return nil
		end,
		__newindex = function(_, key, value)
			if key ~= "Parent" then rawset(node, key, value); return end
			if value == parentValue then return end
			detachFrom(parentValue, node)
			parentValue = value
			if value then table.insert(value.children, node) end
		end,
	})
	return node
end
local Instance = {new = function(class) return inst(class) end}
local function attach(parent, child)
	child.Parent = parent
end
local function detach(node)
	node.Parent = nil
end

local workspaceNode = inst("Workspace")
local playerGui = inst("PlayerGui")
playerGui.Name = "PlayerGui"
local tempUi = inst("Folder")
tempUi.Name = "TemporaryUI"
local playerInfo = inst("Frame")
playerInfo.Name = "PlayerInfo"
local survivors = inst("Frame")
survivors.Name = "CurrentSurvivors"
attach(playerGui, tempUi)
attach(tempUi, playerInfo)
attach(playerInfo, survivors)

local function survivorFrame(username, survivor)
	local frame = inst("Frame")
	local userLabel = inst("TextLabel")
	userLabel.Name, userLabel.Text = "Username", username
	local nameLabel = inst("TextLabel")
	nameLabel.Name, nameLabel.Text = "SurvivorName", survivor
	local iconLabel = inst("ImageLabel")
	iconLabel.Name, iconLabel.Image = "Icon", ""
	attach(frame, userLabel)
	attach(frame, nameLabel)
	attach(frame, iconLabel)
	attach(survivors, frame)
	return frame
end

local localChar = inst("Model", "TwoTime")
local localHum = inst("Humanoid")
localHum.Health = 100
local localRightArm = inst("Part", "Right Arm")
attach(localHum, localRightArm)
attach(localChar, localHum)
attach(localChar, localRightArm)
attach(workspaceNode, localChar)

local localPlayer = inst("Player")
localPlayer.Name = "LocalUser"
localPlayer.Character = localChar
attach(localPlayer, playerGui)
localPlayer.Chatted = signal()
localPlayer.CharacterRemoving = signal()

local remoteChar = inst("Model", "TwoTime")
local remoteHum = inst("Humanoid")
remoteHum.Health = 100
local remoteRightArm = inst("Part", "Right Arm")
attach(remoteHum, remoteRightArm)
attach(remoteChar, remoteHum)
attach(remoteChar, remoteRightArm)
attach(workspaceNode, remoteChar)

local function player(name, char)
	local node = inst("Player")
	node.Name = name
	node.Character = char
	node.Chatted = signal()
	node.CharacterRemoving = signal()
	return node
end
local remotePlayer = player("OtherUser", remoteChar)
remotePlayer.UserId = 4242

local playersNode = inst("Players")
playersNode.LocalPlayer = localPlayer
playersNode.PlayerAdded = signal()
playersNode.PlayerRemoving = signal()
playersNode.GetPlayers = function()
	local out = {}
	for _, child in ipairs(playersNode.children) do table.insert(out, child) end
	return out
end
playersNode.GetPlayerByUserId = function(_, userId)
	for _, child in ipairs(playersNode.children) do
		if child.UserId == userId then return child end
	end
	return nil
end
attach(playersNode, localPlayer)
attach(playersNode, remotePlayer)

local heartbeatStore = {}
local textChat = inst("TextChatService")
textChat.MessageReceived = signal()
local runService = inst("RunService")
runService.Heartbeat = recordingSignal(heartbeatStore)

local tracked = {}
local ctx = {
	Players = playersNode,
	LocalPlayer = localPlayer,
	RunService = runService,
	Workspace = workspaceNode,
	TextChatService = textChat,
	sessionEnv = nil,
	thisSessionId = nil,
	clock = function() return now end,
	track = function(conn) table.insert(tracked, conn); return conn end,
}
local clock = ctx.clock or os.clock
local Players, LocalPlayer, RunService = ctx.Players, ctx.LocalPlayer, ctx.RunService
local destroyed = false
__SYNC_HELPERS__
-- 静态接口闸门由 runner 在组装阶段执行（禁服务端/网络/破坏性调用 + 根级默认关闭 + Destroy 停止）。

local function liveBlades()
	local out = {}
	for _, child in ipairs(remoteChar.children) do
		if child.Name == "VortexionSyncedShadowBlade" then table.insert(out, child) end
	end
	return out
end
local function localBlades()
	local out = {}
	for _, child in ipairs(localChar.children) do
		if child.Name == "VortexionSyncedShadowBlade" then table.insert(out, child) end
	end
	return out
end
local function survivorLabel(owner)
	for _, frame in ipairs(survivors:GetChildren()) do
		local user = frame:FindFirstChild("Username")
		local name = frame:FindFirstChild("SurvivorName")
		if user and user.Text == owner then return name end
	end
	return nil
end
local function remoteSurvivorName()
	local label = survivorLabel("OtherUser")
	return label and label.Text or nil
end
local function localSurvivorName()
	local label = survivorLabel("LocalUser")
	return label and label.Text or nil
end
local function resetWorld()
	now = 0
	destroyed = false
	for _, child in ipairs(remoteChar:GetChildren()) do detach(child) end
	for _, child in ipairs(localChar:GetChildren()) do detach(child) end
	for _, child in ipairs(survivors:GetChildren()) do detach(child) end
	for _, child in ipairs(localPlayer:GetChildren()) do detach(child) end
	attach(localPlayer, playerGui)
	attach(remoteHum, remoteRightArm)
	attach(remoteChar, remoteHum)
	attach(remoteChar, remoteRightArm)
	attach(localHum, localRightArm)
	attach(localChar, localHum)
	attach(localChar, localRightArm)
	localHum.Health, remoteHum.Health = 100, 100
	remoteChar.Name = "TwoTime"
	remotePlayer.Character, localPlayer.Character = remoteChar, localChar
	survivorFrame("OtherUser", "TwoTime")
	survivorFrame("LocalUser", "TwoTime (You)")
	remotePlayer.Chatted = signal()
	localPlayer.Chatted = signal()
	remotePlayer.CharacterRemoving = signal()
	textChat.MessageReceived = signal()
	playersNode.PlayerAdded = signal()
	playersNode.PlayerRemoving = signal()
	heartbeatStore = {}
	runService.Heartbeat = recordingSignal(heartbeatStore)
	tracked = {}
	setChatSyncEnabled(false)
end

-- A: 默认关闭
do
	resetWorld()
	equal(chatSyncEnabled, false, "chat sync off by default")
	equal(chatSyncStatus, "已关闭", "default status")
	remotePlayer.Chatted:Fire(":syncScript")
	check(#liveBlades() == 0, "no blade while disabled")
	equal(remoteSurvivorName(), "TwoTime", "survivor name untouched while disabled")
end

-- B: 精确指令 + 其他玩家 + TwoTime 才执行
do
	resetWorld()
	setChatSyncEnabled(true)
	equal(chatSyncEnabled, true, "chat sync enabled")
	equal(chatSyncStatus, "监听精确指令 :syncScript / _sync_terio_（仅其他玩家本机刀饰 / Terio枪饰与衣饰）", "enabled status")
	remotePlayer.Chatted:Fire("hello :syncScript")
	check(#liveBlades() == 0, "non exact message ignored")
	remotePlayer.Chatted:Fire(":syncscript")
	check(#liveBlades() == 0, "case sensitive command ignored")
	localPlayer.Chatted:Fire(":syncScript")
	check(#localBlades() == 0, "self chat never executes")
	check(#liveBlades() == 0, "self chat never creates remote blade")
	equal(localSurvivorName(), "TwoTime (You)", "self survivor name untouched")

	remotePlayer.Chatted:Fire(":syncScript")
	equal(#liveBlades(), 1, "exact command creates one blade")
	local blade = liveBlades()[1]
	local handle = blade:FindFirstChild("Handle")
	check(handle ~= nil, "blade handle present")
	local mesh = handle and handle:FindFirstChildOfClass("SpecialMesh")
	check(mesh ~= nil, "blade mesh present")
	-- SyncScript.lua:59-60 的 http 资产号在本实现里规范化为 rbxassetid:// 形式。
	equal(mesh.MeshId, "rbxassetid://62275962", "blade mesh id matches reference asset")
	equal(mesh.TextureId, "rbxassetid://62276016", "blade texture id matches reference asset")
	local weld = handle and handle:FindFirstChildOfClass("Weld")
	check(weld ~= nil, "blade weld present")
	equal(weld.Part1, remoteRightArm, "weld targets sender right arm")
	equal(remoteSurvivorName(), "Two Time (Rework)", "survivor name rewritten")

	remotePlayer.Chatted:Fire(":syncScript")
	equal(#liveBlades(), 1, "repeat command does not stack blades")
	equal(#survivors:GetChildren(), 2, "repeat command does not stack label rows")
end

-- C: 非 TwoTime / 死亡 / 缺 Right Arm 不执行
do
	resetWorld()
	setChatSyncEnabled(true)
	remoteChar.Name = "Terio"
	remotePlayer.Chatted:Fire(":syncScript")
	check(#liveBlades() == 0, "non TwoTime sender ignored")
	equal(remoteSurvivorName(), "TwoTime", "non TwoTime sender leaves name")
	remoteChar.Name = "TwoTime"

	remoteHum.Health = 0
	remotePlayer.Chatted:Fire(":syncScript")
	check(#liveBlades() == 0, "dead sender ignored")
	remoteHum.Health = 100

	detach(remoteRightArm)
	remotePlayer.Chatted:Fire(":syncScript")
	check(#liveBlades() == 0, "missing right arm ignored")
end

-- D: TextChatService 路径与 UserId 映射
do
	resetWorld()
	setChatSyncEnabled(true)
	textChat.MessageReceived:Fire({Text = ":syncScript", TextSource = {UserId = 1}})
	check(#liveBlades() == 0, "unknown user id ignored")
	textChat.MessageReceived:Fire({Text = ":syncScript", TextSource = {UserId = 4242}})
	equal(#liveBlades(), 1, "mapped user id executes")
	textChat.MessageReceived:Fire({Text = "not a command", TextSource = {UserId = 4242}})
	equal(#liveBlades(), 1, "non command text ignored")
	textChat.MessageReceived:Fire({Text = ":syncScript", TextSource = {UserId = 99}})
	equal(#liveBlades(), 1, "unmapped user id ignored")
end

-- E: 条件回滚与离场回收
do
	resetWorld()
	setChatSyncEnabled(true)
	remotePlayer.Chatted:Fire(":syncScript")
	equal(#liveBlades(), 1, "blade created before rollback")
	equal(remoteSurvivorName(), "Two Time (Rework)", "name rewritten before rollback")
	stopChatSync()
	equal(chatSyncEnabled, false, "stopChatSync disables")
	equal(#liveBlades(), 0, "stopChatSync removes blades")
	equal(remoteSurvivorName(), "TwoTime", "stopChatSync restores survivor name")
	equal(remotePlayer.Chatted:Count(), 0, "chat listeners disconnected")

	setChatSyncEnabled(true)
	remotePlayer.Chatted:Fire(":syncScript")
	equal(#liveBlades(), 1, "blade recreated after re-enable")
	remotePlayer.CharacterRemoving:Fire(remoteChar)
	equal(#liveBlades(), 0, "CharacterRemoving removes blades")
	equal(remoteSurvivorName(), "TwoTime", "CharacterRemoving restores name")

	setChatSyncEnabled(true)
	remotePlayer.Chatted:Fire(":syncScript")
	equal(#liveBlades(), 1, "blade present before session switch")
	ctx.sessionEnv, ctx.thisSessionId = {VortexionSessionId = "S1"}, "S2"
	runService.Heartbeat:Fire()
	equal(#liveBlades(), 0, "session switch reclaims blades")
	equal(remoteSurvivorName(), "TwoTime", "session switch restores name")
	equal(chatSyncEnabled, false, "session switch disables sync")
	ctx.sessionEnv, ctx.thisSessionId = nil, nil

	setChatSyncEnabled(true)
	remotePlayer.Chatted:Fire(":syncScript")
	equal(#liveBlades(), 1, "blade present before destroy")
	destroyed = true
	stopChatSync()
	equal(#liveBlades(), 0, "destroy reclaims blades")
	equal(remoteSurvivorName(), "TwoTime", "destroy restores name")

	-- 外部先改写了标签：条件回滚必须保留外部改写，不得强行覆盖。
	resetWorld()
	setChatSyncEnabled(true)
	remotePlayer.Chatted:Fire(":syncScript")
	equal(remoteSurvivorName(), "Two Time (Rework)", "label rewritten before external edit")
	local label = survivorLabel("OtherUser")
	label.Text = "Terio"
	stopChatSync()
	equal(remoteSurvivorName(), "Terio", "external survivor name preserved")
end

-- F: 心跳节流、迟到 UI 补齐、旧快照回调不停新 epoch
do
	resetWorld()
	setChatSyncEnabled(true)
	remotePlayer.Chatted:Fire(":syncScript")
	equal(#liveBlades(), 1, "blade live before heartbeat")
	equal(#heartbeatStore, 1, "single heartbeat listener per enable")
	now = 1
	runService.Heartbeat:Fire()
	equal(#liveBlades(), 1, "throttled heartbeat keeps live blade")

	-- UI 重建后旧行失效、新行出现：心跳补齐迟到标签。
	for _, frame in ipairs(survivors:GetChildren()) do detach(frame) end
	survivorFrame("OtherUser", "TwoTime")
	now = now + 1
	runService.Heartbeat:Fire()
	equal(remoteSurvivorName(), "Two Time (Rework)", "heartbeat re-applies label to rebuilt rows")

	-- 陈旧判定：Right Arm 脱离即回收并回滚。
	detach(remoteRightArm)
	now = now + 1
	runService.Heartbeat:Fire()
	equal(#liveBlades(), 0, "stale record reclaimed by heartbeat")
	equal(remoteSurvivorName(), "TwoTime", "stale rollback restores name")
	attach(remoteChar, remoteRightArm)

	-- 旧 epoch 的迟到回调不得关停新一轮监听。
	local stale = heartbeatStore[1]
	setChatSyncEnabled(false)
	setChatSyncEnabled(true)
	equal(chatSyncEnabled, true, "re-enabled after stop")
	stale.FN()
	equal(chatSyncEnabled, true, "stale heartbeat callback keeps new epoch alive")
	equal(#heartbeatStore, 2, "re-enable registers its own heartbeat listener")
	remotePlayer.Chatted:Fire(":syncScript")
	equal(#liveBlades(), 1, "new epoch still receives commands")
	setChatSyncEnabled(false)
end

	local remoteTorso = inst("Part", "Torso")
	local function terioLances()
		local out = {}
		for _, child in ipairs(remoteChar.children) do
			if child.Name == "VortexionSyncedLanceBack" or child.Name == "VortexionSyncedLanceFront" then
				table.insert(out, child)
			end
		end
		return out
	end
	local function recordCount()
		local n = 0
		for _ in pairs(chatSyncRecords) do n += 1 end
		return n
	end
	local function terioRow()
		for _, frame in ipairs(survivors:GetChildren()) do
			local user = frame:FindFirstChild("Username")
			if user and user.Text == "OtherUser" then return frame end
		end
		return nil
	end
	local function terioIcon()
		local row = terioRow()
		return row and row:FindFirstChild("Icon") or nil
	end
	local function cframeKey(cf)
		local args = cf and cf.Args
		if not args then return nil end
		return table.concat(args, ",")
	end
	local function terioReset()
		resetWorld()
		remoteChar.Name = "Shedletsky"
		attach(remoteChar, remoteTorso)
	end
	local function terioBeat()
		now = now + 1
		runService.Heartbeat:Fire()
	end
	-- G: Terio exact command and dual lance structure
	do
		terioReset()
		setChatSyncEnabled(true)
		remotePlayer.Chatted:Fire("_sync_terio_")
		local lances = terioLances()
		equal(#lances, 2, "terio exact command creates both lances")
		equal(#liveBlades(), 0, "terio command creates no blade")
		local back = remoteChar:FindFirstChild("VortexionSyncedLanceBack")
		local front = remoteChar:FindFirstChild("VortexionSyncedLanceFront")
		check(back ~= nil and front ~= nil, "both lances present on character")
		equal(back.Parent, remoteChar, "back lance parented to character")
		equal(front.Parent, remoteChar, "front lance parented to character")
		local backHandle = back:FindFirstChild("Handle")
		local frontHandle = front:FindFirstChild("Handle")
		check(backHandle ~= nil and frontHandle ~= nil, "lance handles present")
		equal(backHandle.Transparency, 0, "back lance handle visible")
		equal(frontHandle.Transparency, 1, "front lance handle initially hidden")
		equal(backHandle.Size.X .. "," .. backHandle.Size.Y .. "," .. backHandle.Size.Z, "1,1,1", "back handle unit size")
		equal(frontHandle.Size.X .. "," .. frontHandle.Size.Y .. "," .. frontHandle.Size.Z, "1,1,1", "front handle unit size")
		equal(backHandle.Color.R, 0.1, "back handle reference color")
		equal(backHandle.Massless, true, "back handle massless")
		equal(backHandle.Anchored, false, "back handle not anchored")
		local backMesh = backHandle:FindFirstChildOfClass("SpecialMesh")
		local frontMesh = frontHandle:FindFirstChildOfClass("SpecialMesh")
		check(backMesh ~= nil and frontMesh ~= nil, "lance meshes present")
		equal(backMesh.MeshId, "rbxassetid://18858726703", "lance mesh id matches reference asset")
		equal(backMesh.TextureId, "rbxassetid://18858727747", "lance texture id matches reference asset")
		equal(frontMesh.MeshId, "rbxassetid://18858726703", "front lance mesh id matches reference asset")
		equal(frontMesh.TextureId, "rbxassetid://18858727747", "front lance texture id matches reference asset")
		equal(backMesh.Scale.X .. "," .. backMesh.Scale.Y .. "," .. backMesh.Scale.Z, "1,1,1", "lance mesh unit scale")
		local backWeld = backHandle:FindFirstChildOfClass("Weld")
		local frontWeld = frontHandle:FindFirstChildOfClass("Weld")
		check(backWeld ~= nil and frontWeld ~= nil, "lance welds present")
		equal(backWeld.Part0, backHandle, "back weld Part0 is handle")
		equal(backWeld.Part1, remoteTorso, "back weld mounts torso")
		equal(frontWeld.Part0, frontHandle, "front weld Part0 is handle")
		equal(frontWeld.Part1, remoteRightArm, "front weld mounts right arm")
		equal(cframeKey(backWeld.C0), "0,-1,-0.5,1,0,0,0,-1,0,0,0,1", "terio back weld C0 matrix")
		equal(cframeKey(backWeld.C1), "0,1,0,1,0,0,0,1,0,0,0,1", "terio back weld C1 matrix")
		equal(cframeKey(frontWeld.C0), "-1,0.400000006,0,0.00999950059,-0.999750197,0.0199924111,0,-0.0199934151,-0.999800086,-0.999950051,-0.00999750197,0.000199924252", "terio front weld C0 matrix")
		equal(cframeKey(frontWeld.C1), "0,1,0,1,0,0,0,1,0,0,0,1", "terio front weld C1 matrix")
		equal(remoteSurvivorName(), "Terio", "terio survivor label written")
	end

-- R40: exercise the same production helper, with both original R35 commands and Terio.
local originalNew = Instance.new
local born, faultAt, birthCount, parentFault, destroyEnable = {}, nil, 0, nil, false
Instance.new = function(class)
 birthCount += 1
 if birthCount == faultAt then error('injected Instance.new failure') end
 local object = originalNew(class)
 table.insert(born, object)
 local mt, oldDestroy = getmetatable(object), object.Destroy
 local oldIndex = mt.__newindex
 mt.__newindex = function(self, key, value)
  if key == 'Parent' and value == remoteChar and parentFault then
   if parentFault == 'throw' and self.Name == 'VortexionSyncedLanceFront' then error('injected publish failure') end
   oldIndex(self, key, value)
   if parentFault == 'disable' then setChatSyncEnabled(false) end
  else oldIndex(self, key, value) end
 end
 object.Destroy = function(self)
  if destroyEnable then setChatSyncEnabled(true) end
  return oldDestroy(self)
 end
 return object
end
local function owned(char)
 local list = {}
 for _, child in ipairs(char:GetChildren()) do
  if child.Name == 'VortexionSyncedLanceBack' or child.Name == 'VortexionSyncedLanceFront' or child.Name == 'VortexionSyncedShadowBlade' then table.insert(list, child) end
 end
 return list
end
local function remoteIcon()
 local label = survivorLabel('OtherUser')
 return label and label.Parent:FindFirstChild('Icon')
end
local function terioWorld()
 faultAt, parentFault, destroyEnable = nil, nil, false
 setChatSyncEnabled(false)
 ctx.sessionEnv, ctx.thisSessionId = nil, nil
 resetWorld()
 remoteChar.Name, localChar.Name = 'Shedletsky', 'TwoTime'
 survivorLabel('OtherUser').Text = 'Shedletsky'
 remoteIcon().Image = 'original-icon'
 local torso = inst('Part', 'Torso')
 attach(remoteChar, torso)
 born, birthCount = {}, 0
 return torso
end
local function assertDisposed(label)
 equal(#owned(remoteChar), 0, label .. ' removes complete accessory set')
 for _, object in ipairs(born) do
  check(object.Destroyed, label .. ' destroys every owned candidate')
  equal(object.destroys, 1, label .. ' destroys candidate once')
 end
end
local function matrix(actual, expected, label)
 equal(#actual.Args, #expected, label .. ' arity')
 for i, value in ipairs(expected) do equal(actual.Args[i], value, label .. ' component ' .. i) end
end

do
 local torso = terioWorld()
 setChatSyncEnabled(true)
 for _, message in ipairs({'hello _sync_terio_', '_SYNC_TERIO_', '_sync_sil_', ':syncScript', '_sync_terio_ '}) do
  remotePlayer.Chatted:Fire(message)
  equal(#owned(remoteChar), 0, 'Terio rejects wrong command ' .. message)
 end
 localPlayer.Chatted:Fire('_sync_terio_')
 equal(#owned(localChar), 0, 'Terio self sender ignored')
 local neighbor = survivorFrame('PrefixOtherUserSuffix', 'Neighbor')
 neighbor:FindFirstChild('Icon').Image = 'neighbor-icon'
 remotePlayer.Chatted:Fire('_sync_terio_')
 equal(#owned(remoteChar), 2, 'Terio exact command creates complete set')
 local back = remoteChar:FindFirstChild('VortexionSyncedLanceBack')
 local front = remoteChar:FindFirstChild('VortexionSyncedLanceFront')
 check(back and front, 'Terio named accessories present')
 for _, accessory in ipairs({back, front}) do
  local handle = accessory:FindFirstChild('Handle')
  local mesh, weld = handle:FindFirstChildOfClass('SpecialMesh'), handle:FindFirstChildOfClass('Weld')
  equal(mesh.MeshId, 'rbxassetid://18858726703', 'Terio mesh reference')
  equal(mesh.TextureId, 'rbxassetid://18858727747', 'Terio texture reference')
  equal(mesh.Scale.X, 1, 'Terio scale x'); equal(mesh.Scale.Y, 1, 'Terio scale y'); equal(mesh.Scale.Z, 1, 'Terio scale z')
  equal(handle.CanCollide, false, 'Terio no collision'); equal(handle.CanTouch, false, 'Terio no touch'); equal(handle.CanQuery, false, 'Terio no query')
  equal(handle.Massless, true, 'Terio massless'); equal(handle.Anchored, false, 'Terio not anchored')
  equal(weld.Part0, handle, 'Terio weld owns handle')
  matrix(weld.C1, {0,1,0,1,0,0,0,1,0,0,0,1}, 'Terio C1')
 end
 local bh, fh = back:FindFirstChild('Handle'), front:FindFirstChild('Handle')
 equal(bh.Transparency, 0, 'Terio back initially visible'); equal(fh.Transparency, 1, 'Terio front remains hidden without animation')
 equal(bh:FindFirstChildOfClass('Weld').Part1, torso, 'Terio back mounts exact torso')
 equal(fh:FindFirstChildOfClass('Weld').Part1, remoteRightArm, 'Terio front mounts exact arm')
 matrix(bh:FindFirstChildOfClass('Weld').C0, {0,-1,-0.5,1,0,0,0,-1,0,0,0,1}, 'Terio back C0')
 matrix(fh:FindFirstChildOfClass('Weld').C0, {-1,0.400000006,0,0.00999950059,-0.999750197,0.0199924111,0,-0.0199934151,-0.999800086,-0.999950051,-0.00999750197,0.000199924252}, 'Terio front C0')
 equal(remoteSurvivorName(), 'Terio', 'Terio name rewritten')
 equal(remoteIcon().Image, 'rbxassetid://115704573151422', 'Terio icon rewritten')
 equal(neighbor:FindFirstChild('SurvivorName').Text, 'Neighbor', 'Terio exact username preserves neighbor name')
 equal(neighbor:FindFirstChild('Icon').Image, 'neighbor-icon', 'Terio exact username preserves neighbor icon')
 remotePlayer.Chatted:Fire('_sync_terio_')
 textChat.MessageReceived:Fire({Text='_sync_terio_',TextSource={UserId=4242}})
 equal(#owned(remoteChar), 2, 'Terio legacy and text chat deduplicate')
 equal(runService.Heartbeat:Count(), 1, 'Terio shares one heartbeat')
 setChatSyncEnabled(false)
 equal(remoteSurvivorName(), 'Shedletsky', 'Terio restores original name')
 equal(remoteIcon().Image, 'original-icon', 'Terio restores original icon')
 assertDisposed('Terio close')
end

do
 terioWorld(); setChatSyncEnabled(true)
 remoteChar.Name = 'Terio'
 remotePlayer.Chatted:Fire('_sync_terio_')
 equal(#owned(remoteChar), 0, 'Terio display name is not accepted character identity')
 remoteChar.Name = 'Shedletsky'; remoteHum.Health = 0
 remotePlayer.Chatted:Fire('_sync_terio_')
 equal(#owned(remoteChar), 0, 'Terio dead sender ignored')
 remoteHum.Health = 100
 local torso = remoteChar:FindFirstChild('Torso'); detach(torso)
 remotePlayer.Chatted:Fire('_sync_terio_')
 equal(#owned(remoteChar), 0, 'Terio missing torso ignored')
 attach(remoteChar, torso); detach(remoteRightArm)
 remotePlayer.Chatted:Fire('_sync_terio_')
 equal(#owned(remoteChar), 0, 'Terio missing arm ignored')
end

do
 terioWorld(); setChatSyncEnabled(true)
 textChat.MessageReceived:Fire({Text='_sync_terio_',TextSource={UserId=4242}})
 equal(#owned(remoteChar), 2, 'Terio modern chat resolves true sender')
 survivorLabel('OtherUser').Text = 'external-name'; remoteIcon().Image = 'external-icon'
 setChatSyncEnabled(false)
 equal(remoteSurvivorName(), 'external-name', 'external Terio name preserved')
 equal(remoteIcon().Image, 'external-icon', 'external Terio icon preserved')
 assertDisposed('Terio external edits')
end

for _, kind in ipairs({'death','character-name','arm-identity','torso-identity','humanoid','character','session','character-removing','player-removing'}) do
 local torso = terioWorld(); setChatSyncEnabled(true)
 remotePlayer.Chatted:Fire('_sync_terio_')
 equal(#owned(remoteChar), 2, 'Terio installed before ' .. kind)
 if kind == 'death' then remoteHum.Health = 0
 elseif kind == 'character-name' then remoteChar.Name = 'Other'
 elseif kind == 'arm-identity' then remoteRightArm.Name = 'RetiredArm'; attach(remoteChar, inst('Part','Right Arm'))
 elseif kind == 'torso-identity' then torso.Name = 'RetiredTorso'; attach(remoteChar, inst('Part','Torso'))
 elseif kind == 'humanoid' then detach(remoteHum)
 elseif kind == 'character' then remotePlayer.Character = localChar
 elseif kind == 'session' then ctx.sessionEnv, ctx.thisSessionId = {VortexionSessionId='old'}, 'new'
 elseif kind == 'character-removing' then remotePlayer.CharacterRemoving:Fire(remoteChar)
 elseif kind == 'player-removing' then playersNode.PlayerRemoving:Fire(remotePlayer) end
 now += 1; runService.Heartbeat:Fire()
 assertDisposed('Terio ' .. kind)
 equal(remoteSurvivorName(), 'Shedletsky', 'Terio stale name restored ' .. kind)
 equal(remoteIcon().Image, 'original-icon', 'Terio stale icon restored ' .. kind)
 remoteRightArm.Name = 'Right Arm'
end

for _, kind in ipairs({'birth','publish','disable','destroy-reentry'}) do
 terioWorld(); setChatSyncEnabled(true)
 if kind == 'birth' then faultAt = 7
 elseif kind == 'publish' then parentFault = 'throw'
 elseif kind == 'disable' then parentFault = 'disable' end
 remotePlayer.Chatted:Fire('_sync_terio_')
 if kind == 'destroy-reentry' then destroyEnable = true; setChatSyncEnabled(false) end
 assertDisposed('Terio transaction ' .. kind)
 equal(remoteSurvivorName(), 'Shedletsky', 'Terio transaction preserves original name ' .. kind)
 equal(remoteIcon().Image, 'original-icon', 'Terio transaction preserves original icon ' .. kind)
 if kind == 'disable' or kind == 'destroy-reentry' then
  equal(chatSyncEnabled, false, 'Terio transaction stays off ' .. kind)
  equal(runService.Heartbeat:Count(), 0, 'Terio transaction disconnects heartbeat ' .. kind)
  equal(remotePlayer.Chatted:Count(), 0, 'Terio transaction disconnects chat ' .. kind)
 end
end

do
 terioWorld(); local icon = remoteIcon(); detach(icon)
 local fake = inst('Frame','Icon'); fake.Image='fake-image'; attach(survivorLabel('OtherUser').Parent,fake)
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire('_sync_terio_')
 equal(fake.Image, 'fake-image', 'Terio ignores non-image icon class')
 equal(remoteSurvivorName(), 'Terio', 'Terio bad icon does not block valid name')
 detach(fake); icon.ClassName='ImageButton'; attach(survivorLabel('OtherUser').Parent,icon)
 now += 1; runService.Heartbeat:Fire()
 equal(icon.Image, 'rbxassetid://115704573151422', 'Terio late ImageButton icon updated')
 setChatSyncEnabled(false)
 equal(icon.Image, 'original-icon', 'Terio late ImageButton icon restored')
end

do
 terioWorld(); setChatSyncEnabled(true)
 local added, chars = {}, {}
 for i=1,33 do
  local isTerio = i%2 == 0
  local char = inst('Model',isTerio and 'Shedletsky' or 'TwoTime')
  local hum, arm, torso = inst('Humanoid'), inst('Part','Right Arm'), inst('Part','Torso')
  hum.Health=100; attach(char,hum); attach(char,arm); attach(char,torso); attach(workspaceNode,char)
  local sender=player('CapUser'..i,char); sender.UserId=5000+i; attach(playersNode,sender)
  table.insert(added,sender); table.insert(chars,char); playersNode.PlayerAdded:Fire(sender)
  sender.Chatted:Fire(isTerio and '_sync_terio_' or ':syncScript')
 end
 local count,total=0,0
 for _ in pairs(chatSyncRecords) do count+=1 end
 for _,char in ipairs(chars) do total+=#owned(char) end
 equal(count,32,'Terio and TwoTime share 32 record cap')
 equal(total,48,'mixed cap counts records not accessory objects')
 equal(#owned(chars[33]),0,'33rd mixed record ignored')
 setChatSyncEnabled(false)
 for i,sender in ipairs(added) do
  equal(#owned(chars[i]),0,'mixed cap cleans all owned cosmetics')
  equal(sender.Chatted:Count(),0,'mixed cap disconnects all senders')
  detach(sender); detach(chars[i])
 end
end
-- R41: real Animator events drive only the locally owned lance handles.
local function animationWorld()
 terioWorld()
 for _, child in ipairs(remoteHum:GetChildren()) do if child:IsA('Animator') then detach(child) end end
 local animator, store = inst('Animator'), {}
 animator.AnimationPlayed = recordingSignal(store)
 attach(remoteHum, animator)
 return animator, store
end
local function lanceHandles()
 return remoteChar:FindFirstChild('VortexionSyncedLanceFront'):FindFirstChild('Handle'), remoteChar:FindFirstChild('VortexionSyncedLanceBack'):FindFirstChild('Handle')
end
local function syncLance()
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire('_sync_terio_')
 return lanceHandles()
end
local function observedTrack(asset)
 local track = {Animation={AnimationId=asset},stops=0,destroys=0}
 function track:Stop() self.stops+=1 end
 function track:Destroy() self.destroys+=1 end
 return track
end

do
 local animator = animationWorld(); local front, back = syncLance()
 equal(animator.AnimationPlayed:Count(),1,'Terio installs one Animator observer')
 for _, bad in ipairs({'184413781229733','rbxassetid://844137812297330','prefix84413781229733','rbxassetid://84413781229733suffix','121781457295101'}) do
  animator.AnimationPlayed:Fire(observedTrack(bad))
  equal(front.Transparency,1,'Terio rejects non-swing asset '..bad)
  equal(back.Transparency,0,'Terio rejected asset preserves back '..bad)
 end
 animator.AnimationPlayed:Fire(nil); animator.AnimationPlayed:Fire({})
 equal(front.Transparency,1,'Terio malformed tracks leave front hidden')
 for _, asset in ipairs({'rbxassetid://84413781229733','84413781229733','http://www.roblox.com/asset/?id=84413781229733'}) do
  local track = observedTrack(asset); animator.AnimationPlayed:Fire(track)
  equal(front.Transparency,0,'Terio exact swing shows front')
  equal(back.Transparency,1,'Terio exact swing hides back')
  equal(track.stops,0,'Terio never stops borrowed track'); equal(track.destroys,0,'Terio never destroys borrowed track')
  now+=2; runService.Heartbeat:Fire()
  equal(front.Transparency,1,'Terio canonical asset window expires')
  equal(back.Transparency,0,'Terio canonical asset restores back')
 end
 setChatSyncEnabled(false); equal(animator.AnimationPlayed:Count(),0,'Terio observer disconnected on close')
 assertDisposed('Terio animation close')
end

do
 local animator = animationWorld(); local front, back = syncLance()
 animator.AnimationPlayed:Fire(observedTrack('84413781229733'))
 now=1.999; runService.Heartbeat:Fire()
 equal(front.Transparency,0,'Terio window stays visible before two seconds')
 now=2; runService.Heartbeat:Fire()
 equal(front.Transparency,1,'Terio deadline restores at exact two seconds')
 equal(back.Transparency,0,'Terio deadline restores back before slow sweep')
 equal(runService.Heartbeat:Count(),1,'Terio deadlines reuse shared heartbeat')
 setChatSyncEnabled(false)
end

do
 local animator = animationWorld(); local front = syncLance()
 animator.AnimationPlayed:Fire(observedTrack('84413781229733'))
 now=1.5; animator.AnimationPlayed:Fire(observedTrack('84413781229733'))
 now=2; runService.Heartbeat:Fire()
 equal(front.Transparency,0,'Terio latest swing keeps new window alive')
 now=3.499; runService.Heartbeat:Fire()
 equal(front.Transparency,0,'Terio refreshed window stays visible before deadline')
 now=3.5; runService.Heartbeat:Fire()
 equal(front.Transparency,1,'Terio latest window expires at new deadline')
 setChatSyncEnabled(false)
end

do
 local animator, store = animationWorld(); local front = syncLance()
 local stale = store[1]
 animator.AnimationPlayed:Fire(observedTrack('84413781229733'))
 detach(animator)
 local replacement = inst('Animator'); replacement.AnimationPlayed=signal(); attach(remoteHum,replacement)
 stale.FN(observedTrack('84413781229733'))
 now=1; runService.Heartbeat:Fire()
 equal(animator.AnimationPlayed:Count(),0,'Terio old Animator observer disconnected')
 equal(replacement.AnimationPlayed:Count(),1,'Terio replacement Animator rebound')
 equal(front.Transparency,1,'Terio Animator replacement restores initial visibility')
 equal(#owned(remoteChar),2,'Terio Animator replacement keeps accessory pair')
 stale.FN(observedTrack('84413781229733'))
 equal(front.Transparency,1,'Terio stale Animator callback ignored')
 replacement.AnimationPlayed:Fire(observedTrack('84413781229733'))
 equal(front.Transparency,0,'Terio replacement Animator drives front')
 setChatSyncEnabled(false); equal(replacement.AnimationPlayed:Count(),0,'Terio replacement observer cleaned')
end

do
 local animator, store = animationWorld(); syncLance()
 local stale, count = store[1], #born
 animator.AnimationPlayed:Fire(observedTrack('84413781229733'))
 setChatSyncEnabled(false); assertDisposed('Terio active window shutdown')
 equal(animator.AnimationPlayed:Count(),0,'Terio active shutdown disconnects Animator')
 stale.FN(observedTrack('84413781229733')); now=5; runService.Heartbeat:Fire()
 equal(#born,count,'Terio stale callback allocates nothing')
 equal(#owned(remoteChar),0,'Terio stale callback does not resurrect pair')
 local front = syncLance()
 stale.FN(observedTrack('84413781229733'))
 equal(front.Transparency,1,'Terio old epoch cannot show new record')
 animator.AnimationPlayed:Fire(observedTrack('84413781229733'))
 equal(front.Transparency,0,'Terio new epoch observer remains functional')
 setChatSyncEnabled(false)
end

do
 local animator, store = animationWorld()
 local connect = animator.AnimationPlayed.Connect
 animator.AnimationPlayed.Connect=function(self,fn)
  local candidate=connect(self,fn); setChatSyncEnabled(false); return candidate
 end
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire('_sync_terio_')
 equal(chatSyncEnabled,false,'Terio Connect return after close stays disabled')
 equal(animator.AnimationPlayed:Count(),0,'Terio late Connect candidate disconnected')
 equal(#store,1,'Terio late Connect actually produced a candidate')
 assertDisposed('Terio late Connect')
end

do
 local animator = animationWorld(); local attempts=0
 animator.AnimationPlayed.Connect=function() attempts+=1; error('injected Animator Connect failure') end
 local front = syncLance()
 equal(#owned(remoteChar),2,'Terio observer failure retains passive cosmetic pair')
 equal(front.Transparency,1,'Terio observer failure keeps initial state')
 now=1; runService.Heartbeat:Fire(); now=2; runService.Heartbeat:Fire()
 equal(attempts,1,'Terio failed Animator not retried every heartbeat')
 detach(animator)
 local replacement=inst('Animator'); replacement.AnimationPlayed=signal(); attach(remoteHum,replacement)
 now=3; runService.Heartbeat:Fire()
 equal(replacement.AnimationPlayed:Count(),1,'Terio observer failure recovers on Animator replacement')
 replacement.AnimationPlayed:Fire(observedTrack('84413781229733'))
 equal(front.Transparency,0,'Terio recovered observer shows front')
 setChatSyncEnabled(false)
end

do
 local animator=animationWorld(); detach(animator)
 local front=syncLance()
 equal(front.Transparency,1,'Terio absent Animator keeps initial cosmetic')
 attach(remoteHum,animator); now=1; runService.Heartbeat:Fire()
 equal(animator.AnimationPlayed:Count(),1,'Terio late Animator gets observer')
 animator.AnimationPlayed:Fire(observedTrack('84413781229733'))
 equal(front.Transparency,0,'Terio late Animator drives visibility')
 setChatSyncEnabled(false)
 local sounds=0
 for _,object in ipairs(born) do if object.ClassName=='Sound' then sounds+=1 end end
 equal(sounds,0,'Terio visibility branch does not create sounds')
 assertDisposed('Terio late Animator close')
end

-- R42: borrowed appearance is patched per property; only missing instances are owned.
local function lookWorld(borrowed)
 terioWorld()
 local head = inst("Part", "Head"); attach(remoteChar,head)
 if not borrowed then return head end
 local shirt,pants,face = inst("Shirt","OriginalShirt"),inst("Pants","OriginalPants"),inst("Decal","OriginalFace")
 shirt.ShirtTemplate,pants.PantsTemplate,face.Texture = "old-shirt","old-pants","old-face"
 shirt.Color3,pants.Color3,face.Color3 = Color3.new(.2,.3,.4),Color3.new(.4,.5,.6),Color3.new(.6,.7,.8)
 face.Face,face.Transparency = Enum.NormalId.Front,.4
 attach(remoteChar,shirt); attach(remoteChar,pants); attach(head,face)
 return head,shirt,pants,face
end
local function white(object,label)
 equal(object.Color3.R,1,label.." red"); equal(object.Color3.G,1,label.." green"); equal(object.Color3.B,1,label.." blue")
end
local function borrowedIntact(shirt,pants,face,label)
 for _,object in ipairs({shirt,pants,face}) do equal(object.destroys,0,label.." never destroys borrowed "..object.ClassName) end
end
local function interceptProperty(object,property,callback)
 local value = object[property]
 rawset(object,property,nil)
 local mt = getmetatable(object)
 local index,newindex = mt.__index,mt.__newindex
 mt.__index = function(self,key) if key==property then return value end; return index(self,key) end
 mt.__newindex = function(self,key,nextValue)
  if key==property then callback(nextValue,function() value=nextValue end) else newindex(self,key,nextValue) end
 end
end
do
 local head,shirt,pants,face = lookWorld(true)
 local oldShirtColor,oldPantsColor,oldFaceColor = shirt.Color3,pants.Color3,face.Color3
 local otherFace=inst("Decal","BackDecal"); otherFace.Face,otherFace.Texture=Enum.NormalId.Back,"back-face"; attach(head,otherFace)
 local expression=inst("Model","ExpressionHolder"); attach(head,expression)
 local sword=inst("Accessory","Sword"); attach(remoteChar,sword)
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
 equal(shirt.ShirtTemplate,"rbxassetid://13132949672","Terio borrowed shirt exact asset")
 equal(pants.PantsTemplate,"rbxassetid://13132951176","Terio borrowed pants exact asset")
 equal(face.Texture,"rbxassetid://133089396665213","Terio borrowed face exact asset")
 white(shirt,"Terio shirt tint"); white(pants,"Terio pants tint"); white(face,"Terio face tint")
 equal(face.Transparency,0,"Terio front face opaque")
 equal(otherFace.Texture,"back-face","Terio nonfront decal untouched")
 equal(#born,8,"Terio borrowed appearance allocates only two lances")
 equal(shirt.Parent,remoteChar,"Terio shirt never detached"); equal(face.Parent,head,"Terio face never detached")
 setChatSyncEnabled(false)
 equal(shirt.ShirtTemplate,"old-shirt","Terio restores borrowed shirt")
 equal(pants.PantsTemplate,"old-pants","Terio restores borrowed pants")
 equal(face.Texture,"old-face","Terio restores borrowed face")
 equal(shirt.Color3,oldShirtColor,"Terio restores shirt tint"); equal(pants.Color3,oldPantsColor,"Terio restores pants tint"); equal(face.Color3,oldFaceColor,"Terio restores face tint")
 equal(face.Transparency,.4,"Terio restores face opacity")
 equal(expression.Parent,head,"Terio preserves expression holder"); equal(sword.Parent,remoteChar,"Terio preserves original sword")
 borrowedIntact(shirt,pants,face,"Terio normal close"); assertDisposed("Terio borrowed close")
end
do
 local head=lookWorld(false)
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
 local shirt,pants,face=remoteChar:FindFirstChild("VortexionSyncedShirt"),remoteChar:FindFirstChild("VortexionSyncedPants"),head:FindFirstChild("VortexionSyncedDecal")
 check(shirt and pants and face,"Terio missing appearance creates full set")
 equal(shirt.ShirtTemplate,"rbxassetid://13132949672","Terio owned shirt exact asset")
 equal(pants.PantsTemplate,"rbxassetid://13132951176","Terio owned pants exact asset")
 equal(face.Texture,"rbxassetid://133089396665213","Terio owned face exact asset")
 equal(face.Face,Enum.NormalId.Front,"Terio owned face is Front"); equal(face.Transparency,0,"Terio owned face visible")
 equal(#born,11,"Terio missing appearance owns exactly eleven instances")
 remotePlayer.Chatted:Fire("_sync_terio_"); equal(#born,11,"Terio duplicate does not create clothing")
 setChatSyncEnabled(false); assertDisposed("Terio owned appearance close")
end
do
 local _,shirt,pants,face=lookWorld(true)
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
 local color=Color3.new(.9,.8,.7)
 shirt.ShirtTemplate,shirt.Color3,face.Texture,face.Transparency="external-shirt",color,"external-face",.75
 now=1; runService.Heartbeat:Fire()
 equal(shirt.ShirtTemplate,"external-shirt","Terio heartbeat does not reapply borrowed property")
 setChatSyncEnabled(false)
 equal(shirt.ShirtTemplate,"external-shirt","Terio external shirt preserved")
 equal(shirt.Color3,color,"Terio external tint preserved")
 equal(face.Texture,"external-face","Terio external face preserved"); equal(face.Transparency,.75,"Terio external opacity preserved")
 equal(pants.PantsTemplate,"old-pants","Terio untouched pants still restored")
 borrowedIntact(shirt,pants,face,"Terio external writes"); assertDisposed("Terio external writes")
end
do
 local _,shirt,pants,face=lookWorld(true)
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
 local elsewhere=inst("Model","ExternalOwner"); attach(elsewhere,shirt); attach(elsewhere,face)
 setChatSyncEnabled(false)
 equal(shirt.Parent,elsewhere,"Terio external shirt parent preserved"); equal(face.Parent,elsewhere,"Terio external face parent preserved")
 equal(shirt.ShirtTemplate,"rbxassetid://13132949672","Terio handed-off shirt not rewritten")
 equal(face.Texture,"rbxassetid://133089396665213","Terio handed-off face not rewritten")
 equal(pants.PantsTemplate,"old-pants","Terio same-owner pants restored")
 borrowedIntact(shirt,pants,face,"Terio handoff"); assertDisposed("Terio handoff")
end
for _,mode in ipairs({"head-replace","head-detach","death","respawn","session","destroy"}) do
 local head,shirt,pants,face=lookWorld(true)
 if mode=="session" then ctx.sessionEnv,ctx.thisSessionId={VortexionSessionId="old"},"old" end
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
 if mode=="head-replace" then detach(head); attach(remoteChar,inst("Part","Head"))
 elseif mode=="head-detach" then detach(head)
 elseif mode=="death" then remoteHum.Health=0
 elseif mode=="respawn" then remotePlayer.CharacterRemoving:Fire(remoteChar)
 elseif mode=="session" then ctx.sessionEnv.VortexionSessionId="new"
 else destroyed=true end
 now=1; runService.Heartbeat:Fire()
 equal(shirt.ShirtTemplate,"old-shirt","Terio invalid appearance restores shirt "..mode)
 equal(face.Texture,"old-face","Terio invalid appearance restores original head face "..mode)
 equal(chatSyncRecords[remotePlayer],nil,"Terio invalid appearance clears record "..mode)
 borrowedIntact(shirt,pants,face,"Terio invalid "..mode); assertDisposed("Terio invalid "..mode)
 setChatSyncEnabled(false)
end
for _,failure in ipairs({9,10,11}) do
 lookWorld(false); faultAt=failure
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
 equal(chatSyncRecords[remotePlayer],nil,"Terio partial appearance construction rolls back "..failure)
 equal(remoteSurvivorName(),"Shedletsky","Terio failed appearance leaves UI original "..failure)
 assertDisposed("Terio appearance construction failure "..failure); setChatSyncEnabled(false)
end
for _,mode in ipairs({"close-before","close-after","close-before-throw","close-after-throw","write-throw","throw-before"}) do
 local _,shirt,pants,face=lookWorld(true)
 local fired=false
 interceptProperty(shirt,"ShirtTemplate",function(value,commit)
  if value=="rbxassetid://13132949672" and not fired then
   fired=true
   if mode=="close-before" or mode=="close-before-throw" then setChatSyncEnabled(false) end
   if mode=="throw-before" then error("injected appearance setter failure before write") end
   commit()
   if mode=="close-after" or mode=="close-after-throw" then setChatSyncEnabled(false) end
   if mode=="write-throw" or mode=="close-before-throw" or mode=="close-after-throw" then error("injected appearance setter failure after write") end
  else commit() end
 end)
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
 check(fired,"Terio setter failure injected "..mode)
 equal(shirt.ShirtTemplate,"old-shirt","Terio setter interruption compensates late write "..mode)
 equal(pants.PantsTemplate,"old-pants","Terio setter interruption leaves pants "..mode)
 equal(face.Texture,"old-face","Terio setter interruption leaves face "..mode)
 equal(chatSyncRecords[remotePlayer],nil,"Terio setter interruption clears record "..mode)
 borrowedIntact(shirt,pants,face,"Terio setter "..mode); assertDisposed("Terio setter "..mode)
 setChatSyncEnabled(false)
end
do
 local _,shirt,pants,face=lookWorld(true)
 local applied,reentered=false,false
 interceptProperty(shirt,"ShirtTemplate",function(value,commit)
  commit()
  if value=="rbxassetid://13132949672" then applied=true
  elseif applied and value=="old-shirt" and not reentered then
   reentered=true; remoteHum.Health=100; remotePlayer.Chatted:Fire("_sync_terio_")
  end
 end)
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
 remoteHum.Health=0; now=1; runService.Heartbeat:Fire()
 check(reentered,"Terio cleanup property callback actually reentered")
 equal(chatSyncRecords[remotePlayer],nil,"Terio cleanup callback cannot recreate a record")
 borrowedIntact(shirt,pants,face,"Terio cleanup reentry"); assertDisposed("Terio cleanup reentry"); setChatSyncEnabled(false)
end
do
 lookWorld(true); remoteChar.Name="TwoTime"
 local shirt=remoteChar:FindFirstChild("OriginalShirt")
 setChatSyncEnabled(true); remotePlayer.Chatted:Fire(":syncScript")
 equal(shirt.ShirtTemplate,"old-shirt","TwoTime sync does not change appearance")
 equal(#born,4,"TwoTime still creates only the original blade set")
 setChatSyncEnabled(false); assertDisposed("TwoTime appearance unchanged")
end
Instance.new = originalNew
equal(runService.Heartbeat:Count(),0,'R40 leaves no heartbeat')
equal(chatSyncEnabled,false,'R40 leaves sync disabled')

-- R43: deterministic face pulses share the existing heartbeat.
do
 local base, pulse = "rbxassetid://133089396665213", "rbxassetid://127552301758353"
 local function world(borrowed)
  local head,shirt,pants,face=lookWorld(borrowed)
  for _,child in ipairs(remoteHum:GetChildren()) do if child:IsA("Animator") then detach(child) end end
  local animator,store=inst("Animator"),{}
  animator.AnimationPlayed=recordingSignal(store); attach(remoteHum,animator)
  setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
  return head,face or head:FindFirstChild("VortexionSyncedDecal"),animator,store
 end
 local function beat(t) now=t; runService.Heartbeat:Fire() end
 local function fire(animator,asset)
  local track=observedTrack(asset or "121781457295101"); animator.AnimationPlayed:Fire(track); return track
 end
 local function close(face,label)
  setChatSyncEnabled(false); assertDisposed(label)
  equal(runService.Heartbeat:Count(),0,label.." disconnects heartbeat")
  equal(chatSyncRecords[remotePlayer],nil,label.." clears record")
 end
 for _,asset in ipairs({"121781457295101","rbxassetid://121781457295101","http://www.roblox.com/asset/?id=121781457295101"}) do
  local _,face,animator=world(true); local track=fire(animator,asset)
  equal(face.Texture,base,"Terio event only schedules face")
  beat(1.999); equal(face.Texture,base,"Terio face delayed until two seconds")
  beat(2); equal(face.Texture,pulse,"Terio face changes at exact two seconds")
  beat(2.549); equal(face.Texture,pulse,"Terio face remains before nominal deadline")
  beat(2.55); equal(face.Texture,base,"Terio face restores at nominal deadline")
  equal(track.stops,0,"Terio face never stops borrowed track"); equal(track.destroys,0,"Terio face never destroys borrowed track")
  equal(runService.Heartbeat:Count(),1,"Terio face uses shared heartbeat")
  close(face,"Terio face canonical"); equal(face.Texture,"old-face","Terio canonical restores original")
 end
 do
  local _,face,animator=world(true)
  for _,bad in ipairs({"1217814572951010","prefix121781457295101","rbxassetid://121781457295101suffix","84413781229733"}) do
   fire(animator,bad); now+=3; runService.Heartbeat:Fire(); equal(face.Texture,base,"Terio face rejects other exact assets")
  end
  fire(animator); beat(now+2); equal(face.Texture,pulse,"Terio face active before close")
  close(face,"Terio pulse close"); equal(face.Texture,"old-face","Terio pulse close restores original face")
 end
 do
  local _,face,animator=world(false); fire(animator); beat(2)
  equal(face.Texture,pulse,"Terio owned Front pulses"); close(face,"Terio owned pulse")
  equal(face.destroys,1,"Terio owned face destroyed once")
 end
 do
  local _,face,animator=world(true); fire(animator); now=1; fire(animator)
  beat(2); equal(face.Texture,base,"Terio latest pending event supersedes old deadline")
  beat(3); equal(face.Texture,pulse,"Terio latest pending event runs")
  now=3.1; fire(animator); equal(face.Texture,base,"Terio active pulse reset by newer event")
  beat(5.1); equal(face.Texture,pulse,"Terio replacement pulse runs")
  close(face,"Terio latest pulse")
 end
 do
  local _,face,animator=world(true); fire(animator); beat(3)
  equal(face.Texture,base,"Terio skipped entire window never flashes")
  equal(chatSyncRecords[remotePlayer].FaceAt,nil,"Terio expired pending request consumed")
  close(face,"Terio skipped pulse")
 end
 for _,when in ipairs({"before","during"}) do
  local _,face,animator=world(true); fire(animator)
  if when=="during" then beat(2) end
  face.Texture="external-pulse"; beat(2.55); close(face,"Terio external pulse")
  equal(face.Texture,"external-pulse","Terio external pulse texture preserved")
 end
 do
  local _,face,animator=world(true); fire(animator); beat(2)
  local other=inst("Part","OtherOwner"); attach(other,face); beat(2.55); close(face,"Terio pulse handoff")
  equal(face.Parent,other,"Terio pulse parent handoff preserved")
  equal(face.Texture,pulse,"Terio handed-off pulse not rewritten")
  equal(face.destroys,0,"Terio handed-off borrowed face survives")
 end
 for _,phase in ipairs({"pending","active"}) do
  for _,mode in ipairs({"head","animator","death","respawn","session","destroy","leave"}) do
   local head,face,animator,store=world(true); local stale=store[1].FN; fire(animator)
   if phase=="active" then beat(2) end
   if mode=="head" then detach(head); attach(remoteChar,inst("Part","Head"))
   elseif mode=="animator" then detach(animator); attach(remoteHum,inst("Animator"))
   elseif mode=="death" then remoteHum.Health=0
   elseif mode=="respawn" then remotePlayer.CharacterRemoving:Fire(remoteChar)
   elseif mode=="session" then ctx.sessionEnv,ctx.thisSessionId={VortexionSessionId="new"},"old"
   elseif mode=="destroy" then destroyed=true
   else playersNode.PlayerRemoving:Fire(remotePlayer) end
   beat(now+.01); stale(observedTrack("121781457295101"))
   if mode=="animator" then equal(face.Texture,base,"Terio Animator change clears pulse")
   else equal(face.Texture,"old-face","Terio invalid identity restores original "..phase..mode) end
   close(face,"Terio invalid pulse "..phase..mode)
   equal(face.Texture,"old-face","Terio invalid pulse closes both snapshots")
  end
 end
 for _,mode in ipairs({"close-before","close-after","close-before-throw","close-after-throw","write-throw","throw-before"}) do
  local _,face,animator=world(true); local fired=false
  interceptProperty(face,"Texture",function(value,commit)
   if value==pulse and not fired then
    fired=true
    if mode=="close-before" or mode=="close-before-throw" then setChatSyncEnabled(false) end
    if mode=="throw-before" then error("injected pulse before write") end
    commit()
    if mode=="close-after" or mode=="close-after-throw" then setChatSyncEnabled(false) end
    if string.find(mode,"throw",1,true) then error("injected pulse after write") end
   else commit() end
  end)
  fire(animator); beat(2); check(fired,"Terio pulse setter fault reached "..mode)
  equal(face.Texture,"old-face","Terio pulse compensates late write "..mode)
  close(face,"Terio pulse setter "..mode)
 end
 for _,trigger in ipairs({"deadline","new-event"}) do
  local _,face,animator=world(true); fire(animator); beat(2); local fired=false
  interceptProperty(face,"Texture",function(value,commit)
   if value==base and not fired then fired=true; setChatSyncEnabled(false); commit() else commit() end
  end)
  if trigger=="deadline" then beat(2.55) else fire(animator) end
  check(fired,"Terio pulse reset close-before reached "..trigger)
  equal(face.Texture,"old-face","Terio pulse reset compensates both snapshots "..trigger)
  close(face,"Terio reset setter "..trigger)
 end
 do
  local _,face,animator=world(true); fire(animator); local stale=animator.AnimationPlayed.handlers[1].FN
  close(face,"Terio stale epoch first"); setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_")
  stale(observedTrack("121781457295101")); beat(2)
  equal(face.Texture,base,"Terio stale epoch callback does not pulse new record")
  close(face,"Terio stale epoch second")
 end
 for _,object in ipairs(born) do check(object.ClassName~="Sound" and object.ClassName~="Highlight","Terio face creates no sound or highlight") end
 equal(chatSyncEnabled,false,"R43 ends disabled")
end
-- R45: a bounded direct-part skin snapshot shares the appearance transaction.
do
 local function skinWorld()
  local head=lookWorld(true)
  local parts={remoteRightArm,remoteChar:FindFirstChild("Torso"),head}
  for _,name in ipairs({"Left Arm","Right Leg","Left Leg","HumanoidRootPart"}) do
   local part=inst("Part",name); attach(remoteChar,part); table.insert(parts,part)
  end
  local colors={} 
  for i,part in ipairs(parts) do colors[i]=Color3.new(i/10,.25,.75); part.Color=colors[i] end
  local body=inst("BodyColors","Body Colors"); body.HeadColor3=Color3.new(.8,.2,.1); attach(remoteChar,body)
  local accessory=inst("Accessory","OriginalHair"); attach(remoteChar,accessory)
  local handle=inst("Part","Handle"); handle.Color=Color3.new(.1,.2,.3); attach(accessory,handle)
  return parts,colors,body,accessory,handle
 end
 local function start() setChatSyncEnabled(true); remotePlayer.Chatted:Fire("_sync_terio_") end
 local function isWhite(part,label)
  check(part.Color and part.Color.R==1 and part.Color.G==1 and part.Color.B==1,label)
 end
 do
  local parts,colors,body,accessory,handle=skinWorld(); local bodyColor,handleColor=body.HeadColor3,handle.Color
  start()
  for _,part in ipairs(parts) do isWhite(part,"Terio skin applies exact reference white") end
  local size=#chatSyncRecords[remotePlayer].Appearance; remotePlayer.Chatted:Fire("_sync_terio_")
  equal(#chatSyncRecords[remotePlayer].Appearance,size,"Terio repeated skin request preserves original snapshots")
  equal(body.HeadColor3,bodyColor,"Terio BodyColors preserved"); equal(handle.Color,handleColor,"Terio accessory descendants untouched")
  local newPart=inst("Part","LaterPart"); newPart.Color=Color3.new(.2,.5,.8); local color=newPart.Color; attach(remoteChar,newPart)
  now=5; runService.Heartbeat:Fire(); equal(newPart.Color,color,"Terio skin does not continuously recolor new parts")
  setChatSyncEnabled(false)
  for i,part in ipairs(parts) do equal(part.Color,colors[i],"Terio skin close restores snapshot"); equal(part.destroys,0,"Terio skin never destroys borrowed body") end
  equal(body.Parent,remoteChar,"Terio keeps BodyColors object"); equal(accessory.Parent,remoteChar,"Terio keeps original hair"); assertDisposed("Terio skin close")
 end
 do
  local parts,colors=skinWorld(); start(); local external=Color3.new(1,0,0); parts[3].Color=external
  local other=inst("Model","Handoff"); attach(other,parts[2]); local applied=parts[2].Color
  setChatSyncEnabled(false)
  equal(parts[3].Color,external,"Terio external skin preserved")
  equal(parts[2].Color,applied,"Terio handed-off skin not rewritten"); equal(parts[2].Parent,other,"Terio skin preserves new owner")
  equal(parts[1].Color,colors[1],"Terio unaffected skin still restored")
 end
 for _,mode in ipairs({"close-before","close-after","close-before-throw","close-after-throw","write-throw","throw-before"}) do
  local parts,colors=skinWorld(); local fired=false
  interceptProperty(parts[3],"Color",function(value,commit)
   if value and value.R==1 and not fired then
    fired=true
    if mode=="close-before" or mode=="close-before-throw" then setChatSyncEnabled(false) end
    if mode=="throw-before" then error("injected skin before write") end
    commit()
    if mode=="close-after" or mode=="close-after-throw" then setChatSyncEnabled(false) end
    if string.find(mode,"throw",1,true) then error("injected skin after write") end
   else commit() end
  end)
  start(); check(fired,"Terio skin setter fault reached "..mode)
  for i,part in ipairs(parts) do equal(part.Color,colors[i],"Terio skin setter compensates "..mode) end
  equal(chatSyncRecords[remotePlayer],nil,"Terio skin setter fault removes record"); assertDisposed("Terio skin setter "..mode)
  setChatSyncEnabled(false)
 end
 for _,mode in ipairs({"death","respawn","session","destroy","leave","head"}) do
  local parts,colors=skinWorld(); start()
  if mode=="death" then remoteHum.Health=0
  elseif mode=="respawn" then remotePlayer.CharacterRemoving:Fire(remoteChar)
  elseif mode=="session" then ctx.sessionEnv,ctx.thisSessionId={VortexionSessionId="new"},"old"
  elseif mode=="destroy" then destroyed=true
  elseif mode=="leave" then playersNode.PlayerRemoving:Fire(remotePlayer)
  else detach(parts[3]); attach(remoteChar,inst("Part","Head")) end
  now=1; runService.Heartbeat:Fire()
  for i,part in ipairs(parts) do
   if mode~="head" or i~=3 then equal(part.Color,colors[i],"Terio invalid skin identity restores "..mode) end
  end
  setChatSyncEnabled(false); assertDisposed("Terio skin invalid "..mode)
 end
 do
  skinWorld()
  local state={Name="UserdataLimb",Parent=remoteChar,Color=Color3.new(.3,.6,.9)}; local original=state.Color
  local part=newproxy(true); local mt=getmetatable(part)
  mt.__index=function(_,key) if key=="IsA" then return function(_,kind) return kind=="BasePart" end end; return state[key] end
  mt.__newindex=function(_,key,value)
   if key=="Parent" then
    detachFrom(state.Parent,part); state.Parent=value
    if value then table.insert(value.children,part) end
   else state[key]=value end
  end
  table.insert(remoteChar.children,part); start()
  equal(type(part),"userdata","Terio skin fixture exercises userdata"); isWhite(part,"Terio skin supports userdata parts")
  setChatSyncEnabled(false); equal(part.Color,original,"Terio userdata skin restored")
 end
 do
  skinWorld()
  while #remoteChar.children<256 do attach(remoteChar,inst("Folder","Padding")) end
  local part=inst("Part","AfterBound"); part.Color=Color3.new(.1,.2,.3); local original=part.Color; attach(remoteChar,part)
  start(); check(chatSyncRecords[remotePlayer]~=nil,"Terio bounded skin record published")
  equal(part.Color,original,"Terio skin scan is bounded at 256 direct children")
  setChatSyncEnabled(false); assertDisposed("Terio bounded skin")
 end
 equal(chatSyncEnabled,false,"R45 ends disabled")
end
print("test_sync_r35 assertions: " .. assertions .. " (checks " .. checks .. ")")
return true
