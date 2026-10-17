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
            ["AccentGradient"] = FromRGB(0, 195, 255),   -- Slightly deeper blue accent
            ["Background 2"] = FromRGB(10, 10, 12),      -- Very dark gray
            ["Background"] = FromRGB(12, 12, 14),        -- Main near-black background
            ["Text"] = FromRGB(235, 235, 235),           -- Slightly dimmed light text
            ["Outline"] = FromRGB(25, 25, 28),           -- Subtle outline, almost invisible
            ["Section Top"] = FromRGB(28, 27, 31),       -- Dark section header
            ["Section Background"] = FromRGB(10, 10, 12),-- Deep black section background
            ["Section Background 2"] = FromRGB(14, 14, 16),-- Alternate section, minimal difference
            ["Accent"] = FromRGB(0, 116, 224),           -- Darker blue accent for consistency
            ["Element"] = FromRGB(16, 16, 18)            -- Deep gray for UI elements
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
                    BackgroundTransparency = 0.12,
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
                    BackgroundTransparency = 0.15,
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
                        Size = UDim2New(0, 50, 0, 50),
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
                        Image = "rbxassetid://" .. Window.Logo,
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
                        Enabled = true,
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
                    Image = "rbxassetid://"..Window.Logo,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 12),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Logo"].Instance,
                    Name = "\0",
                    Enabled = true,
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
        local menuWidth=mobile and (aspect < 0.86 and 460 or 655) or 677
        local menuHeight=mobile and (aspect < 0.86 and 630 or 560) or 644
        local sidebar=mobile and (aspect<0.86 and 112 or 158) or 225
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
        local function newSection()
            local index=#tab.Sections+1
            local side=mobile and 1 or (index%2==0 and 2 or 1)
            local section=sourcePage:Section({Name=index==1 and "功能" or ("功能 · "..index),Side=side})
            table.insert(tab.Sections,section)
            return section
        end
        local function sectionFor()
            if tab.OptionCount%14==0 then return newSection() end
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
        appearance:AddParagraph({Title="Neverlose · Mobile",Content="移动端采用单列布局、自动屏幕适配、触控优先、关闭全窗口拖动。"})
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
            local colors={['Neverlose 蓝']={Color3.fromRGB(0,116,224),Color3.fromRGB(0,195,255)},['翡翠绿']={Color3.fromRGB(18,164,120),Color3.fromRGB(70,201,164)},['灰白']={Color3.fromRGB(170,178,192),Color3.fromRGB(212,217,225)},['琥珀']={Color3.fromRGB(214,142,32),Color3.fromRGB(244,192,83)}}
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
        local native=Neverlose:Window({Name=tostring(info.Title or config.Name or "Vortexion"),SubName="VORTEXION · NEVERLOSE",Logo="120959262762131"})
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
local entry = function()
local AOTRCommon = (function()
-- Lifecycle, capability probe and UI shared by AOTR lobby and battle.
-- Modules receive this app table and register features against it.
return function(scene, WindUI, Bridge)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local Lighting=game:GetService("Lighting")
    local UserInputService=game:GetService("UserInputService")
    local Stats=game:GetService("Stats")
    local client=(getgenv and getgenv()) or _G
    if type(client.VortexionAOTRCleanup)=="function" then pcall(client.VortexionAOTRCleanup) end
    local app={scene=scene, connections={}, disposers={}, active=true, flags={}, player=Players.LocalPlayer}
    app.Services={Players=Players,RunService=RunService,Workspace=Workspace,
        ReplicatedStorage=ReplicatedStorage,Lighting=Lighting,Input=UserInputService,
        UserInputService=UserInputService,Stats=Stats}

    -- Executor name is diagnostic metadata only. Never abort the entire game
    -- based on a vendor label: capabilities are checked individually below.
    -- A missing hook API must disable only the dependent optional feature.
    local executorName = "unknown"
    pcall(function()
        if type(identifyexecutor) == "function" then
            executorName = tostring(identifyexecutor() or "unknown")
        end
    end)
    app.ExecutorName = executorName

    --=========================================================================
    -- Capability probe: every optional integration checks these, never guesses.
    --=========================================================================
    local Caps={
        Drawing=type(Drawing)=="table" or type(Drawing)=="userdata",
        DrawingUserdata=type(Drawing)=="userdata",
        hookfunction=type(hookfunction)=="function",
        replaceclosure=type(replaceclosure)=="function",
        hookmetamethod=type(hookmetamethod)=="function",
        getrawmetatable=type(getrawmetatable)=="function",
        newcclosure=type(newcclosure)=="function",
        checkcaller=type(checkcaller)=="function",
        getnamecallmethod=type(getnamecallmethod)=="function",
        mousemoverel=type(mousemoverel)=="function",
        mouse1press=type(mouse1press)=="function",
        mouse1release=type(mouse1release)=="function",
        VirtualUser=type(VirtualUser)=="table",
        gethui=type(gethui)=="function",
        getgenv=type(getgenv)=="function",
    }
    app.Caps=Caps
    app.HasDrawing=(Caps.Drawing or Caps.DrawingUserdata) and true or false
    app.CanCloak=Caps.hookmetamethod and Caps.checkcaller and Caps.getnamecallmethod

    --=========================================================================
    -- Guarded logging: Debug flag gates verbose output; warn is throttled so a
    -- stuck subsystem cannot flood the console.
    --=========================================================================
    app.Debug=false
    local lastWarn={}
    local function Log(fmt,...)
        if not app.Debug then return end
        local ok,msg=pcall(string.format,fmt,...)
        print("[Vortexion/AOTR/"..tostring(scene).."] "..(ok and msg or tostring(fmt)))
    end
    local function Guard(tag,fn,...)
        local ok,err=pcall(fn,...)
        if not ok then
            local now=tick()
            if now-(lastWarn[tag] or 0)>5 then
                lastWarn[tag]=now
                warn("[Vortexion/AOTR/"..tostring(tag).."] "..tostring(err))
            end
        end
        return ok,err
    end
    local function RandomName()
        local s={}
        for i=1,14 do s[i]=string.char(math.random(65,90)) end
        return table.concat(s)
    end
    local function GetGuiParent()
        if Caps.gethui then
            local ok,h=pcall(gethui)
            if ok and h then return h end
        end
        local ok,cg=pcall(function() return game:GetService("CoreGui") end)
        if ok and cg then return cg end
        -- Render callers already retry on nil; never suspend a visual tick.
        local lp=Players.LocalPlayer
        if not lp then return nil end
        local okPG,pg=pcall(function() return lp:FindFirstChild("PlayerGui") end)
        if okPG and pg then return pg end
        return nil
    end
    local function Ping()
        local ok,item=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"] end)
        if ok and item then
            local okv,v=pcall(function() return item:GetValue() end)
            if okv and type(v)=="number" and v>0 then return math.clamp(v/1000,0.02,0.4) end
        end
        return 0.08
    end
    app.Log=Log
    app.Guard=Guard
    app.RandomName=RandomName
    app.GetGuiParent=GetGuiParent
    app.Ping=Ping
    app.OnCleanup=function(fn)
        if type(fn)=="function" then return app:OnStop(fn) end
        return fn
    end
    app.Notify=app.Notify -- keep original signature (message)

    --=========================================================================
    -- Remote surface: one probe, every consumer. AOTR protocol is stable across
    -- the known scripts (GET RemoteFunction + POST RemoteEvent under
    -- ReplicatedStorage.Assets.Remotes); missing pieces degrade per feature.
    --=========================================================================
    local Remotes={ready=false,GET=nil,POST=nil}
    local function probeRemotes()
        local ok,res=pcall(function()
            local folder=ReplicatedStorage:FindFirstChild("Assets")
            folder=folder and folder:FindFirstChild("Remotes")
            if not folder then return nil end
            return folder
        end)
        if ok and res then
            Remotes.GET=res:FindFirstChild("GET")
            Remotes.POST=res:FindFirstChild("POST")
        end
        Remotes.ready=(Remotes.GET~=nil) or (Remotes.POST~=nil)
        Log("remotes GET=%s POST=%s",tostring(Remotes.GET~=nil),tostring(Remotes.POST~=nil))
        return Remotes.ready
    end
    app.Remotes=Remotes
    app.ProbeRemotes=probeRemotes

    --=========================================================================
    -- HUD reader: blade/spear counters live in deeply nested labels whose
    -- intermediate names drift between versions. Probe a candidate chain once,
    -- cache the resolved labels, re-probe on nil text.
    --=========================================================================
    local HUD={blades=nil,spears=nil,lastProbe=0}
    local function findLabel(root,path)
        local cur=root
        for _,name in ipairs(path) do
            if not cur then return nil end
            cur=cur:FindFirstChild(name,true)
        end
        if cur and cur:IsA("TextLabel") then return cur end
    end
    -- Gas sits at an exact non-recursive path (Top["7"].Gas.Percentage); a
    -- missing hop, a raised error or a non-TextLabel terminal all resolve nil.
    local function findExactLabel(root,path)
        local cur=root
        for _,name in ipairs(path) do
            if not cur then return nil end
            local ok,child=pcall(function() return cur:FindFirstChild(name) end)
            if not ok or not child then return nil end
            cur=child
        end
        if not cur then return nil end
        local okText,isText=pcall(function() return cur:IsA("TextLabel") end)
        if okText and isText then return cur end
        return nil
    end
    local function probeHUD(force)
        if not force and tick()-HUD.lastProbe<2 then return HUD end
        HUD.lastProbe=tick()
        local ok,gui=pcall(function()
            local lp=Players.LocalPlayer
            return lp and lp:FindFirstChild("PlayerGui")
        end)
        if not ok or not gui then HUD.blades=nil; HUD.spears=nil; HUD.gas=nil; return HUD end
        HUD.blades=findLabel(gui,{"Interface","HUD","Main","Top","Blades","Sets"})
        HUD.spears=findLabel(gui,{"Interface","HUD","Main","Top","Spears","Spears"})
        HUD.gas=findExactLabel(gui,{"Interface","HUD","Main","Top","7","Gas","Percentage"})
        return HUD
    end
    local function readCount(label)
        if not label or not label.Parent then return nil end
        local ok,text=pcall(function() return label.Text end)
        if not ok or not text then return nil end
        local have,max=string.match(text,"(%d+)%s*/%s*(%d+)")
        if have then return tonumber(have),tonumber(max) end
        local m=string.match(text,"(%d+)")
        if m then local n=tonumber(m); return n,n end
        return nil
    end
    -- Strict decimal percentage: "42%", "42.5%", bare 0/100 with surrounding
    -- whitespace. Rejects negatives, nan/inf, >100 and mixed text. Never
    -- reuses readCount, which would truncate a leading minus into digits.
    local function readPercent(label)
        if not label then return nil end
        local okParent,parent=pcall(function() return label.Parent end)
        if not okParent or not parent then return nil end
        local okText,text=pcall(function() return label.Text end)
        if not okText or type(text)~="string" then return nil end
        local trimmed=string.match(text,"^%s*(.-)%s*$")
        local body=string.match(trimmed,"^(.-)%s*%%$")
        if body==nil then body=trimmed end
        if not string.match(body,"^%d+$") and not string.match(body,"^%d+%.%d+$") then return nil end
        local value=tonumber(body)
        if not value or value~=value or value==math.huge or value==-math.huge then return nil end
        if value<0 or value>100 then return nil end
        return value
    end
    app.HUD=HUD
    app.ProbeHUD=probeHUD
    app.ReadCount=readCount
    app.ReadPercent=readPercent

    local function cleanup()
        if not app.active then return end
        app.active=false
        for _,con in ipairs(app.connections) do pcall(function() con:Disconnect() end) end
        for _,fn in ipairs(app.disposers) do pcall(fn) end
        if app.ui then pcall(function() app.ui:Destroy() end) end
    end
    client.VortexionAOTRCleanup=cleanup
    function app:Track(con) table.insert(self.connections,con);return con end
    function app:OnStop(fn) table.insert(self.disposers,fn);return fn end

    --=========================================================================
    -- Touch layer: mobile trigger + fly drag. Single finger held = trigger;
    -- single finger drag = horizontal fly; two fingers = vertical fly.
    --=========================================================================
    app.Touch = { Enabled = false, Held = false, RightSideOnly = true }
    do
        local UIS = app.Services and app.Services.UserInputService
        if not UIS then
            local ok, svc = pcall(function() return game:GetService("UserInputService") end)
            if ok then UIS = svc end
        end
        if UIS and UIS.TouchEnabled then
            app.Touch.Enabled = true
            local touchPoints = {}
            local touchOrder = {}
            local touchConns = {}
            local touchType = Enum and Enum.UserInputType and Enum.UserInputType.Touch
            local function isTouch(input)
                return input and (not touchType or input.UserInputType==touchType)
            end
            local function beginTouch(input, processed)
                if not app.active or processed or not isTouch(input) or touchPoints[input] then return end
                local position=input.Position
                if not position then return end
                local camera=Workspace.CurrentCamera
                local viewport=camera and camera.ViewportSize
                if app.Touch.RightSideOnly and viewport and viewport.X>0 and position.X<viewport.X*0.5 then return end
                touchPoints[input]={start=position,current=position}
                table.insert(touchOrder,input)
                app.Touch.Held=true
            end
            local function moveTouch(input)
                local point=touchPoints[input]
                if point and input.Position then point.current=input.Position end
            end
            local function endTouch(input)
                if not touchPoints[input] then return end
                touchPoints[input]=nil
                local index=table.find(touchOrder,input)
                if index then table.remove(touchOrder,index) end
                app.Touch.Held=#touchOrder>0
            end
            if UIS.InputBegan then
                table.insert(touchConns, UIS.InputBegan:Connect(beginTouch))
                table.insert(touchConns, UIS.InputChanged:Connect(moveTouch))
                table.insert(touchConns, UIS.InputEnded:Connect(endTouch))
            else
                table.insert(touchConns, UIS.TouchStarted:Connect(beginTouch))
                table.insert(touchConns, UIS.TouchMoved:Connect(moveTouch))
                table.insert(touchConns, UIS.TouchEnded:Connect(endTouch))
            end
            function app.Touch:Drag()
                local first=touchPoints[touchOrder[1]]
                local second=touchPoints[touchOrder[2]]
                if not first then return Vector2.zero,0 end
                local delta=first.current-first.start
                local vertical=0
                if second then vertical=second.current.Y-second.start.Y end
                return Vector2.new(delta.X,delta.Y),vertical
            end
            local function clearTouches()
                table.clear(touchPoints)
                table.clear(touchOrder)
                app.Touch.Held=false
            end
            if UIS.WindowFocusReleased then
                table.insert(touchConns,UIS.WindowFocusReleased:Connect(clearTouches))
            end
            app.OnCleanup(function()
                for _,cn in ipairs(touchConns) do pcall(function() cn:Disconnect() end) end
                clearTouches()
            end)
        end
    end
    function app:Alive() return self.active and client.VortexionAOTRCleanup==cleanup end
    -- Bounded visual cadence from the shared bridge (app.ui). Degrades to the
    -- caller's base interval when the bridge or method is absent, so pre-bridge
    -- cadence is preserved and the fixture path keeps its original frequency.
    function app:GetVisualInterval(base)
        base=tonumber(base) or 0.1
        -- Reject non-finite or non-positive bases: math.huge freezes visuals
        -- forever, NaN or <=0 stalls the cadence.
        if base~=base or base==math.huge or base==-math.huge or base<=0 then base=0.1 end
        local ui=self.ui
        if ui and type(ui.GetVisualInterval)=="function" then
            local ok,value=pcall(function() return ui:GetVisualInterval(base) end)
            if ok and type(value)=="number" and value==value and value~=math.huge and value~=-math.huge and value>0 then
                return math.max(base,value)
            end
        end
        return base
    end
    function app:Notify(message)
        if self.ui and self:Alive() then self.ui:Notify({Title="AOTR",Content=message,Duration=3}) end
    end
    function app:Open()
        if not self:Alive() then return end
        local ok,ui=pcall(function()
            return Bridge(WindUI,{Name="AOTR",Folder="VortexionAOTR",Section="A T T A C K  O N  T I T A N"})
        end)
        if not ok or not ui then
            local reason="AOTR Bridge: "..tostring(ui)
            client.VortexionBootError = reason
            warn("[Vortexion/AOTR] "..reason)
            cleanup()
            return
        end
        -- Bridge may yield while cleanup retires this app; reclaim the late UI.
        if not self:Alive() then pcall(function() ui:Destroy() end);return end
        self.ui=ui
        local initialized,window=pcall(function()
            ui:OnDestroy(cleanup)
            if not self:Alive() then return end
            return ui:CreateWindow({Title=scene=="lobby" and "AOTR 大厅" or "AOTR 战斗"})
        end)
        if not initialized or not window then
            if not initialized or self:Alive() then
                local reason="AOTR Window: "..tostring(window)
                client.VortexionBootError = client.VortexionBootError or reason
                warn("[Vortexion/AOTR] "..reason)
            end
            cleanup()
            return
        end
        if not self:Alive() then return end
        return window
    end
    function app:Loop(id, interval, work)
        self.flags[id]=(self.flags[id] or 0)+1
        local generation=self.flags[id]
        task.spawn(function()
            while self:Alive() and self.flags[id]==generation do
                local started=os.clock()
                local ok,err=pcall(work)
                if not ok then warn("[AOTR/"..id.."] "..tostring(err)) end
                task.wait(math.max(0.1,interval-(os.clock()-started)))
            end
        end)
    end
    function app:StopLoop(id) self.flags[id]=(self.flags[id] or 0)+1 end
    function app:Character()
        local c=self.player and self.player.Character
        local hum=c and c:FindFirstChildOfClass("Humanoid")
        local root=c and c:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health>0 then return c,hum,root end
    end
    function app:Status(tab)
        tab:AddParagraph({Title="当前场景",Content=scene=="lobby" and "大厅 / 主菜单" or "战斗任务"})
        tab:AddParagraph({Title="脚本状态",Content="独立模块已启动。禁用功能不会保留后台循环；重新执行会清理旧监听。"})
    end
    return app
end

end)()
local AOTRTitansFactory = (function()
-- Vortexion AOTR titan awareness: shared candidate pool.
--
-- One 10Hz scan resolves every titan into a cached entry (humanoid / HRP /
-- nape / type / boss flag); consumers read live fields without touching the
-- tree. Nape resolution tries several known layouts so version drift degrades
-- to a slower probe instead of a dead feature.
return function(app)
    local Workspace=app.Services.Workspace
    local Players=app.Services.Players
    local Titans={}

    local Config={
        MaxDistance=1200,
        ScanInterval=0.1,
        MaxTitans=32,
        IgnoreAfterFails=3,
        IgnoreDuration=5,
    }

    local state={
        entries={},           -- model -> entry
        lastScan=0,
        dirty=true,
        folder=nil,
        failCount={},         -- model -> fails (nape unreachable)
        ignoredUntil={},      -- model -> os.clock()
    }

    local BOSS_NAMES={
        Attack_Titan=true,Armored_Titan=true,Female_Titan=true,
        Colossal_Titan=true,Beast_Titan=true,Jaw_Titan=true,Cart_Titan=true,
    }

    --=========================================================================
    -- Path resolution: nape lives at Hitboxes.Hit.Nape in every known layout;
    -- the fallbacks cover renamed containers from older/newer builds.
    --=========================================================================
    local function resolveNape(titan)
        local hitboxes=titan:FindFirstChild("Hitboxes")
        if hitboxes then
            local hit=hitboxes:FindFirstChild("Hit")
            if hit then
                local nape=hit:FindFirstChild("Nape")
                if nape and nape:IsA("BasePart") then return nape end
                local any=hit:FindFirstChildWhichIsA("BasePart")
                if any then return any end
            end
            local direct=hitboxes:FindFirstChild("Nape")
            if direct and direct:IsA("BasePart") then return direct end
        end
        local loose=titan:FindFirstChild("Nape",true)
        if loose and loose:IsA("BasePart") then return loose end
        return nil
    end
    Titans.ResolveNape=resolveNape

    local function resolveRoot(titan)
        local root=titan:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then return root end
        root=titan:FindFirstChild("UpperTorso")
        if root and root:IsA("BasePart") then return root end
        root=titan:FindFirstChild("Torso")
        if root and root:IsA("BasePart") then return root end
        for _,child in ipairs(titan:GetChildren()) do
            if child:IsA("BasePart") then return child end
        end
        return nil
    end
    Titans.ResolveRoot=resolveRoot

    local function isIgnored(model)
        local until_=state.ignoredUntil[model]
        if not until_ then return false end
        if os.clock()>=until_ then
            state.ignoredUntil[model]=nil
            state.failCount[model]=nil
            return false
        end
        return true
    end
    Titans.IsIgnored=isIgnored

    function Titans:RegisterFail(model)
        local n=(state.failCount[model] or 0)+1
        state.failCount[model]=n
        if n>=Config.IgnoreAfterFails then
            state.ignoredUntil[model]=os.clock()+Config.IgnoreDuration
            app.Log("titan %s ignored %.0fs after %d fails",model.Name,Config.IgnoreDuration,n)
        end
    end

    function Titans:ClearFails(model)
        state.failCount[model]=nil
        state.ignoredUntil[model]=nil
    end

    --=========================================================================
    -- Scan: rebuild the entry set on a fixed cadence, refresh live fields
    -- every scan. Watches the Titans folder for spawn/despawn.
    --=========================================================================
    local stopped=false
    local addedConnection,removedConnection
    local function disconnectFolder()
        if addedConnection then addedConnection:Disconnect();addedConnection=nil end
        if removedConnection then removedConnection:Disconnect();removedConnection=nil end
    end

    local function ensureFolder()
        if stopped then return nil end
        local folder=Workspace:FindFirstChild("Titans")
        if folder~=state.folder then
            disconnectFolder()
            state.folder=folder
            state.dirty=true
            if folder then
                -- Replaceable handles belong to this module, not the app registry.
                addedConnection=folder.ChildAdded:Connect(function() state.dirty=true end)
                removedConnection=folder.ChildRemoved:Connect(function() state.dirty=true end)
            end
        end
        return folder
    end

    local function clearVisual(entry)
        entry.screenPos=nil
        entry.onScreen=false
        entry.worldDist=nil
        entry.outOfRange=false
    end

    local function retireEntry(entry)
        clearVisual(entry)
        entry.alive=false
        entry.health=nil
        entry.nape=nil
    end

    local function buildEntry(model)
        local humanoid=model:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        local root=resolveRoot(model)
        if not root then return nil end
        local entry=state.entries[model]
        if not entry then
            entry={model=model,humanoid=humanoid,root=root,nape=nil}
            state.entries[model]=entry
        else
            entry.humanoid=humanoid
            entry.root=root
        end
        if not entry.nape or not entry.nape:IsDescendantOf(model) then
            entry.nape=resolveNape(model)
        end
        entry.boss= BOSS_NAMES[model.Name] and true or false
        local ok,kind=pcall(function() return model:GetAttribute("Type") end)
        entry.type=(ok and type(kind)=="string" and kind) or (entry.boss and "Boss" or "Normal")
        return entry
    end

    local function scan(force)
        if stopped then return end
        local now=tick()
        if not force and now-state.lastScan<Config.ScanInterval then return end
        state.lastScan=now
        local folder=ensureFolder()
        if not folder then
            for _,entry in pairs(state.entries) do retireEntry(entry) end
            state.entries={}
            state.dirty=false
            return
        end
        local rootPos
        local char,_,hrp=app:Character()
        if hrp then rootPos=hrp.Position end
        local seen={}
        local n=0
        for _,model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and n<Config.MaxTitans then
                local entry=buildEntry(model)
                -- Derived fields need fresh inputs on every scan.
                if entry then clearVisual(entry) end
                if entry and entry.nape and entry.humanoid.Health>0 then
                    seen[model]=true
                    n+=1
                    if rootPos then
                        entry.worldDist=(entry.nape.Position-rootPos).Magnitude
                        if Config.MaxDistance>0 and entry.worldDist>Config.MaxDistance then
                            entry.nape=nil -- out of range: drop so consumers skip it
                            entry.outOfRange=true
                        else
                            entry.outOfRange=false
                            local cam=Workspace.CurrentCamera
                            if cam then
                                local sp,on=cam:WorldToViewportPoint(entry.nape.Position)
                                entry.screenPos=Vector2.new(sp.X,sp.Y)
                                entry.onScreen=on and sp.Z>0
                            else
                                entry.screenPos=nil
                                entry.onScreen=false
                            end
                        end
                    end
                    entry.health=entry.humanoid.Health
                    entry.alive=true
                elseif entry then
                    retireEntry(entry)
                    entry.health=entry.humanoid.Health
                    seen[model]=true
                end
            end
        end
        for model,entry in pairs(state.entries) do
            if not seen[model] then
                retireEntry(entry)
                state.entries[model]=nil
            end
        end
        state.dirty=false
    end
    Titans.Scan=scan

    -- folder lifecycle: mark dirty on spawn/despawn; scan picks it up next tick.
    -- The folder itself appears late (it parents after load), so Update retries
    -- the watch until it sticks.
    ensureFolder()

    function Titans:Update(dt)
        if stopped then return end
        ensureFolder()
        if state.dirty then
            scan(true)
        else
            scan(false)
        end
    end

    --=========================================================================
    -- Selection: nearest nape by world distance; boss priority optional.
    --=========================================================================
    function Titans:Nearest(preferBoss)
        scan(false)
        local rootPos
        local char,_,hrp=app:Character()
        if hrp then rootPos=hrp.Position end
        if not rootPos then return nil end
        local best,bestDist=nil,math.huge
        local bossBest,bossDist=nil,math.huge
        for model,entry in pairs(state.entries) do
            if entry.nape and entry.alive and not isIgnored(model) and not entry.outOfRange then
                local d=(entry.nape.Position-rootPos).Magnitude
                if entry.boss and d<bossDist then bossBest,bossDist=entry,d end
                if d<bestDist then best,bestDist=entry,d end
            end
        end
        if preferBoss and bossBest then return bossBest,bossDist end
        return best,bestDist
    end

    function Titans:All()
        local out={}
        for model,entry in pairs(state.entries) do
            if entry.nape and entry.alive and not isIgnored(model) and not entry.outOfRange then
                table.insert(out,entry)
            end
        end
        return out
    end

    function Titans:Bosses()
        local out={}
        for _,entry in ipairs(self:All()) do
            if entry.boss then table.insert(out,entry) end
        end
        return out
    end

    function Titans:Count()
        scan(false)
        local n=0
        for _,entry in pairs(state.entries) do
            if entry.alive then n+=1 end
        end
        return n
    end

    function Titans:DebugSnapshot()
        local total,withNape=0,0
        for _,entry in pairs(state.entries) do
            total+=1
            if entry.nape then withNape+=1 end
        end
        return {titans=total,nape=withNape,dirty=state.dirty}
    end

    app:OnStop(function()
        if stopped then return end
        stopped=true
        disconnectFolder()
        for _,entry in pairs(state.entries) do retireEntry(entry) end
        state.entries={}
        state.failCount={}
        state.ignoredUntil={}
        state.folder=nil
        state.dirty=false
    end)

    return Titans
end

end)()
local AOTRCombatFactory = (function()
-- Vortexion AOTR combat: nape lock, remote hit registration, spears, hitbox.
--
-- AOTR's damage surface is two remotes (validated across every known public
-- script): POST FireServer("Attacks","Slash",true) fires the swing and
-- POST FireServer("Hitboxes","Register",nape,dmg,crit,combo) registers a hit
-- on a nape instance; the server trusts the instance reference and the client
-- damage number. Thunder spears use GET InvokeServer("Spears","S_Fire",slot)
-- plus POST FireServer("Spears","S_Explode",position).
--
-- Anti-detection posture (the public scripts do none of this):
--   * attack cadence is a randomized interval, never a fixed timer
--   * damage rolls inside the game's own 625-850 band, crit inside 0.2-0.3
--   * combo index cycles 1..4 like real mastery strings
--   * HitChance gates each registration: a failed roll targets a point a few
--     studs off the nape, so the conversion rate stays human
--   * everything pauses while the Roblox window is unfocused
--   * local nape size growth uses a 20Hz lerp state machine with a restore
--     table, never a per-frame write
return function(app)
    local RunService=app.Services.RunService
    local Workspace=app.Services.Workspace
    local UserInputService=app.Services.Input
    local LocalPlayer=app.Services.Players.LocalPlayer
    local Combat={}

    local Config={
        Enabled=false,
        TargetMode="Nearest",     -- Nearest | Boss
        Mode="Camera",            -- Camera | Mouse | Both
        FOV=160,
        MaxDistance=1200,
        Smoothness=0.85,
        MaxAngle=30,
        HitChance=1,
        Prediction=0.12,
        TriggerKey="Always",      -- Always | Hold
        AttackCooldown=0.25,
        CooldownJitter=0.05,       -- +/- fraction of the cooldown
        Weapon="Auto",            -- Auto | Blades | Spears
        DamageMin=625,
        DamageMax=850,
        CritChance=0.25,
        ComboCycle=true,
        SpearBurst=30,            -- S_Explode calls per boss kill
        SpearInterval=0.03,
        HitboxEnabled=false,
        HitboxSize=1.6,
        FOVCircle=true,
    }
    Combat.Config=Config

    local state={
        locked=nil,
        lastLocked=nil,
        lastAttack=0,
        nextCooldown=Config.AttackCooldown,
        comboIndex=1,
        firing=false,
        fireAt=0,
        hitboxEntries={},
        hitboxAccum=0,
        napeVel=Vector3.zero,
        napeVelInit=false,
        aimSmooth=Vector3.zero,
        cost=0,
        attacks=0,
        attempts=0,
        failedRequests=0,
        queuedRequests=0,
        lastRequestError="none",
        errors=0,
        windowFocused=true,
    }

    local rayParams=RaycastParams.new()
    rayParams.FilterType=Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater=true

    local function wallBlocked(fromPos,toPos,char)
        local diff=toPos-fromPos
        local dist=diff.Magnitude
        if dist<0.1 then return false end
        rayParams.FilterDescendantsInstances=char and {char} or {}
        return Workspace:Raycast(fromPos,diff.Unit*(dist+2),rayParams)~=nil
    end

    --=========================================================================
    -- Weapon read: HUD counters decide Blades vs Spears when Auto.
    --=========================================================================
    local function currentWeapon()
        if Config.Weapon~="Auto" then return Config.Weapon end
        local blades=app.ReadCount(app.HUD.blades)
        if blades and blades>0 then return "Blades" end
        local spears=app.ReadCount(app.HUD.spears)
        if spears and spears>0 then return "Spears" end
        return "Blades"
    end

    local function spearSlot()
        local count=app.ReadCount(app.HUD.spears)
        return count or 1
    end

    --=========================================================================
    -- Target acquisition from the shared titan pool.
    --=========================================================================
    local function acquire()
        local Titans=app.Titans
        if not Titans then return nil end
        local entry
        if Config.TargetMode=="Boss" then
            local bosses=Titans:Bosses()
            entry=bosses[1]
        end
        if not entry then entry=Titans:Nearest(Config.TargetMode=="Boss") end
        if not entry then return nil end
        local char,_,hrp=app:Character()
        if not (entry.nape and entry.nape.Parent) then
            Titans:RegisterFail(entry.model)
            return nil
        end
        Titans:ClearFails(entry.model)
        if hrp then
            local worldDist=(entry.nape.Position-hrp.Position).Magnitude
            if worldDist>Config.MaxDistance then return nil end
        end
        return entry
    end

    --=========================================================================
    -- Prediction: nape parts bob vertically. EMA the nape velocity and lead by
    -- half a ping, scaled by the Prediction slider.
    --=========================================================================
    local function predictedPoint(entry)
        local nape=entry.nape
        local pos=nape.Position
        local vel=nape.AssemblyLinearVelocity or Vector3.zero
        if state.napeVelInit then
            state.napeVel=state.napeVel:Lerp(vel,0.15)
        else
            state.napeVel=vel
            state.napeVelInit=true
        end
        local lead=0.5*app.Ping()+0.05
        local offset=state.napeVel*(lead*(Config.Prediction/0.12))
        if (offset-state.aimSmooth).Magnitude>0.05 then
            state.aimSmooth=state.aimSmooth:Lerp(offset,0.25)
        end
        return pos+state.aimSmooth
    end

    --=========================================================================
    -- Camera aim: clamped alpha, angular speed ceiling, vertical damping,
    -- soft first frame after a target switch (same policy as SCP/BloxStrike).
    --=========================================================================
    local function cameraAim(dt,aimPos)
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local camPos=cam.CFrame.Position
        local look=aimPos-camPos
        if look.Magnitude<0.01 then return end
        local targetLook=look.Unit
        local targetCF=CFrame.lookAt(camPos,aimPos)
        local angle=math.acos(math.clamp(cam.CFrame.LookVector:Dot(targetLook),-1,1))
        local screen,on=cam:WorldToViewportPoint(aimPos)
        local viewport=cam.ViewportSize
        local center=Vector2.new(viewport.X/2,viewport.Y/2)
        local screenDist=on and (Vector2.new(screen.X,screen.Y)-center).Magnitude or math.huge
        local fovT=1-math.clamp(screenDist/math.max(Config.FOV,1),0,1)
        local alpha=math.clamp((1-Config.Smoothness)*(0.4+0.6*fovT),0.10,0.45)
        if math.abs(targetLook.Y)>0.6 then alpha=alpha*0.85 end
        if state.locked~=state.lastLocked then alpha=math.min(alpha,0.10) end
        if angle>1e-4 then alpha=math.min(alpha,(math.rad(22)*dt)/angle) end
        if alpha<=0.001 then return end
        cam.CFrame=cam.CFrame:Lerp(targetCF,alpha)
    end

    --=========================================================================
    -- Remote registration: each request can fail locally and may be rejected by
    -- the game server. Track request errors without claiming hit confirmation.
    --=========================================================================
    local function rollDamage()
        local lo=math.min(Config.DamageMin,Config.DamageMax)
        local hi=math.max(Config.DamageMin,Config.DamageMax)
        local span=hi-lo
        local center=(lo+hi)/2
        local gauss=(math.random()+math.random()+math.random())/3
        return math.floor(center+(gauss-0.5)*span)
    end

    local function rollCrit()
        return math.random()<Config.CritChance and (0.2+math.random()*0.1) or nil
    end

    local function jitteredCooldown()
        local j=1+(math.random()*2-1)*Config.CooldownJitter
        return math.max(0.05,Config.AttackCooldown*j)
    end

    local function registerBlades(entry)
        local Remotes=app.Remotes
        if not Remotes.POST then state.lastRequestError="POST missing"; return false end
        if not (entry.nape and entry.nape.Parent) then state.lastRequestError="Nape missing"; return false end
        local ok,err=pcall(function()
            Remotes.POST:FireServer("Attacks","Slash",true)
            local combo=Config.ComboCycle and state.comboIndex or nil
            Remotes.POST:FireServer("Hitboxes","Register",entry.nape,rollDamage(),rollCrit(),combo)
        end)
        if not ok then state.lastRequestError=tostring(err):sub(1,220); return false end
        state.lastRequestError="none (server not acknowledged)"
        local combo=Config.ComboCycle and state.comboIndex or nil
        if combo then
            state.comboIndex+=1
            if state.comboIndex>4 then state.comboIndex=1 end
        end
        return true
    end

    local spearBursting = false
    local function registerSpears(entry)
        local Remotes=app.Remotes
        if not (Remotes.POST and Remotes.GET) then state.lastRequestError="GET/POST missing"; return false end
        if spearBursting then return "busy" end
        spearBursting = true
        -- InvokeServer and multi-shot delays must never yield a RenderStep callback.
        -- Keep exactly one active burst, fence teardown and record actual local send.
        task.spawn(function()
            local sent=0
            local ok,err = pcall(function()
                if not app:Alive() or not Config.Enabled then return end
                local slot=spearSlot()
                Remotes.GET:InvokeServer("Spears","S_Fire",tostring(slot))
                local burst=entry.boss and Config.SpearBurst or 1
                for i=1,burst do
                    if not app:Alive() or not Config.Enabled
                        or not (entry.nape and entry.nape.Parent) then break end
                    Remotes.POST:FireServer("Spears","S_Explode",entry.nape.Position)
                    sent+=1
                    if i<burst then task.wait(Config.SpearInterval) end
                end
            end)
            if sent>0 then state.attacks+=1 end
            if not ok then state.failedRequests+=1 end
            state.lastRequestError = ok and "none (server not acknowledged)" or tostring(err):sub(1,220)
            spearBursting = false
        end)
        return "queued"
    end

    -- Human gate: with probability 1-HitChance the shot misses by a few
    -- studs, so the server-side conversion profile stays plausible.
    local function attackRoll()
        return math.random()<=Config.HitChance
    end

    local function triggerHeld()
        if Config.TriggerKey=="Always" then return true end
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            or (app.Touch.Enabled and app.Touch.Held)
    end

    --=========================================================================
    -- Hitbox: local nape size growth, 20Hz lerp + restore table.
    --=========================================================================
    local function hitboxParts(entry)
        local parts={}
        if entry.nape and entry.nape:IsA("BasePart") then table.insert(parts,entry.nape) end
        return parts
    end

    local function restoreHitEntry(key,record)
        if not record then return end
        for _,item in ipairs(record.parts) do
            local part=item.part
            if part and part.Parent then
                part.Size=item.origSize
                part.Transparency=item.origTransparency
                part.CanCollide=item.origCollide
            end
        end
        state.hitboxEntries[key]=nil
    end

    local function hitboxTick(dt)
        if not Config.HitboxEnabled then
            for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
            return
        end
        state.hitboxAccum+=dt
        if state.hitboxAccum<0.05 then return end
        state.hitboxAccum=0
        local entry=state.locked
        if not (entry and entry.nape and entry.nape.Parent) then
            for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
            return
        end
        local record=state.hitboxEntries[entry.model]
        if not record then
            local parts={}
            for _,part in ipairs(hitboxParts(entry)) do
                table.insert(parts,{part=part,origSize=part.Size,
                    origTransparency=part.Transparency,origCollide=part.CanCollide})
            end
            if #parts==0 then return end
            record={parts=parts}
            state.hitboxEntries[entry.model]=record
        end
        for _,item in ipairs(record.parts) do
            local part=item.part
            if not part or not part.Parent then
                restoreHitEntry(entry.model,record)
                break
            end
            local orig=item.origSize
            local target=Vector3.new(
                math.min(orig.X*Config.HitboxSize,orig.X+10),
                math.min(orig.Y*Config.HitboxSize,orig.Y+10),
                math.min(orig.Z*Config.HitboxSize,orig.Z+10))
            part.Size=part.Size:Lerp(target,0.35)
            part.Transparency=part.Transparency+(0.55-part.Transparency)*0.35
            part.CanCollide=false
        end
    end

    --=========================================================================
    -- FOV circle.
    --=========================================================================
    local fovGui,fovFrame
    local function fovTick()
        if Config.Enabled and Config.FOVCircle then
            if not (fovFrame and fovFrame.Parent) then
                local parent=app.GetGuiParent()
                if not parent then return end
                local sg=Instance.new("ScreenGui")
                sg.Name=app.RandomName()
                sg.ResetOnSpawn=false
                sg.IgnoreGuiInset=true
                sg.DisplayOrder=999
                sg.Parent=parent
                if app.Cloak then sg=app.Cloak.Protect(sg) end
                local frame=Instance.new("Frame")
                frame.Name=app.RandomName()
                frame.AnchorPoint=Vector2.new(0.5,0.5)
                frame.Position=UDim2.fromScale(0.5,0.5)
                frame.BackgroundTransparency=1
                local corner=Instance.new("UICorner")
                corner.CornerRadius=UDim.new(1,0)
                corner.Parent=frame
                local stroke=Instance.new("UIStroke")
                stroke.Color=Color3.fromRGB(255,90,60)
                stroke.Thickness=1.5
                stroke.Transparency=0.35
                stroke.Parent=frame
                frame.Parent=sg
                if app.Cloak then frame=app.Cloak.Protect(frame) end
                fovGui,fovFrame=sg,frame
            end
            fovFrame.Size=UDim2.fromOffset(Config.FOV*2,Config.FOV*2)
            fovFrame.Visible=true
        elseif fovFrame and fovFrame.Parent then
            fovFrame.Visible=false
        end
    end

    --=========================================================================
    -- Update.
    --=========================================================================
    function Combat:Update(dt)
        if not Config.Enabled then
            state.locked=nil
            fovTick()
            return
        end
        local t0=tick()
        state.lastLocked=state.locked

        -- Window focus gate: a focused window is the only human state.
        -- On Android the executor overlay can cause WindowFocusReleased even
        -- though the Roblox scene is still running. The focus gate is desktop-only.
        if not state.windowFocused and not UserInputService.TouchEnabled then
            state.locked=nil
            fovTick()
            return
        end

        state.locked=acquire()
        local entry=state.locked
        if entry then
            local aimPos=predictedPoint(entry)
            if aimPos then
                if Config.Mode=="Mouse" and app.Caps.mousemoverel then
                    local cam=Workspace.CurrentCamera
                    local screen,on=cam and cam:WorldToViewportPoint(aimPos)
                    if on and screen.Z>0 then
                        local viewport=cam.ViewportSize
                        local delta=Vector2.new(screen.X,screen.Y)-Vector2.new(viewport.X/2,viewport.Y/2)
                        if delta.Magnitude>2 then
                            mousemoverel(math.floor(delta.X*0.12+0.5),math.floor(delta.Y*0.12+0.5))
                        end
                    end
                else
                    cameraAim(dt,aimPos)
                end
            end

            -- Remote registration cadence.
            local now=tick()
            if triggerHeld() and now-state.lastAttack>=state.nextCooldown then
                state.lastAttack=now
                state.nextCooldown=jitteredCooldown()
                if attackRoll() then
                    state.attempts += 1
                    app.Guard("Combat.Register",function()
                        local weapon=currentWeapon()
                        local okRegister
                        if weapon=="Spears" then
                            okRegister=registerSpears(entry)
                        else
                            okRegister=registerBlades(entry)
                        end
                        if okRegister == "queued" then
                            state.queuedRequests += 1
                        elseif okRegister == "busy" then
                            -- Existing async burst owns the remote; not a failure.
                        elseif okRegister then
                            state.attacks += 1
                        else
                            state.failedRequests += 1
                        end
                    end)
                end
            end
        else
            state.napeVelInit=false
            state.comboIndex=1
        end

        hitboxTick(dt)
        fovTick()
        state.cost=tick()-t0
    end

    function Combat:GetLock()
        return state.locked
    end

    function Combat:DebugSnapshot()
        return {
            locked=state.locked and state.locked.model.Name or "-",
            dist=state.locked and math.floor(state.locked.worldDist or 0) or 0,
            attacks=state.attacks,
            attempts=state.attempts,
            queuedRequests=state.queuedRequests,
            failedRequests=state.failedRequests,
            lastRequestError=state.lastRequestError,
            windowFocused=state.windowFocused,
            lockAvailable=state.locked ~= nil,
            serverConfirmed=false, -- FireServer is one-way; no damage acknowledgement.
            weapon=currentWeapon(),
            costMs=math.floor(state.cost*100000)/100,
        }
    end

    function Combat:Stop()
        for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
        if fovGui then fovGui:Destroy();fovGui=nil;fovFrame=nil end
        Config.Enabled=false
    end

    -- Window focus watch.
    app:Track(UserInputService.WindowFocused:Connect(function() state.windowFocused=true end))
    app:Track(UserInputService.WindowFocusReleased:Connect(function() state.windowFocused=false end))

    app:OnStop(function()
        Combat:Stop()
    end)

    return Combat
end

end)()
local AOTRMovementFactory = (function()
-- Vortexion AOTR movement: hover glide, teleport follow, noclip, speed, anti-AFK.
--
-- Hover drives AssemblyLinearVelocity toward a hold point above the locked
-- titan (the same shape the game's own ODM flight uses), which replicates as
-- ordinary motion. The teleport mode exists for completeness but is the
-- noisy path; hover is the default.
return function(app)
    local RunService=app.Services.RunService
    local Workspace=app.Services.Workspace
    local UserInputService=app.Services.Input
    local LocalPlayer=app.Services.Players.LocalPlayer
    local Movement={}

    local Config={
        FollowEnabled=false,
        MoveMode="Hover",        -- Hover | Teleport
        HeightOffset=25,         -- studs above the titan HRP hold point
        BehindOffset=30,         -- studs behind the titan HRP
        GlideSpeed=120,
        FollowBossOnly=false,
        SpeedEnabled=false,
        SpeedValue=24,
        Noclip=false,
        AntiAFK=true,
        TouchAssist=false,     -- mobile touch-fly assist: strafe / forward-back / lift
        TouchFlySpeed=120,
    }
    Movement.Config=Config

    local state={
        pulse="idle",
        pulseAt=0,
        speedBackup=nil,
        speedHumanoid=nil,
        collisionBackup={},
        noclipAccum=0,
        following=false,
        lastDragX=0,
        lastDragY=0,
        lastVertical=0,
    }

    local function restoreSpeed()
        local hum=state.speedHumanoid
        if hum and hum.Parent and state.speedBackup~=nil then
            pcall(function() hum.WalkSpeed=state.speedBackup end)
        end
        state.speedHumanoid=nil
        state.speedBackup=nil
        state.pulse="idle"
    end

    local function restoreCollision()
        for part,value in pairs(state.collisionBackup) do
            if part.Parent then pcall(function() part.CanCollide=value end) end
            state.collisionBackup[part]=nil
        end
        state.noclipAccum=0
    end

    local function holdPoint(entry)
        if not entry then return nil end
        local model=entry.model
        local hrp=model:FindFirstChild("HumanoidRootPart")
        if hrp then
            return (hrp.CFrame*CFrame.new(0,Config.HeightOffset,Config.BehindOffset)).Position
        end
        if entry.nape and entry.nape.Parent then
            return entry.nape.Position+Vector3.new(0,Config.HeightOffset,0)
        end
        return nil
    end

    local function updateFollow(dt)
        local char,hum,hrp=app:Character()
        if not (char and hrp) then return end
        local entry=app.Combat and app.Combat:GetLock()
        if not entry and app.Titans then entry=app.Titans:Nearest(false) end
        if not entry then return end
        if Config.FollowBossOnly and not entry.boss then return end
        local target=holdPoint(entry)
        if not target then return end

        if Config.MoveMode=="Teleport" then
            hrp.CFrame=CFrame.new(target)
        else
            local dir=target-hrp.Position
            if dir.Magnitude>2 then
                hrp.AssemblyLinearVelocity=dir.Unit*Config.GlideSpeed
            else
                hrp.AssemblyLinearVelocity=Vector3.zero
            end
        end
    end

    local function updateSpeed()
        local char,hum,hrp=app:Character()
        if not (char and hum and hrp) then return end
        if state.speedHumanoid~=hum then
            restoreSpeed()
            state.speedHumanoid=hum
            state.speedBackup=hum.WalkSpeed
        end
        hum.WalkSpeed=Config.SpeedValue
        local dir=hum.MoveDirection
        if dir.Magnitude<=0 then return end
        local now=tick()
        if state.pulse=="idle" then state.pulse="boost";state.pulseAt=now end
        local boosting
        if state.pulse=="boost" then
            if now-state.pulseAt>=0.1 then state.pulse="coast";state.pulseAt=now;boosting=false
            else boosting=true end
        else
            if now-state.pulseAt>=0.15 then state.pulse="boost";state.pulseAt=now;boosting=true
            else boosting=false end
        end
        local target=dir.Unit*(boosting and Config.SpeedValue or Config.SpeedValue*0.16)
        hrp.AssemblyLinearVelocity=Vector3.new(target.X,hrp.AssemblyLinearVelocity.Y,target.Z)
    end

    local function updateNoclip(dt)
        state.noclipAccum=(state.noclipAccum or 0)+(dt or 0)
        if state.noclipAccum<0.05 then return end
        state.noclipAccum=0
        local char=app.Character and select(1,app:Character())
        if not char then
            local c=LocalPlayer.Character
            char=c
        end
        if not char then return end
        for _,part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if state.collisionBackup[part]==nil then state.collisionBackup[part]=part.CanCollide end
                part.CanCollide=false
            end
        end
    end

    -- Mobile touch-fly assist: right-half drag drives camera-relative motion.
    -- Single-finger X strafes, single-finger Y moves forward/back, two-finger
    -- vertical lifts. Release stops assist writes and keeps current momentum
    -- (no automatic braking). Runs on the same Heartbeat cadence as the rest
    -- of movement; never throttled by the visual interval.
    local function updateTouchFly()
        local touch=app.Touch
        if not (touch and touch.Enabled and touch.Held) then
            -- Released or disabled: only the input deltas reset. Any velocity
            -- already written stays; the assist never brakes the character.
            state.lastDragX=0
            state.lastDragY=0
            state.lastVertical=0
            return
        end
        local ok,drag,vertical=pcall(function() return touch:Drag() end)
        if not ok or not drag then
            state.lastDragX=0
            state.lastDragY=0
            state.lastVertical=0
            return
        end
        local dx=drag.X-state.lastDragX
        local dy=drag.Y-state.lastDragY
        local dv=(tonumber(vertical) or 0)-state.lastVertical
        state.lastDragX=drag.X
        state.lastDragY=drag.Y
        state.lastVertical=vertical or 0
        local _,_,hrp=app:Character()
        if not hrp then return end
        local camera=Workspace.CurrentCamera
        local cf=camera and camera.CFrame
        local vel=hrp.AssemblyLinearVelocity
        local hx,hz=vel.X,vel.Z
        if dx~=0 and cf then
            local rx,rz=cf.RightVector.X,cf.RightVector.Z
            local mag=math.sqrt(rx*rx+rz*rz)
            if mag>0.0001 then
                local scale=math.clamp(dx/8,-1,1)*Config.TouchFlySpeed
                hx,hz=(rx/mag)*scale,(rz/mag)*scale
            end
        end
        if dy~=0 and cf then
            -- Forward/back along the flattened camera LookVector. Downward
            -- drag (positive deltaY in screen space) moves backward.
            local lx,lz=cf.LookVector.X,cf.LookVector.Z
            local mag=math.sqrt(lx*lx+lz*lz)
            if mag>0.0001 then
                local scale=-math.clamp(dy/8,-1,1)*Config.TouchFlySpeed
                hx,hz=hx+(lx/mag)*scale,hz+(lz/mag)*scale
            end
        end
        local vy=vel.Y
        if dv~=0 then
            vy=math.clamp(dv/8,-1,1)*Config.TouchFlySpeed
        end
        hrp.AssemblyLinearVelocity=Vector3.new(hx,vy,hz)
    end

    local function teleportLobby()
        local Remotes=app.Remotes
        if Remotes.GET then
            local ok=pcall(function()
                Remotes.GET:InvokeServer("Functions","Teleport","Lobby")
            end)
            if ok then return true end
        end
        local TeleportService=game:GetService("TeleportService")
        pcall(function()
            TeleportService:Teleport(game.PlaceId,LocalPlayer)
        end)
        return false
    end
    Movement.TeleportLobby=teleportLobby

    if LocalPlayer.CharacterRemoving then
        app:Track(LocalPlayer.CharacterRemoving:Connect(function()
            restoreSpeed()
            restoreCollision()
        end))
    end
    if LocalPlayer.CharacterAdded then
        app:Track(LocalPlayer.CharacterAdded:Connect(function()
            restoreSpeed()
            restoreCollision()
        end))
    end

    local function antiAFK()
        local VirtualUser=game:GetService("VirtualUser")
        app:Track(LocalPlayer.Idled:Connect(function()
            if not Config.AntiAFK then return end
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0,0),Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0),Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
            end)
        end))
    end
    antiAFK()

    -- Heartbeat loop: velocity writes must land before the physics solver.
    app:Track(RunService.Heartbeat:Connect(function(dt)
        if not app:Alive() then return end
        app.Guard("Movement",function()
            if Config.FollowEnabled then updateFollow(dt) end
            if Config.SpeedEnabled then updateSpeed() else restoreSpeed() end
            if Config.Noclip then updateNoclip(dt) else restoreCollision() end
            if Config.TouchAssist then updateTouchFly() end
        end)
    end))

    app:OnStop(function()
        Config.FollowEnabled=false
        Config.SpeedEnabled=false
        Config.Noclip=false
        Config.TouchAssist=false
        state.lastDragX=0
        state.lastDragY=0
        state.lastVertical=0
        restoreSpeed()
        restoreCollision()
    end)

    return Movement
end

end)()
local AOTRESPFactory = (function()
-- Vortexion AOTR ESP: per-titan billboard tags and nape highlights.
--
-- Tags live in one cloaked ScreenGui (gethui/CoreGui) with Adornee pointing at
-- each titan nape: parenting them into the titan model would expose them to
-- workspace enumeration, and a name like "TitanESP" is a one-line scan hit.
-- Refresh runs at 10Hz with entry reuse; dead/despawned titans drop their tag.
return function(app)
    local Players=app.Services.Players
    local Workspace=app.Services.Workspace
    local LocalPlayer=Players.LocalPlayer
    local ESP={}

    local Config={
        Enabled=false,
        Tags=true,
        Health=true,
        Distance=true,
        NapeHighlight=false,
        MaxDistance=1200,
        BossColor=Color3.fromRGB(255,80,80),
        NormalColor=Color3.fromRGB(255,200,90),
    }
    ESP.Config=Config

    local state={screenGui=nil,entries={},accum=0,disposed=false}

    local function ensureGui()
        if state.screenGui and state.screenGui.Parent then return state.screenGui end
        if state.screenGui then
            pcall(function() state.screenGui:Destroy() end)
            state.screenGui=nil
        end
        local parent=app.GetGuiParent()
        if not parent then return nil end
        local raw=Instance.new("ScreenGui")
        local ok,result=pcall(function()
            raw.Name=app.RandomName()
            raw.ResetOnSpawn=false
            raw.DisplayOrder=990
            raw.Parent=parent
            return app.Cloak and app.Cloak.Protect(raw) or raw
        end)
        if not ok then
            pcall(function() raw:Destroy() end)
            error(result,0)
        end
        state.screenGui=result
        return result
    end

    local function buildEntry(entry)
        local gui=ensureGui()
        if not gui then return nil end
        local created={}
        local function allocate(class)
            local object=Instance.new(class)
            table.insert(created,object)
            return object
        end
        -- Own every allocation before setting properties; failed setup rolls back.
        local ok,result=pcall(function()
            local billboard=allocate("BillboardGui")
            billboard.Name=app.RandomName()
            billboard.Adornee=entry.nape
            billboard.Size=UDim2.fromOffset(160,44)
            billboard.StudsOffset=Vector3.new(0,4,0)
            billboard.AlwaysOnTop=true
            billboard.MaxDistance=Config.MaxDistance
            local nameLabel=allocate("TextLabel")
            nameLabel.Name="Name"
            nameLabel.BackgroundTransparency=1
            nameLabel.Size=UDim2.new(1,0,0,16)
            nameLabel.Font=Enum.Font.GothamBold
            nameLabel.TextSize=13
            nameLabel.TextStrokeTransparency=0.4
            nameLabel.Text=entry.model.Name
            nameLabel.Parent=billboard
            local sub=allocate("TextLabel")
            sub.Name="Sub"
            sub.BackgroundTransparency=1
            sub.Position=UDim2.new(0,0,0,16)
            sub.Size=UDim2.new(1,0,0,14)
            sub.Font=Enum.Font.Gotham
            sub.TextSize=12
            sub.TextStrokeTransparency=0.5
            sub.Parent=billboard
            local barBack=allocate("Frame")
            barBack.Name="BarBack"
            barBack.Position=UDim2.new(0,0,0,30)
            barBack.Size=UDim2.new(1,0,0,4)
            barBack.BackgroundColor3=Color3.fromRGB(20,20,20)
            barBack.BorderSizePixel=0
            barBack.Parent=billboard
            local barFill=allocate("Frame")
            barFill.Name="BarFill"
            barFill.Size=UDim2.fromScale(1,1)
            barFill.BackgroundColor3=Color3.fromRGB(90,220,110)
            barFill.BorderSizePixel=0
            barFill.Parent=barBack
            billboard.Parent=gui
            if app.Cloak then billboard=app.Cloak.Protect(billboard) end

            local record={billboard=billboard,nameLabel=nameLabel,subLabel=sub,barBack=barBack,barFill=barFill,highlight=nil,cache={}}
            return record
        end)
        if not ok then
            for i=#created,1,-1 do pcall(function() created[i]:Destroy() end) end
            error(result,0)
        end
        return result
    end

    local function destroyEntry(record)
        local owned={}
        for _,key in ipairs({"nameLabel","subLabel","barFill","barBack","highlight","billboard"}) do
            if record[key] then table.insert(owned,record[key]) end
            record[key]=nil
        end
        record.cache={}
        for _,object in ipairs(owned) do pcall(function() object:Destroy() end) end
    end

    local function validEntry(record)
        if not record then return false end
        local ok,valid=pcall(function()
            return record.billboard and record.billboard.Parent==state.screenGui
                and record.nameLabel and record.nameLabel.Parent==record.billboard
                and record.subLabel and record.subLabel.Parent==record.billboard
                and record.barBack and record.barBack.Parent==record.billboard
                and record.barFill and record.barFill.Parent==record.barBack
        end)
        return ok and valid==true
    end

    local function clearAll()
        for _,record in pairs(state.entries) do destroyEntry(record) end
        state.entries={}
    end

    local function syncHighlight(record,entry,color)
        if not Config.NapeHighlight then
            if record.highlight then record.highlight:Destroy();record.highlight=nil end
            return
        end
        if not record.highlight or not record.highlight.Parent then
            if record.highlight then record.highlight:Destroy();record.highlight=nil end
            local raw=Instance.new("Highlight")
            local ok,result=pcall(function()
                raw.Name=app.RandomName()
                raw.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                raw.FillTransparency=0.7
                raw.OutlineTransparency=0
                raw.Parent=state.screenGui
                return app.Cloak and app.Cloak.Protect(raw) or raw
            end)
            if not ok then
                pcall(function() raw:Destroy() end)
                error(result,0)
            end
            record.highlight=result
        end
        record.highlight.Adornee=entry.model
        record.highlight.FillColor=color
        record.highlight.OutlineColor=color
    end

    local function updateESP()
        local Titans=app.Titans
        if not Titans then clearAll();return end
        local entries=Titans:All()
        if #entries==0 then clearAll();return end
        if not ensureGui() then clearAll();return end
        local hrp
        local char,_,root=app:Character()
        if root then hrp=root end
        local seen={}
        for _,entry in ipairs(entries) do
            if entry.nape and entry.nape.Parent then
                seen[entry.model]=true
                local record=state.entries[entry.model]
                if not validEntry(record) then
                    if record then destroyEntry(record) end
                    record=buildEntry(entry)
                    state.entries[entry.model]=record
                end
                if record then
                    local cache=record.cache
                    local color=entry.boss and Config.BossColor or Config.NormalColor
                    if cache.nape~=entry.nape then
                        cache.nape=entry.nape
                        record.billboard.Adornee=entry.nape
                    end
                    if cache.maxDist~=Config.MaxDistance then
                        cache.maxDist=Config.MaxDistance
                        record.billboard.MaxDistance=Config.MaxDistance
                    end
                    if cache.nameText~=entry.model.Name then
                        cache.nameText=entry.model.Name
                        record.nameLabel.Text=entry.model.Name
                    end
                    if cache.tagsVis~=Config.Tags then
                        cache.tagsVis=Config.Tags
                        record.nameLabel.Visible=Config.Tags
                    end
                    if cache.boss~=entry.boss then
                        cache.boss=entry.boss
                        record.nameLabel.TextColor3=color
                    end
                    if Config.Distance and hrp then
                        local d=math.floor((entry.nape.Position-hrp.Position).Magnitude)
                        local text=("%d studs"):format(d)
                        if cache.distText~=text then
                            cache.distText=text
                            record.subLabel.Text=text
                        end
                        if not record.subLabel.Visible then record.subLabel.Visible=true end
                    else
                        if record.subLabel.Visible then record.subLabel.Visible=false end
                    end
                    if Config.Health and entry.humanoid then
                        local maxH=math.max(entry.humanoid.MaxHealth,1)
                        local frac=math.clamp(entry.humanoid.Health/maxH,0,1)
                        if cache.frac~=frac then
                            cache.frac=frac
                            record.barFill.Size=UDim2.fromScale(frac,1)
                            record.barFill.BackgroundColor3=Color3.fromRGB(220,60,60):Lerp(Color3.fromRGB(90,220,110),frac)
                        end
                        if not record.barFill.Parent.Visible then record.barFill.Parent.Visible=true end
                    else
                        if record.barFill.Parent.Visible then record.barFill.Parent.Visible=false end
                    end
                    local enabled=Config.Tags or record.subLabel.Visible or record.barFill.Parent.Visible
                    if cache.enabled~=enabled then
                        cache.enabled=enabled
                        record.billboard.Enabled=enabled
                    end
                    syncHighlight(record,entry,color)
                end
            end
        end
        for model,record in pairs(state.entries) do
            if not seen[model] then
                destroyEntry(record)
                state.entries[model]=nil
            end
        end
    end

    local function visualInterval(base)
        base=tonumber(base) or 0.1
        if base~=base or base==math.huge or base==-math.huge or base<=0 then base=0.1 end
        local function accept(v)
            return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge and v>0
        end
        if type(app.GetVisualInterval)=="function" then
            local ok,value=pcall(app.GetVisualInterval,app,base)
            if ok and accept(value) then return math.max(base,value) end
            return base
        end
        local ui=app.ui
        if ui and type(ui.GetVisualInterval)=="function" then
            local ok,value=pcall(function() return ui:GetVisualInterval(base) end)
            if ok and accept(value) then return math.max(base,value) end
        end
        return base
    end

    function ESP:Update(dt)
        if state.disposed then return end
        if not Config.Enabled then
            state.accum=0
            clearAll()
            return
        end
        -- Losing the local character must drop stale distance text immediately,
        -- independent of the (possibly throttled) visual cadence.
        if next(state.entries)~=nil then
            local _,_,root=app:Character()
            if not root then
                for _,record in pairs(state.entries) do
                    if record.subLabel.Visible then record.subLabel.Visible=false end
                end
            end
        end
        state.accum+=dt
        if state.accum<visualInterval(0.1) then return end
        state.accum=0
        app.Guard("ESP",updateESP)
    end

    function ESP:Stop()
        state.accum=0
        clearAll()
        if state.screenGui then
            pcall(function() state.screenGui:Destroy() end)
            state.screenGui=nil
        end
        Config.Enabled=false
    end

    app:OnStop(function()
        state.disposed=true
        ESP:Stop()
    end)

    return ESP
end

end)()
local AOTRFarmFactory = (function()
-- Vortexion AOTR farm: reload/refill automation, server-side FPS settings.
--
-- Reload triggers read the HUD blade counter; refills resolve once from
-- workspace.Unclimbable.Reloads and are re-resolved when the part leaves.
-- The FPS settings go through the game's own settings remote
-- (Functions/Settings), which is a server-side change: no local lighting or
-- render hacks that a client-side scan could notice.
return function(app)
    local Workspace=app.Services.Workspace
    local Players=app.Services.Players
    local Farm={}

    local Config={
        AutoReload=false,
        AutoRefill=false,
        CheckInterval=0.5,
        FPSSettings=false,
        Settings={
            Damage_Indicator="Off",
            Shadows="Off",
            Blur="Off",
            Player_Effects="Off",
            Effects=0,
            Music=0,
        },
    }
    Farm.Config=Config

    local state={
        refillPart=nil,
        settingsApplied=false,
        reloads=0,
        refills=0,
        refillAttempts=0,
        lastRefillStatus="idle",
        lastRefillAt=-math.huge,
        lastFuel=nil,
        lastSpears=nil,
        lastRefillDistance=nil,
        denied=0,
    }

    --=========================================================================
    -- Refill point: workspace.Unclimbable.Reloads.<something>.Refill
    --=========================================================================
    local function resolveRefill()
        -- Map-dependent refill locations found in the uploaded AOTR scripts.
        -- Select a nearby station; the old implementation always returned
        -- the first station, often on a completely different map/zone.
        local folders = {}
        local unclimbable = Workspace:FindFirstChild("Unclimbable")
        local climbable = Workspace:FindFirstChild("Climbable")
        local function path(root, ...)
            for _, key in ipairs({...}) do
                root = root and root:FindFirstChild(key)
            end
            return root
        end
        folders[#folders+1] = path(unclimbable,"Reloads")
        folders[#folders+1] = path(unclimbable,"Camps","Camp","GasTanks")
        folders[#folders+1] = path(climbable,"Walls","Gate","GasTanks")
        folders[#folders+1] = path(climbable,"_Walls","Gate","GasTanks")
        local localPlayer = Players.LocalPlayer
        local character = localPlayer and localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local best, distance = nil, math.huge
        for _, folder in pairs(folders) do
            if folder then
                local options = {folder}
                for _, child in ipairs(folder:GetDescendants()) do
                    if child:IsA("BasePart") and child.Name == "Refill" then
                        options[#options+1] = child
                    end
                end
                for _, node in ipairs(options) do
                    local candidate = node.Name == "Refill" and node:IsA("BasePart") and node or node:FindFirstChild("Refill")
                    if candidate and candidate:IsA("BasePart") then
                        local delta = (candidate.Position-root.Position).Magnitude
                        if delta < distance then best, distance = candidate, delta end
                    end
                end
            end
        end
        state.lastRefillDistance = best and distance or nil
        return best
    end
    Farm.ResolveRefill=resolveRefill

    local function doReload()
        local Remotes=app.Remotes
        if not Remotes.GET then return false end
        local have,max=app.ReadCount(app.HUD.blades)
        if not have then return false end
        if have>0 then return false end
        local ok=pcall(function()
            Remotes.GET:InvokeServer("Blades","Reload")
        end)
        if ok then state.reloads+=1 end
        return ok
    end

    local function doRefill()
        local Remotes=app.Remotes
        if not Remotes.POST then state.lastRefillStatus="POST missing"; return false end
        local now=os.clock()
        if now-state.lastRefillAt<2.5 then return false end
        app.ProbeHUD(false)
        local gas=app.ReadPercent(app.HUD.gas)
        local spears=app.ReadCount(app.HUD.spears)
        local blades=app.ReadCount(app.HUD.blades)
        -- Do not spam refill every 0.5s when already full.
        local needsGas=type(gas)=="number" and gas<85
        local needsSpears=type(spears)=="number" and spears<=0
        local needsBlades=type(blades)=="number" and blades<=0
        if type(gas)=="number" or type(spears)=="number" or type(blades)=="number" then
            if not needsGas and not needsSpears and not needsBlades then
                state.lastRefillStatus="supply healthy"
                return false
            end
        end
        local refill=state.refillPart
        if not refill or not refill.Parent then refill=resolveRefill() end
        if not refill then state.lastRefillStatus="station not found"; return false end
        state.refillPart=refill
        local char=Players.LocalPlayer and Players.LocalPlayer.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then state.lastRefillStatus="character not ready"; return false end
        local dist=(refill.Position-root.Position).Magnitude
        state.lastRefillDistance=dist
        if dist>18 then
            state.lastRefillStatus=("station too far (%.0f studs)"):format(dist)
            return false
        end
        state.lastRefillAt=now
        state.refillAttempts+=1
        state.lastFuel,state.lastSpears=gas,spears
        local ok,err=pcall(function()
            Remotes.POST:FireServer("Attacks","Reload",refill)
        end)
        if ok then
            state.refills+=1 -- request counter, NOT proof of success
            state.lastRefillStatus="request sent, awaiting resource change"
        else
            state.denied+=1
            state.lastRefillStatus=tostring(err):sub(1,150)
        end
        return ok
    end
    local function observeRefill()
        if state.lastRefillStatus~="request sent, awaiting resource change" then return end
        app.ProbeHUD(false)
        local gas=app.ReadPercent(app.HUD.gas)
        local spears=app.ReadCount(app.HUD.spears)
        if (type(gas)=="number" and type(state.lastFuel)=="number" and gas>state.lastFuel)
            or (type(spears)=="number" and type(state.lastSpears)=="number" and spears>state.lastSpears) then
            state.lastRefillStatus="confirmed by HUD"
        elseif os.clock()-state.lastRefillAt>3 then
            state.denied+=1
            state.lastRefillStatus="server unconfirmed (HUD unchanged)"
        end
    end

    --=========================================================================
    -- Server-side settings: one-shot per session, idempotent.
    --=========================================================================
    local function applySettings()
        if state.settingsApplied then return end
        local Remotes=app.Remotes
        if not Remotes.GET then return end
        local ok=pcall(function()
            for key,value in pairs(Config.Settings) do
                Remotes.GET:InvokeServer("Functions","Settings",key,value)
                task.wait(0.05)
            end
        end)
        state.settingsApplied=ok
        app.Log("farm settings applied=%s",tostring(ok))
    end

    local accum=0
    local function tickFarm(dt)
        if Config.AutoRefill then app.Guard("Farm.RefillObserve",observeRefill) end
        if Config.AutoReload then app.Guard("Farm.Reload",doReload) end
        if Config.AutoRefill then app.Guard("Farm.Refill",doRefill) end
    end

    function Farm:Update(dt)
        if Config.FPSSettings and not state.settingsApplied then
            app.Guard("Farm.Settings",applySettings)
        end
        accum+=dt
        if accum<Config.CheckInterval then return end
        accum=0
        app.Guard("Farm",tickFarm,dt)
    end

    function Farm:DebugSnapshot()
        return {reloads=state.reloads,refills=state.refills,
            refill=state.refillPart and state.refillPart.Parent and true or false,
            attempts=state.refillAttempts, status=state.lastRefillStatus,
            distance=state.lastRefillDistance, unconfirmed=state.denied}
    end

    app:OnStop(function()
        Config.AutoReload=false
        Config.AutoRefill=false
    end)

    return Farm
end

end)()
-- AOTR battle: full combat suite (nape lock, remote registration, spears,
-- hitbox, follow, ESP, farm) wired through one budgeted render loop.
local app=AOTRCommon("battle",WindUI,WindBridgeFactory)
if not app then return end
local window=app:Open()
if not window then return end

--=========================================================================
-- Environment probe before features: remotes, HUD labels, executor caps.
--=========================================================================
-- Remote probe is nonessential for initial window creation.
task.defer(function() if app:Alive() then app:ProbeRemotes() end end)
-- HUD discovery is deferred until the user requests readouts or farm needs it.
local bootFailures = {}
local function reportBootFailure(name, message)
    local detail = tostring(name) .. ": " .. tostring(message):sub(1, 160)
    table.insert(bootFailures, detail)
    if app.ui then
        app.ui.BootStatus = "partial"
        app.ui.BootError = table.concat(bootFailures, "; ")
    end
    warn("[Vortexion/AOTR] " .. detail)
end
-- R2.5: Do not install a global __namecall hook during battle startup.
-- Such hooks cannot be safely uninstalled on every Android executor and can
-- disrupt the game's own method dispatch. ESP degrades to ordinary instances.
app.Cloak = { Protect = function(instance) return instance end }

local tabs={
    combat=window:AddTab({Title="战斗",Icon="lucide-swords"}),
    visual=window:AddTab({Title="感知",Icon="lucide-eye"}),
    movement=window:AddTab({Title="移动",Icon="lucide-activity"}),
    farm=window:AddTab({Title="农场",Icon="lucide-package"}),
    settings=window:AddTab({Title="设置",Icon="lucide-settings"}),
}
window:InstallSettings(tabs.settings)

local function setup(name,factory,key)
    if type(factory)~="function" then
        reportBootFailure(name, "factory missing")
        return nil
    end
    local ok,result=pcall(factory,app)
    if not ok then
        reportBootFailure(name, result)
        app:Notify(name.." 模块失败: "..tostring(result))
        return nil
    end
    if key then app[key]=result end
    return result
end

setup("titans",AOTRTitansFactory,"Titans")
setup("combat",AOTRCombatFactory,"Combat")
setup("movement",AOTRMovementFactory,"Movement")
setup("esp",AOTRESPFactory,"ESP")
setup("farm",AOTRFarmFactory,"Farm")

local Titans,Combat,Movement,ESP,Farm=app.Titans,app.Combat,app.Movement,app.ESP,app.Farm
if app.ui and type(app.ui.RegisterFeatureHealth) == "function" then
    app.ui:RegisterFeatureHealth("AOTR 战斗", function()
        return ("存活=%s 巨人池=%s 战斗=%s 移动=%s 感知=%s 农场=%s 子模块错误=%d")
            :format(tostring(app:Alive()), tostring(Titans ~= nil), tostring(Combat ~= nil),
                tostring(Movement ~= nil), tostring(ESP ~= nil), tostring(Farm ~= nil), #bootFailures)
    end)
end


--=========================================================================
-- Shared render loop: one BindToRenderStep(Last), dt gate, per-subsystem
-- budget, 2s debug snapshot. Movement runs on Heartbeat inside its module.
--=========================================================================
local budgets={Titans=0.4,Combat=1.5,ESP=1.0,Farm=0.2}
local costs={Titans=0,Combat=0,ESP=0,Farm=0}
local slowLoops=0
local throttled = {Titans=0, ESP=0, Farm=0}
local farmBusy = false
app:OnStop(function()
    app.Services.RunService:UnbindFromRenderStep("VortexionAOTRFrame")
end)
app.Services.RunService:BindToRenderStep("VortexionAOTRFrame",Enum.RenderPriority.Last.Value,function(dt)
    if not app:Alive() then return end
    app.Guard("Frame",function()
        if dt<0.004 then return end
        local combatOn = Combat and (Combat.Config.Enabled or Combat.Config.HitboxEnabled)
        local espOn = ESP and ESP.Config.Enabled
        local movementOn = Movement and Movement.Config.FollowEnabled
        if not (combatOn or espOn or movementOn or (Farm and (Farm.Config.AutoReload or Farm.Config.AutoRefill))) then return end
        throttled.Titans = throttled.Titans + math.min(dt, 0.2)
        throttled.ESP = throttled.ESP + math.min(dt, 0.2)
        throttled.Farm = throttled.Farm + math.min(dt, 0.2)
        if Titans and throttled.Titans >= 0.10 then
            throttled.Titans = 0
            local t0=tick()
            app.Guard("Titans",function() Titans:Update(dt) end)
            costs.Titans=tick()-t0
        end
        if Combat then
            local t0=tick()
            app.Guard("Combat",function() Combat:Update(dt) end)
            costs.Combat=tick()-t0
        end
        if ESP and throttled.ESP >= 0.05 then
            throttled.ESP = 0
            local t0=tick()
            app.Guard("ESP",function() ESP:Update(dt) end)
            costs.ESP=tick()-t0
        end
        if Farm and throttled.Farm >= 0.25 then
            throttled.Farm = 0
            if not farmBusy then
                farmBusy = true
                task.spawn(function()
                    local t0=tick()
                    if app:Alive() then
                        app.Guard("Farm",function() Farm:Update(0.25) end)
                    end
                    costs.Farm=tick()-t0
                    farmBusy = false
                end)
            end
        end
        for name,cost in pairs(costs) do
            if cost*1000>budgets[name] then slowLoops+=1 end
        end
    end)
end)

task.spawn(function()
    while app:Alive() do
        task.wait(2)
        if not app:Alive() then break end
        if app.Debug then
            local combat=Combat and Combat:DebugSnapshot() or {}
            local titans=Titans and Titans:DebugSnapshot() or {}
            local farm=Farm and Farm:DebugSnapshot() or {}
            local remotes=app.Remotes
            print(("[Vortexion/AOTR] titans=%d nape=%d lock=%s dist=%s atk=%d wpn=%s reload=%d refill=%d | %.2f/%.2f/%.2f/%.2fms slow=%d GET=%s POST=%s"):format(
                titans.titans or 0,titans.nape or 0,
                tostring(combat.locked or "-"),tostring(combat.dist or 0),
                tonumber(combat.attacks) or 0,tostring(combat.weapon or "-"),
                tonumber(farm.reloads) or 0,tonumber(farm.refills) or 0,
                costs.Titans*1000,costs.Combat*1000,costs.ESP*1000,costs.Farm*1000,
                slowLoops,
                tostring(remotes.GET~=nil),tostring(remotes.POST~=nil)))
        end
    end
end)

--=========================================================================
-- UI: combat.
--=========================================================================
if Combat then
    local c=Combat.Config
    local tab=tabs.combat
    tab:AddToggle("AOTRAimEnabled",{Title="斩击锁定（自动注册命中）",Default=false,Callback=function(v)
        c.Enabled=v
        app.Log("combat enabled=%s",tostring(v))
    end})
    tab:AddDropdown("AOTRTargetMode",{Title="目标选择",Values={"Nearest","Boss"},Default="Nearest",
        Callback=function(v) c.TargetMode=v end})
    tab:AddDropdown("AOTRAimMode",{Title="瞄准模式",Values={"Camera","Mouse","Both"},Default="Camera",
        Callback=function(v) c.Mode=v end})
    tab:AddSlider("AOTRAimFov",{Title="锁定 FOV",Min=40,Max=600,Default=160,Rounding=0,
        Callback=function(v) c.FOV=v end})
    tab:AddSlider("AOTRAimDist",{Title="锁定距离",Min=100,Max=3000,Default=1200,Rounding=0,
        Callback=function(v) c.MaxDistance=v end})
    tab:AddSlider("AOTRAimSmooth",{Title="平滑（越小越快）",Min=0.05,Max=0.95,Default=0.85,Rounding=2,
        Callback=function(v) c.Smoothness=v end})
    tab:AddSlider("AOTRAimPrediction",{Title="预瞄（浮动补偿）",Min=0,Max=0.5,Default=0.12,Rounding=2,
        Callback=function(v) c.Prediction=v end})
    tab:AddSlider("AOTRAimHitChance",{Title="注册命中率（%）",Min=10,Max=100,Default=100,Rounding=0,
        Callback=function(v) c.HitChance=v/100 end})
    tab:AddDropdown("AOTRAimKey",{Title="触发键",Values={"Always","Hold"},Default="Always",
        Callback=function(v) c.TriggerKey=v end})
    tab:AddSlider("AOTRAttackCd",{Title="攻击间隔（秒）",Min=0.08,Max=1.5,Default=0.25,Rounding=2,
        Callback=function(v) c.AttackCooldown=v end})
    tab:AddSlider("AOTRAttackJitter",{Title="节奏抖动（±）",Min=0,Max=0.8,Default=0.05,Rounding=2,
        Callback=function(v) c.CooldownJitter=v end})
    tab:AddDropdown("AOTRWeapon",{Title="武器",Values={"Auto","Blades","Spears"},Default="Auto",
        Callback=function(v) c.Weapon=v end})
    tab:AddSlider("AOTRDmgMin",{Title="伤害下限",Min=100,Max=2000,Default=625,Rounding=0,
        Callback=function(v) c.DamageMin=v end})
    tab:AddSlider("AOTRDmgMax",{Title="伤害上限",Min=100,Max=2000,Default=850,Rounding=0,
        Callback=function(v) c.DamageMax=v end})
    tab:AddSlider("AOTRCritChance",{Title="暴击概率（%）",Min=0,Max=100,Default=25,Rounding=0,
        Callback=function(v) c.CritChance=v/100 end})
    tab:AddToggle("AOTRComboCycle",{Title="连击序号循环",Default=true,
        Callback=function(v) c.ComboCycle=v end})
    tab:AddSlider("AOTRSpearBurst",{Title="雷枪连发（Boss）",Min=1,Max=60,Default=30,Rounding=0,
        Callback=function(v) c.SpearBurst=v end})
    tab:AddToggle("AOTRHitboxEnabled",{Title="后颈碰撞箱放大",Default=false,
        Callback=function(v) c.HitboxEnabled=v end})
    tab:AddSlider("AOTRHitboxSize",{Title="碰撞箱倍率",Min=1.1,Max=4,Default=1.6,Rounding=1,
        Callback=function(v) c.HitboxSize=v end})
    tab:AddToggle("AOTRFovCircle",{Title="FOV 圆圈",Default=true,
        Callback=function(v) c.FOVCircle=v end})
end

--=========================================================================
-- UI: visual (ESP) + preserved awareness readouts.
--=========================================================================
if ESP then
    local c=ESP.Config
    local tab=tabs.visual
    tab:AddToggle("AOTRESPEnabled",{Title="巨人 ESP",Default=false,Callback=function(v) c.Enabled=v end})
    tab:AddToggle("AOTRESPTags",{Title="名称标签",Default=true,Callback=function(v) c.Tags=v end})
    tab:AddToggle("AOTRESPHealth",{Title="血量条",Default=true,Callback=function(v) c.Health=v end})
    tab:AddToggle("AOTRESPDistance",{Title="距离",Default=true,Callback=function(v) c.Distance=v end})
    tab:AddToggle("AOTRNapeHighlight",{Title="后颈高亮",Default=false,
        Callback=function(v) c.NapeHighlight=v end})
    tab:AddSlider("AOTRESPDist",{Title="ESP 距离",Min=200,Max=3000,Default=1200,Rounding=0,
        Callback=function(v) c.MaxDistance=v end})
end

tabs.visual:AddButton({Title="刷新巨人数量",Callback=function()
    if Titans then app:Notify("当前发现巨人 "..tostring(Titans:Count()).." 个") end
end})
tabs.visual:AddButton({Title="当前 ESP 刷新间隔",Callback=function()
    local interval=app:GetVisualInterval(0.1)
    app:Notify(("ESP 刷新间隔 %.3f 秒（约 %d Hz，随共享桥接档位变化）"):format(interval,math.max(1,math.floor(1/interval+0.5))))
end})
tabs.visual:AddButton({Title="查看刀片/雷枪余量",Callback=function()
    if not app:Alive() then return end
    app.ProbeHUD(false)
    local bh,bm=app.ReadCount(app.HUD.blades)
    local sh,sm=app.ReadCount(app.HUD.spears)
    app:Notify(("刀片 %s · 雷枪 %s"):format(
        bh and ("%d/%d"):format(bh,bm) or "未读取",
        sh and ("%d/%d"):format(sh,sm) or "未读取"))
end})
tabs.visual:AddButton({Title="查看燃气余量",Callback=function()
    if not app:Alive() then return end
    local ok,percent=pcall(function()
        app.ProbeHUD(false)
        return app.ReadPercent(app.HUD.gas)
    end)
    local valid=ok and type(percent)=="number" and percent==percent and percent>=0 and percent<=100
    local text=valid and ("%.1f%%"):format(percent) or "未读取"
    if app:Alive() then app:Notify("燃气: "..text) end
end})
tabs.visual:AddParagraph({Title="感知策略",
    Content="巨人池 10Hz 扫描一次，后颈解析带多路径回退；解锁目标自动忽略 5 秒，避免卡死重试。"})

--=========================================================================
-- UI: movement.
--=========================================================================
if Movement then
    local c=Movement.Config
    local tab=tabs.movement
    tab:AddToggle("AOTRFollow",{Title="自动跟随锁定目标",Default=false,
        Callback=function(v) c.FollowEnabled=v end})
    tab:AddDropdown("AOTRMoveMode",{Title="移动方式",Values={"Hover","Teleport"},Default="Hover",
        Callback=function(v) c.MoveMode=v end})
    tab:AddSlider("AOTRHeightOffset",{Title="跟随高度",Min=5,Max=80,Default=25,Rounding=0,
        Callback=function(v) c.HeightOffset=v end})
    tab:AddSlider("AOTRBehindOffset",{Title="身后距离",Min=0,Max=80,Default=30,Rounding=0,
        Callback=function(v) c.BehindOffset=v end})
    tab:AddSlider("AOTRGlideSpeed",{Title="滑行速度",Min=30,Max=400,Default=120,Rounding=0,
        Callback=function(v) c.GlideSpeed=v end})
    tab:AddToggle("AOTRFollowBoss",{Title="仅跟随 Boss",Default=false,
        Callback=function(v) c.FollowBossOnly=v end})
    tab:AddToggle("AOTRSpeedEnabled",{Title="自定义移动速度",Default=false,
        Callback=function(v) c.SpeedEnabled=v end})
    tab:AddSlider("AOTRSpeedValue",{Title="速度值",Min=16,Max=80,Default=24,Rounding=0,
        Callback=function(v) c.SpeedValue=v end})
    tab:AddToggle("AOTRNoclip",{Title="穿墙",Default=false,Callback=function(v) c.Noclip=v end})
    tab:AddToggle("AOTRTouchAssist",{Title="触摸飞行辅助（右半屏拖动）",Default=false,Callback=function(v) c.TouchAssist=v end})
    tab:AddSlider("AOTRTouchFlySpeed",{Title="触摸飞行速度",Min=30,Max=400,Default=120,Rounding=0,
        Callback=function(v) c.TouchFlySpeed=v end})
    tab:AddParagraph({Title="触屏飞行操作",
        Content="右半屏单指左右=侧移，单指上下=前后，双指上下=升降，均按相机朝向映射。松手或关闭仅停止写入并保留当前动量，不自动制动。"})
    tab:AddToggle("AOTRAntiAFK",{Title="反挂机",Default=true,Callback=function(v) c.AntiAFK=v end})
    tab:AddButton({Title="远程传送回大厅",Callback=function()
        if Movement.TeleportLobby then Movement.TeleportLobby() end
    end})
end

--=========================================================================
-- UI: farm.
--=========================================================================
if Farm then
    local c=Farm.Config
    local tab=tabs.farm
    tab:AddToggle("AOTRAutoReload",{Title="自动换刃（刀片耗尽）",Default=false,
        Callback=function(v) c.AutoReload=v end})
    tab:AddToggle("AOTRAutoRefill",{Title="自动补给（气罐/弹药）",Default=false,
        Callback=function(v) c.AutoRefill=v end})
    tab:AddButton({Title="查看自动补给状态",Callback=function()
        local r=Farm:DebugSnapshot()
        local info=("请求 %d / 未确认 %d / 距离 %s / 状态 %s")
            :format(r.attempts or 0,r.unconfirmed or 0,
                r.distance and ("%.0f"):format(r.distance) or "-",r.status or "unknown")
        print("[Vortexion/AOTR/Refill] " .. info)
        app:Notify(info)
    end})
    tab:AddToggle("AOTRFPSSettings",{Title="服务端画质设置（关特效）",Default=true,
        Callback=function(v)
            c.FPSSettings=v
        end})
    tab:AddParagraph({Title="农场说明",
        Content="换刃/补给读取 HUD 计数后调用游戏远程；画质设置走服务端 Settings 远程，不留本地渲染改动。"})
end

--=========================================================================
-- UI: settings (camera + debug + status + unload), preserving the original
-- local FOV control and scene awareness.
--=========================================================================
local AOTRWorkspace=app.Services.Workspace or workspace
local cameraDefaults={}
local camera=AOTRWorkspace and AOTRWorkspace.CurrentCamera
local defaultFov=camera and camera.FieldOfView or 70
local fovOn=false
local fovValue=math.clamp(math.floor(defaultFov),60,110)
local function restoreCameraFov()
    for cam,original in pairs(cameraDefaults) do
        pcall(function() cam.FieldOfView=original end)
    end
    table.clear(cameraDefaults)
end
local function applyCameraFov(cam)
    if not cam or not fovOn or not app:Alive() then return end
    if cameraDefaults[cam]==nil then cameraDefaults[cam]=cam.FieldOfView or 70 end
    if fovOn then cam.FieldOfView=fovValue end
end
tabs.settings:AddToggle("AOTRCameraFovOn",{Title="启用视场角修改",Default=false,Callback=function(v)
    if not app:Alive() then return end
    fovOn=v
    local cam=AOTRWorkspace and AOTRWorkspace.CurrentCamera
    if v then applyCameraFov(cam)
    else
        restoreCameraFov()
    end
end})
tabs.settings:AddSlider("AOTRCameraFov",{Title="本地视场角",Min=60,Max=110,Default=math.clamp(math.floor(defaultFov),60,110),Rounding=0,
    Callback=function(v)
        if not app:Alive() then return end
        fovValue=v
        if fovOn then applyCameraFov(AOTRWorkspace and AOTRWorkspace.CurrentCamera) end
    end})
if AOTRWorkspace and AOTRWorkspace.GetPropertyChangedSignal then
    app:Track(AOTRWorkspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if not app:Alive() then return end
        restoreCameraFov()
        applyCameraFov(AOTRWorkspace.CurrentCamera)
    end))
end
app:OnStop(function()
    fovOn=false
    restoreCameraFov()
end)
tabs.settings:AddToggle("AOTRDebug",{Title="调试日志",Default=false,Callback=function(v)
    app.Debug=v
end})
tabs.settings:AddParagraph({Title="场景识别",
    Content="仅在已核实的任务 PlaceId 中启动；未识别地图不会误加载战斗脚本。"})
tabs.settings:AddButton({Title="子模块初始化诊断",Callback=function()
    app:Notify(#bootFailures > 0 and table.concat(bootFailures, " / ") or "已调用全部子模块工厂；玩法有效性仍需实机测试")
end})
local combatStatusParagraph=tabs.settings:AddParagraph({Title="战斗运行状态",Content="点击运行状态查看请求计数；发送不代表服务器命中"})
tabs.settings:AddButton({Title="运行状态",Callback=function()
    local Titans,Combat,Farm=app.Titans,app.Combat,app.Farm
    local remotes=app.Remotes
    local titanInfo=Titans and ("巨人 "..tostring(Titans:Count())) or "巨人池未加载"
    local snapshot=Combat and Combat:DebugSnapshot() or {}
    local text=("GET=%s POST=%s / %s / 锁定=%s\n尝试=%s 发送=%s 排队=%s 本地失败=%s\n原因=%s\n服务器命中尚未确认")
        :format(tostring(remotes.GET~=nil),tostring(remotes.POST~=nil),titanInfo,
            tostring(snapshot.locked or "-"), tostring(snapshot.attempts or 0),
            tostring(snapshot.attacks or 0),tostring(snapshot.queuedRequests or 0),
            tostring(snapshot.failedRequests or 0),tostring(snapshot.lastRequestError or "unknown"))
    if combatStatusParagraph and type(combatStatusParagraph.SetDesc)=="function" then
        combatStatusParagraph:SetDesc(text)
    else
        print("[Vortexion/AOTR] "..text)
    end
end})
tabs.settings:AddButton({Title="卸载全部 AOTR 功能",Callback=function()
    local client=(getgenv and getgenv()) or _G
    if type(client.VortexionAOTRCleanup)=="function" then
        pcall(client.VortexionAOTRCleanup)
    end
    pcall(function() app.ui:Destroy() end)
end})

app:Status(tabs.settings)
window:SelectTab(1)
app:Notify("战斗模块已加载：进入任务后启用对应功能")

end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "AOTR_Battle")
