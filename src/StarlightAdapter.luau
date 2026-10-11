-- Vortexion - Forsaken: real Starlight API bridge for preserved v4 callbacks.
-- Existing stable option IDs are retained for mobile hotkeys and future config migration.
-- Called after the vendored Starlight Source.lua has been executed.
return function(Starlight)
    assert(Starlight and type(Starlight.CreateWindow) == "function", "Starlight UI missing")
    local input = game:GetService("UserInputService")
    local camera = workspace.CurrentCamera
    local bridge = { Options = {}, GUI = Starlight.Instance, Library = Starlight, Tabs = {} }
    local windowHandle
    local firstTab = nil
    local sections = {}
    local created = 0
    local scrollConns = {}
    local isTouch = input.TouchEnabled

    local function safeCallback(callback, value)
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback, value)
        if not ok then warn("[Forsaken/Starlight] 控件回调异常: " .. tostring(err)) end
    end

    local function clampFrame()
        local gui = Starlight.Instance
        local root = gui and gui:FindFirstChild("MainWindow")
        local cam = workspace.CurrentCamera
        if not root or not cam then return end
        local view = cam.ViewportSize
        local logical = root.Size
        if logical.X.Offset <= 0 or logical.Y.Offset <= 0 then return end
        local s = math.clamp(math.min((view.X - 16) / logical.X.Offset, (view.Y - 52) / logical.Y.Offset), 0.32, 1)
        local scale = root:FindFirstChild("ForsakenStarlightScale")
        if not scale then
            scale = Instance.new("UIScale")
            scale.Name = "ForsakenStarlightScale"
            scale.Parent = root
        end
        scale.Scale = isTouch and s or 1
        local width = logical.X.Offset * scale.Scale
        local height = logical.Y.Offset * scale.Scale
        root.Position = UDim2.fromOffset(math.max(4, math.floor((view.X - width) * 0.5)), math.max(25, math.floor((view.Y - height) * 0.5)))
    end

    -- Roblox’s Starlight template uses one ScrollingFrame per content column.
    -- Its stock implementation can disable scrolling at InputEnded, and bottom padding
    -- may not be counted after changing UIScale on a small viewport.
    local function repairScroll(contentTab)
        if not contentTab or not contentTab.Instances or not contentTab.Instances.Page then return end
        local page = contentTab.Instances.Page
        local scrollables = {page}
        for _, descendant in ipairs(page:GetDescendants()) do
            if descendant:IsA("ScrollingFrame") then table.insert(scrollables, descendant) end
        end
        -- Delay one frame for Starlight's asynchronously initialized groupboxes.
        for _, column in ipairs(scrollables) do
            if column:IsA("ScrollingFrame") then
                column.Active = true
                column.ScrollingEnabled = true
                column.ScrollingDirection = Enum.ScrollingDirection.Y
                if isTouch then
                    column.ScrollBarThickness = 5
                    column.ScrollingEnabled = true
                end
                local layout = column:FindFirstChildOfClass("UIListLayout")
                local refreshPending = false
                local function refresh()
                    refreshPending = false
                    if not column.Parent then return end
                    local content = layout and layout.AbsoluteContentSize.Y or 0
                    local needed = math.ceil(content + (isTouch and 62 or 30))
                    if column.CanvasSize.Y.Offset ~= needed then
                        column.CanvasSize = UDim2.new(0, 0, 0, needed)
                    end
                end
                local function scheduleRefresh()
                    if refreshPending then return end
                    refreshPending = true
                    task.defer(refresh)
                end
                if layout then
                    table.insert(scrollConns, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        scheduleRefresh()
                    end))
                end
                table.insert(scrollConns, column:GetPropertyChangedSignal("AbsoluteSize"):Connect(scheduleRefresh))
                scheduleRefresh()
            end
        end
    end

    function bridge:Notify(config)
        pcall(function()
            Starlight:Notification({Title = config.Title or "Forsaken", Content = config.Content or "", Duration = config.Duration or 4})
        end)
    end

    -- The project is Vortexion - Forsaken, but the window shows a clean two-level mark:
    -- "Forsaken" in the original title slot with a small grey "- Vortexion" below its right edge.
    -- Make this a child of the actual title label so mobile UIScale and window dragging
    -- cannot desynchronize the two text elements.
    local function attachBrandSignature()
        local gui = Starlight.Instance
        local main = gui and gui:FindFirstChild("MainWindow")
        local sidebar = main and main:FindFirstChild("Sidebar")
        local header = sidebar and sidebar:FindFirstChild("Header")
        if not (header and header:IsA("TextLabel")) then return false end
        header.Text = "Forsaken"
        header.ClipsDescendants = false
        local byline = header:FindFirstChild("VortexionSignature")
        if not byline then
            byline = Instance.new("TextLabel")
            byline.Name = "VortexionSignature"
            byline.AnchorPoint = Vector2.new(1, 0)
            -- Tucked towards the lower-right of the title, slightly inset to the left.
            byline.Position = UDim2.new(1, -12, 1, -3)
            byline.Size = UDim2.fromOffset(91, 13)
            byline.BackgroundTransparency = 1
            byline.BorderSizePixel = 0
            byline.Font = Enum.Font.Gotham
            byline.TextSize = 10
            byline.TextXAlignment = Enum.TextXAlignment.Right
            byline.TextYAlignment = Enum.TextYAlignment.Center
            byline.TextColor3 = Color3.fromRGB(177, 181, 189)
            byline.TextTransparency = 0.16
            byline.ZIndex = header.ZIndex + 1
            byline.Parent = header
        end
        byline.Text = "- Vortexion"
        byline.Visible = true
        return true
    end

    function bridge:CreateWindow(config)
        Starlight.WindowKeybind = "K"
        local native = Starlight:CreateWindow({
            Name = "Forsaken",
            Subtitle = "",
            LoadingEnabled = false,
            InterfaceAdvertisingPrompts = false,
            NotifyOnCallbackError = true,
            BuildWarnings = true,
            DefaultSize = UDim2.fromOffset(650, 490),
            FileSettings = {RootFolder = "ForsakenCN", ConfigFolder = "Configs", ThemeFolder = "Themes"},
        })
        -- Starlight's sidebar header is the only project-name slot; keep the
        -- byline out of the main content subtitle and fixed to the name itself.
        if not attachBrandSignature() then task.defer(attachBrandSignature) end
        local group = native:CreateTabSection("F O R S A K E N", true)
        local win = {Native = native, Root = Starlight.Instance.MainWindow, TabHolder = nil}
        function win:SelectTab(index)
            local item = bridge.Tabs[index]
            if item and item.Native and item.Native.Instances then
                local page = item.Native.Instances.Page
                local pages = Starlight.Instance.MainWindow.Content.ContentMain.Elements
                if page and pages then
                    local layout = pages:FindFirstChildOfClass("UIPageLayout")
                    if layout then layout:JumpTo(page) end
                end
            end
        end
        function win:Minimize()
            local gui = Starlight.Instance
            if not gui then return end
            local root = gui:FindFirstChild("MainWindow")
            if root then
                root.Visible = not root.Visible
                Starlight.Minimized = not root.Visible
                if gui:FindFirstChild("Drag") then gui.Drag.Visible = root.Visible end
            end
        end
        function win:AddTab(info)
            created += 1
            local idx = "goon_cn_tab_" .. tostring(created)
            local nativeTab = group:CreateTab({Name = info.Title or idx, Columns = isTouch and 1 or 2, Icon = ""}, idx)
            local handle = {Native = nativeTab, Key = idx, Title = info.Title, Count = 0, GroupCount = 0}
            local groupbox
            local function pickBox()
                -- Release the render thread periodically while building many mobile controls.
                if isTouch and handle.Count > 0 and handle.Count % 7 == 0 then
                    task.wait()
                end
                -- Split large lists into bounded groupboxes; avoid one enormous page hierarchy.
                if not groupbox or (handle.Count > 0 and handle.Count % 9 == 0) then
                    handle.GroupCount += 1
                    local name = handle.GroupCount == 1 and (info.Title .. " · 功能") or (info.Title .. " · 更多 " .. tostring(handle.GroupCount))
                    groupbox = nativeTab:CreateGroupbox({Name = name, Column = isTouch and 1 or (handle.GroupCount % 2 == 1 and 1 or 2), Style = 1}, idx .. "_group_" .. handle.GroupCount)
                    -- Starlight initializes Groupbox templates inside task.spawn.
                    -- Dropdowns initialize synchronously and will otherwise dereference nil.
                    local untilAt = os.clock() + 10
                    while (not groupbox.ParentingItem or not groupbox.Instance) and os.clock() < untilAt do
                        task.wait()
                    end
                    if not groupbox.ParentingItem then error("Starlight 分组初始化超时: " .. name) end
                end
                handle.Count += 1
                return groupbox, idx .. "_control_" .. handle.Count
            end
            local function registerOption(id, initial, nativeControl, builder)
                local option = {Value = initial, Native = nativeControl, ID = id}
                function option:SetValue(value)
                    option.Value = value
                    if option.Native and option.Native.Set then
                        local settings = builder(value)
                        -- Native Starlight Element:Set accepts a settings table, not a raw value.
                        local ok, err = pcall(function() option.Native:Set(settings) end)
                        if not ok then warn("[Starlight] 更新选项失败 " .. tostring(id) .. ": " .. tostring(err)) end
                    end
                end
                bridge.Options[id] = option
                return option
            end
            function handle:AddToggle(id, c)
                local box, key = pickBox()
                local option
                local function onChange(v)
                    if option then option.Value = not not v end
                    safeCallback(c.Callback, v)
                end
                local settings = {Name = c.Title, Tooltip = c.Description or "", CurrentValue = c.Default == true, Style = 2, Callback = onChange}
                local element = box:CreateToggle(settings, key)
                option = registerOption(id, c.Default == true, element, function(v)
                    return {Name = c.Title, Tooltip = c.Description or "", CurrentValue = v, Style = 2, Callback = onChange}
                end)
                -- Native Starlight toggle invokes its callback on initialization.
                return option
            end
            function handle:AddSlider(id, c)
                local box, key = pickBox()
                local default = math.clamp(tonumber(c.Default) or c.Min or 0, c.Min or 0, c.Max or 100)
                local option
                local function onChange(v)
                    if option then option.Value = v end
                    safeCallback(c.Callback, v)
                end
                local nativeControl = box:CreateSlider({Name=c.Title, Range={c.Min or 0,c.Max or 100}, Increment=10 ^ -(c.Rounding or 0), CurrentValue=default, Suffix=c.Suffix, Callback=onChange}, key)
                option = registerOption(id, default, nativeControl, function(v)
                    return {Name=c.Title, Range={c.Min or 0,c.Max or 100}, Increment=10 ^ -(c.Rounding or 0), CurrentValue=v, Suffix=c.Suffix, Callback=onChange}
                end)
                -- Native Starlight slider invokes its callback on initialization.
                return option
            end
            function handle:AddButton(c)
                local box, key = pickBox()
                return box:CreateButton({Name=c.Title, Style=2, Tooltip=c.Description or "", Callback=function() safeCallback(c.Callback) end}, key)
            end
            function handle:AddInput(id, c)
                local box,key=pickBox()
                local default = tostring(c.Default or "")
                local option
                local function changed(v)
                    if option then option.Value = v end
                    safeCallback(c.Callback, v)
                end
                local element=box:CreateInput({Name=c.Title, CurrentValue=default, PlaceholderText=c.Placeholder or "", Numeric=c.Numeric or false, RemoveTextOnFocus=false, RemoveTextAfterFocusLost=false, Callback=changed},key)
                option=registerOption(id,default,element,function(v)
                    return {Name=c.Title, CurrentValue=tostring(v), PlaceholderText=c.Placeholder or "", Numeric=c.Numeric or false, RemoveTextOnFocus=false, RemoveTextAfterFocusLost=false, Callback=changed}
                end)
                return option
            end
            function handle:AddDropdown(id,c)
                local box,key=pickBox()
                local vals = c.Values or {}
                local chosen = type(c.Default)=="number" and vals[c.Default] or c.Default or vals[1]
                local option
                local function changed(v)
                    if type(v)=="table" and not c.Multi then v=v[1] end
                    if option then option.Value=v end
                    safeCallback(c.Callback,v)
                end
                local element = box:CreateDropdown({Name=c.Title, Options=vals, CurrentOption={chosen}, MultipleOptions=c.Multi or false, Callback=changed})
                option=registerOption(id,chosen,element,function(v)
                    return {Name=c.Title, Options=vals, CurrentOption=type(v)=="table" and v or {v}, MultipleOptions=c.Multi or false, Callback=changed}
                end)
                return option
            end
            function handle:AddParagraph(c)
                local box,key=pickBox()
                return box:CreateParagraph({Name=c.Title or "说明",Content=c.Content or ""},key)
            end
            bridge.Tabs[created] = handle
            task.defer(function() repairScroll(nativeTab) end)
            return handle
        end
        function win:InstallSettings(tab)
            -- Native Starlight built-ins: config + theme controls, no Fluent add-ons.
            if not tab or not tab.Native then return end
            pcall(function() tab.Native:BuildThemeGroupbox(1,1,true) end)
            pcall(function() tab.Native:BuildConfigGroupbox(1,1,true) end)
        end
        windowHandle = win
        task.defer(clampFrame)
        if camera then table.insert(scrollConns, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() task.defer(clampFrame) end)) end
        return win
    end
    function bridge:Destroy()
        for _, c in ipairs(scrollConns) do pcall(function() c:Disconnect() end) end
        pcall(function() Starlight:Destroy() end)
    end
    bridge.Window = function() return windowHandle end
    return bridge
end
