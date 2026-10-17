warn = print
local createBridge = __FACTORY__
local queue = {}
local function drain()
    while #queue > 0 do table.remove(queue, 1)() end
end
task = {defer = function(fn) table.insert(queue, fn) end, spawn = function(fn) table.insert(queue, fn) end}
local connections = {}
local function signal()
    local s = {listeners = {}}
    function s:Connect(fn)
        local c = {Connected = true}
        function c:Disconnect() self.Connected = false end
        table.insert(self.listeners, {fn = fn, connection = c})
        table.insert(connections, c)
        return c
    end
    function s:Fire() for _, l in ipairs(self.listeners) do if l.connection.Connected then l.fn() end end end
    return s
end
local viewportSignal, cameraSignal, sizeSignal = signal(), signal(), signal()
local camera = {ViewportSize = {X = 420, Y = 800}, GetPropertyChangedSignal = function() return viewportSignal end}
workspace = {CurrentCamera = camera, GetPropertyChangedSignal = function() return cameraSignal end}
game = {GameId = 12, PlaceId = 34, JobId = "fixture-job", GetService = function(_, name)
    if name == "Workspace" then return workspace end
    return {TouchEnabled = true}
end}
Enum = {KeyCode = {K = "K", RightControl = "RightControl", LeftAlt = "LeftAlt"}}
UDim2 = {fromOffset = function(x, y) return {X = {Offset = x}, Y = {Offset = y}} end}
local native = {sections = {}, allTabs = {}, Debug = false, scale = 1, Size = UDim2.fromOffset(650, 490), UIElements = {Main = {}}, toggles = 0, destroyed = 0}
local function element(kind, c)
    local e = {Step = c.Step, refreshCount = 0, __type = kind, Value = kind == "Slider" and {Default = c.Value.Default} or c.Value, Values = c.Values, Callback = c.Callback, Title = c.Title, Desc = c.Desc, Locked = c.Locked}
    function e:SetTitle(v) self.Title = v end
    function e:SetDesc(v) self.Desc = v end
    function e:Set(v)
        if kind == "Slider" then self.Value.Default = v else self.Value = v end
        if self.Callback then
            if kind == "Input" then self.Callback(v) else task.spawn(function() self.Callback(v) end) end
        end
    end
    function e:Select(v) self.Value = v; if self.Callback then task.spawn(function() self.Callback(self.Value) end) end end
    function e:Refresh(v) self.refreshCount += 1; self.Values = v; if self.Callback then task.spawn(function() self.Callback(self.Value) end) end end
    if kind == "Colorpicker" then
        -- Vendor Colorpicker keeps the current color in Default and never exposes Value; Set/Update are silent.
        e.Value = nil
        e.Default = c.Default
        e.sets, e.updates = 0, 0
        function e:Set(v) self.sets += 1; self.Default = v end
        function e:Update(v) self.updates += 1; self.Default = v end
    end
    if kind == "Input" and c.Callback then c.Callback(c.Value) end
    if kind == "Dropdown" and c.Callback then task.spawn(function() c.Callback(e.Value) end) end
    return e
end
function native:Section(c)
    local s = {Title = c.Title, Opened = c.Opened, tabs = {}}
    function s:Tab(info)
        local t = {Title = info.Title, Index = #native.allTabs + 1, elements = {}}
        function t:Select() native.CurrentTab = self.Index end
        for _, kind in ipairs({"Toggle", "Slider", "Input", "Dropdown", "Paragraph", "Button", "Colorpicker"}) do
            t[kind] = function(self, opts) local e = element(kind, opts); table.insert(self.elements, e); return e end
        end
        table.insert(self.tabs, t); table.insert(native.allTabs, t); return t
    end
    function s:Open() self.Opened = true end
    table.insert(self.sections, s); return s
end
function native:OnDestroy(fn) self.destroyCallback = fn end
function native:Destroy() self.destroyed += 1; self.destroyCallback() end
function native:Toggle() self.toggles += 1 end
function native:Open() self.open = true end
function native:EditOpenButton(c) self.openButton = c end
function native:GetUIScale() return self.scale end
function native:SetUIScale(v) self.scale = v; self.scaleWrites = (self.scaleWrites or 0) + 1 end
function native:SetToTheCenter() self.centered = true; self.centerWrites = (self.centerWrites or 0) + 1 end
function native.UIElements.Main:GetPropertyChangedSignal() return sizeSignal end
function native:SetToggleKey(v) self.ToggleKey = v end
function native:SetSize(v) self.Size = v; sizeSignal:Fire() end
function native:IsResizable(v) self.resizable = v end
function native:ToggleFullscreen() self.IsFullscreen = not self.IsFullscreen end
function native:ToggleTransparency(v) self.transparent = v end
function native:SetBackgroundTransparency(v) self.transparency = v end
function native:SetBackgroundImage(v) self.background = v end
function native:SetBackgroundImageTransparency(v) self.backgroundAlpha = v end
local wind = {ScreenGui = {}, theme = "Dark", notifications = {}, themes = {Dark = {}, Light = {}, MonokaiPro = {}}}
function wind:CreateWindow(c) assert(workspace.CurrentCamera, "native camera precondition"); self.windowConfig = c; native.Size = c.Size; self.Window = native; return native end
function wind:Notify(c) table.insert(self.notifications, c); return c end
function wind:GetThemes() return self.themes end
function wind:SetTheme(v) assert(self.themes[v], "theme must use dictionary key"); self.theme = v; self.Theme = v end
function wind:GetCurrentTheme() return self.theme == "MonokaiPro" and "Monokai Pro" or self.theme end
function wind:ToggleAcrylic(v) self.acrylic = v end
function wind:SetNotificationLower(v) self.notificationLower = v end
-- Colorpicker contract: real Color3 userdata (newproxy) so the adapter's typeof and identity checks behave
-- like Roblox instead of a table stand-in that copy() would flatten.
local colorData = setmetatable({}, {__mode = "k"})
local colorMeta = {}
function colorMeta:__index(key)
    local data = colorData[self]
    if key == "R" then return data[1] end
    if key == "G" then return data[2] end
    if key == "B" then return data[3] end
    if key == "ToHex" then
        return function()
            return string.format("%02x%02x%02x", math.floor(data[1] * 255 + 0.5), math.floor(data[2] * 255 + 0.5), math.floor(data[3] * 255 + 0.5))
        end
    end
    error("Color3 has no property " .. tostring(key))
end
local originalTypeof = typeof
typeof = function(value)
    local kind = type(value)
    if kind == "table" or kind == "userdata" then
        if colorData[value] then return "Color3" end
    end
    return originalTypeof(value)
end
local function equalColor(a, b)
    local x, y = colorData[a], colorData[b]
    return x ~= nil and y ~= nil and x[1] == y[1] and x[2] == y[2] and x[3] == y[3]
end
local function color3(r, g, b)
    local proxy = newproxy(true)
    colorData[proxy] = {r, g, b}
    local meta = getmetatable(proxy)
    meta.__index, meta.__eq = colorMeta.__index, equalColor
    return proxy
end
Color3 = {
    new = color3,
    fromRGB = function(r, g, b) return color3(r / 255, g / 255, b / 255) end,
    fromHex = function(hex)
        assert(type(hex) == "string", "Color3.fromHex requires a string")
        local clean = hex:gsub("^#", "")
        assert(#clean == 6 and clean:match("^%x+$"), "Color3.fromHex requires six hex digits")
        return color3(tonumber(clean:sub(1, 2), 16) / 255, tonumber(clean:sub(3, 4), 16) / 255, tonumber(clean:sub(5, 6), 16) / 255)
    end,
}
local env, stops = {}, 0
local bridge = createBridge(wind, {Name = "Fixture", Theme = "MonokaiPro", Env = env, ServerSwitchFactory = function(tab)
    assert(tab.AddToggle and tab.AddSlider, "server switch receives compatible tab")
    return {Stop = function() stops += 1 end}
end})
local win = bridge:CreateWindow({})
assert(wind.windowConfig.SideBarWidth == 160 and wind.windowConfig.AutoScale == false)
assert(bridge.AutoFit and not wind.acrylic, "mobile blur defaults off without removing its toggle")
assert(native.Size.X.Offset * native.scale <= camera.ViewportSize.X - 40, "initial portrait fits with margins")
assert(native.sections[1].Title == "通用" and native.sections[2].Title == "游戏功能" and native.sections[3].Title == "UI", "native ordered sections")
assert(#native.sections[1].tabs == 1, "one common server switch tab")
assert(#native.sections[3].tabs == 4, "four native settings tabs")
assert(env.VortexionWindBridge == bridge and bridge.GUI == wind.ScreenGui and win.Root == native.UIElements.Main)
assert(native.openButton.Enabled ~= false, "open button stays enabled")
local first = win:AddTab({Title = "First game"})
local second = win:AddTab({Title = "Second game"})
win:SelectTab(2)
assert(native.CurrentTab == second.Native.Index, "game selection does not use global index")
win:Minimize(); assert(native.toggles == 1, "native Toggle handles minimize")
assert(#bridge.Tabs == 2, "settings do not enter game tab registry")
assert(bridge.Options.wind_theme.Value == "MonokaiPro", "theme default uses key, not display name")
assert(string.find(bridge.GetDiagnostics(), "当前页: " .. tostring(second.Native.Index), 1, true), "diagnostics uses native CurrentTab")
print("wind adapter native navigation PASS")
local counts, seen = {}, {}
local function callback(id) return function(v)
    counts[id] = (counts[id] or 0) + 1; seen[id] = v
    assert(bridge.Options[id].Value == v or type(v) == "table", "value visible inside callback")
end end
local toggle = first:AddToggle("test_toggle", {Default = false, Callback = callback("test_toggle")})
local slider = first:AddSlider("test_slider", {Min = 0, Max = 10, Default = 99, Rounding = 1, Callback = callback("test_slider")})
local text = first:AddInput("test_input", {Default = "a", Callback = callback("test_input")})
local dropdown = first:AddDropdown("test_dropdown", {Values = {"a", "b"}, Default = 2, Callback = callback("test_dropdown")})
local multi = first:AddDropdown("test_multi", {Values = {"a", "b"}, Default = {"a"}, Multi = true, Callback = callback("test_multi")})
assert(dropdown.Value == "b" and slider.Value == 10)
drain()
for _, id in ipairs({"test_toggle", "test_slider", "test_input", "test_dropdown", "test_multi"}) do assert(counts[id] == 1, "exactly one initial callback: " .. id) end
toggle:SetValue(true); toggle:SetValue(false)
assert(counts.test_toggle == 3 and seen.test_toggle == false, "SetValue is immediate")
drain(); assert(counts.test_toggle == 3 and toggle.Value == false, "stale native echoes ignored")
slider:SetValue(2.34); assert(slider.Value == 2.3)
text:SetValue("b"); assert(counts.test_input == 2)
dropdown:SetValue("a"); dropdown:SetValues({"a", "b", "c"})
multi:SetValue({"a"}); assert(counts.test_multi == 1, "deep equality suppresses duplicate multi callbacks")
drain(); assert(counts.test_slider == 2 and counts.test_dropdown == 2)
local refreshCount = dropdown.Native.refreshCount
dropdown:SetValues({"a", "b", "c"}); assert(dropdown.Native.refreshCount == refreshCount, "unchanged lists do not rebuild native items")
local precise = first:AddSlider("test_precision", {Min = 0.123, Max = 0.997, Default = 0.5, Rounding = 8})
assert(precise.Native.Step == 0.01, "precision matches the native two-decimal formatter")
precise:SetValue(0 / 0); assert(precise.Value >= 0.123 and precise.Value == precise.Value)
precise:SetValue(math.huge); assert(precise.Value == 0.997)
precise:SetValue(-math.huge); assert(precise.Value == 0.123)
precise:SetValue("bad"); assert(precise.Value == 0.123)
local integral = first:AddSlider("test_integral", {Min = 0.1, Max = 1.8, Default = 0, Rounding = 0 / 0})
assert(integral.Value == 0.1 and integral.Native.Step == 1, "rounding preserves fractional bounds and handles NaN precision")
assert(not pcall(function() first:AddSlider("invalid_range", {Min = 10, Max = 1}) end) and bridge.Options.invalid_range == nil)
drain()
text.Native:Set("config-loaded"); assert(text.Value == "config-loaded" and counts.test_input == 3, "native config Set reaches business callback")
local observed = 0
toggle:OnChanged(function() observed += 1 end); toggle:SetValue(true); drain(); assert(observed == 2)
local paragraph = first:AddParagraph({Title = "old", Content = "description"})
paragraph:SetTitle("new"); paragraph:SetDesc("updated"); assert(paragraph.Title == "new" and paragraph.Desc == "updated")
assert(bridge.Options.wind_theme, "dynamic native theme selector is installed")
assert(#bridge.Options.wind_theme.Values == 3 and bridge.Options.wind_theme.Values[1] == "Dark", "themes use sorted dictionary keys")
wind.themes.Custom = {}; bridge.RefreshThemes(); drain(); assert(#bridge.Options.wind_theme.Values == 4)
bridge.Options.wind_theme:SetValue("MonokaiPro"); assert(wind.theme == "MonokaiPro")
bridge.Options.wind_debug:SetValue(true); assert(native.Debug == true)
first:AddToggle("test_error", {Default = false, Callback = function() error("fixture callback failure") end})
assert(string.find(bridge.LastError, "fixture callback failure", 1, true))
assert(#wind.notifications > 0, "debug error notification")
camera.ViewportSize = {X = 800, Y = 420}; viewportSignal:Fire(); drain(); assert(native.scale >= 0.3 and native.scale <= 1)
local old = viewportSignal
viewportSignal = signal(); workspace.CurrentCamera = {ViewportSize = {X = 1000, Y = 700}, GetPropertyChangedSignal = function() return viewportSignal end}
cameraSignal:Fire(); drain(); assert(native.scale == 1, "camera replacement rebinds scale observer")
local scale = native.scale; old:Fire(); drain(); assert(native.scale == scale)
local activeCamera = workspace.CurrentCamera
bridge.Options.wind_height:SetValue(900); drain()
assert(native.scale == 0.73, "size controls re-fit the viewport")
native:SetSize(UDim2.fromOffset(1000, 800)); drain()
assert(native.scale == 0.82, "native resize re-fits without stale control values")
bridge.Options.wind_width:SetValue(1050); drain()
assert(native.Size.X.Offset == 1050 and native.Size.Y.Offset == 800, "changing one axis preserves the native-dragged other axis")
native.IsFullscreen = true
bridge.Options.wind_height:SetValue(700); drain()
assert(not native.IsFullscreen and native.Size.X.Offset == 1050 and native.Size.Y.Offset == 700, "size controls exit fullscreen before changing normal bounds")
native:SetSize(UDim2.fromOffset(1000, 800)); drain()
local writes = native.scaleWrites
activeCamera.ViewportSize = {X = 600, Y = 400}
for _ = 1, 30 do viewportSignal:Fire() end
assert(native.scaleWrites == writes, "burst layout is deferred")
drain(); assert(native.scaleWrites == writes + 1 and native.scale == 0.45, "one scale write for a viewport burst")
local centers = native.centerWrites
for _ = 1, 30 do viewportSignal:Fire() end
drain(); assert(native.scaleWrites == writes + 1 and native.centerWrites == centers, "unchanged layout is a no-op")
native.IsFullscreen = true
activeCamera.ViewportSize = {X = 600, Y = 300}; viewportSignal:Fire(); drain()
assert(native.scale == 0.45, "fullscreen bypasses fit")
native.IsFullscreen = false; sizeSignal:Fire(); drain(); assert(native.scale == 0.32)
activeCamera.ViewportSize = {X = 0, Y = 0}; viewportSignal:Fire(); drain(); assert(native.scale == 0.32, "zero viewport does not collapse UI")
bridge.Options.wind_auto_fit:SetValue(false); bridge.Options.wind_scale:SetValue(0.75); drain()
activeCamera.ViewportSize = {X = 420, Y = 800}; viewportSignal:Fire(); drain(); assert(native.scale == 0.75, "manual scaling survives with auto-fit off")
bridge.Options.wind_auto_fit:SetValue(true); drain(); assert(native.scale == 0.38)
local lastSignal = viewportSignal
for _ = 1, 50 do
    viewportSignal = signal()
    workspace.CurrentCamera = {ViewportSize = {X = 420, Y = 800}, GetPropertyChangedSignal = function() return viewportSignal end}
    cameraSignal:Fire()
end
drain()
assert(not lastSignal.listeners[1].connection.Connected, "camera replacement removes old observer")
workspace.CurrentCamera = nil; cameraSignal:Fire(); drain(); assert(native.scale == 0.38)
local function viewButton(title)
    for _, e in ipairs(bridge.SettingsTabs["界面"].Native.elements) do if e.Title == title then return e end end
    error("missing view button: " .. title)
end
bridge.Options.wind_acrylic:SetValue(true); bridge.Options.wind_background:SetValue("rbxassetid://123")
viewButton("简化视觉效果").Callback(); drain()
assert(not wind.acrylic and native.background == "" and not native.transparent)
print("wind adapter numeric bounds, dropdown deduplication, burst layout, manual/fullscreen/nil camera, camera churn PASS")
bridge:Notify("multiargument", "content", 9); assert(wind.notifications[#wind.notifications].Duration == 9)
bridge:Notify({Title = "table", Content = "content", Duration = 7}); assert(wind.notifications[#wind.notifications].Duration == 7)
local resetCount, resetValue = 0, false
local resetting = first:AddToggle("destroy_reset", {Default = true, Callback = function(v) resetCount += 1; resetValue = v end})
assert(resetCount == 1 and resetValue)
local destroyed = 0
bridge:OnDestroy(function() destroyed += 1; bridge:Destroy(); resetting:SetValue(false) end)
toggle:SetValue(false)
local before = counts.test_toggle
sizeSignal:Fire()
local finalWrites = native.scaleWrites
bridge:Destroy(); bridge:Destroy(); drain()
assert(native.scaleWrites == finalWrites, "queued layout is canceled after destruction")
assert(counts.test_toggle == before and stops == 1 and destroyed == 1 and native.destroyed == 1)
assert(not bridge.Active and env.VortexionWindBridge == nil)
assert(resetCount == 2 and not resetValue and not resetting.Value, "cleanup callbacks reset business values once")
assert(resetting.Native.Value == true, "cleanup reset does not schedule native callbacks")
for _, c in ipairs(connections) do assert(not c.Connected, "tracked connection disconnected") end
print("wind adapter callbacks, settings, config callback, rotation, cleanup PASS")
local createCount, loadCount, saveCount = 0, 0, 0
local manager = {}
function manager:AllConfigs() return {"legacy"} end
function manager:CreateConfig(name, autoload)
    createCount += 1; assert(autoload == false)
    local c = {Elements = {}, AutoLoad = true}
    function c:Register(id, e) self.Elements[id] = e end
    function c:SetAsCurrent() native.CurrentConfig = self end
    function c:SetAutoLoad(v) self.AutoLoad = v end
    function c:Save() saveCount += 1; assert(not self.AutoLoad); return {} end
    function c:Load() loadCount += 1; self.Elements.config_business:Set(false); return {} end
    function c:Delete() return true end
    task.spawn(function() c:Load() end)
    return c
end
native.ConfigManager = manager
workspace.CurrentCamera = activeCamera
local fileEnv = {}
for _, name in ipairs({"readfile", "writefile", "isfile", "isfolder", "makefolder", "listfiles"}) do fileEnv[name] = function() return true end end
local full = createBridge(wind, {Name = "ConfigFixture", Env = fileEnv, ServerSwitchFactory = function() return {Stop = function() end} end})
local fullWin = full:CreateWindow({Title = "Game name", Size = UDim2.fromOffset(720, 510)})
assert(wind.windowConfig.Title == "Game name" and wind.windowConfig.Folder == "ConfigFixture/34" and wind.windowConfig.Background == "")
assert(createCount == 0 and loadCount == 0, "startup never creates/loads a config")
local businessCount, businessValue = 0, false
fullWin:AddTab({Title = "Game"}):AddToggle("config_business", {Default = true, Callback = function(v) businessCount += 1; businessValue = v end})
assert(businessCount == 1 and businessValue, "true business default is initialized once")
local function button(title)
    for _, e in ipairs(full.SettingsTabs["配置"].Native.elements) do if e.Title == title then return e end end
    error("missing settings button: " .. title)
end
assert(button("删除配置").Locked, "missing delfile locks delete")
button("创建 / 选定配置").Callback(); drain()
assert(createCount == 1 and loadCount == 0 and businessCount == 1, "legacy autoload is suppressed")
assert(full.Config.Elements.config_business == full.Options.config_business.Native, "config registers native control")
button("保存配置").Callback(); drain(); assert(saveCount == 1 and createCount == 1)
button("加载配置").Callback(); drain()
assert(loadCount == 1 and businessCount == 2 and not businessValue and not full.Options.config_business.Value, "explicit config load updates business callback")
local previousName = full.Options.wind_config_name.Value
full.Options.wind_config_name:SetValue("../broken")
button("创建 / 选定配置").Callback()
assert(createCount == 1 and string.find(full.LastError, "Config name", 1, true), "invalid config name cannot reach storage")
full.Options.wind_config_name:SetValue(previousName)
local save = full.Config.Save
full.Config.Save = function() error("fixture storage full") end
local notificationCount = #wind.notifications
button("保存配置").Callback()
assert(not native.Debug and #wind.notifications == notificationCount + 1 and string.find(wind.notifications[#wind.notifications].Content, "fixture storage full", 1, true), "storage errors are visible even when Debug is off")
assert(string.find(full.LastError, "fixture storage full", 1, true) and full.Active, "write error is visible and UI stays alive")
full.Config.Save = save
local load = full.Config.ManualLoad
full.Config.ManualLoad = function() error("fixture corrupt config") end
local beforeLoad = businessCount
button("加载配置").Callback()
assert(string.find(full.LastError, "fixture corrupt config", 1, true) and businessCount == beforeLoad, "bad load does not enable business defaults")
full.Config.ManualLoad = load
local list = manager.AllConfigs
manager.AllConfigs = function() error("fixture list denied") end
button("刷新文件列表").Callback()
assert(string.find(full.LastError, "fixture list denied", 1, true) and full.Active)
manager.AllConfigs = list
full:Destroy(); drain()
local mobileGetService = game.GetService
game.GetService = function(_, name) if name == "Workspace" then return workspace end return {TouchEnabled = false} end
workspace.CurrentCamera = {ViewportSize = {X = 1800, Y = 1000}, GetPropertyChangedSignal = function() return viewportSignal end}
local desktop = createBridge(wind, {Name = "DesktopFixture", Env = {}})
desktop:CreateWindow({Size = UDim2.fromOffset(720, 510)}); drain()
assert(wind.windowConfig.SideBarWidth == 200 and wind.acrylic and desktop.AutoFit and native.scale == 1)
desktop:Destroy(); drain()
workspace.CurrentCamera = nil
local cameraWaits = 0
task.wait = function() cameraWaits += 1; workspace.CurrentCamera = {ViewportSize = {X = 1800, Y = 1000}, GetPropertyChangedSignal = function() return viewportSignal end} end
local starting = createBridge(wind, {Name = "CameraStartupFixture", Env = {}})
assert(starting:CreateWindow({}) and cameraWaits == 1, "nil camera startup waits before calling native constructor")
starting:Destroy(); drain()
workspace.CurrentCamera = nil
local canceled = createBridge(wind, {Name = "CanceledStartupFixture", Env = {}})
task.wait = function() canceled:Destroy() end
assert(canceled:CreateWindow({}) == nil and not canceled.Active, "startup wait is canceled by destruction")
game.GetService = mobileGetService
workspace.CurrentCamera = activeCamera
manager.AllConfigs = function() error("fixture initial list denied") end
local initialList = createBridge(wind, {Name = "InitialListFixture", Env = fileEnv})
assert(initialList:CreateWindow({}) and initialList.Active and string.find(initialList.LastError, "fixture initial list denied", 1, true), "initial config list failure preserves complete UI and observers")
assert(initialList.Options.wind_config_files and #initialList.Options.wind_config_files.Values == 0)
initialList:Destroy(); drain(); manager.AllConfigs = list
local failed = createBridge(wind, {Name = "FailedInitFixture", Env = {}, ServerSwitchFactory = function() error("fixture module init failed") end})
local destroys = native.destroyed
assert(not pcall(function() failed:CreateWindow({}) end))
assert(not failed.Active and failed.Window() == nil and native.destroyed == destroys + 1, "partial window cannot be returned or reused after failure")
assert(failed:CreateWindow({}) == nil)
local constructor = wind.CreateWindow
wind.CreateWindow = function() error("fixture native directory denied") end
local rejected = createBridge(wind, {Name = "NativeStorageFixture", Env = {}})
assert(not pcall(function() rejected:CreateWindow({}) end) and not rejected.Active and rejected.Window() == nil)
assert(string.find(rejected.LastError, "fixture native directory denied", 1, true), "native constructor errors surface and cancel bridge initialization")
wind.CreateWindow = constructor
-- Colorpicker bridge contract: real Color3 userdata, silent native swatch, immediate business sync.
local colorCalls, colorSeen = 0, nil
local colorRed, colorBlue, colorGreen = Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(0, 255, 0)
local colorBridge = createBridge(wind, {Name = "ColorFixture", Env = fileEnv})
local colorWin = colorBridge:CreateWindow({Title = "Color", Size = UDim2.fromOffset(700, 500)})
local picker = colorWin:AddTab({Title = "Color"}):AddColorpicker("test_color", {Default = colorRed, Callback = function(v) colorCalls += 1; colorSeen = v end})
assert(colorCalls == 1 and colorSeen == colorRed, "colorpicker default fires exactly once")
assert(picker.Value == colorRed and picker.Native.Default == colorRed, "bridge value and native swatch start at the default")
assert(picker.Native.Value == nil, "native colorpicker never exposes a Value field")
picker:SetValue(colorBlue)
assert(colorCalls == 2 and picker.Value == colorBlue and picker.Native.Default == colorBlue, "SetValue synchronizes business state and the native swatch immediately")
picker:SetValue(colorBlue)
assert(colorCalls == 2, "reselecting the same color does not dispatch twice")
picker.Native:Set(colorGreen)
assert(colorCalls == 2 and picker.Value == colorBlue, "a silent native Set leaves business state untouched")
picker.Native.Callback(colorGreen)
assert(colorCalls == 3 and picker.Value == colorGreen, "a native picker callback reaches business state")
picker.Native:Set(colorGreen)
picker:SetValue(colorRed)
picker.Native.Callback(colorGreen)
assert(colorCalls == 4 and picker.Value == colorRed, "a stale native echo cannot override a newer SetValue")
local observed = 0
picker:OnChanged(function() observed += 1 end)
assert(observed == 1, "OnChanged reports the current color immediately")
picker:SetValue(colorBlue)
assert(observed == 2 and colorCalls == 5, "OnChanged observes every colorpicker change")
for _, bad in ipairs({{R = 0, G = 0, B = 0}, "ff0000", false, Color3.new(2, 0, 0), Color3.new(-0.5, 0, 0), Color3.new(0 / 0, 0, 0), Color3.new(math.huge, 0, 0)}) do
    assert(not pcall(function() picker:SetValue(bad) end), "invalid color rejected: " .. tostring(bad))
    assert(picker.Value == colorBlue and colorCalls == 5, "a rejected color keeps the previous state")
end
local colorButton
for _, item in ipairs(colorBridge.SettingsTabs["配置"].Native.elements) do if item.Title == "创建 / 选定配置" then colorButton = item end end
assert(colorButton, "config tab exposes the create button")
colorButton.Callback(); drain()
assert(colorBridge.Config.Elements.test_color == picker.Native, "config registers the native colorpicker")
colorBridge:Destroy(); drain()
local settled = colorCalls
picker.Native.Callback(colorRed); picker:SetValue(colorGreen)
assert(colorCalls == settled and picker.Value == colorBlue, "a destroyed bridge dispatches nothing")
print("wind adapter colorpicker default, silent native Set, immediate sync, dedupe, stale echo, OnChanged, invalid input, config registration, unload PASS")
for _, c in ipairs(connections) do assert(not c.Connected) end
print("wind adapter manual config, storage failures, file capability, legacy autoload gate, desktop/mobile defaults PASS")
