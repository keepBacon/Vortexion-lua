---------------------------------------------------------------------------
-- R23 专项测试：Guest 自定义动画速度/循环 + playCustomAnim 失败与回收路径
-- 用法：追加在 tests/test_forsaken_enrichment.luau 前缀第 231 行（change 定义）
--       之后，由父 runner 注入 ForsakenGuest 工厂统一执行。
-- 复用前缀 mock：factory/ctx/change/now/animator/hum/char/localPlayer/methods/
--               created/loadCount/stopCount/getconnections/character/fluent/tab/
--               check/equal/assertions；不复制产品算法，只观测可观察行为。
---------------------------------------------------------------------------

-- 包装 mock LoadAnimation：保留原行为，记录 Play 实参并支持故障注入
local baseLoadAnimation = methods.LoadAnimation
local playLog, trackLog = {}, {}
local failPlay, syncStopped, failConnect = false, false, false
local loadHook = nil
methods.LoadAnimation = function(self, animation)
    local track = baseLoadAnimation(self, animation)
    table.insert(trackLog, track)
    local baseDestroy = track.Destroy
    track.Destroy = function(t)
        t.DestroyCalls = (t.DestroyCalls or 0) + 1
        baseDestroy(t)
    end
    if failConnect then
        track.Stopped = {Connect = function() error('injected stopped connect error') end, Fire = function() end}
    end
    if loadHook then loadHook() end
    local basePlay = track.Play
    track.Play = function(t, fadeTime, weight, speed)
        table.insert(playLog, {fade = fadeTime, weight = weight, speed = speed})
        if failPlay then error('injected play error') end
        basePlay(t)
        if syncStopped then track.Stopped:Fire() end
    end
    return track
end

-- 每组重建工厂：清空选项注册避免 duplicate option，同时重置节流与活动 Track
local previousApi = api
local function freshApi()
    if previousApi then previousApi.Destroy() end
    for id in pairs(fluent.Options) do fluent.Options[id] = nil end
    tab.buttons = {}
    previousApi = factory(ctx)
    return previousApi
end

local function countLeakedAnimations()
    local leaked = 0
    for _, object in ipairs(created) do
        if object:IsA('Animation') and not object.Destroyed then leaked = leaked + 1 end
    end
    return leaked
end

local function resetFixtures()
    animator.FailLoad = false
    failPlay, syncStopped, failConnect, loadHook = false, false, false, nil
    playLog = {}
    localPlayer.Character = char
    hum.Health = 100
    animator.Parent = hum
end

local guestApi

---------------------------------------------------------------------------
-- A: 默认 1x、ID 归一化、门禁与节流
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
equal(fluent.Options.GuestAnimationSpeed.Value, 100, 'speed slider default 100')
equal(fluent.Options.GuestAnimationLoop.Value, false, 'loop toggle default false')
check(guestApi.playCustomAnim('31337'), 'default speed play succeeds')
equal(#playLog, 1, 'single play recorded')
equal(playLog[1].fade, 0.1, 'fade time 0.1')
equal(playLog[1].weight, 1, 'weight 1')
equal(playLog[1].speed, 1, 'default 100 percent plays at 1x')
equal(animator.LastId, 'rbxassetid://31337', 'numeric id normalized')
check(animator.LastTrack.Playing, 'mock track playing')
equal(countLeakedAnimations(), 0, 'temporary Animation destroyed after success')
local okT, errT = guestApi.playCustomAnim('31338')
check(not okT, 'immediate replay throttled')
equal(errT, '播放过于频繁', 'throttle message')
local okN, errN = guestApi.playCustomAnim('https://example.test/a')
equal(errN, '请输入纯数字或 rbxassetid://数字', 'url rejected')
local okF, errF = guestApi.playCustomAnim(123)
equal(errF, '动画 ID 格式错误', 'non string rejected')
now = now + 0.5
animator.Parent = nil
local okA, errA = guestApi.playCustomAnim('31339')
equal(errA, 'Animator 未就绪', 'animator gate message')
animator.Parent = hum
hum.Health = 0
local okH, errH = guestApi.playCustomAnim('31340')
equal(errH, '角色已失效', 'dead humanoid rejected')
hum.Health = 100
now = now + 0.5
check(guestApi.playCustomAnim('31341'), 'gated failures do not consume throttle')
equal(countLeakedAnimations(), 0, 'gate failures leak no Animation')

---------------------------------------------------------------------------
-- B: 25/200 限幅、非法值保持、loop 仅对下一次播放生效
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
change('GuestAnimationSpeed', 10)
check(guestApi.playCustomAnim('41001'), 'clamped low speed play')
equal(playLog[1].speed, 0.25, '10 percent clamped to 25 -> 0.25x')
now = now + 0.5
change('GuestAnimationSpeed', 500)
check(guestApi.playCustomAnim('41002'), 'clamped high speed play')
equal(playLog[2].speed, 2, '500 percent clamped to 200 -> 2x')
now = now + 0.5
change('GuestAnimationSpeed', 'abc')
check(guestApi.playCustomAnim('41003'), 'non numeric speed keeps previous')
equal(playLog[3].speed, 2, 'invalid speed value ignored')
now = now + 0.5
change('GuestAnimationSpeed', 0 / 0)
check(guestApi.playCustomAnim('41004'), 'nan speed keeps previous')
equal(playLog[4].speed, 2, 'nan speed value ignored')
now = now + 0.5
change('GuestAnimationSpeed', 75)
check(guestApi.playCustomAnim('41005'), 'mid speed play')
equal(playLog[5].speed, 0.75, '75 percent -> 0.75x')
local loopOffTrack = animator.LastTrack
equal(loopOffTrack.Looped, false, 'loop off by default')
change('GuestAnimationLoop', true)
equal(loopOffTrack.Looped, false, 'loop change does not touch live track')
check(loopOffTrack.Playing, 'live track keeps playing')
now = now + 0.5
check(guestApi.playCustomAnim('41006'), 'loop enabled next play')
equal(playLog[6].speed, 0.75, 'speed persists across plays')
equal(animator.LastTrack.Looped, true, 'loop applies to next play only')
check(loopOffTrack.Destroyed, 'previous track disposed on next play')
equal(countLeakedAnimations(), 0, 'clamp/loop group leaks no Animation')

---------------------------------------------------------------------------
-- C1: LoadAnimation 失败不消耗节流，旧活动 Track 与连接保留
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
check(guestApi.playCustomAnim('42001'), 'baseline play before load failure')
local trackA = animator.LastTrack
equal(#getconnections(trackA.Stopped), 1, 'baseline stopped connection registered')
animator.FailLoad = true
now = now + 0.5
local okL, errL = guestApi.playCustomAnim('42002')
check(not okL, 'load failure reported')
equal(errL, 'LoadAnimation 失败', 'load failure message')
check(trackA.Playing, 'previous track survives load failure')
check(not trackA.Destroyed, 'previous track not destroyed by load failure')
equal(#getconnections(trackA.Stopped), 1, 'previous stopped connection preserved')
equal(countLeakedAnimations(), 0, 'failed load destroys temporary Animation')
animator.FailLoad = false
check(guestApi.playCustomAnim('42003'), 'failed load does not consume throttle')
equal(animator.LastId, 'rbxassetid://42003', 'recovered play uses new id')

---------------------------------------------------------------------------
-- C2: Stopped:Connect 失败回收新 Track 且不消耗节流
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
check(guestApi.playCustomAnim("42000"), "play before connect failure")
local beforeConnectTrack = animator.LastTrack
now = now + 0.5
failConnect = true
local okC, errC = guestApi.playCustomAnim('42004')
check(not okC, 'stopped connect failure reported')
equal(errC, '动画回收监听未就绪', 'connect failure message')
check(animator.LastTrack.Destroyed, 'track destroyed when connect fails')
check(beforeConnectTrack.Playing and not beforeConnectTrack.Destroyed, 'old track survives connect failure')
check(getconnections(beforeConnectTrack.Stopped)[1].Connected, 'old subscription survives connect failure')
equal(countLeakedAnimations(), 0, 'connect failure destroys temporary Animation')
failConnect = false
check(guestApi.playCustomAnim('42005'), 'connect failure does not consume throttle')

---------------------------------------------------------------------------
-- C3: Play 失败回收且不消耗节流
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
failPlay = true
local okP, errP = guestApi.playCustomAnim('42006')
check(not okP, 'play failure reported')
equal(errP, '播放失败或请求已失效', 'play failure message')
local failTrack = animator.LastTrack
check(failTrack.Destroyed, 'track destroyed on play failure')
check(not failTrack.Playing, 'play never started on failure')
equal(countLeakedAnimations(), 0, 'play failure destroys temporary Animation')
failPlay = false
check(guestApi.playCustomAnim('42007'), 'play failure does not consume throttle')

---------------------------------------------------------------------------
-- C4: Play 同步触发 Stopped 时回收，不残留活动 Track
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
syncStopped = true
local okS, errS = guestApi.playCustomAnim('42008')
check(not okS, 'synchronous stopped during play reported')
equal(errS, '播放失败或请求已失效', 'sync stopped message')
local syncTrack = animator.LastTrack
check(syncTrack.Destroyed, 'track destroyed when stopped fires inside play')
equal(syncTrack.DestroyCalls, 1, 'synchronous stopped disposes once')
equal(countLeakedAnimations(), 0, 'sync stopped destroys temporary Animation')
syncStopped = false
check(guestApi.playCustomAnim('42009'), 'sync stopped does not consume throttle')
check(animator.LastTrack.Playing, 'module recovers after sync stopped')

---------------------------------------------------------------------------
-- C5: Load 期间换角色回收迟到 Track；Stopped 迟到回收
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
check(guestApi.playCustomAnim('42010'), 'play before character swap')
local preSwapTrack = animator.LastTrack
local swapChar = character('Swapped', 0, survivors)
now = now + 0.5
loadHook = function() localPlayer.Character = swapChar end
local okW, errW = guestApi.playCustomAnim('42011')
check(not okW, 'character swap during load invalidates')
equal(errW, '播放请求已失效', 'swap during load message')
local lateTrack = animator.LastTrack
check(lateTrack ~= preSwapTrack, 'late load produced a new track')
check(lateTrack.Destroyed, 'late track reclaimed after character swap')
equal(countLeakedAnimations(), 0, 'swap reclaim destroys temporary Animation')
loadHook = nil
localPlayer.Character = char
check(guestApi.playCustomAnim('42012'), 'play resumes on original character')
local swapTrack = animator.LastTrack
localPlayer.Character = swapChar
swapTrack.Stopped:Fire()
check(swapTrack.Destroyed, 'stopped handler reclaims after character swap')
localPlayer.Character = char

---------------------------------------------------------------------------
-- C6: Load 期间 stopAnimations 使请求失效并回收 Track
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
loadHook = function() guestApi.stopAnimations() end
local okSt, errSt = guestApi.playCustomAnim('42013')
check(not okSt, 'stop during load invalidates play')
equal(errSt, '播放请求已失效', 'stop during load message')
check(animator.LastTrack.Destroyed, 'track reclaimed when stopped during load')
loadHook = nil
check(guestApi.playCustomAnim('42014'), 'play works after stop during load')

---------------------------------------------------------------------------
-- C7: Destroy 回收活动 Track；迟到 Stopped 不二次回收；销毁后停止
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
check(guestApi.playCustomAnim('42015'), 'play before destroy')
local destroyTrack = animator.LastTrack
local stopBefore = stopCount
guestApi.Destroy()
check(destroyTrack.Destroyed, 'destroy disposes active track')
equal(stopCount, stopBefore + 1, 'destroy stops track once')
local okZ, errZ = guestApi.playCustomAnim('42016')
equal(errZ, '模块已关闭', 'destroyed module message')
destroyTrack.Stopped:Fire()
equal(stopCount, stopBefore + 1, 'late stopped after destroy does not re-dispose')
equal(countLeakedAnimations(), 0, 'destroy path leaks no Animation')

---------------------------------------------------------------------------
-- C7b: Load 期间 Destroy 回收迟到 Track
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
loadHook = function() guestApi.Destroy() end
local okD, errD = guestApi.playCustomAnim('42017')
check(not okD, 'destroy during load invalidates play')
equal(errD, '播放请求已失效', 'destroy during load message')
check(animator.LastTrack.Destroyed, 'late track reclaimed on destroy during load')
loadHook = nil

---------------------------------------------------------------------------
-- D: 正常 Stopped 断连回收，模块可继续播放
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
check(guestApi.playCustomAnim('43001'), 'play for stopped reclaim')
local stopTrack = animator.LastTrack
local stopConns = getconnections(stopTrack.Stopped)
equal(#stopConns, 1, 'stopped connection registered')
check(stopConns[1].Connected, 'stopped connection live')
local stopBeforeD = stopCount
stopTrack.Stopped:Fire()
check(not stopConns[1].Connected, 'stopped connection disconnected on fire')
check(stopTrack.Destroyed, 'track destroyed on stopped')
equal(stopCount, stopBeforeD + 1, 'single stop on reclaim')
now = now + 0.5
check(guestApi.playCustomAnim('43002'), 'play works after stopped reclaim')
equal(countLeakedAnimations(), 0, 'stopped reclaim leaks no Animation')

---------------------------------------------------------------------------
-- E: triggerFakeBlock 门禁与变体路由（共享 playCustomAnim）
---------------------------------------------------------------------------
resetFixtures()
guestApi = freshApi()
fluent.notifications = {}
local loadBeforeE = loadCount
check(not guestApi.triggerFakeBlock(), 'fake block gated until enabled')
equal(loadCount, loadBeforeE, 'gated fake block loads nothing')
check(#fluent.notifications > 0, 'gated fake block notifies')
change('GuestFakeBlockGui', true)
check(guestApi.triggerFakeBlock(), 'enabled fake block plays')
equal(animator.LastId, 'rbxassetid://72722244508749', 'default fake block asset')
equal(playLog[1].speed, 1, 'fake block plays at default 1x')
now = now + 0.5
change('GuestFakeBlockVariant', 'M3 / M4')
check(guestApi.triggerFakeBlock(), 'alternate fake block plays')
equal(animator.LastId, 'rbxassetid://96959123077498', 'alternate fake block asset')
check(animator.LastTrack.Playing, 'alternate fake block track playing')
equal(countLeakedAnimations(), 0, 'fake block leaks no Animation')

-- 收尾：销毁各代工厂并核对所有轨道与订阅。
guestApi.Destroy()
for _, track in ipairs(trackLog) do
    check(track.Destroyed, "every created track reclaimed")
    equal(track.DestroyCalls, 1, "every track destroyed once")
    for _, connection in ipairs(getconnections(track.Stopped)) do
        check(not connection.Connected, "every track subscription disconnected")
    end
end
for _, connection in ipairs(tracked) do
    check(not connection.Connected, "every factory subscription disconnected")
end
resetFixtures()
print('test_guest_animation_r23 assertions: ' .. assertions)
return true
