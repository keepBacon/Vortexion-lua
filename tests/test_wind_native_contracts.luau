local createBridge = __FACTORY__
local function vendorColorpicker(c)
    local aw = {__type = 'Colorpicker', Default = c.Default, Callback = c.Callback, UIElements = {Colorpicker = {}}}
    __VENDOR_COLORPICKER__
    return aw
end
local colorBaseElement = element
element = function(kind, c)
    if kind == 'Colorpicker' then return vendorColorpicker(c) end
    return colorBaseElement(kind, c)
end
local failures, passed, checked = {}, 0, 0
local function check(name, fn)
    checked += 1
    local ok, err = pcall(fn)
    if ok then
        passed += 1
        print("PASS contract " .. name)
    else
        local line = "RED contract " .. name .. ": " .. tostring(err)
        print(line)
        table.insert(failures, line)
    end
end
local function fileEnv()
    local env = {}
    for _, name in ipairs({"readfile", "writefile", "isfile", "isfolder", "makefolder", "listfiles"}) do
        env[name] = function() return true end
    end
    return env
end
local function button(bridge, title)
    for _, item in ipairs(bridge.SettingsTabs["配置"].Native.elements) do
        if item.Title == title then return item end
    end
    error("missing config button: " .. title)
end
local function newBridge(name, env)
    __windReset()
    local bridge = createBridge(__windWind, {Name = name, Env = env or {}})
    local win
    local ok, err = pcall(function() win = bridge:CreateWindow({Title = name, Size = UDim2.fromOffset(700, 500)}) end)
    return bridge, win, ok, err
end
check('color vendor Set is silent but bridge SetValue synchronizes once', function()
    __windConfigManager = nil
    local bridge, win, ok, err = newBridge('ColorVendorSet'); assert(ok, err)
    local red, blue = Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255)
    local calls = 0
    local color = win:AddTab({Title = 'Contract'}):AddColorpicker('vendor_color', {Default = red, Callback = function() calls += 1 end})
    assert(calls == 1 and color.Native.Value == nil, 'color constructor uses Default, never Value')
    color.Native:Set(blue)
    assert(calls == 1 and color.Value:ToHex() == red:ToHex() and color.Native.Default:ToHex() == blue:ToHex(), 'real vendor Set must remain silent')
    color:SetValue(blue); __windDrain()
    assert(calls == 2 and color.Value:ToHex() == blue:ToHex(), 'bridge must synchronize silent vendor Set')
    color:SetValue(blue); __windDrain(); assert(calls == 2, 'same color must not dispatch twice')
    bridge:Destroy(); __windDrain()
end)

check('color config round trip synchronizes business state and contains bad entries', function()
    __windAsyncErrors = {}
    __windConfigManager = {Parser = __windParserTable()}
    function __windConfigManager:AllConfigs() return {'default'} end
    function __windConfigManager:CreateConfig()
        local c = {Elements = {}}
        function c:Register(id, e) self.Elements[id] = e end
        function c:SetAsCurrent() end
        function c:SetAutoLoad(v) self.AutoLoad = v end
        function c:Load() return __windLoadConfig(__windConfigManager, self) end
        return c
    end
    local bridge, win, ok, err = newBridge('ColorConfigRoundTrip', fileEnv()); assert(ok, err)
    local red, blue = Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255)
    local calls, business = 0, nil
    local tab = win:AddTab({Title = 'Contract'})
    local color = tab:AddColorpicker('config_color', {Default = red, Callback = function(v) calls += 1; business = v end})
    tab:AddToggle('color_config_toggle', {Default = true})
    button(bridge, '创建 / 选定配置').Callback(); __windDrain()
    assert(bridge.Config.Elements.config_color == color.Native, 'config must register the native color control')
    local saved = __windConfigManager.Parser.Colorpicker.Save(color.Native)
    assert(saved.__type == 'Colorpicker' and saved.value == red:ToHex(), 'real vendor Save writes six-digit hex')
    color:SetValue(blue); __windDrain(); local before = calls
    __windConfigData = {__version = 1.2, __elements = {config_color = saved}}
    button(bridge, '加载配置').Callback(); __windDrain()
    assert(calls == before + 1 and color.Value:ToHex() == saved.value and business:ToHex() == saved.value and color.Native.Default:ToHex() == saved.value, 'color config restores business callback, option and native swatch')
    local current, asyncBefore = calls, #__windAsyncErrors
    __windConfigData.__elements = {config_color = {__type = 'Colorpicker', value = 'not-hex'}, color_config_toggle = {__type = 'Toggle', value = false}}
    button(bridge, '加载配置').Callback(); __windDrain()
    assert(calls == current and business:ToHex() == saved.value and #__windAsyncErrors == asyncBefore and not bridge.Options.color_config_toggle.Value, 'bad color preserves prior state while valid entries load')
    assert((bridge.LastError or ''):find('six-digit color hex', 1, true), 'bad hex must surface a useful diagnostic')
    local parser = __windConfigManager.Parser.Colorpicker
    bridge:Destroy(); parser.Load(color.Native, {__type = 'Colorpicker', value = '0000ff'}); __windDrain()
    assert(calls == current and business:ToHex() == saved.value, 'late color config load after unload is ignored')
    __windConfigManager = nil
end)

check("settings AllConfigs failure leaves a usable window", function()
    __windConfigManager = {AllConfigs = function() error("fixture AllConfigs initialization failure") end}
    local bridge, win, ok, err = newBridge("AllConfigsFailure", fileEnv())
    assert(ok, err)
    assert(bridge.Active and win and bridge.SettingsTabs["配置"], "window must survive manager listing failure")
    __windConfigManager = nil
end)
check("slider rejects busy native writes", function()
    __windConfigManager = nil
    local bridge, win, ok, err = newBridge("BusySlider")
    assert(ok, err)
    local calls = 0
    local slider = win:AddTab({Title = "Contract"}):AddSlider("busy_slider", {Min = 0, Max = 1, Default = 0.5, Rounding = 2, Callback = function() calls += 1 end})
    local beforeCalls, beforeValue = calls, slider.Value
    slider.Native:SetBusy(true)
    slider:SetValue(0.8)
    assert(slider.Value == beforeValue and calls == beforeCalls, "rejected busy Set must not publish")
end)
check("slider rejects focusing native writes", function()
    local bridge, win, ok, err = newBridge("FocusedSlider")
    assert(ok, err)
    local calls = 0
    local slider = win:AddTab({Title = "Contract"}):AddSlider("focused_slider", {Min = 0, Max = 1, Default = 0.5, Rounding = 2, Callback = function() calls += 1 end})
    local beforeCalls, beforeValue = calls, slider.Value
    slider.Native:SetFocused(true)
    slider:SetValue(0.8)
    assert(slider.Value == beforeValue and calls == beforeCalls, "rejected focus Set must not publish")
end)
check("slider clamps after vendor CalculateValue", function()
    local bridge, win, ok, err = newBridge("SliderClamp")
    assert(ok, err)
    local tab = win:AddTab({Title = "Contract"})
    local coarse = tab:AddSlider("coarse_slider", {Min = 0, Max = 1.8, Default = 0, Rounding = 0})
    coarse:SetValue(1.8)
    assert(coarse.Value <= 1.8 and coarse.Native.Value.Default <= 1.8, "max 1.8 step 1 must not publish native 2")
    local fine = tab:AddSlider("fine_slider", {Min = 0, Max = 0.997, Default = 0, Rounding = 2})
    fine:SetValue(0.997)
    assert(fine.Value <= 0.997 and fine.Native.Value.Default <= 0.997, "max .997 step .01 must not publish native 1")
end)
check("vendor aq suppresses duplicate callbacks", function()
    local bridge, win, ok, err = newBridge("AqDedup")
    assert(ok, err)
    local calls = 0
    local slider = win:AddTab({Title = "Contract"}):AddSlider("aq_slider", {Min = 0, Max = 1, Default = 0.5, Rounding = 2, Callback = function() calls += 1 end})
    local before = calls
    slider.Native:VendorSet(0.5)
    slider.Native:VendorSet(0.5)
    assert(calls == before, "vendor aq must suppress same-value callbacks")
end)
check("synchronous callback reentry preserves latest value", function()
    local bridge, win, ok, err = newBridge("ReentrantSlider")
    assert(ok, err)
    local events, inOuter, reentered = {}, false, false
    local slider
    slider = win:AddTab({Title = "Contract"}):AddSlider("reentrant_slider", {Min = 0, Max = 1, Default = 0, Rounding = 2, Callback = function(value)
        table.insert(events, value)
        if inOuter and not reentered then
            reentered = true
            slider:SetValue(0.7)
        end
    end})
    inOuter = true
    slider:SetValue(0.3)
    inOuter = false
    assert(reentered and #events >= 3, "native callback must run synchronously and allow reentry")
    assert(slider.Value == 0.7 and slider.Native.Value.Default == 0.7, "outer Set must not overwrite a reentrant latest value")
end)
check("config child failures stay contained", function()
    __windAsyncErrors = {}
    __windConfigManager = {Parser = __windParserTable()}
    __windConfigData = {__version = 1.2, __elements = {config_slider = {__type = 'Slider', value = 'bad'}, config_business = {__type = 'Toggle', value = false}}}
    function __windConfigManager:AllConfigs() return {"default"} end
    function __windConfigManager:CreateConfig(name, autoload)
        local c = {Elements = {}}
        function c:Register(id, element) self.Elements[id] = element end
        function c:SetAsCurrent() end
        function c:SetAutoLoad(value) self.AutoLoad = value end
        function c:Save() error("fixture config child Save failure") end
        function c:Delete() error("fixture config child Delete failure") end
        function c:Load() return __windLoadConfig(__windConfigManager, self) end
        return c
    end
    local bridge, win, ok, err = newBridge("ConfigChildFailure", fileEnv())
    assert(ok, err)
    local tab = win:AddTab({Title = 'Contract'})
    tab:AddToggle('config_business', {Default = true})
    tab:AddSlider('config_slider', {Min = 0, Max = 1, Default = 0.5, Rounding = 2})
    button(bridge, "创建 / 选定配置").Callback(); __windDrain()
    button(bridge, "保存配置").Callback(); __windDrain()
    assert(string.find(bridge.LastError or "", "fixture config child Save failure", 1, true), "Save child error must be surfaced")
    local before = #__windAsyncErrors
    button(bridge, "加载配置").Callback(); __windDrain()
    assert(#__windAsyncErrors == before, 'invalid slider task error must be contained')
    assert(string.find(bridge.LastError or '', 'finite slider value', 1, true), 'invalid config is reported')
    assert(bridge.Options.config_slider.Value == 0.5 and bridge.Options.config_business.Value == false, 'bad entry preserves value while valid entries load')
    __windConfigManager = nil
end)
check("latest pending writes survive shared busy and coalesce releases", function()
    local bridge, win, ok, err = newBridge("SharedBusy"); assert(ok, err); __windDrain()
    local tab = win:AddTab({Title = 'Contract'})
    local a = tab:AddSlider('pending_a', {Min = 0, Max = 1, Default = 0.5, Rounding = 2})
    local b = tab:AddSlider('pending_b', {Min = 0, Max = 1, Default = 0.5, Rounding = 2})
    local writes = 0
    for _, option in ipairs({a, b}) do
        local setter = option.Native.Set
        option.Native.Set = function(self, value) writes += 1; return setter(self, value) end
    end
    a.Native:SetBusy(true)
    assert(a:SetValue(0.6) == false and a:SetValue(0.8) == false and b:SetValue(0.9) == false)
    __windRelease(); assert(a.Pending == 0.8 and b.Pending == 0.9)
    local before = writes
    a.Native:SetBusy(false)
    for _ = 1, 30 do inputService.InputEnded:Fire(); inputService.TextBoxFocusReleased:Fire(); inputService.WindowFocusReleased:Fire() end
    assert(#queue == 1, 'release bursts schedule exactly one flush')
    __windDrain()
    assert(writes == before + 2 and a.Value == 0.8 and b.Value == 0.9 and a.Pending == nil and b.Pending == nil)
end)
check("textbox release applies pending focus write", function()
    local bridge, win, ok, err = newBridge('TextboxRelease'); assert(ok, err); __windDrain()
    local s = win:AddTab({Title = 'Contract'}):AddSlider('focus_pending', {Min = 0, Max = 1, Default = 0.5, Rounding = 2})
    s.Native:SetFocused(true); s:SetValue(0.8); s.Native:SetFocused(false)
    s.Native.UIElements.SliderContainer.TextBox.FocusLost:Fire(); __windDrain()
    assert(s.Value == 0.8 and s.Pending == nil)
end)
check("locked native writes never enqueue retries", function()
    local bridge, win, ok, err = newBridge('LockedWrite'); assert(ok, err); __windDrain()
    local s = win:AddTab({Title = 'Contract'}):AddSlider('locked_write', {Min = 0, Max = 1, Default = 0.5, Rounding = 2})
    s.Native:Lock(); assert(s:SetValue(0.8) == false and s.Pending == nil)
    __windRelease(); s.Native:Unlock(); __windRelease()
    assert(s.Value == 0.5 and s.Native.Value.Default == 0.5)
end)
check("destroy cancels queued slider flush", function()
    local bridge, win, ok, err = newBridge('DestroyPending'); assert(ok, err); __windDrain()
    local s = win:AddTab({Title = 'Contract'}):AddSlider('destroy_pending', {Min = 0, Max = 1, Default = 0.5, Rounding = 2})
    s.Native:SetBusy(true); s:SetValue(0.8); s.Native:SetBusy(false)
    inputService.InputEnded:Fire(); bridge:Destroy(); __windDrain()
    assert(s.Native.Value.Default == 0.5 and not bridge.Active)
end)
check("new native input supersedes deferred programmatic value", function()
    local bridge, win, ok, err = newBridge('NativeSupersedes'); assert(ok, err); __windDrain()
    local s = win:AddTab({Title = 'Contract'}):AddSlider('superseded', {Min = 0, Max = 1, Default = 0.5, Rounding = 2})
    s.Native:SetFocused(true); s:SetValue(0.8); s.Native:SetFocused(false); s.Native:VendorSet(0.6)
    __windRelease(); assert(s.Value == 0.6 and s.Pending == nil and s.Native.Value.Default == 0.6)
end)
check("reentrant listener suppresses stale outer notification", function()
    local bridge, win, ok, err = newBridge('ListenerReentry'); assert(ok, err); __windDrain()
    local s = win:AddTab({Title = 'Contract'}):AddSlider('listener_reentry', {Min = 0, Max = 1, Default = 0.5, Rounding = 2})
    local observed = {}
    s:OnChanged(function(value) if value == 0.3 then s:SetValue(0.7) end end)
    s:OnChanged(function(value) table.insert(observed, value) end); table.clear(observed)
    s:SetValue(0.3)
    assert(#observed == 1 and observed[1] == 0.7 and s.Value == 0.7)
end)
check("constructor failure reclaims owned GUI and creator signals", function()
    __windReset()
    local originalCreate, originalCreator = wind.CreateWindow, wind.Creator
    local originals, allocated, ownedSignals = {}, {}, {}
    for _, key in ipairs({'ScreenGui', 'NotificationGui', 'DropdownGui', 'TooltipGui'}) do
        originals[key] = wind[key]
        local gui = {destroyed = 0}; function gui:Destroy() self.destroyed += 1 end
        wind[key] = gui; allocated[key] = gui
    end
    for i = 1, 4 do
        local c = {Connected = true}; function c:Disconnect() self.Connected = false end
        ownedSignals[i] = c
    end
    local creatorSignals = table.clone(ownedSignals)
    wind.Creator = {Signals = creatorSignals}
    wind.CreateWindow = function() error('fixture constructor filesystem failure') end
    local bridge = createBridge(wind, {Name = 'ConstructorFailure', Env = {}})
    local ok, err = pcall(function() bridge:CreateWindow({}) end)
    __windDrain()
    wind.CreateWindow = originalCreate; wind.Creator = originalCreator
    for key, value in pairs(originals) do wind[key] = value end
    for _, key in ipairs({'NotificationGui', 'DropdownGui', 'TooltipGui'}) do if originals[key] == nil then wind[key] = nil end end
    assert(not ok and string.find(tostring(err), 'fixture constructor filesystem failure', 1, true))
    assert(not bridge.Active and bridge:Window() == nil)
    for key, gui in pairs(allocated) do assert(gui.destroyed == 1, key .. ' leaked before constructor returned') end
    for _, c in ipairs(ownedSignals) do assert(not c.Connected, 'creator signal leaked') end
    assert(next(creatorSignals) == nil, 'creator registry retained disconnected signals')
end)
local function suspendedConstructor(mode)
    __windReset()
    local keys = {'ScreenGui', 'NotificationGui', 'DropdownGui', 'TooltipGui'}
    local originalCreate, originalCreator, originalDestroy = wind.CreateWindow, wind.Creator, native.Destroy
    local originalCallback = native.destroyCallback
    local originals, allocated, ownedSignals = {}, {}, {}
    for _, key in ipairs(keys) do originals[key] = wind[key] end
    local creatorSignals = {}
    wind.Creator = {Signals = creatorSignals}
    local destroyCalls, createCalls, cleanupCalls = 0, 0, 0
    native.destroyCallback = nil
    native.Destroy = function(self)
        destroyCalls += 1
        for _, gui in pairs(allocated) do gui:Destroy() end
        for _, c in ipairs(ownedSignals) do c:Disconnect() end
        table.clear(creatorSignals)
        if wind.Window == self then wind.Window = nil end
        if self.destroyCallback then self.destroyCallback() end
    end
    local function allocate()
        for _, key in ipairs(keys) do
            local gui = {destroyed = 0}
            function gui:Destroy() self.destroyed += 1 end
            wind[key] = gui; allocated[key] = gui
        end
        for i = 1, 4 do
            local c = {Connected = true}
            function c:Disconnect() self.Connected = false end
            ownedSignals[i] = c; creatorSignals[i] = c
        end
    end
    wind.CreateWindow = function(self, info)
        createCalls += 1
        if mode == 'before' then allocate() end
        coroutine.yield('native constructor suspended')
        if mode ~= 'before' then allocate() end
        if mode == 'nil' then return nil end
        local result = originalCreate(self, info)
        if mode == 'error' then error('fixture late native constructor failure') end
        return result
    end
    local env = {}
    local bridge = createBridge(wind, {Name = 'SuspendedNative', Env = env})
    bridge:OnDestroy(function() cleanupCalls += 1 end)
    local baseline = #connections
    local thread = coroutine.create(function() return bridge:CreateWindow({}) end)
    local started, marker = coroutine.resume(thread)
    assert(started and marker == 'native constructor suspended' and coroutine.status(thread) == 'suspended', 'fixture suspension must be reached')
    local pendingWindow = bridge:Window()
    if mode ~= 'healthy' then bridge:Destroy(); bridge:Destroy() end
    local resumed, result = coroutine.resume(thread)
    __windDrain()
    local installed, newConnections = #native.sections, #connections - baseline
    local healthyWindow = bridge:Window()
    local healthyActive = bridge.Active
    if mode == 'healthy' then bridge:Destroy() end
    bridge:Destroy(); bridge:Destroy()
    local lateOk, lateResult = pcall(function() return bridge:CreateWindow({}) end)
    local connected = 0
    for i = baseline + 1, #connections do if connections[i].Connected then connected += 1 end end
    local returnedWindow = bridge:Window()
    local remainingNative = wind.Window
    wind.CreateWindow = originalCreate; wind.Creator = originalCreator; native.Destroy = originalDestroy; native.destroyCallback = originalCallback
    for _, key in ipairs(keys) do wind[key] = originals[key] end
    return {bridge = bridge, env = env, resumed = resumed, result = result, pending = pendingWindow, installed = installed, newConnections = newConnections, connected = connected, window = returnedWindow, remainingNative = remainingNative, allocated = allocated, signals = ownedSignals, creatorSignals = creatorSignals, destroyCalls = destroyCalls, createCalls = createCalls, cleanupCalls = cleanupCalls, lateOk = lateOk, lateResult = lateResult, healthyWindow = healthyWindow, healthyActive = healthyActive}
end
check('suspended native constructor resumes into a healthy complete window', function()
    local state = suspendedConstructor('healthy')
    assert(state.resumed and state.result and state.result == state.healthyWindow and state.healthyActive, 'healthy construction must return its real bridge handle')
    assert(state.pending == nil and state.installed == 3 and state.newConnections > 0, 'fixture must execute complete native adapter setup')
    assert(state.destroyCalls == 1 and state.cleanupCalls == 1 and state.connected == 0, 'healthy cleanup must reclaim native and listeners')
    for key, gui in pairs(state.allocated) do assert(gui.destroyed >= 1, key .. ' healthy GUI leaked') end
    print('FIXTURE HEALTH: suspended real WindAdapter construction completed')
end)
for _, mode in ipairs({'before', 'after', 'error', 'nil'}) do
    check('cleanup reclaims suspended native constructor ' .. mode, function()
        local state = suspendedConstructor(mode)
        if mode == 'error' or mode == 'nil' then
            assert(not state.resumed and state.bridge.LastError, 'constructor failure must preserve diagnostics')
            if mode == 'error' then assert(string.find(tostring(state.result), 'fixture late native constructor failure', 1, true), 'late error must propagate') end
        else
            assert(state.resumed and state.result == nil, 'cancelled native constructor must not return usable UI')
        end
        assert(not state.bridge.Active and state.window == nil and state.remainingNative == nil and state.env.VortexionWindBridge == nil, 'cancelled native window retained or bridge revived')
        assert(state.pending == nil and state.installed == 0 and state.newConnections == 0 and state.connected == 0, 'cancelled constructor installed windows or new connections')
        assert(state.cleanupCalls == 1 and state.destroyCalls == (mode == 'nil' and 0 or 1), 'late native ownership must be reclaimed exactly once')
        for key, gui in pairs(state.allocated) do assert(gui.destroyed >= 1, key .. ' late GUI leaked') end
        for _, c in ipairs(state.signals) do assert(not c.Connected, 'late creator signal leaked') end
        assert(next(state.creatorSignals) == nil, 'late creator registry retained signals')
        assert(state.lateOk and state.lateResult == nil and state.createCalls == 1, 'late CreateWindow revived cancelled bridge')
    end)
end
check('constructor failure preserves pre-existing native GUI ownership', function()
    __windReset()
    local originalCreate, originalWindow, originalGui, originalCreator = wind.CreateWindow, wind.Window, wind.ScreenGui, wind.Creator
    local oldNative, oldGui, oldSignal = {destroyed = 0}, {destroyed = 0}, {Connected = true}
    function oldNative:Destroy() self.destroyed += 1 end
    function oldGui:Destroy() self.destroyed += 1 end
    function oldSignal:Disconnect() self.Connected = false end
    local registry = {oldSignal}
    wind.Window = oldNative; wind.ScreenGui = oldGui; wind.Creator = {Signals = registry}
    wind.CreateWindow = function() error('fixture existing native constructor failure') end
    local bridge = createBridge(wind, {Env = {}})
    local ok, err = pcall(function() bridge:CreateWindow({}) end)
    local preserved = wind.Window == oldNative and wind.ScreenGui == oldGui
    bridge:Destroy()
    wind.CreateWindow = originalCreate; wind.Window = originalWindow; wind.ScreenGui = originalGui; wind.Creator = originalCreator
    assert(not ok and string.find(tostring(err), 'fixture existing native constructor failure', 1, true), 'existing constructor error must propagate')
    assert(not bridge.Active and bridge:Window() == nil and preserved, 'foreign ownership changed')
    assert(oldNative.destroyed == 0 and oldGui.destroyed == 0 and oldSignal.Connected and registry[1] == oldSignal, 'foreign resources reclaimed')
end)
local function suspendedServerSetup(cancel)
    __windReset()
    local originalDestroy = native.Destroy
    local destroys, stops, cleanups = 0, 0, 0
    native.Destroy = function(self) destroys += 1; originalDestroy(self) end
    local env = {}
    local bridge = createBridge(wind, {Env = env, ServerSwitchFactory = function(tab)
        assert(tab.AddButton, "server page received real adapter tab")
        coroutine.yield("server setup suspended")
        return {Stop = function() stops += 1 end}
    end})
    bridge:OnDestroy(function() cleanups += 1 end)
    local baseline = #connections
    local thread = coroutine.create(function() return bridge:CreateWindow({}) end)
    local started, marker = coroutine.resume(thread)
    assert(started and marker == "server setup suspended", "fixture must reach real setup suspension")
    local pending = bridge:Window()
    if cancel then bridge:Destroy(); bridge:Destroy() end
    local resumed, result = coroutine.resume(thread)
    __windDrain()
    local live = 0
    for i = baseline + 1, #connections do if connections[i].Connected then live += 1 end end
    local settings = bridge.SettingsTabs
    local window = bridge:Window()
    bridge:Destroy(); bridge:Destroy()
    local closedWindow = bridge:Window()
    local lateOk, lateResult = pcall(function() return bridge:CreateWindow({}) end)
    native.Destroy = originalDestroy
    return {bridge = bridge, resumed = resumed, result = result, pending = pending, live = live, settings = settings, window = window, closedWindow = closedWindow, lateOk = lateOk, lateResult = lateResult, stops = stops, destroys = destroys, cleanups = cleanups, env = env}
end
check("suspended server page setup completes when active", function()
    local state = suspendedServerSetup(false)
    assert(state.resumed and state.result == state.window and state.settings and state.live > 0, "healthy setup must install full UI")
    assert(state.stops == 1 and state.destroys == 1 and state.cleanups == 1, "healthy setup cleanup owns one switch and window")
    print("FIXTURE HEALTH: server setup suspension resumed into complete UI")
end)
check("closed bridge never returns its cached window handle", function()
    local state = suspendedServerSetup(false)
    assert(state.closedWindow == nil and state.lateOk and state.lateResult == nil, "destroyed bridge retained a reusable cached window")
end)
check("inflight server setup does not expose a partial window", function()
    local state = suspendedServerSetup(false)
    assert(state.pending == nil, "window handle published before settings were installed")
end)
check("cancelled server page setup stops late worker before installing settings", function()
    local state = suspendedServerSetup(true)
    assert(state.resumed and state.result == nil, "cancelled server setup returned a usable window")
    assert(state.window == nil and state.settings == nil and state.live == 0, "cancelled setup installed settings or live listeners")
    assert(state.stops == 1 and state.destroys == 1 and state.cleanups == 1, "late switch must stop once without repeated window destruction")
    assert(not state.bridge.Active and state.env.VortexionWindBridge == nil, "cancelled setup revived bridge ownership")
end)
local function suspendedSettingsSetup(cancel)
    __windConfigManager = {AllConfigs = function()
        coroutine.yield("config listing suspended")
        return {}
    end}
    __windReset()
    local originalDestroy = native.Destroy
    local destroys, stops = 0, 0
    native.Destroy = function(self) destroys += 1; originalDestroy(self) end
    local bridge = createBridge(wind, {Env = fileEnv(), ServerSwitchFactory = function()
        return {Stop = function() stops += 1 end}
    end})
    local function countElements()
        local n = 0
        for _, tab in ipairs(native.allTabs) do n += #tab.elements end
        return n
    end
    local baseline = #connections
    local thread = coroutine.create(function() return bridge:CreateWindow({}) end)
    local started, marker = coroutine.resume(thread)
    assert(started and marker == "config listing suspended", "fixture must pause real settings installation")
    local before = countElements()
    if cancel then bridge:Destroy() end
    local resumed, result = coroutine.resume(thread)
    __windDrain()
    local after, live = countElements(), 0
    for i = baseline + 1, #connections do if connections[i].Connected then live += 1 end end
    local window = bridge:Window()
    bridge:Destroy(); bridge:Destroy()
    native.Destroy = originalDestroy
    __windConfigManager = nil
    native.ConfigManager = nil
    return {bridge = bridge, resumed = resumed, result = result, before = before, after = after, live = live, window = window, stops = stops, destroys = destroys}
end
check("suspended config listing completes when active", function()
    local state = suspendedSettingsSetup(false)
    assert(state.resumed and state.result == state.window and state.after > state.before and state.live > 0, "healthy config setup must complete controls and listeners")
    assert(state.stops == 1 and state.destroys == 1, "healthy settings cleanup must run once")
    print("FIXTURE HEALTH: suspended config listing completed real settings")
end)
check("cancelled config listing never installs late controls or listeners", function()
    local state = suspendedSettingsSetup(true)
    assert(state.resumed and state.result == nil and state.window == nil, "cancelled config listing returned a usable UI")
    assert(state.after == state.before and state.live == 0, "cancelled settings installed late controls or live listeners")
    assert(state.stops == 1 and state.destroys == 1 and not state.bridge.Active, "settings cancellation must retain exact-once cleanup")
end)
local function configFixture(stage, failPrepare)
    local state = {creates = 0, registrations = 0, prepares = 0, publishes = 0, nativePublishes = 0, saves = 0, loads = 0, deletes = 0, lists = 0}
    local paused = false
    local function pause(at)
        if stage == at and not paused then
            paused = true
            coroutine.yield('config action suspended: ' .. at)
        end
    end
    local function fault(at)
        if state.failAt == at then error('fixture config ' .. at .. ' failure') end
    end
    local manager = {Configs = {}}
    function manager:AllConfigs()
        state.lists += 1
        if state.ready then pause('list'); fault('list') end
        return {'default'}
    end
    function manager:CreateConfig(name)
        state.creates += 1
        local c = {Name = name, Elements = {}}
        function c:SetAutoLoad(v)
            state.prepares += 1
            pause('prepare')
            if failPrepare and state.prepares == 1 then error('fixture config preparation failure') end
            self.AutoLoad = v
        end
        function c:Register(id, control)
            state.registrations += 1
            pause('register')
            fault('register')
            self.Elements[id] = control
        end
        function c:SetAsCurrent()
            state.publishes += 1; pause('publish'); fault('publish')
            state.nativePublishes += 1; native.CurrentConfig = self
        end
        function c:Save()
            state.saves += 1; pause('save'); fault('save')
            if state.falseAt == 'save' then return false, 'fixture config save rejected' end
            return {}
        end
        function c:Load()
            state.loads += 1; pause('load'); fault('load')
            if state.falseAt == 'load' then return false, 'fixture config load rejected' end
            return {}
        end
        function c:Delete()
            state.deletes += 1; pause('delete'); fault('delete')
            if state.falseAt == 'delete' then return false, 'fixture config delete rejected' end
            return true
        end
        state.candidate = c
        -- The vendor publishes these native references before CreateConfig returns.
        manager.Configs[name] = c; native.CurrentConfig = c
        state.nativePublishes += 1
        pause('create')
        return c
    end
    __windConfigManager = manager
    local env = fileEnv(); env.delfile = function() return true end
    local bridge, win, ok, err = newBridge('AsyncConfig', env)
    assert(ok and win, err)
    __windDrain()
    state.bridge, state.ready = bridge, true
    for _, e in ipairs(bridge.SettingsTabs['配置'].Native.elements) do
        if e.Title == '原生配置' then state.status = e end
    end
    assert(state.status, 'fixture config status must exist')
    function state:start(title)
        self.thread = coroutine.create(function() button(bridge, title).Callback() end)
        local resumed, marker = coroutine.resume(self.thread)
        assert(resumed and marker == 'config action suspended: ' .. stage, 'fixture must suspend real config callback: ' .. tostring(marker))
    end
    function state:finish()
        local ok, err = coroutine.resume(self.thread)
        assert(ok and coroutine.status(self.thread) == 'dead', err)
        __windDrain()
    end
    function state:close()
        bridge:Destroy(); __windDrain(); __windConfigManager = nil; native.ConfigManager = nil; native.CurrentConfig = nil
    end
    return state
end
check('suspended config creation completes a healthy save', function()
    local s = configFixture('create')
    s:start('保存配置'); s:finish()
    assert(s.creates == 1 and s.registrations > 0 and s.saves == 1 and s.bridge.Config and s.bridge.Config.AutoLoad == false, 'healthy config save must complete')
    assert(s.status.Desc == '配置已保存。', 'healthy save updates status')
    s:close()
    print('FIXTURE HEALTH: suspended config creation completed a save')
end)
for _, phase in ipairs({'create', 'prepare', 'register', 'publish'}) do
    check('closed config action stops after suspended ' .. phase, function()
        local s = configFixture(phase)
        s:start('保存配置')
        s.bridge:Destroy()
        local before = {s.registrations, s.prepares, s.publishes, s.lists, s.status.Desc}
        s:finish()
        assert(s.saves == 0 and s.bridge.Config == nil, 'closed config setup published or saved a late config')
        assert(s.registrations == before[1] and s.prepares == before[2] and s.publishes == before[3] and s.lists == before[4] and s.status.Desc == before[5], 'closed config setup continued native calls or status writes')
        s:close()
    end)
end
check('failed config preparation retries a fresh complete candidate', function()
    local s = configFixture(nil, true)
    button(s.bridge, '创建 / 选定配置').Callback()
    assert(string.find(s.bridge.LastError or '', 'fixture config preparation failure', 1, true), 'preparation failure must be surfaced')
    assert(s.bridge.Config == nil, 'incomplete candidate must not be published')
    button(s.bridge, '创建 / 选定配置').Callback()
    assert(s.creates == 2 and s.bridge.Config and s.bridge.Config.AutoLoad == false, 'retry reused failed config candidate')
    s:close()
end)
check('overlapping config clicks share one inflight file operation', function()
    local s = configFixture('create')
    s:start('保存配置')
    button(s.bridge, '保存配置').Callback()
    assert(s.creates == 1 and s.saves == 0, 'duplicate click entered a second config operation')
    s:finish()
    assert(s.saves == 1, 'one click must produce one save')
    button(s.bridge, '保存配置').Callback()
    assert(s.saves == 2 and s.creates == 1, 'config operation gate did not release after completion')
    s:close()
end)
check('legacy autoload stays blocked during a suspended manual load', function()
    local s = configFixture('load')
    s:start('加载配置')
    assert(s.loads == 1 and s.bridge.Config, 'manual load must reach raw native loader')
    s.bridge.Config:Load()
    assert(s.loads == 1, 'legacy autoload entered the suspended manual load')
    s:finish()
    assert(s.loads == 1 and s.bridge.Active, 'healthy manual load did not settle')
    s:close()
end)
check('late saved config does not refresh or write closed UI status', function()
    local s = configFixture('save')
    s:start('保存配置')
    s.bridge:Destroy()
    local lists, status = s.lists, s.status.Desc
    s:finish()
    assert(s.lists == lists and s.status.Desc == status, 'late save touched closed config UI')
    s:close()
end)
for _, spec in ipairs({{'load', '加载配置'}, {'list', '刷新文件列表'}, {'delete', '删除配置'}}) do
    check('closed config action stops after suspended ' .. spec[1], function()
        local s = configFixture(spec[1])
        s:start(spec[2]); s.bridge:Destroy()
        local lists, status = s.lists, s.status.Desc
        s:finish()
        assert(s.lists == lists and s.status.Desc == status and s.bridge.Config == nil, 'closed file operation updated UI or retained config')
        s:close()
    end)
end
check('suspended config manual load resumes once with healthy UI status', function()
    local s = configFixture('load')
    s:start('加载配置'); s:finish()
    assert(s.loads == 1 and s.status.Desc == '已提交原生加载；控件回调将同步业务状态。', 'healthy explicit load must report submission once')
    s:close()
end)
check('cancelled config creation disables the late legacy loader', function()
    local s = configFixture('create')
    s:start('保存配置'); s.bridge:Destroy(); s:finish()
    assert(s.candidate, 'fixture late candidate must be retained for inspection')
    s.candidate:Load()
    assert(s.loads == 0, 'late candidate retained an active legacy loader')
    s:close()
end)
local function assertAllRegistered(s)
    local c = s.bridge.Config
    assert(c, 'complete bridge config must be published')
    for id, option in pairs(s.bridge.Options) do
        assert(c.Elements[id] == option.Native, 'config registration missing ID: ' .. id)
    end
end
for _, phase in ipairs({'register', 'publish'}) do
    check('failed config ' .. phase .. ' retries with every native option registered', function()
        local s = configFixture(nil)
        s.failAt = phase
        button(s.bridge, '创建 / 选定配置').Callback()
        assert(s.bridge.Config == nil and string.find(s.bridge.LastError or '', 'fixture config ' .. phase .. ' failure', 1, true), 'failed setup published incomplete bridge config or lost error')
        assert(native.CurrentConfig == s.candidate, 'fixture must retain vendor early native publication')
        s.failAt = nil
        button(s.bridge, '创建 / 选定配置').Callback()
        assert(s.creates == 2, 'setup retry must create a fresh candidate')
        assertAllRegistered(s); s:close()
    end)
end
check('failed config rename preserves previous bridge config until successful retry', function()
    local s = configFixture(nil)
    button(s.bridge, '创建 / 选定配置').Callback()
    local prior = s.bridge.Config
    s.bridge.Options.wind_config_name:SetValue('second')
    s.failAt = 'register'
    button(s.bridge, '保存配置').Callback()
    assert(s.bridge.Config == prior and s.saves == 0 and native.CurrentConfig ~= prior, 'failed rename lost prior bridge config, saved stale config, or erased native publication boundary')
    s.failAt = nil
    button(s.bridge, '保存配置').Callback()
    assert(s.creates == 3 and s.saves == 1 and s.bridge.Config.Name == 'second', 'rename retry did not prepare and save a fresh candidate')
    assertAllRegistered(s); s:close()
end)
for _, spec in ipairs({{'save', '保存配置', 'saves', '配置已保存。'}, {'load', '加载配置', 'loads', '已提交原生加载；控件回调将同步业务状态。'}, {'delete', '删除配置', 'deletes', '配置已删除。'}, {'list', '刷新文件列表', 'lists'}}) do
    check('config ' .. spec[1] .. ' exception releases operation gate for retry', function()
        local s = configFixture(nil)
        s.failAt = spec[1]
        button(s.bridge, spec[2]).Callback()
        assert(string.find(s.bridge.LastError or '', 'fixture config ' .. spec[1] .. ' failure', 1, true), 'native operation failure was not surfaced')
        local count = s[spec[3]]
        s.failAt = nil
        button(s.bridge, spec[2]).Callback()
        assert(s[spec[3]] == count + 1 and (not spec[4] or s.status.Desc == spec[4]), 'operation gate or status failed after exception retry')
        s:close()
    end)
end
for _, spec in ipairs({{'save', '保存配置', 'saves', '配置已保存。'}, {'load', '加载配置', 'loads', '已提交原生加载；控件回调将同步业务状态。'}, {'delete', '删除配置', 'deletes', '配置已删除。'}}) do
    check('config ' .. spec[1] .. ' false result surfaces error and permits retry', function()
        local s = configFixture(nil)
        s.falseAt = spec[1]
        button(s.bridge, spec[2]).Callback()
        assert(string.find(s.bridge.LastError or '', 'fixture config ' .. spec[1] .. ' rejected', 1, true) and s.status.Desc ~= spec[4], 'false native result was presented as success')
        s.falseAt = nil
        button(s.bridge, spec[2]).Callback()
        assert(s[spec[3]] == 2 and s.status.Desc == spec[4], 'operation gate failed after false-result retry')
        s:close()
    end)
end
for _, mode in ipairs({'false', 'throw'}) do
    check('cancelled manual load ' .. mode .. ' result does not mutate closed error state', function()
        local s = configFixture('load')
        if mode == 'false' then s.falseAt = 'load' else s.failAt = 'load' end
        s:start('加载配置'); s.bridge:Destroy()
        local err, desc, lists = s.bridge.LastError, s.status.Desc, s.lists
        s:finish()
        assert(s.bridge.LastError == err and s.status.Desc == desc and s.lists == lists, 'late manual load error mutated closed bridge state')
        s:close()
    end)
end
local function dispatchFixture(callback)
    local bridge, win, ok, err = newBridge('DispatchLifecycle')
    assert(ok, err); __windDrain()
    local option = win:AddTab({Title = 'Dispatch'}):AddSlider('dispatch_value', {Min = 0, Max = 1, Default = 0.5, Rounding = 2, Callback = callback})
    return bridge, option
end
check('destroy in primary callback stops listener fanout', function()
    local bridge, option, seen
    seen = 0
    bridge, option = dispatchFixture(function(v) if v == 0.3 then bridge:Destroy() end end)
    option:OnChanged(function() seen += 1 end); seen = 0
    option:SetValue(0.3); __windDrain()
    assert(not bridge.Active and seen == 0, 'closed primary callback continued listener fanout')
end)
check('destroy in first listener stops remaining fanout', function()
    local bridge, option = dispatchFixture()
    local seen = 0
    option:OnChanged(function(v) if v == 0.3 then bridge:Destroy() end end)
    option:OnChanged(function() seen += 1 end); seen = 0
    option:SetValue(0.3); __windDrain()
    assert(seen == 0 and not bridge.Active, 'listener after destroy still ran')
end)
for _, position in ipairs({'primary', 'listener'}) do
    for _, mode in ipairs({'success', 'throw'}) do
        check('cancelled suspended ' .. position .. ' ' .. mode .. ' does not dispatch or overwrite errors', function()
            local function callback(v)
                if v == 0.3 then
                    coroutine.yield('dispatch suspended')
                    if mode == 'throw' then error('fixture late dispatch failure') end
                end
            end
            local bridge, option = dispatchFixture(position == 'primary' and callback or nil)
            if position == 'listener' then option:OnChanged(callback) end
            local seen = 0
            option:OnChanged(function() seen += 1 end); seen = 0
            local thread = coroutine.create(function() option:SetValue(0.3) end)
            local ok, marker = coroutine.resume(thread)
            assert(ok and marker == 'dispatch suspended', 'real callback must suspend')
            bridge:Destroy()
            local previous, notifications = bridge.LastError, #wind.notifications
            local resumed, err = coroutine.resume(thread); __windDrain()
            assert(resumed and coroutine.status(thread) == 'dead', err)
            assert(seen == 0 and bridge.LastError == previous and #wind.notifications == notifications, 'late callback dispatched or changed closed error state')
        end)
    end
end
for _, position in ipairs({'primary', 'listener'}) do
    check('ABA ' .. position .. ' reentry suppresses superseded outer event', function()
        local bridge, option, nested = nil, nil, false
        local function callback(v)
            if v == 0.3 and not nested then
                nested = true; option:SetValue(0.7); option:SetValue(0.3)
            end
        end
        bridge, option = dispatchFixture(position == 'primary' and callback or nil)
        if position == 'listener' then option:OnChanged(callback) end
        local seen = {}
        option:OnChanged(function(v) table.insert(seen, v) end); table.clear(seen)
        option:SetValue(0.3)
        assert(#seen == 2 and seen[1] == 0.7 and seen[2] == 0.3, 'ABA reentry replayed superseded event')
        bridge:Destroy(); __windDrain()
    end)
end
for _, position in ipairs({'primary', 'listener'}) do
    check('listener added during ' .. position .. ' dispatch initializes exactly once', function()
        local bridge, option, seen = nil, nil, 0
        local function callback(v) if v == 0.3 then option:OnChanged(function() seen += 1 end) end end
        bridge, option = dispatchFixture(position == 'primary' and callback or nil)
        if position == 'listener' then option:OnChanged(callback) end
        option:SetValue(0.3)
        assert(seen == 1, 'new listener initialized twice during one dispatch')
        bridge:Destroy(); __windDrain()
    end)
end
check('cleanup releases pending values and listener closures and ignores late registration', function()
    local bridge, option = dispatchFixture()
    option:OnChanged(function() end)
    option.Native:SetBusy(true); option:SetValue(0.8)
    bridge:Destroy(); __windDrain()
    assert(option.Pending == nil and #option.listeners == 0, 'cleanup retained pending value or listener closure')
    local seen = 0
    assert(option:OnChanged(function() seen += 1 end) == option)
    assert(seen == 0 and #option.listeners == 0, 'late registration retained a closed listener')
end)
check('healthy suspended callback continues existing listeners once', function()
    local bridge, option = dispatchFixture(function(v) if v == 0.3 then coroutine.yield('healthy dispatch suspended') end end)
    local seen = 0
    option:OnChanged(function(v) if v == 0.3 then seen += 1 end end)
    local thread = coroutine.create(function() option:SetValue(0.3) end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'healthy dispatch suspended')
    local resumed, err = coroutine.resume(thread)
    assert(resumed and coroutine.status(thread) == 'dead' and seen == 1 and option.Value == 0.3, err)
    bridge:Destroy(); __windDrain()
end)
check('cleanup reset listeners run once and cleanup failures remain diagnostic', function()
    local calls, observed = 0, {}
    local bridge, option = dispatchFixture(function() calls += 1 end)
    option:OnChanged(function(v) table.insert(observed, v) end)
    bridge:OnDestroy(function() option:SetValue(0); error('fixture cleanup diagnostic') end)
    bridge:Destroy(); __windDrain()
    assert(calls == 2 and #observed == 2 and observed[2] == 0 and option.Value == 0, 'intentional cleanup reset lost callbacks or duplicated them')
    assert(string.find(bridge.LastError or '', 'fixture cleanup diagnostic', 1, true), 'cleanup failure diagnostic was suppressed')
end)
check('late failed notification does not overwrite closed error state', function()
    local bridge = dispatchFixture()
    local original = wind.Notify
    wind.Notify = function() coroutine.yield('notification suspended'); error('fixture late notify failure') end
    local thread = coroutine.create(function() bridge:Notify('test', 'test') end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'notification suspended')
    bridge:Destroy(); local previous = bridge.LastError
    local resumed, err = coroutine.resume(thread); wind.Notify = original
    assert(resumed and coroutine.status(thread) == 'dead', err)
    assert(bridge.LastError == previous, 'late notification overwrote closed error state')
    __windDrain()
end)
check('late native setter return never reads destroyed native value', function()
    local bridge, option = dispatchFixture()
    local reads = 0
    option.Native.Set = function(self)
        coroutine.yield('native setter suspended')
        self.Value = setmetatable({}, {__index = function() reads += 1; error('fixture destroyed native value read') end})
    end
    local thread = coroutine.create(function() option:SetValue(0.3) end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'native setter suspended')
    bridge:Destroy()
    local resumed, err = coroutine.resume(thread); __windDrain()
    assert(resumed and coroutine.status(thread) == 'dead' and reads == 0 and option.Value == 0.5, 'late setter read destroyed native value: ' .. tostring(err))
end)
for _, position in ipairs({'primary', 'listener'}) do
    check('cancelled ' .. position .. ' cannot resume fanout during yielded cleanup', function()
        local function callback(v) if v == 0.3 then coroutine.yield('original dispatch suspended') end end
        local bridge, option = dispatchFixture(position == 'primary' and callback or nil)
        if position == 'listener' then option:OnChanged(callback) end
        local seen = 0
        option:OnChanged(function(v) if v == 0.3 then seen += 1 end end)
        bridge:OnDestroy(function() coroutine.yield('cleanup suspended') end)
        local original = coroutine.create(function() option:SetValue(0.3) end)
        local ok, marker = coroutine.resume(original)
        assert(ok and marker == 'original dispatch suspended')
        local destroy = coroutine.create(function() bridge:Destroy() end)
        ok, marker = coroutine.resume(destroy)
        assert(ok and marker == 'cleanup suspended' and bridge.Cleaning and not bridge.Active)
        local resumed, err = coroutine.resume(original)
        local stale = seen
        local finished, finishErr = coroutine.resume(destroy); __windDrain()
        assert(resumed and coroutine.status(original) == 'dead', err)
        assert(finished and coroutine.status(destroy) == 'dead', finishErr)
        assert(stale == 0 and seen == 0, 'global cleaning state admitted a cancelled active dispatch')
    end)
end
check('same-value setter reentry preserves the one genuine listener event', function()
    local bridge, option
    bridge, option = dispatchFixture(function(v) if v == 0.3 then option:SetValue(v) end end)
    local seen = 0
    option:OnChanged(function(v) if v == 0.3 then seen += 1 end end)
    option:SetValue(0.3)
    assert(seen == 1 and option.Value == 0.3, 'idempotent reentry suppressed or duplicated the genuine event')
    bridge:Destroy(); __windDrain()
end)
check('repeated ABA callback bursts preserve latest values without duplicate fanout', function()
    local bridge, option, nested = nil, nil, false
    bridge, option = dispatchFixture(function(v)
        if v == 0.3 and not nested then nested = true; option:SetValue(0.7); option:SetValue(0.3) end
    end)
    local seen = {}
    option:OnChanged(function(v) table.insert(seen, v) end)
    for _ = 1, 200 do
        option:SetValue(0.5); table.clear(seen); nested = false
        option:SetValue(0.3)
        assert(#seen == 2 and seen[1] == 0.7 and seen[2] == 0.3 and option.Value == 0.3, 'ABA burst lost latest value or replayed outer event')
    end
    bridge:Destroy(); __windDrain()
end)
check('active callback failure stays diagnostic and permits remaining listeners', function()
    local bridge, option = dispatchFixture(function(v) if v == 0.3 then error('fixture active dispatch failure') end end)
    local seen = 0
    option:OnChanged(function(v) if v == 0.3 then seen += 1 end end)
    option:SetValue(0.3)
    assert(seen == 1 and bridge.Active and string.find(bridge.LastError or '', 'fixture active dispatch failure', 1, true) and #wind.notifications > 0, 'healthy error reporting or remaining listeners regressed')
    bridge:Destroy(); __windDrain()
end)
local function drainLayout()
    __windDrain()
    assert(#__windAsyncErrors == 0, "layout deferred task failed: " .. table.concat(__windAsyncErrors, "; "))
end
local function layoutFixture()
    __windAsyncErrors = {}
    local camera = {ViewportSize = {X = 420, Y = 800}, GetPropertyChangedSignal = function() return signal() end}
    workspace.CurrentCamera = camera
    local bridge, win, ok, err = newBridge('LayoutLifecycle')
    assert(ok and win, err); drainLayout()
    return bridge, bridge.Options.wind_scale, camera
end
for _, mode in ipairs({'destroy', 'manual', 'fullscreen'}) do
    check('layout listener ' .. mode .. ' cancels remaining automatic center', function()
        local bridge, scale, camera = layoutFixture()
        local armed = false
        scale:OnChanged(function()
            if not armed then return end
            if mode == 'destroy' then bridge:Destroy()
            elseif mode == 'manual' then bridge.Options.wind_auto_fit:SetValue(false)
            else native.IsFullscreen = true end
        end)
        local centers = native.centerWrites
        camera.ViewportSize = {X = 800, Y = 600}; armed = true
        bridge:FitViewport()
        assert(native.centerWrites == centers, 'cancelled layout still centered native window')
        bridge:Destroy(); drainLayout()
    end)
end
for _, mode in ipairs({'destroy', 'manual', 'fullscreen'}) do
    check('suspended scale ' .. mode .. ' cancels remaining automatic center', function()
        local bridge, scale, camera = layoutFixture()
        local original = native.SetUIScale
        native.SetUIScale = function(self, value) coroutine.yield('layout scale suspended'); return original(self, value) end
        camera.ViewportSize = {X = 800, Y = 600}
        local thread = coroutine.create(function() bridge:FitViewport() end)
        local ok, marker = coroutine.resume(thread)
        assert(ok and marker == 'layout scale suspended')
        if mode == 'destroy' then bridge:Destroy()
        elseif mode == 'manual' then bridge.Options.wind_auto_fit:SetValue(false)
        else native.IsFullscreen = true end
        local centers = native.centerWrites
        local resumed, err = coroutine.resume(thread); native.SetUIScale = original
        assert(resumed and coroutine.status(thread) == 'dead', err)
        assert(native.centerWrites == centers, 'suspended cancelled layout still centered')
        bridge:Destroy(); drainLayout()
    end)
end
check('healthy suspended scale completes one center and caches layout', function()
    local bridge, scale, camera = layoutFixture()
    local original = native.SetUIScale
    native.SetUIScale = function(self, value) coroutine.yield('healthy layout scale suspended'); return original(self, value) end
    camera.ViewportSize = {X = 800, Y = 600}
    local centers = native.centerWrites
    local thread = coroutine.create(function() bridge:FitViewport() end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'healthy layout scale suspended')
    local resumed, err = coroutine.resume(thread); native.SetUIScale = original
    assert(resumed and coroutine.status(thread) == 'dead' and native.centerWrites == centers + 1 and native.scale == 1, err)
    bridge:FitViewport(); drainLayout()
    assert(native.centerWrites == centers + 1, 'healthy completed layout not cached')
    bridge:Destroy(); drainLayout()
end)
check('nested same-geometry fit supersedes outer center', function()
    local bridge, scale, camera = layoutFixture()
    local armed = false
    scale:OnChanged(function() if armed then armed = false; bridge:FitViewport() end end)
    camera.ViewportSize = {X = 800, Y = 600}; armed = true
    local centers = native.centerWrites
    bridge:FitViewport(); drainLayout()
    assert(native.centerWrites == centers + 1, 'outer layout replayed center after nested fit')
    bridge:FitViewport(); assert(native.centerWrites == centers + 1)
    bridge:Destroy(); drainLayout()
end)
for _, mode in ipairs({'viewport', 'camera', 'size'}) do
    check('layout ' .. mode .. ' changes requeue before old center', function()
        local bridge, scale, camera = layoutFixture()
        local armed = false
        scale:OnChanged(function()
            if not armed then return end
            armed = false
            if mode == 'viewport' then camera.ViewportSize = {X = 500, Y = 700}
            elseif mode == 'camera' then workspace.CurrentCamera = {ViewportSize = {X = 500, Y = 700}, GetPropertyChangedSignal = function() return signal() end}
            else native.Size = UDim2.fromOffset(1000, 700) end
        end)
        camera.ViewportSize = {X = 800, Y = 600}; armed = true
        local centers = native.centerWrites
        bridge:FitViewport()
        assert(native.centerWrites == centers, 'stale geometry centered before replacement fit')
        drainLayout()
        local expected = mode == 'size' and 0.76 or 0.65
        assert(native.centerWrites == centers + 1 and native.scale == expected, 'new geometry fit was not queued exactly once')
        bridge:FitViewport(); assert(native.centerWrites == centers + 1, 'replacement layout not cached')
        bridge:Destroy(); drainLayout()
    end)
end
check('failed center does not cache an incomplete layout', function()
    local bridge, scale, camera = layoutFixture()
    local original = native.SetToTheCenter
    native.SetToTheCenter = function() error('fixture layout center failure') end
    camera.ViewportSize = {X = 800, Y = 600}
    local centers = native.centerWrites
    local ok, err = pcall(function() bridge:FitViewport() end)
    native.SetToTheCenter = original
    assert(not ok and string.find(tostring(err), 'fixture layout center failure', 1, true))
    bridge:FitViewport()
    assert(native.centerWrites == centers + 1, 'failed center prematurely cached layout and blocked retry')
    bridge:Destroy(); drainLayout()
end)
check('healthy suspended center commits cache only after completion', function()
    local bridge, scale, camera = layoutFixture()
    local original = native.SetToTheCenter
    native.SetToTheCenter = function(self) coroutine.yield('healthy center suspended'); return original(self) end
    camera.ViewportSize = {X = 800, Y = 600}
    local centers = native.centerWrites
    local thread = coroutine.create(function() bridge:FitViewport() end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'healthy center suspended' and native.centerWrites == centers)
    local resumed, err = coroutine.resume(thread); native.SetToTheCenter = original
    assert(resumed and coroutine.status(thread) == 'dead' and native.centerWrites == centers + 1, err)
    bridge:FitViewport(); drainLayout()
    assert(native.centerWrites == centers + 1)
    bridge:Destroy(); drainLayout()
end)
check('geometry changed during center queues one replacement after entered call', function()
    local bridge, scale, camera = layoutFixture()
    local original = native.SetToTheCenter
    native.SetToTheCenter = function(self) coroutine.yield('center geometry suspended'); return original(self) end
    camera.ViewportSize = {X = 800, Y = 600}
    local centers = native.centerWrites
    local thread = coroutine.create(function() bridge:FitViewport() end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'center geometry suspended')
    camera.ViewportSize = {X = 500, Y = 700}
    local resumed, err = coroutine.resume(thread); native.SetToTheCenter = original
    assert(resumed and coroutine.status(thread) == 'dead' and native.centerWrites == centers + 1, err)
    drainLayout()
    assert(native.centerWrites == centers + 2 and native.scale == 0.65, 'geometry change during center was cached or not queued')
    bridge:FitViewport(); assert(native.centerWrites == centers + 2)
    bridge:Destroy(); drainLayout()
end)
check('old suspended center cannot overwrite newer completed layout cache', function()
    local bridge, scale, camera = layoutFixture()
    local original = native.SetToTheCenter
    local paused = false
    native.SetToTheCenter = function(self)
        if not paused then paused = true; coroutine.yield('old center suspended') end
        return original(self)
    end
    camera.ViewportSize = {X = 800, Y = 600}
    local centers = native.centerWrites
    local thread = coroutine.create(function() bridge:FitViewport() end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'old center suspended')
    camera.ViewportSize = {X = 500, Y = 700}; bridge:FitViewport()
    assert(native.scale == 0.65 and native.centerWrites == centers + 1)
    local resumed, err = coroutine.resume(thread); native.SetToTheCenter = original
    assert(resumed and coroutine.status(thread) == 'dead', err)
    bridge:FitViewport(); drainLayout()
    assert(native.centerWrites == centers + 2, 'old center committed stale cache after newer fit')
    bridge:Destroy(); drainLayout()
end)
for _, mode in ipairs({'manual', 'fullscreen'}) do
    check('suspended center ' .. mode .. ' does not commit cancelled cache', function()
        local bridge, scale, camera = layoutFixture()
        local original = native.SetToTheCenter
        native.SetToTheCenter = function(self) coroutine.yield('cancelled center suspended'); return original(self) end
        camera.ViewportSize = {X = 800, Y = 600}
        local centers = native.centerWrites
        local thread = coroutine.create(function() bridge:FitViewport() end)
        local ok, marker = coroutine.resume(thread)
        assert(ok and marker == 'cancelled center suspended')
        if mode == 'manual' then bridge.Options.wind_auto_fit:SetValue(false) else native.IsFullscreen = true end
        local resumed, err = coroutine.resume(thread); native.SetToTheCenter = original
        assert(resumed and coroutine.status(thread) == 'dead' and native.centerWrites == centers + 1, err)
        if mode == 'manual' then bridge.Options.wind_auto_fit:SetValue(true) else native.IsFullscreen = false end
        bridge:FitViewport(); drainLayout()
        assert(native.centerWrites == centers + 2, 'cancelled center prematurely cached geometry')
        bridge:Destroy(); drainLayout()
    end)
end
check('replacement camera prevents stale viewport reads after scale callback', function()
    local bridge, scale, camera = layoutFixture()
    local armed, reads = false, 0
    scale:OnChanged(function()
        if not armed then return end
        armed = false
        workspace.CurrentCamera = {ViewportSize = {X = 500, Y = 700}, GetPropertyChangedSignal = function() return signal() end}
        camera.ViewportSize = nil
        setmetatable(camera, {__index = function(_, key) if key == 'ViewportSize' then reads += 1; error('fixture stale camera viewport read') end end})
    end)
    camera.ViewportSize = {X = 800, Y = 600}; armed = true
    local ok, err = pcall(function() bridge:FitViewport() end); drainLayout()
    assert(ok and reads == 0 and native.scale == 0.65, 'stale camera accessed after replacement: ' .. tostring(err))
    bridge:Destroy(); drainLayout()
end)
check('repeated viewport reentry coalesces one completed fit per rotation', function()
    local bridge, scale, camera = layoutFixture()
    local armed = false
    scale:OnChanged(function() if armed then armed = false; camera.ViewportSize = {X = 500, Y = 700} end end)
    local centers = native.centerWrites
    for round = 1, 100 do
        camera.ViewportSize = {X = 800, Y = 600}; armed = true
        bridge:FitViewport(); drainLayout()
        assert(native.scale == 0.65 and native.centerWrites == centers + round, 'rotation burst repeated stale center')
    end
    bridge:Destroy(); drainLayout()
end)
check('destroyed suspended center makes no late geometry reads or cache updates', function()
    local bridge, scale, camera = layoutFixture()
    local original, size, meta = native.SetToTheCenter, native.Size, getmetatable(native)
    local reads = 0
    native.SetToTheCenter = function(self)
        coroutine.yield('destroyed center suspended')
        local result = original(self)
        self.Size = nil
        setmetatable(self, {__index = function(_, key) if key == 'Size' then reads += 1; error('fixture destroyed center size read') end end})
        return result
    end
    camera.ViewportSize = {X = 800, Y = 600}
    local centers = native.centerWrites
    local thread = coroutine.create(function() bridge:FitViewport() end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'destroyed center suspended')
    bridge:Destroy()
    local resumed, err = coroutine.resume(thread)
    native.SetToTheCenter, native.Size = original, size; setmetatable(native, meta)
    assert(resumed and coroutine.status(thread) == 'dead' and reads == 0 and not bridge.Active, err)
    drainLayout(); bridge:FitViewport()
    assert(native.centerWrites == centers + 1, 'bridge appended a center after cancelled entered center')
end)
local function dropdownFixture()
    __windAsyncErrors = {}
    local bridge, win, ok, err = newBridge('DropdownRefresh')
    assert(ok, err); drainLayout()
    local option = win:AddTab({Title = 'Dropdown'}):AddDropdown('refresh_list', {Values = {'a', 'b'}, Default = 'a'})
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
    drainLayout()
    return bridge, option
end
check('healthy dropdown refresh commits and deduplicates independent snapshots', function()
    local bridge, option = dropdownFixture()
    local requested = {'c', 'd'}
    option:SetValues(requested); drainLayout()
    local count = option.Native.refreshCount
    assert(option.Values[1] == 'c' and option.Native.Values[1] == 'c')
    requested[1] = 'caller mutation'
    assert(option.Values[1] == 'c' and option.Native.Values[1] == 'c', 'caller mutated refresh snapshot')
    option:SetValues({'c', 'd'}); drainLayout()
    assert(option.Native.refreshCount == count, 'unchanged healthy list rebuilt')
    bridge:Destroy(); drainLayout()
end)
check('failed dropdown refresh preserves committed list and permits identical retry', function()
    local bridge, option = dropdownFixture()
    option.Native.BeforeRefresh = function() error('fixture refresh failure') end
    local ok, err = pcall(function() option:SetValues({'c', 'd'}) end)
    assert(not ok and string.find(tostring(err), 'fixture refresh failure', 1, true))
    assert(option.Values[1] == 'a', 'failed refresh published uncommitted list')
    option.Native.BeforeRefresh = nil; option:SetValues({'c', 'd'}); drainLayout()
    assert(option.Native.Values[1] == 'c' and option.Values[1] == 'c', 'identical failed list was suppressed on retry')
    bridge:Destroy(); drainLayout()
end)
check('partial dropdown failure can rebuild unchanged last committed list', function()
    local bridge, option = dropdownFixture()
    option.Native.BeforeRefresh = function(av) option.Native.Values = av; error('fixture partial refresh failure') end
    local ok = pcall(function() option:SetValues({'c'}) end)
    assert(not ok and option.Values[1] == 'a', 'partial native failure leaked into adapter cache')
    local count = option.Native.refreshCount
    option.Native.BeforeRefresh = nil; option:SetValues({'a', 'b'}); drainLayout()
    assert(option.Native.Values[1] == 'a' and option.Native.refreshCount == count + 1, 'dirty committed list did not rebuild')
    bridge:Destroy(); drainLayout()
end)
check('suspended dropdown refresh publishes only after native return', function()
    local bridge, option = dropdownFixture()
    option.Native.BeforeRefresh = function() coroutine.yield('refresh suspended') end
    local values = {'c'}
    local thread = coroutine.create(function() option:SetValues(values) end)
    local ok, marker = coroutine.resume(thread)
    assert(ok and marker == 'refresh suspended' and option.Values[1] == 'a', 'in-flight list published early')
    values[1] = 'mutated'
    local resumed, err = coroutine.resume(thread)
    assert(resumed and coroutine.status(thread) == 'dead', err)
    assert(option.Values[1] == 'c' and option.Native.Values[1] == 'c')
    bridge:Destroy(); drainLayout()
end)
for _, mode in ipairs({'success', 'throw'}) do
    check('destroyed suspended dropdown refresh ' .. mode .. ' keeps cache closed', function()
        local bridge, option = dropdownFixture()
        option.Native.BeforeRefresh = function() coroutine.yield('refresh suspended'); if mode == 'throw' then error('fixture late refresh failure') end end
        local thread = coroutine.create(function() option:SetValues({'c'}) end)
        local ok, marker = coroutine.resume(thread)
        assert(ok and marker == 'refresh suspended')
        bridge:Destroy()
        local resumed, err = coroutine.resume(thread)
        assert(resumed == (mode == 'success'), err)
        if mode == 'throw' then assert(string.find(tostring(err), 'fixture late refresh failure', 1, true)) end
        assert(option.Values[1] == 'a' and not bridge.Active, 'cancelled refresh committed bridge cache')
        drainLayout()
    end)
end
check('nested dropdown refresh coalesces latest request without native overlap', function()
    local bridge, option = dropdownFixture()
    local inside, overlap, fired = false, 0, false
    option.Native.BeforeRefresh = function()
        if inside then overlap += 1 end
        inside = true
        if not fired then fired = true; option:SetValues({'c'}); option:SetValues({'d'}); option:SetValues({'e'}) end
        inside = false
    end
    local count = option.Native.refreshCount
    option:SetValues({'start'}); drainLayout()
    assert(overlap == 0 and option.Native.Values[1] == 'e' and option.Values[1] == 'e', 'nested refresh overlapped or stale native commit won')
    assert(option.Native.refreshCount == count + 2, 'intermediate nested lists were rebuilt')
    bridge:Destroy(); drainLayout()
end)
check('concurrent suspended dropdown requests settle to newest list', function()
    local bridge, option = dropdownFixture()
    local first = true
    option.Native.BeforeRefresh = function() if first then first = false; coroutine.yield('refresh suspended') end end
    local thread = coroutine.create(function() option:SetValues({'c'}) end)
    assert(coroutine.resume(thread))
    option:SetValues({'d'}); option:SetValues({'e'})
    local resumed, err = coroutine.resume(thread)
    assert(resumed and coroutine.status(thread) == 'dead', err); drainLayout()
    assert(option.Values[1] == 'e' and option.Native.Values[1] == 'e', 'old suspended refresh overwrote newest native list')
    bridge:Destroy(); drainLayout()
end)
check('invalid dropdown lists fail before native work and leave gate reusable', function()
    local bridge, option = dropdownFixture()
    local count = option.Native.refreshCount
    local ok, err = pcall(function() option:SetValues('invalid') end)
    assert(not ok and string.find(tostring(err), 'dropdown values must be a table', 1, true))
    assert(option.Native.refreshCount == count and option.Values[1] == 'a')
    option:SetValues({'c'}); drainLayout(); assert(option.Values[1] == 'c')
    bridge:Destroy(); drainLayout()
end)
check('nil dropdown list clears once without inventing a selection event', function()
    local bridge, option = dropdownFixture()
    local seen = 0
    option:OnChanged(function() seen += 1 end)
    option:SetValues(nil); drainLayout()
    local count = option.Native.refreshCount
    option:SetValues({}); drainLayout()
    assert(#option.Values == 0 and #option.Native.Values == 0 and option.Native.refreshCount == count)
    assert(option.Value == 'a' and seen == 1, 'refresh changed legacy selection semantics')
    bridge:Destroy(); drainLayout()
end)
check('rich dropdown cache does not alias caller or native list metadata', function()
    local bridge, option = dropdownFixture()
    local requested = {{Title = 'Rich', Meta = {Version = 1}}}
    option:SetValues(requested); drainLayout()
    requested[1].Meta.Version = 2; option.Native.Values[1].Meta.Version = 3
    assert(option.Values[1].Meta.Version == 1, 'native or caller mutated committed cache')
    bridge:Destroy(); drainLayout()
end)
check('same inflight dropdown request does not schedule a redundant rebuild', function()
    local bridge, option = dropdownFixture()
    option.Native.BeforeRefresh = function(av) option:SetValues(av) end
    local count = option.Native.refreshCount
    option:SetValues({'c'}); drainLayout()
    assert(option.Native.refreshCount == count + 1 and not option.RefreshPending)
    bridge:Destroy(); drainLayout()
end)
check('nested request for previous committed list is not suppressed during refresh', function()
    local bridge, option = dropdownFixture()
    local first = true
    option.Native.BeforeRefresh = function() if first then first = false; option:SetValues({'a', 'b'}) end end
    local count = option.Native.refreshCount
    option:SetValues({'c'}); drainLayout()
    assert(option.Values[1] == 'a' and option.Native.Values[1] == 'a' and option.Native.refreshCount == count + 2)
    bridge:Destroy(); drainLayout()
end)
check('failed refresh clears nested pending work and explicit retry restores latest intent', function()
    local bridge, option = dropdownFixture()
    option.Native.BeforeRefresh = function() option:SetValues({'d'}); error('fixture pending refresh failure') end
    assert(not pcall(function() option:SetValues({'c'}) end))
    assert(not option.RefreshPending and option.Values[1] == 'a')
    option.Native.BeforeRefresh = nil; option:SetValues({'d'}); drainLayout()
    assert(option.Values[1] == 'd' and option.Native.Values[1] == 'd')
    bridge:Destroy(); drainLayout()
end)
local function chainedDropdown(limit)
    local bridge, option = dropdownFixture()
    local count = 0
    option.Native.BeforeRefresh = function()
        count += 1
        if count < limit then option:SetValues({'v' .. tostring(count + 1)}) end
    end
    return bridge, option
end
check('dropdown refresh batches bound synchronous rebuilds and eventually settle', function()
    local bridge, option = chainedDropdown(20)
    local count = option.Native.refreshCount
    assert(option:SetValues({'v1'}) == false)
    assert(option.Native.refreshCount == count + 8 and option.Values[1] == 'v8' and option.RefreshPending[1] == 'v9')
    drainLayout()
    assert(option.Native.refreshCount == count + 20 and option.Values[1] == 'v20' and option.Native.Values[1] == 'v20')
    assert(not option.RefreshPending)
    bridge:Destroy(); drainLayout()
end)
check('one queued dropdown continuation consumes only newest independent snapshot', function()
    local bridge, option = chainedDropdown(20)
    local count = option.Native.refreshCount
    option:SetValues({'v1'}); option.Native.BeforeRefresh = nil
    option:SetValues({'older'})
    local latest = {'newest'}
    option:SetValues(latest); latest[1] = 'caller mutation'
    drainLayout()
    assert(option.Values[1] == 'newest' and option.Native.Values[1] == 'newest' and option.Native.refreshCount == count + 9)
    bridge:Destroy(); drainLayout()
end)
check('destroy clears queued dropdown intent and cancels continuation', function()
    local bridge, option = chainedDropdown(20)
    option:SetValues({'v1'})
    local count = option.Native.refreshCount
    assert(option.RefreshPending)
    bridge:Destroy(); assert(not option.RefreshPending)
    option.Native.BeforeRefresh = function() error('fixture late queued refresh') end
    drainLayout(); option:SetValues({'late'})
    assert(option.Native.refreshCount == count)
end)
check('deferred dropdown failure stays diagnostic and permits explicit retry', function()
    local bridge, option = chainedDropdown(20)
    option:SetValues({'v1'})
    option.Native.BeforeRefresh = function() error('fixture deferred refresh failure') end
    drainLayout()
    assert(string.find(bridge.LastError, 'fixture deferred refresh failure', 1, true) and #__windWind.notifications > 0)
    assert(option.Values[1] == 'v8' and not option.RefreshPending)
    option.Native.BeforeRefresh = nil; option:SetValues({'v9'}); drainLayout()
    assert(option.Values[1] == 'v9' and option.Native.Values[1] == 'v9')
    bridge:Destroy(); drainLayout()
end)
check('vendor dropdown Select still publishes exactly one compatible selection event', function()
    local bridge, option = dropdownFixture()
    local seen = 0
    option:OnChanged(function() seen += 1 end)
    option:SetValues({'a', 'b', 'c'}); option:SetValue('b'); drainLayout()
    assert(option.Value == 'b' and option.Native.Value == 'b' and seen == 2)
    option:SetValues({'c', 'd'}); drainLayout()
    assert(option.Value == 'b' and seen == 2, 'list refresh invented selection callback')
    bridge:Destroy(); drainLayout()
end)
check('five hundred nested dropdown requests coalesce to one final list rebuild', function()
    local bridge, option = dropdownFixture()
    local first = true
    option.Native.BeforeRefresh = function()
        if first then
            first = false
            for i = 1, 500 do option:SetValues({'request' .. tostring(i)}) end
        end
    end
    local count = option.Native.refreshCount
    option:SetValues({'initial'}); drainLayout()
    assert(option.Values[1] == 'request500' and option.Native.Values[1] == 'request500' and option.Native.refreshCount == count + 2)
    bridge:Destroy(); drainLayout()
end)
for _, firstOperation in ipairs({'select', 'list'}) do
    check('suspended dropdown ' .. firstOperation .. ' serializes cross-operation refresh', function()
        local bridge, option = dropdownFixture()
        local entered, overlap, pause = 0, 0, true
        option.Native.BeforeRefresh = function()
            entered += 1; if entered > 1 then overlap += 1 end
            if pause then pause = false; coroutine.yield('cross suspended') end
            entered -= 1
        end
        local thread = coroutine.create(function()
            if firstOperation == 'select' then option:SetValue('b') else option:SetValues({'c', 'd'}) end
        end)
        local ok, marker = coroutine.resume(thread)
        assert(ok and marker == 'cross suspended')
        if firstOperation == 'select' then option:SetValues({'c', 'd'}) else option:SetValue('d') end
        local resumed, err = coroutine.resume(thread)
        assert(resumed and coroutine.status(thread) == 'dead', err); drainLayout()
        assert(overlap == 0, 'selection and list native refresh overlapped')
        assert(option.Native.Values[1] == 'c' and option.Values[1] == 'c', 'cross-operation stale native list commit')
        assert(option.Value == (firstOperation == 'select' and 'b' or 'd') and option.Native.Value == option.Value)
        bridge:Destroy(); drainLayout()
    end)
end
check('visual refresh tier restore drives GetVisualInterval and survives reset', function()
    local function close(a, b) return math.abs(a - b) < 1e-9 end
    local bridge, win, ok, err = newBridge('VisualTier')
    assert(ok, err)
    assert(bridge.VisualHz == 15, 'mobile default tier must be balanced 15Hz, got ' .. tostring(bridge.VisualHz))
    assert(close(bridge:GetVisualInterval(0), 1 / 15), 'balanced tier floors a 0 base at 1/15')
    bridge.Options.wind_perf_tier:SetValue('省电'); drainLayout()
    assert(bridge.VisualHz == 5 and bridge.Options.wind_perf_tier.Value == '省电', 'power-saver tier must publish 5Hz')
    assert(close(bridge:GetVisualInterval(0), 1 / 5) and close(bridge:GetVisualInterval(0.01), 1 / 5), 'power-saver caps aggressive bases at 1/5')
    bridge.Options.wind_perf_tier:SetValue('原速'); drainLayout()
    assert(bridge.VisualHz == 60, 'full-speed tier must publish 60Hz')
    assert(close(bridge:GetVisualInterval(1 / 120), 1 / 60), 'full-speed caps a 120Hz base down to 60Hz')
    assert(close(bridge:GetVisualInterval(1 / 30), 1 / 30), 'full-speed must never accelerate an existing slower cadence')
    bridge.Options.wind_perf_tier:SetValue('自定义'); drainLayout()
    assert(bridge.VisualHz == 15, 'custom tier seeds from the custom slider default (mobile 15)')
    bridge.Options.wind_visual_hz:SetValue(42); drainLayout()
    assert(bridge.VisualHz == 42 and bridge.Options.wind_visual_hz.Value == 42, 'custom slider must retune visual Hz')
    assert(close(bridge:GetVisualInterval(0), 1 / 42), 'custom Hz floors a 0 base at 1/42')
    assert(close(bridge:GetVisualInterval('bad'), 1 / 42), 'non-numeric base sanitizes to 0 then floors at 1/42')
    assert(close(bridge:GetVisualInterval(-3), 1 / 42), 'negative base sanitizes to 0 then floors at 1/42')
    assert(close(bridge:GetVisualInterval(math.huge), 1 / 42), 'infinite base sanitizes to 0 then floors at 1/42')
    bridge:Destroy(); drainLayout()
    local restored = newBridge('VisualTierRestore')
    assert(restored.VisualHz == 15, 'a fresh bridge must restore the mobile default tier')
    restored:Destroy(); drainLayout()
end)
check('GetVisualInterval stays bounded and schedule-free after Destroy', function()
    local function close(a, b) return math.abs(a - b) < 1e-9 end
    local bridge, win, ok, err = newBridge('VisualDestroy')
    assert(ok, err)
    assert(bridge.VisualHz == 15)
    bridge:Destroy(); drainLayout()
    assert(not bridge.Active, 'bridge must be inactive after destroy')
    assert(close(bridge:GetVisualInterval(0), 1 / 15), 'destroyed bridge must still return a bounded interval')
    assert(close(bridge:GetVisualInterval(1 / 120), 1 / 15), 'destroyed bridge still caps at its last VisualHz')
    assert(close(bridge:GetVisualInterval(math.huge), 1 / 15), 'destroyed bridge sanitizes non-finite bases')
    local before = #__windAsyncErrors
    for _ = 1, 50 do bridge:GetVisualInterval(0) end
    drainLayout()
    assert(not bridge.Active and #__windAsyncErrors == before, 'GetVisualInterval must not schedule recovery or resurrect the bridge')
end)
check('safe-area controlled centering: async tail, same-inset rotation, inset-only change, rapid toggle/destroy', function()
    local bridge, scale, camera = layoutFixture()
    local realMain = native.UIElements and native.UIElements.Main
    assert(realMain, 'window main frame present')
    -- Count Position writes through a proxy so teardown can require the write count unchanged, not merely that Cancel ran.
    local writes = 0
    local main = setmetatable({}, {
        __index = function(_, k) return realMain[k] end,
        __newindex = function(_, k, v) if k == 'Position' then writes += 1 end; realMain[k] = v end,
    })
    native.UIElements.Main = main

    -- Fixture has no Roblox TweenService / easing Enum / TweenInfo; provide controlled fakes and restore afterwards.
    -- Create uses an explicit (main, info, goal) signature: the colon already supplies self, so the three production
    -- args (main, TweenInfo, {Position=goal}) map straight onto main/info/goal. Play queues a controlled async tail
    -- (like a real Tween) that applies the goal unless Cancel invalidated it first.
    local realGetService = game.GetService
    local realTweenInfo, realEnum = TweenInfo, Enum
    local plays, cancels = 0, 0
    local fakeTweenService = {}
    function fakeTweenService:Create(main, info, goal)
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
    TweenInfo = {new = function() return {} end}
    Enum = {KeyCode = realEnum.KeyCode, EasingStyle = {Quint = 'Quint'}, EasingDirection = {Out = 'Out'}}
    -- Real userdata Vector2 probe: newproxy(true) yields a genuine userdata (type == "userdata") with a metatable, so
    -- the fixture asserts the adapter never assumes type(Vector2)=="table". Only .X/.Y resolve; any other property errors.
    local function vec2(x, y)
        local proxy = newproxy(true)
        local mt = getmetatable(proxy)
        mt.__index = function(_, k)
            if k == 'X' then return x elseif k == 'Y' then return y end
            error('Vector2 has no property ' .. tostring(k))
        end
        return proxy
    end
    assert(type(vec2(1, 2)) == 'userdata', 'Vector2 probe must be real userdata, not a table stand-in')
    -- GuiService:GetGuiInset() returns topLeft then bottomRight (Vector2, pixels). topLeft.X=left, topLeft.Y=top,
    -- bottomRight.X=right, bottomRight.Y=bottom. The adapter reads them via pcall without any table type check.
    local function setInset(top, bottom, left, right)
        game.GetService = function(self, name)
            if name == 'GuiService' then
                return {GetGuiInset = function() return vec2(left or 0, top or 0), vec2(right or 0, bottom or 0) end}
            end
            if name == 'TweenService' then return fakeTweenService end
            return realGetService(self, name)
        end
    end

    -- 1) Async tail: safe area drives one controlled tween, landing Main at (top-bottom)/2=20 and (left-right)/2=30.
    setInset(40, 0, 60, 0)
    local p0 = plays
    bridge.Options.wind_safe_area:SetValue(true); drainLayout()
    assert(bridge.SafeArea == true, 'safe-area toggle must publish its flag')
    assert(plays == p0 + 1, 'safe area must center through exactly one controlled tween, plays=' .. plays)
    assert(main.Position and main.Position.Y.Offset == 20 and main.Position.X.Offset == 30,
        'controlled center must land Main at Y=(top-bottom)/2=20, X=(left-right)/2=30, got '
        .. tostring(main.Position and main.Position.Y.Offset) .. '/' .. tostring(main.Position and main.Position.X.Offset))

    -- 2) Same-inset rotation: each relayout re-applies the target, so the offset survives portrait<->landscape.
    camera.ViewportSize = {X = 800, Y = 600}; bridge:FitViewport(); drainLayout()
    assert(main.Position.Y.Offset == 20 and main.Position.X.Offset == 30, 'landscape at the same inset keeps the safe-area offset')
    camera.ViewportSize = {X = 420, Y = 800}; bridge:FitViewport(); drainLayout()
    assert(main.Position.Y.Offset == 20 and main.Position.X.Offset == 30, 'portrait at the same inset keeps the safe-area offset')

    -- 3) Inset change re-targets and cancels the prior owned tween.
    local c0 = cancels
    setInset(80, 0, 0, 0)
    camera.ViewportSize = {X = 820, Y = 620}; bridge:FitViewport(); drainLayout()
    assert(main.Position.Y.Offset == 40 and main.Position.X.Offset == 0, 'inset 80 moves the center offset to 40, got ' .. tostring(main.Position.Y.Offset))
    assert(cancels >= c0 + 1, 'a new center tween cancels the previous one')

    -- 3b) Inset-only change that keeps the quantized scale identical still re-centers (offset follows (top-bottom)/2).
    local f0 = scale.Value
    setInset(60, 20, 0, 0)
    bridge:FitViewport(); drainLayout()
    assert(main.Position.Y.Offset == 20 and scale.Value == f0, 'inset-only change re-centers to (top-bottom)/2=20 without changing the quantized scale, got ' .. tostring(main.Position.Y.Offset) .. ' scale=' .. tostring(scale.Value))

    -- 4) Rapid toggle, then Destroy with a PENDING center tween tail: teardown must cancel the queued tail so it never
    --    writes. Require the landing offset AND the Position write count to be identical across the destroy drain.
    bridge.Options.wind_safe_area:SetValue(false); drainLayout()
    bridge.Options.wind_safe_area:SetValue(true); drainLayout()
    local errors = #__windAsyncErrors
    local posStable, writesStable = main.Position and main.Position.Y.Offset, writes
    setInset(80, 0, 0, 0)  -- new target -> new tween + queued tail, NOT drained yet
    bridge:FitViewport()
    assert(writes == writesStable, 'tween path must not write Position directly, writes=' .. writes)
    bridge:Destroy(); drainLayout()
    assert(writes == writesStable, 'pending center tween tail must not write after destroy, writes=' .. writes)
    assert(main.Position and main.Position.Y.Offset == posStable, 'pending tail must not change the landing offset after destroy, got ' .. tostring(main.Position and main.Position.Y.Offset))
    assert(#__windAsyncErrors == errors, 'destroy with a pending tail must not raise async errors')
    assert(not bridge.Active, 'bridge destroyed')

    TweenInfo, Enum, game.GetService = realTweenInfo, realEnum, realGetService
end)
check('safe-area degrade: Create/Play failure cancels owned tail, missing Main defers, tiny viewport safe', function()
    local bridge, scale, camera = layoutFixture()
    local realMain = native.UIElements and native.UIElements.Main
    local realGetService = game.GetService
    local realTweenInfo, realEnum = TweenInfo, Enum
    TweenInfo = {new = function() return {} end}
    Enum = {KeyCode = realEnum.KeyCode, EasingStyle = {Quint = 'Quint'}, EasingDirection = {Out = 'Out'}}
    local plays, cancels = 0, 0
    local fakeTweenService = {}
    function fakeTweenService:Create(main, info, goal)
        local tw = {}
        local cancelled = false
        function tw:Play() plays += 1; task.defer(function() if cancelled then return end; for k, v in pairs(goal) do main[k] = v end end) end
        function tw:Cancel() cancels += 1; cancelled = true end
        return tw
    end
    local function vec2(x, y)
        local proxy = newproxy(true)
        local mt = getmetatable(proxy)
        mt.__index = function(_, k)
            if k == 'X' then return x elseif k == 'Y' then return y end
            error('Vector2 has no property ' .. tostring(k))
        end
        return proxy
    end
    assert(type(vec2(1, 2)) == 'userdata', 'Vector2 probe must be real userdata, not a table stand-in')
    local function setServices(gui, ts)
        game.GetService = function(self, name)
            if name == 'GuiService' then return gui end
            if name == 'TweenService' then return ts end
            return realGetService(self, name)
        end
    end
    -- GetGuiInset returns topLeft then bottomRight; vec2(X, Y) with X=left, Y=top on the first, X=right, Y=bottom on the second.
    local inset40 = {GetGuiInset = function() return vec2(0, 40), vec2(0, 0) end}
    local inset80 = {GetGuiInset = function() return vec2(0, 80), vec2(0, 0) end}

    -- Publish the safe-area flag with default services first (no inset -> native center, no tween).
    bridge.Options.wind_safe_area:SetValue(true); drainLayout()

    -- Owned tween A with a pending async tail (offset 20); do NOT drain so tail A stays queued.
    setServices(inset40, fakeTweenService)
    bridge:FitViewport()
    assert(plays == 1, 'owned tween A created and played')

    -- Create now throws: FitViewport must cancel tail A and direct-set the new offset (40); the queued tail A must not overwrite it.
    setServices(inset80, {Create = function() error('no create') end})
    bridge:FitViewport()
    drainLayout()
    assert(realMain.Position and realMain.Position.Y.Offset == 40, 'Create failure cancels the owned tail and direct-sets the new offset, got ' .. tostring(realMain.Position and realMain.Position.Y.Offset))
    assert(cancels >= 1, 'Create failure cancels the prior owned tween')

    -- Re-establish a pending owned tween B (its queued tail would land offset 20), then make the next Play fail so the
    -- direct set lands offset 40. Both the prior tail B and the failed new tail must stay cancelled so the direct set survives.
    setServices(inset40, fakeTweenService)
    camera.ViewportSize = {X = 825, Y = 625}; bridge:FitViewport()  -- pending B, tail B queued (offset 20), not drained
    assert(plays == 2, 're-established pending tween B played, plays=' .. plays)
    setServices(inset80, {Create = function() return {Play = function() error('no play') end, Cancel = function() cancels += 1 end} end})
    camera.ViewportSize = {X = 835, Y = 635}; bridge:FitViewport(); drainLayout()
    assert(realMain.Position and realMain.Position.Y.Offset == 40, 'Play failure direct-set survives; prior tail B (offset 20) and the failed tail must not overwrite it, got ' .. tostring(realMain.Position and realMain.Position.Y.Offset))

    -- Missing Main: cancel owned tween and defer without caching; no async error, bridge stays active.
    native.UIElements.Main = nil
    setServices(inset80, fakeTweenService)
    camera.ViewportSize = {X = 840, Y = 640}; bridge:FitViewport(); drainLayout()
    assert(bridge.Active, 'missing Main must not tear the bridge down')
    -- Restore Main and re-fit with the SAME geometry: the missing-Main pass must not have cached an unfinished layout, so
    -- this re-plays and commits the landing offset for real.
    native.UIElements.Main = realMain
    local playsBefore = plays
    bridge:FitViewport(); drainLayout()
    assert(plays == playsBefore + 1, 'restored Main with the same geometry must re-play (no unfinished layout cached), plays=' .. plays)
    assert(realMain.Position and realMain.Position.Y.Offset == 40, 'restored Main commits the landing offset, got ' .. tostring(realMain.Position and realMain.Position.Y.Offset))

    -- Extreme small viewport: guarded early return / clamped scale, no async error.
    camera.ViewportSize = {X = 10, Y = 10}; bridge:FitViewport(); drainLayout()
    camera.ViewportSize = {X = 50, Y = 50}; bridge:FitViewport(); drainLayout()
    assert(bridge.Active, 'tiny viewport must stay safe')

    bridge:Destroy(); drainLayout()
    TweenInfo, Enum, game.GetService = realTweenInfo, realEnum, realGetService
end)

    check('owned center tween lifecycle: pending tail cancelled on auto-fit off / safe-area off / fullscreen, same geometry re-runs, stable geometry never cancels', function()
        local bridge, scale, camera = layoutFixture()
        local realMain = native.UIElements and native.UIElements.Main
        assert(realMain, 'window main frame present')
        local writes = 0
        local main = setmetatable({}, {
            __index = function(_, k) return realMain[k] end,
            __newindex = function(_, k, v) if k == 'Position' then writes += 1 end; realMain[k] = v end,
        })
        native.UIElements.Main = main
        local plays, cancels = 0, 0
        local fakeTweenService = {}
        function fakeTweenService:Create(t, info, goal)
            local tw = {}
            local cancelled = false
            tw.Cancel = function() if not cancelled then cancelled = true; cancels += 1 end end
            tw.Play = function()
                plays += 1
                task.defer(function()
                    if cancelled then return end
                    for k, v in pairs(goal) do main[k] = v end
                end)
            end
            return tw
        end
        local realTweenInfo, realEnum, realGetService = TweenInfo, Enum, game.GetService
        local function vec2(x, y)
            local proxy = newproxy(true)
            local mt = getmetatable(proxy)
            mt.__index = function(_, k)
                if k == 'X' then return x elseif k == 'Y' then return y end
                error('Vector2 has no property ' .. tostring(k))
            end
            return proxy
        end
        local function setInset(top, bottom, left, right)
            local gui = {GetGuiInset = function() return vec2(left or 0, top or 0), vec2(right or 0, bottom or 0) end}
            game.GetService = function(_, name)
                if name == "GuiService" then return gui
                elseif name == "TweenService" then return fakeTweenService
                else return realGetService(game, name) end
            end
        end
        TweenInfo = {new = function() return {} end}
        Enum = {KeyCode = realEnum.KeyCode, EasingStyle = {Quint = 'Quint'}, EasingDirection = {Out = 'Out'}}
        -- Force auto-fit on through the real toggle so bridge.AutoFit is guaranteed regardless of Default-callback behavior.
        bridge.Options.wind_auto_fit:SetValue(false); drainLayout()
        bridge.Options.wind_auto_fit:SetValue(true); drainLayout()

        -- A) pending safe-area tail -> auto-fit off cancels the tail with no write; restore re-runs and lands offset 40.
        setInset(40, 0, 0, 0)
        bridge.Options.wind_safe_area:SetValue(true); drainLayout()
        assert(plays == 1 and main.Position.Y.Offset == 20, 'safe-area lands offset 20 first, plays=' .. plays .. ' off=' .. tostring(main.Position and main.Position.Y.Offset))
        setInset(80, 0, 0, 0); bridge:FitViewport()  -- pending tail B (would land 40), not drained
        assert(plays == 2 and writes == 1, 'pending tail B played without a direct write, plays=' .. plays .. ' writes=' .. writes)
        bridge.Options.wind_auto_fit:SetValue(false); drainLayout()
        assert(writes == 1 and main.Position.Y.Offset == 20, 'auto-fit off cancels the pending tail with no write, writes=' .. writes .. ' off=' .. tostring(main.Position.Y.Offset))
        bridge.Options.wind_auto_fit:SetValue(true); drainLayout()
        assert(plays == 3 and main.Position.Y.Offset == 40, 'restoring auto-fit re-runs and lands offset 40, plays=' .. plays .. ' off=' .. tostring(main.Position.Y.Offset))

        -- B) pending safe-area tail -> safe-area off cancels the tail and returns to native centering (no write); restore re-runs.
        setInset(40, 0, 0, 0); bridge:FitViewport()  -- pending tail C (would land 20), not drained
        assert(plays == 4 and writes == 2, 'pending tail C played without a direct write, plays=' .. plays .. ' writes=' .. writes)
        bridge.Options.wind_safe_area:SetValue(false); drainLayout()
        assert(writes == 2 and main.Position.Y.Offset == 40, 'safe-area off cancels the pending tail with no write, writes=' .. writes .. ' off=' .. tostring(main.Position.Y.Offset))
        bridge.Options.wind_safe_area:SetValue(true); drainLayout()
        assert(plays == 5 and main.Position.Y.Offset == 20, 'restoring safe-area re-runs and lands offset 20, plays=' .. plays .. ' off=' .. tostring(main.Position.Y.Offset))

        -- C) pending safe-area tail -> fullscreen early-exit cancels the tail and drops the cache; leaving re-runs.
        setInset(80, 0, 0, 0); bridge:FitViewport()  -- pending tail D (would land 40), not drained
        assert(plays == 6 and writes == 3, 'pending tail D played without a direct write, plays=' .. plays .. ' writes=' .. writes)
        native.IsFullscreen = true; bridge:FitViewport(); drainLayout()
        assert(writes == 3 and main.Position.Y.Offset == 20, 'fullscreen early-exit cancels the pending tail with no write, writes=' .. writes .. ' off=' .. tostring(main.Position.Y.Offset))
        native.IsFullscreen = false; bridge:FitViewport(); drainLayout()
        assert(plays == 7 and main.Position.Y.Offset == 40, 'leaving fullscreen re-runs and lands offset 40, plays=' .. plays .. ' off=' .. tostring(main.Position.Y.Offset))

        -- D) stable repeated geometry never cancels: consecutive identical FitViewport calls keep the completed tween intact.
        local cancelsStable = cancels
        bridge:FitViewport(); bridge:FitViewport(); bridge:FitViewport(); drainLayout()
        assert(cancels == cancelsStable, 'stable repeated geometry must not cancel the owned tween, cancels=' .. cancels)
        assert(main.Position.Y.Offset == 40, 'stable geometry keeps the landed offset, got ' .. tostring(main.Position.Y.Offset))

        bridge:Destroy(); drainLayout()
        assert(not bridge.Active, 'bridge destroyed')
        TweenInfo, Enum, game.GetService = realTweenInfo, realEnum, realGetService
    end)

    -- === TopbarInset safe-area refresh watch (shared UI lifecycle) ===
    local function probeVec2(x, y)
        local proxy = newproxy(true)
        local mt = getmetatable(proxy)
        mt.__index = function(_, k)
            if k == 'X' then return x elseif k == 'Y' then return y end
            error('Vector2 has no property ' .. tostring(k))
        end
        return proxy
    end
    assert(type(probeVec2(1, 2)) == 'userdata', 'Vector2 probe must be real userdata, not a table stand-in')
    -- Each GuiService fixture runs its body under pcall and restores every global it touches, so one failure cannot
    -- cascade into false failures for the contracts that follow.
    local function withGuiFixture(body)
        local realGetService, realEnum, realTweenInfo, realTask = game.GetService, Enum, TweenInfo, task
        local ok, err = pcall(body)
        game.GetService, Enum, TweenInfo, task = realGetService, realEnum, realTweenInfo, realTask
        assert(ok, tostring(err))
    end
    local function makeFakeTween(plays, cancels)
        local svc = {}
        function svc:Create(main, info, goal)
            local tw = {}
            local cancelled = false
            function tw:Play() plays.n += 1; task.defer(function() if cancelled then return end; for k, v in pairs(goal) do main[k] = v end end) end
            function tw:Cancel() cancels.n += 1; cancelled = true end
            return tw
        end
        return svc
    end

    check('topbar inset watch: healthy async connect relocates on the real signal, burst coalesces, disabled flags stay quiet, teardown inert', function()
        withGuiFixture(function()
            TweenInfo = {new = function() return {} end}
            Enum = {KeyCode = Enum.KeyCode, EasingStyle = {Quint = 'Quint'}, EasingDirection = {Out = 'Out'}}
            local plays, cancels = {n = 0}, {n = 0}
            local ts = makeFakeTween(plays, cancels)
            local cur = {top = 0, bottom = 0, left = 0, right = 0}
            local topbarSignal = signal()
            local gui = {
                GetGuiInset = function() return probeVec2(cur.left, cur.top), probeVec2(cur.right, cur.bottom) end,
                GetPropertyChangedSignal = function(_, prop)
                    assert(prop == 'TopbarInset', 'only TopbarInset is watched, got ' .. tostring(prop))
                    return topbarSignal
                end,
            }
            local function setInset(t, b, l, r) cur = {top = t, bottom = b, left = l, right = r} end
            local realGetService = game.GetService
            game.GetService = function(self, name)
                if name == 'GuiService' then return gui
                elseif name == 'TweenService' then return ts
                else return realGetService(self, name) end
            end
            local bridge, win, nbOk, nbErr = newBridge('TopbarWatch')
            assert(nbOk and win, nbErr)
            assert(bridge.GetDiagnostics():find('TopbarInset 监听: 否', 1, true), 'watch not live before the queued install drains')
            drainLayout()
            assert(bridge.GetDiagnostics():find('TopbarInset 监听: 是', 1, true), 'watch live after the queued install drains')
            assert(bridge.Active and native.UIElements.Main and bridge.Options.wind_safe_area, 'full UI present after async connect')
            local main = native.UIElements.Main
            setInset(40, 0, 0, 0)
            bridge.Options.wind_safe_area:SetValue(true); drainLayout()
            assert(main.Position and main.Position.Y.Offset == 20, 'healthy safe-area landing offset 20, got ' .. tostring(main.Position and main.Position.Y.Offset))
            local playsAfterHealthy = plays.n
            setInset(80, 0, 0, 0)
            topbarSignal:Fire(); drainLayout()
            assert(main.Position and main.Position.Y.Offset == 40, 'TopbarInset event re-reads GetGuiInset and relocates to 40, got ' .. tostring(main.Position and main.Position.Y.Offset))
            assert(plays.n == playsAfterHealthy + 1, 'event plays exactly one owned tween, plays=' .. plays.n)
            setInset(40, 0, 0, 0); topbarSignal:Fire()
            setInset(80, 0, 0, 0); topbarSignal:Fire()
            setInset(60, 0, 0, 0); topbarSignal:Fire()
            assert(#queue == 1, 'burst coalesces to one queued layout, queue=' .. #queue)
            drainLayout()
            assert(main.Position and main.Position.Y.Offset == 30, 'burst reads the final inset (60 top -> 30), got ' .. tostring(main.Position and main.Position.Y.Offset))
            assert(plays.n == playsAfterHealthy + 2, 'burst plays exactly one more tween, plays=' .. plays.n)
            bridge.Options.wind_safe_area:SetValue(false); drainLayout()
            assert(#queue == 0, 'queue drained before the disabled safe-area check, queue=' .. #queue)
            topbarSignal:Fire()
            assert(#queue == 0, 'safe-area off: TopbarInset event must not queue a layout, queue=' .. #queue)
            bridge.Options.wind_safe_area:SetValue(true); drainLayout()
            bridge.Options.wind_auto_fit:SetValue(false); drainLayout()
            assert(#queue == 0, 'queue drained before the disabled auto-fit check, queue=' .. #queue)
            topbarSignal:Fire()
            assert(#queue == 0, 'auto-fit off: TopbarInset event must not queue a layout, queue=' .. #queue)
            bridge.Options.wind_auto_fit:SetValue(true); drainLayout()
            bridge:Destroy(); drainLayout()
            local offsetAfterDestroy = main.Position and main.Position.Y.Offset
            for _, l in ipairs(topbarSignal.listeners) do l.fn() end
            drainLayout()
            assert(main.Position and main.Position.Y.Offset == offsetAfterDestroy, 'late callback after destroy must not move the window')
            assert(#queue == 0, 'late callback after destroy must not queue a layout, queue=' .. #queue)
            assert(bridge.GetDiagnostics():find('TopbarInset 监听: 否', 1, true), 'watch cleared after destroy')
        end)
    end)

    check('topbar inset watch: a throwing GetPropertyChangedSignal or Connect never breaks init or explicit Fit', function()
        withGuiFixture(function()
            TweenInfo = {new = function() return {} end}
            Enum = {KeyCode = Enum.KeyCode, EasingStyle = {Quint = 'Quint'}, EasingDirection = {Out = 'Out'}}
            local ts = makeFakeTween({n = 0}, {n = 0})
            local realGetService = game.GetService
            local function explicitFitLands(bridge)
                bridge.Options.wind_safe_area:SetValue(true); drainLayout()
                assert(native.UIElements.Main.Position and native.UIElements.Main.Position.Y.Offset == 20, 'explicit Fit lands offset 20 despite a broken watch, got ' .. tostring(native.UIElements.Main.Position and native.UIElements.Main.Position.Y.Offset))
                assert(bridge.Active, 'a broken watch must not tear down the bridge')
            end
            game.GetService = function(self, name)
                if name == 'GuiService' then return {GetPropertyChangedSignal = function() error('signal boom') end}
                elseif name == 'TweenService' then return ts
                else return realGetService(self, name) end
            end
            local b1, w1, ok1, err1 = newBridge('TopbarThrowSignal')
            assert(ok1 and w1, err1)
            drainLayout()
            assert(b1.Active, 'throwing GetPropertyChangedSignal must not tear down init')
            assert(b1.GetDiagnostics():find('TopbarInset 监听: 否', 1, true), 'no watch when the signal accessor throws')
            game.GetService = function(self, name)
                if name == 'GuiService' then return {GetGuiInset = function() return probeVec2(0, 40), probeVec2(0, 0) end}
                elseif name == 'TweenService' then return ts
                else return realGetService(self, name) end
            end
            explicitFitLands(b1)
            b1:Destroy(); drainLayout()
            game.GetService = function(self, name)
                if name == 'GuiService' then return {GetGuiInset = function() return probeVec2(0, 40), probeVec2(0, 0) end, GetPropertyChangedSignal = function(_, p) assert(p == 'TopbarInset'); return {Connect = function() error('connect boom') end} end}
                elseif name == 'TweenService' then return ts
                else return realGetService(self, name) end
            end
            local b2, w2, ok2, err2 = newBridge('TopbarThrowConnect')
            assert(ok2 and w2, err2)
            drainLayout()
            assert(b2.Active, 'throwing Connect must not tear down init')
            assert(b2.GetDiagnostics():find('TopbarInset 监听: 否', 1, true), 'no watch when Connect throws')
            explicitFitLands(b2)
            b2:Destroy(); drainLayout()
        end)
    end)

    check('topbar inset watch: install fences stop after a teardown raised inside GetService/GetSignal/Connect; late connection disconnects exactly once', function()
        withGuiFixture(function()
            Enum = {KeyCode = Enum.KeyCode}
            local realGetService = game.GetService
            local ts = makeFakeTween({n = 0}, {n = 0})
            local stage, currentBridge, counts
            local function resetCounts() counts = {get = 0, signal = 0, connect = 0, disconnect = 0} end
            local gui = {
                GetGuiInset = function() return probeVec2(0, 0), probeVec2(0, 0) end,
                GetPropertyChangedSignal = function(_, prop)
                    counts.signal += 1
                    assert(prop == 'TopbarInset')
                    if stage == 'signal' then currentBridge:Destroy() end
                    return {
                        Connect = function(fn)
                            counts.connect += 1
                            local c = {Connected = true}
                            function c:Disconnect() counts.disconnect += 1; self.Connected = false end
                            if stage == 'connect' then currentBridge:Destroy() end
                            return c
                        end,
                    }
                end,
            }
            game.GetService = function(self, name)
                if name == 'GuiService' then
                    counts.get += 1
                    if stage == 'get' then currentBridge:Destroy() end
                    return gui
                elseif name == 'TweenService' then return ts
                else return realGetService(self, name) end
            end
            resetCounts(); stage = nil
            local b1, w1, ok1, err1 = newBridge('TopbarFenceEntry')
            assert(ok1 and w1, err1)
            currentBridge = b1
            b1:Destroy()
            drainLayout()
            assert(counts.get == 0 and counts.signal == 0 and counts.connect == 0, 'scheduled install destroyed before drain must not touch any stage, got ' .. counts.get .. '/' .. counts.signal .. '/' .. counts.connect)
            resetCounts(); stage = 'get'
            local b2, w2, ok2, err2 = newBridge('TopbarFenceGet')
            assert(ok2 and w2, err2)
            currentBridge = b2
            drainLayout()
            assert(counts.get == 1, 'GetService reached once, got ' .. counts.get)
            assert(counts.signal == 0 and counts.connect == 0, 'teardown during GetService must not reach GetSignal/Connect, got ' .. counts.signal .. '/' .. counts.connect)
            resetCounts(); stage = 'signal'
            local b3, w3, ok3, err3 = newBridge('TopbarFenceSignal')
            assert(ok3 and w3, err3)
            currentBridge = b3
            drainLayout()
            assert(counts.get == 1 and counts.signal == 1, 'GetService/GetSignal reached once, got ' .. counts.get .. '/' .. counts.signal)
            assert(counts.connect == 0, 'teardown during GetSignal must not reach Connect, got ' .. counts.connect)
            resetCounts(); stage = 'connect'
            local b4, w4, ok4, err4 = newBridge('TopbarFenceConnect')
            assert(ok4 and w4, err4)
            currentBridge = b4
            drainLayout()
            assert(counts.get == 1 and counts.signal == 1 and counts.connect == 1, 'all three stages reached once, got ' .. counts.get .. '/' .. counts.signal .. '/' .. counts.connect)
            assert(counts.disconnect == 1, 'late connection after teardown disconnects exactly once, got ' .. counts.disconnect)
            assert(b4.GetDiagnostics():find('TopbarInset 监听: 否', 1, true), 'late connection is never pooled')
            assert(b4:CreateWindow({}) == nil, 'destroyed bridge publishes no window')
        end)
    end)

    check('topbar inset watch: synchronous-executor install that reentrant-destroys makes CreateWindow return nil and clears the cache', function()
        withGuiFixture(function()
            Enum = {KeyCode = Enum.KeyCode}
            local realGetService, realTask = game.GetService, task
            local counts = {connect = 0, disconnect = 0}
            local gui = {
                GetGuiInset = function() return probeVec2(0, 0), probeVec2(0, 0) end,
                GetPropertyChangedSignal = function(_, prop)
                    assert(prop == 'TopbarInset')
                    return {
                        Connect = function(fn)
                            counts.connect += 1
                            local c = {Connected = true}
                            function c:Disconnect() counts.disconnect += 1; self.Connected = false end
                            -- Synchronous executor: the install runs inline inside CreateWindow; Connect reentrant-tears-down.
                            native:Destroy()
                            return c
                        end,
                    }
                end,
            }
            game.GetService = function(self, name)
                if name == 'GuiService' then return gui
                elseif name == 'TweenService' then return makeFakeTween({n = 0}, {n = 0})
                else return realGetService(self, name) end
            end
            -- Simulate a synchronous-executor task.spawn (a real executor behavior) so the install runs inside CreateWindow.
            task = {defer = realTask.defer, spawn = function(fn) fn() end}
            local bridge, win, ok, err = newBridge('TopbarSyncReentry')
            task = realTask
            assert(ok, 'CreateWindow must not error, got ' .. tostring(err))
            assert(win == nil, 'synchronous reentrant teardown inside the watch install must make CreateWindow return nil, got ' .. tostring(win))
            assert(counts.connect == 1, 'Connect reached once, got ' .. counts.connect)
            assert(counts.disconnect == 1, 'late connection disconnected exactly once, got ' .. counts.disconnect)
            assert(bridge:CreateWindow({}) == nil, 'cache cleared: a follow-up CreateWindow returns nil')
            drainLayout()
            assert(not bridge.Active, 'bridge torn down')
        end)
    end)

    check('topbar inset watch: a real coroutine.yield pause in Connect lets CreateWindow return first; healthy resume relocates, cancel-after-yield disconnects exactly once', function()
        withGuiFixture(function()
            TweenInfo = {new = function() return {} end}
            Enum = {KeyCode = Enum.KeyCode, EasingStyle = {Quint = 'Quint'}, EasingDirection = {Out = 'Out'}}
            local plays, cancels = {n = 0}, {n = 0}
            local ts = makeFakeTween(plays, cancels)
            local realGetService, realTask = game.GetService, task
            local cur = {top = 0, bottom = 0, left = 0, right = 0}
            local topbarSignal = signal()
            local installCo = nil
            local conns = {}
            local function connectedListenerCount()
                local n = 0
                for _, l in ipairs(topbarSignal.listeners) do if l.connection.Connected then n += 1 end end
                return n
            end
            local gui = {
                GetGuiInset = function() return probeVec2(cur.left, cur.top), probeVec2(cur.right, cur.bottom) end,
                GetPropertyChangedSignal = function(_, prop)
                    assert(prop == 'TopbarInset', 'only TopbarInset is watched, got ' .. tostring(prop))
                    return topbarSignal
                end,
            }
            local realConnect = topbarSignal.Connect
            -- Connect really suspends the install coroutine at a yield point; the listener is only registered once the
            -- install actually completes, so a cancelled pause leaves an inert (Active-gated) callback.
            topbarSignal.Connect = function(self, fn)
                installCo = coroutine.running()  -- capture the real install coroutine, not any later task.spawn
                coroutine.yield()
                local realConn = realConnect(self, fn)  -- registers a real listener + real connection into topbarSignal
                -- Wrap the REAL connection: count every Disconnect unconditionally, then truly disconnect the listener.
                -- base signal()'s Disconnect only clears Connected (which Fire honors), so wrapping keeps a real teardown.
                local wrapper = {Disconnects = 0}
                function wrapper:Disconnect() self.Disconnects += 1; realConn:Disconnect() end
                table.insert(conns, wrapper)
                return wrapper
            end
            game.GetService = function(self, name)
                if name == 'GuiService' then return gui
                elseif name == 'TweenService' then return ts
                else return realGetService(self, name) end
            end
            -- task.spawn runs the install in its own coroutine and stops at the yield; CreateWindow proceeds and returns.
            task = {defer = realTask.defer, spawn = function(fn) local co = coroutine.create(fn); local ok, err = coroutine.resume(co); assert(ok, err) end}

            -- Healthy branch: the window is legally returned during the pause; resuming completes a live subscription.
            cur = {top = 40, bottom = 0, left = 0, right = 0}
            local bridge, win, ok, err = newBridge('TopbarYieldHealthy')
            assert(ok and win, err)
            assert(installCo and coroutine.status(installCo) == 'suspended', 'install coroutine paused at the yield, status=' .. tostring(installCo and coroutine.status(installCo)))
            assert(bridge.GetDiagnostics():find('TopbarInset 监听: 否', 1, true), 'watch not live while the install is paused')
            bridge.Options.wind_safe_area:SetValue(true); drainLayout()
            local main = native.UIElements.Main
            assert(main.Position and main.Position.Y.Offset == 20, 'explicit Fit lands offset 20 before the watch resumes, got ' .. tostring(main.Position and main.Position.Y.Offset))
            local rok, rerr = coroutine.resume(installCo)
            assert(rok, rerr)
            assert(coroutine.status(installCo) == 'dead', 'install coroutine finished after healthy resume')
            assert(bridge.GetDiagnostics():find('TopbarInset 监听: 是', 1, true), 'watch live after healthy resume')
            assert(conns[1] and conns[1].Disconnects == 0, 'healthy resume must not disconnect, got ' .. tostring(conns[1] and conns[1].Disconnects))
            local playsBefore = plays.n
            cur = {top = 80, bottom = 0, left = 0, right = 0}
            topbarSignal:Fire(); drainLayout()
            assert(main.Position and main.Position.Y.Offset == 40, 'resumed subscription relocates for real on the TopbarInset event, got ' .. tostring(main.Position and main.Position.Y.Offset))
            assert(plays.n == playsBefore + 1, 'event plays exactly one owned tween, plays=' .. plays.n)
            bridge:Destroy(); drainLayout()
            assert(conns[1] and conns[1].Disconnects == 1, 'healthy Destroy disconnects the real connection exactly once, got ' .. tostring(conns[1] and conns[1].Disconnects))
            assert(connectedListenerCount() == 0, 'no listener stays Connected after healthy Destroy, got ' .. connectedListenerCount())

            -- Cancel branch: pause, Destroy, then resume; the late real connection disconnects exactly once, never pooled, inert.
            cur = {top = 40, bottom = 0, left = 0, right = 0}
            local bridge2, win2, ok2, err2 = newBridge('TopbarYieldCancel')
            assert(ok2 and win2, err2)
            assert(installCo and coroutine.status(installCo) == 'suspended', 'second install coroutine paused at the yield')
            bridge2.Options.wind_safe_area:SetValue(true); drainLayout()
            local main2 = native.UIElements.Main
            assert(main2.Position and main2.Position.Y.Offset == 20, 'explicit Fit lands offset 20 before cancel resume, got ' .. tostring(main2.Position and main2.Position.Y.Offset))
            bridge2:Destroy()
            local rok2, rerr2 = coroutine.resume(installCo)  -- Connect returns the real connection into the fence after teardown
            assert(rok2, rerr2)
            assert(conns[2] and conns[2].Disconnects == 1, 'late connection after pause+destroy disconnects exactly once, got ' .. tostring(conns[2] and conns[2].Disconnects))
            assert(bridge2.GetDiagnostics():find('TopbarInset 监听: 否', 1, true), 'late connection never pooled')
            assert(connectedListenerCount() == 0, 'no listener stays Connected after cancel teardown, got ' .. connectedListenerCount())
            local posBefore = main2.Position and main2.Position.Y.Offset
            for _, l in ipairs(topbarSignal.listeners) do l.fn() end
            drainLayout()
            assert(#queue == 0, 'forced late callback after cancel must not queue a layout, queue=' .. #queue)
            assert(main2.Position and main2.Position.Y.Offset == posBefore, 'forced late callback must not move the window')
            assert(bridge2:CreateWindow({}) == nil, 'destroyed bridge publishes no window')
        end)
    end)

print('WIND_NATIVE_CONTRACTS: passed=' .. passed .. ' failed=' .. #failures .. ' checks=' .. checked)
if #failures > 0 then
    error("WIND_NATIVE_CONTRACTS_RED: " .. #failures .. " contract(s) failed")
end
print("WIND_NATIVE_CONTRACTS_GREEN")
