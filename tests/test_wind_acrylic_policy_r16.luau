-- Acrylic preference policy against real vendor Open/Close/ToggleAcrylic assembled with a real factory bridge.
-- The vendor force-sets the blur on Open (Source.lua:38667 av.WindUI:ToggleAcrylic(true)) and off on Close
-- (:38684). This bridge owns a fenced filter so a stored "off" preference survives those forced calls while a
-- manual/side-window/desktop enable still reaches the vendor model and blur counter.
local failures, passed, checked = {}, 0, 0
local function check(name, fn)
    checked += 1
    local ok, err = pcall(fn)
    if ok then
        passed += 1
    else
        table.insert(failures, name .. ": " .. tostring(err))
    end
end

-- Blur counter the real vendor ToggleAcrylic drives (au.Enable/au.Disable). Reassigned per scenario; the vendor
-- closure reads it as an upvalue, so the fresh table is always observed.
local au
local function installBlurCounter()
    -- The real vendor calls au.Enable()/au.Disable() with dot notation (Source.lua:39720/39722), passing no self,
    -- so the counters must close over their own table rather than rely on an implicit self argument.
    local counter = {enabled = false, enableCalls = 0, disableCalls = 0}
    counter.Enable = function() counter.enableCalls += 1; counter.enabled = true end
    counter.Disable = function() counter.disableCalls += 1; counter.enabled = false end
    au = counter
end
installBlurCounter()
local ap = function() return {Play = function() end} end
local an = {SafeCallback = function(fn, ...) return fn(...) end}
local A = {Set = function() end}
local az = {ImageLabel = {}}
local d, u, l = {}, {}, nil
local av = {WindUI = wind}
local aw = native
local aa = wind
wind.TransparencyValue = wind.TransparencyValue or 0.3

-- Enum + task.wait the real vendor Open/Close reference.
local realEasingStyle, realEasingDirection, realTaskWait = Enum.EasingStyle, Enum.EasingDirection, task.wait
Enum.EasingStyle = {Quint = "Quint", Exponential = "Exponential"}
Enum.EasingDirection = {Out = "Out", InOut = "InOut"}
task.wait = function() end

__VENDOR_TOGGLE_ACRYLIC__
__VENDOR_OPEN__
__VENDOR_CLOSE__

local vendorToggleAcrylic = wind.ToggleAcrylic

local function prepareWindow()
    native.Destroyed = false
    native.Closed = true
    native.Transparent = false
    native.CanResize = false
    native.OpenButtonMain = nil
    native.IsOpenButtonEnabled = false
    native.IsPC = false
    native.Size = {X = {Scale = 1, Offset = 650}, Y = {Scale = 1, Offset = 490}}
    native.UIElements.Main.Background = {ImageTransparency = 0}
    native.UIElements.Main.Main = {Visible = true}
    function native.UIElements.Main:WaitForChild(name) return {Visible = false} end
    native.AcrylicPaint = {Model = {Transparency = 1}}
end

local function resetAcrylic()
    wind.ToggleAcrylic = vendorToggleAcrylic
    wind.Window = nil
    wind.acrylic = nil
    __windReset()
    installBlurCounter()
end

local function makeBridge(name)
    local bridge = createBridge(wind, {Name = name or "AcrylicFixture", Theme = "MonokaiPro", Env = {}})
    local win = bridge:CreateWindow({})
    __windDrain()
    assert(bridge.Active, "bridge must stay active after create")
    assert(win, "CreateWindow must return a handle")
    -- Load-bearing: prepareWindow injects the paint by hand, so a production Acrylic=false regression would
    -- otherwise stay hidden. The real allocation switch must remain enabled at construction time.
    assert(wind.windowConfig and wind.windowConfig.Acrylic == true, "initial acrylic allocation must stay enabled")
    return bridge
end

check('acrylic touch preference: real vendor Open force-enable is filtered, blur stays off', function()
    resetAcrylic()
    local bridge = makeBridge('AcrylicTouch')
    prepareWindow()
    assert(wind.Window == native, "bridge window occupies the slot")
    local enable0, disable0 = au.enableCalls, au.disableCalls
    aw:Open()
    __windDrain()
    assert(au.enableCalls == enable0, "touch off-preference must not enable blur on real Open")
    assert(au.disableCalls > disable0, "filtered enable must fall through to disable")
    assert(native.Acrylic == false, "window Acrylic must stay false")
    assert(native.AcrylicPaint.Model.Transparency == 1, "acrylic model must stay transparent")
    bridge:Destroy()
    __windDrain()
end)

check('acrylic desktop preference: real vendor Open enables blur', function()
    resetAcrylic()
    local realGetService = game.GetService
    game.GetService = function(_, name) if name == 'Workspace' then return workspace end return {TouchEnabled = false} end
    local bridge = makeBridge('AcrylicDesktop')
    prepareWindow()
    game.GetService = realGetService
    aw:Open()
    __windDrain()
    assert(native.Acrylic == true, "desktop on-preference must let Open enable")
    assert(native.AcrylicPaint.Model.Transparency == 0.98, "enabled acrylic model transparency")
    assert(au.enableCalls >= 1, "desktop on-preference must enable blur")
    bridge:Destroy()
    __windDrain()
end)

check('acrylic manual toggle routes through the wrapper and flips the model', function()
    resetAcrylic()
    local bridge = makeBridge('AcrylicManual')
    prepareWindow()
    local acrylic = bridge.Options.wind_acrylic
    assert(acrylic, "wind_acrylic option must exist")
    acrylic:SetValue(true)
    __windDrain()
    assert(native.Acrylic == true, "manual enable must reach the vendor model")
    assert(native.AcrylicPaint.Model.Transparency == 0.98, "manual enable transparency")
    assert(au.enableCalls >= 1, "manual enable must enable blur")
    -- Real Close force-disables the vendor model, but must not overwrite the stored "on" preference: the option
    -- value stays true and a following real Open re-enables the blur (preference independent of vendor state).
    aw:Close()
    __windDrain()
    assert(native.Acrylic == false, "real Close force-disables the model")
    assert(native.AcrylicPaint.Model.Transparency == 1, "real Close sets model transparency to 1")
    assert(acrylic.Value == true, "Close vendor state must not pollute the stored on-preference")
    aw:Open()
    __windDrain()
    assert(native.Acrylic == true, "real Open re-enables because the on-preference survived Close")
    assert(native.AcrylicPaint.Model.Transparency == 0.98, "reopened model transparency")
    acrylic:SetValue(false)
    __windDrain()
    assert(native.Acrylic == false, "manual disable must reach the vendor model")
    assert(native.AcrylicPaint.Model.Transparency == 1, "manual disable transparency")
    assert(au.disableCalls >= 1, "manual disable must disable blur")
    bridge:Destroy()
    __windDrain()
end)

check('acrylic real Close force-disable passes through and a reopen stays filtered', function()
    resetAcrylic()
    local bridge = makeBridge('AcrylicClose')
    prepareWindow()
    aw:Open()
    __windDrain()
    assert(au.enableCalls == 0, "touch Open stays filtered")
    assert(native.Acrylic == false, "touch Open stays off")
    local disableAfterOpen = au.disableCalls
    aw:Close()
    __windDrain()
    assert(au.enableCalls == 0, "real Close must never enable blur")
    assert(au.disableCalls > disableAfterOpen, "real Close force-disable reaches the vendor")
    assert(native.Acrylic == false, "Close keeps acrylic off")
    aw:Open()
    __windDrain()
    assert(au.enableCalls == 0, "reopen after Close stays filtered")
    assert(native.Acrylic == false, "reopen after Close stays off")
    bridge:Destroy()
    __windDrain()
end)

check('acrylic repeated real Open never leaks an enable', function()
    resetAcrylic()
    local bridge = makeBridge('AcrylicRepeat')
    prepareWindow()
    -- The build-time emit(ToggleAcrylic(Default=false)) can already burn one disable when paint is present; capture
    -- the baseline after prepareWindow and assert the exact +3 increment rather than an absolute total.
    local disable0 = au.disableCalls
    for _ = 1, 3 do
        aw:Open()
        __windDrain()
    end
    assert(au.enableCalls == 0, "repeated Open must never enable blur under off-preference")
    assert(au.disableCalls == disable0 + 3, "each Open force-enable falls through to disable (exact +3)")
    assert(native.Acrylic == false, "window stays off after repeated Open")
    bridge:Destroy()
    __windDrain()
end)

check('acrylic fence: a side window taking the slot is not gated by this bridge preference', function()
    resetAcrylic()
    local bridge = makeBridge('AcrylicSide')
    prepareWindow()
    assert(wind.Window == native, "bridge owns the slot")
    local side = {AcrylicPaint = {Model = {Transparency = 1}}}
    wind.Window = side
    wind:ToggleAcrylic(true)
    assert(side.Acrylic == true, "side window enable must pass through")
    assert(side.AcrylicPaint.Model.Transparency == 0.98, "side window model enabled")
    assert(au.enableCalls >= 1, "side window enable reaches the blur")
    wind.Window = native
    bridge:Destroy()
    __windDrain()
end)

check('acrylic teardown: external delegate keeps forwarding and cleanup never replaces it', function()
    resetAcrylic()
    local bridge = makeBridge('AcrylicDelegate')
    prepareWindow()
    assert(wind.ToggleAcrylic ~= vendorToggleAcrylic, "bridge must wrap the vendor toggle")
    local previous = wind.ToggleAcrylic
    local delegate
    delegate = function(self, v) return previous(self, v) end
    wind.ToggleAcrylic = delegate
    bridge:Destroy()
    __windDrain()
    assert(wind.ToggleAcrylic == delegate, "cleanup must not replace an external wrapper")
    -- The captured wrapper must still reach the real vendor method after teardown (passthrough retention).
    wind:ToggleAcrylic(true)
    assert(native.Acrylic == true, "external delegate must still reach the vendor model after destroy")
    assert(native.AcrylicPaint.Model.Transparency == 0.98, "delegated enable sets the model")
    assert(au.enableCalls >= 1, "delegated enable still drives the blur")
end)

check('acrylic construction failure after install restores the vendor toggle', function()
    resetAcrylic()
    local bridge = createBridge(wind, {Name = "AcrylicFail", Theme = "MonokaiPro", Env = {}})
    local realEdit = native.EditOpenButton
    native.EditOpenButton = function() error("fixture post-install failure") end
    local ok = pcall(function() return bridge:CreateWindow({}) end)
    native.EditOpenButton = realEdit
    assert(not ok, "post-install failure must surface (CreateWindow re-raises)")
    assert(wind.ToggleAcrylic == vendorToggleAcrylic, "cleanup must restore the vendor toggle after a failed build")
    assert(not bridge.Active, "failed bridge must be inactive")
    __windDrain()
end)

check('acrylic re-install: a future bridge re-wraps and enforces its own preference', function()
    resetAcrylic()
    local first = makeBridge('AcrylicFirst')
    prepareWindow()
    assert(wind.ToggleAcrylic ~= vendorToggleAcrylic, "first bridge wraps")
    first:Destroy()
    __windDrain()
    assert(wind.ToggleAcrylic == vendorToggleAcrylic, "first teardown restores the vendor toggle")
    resetAcrylic()
    local second = makeBridge('AcrylicSecond')
    prepareWindow()
    assert(wind.ToggleAcrylic ~= vendorToggleAcrylic, "second bridge re-wraps the restored vendor toggle")
    aw:Open()
    __windDrain()
    assert(au.enableCalls == 0, "second bridge enforces its own off-preference on real Open")
    assert(native.Acrylic == false, "second bridge keeps acrylic off")
    second:Destroy()
    __windDrain()
end)

print(string.format("WIND_ACRYLIC_POLICY: passed=%d failed=%d checks=%d", passed, #failures, checked))
for _, f in ipairs(failures) do print("  FAIL " .. f) end
-- Restore globals the real vendor Open/Close fixtures touched.
Enum.EasingStyle = realEasingStyle
Enum.EasingDirection = realEasingDirection
task.wait = realTaskWait
wind.ToggleAcrylic = vendorToggleAcrylic
if #failures > 0 then
    error("WIND_ACRYLIC_POLICY_RED", 2)
end
print("WIND_ACRYLIC_POLICY_GREEN")
