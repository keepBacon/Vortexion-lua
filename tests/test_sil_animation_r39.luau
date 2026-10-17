---------------------------------------------------------------------------
-- R39 专项测试：Guest 本地 SIL 动画替换（非技能/位移/伤害）
-- 用法：追加在 tests/test_forsaken_enrichment.luau 前缀（change 定义）之后，
--       由父 runner 注入 ForsakenGuest 工厂统一执行。
-- 契约（父代理约定，m00064）：
--   api.setSilAnimationEnabled(bool) / api.getSilAnimationStatus() -> string
--   UI 选项 GuestSilAnimationEnabled 默认 false
--   观察 LocalPlayer 当前角色 Animator.AnimationPlayed
--   93368339913846 -> 140035118771958（延迟 0.45s，1x）
--   119429069577280 -> 128730974312965（立即，1.65x）
--   仅两个精确 ID（纯数字或 rbxassetid:// 规范化）；不改 M1/root/速度/输入/网络
--   原轨道仅替换成功后 Stop，失败保留；自有轨道 Stop/Destroy/事件回收
--   单个 Heartbeat 仅开启时连接；关闭/换角色/换 Animator/死亡/卸载后迟到回调失效
-- 复用前缀 mock：factory/ctx/change/heartbeat/now/animator/character/signal/
--               methods/created/fluent/tab/check/equal/assertions；
--               不复制生产算法，只观测可观察行为。
---------------------------------------------------------------------------

-- 夹具补丁：为角色 Animator 提供 AnimationPlayed 信号（前缀 inst 未内置）
animator.AnimationPlayed = signal()
localPlayer.CharacterRemoving = signal()

-- 包装 mock LoadAnimation：保留原行为，记录 speed/IsPlaying/停止次数与事件顺序，
-- 并支持替换轨 Play 故障注入（LoadAnimation 失败用 animator.FailLoad）
local silBaseLoad = methods.LoadAnimation
local silPlays, silStops, silEvents = {}, 0, {}
local silFailLoad, silFailPlay, silLoadHook = false, false, nil
methods.LoadAnimation = function(self, animation)
    local id = animation and animation.AnimationId
    local replacement = id == "rbxassetid://128730974312965" or id == "rbxassetid://140035118771958"
    if replacement and silLoadHook then local hook = silLoadHook; silLoadHook = nil; hook() end
    if replacement and silFailLoad then error("injected sil load error") end
    local track = silBaseLoad(self, animation)
    track.Animation, track.LoadedId = animation, id
    track.IsPlaying = false
    local basePlay, baseStop = track.Play, track.Stop
    track.Play = function(t, fadeTime, weight, speed)
        if replacement and silFailPlay then error('injected sil play error') end
        t.LastSpeed = speed
        t.IsPlaying = true
        table.insert(silPlays, {id = t.LoadedId, speed = speed})
        table.insert(silEvents, 'play:' .. tostring(t.LoadedId))
        basePlay(t, fadeTime, weight, speed)
    end
    track.Stop = function(t)
        silStops += 1
        table.insert(silEvents, 'stop:' .. tostring(t.LoadedId))
        baseStop(t)
        t.IsPlaying = false
    end
    return track
end

local previousSilApi = api
local function silFreshApi()
    if previousSilApi then previousSilApi.Destroy() end
    for id in pairs(fluent.Options) do fluent.Options[id] = nil end
    tab.buttons = {}
    previousSilApi = factory(ctx)
    return previousSilApi
end

local function silReset()
    animator.FailLoad = false
    silFailLoad, silFailPlay, silLoadHook = false, false, nil
    silPlays, silEvents = {}, {}
    localPlayer.Character = char
    hum.Health = 100
    ctx.sessionEnv.VortexionSessionId = ctx.thisSessionId
    animator.Parent = hum
    animator.AnimationPlayed = signal()
end

local function silReplacementPlays()
    local n = 0
    for _, entry in ipairs(silPlays) do
        local id = tostring(entry.id or '')
        if string.find(id, '128730974312965', 1, true) or string.find(id, '140035118771958', 1, true) then
            n += 1
        end
    end
    return n
end

local function silEventIndex(prefix)
    for i, entry in ipairs(silEvents) do
        if string.sub(entry, 1, #prefix) == prefix then return i end
    end
    return 0
end

local function silStopCountFor(idFragment)
    local n = 0
    for _, entry in ipairs(silEvents) do
        if string.sub(entry, 1, 5) == 'stop:' and string.find(entry, idFragment, 1, true) then n += 1 end
    end
    return n
end

local function silCharacter(name)
    local c, h, r, a = character(name, 0, survivors)
    a.AnimationPlayed = signal()
    return c, h, r, a
end

local function silFirePlayed(anim, animId)
    local obj = Instance.new('Animation')
    obj.AnimationId = animId
    local track = anim:LoadAnimation(obj)
    track:Play()
    anim.AnimationPlayed:Fire(track)
    return track
end

local function silBeat(dt) heartbeat(now + dt, dt) end

local silApi

---------------------------------------------------------------------------
-- A: 默认关闭、状态字符串、Heartbeat 单连接与开关幂等
---------------------------------------------------------------------------
silReset()
silApi = silFreshApi()
check(fluent.Options.GuestSilAnimationEnabled ~= nil, 'GuestSilAnimationEnabled option registered')
equal(fluent.Options.GuestSilAnimationEnabled.Value, false, 'GuestSilAnimationEnabled default false')
local statusOff = silApi.getSilAnimationStatus()
check(type(statusOff) == 'string', 'status is string when disabled')
local origA = silFirePlayed(animator, 'rbxassetid://93368339913846')
equal(silReplacementPlays(), 0, 'disabled: mapped id ignored')
check(origA.Playing, 'disabled: original keeps playing')
silApi.setSilAnimationEnabled(true)
check(type(silApi.getSilAnimationStatus()) == 'string' and silApi.getSilAnimationStatus() ~= statusOff, 'status changes when enabled')
equal(runService.Heartbeat:Count(), 1, 'enable connects single heartbeat')
silApi.setSilAnimationEnabled(true)
equal(runService.Heartbeat:Count(), 1, 'enable idempotent')
silApi.setSilAnimationEnabled(false)
equal(runService.Heartbeat:Count(), 0, 'disable disconnects heartbeat')
equal(silApi.getSilAnimationStatus(), statusOff, 'status returns to disabled text')

---------------------------------------------------------------------------
-- B: 立即替换（119429069577280）、规范化与未映射 ID 忽略
---------------------------------------------------------------------------
silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
local origB = silFirePlayed(animator, '119429069577280')
check(silReplacementPlays() == 1, 'immediate mapped id replaces without waiting')
equal(animator.LastId, 'rbxassetid://128730974312965', 'immediate replacement id')
equal(animator.LastTrack.LastSpeed, 1.65, 'immediate replacement speed 1.65x')
check(animator.LastTrack.IsPlaying, 'replacement track playing')
equal(silStopCountFor('119429069577280'), 1, 'original stopped once after success')
check(silEventIndex('play:rbxassetid://128730974312965') < silEventIndex('stop:119429069577280'), 'original stopped only after replacement play')
local origB2 = silFirePlayed(animator, 'rbxassetid://119429069577280')
equal(silReplacementPlays(), 2, 'rbxassetid form normalized and replaced')
local origB3 = silFirePlayed(animator, 'rbxassetid://999999999')
equal(silReplacementPlays(), 2, 'unmapped numeric id ignored')
check(origB3.Playing, 'unmapped original keeps playing')
local origB4 = silFirePlayed(animator, 'https://example.test/a')
equal(silReplacementPlays(), 2, 'url id ignored')
equal(runService.Heartbeat:Count(), 1, 'events do not leak heartbeat connections')

---------------------------------------------------------------------------
-- C: 延迟替换（93368339913846，0.45s，1x）与到期前保持
---------------------------------------------------------------------------
silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
local origC = silFirePlayed(animator, '93368339913846')
equal(silReplacementPlays(), 0, 'delayed id does not replace immediately')
silBeat(0.2); silBeat(0.24)
equal(silReplacementPlays(), 0, 'delayed id still pending before deadline')
check(origC.Playing, 'original still playing before deadline')
silBeat(0.010001)
check(silReplacementPlays() == 1, 'delayed id replaces at 0.45 seconds')
equal(animator.LastId, 'rbxassetid://140035118771958', 'delayed replacement id')
equal(animator.LastTrack.LastSpeed, 1, 'delayed replacement speed 1x')
equal(silStopCountFor('93368339913846'), 1, 'original stopped once after delayed success')
check(silEventIndex('play:rbxassetid://140035118771958') < silEventIndex('stop:93368339913846'), 'delayed original stopped after replacement play')

---------------------------------------------------------------------------
-- D: 迟到回调失效（关闭 / 换角色重绑 / 卸载 / 死亡）
---------------------------------------------------------------------------
silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
local origD = silFirePlayed(animator, '93368339913846')
silApi.setSilAnimationEnabled(false)
silBeat(0.6)
equal(silReplacementPlays(), 0, 'disable invalidates pending delayed replacement')
check(origD.Playing, 'original survives disable before deadline')
equal(runService.Heartbeat:Count(), 0, 'disable keeps heartbeat disconnected')

silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
local origD2 = silFirePlayed(animator, '93368339913846')
local swapChar, swapHum, swapRoot, swapAnim = silCharacter('SilSwap')
localPlayer.Character = swapChar
localPlayer.CharacterAdded:Fire(swapChar)
silBeat(0.6)
equal(silReplacementPlays(), 0, 'character swap invalidates pending delayed replacement')
check(origD2.Playing, 'old original untouched after swap')
silBeat(0.016)
local origD3 = silFirePlayed(swapAnim, '119429069577280')
check(silReplacementPlays() == 1, 'rebind after swap replaces on new animator')
equal(swapAnim.LastId, 'rbxassetid://128730974312965', 'rebound replacement id')
localPlayer.Character = char

silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
local origD4 = silFirePlayed(animator, '93368339913846')
silApi.Destroy()
silBeat(0.6)
equal(silReplacementPlays(), 0, 'destroy invalidates pending delayed replacement')

silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
local origD5 = silFirePlayed(animator, '93368339913846')
hum.Health = 0
silBeat(0.6)
equal(silReplacementPlays(), 0, 'death invalidates pending delayed replacement')
check(origD5.Playing, 'original untouched after death')

---------------------------------------------------------------------------
-- E: 替换失败保留原轨道（LoadAnimation 失败 / Play 失败）
---------------------------------------------------------------------------
silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
silFailLoad = true
local origE = silFirePlayed(animator, '119429069577280')
equal(silReplacementPlays(), 0, 'load failure produces no replacement play')
equal(silStopCountFor('119429069577280'), 0, 'original not stopped when load fails')
silFailLoad = false
silFirePlayed(animator, '119429069577280')
check(silReplacementPlays() == 1, 'recovery after load failure replaces')
equal(silStopCountFor('119429069577280'), 1, 'original stopped after successful retry')

silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
silFailPlay = true
local origE3 = silFirePlayed(animator, '119429069577280')
equal(silReplacementPlays(), 0, 'play failure records no replacement play')
equal(silStopCountFor('119429069577280'), 0, 'original not stopped when replacement play fails')
check(origE3.Playing, 'original keeps playing after replacement play failure')

---------------------------------------------------------------------------
-- F: 自有轨道 Stop/Destroy/事件回收与关闭清理
---------------------------------------------------------------------------
silReset()
silApi = silFreshApi()
silApi.setSilAnimationEnabled(true)
silFirePlayed(animator, '119429069577280')
local replF = animator.LastTrack
local stopConns = getconnections(replF.Stopped)
equal(#stopConns, 1, 'replacement stopped subscription registered')
replF.Stopped:Fire()
check(not stopConns[1].Connected, 'replacement subscription disconnected on stopped')
check(replF.Destroyed, 'replacement destroyed on stopped')
silFirePlayed(animator, '119429069577280')
check(silReplacementPlays() == 2, 'module replaces again after reclaim')
local replF2 = animator.LastTrack
local stopsBeforeDisable = silStopCountFor('128730974312965')
silApi.setSilAnimationEnabled(false)
equal(silStopCountFor('128730974312965') - stopsBeforeDisable, 1, 'disable stops active replacement')
check(replF2.Destroyed, 'disable destroys active replacement')
equal(animator.AnimationPlayed:Count(), 0, 'disable removes AnimationPlayed subscriptions')

---------------------------------------------------------------------------
-- Additional transaction boundaries: latest request wins, borrowed tracks and reentry.
silReset(); silApi = silFreshApi(); silApi.setSilAnimationEnabled(true)
local borrowed = silFirePlayed(animator, "93368339913846")
silFirePlayed(animator, "119429069577280"); silBeat(0.5)
equal(silReplacementPlays(), 1, "latest mapped event replaces pending request")
check(borrowed.IsPlaying and not borrowed.Destroyed, "superseded borrowed track remains untouched")
local expiring = animator.LastTrack
silBeat(15.000001)
check(expiring.Destroyed, "owned replacement expires after 15 seconds")

silReset(); silApi = silFreshApi(); silApi.setSilAnimationEnabled(true)
local lateListener = getconnections(animator.AnimationPlayed)[1]
silFirePlayed(animator, "93368339913846")
ctx.sessionEnv.VortexionSessionId = 2; silBeat(0.5)
equal(silReplacementPlays(), 0, "session replacement cancels pending work")
equal(runService.Heartbeat:Count(), 0, "session replacement disconnects heartbeat")
equal(fluent.Options.GuestSilAnimationEnabled.Value, false, "session replacement synchronizes disabled toggle")
local lateOriginal = silFirePlayed(animator, "119429069577280")
lateListener.fn(lateOriginal)
equal(silReplacementPlays(), 0, "late disconnected listener cannot revive old session")

silReset(); silApi = silFreshApi(); silApi.setSilAnimationEnabled(true)
silLoadHook = function() silApi.setSilAnimationEnabled(false) end
local cancelledOriginal = silFirePlayed(animator, "119429069577280")
check(cancelledOriginal.IsPlaying, "load cancellation preserves borrowed original")
check(animator.LastTrack.Destroyed, "load cancellation disposes returned candidate")
equal(silReplacementPlays(), 0, "load cancellation does not play stale candidate")

silReset(); silApi = silFreshApi(); silApi.setSilAnimationEnabled(true)
local stopAsset = Instance.new("Animation"); stopAsset.AnimationId = "119429069577280"
local stopOriginal = animator:LoadAnimation(stopAsset); stopOriginal:Play()
stopOriginal.Stop = function() error("injected original stop failure") end
animator.AnimationPlayed:Fire(stopOriginal)
check(stopOriginal.IsPlaying and not stopOriginal.Destroyed, "original stop failure never destroys borrowed original")
check(animator.LastTrack.Destroyed, "original stop failure rolls back replacement")

silReset(); silApi = silFreshApi(); silApi.setSilAnimationEnabled(true)
silFirePlayed(animator, "119429069577280")
local reentrant = animator.LastTrack
local reentrantStop = reentrant.Stop
reentrant.Stop = function(t) silApi.setSilAnimationEnabled(true); reentrantStop(t) end
silApi.setSilAnimationEnabled(false)
equal(runService.Heartbeat:Count(), 0, "cleanup callback cannot reenable heartbeat")
equal(animator.AnimationPlayed:Count(), 0, "cleanup callback cannot rebind animation listener")

silReset(); silApi = silFreshApi()
local heartbeatConnect = runService.Heartbeat.Connect
runService.Heartbeat.Connect = function(s, fn)
    local candidate = heartbeatConnect(s, fn)
    silApi.setSilAnimationEnabled(false)
    return candidate
end
silApi.setSilAnimationEnabled(true)
runService.Heartbeat.Connect = heartbeatConnect
equal(runService.Heartbeat:Count(), 0, "setup cancellation disconnects returned heartbeat candidate")
equal(localPlayer.CharacterRemoving:Count(), 0, "setup cancellation removes committed listener")
equal(animator.AnimationPlayed:Count(), 0, "setup cancellation does not bind animator")

silReset(); silApi = silFreshApi(); silApi.setSilAnimationEnabled(true)
silFirePlayed(animator, "93368339913846")
animator.Parent = nil
local replacementAnimator = Instance.new("Animator"); replacementAnimator.Parent = hum
replacementAnimator.AnimationPlayed = signal()
silBeat(0.5)
equal(silReplacementPlays(), 0, "animator identity replacement invalidates pending track")
silFirePlayed(replacementAnimator, "119429069577280")
equal(silReplacementPlays(), 1, "animator identity replacement rebinds current animator")
silApi.Destroy(); replacementAnimator:Destroy(); animator.Parent = hum

-- 收尾：销毁并核对无残留订阅
---------------------------------------------------------------------------
silApi.Destroy()
silApi.Destroy()
equal(runService.Heartbeat:Count(), 0, 'destroy leaves no heartbeat')
for _, connection in ipairs(getconnections(animator.AnimationPlayed)) do
    check(not connection.Connected, 'every AnimationPlayed subscription disconnected')
end
print('test_sil_animation_r39 assertions: ' .. assertions)
return true
