-- Native WindUI navigation and compatibility for the preserved game option IDs.
return function(WindUI, config)
    config = config or {}
    assert(WindUI and type(WindUI.CreateWindow) == "function", "WindUI missing")
    local env = config.Env or (getgenv and getgenv()) or _G
    local bridge = {Options = {}, Tabs = {}, GameTabs = {}, Library = WindUI, GUI = WindUI.ScreenGui, Active = true, Trace = false}
    local connections, destroyCallbacks = {}, {}
    local native, windowHandle
    local appName = config.Name or "Vortexion"
    local input = game:GetService("UserInputService")
    local world = game:GetService("Workspace")
    local layoutQueued, lastLayout, layoutRevision = false, nil, 0
    local centerTween = nil
    local topbarConnection, topbarWatchInstalled = nil, false
    -- Vendor aw.Open force-enables the acrylic blur (WindUI:ToggleAcrylic(true)) after its open animation,
    -- ignoring the user's choice, and aw.Close force-disables it. This bridge owns a preference-enforcing
    -- override for its lifetime: a forced enable cannot turn the blur on against a stored "off" preference,
    -- while the user can still enable it later. The override is fenced to the single window this bridge created
    -- (self == WindUI and WindUI.Window == native while Active): ToggleAcrylic mutates that one Window slot, so a
    -- side window that later takes the slot is never gated by this bridge's preference, and any other self or
    -- inactive call forwards untouched. The previous module method is saved per instance and restored in cleanup
    -- only while it is still this bridge's own wrapper, so an externally installed wrapper is never replaced.
    -- After teardown the wrapper must stay a working passthrough, not an identity that silently drops calls: an
    -- external delegate that captured it would otherwise stop reaching the vendor method, so the captured original
    -- is retained in acrylicForward and never released. CreateWindow keeps Acrylic = true so the low-level blur
    -- allocation stays available; only the runtime toggle is gated by the stored preference, which is kept
    -- independent of the vendor-written Window.Acrylic.
    local acrylicPref = not input.TouchEnabled
    local originalToggleAcrylic, acrylicForward = nil, nil
    local function acrylicWrapper(self, value)
        if self == WindUI and self.Window == native and bridge.Active and value and not acrylicPref then
            value = false
        end
        local forward = originalToggleAcrylic or acrylicForward
        if forward then return forward(self, value) end
    end
    -- Cancel only our own centering tween. Vendor centering (SetToTheCenter / drag / double-click) is never touched.
    local function cancelOwnedCenter()
        local tween = centerTween
        if tween then
            centerTween = nil
            pcall(function() tween:Cancel() end)
        end
    end
    local sliderFlushQueued = false
    -- Non-critical visual refresh pacing. Pure: allocates nothing and reads no control per call.
    local VISUAL_HZ_MIN, VISUAL_HZ_MAX = 5, 60
    local PERF_TIER_HZ = {["原速"] = 60, ["均衡"] = 15, ["省电"] = 5}
    local defaultPerfTier = input.TouchEnabled and "均衡" or "原速"
    bridge.VisualHz = PERF_TIER_HZ[defaultPerfTier]
    -- Optional budget only affects non-critical visual refresh loops. Disabled by default.
    bridge.AdaptiveVisualHz = nil
    local adaptiveConnection, adaptiveAccum, adaptiveFrames = nil, 0, 0
    local adaptiveLow, adaptiveHigh, adaptiveMeasured = 0, 0, 0
    local adaptiveFloor, adaptiveTarget = 10, 38
    local function resetAdaptive()
        if adaptiveConnection then adaptiveConnection:Disconnect(); adaptiveConnection = nil end
        bridge.AdaptiveVisualHz = nil
        adaptiveAccum, adaptiveFrames, adaptiveLow, adaptiveHigh = 0, 0, 0, 0
    end
    local function setAdaptive(enabled)
        resetAdaptive()
        if not enabled or not bridge.Active then return end
        -- The instantaneous UI pacing target does not change until enough low-FPS samples persist.
        local service = game:GetService("RunService")
        adaptiveConnection = service.Heartbeat:Connect(function(dt)
            if not bridge.Active then return end
            local frameTime = tonumber(dt)
            if not frameTime or frameTime <= 0 or frameTime > 0.5 then return end
            adaptiveAccum += frameTime
            adaptiveFrames += 1
            if adaptiveAccum < 1 then return end
            adaptiveMeasured = math.floor(adaptiveFrames / adaptiveAccum + 0.5)
            adaptiveAccum, adaptiveFrames = 0, 0
            local target = math.max(adaptiveFloor, math.min(60, adaptiveTarget))
            if adaptiveMeasured < target then
                adaptiveLow += 1
                adaptiveHigh = 0
            elseif adaptiveMeasured > target + 8 then
                adaptiveHigh += 1
                adaptiveLow = 0
            else
                adaptiveLow, adaptiveHigh = 0, 0
            end
            -- Only reduce optional visual work after 3 consecutive poor samples;
            -- recover after 6 good samples to prevent oscillation.
            if adaptiveLow >= 3 then
                bridge.AdaptiveVisualHz = math.max(adaptiveFloor, math.floor(adaptiveMeasured * 0.65))
                adaptiveLow = 0
            elseif adaptiveHigh >= 6 then
                bridge.AdaptiveVisualHz = nil
                adaptiveHigh = 0
            end
        end)
    end
    local function clampHz(value)
        local hz = tonumber(value)
        if not hz or hz ~= hz or hz == math.huge or hz == -math.huge then return VISUAL_HZ_MAX end
        hz = math.floor(hz + 0.5)
        if hz < VISUAL_HZ_MIN then return VISUAL_HZ_MIN elseif hz > VISUAL_HZ_MAX then return VISUAL_HZ_MAX end
        return hz
    end
    local function sanitizeBase(value)
        local n = tonumber(value)
        if not n or n ~= n or n == math.huge or n == -math.huge or n < 0 then return 0 end
        return n
    end
    function bridge:GetVisualInterval(baseSeconds)
        -- Caps non-critical visual refresh at VisualHz without ever accelerating the caller's own cadence.
        local visualHz = clampHz(self.VisualHz)
        if self.AdaptiveVisualHz then visualHz = math.min(visualHz, clampHz(self.AdaptiveVisualHz)) end
        return math.max(sanitizeBase(baseSeconds), 1 / visualHz)
    end
    local function flushSliders()
        if not bridge.Active or sliderFlushQueued then return end
        sliderFlushQueued = true
        task.defer(function()
            sliderFlushQueued = false
            if not bridge.Active then return end
            for _, option in pairs(bridge.Options) do
                if option.Pending and not option.Native.Locked then
                    local value = option.Pending
                    option.Pending = nil
                    option:SetValue(value)
                end
            end
        end)
    end
    local function requestLayout()
        if not bridge.Active or layoutQueued then return end
        layoutQueued = true
        task.defer(function()
            layoutQueued = false
            if bridge.Active and bridge.FitViewport then bridge:FitViewport() end
        end)
    end
    -- TopbarInset is a read-only Rect that changes as Roblox UI controls occupy or release the safe area; the official
    -- GuiService docs recommend GetPropertyChangedSignal("TopbarInset") to react. The signal is used purely as a trigger
    -- to re-read GuiService:GetGuiInset() (two Vector2 values); the Rect itself is never read as a coordinate, and this
    -- refresh is not claimed to cover every hardware edge change. Install once, guarded end to end: a missing
    -- GetService / GetPropertyChangedSignal / Connect must not break init or an explicit FitViewport, and a connection
    -- that arrives after teardown is disconnected immediately and never pooled.
    local function installTopbarInsetWatch()
        if topbarWatchInstalled then return end
        topbarWatchInstalled = true
        task.spawn(function()
            -- Every stage that can suspend is fenced: a bridge torn down before or during the install must not keep
            -- acquiring services or connections. A connection that still arrives is disconnected exactly once.
            if not bridge.Active then return end
            local okGui, gui = pcall(function() return game:GetService("GuiService") end)
            if not bridge.Active then return end
            if not okGui or not gui then return end
            local okSignal, signal = pcall(function() return gui:GetPropertyChangedSignal("TopbarInset") end)
            if not bridge.Active then return end
            if not okSignal or not signal then return end
            local okConnection, connection = pcall(function()
                return signal:Connect(function()
                    -- A late event after teardown is inert; a disabled safe-area or auto-fit must not queue a layout.
                    if not bridge.Active or not bridge.SafeArea or not bridge.AutoFit then return end
                    requestLayout()
                end)
            end)
            -- Late connection after teardown: disconnect once, keep no pool, publish nothing.
            if not bridge.Active then
                if okConnection and connection then pcall(function() connection:Disconnect() end) end
                return
            end
            if not okConnection or not connection then return end
            topbarConnection = connection
            table.insert(connections, connection)
        end)
    end
    env.VortexionWindBridge = bridge
    -- Diagnostic survives bridge cleanup: loader needs the original WindUI failure,
    -- not the secondary "No active WindUI bridge" symptom.
    local function recordStartupFailure(step, reason)
        local message = "WindUI/" .. tostring(step) .. ": " .. tostring(reason)
        if env.VortexionTextCompatLast then
            message = message .. " | TextCompat: " .. tostring(env.VortexionTextCompatLast)
        end
        env.VortexionBootError = message:sub(1, 1500)
        warn("[Vortexion/Wind/BOOT] " .. message)
    end

    function bridge:Notify(info, content, duration)
        if not self.Active then return end
        local c = type(info) == "table" and info or {Title = info, Content = content, Duration = duration}
        local ok, result = pcall(function()
            return WindUI:Notify({Title = c.Title or appName, Content = c.Content or "", Duration = c.Duration or 4})
        end)
        if not self.Active then return end
        if ok then return result end
        self.LastError = tostring(result)
    end
    local callbackErrorRevision = 0
    local callbackCalls, nativeEvents, nativeMismatch, lastNativeEvent = 0, 0, 0, "none"
    local function safeCallback(fn, ...)
        if type(fn) == "function" then callbackCalls += 1 end
        if type(fn) ~= "function" then return end
        local wasActive = bridge.Active
        local ok, err = pcall(fn, ...)
        if not ok then
            if wasActive and not bridge.Active then return end
            callbackErrorRevision += 1
            bridge.LastError = tostring(err)
            if native and native.Debug then warn("[" .. appName .. "/WindUI] " .. tostring(err)) end
            bridge:Notify("回调异常", string.sub(tostring(err), 1, 500), 8)
        end
    end
    local function colorValue(value)
        assert(typeof(value) == "Color3", "colorpicker requires Color3")
        local r, g, b = value.R, value.G, value.B
        assert(r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1, "colorpicker requires finite RGB components in [0, 1]")
        return value
    end
    local function copy(value)
        if type(value) ~= "table" then return value end
        local result = {}
        for k, v in pairs(value) do result[k] = copy(v) end
        return result
    end
    local function equal(a, b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= "table" then return a == b end
        for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
        for k in pairs(b) do if a[k] == nil then return false end end
        return true
    end
    local function cleanup()
        if not bridge.Active then return end
        bridge.Active = false
        windowHandle = nil
        bridge.Config = nil
        if bridge.ServerSwitch then safeCallback(function() bridge.ServerSwitch:Stop() end) end
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        table.clear(connections)
        topbarConnection = nil
        cancelOwnedCenter()
        resetAdaptive()
        if originalToggleAcrylic and WindUI.ToggleAcrylic == acrylicWrapper then
            WindUI.ToggleAcrylic = originalToggleAcrylic
        end
        -- Never drop the forwarding target: an external delegate that captured this wrapper after install must keep
        -- reaching the real vendor method. originalToggleAcrylic is released only for the captured-forward fallback,
        -- and acrylicForward keeps the last captured original alive so the wrapper stays a working passthrough.
        acrylicForward = originalToggleAcrylic or acrylicForward
        originalToggleAcrylic = nil
        bridge.Cleaning = true
        for _, fn in ipairs(destroyCallbacks) do safeCallback(fn) end
        bridge.Cleaning = false
        table.clear(destroyCallbacks)
        for _, option in pairs(bridge.Options) do
            option.Pending = nil
            option.RefreshPending, option.SelectPending = nil, nil
            table.clear(option.listeners)
        end
        if env.VortexionWindBridge == bridge then env.VortexionWindBridge = nil end
    end
    function bridge:OnDestroy(fn)
        if self.Active then table.insert(destroyCallbacks, fn) else safeCallback(fn) end
    end
    function bridge:Destroy()
        if not self.Active then return end
        cleanup()
        if native then safeCallback(function() native:Destroy() end) end
    end
    bridge.Window = function() return windowHandle end

    local function wrapTab(nativeTab)
        local handle = {Native = nativeTab, Title = nativeTab.Title}
        local function createOption(kind, id, c)
            assert(not bridge.Options[id], "duplicate option ID: " .. tostring(id))
            local values = copy(c.Values or {})
            local min, max = tonumber(c.Min) or 0, tonumber(c.Max) or 100
            local precision = tonumber(c.Rounding) or 0
            if precision ~= precision then precision = 0 end
            precision = math.clamp(math.floor(precision), 0, 2)
            local step = 10 ^ -precision
            if kind == "Slider" then
                assert(min == min and max == max and min > -math.huge and max < math.huge and min < max, "slider requires finite Min < Max")
            end
            local function normalize(v, isDefault)
                if kind == "Colorpicker" then return colorValue(v) end
                if kind == "Toggle" then return v == true end
                if kind == "Input" then return tostring(v == nil and "" or v) end
                if kind == "Slider" then
                    local n = tonumber(v)
                    if not n or n ~= n then n = min end
                    n = math.clamp(n, min, max)
                    n = math.clamp(math.floor(n / step + 0.5) * step, min, max)
                    return math.clamp(step % 1 ~= 0 and tonumber(string.format("%.2f", n)) or n, min, max)
                end
                if isDefault and type(v) == "number" then v = values[v] end
                if c.Multi then return type(v) == "table" and copy(v) or (v ~= nil and {v} or {}) end
                return v == nil and isDefault and values[1] or v
            end
            local option = {ID = id, Value = normalize(c.Default, true), Values = values, listeners = {}}
            bridge.Options[id] = option
            local ready, revision, dispatchRevision = false, 0, 0
            local refreshBusy, refreshQueued, refreshTarget, refreshDirty = false, false, nil, false
            local function nativeValue()
                if kind == "Colorpicker" then return colorValue(option.Native.Default) end
                local value = option.Native.Value
                if kind == 'Slider' then
                    local raw = value.Default
                    value = normalize(raw, false)
                    if tonumber(raw) ~= value then
                        option.Native.Value.Default = value
                        local elements = option.Native.UIElements
                        local box = elements and elements.SliderContainer and elements.SliderContainer.TextBox
                        if box then box.Text = tostring(value) end
                    end
                    return value
                end
                return normalize(value, false)
            end
            local function emit(value)
                if not bridge.Active and not bridge.Cleaning then return end
                dispatchRevision += 1
                local dispatch, listenerCount = dispatchRevision, #option.listeners
                local cleanupDispatch = not bridge.Active and bridge.Cleaning
                option.Value = copy(value)
                if bridge.Trace then print("[WindUI] " .. tostring(id) .. " = " .. tostring(value)) end
                safeCallback(c.Callback, copy(value))
                -- Bound fanout and fence nested dispatch, including same-value ABA reentry.
                for index = 1, listenerCount do
                    if dispatch ~= dispatchRevision or (not bridge.Active and not (cleanupDispatch and bridge.Cleaning)) then break end
                    safeCallback(option.listeners[index], copy(value))
                end
            end
            local function changed(value)
                if not bridge.Active or not ready then return end
                value = normalize(value, false)
                nativeEvents += 1
                lastNativeEvent = tostring(id) .. "=" .. tostring(value)
                -- Native asynchronous callbacks can arrive after another SetValue.
                local current = nativeValue()
                if not equal(value, current) then
                    nativeMismatch += 1
                    return
                end
                if not equal(value, option.Value) then
                    revision += 1
                    option.Pending = nil
                    emit(value)
                end
            end
            local settings = {Title = c.Title or tostring(id), Desc = c.Description or c.Desc, Flag = id, Callback = changed}
            if kind == "Colorpicker" then
                settings.Default = option.Value
            elseif kind == "Slider" then
                settings.Value = {Min = min, Max = max, Default = option.Value}
                settings.Step = step
            else settings.Value = copy(option.Value) end
            if kind == "Dropdown" then settings.Values = values; settings.Multi = c.Multi or false; settings.AllowNone = true; settings.SearchBarEnabled = true end
            if kind == "Input" then
                settings.Placeholder = c.Placeholder or ""
                settings.InputIcon = c.InputIcon
            end
            option.Native = nativeTab[kind](nativeTab, settings)
            if kind == 'Slider' then
                nativeValue()
                local elements = option.Native.UIElements
                local box = elements and elements.SliderContainer and elements.SliderContainer.TextBox
                if box and box.FocusLost then table.insert(connections, box.FocusLost:Connect(flushSliders)) end
            end
            local requestOrder = 0
            local function takeDropdownPending()
                local selected = option.SelectPending
                if selected and (not option.RefreshPending or selected.Order < option.RefreshOrder) then
                    option.SelectPending = nil; return selected
                end
                local pending = option.RefreshPending
                option.RefreshPending = nil
                if pending and (refreshDirty or not equal(values, pending)) then
                    return {Kind = 'Refresh', Value = pending, Order = option.RefreshOrder}
                end
                option.SelectPending = nil
                return selected
            end
            local function runDropdown(target)
                local passes = 0
                refreshBusy = true
                while target do
                    if target.Kind == 'Select' and refreshDirty then
                        -- Repair a failed native menu before selecting; count it as a separate pass.
                        if not option.SelectPending then option.SelectPending = target end
                        target = {Kind = 'Refresh', Value = copy(values), Order = target.Order}
                    end
                    refreshTarget = target.Kind == 'Refresh' and target.Value or nil
                    local selectionRevision = revision
                    local ok, err = pcall(function()
                        if target.Kind == 'Refresh' then option.Native:Refresh(copy(target.Value))
                        else
                            option.Native:Select(copy(target.Value))
                            if bridge.Active and selectionRevision == revision then
                                local accepted = nativeValue()
                                if not equal(option.Value, accepted) then emit(accepted) end
                            end
                        end
                    end)
                    refreshTarget = nil
                    if not ok or not bridge.Active then
                        refreshBusy = false
                        option.RefreshPending, option.SelectPending = nil, nil
                        if not ok then refreshDirty = true; error(err, 0) end
                        return false
                    end
                    if target.Kind == 'Refresh' then
                        values = target.Value
                        option.Values = values
                        refreshDirty = false
                    end
                    passes += 1
                    if passes >= 8 and (option.RefreshPending or option.SelectPending) then
                        refreshBusy, refreshQueued = false, true
                        task.defer(function()
                            refreshQueued = false
                            if not bridge.Active then return end
                            local latest = takeDropdownPending()
                            if latest then safeCallback(function() runDropdown(latest) end) end
                        end)
                        return false
                    end
                    target = takeDropdownPending()
                end
                refreshBusy = false
                return true
            end
            function option:SetValue(value)
                if not bridge.Active and not bridge.Cleaning then return end
                value = normalize(value, false)
                revision += 1
                local requestRevision = revision
                self.Pending = nil
                if bridge.Cleaning then
                    if not equal(self.Value, value) then emit(value) end
                    return true
                end
                if kind == 'Dropdown' then
                    requestOrder += 1
                    local selected = {Kind = 'Select', Value = copy(value), Order = requestOrder}
                    if refreshBusy or refreshQueued then self.SelectPending = selected; return false end
                    return runDropdown(selected)
                end
                self.Native:Set(value)
                if not bridge.Active then return false end
                -- Native setters may decline during drag/focus or reenter this option.
                if revision ~= requestRevision then return true end
                local accepted = nativeValue()
                if kind == 'Slider' and not equal(accepted, value) then
                    if not self.Native.Locked then self.Pending = copy(value) end
                    return false
                end
                if not equal(self.Value, accepted) then emit(accepted) end
                return true
            end
            function option:SetValues(newValues)
                if not bridge.Active or kind ~= 'Dropdown' then return end
                newValues = newValues or {}
                assert(type(newValues) == 'table', 'dropdown values must be a table')
                if refreshBusy or refreshQueued then
                    local desired = self.RefreshPending or refreshTarget or values
                    if not equal(desired, newValues) then
                        requestOrder += 1
                        self.RefreshPending, self.RefreshOrder = copy(newValues), requestOrder
                    end
                    return false
                end
                if not refreshDirty and equal(values, newValues) then return true end
                requestOrder += 1
                return runDropdown({Kind = 'Refresh', Value = copy(newValues), Order = requestOrder})
            end
            function option:OnChanged(fn)
                if not bridge.Active then return self end
                table.insert(self.listeners, fn)
                if bridge.Active then safeCallback(fn, copy(self.Value)) end
                return self
            end
            ready = true
            emit(option.Value)
            return option
        end
        for _, kind in ipairs({"Toggle", "Slider", "Input", "Dropdown", "Colorpicker"}) do
            handle["Add" .. kind] = function(_, id, c) return createOption(kind, id, c or {}) end
        end
        function handle:AddButton(c)
            return nativeTab:Button({Title = c.Title, Desc = c.Description or c.Desc, Locked = c.Locked, Callback = function() if bridge.Active then safeCallback(c.Callback) end end})
        end
        function handle:AddParagraph(c) return nativeTab:Paragraph({Title = c.Title or "说明", Desc = c.Content or c.Desc or ""}) end
        return handle
    end

    local fileApi = {readfile = readfile, writefile = writefile, isfile = isfile, isfolder = isfolder, makefolder = makefolder, listfiles = listfiles, delfile = delfile}
    local missingFileApi = {}
    for _, name in ipairs({"readfile", "writefile", "isfile", "isfolder", "makefolder", "listfiles"}) do
        fileApi[name] = fileApi[name] or env[name]
        if type(fileApi[name]) ~= "function" then table.insert(missingFileApi, name) end
    end
    fileApi.delfile = fileApi.delfile or env.delfile
    local function installSettings(groups)
        local pages = {}
        for _, title in ipairs({"主题", "界面", "调试", "配置"}) do pages[title] = wrapTab(groups.UI:Tab({Title = title})) end
        bridge.SettingsTabs = pages
        local theme, view, debugPage, configs = pages["主题"], pages["界面"], pages["调试"], pages["配置"]
        local function themes()
            local keys = {}
            for key in pairs(WindUI:GetThemes()) do table.insert(keys, key) end
            table.sort(keys); return keys
        end
        -- WindUI.Theme is a theme CONFIGURATION TABLE, not a theme identifier.
        -- Passing it as a Dropdown default is fatal: vendor Dropdown.Display
        -- assigns the table directly to TextLabel.Text (which requires string).
        -- Always resolve a registered theme NAME before handing it to WindUI.
        local function resolveThemeName(configuredName)
            local available = WindUI:GetThemes()
            if type(configuredName) == "string" and available[configuredName] then
                return configuredName
            end
            local currentName = WindUI:GetCurrentTheme()
            if type(currentName) == "string" and available[currentName] then
                return currentName
            end
            if available.Dark then return "Dark" end
            local names = themes()
            assert(#names > 0, "WindUI did not register any themes")
            return names[1]
        end
        local themeOption = theme:AddDropdown("wind_theme", {Title = "原生主题", Values = themes(), Default = resolveThemeName(config.Theme), Callback = function(v) if type(v) == "string" then WindUI:SetTheme(v) end end})
        bridge.RefreshThemes = function() themeOption:SetValues(themes()) end
        theme:AddButton({Title = "刷新主题列表", Callback = bridge.RefreshThemes})
        theme:AddToggle("wind_transparent", {Title = "透明窗口", Default = false, Callback = function(v) native:ToggleTransparency(v) end})
        theme:AddSlider("wind_transparency", {Title = "窗口透明度", Min = 0, Max = 1, Default = 0, Rounding = 1, Callback = function(v) native:SetBackgroundTransparency(v) end})
        theme:AddToggle("wind_acrylic", {Title = "亚克力模糊", Default = not input.TouchEnabled, Callback = function(v) acrylicPref = v; WindUI:ToggleAcrylic(v) end})
        theme:AddInput("wind_background", {Title = "背景图资源", Default = "", Placeholder = "rbxassetid://资源ID", Callback = function(v) native:SetBackgroundImage(v) end})
        theme:AddSlider("wind_background_alpha", {Title = "背景图透明度", Min = 0, Max = 1, Default = 0, Rounding = 1, Callback = function(v) native:SetBackgroundImageTransparency(v) end})
        view:AddSlider("wind_scale", {Title = "界面缩放", Min = 0.1, Max = 1.5, Default = native:GetUIScale(), Rounding = 2, Callback = function(v) native:SetUIScale(v) end})
        view:AddToggle("wind_auto_fit", {Title = "自动适配屏幕", Default = true, Callback = function(v) bridge.AutoFit = v; cancelOwnedCenter(); lastLayout = nil; requestLayout() end})
        view:AddDropdown("wind_key", {Title = "收起快捷键", Values = {"K", "RightControl", "LeftAlt"}, Default = "K", Callback = function(v) if Enum.KeyCode[v] then native:SetToggleKey(Enum.KeyCode[v]) end end})
        view:AddToggle("wind_resizable", {Title = "允许调整窗口大小", Default = true, Callback = function(v) native:IsResizable(v) end})
        local initialWidth, initialHeight = native.Size.X.Offset, native.Size.Y.Offset
        local function resize(axis, value)
            if native.IsFullscreen then native:ToggleFullscreen() end
            local width = axis == "width" and value or native.Size.X.Offset
            local height = axis == "height" and value or native.Size.Y.Offset
            native:SetSize(UDim2.fromOffset(width, height))
            if not bridge.AutoFit then native:SetToTheCenter() end
            requestLayout()
        end
        view:AddSlider("wind_width", {Title = "窗口宽度", Min = 400, Max = 1100, Default = initialWidth, Callback = function(v) resize("width", v) end})
        view:AddSlider("wind_height", {Title = "窗口高度", Min = 300, Max = 900, Default = initialHeight, Callback = function(v) resize("height", v) end})
        local function computeVisualHz()
            local tier = bridge.Options.wind_perf_tier and bridge.Options.wind_perf_tier.Value or defaultPerfTier
            if tier == "自定义" then
                bridge.VisualHz = clampHz(bridge.Options.wind_visual_hz and bridge.Options.wind_visual_hz.Value)
            else
                bridge.VisualHz = PERF_TIER_HZ[tier] or bridge.VisualHz
            end
        end
        view:AddDropdown("wind_perf_tier", {Title = "视觉刷新档位", Values = {"原速", "均衡", "省电", "自定义"}, Default = defaultPerfTier, Callback = function() computeVisualHz() end})
        view:AddSlider("wind_visual_hz", {Title = "自定义刷新率 (Hz)", Min = VISUAL_HZ_MIN, Max = VISUAL_HZ_MAX, Default = clampHz(input.TouchEnabled and 15 or 60), Rounding = 0, Callback = function() computeVisualHz() end})
        view:AddParagraph({Title = "视觉刷新", Content = "仅限制非关键视觉刷新（ESP/轨迹/高亮等），不改变移动、输入、回收或战斗/冷却频率。档位越高刷新越勤、耗电越高；\"原速\" 只把刷新限制到不高于 60Hz，不会把旧有节拍加速。"})
        computeVisualHz()
        view:AddToggle("wind_adaptive_visual", {Title = "自适应视觉调度（实验）", Default = false,
            Callback = function(v) setAdaptive(v) end})
        view:AddSlider("wind_adaptive_target", {Title = "自适应目标帧率", Min = 20, Max = 60, Default = 38, Rounding = 0,
            Callback = function(v) adaptiveTarget = tonumber(v) or 38 end})
        view:AddParagraph({Title = "自适应说明", Content = "持续 3 秒低于目标帧率时，降低非关键视觉刷新上限；连续 6 秒恢复后取消限制。不开启时无额外帧监听。该选项不改变输入、物理或关键战斗更新。"})
        view:AddToggle("wind_notification_lower", {Title = "通知显示在底部", Default = false, Callback = function(v) WindUI:SetNotificationLower(v) end})
        view:AddButton({Title = "窗口居中", Callback = function() cancelOwnedCenter(); native:SetToTheCenter() end})
        view:AddButton({Title = "收起窗口", Callback = function() native:Toggle() end})
        view:AddButton({Title = "恢复触控入口", Callback = function() native:EditOpenButton({Title = appName, Enabled = true, Draggable = true, OnlyMobile = false}) end})
        view:AddButton({Title = "简化视觉效果", Callback = function()
            bridge.Options.wind_acrylic:SetValue(false)
            bridge.Options.wind_transparent:SetValue(false)
            bridge.Options.wind_background:SetValue("")
        end})
        view:AddButton({Title = "适配当前屏幕", Callback = function() bridge.Options.wind_auto_fit:SetValue(true); bridge:FitViewport() end})
        view:AddToggle("wind_readability_guard", {Title = "可读性保护(限制最小缩放)", Default = false, Callback = function(v) bridge.ReadabilityGuard = v; requestLayout() end})
        view:AddSlider("wind_min_scale", {Title = "可读性最小缩放", Min = 0.3, Max = 1, Default = 0.5, Rounding = 2, Callback = function() requestLayout() end})
        view:AddToggle("wind_safe_area", {Title = "GUI 安全边距（四边，不仅顶部）", Default = false, Callback = function(v) bridge.SafeArea = v; cancelOwnedCenter(); lastLayout = nil; requestLayout() end})
        view:AddParagraph({Title = "移动端", Content = "自动适配同时处理旋转和窗口尺寸变化；关闭后保留手动缩放。触屏使用紧凑侧栏，收起后保留可拖动的原生恢复按钮。可读性保护开启后，缩放不再小于下方设定值，避免文字难以辨认。开启 GUI 安全边距后按四边 inset（含左右/底部）在可用区内受控居中，偏移取四边差值的一半；文字可读性优先可能使窗口溢出，物理刘海/系统手势区未在真机实测。"})
        -- 一键推荐设置：仅通过既有 Options 的 SetValue 应用预设组合，不直接写 native/bridge 布局字段。
        -- auto_fit is last; changed values request layout through the existing callback.
        local function applyRecommended(label, ordered)
            if not bridge.Active then return end
            -- 开始前先核验全套目标 option 及 SetValue 能力，缺失则友好提示且不应用任何更改。
            for _, entry in ipairs(ordered) do
                local option = bridge.Options[entry[1]]
                if type(option) ~= "table" or type(option.SetValue) ~= "function" then
                    bridge:Notify({Title = "推荐设置", Content = label .. "未应用：缺少选项 " .. tostring(entry[1]) .. "。"})
                    return
                end
            end
            -- 逐项应用；每次 SetValue 前检查 bridge.Active，异常经 Notify 说明并停止，绝不报告全成功。
            for _, entry in ipairs(ordered) do
                if not bridge.Active then return end
                local previousErrors = callbackErrorRevision
                local ok, result = pcall(function() return bridge.Options[entry[1]]:SetValue(entry[2]) end)
                if not bridge.Active then return end
                if not ok or callbackErrorRevision ~= previousErrors then
                    bridge:Notify({Title = "推荐设置", Content = label .. "部分应用后中断：" .. string.sub(tostring(not ok and result or bridge.LastError), 1, 200)})
                    return
                end
                if result ~= true or bridge.Options[entry[1]].Value ~= entry[2] then
                    bridge:Notify({Title = "推荐设置", Content = label .. "尚未全部应用：选项 " .. entry[1] .. "仍在交互或排队，请结束当前操作后重试。"})
                    return
                end
            end
            -- 全部完成且仍 Active 才通知成功。
            if bridge.Active then bridge:Notify({Title = "推荐设置", Content = label .. "已应用。"}) end
        end
        view:AddButton({Title = "完整显示优先适配", Desc = "关闭可读性下限，开启 GUI 安全边距与自动适配；保留手动最小缩放、窗口尺寸、主题和刷新档位。", Callback = function()
            applyRecommended("完整显示优先适配", {
                {"wind_readability_guard", false},
                {"wind_safe_area", true},
                {"wind_auto_fit", true},
            })
        end})
        view:AddButton({Title = "文字可读性优先适配", Desc = "启用当前最小缩放、GUI 安全边距与自动适配；小屏可能溢出，可用完整显示优先恢复。", Callback = function()
            applyRecommended("文字可读性优先适配", {
                {"wind_readability_guard", true},
                {"wind_safe_area", true},
                {"wind_auto_fit", true},
            })
        end})
        view:AddButton({Title = "应用触屏推荐设置", Desc = "触屏组合：关闭亚克力与透明窗口、通知置底、均衡刷新档位、关闭可读性保护、开启 GUI 安全边距与自动适配；不改动缩放、背景、尺寸与自定义刷新率。", Callback = function()
            applyRecommended("触屏推荐设置", {
                {"wind_acrylic", false},
                {"wind_transparent", false},
                {"wind_perf_tier", "均衡"},
                {"wind_notification_lower", true},
                {"wind_readability_guard", false},
                {"wind_safe_area", true},
                {"wind_auto_fit", true},
            })
        end})
        view:AddButton({Title = "应用桌面推荐设置", Desc = "桌面组合：开启亚克力、关闭透明窗口、通知不置底、原速刷新档位、关闭可读性保护与 GUI 安全边距、保持自动适配；不改动缩放、背景、尺寸与自定义刷新率。", Callback = function()
            applyRecommended("桌面推荐设置", {
                {"wind_acrylic", true},
                {"wind_transparent", false},
                {"wind_perf_tier", "原速"},
                {"wind_notification_lower", false},
                {"wind_readability_guard", false},
                {"wind_safe_area", false},
                {"wind_auto_fit", true},
            })
        end})
        debugPage:AddToggle("wind_debug", {Title = "WindUI 原生调试", Default = config.Debug == true, Callback = function(v) native.Debug = v end})
        debugPage:AddToggle("wind_trace", {Title = "桥接回调跟踪", Default = false, Callback = function(v) bridge.Trace = v end})
        local diagnostic = debugPage:AddParagraph({Title = "运行诊断", Content = "点击刷新获取当前状态。"})
        bridge.GetDiagnostics = function()
            local optionCount = 0
            for _ in pairs(bridge.Options) do optionCount += 1 end
            return string.format("GameId: %s\nPlaceId: %s\nJobId: %s\n当前页: %s\n缩放: %s\n主题: %s\n选项: %s\n主题数: %s\n最近异常: %s\n视觉档位: %s\n视觉刷新: %s Hz (上限 %s)\nTopbarInset 监听: %s", tostring(game.GameId), tostring(game.PlaceId), tostring(game.JobId), tostring(native.CurrentTab), tostring(native:GetUIScale()), tostring(WindUI:GetCurrentTheme()), tostring(optionCount), tostring(#themes()), bridge.LastError or "无", tostring(bridge.Options.wind_perf_tier and bridge.Options.wind_perf_tier.Value or defaultPerfTier), tostring(clampHz(bridge.VisualHz)), tostring(VISUAL_HZ_MAX), tostring(topbarConnection and "是" or "否")) .. ("\n自适应视觉: %s / FPS %d / 上限 %s")
                :format(tostring(adaptiveConnection ~= nil), adaptiveMeasured, tostring(bridge.AdaptiveVisualHz or "默认")) .. ("\n原生控件事件: %d / 丢弃过期事件: %d / 业务回调调用: %d\n最后控件事件: %s\n执行器: %s")
                :format(nativeEvents, nativeMismatch, callbackCalls, lastNativeEvent, tostring(env.VortexionExecutorName or "未上报"))
        end
        local function refreshDiagnostic() local value = bridge.GetDiagnostics(); diagnostic:SetDesc(value); return value end
        local probeCount = 0
        -- A native user-gesture probe, not a programmatic SetValue test.
        -- Tap this toggle manually, then refresh diagnostics. If nativeEvents
        -- does not increase, the failure is upstream of the business modules.
        debugPage:AddToggle("wind_input_probe", {Title = "触控回调自检（手动切换）", Default = false,
            Callback = function(value)
                probeCount += 1
                bridge.UiProbeCount = probeCount
                bridge.UiProbeValue = value
                if probeCount > 1 then
                    warn("[Vortexion/UI-PROBE] toggle fired=" .. tostring(probeCount) .. " value=" .. tostring(value))
                end
            end})
        debugPage:AddButton({Title = "显示触控回调自检", Callback = function()
            local stateText = ("收到 %d 次自检回调；原生事件 %d 次；最近事件 %s")
                :format(probeCount, nativeEvents, lastNativeEvent)
            bridge:Notify({Title = "输入链路自检", Content = stateText, Duration = 8})
            refreshDiagnostic()
        end})
        debugPage:AddButton({Title = "刷新诊断", Callback = refreshDiagnostic})
        debugPage:AddButton({Title = "打印诊断", Callback = function() print(refreshDiagnostic()) end})
        debugPage:AddButton({Title = "复制诊断", Callback = function()
            local clipboard = setclipboard or toclipboard or env.setclipboard or env.toclipboard
            if type(clipboard) == "function" then clipboard(refreshDiagnostic()) else bridge:Notify("剪贴板未挂载", refreshDiagnostic()) end
        end})
        debugPage:AddButton({Title = "测试通知", Callback = function() bridge:Notify("WindUI", "原生通知正常。") end})
        debugPage:AddButton({Title = "清除最近异常", Callback = function() bridge.LastError = nil; refreshDiagnostic() end})
        local status = configs:AddParagraph({Title = "原生配置", Content = "配置按 PlaceId 隔离；仅手动加载。"})
        if #missingFileApi > 0 or not native.ConfigManager then
            status:SetDesc("文件接口未齐备：" .. table.concat(missingFileApi, ", ") .. "。当前会话仍可使用全部界面与功能。")
            return
        end
        local manager, current, currentName = native.ConfigManager, nil, nil
        -- Native Load spawns a task per entry; protect the parser, not only Load.
        if type(manager.Parser) == 'table' then
            local parsers = {}
            for kind, parser in pairs(manager.Parser) do
                local protected = {}
                for key, value in pairs(parser) do protected[key] = value end
                if type(parser.Load) == 'function' then
                    protected.Load = function(element, data)
                        if not bridge.Active then return end
                        safeCallback(function()
                            assert(type(data) == 'table' and element and element.__type == kind and data.__type == kind, 'Config element type mismatch')
                            local value = data.value
                            if kind == 'Slider' then
                                local n = tonumber(value)
                                assert(n and n == n and math.abs(n) < math.huge, 'Config requires a finite slider value')
                            elseif kind == 'Toggle' then
                                assert(type(value) == 'boolean', 'Config requires a boolean toggle value')
                            elseif kind == 'Input' then
                                assert(type(value) == 'string', 'Config requires a string input value')
                            elseif kind == 'Colorpicker' then
                                assert(type(value) == 'string', 'Config requires a six-digit color hex value')
                                local hex = value:gsub('^#', '')
                                assert(#hex == 6 and hex:match('^%x+$'), 'Config requires a six-digit color hex value')
                                -- Native Colorpicker.Load only updates its swatch; route through the bridge to sync business state.
                                local color = colorValue(Color3.fromHex(hex))
                                for _, option in pairs(bridge.Options) do
                                    if option.Native == element then option:SetValue(color); return end
                                end
                                error('Config color control is not owned by this bridge')
                            elseif kind == 'Dropdown' then
                                local t = type(value)
                                assert(value == nil or t == 'table' or t == 'string' or t == 'number', 'Config requires a dropdown value')
                            end
                            parser.Load(element, data)
                        end)
                    end
                end
                parsers[kind] = protected
            end
            manager.Parser = parsers
        end
        configs:AddInput("wind_config_name", {Title = "配置名称", Default = "default"})
        local listed, initialFiles = pcall(function()
            local files = manager:AllConfigs()
            assert(type(files) == "table", "Config list must be a table")
            return files
        end)
        if not bridge.Active then return end
        if not listed then
            bridge.LastError = tostring(initialFiles)
            status:SetDesc("初始配置列表读取失败；当前会话仍可使用。")
            bridge:Notify("配置读取异常", string.sub(tostring(initialFiles), 1, 500), 8)
            initialFiles = {}
        end
        local selection = configs:AddDropdown("wind_config_files", {Title = "已有配置", Values = initialFiles, Callback = function(v) if v then bridge.Options.wind_config_name:SetValue(v) end end})
        local function refreshFiles()
            if not bridge.Active then return end
            local files = manager:AllConfigs()
            if not bridge.Active then return end
            assert(type(files) == 'table', 'Config list must be a table')
            selection:SetValues(files)
        end
        local function getConfig()
            if not bridge.Active then return end
            local name = bridge.Options.wind_config_name.Value
            assert(name ~= "" and not string.find(name, "[^%w_%-]"), "Config name must contain letters, digits, _ or -")
            local candidate = current
            if not candidate or currentName ~= name then
                candidate = manager:CreateConfig(name, false)
                if not bridge.Active then
                    -- CreateConfig retains native references before returning.
                    if type(candidate) == 'table' then candidate.Load = function() return {} end end
                    return
                end
                assert(type(candidate) == 'table', 'Config creation must return a config')
                local load = candidate.Load
                assert(type(load) == 'function', 'Config load method missing')
                -- Legacy autoload remains blocked even while an explicit load yields.
                candidate.Load = function() return {} end
                candidate.ManualLoad = function(self)
                    if not bridge.Active then return {} end
                    local ok, result, err = pcall(load, self)
                    if not bridge.Active then return {} end
                    assert(ok and result ~= false, err or result)
                    return result
                end
                candidate:SetAutoLoad(false)
                if not bridge.Active then return end
            end
            for id, option in pairs(bridge.Options) do
                candidate:Register(id, option.Native)
                if not bridge.Active then return end
            end
            candidate:SetAsCurrent()
            if not bridge.Active then return end
            -- Publish only the fully prepared bridge handle; native creation publishes earlier.
            current, currentName = candidate, name
            bridge.Config = candidate
            return candidate
        end
        local configBusy = false
        local function configButton(title, callback, locked)
            configs:AddButton({Title = title, Locked = locked, Callback = function()
                if configBusy then bridge:Notify('配置操作进行中', '当前操作完成后可再次操作。'); return end
                configBusy = true
                local ok, err = pcall(callback)
                configBusy = false
                if not ok then error(err, 0) end
            end})
        end
        configButton("创建 / 选定配置", function()
            if not getConfig() then return end
            status:SetDesc("已选定配置；当前设置未自动覆盖或加载。")
            refreshFiles()
        end)
        configButton("保存配置", function()
            local c = getConfig(); if not c then return end
            c:SetAutoLoad(false); if not bridge.Active then return end
            local result, err = c:Save(); if not bridge.Active then return end
            assert(result ~= false, err or 'Config save failed')
            refreshFiles()
            if bridge.Active then status:SetDesc("配置已保存。") end
        end)
        configButton("加载配置", function()
            local c = getConfig(); if not c then return end
            c:ManualLoad()
            if bridge.Active then status:SetDesc("已提交原生加载；控件回调将同步业务状态。") end
        end)
        configButton("刷新文件列表", refreshFiles)
        configButton("删除配置", function()
            if type(fileApi.delfile) ~= "function" then status:SetDesc("delfile 未挂载。"); return end
            local c = getConfig(); if not c then return end
            local ok, err = c:Delete(); if not bridge.Active then return end
            assert(ok, err); current = nil; bridge.Config = nil
            refreshFiles()
            if bridge.Active then status:SetDesc("配置已删除。") end
        end, type(fileApi.delfile) ~= "function")
        if type(fileApi.delfile) ~= "function" then configs:AddParagraph({Title = "删除接口未挂载", Content = "保存与加载仍可使用；删除按钮已锁定。"}) end
    end

    function bridge:FitViewport()
        if not self.Active or not native or not self.AutoFit or native.IsFullscreen then
            cancelOwnedCenter()  -- deactivated / auto-fit off / fullscreen / no window: stop any in-flight owned centering tail
            lastLayout = nil      -- drop the coalescing cache so a later re-activation re-runs instead of trusting a stale layout
            return
        end
        layoutRevision += 1
        local revision = layoutRevision
        local camera = world.CurrentCamera
        if not camera then cancelOwnedCenter(); lastLayout = nil; return end
        local view, size = camera.ViewportSize, native.Size
        local width, height, sizeX, sizeY = view.X, view.Y, size.X.Offset, size.Y.Offset
        local function finiteExtent(value, minimum)
            return type(value) == "number" and value == value and value > minimum and value < math.huge
        end
        if not finiteExtent(width, 40) or not finiteExtent(height, 40) or not finiteExtent(sizeX, 0) or not finiteExtent(sizeY, 0) then
            cancelOwnedCenter(); lastLayout = nil; return
        end
        local function currentLayout()
            if not self.Active or not self.AutoFit or native.IsFullscreen or revision ~= layoutRevision then return false end
            if world.CurrentCamera ~= camera then requestLayout(); return false end
            local currentView, currentSize = camera.ViewportSize, native.Size
            if currentView.X ~= width or currentView.Y ~= height or currentSize.X.Offset ~= sizeX or currentSize.Y.Offset ~= sizeY then
                requestLayout()
                return false
            end
            return true
        end
        -- Safe-area rectangle: read the real GuiService:GetGuiInset() topLeft/bottomRight Vector2 pair inside one pcall.
        -- Vector2 is a Roblox userdata; we only touch .X/.Y and never type-check it as a table. The pcall flattens the
        -- pair into left, top, right, bottom (topLeft.X=left, topLeft.Y=top, bottomRight.X=right, bottomRight.Y=bottom);
        -- keep only finite, non-negative, bounded values, defaulting any bad axis to 0.
        local topInset, bottomInset, leftInset, rightInset = 0, 0, 0, 0
        if self.SafeArea then
            local okGui, gui = pcall(function() return game:GetService("GuiService") end)
            if okGui and gui then
                local okInset, left, top, right, bottom = pcall(function()
                    local topLeft, bottomRight = gui:GetGuiInset()
                    return topLeft.X, topLeft.Y, bottomRight.X, bottomRight.Y
                end)
                if okInset then
                    local function clampInset(v)
                        if tonumber(v) and v == v and math.abs(v) ~= math.huge then return math.clamp(math.floor(v + 0.5), 0, 4096) end
                        return nil
                    end
                    leftInset = clampInset(left) or 0
                    topInset = clampInset(top) or 0
                    rightInset = clampInset(right) or 0
                    bottomInset = clampInset(bottom) or 0
                end
            end
        end
        local safeActive = self.SafeArea and (topInset + bottomInset + leftInset + rightInset > 0)
        -- Usable box drops by the real insets when the safe area is active; otherwise keep the classic 40px margin. Never below a 40px floor.
        local marginX = safeActive and (leftInset + rightInset) or 40
        local marginY = safeActive and (topInset + bottomInset) or 40
        local availWidth = math.max(width - marginX, 40)
        local availHeight = math.max(height - marginY, 40)
        -- Center within the safe rectangle: offset = (left-right)/2 on X, (top-bottom)/2 on Y.
        local offsetX = safeActive and math.floor((leftInset - rightInset) / 2) or 0
        local offsetY = safeActive and math.floor((topInset - bottomInset) / 2) or 0
        -- Round down so control precision never expands beyond the viewport.
        local factor = math.clamp(math.floor(math.min(availWidth / sizeX, availHeight / sizeY) * 100 + 1e-6) / 100, 0.1, 1)
        -- Optional mobile readability floor: raise the minimum scale for legibility. This can overflow the viewport, so it is a legibility-over-completeness trade-off, not a reachability guarantee.
        if self.ReadabilityGuard then
            local minScale = self.Options.wind_min_scale and tonumber(self.Options.wind_min_scale.Value)
            if minScale and minScale == minScale then factor = math.max(factor, math.clamp(minScale, 0.1, 1)) end
        end
        local changed = self.Options.wind_scale.Value ~= factor
        if changed then self.Options.wind_scale:SetValue(factor) end
        if not currentLayout() then return end
        if changed or not lastLayout or lastLayout[1] ~= width or lastLayout[2] ~= height or lastLayout[3] ~= sizeX or lastLayout[4] ~= sizeY
            or lastLayout[5] ~= topInset or lastLayout[6] ~= bottomInset or lastLayout[7] ~= leftInset or lastLayout[8] ~= rightInset or lastLayout[9] ~= camera then
            if safeActive then
                -- Controlled centering: tween Main to the safe-rectangle target so the vendor's fixed center tween cannot clobber the offset. Every degrade path (Create/Play failure) cancels the prior owned tween first, otherwise its tail frame overwrites the fallback; a missing Main cancels and defers without caching an unfinished layout.
                local main = native.UIElements and native.UIElements.Main
                if main then
                    local goal = UDim2.new(0.5, offsetX, 0.5, offsetY)
                    local tween
                    local okTs, ts = pcall(function() return game:GetService("TweenService") end)
                    if okTs and ts then
                        local okCreate, created = pcall(function()
                            return ts:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = goal})
                        end)
                        if okCreate then tween = created end
                    end
                    if tween then
                        if centerTween and centerTween ~= tween then pcall(function() centerTween:Cancel() end) end
                        centerTween = tween
                        local okPlay = pcall(function() tween:Play() end)
                        if not okPlay then
                            pcall(function() centerTween:Cancel() end); centerTween = nil
                            main.Position = goal
                        end
                    else
                        if centerTween then pcall(function() centerTween:Cancel() end); centerTween = nil end
                        main.Position = goal
                    end
                else
                    if centerTween then pcall(function() centerTween:Cancel() end); centerTween = nil end
                    return
                end
            else
                if centerTween then pcall(function() centerTween:Cancel() end); centerTween = nil end
                native:SetToTheCenter()
            end
            -- Only a completed, current layout may update the coalescing cache (insets + camera identity included so an inset-only change re-centers even when the quantized scale is unchanged).
            if currentLayout() then lastLayout = {width, height, sizeX, sizeY, topInset, bottomInset, leftInset, rightInset, camera} end
        end
    end

    function bridge:CreateWindow(info)
        if windowHandle then return windowHandle end
        if not self.Active then return nil end
        -- WindUI reads CurrentCamera before its optional AutoScale branch.
        local deadline = os.clock() + 5
        while not world.CurrentCamera and self.Active and os.clock() < deadline do task.wait(0.05) end
        if not self.Active then return nil end
        assert(world.CurrentCamera, "WindUI initialization requires an available CurrentCamera")
        info = info or {}
        local existingWindow = WindUI.Window
        local cancelled, acquired = false, false
        local creationPhase = "vendor-constructor"
        local initialized, result = pcall(function()
            -- xpcall must surround the vendor call itself. A later outer pcall only
            -- reports the calling game module's CreateWindow line, not the actual
            -- vendor function and property assignment which failed.
            local function vendorTrace(err)
                local message = tostring(err)
                if type(debug) == "table" and type(debug.traceback) == "function" then
                    local okTrace, frames = pcall(debug.traceback, message, 2)
                    if okTrace and type(frames) == "string" then return frames end
                end
                -- Roblox Luau commonly exposes debug.info rather than debug.traceback.
                -- Inspect the stack while xpcall's error handler is still running;
                -- once the game entry catches it, the internal vendor frames are gone.
                if type(debug) == "table" and type(debug.info) == "function" then
                    local frames = {}
                    for level = 2, 12 do
                        local okFrame, source, line, name = pcall(debug.info, level, "sln")
                        if not okFrame or source == nil then break end
                        frames[#frames + 1] = tostring(source) .. ":" .. tostring(line) .. " " .. tostring(name or "")
                    end
                    if #frames > 0 then return message .. "\nVendor frames:\n" .. table.concat(frames, "\n") end
                end
                return message
            end
            local vendorOK, vendorValue = xpcall(function()
                return WindUI:CreateWindow({Title = info.Title or appName, Author = "- Vortexion", Folder = #missingFileApi == 0 and ((config.Folder or appName) .. "/" .. tostring(game.PlaceId)) or nil, Theme = config.Theme or "Dark", Size = info.Size or UDim2.fromOffset(650, 490), ToggleKey = Enum.KeyCode.K, Background = "", Acrylic = not input.TouchEnabled, Transparent = false, AutoScale = false, SideBarWidth = input.TouchEnabled and 160 or 200})
            end, vendorTrace)
            if not vendorOK then error("WindUI vendor constructor: " .. tostring(vendorValue), 0) end
            native = vendorValue
            assert(native, "WindUI CreateWindow returned no window")
            if not self.Active then cancelled = true; return nil end
            acquired = true
            creationPhase = "window-theme"
            self.GUI = WindUI.ScreenGui
            native.Debug = config.Debug == true
            local themeOK, themeErr = pcall(function() WindUI:SetTheme(config.Theme or "Dark") end)
            if not themeOK then
                self.LastError = "Theme: " .. tostring(themeErr)
                warn("[Vortexion/Wind] " .. self.LastError)
            end
            if not originalToggleAcrylic and type(WindUI.ToggleAcrylic) == "function" then
                originalToggleAcrylic = WindUI.ToggleAcrylic
                WindUI.ToggleAcrylic = acrylicWrapper
            end
            native:OnDestroy(cleanup)
            local buttonOK, buttonErr = pcall(function()
                native:EditOpenButton({Title = appName, Enabled = true, Draggable = true, OnlyMobile = false})
            end)
            if not buttonOK then
                self.LastError = "OpenButton: " .. tostring(buttonErr)
                warn("[Vortexion/Wind] " .. self.LastError)
            end
            creationPhase = "section-creation"
            local groups = {Common = native:Section({Title = "通用", Opened = true}), Game = native:Section({Title = "游戏功能", Opened = true}), UI = native:Section({Title = "UI", Opened = false})}
            local win = {Native = native, Root = native.UIElements.Main, Groups = groups, GameTabs = self.GameTabs}
            function win:AddTab(c)
                local tab = wrapTab(groups.Game:Tab({Title = c.Title or "功能", Icon = c.Icon}))
                table.insert(bridge.GameTabs, tab); table.insert(bridge.Tabs, tab)
                return tab
            end
            function win:SelectTab(index)
                local tab = bridge.GameTabs[index]
                if bridge.Active and tab then groups.Game:Open(); tab.Native:Select() end
            end
            function win:Minimize() if bridge.Active then native:Toggle() end end
            function win:Destroy() bridge:Destroy() end
            function win:InstallSettings() end
            creationPhase = "common-features"
            local common = wrapTab(groups.Common:Tab({Title = "低延迟切服"}))
            local serverFactory = config.ServerSwitchFactory or ServerSwitchFactory
            if type(serverFactory) == "function" then
                local serverSwitch = serverFactory(common, function(message) bridge:Notify({Title = "低延迟切服", Content = message}) end)
                if not self.Active then
                    cancelled = true
                    if serverSwitch then safeCallback(function() serverSwitch:Stop() end) end
                    return nil
                end
                bridge.ServerSwitch = serverSwitch
            else common:AddParagraph({Title = "切服模块未加载", Content = "请检查构建是否包含 ServerSwitch。"}) end
            -- Shared optional runtime telemetry. Constructor failures never abort the game window.
            if type(RuntimeMonitorFactory) == "function" then
                local diagnosticsTab = wrapTab(groups.Common:Tab({Title = "性能诊断", Icon = "lucide-gauge"}))
                local okMonitor, monitor = pcall(RuntimeMonitorFactory, diagnosticsTab, bridge)
                if okMonitor and self.Active then
                    bridge.RuntimeMonitor = monitor
                elseif not okMonitor then
                    bridge.LastError = "RuntimeMonitor: " .. tostring(monitor)
                    warn("[Vortexion/Wind] " .. bridge.LastError)
                end
            end
            creationPhase = "settings"
            installSettings(groups)
            if not self.Active then cancelled = true; return nil end
            creationPhase = "viewport-events"
            local cameraConnection
            local function bindCamera()
                if cameraConnection then cameraConnection:Disconnect(); cameraConnection = nil end
                local camera = world.CurrentCamera
                if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(requestLayout) end
                requestLayout()
            end
            bridge:OnDestroy(function() if cameraConnection then cameraConnection:Disconnect(); cameraConnection = nil end end)
            table.insert(connections, world:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera))
            local root = native.UIElements.Main
            if root and type(root.GetPropertyChangedSignal) == "function" then
                table.insert(connections, root:GetPropertyChangedSignal("Size"):Connect(requestLayout))
            end
            for _, name in ipairs({'InputEnded', 'TextBoxFocusReleased', 'WindowFocusReleased'}) do
                local event = input[name]
                if event then table.insert(connections, event:Connect(flushSliders)) end
            end
            bindCamera()
            bridge:FitViewport()
            installTopbarInsetWatch()
            -- A synchronous-executor spawn (or a reentrant destroy raised inside the watch install) can tear the bridge
            -- down before the handle is published: never return a stale window or rewrite the handle cache.
            if not self.Active then cancelled = true; return nil end
            windowHandle = win
            return win
        end)
        if not initialized or cancelled then
            if not initialized then
                self.LastError = tostring(result)
                recordStartupFailure("CreateWindow", "[" .. creationPhase .. "] " .. tostring(result))
            elseif cancelled then
                recordStartupFailure("CreateWindow", "Bridge was cancelled during initialization")
            end
            local lateNative = not self.Active and ((cancelled and not acquired) or native == nil)
            if not existingWindow then native = native or WindUI.Window end
            self:Destroy()
            -- Destroy already ran before ownership arrived from the suspended constructor.
            if lateNative and native then safeCallback(function() native:Destroy() end) end
            -- The vendor allocates these before CreateWindow can return a handle.
            if not existingWindow then
                for _, key in ipairs({"ScreenGui", "NotificationGui", "DropdownGui", "TooltipGui"}) do
                    local gui = WindUI[key]
                    if gui then pcall(function() gui:Destroy() end) end
                end
                local signals = WindUI.Creator and WindUI.Creator.Signals
                if signals then
                    for _, connection in pairs(signals) do pcall(function() connection:Disconnect() end) end
                    table.clear(signals)
                end
                WindUI.Window = nil
            end
            windowHandle = nil
            if not initialized then error(result, 2) end
            return nil
        end
        return result
    end
    return bridge
end
