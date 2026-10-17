-- R14 input-queue snapshot regression (Step 5 Preview subagent deliverable).
-- Scope: ordinary shared GUI only. Fake business callbacks on Slider/Input/Dropdown.
-- No game options, no network, no game remote calls, no release build.
-- This file is concatenated after tests/wind_native_harness.luau by
-- tests/run_wind_input_queue_r14.mjs; createBridge comes from the base mock
-- (tests/test_wind_adapter.luau head) and is replaced with the real
-- src/WindAdapter.luau factory by the runner.
local failures, passed, checked = {}, 0, 0
local function check(name, fn)
    checked += 1
    local ok, err = pcall(fn)
    if ok then
        passed += 1
        print('PASS r14 ' .. name)
    else
        local line = 'RED r14 ' .. name .. ': ' .. tostring(err)
        print(line)
        table.insert(failures, line)
    end
end

local function newBridge(name)
    __windReset()
    local bridge = createBridge(__windWind, {Name = name, Env = {}})
    local win
    local ok, err = pcall(function() win = bridge:CreateWindow({Title = name, Size = UDim2.fromOffset(700, 500)}) end)
    return bridge, win, ok, err
end

local function drainLayout()
    __windDrain()
    assert(#__windAsyncErrors == 0, 'layout deferred task failed: ' .. table.concat(__windAsyncErrors, '; '))
end

-- Argument-carrying signal clone: the base mock signal() drops Fire() payloads,
-- but the vendor slider InputEnded handler needs the input object identity.
local function signalWithArgs()
    local s = {listeners = {}}
    function s:Connect(fn)
        local c = {Connected = true}
        function c:Disconnect() self.Connected = false end
        table.insert(self.listeners, {fn = fn, connection = c})
        table.insert(connections, c)
        return c
    end
    function s:Fire(...) for _, l in ipairs(self.listeners) do if l.connection.Connected then l.fn(...) end end end
    return s
end

-- Vendor globals the real WindUI slider slice reads at call time. They are not
-- defined by the harness, so a touch drag cannot be simulated without them.
Enum.UserInputType = {MouseButton1 = 'MouseButton1', Touch = 'Touch'}
ac = {InputEnded = signalWithArgs(), GetMouseLocation = function() return {X = 0} end}
ad = {RenderStepped = signalWithArgs()}
ak = {WindUI = {}, Window = {}}

local function sliderFixture(name, spec)
    __windAsyncErrors = {}
    local bridge, win, ok, err = newBridge(name)
    assert(ok, err); drainLayout()
    local option = win:AddTab({Title = 'Queue'}):AddSlider('r14_' .. name, spec)
    drainLayout()
    return bridge, option
end

local function dropdownFixture(onBusiness)
    __windAsyncErrors = {}
    local bridge, win, ok, err = newBridge('InputQueueR14Dropdown')
    assert(ok, err); drainLayout()
    local spec = {Values = {'a', 'b'}, Default = 'a'}
    if onBusiness then spec.Callback = onBusiness end
    local option = win:AddTab({Title = 'Dropdown'}):AddDropdown('r14_refresh_list', spec)
    local ap, ak = option.Native, {SafeCallback = function(fn, ...) fn(...) end}
    local as = ap
    ap.MenuWidth = 160
    ap.UIElements = {MenuCanvas = {Size = UDim2.new(0, 160, 0, 100)}}
    function as:Display() self.displayCount = (self.displayCount or 0) + 1 end
    __VENDOR_DROPDOWN_CALLBACK__
    function as.Refresh(au, av)
        au.refreshCount += 1
        if au.BeforeRefresh then au.BeforeRefresh(av) end
        __VENDOR_DROPDOWN_COMMIT__
    __VENDOR_DROPDOWN_SELECT__
    local baseSelect = as.Select
    function as.Select(au, av)
        au.selectCount = (au.selectCount or 0) + 1
        return baseSelect(au, av)
    end
    drainLayout()
    return bridge, option
end

-- R1: dense touch-drag updates collapse to the final value with one business
-- callback per distinct published position, and a programmatic write right
-- after release is accepted synchronously.
check('touch drag dense updates land on final value with exact callback count', function()
    local calls = 0
    local bridge, slider = sliderFixture('TouchDense', {Min = 0, Max = 1, Default = 0.2, Rounding = 2, Callback = function() calls += 1 end})
    assert(calls == 1 and slider.Value == 0.2, 'creation must emit exactly once, got calls=' .. calls .. ' value=' .. tostring(slider.Value))
    local icon = slider.Native.UIElements.SliderIcon
    icon.AbsolutePosition = {X = 0}
    icon.AbsoluteSize = {X = 100}
    local touch = {UserInputType = 'Touch', Position = {X = 10}}
    slider.Native:Set(nil, touch)
    assert(calls == 2 and slider.Value == 0.1, 'first touch sample must publish 0.1, got calls=' .. calls .. ' value=' .. tostring(slider.Value))
    local positions = {15, 20, 20, 35, 50, 65, 80, 95, 95, 100}
    for _, x in ipairs(positions) do
        touch.Position.X = x
        ad.RenderStepped:Fire()
    end
    drainLayout()
    assert(calls == 10, 'dense drag must publish 8 distinct samples after creation and first touch, got calls=' .. calls)
    assert(slider.Value == 1, 'final drag value must be 1, got ' .. tostring(slider.Value))
    assert(slider.Native.Value.Default == 1, 'native default must track final drag value, got ' .. tostring(slider.Native.Value.Default))
    assert(slider.Native.UIElements.SliderContainer.TextBox.Text == 1, 'vendor drag path must refresh the textbox to the final value, got ' .. tostring(slider.Native.UIElements.SliderContainer.TextBox.Text))
    assert(slider.Pending == nil, 'accepted native drag writes must not leave a pending retry')
    ac.InputEnded:Fire(touch)
    assert(slider:SetValue(0.3) == true, 'programmatic write after release must be accepted')
    assert(calls == 11 and slider.Value == 0.3, 'post-release write must publish once, got calls=' .. calls .. ' value=' .. tostring(slider.Value))
    bridge:Destroy(); drainLayout()
end)

-- R2: a programmatic write that arrives while the vendor drag gate is busy is
-- parked as Pending, then the release flush applies it exactly once.
check('busy drag gate parks programmatic write and release flush applies it once', function()
    local calls = 0
    local bridge, slider = sliderFixture('DragGate', {Min = 0, Max = 1, Default = 0.2, Rounding = 2, Callback = function() calls += 1 end})
    local icon = slider.Native.UIElements.SliderIcon
    icon.AbsolutePosition = {X = 0}
    icon.AbsoluteSize = {X = 100}
    local touch = {UserInputType = 'Touch', Position = {X = 20}}
    slider.Native:Set(nil, touch)
    assert(calls == 1 and slider.Value == 0.2, 'drag start at the current value must not republish, got calls=' .. calls)
    assert(slider:SetValue(0.8) == false, 'write during vendor drag must be rejected')
    assert(slider.Pending == 0.8, 'rejected write must park as Pending, got ' .. tostring(slider.Pending))
    assert(calls == 1 and slider.Value == 0.2, 'parked write must not publish yet, got calls=' .. calls)
    ac.InputEnded:Fire(touch)
    __windRelease()
    assert(calls == 2, 'release flush must apply the parked write exactly once, got calls=' .. calls)
    assert(slider.Value == 0.8 and slider.Native.Value.Default == 0.8, 'flushed value must land, got ' .. tostring(slider.Value))
    assert(slider.Pending == nil, 'flush must clear the parked write')
    bridge:Destroy(); drainLayout()
end)

-- R3: Input text path normalizes non-string writes through tostring and the
-- business callback plus OnChanged listeners observe every accepted write.
check('input text writes normalize and notify business callback and listeners', function()
    local calls, heard = 0, {}
    local bridge, win, ok, err = newBridge('InputText')
    assert(ok, err); drainLayout()
    local option = win:AddTab({Title = 'Queue'}):AddInput('r14_text', {Default = 'alpha', Callback = function(value) calls += 1; heard[#heard + 1] = value end})
    drainLayout()
    assert(calls == 1 and option.Value == 'alpha', 'creation must emit once, got calls=' .. calls .. ' value=' .. tostring(option.Value))
    assert(option:SetValue('beta') == true, 'text write must be accepted')
    assert(calls == 2 and option.Value == 'beta' and heard[2] == 'beta', 'accepted text write must publish, got calls=' .. calls)
    assert(option:SetValue(42) == true, 'numeric write must be accepted and normalized')
    assert(calls == 3 and option.Value == '42' and heard[3] == '42', 'numeric write must normalize to string 42, got value=' .. tostring(option.Value))
    local listenerCalls = 0
    option:OnChanged(function() listenerCalls += 1 end)
    assert(listenerCalls == 1, 'OnChanged must replay the current value once, got ' .. listenerCalls)
    assert(option:SetValue('gamma') == true)
    assert(listenerCalls == 2 and calls == 4, 'listener and business callback must observe the accepted write, got listener=' .. listenerCalls .. ' calls=' .. calls)
    bridge:Destroy(); drainLayout()
end)

-- R4: while a native refresh is suspended, a Select and a Refresh queued back
-- to back both settle in request order, with exactly one business emission.
check('suspended dropdown settles batched select and refresh with one business event', function()
    local business = 0
    local bridge, option = dropdownFixture(function() business += 1 end)
    local refreshBaseline = option.Native.refreshCount
    assert(refreshBaseline == 0, 'construction must not refresh the native list, got ' .. tostring(refreshBaseline))
    assert(business == 1, 'dropdown creation must emit once, got ' .. business)
    local listener = 0
    option:OnChanged(function() listener += 1 end)
    assert(listener == 1, 'OnChanged must replay once, got ' .. listener)
    local first = true
    option.Native.BeforeRefresh = function() if first then first = false; coroutine.yield('refresh suspended') end end
    local thread = coroutine.create(function() option:SetValues({'c', 'd'}) end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'refresh suspended', 'suspended refresh did not yield: ' .. tostring(marker))
    assert(option.SelectPending == nil and option.RefreshPending == nil, 'pendings must start empty')
    assert(option:SetValue('b') == false, 'select during busy refresh must queue')
    assert(option.SelectPending and option.SelectPending.Value == 'b', 'queued select lost its value')
    assert(option:SetValues({'e', 'f'}) == false, 'refresh during busy refresh must queue')
    assert(option.RefreshPending and option.RefreshPending[1] == 'e', 'queued refresh lost its list')
    assert(business == 1 and listener == 1, 'queued batch must not publish before the gate opens')
    local resumed, err = coroutine.resume(thread)
    assert(resumed and coroutine.status(thread) == 'dead', err)
    drainLayout()
    assert(business == 2, 'batched select plus refresh must publish exactly one business event, got ' .. business)
    assert(listener == 2, 'batched select plus refresh must notify listeners exactly once, got ' .. listener)
    assert(option.Value == 'b' and option.Native.Value == 'b', 'queued selection lost, got ' .. tostring(option.Value))
    assert(option.Values[1] == 'e' and option.Values[2] == 'f', 'bridge cache must hold the newest list')
    assert(option.Native.Values[1] == 'e' and option.Native.Values[2] == 'f', 'native list must hold the newest refresh')
    -- Vendor as.Select ends with as:Refresh(ap.Values) (vendor/WindUI/Source.lua:33039-33046),
    -- so the batched phase performs three native refreshes: the suspended batch list,
    -- the select's internal vendor refresh, and the queued newest list.
    assert(option.Native.selectCount == 1, 'batched phase must select exactly once, got ' .. tostring(option.Native.selectCount))
    assert(option.Native.refreshCount == option.Native.selectCount + 2, 'phase must add two refresh passes plus one per native select, got refreshes=' .. tostring(option.Native.refreshCount) .. ' selects=' .. tostring(option.Native.selectCount))
    assert(option.Native.refreshCount == refreshBaseline + 3, 'suspended phase must add exactly three native refreshes over baseline ' .. tostring(refreshBaseline) .. ', got ' .. tostring(option.Native.refreshCount))
    assert(option.SelectPending == nil and option.RefreshPending == nil, 'pendings must clear after settle')
    bridge:Destroy(); drainLayout()
end)

-- R5: closing the bridge mid-drag freezes business state. Vendor render hooks
-- that survive on test-owned globals may still touch the native mock, but the
-- adapter gate must not turn them into business writes or queued retries.
check('close during drag freezes business state against stray native events', function()
    local calls = 0
    local bridge, slider = sliderFixture('MidDragClose', {Min = 0, Max = 1, Default = 0.2, Rounding = 2, Callback = function() calls += 1 end})
    local icon = slider.Native.UIElements.SliderIcon
    icon.AbsolutePosition = {X = 0}
    icon.AbsoluteSize = {X = 100}
    local touch = {UserInputType = 'Touch', Position = {X = 70}}
    slider.Native:Set(nil, touch)
    assert(calls == 2 and slider.Value == 0.7, 'drag to 0.7 must publish once, got calls=' .. calls .. ' value=' .. tostring(slider.Value))
    bridge:Destroy(); drainLayout()
    touch.Position.X = 90
    ad.RenderStepped:Fire()
    ac.InputEnded:Fire(touch)
    __windRelease()
    assert(calls == 2, 'post-close stray native events must not write business state, got calls=' .. calls)
    assert(slider.Value == 0.7, 'post-close bridge value must stay frozen at 0.7, got ' .. tostring(slider.Value))
    assert(slider.Pending == nil, 'post-close events must not park retries')
    assert(#__windAsyncErrors == 0, 'post-close stray events must not raise adapter errors')
    drainLayout()
end)

-- R6: a native input that arrives while a programmatic write is parked
-- supersedes it (src/WindAdapter.luau changed() clears Pending on a newer native
-- value). The parked write must not survive to the release flush: after
-- supersede the flush performs zero extra native Set calls, proven by counting
-- native writes on a wrapper instead of only business callbacks.
check('a newer native input supersedes the parked write and the release flush performs no extra native write', function()
    local calls = 0
    local bridge, slider = sliderFixture('NativeSupersede', {Min = 0, Max = 1, Default = 0.2, Rounding = 2, Callback = function() calls += 1 end})
    local nativeSetCalls = 0
    local baseSet = slider.Native.Set
    slider.Native.Set = function(au, av, aq)
        nativeSetCalls += 1
        return baseSet(au, av, aq)
    end
    local icon = slider.Native.UIElements.SliderIcon
    icon.AbsolutePosition = {X = 0}
    icon.AbsoluteSize = {X = 100}
    local touch = {UserInputType = 'Touch', Position = {X = 10}}
    slider.Native:Set(nil, touch)
    drainLayout()
    assert(calls == 2, 'touch drag must publish 0.1 once, got calls=' .. calls)
    assert(slider.Value == 0.1, 'touch drag must land 0.1, got ' .. tostring(slider.Value))
    assert(nativeSetCalls == 1, 'the drag publish path must not call the programmatic setter, got ' .. nativeSetCalls)
    assert(slider:SetValue(0.8) == false, 'busy drag gate must reject the programmatic write')
    assert(slider.Pending == 0.8, 'the rejected write must stay parked at 0.8, got ' .. tostring(slider.Pending))
    assert(nativeSetCalls == 2, 'the rejected write still performs exactly one native set, got ' .. nativeSetCalls)
    touch.Position.X = 90
    ad.RenderStepped:Fire()
    drainLayout()
    assert(calls == 3, 'the newer drag value must notify the business callback once, got calls=' .. calls)
    assert(slider.Value == 0.9, 'the newer drag value must win, got ' .. tostring(slider.Value))
    assert(slider.Pending == nil, 'a newer native input must clear the parked write, got ' .. tostring(slider.Pending))
    assert(nativeSetCalls == 2, 'the newer native value must not go through the programmatic setter, got ' .. nativeSetCalls)
    ac.InputEnded:Fire(touch)
    __windRelease()
    drainLayout()
    assert(nativeSetCalls == 2, 'release flush must not write when the parked value was superseded, got ' .. nativeSetCalls)
    assert(calls == 3, 'no extra business event may fire after supersede, got calls=' .. calls)
    assert(slider.Value == 0.9, 'final value must stay the superseded drag value, got ' .. tostring(slider.Value))
    bridge:Destroy(); drainLayout()
end)

-- R7: a business callback that raises during the release flush is captured by
-- safeCallback (src/WindAdapter.luau:128 pcall) instead of leaking into the
-- task.defer drainer. The write still lands, the error is recorded on the
-- bridge, and the queue keeps working afterwards.
check('async business callback errors are captured and never leak into the flush drainer', function()
    local calls = 0
    local onBusiness = function(value)
        calls += 1
        if value == 0.8 then error('r14 async boom') end
    end
    local bridge, slider = sliderFixture('AsyncError', {Min = 0, Max = 1, Default = 0.2, Rounding = 2, Callback = onBusiness})
    local icon = slider.Native.UIElements.SliderIcon
    icon.AbsolutePosition = {X = 0}
    icon.AbsoluteSize = {X = 100}
    local touch = {UserInputType = 'Touch', Position = {X = 20}}
    slider.Native:Set(nil, touch)
    drainLayout()
    assert(calls == 1, 'the 0.2 creation callback must succeed, got calls=' .. calls)
    assert(slider:SetValue(0.8) == false, 'busy drag gate must reject the write that will fail in the callback')
    assert(slider.Pending == 0.8, '0.8 must stay parked, got ' .. tostring(slider.Pending))
    ac.InputEnded:Fire(touch)
    __windRelease()
    drainLayout()
    assert(slider.Value == 0.8, 'the flush must still land 0.8 despite the failing callback, got ' .. tostring(slider.Value))
    assert(calls == 2, 'the failing callback must still count as one business event, got calls=' .. calls)
    assert(bridge.LastError ~= nil and string.find(bridge.LastError, 'r14 async boom', 1, true), 'the adapter must record the async callback error on the bridge, got ' .. tostring(bridge.LastError))
    assert(#__windAsyncErrors == 0, 'the async callback error must not leak into the drainer')
    assert(slider:SetValue(0.4) == true, 'the queue must keep working after a captured callback error')
    drainLayout()
    assert(slider.Value == 0.4, 'the post-error write must land, got ' .. tostring(slider.Value))
    assert(calls == 3, 'the post-error callback must fire once, got calls=' .. calls)
    bridge:Destroy(); drainLayout()
end)

print('R14 RESULT passed=' .. passed .. ' failed=' .. #failures .. ' checked=' .. checked)
if #failures > 0 then
    error('r14 snapshot regression: ' .. #failures .. ' check(s) failed')
end
