-- Vortexion - Forsaken · Guest 特权组模块 (Guest Group)
-- 借鉴来源: Auto-Trick (幂等/查重/cleanup 全库最佳实践) / Auto-Block-V4 (自定义动画) /
--           Fake-Block (char/Humanoid 双门) / forsaken_hub (防重复加载标志)
return function(ctx)
	local Players = ctx.Players
	local LocalPlayer = ctx.LocalPlayer
	local RunService = ctx.RunService
	local Workspace = ctx.Workspace
	local track = ctx.track
	local Fluent = ctx.Fluent
	local Tabs = ctx.Tabs
	local sessionEnv = ctx.sessionEnv

	local function notify(title, content)
		if Fluent then
			pcall(function()
				Fluent:Notify({ Title = title, Content = content, Duration = 5 })
			end)
		end
	end

	-- CoreGui 回退 PlayerGui: 附件 Fake-Block:7/:14
	local function getGuiHost()
		local ok, core = pcall(function() return game:GetService("CoreGui") end)
		if ok and core then
			local ok2, existing = pcall(function() return core:FindFirstChild("VortexionGuestGui") end)
			if ok2 then return core end
		end
		return LocalPlayer:FindFirstChild("PlayerGui")
	end

	-- 查重防双 GUI: 附件 Auto-Trick:165-167 + forsaken_hub:250
	local function ensureSingleGui(name)
		local host = getGuiHost()
		if not host then return nil end
		local existing = host:FindFirstChild(name)
		if existing then
			pcall(function() existing:Destroy() end)
		end
		return host
	end

	-- Keep the old lifecycle API and option ID, but let WindUI own all controls.
	local guestState = {}
	local playCustomAnim, stopAnimations
	local destroyed, fakeVariant = false, "Normal"
	-- 自定义动画播放参数：仅写局部量，影响下一次本地播放，不改现有 Track
	local animationSpeed, animationLoop = 100, false
	local function setEnabled(key, value)
		if guestState[key] == value then return end
		guestState[key] = value
	end

	local function destroyFakeBlockGui()
		guestState.FakeBlock = false
		if stopAnimations then stopAnimations() end
		ensureSingleGui("VortexionGuestGui")
		local option = Fluent and Fluent.Options and Fluent.Options.GuestFakeBlockGui
		if option and option.Value then option:SetValue(false) end
	end

	local function buildFakeBlockGui()
		ensureSingleGui("VortexionGuestGui")
		setEnabled("FakeBlock", true)
		local option = Fluent and Fluent.Options and Fluent.Options.GuestFakeBlockGui
		if option and not option.Value then option:SetValue(true) end
	end

	local function triggerFakeBlock()
		if not guestState.FakeBlock then
			notify("假格挡", "请先启用假格挡。")
			return
		end
		local char = LocalPlayer and LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if not (char and hum) then
			notify("假格挡", "角色或 Humanoid 未就绪")
			return
		end
		local id = fakeVariant == "M3 / M4" and "96959123077498" or "72722244508749"
		local ok, err = playCustomAnim(id)
		notify("假格挡", ok and "本地动画已播放" or tostring(err))
		return ok, err
	end

	ensureSingleGui("VortexionGuestGui")

	---------------------------------------------------------------------------
	-- 自定义动画安全播放: Animator/animId 门 + pcall LoadAnimation + 节流
	-- 附件 Auto-Block-V4:353-397 / Chance-V2:358-365
	---------------------------------------------------------------------------
	local clock = ctx.clock or os.clock
	local lastAnimAt = -math.huge
	local activeTrack, stoppedConn = nil, nil
	local disposedTracks = setmetatable({}, {__mode = "k"})
	local animationRevision = 0
	local function disposeTrack(current, connection)
		if connection then pcall(function() connection:Disconnect() end) end
		if current and not disposedTracks[current] then
			-- Stop may synchronously re-enter disposal through Stopped.
			disposedTracks[current] = true
			pcall(function() current:Stop(0.1) end)
			pcall(function() current:Destroy() end)
		end
	end
	local function clearActiveTrack()
		local current, connection = activeTrack, stoppedConn
		activeTrack, stoppedConn = nil, nil
		disposeTrack(current, connection)
	end
	stopAnimations = function()
		animationRevision += 1
		clearActiveTrack()
	end
	playCustomAnim = function(animId)
		if destroyed then return false, "模块已关闭" end
		if type(animId) ~= "string" then return false, "动画 ID 格式错误" end
		local id = animId:match("^rbxassetid://(%d+)$") or animId:match("^(%d+)$")
		if not id or tonumber(id) == 0 then return false, "请输入纯数字或 rbxassetid://数字" end
		if clock() - lastAnimAt < 0.35 then return false, "播放过于频繁" end
		local char, hum, animator
		local ready = pcall(function()
			char = LocalPlayer.Character
			hum = char and char:FindFirstChildOfClass("Humanoid")
			animator = hum and hum:FindFirstChildOfClass("Animator")
		end)
		if not ready or not hum or not animator then return false, "Animator 未就绪" end
		animationRevision += 1
		local revision = animationRevision
		local function current()
			local ok, value = pcall(function()
				return not destroyed and revision == animationRevision and LocalPlayer.Character == char
					and (not sessionEnv or ctx.thisSessionId == nil or sessionEnv.VortexionSessionId == ctx.thisSessionId)
					and char.Parent ~= nil and hum.Parent == char and hum.Health > 0 and animator.Parent == hum
			end)
			return ok and value == true
		end
		if not current() then return false, "角色已失效" end
		local animation, result
		local ok = pcall(function()
			animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. id
			result = animator:LoadAnimation(animation)
		end)
		if animation then pcall(function() animation:Destroy() end) end
		if not ok or not result then disposeTrack(result); return false, "LoadAnimation 失败" end
		if not current() then disposeTrack(result); return false, "播放请求已失效" end
		local stoppedEarly = false
		local connected, connection = pcall(function()
			return result.Stopped:Connect(function()
				stoppedEarly = true
				if activeTrack == result then stopAnimations() end
			end)
		end)
		if not connected or not connection or stoppedEarly or not current() then
			disposeTrack(result, connected and connection or nil)
			return false, "动画回收监听未就绪"
		end
		clearActiveTrack()
		if not current() or stoppedEarly then disposeTrack(result, connection); return false, "播放请求已失效" end
		activeTrack, stoppedConn = result, connection
		ok = pcall(function() result.Looped = animationLoop; result:Play(0.1, 1, animationSpeed / 100) end)
		if not ok or not current() or activeTrack ~= result or stoppedEarly then
			if activeTrack == result then stopAnimations() else disposeTrack(result, connection) end
			return false, "播放失败或请求已失效"
		end
		lastAnimAt = clock()
		return true
	end

	-- Local locomotion only: no movement parameters or server ability state are written.
	local locomotionProfiles = {
		["Terio"] = {Idle = "138598353840498", Walk = "136463880292090"},
		["TwoTime / 蹲伏"] = {Intro = "98606150731314", IntroDelay = 0.15, Idle = "74530436512522", Walk = "94721495253171"},
	}
	local locomotionEnabled, locomotionProfile, locomotionStatus = false, "Terio", "已关闭"
	local locomotionEpoch, locomotionChar, locomotionRemoving, locomotionAttempt = 0, nil, nil, nil
	local locomotionRecord, locomotionPending, locomotionStep, locomotionRemove, locomotionToggle, locomotionAttemptAnimator
	local locomotionReleaseDepth, locomotionToggleSync = 0, false
	local function releaseLocomotion(record)
		if not record or record.disposed then return end
		record.disposed = true
		locomotionReleaseDepth += 1
		local introConnection = record.introConnection
		record.introConnection = nil
		if introConnection then pcall(function() introConnection:Disconnect() end) end
		for _, current in pairs(record.tracks) do disposeTrack(current) end
		for animation in pairs(record.animations) do
			record.animations[animation] = nil
			pcall(function() animation:Destroy() end)
		end
		locomotionReleaseDepth -= 1
	end
	local function resetLocomotion()
		locomotionEpoch += 1
		local current, pending = locomotionRecord, locomotionPending
		locomotionRecord, locomotionPending, locomotionAttempt, locomotionChar, locomotionAttemptAnimator = nil, nil, nil, nil, nil
		releaseLocomotion(current); releaseLocomotion(pending)
	end
	local function locomotionCurrent(record)
		return not destroyed and locomotionEnabled and not record.disposed and record.epoch == locomotionEpoch
			and record.char == LocalPlayer.Character and record.char ~= locomotionRemoving and record.char.Parent ~= nil
			and record.hum.Parent == record.char and record.hum.Health > 0 and record.animator.Parent == record.hum
			and (not sessionEnv or ctx.thisSessionId == nil or sessionEnv.VortexionSessionId == ctx.thisSessionId)
	end
	local function finishLocomotionIntro(record, delay)
		record.introDone = true
		local intro, connection = record.tracks.Intro, record.introConnection
		record.tracks.Intro, record.introConnection = nil, nil
		disposeTrack(intro, connection)
		if not locomotionCurrent(record) then return false end
		local readyAt = delay and clock() + delay or nil
		if not locomotionCurrent(record) then return false end
		record.introReadyAt = readyAt
		return true
	end
	local function loadLocomotion(char, hum, animator)
		local profile = locomotionProfiles[locomotionProfile]
		local record = {char = char, hum = hum, animator = animator, epoch = locomotionEpoch, tracks = {}, animations = {}, introDelay = profile.IntroDelay}
		locomotionPending, locomotionAttempt, locomotionAttemptAnimator, locomotionStatus = record, char, animator, "载入中"
		local spawned = pcall(function() task.spawn(function()
			local ok = pcall(function()
				for _, name in ipairs({"Idle", "Walk", "Intro"}) do
					if profile[name] then
						assert(locomotionCurrent(record), "locomotion load cancelled")
						local animation = Instance.new("Animation")
						record.animations[animation] = true
						animation.AnimationId = "rbxassetid://" .. profile[name]
						local current = animator:LoadAnimation(animation)
						if record.animations[animation] then
							record.animations[animation] = nil
							pcall(function() animation:Destroy() end)
						end
						if not locomotionCurrent(record) then disposeTrack(current); error("late locomotion track") end
						assert(current, "locomotion track missing")
						record.tracks[name] = current
						current.Looped = name ~= "Intro"
						current.Priority = name == "Intro" and Enum.AnimationPriority.Action or (name == "Idle" and Enum.AnimationPriority.Idle or Enum.AnimationPriority.Movement)
					end
				end
				local intro = record.tracks.Intro
				if intro then
					local connected, candidate = pcall(function()
						return intro.Stopped:Connect(function()
							-- Latch only; disposal runs in the existing locomotion tick.
							if not destroyed and locomotionEnabled and not record.disposed and record.epoch == locomotionEpoch and record.introStarted and not record.introDone then record.introStopped = true end
						end)
					end)
					local readable, current = pcall(locomotionCurrent, record)
					if not connected or not candidate or not readable or not current then
						if connected and candidate then pcall(function() candidate:Disconnect() end) end
						error("locomotion intro listener cancelled")
					end
					record.introConnection = candidate
				end
				assert(locomotionCurrent(record), "locomotion commit stale")
				locomotionRecord = record
			end)
			if locomotionPending == record then locomotionPending = nil end
			if not ok then
				if locomotionRecord == record then locomotionRecord = nil end
				releaseLocomotion(record)
			end
			if not destroyed and locomotionEnabled and record.epoch == locomotionEpoch then
				locomotionStatus = ok and "已就绪" or "动画载入失败，点重新应用重试"
			end
		end) end)
		if not spawned then
			if locomotionPending == record then locomotionPending = nil end
			releaseLocomotion(record)
			if record.epoch == locomotionEpoch then locomotionStatus = "异步载入不可用" end
		end
	end
	local function driveLocomotion(record)
		if record.failed or not locomotionCurrent(record) then return end
		local hum = record.hum
		local phase = hum:GetState().Name
		local paused = activeTrack ~= nil or hum.Sit or hum.PlatformStand or phase == "Jumping" or phase == "Freefall"
			or phase == "Climbing" or phase == "Swimming" or phase == "Dead" or phase == "Seated"
		local intro = record.tracks.Intro
		if intro and not record.introDone then
			if record.introStarted then
				if paused then
					if not finishLocomotionIntro(record) then return end
				else
					local playing, expired = intro.IsPlaying, clock() >= record.introDeadline
					if record.introStopped or not playing or expired then
						record.introTimedOut = expired and playing and not record.introStopped
						if not finishLocomotionIntro(record, record.introDelay) then return end
					else locomotionStatus = "蹲伏起手"; return end
				end
			elseif not paused then
				-- A bounded local presentation, not the ability duration or cooldown.
				record.introDeadline = clock() + 8
				if not locomotionCurrent(record) then return end
				record.introStarted = true
				local ok = pcall(function() intro:Play(0.12, 1, 1) end)
				if not ok or not locomotionCurrent(record) then
					if not record.disposed then record.failed = true; locomotionStatus = "起手播放失败，点重新应用重试"; finishLocomotionIntro(record) end
					return
				end
				locomotionStatus = "蹲伏起手"; return
			else locomotionStatus = "让位于当前动作"; return end
		end
		if record.introReadyAt then
			if not paused and clock() < record.introReadyAt then locomotionStatus = "起手衔接"; return end
			record.introReadyAt = nil
		end
		local wanted = not paused and (hum.MoveDirection.Magnitude > 0.01 and "Walk" or "Idle") or nil
		if wanted == record.playing then
			if not wanted then locomotionStatus = "让位于当前动作"; return end
			local readable, playing = pcall(function() return record.tracks[wanted].IsPlaying end)
			if not locomotionCurrent(record) then return end
			if not readable then record.failed = true; locomotionStatus = "动画状态读取失败，点重新应用重试"; return end
			if playing then return end
		end
		local old, nextTrack = record.playing and record.tracks[record.playing], wanted and record.tracks[wanted]
		if nextTrack then
			local ok = pcall(function() nextTrack:Play(0.12, 1, 1) end)
			if not ok or not locomotionCurrent(record) then
				if not record.disposed then pcall(function() nextTrack:Stop(0.12) end) end
				if not record.disposed then record.failed = true; locomotionStatus = "动画播放失败，点重新应用重试" end
				return
			end
		end
		record.playing = wanted
		if old and old ~= nextTrack then pcall(function() old:Stop(0.12) end) end
		if not locomotionCurrent(record) then return end
		locomotionStatus = (wanted == "Walk" and "行走" or wanted == "Idle" and "待机" or "让位于当前动作") .. (record.introTimedOut and "（起手超时已跳过）" or "")
	end
	local function tickLocomotion()
		if destroyed or not locomotionEnabled or locomotionReleaseDepth > 0 then return end
		local char = LocalPlayer.Character
		if char ~= locomotionChar then resetLocomotion(); locomotionChar = char end
		if not char or char == locomotionRemoving or char.Parent == nil then
			if locomotionRecord or locomotionPending or locomotionAttempt then resetLocomotion(); locomotionChar = char end
			locomotionStatus = "等待角色"; return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		local owner = locomotionRecord or locomotionPending
		if owner and (owner.hum ~= hum or owner.animator ~= animator or not locomotionCurrent(owner)) then
			resetLocomotion(); locomotionChar = char
		end
		if not hum or not animator or hum.Health <= 0 then locomotionStatus = "等待存活角色的 Animator"; return end
		if not locomotionRecord then
			if locomotionAttempt ~= char or locomotionAttemptAnimator ~= animator then loadLocomotion(char, hum, animator) end
			return
		end
		driveLocomotion(locomotionRecord)
	end
	local function setLocomotionEnabled(value)
		local enabled = value == true
		if destroyed and enabled then return end
		if not enabled then
			locomotionEnabled = false
			local step, removing = locomotionStep, locomotionRemove
			locomotionStep, locomotionRemove, locomotionRemoving = nil, nil, nil
			if step then pcall(function() step:Disconnect() end) end
			if removing then pcall(function() removing:Disconnect() end) end
			resetLocomotion(); locomotionStatus = "已关闭"
			if locomotionToggle and not locomotionToggleSync then
				locomotionToggleSync = true
				pcall(function() locomotionToggle:SetValue(false) end)
				locomotionToggleSync = false
			end
			return
		end
		if locomotionEnabled then return end
		locomotionEnabled = true
		local lastTick = -math.huge
		local ok = pcall(function()
			locomotionRemove = LocalPlayer.CharacterRemoving:Connect(function(old)
				locomotionRemoving = old; resetLocomotion(); locomotionStatus = "等待重生"
			end)
			locomotionStep = RunService.Heartbeat:Connect(function()
				if clock() - lastTick < 0.1 then return end
				lastTick = clock()
				if sessionEnv and ctx.thisSessionId ~= nil and sessionEnv.VortexionSessionId ~= ctx.thisSessionId then setLocomotionEnabled(false); return end
				local ready = pcall(tickLocomotion)
				if not ready then setLocomotionEnabled(false); locomotionStatus = "角色动作状态读取失败" end
			end)
			track(locomotionRemove); track(locomotionStep)
		end)
		if not ok or destroyed or not locomotionEnabled then setLocomotionEnabled(false) end
	end
	local function setLocomotionProfile(value)
		if destroyed or not locomotionProfiles[value] or value == locomotionProfile then return end
		locomotionProfile = value
		resetLocomotion()
	end
	-- Local Sil presentation only; source tracks are borrowed, never destroyed.
	local sil = {enabled = false, epoch = 0, serial = 0, status = "已关闭"}
	local silMap = {
		["93368339913846"] = {id = "140035118771958", delay = 0.45, speed = 1},
		["119429069577280"] = {id = "128730974312965", delay = 0, speed = 1.65},
	}
	local function silCurrent(owner)
		return sil.enabled and not destroyed and owner and owner.epoch == sil.epoch
			and LocalPlayer.Character == owner.char and owner.char ~= sil.removing and owner.char.Parent ~= nil
			and owner.hum.Parent == owner.char and owner.hum.Health > 0 and owner.animator.Parent == owner.hum
			and owner.char:FindFirstChildOfClass("Humanoid") == owner.hum and owner.hum:FindFirstChildOfClass("Animator") == owner.animator
			and (not sessionEnv or ctx.thisSessionId == nil or sessionEnv.VortexionSessionId == ctx.thisSessionId)
	end
	local function releaseSil(record)
		if not record or record.disposed then return end
		record.disposed = true
		if sil.owned == record then sil.owned = nil end
		disposeTrack(record.track, record.connection)
	end
	local function resetSil()
		sil.epoch += 1; sil.serial += 1
		sil.releaseDepth = (sil.releaseDepth or 0) + 1
		local connection, owned = sil.connection, sil.owned
		sil.connection, sil.owner, sil.pending, sil.owned = nil, nil, nil, nil
		if connection then pcall(function() connection:Disconnect() end) end
		releaseSil(owned)
		sil.releaseDepth -= 1
	end
	local function silRequestCurrent(request)
		return silCurrent(request.owner) and request.serial == sil.serial and request.original.IsPlaying == true
	end
	local function replaceSil(request)
		if not silRequestCurrent(request) then return end
		local animation, result
		local ok = pcall(function()
			animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. request.spec.id
			result = request.owner.animator:LoadAnimation(animation)
		end)
		if animation then pcall(function() animation:Destroy() end) end
		if not ok or not result then
			disposeTrack(result)
			if silCurrent(request.owner) and request.serial == sil.serial then sil.status = "动画载入失败，保留原动作" end
			return
		end
		local record = {track = result, owner = request.owner}
		if not silRequestCurrent(request) then releaseSil(record); return end
		local connected, connection = pcall(function()
			return result.Stopped:Connect(function()
				record.ended = true
				if sil.owned == record then releaseSil(record) end
			end)
		end)
		record.connection = connected and connection or nil
		if not connected or not connection or record.ended or not silRequestCurrent(request) then releaseSil(record); return end
		ok = pcall(function() result.Looped = false; result:Play(0.1, 1, request.spec.speed) end)
		if not ok or record.ended or not silRequestCurrent(request) then releaseSil(record); return end
		local old = sil.owned
		sil.owned, record.expiresAt = record, clock() + 15
		releaseSil(old)
		if sil.owned ~= record or not silRequestCurrent(request) then releaseSil(record); return end
		-- Commit the replacement before suppressing the original; failed loads leave it alone.
		local stopped = pcall(function() request.original:Stop() end)
		if not stopped then
			releaseSil(record)
			if silCurrent(record.owner) then sil.status = "原动作停止失败，撤回替换" end
			return
		end
		if sil.owned == record and silCurrent(record.owner) then sil.status = "本地动作已替换" end
	end
	local function bindSil(char, hum, animator)
		local owner = {char = char, hum = hum, animator = animator, epoch = sil.epoch}
		sil.owner = owner
		local ok, connection = pcall(function()
			return animator.AnimationPlayed:Connect(function(original)
				local readable, err = pcall(function()
					if not silCurrent(owner) or not original or original.IsPlaying ~= true then return end
					local value = original.Animation and original.Animation.AnimationId
					local id = type(value) == "string" and (value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$"))
					local spec = id and silMap[id]
					if not spec or (sil.pending and sil.pending.original == original) then return end
					sil.serial += 1
					local request = {owner = owner, original = original, spec = spec, serial = sil.serial, due = clock() + spec.delay}
					sil.pending = nil
					if spec.delay > 0 then sil.pending = request else replaceSil(request) end
				end)
				if not readable and silCurrent(owner) then sil.status = "动画观察失败：" .. tostring(err) end
			end)
		end)
		if not ok or not connection or not silCurrent(owner) then
			if ok and connection then pcall(function() connection:Disconnect() end) end
			if sil.owner == owner then sil.status = "动画监听未就绪，关闭后重试" end
			return
		end
		sil.connection, sil.status = connection, "监听本机两项Sil动作"
	end
	local setSilAnimationEnabled
	setSilAnimationEnabled = function(value)
		local enabled = value == true and not destroyed
		if not enabled then
			sil.enabled = false; sil.setup = (sil.setup or 0) + 1
			local step, removing = sil.step, sil.remove
			sil.step, sil.remove, sil.removing = nil, nil, nil
			if step then pcall(function() step:Disconnect() end) end
			if removing then pcall(function() removing:Disconnect() end) end
			resetSil(); sil.status = "已关闭"
			if sil.toggle and not sil.sync then
				sil.sync = true; pcall(function() sil.toggle:SetValue(false) end); sil.sync = false
			end
			return
		end
		if sil.enabled or (sil.releaseDepth or 0) > 0 then return end
		sil.enabled = true; sil.setup = (sil.setup or 0) + 1
		local setup = sil.setup
		local function connectSil(key, signal, fn)
			local connection = signal:Connect(fn)
			if not connection then error("Sil listener missing") end
			if not sil.enabled or destroyed or sil.setup ~= setup then
				pcall(function() connection:Disconnect() end); error("Sil listener setup cancelled")
			end
			sil[key] = connection
		end
		local lastBind = -math.huge
		local function tickSil()
			if not sil.enabled or destroyed then return end
			if sessionEnv and ctx.thisSessionId ~= nil and sessionEnv.VortexionSessionId ~= ctx.thisSessionId then setSilAnimationEnabled(false); return end
			local t = clock()
			if t - lastBind >= 0.1 then
				lastBind = t
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local animator = hum and hum:FindFirstChildOfClass("Animator")
				local owner = sil.owner
				if owner and (not silCurrent(owner) or owner.hum ~= hum or owner.animator ~= animator) then resetSil() end
				if not sil.enabled or destroyed then return end
				if not sil.owner and char and char ~= sil.removing and char.Parent and hum and hum.Health > 0 and animator and animator.Parent == hum then bindSil(char, hum, animator) end
			end
			local pending = sil.pending
			if pending and t >= pending.due then sil.pending = nil; replaceSil(pending) end
			local owned = sil.owned
			if owned and (not silCurrent(owned.owner) or t >= owned.expiresAt or not owned.track.IsPlaying) then releaseSil(owned) end
		end
		local ok, err = pcall(function()
			connectSil("remove", LocalPlayer.CharacterRemoving, function(old) sil.removing = old; resetSil() end)
			connectSil("step", RunService.Heartbeat, function()
				local success, failure = pcall(tickSil)
				if not success then resetSil(); sil.status = "动画刷新失败：" .. tostring(failure) end
			end)
			tickSil()
		end)
		if not ok and sil.setup == setup then setSilAnimationEnabled(false); sil.status = "动画监听失败：" .. tostring(err) end
	end

	local function stopAllAnimations()
		setSilAnimationEnabled(false)
		stopAnimations(); setLocomotionEnabled(false)
	end

	-- Reference chat sync: SyncScript.lua:24-78 / Terio_Survivor.lua:1243-1428; local cosmetics only.
	local chatSyncEnabled, chatSyncStatus, chatSyncEpoch = false, "已关闭", 0
	local chatSyncRecords, chatSyncBindings, chatSyncConnections = {}, {}, {}
	local setChatSyncEnabled, chatSyncToggle
	local chatSyncToggleSync, chatSyncReleaseDepth = false, 0
	local function chatSyncCurrent(epoch)
		return not destroyed and chatSyncEnabled and epoch == chatSyncEpoch
			and (not ctx.sessionEnv or ctx.thisSessionId == nil or ctx.sessionEnv.VortexionSessionId == ctx.thisSessionId)
	end
	local function chatRecordCurrent(record)
		local ok, value = pcall(function()
			return chatSyncCurrent(record.Epoch) and chatSyncRecords[record.Player] == record
				and record.Player.Parent == Players and record.Player.Character == record.Character
				and record.Character.Parent ~= nil and record.Character.Name == record.CharacterName
				and record.Humanoid.Parent == record.Character and record.Humanoid.Health > 0
				and record.Arm.Parent == record.Character and record.Character:FindFirstChild("Right Arm") == record.Arm
				and (not record.Torso or (record.Torso.Parent == record.Character and record.Character:FindFirstChild("Torso") == record.Torso))
				and (not record.Head or (record.Head.Parent == record.Character and record.Character:FindFirstChild("Head") == record.Head))
		end)
		return ok and value == true
	end
	local function restoreChatLook(entry)
		pcall(function()
			if entry.Object.Parent == entry.Owner and entry.Object[entry.Property] == entry.Applied then
				entry.Object[entry.Property] = entry.Original
			end
		end)
	end
	local function resetChatFace(record)
		chatSyncReleaseDepth += 1
		local edits, appearance = record.FaceEdits or {}, record.Appearance or {}
		record.FaceAt, record.FaceUntil, record.FaceAnimator, record.FaceEdits = nil, nil, nil, nil
		for i = #edits, 1, -1 do restoreChatLook(edits[i]) end
		if chatSyncRecords[record.Player] ~= record then
			for i = #appearance, 1, -1 do restoreChatLook(appearance[i]) end
		end
		chatSyncReleaseDepth -= 1
	end
	local function releaseChatRecord(record)
		chatSyncReleaseDepth += 1
		if chatSyncRecords[record.Player] == record then chatSyncRecords[record.Player] = nil end
		local items, labels, icons, animation, appearance = record.Items, record.Labels, record.Icons, record.LanceConnection, record.Appearance or {}
		record.Items, record.Labels, record.Icons, record.Appearance = {}, {}, {}, {}
		record.LanceAnimator, record.LanceConnection, record.LanceUntil = nil, nil, nil
		if animation then pcall(function() animation:Disconnect() end) end
		for label, original in pairs(labels) do
			pcall(function() if label.Text == record.LabelText then label.Text = original end end)
		end
		for icon, original in pairs(icons) do
			pcall(function() if icon.Image == record.IconImage then icon.Image = original end end)
		end
		resetChatFace(record)
		for i = #appearance, 1, -1 do restoreChatLook(appearance[i]) end
		for i = #items, 1, -1 do pcall(function() items[i]:Destroy() end) end
		chatSyncReleaseDepth -= 1
	end
	local function setChatLanceVisible(record, visible)
		if not chatRecordCurrent(record) then return false end
		local ok = pcall(function()
			local front, back = record.LanceFront, record.LanceBack
			if not (front and back and front.Parent and back.Parent
				and front.Parent.Parent == record.Character and back.Parent.Parent == record.Character) then error("stale lance handles") end
			front.Transparency = visible and 0 or 1
			if chatRecordCurrent(record) then back.Transparency = visible and 1 or 0 end
		end)
		if not ok then releaseChatRecord(record) end
		return ok and chatRecordCurrent(record)
	end
	local function chatLanceAnimatorCurrent(record, animator)
		local ok, valid = pcall(function()
			return chatRecordCurrent(record) and record.LanceAnimator == animator
				and animator.Parent == record.Humanoid and record.Humanoid:FindFirstChildOfClass("Animator") == animator
		end)
		return ok and valid == true
	end
	local function compensateChatFace(record, entry, appearance)
		restoreChatLook(entry)
		-- A late pulse write may outlive both pulse and appearance cleanup.
		if chatSyncRecords[record.Player] ~= record then
			for i = #appearance, 1, -1 do restoreChatLook(appearance[i]) end
		end
	end
	local function tickChatFace(record, at)
		if not record.FaceAt and not record.FaceUntil then return end
		if not chatLanceAnimatorCurrent(record, record.FaceAnimator) then
			resetChatFace(record)
			if not chatRecordCurrent(record) then releaseChatRecord(record) end
			return
		end
		if record.FaceUntil then
			if at >= record.FaceUntil then resetChatFace(record) end
			return
		end
		if at < record.FaceAt then return end
		-- Nominal reference hold: 0.15s lead + 0.20s fade-in + 0.20s hold.
		local deadline = record.FaceAt + 0.55
		if at >= deadline then resetChatFace(record); return end
		record.FaceAt, record.FaceUntil = nil, deadline
		local edits, appearance = {}, record.Appearance or {}
		record.FaceEdits = edits
		local ok = pcall(function()
			for _, face in ipairs(record.Faces or {}) do
				if not chatLanceAnimatorCurrent(record, record.FaceAnimator) or record.FaceEdits ~= edits then return end
				if face.Parent == record.Head and face.Face == Enum.NormalId.Front and face.Texture == "rbxassetid://133089396665213" then
					local entry = {Object = face, Owner = record.Head, Property = "Texture", Original = face.Texture, Applied = "rbxassetid://127552301758353"}
					table.insert(edits, entry)
					local written = pcall(function() face.Texture = entry.Applied end)
					if not written or not chatLanceAnimatorCurrent(record, record.FaceAnimator) or record.FaceEdits ~= edits or face.Parent ~= entry.Owner then
						compensateChatFace(record, entry, appearance)
						releaseChatRecord(record); return
					end
				end
			end
		end)
		if not ok then releaseChatRecord(record) end
	end
	local function refreshChatLance(record)
		if not record.LanceFront or not chatRecordCurrent(record) then return end
		local ok, animator = pcall(function() return record.Humanoid:FindFirstChildOfClass("Animator") end)
		if not ok or record.LanceAnimator == animator then return end
		local previous = record.LanceConnection
		record.LanceAnimator, record.LanceConnection, record.LanceUntil = animator, nil, nil
		if previous then pcall(function() previous:Disconnect() end) end
		resetChatFace(record)
		if not setChatLanceVisible(record, false) or not animator then return end
		local connected, connection = pcall(function()
			return animator.AnimationPlayed:Connect(function(track)
				if chatSyncReleaseDepth > 0 or not chatLanceAnimatorCurrent(record, animator) then return end
				local read, asset = pcall(function() return track.Animation.AnimationId end)
				if not read or type(asset) ~= "string" then return end
				local id = asset:match("^rbxassetid://(%d+)$") or asset:match("^(%d+)$")
					or asset:match("^https?://www%.roblox%.com/asset/%?id=(%d+)$")
				if id == "121781457295101" then
					resetChatFace(record)
					if chatLanceAnimatorCurrent(record, animator) then
						record.FaceAt, record.FaceAnimator = clock() + 2, animator
					end
					return
				end
				if id ~= "84413781229733" then return end
				-- Latest event owns the two-second window; no per-track tasks or borrowed-track writes.
				record.LanceUntil = clock() + 2
				setChatLanceVisible(record, true)
			end)
		end)
		if connected and connection then
			if chatLanceAnimatorCurrent(record, animator) then record.LanceConnection = connection
			else pcall(function() connection:Disconnect() end) end
		end
	end
	local function updateChatLabel(record)
		if not chatRecordCurrent(record) then return end
		pcall(function()
			local panel = LocalPlayer:FindFirstChild("PlayerGui")
			for _, name in ipairs({"TemporaryUI", "PlayerInfo", "CurrentSurvivors"}) do
				panel = panel and panel:FindFirstChild(name)
			end
			if not panel then return end
			for _, row in ipairs(panel:GetChildren()) do
				local username, label = row:FindFirstChild("Username"), row:FindFirstChild("SurvivorName")
				if row:IsA("Frame") and username and username.Text == record.Player.Name and chatRecordCurrent(record) then
					if label and label:IsA("TextLabel") and record.Labels[label] == nil then
						local original = label.Text
						if original ~= record.LabelText then
							record.Labels[label] = original
							label.Text = record.LabelText
							if not chatRecordCurrent(record) then releaseChatRecord(record); return end
						end
					end
					local icon = row:FindFirstChild("Icon")
					if record.IconImage and icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) and record.Icons[icon] == nil then
						local original = icon.Image
						if original ~= record.IconImage then
							record.Icons[icon] = original
							icon.Image = record.IconImage
							if not chatRecordCurrent(record) then releaseChatRecord(record); return end
						end
					end
				end
			end
		end)
	end
	local function receiveChatSync(player, message, epoch)
		if chatSyncReleaseDepth > 0 or not chatSyncCurrent(epoch) or (message ~= ":syncScript" and message ~= "_sync_terio_") or player == LocalPlayer then return end
		local record
		local ok = pcall(function()
			if not player or player.Parent ~= Players then return end
			local existing = chatSyncRecords[player]
			if existing then
				if chatRecordCurrent(existing) then return end
				releaseChatRecord(existing)
			end
			local count = 0
			for _ in pairs(chatSyncRecords) do count += 1 end
			if count >= 32 then return end
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local arm = char and char:FindFirstChild("Right Arm")
			local terio = message == "_sync_terio_"
			local characterName = terio and "Shedletsky" or "TwoTime"
			local torso = terio and char and char:FindFirstChild("Torso")
			if not (char and char.Name == characterName and hum and hum.Health > 0 and arm and arm:IsA("BasePart")) then return end
			if terio and not (torso and torso:IsA("BasePart")) then return end
			record = {Player = player, Character = char, CharacterName = characterName, Humanoid = hum, Arm = arm, Torso = torso, Epoch = epoch, Items = {}, Appearance = {},
				LabelText = terio and "Terio" or "Two Time (Rework)", IconImage = terio and "rbxassetid://115704573151422" or nil,
				Labels = setmetatable({}, {__mode = "k"}), Icons = setmetatable({}, {__mode = "k"})}
			chatSyncRecords[player] = record
			local function create(className, parent)
				local object = Instance.new(className)
				table.insert(record.Items, object)
				if parent then object.Parent = parent end
				return object
			end
			local function weapon(name, mount, meshId, textureId, scale, transparency, c0)
				local accessory = create("Accessory")
				accessory.Name = name
				local handle = create("Part", accessory)
				handle.Name, handle.Size = "Handle", Vector3.new(1, 1, 1)
				handle.CanCollide, handle.CanTouch, handle.CanQuery = false, false, false
				handle.Anchored, handle.Massless, handle.Transparency = false, true, transparency
				handle.Color = Color3.new(0.1, 0.1, 0.1)
				local mesh = create("SpecialMesh", handle)
				mesh.MeshId, mesh.TextureId, mesh.Scale = meshId, textureId, scale
				local weld = create("Weld", handle)
				weld.Part0, weld.Part1 = handle, mount
				weld.C0 = c0
				weld.C1 = CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
				return accessory
			end
			local accessories
			if terio then
				accessories = {
					weapon("VortexionSyncedLanceBack", torso, "rbxassetid://18858726703", "rbxassetid://18858727747", Vector3.new(1, 1, 1), 0,
						CFrame.new(0, -1, -0.5, 1, 0, 0, 0, -1, 0, 0, 0, 1)),
					weapon("VortexionSyncedLanceFront", arm, "rbxassetid://18858726703", "rbxassetid://18858727747", Vector3.new(1, 1, 1), 1,
						CFrame.new(-1, 0.400000006, 0, 0.00999950059, -0.999750197, 0.0199924111, 0, -0.0199934151, -0.999800086, -0.999950051, -0.00999750197, 0.000199924252)),
				}
			else
				accessories = {weapon("VortexionSyncedShadowBlade", arm, "rbxassetid://62275962", "rbxassetid://62276016", Vector3.new(0.5, 0.5, 0.5), 0,
					CFrame.new(1.75, -0.879999995, 0, -1.31445322e-05, 1, 0, 0, 0, 1, 1, 1.31445331e-05, -7.10549173e-15))}
			end
			if terio then
				record.LanceBack, record.LanceFront = accessories[1]:FindFirstChild("Handle"), accessories[2]:FindFirstChild("Handle")
			end
			local lookPublications, lookEdits = {}, {}
			if terio then
				local head = char:FindFirstChild("Head")
				if head and head:IsA("BasePart") then record.Head = head end
				local function stageLook(className, owner, property, asset)
					local targets = {}
					for _, object in ipairs(owner:GetChildren()) do
						if object:IsA(className) and (className ~= "Decal" or object.Face == Enum.NormalId.Front) then
							table.insert(targets, object)
						end
					end
					if #targets == 0 then
						local object = create(className)
						object.Name, object[property], object.Color3 = "VortexionSynced" .. className, asset, Color3.new(1, 1, 1)
						if className == "Decal" then object.Face, object.Transparency = Enum.NormalId.Front, 0 end
						table.insert(lookPublications, {Object = object, Owner = owner})
						table.insert(targets, object)
					else
						for _, object in ipairs(targets) do
							table.insert(lookEdits, {Object = object, Owner = owner, Property = property, Applied = asset})
							table.insert(lookEdits, {Object = object, Owner = owner, Property = "Color3", Applied = Color3.new(1, 1, 1)})
							if className == "Decal" then table.insert(lookEdits, {Object = object, Owner = owner, Property = "Transparency", Applied = 0}) end
						end
					end
					if className == "Decal" then record.Faces = targets end
				end
				stageLook("Shirt", char, "ShirtTemplate", "rbxassetid://13132949672")
				stageLook("Pants", char, "PantsTemplate", "rbxassetid://13132951176")
				if record.Head then stageLook("Decal", record.Head, "Texture", "rbxassetid://133089396665213") end
				-- One bounded direct-part sweep; never lock descendants or change BodyColors.
				for index, object in ipairs(char:GetChildren()) do
					if index > 256 then break end
					if object:IsA("BasePart") then
						table.insert(lookEdits, {Object = object, Owner = char, Property = "Color", Applied = Color3.new(1, 1, 1)})
					end
				end
			end
			-- Build the complete set off-character; stale or failed candidates roll back together.
			for _, accessory in ipairs(accessories) do
				if not chatRecordCurrent(record) then releaseChatRecord(record); return end
				accessory.Parent = char
				if not chatRecordCurrent(record) then releaseChatRecord(record); return end
			end
			for _, entry in ipairs(lookPublications) do
				if not chatRecordCurrent(record) then releaseChatRecord(record); return end
				entry.Object.Parent = entry.Owner
				if not chatRecordCurrent(record) then releaseChatRecord(record); return end
			end
			for _, entry in ipairs(lookEdits) do
				if not chatRecordCurrent(record) or entry.Object.Parent ~= entry.Owner then releaseChatRecord(record); return end
				entry.Original = entry.Object[entry.Property]
				if entry.Original ~= entry.Applied then
					table.insert(record.Appearance, entry)
					local written = pcall(function() entry.Object[entry.Property] = entry.Applied end)
					if not written or not chatRecordCurrent(record) or entry.Object.Parent ~= entry.Owner then
						-- A setter can close before completing its write, after the first release ran.
						restoreChatLook(entry)
						releaseChatRecord(record); return
					end
				end
			end
			refreshChatLance(record)
			updateChatLabel(record)
		end)
		if not ok and record then releaseChatRecord(record) end
	end
	local function disconnectChatConnections(list)
		for _, connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
	end
	local function stopChatSync()
		chatSyncReleaseDepth += 1
		chatSyncEnabled, chatSyncEpoch, chatSyncStatus = false, chatSyncEpoch + 1, "已关闭"
		local connections, bindings, records = chatSyncConnections, chatSyncBindings, chatSyncRecords
		chatSyncConnections, chatSyncBindings, chatSyncRecords = {}, {}, {}
		disconnectChatConnections(connections)
		for _, binding in pairs(bindings) do disconnectChatConnections(binding) end
		for _, record in pairs(records) do releaseChatRecord(record) end
		if chatSyncToggle and not chatSyncToggleSync and not chatSyncEnabled then
			chatSyncToggleSync = true
			pcall(function() chatSyncToggle:SetValue(false) end)
			chatSyncToggleSync = false
		end
		chatSyncReleaseDepth -= 1
	end
	setChatSyncEnabled = function(value)
		if value ~= true then stopChatSync(); return end
		if destroyed or chatSyncEnabled or chatSyncReleaseDepth > 0 then return end
		chatSyncEpoch += 1
		chatSyncEnabled = true
		local epoch, lastTick = chatSyncEpoch, -math.huge
		local function listen(signal, callback, bucket, current)
			local connection = signal:Connect(callback)
			if not current() then pcall(function() connection:Disconnect() end); return end
			table.insert(bucket, connection)
		end
		local function current() return chatSyncCurrent(epoch) end
		local function bind(player)
			if player == LocalPlayer or chatSyncBindings[player] or not current() or player.Parent ~= Players then return end
			local bucket = {}
			chatSyncBindings[player] = bucket
			local function bindingCurrent() return current() and chatSyncBindings[player] == bucket and player.Parent == Players end
			local ok = pcall(function()
				listen(player.Chatted, function(message) if bindingCurrent() then receiveChatSync(player, message, epoch) end end, bucket, bindingCurrent)
				listen(player.CharacterRemoving, function(char)
					local record = chatSyncRecords[player]
					if bindingCurrent() and record and record.Character == char then releaseChatRecord(record) end
				end, bucket, bindingCurrent)
			end)
			if not ok or not bindingCurrent() then
				if chatSyncBindings[player] == bucket then chatSyncBindings[player] = nil end
				disconnectChatConnections(bucket)
			end
		end
		local ok = pcall(function()
			listen(Players.PlayerAdded, bind, chatSyncConnections, current)
			listen(Players.PlayerRemoving, function(player)
				if not current() then return end
				local bucket, record = chatSyncBindings[player], chatSyncRecords[player]
				chatSyncBindings[player] = nil
				if bucket then disconnectChatConnections(bucket) end
				if record then releaseChatRecord(record) end
			end, chatSyncConnections, current)
			if not current() then return end
			for _, player in ipairs(Players:GetPlayers()) do bind(player) end
			local textChat = ctx.TextChatService
			if textChat and textChat.MessageReceived then
				listen(textChat.MessageReceived, function(message)
					if not current() then return end
					pcall(function()
						local source = message.TextSource
						if source then receiveChatSync(Players:GetPlayerByUserId(source.UserId), message.Text, epoch) end
					end)
				end, chatSyncConnections, current)
			end
			if not current() then return end
			listen(RunService.Heartbeat, function()
				if not current() then
					if chatSyncEpoch == epoch then stopChatSync() end
					return
				end
				local at = clock()
				-- Check deadlines before the slower identity/UI sweep, including adjacent frames.
				for _, record in pairs(table.clone(chatSyncRecords)) do
					tickChatFace(record, at)
					if record.LanceUntil and at >= record.LanceUntil then
						record.LanceUntil = nil
						if chatRecordCurrent(record) then setChatLanceVisible(record, false) else releaseChatRecord(record) end
					end
				end
				if not current() or at - lastTick < 0.25 then return end
				lastTick = at
				for _, record in pairs(table.clone(chatSyncRecords)) do
					if chatRecordCurrent(record) then
						refreshChatLance(record)
						updateChatLabel(record)
					else releaseChatRecord(record) end
				end
			end, chatSyncConnections, current)
		end)
		if not ok or not current() then
			if chatSyncEpoch == epoch then stopChatSync(); chatSyncStatus = "聊天监听未就绪" end
			return
		end
		chatSyncStatus = "监听精确指令 :syncScript / _sync_terio_（仅其他玩家本机刀饰 / Terio枪饰与衣饰）"
	end
	-- End reference chat sync.

	local chargeSaved = {}
	local function chargeStateSave(hum)
		if hum and not chargeSaved[hum] then chargeSaved[hum] = {WalkSpeed = hum.WalkSpeed, JumpPower = hum.JumpPower} end
	end
	local function chargeStateRestore(hum)
		local saved = hum and chargeSaved[hum]
		if not saved then return end
		for key, value in pairs(saved) do pcall(function() hum[key] = value end) end
		chargeSaved[hum] = nil
	end
	local respawnConn = LocalPlayer.CharacterAdded:Connect(function()
		locomotionRemoving = nil; resetLocomotion()
		sil.removing = nil; resetSil()
		stopAnimations()
		for hum in pairs(chargeSaved) do chargeStateRestore(hum) end
	end)
	track(respawnConn)
	local function destroy()
		if destroyed then return end
		destroyed = true
		stopChatSync()
		setSilAnimationEnabled(false)
		guestState.FakeBlock = false
		setLocomotionEnabled(false)
		stopAnimations(); respawnConn:Disconnect()
		for hum in pairs(chargeSaved) do chargeStateRestore(hum) end
		ensureSingleGui("VortexionGuestGui")
	end

	---------------------------------------------------------------------------
	-- UI: Guest 增强 (挂 GuestSettings tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Guest then
		Tabs.Guest:AddToggle("GuestFakeBlockGui", {
			Title = "启用假格挡",
			Default = false,
			Callback = function(state)
				setEnabled("FakeBlock", state)
				if not state then stopAnimations() end
			end
		})

		Tabs.Guest:AddButton({ Title = "触发假格挡", Callback = triggerFakeBlock })

		-- 纯本地演出预设：仅本机播放，不自动触发、不写服务端状态
		local actionProfiles = {
			["TwoTime / 蹲伏起手"] = "98606150731314",
			["TwoTime / 蹲伏斩击"] = "119256819262245",
			["TwoTime / 站姿斩击"] = "86545133269813",
			["Sil / 普通挥击"] = "83829782357897",
			["Terio / 蹲姿斩击"] = "84413781229733",
		}
		local actionSelected = "TwoTime / 蹲伏起手"
		Tabs.Guest:AddDropdown("GuestActionPreset", {
			Title = "本地动作演出预设",
			Values = { "TwoTime / 蹲伏起手", "TwoTime / 蹲伏斩击", "TwoTime / 站姿斩击", "Sil / 普通挥击", "Terio / 蹲姿斩击" },
			Default = "TwoTime / 蹲伏起手",
			Callback = function(v)
				if destroyed then return end
				if actionProfiles[v] then actionSelected = v end
			end,
		})
		Tabs.Guest:AddButton({
			Title = "播放所选动作（仅演出）",
			Callback = function()
				if destroyed then return end
				local ok, err = playCustomAnim(actionProfiles[actionSelected])
				notify("本地演出", ok and ("已播放 " .. actionSelected .. "（仅演出，非实际技能）") or tostring(err))
			end,
		})
		Tabs.Guest:AddInput("GuestCustomAnimId", {
			Title = "播放自定义动画 ID",
			Placeholder = "rbxassetid://...",
			Callback = function(input)
				local ok, err = playCustomAnim(input)
				notify("自定义动画", ok and "已播放" or tostring(err))
			end
		})

		Tabs.Guest:AddSlider("GuestAnimationSpeed", {
			Title = "自定义动画速度（%）",
			Min = 25,
			Max = 200,
			Default = 100,
			Rounding = 0,
			Callback = function(value)
				if destroyed then return end
				local speed = tonumber(value)
				if speed and speed == speed and speed ~= math.huge and speed ~= -math.huge then
					animationSpeed = math.clamp(speed, 25, 200)
				end
			end
		})

		Tabs.Guest:AddToggle("GuestAnimationLoop", {
			Title = "自定义动画循环播放",
			Default = false,
			Callback = function(state)
				if destroyed then return end
				animationLoop = state == true
			end
		})

		Tabs.Guest:AddToggle("GuestChargeStateGuard", {
			Title = "冲锋状态安全恢复（含 WalkSpeed=0）",
			Default = true,
			Callback = function(state)
				_G.VortexionChargeStateGuard = state or nil
			end
		})
	end

	---------------------------------------------------------------------------
	-- UI: Guest 增强 (挂 Blatant tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Guest then
		Tabs.Guest:AddButton({
			Title = "关闭假格挡 / 清理旧浮窗",
			Callback = function()
				destroyFakeBlockGui()
				notify("Guest", "GUI 已清理")
			end
		})
	end

	if Tabs and Tabs.Guest then
		Tabs.Guest:AddParagraph({Title = "聊天武器外观同步", Content = "默认关闭。其他 TwoTime 的精确 :syncScript 显示刀饰；其他存活 Shedletsky 的 _sync_terio_ 同步Terio枪饰、衣裤、正面贴图和玩家栏，挥枪动画显形2秒；精确凝血动画延迟2秒变脸、名义0.55秒后恢复，不附带音效或红光。借用外观有条件恢复，缺项才新建；初次缺Head时跳过脸贴图，重开可补脸。仅本机可见，不发送聊天或运行远程脚本，不修改伤害/输入；关闭、离场或身份变化回收。身体白肤仅单次扫描至多256个直接子项，关闭按快照恢复；保留原配件与BodyColors，不循环锁色。Sil、Terio头发及其余动作音效仍待补。"})
		chatSyncToggle = Tabs.Guest:AddToggle("GuestTwoTimeChatSync", {Title = "接收 TwoTime / Terio 本机外观同步", Default = false, Callback = setChatSyncEnabled})
		Tabs.Guest:AddButton({Title = "聊天同步状态", Callback = function() if not destroyed then notify("聊天同步", chatSyncStatus) end end})
		Tabs.Guest:AddDropdown("GuestFakeBlockVariant", {Title = "假格挡动画类型", Values = {"Normal", "M3 / M4"}, Default = 1, Callback = function(v) fakeVariant = v end})
		Tabs.Guest:AddParagraph({Title = "角色待机 / 行走（本地）", Content = "只替换本机动作表现，不改移速或技能。TwoTime 先播一次起手，再接待机/行走；起手最长8秒兜底，中断不重播。角色离地、坐下及自定义动作播放时让位；动画权限与实际效果待游戏确认。"})
		Tabs.Guest:AddDropdown("GuestLocomotionProfile", {Title = "待机 / 行走方案", Values = {"Terio", "TwoTime / 蹲伏"}, Default = "Terio", Callback = setLocomotionProfile})
		locomotionToggle = Tabs.Guest:AddToggle("GuestLocomotionEnabled", {Title = "启用本地待机 / 行走", Default = false, Callback = setLocomotionEnabled})
		Tabs.Guest:AddButton({Title = "重新应用角色动作", Callback = function() if not destroyed then resetLocomotion() end end})
		Tabs.Guest:AddButton({Title = "角色动作状态", Callback = function() if not destroyed then notify("角色动作", locomotionProfile .. "：" .. locomotionStatus) end end})
		sil.toggle = Tabs.Guest:AddToggle("GuestSilAnimationEnabled", {Title = "Sil 本地动作替换", Default = false, Callback = setSilAnimationEnabled})
		Tabs.Guest:AddParagraph({Title = "Sil 动作范围", Content = "仅替换本机终结技与不稳之眼动画；终结技等待0.45秒，眼部动作1.65倍速。默认关闭，失败保留原动作，不附带伤害、位移或输入修改；关闭后清理自有轨道，不重播原动作。"})
		Tabs.Guest:AddButton({Title = "Sil 动作状态", Callback = function() if not destroyed then notify("Sil", sil.status) end end})
		Tabs.Guest:AddButton({Title = "停止本模块动画", Callback = stopAllAnimations})
	end

	return {
		Destroy = destroy,
		stopAnimations = stopAnimations,
		setEnabled = setEnabled,
		setChatSyncEnabled = setChatSyncEnabled,
		getChatSyncStatus = function() return chatSyncStatus end,
		playCustomAnim = playCustomAnim,
		setLocomotionEnabled = setLocomotionEnabled,
		setLocomotionProfile = setLocomotionProfile,
		getLocomotionStatus = function() return locomotionStatus end,
		stopAllAnimations = stopAllAnimations,
		setSilAnimationEnabled = setSilAnimationEnabled,
		getSilAnimationStatus = function() return sil.status end,
		buildFakeBlockGui = buildFakeBlockGui,
		triggerFakeBlock = triggerFakeBlock,
		destroyFakeBlockGui = destroyFakeBlockGui,
		chargeStateSave = chargeStateSave,
		chargeStateRestore = chargeStateRestore,
		ensureSingleGui = ensureSingleGui,
	}
end
