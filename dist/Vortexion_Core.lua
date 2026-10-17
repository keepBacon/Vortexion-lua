-- Vortexion Neverlose - generated offline; publishing must be performed separately.
-- Neverlose attribution is retained in vendor/Neverlose/README.md.
-- Forsaken retains runtime model rbxassetid://132866968194043.
-- Modify src/*.luau and run python3 build.py; do not edit this output.
local client = (getgenv and getgenv()) or _G
local previousBridge = client.VortexionWindBridge
if type(previousBridge) == "table" and type(previousBridge.Destroy) == "function" then
    local ok, err = pcall(function() previousBridge:Destroy() end)
    if not ok then warn("[Vortexion/UI] Previous UI cleanup: " .. tostring(err)) end
    if client.VortexionWindBridge == previousBridge then client.VortexionWindBridge = nil end
    task.wait(0.5)
end
local WindUI = (function()
local Library do
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")

    gethui = gethui or function()
        return CoreGui
    end

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()

    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV
    local FromHex = Color3.fromHex

    local RGBSequence = ColorSequence.new
    local RGBSequenceKeypoint = ColorSequenceKeypoint.new
    local NumSequence = NumberSequence.new
    local NumSequenceKeypoint = NumberSequenceKeypoint.new

    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local UDim2FromOffset = UDim2.fromOffset
    local Vector2New = Vector2.new
    local Vector3New = Vector3.new

    local MathClamp = math.clamp
    local MathFloor = math.floor
    local MathAbs = math.abs
    local MathSin = math.sin

    local TableInsert = table.insert
    local TableFind = table.find
    local TableRemove = table.remove
    local TableConcat = table.concat
    local TableClone = table.clone
    local TableUnpack = table.unpack

    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub
    local StringLower = string.lower
    local StringLen = string.len

    local InstanceNew = Instance.new

    local RectNew = Rect.new

    local IsMobile = UserInputService.TouchEnabled or false

    Library = {
        Theme =  { },
        ToClean = { },

        MenuKeybind = tostring(Enum.KeyCode.Insert),

        Flags = { },

        Tween = {
            Time = IsMobile and 0.12 or 0.2,
            Style = Enum.EasingStyle.Quad,
            Direction = Enum.EasingDirection.Out
        },

        FadeSpeed = IsMobile and 0.12 or 0.18,

        Folders = {
            Directory = "Vortexion",
            Configs = "Vortexion/NeverloseConfigs",
            Assets = "Vortexion/NeverloseAssets",
        },

        -- Ignore below
        Pages = { },
        Sections = { },

        Connections = { },
        Threads = { },

        ThemeMap = { },
        ThemeItems = { },

        OpenFrames = { },

        SetFlags = { },

        UnnamedConnections = 0,
        UnnamedFlags = 0,

        Holder = nil,
        NotifHolder = nil,
        UnusedHolder = nil,

        Font = nil
    }

    Library.__index = Library
    Library.Sections.__index = Library.Sections
    Library.Pages.__index = Library.Pages

    local Keys = {
        ["Unknown"]           = "Unknown",
        ["Backspace"]         = "Back",
        ["Tab"]               = "Tab",
        ["Clear"]             = "Clear",
        ["Return"]            = "Return",
        ["Pause"]             = "Pause",
        ["Escape"]            = "Escape",
        ["Space"]             = "Space",
        ["QuotedDouble"]      = '"',
        ["Hash"]              = "#",
        ["Dollar"]            = "$",
        ["Percent"]           = "%",
        ["Ampersand"]         = "&",
        ["Quote"]             = "'",
        ["LeftParenthesis"]   = "(",
        ["RightParenthesis"]  = " )",
        ["Asterisk"]          = "*",
        ["Plus"]              = "+",
        ["Comma"]             = ",",
        ["Minus"]             = "-",
        ["Period"]            = ".",
        ["Slash"]             = "`",
        ["Three"]             = "3",
        ["Seven"]             = "7",
        ["Eight"]             = "8",
        ["Colon"]             = ":",
        ["Semicolon"]         = ";",
        ["LessThan"]          = "<",
        ["GreaterThan"]       = ">",
        ["Question"]          = "?",
        ["Equals"]            = "=",
        ["At"]                = "@",
        ["LeftBracket"]       = "LeftBracket",
        ["RightBracket"]      = "RightBracked",
        ["BackSlash"]         = "BackSlash",
        ["Caret"]             = "^",
        ["Underscore"]        = "_",
        ["Backquote"]         = "`",
        ["LeftCurly"]         = "{",
        ["Pipe"]              = "|",
        ["RightCurly"]        = "}",
        ["Tilde"]             = "~",
        ["Delete"]            = "Delete",
        ["End"]               = "End",
        ["KeypadZero"]        = "Keypad0",
        ["KeypadOne"]         = "Keypad1",
        ["KeypadTwo"]         = "Keypad2",
        ["KeypadThree"]       = "Keypad3",
        ["KeypadFour"]        = "Keypad4",
        ["KeypadFive"]        = "Keypad5",
        ["KeypadSix"]         = "Keypad6",
        ["KeypadSeven"]       = "Keypad7",
        ["KeypadEight"]       = "Keypad8",
        ["KeypadNine"]        = "Keypad9",
        ["KeypadPeriod"]      = "KeypadP",
        ["KeypadDivide"]      = "KeypadD",
        ["KeypadMultiply"]    = "KeypadM",
        ["KeypadMinus"]       = "KeypadM",
        ["KeypadPlus"]        = "KeypadP",
        ["KeypadEnter"]       = "KeypadE",
        ["KeypadEquals"]      = "KeypadE",
        ["Insert"]            = "Insert",
        ["Home"]              = "Home",
        ["PageUp"]            = "PageUp",
        ["PageDown"]          = "PageDown",
        ["RightShift"]        = "RightShift",
        ["LeftShift"]         = "LeftShift",
        ["RightControl"]      = "RightControl",
        ["LeftControl"]       = "LeftControl",
        ["LeftAlt"]           = "LeftAlt",
        ["RightAlt"]          = "RightAlt"
    }

    local Themes = {
        ["Preset"] = {
            ["AccentGradient"] = FromRGB(106, 210, 218),   -- Slightly deeper blue accent
            ["Background 2"] = FromRGB(10, 14, 16),      -- Very dark gray
            ["Background"] = FromRGB(15, 21, 24),        -- Main near-black background
            ["Text"] = FromRGB(228, 236, 239),           -- Slightly dimmed light text
            ["Outline"] = FromRGB(33, 42, 46),           -- Subtle outline, almost invisible
            ["Section Top"] = FromRGB(25, 34, 37),       -- Dark section header
            ["Section Background"] = FromRGB(12, 17, 19),-- Deep black section background
            ["Section Background 2"] = FromRGB(17, 23, 25),-- Alternate section, minimal difference
            ["Accent"] = FromRGB(66, 173, 190),           -- Darker blue accent for consistency
            ["Element"] = FromRGB(21, 28, 31)            -- Deep gray for UI elements
        }
    }

    Library.Theme = TableClone(Themes["Preset"])

    -- Folders are optional on mobile executors (do not block UI startup).
    for _, path in Library.Folders do
        if type(isfolder) == "function" and type(makefolder) == "function" then
            local ok, present = pcall(isfolder, path)
            if ok and not present then pcall(makefolder, path) end
        end
    end

    -- Tweening
    local Tween = { } do
        Tween.__index = Tween

        Tween.Create = function(self, Item, Info, Goal, IsRawItem)
            Item = IsRawItem and Item or Item.Instance
            Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()

            setmetatable(NewTween, Tween)

            return NewTween
        end

        Tween.GetProperty = function(self, Item)
            Item = Item or self.Item

            if Item:IsA("Frame") then
                return { "BackgroundTransparency" }
            elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
                return { "BackgroundTransparency", "ImageTransparency" }
            elseif Item:IsA("ScrollingFrame") then
                return { "BackgroundTransparency", "ScrollBarImageTransparency" }
            elseif Item:IsA("TextBox") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("UIStroke") then
                return { "Transparency" }
            end
        end

        Tween.FadeItem = function(self, Item, Property, Visibility, Speed)
            local Item = Item or self.Item

            local OldTransparency = Item[Property]
            Item[Property] = Visibility and 1 or OldTransparency

            local NewTween = Tween:Create(Item, TweenInfo.new(Speed or Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction), {
                [Property] = Visibility and OldTransparency or 1
            }, true)

            Library:Connect(NewTween.Tween.Completed, function()
                if not Visibility then
                    task.wait()
                    Item[Property] = OldTransparency
                end
            end)

            return NewTween
        end

        Tween.Get = function(self)
            if not self.Tween then
                return
            end

            return self.Tween, self.Info, self.Goal
        end

        Tween.Pause = function(self)
            if not self.Tween then
                return
            end

            self.Tween:Pause()
        end

        Tween.Play = function(self)
            if not self.Tween then
                return
            end

            self.Tween:Play()
        end

        Tween.Clean = function(self)
            if not self.Tween then
                return
            end

            Tween:Pause()
            self = nil
        end
    end

    -- Instances
    local Instances = { } do
        Instances.__index = Instances

        Instances.Create = function(self, Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }

            setmetatable(NewItem, Instances)

            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end

            return NewItem
        end

        Instances.FadeItem = function(self, Visibility, Speed)
            local Item = self.Instance

            if Visibility == true then
                Item.Visible = true
            end

            local Descendants = Item:GetDescendants()
            TableInsert(Descendants, Item)

            local NewTween

            for Index, Value in Descendants do
                local TransparencyProperty = Tween:GetProperty(Value)

                if not TransparencyProperty then
                    continue
                end

                if type(TransparencyProperty) == "table" then
                    for _, Property in TransparencyProperty do
                        NewTween = Tween:FadeItem(Value, Property, not Visibility, Speed)
                    end
                else
                    NewTween = Tween:FadeItem(Value, TransparencyProperty, not Visibility, Speed)
                end
            end
        end

        Instances.AddToTheme = function(self, Properties)
            if not self.Instance then
                return
            end

            Library:AddToTheme(self, Properties)
        end

        Instances.ChangeItemTheme = function(self, Properties)
            if not self.Instance then
                return
            end

            Library:ChangeItemTheme(self, Properties)
        end

        Instances.Connect = function(self, Event, Callback, Name)
            if not self.Instance then
                return
            end

            if not self.Instance[Event] then
                return
            end

            if IsMobile then
                if Event == "MouseButton1Down" or Event == "MouseButton1Click" then
                    Event = "TouchTap"
                elseif Event == "MouseButton2Down" or Event == "MouseButton2Click" then
                    Event = "TouchLongPress"
                end
            end

            return Library:Connect(self.Instance[Event], Callback, Name)
        end

        Instances.Tween = function(self, Info, Goal)
            if not self.Instance then
                return
            end

            return Tween:Create(self, Info, Goal)
        end

        Instances.Disconnect = function(self, Name)
            if not self.Instance then
                return
            end

            return Library:Disconnect(Name)
        end

        Instances.Clean = function(self)
            if not self.Instance then
                return
            end

            self.Instance:Destroy()
            self = nil
        end

        Instances.MakeDraggable = function(self)
            if not self.Instance then
                return
            end

            local Gui = self.Instance
            local Dragging = false
            local DragStart
            local StartPosition

            local Set = function(Input)
                local DragDelta = Input.Position - DragStart
                local NewX = StartPosition.X.Offset + DragDelta.X
                local NewY = StartPosition.Y.Offset + DragDelta.Y
                self:Tween(TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2New(StartPosition.X.Scale, NewX, StartPosition.Y.Scale, NewY)
                })
            end

            local InputChanged

            self:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    DragStart = Input.Position
                    StartPosition = Gui.Position

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false
                            if InputChanged then
                                InputChanged:Disconnect()
                                InputChanged = nil
                            end
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dragging then
                        Set(Input)
                    end
                end
            end)

            return Dragging
        end

        Instances.MakeResizeable = function(self, Minimum, Maximum, Window)
            if not self.Instance then
                return
            end

            local Gui = self.Instance

            local Resizing = false
            local CurrentSide = nil

            local StartMouse = nil
            local StartPosition = nil
            local StartSize = nil

            local EdgeThickness = 2

            local MakeEdge = function(Name, Position, Size)
                local Button = Instances:Create("TextButton", {
                    Name = "\0",
                    Size = Size,
                    Position = Position,
                    BackgroundColor3 = FromRGB(166, 147, 243),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Parent = Gui,
                    ZIndex = 99999,
                })  Button:AddToTheme({BackgroundColor3 = "Accent"})

                return Button
            end

            local Edges = {
                {Button = MakeEdge(
                    "Left",
                    UDim2New(0, 0, 0, 0),
                    UDim2New(0, EdgeThickness, 1, 0)),
                    Side = "L"
                },

                {Button = MakeEdge(
                    "Right",
                    UDim2New(1, -EdgeThickness, 0, 0),
                    UDim2New(0, EdgeThickness, 1, 0)),
                    Side = "R"
                },

                {Button = MakeEdge(
                    "Top", UDim2New(0, 0, 0, 0),
                    UDim2New(1, 0, 0, EdgeThickness)),
                    Side = "T"
                },

                {Button = MakeEdge(
                    "Bottom",
                    UDim2New(0, 0, 1, -EdgeThickness),
                    UDim2New(1, 0, 0, EdgeThickness)),
                    Side = "B"
                },
            }

            local BeginResizing = function(Side)
                Resizing = true
                CurrentSide = Side

                StartMouse = UserInputService:GetMouseLocation()

                -- store offsets, not absolute screen pos
                StartPosition = Vector2New(Gui.Position.X.Offset, Gui.Position.Y.Offset)
                StartSize = Vector2New(Gui.Size.X.Offset, Gui.Size.Y.Offset)

                for Index, Value in Edges do
                    Value.Button:Tween(nil, {BackgroundTransparency = (Value.Side == Side) and 0 or 1})
                end
            end

            local EndResizing = function()
                Resizing = false
                CurrentSide = nil

                for Index, Value in Edges do
                    Value.Button.Instance.BackgroundTransparency = 1
                end
            end

            for Index, Value in Edges do
                Value.Button:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        BeginResizing(Value.Side)
                    end
                end)
            end

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if Resizing then
                        EndResizing()
                    end
                end
            end)

            Library:Connect(RunService.RenderStepped, function()
                if not Resizing or not CurrentSide then
                    return
                end

                local MouseLocation = UserInputService:GetMouseLocation()
                local dx = MouseLocation.X - StartMouse.X
                local dy = MouseLocation.Y - StartMouse.Y

                local x, y = StartPosition.X, StartPosition.Y
                local w, h = StartSize.X, StartSize.Y

                if CurrentSide == "L" then
                    x = StartPosition.X + dx
                    w = StartSize.X - dx

                    if Window then
                        Window.Left.Y = h
                    end
                elseif CurrentSide == "R" then
                    w = StartSize.X + dx

                    if Window then
                        Window.Right.Y = h
                    end
                elseif CurrentSide == "T" then
                    y = StartPosition.Y + dy
                    h = StartSize.Y - dy

                    if Window then
                        Window.Top.X = w
                    end
                elseif CurrentSide == "B" then
                    h = StartSize.Y + dy

                    if Window then
                        Window.Bottom.X = w
                    end
                end

                if w < Minimum.X then
                    if CurrentSide == "L" then
                        x = x - (Minimum.X - w)
                    end
                    w = Minimum.X
                end
                if h < Minimum.Y then
                    if CurrentSide == "T" then
                        y = y - (Minimum.Y - h)
                    end
                    h = Minimum.Y
                end

                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2FromOffset(x, y)})
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2FromOffset(w, h)})
            end)
        end

        Instances.OnHover = function(self, Function)
            if not self.Instance then
                return
            end

            return Library:Connect(self.Instance.MouseEnter, Function)
        end

        Instances.OnHoverLeave = function(self, Function)
            if not self.Instance then
                return
            end

            return Library:Connect(self.Instance.MouseLeave, Function)
        end
    end

    -- Custom font
    local CustomFont = { } do
        function CustomFont:New(Name, Weight, Style, Data)
            if not isfile(Data.Id) then
                writefile(Data.Id, game:HttpGet(Data.Url))
            end

            local Data = {
                name = Name,
                faces = {
                    {
                        name = Name,
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Data.Id)
                    }
                }
            }

            writefile(`{Library.Folders.Assets}/{Name}.font`, HttpService:JSONEncode(Data))
            return getcustomasset(`{Library.Folders.Assets}/{Name}.font`)
        end

        local SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

        local Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

        local Light = Font.new("rbxassetid://12187365364", Enum.FontWeight.Light, Enum.FontStyle.Normal)

        Library.Fonts = {
            ["SemiBold"] = SemiBold,
            ["Regular"] = Regular,
            ["Light"] = Light
        }

        Library.Font = SemiBold
    end

    Library.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "VortexionNeverlose",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 10000,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    })

    Library.UnusedHolder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
        ResetOnSpawn = false
    })

    Library.NotifHolder  = Instances:Create("Frame", {
        Parent = Library.Holder.Instance,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = UDim2New(0, 0, 1, 0),
        BorderColor3 = FromRGB(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = FromRGB(255, 255, 255)
    })

    Instances:Create("UIListLayout", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        Padding = UDimNew(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    Instances:Create("UIPadding", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        PaddingTop = UDimNew(0, 12),
        PaddingBottom = UDimNew(0, 12),
        PaddingRight = UDimNew(0, 12),
        PaddingLeft = UDimNew(0, 12)
    })

    Library.Unload = function(self)
        for Index, Value in self.Connections do
            Value.Connection:Disconnect()
        end

        for Index, Value in self.Threads do
            coroutine.close(Value)
        end

        if self.Holder then
            self.Holder:Clean()
        end

        if self.UnusedHolder then
            self.UnusedHolder:Clean()
        end

        if self.WatermarkFrame then
            self.WatermarkFrame.Instance:Destroy()
            self.WatermarkFrame = nil
        end

        for _, Object in pairs(self.ToClean) do
            if Object and Object.Parent then
                Object:Destroy()
            end
        end

        Library = nil
        local env = (type(getgenv) == "function" and getgenv()) or _G
        if env.VortexionNeverloseLibrary == self then env.VortexionNeverloseLibrary = nil end
    end

    Library.GetImage = function(self, Image)
        local ImageData = self.Images[Image]

        if not ImageData then
            return
        end

        return getcustomasset(self.Folders.Assets .. "/" .. ImageData[1])
    end

    Library.Round = function(self, Number, Float)
        local Multiplier = 1 / (Float or 1)
        return MathFloor(Number * Multiplier) / Multiplier
    end

    Library.Thread = function(self, Function)
        local NewThread = coroutine.create(Function)

        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()

        TableInsert(self.Threads, NewThread)
        return NewThread
    end

    Library.SafeCall = function(self, Function, ...)
        local Arguements = { ... }
        local Success, Result = pcall(Function, TableUnpack(Arguements))

        if not Success then
            warn(Result)
            return false
        end

        return Success
    end

    Library.Connect = function(self, Event, Callback, Name)
        Name = Name or StringFormat("connection_number_%s_%s", self.UnnamedConnections + 1, HttpService:GenerateGUID(false))

        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }

        Library:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)

        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    Library.Disconnect = function(self, Name)
        for _, Connection in self.Connections do
            if Connection.Name == Name then
                Connection.Connection:Disconnect()
                break
            end
        end
    end

    Library.NextFlag = function(self)
        local FlagNumber = self.UnnamedFlags + 1
        return StringFormat("flag_number_%s_%s", FlagNumber, HttpService:GenerateGUID(false))
    end

    Library.AddToTheme = function(self, Item, Properties)
        Item = Item.Instance or Item

        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }

        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                Item[Property] = self.Theme[Value]
            else
                Item[Property] = Value()
            end
        end

        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

    Library.ToRich = function(self, Text, Color)
        return `<font color="rgb({MathFloor(Color.R * 255)}, {MathFloor(Color.G * 255)}, {MathFloor(Color.B * 255)})">{Text}</font>`
    end

    Library.GetConfig = function(self)
        local Config = { }

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Library.Flags do
                if type(Value) == "table" and Value.Key then
                    Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
                elseif type(Value) == "table" and Value.Color then
                    Config[Index] = {Color = "#" .. Value.HexValue, Alpha = Value.Alpha}
                else
                    Config[Index] = Value
                end
            end
        end)

        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, Config)
        local Decoded = HttpService:JSONDecode(Config)

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Decoded do
                local SetFunction = Library.SetFlags[Index]

                if not SetFunction then
                    continue
                end

                if type(Value) == "table" and Value.Key then
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    SetFunction(Value.Color, Value.Alpha)
                else
                    SetFunction(Value)
                end
            end
        end)

        return Success, Result
    end

    Library.DeleteConfig = function(self, Config)
        if isfile(Library.Folders.Configs .. "/" .. Config) then
            delfile(Library.Folders.Configs .. "/" .. Config)
        end
    end

    Library.RefreshConfigsList = function(self, Element)
        if not Element or not Element.Refresh then
            return
        end

        local List = { }

        if isfolder(Library.Folders.Configs) then
            for Index, FilePath in listfiles(Library.Folders.Configs) do
                local FileName = FilePath:match("[^/^\\]+$")
                if FileName then
                    TableInsert(List, FileName)
                end
            end
        end

        Element:Refresh(List)
    end

    Library.ChangeItemTheme = function(self, Item, Properties)
        Item = Item.Instance or Item

        if not self.ThemeMap[Item] then
            return
        end

        self.ThemeMap[Item].Properties = Properties
        self.ThemeMap[Item] = self.ThemeMap[Item]
    end

    Library.ChangeTheme = function(self, Theme, Color)
        self.Theme[Theme] = Color

        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    Item.Item[Property] = Color
                elseif type(Value) == "function" then
                    Item.Item[Property] = Value()
                end
            end
        end
    end

    Library.IsMouseOverFrame = function(self, Frame, Input)
        Frame = Frame and (Frame.Instance or Frame)
        if not Frame then return false end
        -- Touch has its own pointer position; Mouse.X / Mouse.Y are stale on Android.
        local position = Input and Input.Position or UserInputService:GetMouseLocation()
        return position.X >= Frame.AbsolutePosition.X and position.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X
           and position.Y >= Frame.AbsolutePosition.Y and position.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end

    Library.Lerp = function(self, Start, Finish, Time)
        return Start + (Finish - Start) * Time
    end

    Library.CompareVectors = function(self, PointA, PointB)
        return (PointA.X < PointB.X) or (PointA.Y < PointB.Y)
    end

    Library.IsClipped = function(self, Object, Column)
        local Parent = Column

        local BoundryTop = Parent.AbsolutePosition
        local BoundryBottom = BoundryTop + Parent.AbsoluteSize

        local Top = Object.AbsolutePosition
        local Bottom = Top + Object.AbsoluteSize

        return Library:CompareVectors(Top, BoundryTop) or Library:CompareVectors(BoundryBottom, Bottom)
    end

    Library.GetCalculatedRayPosition = function(self, Position, Normal, Origin, Direction)
        local N = Normal
        local D = Direction
        local V = Origin - Position

        local Number = (N.x * V.x) + (N.y * V.y) + (N.z * V.z)
        local Den = (N.x * D.x) + (N.y * D.y) + (N.z * D.z)
        local A = -Number / Den

        return Origin + (A * Direction)
    end

    Library.UpdateText = function(self)
        for Index, Value in self.UnusedHolder.Instance:GetDescendants() do
            if Value:IsA("TextLabel") or Value:IsA("TextButton") or Value:IsA("TextBox") then
                Value.FontFace = Library.Font
            end
        end

        for Index, Value in self.Holder.Instance:GetDescendants() do
            if Value:IsA("TextLabel") or Value:IsA("TextButton") or Value:IsA("TextBox") then
                Value.FontFace = Library.Font
            end
        end
    end

    Library.MakeBlurred = function(self, Item, Window)
        if IsMobile then return end
        Item = Item.Instance
        local BlurItem = Item

        local Part = Instances:Create("Part", {
            Material = Enum.Material.Glass,
            Transparency = 1,
            Reflectance = 1,
            CastShadow = false,
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CollisionGroup = " ",
            Size = Vector3New(1, 1, 1) * 0.01,
            Color = FromRGB(0,0,0),
            Parent = Camera
        })
        -- Добавляем в список на удаление
        table.insert(self.ToClean, Part.Instance)

        local BlockMesh = Instances:Create("BlockMesh", {Parent = Part.Instance})

        local DepthOfField = Instances:Create("DepthOfFieldEffect", {
            Parent = Lighting,
            Enabled = true,
            FarIntensity = 0,
            FocusDistance = 0,
            InFocusRadius = 1000,
            NearIntensity = 1,
            Name = ""
        })
        -- Добавляем в список на удаление
        table.insert(self.ToClean, DepthOfField.Instance)

        Library:Connect(RunService.RenderStepped, function()
            if Window.IsOpen then
                if Item.Visible then
                    DepthOfField:Tween(nil, {NearIntensity = 1})

                    Part:Tween(nil, {Transparency = 0.97})
                    Part:Tween(nil, {Size = Vector3New(1, 1, 1) * 0.01})

                    local Corner0 = BlurItem.AbsolutePosition;
                    local Corner1 = Corner0 + BlurItem.AbsoluteSize;

                    local Ray0 = Camera.ScreenPointToRay(Camera, Corner0.X, Corner0.Y, 1);
                    local Ray1 = Camera.ScreenPointToRay(Camera, Corner1.X, Corner1.Y, 1);

                    local Origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (0.05 - Camera.NearPlaneZ);

                    local Normal = Camera.CFrame.LookVector;

                    local Position0 = Library:GetCalculatedRayPosition(Origin, Normal, Ray0.Origin, Ray0.Direction)
                    local Position1 = Library:GetCalculatedRayPosition(Origin, Normal, Ray1.Origin, Ray1.Direction)

                    Position0 = Camera.CFrame:PointToObjectSpace(Position0)
                    Position1 = Camera.CFrame:PointToObjectSpace(Position1)

                    local Size = Position1 - Position0
                    local Center = (Position0 + Position1) / 2

                    BlockMesh.Instance.Offset = Center
                    BlockMesh.Instance.Scale  = Size / 0.0101

                    Part.Instance.CFrame = Camera.CFrame
                else
                    DepthOfField:Tween(nil, {NearIntensity = 0})
                    BlockMesh.Instance.Offset = Vector3New(0, 0, 0)
                    BlockMesh.Instance.Scale  = Vector3New(0, 0, 0)
                end
            else
                DepthOfField:Tween(nil, {NearIntensity = 0})
                BlockMesh.Instance.Offset = Vector3New(0, 0, 0)
                BlockMesh.Instance.Scale  = Vector3New(0, 0, 0)
            end
        end)
    end

    Library.EscapePattern = function(self, String)
        local ShouldEscape = false

        if string.match(String, "[%(%)%.%%%+%-%*%?%[%]%^%$]") then
            ShouldEscape = true
        end

        if ShouldEscape then
            return StringGSub(String, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
        end

        return String
    end

    do
        Library.CreateColorpicker = function(self, Data)
            local Colorpicker = {
                Flag = Data.Flag,

                Hue = 0,
                Saturation = 0,
                Value = 0,

                Alpha = 0,

                Color = FromRGB(0, 0, 0),
                HexValue = "#000000",

                SavedColors = { },

                IsOpen = false
            }

            local Items = { } do
                Items["ColorpickerButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 100, 0, 20),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                if not Data.Parent2.Instance:FindFirstChild("nig") then
                    Items["PaletteIcon"] = Instances:Create("ImageLabel", {
                        Parent = Data.Parent2.Instance,
                        ImageColor3 = FromRGB(141, 141, 150),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 16, 0, 16),
                        AnchorPoint = Vector2New(0.5, 1),
                        Image = "rbxassetid://92464809279921",
                        Name = "nig",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, -16, 1, -6),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Items["PaletteIcon"]:OnHover(function()
                        Items["PaletteIcon"]:Tween(nil, {ImageColor3 = Library.Theme.Accent})
                    end)

                    Items["PaletteIcon"]:OnHoverLeave(function()
                        Items["PaletteIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
                    end)
                end

                Items["Color"] = Instances:Create("Frame", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 15, 0, 15),
                    Position = UDim2New(0, 0, 0, 2),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Color"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "#7842ff",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 25, 0, 2),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["ColorpickerWindow"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    AutoButtonColor = false,
                    Text = "",
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0.01075268816202879, 0, 0.0336427167057991, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 235, 0, 270),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 25)
                })  Items["ColorpickerWindow"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Items["Palette"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Position = UDim2New(0, 15, 0, 10),
                    Size = UDim2New(1, -31, 1, -159),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })

                Items["Saturation"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 1, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
                })

                Instances:Create("UICorner", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Value"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 1, 1, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
                })

                Instances:Create("UICorner", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["PaletteDragger"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0, 15),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 10),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0",
                    Color = FromRGB(255, 255, 255),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Instances:Create("UICorner", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0"
                })

                Items["Hue"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 15, 1, -131),
                    Size = UDim2New(1, -31, 0, 6),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["HueInline"] = Instances:Create("TextButton", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 0, 0)), RGBSequenceKeypoint(0.17, FromRGB(255, 255, 0)), RGBSequenceKeypoint(0.33, FromRGB(0, 255, 0)), RGBSequenceKeypoint(0.5, FromRGB(0, 255, 255)), RGBSequenceKeypoint(0.67, FromRGB(0, 0, 255)), RGBSequenceKeypoint(0.83, FromRGB(255, 0, 255)), RGBSequenceKeypoint(1, FromRGB(255, 0, 0))}
                })

                Items["HueDragger"] = Instances:Create("Frame", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 15, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["HueDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["Alpha"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 15, 1, -107),
                    Size = UDim2New(1, -31, 0, 6),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(0, 0, 0)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })

                Items["AlphaDragger"] = Instances:Create("Frame", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 15, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["AlphaDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["SavedColors"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2New(0, 1),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    ScrollBarImageColor3 = FromRGB(124, 163, 255),
                    MidImage = "rbxassetid://86870199131153",
                    BorderColor3 = FromRGB(0, 0, 0),
                    ScrollBarThickness = 0,
                    Size = UDim2New(1, -20, 0, 69),
                    Selectable = false,
                    TopImage = "rbxassetid://86870199131153",
                    Position = UDim2New(0, 10, 1, -30),
                    BottomImage = "rbxassetid://86870199131153",
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGridLayout", {
                    Parent = Items["SavedColors"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    CellPadding = UDim2New(0, 10, 0, 10),
                    CellSize = UDim2New(0, 25, 0, 25)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["SavedColors"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 5),
                    PaddingTop = UDimNew(0, 5),
                    PaddingRight = UDimNew(0, -125),
                    PaddingBottom = UDimNew(0, 5)
                })

                Items["HEXInput"] = Instances:Create("TextBox", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ClearTextOnFocus = false,
                    Text = "#7ca3ff",
                    AnchorPoint = Vector2New(1, 1),
                    Size = UDim2New(0, 140, 0, 20),
                    TextTransparency = 0.5,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    Position = UDim2New(1, -8, 1, -8),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(30, 29, 31)
                })  Items["HEXInput"]:AddToTheme({BackgroundColor3 = "Outline"})

                Instances:Create("UIPadding", {
                    Parent = Items["HEXInput"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 5),
                })

                Items["HexLabel"] = Instances:Create("TextLabel", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Custom:",
                    TextTransparency = 0.5,
                    AnchorPoint = Vector2New(0, 1),
                    Size = UDim2New(0, 40, 0, 20),
                    Position = UDim2New(0, 10, 1, -8),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(30, 29, 31)
                })  Items["HexLabel"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UICorner", {
                    Parent = Items["HEXInput"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
            end

            function Colorpicker:Get()
                return Colorpicker.Color, Colorpicker.Alpha
            end

            function Colorpicker:Update(IsFromAlpha)
                local Hue, Saturation, Value = Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value
                Colorpicker.Color = FromHSV(Hue, Saturation, Value)
                Colorpicker.HexValue = Colorpicker.Color:ToHex()

                Library.Flags[Colorpicker.Flag] = {
                    Alpha = Colorpicker.Alpha,
                    Color = Colorpicker.Color,
                    HexValue = Colorpicker.HexValue,
                    Transparency = 1 - Colorpicker.Alpha
                }

                Items["Color"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                Items["Palette"]:Tween(nil, {BackgroundColor3 = FromHSV(Hue, 1, 1)})
                Items["Text"].Instance.Text = ("#"..Colorpicker.HexValue):upper()
                Items["HEXInput"].Instance.Text = "#"..Colorpicker.HexValue

                if not IsFromAlpha then
                    Items["Alpha"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                end

                if Data.Callback then
                    Library:SafeCall(Data.Callback, Colorpicker.Color, Colorpicker.Alpha)
                end
            end

            local SlidingPalette = false
            local PaletteChanged

            function Colorpicker:SlidePalette(Input)
                if not Input or not SlidingPalette then
                    return
                end

                local ValueX = MathClamp(1 - (Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 1)
                local ValueY = MathClamp(1 - (Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 1)

                Colorpicker.Saturation = ValueX
                Colorpicker.Value = ValueY

                local SlideX = MathClamp((Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 0.955)
                local SlideY = MathClamp((Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 0.955)

                Items["PaletteDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, SlideY, 0)})
                Colorpicker:Update()
            end

            local SlidingHue = false
            local HueChanged

            function Colorpicker:SlideHue(Input)
                if not Input or not SlidingHue then
                    return
                end

                local ValueX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 1)

                Colorpicker.Hue = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 0.955)

                Items["HueDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0.5, 0)})
                Colorpicker:Update()
            end

            local SlidingAlpha = false
            local AlphaChanged

            function Colorpicker:SlideAlpha(Input)
                if not Input or not SlidingAlpha then
                    return
                end

                local ValueX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 1)

                Colorpicker.Alpha = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 0.955)

                Items["AlphaDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0.5, 0)})
                Colorpicker:Update(true)
            end

            local Debounce = false
            local RenderStepped

            function Colorpicker:SetOpen(Bool)
                if Debounce then
                    return
                end

                Colorpicker.IsOpen = Bool

                Debounce = true

                if Colorpicker.IsOpen then
                    Items["ColorpickerWindow"].Instance.Visible = true
                    Items["ColorpickerWindow"].Instance.Parent = Library.Holder.Instance

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["ColorpickerWindow"].Instance.Position = UDim2New(
                            0,
                            Items["ColorpickerButton"].Instance.AbsolutePosition.X,
                            0,
                            Items["ColorpickerButton"].Instance.AbsolutePosition.Y + Items["ColorpickerButton"].Instance.AbsoluteSize.Y + 5
                        )
                    end)

                    if Data.Section.IsSettings ~= true then
                        for Index, Value in Library.OpenFrames do
                            if Value ~= Colorpicker then
                                Value:SetOpen(false)
                            end
                        end
                    end

                    Library.OpenFrames[Colorpicker] = Colorpicker
                else
                    if not Data.Section.IsSettings then
                        if Library.OpenFrames[Colorpicker] then
                            Library.OpenFrames[Colorpicker] = nil
                        end
                    end

                    if RenderStepped then
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["ColorpickerWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["ColorpickerWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue
                    end

                    if not Value.ClassName:find("UI") then
                        Value.ZIndex = (Colorpicker.IsOpen and Data.Section.IsSettings and 9) or (Colorpicker.IsOpen and not Data.Section.IsSettings and 3) or 1
                    end

                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                NewTween.Tween.Completed:Connect(function()
                    Debounce = false
                    Items["ColorpickerWindow"].Instance.Visible = Colorpicker.IsOpen
                    task.wait(0.2)
                    Items["ColorpickerWindow"].Instance.Parent = not Colorpicker.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Colorpicker:Set(Color, Alpha)
                if type(Color) == "table" then
                    Color = FromRGB(Color[1], Color[2], Color[3])
                    Alpha = Color[4]
                elseif type(Color) == "string" then
                    Color = FromHex(Color)
                end

                Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value = Color:ToHSV()
                Colorpicker.Alpha = Alpha or 0

                local PaletteValueX = MathClamp(1 - Colorpicker.Saturation, 0, 0.955)
                local PaletteValueY = MathClamp(1 - Colorpicker.Value, 0, 0.955)

                local AlphaPositionX = MathClamp(Colorpicker.Alpha, 0, 0.955)

                local HuePositionX = MathClamp(Colorpicker.Hue, 0, 0.955)

                Items["PaletteDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(PaletteValueX, 0, PaletteValueY, 0)})
                Items["HueDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(HuePositionX, 0, 0.5, 0)})
                Items["AlphaDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(AlphaPositionX, 0, 0.5, 0)})
                Colorpicker:Update()
            end

            Items["ColorpickerButton"]:Connect("Activated", function()
                Colorpicker:SetOpen(not Colorpicker.IsOpen)
            end)

            Items["Palette"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingPalette = true

                    Colorpicker:SlidePalette(Input)

                    if PaletteChanged then
                        return
                    end

                    PaletteChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingPalette = false

                            PaletteChanged:Disconnect()
                            PaletteChanged = nil
                        end
                    end)
                end
            end)

            Items["HueInline"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingHue = true

                    Colorpicker:SlideHue(Input)

                    if HueChanged then
                        return
                    end

                    HueChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingHue = false

                            HueChanged:Disconnect()
                            HueChanged = nil
                        end
                    end)
                end
            end)

            Items["Alpha"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingAlpha = true

                    Colorpicker:SlideAlpha(Input)

                    if AlphaChanged then
                        return
                    end

                    AlphaChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingAlpha = false

                            AlphaChanged:Disconnect()
                            AlphaChanged = nil
                        end
                    end)
                end
            end)

            function AddColor(Color)
                --if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local SaveIndex = #Colorpicker.SavedColors + 1

                    local SavedColor = Instances:Create("TextButton", {
                        Parent = Items["SavedColors"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        Size = UDim2New(0, 200, 0, 50),
                        BorderSizePixel = 0,
                        TextSize = 14,
                        BackgroundTransparency = 1,
                        ZIndex = 4,
                        BackgroundColor3 = Color
                    })

                    Instances:Create("UICorner", {
                        Parent = SavedColor.Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6),
                    })

                    local UIStroke = Instances:Create("UIStroke", {
                        Parent = SavedColor.Instance,
                        Name = "\0",
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Color = FromRGB(255, 255, 255),
                        Thickness = 1.5,
                        Transparency = 1
                    })

                    SavedColor:OnHover(function()
                        UIStroke:Tween(nil, {Transparency = 0})
                    end)

                    SavedColor:OnHoverLeave(function()
                        UIStroke:Tween(nil, {Transparency = 1})
                    end)

                    Colorpicker.SavedColors[SaveIndex] = {
                        Color = Color,
                        Alpha = Colorpicker.Alpha,
                    }

                    SavedColor:Connect("Activated", function()
                        local NewColorData = Colorpicker.SavedColors[SaveIndex]
                        Colorpicker:Set(NewColorData.Color, NewColorData.Alpha)
                    end)

                    SavedColor:Tween(nil, {BackgroundTransparency = 0})
                --end
            end

            local Colors = {
                ["Orange"] = FromRGB(245, 114, 66),
                ["Pink"] = FromRGB(245, 66, 191),
                ["Purple"] = FromRGB(124, 54, 245),
                ["Pink 2"] = FromRGB(202, 110, 255),
                ["Pink 3"] = FromRGB(250, 142, 239),
                ["Yellow"] = FromRGB(214, 206, 92),
                ["Orange 2"] = FromRGB(255, 93, 48),
                ["Orange 3"] = FromRGB(255, 169, 56),
                ["Green"] = FromRGB(0, 171, 0),
                ["Blue"] = FromRGB(0, 116, 224),
                ["Maroon"] = FromRGB(120, 0, 76),
                ["Whiteish Pink"] = FromRGB(255, 194, 245),
                ["White"] = FromRGB(255, 255, 255),
                ["Red"] = FromRGB(255, 0, 0),
                ["Sky Blue"] = FromRGB(171, 209, 255),
            }

            AddColor(Colors["Orange"])
            AddColor(Colors["Pink"])
            AddColor(Colors["Purple"])
            AddColor(Colors["Pink 2"])
            AddColor(Colors["Pink 3"])
            AddColor(Colors["Yellow"])
            AddColor(Colors["Orange 2"])
            AddColor(Colors["Orange 3"])
            AddColor(Colors["Green"])
            AddColor(Colors["Blue"])
            AddColor(Colors["Maroon"])
            AddColor(Colors["Whiteish Pink"]) -- had to do it in order
            AddColor(Colors["White"])
            AddColor(Colors["Red"])
            AddColor(Colors["Sky Blue"])

            Items["HEXInput"]:Connect("FocusLost", function()
                Colorpicker:Set(tostring(Items["HEXInput"].Instance.Text), Colorpicker.Alpha)
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if SlidingPalette then
                        Colorpicker:SlidePalette(Input)
                    end

                    if SlidingHue then
                        Colorpicker:SlideHue(Input)
                    end

                    if SlidingAlpha then
                        Colorpicker:SlideAlpha(Input)
                    end
                end
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if not Colorpicker.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["ColorpickerWindow"],Input) or Library:IsMouseOverFrame(Items["PaletteIcon"],Input) and not Data.Section.IsSettings then
                        return
                    end

                    Colorpicker:SetOpen(false)
                end
            end)

            if Data.Default then
                Colorpicker:Set(Data.Default, Data.Alpha)
            end

            Library.SetFlags[Colorpicker.Flag] = function(Value, Alpha)
                Colorpicker:Set(Value, Alpha)
            end

            return Colorpicker, Items
        end

        Library.KeybindList = function(self, Title)
            local KeybindList = { }
            Library.KeyList = KeybindList

            local Items = { } do
                Items["KeybindsList"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 0.30000001192092896,
                    Position = UDim2New(0, 20, 0.5, 20),
                    Size = UDim2New(0, 100, 0, 30),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(27, 25, 29),
                    Visible = false,
                })  Items["KeybindsList"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["KeybindsList"]:MakeDraggable()

                Instances:Create("UICorner", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0"
                })

                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 12, 0, 40),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                })  Items["Top"]:AddToTheme({BackgroundColor3 = "Section Background 2"})

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 21, 0, 20),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://81598136527047",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(248, 248, 248),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Title,
                    AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 45, 0.5, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UICorner", {
                    Parent = Items["Top"].Instance,
                    Name = "\0"
                })

                Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 5),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                }):AddToTheme({BackgroundColor3 = "Section Background 2"})

                Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 1),
                    Position = UDim2New(1, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 5),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                }):AddToTheme({BackgroundColor3 = "Section Background 2"})

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 40),
                    Size = UDim2New(1, 12, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 12)
                })
            end

            function KeybindList:SetVisibility(Bool)
                Items["KeybindsList"].Instance.Visible = Bool
            end

            function KeybindList:Add(Name, Key)
                local NewKey = Instances:Create("TextButton", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, IsMobile and 40 or 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local NewKeyAccent = Instances:Create("Frame", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient",{
                    Parent = NewKeyAccent.Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = NewKeyAccent.Instance,
                    Name = "\0"
                })

                local NewKeyText = Instances:Create("TextLabel", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Name .. " ["..Key.."]",
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  NewKeyText:AddToTheme({TextColor3 = "Text"})

                function NewKey:Set(Name, Key)
                    NewKeyText.Instance.Text = Name .. " ["..Key.."]"
                end

                function NewKey:SetStatus(Bool)
                    if Bool then
                        NewKeyText:Tween(nil, {Position = UDim2New(0, 15, 0.5, 0), TextTransparency = 0})
                        NewKeyAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        NewKeyText:Tween(nil, {Position = UDim2New(0, 0, 0.5, 0), TextTransparency = 0.3})
                        NewKeyAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                return NewKey
            end

            return KeybindList
        end

        Library.Notification = function(self, Data)
            local Items = { } do
                Items["Notification"] = Instances:Create("Frame", {
                    Parent = Library.NotifHolder.Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.3499999940395355,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Data.Title,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIPadding", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Description"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Data.Description,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Description"]:AddToTheme({TextColor3 = "Text"})

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 0, 0, Items["Description"].Instance.AbsoluteSize.Y + Items["Title"].Instance.AbsoluteSize.Y + 12),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 0, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Image = "rbxassetid://"..Data.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 16, 0, 16),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                if not Data.IconColor then
                    Instances:Create("UIGradient", {
                        Parent = Items["Icon"].Instance,
                        Name = "\0",
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})
                else
                    Instances:Create("UIGradient", {
                        Parent = Items["Icon"].Instance,
                        Name = "\0",
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, Data.IconColor.Start), RGBSequenceKeypoint(1, Data.IconColor.End)}
                    })
                end
            end

            local Size = Items["Notification"].Instance.AbsoluteSize
            Items["Notification"].Instance.Size = UDim2New(0, 0, 0, 0)

            for Index, Value in Items do
                if Value.Instance:IsA("Frame") then
                    Value.Instance.BackgroundTransparency = 1
                elseif Value.Instance:IsA("TextLabel") then
                    Value.Instance.TextTransparency = 1
                elseif Value.Instance:IsA("ImageLabel") then
                    Value.Instance.ImageTransparency = 1
                end
            end

            task.wait(0.2)

            Items["Notification"].Instance.AutomaticSize = Enum.AutomaticSize.Y

            Library:Thread(function()
                for Index, Value in Items do
                    if Value.Instance:IsA("Frame") then
                        Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {BackgroundTransparency = 0})
                    elseif Value.Instance:IsA("TextLabel") then
                        Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {TextTransparency = 0})
                    elseif Value.Instance:IsA("ImageLabel") then
                        Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {ImageTransparency = 0})
                    end
                end

                Items["Notification"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {Size = UDim2New(0, Size.X, 0, Size.Y)})
                Items["Accent"]:Tween(TweenInfo.new(Data.Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Size = UDim2New(1, 0, 0, 6)})

                task.delay(Data.Duration + 0.15, function()
                    for Index, Value in Items do
                        if Value.Instance:IsA("Frame") then
                            Value:Tween(nil, {BackgroundTransparency = 1})
                        elseif Value.Instance:IsA("TextLabel") then
                            Value:Tween(nil, {TextTransparency = 1})
                        elseif Value.Instance:IsA("ImageLabel") then
                            Value:Tween(nil, {ImageTransparency = 1})
                        end
                    end

                    Items["Notification"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {Size = UDim2New(0, 0, 0, 0)})
                    task.wait(0.5)
                    Items["Notification"]:Clean()
                end)
            end)
        end

        Library.Window = function(self, Data)
            Data = Data or { }

            local Window = {
                Name = Data.Name or Data.name or "Window",
                SubName = Data.SubName or Data.subname or "Fine-tuning for sure wins",
                Logo = Data.Logo or Data.logo or "1l20959262762131",

                Pages = { },
                Items = { },
                IsOpen = false,
                CurrentAlignment = "LeftTabs"
            }

            local Items = { } do
                Items["MainFrame"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BackgroundTransparency = 0.02,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 677, 0, 644),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["MainFrame"]:AddToTheme({BackgroundColor3 = "Background"})

                -- Mobile scale is owned by Vortexion's viewport adapter, not a hardcoded .7.

                -- Resizing is managed by the viewport adapter; legacy edge handles
                -- can extend outside the touch-safe area and steal gestures.
                Library:MakeBlurred(Items["MainFrame"], Window)

                Items["LeftTabs"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["MainFrame"].Instance,
                    Active = true,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    CanvasSize = UDim2FromOffset(0, 0),
                    ScrollBarThickness = IsMobile and 4 or 3,
                    ClipsDescendants = true,
                    Name = "\0",
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.03,
                    Size = UDim2New(0, 225, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["LeftTabs"]:AddToTheme({BackgroundColor3 = "Background"})

                Library:MakeBlurred(Items["LeftTabs"], Window)

                local Gui = Items["MainFrame"].Instance

                local Dragging = false
                local ActivePointer = nil
                local DragStart
                local StartPosition

                local Set = function(Input)
                    local DragDelta = Input.Position - DragStart
                    Items["MainFrame"]:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
                end

                -- Drag via the sidebar only on desktop. On touch a full-frame drag
                -- consumes taps on controls; moving the menu is disabled in favour
                -- of automatic safe-area fitting.
                if not IsMobile then
                    Items["LeftTabs"]:Connect("InputBegan", function(pointer)
                        if pointer.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                        Dragging, ActivePointer = true, pointer
                        DragStart, StartPosition = pointer.Position, Gui.Position
                        Library:Connect(pointer.Changed, function()
                            if pointer.UserInputState == Enum.UserInputState.End then
                                Dragging, ActivePointer = false, nil
                            end
                        end)
                    end)
                    Library:Connect(UserInputService.InputChanged, function(pointer)
                        if Dragging and ActivePointer and pointer.UserInputType == Enum.UserInputType.MouseMovement then
                            Set(pointer)
                        end
                    end)
                end

                if IsMobile then
                    Items["FloatingButton"] = Instances:Create("TextButton", {
                        Parent = Library.Holder.Instance,
                        Text = "",
                        AutoButtonColor = false,
                        Name = "\0",
                        Position = UDim2New(0.5, 0, 0, 20),
                        AnchorPoint = Vector2New(0.5, 0),
                        Visible = true,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 48, 0, 48),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 0.5,
                        ZIndex = 127,
                        BackgroundColor3 = Library.Theme.Background
                    })  Items["FloatingButton"]:AddToTheme({BackgroundColor3 = "Background"})

                    local Gui = Items["FloatingButton"].Instance

                    local Dragging = false
                    local DragPointer = nil
                    local DragStart
                    local StartPosition

                    local Set = function(Input)
                        local DragDelta = Input.Position - DragStart
                        Items["FloatingButton"]:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
                    end

                    Items["FloatingButton"]:Connect("InputBegan", function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                            if DragPointer and DragPointer ~= Input then return end
                            Dragging, DragPointer = true, Input
                            DragStart = Input.Position
                            StartPosition = Gui.Position

                            Input.Changed:Connect(function()
                                if Input.UserInputState == Enum.UserInputState.End then
                                    Dragging, DragPointer = false, nil
                                end
                            end)
                        end
                    end)

                    Library:Connect(UserInputService.InputChanged, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                            if Dragging and (Input == DragPointer or
                                (DragPointer and DragPointer.UserInputType == Enum.UserInputType.MouseButton1 and Input.UserInputType == Enum.UserInputType.MouseMovement)) then
                                Set(Input)
                            end
                        end
                    end)

                    Items["FloatingLogo"] = Instances:Create("ImageLabel", {
                        Parent = Items["FloatingButton"].Instance,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Name = "\0",
                        Image = (Window.Logo:find("://", 1, true) and Window.Logo or "rbxassetid://" .. Window.Logo),
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        ZIndex = 127,
                        Size = UDim2New(1, -25, 1, -25),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Instances:Create("UICorner", {
                        Parent = Items["FloatingButton"].Instance,
                        CornerRadius = UDimNew(1, 0)
                    })

                    Instances:Create("UIGradient", {
                        Parent = Items["FloatingLogo"].Instance,
                        Name = "\0",
                        Enabled = false,
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})
                end

                Items["PagePlaceholder"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 12),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 15),
                    PaddingBottom = UDimNew(0, 15),
                    PaddingRight = UDimNew(0, 12),
                    PaddingLeft = UDimNew(0, 12)
                })

                Items["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 35, 0, 35),
                    Image = (Window.Logo:find("://", 1, true) and Window.Logo or "rbxassetid://" .. Window.Logo),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 12),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Logo"].Instance,
                    Name = "\0",
                    Enabled = false,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Window.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 52, 0, 13),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 16,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["SubTitle"] = Instances:Create("TextLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.4000000059604645,
                    Text = Window.SubName,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 52, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SubTitle"]:AddToTheme({TextColor3 = "Text"})

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.75,
                    Position = UDim2New(0, 0, 0, 55),
                    Size = UDim2New(1, 0, 1, -55),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["Content"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["CloseButton"] = Instances:Create("TextButton", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.20000000298023224,
                    Position = UDim2New(1, -14, 0, 11),
                    Size = UDim2New(0, 32, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["CloseButton"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["CloseIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(240, 240, 240),
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 11, 0, 11),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://130510492706892",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["CloseIcon"]:AddToTheme({ImageColor3 = "Text"})

                Items["CloseButton"]:Connect("Activated", function()
                    Window:SetOpen(false) -- minimize, preserve running UI and mobile reopen
                end)

                Items["CloseIconAccent"] = Instances:Create("Frame", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["CloseIconAccent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UICorner", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UICorner", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                do
                    Items["LeftBottomPixels"] = Instances:Create("Frame", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 1),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 1, 1, 0),
                        Size = UDim2New(0, 5, 0, 5),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Items["___1"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 2, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___1"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___2"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 4, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___2"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___3"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 3, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___3"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___4"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 3, 1, -1),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___4"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___5"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 4, 1, -1),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___5"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___6"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 5, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___6"]:AddToTheme({BackgroundColor3 = "Background"})



                    Items["LeftTopPixels"] = Instances:Create("Frame", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 1, 0, 0),
                        Size = UDim2New(0, 5, 0, 5),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    Items["___7"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 2, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___7"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___8"]= Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        BackgroundTransparency = 0.12,
                        Position = UDim2New(0, 3, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___8"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___9"]= Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 4, 0, 0),
                        BackgroundTransparency = 0.12,
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___9"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___10"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 5, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 0.12,
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___10"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___11"]=Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 3, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___11"]:AddToTheme({BackgroundColor3 = "Background"})

                    Items["___12"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 4, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___12"]:AddToTheme({BackgroundColor3 = "Background"})
                end

                function Window:SetTransparency()
                    Items["MainFrame"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]
                    Items["LeftTabs"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]
                    if IsMobile then
                        Items["FloatingButton"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]
                    end

                    for _, Value in Items do
                        if _:find("___") then
                            Value.Instance.BackgroundTransparency = tonumber(Library.Flags["BackgroundTransparency"])
                        end
                    end
                end

                Instances:Create("UIGradient", {
                    Parent = Items["CloseIconAccent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))},
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["SettingsButton"] = Instances:Create("TextButton", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.20000000298023224,
                    Position = UDim2New(1, -56, 0, 11),
                    Size = UDim2New(0, 32, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["SettingsButton"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["SettingsIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(240, 240, 240),
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 15, 0, 14),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://122669828593160",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SettingsIcon"]:AddToTheme({ImageColor3 = "Text"})

                Items["SettingsIconAccent"] = Instances:Create("Frame", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["SettingsIconAccent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["SettingsIconAccent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))},
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["SettingsButton"]:OnHover(function()
                    Items["SettingsIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(1, 0, 1, 0),
                        BackgroundTransparency = 0
                    })
                end)

                Items["SettingsButton"]:OnHoverLeave(function()
                    Items["SettingsIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    })
                end)

                Items["CloseButton"]:OnHover(function()
                    Items["CloseIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(1, 0, 1, 0),
                        BackgroundTransparency = 0
                    })
                end)

                Items["CloseButton"]:OnHoverLeave(function()
                    Items["CloseIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    })
                end)

                local Settings = {
                    IsOpen = false,
                    Name = ""..#Library.Sections,
                    Items = { },
                    IsSettings = true,
                    Elements = { }
                }

                local SettingsItems = { }
                do
                    SettingsItems["Settings"] = Instances:Create("Frame", {
                        Parent = Library.UnusedHolder.Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        Position = UDim2New(0.8949604630470276, 0, 0.2945185601711273, 0),
                        Size = UDim2New(0, 245, 0, 159),
                        ZIndex = 2,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = FromRGB(21, 21, 24)
                    }) SettingsItems["Settings"]:AddToTheme({BackgroundColor3 = "Section Background 2"})

                    Instances:Create("UICorner", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6)
                    })

                    SettingsItems["CloseButton"] = Instances:Create("TextButton", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        AnchorPoint = Vector2New(0, 1),
                        BorderSizePixel = 0,
                        Position = UDim2New(0, 8, 1, -8),
                        Size = UDim2New(1, -16, 0, 32),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    }) SettingsItems["CloseButton"]:AddToTheme({BackgroundColor3 = "Element"})

                    Instances:Create("UICorner", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    SettingsItems["Text"] = Instances:Create("TextLabel", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        TextTransparency = 0.30000001192092896,
                        Text = "Close",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    SettingsItems["Content"] = Instances:Create("ScrollingFrame", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Selectable = false,
                        Size = UDim2New(1, -8, 1, -46),
                        Position = UDim2New(0, 4, 0, 4),
                        ScrollBarThickness = 2,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })  SettingsItems["Content"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                    Instances:Create("UIListLayout", {
                        Parent = SettingsItems["Content"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Instances:Create("UIPadding", {
                        Parent = SettingsItems["Content"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 4),
                        PaddingBottom = UDimNew(0, 4),
                        PaddingRight = UDimNew(0, 4),
                        PaddingLeft = UDimNew(0, 4)
                    })

                    SettingsItems["Accent"] = Instances:Create("Frame", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0)
                    })  --SettingsItems["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                    SettingsItems["Gradient"] = Instances:Create("UIGradient", {
                        Parent = SettingsItems["Accent"].Instance,
                        Name = "\0",
                        Enabled = true,
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    })  SettingsItems["Gradient"]:AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})

                    Instances:Create("UICorner", {
                        Parent = SettingsItems["Accent"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    Instances:Create("UICorner", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    SettingsItems["CloseButton"]:OnHover(function()
                        SettingsItems["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                    end)

                    SettingsItems["CloseButton"]:OnHoverLeave(function()
                        SettingsItems["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                    end)

                    local RenderStepped
                    local Debounce = false

                    function Settings:SetOpen(Bool)
                        if Debounce then
                            return
                        end

                        Settings.IsOpen = Bool

                        Debounce = true

                        if Settings.IsOpen then
                            for Index, Value in Settings.Elements do
                                Value:RefreshPosition(true)
                                task.wait(0.03)
                            end

                            SettingsItems["Settings"].Instance.Visible = true
                            SettingsItems["Settings"].Instance.Parent = Library.Holder.Instance

                            RenderStepped = RunService.RenderStepped:Connect(function()
                                SettingsItems["Settings"].Instance.Position = UDim2New(0, Items["SettingsIcon"].Instance.AbsolutePosition.X, 0, Items["SettingsIcon"].Instance.AbsolutePosition.Y + Items["SettingsButton"].Instance.AbsoluteSize.Y + 108)
                                SettingsItems["Settings"].Instance.Size = UDim2New(0, 325, 0, 230)
                            end)

                            for Index, Value in Library.OpenFrames do
                                if Value ~= Settings then
                                    Value:SetOpen(false)
                                end
                            end

                            Library.OpenFrames[Settings] = Settings
                        else
                            for Index, Value in Settings.Elements do
                                Value:RefreshPosition(false)
                            end

                            if Library.OpenFrames[Settings] then
                                Library.OpenFrames[Settings] = nil
                            end

                            if RenderStepped then
                                RenderStepped:Disconnect()
                                RenderStepped = nil
                            end
                        end

                        local Descendants = SettingsItems["Settings"].Instance:GetDescendants()
                        TableInsert(Descendants, SettingsItems["Settings"].Instance)

                        local NewTween

                        for Index, Value in Descendants do
                            local TransparencyProperty = Tween:GetProperty(Value)

                            if not TransparencyProperty then
                                continue
                            end

                            if not Value.ClassName:find("UI") then
                                Value.ZIndex = Settings.IsOpen and 7 or 1
                                SettingsItems["Text"].Instance.ZIndex = 8
                            end

                            if type(TransparencyProperty) == "table" then
                                for _, Property in TransparencyProperty do
                                    NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                                end
                            else
                                NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                            end
                        end

                        NewTween.Tween.Completed:Connect(function()
                            Debounce = false
                            SettingsItems["Settings"].Instance.Visible = Settings.IsOpen
                            task.wait(0.2)
                            SettingsItems["Settings"].Instance.Parent = not Settings.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                        end)
                    end

                    SettingsItems["CloseButton"]:Connect("Activated", function()
                        Settings:SetOpen(false)
                    end)

                    Items["SettingsButton"]:Connect("Activated", function()
                        Settings:SetOpen(not Settings.IsOpen)
                    end)

                    Settings.Items = SettingsItems
                    setmetatable(Settings, Library.Sections)
                end

                Settings:Label("First gradient color"):Colorpicker({
                    Flag = "AccentColor",
                    Default = Library.Theme.Accent,
                    Callback = function(Color)
                        Library.Theme.Accent = Color
                        Library:ChangeTheme("Accent", Color)
                    end
                })

                Settings:Label("Second gradient color"):Colorpicker({
                    Flag = "AccentGradientColor",
                    Default = Library.Theme.AccentGradient,
                    Callback = function(Color)
                        Library.Theme.AccentGradient = Color
                        Library:ChangeTheme("AccentGradient", Color)
                    end
                })

                Settings:Dropdown({
                    Name = "Font weight",
                    Flag = "FontStyle",
                    Default = "SemiBold",
                    Items = {"Light", "Regular", "SemiBold"},
                    Callback = function(Value)
                        local FontData = Library.Fonts[Value]

                        if FontData then
                            Library.Font = FontData
                            Library:UpdateText()
                        end
                    end
                })

                Settings:Slider({
                    Name = "Background Transparency",
                    Default = 0.12,
                    Decimals = 0.01,
                    Max = 1,
                    Min = 0,
                    Suffix = "%",
                    Flag = "BackgroundTransparency",
                    Callback = function(Value)
                        Window:SetTransparency(Value)
                    end
                })

                Settings:Keybind({
                    Name = "Menu Keybind",
                    Flag = "MenuBind",
                    Default = Enum.KeyCode.Z,
                    Callback = function(Value)
                        Window:SetOpen(Value)
                    end
                })

                Window.Items = Items
            end

            local Debounce = false

            function Window:SetCenter()
                local CenterPosition = Items["MainFrame"].Instance.AbsolutePosition
                task.wait()
                Items["MainFrame"].Instance.AnchorPoint = Vector2New(0, 0)

                Items["MainFrame"].Instance.Position = UDim2New(0, CenterPosition.X, 0, CenterPosition.Y)
            end

            function Window:SetOpen(Bool)
                if Debounce then
                    return
                end

                Window.IsOpen = Bool

                Debounce = true

                if Window.IsOpen then
                    Items["MainFrame"].Instance.Visible = true
                end

                local Descendants = Items["MainFrame"].Instance:GetDescendants()
                TableInsert(Descendants, Items["MainFrame"].Instance)

                local NewTween

                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue
                    end

                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                NewTween.Tween.Completed:Connect(function()
                    Debounce = false
                    Items["MainFrame"].Instance.Visible = Window.IsOpen
                end)
            end

            if IsMobile then
                Items["FloatingButton"]:Connect("Activated", function()
                    Window:SetOpen(not Window.IsOpen)
                end)
            end

            --[[
            function Window:GetClosestFrame(Position, Instances)
                local ClosestRadius = math.huge
                local ClosestFrame

                local String = {"Items.LeftTabs", "Items.RightTabs", "Items.BottomTabs", "Items.TopTabs"}

                for Index, Value in (Instances or {Items.LeftTabs.Instance, Items.RightTabs.Instance, Items.BottomTabs.Instance, Items.TopTabs.Instance}) do
                    local Magnitude = (Vector2New(Value.AbsolutePosition.X, Value.AbsolutePosition.Y) - Position).Magnitude
                    if Magnitude < ClosestRadius then
                        ClosestFrame = String[Index]:gsub("Items.", "")
                        ClosestRadius = Magnitude
                    end
                end

                return ClosestFrame
            end

            function Window:UpdateTabs(CurrentAlignment)
                if CurrentAlignment == "TopTabs" or CurrentAlignment == "BottomTabs" then
                    for Index, Value in Window.Pages do
                        Value.Items.Inactive.Instance.Parent = Items[CurrentAlignment].Instance
                        Value.Items.Inactive.Instance.Size = UDim2New(0, 70, 0, 60)
                        Value.Items.Text.Instance.Position = UDim2New(0.5, 0, 1, -2)
                        Value.Items.Text.Instance.AnchorPoint = Vector2New(0.5, 1)
                        Value.Items.Icon.Instance.AnchorPoint = Vector2New(0.5, 0.5)
                        Value.Items.Gradient.Instance.Rotation = -90

                        if Value.Active then
                            Value.Items.Icon.Instance.Size = UDim2New(0, 32, 0, 32)
                            Value.Items.Icon.Instance.Position = UDim2New(0.5, 0, 0.5, 0)
                            Value.Items.Text.Instance.TextTransparency = 1
                        else
                            Value.Items.Icon.Instance.Size = UDim2New(0, 24, 0, 24)
                            Value.Items.Icon.Instance.Position = UDim2New(0.5, 0, 0.5, -8)
                            Value.Items.Text.Instance.TextTransparency = 0
                        end
                    end
                elseif CurrentAlignment == "LeftTabs" or CurrentAlignment == "RightTabs" then
                    for Index, Value in Window.Pages do
                        Value.Items.Inactive.Instance.Parent = Items[CurrentAlignment].Instance
                        Value.Items.Inactive.Instance.Size = UDim2New(0, 200, 0, 40)

                        Value.Items.Text.Instance.Position = UDim2New(45, 0, 0.5, 0)
                        Value.Items.Text.Instance.AnchorPoint = Vector2New(0, 0.5)

                        Value.Items.Icon.Instance.AnchorPoint = Vector2New(0, 0.5)
                        Value.Items.Icon.Instance.Position = UDim2New(16, 0, 0.5, 0)
                        Value.Items.Icon.Instance.Size = UDim2New(0, 18, 0, 18)

                        Value.Items.Gradient.Instance.Rotation = 0
                    end

                end
            end

            function Window:UpdateFrameSide(OldFrame, NewFrame)
                OldFrame.Instance.Visible = false
                NewFrame.Instance.Visible = true
                Window:UpdateTabs(Window.CurrentAlignment)
            end

            function Window:UpdateHighlight(CurrentFrame, Bool)
                if Bool then
                    CurrentFrame.Instance.Visible = false
                    Items["PagePlaceholder"].Instance.Visible = true
                else
                    CurrentFrame.Instance.Visible = true
                    Items["PagePlaceholder"].Instance.Visible = false
                end
            end

            for Index, Value in {"Left", "Top", "Bottom", "Right"} do
                local TabDragging = false
                local TabItem = Items[Value.."Tabs"]
                local SelectedParent

                TabItem:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        TabItem.Instance.Parent = Library.Holder.Instance
                        Window:UpdateHighlight(TabItem, true)
                        Items["PagePlaceholder"]:Tween(nil, {BackgroundTransparency = 0.3})
                        TabDragging = true
                    end
                end)

                TabItem:Connect("InputEnded", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        TabDragging = false

                        if SelectedParent then
                            Items["PagePlaceholder"]:Tween(nil, {BackgroundTransparency = 1})
                            Window:UpdateHighlight(TabItem, false)
                            Window:UpdateFrameSide(TabItem, Items[SelectedParent])
                            Window.CurrentAlignment = SelectedParent
                        end
                    end
                end)

                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement and TabDragging then
                        SelectedParent = Window:GetClosestFrame(Vector2New(Input.Position.X, Input.Position.Y - 36))
                        local TargetSize
                        local TargetPosition
                        local TargetAnchorPoint

                        if SelectedParent == "LeftTabs" then
                            TargetSize = UDim2New(0, 225, 1, 0)
                            TargetPosition = UDim2New(0, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(1, 0)
                        elseif SelectedParent == "RightTabs" then
                            TargetSize = UDim2New(0, 225, 1, 0)
                            TargetPosition = UDim2New(1, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(0, 0)
                        elseif SelectedParent == "TopTabs" then
                            TargetSize = UDim2New(1, 0, 0, 80)
                            TargetPosition = UDim2New(0, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(0, 1)
                        elseif SelectedParent == "BottomTabs" then
                            TargetSize = UDim2New(1, 0, 0, 90)
                            TargetPosition = UDim2New(0, 0, 1, 0)
                            TargetAnchorPoint = Vector2New(0, 0)
                        end

                        Items["PagePlaceholder"].Instance.AnchorPoint = TargetAnchorPoint
                        Items["PagePlaceholder"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = TargetSize})
                        Items["PagePlaceholder"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = TargetPosition})
                    end
                end)
            end
            --]]

            function Window:Init()
                for __, Value in Window.Pages do
                    if Value.Active then
                        for _, Value2 in Value.Sections do
                            task.spawn(function()
                                Value2:TweenElements(true)
                                -- Standalone window has no ConfigsDropdown; managed by adapter.
                            end)
                        end
                    end
                end
            end

            Library:Connect(UserInputService.InputBegan, function(Input)
                if tostring(Input.KeyCode) == Library.MenuKeybind or tostring(Input.UserInputType) == Library.MenuKeybind then
                    Window:SetOpen(not Window.IsOpen)
                end
            end)

            Window:SetCenter()
            task.wait()
            Window:SetOpen(true)
            return setmetatable(Window, Library)
        end

        Library.Watermark = function(self, Data)
            if not Library.WatermarkFrame then
                Library.WatermarkFrame = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "Watermark",
                    AnchorPoint = Vector2New(0, 0),
                    Position = UDim2New(0, 15, 0, 15),
                    Size = UDim2New(0, 0, 0, 28),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29),
                    ZIndex = 10,
                    Visible = false
                })
                Library.WatermarkFrame:MakeDraggable()

                Instances:Create("UICorner", {
                    Parent = Library.WatermarkFrame.Instance,
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIStroke", {
                    Parent = Library.WatermarkFrame.Instance,
                    Color = FromRGB(0, 0, 0),
                    Thickness = 1,
                    Transparency = 0
                })
                local AccentLine = Instances:Create("Frame", {
                    Parent = Library.WatermarkFrame.Instance,
                    Name = "Accent",
                    Size = UDim2New(1, 0, 0, 2),
                    Position = UDim2New(0, 0, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    ZIndex = 12
                })

                Instances:Create("UICorner", {
                    Parent = AccentLine.Instance,
                    CornerRadius = UDimNew(0, 4)
                })

                local Gradient = Instances:Create("UIGradient", {
                    Parent = AccentLine.Instance,
                    Color = RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent),
                        RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
                    }
                })

                Gradient:AddToTheme({
                    Color = function()
                        return RGBSequence{
                            RGBSequenceKeypoint(0, Library.Theme.Accent),
                            RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
                        }
                    end
                })

                local Content = Instances:Create("Frame", {
                    Parent = Library.WatermarkFrame.Instance,
                    Name = "Content",
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 11
                })

                Instances:Create("UIListLayout", {
                    Parent = Content.Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDimNew(0, 6)
                })

                Instances:Create("UIPadding", {
                    Parent = Content.Instance,
                    PaddingLeft = UDimNew(0, 10),
                    PaddingRight = UDimNew(0, 10),
                    PaddingTop = UDimNew(0, 4)
                })

                if Library.ToClean then
                    table.insert(Library.ToClean, Library.WatermarkFrame.Instance)
                end
            end

            local ContentFrame = Library.WatermarkFrame.Instance:FindFirstChild("Content")
            for Index, Value in ipairs(Data) do
                if Index > 1 then
                    local SepName = "Sep_" .. Index
                    local Sep = ContentFrame:FindFirstChild(SepName)
                    if not Sep then
                        Sep = Instances:Create("TextLabel", {
                            Parent = ContentFrame,
                            Name = SepName,
                            Text = "|",
                            TextColor3 = FromRGB(80, 80, 80),
                            FontFace = Library.Font,
                            TextSize = 14,
                            BackgroundTransparency = 1,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            LayoutOrder = (Index * 2) - 1,
                            ZIndex = 11
                        }).Instance
                    end
                end

                local ItemName = "Item_" .. Index
                local ExistingItem = ContentFrame:FindFirstChild(ItemName)

                local Type = type(Value)
                local IsImage = (Type == "number" or (Type == "string" and string.find(Value, "rbxassetid")))

                if ExistingItem then
                    if IsImage and not ExistingItem:IsA("ImageLabel") then
                        ExistingItem:Destroy()
                        ExistingItem = nil
                    elseif not IsImage and not ExistingItem:IsA("TextLabel") then
                        ExistingItem:Destroy()
                        ExistingItem = nil
                    end
                end

                if not ExistingItem then
                    if IsImage then
                        ExistingItem = Instances:Create("ImageLabel", {
                            Parent = ContentFrame,
                            Name = ItemName,
                            BackgroundTransparency = 1,
                            Size = UDim2New(0, 14, 0, 14),
                            ImageColor3 = FromRGB(255, 255, 255),
                            LayoutOrder = Index * 2,
                            ZIndex = 11
                        }).Instance
                    else
                        ExistingItem = Instances:Create("TextLabel", {
                            Parent = ContentFrame,
                            Name = ItemName,
                            TextColor3 = FromRGB(240, 240, 240),
                            FontFace = Library.Font,
                            TextSize = 13,
                            BackgroundTransparency = 1,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            LayoutOrder = Index * 2,
                            ZIndex = 11
                        }).Instance
                    end
                end

                if IsImage then
                    local ImageId = (Type == "number") and "rbxassetid://"..Value or Value
                    if ExistingItem.Image ~= ImageId then
                        ExistingItem.Image = ImageId
                    end
                else
                    local TextVal = tostring(Value)
                    if ExistingItem.Text ~= TextVal then
                        ExistingItem.Text = TextVal
                    end
                end
            end

            for _, Child in pairs(ContentFrame:GetChildren()) do
                if Child.Name:find("Item_") or Child.Name:find("Sep_") then
                    local _, IndexStr = Child.Name:match("(%a+)_(%d+)")
                    local Index = tonumber(IndexStr)
                    if Index and Index > #Data then
                        Child:Destroy()
                    end
                end
            end
        end

        Library.Category = function(self, Name)
            local Items = { } do
                Items["Category"] = Instances:Create("TextLabel", {
                    Parent = self.Items["LeftTabs"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.4000000059604645,
                    Text = Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Category"]:AddToTheme({TextColor3 = "Text"})
            end
        end

        Library.Page = function(self, Data)
            Data = Data or { }
            if IsMobile then Data.Columns = 1 end

            local Page = {
                Window = self,

                Name = Data.Name or Data.name or "Page",
                Icon = Data.Icon or Data.icon or "100050851789190",
                Columns = Data.Columns or Data.columns or 2,

                Items = { },
                ColumnsData = { },
                Sections = { },
                Active = false
            }

            local Items = { } do
                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = Page.Window.Items["LeftTabs"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 200, 0, 40),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })  Items["Inactive"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items.Gradient = Instances:Create("UIGradient", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 0.41874998807907104), NumSequenceKeypoint(0.445, 0.78125), NumSequenceKeypoint(0.751, 0.9375), NumSequenceKeypoint(1, 1)}
                })

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 18, 0, 18),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://"..Page.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 16, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Icon"]:AddToTheme({ImageColor3 = "Accent"})

                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Page.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 45, 0.5, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["Page"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    Position = UDim2New(0, 0, 0, 60),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDimNew(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalFlex = Enum.UIFlexAlignment.Fill
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 10),
                    PaddingBottom = UDimNew(0, 10),
                    PaddingRight = UDimNew(0, 10),
                    PaddingLeft = UDimNew(0, 10)
                })

                for Index = 1, Page.Columns do
                    local NewColumn = Instances:Create("ScrollingFrame", {
                        Parent = Items["Page"].Instance,
                        Name = "\0",
                        ScrollBarImageColor3 = FromRGB(0, 0, 0),
                        Active = true,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollBarThickness = 0,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 100, 0, 100),
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = NewColumn.Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Page.ColumnsData[Index] = NewColumn
                end

                Page.Items = Items
            end

            local Debounce = false

            function Page:Turn(Bool)
                if Debounce then
                    return
                end

                Page.Active = Bool

                Debounce = true
                Items["Page"].Instance.Visible = Bool
                Items["Page"].Instance.Parent = Bool and Page.Window.Items["Content"].Instance or Library.UnusedHolder.Instance

                if Page.Active then
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 0.25})
                    Items["Page"]:Tween(TweenInfo.new(IsMobile and 0.12 or 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})

                    for Index, Value in Page.Sections do
                        task.spawn(function()
                            Value:TweenElements(true)
                        end)
                    end
                else
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1})
                    Items["Page"]:Tween(TweenInfo.new(IsMobile and 0.12 or 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 60)})
                end

                local AllInstances = Items["Page"].Instance:GetDescendants()
                TableInsert(AllInstances, Items["Page"].Instance)

                local NewTween

                for Index, Value in AllInstances do
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue
                    end

                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false

                    if not Page.Active then
                        for Index, Value in Page.Sections do
                            task.spawn(function()
                                Value:TweenElements(false, true)
                            end)
                        end
                    end
                end)
            end

            Items["Inactive"]:Connect("Activated", function()
                if Page.Active then return end
                for _, other in Page.Window.Pages do
                    local want = other == Page
                    if other.Active ~= want then other:Turn(want) end
                end
            end)

            if #Page.Window.Pages == 0 then
                Page:Turn(true)
            end

            TableInsert(Page.Window.Pages, Page)
            return setmetatable(Page, Library.Pages)
        end

        Library.Pages.GlobalChat = function(self, Side)
            local GlobalChat = { }
            Library.GlobalChatt = GlobalChat

            local Items = { } do
                Items["GlobalChat"] = Instances:Create("Frame", {
                    Parent = self.ColumnsData[Side].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.30000001192092896,
                    Position = UDim2New(0,0,0,0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["GlobalChat"]:AddToTheme({BackgroundColor3 = "Section Background 2"})

                Items["GlobalChat"]:MakeDraggable()

                Instances:Create("UICorner", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "GLOBAL CHAT",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 13),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 16,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["SubTitle"] = Instances:Create("TextLabel", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.4000000059604645,
                    Text = "Chat with other users here.",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 14, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SubTitle"]:AddToTheme({TextColor3 = "Text"})

                Items["Message"] = Instances:Create("Frame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Selectable = true,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 1, -12),
                    Size = UDim2New(1, -66, 0, 32),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Message"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Message"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Message"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    Selectable = true,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, -20, 0, 15),
                    Position = UDim2New(0, 10, 0, 8),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = "Message...",
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text"})

                Items["SendButton"] = Instances:Create("TextButton", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 1),
                    Position = UDim2New(1, -12, 1, -12),
                    Size = UDim2New(0, 32, 0, 32),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["SendButton"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["SendIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ImageTransparency = 0.2,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://101636617799068",
                    BackgroundTransparency = 1,
                    ZIndex = 3,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 22, 0, 22),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["SendButton"]:OnHover(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time+0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                end)

                Items["SendButton"]:OnHoverLeave(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time+0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                end)

                Items["Messages"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    ScrollBarImageColor3 = FromRGB(124, 163, 255),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -24, 1, -115),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 60),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Messages"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Messages"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Messages"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 0),
                    PaddingBottom = UDimNew(0, 0),
                    PaddingRight = UDimNew(0, 10),
                    PaddingLeft = UDimNew(0, 0)
                })

                Items["Status"] = Instances:Create("Frame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -12, 0, 10),
                    Size = UDim2New(0, 100, 0, 20),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["StatusCircle"] = Instances:Create("Frame", {
                    Parent = Items["Status"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 210, 62)
                })

                Items["Glow"] = Instances:Create("ImageLabel", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 210, 62),
                    ScaleType = Enum.ScaleType.Slice,
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    Size = UDim2New(1, 8, 1, 8),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "http://www.roblox.com/asset/?id=18245826428",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    SliceCenter = RectNew(Vector2New(21, 21), Vector2New(79, 79))
                })

                Instances:Create("UICorner", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["StatusText"] = Instances:Create("TextLabel", {
                    Parent = Items["Status"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 210, 62),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "67 Active | Connected",
                    AnchorPoint = Vector2New(1, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -20, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
            end

            function GlobalChat:SetVisibility(Bool)
                Items["GlobalChat"].Instance.Visible = Bool
                Items["GlobalChat"].Instance.Parent = Bool and Data.MainFrame.Instance or Library.UnusedHolder
            end

            function GlobalChat:SetStatus(Text, Color)
                Items["StatusText"].Instance.Text = Text
                Items["StatusText"].Instance.TextColor3 = Color
                Items["StatusCircle"].Instance.BackgroundColor3 = Color
            end

            function GlobalChat:SetStatusText(Text)
                if not Done then
                    Items["StatusText"].Instance.TextColor3 = FromRGB(62, 255, 91)
                    Items["Glow"].Instance.ImageColor3 = FromRGB(62, 255, 91)
                    Items["StatusCircle"].Instance.BackgroundColor3 = FromRGB(62, 255, 91)
                    Done = true
                end
                Items["StatusText"].Instance.Text = Text
            end

            local OnMessagePressed

            function GlobalChat:OnMessageSendPressed(Func)
                OnMessagePressed = Func
            end

            function GlobalChat:GetTypedMessage()
                return Items["Input"].Instance.Text
            end

            function GlobalChat:ClearText()
                Items["Input"].Instance.Text = ""
            end

            function GlobalChat:SendMessage(Avatar, Username, Message, IsLocalPlayer)
                local SubItems = { } do
                    if not IsLocalPlayer then
                        SubItems["Message1"] = Instances:Create("Frame", {
                            Parent = Items["Messages"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 45),
                            ZIndex = 2,
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        SubItems["PlayerName"] = Instances:Create("TextLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Username,
                            Size = UDim2New(0, 0, 0, 15),
                            BackgroundTransparency = 1,
                            RichText = true,
                            Position = UDim2New(0, 38, 0, 0),
                            TextTransparency = 0.3,
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.X,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["PlayerName"]:AddToTheme({TextColor3 = "Text"})

                        SubItems["RealMessage"] = Instances:Create("Frame", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            Position = UDim2New(0, 38, 0, 20),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            BackgroundColor3 = FromRGB(27, 25, 29)
                        })  SubItems["RealMessage"]:AddToTheme({BackgroundColor3 = "Background"})

                        Instances:Create("UISizeConstraint", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            MaxSize = Vector2New(370, 70)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })

                        SubItems["MessageText"] = Instances:Create("TextLabel", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Message,
                            BackgroundTransparency = 1,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            TextSize = 14,
                            ZIndex = 2,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["MessageText"]:AddToTheme({TextColor3 = "Text"})

                        Instances:Create("UIPadding", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 10),
                            PaddingBottom = UDimNew(0, 10),
                            PaddingRight = UDimNew(0, 10),
                            PaddingLeft = UDimNew(0, 10)
                        })

                        SubItems["Avatar"] = Instances:Create("ImageLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(0, 0.5),
                            Image = Avatar,
                            BackgroundTransparency = 1,
                            Position = UDim2New(0, 0, 0.5, 0),
                            Size = UDim2New(0, 30, 0, 30),
                            ZIndex = 2,
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["Avatar"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })
                    else
                        SubItems["Message1"] = Instances:Create("Frame", {
                            Parent = Items["Messages"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 45),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        SubItems["PlayerName"] = Instances:Create("TextLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Username,
                            RichText = true,
                            AnchorPoint = Vector2New(1, 0),
                            Size = UDim2New(0, 0, 0, 15),
                            ZIndex = 2,
                            TextTransparency = 0.3,
                            BackgroundTransparency = 1,
                            Position = UDim2New(1, -38, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.X,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["PlayerName"]:AddToTheme({TextColor3 = "Text"})

                        SubItems["RealMessage"] = Instances:Create("Frame", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            AnchorPoint = Vector2New(1, 0),
                            Position = UDim2New(1, -38, 0, 20),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            BackgroundColor3 = FromRGB(27, 25, 29)
                        })  SubItems["RealMessage"]:AddToTheme({BackgroundColor3 = "Background"})

                        Instances:Create("UISizeConstraint", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            MaxSize = Vector2New(370, 75)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })

                        SubItems["MessageText"] = Instances:Create("TextLabel", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Message,
                            BackgroundTransparency = 1,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            ZIndex = 2,
                            TextWrapped = true,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["MessageText"]:AddToTheme({TextColor3 = "Text"})

                        Instances:Create("UIPadding", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 10),
                            PaddingBottom = UDimNew(0, 10),
                            PaddingRight = UDimNew(0, 10),
                            PaddingLeft = UDimNew(0, 10)
                        })

                        SubItems["Avatar"] = Instances:Create("ImageLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(1, 0.5),
                            Image = Avatar,
                            ZIndex = 2,
                            BackgroundTransparency = 1,
                            Position = UDim2New(1, 0, 0.5, 0),
                            Size = UDim2New(0, 30, 0, 30),
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["Avatar"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })
                    end
                end
            end

            Items["SendButton"]:Connect("Activated", function()
                if GlobalChat:GetTypedMessage() == "" then
                    return
                end

                OnMessagePressed()
            end)

            Items["Messages"]:Connect("ChildAdded", function()
                task.wait()
                Items["Messages"]:Tween(nil, {CanvasPosition = Vector2New(0, Items["Messages"].Instance.AbsoluteCanvasSize.Y - Items["Messages"].Instance.AbsoluteSize.Y)})
            end)

            for Index, Value in Items["GlobalChat"].Instance:GetDescendants() do
                if Value.ClassName:find("UI") then
                    continue
                end

                Value.ZIndex = 2
            end

            Items["GlobalChat"].Instance.ZIndex = 2
            Items["SendIcon"].Instance.ZIndex = 3

            return GlobalChat
        end

        Library.Pages.Section = function(self, Data)
            Data = Data or { }

            local Section = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "Section",
                Description = Data.Description or Data.Description or "",
                Icon = Data.Icon or Data.icon or "123944728972740",
                Side = Data.Side or Data.side or 1,
                EnableToggle = Data.EnableToggle or Data.enabletoggle or false,

                Items = { },
                IsActive = true,
                Elements = { }
            }

            local Items = { } do
                Items["Section"] = Instances:Create("Frame", {
                    Parent = Section.Page.ColumnsData[Section.Side].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 45),
                    ZIndex = 2,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(29, 28, 32)
                })  Items["Section"]:AddToTheme({BackgroundColor3 = "Section Background 2"})

                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.6499999761581421,
                    Size = UDim2New(1, 0, 0, 55),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                })  Items["Top"]:AddToTheme({BackgroundColor3 = "Outline"})

                Items["TopBackground"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 1, 0, 1),
                    Size = UDim2New(1, -2, 1, -2),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["TopBackground"]:AddToTheme({BackgroundColor3 = "Section Top"})

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 21, 0, 20),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://"..Section.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Description"] = Instances:Create("TextLabel", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(183, 183, 183),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Section.Description,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 50, 0, 28),
                    BorderSizePixel = 0,
                    TextTransparency = 0.4,
                    ZIndex = 2,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Description"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UICorner", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(248, 248, 248),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Section.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    -- Сохранил твою логику центрирования из прошлого вопроса
                    Position = (Section.Description == "") and UDim2New(0, 50, 0, 19) or UDim2New(0, 50, 0, 10),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    Active = false,
                    -- ДОБАВЛЕНО: Видимость зависит от параметра EnableToggle
                    Visible = Section.EnableToggle,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Selectable = false,
                    Position = UDim2New(1, -15, 0.5, 0),
                    Size = UDim2New(0, 26, 0, 16),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Circle"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, -4, 0.5, 0),
                    Size = UDim2New(0, 8, 0, 8),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Circle"]:AddToTheme({BackgroundColor3 = "Text"})

                Instances:Create("UICorner", {
                    Parent = Items["Circle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 99999)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 9)
                })

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Fill"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 1, 1, -4),
                    Size = UDim2New(1, -2, 0, 4),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Fill"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Instances:Create("UICorner", {
                    Parent = Items["Fill"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["TopFills"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 3),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Right1"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -1, 0, 0),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right1"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["Right2"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -1, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right2"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["Right3"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -2, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right3"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["Left1"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 2, 0, 0),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left1"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["Left2"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 2, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left2"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["Left3"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 3, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left3"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Instances:Create("UICorner", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 1, 0, 55),
                    Size = UDim2New(1, -2, 1, -56),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(24, 22, 25)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 15),
                    Size = UDim2New(1, -24, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Items["Fade"] = Instances:Create("TextButton", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 10, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    Visible = false,
                    Text = "",
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(24, 22, 25)
                })  Items["Fade"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Instances:Create("UICorner", {
                    Parent = Items["Fade"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 10)
                })

                Section.Items = Items
            end

            function Section:ToggleBackground()
                Section.IsActive = not Section.IsActive

                if not Section.IsActive then
                    Items["Fade"].Instance.Visible = true
                    Items["Fade"]:Tween(nil, {BackgroundTransparency = 0.3})

                    Items["Gradient"].Instance.Enabled = false
                    Items["Toggle"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                    Items["Toggle"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                    Items["Circle"]:Tween(nil, {AnchorPoint = Vector2New(0, 0.5), Position = UDim2New(0, 4, 0.5, 0), BackgroundColor3 = Library.Theme.Text, BackgroundTransparency = 0.6})
                else
                    Items["Fade"]:Tween(nil, {BackgroundTransparency = 1})
                    task.spawn(function()
                        task.wait(Library.Tween.Time)
                        Items["Fade"].Instance.Visible = false
                    end)

                    Items["Gradient"].Instance.Enabled = true
                    Items["Toggle"]:ChangeItemTheme({BackgroundColor3 = "Text"})
                    Items["Toggle"]:Tween(nil, {BackgroundColor3 = Library.Theme.Text})
                    Items["Circle"]:Tween(nil, {AnchorPoint = Vector2New(1, 0.5), Position = UDim2New(1, -4, 0.5, 0), BackgroundColor3 = Library.Theme.Text, BackgroundTransparency = 0})
                end
            end

            Library:Connect(Items["Content"].Instance.Changed, function(Property)
                if Property == "AbsoluteSize" then
                    Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Items["Content"].Instance.AbsoluteSize.Y + 10)
                end
            end)

            function Section:TweenElements(Bool, Debounce)
                for Index, Value in Section.Elements do
                    Value:RefreshPosition(Bool)
                    if not Debounce and not IsMobile then
                        task.wait(0.01)
                    end
                end
            end

            Items["Toggle"]:Connect("Activated", function()
                Section:ToggleBackground()
            end)

            Section.Page.Sections[Section.Name] = Section

            return setmetatable(Section, Library.Sections)
        end

        Library.Sections.Toggle = function(self, Data)
            Data = Data or { }

            local Toggle = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Toggle",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or false,
                Callback = Data.Callback or Data.callback or function() end,

                Value = false
            }

            local Items = { } do
                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Toggle.Section.Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, IsMobile and 38 or 18),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Indicator"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 18, 0, 18),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })  Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })

                Items["CheckImage"] = Instances:Create("ImageLabel", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://121760666525660",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    ImageTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["CheckImage"]:AddToTheme({ImageColor3 = "Text"})

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Toggle.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    Position = UDim2New(0, 24, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Toggle"]:OnHover(function()
                    Items["Indicator"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 21, 0, 21), Position = UDim2New(0, -3, 0, -3)})
                end)

                Items["Toggle"]:OnHoverLeave(function()
                    Items["Indicator"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 18, 0, 18), Position = UDim2New(0, 0, 0, 0)})
                end)
            end

            Items["Indicator"].Instance.Position = UDim2New(0, 60, 0, 0)
            Items["Text"].Instance.Position = UDim2New(0, 84, 0, 0)

            --Toggle.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Toggle.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            function Toggle:Get()
                return Toggle.Value
            end

            function Toggle:Set(Value)
                Toggle.Value = Value
                Library.Flags[Toggle.Flag] = Value

                if Toggle.Value then
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2New(1, 0, 1, 0)})
                    Items["CheckImage"]:Tween(nil, {ImageTransparency = 0, Size = UDim2New(0, 10, 0, 9)})

                    --Items["Gradient"].Instance.Enabled = true
                else
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.05, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2New(0, 0, 0, 0)})
                    Items["CheckImage"]:Tween(nil, {ImageTransparency = 1, Size = UDim2New(0, 0, 0, 0)})

                    --Items["Gradient"].Instance.Enabled = false
                end

                if Toggle.Callback then
                    Library:SafeCall(Toggle.Callback, Toggle.Value)
                end
            end

            local SettingsItem = { }

            function Toggle:Settings(Size)
                local Settings = {
                    IsOpen = false,
                    Name = "",
                    Items = { },
                    IsSettings = true,
                    Elements = { }
                }
                Toggle.Settings = Settings

                SettingsItem = { } do
                    SettingsItem["Settings"] = Instances:Create("Frame", {
                        Parent = Library.UnusedHolder.Instance,
                        Name = "\0",
                        Visible = false,
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        Position = UDim2New(0.8949604630470276, 0, 0.2945185601711273, 0),
                        Size = UDim2New(0, 245, 0, 159),
                        ZIndex = 2,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = FromRGB(21, 21, 24)
                    })  SettingsItem["Settings"]:AddToTheme({BackgroundColor3 = "Background"})

                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6)
                    })

                    SettingsItem["SettingsIcon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Text"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(141, 141, 150),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 14, 0, 14),
                        AnchorPoint = Vector2New(0, 0.5),
                        Image = "rbxassetid://101500482366184",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, 6, 0.5, 1),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["SettingsIcon"] = SettingsItem["SettingsIcon"]

                    SettingsItem["Content"] = Instances:Create("ScrollingFrame", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Selectable = false,
                        Size = UDim2New(1, -8, 1, -46),
                        Position = UDim2New(0, 4, 0, 4),
                        ScrollBarThickness = 2,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })  SettingsItem["Content"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                    Instances:Create("UIListLayout", {
                        Parent = SettingsItem["Content"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Instances:Create("UIPadding", {
                        Parent = SettingsItem["Content"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 4),
                        PaddingBottom = UDimNew(0, 4),
                        PaddingRight = UDimNew(0, 4),
                        PaddingLeft = UDimNew(0, 4)
                    })

                    SettingsItem["Button"] = Instances:Create("TextButton", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, -16, 0, 32),
                        ZIndex = 2,
                        AnchorPoint = Vector2New(0, 1),
                        Position = UDim2New(0, 8, 1, -8),
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    })  SettingsItem["Button"]:AddToTheme({BackgroundColor3 = "Element"})

                    SettingsItem["Accent"] = Instances:Create("Frame", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0)
                    })  --SettingsItem["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                    SettingsItem["Gradient"] = Instances:Create("UIGradient", {
                        Parent = SettingsItem["Accent"].Instance,
                        Name = "\0",
                        Enabled = true,
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    })  SettingsItem["Gradient"]:AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})

                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Accent"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    SettingsItem["Text"] = Instances:Create("TextLabel", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        TextTransparency = 0.30000001192092896,
                        Text = "Close",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  SettingsItem["Text"]:AddToTheme({TextColor3 = "Text"})

                    SettingsItem["Button"]:OnHover(function()
                        SettingsItem["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                    end)

                    SettingsItem["Button"]:OnHoverLeave(function()
                        SettingsItem["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                    end)
                end

                local RenderStepped
                local Debounce = false

                function Settings:SetOpen(Bool)
                    if Debounce then
                        return
                    end

                    Settings.IsOpen = Bool

                    Debounce = true

                    if Settings.IsOpen then
                        task.spawn(function()
                            for Index, Value in Settings.Elements do
                                Value:RefreshPosition(true)
                                task.wait(0.03)
                            end
                        end)

                        SettingsItem["Settings"].Instance.Visible = true
                        SettingsItem["Settings"].Instance.Parent = Library.Holder.Instance

                        RenderStepped = RunService.RenderStepped:Connect(function()
                            SettingsItem["Settings"].Instance.Position = UDim2New(
                                0, Items["Toggle"].Instance.AbsolutePosition.X + Items["Toggle"].Instance.AbsoluteSize.X / 1.9 + 15,
                                0, Items["Toggle"].Instance.AbsolutePosition.Y + Items["Toggle"].Instance.AbsoluteSize.Y + Size / 1.9)
                            SettingsItem["Settings"].Instance.Size = UDim2New(0, 245, 0, Size)
                        end)

                        for Index, Value in Library.OpenFrames do
                            if Value ~= Settings then
                                Value:SetOpen(false)
                            end
                        end

                        Library.OpenFrames[Settings] = Settings
                    else
                        for Index, Value in Settings.Elements do
                            Value:RefreshPosition(false)
                        end

                        if Library.OpenFrames[Settings] then
                            Library.OpenFrames[Settings] = nil
                        end

                        if RenderStepped then
                            RenderStepped:Disconnect()
                            RenderStepped = nil
                        end
                    end

                    local Descendants = SettingsItem["Settings"].Instance:GetDescendants()
                    TableInsert(Descendants, SettingsItem["Settings"].Instance)

                    local NewTween

                    for Index, Value in Descendants do
                        local TransparencyProperty = Tween:GetProperty(Value)

                        if not TransparencyProperty then
                            continue
                        end

                        if not Value.ClassName:find("UI") then
                            Value.ZIndex = Settings.IsOpen and 7 or 1
                        end

                        if type(TransparencyProperty) == "table" then
                            for _, Property in TransparencyProperty do
                                NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                            end
                        else
                            NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                        end
                    end

                    NewTween.Tween.Completed:Connect(function()
                        Debounce = false
                        SettingsItem["Settings"].Instance.Visible = Settings.IsOpen
                        task.wait(0.2)
                        SettingsItem["Settings"].Instance.Parent = not Settings.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                    end)
                end

                SettingsItem["Button"]:Connect("Activated", function()
                    Settings:SetOpen(false)
                end)

                SettingsItem["SettingsIcon"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Settings:SetOpen(not Settings.IsOpen)
                    end
                end)

                Library:Connect(UserInputService.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        if Library:IsMouseOverFrame(SettingsItem["Settings"],Input) then
                            return
                        end

                        Settings:SetOpen(false)
                    end
                end)

                Settings.Items = SettingsItem

                setmetatable(Settings, Library.Sections)
                return Settings
            end

            function Toggle:SetVisibility(Bool)
                Items["Toggle"].Instance.Visible = Bool
            end

            function Toggle:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end,
                    Alpha = Data.Alpha or Data.alpha or false
                }

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["SubElements"],
                    Page = Colorpicker.Page,
                    Section = Colorpicker.Section,
                    Flag = Colorpicker.Flag,
                    Default = Colorpicker.Default,
                    Callback = Colorpicker.Callback,
                    Alpha = Colorpicker.Alpha
                })

                return NewColorpicker
            end

            function Toggle:Keybind(Data)
                Data = Data or { }

                local Keybind = {
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.E,
                    Callback = Data.Callback or Data.callback or function() end,
                    Mode = Data.Mode or Data.mode or "Toggle"
                }

                local NewKeybind, KeybindItems = Library:CreateKeybind({
                    Parent = Items["SubElements"],
                    Page = Keybind.Page,
                    Section = Keybind.Section,
                    Flag = Keybind.Flag,
                    Default = Keybind.Default,
                    Mode = Keybind.Mode,
                    Callback = Keybind.Callback
                })

                return NewKeybind
            end

            function Toggle:RefreshPosition(Bool)
                if Bool then
                    Items["Indicator"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 24, 0, 0)})
                else
                    Items["Indicator"].Instance.Position = UDim2New(0, 60, 0, 0)
                    Items["Text"].Instance.Position = UDim2New(0, 84, 0, 0)
                end
            end

            Items["Toggle"]:Connect("Activated", function()
                -- Activated fires on a completed tap/click, not on scroll gestures.
                Toggle:Set(not Toggle.Value)
            end)

            Toggle:Set(Toggle.Default)

            Library.SetFlags[Toggle.Flag] = function(Value)
                Toggle:Set(Value)
            end

            Toggle.Section.Elements[#Toggle.Section.Elements+1] = Toggle

            return Toggle
        end

        Library.Sections.Button = function(self, Data)
            Data = Data or { }

            local Button = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Button",
                Icon = Data.Icon or Data.icon or nil,
                Callback = Data.Callback or Data.callback or function() end
            }

            local Items = { } do
                Items["Button"] = Instances:Create("TextButton", {
                    Parent = Button.Section.Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, IsMobile and 42 or 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Button"]:AddToTheme({BackgroundColor3 = "Element"})

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Button.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                if Button.Icon then
                    Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Text"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(240, 240, 240),
                        ImageTransparency = 0.30000001192092896,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 18, 0, 18),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = "rbxassetid://"..Button.Icon,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, -8, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["Icon"]:AddToTheme({ImageColor3 = "Text"})
                end

                Items["Button"]:OnHover(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                end)

                Items["Button"]:OnHoverLeave(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                end)
            end

            --Button.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Button.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            function Button:SetVisibility(Bool)
                Items["Button"].Instance.Visible = Bool
            end

            function Button:Press()
                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})

                Items["Text"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0), TextTransparency = 0})

                if Button.Icon then
                    Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(0, 0, 0), ImageTransparency = 0})
                end

                task.wait(0.2)

                Library:SafeCall(Button.Callback)
                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})

                Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Text, TextTransparency = 0.3})

                if Button.Icon then
                    Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Text, ImageTransparency = 0.3})
                end
            end

            Items["Button"]:Connect("Activated", function()
                Button:Press()
            end)

            return Button
        end

        Library.Sections.Slider = function(self, Data)
            Data = Data or { }

            local Slider = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Slider",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Min = Data.Min or Data.min or 0,
                Default = Data.Default or Data.default or 0,
                Max = Data.Max or Data.max or 100,
                Suffix = Data.Suffix or Data.suffix or "",
                Decimals = Data.Decimals or Data.decimals or 1,
                Callback = Data.Callback or Data.callback or function() end,

                Value = 0,
                Sliding = false
            }

            local Items = { } do
                Items["Slider"] = Instances:Create("Frame", {
                    Parent = Slider.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, IsMobile and 46 or 35),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Slider.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["RealSlider"] = Instances:Create("TextButton", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 20, 1, -3),
                    Size = UDim2New(1, -40, 0, IsMobile and 22 or 7),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["RealSlider"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0"
                })

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    Size = UDim2New(0.5, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0"
                })

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 12),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://117786983271442",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Rotation = -102,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Plus"] = Instances:Create("TextButton", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "+",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, IsMobile and 30 or 20, 0, IsMobile and 30 or 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0.5, -3),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Plus"]:AddToTheme({TextColor3 = "Text"})

                Items["Minus"] = Instances:Create("TextButton", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "-",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Size = UDim2New(0, IsMobile and 30 or 20, 0, IsMobile and 30 or 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, -2, 0.5, -2),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Minus"]:AddToTheme({TextColor3 = "Text"})

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "50%",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})

                Items["RealSlider"]:OnHover(function()
                    Items["Icon"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 18, 0, 14)})
                end)

                Items["RealSlider"]:OnHoverLeave(function()
                    Items["Icon"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 16, 0, 12)})
                end)
            end

            --Slider.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Slider.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            --Items["Value"].Instance.TextTransparency = 1
            Items["RealSlider"].Instance.Position = UDim2New(0, 80, 1, -3)
            Items["Text"].Instance.Position = UDim2New(0, 80, 0, 0)

            function Slider:Get()
                return Slider.Value
            end

            function Slider:SetVisibility(Bool)
                Items["Slider"].Instance.Visible = Bool
            end

            function Slider:RefreshPosition(Bool)
                if Bool then
                    Items["RealSlider"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 20, 1, -3)})
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                -- Items["Value"].Instance.TextTransparency = 0.3
                else
                    Items["RealSlider"].Instance.Position = UDim2New(0, 80, 1, -3)
                    Items["Text"].Instance.Position = UDim2New(0, 80, 0, 0)
                -- Items["Value"].Instance.TextTransparency = 1
                end
            end

            function Slider:Set(Value)
                Slider.Value = Library:Round(MathClamp(Value, Slider.Min, Slider.Max), Slider.Decimals)
                Library.Flags[Slider.Flag] = Slider.Value

                Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0)})
                Items["Value"].Instance.Text = StringFormat("%s%s", Slider.Value, Slider.Suffix)

                if Slider.Value >= Slider.Max then
                    Items["Icon"].Instance.Position = UDim2New(1, -5, 0.5, 0)
                else
                    Items["Icon"].Instance.Position = UDim2New(1, 5, 0.5, 0)
                end

                if Slider.Callback then
                    Library:SafeCall(Slider.Callback, Slider.Value)
                end
            end

            Items["Plus"]:Connect("Activated", function()
                Slider:Set(Slider.Value + Slider.Decimals)
            end)

            Items["Minus"]:Connect("Activated", function()
                Slider:Set(Slider.Value - Slider.Decimals)
            end)

            local InputChanged
            local ActiveSliderPointer

            Items["RealSlider"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if ActiveSliderPointer and ActiveSliderPointer ~= Input then return end
                    Slider.Sliding = true
                    ActiveSliderPointer = Input

                    local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / math.max(1, Items["RealSlider"].Instance.AbsoluteSize.X)
                    local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                    Slider:Set(Value)

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Slider.Sliding = false
                            ActiveSliderPointer = nil

                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Slider.Sliding and ActiveSliderPointer and
                        (Input == ActiveSliderPointer or
                        (ActiveSliderPointer.UserInputType == Enum.UserInputType.MouseButton1 and Input.UserInputType == Enum.UserInputType.MouseMovement)) then
                        local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / math.max(1, Items["RealSlider"].Instance.AbsoluteSize.X)
                        local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                        Slider:Set(Value)
                    end
                end
            end)

            if Slider.Default then
                Slider:Set(Slider.Default)
            end

            Library.SetFlags[Slider.Flag] = function(Value)
                Slider:Set(Value)
            end

            Slider.Section.Elements[#Slider.Section.Elements+1] = Slider
            return Slider
        end

        Library.Sections.Dropdown = function(self, Data)
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Dropdown",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or { "One", "Two", "Three" },
                Default = Data.Default or Data.default or nil,
                Callback = Data.Callback or Data.callback or function() end,
                Size = Data.Size or Data.size or 125,
                OptionHolderSize = Data.OptionHolderSize or Data.optionholder or 125,
                Multi = Data.Multi or Data.multi or false,

                Value = { },
                Options = { },
                OptionsWithIndexes = { },
                IsOpen = false
            }

            local Items = { } do
                Items["Dropdown"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, IsMobile and 40 or 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Dropdown.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["RealDropdown"] = Instances:Create("TextButton", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    Size = UDim2New(0, IsMobile and 144 or (Dropdown.Size or 125), 0, IsMobile and 40 or 25),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "-",
                    Size = UDim2New(1, -40, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, -1),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})

                Items["Liner"] = Instances:Create("Frame", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, -25, 0, 0),
                    Size = UDim2New(0, 2, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 32, 36)
                })  Items["Liner"]:AddToTheme({BackgroundColor3 = "Outline"})

                Items["ArrowIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(141, 141, 150),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 8),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://123317177279443",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["ArrowIcon"].Instance,
                    Name = "\0",
                    Enabled = false,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["OptionHolder"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0, 897, 0, 101),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 159, 0, 87),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UIStroke", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 33, 38),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Outline"})

                Instances:Create("UICorner", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -16, 1, -16),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0, 8),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            --ropdown.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Dropdown.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
            Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:SetVisibility(Bool)
                Items["Dropdown"].Instance.Visible = Bool
            end

            function Dropdown:RefreshPosition(Bool)
                if Bool then
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    Items["RealDropdown"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
                    Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)
                end
            end

            Items["RealDropdown"]:OnHover(function()
                if Dropdown.IsOpen then
                    return
                end

                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(255, 255, 255)})
                Items["Gradient"].Instance.Enabled = true
            end)

            Items["RealDropdown"]:OnHoverLeave(function()
                if Dropdown.IsOpen then
                    return
                end

                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
                Items["Gradient"].Instance.Enabled = false
            end)

            local RenderStepped

            function Dropdown:SetOpen(Bool)
                if Debounce then
                    return
                end

                Dropdown.IsOpen = Bool

                Debounce = true

                if Dropdown.IsOpen then
                    Items["OptionHolder"].Instance.Visible = true
                    Items["OptionHolder"].Instance.Parent = Library.Holder.Instance

                    Items["ArrowIcon"]:Tween(nil, {Rotation = 180, ImageColor3 = FromRGB(255, 255, 255)})
                    Items["Gradient"].Instance.Enabled = true

                    Library:Thread(function()
                        for Index, Value in Dropdown.OptionsWithIndexes do
                            task.spawn(function()
                                Value:RefreshPosition(true)
                            end)
                            if not IsMobile then task.wait(0.02) end
                        end
                    end)

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        local px = Items["RealDropdown"].Instance.AbsolutePosition.X
                        local py = Items["RealDropdown"].Instance.AbsolutePosition.Y
                        local hh = IsMobile and math.min(math.max(Dropdown.OptionHolderSize, 168), 216) or Dropdown.OptionHolderSize
                        local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2New(1000, 1000)
                        local bottom = py + Items["RealDropdown"].Instance.AbsoluteSize.Y + 5
                        if IsMobile and bottom + hh > viewport.Y - 8 then bottom = math.max(8,py-hh-5) end
                        Items["OptionHolder"].Instance.Position = UDim2New(0, MathClamp(px, 4, math.max(4,viewport.X-Items["RealDropdown"].Instance.AbsoluteSize.X-4)), 0, bottom)
                        Items["OptionHolder"].Instance.Size = UDim2New(0, Items["RealDropdown"].Instance.AbsoluteSize.X, 0, hh)
                    end)

                    for Index, Value in Library.OpenFrames do
                        if Value ~= Dropdown and not Dropdown.Section.IsSettings then
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Dropdown] = Dropdown
                else
                    if not Dropdown.IsOpen then
                        for Index, Value in Dropdown.OptionsWithIndexes do
                            task.spawn(function()
                                Value:RefreshPosition(false)
                            end)
                        end
                    end

                    if Library.OpenFrames[Dropdown] then
                        Library.OpenFrames[Dropdown] = nil
                    end

                    if RenderStepped then
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end

                    Items["ArrowIcon"]:Tween(nil, {Rotation = 0, ImageColor3 = FromRGB(141, 141, 150)})
                    Items["Gradient"].Instance.Enabled = false
                end

                local Descendants = Items["OptionHolder"].Instance:GetDescendants()
                TableInsert(Descendants, Items["OptionHolder"].Instance)

                local NewTween

                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue
                    end

                    if not Value.ClassName:find("UI") then
                        Value.ZIndex = (Dropdown.IsOpen and Dropdown.Section.IsSettings and 8) or (Dropdown.IsOpen and 3) or 1
                    end

                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                NewTween.Tween.Completed:Connect(function()
                    Debounce = false
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                    task.wait(0.2)
                    Items["OptionHolder"].Instance.Parent = not Dropdown.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Dropdown:Set(Option)
                if Dropdown.Multi then
                    if type(Option) ~= "table" then
                        return
                    end

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Dropdown.Options[Value]

                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true
                        OptionData:Toggle("Active")
                    end

                    Items["Value"].Instance.Text = TableConcat(Option, ", ")
                else
                    if not Dropdown.Options[Option] then
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Dropdown.Options do
                        if Value ~= OptionData then
                            Value.Selected = false
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true
                            Value:Toggle("Active")
                        end
                    end

                    Items["Value"].Instance.Text = Option
                end

                if Dropdown.Callback then
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            function Dropdown:Add(Option)
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, IsMobile and 40 or 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local OptionAccent = Instances:Create("Frame", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --OptionAccent:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UIGradient", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = OptionAccent.Instance,
                    Name = "\0"
                })

                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Option,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})

                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    OptionText = OptionText,
                    OptionAccent = OptionAccent,
                    Selected = false
                }

                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionText:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 15, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionText:Tween(nil, {TextTransparency = 0.3, Position = UDim2New(0, 0, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:RefreshPosition(Bool)
                    if Bool then
                        if OptionData.Selected then
                            OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 15, 0.5, 0)})
                        else
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                        end
                    else
                        if OptionData.Selected then
                            OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                            OptionText.Instance.Position = UDim2New(0, 45, 0.5, 0)
                        else
                            OptionText.Instance.Position = UDim2New(0, 30, 0.5, 0)
                        end
                    end

                    --if Bool then
                        --OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    --else
                        --OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                    --end

                    --[[
                    if Bool then
                        if OptionData.Selected then
                            OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 15, 0.5, 0)})
                        else
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                        end
                    else
                        if OptionData.Selected then
                            OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                            OptionText.Instance.Position = UDim2New(0, 45, 0.5, 0)
                        else
                            OptionText.Instance.Position = UDim2New(0, 30, 0.5, 0)
                        end
                    end
                    --]]
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Dropdown.Multi then
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Dropdown.Flag] = Dropdown.Value

                        local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "..."
                        Items["Value"].Instance.Text = TextFormat
                    else
                        if OptionData.Selected then
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do
                                if Value ~= OptionData then
                                    Value.Selected = false
                                    Value:Toggle("Inactive")
                                end
                            end

                            Items["Value"].Instance.Text = OptionData.Name
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")

                            Items["Value"].Instance.Text = "..."
                        end
                    end

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("Activated", function()
                    OptionData:Set()
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                Dropdown.OptionsWithIndexes[#Dropdown.OptionsWithIndexes+1] = OptionData
                OptionData:RefreshPosition(false)

                return OptionData
            end

            function Dropdown:Remove(Option)
                if Dropdown.Options[Option] then
                    Dropdown.Options[Option].Button:Clean()
                    Dropdown.Options[Option] = nil
                end
            end

            function Dropdown:Refresh(List, DefaultVal)
                local OptionsToRemove = {}
                for Name, _ in pairs(Dropdown.Options) do
                    table.insert(OptionsToRemove, Name)
                end
                for _, Name in ipairs(OptionsToRemove) do
                    Dropdown:Remove(Name)
                end
                Dropdown.Options = {}
                Dropdown.OptionsWithIndexes = {}
                for Index, Value in ipairs(List) do
                    Dropdown:Add(Value)
                end
                if DefaultVal then
                    Dropdown:Set(DefaultVal)
                else
                    Dropdown.Value = nil
                    Library.Flags[Dropdown.Flag] = nil
                    Items["Value"].Instance.Text = "..."
                end
            end

            Items["RealDropdown"]:Connect("Activated", function()
                Dropdown:SetOpen(not Dropdown.IsOpen)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dropdown.IsOpen then
                        if Library:IsMouseOverFrame(Items["OptionHolder"],Input) then
                            return
                        end

                        Dropdown:SetOpen(false)
                    end
                end
            end)

            Items["RealDropdown"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Dropdown.IsOpen and not IsMobile then
                    Dropdown.IsOpen = not Library:IsClipped(Items["OptionHolder"].Instance, Dropdown.Section.Items["Section"].Instance.Parent)
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                end
            end)

            for Index, Value in Dropdown.Items do
                Dropdown:Add(Value)
            end

            if Dropdown.Default then
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            Dropdown.Section.Elements[#Dropdown.Section.Elements+1] = Dropdown
            return Dropdown
        end

        Library.Sections.Label = function(self, Name)
            local Label = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Name or "Label"
            }

            local Items = { } do
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Label.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Label.Name,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    Size = UDim2New(1, -2, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            end

            --Label.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Label.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            function Label:SetText(Text)
                Text = tostring(Text)
                Items["Text"].Instance.Text = Text
            end

            function Label:SetVisibility(Bool)
                Items["Label"].Instance.Visible = Bool
            end

            function Label:RefreshPosition(Bool)
                if Bool then
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 5)})

                    if Items["SubElements"] then
                        Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                        -- Avoid tweening a nil placeholder when the optional colorpicker is attached.
                    end
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0, 5)

                    if Items["SubElements"] then
                        Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 30, 0, 30)})
                        Tween:Create(Items["Label"].Instance:FindFirstChild("nig"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 30, 1, -6)}, true)
                    end
                end
            end

            function Label:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Label.Window,
                    Page = Label.Page,
                    Section = Label.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end,
                    Alpha = Data.Alpha or Data.alpha or false
                }

                if not Items["SubElements"] then
                    Items["SubElements"] = Instances:Create("Frame", {
                        Parent = Items["Label"].Instance,
                        Name = "\0",
                        Size = UDim2New(1, 0, 0, 30),
                        Position = UDim2New(0, 0, 0, 30),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    })  Items["SubElements"]:AddToTheme({BackgroundColor3 = "Element"})

                    Instances:Create("UICorner", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })

                    Instances:Create("UIListLayout", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Instances:Create("UIPadding", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        PaddingLeft = UDimNew(0, 6)
                    })
                end

                --Label.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Label.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["SubElements"],
                    Page = Colorpicker.Page,
                    Section = Colorpicker.Section,
                    Flag = Colorpicker.Flag,
                    Default = Colorpicker.Default,
                    Callback = Colorpicker.Callback,
                    Parent2 = Items["Label"],
                    Alpha = Colorpicker.Alpha
                })

                return NewColorpicker
            end

            Label.Section.Elements[#Label.Section.Elements+1] = Label
            return Label
        end

        Library.Sections.Keybind = function(self, Data)
            Data = Data or { }

            local Keybind = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Keybind",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                Callback = Data.Callback or Data.callback or function() end,
                Mode = Data.Mode or Data.mode or Enum.KeyCode.RightShift,

                Value = "",
                ModeSelected = "",
                Toggled = false,
                Picking = false
            }

            local Items = { } do
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Keybind.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["SubElements"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 30),
                    Position = UDim2New(0, 0, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["SubElements"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 6)
                })

                Items["KeyButton"] = Instances:Create("TextButton", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "MouseButton2",
                    AutoButtonColor = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    SelectionOrder = 2,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["KeyButton"]:AddToTheme({TextColor3 = "Text"})

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Keybind.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["Modes"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 200, 0, 25),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Modes"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    Size = UDim2New(0.35, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Background"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    TextTransparency = 0.30000001192092896,
                    Text = "Toggle",
                    AutoButtonColor = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0.35, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Toggle"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})

                Items["Hold"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.20000000298023224,
                    Text = "Hold",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0),
                    Size = UDim2New(0.35, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.35, 0, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Hold"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})

                Items["Always"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.20000000298023224,
                    Text = "Always",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0),
                    Size = UDim2New(0.4, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.7, -12, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Always"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})
            end

            --Keybind.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Keybind.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            local KeyListItem

            if Library.KeyList then
                KeyListItem = Library.KeyList:Add("", "")
            end

            local Update = function()
                if KeyListItem then
                    KeyListItem:Set(Data.Name, Keybind.Value)
                    KeyListItem:SetStatus(Keybind.Toggled)
                end
            end

            function Keybind:RefreshPosition(Bool)
                if Bool then
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 5)})
                    Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                    Items["Modes"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0, 5)
                    Items["SubElements"].Instance.Position = UDim2New(0, 30, 0, 30)
                    Items["Modes"].Instance.Position = UDim2New(1, 30, 0, 0)
                end
            end

            function Keybind:SetMode(Mode) -- hard coded
                if Mode == "Toggle" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0), Size = UDim2New(0.35, 0, 1, 0)})
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                elseif Mode == "Hold" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0.35, 0, 0, 0), Size = UDim2New(0.35, 0, 1, 0)})

                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                elseif Mode == "Always" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0.7, 0, 0, 0), Size = UDim2New(0.3, 0, 1, 0)})

                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.ModeSelected,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
            end

            function Keybind:Press(Bool)
                if Keybind.ModeSelected == "Toggle" then
                    Keybind.Toggled = not Keybind.Toggled
                elseif Keybind.ModeSelected == "Hold" then
                    Keybind.Toggled = Bool
                elseif Keybind.ModeSelected == "Always" then
                    Keybind.Toggled = true
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.ModeSelected,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end

                Update()
            end

            function Keybind:Get()
                return Keybind.Key, Keybind.ModeSelected, Keybind.Toggled
            end

            function Keybind:Set(Key)
                if StringFind(tostring(Key), "Enum") then
                    Keybind.Key = tostring(Key)

                    Key = Key.Name == "Backspace" and "None" or Key.Name

                    local KeyString = Keys[Keybind.Key] or StringGSub(Key, "Enum.", "") or "None"
                    local TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    Library.Flags[Keybind.Flag] = {
                        Mode = Keybind.ModeSelected,
                        Key = Keybind.Key,
                        Toggled = Keybind.Toggled
                    }

                    if Data.Callback then
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif type(Key) == "table" then
                    local RealKey = Key.Key == "Backspace" and "None" or Key.Key
                    Keybind.Key = tostring(Key.Key)

                    if Key.ModeSelected then
                        Keybind.ModeSelected = Key.Mode
                        Keybind:SetMode(Key.Mode)
                    else
                        Keybind.ModeSelected = "Toggle"
                        Keybind:SetMode("Toggle")
                    end

                    local KeyString = Keys[Keybind.Key] or StringGSub(tostring(RealKey), "Enum.", "") or RealKey
                    local TextToDisplay = KeyString and StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "")

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    if Data.Callback then
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif TableFind({"Toggle", "Hold", "Always"}, Key) then
                    Keybind.ModeSelected = Key
                    Keybind:SetMode(Key)

                    if Data.Callback then
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                end

                --Items["KeyButton"].Instance.Position = UDim2New(0, Data.Text.Instance.TextBounds.X + 12, 0, 0)
                Keybind.Picking = false
            end

            Items["KeyButton"]:Connect("Activated", function()
                Keybind.Picking = true

                Items["KeyButton"].Instance.Text = "."
                Library:Thread(function()
                    local Count = 1

                    while true do
                        if not Keybind.Picking then
                            break
                        end

                        if Count == 4 then
                            Count = 1
                        end

                        Items["KeyButton"].Instance.Text = Count == 1 and "." or Count == 2 and ".." or Count == 3 and "..."
                        Count += 1
                        task.wait(0.35)
                    end
                end)

                local InputBegan
                InputBegan = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Keybind:Set(Input.KeyCode)
                    else
                        Keybind:Set(Input.UserInputType)
                    end

                    InputBegan:Disconnect()
                    InputBegan = nil
                end)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.ModeSelected == "Toggle" then
                        Keybind:Press()
                    elseif Keybind.ModeSelected == "Hold" then
                        Keybind:Press(true)
                    elseif Keybind.ModeSelected == "Always" then
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.ModeSelected == "Toggle" then
                        Keybind:Press()
                    elseif Keybind.ModeSelected == "Hold" then
                        Keybind:Press(true)
                    elseif Keybind.ModeSelected == "Always" then
                        Keybind:Press(true)
                    end
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not Keybind.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["KeybindWindow"],Input) or Library:IsMouseOverFrame(Items["OptionHolder"],Input) then
                        return
                    end

                    Keybind:SetOpen(false)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.ModeSelected == "Hold" then
                        Keybind:Press(false)
                    elseif Keybind.ModeSelected == "Always" then
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.ModeSelected == "Hold" then
                        Keybind:Press(false)
                    elseif Keybind.ModeSelected == "Always" then
                        Keybind:Press(true)
                    end
                end
            end)

            Items["Toggle"]:Connect("Activated", function()
                Keybind.ModeSelected = "Toggle"
                Keybind:SetMode("Toggle")
            end)

            Items["Hold"]:Connect("Activated", function()
                Keybind.ModeSelected = "Hold"
                Keybind:SetMode("Hold")
            end)

            Items["Always"]:Connect("Activated", function()
                Keybind.ModeSelected = "Always"
                Keybind:SetMode("Always")
            end)

            if Keybind.Default then
                Keybind:Set({
                    Mode = Keybind.Mode or "Toggle",
                    Key = Keybind.Default,
                })
            end

            Library.SetFlags[Keybind.Flag] = function(Value)
                Keybind:Set(Value)
            end

            Keybind.Section.Elements[#Keybind.Section.Elements+1] = Keybind
            return Keybind
        end

        Library.Sections.Textbox = function(self, Data)
            Data = Data or { }

            local Textbox = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "",
                Callback = Data.Callback or Data.callback or function() end,
                Placeholder = Data.Placeholder or Data.placeholder or "Placeholder",
                Numeric = Data.Numeric or Data.numeric or false,
                Finished = Data.Finished or Data.finished or false,

                Value = ""
            }

            local Items = { } do
                Items["Textbox"] = Instances:Create("Frame", {
                    Parent = Textbox.Section.Items["Content"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Selectable = true,
                    Size = UDim2New(1, 0, 0, 32),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    Selectable = true,
                    ZIndex = 2,
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, -20, 0, 15),
                    Position = UDim2New(0, 10, 0, 8),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = Textbox.Placeholder,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text"})
            end

            function Textbox:Get()
                return Textbox.Value
            end

            function Textbox:SetVisibility(Bool)
                Items["Textbox"].Instance.Visible = Bool
            end

            function Textbox:RefreshPosition(Bool)
                if Bool then
                    Items["Background"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                else
                    Items["Background"].Instance.Position = UDim2New(0, 30, 0, 0)
                end
            end

            function Textbox:Set(Value)
                if Textbox.Numeric then
                    if (not tonumber(Value)) and StringLen(tostring(Value)) > 0 then
                        Value = Textbox.Value
                    end
                end

                Textbox.Value = Value
                Items["Input"].Instance.Text = Value
                Library.Flags[Textbox.Flag] = Value

                if Textbox.Callback then
                    Library:SafeCall(Textbox.Callback, Value)
                end
            end

            if Textbox.Finished then
                Items["Input"]:Connect("FocusLost", function(PressedEnterQuestionMark)
                    if PressedEnterQuestionMark or IsMobile then
                        Textbox:Set(Items["Input"].Instance.Text)
                    end
                end)
            else
                Library:Connect(Items["Input"].Instance:GetPropertyChangedSignal("Text"), function()
                    Textbox:Set(Items["Input"].Instance.Text)
                end)
            end

            if Textbox.Default then
                Textbox:Set(Textbox.Default)
            end

            Library.SetFlags[Textbox.Flag] = function(Value)
                Textbox:Set(Value)
            end

            Textbox.Section.Elements[#Textbox.Section.Elements+1] = Textbox
            return Textbox
        end

        Library.Sections.Listbox = function(self, Data)
            -- basically just dropdowns so i jsut copied dropdowns
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or { "One", "Two", "Three" },
                Default = Data.Default or Data.default or nil,
                Callback = Data.Callback or Data.callback or function() end,
                Size = Data.Size or Data.size or 125,
                Multi = Data.Multi or Data.multi or false,

                Value = { },
                Options = { },
                IsOpen = false
            }

            local Items = { } do
                Items["Listbox"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, Dropdown.Size),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Search"] = Instances:Create("TextBox", {
                    Parent = Items["Listbox"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    CursorPosition = -1,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, 0, 0, 30),
                    BorderSizePixel = 0,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = "Search..",
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Search"]:AddToTheme({TextColor3 = "Text", BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 4),
                    PaddingLeft = UDimNew(0, 8)
                })

                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Listbox"].Instance,
                    Name = "\0",
                    Active = true,
                    Size = UDim2New(1, 0, 1, -30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Position = UDim2New(0, 0, 0, 30),
                    BackgroundColor3 = FromRGB(27, 26, 29),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})

                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    ScrollBarImageColor3 = FromRGB(0, 0, 0),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -4, 1, -8),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Position = UDim2New(0, 0, 0, 4),
                    BackgroundColor3 = FromRGB(27, 26, 29),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 12),
                    PaddingLeft = UDimNew(0, 8)
                })

                Items["_"] = Instances:Create("Frame", {
                    Parent = Items["Listbox"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 10),
                    Position = UDim2New(0, 0, 0, 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["_"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("Frame", {
                    Parent = Items["_"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 1),
                    Position = UDim2New(0, 0, 1, -3),
                    AnchorPoint = Vector2New(0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29),
                }):AddToTheme({BackgroundColor3 = "Outline"})
            end

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:SetVisibility(Bool)
                Items["Listbox"].Instance.Visible = Bool
            end

            function Dropdown:RefreshPosition(Bool)
                if Bool then
                    Items["Background"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                    Items["Search"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                    Items["_"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 25)})
                else
                    Items["Background"].Instance.Position = UDim2New(0, 30, 0, 30)
                    Items["Search"].Instance.Position = UDim2New(0, 30, 0, 0)
                    Items["_"].Instance.Position = UDim2New(0, 30, 0, 25)
                end
            end

            function Dropdown:Set(Option)
                if Dropdown.Multi then
                    if type(Option) ~= "table" then
                        return
                    end

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Dropdown.Options[Value]

                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true
                        OptionData:Toggle("Active")
                    end
                else
                    if not Dropdown.Options[Option] then
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Dropdown.Options do
                        if Value ~= OptionData then
                            Value.Selected = false
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true
                            Value:Toggle("Active")
                        end
                    end
                end

                if Dropdown.Callback then
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            function Dropdown:Add(Option)
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, IsMobile and 40 or 20),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local OptionAccent = Instances:Create("Frame", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --OptionAccent:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UIGradient", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = OptionAccent.Instance,
                    Name = "\0"
                })

                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Option,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})

                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    OptionText = OptionText,
                    IsSearching = false,
                    OptionAccent = OptionAccent,
                    Selected = false
                }

                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionText:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 15, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionText:Tween(nil, {TextTransparency = 0.3, Position = UDim2New(0, 0, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:Search(Bool)
                    Library:Thread(function()
                        if Bool then
                            OptionData.IsSearching = true
                            OptionText:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1})
                            task.wait(0.08)
                            OptionButton:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, 0)})

                            if OptionData.Selected then
                                OptionAccent:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                            end
                        else
                            OptionData.IsSearching = false
                            OptionText:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = OptionData.Selected and 0 or 0.3})
                            task.wait(0.08)
                            OptionButton:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, IsMobile and 40 or 20)})

                            if OptionData.Selected then
                                OptionAccent:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                            end
                        end
                    end)
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Dropdown.Multi then
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Dropdown.Flag] = Dropdown.Value
                    else
                        if OptionData.Selected then
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do
                                if Value ~= OptionData and not Value.IsSearching then
                                    Value.Selected = false
                                    Value:Toggle("Inactive")
                                end
                            end
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")
                        end
                    end

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("Activated", function()
                    OptionData:Set()
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                return OptionData
            end

            function Dropdown:Remove(Option)
                if Dropdown.Options[Option] then
                    Dropdown.Options[Option].Button:Clean()
                    Dropdown.Options[Option] = nil
                end
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do
                    Dropdown:Remove(Value.Name)
                end

                for Index, Value in List do
                    Dropdown:Add(Value)
                end
            end

            Library:Connect(Items["Search"].Instance:GetPropertyChangedSignal("Text"), function()
                Library:Thread(function()
                    for Index, Value in Dropdown.Options do
                        local InputText = Items["Search"].Instance.Text
                        if InputText ~= "" then
                            if StringFind(StringLower(Value.Name), Library:EscapePattern(StringLower(InputText))) then
                                Value.Button.Instance.Visible = true
                                Value:Search(false)
                            else
                                Value:Search(true)
                                Value.Button.Instance.Visible = false
                            end
                        else
                            Value:Search(false)
                            Value.Button.Instance.Visible = true
                        end
                    end
                end)
            end)


            for Index, Value in Dropdown.Items do
                Dropdown:Add(Value)
            end

            if Dropdown.Default then
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            Dropdown.Section.Elements[#Dropdown.Section.Elements+1] = Dropdown
            return Dropdown
        end
    end

    Library.CreateSettingsPage = function(self, Window, KeybindList)
        local Page = Window:Page({Name = "Settings", Icon = "122669828593160"})
        local ConfigsSection = Page:Section({Name = "Configs", Side = 1}) do
            local ConfigSelected = nil

            local ConfigsDropdown = ConfigsSection:Listbox({
                Flag = "ConfigsList",
                Items = { },
                Multi = false,
                Callback = function(Value)
                    ConfigSelected = Value
                end
            })

            ConfigsSection:Textbox({
                Flag = "ConfigsName",
                Placeholder = "Name",
                Numeric = false,
                Finished = false,
                Callback = function(Value)
                end
            })

            ConfigsSection:Button({
                Name = "Create",
                Callback = function()
                    local InputName = Library.Flags["ConfigsName"]
                    if InputName and InputName ~= "" then
                        if not isfolder(Library.Folders.Configs) then
                            makefolder(Library.Folders.Configs)
                        end
                        local FinalName = InputName:find(".json") and InputName or InputName .. ".json"
                        writefile(Library.Folders.Configs .. "/" .. FinalName, Library:GetConfig())

                        Library:RefreshConfigsList(ConfigsDropdown)
                    end
                end
            })

            ConfigsSection:Button({
                Name = "Delete",
                Callback = function()
                    if ConfigSelected and isfile(Library.Folders.Configs .. "/" .. ConfigSelected) then
                        delfile(Library.Folders.Configs .. "/" .. ConfigSelected)
                        Library:RefreshConfigsList(ConfigsDropdown)
                        ConfigSelected = nil
                    end
                end
            })

            ConfigsSection:Button({
                Name = "Load",
                Callback = function()
                    if ConfigSelected and isfile(Library.Folders.Configs .. "/" .. ConfigSelected) then
                        Library:LoadConfig(readfile(Library.Folders.Configs .. "/" .. ConfigSelected))
                    end
                end
            })

            ConfigsSection:Button({
                Name = "Save",
                Callback = function()
                    if ConfigSelected and isfile(Library.Folders.Configs .. "/" .. ConfigSelected) then
                        writefile(Library.Folders.Configs .. "/" .. ConfigSelected, Library:GetConfig())
                    end
                end
            })

            ConfigsSection:Button({
                Name = "Refresh",
                Callback = function()
                    Library:RefreshConfigsList(ConfigsDropdown)
                end
            })

            if not isfolder(Library.Folders.Configs) then
                makefolder(Library.Folders.Configs)
            end
            Library:RefreshConfigsList(ConfigsDropdown)
        end

        local UISection = Page:Section({Name = "UI Settings", Side = 2}) do
            UISection:Toggle({
                Name = "Watermark",
                Flag = "WatermarkToggle",
                Default = false,
                Callback = function(Value)
                    if Library.WatermarkFrame then
                        Library.WatermarkFrame.Instance.Visible = Value
                    end
                end
            })

            UISection:Toggle({
                Name = "Keybind List",
                Flag = "KeybindListToggle",
                Default = false,
                Callback = function(Value)
                    if KeybindList then
                        KeybindList:SetVisibility(Value)
                    end
                end
            })
        end

        return Page
    end
end

local env = (type(getgenv) == "function" and getgenv()) or _G
env.VortexionNeverloseLibrary = Library
return Library

end)()
-- Generated from assets/ui/Vortexion_Logo_256.png. Direct user-provided artwork, not a Roblox asset ID.
local VortexionLogoAssetFactory = (function()
    local encoded = [[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]]
    local filename = "Vortexion_r224_brand-772fd5fda849.png"
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for i=1,#chars do lookup[string.sub(chars,i,i)] = i-1 end
    local function decode64(input)
        local out = {}
        for i=1,#input,4 do
            local a,b,c,d = lookup[input:sub(i,i)],lookup[input:sub(i+1,i+1)],lookup[input:sub(i+2,i+2)],lookup[input:sub(i+3,i+3)]
            if not a or not b then return nil end
            local n=a*262144+b*4096+(c or 0)*64+(d or 0)
            out[#out+1]=string.char(math.floor(n/65536)%256)
            if c then out[#out+1]=string.char(math.floor(n/256)%256) end
            if d then out[#out+1]=string.char(n%256) end
        end
        return table.concat(out)
    end
    return function()
        local env = (type(getgenv)=="function" and getgenv()) or _G
        if type(env.VortexionR224BrandAsset)=="string" then return env.VortexionR224BrandAsset, "embedded PNG" end
        local assetFn = type(getcustomasset)=="function" and getcustomasset or
            (type(getsynasset)=="function" and getsynasset) or
            (type(getfileasset)=="function" and getfileasset)
        if not assetFn or type(writefile)~="function" then
            return nil,"执行器不支持本地 PNG 资源（需要 writefile 与 getcustomasset）"
        end
        local ok,result=pcall(function()
            if type(isfolder)=="function" and type(makefolder)=="function" and not isfolder("Vortexion") then makefolder("Vortexion") end
            local exists=type(isfile)=="function" and isfile(filename)
            if not exists then
                local bytes=decode64(encoded)
                assert(type(bytes)=="string" and #bytes>1000,"brand PNG decode failed")
                writefile(filename,bytes)
            end
            return assetFn(filename)
        end)
        if ok and type(result)=="string" and #result>0 then
            env.VortexionR224BrandAsset=result
            return result,"embedded PNG"
        end
        return nil,"PNG 资源加载失败: "..tostring(result)
    end
end)()

local ServerSwitchFactory = (function()
-- Standalone factory; controller methods use colon syntax.
return function(tab, notify)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local player, placeId = Players.LocalPlayer, game.PlaceId
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local apiRequest = (syn and syn.request) or http_request or request
        or (http and http.request) or (fluxus and fluxus.request)
    local config = {
        PreferredCountries = {"HK", "JP", "SG", "TW", "KR"},
        PreferredIPPrefixes = {}, AutoSwitch = false, StrictRegion = true,
        PingThresholdMs = 180, PingSamplesRequired = 4, SampleIntervalSeconds = 5,
        InitialDelaySeconds = 20, SwitchCooldownSeconds = 240,
        MaxServerPages = 3, MaxIPLookups = 12, MinAvailableSlots = 1,
        MinimumServerFPS = 35, CountryLookupUrl = "https://ipwho.is/",
        RequestTimeoutSeconds = 10, TeleportTimeoutSeconds = 20,
        MaxTeleportAttempts = 3, RetryDelaySeconds = 2,
    }
    local bounds = {
        PingThresholdMs = {50, 1000}, PingSamplesRequired = {1, 12},
        SampleIntervalSeconds = {1, 60}, InitialDelaySeconds = {0, 120},
        SwitchCooldownSeconds = {10, 1800}, MaxServerPages = {1, 10},
        MaxIPLookups = {1, 30}, MinAvailableSlots = {1, 100},
        MinimumServerFPS = {0, 60}, RequestTimeoutSeconds = {1, 60},
        TeleportTimeoutSeconds = {5, 120}, MaxTeleportAttempts = {1, 5},
        RetryDelaySeconds = {1, 30},
    }
    local function copy(value)
        if type(value) ~= "table" then return value end
        local result = {}
        for k, v in pairs(value) do result[k] = copy(v) end
        return result
    end
    local function finite(n)
        return type(n) == "number" and n == n and n > -math.huge and n < math.huge
    end
    local function validIP(ip)
        if type(ip) ~= "string" then return false end
        local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
        if not a then return false end
        a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
        if a > 255 or b > 255 or c > 255 or d > 255 then return false end
        return not (a == 0 or a == 10 or a == 127 or a >= 224
            or (a == 169 and b == 254) or (a == 172 and b >= 16 and b <= 31)
            or (a == 192 and b == 168) or (a == 100 and b >= 64 and b <= 127))
    end
    local running, busy, generation = true, false, 0
    local highSamples, lastSearch, enabledAt = 0, -math.huge, os.clock()
    local requestInFlight, pendingTeleport = false, nil
    local listeners, regionCache = {}, {}
    local blocked = {[game.JobId] = true}
    local status = {Phase = "idle", Message = "自动切服默认关闭", Busy = false,
        Running = true, AutoSwitch = false, HighSamples = 0, Requests = 0,
        Pages = 0, IPChecks = 0, ResolvedIPs = 0, TeleportAttempts = 0}
    local paragraph
    local controller = {}
    local function emit(phase, message, fields)
        if phase then status.Phase = phase end
        if message then status.Message = message end
        for k, v in pairs(fields or {}) do status[k] = v end
        status.Busy, status.Running = busy, running
        status.AutoSwitch, status.HighSamples = config.AutoSwitch, highSamples
        status.RequestInFlight = requestInFlight
        status.CooldownRemaining = math.max(0, config.SwitchCooldownSeconds - (os.clock() - lastSearch))
        if paragraph and type(paragraph.SetDesc) == "function" then
            local ping = status.PingMs and (tostring(status.PingMs) .. " ms") or "暂无采样"
            pcall(paragraph.SetDesc, paragraph, status.Message .. "\n客户端延迟：" .. ping
                .. " | 连续高延迟：" .. highSamples .. "/" .. config.PingSamplesRequired
                .. "\n列表页：" .. status.Pages .. " | IP 查询：" .. status.IPChecks
                .. " | 传送尝试：" .. status.TeleportAttempts)
        end
        local callbacks = {}
        for fn in pairs(listeners) do callbacks[#callbacks + 1] = fn end
        for _, fn in ipairs(callbacks) do
            if listeners[fn] then pcall(fn, copy(status)) end
        end
    end
    local function alive(token) return running and token == generation end
    local function pause(token, duration)
        local deadline = os.clock() + duration
        while alive(token) and os.clock() < deadline do task.wait(math.min(0.1, deadline - os.clock())) end
        return alive(token)
    end
    -- Keep the physical request fence after timeout; late results never commit state.
    local function bounded(token, timeout, fn)
        if not alive(token) then return nil, "已停止" end
        if requestInFlight then return nil, "上次超时请求尚未返回" end
        requestInFlight = true
        local done, expired, ok, result = false, false, false, nil
        local deadline = os.clock() + timeout
        task.spawn(function()
            if not alive(token) then requestInFlight = false; return end
            local success, value = pcall(fn)
            requestInFlight = false
            if not expired and alive(token) and os.clock() <= deadline then
                ok, result, done = success, value, true
            end
        end)
        while alive(token) and not done and os.clock() < deadline do task.wait(0.05) end
        if not alive(token) then expired = true; return nil, "已停止" end
        if not done then expired = true; return nil, "请求超时" end
        if not ok then return nil, "请求失败：" .. tostring(result) end
        return result
    end
    local function json(token, cfg, method, url, body)
        status.Requests = status.Requests + 1
        local response, reason = bounded(token, cfg.RequestTimeoutSeconds, function()
            if type(apiRequest) == "function" then
                return apiRequest({Url = url, Method = method, Body = body,
                    Headers = {["Content-Type"] = "application/json", Accept = "application/json"}})
            end
            if method == "GET" then return {Body = game:HttpGet(url)} end
            error("执行器未提供 POST 请求接口")
        end)
        if not alive(token) then return nil, "已停止" end
        if type(response) ~= "table" then return nil, reason or "响应格式错误" end
        local code = tonumber(response.StatusCode or response.Status or response.status_code)
        if code and (code < 200 or code >= 300) then return nil, "HTTP " .. code end
        local bodyText = response.Body or response.body
        if type(bodyText) ~= "string" then return nil, "响应正文缺失" end
        local ok, data = pcall(HttpService.JSONDecode, HttpService, bodyText)
        if not alive(token) then return nil, "已停止" end
        if ok and type(data) == "table" then return data end
        return nil, "JSON 解析失败"
    end
    local function resolve(token, cfg, id)
        if type(env.VortexionResolveServerIP) == "function" then
            local ip = bounded(token, cfg.RequestTimeoutSeconds, function()
                return env.VortexionResolveServerIP(placeId, id)
            end)
            if not alive(token) then return nil end
            if validIP(ip) then return ip end
            if requestInFlight then return nil end
        end
        if type(apiRequest) ~= "function" then return nil end
        local body = HttpService:JSONEncode({placeId = placeId, gameId = id,
            gameJoinAttemptId = id, isTeleport = false})
        local data = json(token, cfg, "POST", "https://gamejoin.roblox.com/v1/join-game-instance", body)
        local js = data and data.joinScript
        if type(js) ~= "table" then return nil end
        for _, key in ipairs({"UdmuxEndpoints", "ServerConnections"}) do
            if type(js[key]) == "table" then
                for _, endpoint in ipairs(js[key]) do
                    if type(endpoint) == "table" and validIP(endpoint.Address) then return endpoint.Address end
                end
            end
        end
        return validIP(js.MachineAddress) and js.MachineAddress or nil
    end
    local function rankIP(token, cfg, ip)
        for i, prefix in ipairs(cfg.PreferredIPPrefixes) do
            if ip:sub(1, #prefix) == prefix then return i, "IP 前缀 " .. prefix end
        end
        local cache = regionCache
        local country = cache[ip]
        if not country then
            local geo = json(token, cfg, "GET", cfg.CountryLookupUrl .. ip)
            if not alive(token) then return nil end
            country = geo and geo.success == true and geo.country_code
            if type(country) ~= "string" then return nil, "地区未知" end
            country = country:upper()
            cache[ip] = country
        end
        for i, wanted in ipairs(cfg.PreferredCountries) do
            if country == wanted then return i + #cfg.PreferredIPPrefixes, country end
        end
        return nil, country
    end
    local function candidates(token, cfg)
        local results, seen, cursors = {}, {}, {}
        local cursor
        for _ = 1, cfg.MaxServerPages do
            if not alive(token) then return {} end
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(placeId)
            if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local data, reason = json(token, cfg, "GET", url)
            if not alive(token) then return {} end
            if not data or type(data.data) ~= "table" then return results, reason or "服务器列表格式错误" end
            status.Pages = status.Pages + 1
            for _, server in ipairs(data.data) do
                if type(server) == "table" then
                    local slots = (tonumber(server.maxPlayers) or 0) - (tonumber(server.playing) or 0)
                    local fps = tonumber(server.fps) or 0
                    local listPing = tonumber(server.ping)
                    if type(server.id) == "string" and server.id ~= "" and not blocked[server.id]
                        and not seen[server.id] and slots >= cfg.MinAvailableSlots and fps >= cfg.MinimumServerFPS then
                        seen[server.id] = true
                        results[#results + 1] = {id = server.id, slots = slots,
                            listPing = finite(listPing) and listPing >= 0 and listPing or nil}
                    end
                end
            end
            cursor = data.nextPageCursor
            if type(cursor) ~= "string" or cursor == "" or cursors[cursor] then break end
            cursors[cursor] = true
            if not pause(token, 0.4) then return {} end
        end
        table.sort(results, function(a, b)
            return (a.listPing or math.huge) < (b.listPing or math.huge)
        end)
        return results
    end
    local function search(token, cfg)
        local list, listError = candidates(token, cfg)
        if not alive(token) then return {} end
        if #list == 0 then return {}, listError or "没有可用的公共服务器" end
        local matches = {}
        for _, server in ipairs(list) do
            if not alive(token) or requestInFlight or status.IPChecks >= cfg.MaxIPLookups then break end
            status.IPChecks = status.IPChecks + 1
            local ip = resolve(token, cfg, server.id)
            if not alive(token) then return {} end
            if ip then
                status.ResolvedIPs = status.ResolvedIPs + 1
                local rank, country = rankIP(token, cfg, ip)
                if not alive(token) then return {} end
                if rank or not cfg.StrictRegion then
                    server.ip, server.country, server.rank = ip, country or "地区未知", rank or math.huge
                    matches[#matches + 1] = server
                end
            end
            emit("searching", "正在确认候选服务器 IP 与地区")
            if not pause(token, 0.4) then return {} end
        end
        table.sort(matches, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            return (a.listPing or math.huge) < (b.listPing or math.huge)
        end)
        if #matches > 0 then return matches end
        if status.ResolvedIPs == 0 then return {}, "IP 解析失败；未使用虚构 IP 或仅按列表延迟切服" end
        return {}, "没有已确认且符合偏好地区的 IP"
    end
    local failureConnection = TeleportService.TeleportInitFailed:Connect(function(who, result, message, failedPlace, options)
        local attempt = pendingTeleport
        if not running or not attempt or who ~= player or failedPlace ~= placeId then return end
        local identified = false
        if options then
            local ok, id = pcall(function() return options.ServerInstanceId end)
            if ok and type(id) == "string" and id ~= "" then
                if id ~= attempt.id then return end
                identified = true
            end
        end
        if attempt.failed then return end
        -- Legacy events without a target id are terminal, not a basis for chained retries.
        attempt.retryable = identified
        attempt.failed = "传送失败：" .. tostring(message or result)
        if attempt.uncertain then
            pendingTeleport = nil
            emit("failed", attempt.failed, {TeleportUncertain = false})
        end
    end)
    local function finish(token, phase, message)
        if not alive(token) then return end
        busy = false
        emit(phase, message)
        if alive(token) and type(notify) == "function" then pcall(notify, message) end
    end
    function controller:Switch()
        if not running then return false, "已停止" end
        if busy then return false, "正在搜索或传送" end
        if pendingTeleport then return false, "前次传送结果仍待确认，请勿重复切服" end
        if requestInFlight then return false, "前次请求仍在返回中" end
        if os.clock() - lastSearch < config.SwitchCooldownSeconds then return false, "切服冷却中" end
        busy, lastSearch, generation = true, os.clock(), generation + 1
        local token, cfg = generation, copy(config)
        highSamples = 0
        status.Pages, status.IPChecks, status.ResolvedIPs, status.Requests, status.TeleportAttempts = 0, 0, 0, 0, 0
        status.Target, status.LastError, status.TeleportUncertain = nil, nil, false
        emit("searching", "正在搜索低延迟地区服务器")
        task.spawn(function()
            local ok, err = pcall(function()
                local matches, reason = search(token, cfg)
                if not alive(token) then return end
                if #matches == 0 then finish(token, "failed", reason); return end
                for i = 1, math.min(#matches, cfg.MaxTeleportAttempts) do
                    if not alive(token) then return end
                    local target = matches[i]
                    local attempt = {id = target.id}
                    pendingTeleport = attempt
                    status.Target = {id = target.id, ip = target.ip, country = target.country,
                        listPing = target.listPing, slots = target.slots}
                    status.TeleportAttempts = i
                    emit("teleporting", "正在切服至 " .. target.country .. "；列表延迟仅作排序参考")
                    if not alive(token) then return end
                    blocked[target.id] = true
                    local deadline = os.clock() + cfg.TeleportTimeoutSeconds
                    task.spawn(function()
                        if not alive(token) or pendingTeleport ~= attempt then return end
                        attempt.dispatched = true
                        local sent, sendError = pcall(function()
                            TeleportService:TeleportToPlaceInstance(placeId, target.id, player)
                        end)
                        if not alive(token) or pendingTeleport ~= attempt then return end
                        if not sent and not attempt.failed then
                            attempt.failed = "传送调用失败：" .. tostring(sendError)
                            attempt.retryable = true
                            if attempt.uncertain then
                                pendingTeleport = nil
                                emit("failed", attempt.failed, {TeleportUncertain = false})
                            end
                        end
                    end)
                    while alive(token) and not attempt.failed and os.clock() < deadline do task.wait(0.1) end
                    if not alive(token) then return end
                    if not attempt.failed then
                        -- Absence of failure is not success. Never retry an outcome-unknown teleport.
                        attempt.uncertain = true
                        status.TeleportUncertain = true
                        finish(token, "uncertain", "传送等待超时，结果未确认；已阻止重复传送")
                        return
                    end
                    pendingTeleport = nil
                    status.LastError = attempt.failed
                    if not attempt.retryable or i >= math.min(#matches, cfg.MaxTeleportAttempts) then break end
                    emit("retrying", attempt.failed .. "；尝试下一候选服务器")
                    if not pause(token, cfg.RetryDelaySeconds) then return end
                end
                finish(token, "failed", status.LastError or "传送失败")
            end)
            if not ok and alive(token) then
                pendingTeleport = nil
                finish(token, "failed", "切服流程错误：" .. tostring(err))
            end
        end)
        return true
    end
    function controller:Stop()
        if not running then return end
        running, busy, generation = false, false, generation + 1
        config.AutoSwitch, highSamples = false, 0
        failureConnection:Disconnect()
        local dispatched = pendingTeleport and pendingTeleport.dispatched
        pendingTeleport = nil
        emit("stopped", dispatched and "已停止后续操作；已发出的传送由客户端处理" or "已停止切服与采样")
        listeners = {}
    end
    function controller:GetStatus()
        local snapshot = copy(status)
        snapshot.RequestInFlight = requestInFlight
        snapshot.HighSamples, snapshot.AutoSwitch = highSamples, config.AutoSwitch
        snapshot.CooldownRemaining = math.max(0, config.SwitchCooldownSeconds - (os.clock() - lastSearch))
        return snapshot
    end
    function controller:OnChange(fn)
        assert(type(fn) == "function", "OnChange expects a function")
        if not running then return function() end end
        listeners[fn] = true
        pcall(fn, self:GetStatus())
        return function() listeners[fn] = nil end
    end
    function controller:Config(patch)
        if patch == nil then return copy(config) end
        if not running then return false, "已停止" end
        if type(patch) ~= "table" then return false, "配置须为表" end
        local nextConfig = copy(config)
        for key, value in pairs(patch) do
            if bounds[key] then
                local range = bounds[key]
                if not finite(value) or value < range[1] or value > range[2] then return false, "配置数值越界：" .. key end
                nextConfig[key] = math.floor(value)
            elseif key == "AutoSwitch" or key == "StrictRegion" then
                if type(value) ~= "boolean" then return false, "配置须为布尔值：" .. key end
                nextConfig[key] = value
            elseif key == "PreferredCountries" or key == "PreferredIPPrefixes" then
                if type(value) ~= "table" or #value > 30 then return false, "地区配置格式错误" end
                local items = {}
                for _, item in ipairs(value) do
                    if type(item) ~= "string" or item == "" then return false, "地区配置格式错误" end
                    if key == "PreferredCountries" then
                        item = item:upper()
                        if not item:match("^[A-Z][A-Z]$") then return false, "国家代码须为两位字母" end
                    elseif not item:match("^%d[%d%.]*$") or #item > 15 then
                        return false, "IP 前缀格式错误"
                    end
                    items[#items + 1] = item
                end
                nextConfig[key] = items
            elseif key == "CountryLookupUrl" then
                if type(value) ~= "string" or not value:match("^https://") then return false, "地区接口须使用 HTTPS" end
                nextConfig[key] = value
            else return false, "未知配置：" .. tostring(key) end
        end
        if nextConfig.AutoSwitch ~= config.AutoSwitch then enabledAt = os.clock(); highSamples = 0 end
        if nextConfig.PingThresholdMs ~= config.PingThresholdMs or nextConfig.PingSamplesRequired ~= config.PingSamplesRequired then highSamples = 0 end
        if nextConfig.CountryLookupUrl ~= config.CountryLookupUrl then regionCache = {} end
        config = nextConfig
        emit(nil, nil)
        return true
    end
    local function set(key, value)
        local ok, reason = controller:Config({[key] = value})
        if not ok and type(notify) == "function" then pcall(notify, reason) end
    end
    paragraph = tab:AddParagraph({Title = "低延迟切服状态", Content = status.Message})
    tab:AddParagraph({Title = "切服说明", Content = "真实延迟来自客户端 GetNetworkPing 采样。服务器列表 ping 不是你的客户端延迟，也不保证换服后更低。默认严格确认 IP 地区；IP 失败则停止搜索，不虚构地区。冷却同时适用于手动与自动切服。"})
    tab:AddToggle("ServerSwitchAuto", {Title = "持续高延迟时自动切服", Default = false, Callback = function(v) set("AutoSwitch", v) end})
    tab:AddToggle("ServerSwitchStrictRegion", {Title = "严格匹配已确认 IP 地区", Default = true, Callback = function(v) set("StrictRegion", v) end})
    local sliders = {
        {"PingThresholdMs", "客户端延迟阈值（ms）"}, {"PingSamplesRequired", "连续高延迟采样次数"},
        {"SampleIntervalSeconds", "采样间隔（秒）"}, {"SwitchCooldownSeconds", "切服冷却（秒）"},
        {"MaxServerPages", "服务器列表页数预算"}, {"MaxIPLookups", "候选 IP 查询预算"},
        {"MinimumServerFPS", "最低服务器 FPS"},
    }
    for _, item in ipairs(sliders) do
        local key = item[1]
        tab:AddSlider("ServerSwitch" .. key, {Title = item[2], Min = bounds[key][1], Max = bounds[key][2],
            Default = config[key], Rounding = 0, Callback = function(v) set(key, v) end})
    end
    local function split(text)
        local items = {}
        for item in tostring(text):gmatch("[^,%s]+") do items[#items + 1] = item end
        return items
    end
    tab:AddInput("ServerSwitchCountries", {Title = "地区优先顺序（逗号分隔）", Default = "HK,JP,SG,TW,KR", Callback = function(v) set("PreferredCountries", split(v)) end})
    tab:AddInput("ServerSwitchIPPrefixes", {Title = "优先 IP 前缀（可留空）", Default = "", Callback = function(v) set("PreferredIPPrefixes", split(v)) end})
    tab:AddButton({Title = "立即搜索并切服", Callback = function()
        local ok, reason = controller:Switch()
        if not ok and type(notify) == "function" then pcall(notify, reason) end
    end})
    local function showSampleStatus()
        local text
        if not running then
            text = "此切服模块已停止，没有新的采样数据"
        else
            local snapshot = controller:GetStatus()
            local message = (type(snapshot.Message) == "string" and snapshot.Message ~= "") and snapshot.Message or "未采样"
            local ping = finite(snapshot.PingMs) and (tostring(math.floor(snapshot.PingMs * 100 + 0.5) / 100) .. " ms") or "未采样"
            local high = finite(snapshot.HighSamples) and tostring(math.floor(snapshot.HighSamples + 0.5)) or "未采样"
            local cooldown = finite(snapshot.CooldownRemaining) and (tostring(math.floor(snapshot.CooldownRemaining * 100 + 0.5) / 100) .. " 秒") or "未采样"
            text = table.concat({
                "切服采样状态：" .. message,
                "客户端延迟：" .. ping,
                "连续高延迟采样：" .. high .. "/" .. config.PingSamplesRequired,
                "切服冷却剩余：" .. cooldown,
                "请求进行中：" .. (snapshot.RequestInFlight and "是" or "否"),
                "自动切服：" .. (snapshot.AutoSwitch and "开启" or "关闭"),
            }, "\n")
        end
        if type(notify) == "function" then pcall(notify, text) else pcall(paragraph.SetDesc, paragraph, text) end
    end
    tab:AddButton({Title = "查看切服采样状态", Callback = showSampleStatus})
    tab:AddButton({Title = "停止此切服模块", Callback = function() controller:Stop() end})
    emit(nil, nil)
    task.spawn(function()
        while running do
            local ok, seconds = pcall(function() return player:GetNetworkPing() end)
            if not running then return end
            local ping = ok and finite(seconds) and seconds >= 0 and math.floor(seconds * 1000 + 0.5) or nil
            status.PingMs = ping
            local ready = config.AutoSwitch and os.clock() - enabledAt >= config.InitialDelaySeconds
            if ready and ping and ping >= config.PingThresholdMs then highSamples = highSamples + 1 else highSamples = 0 end
            emit(nil, nil)
            if running and config.AutoSwitch and highSamples >= config.PingSamplesRequired then
                controller:Switch()
                highSamples = 0
            end
            local deadline = os.clock() + config.SampleIntervalSeconds
            while running and os.clock() < deadline do task.wait(0.1) end
        end
    end)
    return controller
end

end)()
local RuntimeMonitorFactory = (function()
-- Vortexion R2.16: read-only, touch-transparent performance telemetry.
-- No screen-sized frames, buttons, modal capture or CoreGui modifications.
return function(tab, bridge)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")
    local localPlayer = Players.LocalPlayer
    local running, active, accumulator, frames = false, true, 0, 0
    local sampleInterval = 1
    local frameConnection, screenGui, label = nil, nil, nil
    local fps, minimum, maximum, samples = 0, math.huge, 0, 0
    local peakFrameMs, stutterCount, lastAverageFrameMs = 0, 0, 0
    local intervalFrameMs, intervalFrames = 0, 0
    local STUTTER_THRESHOLD_MS = 50
    local lastPing, lastMemory = nil, nil
    local startedAt = os.clock()

    local function elapsedString(seconds)
        local n = math.max(0, math.floor(seconds))
        return string.format("%02d:%02d:%02d", math.floor(n / 3600), math.floor(n / 60) % 60, n % 60)
    end
    local function textReport()
        return ("FPS %d [%d-%d] | %.1fms\nPING %s | RAM %s MB\nPEAK %.0fms | >50ms %d\nUP %s | UI %sHz"):format(
            fps, samples > 0 and minimum or 0, maximum, lastAverageFrameMs,
            lastPing and tostring(math.floor(lastPing + 0.5)) .. "ms" or "--",
            lastMemory and tostring(math.floor(lastMemory + 0.5)) or "--",
            peakFrameMs, stutterCount, elapsedString(os.clock() - startedAt),
            tostring(math.floor(tonumber(bridge.VisualHz) or 0)))
    end
    local function makeGui()
        if screenGui or not active then return end
        local parent
        pcall(function() parent = localPlayer:FindFirstChildOfClass("PlayerGui") end)
        if not parent then return end
        -- A stale HUD from an earlier executor run must not remain as an input overlay.
        pcall(function()
            local stale = parent:FindFirstChild("VortexionPerformanceHUD")
            if stale then stale:Destroy() end
        end)
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionPerformanceHUD"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = false
        gui.DisplayOrder = -1000  -- Never compete with game / Roblox menus.
        pcall(function() gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets end)
        local content = Instance.new("TextLabel")
        content.Name = "Metrics"
        content.AnchorPoint = Vector2.new(1, 0)
        content.Position = UDim2.new(1, -6, 0, 5)
        content.Size = UDim2.fromOffset(0, 0)
        if Enum.AutomaticSize then content.AutomaticSize = Enum.AutomaticSize.XY end
        content.BackgroundColor3 = Color3.fromRGB(12, 16, 21)
        content.BackgroundTransparency = 0.45
        content.BorderSizePixel = 0
        content.TextColor3 = Color3.fromRGB(236, 241, 246)
        content.TextStrokeTransparency = 0.7
        content.Font = Enum.Font.Code
        content.TextSize = 12
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.TextWrapped = false
        content.Text = textReport()
        content.Active = false
        content.Selectable = false
        pcall(function() content.Interactable = false end)
        pcall(function() content.InputSink = Enum.InputSink.None end)
        -- Padding belongs to the text itself: no oversized backdrop frame.
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 3)
        padding.PaddingRight = UDim.new(0, 3)
        padding.PaddingTop = UDim.new(0, 2)
        padding.PaddingBottom = UDim.new(0, 2)
        padding.Parent = content
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 3)
        corner.Parent = content
        content.Parent = gui
        local ok = pcall(function() gui.Parent = parent end)
        if not ok or not gui.Parent then gui:Destroy(); return end
        screenGui, label = gui, content
    end
    local function snapshot()
        return {
            fps = fps, minFps = samples > 0 and minimum or 0, maxFps = maximum,
            avgFrameMs = lastAverageFrameMs, peakFrameMs = peakFrameMs,
            stutters = stutterCount, pingMs = lastPing, memoryMb = lastMemory,
            samples = samples, uptimeSeconds = math.floor(os.clock() - startedAt),
            gameId = game.GameId, placeId = game.PlaceId,
        }
    end
    local function update(dt)
        if not active or not running then return end
        local delta = tonumber(dt)
        if not delta or delta ~= delta or delta < 0 or delta == math.huge then return end
        local ms = delta * 1000
        peakFrameMs = math.max(peakFrameMs, ms)
        if ms >= STUTTER_THRESHOLD_MS then stutterCount += 1 end
        intervalFrameMs += ms
        intervalFrames += 1
        frames += 1
        accumulator += math.min(delta, 0.5)
        if accumulator < sampleInterval then return end
        fps = accumulator > 0 and math.floor(frames / accumulator + 0.5) or 0
        minimum, maximum = math.min(minimum, fps), math.max(maximum, fps)
        samples += 1
        lastAverageFrameMs = intervalFrames > 0 and intervalFrameMs / intervalFrames or 0
        frames, accumulator, intervalFrameMs, intervalFrames = 0, 0, 0, 0
        local okPing, ping = pcall(function() return localPlayer:GetNetworkPing() * 1000 end)
        if okPing and type(ping) == "number" and ping >= 0 and ping < math.huge then lastPing = ping end
        local okMemory, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
        if okMemory and type(mem) == "number" and mem >= 0 and mem < math.huge then lastMemory = mem end
        if label and label.Parent then label.Text = textReport() end
    end
    local function stop()
        running = false
        if frameConnection then frameConnection:Disconnect(); frameConnection = nil end
        if screenGui then screenGui:Destroy(); screenGui = nil; label = nil end
        accumulator, frames = 0, 0
    end
    local function resetSamples()
        fps, minimum, maximum, samples = 0, math.huge, 0, 0
        peakFrameMs, stutterCount, lastAverageFrameMs = 0, 0, 0
        frames, accumulator, intervalFrameMs, intervalFrames = 0, 0, 0, 0
        lastPing, lastMemory = nil, nil
        startedAt = os.clock()
        if label and label.Parent then label.Text = textReport() end
    end
    local function setEnabled(value)
        if not active then return end
        if not value then stop(); return end
        if running then return end
        makeGui()
        if not screenGui then
            bridge:Notify({Title = "性能监控", Content = "PlayerGui HUD 创建失败", Duration = 4})
            return
        end
        running = true
        frameConnection = RunService.Heartbeat:Connect(update)
    end
    tab:AddParagraph({Title = "性能与触控", Content = "紧凑 HUD 只含文本及 2-3px 内边距；位于系统安全区，不接收触摸，不修改 Roblox 菜单。"})
    tab:AddToggle("VortexionPerfHUD", {Title = "显示性能 HUD", Default = false, Callback = setEnabled})
    tab:AddSlider("VortexionPerfSampleSeconds", {Title = "采样间隔（秒）", Min = 1, Max = 5, Default = 1, Rounding = 0,
        Callback = function(v)
            local n = tonumber(v)
            if not n or n ~= n or n == math.huge or n == -math.huge then n = 1 end
            sampleInterval = math.max(1, math.min(5, n))
        end})
    tab:AddButton({Title = "紧急关闭性能 HUD（排查 Roblox 菜单）", Callback = function()
        stop()
        local option = bridge.Options and bridge.Options.VortexionPerfHUD
        if option and option.SetValue then option:SetValue(false) end
    end})
    tab:AddButton({Title = "重置性能采样", Callback = resetSamples})
    tab:AddButton({Title = "复制性能诊断", Callback = function()
        local s = snapshot()
        local info = ("Vortexion Runtime\nGameId=%s PlaceId=%s\nFPS=%d min=%d max=%d\nFrameAvgMs=%.2f FramePeakMs=%.2f Stutters(>=50ms)=%d\nPing=%s Memory=%s Samples=%d Uptime=%ds")
            :format(tostring(s.gameId), tostring(s.placeId), s.fps, s.minFps, s.maxFps,
                s.avgFrameMs, s.peakFrameMs, s.stutters,
                tostring(s.pingMs or "unavailable"), tostring(s.memoryMb or "unavailable"), s.samples, s.uptimeSeconds)
        local copy = type(setclipboard) == "function" and setclipboard or type(toclipboard) == "function" and toclipboard
        if copy then
            local ok = pcall(copy, info)
            bridge:Notify({Title = "性能诊断", Content = ok and "已复制" or "复制失败，详见控制台", Duration = 4})
        else
            warn(info)
            bridge:Notify({Title = "性能诊断", Content = "无剪贴板接口，已输出到控制台", Duration = 4})
        end
    end})
    bridge:OnDestroy(function() active = false; stop() end)
    return {GetSnapshot = snapshot, Stop = stop, Reset = resetSamples}
end

end)()
local WindBridgeFactory = (function()
-- Vortexion Neverlose bridge. All existing game feature IDs and module APIs are preserved.
-- The shared UI is vendored offline; no HttpGet dependency at runtime.
return function(Neverlose, config)
    config = config or {}
    assert(type(Neverlose) == "table" and type(Neverlose.Window) == "function", "Neverlose UI unavailable")
    local env = config.Env or ((type(getgenv) == "function" and getgenv()) or _G)
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local GuiService = game:GetService("GuiService")
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local mobile = UIS.TouchEnabled
    local callbacks, connections, health, recent = {}, {}, {}, {}
    local window, root, scale, viewportCamera, cameraConn = nil, nil, nil, nil, nil
    local createdPages, selectedPage = {}, ""
    local resizing, lastViewport, lastInsets = false, "", ""
    local uiScale = 1
    local stats = {callbacks=0, inputs=0, errors=0, repairs=0, resizes=0}
    local bridge = {Active=true, Library=Neverlose, Options={}, Tabs={}, GameTabs={}, GUI=Neverlose.Holder and Neverlose.Holder.Instance,
        VisualHz=mobile and 30 or 60, NativeNoticesEnabled=not mobile, NoticeHistory={}, AutoFit=true, SafeArea=true,
        Trace=false, Debug=config.Debug == true, TouchMode=mobile and "手指" or "鼠标"}
    env.VortexionWindBridge = bridge -- backwards-compatible key, used for old bundle teardown
    env.VortexionNeverloseBridge = bridge

    local function copy(t)
        if type(t) ~= "table" then return t end
        local r = {}; for k,v in pairs(t) do r[k]=copy(v) end; return r
    end
    local function same(a,b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= "table" then return a == b end
        for k,v in pairs(a) do if not same(v,b[k]) then return false end end
        for k in pairs(b) do if a[k]==nil then return false end end
        return true
    end
    local function finite(n, default)
        n = tonumber(n)
        if not n or n~=n or math.abs(n)==math.huge then return default end
        return n
    end
    local function clamp(n, lo, hi) return math.max(lo,math.min(hi,n)) end
    local function fire(fn,...)
        if type(fn) ~= "function" then return true end
        stats.callbacks=stats.callbacks+1
        local ok,err=pcall(fn,...)
        if not ok then
            stats.errors=stats.errors+1; bridge.LastError=tostring(err)
            warn("[Vortexion/Neverlose] "..tostring(err))
        end
        return ok
    end
    function bridge:Notify(info, message, duration)
        local title,desc,seconds
        if type(info)=="table" then
            title=tostring(info.Title or "Vortexion")
            desc=tostring(info.Content or info.Description or "")
            seconds=finite(info.Duration,4)
        else title=tostring(info or "Vortexion"); desc=tostring(message or ""); seconds=finite(duration,4) end
        local record=(title..": "..desc):sub(1,1500)
        self.NoticeHistory[#self.NoticeHistory+1]=record
        if #self.NoticeHistory>20 then table.remove(self.NoticeHistory,1) end
        if not self.NativeNoticesEnabled then print("[Vortexion/Notice] "..record); return end
        local ok,err=pcall(function() Neverlose:Notification({Title=title,Description=desc,Duration=seconds}) end)
        if not ok then self.LastError=tostring(err) end
    end
    local function trace(id,from,v,ok)
        recent[#recent+1]=(from.." "..tostring(id).."="..tostring(v).." "..tostring(ok)):sub(1,220)
        if #recent>24 then table.remove(recent,1) end
        if bridge.Trace then print("[Vortexion/Neverlose/Trace] "..recent[#recent]) end
    end
    function bridge:FeatureTrace() return #recent>0 and table.concat(recent,"\n") or "暂无控件事件" end
    function bridge:OnDestroy(fn)
        if self.Active then callbacks[#callbacks+1]=fn else fire(fn) end
    end
    function bridge:Destroy()
        if not self.Active then return end
        self.Active=false
        if self.ServerSwitch then pcall(function() self.ServerSwitch:Stop() end) end
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        for _,fn in ipairs(callbacks) do fire(fn) end
        table.clear(callbacks); table.clear(connections); table.clear(health)
        if env.VortexionWindBridge==self then env.VortexionWindBridge=nil end
        if env.VortexionNeverloseBridge==self then env.VortexionNeverloseBridge=nil end
        pcall(function() Neverlose:Unload() end)
        window=nil; root=nil
    end
    bridge.Window=function() return window end
    function bridge:RegisterFeatureHealth(name,fn)
        if not self.Active or type(fn)~="function" then return false end
        health[tostring(name)]=fn; return true
    end
    function bridge:FeatureHealth()
        local out={}
        for name,fn in pairs(health) do
            local ok,v=pcall(fn)
            out[#out+1]=name..": "..(ok and tostring(v) or ("ERROR: "..tostring(v)))
        end
        table.sort(out)
        return #out>0 and table.concat(out,"\n") or "暂无游戏模块状态报告"
    end
    function bridge:GetVisualInterval(base)
        return math.max(finite(base,0),1/clamp(finite(self.VisualHz,30),5,60))
    end
    -- Read native state, including user tap updates. Never overwrite the user's
    -- last action with an older programmatic Set() or repeated default callback.
    function bridge:ReconcileGameplayOptions()
        local repaired=0
        if not self.Active then return 0 end
        for _,item in pairs(self.Options) do
            if item.Kind=="Toggle" and item.Native and type(item.Native.Get)=="function" then
                local ok,value=pcall(function() return item.Native:Get() end)
                if ok and type(value)=="boolean" and value~=item.Value then
                    if item:SyncFromNative() then repaired=repaired+1 end
                end
            end
        end
        stats.repairs=stats.repairs+repaired
        return repaired
    end
    local clock=0
    connections[#connections+1]=RunService.Heartbeat:Connect(function(dt)
        if not bridge.Active then return end
        clock=clock+clamp(finite(dt,0),0,0.5)
        if clock>=1 then
            clock=0
            bridge:ReconcileGameplayOptions()
            if bridge.RefreshDiagnostics then bridge:RefreshDiagnostics() end
        end
    end)

    local function readInsets()
        if not bridge.SafeArea then return 0,0,0,0 end
        local ok,top,bottom=pcall(function() return GuiService:GetGuiInset() end)
        if not ok or not top or not bottom then return 0,0,0,0 end
        -- Inset returns top-left and bottom-right Vector2, both are pixel offsets.
        return clamp(finite(top.X,0),0,1000),clamp(finite(top.Y,0),0,1000),
               clamp(finite(bottom.X,0),0,1000),clamp(finite(bottom.Y,0),0,1000)
    end
    function bridge:FitViewport()
        if not self.Active or not root or not scale or not self.AutoFit then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local viewport=cam.ViewportSize
        local vx,vy=finite(viewport.X,0),finite(viewport.Y,0)
        -- Avoid Roblox errors when camera viewport temporarily becomes (0,0),
        -- NaN or infinity during rotation, app backgrounding or device resize.
        if vx<=0 or vy<=0 then self.LastViewport="等待有效视口";return end
        local l,t,r,b=readInsets()
        l,r=clamp(l,0,vx/3),clamp(r,0,vx/3)
        t,b=clamp(t,0,vy/3),clamp(b,0,vy/3)
        local width,height=math.max(1,vx-l-r),math.max(1,vy-t-b)
        if width<=32 or height<=80 then self.LastViewport="视口暂不可用";return end
        -- On portrait devices the Neverlose sidebar becomes compact and pages
        -- reflow to a single column. The reference window is intentionally fixed
        -- in logical pixels, with a single UIScale instance owned by this bridge.
        local aspect=width/height
        local menuWidth=mobile and (aspect < 0.86 and 460 or 690) or 790
        local menuHeight=mobile and (aspect < 0.86 and 630 or 570) or 590
        local sidebar=mobile and (aspect<0.86 and 112 or 172) or 192
        local baseW=menuWidth
        local baseH=menuHeight
        local fit=math.min((width-16)/baseW,(height-20)/baseH,1.15)
        local result=clamp(fit*uiScale,0.15,1.2)
        -- Never place part of the menu outside the usable area, even in split-screen.
        result=math.min(result,(width-8)/baseW,(height-8)/baseH)
        if result<=0 or finite(result,0)<=0 then return end
        local key=("%d:%d:%d:%d:%d:%d:%.3f:%d"):format(vx,vy,l,t,r,b,result,sidebar)
        if key==lastViewport then return end
        lastViewport=key
        local anchor=Vector2.new(0.5,0.5)
        root.AnchorPoint=anchor
        root.Size=UDim2.fromOffset(baseW,baseH)
        scale.Scale=result
        root.Position=UDim2.fromOffset(l+width/2,t+height/2)
        local elements=window.Native and window.Native.Items
        if elements then
            local sidebarFrame=elements.LeftTabs and elements.LeftTabs.Instance
            if sidebarFrame then
                sidebarFrame.AnchorPoint=Vector2.new(0,0)
                sidebarFrame.Position=UDim2.fromOffset(0,55)
                sidebarFrame.Size=UDim2.new(0,sidebar,1,-55)
                sidebarFrame.ScrollBarThickness=mobile and 4 or 3
            end
            local content=elements.Content and elements.Content.Instance
            if content then
                content.Position=UDim2.fromOffset(sidebar,55)
                content.Size=UDim2.new(1,-sidebar,1,-55)
            end
            for _,page in ipairs(window.Native.Pages) do
                local items=page.Items
                local btn=items and items.Inactive and items.Inactive.Instance
                if btn then btn.Size=UDim2.new(1,-4,0,mobile and 44 or 40) end
                local title=items and items.Text and items.Text.Instance
                if title then
                    title.Size=UDim2.new(1,-50,1,0)
                    title.TextTruncate=Enum.TextTruncate.AtEnd
                    title.TextSize=mobile and 13 or 14
                end
            end
        end
        -- Keep the mobile re-open handle below the OS safe area, not under its status bar.
        if mobile and elements and elements.FloatingButton and elements.FloatingButton.Instance then
            local floating=elements.FloatingButton.Instance
            if floating.Position.Y.Scale==0 and floating.Position.Y.Offset<=40 then
                floating.Position=UDim2.new(floating.Position.X.Scale,floating.Position.X.Offset,0,t+12)
            end
        end
        stats.resizes=stats.resizes+1
        self.EffectiveScale=result
        self.LastViewport=("%d×%d / UI %.2fx / 侧栏 %d"):format(vx,vy,result,sidebar)
    end
    local function bindCamera()
        if cameraConn then cameraConn:Disconnect(); cameraConn=nil end
        viewportCamera=Workspace.CurrentCamera
        if viewportCamera then
            cameraConn=viewportCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                bridge:FitViewport()
            end)
            connections[#connections+1]=cameraConn
        end
        bridge:FitViewport()
    end

    local function createTab(pageName,icon,category)
        if category and window.Native.Category then window.Native:Category(category) end
        local sourcePage=window.Native:Page({Name=pageName, Icon=icon or "122669828593160", Columns=mobile and 1 or 2})
        local tab={Native=sourcePage,Title=pageName,OptionCount=0,Sections={}}
        -- Reference-like semantic grouping. Headings describe the page domain;
        -- they are not invented feature switches. Alternating columns on PC,
        -- stacked sections on touch portrait.
        local headings
        if pageName:find("视觉") or pageName:find("ESP") or pageName:find("感知") then
            headings={"Main", "Players ESP", "World ESP", "Other"}
        elseif pageName:find("世界") then
            headings={"Main", "Ambient", "World ESP", "Other"}
        elseif pageName:find("战斗") or pageName:find("自瞄") then
            headings={"Main", "Targeting", "Advanced", "Other"}
        else
            headings={"Main", "Settings", "Advanced", "Other"}
        end
        local sectionLimit=mobile and 10 or 8
        local function newSection()
            local index=#tab.Sections+1
            local side=mobile and 1 or (index%2==0 and 2 or 1)
            local heading=headings[math.min(index,#headings)]
            if index>#headings then heading="Other · "..(index-#headings+1) end
            local section=sourcePage:Section({Name=heading,Side=side})
            table.insert(tab.Sections,section)
            return section
        end
        local function sectionFor()
            if (tab.OptionCount-1)%sectionLimit==0 then return newSection() end
            return tab.Sections[#tab.Sections] or newSection()
        end
        local function addOption(kind,id,c)
            c=c or {}; id=tostring(id)
            assert(bridge.Options[id]==nil,"重复选项 ID: "..id)
            local values=copy(c.Values or {})
            local low,high=finite(c.Min,0),finite(c.Max,100)
            local decimals=clamp(math.floor(finite(c.Rounding,0)),0,2)
            if kind=="Slider" then assert(low<high,"Slider Min must be < Max: "..id) end
            local step=10^(-decimals)
            local function normalize(v)
                if kind=="Toggle" then return v==true end
                if kind=="Input" then return tostring(v==nil and "" or v) end
                if kind=="Slider" then
                    local n=clamp(finite(v,low),low,high)
                    return clamp(math.floor(n/step+0.5)*step,low,high)
                end
                if kind=="Colorpicker" then return typeof(v)=="Color3" and v or Color3.fromRGB(0,195,255) end
                if c.Multi then return type(v)=="table" and copy(v) or (v==nil and {} or {v}) end
                if type(v)=="number" then v=values[v] end
                if v==nil then return values[1] end
                return v
            end
            local initial=normalize(c.Default)
            local option={ID=id,Kind=kind,Value=copy(initial),Values=values,listeners={}}
            bridge.Options[id]=option
            local ready=false
            local initialized=false
            local function propagate(value, origin)
                if not bridge.Active and not bridge.Cleaning then return false end
                value=normalize(value)
                if same(value,option.Value) and initialized then return false end
                initialized=true
                option.Value=copy(value)
                trace(id,origin,value,"received")
                local success=fire(c.Callback,copy(value))
                trace(id,origin,value,success and "OK" or "ERROR")
                for _,fn in ipairs(option.listeners) do fire(fn,copy(value)) end
                return true
            end
            local data={Name=tostring(c.Title or id),Flag=id,Default=copy(initial),Callback=function(v)
                if not ready then return end
                stats.inputs=stats.inputs+1
                propagate(v,"native")
            end}
            if kind=="Slider" then
                data.Min,data.Max,data.Decimals=low,high,step
                data.Suffix=c.Suffix or ""
            elseif kind=="Dropdown" then
                data.Items=values; data.Multi=c.Multi==true
                data.Size=mobile and 144 or 126
            elseif kind=="Input" then
                data.Placeholder=c.Placeholder or "请输入"
                data.Finished=true
            end
            tab.OptionCount=tab.OptionCount+1
            local section=sectionFor()
            if kind=="Input" then option.Native=section:Textbox(data)
            elseif kind=="Colorpicker" then
                option.Native=section:Label(data.Name):Colorpicker(data)
            else option.Native=section[kind](section,data) end
            -- Existing gameplay modules call GetValue() on Wind-compatible handles.
            function option:GetValue() return copy(self.Value) end
            function option:GetNativeValue()
                if not self.Native or type(self.Native.Get)~="function" then return self.Value end
                local ok,result=pcall(function() return self.Native:Get() end)
                return ok and normalize(result) or self.Value
            end
            function option:SyncFromNative()
                return propagate(self:GetNativeValue(),"audit")
            end
            function option:SetValue(v)
                if not bridge.Active and not bridge.Cleaning then return false end
                v=normalize(v)
                if same(v,self.Value) then return true end
                if bridge.Cleaning then return propagate(v,"cleanup") end
                local ok,err=pcall(function() self.Native:Set(copy(v)) end)
                if not ok then bridge.LastError=tostring(err); return false end
                -- Native:Set calls Callback synchronously. Guard duplicates and
                -- still emit when an executor's implementation omits callback.
                if same(self.Value,v) then return true end
                propagate(v,"setvalue")
                return true
            end
            function option:SetValues(new)
                if not bridge.Active or kind~="Dropdown" or type(new)~="table" then return false end
                local snapshot=copy(new)
                local ok,err=pcall(function()
                    -- Native :Refresh mutates Options asynchronously in some forks;
                    -- default to a valid value after refreshing.
                    self.Native:Refresh(snapshot)
                end)
                if not ok then bridge.LastError=tostring(err); return false end
                values=snapshot
                self.Values=copy(snapshot)
                if not c.Multi then
                    local exists=false
                    for _,item in ipairs(snapshot) do if item==self.Value then exists=true; break end end
                    if not exists then
                        if snapshot[1] then self:SetValue(snapshot[1])
                        else propagate(nil,"refresh-empty") end
                    end
                else
                    local allowed={}
                    for _,v in ipairs(snapshot) do allowed[v]=true end
                    local selected={}
                    if type(self.Value)=="table" then
                        for _,v in ipairs(self.Value) do if allowed[v] then selected[#selected+1]=v end end
                    end
                    if not same(selected,self.Value) then self:SetValue(selected) end
                end
                return true
            end
            function option:OnChanged(fn)
                if type(fn)=="function" then
                    table.insert(self.listeners,fn)
                    if bridge.Active then fire(fn,copy(self.Value)) end
                end
                return self
            end
            ready=true
            propagate(initial,"initial")
            return option
        end
        for _,kind in ipairs({"Toggle","Slider","Dropdown","Input","Colorpicker"}) do
            tab["Add"..kind]=function(_,id,c) return addOption(kind,id,c) end
        end
        function tab:AddButton(info)
            info=info or {}; self.OptionCount=self.OptionCount+1
            local section=sectionFor()
            return section:Button({Name=tostring(info.Title or "运行"),Callback=function()
                if bridge.Active and not info.Locked then fire(info.Callback) end
            end})
        end
        function tab:AddParagraph(info)
            info=info or {}; self.OptionCount=self.OptionCount+1
            local section=sectionFor()
            local label=section:Label(tostring(info.Title or "说明").."\n"..tostring(info.Content or info.Desc or ""))
            function label:SetDesc(text)
                self:SetText(tostring(info.Title or "说明").."\n"..tostring(text))
            end
            return label
        end
        table.insert(bridge.Tabs,tab)
        return tab
    end

    local function installSettings()
        window.Native:Category("VORTEXION · UI")
        local appearance=createTab("外观与布局","122669828593160")
        local diagnostics=createTab("UI 调试","122669828593160")
        local configuration=createTab("配置","122669828593160")
        bridge.SettingsTabs={['主题']=appearance,['界面']=appearance,['调试']=diagnostics,['配置']=configuration}
        appearance:AddParagraph({Title="Neverlose · Vortexion",Content="宣传图风格的深色双列功能面板；窄屏自动转为单列。R224 图标使用用户提供的 PNG。"})
        appearance:AddParagraph({Title="图标资源状态",Content=tostring(bridge.BrandMode or "尚未检测")})
        appearance:AddToggle("nl_auto_fit",{Title="根据屏幕尺寸自动适配",Default=true,Callback=function(v)
            bridge.AutoFit=v; lastViewport=""; bridge:FitViewport()
        end})
        appearance:AddToggle("nl_safe_area",{Title="遵守系统安全区域",Default=true,Callback=function(v)
            bridge.SafeArea=v; lastViewport=""; bridge:FitViewport()
        end})
        appearance:AddSlider("nl_scale",{Title="UI 尺寸百分比",Min=65,Max=120,Default=100,Rounding=0,Suffix="%",Callback=function(v)
            uiScale=v/100; lastViewport=""; bridge:FitViewport()
        end})
        appearance:AddDropdown("nl_accent",{Title="强调色",Values={"Neverlose 蓝","翡翠绿","灰白","琥珀"},Default="Neverlose 蓝",Callback=function(v)
            local colors={['Neverlose 蓝']={Color3.fromRGB(66,173,190),Color3.fromRGB(106,210,218)},['翡翠绿']={Color3.fromRGB(18,164,120),Color3.fromRGB(70,201,164)},['灰白']={Color3.fromRGB(170,178,192),Color3.fromRGB(212,217,225)},['琥珀']={Color3.fromRGB(214,142,32),Color3.fromRGB(244,192,83)}}
            local picked=colors[v]
            if picked then
                Neverlose:ChangeTheme("Accent",picked[1]); Neverlose:ChangeTheme("AccentGradient",picked[2])
            end
        end})
        appearance:AddToggle("nl_notifications",{Title="屏幕通知（触屏默认关闭）",Default=not mobile,Callback=function(v) bridge.NativeNoticesEnabled=v end})
        appearance:AddDropdown("nl_visual_perf",{Title="视觉更新档位",Values={"原速","均衡","省电"},Default=mobile and "均衡" or "原速",Callback=function(v)
            bridge.VisualHz=({["原速"]=60,["均衡"]=30,["省电"]=10})[v] or 30
        end})
        appearance:AddButton({Title="恢复默认窗口尺寸",Callback=function()
            bridge.Options.nl_scale:SetValue(100); bridge.Options.nl_auto_fit:SetValue(true)
            bridge.Options.nl_safe_area:SetValue(true); lastViewport=""; bridge:FitViewport()
        end})
        diagnostics:AddParagraph({Title="输入诊断",Content="点击下方开关检查真实触摸回调。该测试只证明 UI 回调收到事件，不代表服务器功能生效。"})
        local diagnosticLabel=diagnostics:AddParagraph({Title="实时状态",Content="正在检测触控与视口..."})
        local lastDiagnostics=""
        function bridge:RefreshDiagnostics()
            if not self.Active then return end
            local report=("输入设备: %s | 可见: %s\n视口: %s\n收到输入: %d | 回调执行: %d | 异常: %d | 状态修复: %d\n触控试验: %s\n最近控件: %s\n错误: %s")
                :format(self.TouchMode,tostring(window and window.Native and window.Native.IsOpen),self.LastViewport or "未知",stats.inputs,stats.callbacks,stats.errors,stats.repairs,self.LastTouchProbe or "未进行",recent[#recent] or "无",self.LastError or "无")
            if report~=lastDiagnostics then lastDiagnostics=report;diagnosticLabel:SetDesc(report) end
        end
        diagnostics:AddToggle("nl_touch_probe",{Title="触控事件计数测试",Default=false,Callback=function(v)
            bridge.LastTouchProbe="测试回调 "..tostring(v).." · "..tostring(stats.inputs)
            bridge:RefreshDiagnostics()
        end})
        diagnostics:AddToggle("nl_trace",{Title="跟踪控件回调",Default=false,Callback=function(v)bridge.Trace=v end})
        diagnostics:AddButton({Title="复核所有游戏开关状态",Callback=function()
            local n=bridge:ReconcileGameplayOptions()
            bridge:Notify({Title="状态复核",Content=("修复 %d 个本地状态\n%s"):format(n,bridge:FeatureHealth()),Duration=8})
        end})
        diagnostics:AddButton({Title="运行视口 / 触控自检",Callback=function()
            lastViewport=""; bridge:FitViewport()
            local str=("设备: %s\n窗口: %s\n事件: %d | 回调: %d | 修复: %d\n最近触控: %s\n错误: %s")
                :format(bridge.TouchMode,bridge.LastViewport or "未计算",stats.inputs,stats.callbacks,stats.repairs,bridge.LastTouchProbe or "无",bridge.LastError or "无")
            bridge.LastProbe=str
            bridge:RefreshDiagnostics()
            print("[Vortexion/Neverlose/UIProbe] "..str)
            bridge:Notify({Title="Neverlose 移动端检查",Content=str,Duration=10})
        end})
        diagnostics:AddButton({Title="打印最近 24 条控件记录",Callback=function()print(bridge:FeatureTrace()) end})
        diagnostics:AddButton({Title="打印所有游戏模块状态",Callback=function()print(bridge:FeatureHealth()) end})
        diagnostics:AddButton({Title="清除最近异常",Callback=function()bridge.LastError=nil end})
        bridge.GetDiagnostics=function()
            return ("Neverlose | %s | 当前页面 %s | %s | %d 控件 | %d 回调 | %d 次异常 | %d 次重排 | %s")
                :format(bridge.TouchMode,selectedPage,bridge.LastViewport or "未适配",(function()local n=0;for _ in pairs(bridge.Options)do n=n+1 end;return n end)(),stats.callbacks,stats.errors,stats.resizes,bridge.LastError or "无")
        end
        configuration:AddParagraph({Title="会话配置",Content="按 PlaceId 隔离；可选文件接口；仅手动保存或加载，不执行外部脚本。"})
        local folder="Vortexion/neverlose-"..tostring(game.PlaceId)
        local configName=configuration:AddInput("nl_config_name",{Title="配置名称",Default="default",Placeholder="字母、数字、下划线或横线"})
        local function filepath()
            local name=configName.Value:gsub("[^%w_%-]","")
            name=name:sub(1,40)
            if name=="" then name="default" end
            return folder.."/"..name..".json"
        end
        local function ensureDir()
            if type(isfolder)~="function" or type(makefolder)~="function" then return false end
            if not isfolder("Vortexion") then makefolder("Vortexion") end
            if not isfolder(folder) then makefolder(folder) end
            return true
        end
        configuration:AddButton({Title="保存选项配置",Callback=function()
            if type(writefile)~="function" or not ensureDir() then bridge:Notify("配置","执行器缺少文件接口");return end
            local data={schema=1,placeId=game.PlaceId,options={}}
            for id,opt in pairs(bridge.Options) do
                if id~="nl_config_name" and opt.Kind~="Colorpicker" then data.options[id]=copy(opt.Value) end
            end
            local ok,err=pcall(function()writefile(filepath(),HttpService:JSONEncode(data)) end)
            bridge:Notify("保存配置",ok and "保存成功" or tostring(err))
        end})
        configuration:AddButton({Title="读取选项配置",Callback=function()
            if type(readfile)~="function" or type(isfile)~="function" then bridge:Notify("配置","执行器缺少读取接口");return end
            local path=filepath()
            local ok,result=pcall(function()
                if not isfile(path) then error("配置文件不存在") end
                local raw=HttpService:JSONDecode(readfile(path))
                assert(type(raw)=="table" and raw.schema==1 and raw.placeId==game.PlaceId and type(raw.options)=="table","配置格式或游戏不匹配")
                local count=0
                for id,v in pairs(raw.options) do
                    local opt=bridge.Options[id]
                    if opt and opt.Kind~="Colorpicker" and opt:SetValue(v) then count=count+1 end
                end
                return count
            end)
            bridge:Notify("加载配置",ok and ("加载 "..result.." 项") or tostring(result))
        end})
    end

    function bridge:CreateWindow(info)
        if window then return window end
        if not self.Active then return nil end
        info=info or {}
        local deadline=os.clock()+6
        while not Workspace.CurrentCamera and self.Active and os.clock()<deadline do task.wait(0.05) end
        assert(Workspace.CurrentCamera,"Neverlose requires an active camera")
        local brandAsset,brandReason
        if type(VortexionLogoAssetFactory)=="function" then
            brandAsset,brandReason = VortexionLogoAssetFactory()
        else
            brandReason = "logo factory unavailable"
        end
        bridge.BrandMode = brandReason
        -- Actual second uploaded PNG is embedded; only unsupported executors use the legacy Roblox asset.
        local native=Neverlose:Window({Name="VORTEXION",SubName="VORTEXION · NEVERLOSE",Logo=brandAsset or "120959262762131"})
        root=native.Items.MainFrame.Instance
        -- One UIScale. Neverlose's original mobile fixed 0.7 scale was removed.
        scale=Instance.new("UIScale");scale.Name="VortexionViewportScale";scale.Scale=1;scale.Parent=root
        window={Native=native,Root=root,GameTabs=bridge.GameTabs}
        local gameCategoryInserted=false
        function window:AddTab(data)
            if not gameCategoryInserted then native:Category("VORTEXION · GAMES"); gameCategoryInserted=true end
            data=data or {}
            local tab=createTab(tostring(data.Title or "功能"),nil)
            bridge.GameTabs[#bridge.GameTabs+1]=tab
            lastViewport=""; bridge:FitViewport()
            return tab
        end
        local selectRevision=0
        function window:SelectTab(i)
            local tab=bridge.GameTabs[i]
            if not bridge.Active or not tab then return end
            selectedPage=tab.Title
            selectRevision=selectRevision+1
            local revision=selectRevision
            local function apply()
                if not bridge.Active or selectRevision~=revision then return end
                for _,page in ipairs(native.Pages) do
                    local shouldOpen=page==tab.Native
                    if page.Active~=shouldOpen then page:Turn(shouldOpen) end
                end
            end
            apply()
            -- Neverlose's first page is still fading when a game initializes.
            -- Reconcile once after the vendor debounce to avoid stacked pages.
            task.delay(0.8,apply)
        end
        function window:Minimize() native:SetOpen(false) end
        function window:Destroy() bridge:Destroy() end
        function window:InstallSettings() end
        native:Category("VORTEXION · GENERAL")
        local common=createTab("低延迟切服")
        local serverFactory=config.ServerSwitchFactory or ServerSwitchFactory
        if type(serverFactory)=="function" then
            local ok,result=pcall(serverFactory,common,function(msg)bridge:Notify("低延迟切服",msg)end)
            if ok then bridge.ServerSwitch=result else bridge.LastError="ServerSwitch: "..tostring(result) end
        else common:AddParagraph({Title="切服模块不可用",Content="请检查构建文件"}) end
        local perf=createTab("性能诊断")
        if type(RuntimeMonitorFactory)=="function" then
            local ok,result=pcall(RuntimeMonitorFactory,perf,bridge)
            if ok then bridge.RuntimeMonitor=result else bridge.LastError="RuntimeMonitor: "..tostring(result) end
        end
        installSettings()
        bridge:RefreshDiagnostics()
        connections[#connections+1]=Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
        bindCamera()
        task.defer(function() if bridge.Active and native then pcall(function() native:Init() end) end end)
        -- Official topbar inset changes without viewport changes (mobile safe area).
        local ok,insetSignal=pcall(function()return GuiService:GetPropertyChangedSignal("TopbarInset") end)
        if ok and insetSignal then
            connections[#connections+1]=insetSignal:Connect(function()lastViewport="";bridge:FitViewport() end)
        end
        return window
    end
    return bridge
end

end)()
local GameRouter = (function()
-- Exact experience routing, independent from game feature initialization.
local Router = {}
local UNIVERSE_ROUTES = {
    [6331902150] = "Forsaken",
    [7633926880] = "BloxStrike",
    [1742264997] = "SCP",
}
local PLACE_FALLBACK = {
    [18687417158] = "Forsaken",
    [114234929420007] = "BloxStrike",
    [5041144419] = "SCP",
}
local AOTR_UNIVERSE = 4658598196
local AOTR_PLACES = {
    [13379208636] = "AOTR_Lobby",
    [14916516914] = "AOTR_Lobby",
    [13379349730] = "AOTR_Battle",
    [14638336319] = "AOTR_Battle",
    [14012874501] = "AOTR_Battle",
    [13904207646] = "AOTR_Battle",
}

function Router.Resolve(universe, place)
    universe, place = tonumber(universe), tonumber(place)
    -- Do not fall through to another game from an unknown AOTR scene.
    if universe == AOTR_UNIVERSE then
        local entry = AOTR_PLACES[place]
        return entry, entry and "aotr-place" or "unsupported-aotr-scene"
    end
    local entry = UNIVERSE_ROUTES[universe]
    if entry then return entry, "universe" end
    entry = PLACE_FALLBACK[place]
    return entry, entry and "place-fallback" or "unsupported-experience"
end

function Router.ShowUnsupported(WindUI, WindBridgeFactory, universe, place, reason, detail)
    local bridge = WindBridgeFactory(WindUI, {
        Name = "Vortexion", Folder = "VortexionWind", Section = "V O R T E X I O N",
    })
    local window = bridge:CreateWindow({Title = "Vortexion"})
    local info = window:AddTab({Title = "游戏说明", Icon = "lucide-info"})
    info:AddParagraph({
        Title = detail and "游戏功能初始化未完成"
            or (reason == "unsupported-aotr-scene" and "AOTR 未识别场景" or "未支持的游戏"),
        Content = ("GameId: %s / PlaceId: %s\n%s")
            :format(tostring(universe), tostring(place), detail
                or "仅加载 Wind 通用功能和 UI 设置，未启动任何游戏功能。"),
    })
    info:AddParagraph({
        Title = "支持的游戏",
        Content = "Forsaken、BloxStrike、SCP；AOTR 主菜单与大厅加载大厅模块，已核实的任务地图加载战斗模块。交易中心及未知 AOTR 场景保留通用界面。",
    })
    window:SelectTab(1)
    return bridge
end

-- Keep the generic interface visible when a game exits before creating its UI.
function Router.Run(WindUI, WindBridgeFactory, entry, universe, place, reason)
    local ok, result = true, nil
    if entry then ok, result = pcall(entry) end
    local client = (getgenv and getgenv()) or _G
    local bridge = client.VortexionWindBridge
    local summary = not ok and tostring(result):sub(1, 500) or nil
    local failure = client.VortexionBootError
    -- Prefer the actual constructor error over the caller's abbreviated Lua location.
    -- Entry points often rethrow at CreateWindow({...}), losing the vendor frame.
    if type(failure) == "string" and failure:find("WindUI/CreateWindow", 1, true) then
        summary = failure:sub(1, 1400)
    elseif failure and not summary then
        summary = tostring(failure):sub(1, 800)
    end
    local window
    if type(bridge) == "table" and bridge.Active ~= false then
        if type(bridge.Window) == "function" then
            local windowOk, value = pcall(bridge.Window, bridge)
            if windowOk then window = value end
        else
            window = bridge.Window
        end
    end
    if entry and window then
        if summary then
            warn("[Vortexion/Wind] Game initialization: " .. summary)
            if type(bridge.Notify) == "function" then
                pcall(function() bridge:Notify({Title = "游戏初始化失败", Content = summary, Duration = 6}) end)
            end
        end
        local existingPartial = bridge.BootStatus == "partial"
        bridge.BootStatus = (summary or existingPartial) and "partial" or "ready"
        bridge.BootError = summary or (existingPartial and bridge.BootError or nil)
        return ok and result or bridge
    end
    if entry then
        reason = "game-initialization-incomplete"
        summary = summary or "游戏入口提前结束，尚未创建功能界面。"
        client.VortexionBootError = summary
        warn("[Vortexion/Wind] Game initialization: " .. summary)
    end
    if type(bridge) == "table" and type(bridge.Destroy) == "function" then
        pcall(function() bridge:Destroy() end)
    end
    -- A failed vendor CreateWindow destroys the ScreenGui and its Window folder.
    -- Retrying ShowUnsupported against this *same* WindUI object only hides the
    -- first error with "Window is not a valid member of ScreenGui". The loader's
    -- already-visible diagnostic UI is the safe fallback for this case.
    -- Constructor failure can destroy the vendor ScreenGui even when the entry's
    -- error string is just the outer calling line. Never reuse this WindUI instance.
    if (summary and string.find(summary, "WindUI/CreateWindow", 1, true))
        or (type(failure) == "string" and failure:find("WindUI/CreateWindow", 1, true)) then
        client.VortexionBootError = type(failure) == "string" and failure or summary
        warn("[Vortexion/Wind] Skipping unsafe UI fallback after constructor failure: " .. tostring(client.VortexionBootError))
        return nil
    end
    local fallbackOk, fallback = pcall(Router.ShowUnsupported, WindUI, WindBridgeFactory, universe, place, reason, summary)
    if fallbackOk and type(fallback) == "table" then
        fallback.BootStatus = entry and "partial" or "unsupported"
        fallback.BootError = summary
        return fallback
    end
    client.VortexionBootError = "Generic UI fallback: " .. tostring(fallback)
        .. (summary and ("; Original failure: " .. summary) or "")
    warn("[Vortexion/Wind] " .. client.VortexionBootError)
    return nil
end

return Router

end)()
return {WindUI=WindUI, WindBridgeFactory=WindBridgeFactory, ServerSwitchFactory=ServerSwitchFactory, GameRouter=GameRouter}
