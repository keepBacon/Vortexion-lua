local ai = false
local function vendorSlider(c)
    local al = {__type = 'Slider', Step = c.Step, Value = {Min = c.Value.Min, Max = c.Value.Max, Default = c.Value.Default}, Callback = c.Callback, Locked = false, IsFocusing = false, UIElements = {SliderIcon = {Frame = {}}, SliderContainer = {TextBox = {Text = tostring(c.Value.Default), FocusLost = signal()}}}}
    local aq, as, at = al.Value.Default, true, al.Step % 1 ~= 0
    local ax, am, an, ao
    local ay = {ScrollingEnabled = true}
    local ae = {SafeCallback = function(fn, ...) local ok, err = pcall(fn, ...); if not ok then error(err) end end}
    local function ag(object, _, props) return {Play = function() for k, v in pairs(props) do object[k] = v end end} end
    __VENDOR_SLIDER__
    function al:SetBusy(v) ai = v end
    function al:SetFocused(v) self.IsFocusing = v end
    function al:Lock() self.Locked = true; as = false end
    function al:Unlock() self.Locked = false; as = true end
    al.VendorSet = al.Set
    return al
end
local basicElement = element
element = function(kind, c) if kind == 'Slider' then return vendorSlider(c) end return basicElement(kind, c) end
UDim2.new = function(xs, xo, ys, yo) return {X = {Scale = xs, Offset = xo}, Y = {Scale = ys, Offset = yo}} end
local inputService = {TouchEnabled = true, InputEnded = signal(), TextBoxFocusReleased = signal(), WindowFocusReleased = signal()}
game.GetService = function(_, name) if name == 'Workspace' then return workspace end return inputService end
__windWind = wind
__windAsyncErrors = {}
function __windDrain()
    local count = 0
    while #queue > 0 do
        count += 1; assert(count < 1000, 'unbounded task retry')
        local ok, err = pcall(table.remove(queue, 1))
        if not ok then table.insert(__windAsyncErrors, tostring(err)) end
    end
end
function __windRelease() inputService.InputEnded:Fire(); __windDrain() end
function __windReset()
    ai = false; table.clear(queue)
    for _, c in ipairs(connections) do c:Disconnect() end
    native.sections = {}; native.allTabs = {}; native.Size = UDim2.fromOffset(700, 500); native.scale = 1; native.ConfigManager = __windConfigManager; native.Debug = false; native.IsFullscreen = false
    wind.Window = nil; wind.notifications = {}
end
function __windParserTable()
    local ae = {Parser = __VENDOR_PARSERS__}
    return ae.Parser
end
function __windLoadConfig(manager, c)
    local ai, ad = c, {}
    local ae = manager
    local ac = {JSONDecode = function() return __windConfigData end}
    local readfile = function() return '{}' end
    local isfile = function() return true end
    __VENDOR_CONFIG_LOAD__
    return ai:Load()
end
