-- Step 5 Preview (r14): viewport edge regression for the shared WindUI bridge (normal shared GUI only).
-- SNAPSHOT REGRESSION, NOT FROZEN ACCEPTANCE: src/WindAdapter.luau may change under us; re-run this file
-- after any source change. Assembled by tests/run_wind_viewport_edges_r14.mjs on top of the read-only fixture
-- base in tests/test_wind_adapter.luau (everything before the fixture cut marker; the literal marker text is
-- deliberately not quoted here so the executor's post-assembly residue check stays meaningful).
-- Isolation contract: no disk writes, no network, no game features; every scenario restores each global it
-- touches, a failing scenario never blocks the next one, and the run ends with exit 1 if anything failed.
-- Assertions read the window's real writes (native.scale / native.centerWrites / Main.Position), never just
-- callback counts.

-- === fixture additions layered on the read-only base ===
task.wait = task.wait or function() end
UDim2.new = function(xs, xo, ys, yo) return {X = {Scale = xs, Offset = xo}, Y = {Scale = ys, Offset = yo}} end

local asyncErrors = {}
local function drainLayout()
    local guard = 0
    while #queue > 0 do
        guard += 1
        assert(guard < 1000, 'unbounded deferred layout retry')
        local job = table.remove(queue, 1)
        local ok, err = pcall(job)
        if not ok then table.insert(asyncErrors, tostring(err)) end
    end
end

local activeBridge = nil
local function resetFixture()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for i = #connections, 1, -1 do connections[i] = nil end
    for i = #queue, 1, -1 do queue[i] = nil end
    asyncErrors = {}
    native.sections = {}
    native.allTabs = {}
    native.Size = UDim2.fromOffset(700, 500)
    native.scale = 1
    native.scaleWrites = 0
    native.centerWrites = 0
    native.centered = nil
    native.toggles = 0
    native.destroyed = 0
    native.Debug = false
    native.IsFullscreen = false
    native.CurrentTab = nil
    native.windowConfig = nil
    if native.UIElements and native.UIElements.Main then native.UIElements.Main.Position = nil end
    wind.Window = nil
    wind.notifications = {}
    camera.ViewportSize = {X = 420, Y = 800}
    workspace.CurrentCamera = camera
end

local function newBridge(name)
    resetFixture()
    local bridge = createBridge(wind, {Name = name, Env = {}})
    activeBridge = bridge
    local win
    local ok, err = pcall(function() win = bridge:CreateWindow({Title = name, Size = UDim2.fromOffset(700, 500)}) end)
    return bridge, win, ok, err
end

-- Real userdata Vector2 probe: newproxy(true) is genuine userdata; only .X/.Y resolve and any other key
-- errors, so a passing inset scenario also proves the adapter reads X/Y only and never type-checks the pair.
local function vec2(x, y)
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)
    mt.__index = function(_, k)
        if k == 'X' then return x elseif k == 'Y' then return y end
        error('Vector2 has no property ' .. tostring(k))
    end
    return proxy
end

-- GuiService (GetGuiInset -> userdata pair) + TweenService fakes. The fake tween queues a controlled async
-- tail, like a real Tween, so a cancelled tween must not land. Returns controls plus a teardown.
local function installInsetFixture()
    local realGetService, realEnum, realTweenInfo = game.GetService, Enum, TweenInfo
    local state = {top = 0, bottom = 0, left = 0, right = 0}
    local plays, cancels = 0, 0
    local fake = {}
    function fake:Create(main, info, goal)
        local tw = {}
        local cancelled = false
        function tw:Play()
            plays += 1
            task.defer(function()
                if cancelled then return end
                for k, v in pairs(goal) do main[k] = v end
            end)
        end
        function tw:Cancel() cancels += 1; cancelled = true end
        return tw
    end
    game.GetService = function(self, name)
        if name == 'GuiService' then
            return {GetGuiInset = function() return vec2(state.left, state.top), vec2(state.right, state.bottom) end}
        end
        if name == 'TweenService' then return fake end
        return realGetService(self, name)
    end
    TweenInfo = {new = function() return {} end}
    Enum = {KeyCode = realEnum.KeyCode, EasingStyle = {Quint = 'Quint'}, EasingDirection = {Out = 'Out'}}
    local controls = {
        setInset = function(top, bottom, left, right)
            state.top, state.bottom, state.left, state.right = top, bottom, left, right
        end,
        plays = function() return plays end,
        cancels = function() return cancels end,
    }
    controls.teardown = function()
        game.GetService = realGetService
        Enum = realEnum
        TweenInfo = realTweenInfo
    end
    return controls
end

-- Wraps the window Main frame so every Position write is counted while still landing on the real frame.
local function wrapMain()
    local realMain = native.UIElements.Main
    assert(realMain, 'window main frame present')
    local writes = 0
    local main = setmetatable({}, {
        __index = function(_, k) return realMain[k] end,
        __newindex = function(_, k, v) if k == 'Position' then writes += 1 end; realMain[k] = v end,
    })
    native.UIElements.Main = main
    return main, function() return writes end
end

local baseGetService = game.GetService
local baseMain = native.UIElements.Main

local function snapshotGlobals()
    return {
        getService = game.GetService,
        currentCamera = workspace.CurrentCamera,
        viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize,
        tweenInfo = TweenInfo,
        enum = Enum,
        main = native.UIElements.Main,
        setToTheCenter = native.SetToTheCenter,
        setUIScale = native.SetUIScale,
        isFullscreen = native.IsFullscreen,
    }
end
local function restoreGlobals(s)
    game.GetService = s.getService
    workspace.CurrentCamera = s.currentCamera
    if s.currentCamera then s.currentCamera.ViewportSize = s.viewport end
    TweenInfo = s.tweenInfo
    Enum = s.enum
    native.UIElements.Main = s.main
    native.SetToTheCenter = s.setToTheCenter
    native.SetUIScale = s.setUIScale
    native.IsFullscreen = s.isFullscreen
end

local failures, passed, checked = {}, 0, 0
local function check(name, fn)
    checked += 1
    asyncErrors = {}
    local snap = snapshotGlobals()
    local ok, err = pcall(fn)
    local restored, restoreError = pcall(restoreGlobals, snap)
    local cleaned, cleanupError = pcall(function()
        if activeBridge and activeBridge.Active then activeBridge:Destroy(); drainLayout() end
    end)
    if not restored then table.insert(asyncErrors, "global restore failed: " .. tostring(restoreError)) end
    if not cleaned then table.insert(asyncErrors, "cleanup failed: " .. tostring(cleanupError)) end
    -- resetFixture replaces the error list; retain this scenario before resetting.
    local observedErrors = asyncErrors
    resetFixture()
    if #observedErrors > 0 then
        local prefix = ok and "" or (tostring(err) .. "; ")
        ok, err = false, prefix .. "async errors leaked: " .. table.concat(observedErrors, "; ")
    end
    if ok then
        passed += 1
        print('PASS viewport-edge ' .. name)
    else
        local line = 'RED viewport-edge ' .. name .. ': ' .. tostring(err)
        print(line)
        table.insert(failures, line)
    end
end

-- === 1) real userdata X/Y four-edge inset ===
check('four-edge userdata inset drives the exact scale, one tween, and the safe-area offset', function()
    assert(type(vec2(1, 2)) == 'userdata', 'inset probe must be real userdata, not a table stand-in')
    local bridge, win, ok, err = newBridge('R14FourEdgeInset')
    assert(ok and win, err)
    drainLayout()
    -- Creation-time fit runs without the safe area: native centering, classic 40px margin, no tween.
    assert(native.centerWrites == 1 and native.scale == 0.54,
        'creation fit must center natively at the classic margin, centerWrites=' .. tostring(native.centerWrites)
        .. ' scale=' .. tostring(native.scale))
    local controls = installInsetFixture()
    local main, posWrites = wrapMain()
    local plays0, scaleWrites0, centerWrites0 = controls.plays(), native.scaleWrites, native.centerWrites
    controls.setInset(40, 20, 60, 30) -- top, bottom, left, right: all four edges non-zero
    bridge.Options.wind_safe_area:SetValue(true)
    drainLayout()
    assert(bridge.SafeArea == true, 'safe-area toggle must publish its flag')
    -- margins (60+30) x (40+20): availW 330, availH 740 on the 420x800 portrait against the 700x500 window.
    assert(native.scale == 0.47 and bridge.Options.wind_scale.Value == 0.47,
        'four-edge inset scale must be the written 0.47, got scale=' .. tostring(native.scale)
        .. ' option=' .. tostring(bridge.Options.wind_scale.Value))
    assert(native.scaleWrites == scaleWrites0 + 1,
        'exactly one scale write for the inset fit, scaleWrites=' .. tostring(native.scaleWrites))
    assert(controls.plays() == plays0 + 1,
        'safe-area fit must center through exactly one controlled tween, plays=' .. tostring(controls.plays()))
    assert(posWrites() == 1,
        'landing must be exactly one real Position write through the tween tail, writes=' .. tostring(posWrites()))
    assert(main.Position and main.Position.X.Scale == 0.5 and main.Position.X.Offset == 15 and main.Position.Y.Offset == 10,
        'offset must be (left-right)/2=15, (top-bottom)/2=10, got ' .. tostring(main.Position and main.Position.X.Offset)
        .. '/' .. tostring(main.Position and main.Position.Y.Offset))
    assert(native.centerWrites == centerWrites0,
        'safe-area fit must not fall back to native centering, centerWrites=' .. tostring(native.centerWrites))
    assert(#asyncErrors == 0, 'no async errors: ' .. table.concat(asyncErrors, '; '))
    controls.teardown()
    bridge:Destroy(); drainLayout()
    assert(not bridge.Active, 'bridge destroyed')
end)

-- === 2) continuous portrait/landscape rotation ===
check('continuous portrait/landscape rotation keeps the inset offset and lands the exact scale each time', function()
    local bridge, win, ok, err = newBridge('R14RotationLoop')
    assert(ok and win, err)
    drainLayout()
    local controls = installInsetFixture()
    local main, posWrites = wrapMain()
    controls.setInset(40, 20, 60, 30)
    bridge.Options.wind_safe_area:SetValue(true)
    drainLayout()
    local plays0, scaleWrites0 = controls.plays(), native.scaleWrites
    assert(native.scale == 0.47 and main.Position.X.Offset == 15 and main.Position.Y.Offset == 10,
        'portrait baseline 0.47 at offset 15/10')
    local steps = {
        {800, 600, 1}, {500, 400, 0.58}, {420, 800, 0.47},
        {800, 600, 1}, {500, 400, 0.58}, {420, 800, 0.47},
    }
    for index, step in ipairs(steps) do
        camera.ViewportSize = {X = step[1], Y = step[2]}
        viewportSignal:Fire() -- drive through the real camera ViewportSize connection
        drainLayout()
        assert(native.scale == step[3] and bridge.Options.wind_scale.Value == step[3],
            'rotation ' .. index .. ' (' .. step[1] .. 'x' .. step[2] .. ') must land scale ' .. tostring(step[3])
            .. ', got ' .. tostring(native.scale))
        assert(main.Position and main.Position.X.Offset == 15 and main.Position.Y.Offset == 10,
            'rotation ' .. index .. ' must keep the safe-area offset 15/10, got ' .. tostring(main.Position and main.Position.X.Offset)
            .. '/' .. tostring(main.Position and main.Position.Y.Offset))
        assert(controls.plays() == plays0 + index,
            'rotation ' .. index .. ' must play exactly one tween, plays=' .. tostring(controls.plays()))
        assert(#asyncErrors == 0, 'rotation ' .. index .. ' async errors: ' .. table.concat(asyncErrors, '; '))
    end
    -- A repeat of the same geometry is coalesced into the cached layout: no new scale, tween, or Position write.
    local scaleWrites1, posWrites1, plays1 = native.scaleWrites, posWrites(), controls.plays()
    viewportSignal:Fire(); drainLayout()
    assert(native.scale == 0.47 and controls.plays() == plays1 and native.scaleWrites == scaleWrites1 and posWrites() == posWrites1,
        'same-geometry refire must not write scale, tween, or Position again')
    bridge:Destroy(); drainLayout()
    controls.teardown()
end)

-- === 3) camera replacement ===
check('camera replacement refits the new viewport, the stale camera signal stays inert, and nil is a no-op', function()
    local bridge, win, ok, err = newBridge('R14CameraSwap')
    assert(ok and win, err)
    drainLayout()
    local controls = installInsetFixture()
    local main, posWrites = wrapMain()
    controls.setInset(40, 0, 60, 0)
    bridge.Options.wind_safe_area:SetValue(true)
    drainLayout()
    local plays0, scaleWrites0 = controls.plays(), native.scaleWrites
    assert(native.scale == 0.51 and main.Position.X.Offset == 30 and main.Position.Y.Offset == 20,
        'portrait baseline 0.51 at offset 30/20')
    -- Swap through the real world CurrentCamera signal: 900x700 clamps the factor to 1.
    local newCamSignal = signal()
    local newCam = {ViewportSize = {X = 900, Y = 700}, GetPropertyChangedSignal = function() return newCamSignal end}
    workspace.CurrentCamera = newCam
    cameraSignal:Fire()
    drainLayout()
    assert(native.scale == 1 and bridge.Options.wind_scale.Value == 1,
        'replacement camera viewport must clamp scale to 1, got ' .. tostring(native.scale))
    assert(main.Position and main.Position.X.Offset == 30 and main.Position.Y.Offset == 20,
        'insets unchanged keep offset 30/20 after the swap')
    assert(controls.plays() == plays0 + 1 and native.scaleWrites == scaleWrites0 + 1,
        'camera swap plays exactly one tween and one scale write')
    -- The old camera's ViewportSize signal must be inert after the rebind, even with a poisoned viewport.
    camera.ViewportSize = {X = 10, Y = 10}
    viewportSignal:Fire()
    drainLayout()
    bridge:FitViewport()
    drainLayout()
    assert(controls.plays() == plays0 + 1 and native.scale == 1,
        'stale camera signal or read must not refit, plays=' .. tostring(controls.plays()))
    -- Swapping back re-binds and re-fits the original camera.
    workspace.CurrentCamera = camera
    camera.ViewportSize = {X = 420, Y = 800}
    cameraSignal:Fire()
    drainLayout()
    assert(native.scale == 0.51 and controls.plays() == plays0 + 2,
        'swapping back refits 0.51 with one more tween, scale=' .. tostring(native.scale))
    -- A nil CurrentCamera is a guarded no-op; restoring the camera resumes fitting.
    workspace.CurrentCamera = nil
    cameraSignal:Fire()
    drainLayout()
    bridge:FitViewport()
    drainLayout()
    assert(native.scale == 0.51 and controls.plays() == plays0 + 2, 'nil camera must not refit')
    workspace.CurrentCamera = camera
    cameraSignal:Fire()
    drainLayout()
    assert(native.scale == 0.51 and controls.plays() == plays0 + 3,
        'restored camera resumes fitting, plays=' .. tostring(controls.plays()))
    assert(#asyncErrors == 0, 'no async errors: ' .. table.concat(asyncErrors, '; '))
    bridge:Destroy(); drainLayout()
    controls.teardown()
end)

-- === 4) inset-only change ===
check('inset-only changes re-center without a scale write, and released insets fall back to native centering', function()
    local bridge, win, ok, err = newBridge('R14InsetOnly')
    assert(ok and win, err)
    drainLayout()
    local controls = installInsetFixture()
    local main, posWrites = wrapMain()
    controls.setInset(40, 0, 60, 0)
    bridge.Options.wind_safe_area:SetValue(true)
    drainLayout()
    local plays0, scaleWrites0 = controls.plays(), native.scaleWrites
    assert(native.scale == 0.51 and main.Position.X.Offset == 30 and main.Position.Y.Offset == 20,
        'baseline 0.51 at offset 30/20')
    -- Inset-only change that keeps the quantized scale: top 40 -> 80 with the left inset untouched, so
    -- marginX stays 60 and the factor stays 0.51 -- only the vertical offset moves.
    controls.setInset(80, 0, 60, 0)
    bridge:FitViewport()
    drainLayout()
    assert(native.scale == 0.51 and native.scaleWrites == scaleWrites0,
        'inset-only change must not rewrite the scale, scaleWrites=' .. tostring(native.scaleWrites))
    assert(main.Position and main.Position.X.Offset == 30 and main.Position.Y.Offset == 40,
        'inset-only change must re-center to (30,40), got ' .. tostring(main.Position and main.Position.X.Offset)
        .. '/' .. tostring(main.Position and main.Position.Y.Offset))
    assert(controls.plays() == plays0 + 1, 'inset-only change still plays one tween')
    -- Inset change that moves the quantized scale: left 0 -> 120.
    controls.setInset(80, 0, 120, 0)
    bridge:FitViewport()
    drainLayout()
    assert(native.scale == 0.42 and native.scaleWrites == scaleWrites0 + 1,
        'wider left inset must rescale to 0.42 with one write, scale=' .. tostring(native.scale))
    assert(main.Position and main.Position.X.Offset == 60 and main.Position.Y.Offset == 40,
        'offset follows (120-0)/2=60, got ' .. tostring(main.Position and main.Position.X.Offset))
    -- Insets fully released while the safe area stays on: sum 0 -> native centering, no tween, no Position write.
    local plays1, posWrites1 = controls.plays(), posWrites()
    controls.setInset(0, 0, 0, 0)
    bridge:FitViewport()
    drainLayout()
    assert(native.centered == true and native.centerWrites == 2,
        'released insets must fall back to native centering, centerWrites=' .. tostring(native.centerWrites))
    assert(native.scale == 0.54 and native.scaleWrites == scaleWrites0 + 2,
        'released insets return to the classic 40px margin scale 0.54, scale=' .. tostring(native.scale))
    assert(controls.plays() == plays1 and posWrites() == posWrites1,
        'released insets must not tween or write Position')
    assert(main.Position and main.Position.X.Offset == 60 and main.Position.Y.Offset == 40,
        'native centering must not move the frame in the fixture')
    -- Re-applying an inset returns to the tween path.
    controls.setInset(40, 0, 60, 0)
    bridge:FitViewport()
    drainLayout()
    assert(native.scale == 0.51 and main.Position.X.Offset == 30 and main.Position.Y.Offset == 20
        and controls.plays() == plays1 + 1, 're-applied inset returns to the tween path')
    assert(#asyncErrors == 0, 'no async errors: ' .. table.concat(asyncErrors, '; '))
    bridge:Destroy(); drainLayout()
    controls.teardown()
end)

-- === 5) no late writes once auto-fit is disabled ===
check('auto-fit disabled freezes every late write (tail, signal, fullscreen, in-flight) and recovers on re-enable', function()
    local bridge, win, ok, err = newBridge('R14AutoFitOff')
    assert(ok and win, err)
    drainLayout()
    local controls = installInsetFixture()
    local main, posWrites = wrapMain()
    controls.setInset(40, 0, 60, 0)
    bridge.Options.wind_safe_area:SetValue(true)
    drainLayout()
    local plays0, scaleWrites0, centerWrites0 = controls.plays(), native.scaleWrites, native.centerWrites
    assert(native.scale == 0.51 and main.Position.X.Offset == 30 and main.Position.Y.Offset == 20,
        'baseline 0.51 at offset 30/20')

    -- A) A pending safe-area tail is cancelled by the disable with no late Position write. The inset change
    -- keeps the quantized scale (top 40 -> 80, left untouched) so only centering is pending.
    controls.setInset(80, 0, 60, 0)
    bridge:FitViewport()
    assert(controls.plays() == plays0 + 1 and posWrites() == 1,
        'pending tail must play without a direct write, plays=' .. tostring(controls.plays())
        .. ' writes=' .. tostring(posWrites()))
    bridge.Options.wind_auto_fit:SetValue(false)
    drainLayout()
    assert(bridge.AutoFit == false, 'auto-fit toggle must publish its flag')
    assert(posWrites() == 1 and main.Position.X.Offset == 30 and main.Position.Y.Offset == 20,
        'auto-fit off must cancel the pending tail with no late Position write, writes=' .. tostring(posWrites())
        .. ' pos=' .. tostring(main.Position and main.Position.X.Offset) .. '/' .. tostring(main.Position and main.Position.Y.Offset))

    -- B) Quiesced freeze: viewport, inset, and root-size changes all early-return with zero writes.
    camera.ViewportSize = {X = 800, Y = 600}
    viewportSignal:Fire()
    drainLayout()
    controls.setInset(40, 20, 60, 30)
    bridge:FitViewport()
    drainLayout()
    native:SetSize(UDim2.fromOffset(500, 400))
    drainLayout()
    assert(native.scale == 0.51 and native.scaleWrites == scaleWrites0 and native.centerWrites == centerWrites0
        and controls.plays() == plays0 + 1 and posWrites() == 1,
        'auto-fit off must not write scale, tween, Position, or native centering')
    assert(main.Position and main.Position.X.Offset == 30 and main.Position.Y.Offset == 20,
        'frame must stay where the last fit left it')
    assert(#asyncErrors == 0, 'no async errors while frozen: ' .. table.concat(asyncErrors, '; '))

    -- C) Re-enabling refits the geometry accumulated while frozen.
    native:SetSize(UDim2.fromOffset(700, 500))
    bridge.Options.wind_auto_fit:SetValue(true)
    drainLayout()
    assert(native.scale == 1 and native.scaleWrites == scaleWrites0 + 1,
        're-enable refits 800x600 against the four-edge inset to 1, scale=' .. tostring(native.scale))
    assert(main.Position and main.Position.X.Offset == 15 and main.Position.Y.Offset == 10,
        're-enable lands offset 15/10')
    assert(controls.plays() == plays0 + 2 and posWrites() == 2, 're-enable plays exactly one tween')

    -- D) Fullscreen early-exit writes nothing; leaving fullscreen refits.
    native.IsFullscreen = true
    camera.ViewportSize = {X = 420, Y = 800}
    viewportSignal:Fire()
    drainLayout()
    bridge:FitViewport()
    drainLayout()
    local plays1, posWrites1, scaleWrites1 = controls.plays(), posWrites(), native.scaleWrites
    assert(native.scale == 1 and controls.plays() == plays1 and posWrites() == posWrites1 and native.scaleWrites == scaleWrites1,
        'fullscreen early-exit must write nothing')
    native.IsFullscreen = false
    viewportSignal:Fire()
    drainLayout()
    assert(native.scale == 0.47 and controls.plays() == plays1 + 1 and posWrites() == posWrites1 + 1
        and native.scaleWrites == scaleWrites1 + 1, 'leaving fullscreen refits 420x800 to 0.47')

    -- E) In-flight suspension: disabling mid-fit commits only the scale write already in progress, never a
    -- centering or Position write, and the queued replacement layout is also inert.
    local originalSetUIScale = native.SetUIScale
    native.SetUIScale = function(self, value)
        coroutine.yield('r14 scale suspended')
        return originalSetUIScale(self, value)
    end
    camera.ViewportSize = {X = 500, Y = 400}
    local thread = coroutine.create(function() bridge:FitViewport() end)
    local resumed, marker = coroutine.resume(thread)
    assert(resumed and coroutine.status(thread) == 'suspended' and marker == 'r14 scale suspended',
        'fit must suspend inside the scale write')
    bridge.Options.wind_auto_fit:SetValue(false)
    drainLayout()
    assert(bridge.AutoFit == false and #asyncErrors == 0, 'disable during suspension must stay clean')
    local centersBefore, posBefore, playsBefore = native.centerWrites, posWrites(), controls.plays()
    coroutine.resume(thread)
    native.SetUIScale = originalSetUIScale
    drainLayout()
    assert(native.scale == 0.58 and native.scaleWrites == scaleWrites1 + 2,
        'suspended scale write commits exactly its in-flight value 0.58 on top of the leaving-fullscreen refit, scale='
        .. tostring(native.scale) .. ' scaleWrites=' .. tostring(native.scaleWrites))
    assert(native.centerWrites == centersBefore and posWrites() == posBefore and controls.plays() == playsBefore,
        'suspended fit cancelled by auto-fit off must not center or write Position')
    -- Recovery: re-enable re-centers without another scale write.
    bridge.Options.wind_auto_fit:SetValue(true)
    drainLayout()
    assert(controls.plays() == playsBefore + 1 and posWrites() == posBefore + 1
        and main.Position.X.Offset == 15 and main.Position.Y.Offset == 10 and native.scale == 0.58,
        're-enable re-centers with no redundant scale write')

    bridge:Destroy(); drainLayout()
    controls.teardown()
end)

-- === 6) narrow viewport + ReadabilityGuard / min-scale overflow boundary ===
check('narrow viewport readability floor keeps the documented overflow and the clamp boundaries stay exact', function()
    local bridge, win, ok, err = newBridge('R14NarrowGuard')
    assert(ok and win, err)
    drainLayout()
    local controls = installInsetFixture()
    local main, posWrites = wrapMain()
    local plays0, scaleWrites0, centerWrites0 = controls.plays(), native.scaleWrites, native.centerWrites
    -- Classic margin on a 300x500 narrow portrait: availW 260 -> 0.37, which still fits (259 <= 260).
    camera.ViewportSize = {X = 300, Y = 500}
    viewportSignal:Fire()
    drainLayout()
    assert(native.scale == 0.37 and bridge.Options.wind_scale.Value == 0.37,
        'narrow classic-margin scale must be 0.37, got ' .. tostring(native.scale))
    assert(700 * 0.37 <= 300 - 40, '0.37 must fit the 260px available width by the floor discipline')
    local centerWrites1 = native.centerWrites

    -- Guard on with min-scale 0.5: legibility wins over completeness, so a 350px frame in a 260px column is
    -- the documented, explicitly expected overflow -- not a claim of full adaptation.
    bridge.Options.wind_readability_guard:SetValue(true)
    drainLayout()
    assert(bridge.ReadabilityGuard == true and native.scale == 0.5,
        'readability guard must floor the scale at min-scale 0.5, got ' .. tostring(native.scale))
    assert(700 * 0.5 > 300 - 40,
        'documented legibility-over-completeness overflow must be present at min-scale 0.5, not hidden')
    assert(native.centerWrites == centerWrites1 + 1, 'guard fit still routes through native centering, centerWrites='
        .. tostring(native.centerWrites))

    -- min-scale 1: factor saturates at 1, never above.
    bridge.Options.wind_min_scale:SetValue(1)
    drainLayout()
    assert(native.scale == 1 and bridge.Options.wind_scale.Value == 1,
        'min-scale 1 must clamp the factor to exactly 1, got ' .. tostring(native.scale))

    -- min-scale 0.3: computed 0.37 wins over the floor, no overflow.
    bridge.Options.wind_min_scale:SetValue(0.3)
    drainLayout()
    assert(native.scale == 0.37, 'computed 0.37 must win over the 0.3 floor, got ' .. tostring(native.scale))
    assert(700 * 0.37 <= 300 - 40, 'no overflow when the computed factor wins')

    -- Guard off: identical geometry is fully coalesced, zero writes.
    local plays1, scaleWrites1, centerWrites1 = controls.plays(), native.scaleWrites, native.centerWrites
    bridge.Options.wind_readability_guard:SetValue(false)
    drainLayout()
    assert(native.scale == 0.37 and controls.plays() == plays1 and native.scaleWrites == scaleWrites1
        and native.centerWrites == centerWrites1, 'guard off with identical geometry must write nothing')

    -- Narrow + safe area + guard: margins 140x100 -> availW 160; guard floors 0.22 up to 0.3 (210px > 160px,
    -- documented overflow) while the safe-area offset (10,10) still lands through one tween. The guard is
    -- re-enabled here because the previous step deliberately switched it off.
    controls.setInset(60, 40, 80, 60)
    bridge.Options.wind_readability_guard:SetValue(true)
    bridge.Options.wind_safe_area:SetValue(true)
    drainLayout()
    assert(native.scale == 0.3 and bridge.Options.wind_scale.Value == 0.3,
        'safe-area narrow guard scale must be the floored 0.3, got ' .. tostring(native.scale))
    assert(700 * 0.3 > 300 - 140,
        'documented overflow must stay visible under safe-area narrowing (210 > 160), not hidden')
    assert(main.Position and main.Position.X.Offset == 10 and main.Position.Y.Offset == 10,
        'safe-area offset must be (80-60)/2=10, (60-40)/2=10, got ' .. tostring(main.Position and main.Position.X.Offset)
        .. '/' .. tostring(main.Position and main.Position.Y.Offset))
    assert(controls.plays() == plays0 + 1, 'safe-area narrow guard plays exactly one tween')

    -- 45x45: avail clamps to the 40px floor -> factor 0.05 -> clamp floor 0.1; the guard then holds 0.3.
    camera.ViewportSize = {X = 45, Y = 45}
    viewportSignal:Fire()
    drainLayout()
    assert(native.scale == 0.3, 'guard floor must hold 0.3 at the 45x45 boundary, got ' .. tostring(native.scale))
    local plays2 = controls.plays()
    bridge.Options.wind_readability_guard:SetValue(false)
    drainLayout()
    assert(native.scale == 0.1 and bridge.Options.wind_scale.Value == 0.1,
        'without the guard the 45x45 clamp floor must be exactly 0.1, got ' .. tostring(native.scale))
    assert(controls.plays() == plays2 + 1, 'clamp-floor fit still plays one tween')

    -- 30x30: below the hard guard, every write stays frozen.
    local plays3, posWrites3, scaleWrites3, centerWrites3 = controls.plays(), posWrites(), native.scaleWrites, native.centerWrites
    camera.ViewportSize = {X = 30, Y = 30}
    viewportSignal:Fire()
    drainLayout()
    assert(native.scale == 0.1 and controls.plays() == plays3 and posWrites() == posWrites3
        and native.scaleWrites == scaleWrites3 and native.centerWrites == centerWrites3,
        '30x30 must hit the hard guard with zero writes')
    assert(#asyncErrors == 0, 'no async errors: ' .. table.concat(asyncErrors, '; '))

    bridge.Options.wind_safe_area:SetValue(false)
    bridge.Options.wind_min_scale:SetValue(0.5)
    bridge:Destroy(); drainLayout()
    controls.teardown()
end)

-- Non-finite geometry must cancel stale animation without scheduling retries.
for _, axis in ipairs({"viewport-x", "viewport-y", "window-x", "window-y"}) do
    for _, sample in ipairs({{name = "nan", value = 0 / 0}, {name = "positive-infinity", value = math.huge}, {name = "negative-infinity", value = -math.huge}}) do
        check("non-finite " .. axis .. " " .. sample.name .. " cancels and recovers", function()
            local bridge, win, ok, err = newBridge("R44FiniteGeometry")
            assert(ok and win, err)
            drainLayout()
            local controls = installInsetFixture()
            local main, posWrites = wrapMain()
            controls.setInset(40, 20, 60, 30)
            bridge.Options.wind_safe_area:SetValue(true)
            drainLayout()
            controls.setInset(80, 20, 60, 30)
            bridge:FitViewport()
            local writes, scaleWrites, plays = posWrites(), native.scaleWrites, controls.plays()
            local scale = native.scale
            assert(#queue > 0, "valid layout must leave a pending tween tail")
            if axis == "viewport-x" then camera.ViewportSize = {X = sample.value, Y = 800}
            elseif axis == "viewport-y" then camera.ViewportSize = {X = 420, Y = sample.value}
            elseif axis == "window-x" then native.Size = UDim2.fromOffset(sample.value, 500)
            else native.Size = UDim2.fromOffset(700, sample.value) end
            bridge:FitViewport()
            drainLayout()
            assert(#asyncErrors == 0, "non-finite geometry must not raise async errors")
            assert(posWrites() == writes, "non-finite geometry must cancel the pending position write")
            assert(native.scale == scale and native.scaleWrites == scaleWrites, "non-finite geometry must not write scale")
            assert(controls.plays() == plays, "non-finite geometry must not start a tween")
            camera.ViewportSize = {X = 420, Y = 800}
            native.Size = UDim2.fromOffset(700, 500)
            bridge:FitViewport()
            drainLayout()
            assert(posWrites() == writes + 1 and controls.plays() == plays + 1, "finite geometry must invalidate cache and resume layout")
            assert(native.scale == 0.47 and main.Position.X.Offset == 15 and main.Position.Y.Offset == 30, "recovered layout must use the current safe area")
            assert(#queue == 0 and #asyncErrors == 0, "recovered layout must leave no deferred retry")
            controls.teardown()
            bridge:Destroy(); drainLayout()
        end)
    end
end

-- === fixture hygiene ===
check('fixture hygiene: every scenario restored the globals it touched', function()
    assert(game.GetService == baseGetService, 'game.GetService must be restored')
    assert(TweenInfo == nil, 'TweenInfo must be restored to absent')
    assert(Enum and Enum.KeyCode and Enum.KeyCode.K == 'K' and Enum.EasingStyle == nil,
        'Enum must be restored to the base shape')
    assert(workspace.CurrentCamera == camera, 'workspace.CurrentCamera must be restored')
    assert(camera.ViewportSize.X == 420 and camera.ViewportSize.Y == 800, 'camera viewport must be restored')
    assert(native.UIElements.Main == baseMain, 'window Main must be restored to the fixture frame')
    assert(native.IsFullscreen == false, 'IsFullscreen must be restored')
    assert(#queue == 0 and #connections == 0, 'queue and connections must be drained and disconnected')
    assert(activeBridge == nil or not activeBridge.Active, 'no bridge may stay active')
    assert(native.scale == 1 and native.centerWrites == 0 and wind.Window == nil, 'fixture counters must be reset')
end)

print(string.format('WIND_VIEWPORT_EDGES_R14: passed=%d failed=%d checks=%d', passed, #failures, checked))
if #failures > 0 then
    for _, line in ipairs(failures) do print(line) end
    error('WIND_VIEWPORT_EDGES_R14_RED: ' .. #failures .. ' scenario(s) failed', 0)
end
print('WIND_VIEWPORT_EDGES_R14_GREEN')
