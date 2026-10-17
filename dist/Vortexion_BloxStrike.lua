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
local BloxCommonFactory = (function()
-- Vortexion BloxStrike common runtime: capability probe, debug channel, guards.
-- Every BloxStrike module receives this singleton through ctx.c and never
-- touches globals. Degrades per-feature instead of hard-failing.
return function(c)
    local common = c or {}
    common.Version = "3.0.0"
    common.Name = "BloxStrike"

    --=========================================================================
    -- Executor capability probe. Bullet tracking paths and the cloak select
    -- themselves from these flags at runtime.
    --=========================================================================
    local Caps = {}
    local function detect(name, test)
        local ok, result = pcall(test)
        Caps[name] = ok and result and true or false
    end

    detect("Drawing", function() return type(Drawing) == "table" and type(Drawing.new) == "function" end)
    detect("DrawingUserdata", function() return type(Drawing) == "userdata" end)
    detect("hookfunction", function() return type(hookfunction) == "function" end)
    detect("replaceclosure", function() return type(replaceclosure) == "function" end)
    detect("hookmetamethod", function() return type(hookmetamethod) == "function" end)
    detect("getrawmetatable", function() return type(getrawmetatable) == "function" end)
    detect("newcclosure", function() return type(newcclosure) == "function" end)
    detect("checkcaller", function() return type(checkcaller) == "function" end)
    detect("getnamecallmethod", function() return type(getnamecallmethod) == "function" end)
    detect("mousemoverel", function() return type(mousemoverel) == "function" end)
    detect("mouse1click", function() return type(mouse1click) == "function" end)
    detect("mouse1press", function() return type(mouse1press) == "function" end)
    detect("mouse1release", function() return type(mouse1release) == "function" end)
    detect("gethui", function() return type(gethui) == "function" end)
    detect("getgenv", function() return type(getgenv) == "function" end)
    detect("setclipboard", function() return type(setclipboard) == "function" end)
    common.Caps = Caps
    common.HasDrawing = (Caps.Drawing or Caps.DrawingUserdata) and true or false
    -- Cloak gate: the enumeration filter needs the metatable hook plus the
    -- caller discriminator; RandomName-only mode stays available otherwise.
    common.CanCloak = (Caps.hookmetamethod and Caps.checkcaller and Caps.getnamecallmethod) and true or false

    --=========================================================================
    -- Debug channel: gated by the Settings/Debug toggle.
    --=========================================================================
    common.Debug = false
    function common.Log(module, ...)
        if not common.Debug then return end
        print(("[Vortexion/Blox/%s]"):format(module), ...)
    end

    --=========================================================================
    -- Guarded execution with 5s warn throttle: one broken subsystem must never
    -- spam the console or stall the shared render loop.
    --=========================================================================
    local lastWarn = {}
    function common.Guard(module, fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then
            local now = tick()
            if not lastWarn[module] or now - lastWarn[module] > 5 then
                lastWarn[module] = now
                warn(("[Vortexion/Blox/%s] %s"):format(module, tostring(err)))
            end
        end
        return ok
    end

    --=========================================================================
    -- RandomName: 14 random letters. Blocks name-signature scans of anything
    -- this script parents into Workspace/PlayerGui (ESP highlights, skins).
    --=========================================================================
    local NAME_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    function common.RandomName(len)
        len = len or 14
        local out = table.create(len)
        for i = 1, len do
            local ci = math.random(1, #NAME_CHARS)
            out[i] = NAME_CHARS:sub(ci, ci)
        end
        return table.concat(out)
    end

    --=========================================================================
    -- getGuiParent: gethui (hidden) first, then CoreGui, then PlayerGui.
    --=========================================================================
    local function writableGuiParent(parent)
        if not parent then return false end
        local probe = Instance.new("Folder")
        local ok = pcall(function() probe.Parent = parent end)
        probe:Destroy()
        return ok
    end
    function common.GetGuiParent()
        if Caps.gethui then
            local ok, hui = pcall(gethui)
            if ok and writableGuiParent(hui) then return hui end
        end
        local coreGui = game:FindService("CoreGui")
        if writableGuiParent(coreGui) then return coreGui end
        return game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    end

    --=========================================================================
    -- Cleanup registry: Core:Stop() runs every disposer so a reload never
    -- leaks connections, restored sizes or patched closures.
    --=========================================================================
    common.Disposers = {}
    function common.OnCleanup(fn)
        table.insert(common.Disposers, fn)
    end

    --=========================================================================
    -- Shared bridge pacing: ctx.UI may expose GetVisualInterval(baseSeconds)
    -- so non-critical visual work (ESP refresh) follows the bridge's bounded
    -- VisualHz. A missing method, an error or a bad return keeps the original
    -- cadence, which is what every offline fixture and older bridge does.
    --=========================================================================
    local FALLBACK_INTERVAL = 0.05
    local function finitePositive(value)
        return type(value) == "number" and value == value and value > 0 and value < math.huge
    end
    function common.VisualInterval(base)
        if not finitePositive(base) then return FALLBACK_INTERVAL end
        local ui = common.UI
        if type(ui) == "table" and type(ui.GetVisualInterval) == "function" then
            local ok, value = pcall(ui.GetVisualInterval, ui, base)
            -- Only ever slow the cadence down: a bridge that answers faster
            -- than base, or with a non-finite value, is ignored.
            if ok and finitePositive(value) and value > base then
                return value
            end
        end
        return base
    end

    --=========================================================================
    -- Touch layer: mobile trigger + fly drag. Single finger held = trigger;
    -- single finger drag = horizontal fly; two fingers = vertical fly.
    --=========================================================================
    common.Touch = { Enabled = false, Held = false, Region = "Right" }
    do
        local UIS = common.Services and common.Services.UserInputService
        if not UIS then
            local ok, svc = pcall(function() return game:GetService("UserInputService") end)
            if ok then UIS = svc end
        end
        if UIS and UIS.TouchEnabled then
            common.Touch.Enabled = true
            local touchPoints = {}
            local touchConns = {}
            local sequence = 0
            table.insert(touchConns, UIS.TouchStarted:Connect(function(input, processed)
                if processed then return end
                local camera = workspace.CurrentCamera
                if common.Touch.Region == "Right" and camera and input.Position.X < camera.ViewportSize.X / 2 then return end
                sequence += 1
                touchPoints[input] = { origin = input.Position, pos = input.Position, order = sequence }
                common.Touch.Held = true
            end))
            table.insert(touchConns, UIS.TouchMoved:Connect(function(input)
                if touchPoints[input] then touchPoints[input].pos = input.Position end
            end))
            table.insert(touchConns, UIS.TouchEnded:Connect(function(input)
                touchPoints[input] = nil
                common.Touch.Held = next(touchPoints) ~= nil
            end))
            if UIS.WindowFocusReleased then
                table.insert(touchConns, UIS.WindowFocusReleased:Connect(function()
                    touchPoints = {}
                    common.Touch.Held = false
                end))
            end
            function common.Touch:Drag()
                local first, second
                for _, point in pairs(touchPoints) do
                    if not first or point.order < first.order then
                        second, first = first, point
                    elseif not second or point.order < second.order then
                        second = point
                    end
                end
                if not first then return Vector2.zero, 0 end
                local d = first.pos - first.origin
                local vertical = second and (second.pos.Y - second.origin.Y) or 0
                return Vector2.new(d.X, d.Y), vertical
            end
            common.OnCleanup(function()
                for _, cn in ipairs(touchConns) do pcall(function() cn:Disconnect() end) end
                touchPoints = {}
                common.Touch.Held = false
            end)
        end
    end

    --=========================================================================
    -- Ping in seconds. Used by prediction and trigger timing.
    --=========================================================================
    local pingAt, pingValue = -math.huge, 0.08
    function common.Ping()
        local now = tick()
        if now - pingAt < 0.5 then return pingValue end
        pingAt = now
        local ok, stats = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
        end)
        if ok and stats then
            local okValue, value = pcall(function() return stats:GetValue() end)
            if okValue and type(value) == "number" then
                pingValue = math.clamp(value / 1000, 0.02, 0.4)
                return pingValue
            end
        end
        return pingValue
    end

    --=========================================================================
    -- Safe service cache.
    --=========================================================================
    common.Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        UserInputService = game:GetService("UserInputService"),
        HttpService = game:GetService("HttpService"),
        Lighting = game:GetService("Lighting"),
        TeleportService = game:GetService("TeleportService"),
        VirtualUser = game:GetService("VirtualUser"),
        TweenService = game:GetService("TweenService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        Stats = game:GetService("Stats"),
        Workspace = workspace,
    }
    common.LocalPlayer = common.Services.Players.LocalPlayer

    return common
end

end)()
local BloxCloakFactory = (function()
-- Vortexion BloxStrike cloak: hides script-created instances from game scripts.
--
-- Adapted from the Vanity-General-Roblox design (local sandbox study). Game
-- anti-cheat / anti-ESP logic that enumerates children cannot see instances
-- registered here. The hook only rewrites enumeration calls made by game
-- threads (checkcaller() == false); executor-side reads are untouched.
--
-- Two defenses compose:
--   1. Enumeration filter - GetChildren/GetDescendants/FindFirstChild* skip
--      protected instances for game-thread callers.
--   2. RandomName - every created instance gets a 14-letter random name so
--      static name signatures ("_chams", "ESP") never match.
return function(common)
    local Workspace = common.Services.Workspace
    local Players = common.Services.Players

    local Cloak = {}
    local protectedSet = setmetatable({}, { __mode = "k" })
    local hookInstalled = false
    local namecallConnection = nil
    local inFilter = false

    local FILTERED_METHODS = {
        GetChildren = true,
        GetDescendants = true,
        FindFirstChild = true,
        FindFirstChildOfClass = true,
        FindFirstChildWhichIsA = true,
    }

    local function isHidden(instance)
        local current = instance
        local depth = 0
        while current and depth < 64 do
            if protectedSet[current] then return true end
            current = current.Parent
            depth += 1
        end
        return false
    end
    Cloak.IsHidden = isHidden

    -- Instances parented into Workspace or PlayerGui are game-visible surfaces:
    -- a hidden instance there still needs its enumeration filtered (handled by
    -- the hook), but gethui-parented instances are outside the game tree and
    -- need nothing. This distinction keeps the hook's hot path short.
    local function exposedToGame(instance)
        local current = instance
        local depth = 0
        while current and depth < 64 do
            if current == Workspace then return true end
            local playerGui = current == Players.LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then return true end
            current = current.Parent
            depth += 1
        end
        return false
    end
    Cloak.ExposedToGame = exposedToGame

    function Cloak.Protect(instance)
        if typeof(instance) ~= "Instance" then return instance end
        protectedSet[instance] = true
        return instance
    end

    function Cloak.Unprotect(instance)
        protectedSet[instance] = nil
    end

    --=========================================================================
    -- Hook. newcclosure wrapping keeps the hook invisible to islclosure /
    -- getinfo / string.dump probing (looks like a C closure). hookmetamethod
    -- is preferred over getrawmetatable + __namecall assignment because it
    -- restores cleanly and does not disturb other executor hooks.
    --=========================================================================
    local function installHook()
        if hookInstalled then return end
        if not (common.Caps.hookmetamethod and common.Caps.checkcaller) then
            common.Log("Cloak", "hook unavailable; enumeration filter disabled")
            return
        end

        local ok, err = pcall(function()
            local gameMetatable = getrawmetatable(game)
            local originalNamecall = gameMetatable.__namecall
            local namecallHook

            namecallHook = hookmetamethod(game, "__namecall", function(self, ...)
                -- Only game threads are filtered. Executor threads (this
                -- script, the UI library) must see everything or the UI dies.
                local fromGameScript = false
                if common.Caps.checkcaller then
                    local okCaller, caller = pcall(checkcaller)
                    fromGameScript = okCaller and (caller == false)
                end

                if fromGameScript and not inFilter then
                    local methodOk, methodRaw = pcall(getnamecallmethod)
                    local method = methodOk and methodRaw or nil
                    if method and FILTERED_METHODS[method] then
                        inFilter = true
                        local arguments = table.pack(...)
                        local okFilter, result = pcall(function()
                            if isHidden(self) then
                                -- The container itself is hidden: report it empty.
                                if method == "GetChildren" or method == "GetDescendants" then
                                    return {}
                                end
                                return nil
                            end
                            local children = originalNamecall(self, table.unpack(arguments, 1, arguments.n))
                            if method == "GetChildren" or method == "GetDescendants" then
                                local visible = {}
                                for _, child in ipairs(children) do
                                    if not isHidden(child) then
                                        table.insert(visible, child)
                                    end
                                end
                                return visible
                            end
                            return children
                        end)
                        inFilter = false
                        if okFilter then return result end
                    end
                end
                return originalNamecall(self, ...)
            end)

            if common.Caps.newcclosure then
                namecallHook = newcclosure(namecallHook)
            end
            namecallConnection = namecallHook
            hookInstalled = true
            common.Log("Cloak", "enumeration hook installed")
        end)

        if not ok then
            warn("[Vortexion/Blox/Cloak] install failed: " .. tostring(err))
        end
    end

    function Cloak.Start()
        installHook()
    end

    function Cloak.Stop()
        -- The metatable hook cannot be surgically removed without the original
        -- reference on every executor; the filter is inert once protectedSet is
        -- cleared, so clearing is the supported teardown.
        table.clear(protectedSet)
        hookInstalled = false
        namecallConnection = nil
    end

    return Cloak
end

end)()
local BloxCombatFactory = (function()
-- Vortexion BloxStrike combat: aimbot, triggerbot, local hitbox envelope.
--
-- Design notes (why, not what):
--   * The old aim loop lerped with alpha=1-exp(-smooth*25*dt) which at the
--     default smooth=0.35 lands at ~0.58 per frame - a snap, not a track. The
--     new alpha is clamped to (1-Smoothness) scaled by on-screen angular
--     distance, with a per-frame angular-speed ceiling (22 deg/s) so long
--     flicks stay human and short corrections stay sticky.
--   * Locking re-validates every frame (dead / health / distance / on-screen)
--     instead of trusting a cached model reference.
--   * Prediction uses an EMA of target velocity plus half the measured ping;
--     without it a strafing target is always chased from behind.
--   * Triggerbot presses mouse1 (executor) with VirtualUser fallback instead
--     of the previous notify-only stub.
--   * Hitbox grows local part sizes through a 20Hz state machine with lerp,
--     distance-scaled magnitude and a per-player restore table, so nothing is
--     left mutated after a respawn or reload. Client-side sizes never reach
--     the server; the value here is visual consistency plus the envelope the
--     Bullet module feeds back into weapon remotes.
return function(c)
    local Players = c.Services.Players
    local RunService = c.Services.RunService
    local Workspace = c.Services.Workspace
    local LocalPlayer = c.LocalPlayer

    --=========================================================================
    -- Configuration (UI flags kept backwards-compatible where they existed).
    --=========================================================================
    local Config = {
        Enabled = false,
        RageEnabled = false,
        RageMode = "Fast", -- Fast | Instant
        RageDelivery = "Auto", -- detect camera rewrites; fall back to mouse input
        RageAutoFire = true,
        RageFOV = 700,
        RageDistance = 900,
        RageMaxAngle = 85,
        RagePart = "Head",
        RageWallCheck = true,
        RageFireInterval = 0.14,
        RageLead = 0.09,
        RageSwitchDelay = 0.09,
        Mode = "Camera",          -- Camera | Mouse | Both
        TriggerKey = "Always",    -- Always | Hold (RMB2 / touch)
        FOV = 240,
        MaxDistance = 500,
        Smoothness = 0.35,
        Hitbox = "Head",          -- Head | Torso | Arms | Legs | Random
        WallCheck = true,
        TeamCheck = true,
        Prediction = 0.12,
        MaxAngle = 35,
        HitChance = 1,
        AimTurnRate = 120,
        Priority = "Crosshair",     -- Crosshair | Distance | LowHealth
        FOVCircle = true,
        Attraction = 0.6,
        -- triggerbot
        TriggerEnabled = false,
        TriggerMode = "Locked",   -- Locked | Always
        TriggerDelay = 0.12,
        -- hitbox
        HitboxEnabled = false,
        HitboxSize = 1.6,
        HitboxMode = "fullBody", -- lockedOnly | fullBody
        HitboxMaxActive = 8,
    }

    local Combat_PredictPoint

    local state = {
        locked = nil,
        rageTarget = nil,
        rageLastSwitch = 0,
        rageAttempts = 0,
        rageSent = 0,
        rageReason = "off",
        rageAimBackend = "none",
        rageExpectedLook = nil,
        rageCameraMisses = 0,
        rageCameraHits = 0,
        rageMouseMoves = 0,
        rageLastMouseError = 0,
        fireBackend = "none",
        fireOwner = nil,
        lastLocked = nil,
        candidates = {},
        velEMA = {},
        scanAccum = 0,
        aimSmooth = Vector3.zero,
        aimSmoothValid = false,
        lastPredictOffset = nil,
        mouseNoise = nil,
        fireAt = 0,
        firing = false,
        hitAccum = 0,
        hitEntries = {},          -- [player] = hit entry (restore keyed by player)
        rollCache = {},
        rollAt = {},
        cost = 0,
        scans = 0,
        candidatesSeen = 0,
    }

    --=========================================================================
    -- Raycast setup for wall checks.
    --=========================================================================
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    local function wallBlocked(fromPos, toPos, character, target)
        local diff = toPos - fromPos
        local dist = diff.Magnitude
        if dist < 0.1 then return false end
        rayParams.FilterDescendantsInstances = character and { character } or {}
        local result = Workspace:Raycast(fromPos, diff, rayParams)
        return result ~= nil and not (target and result.Instance and result.Instance:IsDescendantOf(target))
    end

    --=========================================================================
    -- Candidate scan (10Hz). Entries carry screen/world distance so target
    -- selection and eligibility gates share one traversal.
    --=========================================================================
    local function scan()
        state.scans += 1
        state.candidates = {}
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local camPos = camera.CFrame.Position
        local viewport = camera.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

        local searchDistance = Config.RageEnabled and math.max(Config.RageDistance, Config.MaxDistance) or Config.MaxDistance
        local searchFov = Config.RageEnabled and math.max(Config.RageFOV, Config.FOV) or Config.FOV
        for _, player in ipairs(type(c.Targets) == "function" and c.Targets() or Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local model, humanoid = c.Living(player)
                if model and humanoid and humanoid.Health > 0 then
                    if (not Config.TeamCheck) or c.Enemy(player, true) then
                        local root = model:FindFirstChild("HumanoidRootPart")
                            or model:FindFirstChild("Torso")
                            or model:FindFirstChildWhichIsA("BasePart")
                        if root then
                            local pos = root.Position
                            local worldDist = (pos - camPos).Magnitude
                            if worldDist <= searchDistance then
                                local screen, onScreen = camera:WorldToViewportPoint(pos)
                                if screen.Z > 0 then
                                    local screenVec = Vector2.new(screen.X, screen.Y)
                                    local screenDist = onScreen and (screenVec - center).Magnitude or math.huge
                                    if screenDist <= searchFov then
                                        local vel = root.AssemblyLinearVelocity or Vector3.zero
                                        local ema = state.velEMA[player]
                                        if not ema then
                                            state.velEMA[player] = vel
                                        else
                                            ema = ema:Lerp(vel, 0.15)
                                            state.velEMA[player] = ema
                                        end
                                        table.insert(state.candidates, {
                                            player = player,
                                            model = model,
                                            humanoid = humanoid,
                                            root = root,
                                            head = model:FindFirstChild("Head"),
                                            screenDist = screenDist,
                                            worldDist = worldDist,
                                            screen = screenVec,
                                            onScreen = onScreen,
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        state.candidatesSeen = #state.candidates
        -- Drop EMA state for players that left.
        for player in pairs(state.velEMA) do
            if not player.Parent or (player.IsVortexionNPC and
                (not player.Character or not player.Character.Parent)) then
                state.velEMA[player] = nil
            end
        end
    end

    --=========================================================================
    -- Target part selection per aim mode.
    --=========================================================================
    local RANDOM_PARTS = { "Head", "UpperTorso", "Torso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" }

    local function pickPart(entry)
        local model = entry.model
        local mode = Config.Hitbox
        if mode == "Random" then
            if entry.randomPart and entry.randomPart.Parent == model then return entry.randomPart end
            for _ = 1, 6 do
                local part = model:FindFirstChild(RANDOM_PARTS[math.random(1, #RANDOM_PARTS)])
                if part then entry.randomPart = part; return part end
            end
            entry.randomPart = entry.head or entry.root
            return entry.randomPart
        elseif mode == "Torso" then
            return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or entry.root
        elseif mode == "Arms" then
            return model:FindFirstChild("LeftUpperArm") or model:FindFirstChild("Left Arm")
                or model:FindFirstChild("RightUpperArm") or model:FindFirstChild("Right Arm")
                or entry.root
        elseif mode == "Legs" then
            return model:FindFirstChild("LeftUpperLeg") or model:FindFirstChild("Left Leg")
                or model:FindFirstChild("RightUpperLeg") or model:FindFirstChild("Right Leg")
                or entry.root
        end
        return entry.head or entry.root
    end

    --=========================================================================
    -- Prediction: EMA velocity * (half ping + fixed lead), intensity-scaled
    -- by Config.Prediction, then smoothed once more so the aim point does not
    -- jitter when the target's velocity estimate flips sign.
    --=========================================================================
    function Combat_PredictPoint(entry, forcePart)
        local part = forcePart or pickPart(entry)
        if not part then return nil end
        local pos = part.Position
        local ema = state.velEMA[entry.player]
        if not ema then return pos end
        local lead = 0.5 * c.Ping() + 0.05
        local offset = ema * (lead * (Config.Prediction / 0.12))
        if state.aimSmoothValid and state.lastPredictOffset then
            if (offset - state.lastPredictOffset).Magnitude > 0.05 then
                state.aimSmooth = state.aimSmooth:Lerp(offset, 0.25)
            end
        else
            state.aimSmooth = offset
            state.aimSmoothValid = true
        end
        state.lastPredictOffset = offset
        return pos + state.aimSmooth
    end

    --=========================================================================
    -- Target selection + per-frame lock validation.
    --=========================================================================
    local function entryValid(entry, rage)
        if not entry or not entry.player.Parent or not entry.model.Parent or not entry.root.Parent then return false end
        local model, humanoid = c.Living(entry.player)
        if model ~= entry.model or humanoid ~= entry.humanoid or humanoid.Health <= 0 then return false end
        if Config.TeamCheck and not c.Enemy(entry.player, true) then return false end
        local camera = Workspace.CurrentCamera
        if not camera then return false end
        local delta = entry.root.Position - camera.CFrame.Position
        local limitDistance = rage and Config.RageDistance or Config.MaxDistance
        if delta.Magnitude > limitDistance or delta.Magnitude < 0.01 then return false end
        local angle = math.deg(math.acos(math.clamp(camera.CFrame.LookVector:Dot(delta.Unit), -1, 1)))
        if angle > (rage and Config.RageMaxAngle or Config.MaxAngle) then return false end
        local screen, visible = camera:WorldToViewportPoint(entry.root.Position)
        if not visible or screen.Z <= 0 then return false end
        local center = camera.ViewportSize * 0.5
        entry.screen = Vector2.new(screen.X, screen.Y)
        entry.screenDist = (entry.screen - center).Magnitude
        entry.worldDist = delta.Magnitude
        if entry.screenDist > (rage and Config.RageFOV or Config.FOV) then return false end
        local blocked = rage and Config.RageWallCheck or (not rage and Config.WallCheck)
        return not blocked or not wallBlocked(camera.CFrame.Position, entry.root.Position, c.Character(), entry.model)
    end

    local function chanceFor(entry)
        local now = tick()
        local player = entry.player
        if not state.rollAt[player] or now - state.rollAt[player] >= 0.15 then
            state.rollAt[player] = now
            state.rollCache[player] = math.random()
        end
        return state.rollCache[player] <= Config.HitChance
    end

    local function selectTarget()
        local camera = Workspace.CurrentCamera
        if not camera or #state.candidates == 0 then
            state.locked = nil
            return
        end
        local camPos = camera.CFrame.Position
        local character = c.Character()
        local best, bestScore
        for _, entry in ipairs(state.candidates) do
            if entryValid(entry) then
                local score
                if Config.Priority == "Distance" then score = entry.worldDist
                elseif Config.Priority == "LowHealth" then
                    score = (type(entry.humanoid) == "table" and entry.humanoid.HealthKnown == false) and (entry.screenDist + 10000)
                        or ((entry.humanoid.Health / math.max(entry.humanoid.MaxHealth, 1)) * 400 + entry.screenDist * 0.2)
                else score = entry.screenDist + entry.worldDist * 0.15 end
                if not bestScore or score < bestScore then
                    best, bestScore = entry, score
                end
            end
        end
        state.locked = best
    end

    local function lockStillValid()
        return entryValid(state.locked)
    end

    --=========================================================================
    -- Camera aim: clamped alpha, angular-speed ceiling, vertical damping,
    -- first-frame softness after target switch.
    --=========================================================================
    local function cameraAim(dt, aimPos)
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local camPos = camera.CFrame.Position
        local look = aimPos - camPos
        if look.Magnitude < 0.01 then return end
        local targetLook = look.Unit
        local targetCF = CFrame.lookAt(camPos, aimPos)
        local angle = math.acos(math.clamp(camera.CFrame.LookVector:Dot(targetLook), -1, 1))

        local screen, onScreen = camera:WorldToViewportPoint(aimPos)
        local viewport = camera.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
        local screenDist = onScreen and (Vector2.new(screen.X, screen.Y) - center).Magnitude or math.huge
        local fovT = 1 - math.clamp(screenDist / math.max(Config.FOV, 1), 0, 1)
        local alpha = math.clamp((1 - Config.Smoothness) * (0.4 + 0.6 * fovT), 0.10, 0.45)
        if math.abs(targetLook.Y) > 0.6 then alpha = alpha * 0.85 end
        if state.locked ~= state.lastLocked then alpha = math.min(alpha, 0.10) end
        if angle > 1e-4 then
            alpha = math.min(alpha, (math.rad(Config.AimTurnRate) * dt) / angle)
        end
        if alpha <= 0.001 then return end
        camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
    end

    --=========================================================================
    -- Mouse aim: relative movement scaled by attraction and a near-center
    -- damping band, EMA-smoothed noise, integer snapping.
    --=========================================================================
    local function mouseAim(dt, aimPos)
        if not c.Caps.mousemoverel then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local screen, onScreen = camera:WorldToViewportPoint(aimPos)
        if not onScreen or screen.Z <= 0 then return end
        local viewport = camera.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
        local target = Vector2.new(screen.X, screen.Y)
        local delta = target - center
        local mag = delta.Magnitude
        if mag < 1 then return end
        local factor = 0.2 * Config.Attraction * (0.4 + 0.6 * (1 - math.clamp(mag / math.max(Config.FOV, 1), 0, 1)))
        if mag <= Config.FOV * 0.25 then factor = factor * 0.5 end
        if mag <= 2 then
            mousemoverel(math.floor(delta.X + 0.5), math.floor(delta.Y + 0.5))
            return
        end
        local step = delta * factor
        local noise = Vector2.new((math.random() - 0.5) * 1.6, (math.random() - 0.5) * 1.6)
        if state.mouseNoise then
            state.mouseNoise = state.mouseNoise:Lerp(noise, 0.3)
        else
            state.mouseNoise = noise
        end
        step = step + state.mouseNoise
        if step ~= step then return end -- NaN guard
        mousemoverel(math.floor(step.X + 0.5), math.floor(step.Y + 0.5))
    end

    --=========================================================================
    -- Triggerbot: real mouse1 press (executor) with VirtualUser fallback.
    --=========================================================================
    local releaseFire, releaseAt
    local stopped = false
    local function finishFire()
        if releaseFire then pcall(releaseFire) end
        releaseFire, releaseAt = nil, nil
        state.firing = false
        state.fireOwner = nil
    end
    local function pressFire(now, owner)
        local camera = Workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local position = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
        if c.Caps.mouse1press and c.Caps.mouse1release then
            state.fireBackend = "mouse1press"
            releaseFire = mouse1release
            if not pcall(mouse1press) then finishFire(); return end
        elseif type(mouse1click) == "function" then
            -- Some mobile executors expose click but not a sustained press.
            state.fireBackend = "mouse1click"
            if not pcall(mouse1click) then return false end
            state.fireOwner = owner
            return true
        else
            local user = c.Services.VirtualUser
            if user and camera then
                state.fireBackend = "VirtualUser"
                releaseFire = function() user:Button1Up(position, camera.CFrame) end
                if not pcall(function() user:Button1Down(position, camera.CFrame) end) then finishFire(); return false end
            else
                -- VirtualInputManager is unavailable on many Roblox clients;
                -- a failed probe is visible in diagnostics, never called a hit.
                local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
                if not ok or not vim then
                    state.fireBackend = "unavailable"
                    return false
                end
                state.fireBackend = "VirtualInputManager"
                releaseFire = function() vim:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 0) end
                if not pcall(function()
                    vim:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 0)
                end) then finishFire(); return false end
            end
        end
        state.firing = true
        state.fireOwner = owner
        releaseAt = now + (owner == "rage" and 0.035 or math.max(Config.TriggerDelay, 0.02))
        return true
    end

    local UserInputService = game:GetService("UserInputService")

    -- Hold gate: when TriggerKey == "Hold" the aim assist and the triggerbot
    -- only run while RMB2 is held (or a single touch point is held on mobile).
    local function gateHeld()
        if Config.TriggerKey ~= "Hold" then return true end
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return true end
        return c.Touch.Enabled and c.Touch.Held
    end

    local function triggerTick(now)
        if not Config.TriggerEnabled or state.firing then return end
        if not gateHeld() then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local allowed = false
        if Config.TriggerMode == "Locked" then
            local entry = state.locked
            if entry and entryValid(entry) and chanceFor(entry) then
                local screen, onScreen = camera:WorldToViewportPoint(entry.root.Position)
                if onScreen and screen.Z > 0 then
                    local viewport = camera.ViewportSize
                    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
                    local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                    allowed = dist <= math.max(60, Config.FOV * 0.25)
                end
            end
        else
            for _, entry in ipairs(state.candidates) do
                if entryValid(entry) and entry.screenDist <= math.max(60, Config.FOV * 0.25) then
                    if chanceFor(entry) then
                        allowed = true
                        break
                    end
                end
            end
        end
        if not allowed then return end
        if now - state.fireAt < 0.18 then return end
        state.fireAt = now
        c.Guard("Combat.Trigger", function() pressFire(now, "trigger") end)
    end

    --=========================================================================
    -- Hitbox: 20Hz state machine. Local size edits never replicate; the point
    -- is (a) a visually consistent growth the player can see, (b) the restore
    -- table that guarantees no leftover mutation, (c) the envelope query the
    -- Bullet module uses when it rewrites weapon remotes.
    --=========================================================================
    local function hitboxParts(entry)
        local parts = {}
        local root = entry.root
        if root and root:IsA("BasePart") then table.insert(parts, root) end
        if entry.head and entry.head:IsA("BasePart") and entry.head ~= root then
            table.insert(parts, entry.head)
        end
        return parts
    end

    local function hitboxEligible(entry)
        if not entryValid(entry) then return false end
        if entry.worldDist > math.min(Config.MaxDistance, 600) then return false end
        -- Full-body visual target envelopes are not limited to the central 120 pixels.
        -- The server retains authority over hit validation.
        return true
    end

    local function targetSizeFor(orig, dist)
        local base = Vector3.new(orig.X * 1.6, orig.Y * 1.3, orig.Z * 1.6)
        local scale = 1 + (Config.HitboxSize - 1) * math.clamp(1 - dist / 250, 0, 1)
        local maxEdge = math.min(10, math.min(orig.X, orig.Z) * 2.2)
        return Vector3.new(
            math.min(base.X * scale, orig.X + maxEdge),
            math.min(base.Y * scale, orig.Y + maxEdge),
            math.min(base.Z * scale, orig.Z + maxEdge)
        )
    end

    local function beginHitEntry(entry)
        local parts = {}
        for _, part in ipairs(hitboxParts(entry)) do
            table.insert(parts, {
                part = part,
                origSize = part.Size,
                origTransparency = part.Transparency,
                origCollide = part.CanCollide,
                phase = "expanding",
                since = tick(),
            })
        end
        if #parts > 0 then
            state.hitEntries[entry.player] = { parts = parts, entry = entry }
        end
    end

    local function restoreHitEntry(player, record)
        if not record then return end
        for _, item in ipairs(record.parts) do
            local part = item.part
            if part and part.Parent then
                part.Size = item.origSize
                part.Transparency = item.origTransparency
                part.CanCollide = item.origCollide
            end
        end
        state.hitEntries[player] = nil
    end

    local function hitboxTick(dt)
        if not Config.HitboxEnabled then
            if next(state.hitEntries) then
                for player, record in pairs(state.hitEntries) do
                    restoreHitEntry(player, record)
                end
            end
            return
        end
        state.hitAccum += dt
        if state.hitAccum < 0.05 then return end
        state.hitAccum = 0
        local now = tick()

        local wanted = {}
        if Config.HitboxMode == "lockedOnly" then
            local entry = state.locked
            if entry and hitboxEligible(entry) then
                table.insert(wanted, entry)
            end
        else
            for i = 1, math.min(Config.HitboxMaxActive, #state.candidates) do
                local entry = state.candidates[i]
                if hitboxEligible(entry) then
                    table.insert(wanted, entry)
                    if #wanted >= Config.HitboxMaxActive then break end
                end
            end
        end

        local wantedSet = {}
        for _, entry in ipairs(wanted) do wantedSet[entry.player] = entry end

        -- Entries no longer wanted collapse back.
        for player, record in pairs(state.hitEntries) do
            if not wantedSet[player] then
                local done = true
                for _, item in ipairs(record.parts) do
                    local part = item.part
                    if part and part.Parent then
                        part.Size = part.Size:Lerp(item.origSize, 0.5)
                        part.Transparency = part.Transparency + (item.origTransparency - part.Transparency) * 0.5
                        if (part.Size - item.origSize).Magnitude > 0.01 then done = false end
                    end
                end
                if done then
                    restoreHitEntry(player, record)
                end
            end
        end

        for _, entry in ipairs(wanted) do
            local record = state.hitEntries[entry.player]
            if record and record.parts[1] and record.parts[1].part ~= entry.root then
                restoreHitEntry(entry.player, record)
                record = nil
            end
            if not record then
                beginHitEntry(entry)
                record = state.hitEntries[entry.player]
            end
            if record then
                for _, item in ipairs(record.parts) do
                    local part = item.part
                    if not part or not part.Parent then
                        restoreHitEntry(entry.player, record)
                        break
                    end
                    if item.phase == "expanding" then
                        local target = targetSizeFor(item.origSize, entry.worldDist)
                        part.Size = part.Size:Lerp(target, 0.35)
                        part.Transparency = part.Transparency + (0.55 - part.Transparency) * 0.35
                        if (part.Size - target).Magnitude < 0.02 then
                            item.phase = "pending"
                            item.since = now
                        end
                    elseif item.phase == "pending" then
                        part.Transparency = part.Transparency + (0.55 - part.Transparency) * 0.35
                        if now - item.since >= 0.25 then
                            item.phase = "expanding"
                        end
                    end
                    part.CanCollide = false
                end
            end
        end
    end

    -- Immediate restore on character/player changes: a stale entry would
    -- otherwise keep mutating a respawned character's parts.
    local function hookLifecycle()
        local function onCharacterRemoving(character)
            local player = Players:GetPlayerFromCharacter(character)
            if player and state.hitEntries[player] then
                restoreHitEntry(player, state.hitEntries[player])
            end
        end
        local conns = {}
        conns[#conns + 1] = Workspace.DescendantRemoving:Connect(function(inst)
            if inst:IsA("Model") then onCharacterRemoving(inst) end
        end)
        conns[#conns + 1] = Players.PlayerRemoving:Connect(function(player)
            if state.hitEntries[player] then
                restoreHitEntry(player, state.hitEntries[player])
            end
            state.velEMA[player], state.rollCache[player], state.rollAt[player] = nil, nil, nil
            if state.locked and state.locked.player == player then state.locked = nil end
            if state.lastLocked and state.lastLocked.player == player then state.lastLocked = nil end
            for i=#state.candidates,1,-1 do
                if state.candidates[i].player == player then table.remove(state.candidates,i) end
            end
        end)
        c.OnCleanup(function()
            for _, con in ipairs(conns) do pcall(function() con:Disconnect() end) end
        end)
    end
    hookLifecycle()

    --=========================================================================
    -- FOV circle (ScreenGui, random name, cloaked).
    --=========================================================================
    local fovGui, fovFrame, fovStroke
    local fovColors = { Red = Color3.fromRGB(255,90,90), Green = Color3.fromRGB(80,230,140), Cyan = Color3.fromRGB(0,180,255) }
    local fovColor = "Red"
    local function ensureFovCircle()
        if fovFrame and fovFrame.Parent then return fovFrame end
        local parent = c.GetGuiParent()
        if not parent then return nil end
        local sg = Instance.new("ScreenGui")
        sg.Name = c.RandomName()
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 999
        sg.Parent = parent
        if c.Cloak then sg = c.Cloak.Protect(sg) end
        local frame = Instance.new("Frame")
        frame.Name = c.RandomName()
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        frame.BackgroundTransparency = 1
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = frame
        local stroke = Instance.new("UIStroke")
        stroke.Color = fovColors[fovColor]
        fovStroke = stroke
        stroke.Thickness = 1.5
        stroke.Transparency = 0.35
        stroke.Parent = frame
        frame.Parent = sg
        if c.Cloak then frame = c.Cloak.Protect(frame) end
        fovGui, fovFrame = sg, frame
        return frame
    end

    local function fovTick()
        if Config.Enabled and Config.FOVCircle then
            local frame = ensureFovCircle()
            if frame then
                frame.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
                frame.Visible = true
            end
        elseif fovFrame and fovFrame.Parent then
            fovFrame.Visible = false
        end
    end

    --=========================================================================
    -- R2.22 RageBot: independent selection + direct camera lock + gated fire.
    -- No arbitrary remote injection: only normal input paths are attempted.
    -- Real damage remains server-authoritative and must be checked in-game.
    --=========================================================================
    local function ragePart(entry)
        local model = entry.model
        if Config.RagePart == "Torso" then
            return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or entry.root
        elseif Config.RagePart == "Nearest" then
            return entry.head or entry.root
        end
        return entry.head or model:FindFirstChild("Head") or entry.root
    end

    local function selectRage(now)
        local previous = state.rageTarget
        if previous and entryValid(previous, true) and now - state.rageLastSwitch < Config.RageSwitchDelay then
            return previous
        end
        local best, scoreBest
        for _, entry in ipairs(state.candidates) do
            if entryValid(entry, true) then
                local score = entry.screenDist + entry.worldDist * 0.025
                if entry == previous then score -= 12 end -- stable lock, no target thrash
                if not scoreBest or score < scoreBest then
                    best, scoreBest = entry, score
                end
            end
        end
        if best ~= previous then state.rageLastSwitch = now end
        state.rageTarget = best
        return best
    end

    -- BloxStrike may rebuild CurrentCamera from its own input yaw/pitch every
    -- frame. Test whether last frame's camera write survived; if not, use the
    -- executor's *input* path rather than repeatedly fighting the controller.
    -- 0% inferred server hits: a successful camera write or mouse event is
    -- only a delivery event, not confirmation that a bullet was accepted.
    local function resolveRageMouse()
        if type(mousemoverel) == "function" then return mousemoverel end
        for _, fetch in ipairs({
            function() return getgenv and getgenv().mousemoverel end,
            function() return getfenv and getfenv().mousemoverel end,
        }) do
            local ok, fn = pcall(fetch)
            if ok and type(fn) == "function" then return fn end
        end
        return nil
    end
    local rageMoveMouse = resolveRageMouse()
    local function rageDeliverAim(dt, camera, targetPoint, targetCF)
        if state.rageExpectedLook then
            local observed = camera.CFrame.LookVector
            local dot = math.clamp(observed:Dot(state.rageExpectedLook), -1, 1)
            local drift = math.deg(math.acos(dot))
            if drift > 2.5 then
                state.rageCameraMisses = (state.rageCameraMisses or 0) + 1
                state.rageCameraHits = 0
            else
                state.rageCameraHits = (state.rageCameraHits or 0) + 1
                state.rageCameraMisses = math.max(0, (state.rageCameraMisses or 0) - 1)
            end
            state.rageExpectedLook = nil
        end
        local delivery = Config.RageDelivery or "Auto"
        local useMouse = delivery == "Mouse"
            or (delivery == "Auto" and (state.rageCameraMisses or 0) >= 4)
        if useMouse and not rageMoveMouse then
            state.rageAimBackend = "Mouse unavailable / Camera"
            if delivery == "Mouse" then
                return false, "mousemoverel unavailable"
            end
            useMouse = false
        end
        if useMouse then
            state.rageAimBackend = "Mouse"
            local point, visible = camera:WorldToViewportPoint(targetPoint)
            if not visible or point.Z <= 0 then return false, "aim off screen" end
            local centre = camera.ViewportSize * 0.5
            local dx = point.X - centre.X
            local dy = point.Y - centre.Y
            local errorPx = math.sqrt(dx * dx + dy * dy)
            state.rageLastMouseError = errorPx
            -- Game input sensitivity varies. Bound every packet and only fire
            -- when the next frame confirms that the target reached the crosshair.
            if errorPx > 2 then
                local speed = Config.RageMode == "Instant" and 0.85 or 0.46
                local mx = math.floor(math.clamp(dx * speed, -120, 120) + 0.5)
                local my = math.floor(math.clamp(dy * speed, -120, 120) + 0.5)
                if mx ~= 0 or my ~= 0 then
                    local ok = pcall(rageMoveMouse, mx, my)
                    if not ok then return false, "mousemoverel error" end
                    state.rageMouseMoves = (state.rageMouseMoves or 0) + 1
                end
                return false, "mouse tracking"
            end
            return true, "mouse converged"
        end
        state.rageAimBackend = "Camera"
        local alpha = Config.RageMode == "Instant" and 1 or math.clamp(dt * 25, 0.45, 0.95)
        camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
        state.rageExpectedLook = camera.CFrame.LookVector
        local direction = (targetPoint - camera.CFrame.Position).Unit
        local error = math.deg(math.acos(math.clamp(camera.CFrame.LookVector:Dot(direction), -1, 1)))
        if delivery == "Auto" and rageMoveMouse and (state.rageCameraHits or 0) < 2 then
            return false, "camera stability probe"
        end
        return error <= 3, "camera tracking"
    end

    local function rageTick(dt, now)
        if not Config.RageEnabled then
            state.rageTarget = nil
            state.rageReason = "off"
            state.rageAimBackend = "none"
            state.rageExpectedLook = nil
            state.rageCameraMisses = 0
            state.rageCameraHits = 0
            return
        end
        if not gateHeld() then
            state.rageReason = "hold gate"
            state.rageTarget = nil
            return
        end
        local camera = Workspace.CurrentCamera
        if not camera then state.rageReason = "camera missing"; return end
        local entry = selectRage(now)
        if not entry then state.rageReason = "no visible candidate"; return end
        local part = ragePart(entry)
        if not part then state.rageReason = "target part unavailable"; return end
        local ping = type(c.Ping) == "function" and c.Ping() or 0
        local lead = math.clamp(Config.RageLead + ping * 0.5, 0, 0.3)
        local velocity = state.velEMA[entry.player] or part.AssemblyLinearVelocity or Vector3.zero
        local targetPoint = part.Position + velocity * lead
        local delta = targetPoint - camera.CFrame.Position
        if delta.Magnitude < 0.1 then return end
        local targetCF = CFrame.lookAt(camera.CFrame.Position, targetPoint)
        local aligned, deliveryReason = rageDeliverAim(dt, camera, targetPoint, targetCF)
        if not Config.RageAutoFire then
            state.rageReason = "tracking / auto-fire off: " .. deliveryReason
            return
        end
        if not aligned then state.rageReason = deliveryReason; return end
        if state.firing then state.rageReason = "fire pulse active"; return end
        if now - state.fireAt < Config.RageFireInterval then
            state.rageReason = "fire cooldown"
            return
        end
        state.fireAt = now
        state.rageAttempts += 1
        local ok, sent = pcall(pressFire, now, "rage")
        if ok and sent then
            state.rageSent += 1
            state.rageReason = "input sent (hit unverified)"
        else
            state.rageReason = "fire unavailable: " .. tostring(state.fireBackend)
        end
    end

    --=========================================================================
    -- Public interface (consumed by Core and the Bullet module).
    --=========================================================================
    local Combat = {}

    function Combat:IsActive()
        return not stopped and (Config.Enabled or Config.RageEnabled or Config.TriggerEnabled or Config.HitboxEnabled or state.firing)
    end

    function Combat:Update(dt)
        if stopped then return end
        local t0 = tick()
        if state.firing and ((not Config.TriggerEnabled and not Config.RageEnabled) or not gateHeld() or t0 >= (releaseAt or 0)) then finishFire() end
        local active = Config.Enabled or Config.RageEnabled or Config.TriggerEnabled or Config.HitboxEnabled
        if not active then
            state.locked = nil
            state.candidates = {}
            hitboxTick(dt)
            fovTick()
            return
        end
        state.scanAccum += dt
        if state.scanAccum >= (Config.RageEnabled and 0.05 or 0.1) then
            state.scanAccum = 0
            scan()
        end
        state.lastLocked = state.locked
        if not lockStillValid() then
            selectTarget()
        end
        local entry = state.locked
        if Config.Enabled and not Config.RageEnabled and gateHeld() and entry and chanceFor(entry) then
            local part = pickPart(entry)
            if part then
                local aimPos = Combat_PredictPoint(entry, part)
                if aimPos then
                    if Config.Mode == "Camera" then
                        cameraAim(dt, aimPos)
                    elseif Config.Mode == "Mouse" then
                        mouseAim(dt, aimPos)
                    else
                        local camera = Workspace.CurrentCamera
                        local screen, onScreen
                        if camera then screen, onScreen = camera:WorldToViewportPoint(aimPos) end
                        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
                        local dist = onScreen and (Vector2.new(screen.X, screen.Y) - Vector2.new(viewport.X / 2, viewport.Y / 2)).Magnitude or math.huge
                        if dist > Config.FOV * 0.25 then
                            cameraAim(dt, aimPos)
                        else
                            mouseAim(dt, aimPos)
                        end
                    end
                end
            end
        end
        rageTick(dt, t0)
        if not Config.RageEnabled then triggerTick(t0) end
        hitboxTick(dt)
        fovTick()
        state.cost = tick() - t0
    end

    -- Lock accessor for the Bullet module and trigger integration.
    function Combat:GetLock()
        if not gateHeld() then return nil end
        if Config.RageEnabled then
            local entry = state.rageTarget
            if not entry or not entryValid(entry, true) then return nil end
            local part = ragePart(entry)
            if not part then return nil end
            local offset = (state.velEMA[entry.player] or Vector3.zero)
                * math.clamp(Config.RageLead + (type(c.Ping) == "function" and c.Ping() or 0) * 0.5, 0, 0.3)
            return {player=entry.player, part=part, point=part.Position + offset, entry=entry}
        end
        if not Config.Enabled or not lockStillValid() then return nil end
        local entry = state.locked
        if not entry or not chanceFor(entry) then return nil end
        local part = pickPart(entry)
        if not part then return nil end
        local point = Combat_PredictPoint(entry, part)
        if not point then return nil end
        return { player = entry.player, part = part, point = point, entry = entry }
    end

    -- Public prediction entry (player, part) -> Vector3.
    function Combat:PredictPoint(player, part)
        if not part then return nil end
        local ema = state.velEMA[player]
        local pos = part.Position
        if not ema then return pos end
        local lead = 0.5 * c.Ping() + 0.05
        return pos + ema * (lead * (Config.Prediction / 0.12))
    end

    local function originalSize(part)
        if not part then return nil end
        for _, record in pairs(state.hitEntries) do
            for _, item in ipairs(record.parts) do
                if item.part == part then return item.origSize end
            end
        end
        return part.Size
    end
    function Combat:GetEnvelope(part)
        -- Never enlarge the bullet target envelope just because local visual
        -- parts were expanded: the server still validates original collision.
        local size = originalSize(part)
        if not size then return Vector3.zero end
        return size * 0.5 + Vector3.new(0.5, 0.5, 0.5)
    end

    function Combat:GetEnvelopeMargin(part)
        if not part then return 0.5 end
        return 0.5
    end

    function Combat:GetCandidates()
        return state.candidates
    end

    function Combat:DebugSnapshot()
        return {
            locked = state.locked and state.locked.player.Name or "-",
            rageLocked = state.rageTarget and state.rageTarget.player.Name or "-",
            rageEnabled = Config.RageEnabled, rageAttempts = state.rageAttempts,
            rageSent = state.rageSent, rageReason = state.rageReason,
            rageAimBackend = state.rageAimBackend,
            rageCameraMisses = state.rageCameraMisses,
            rageMouseMoves = state.rageMouseMoves,
            rageMouseError = state.rageLastMouseError,
            fireBackend = state.fireBackend,
            candidates = #state.candidates,
            hitEntries = (function() local n = 0; for _ in pairs(state.hitEntries) do n += 1 end; return n end)(),
            hitboxScope = Config.HitboxMode, hitboxEnabled = Config.HitboxEnabled,
            firing = state.firing,
            costMs = math.floor(state.cost * 100000) / 100,
            scans = state.scans,
            active = Config.Enabled,
            gate = Config.TriggerKey,
            turnRate = Config.AimTurnRate,
        }
    end

    function Combat:Stop()
        for player, record in pairs(state.hitEntries) do
            restoreHitEntry(player, record)
        end
        if fovGui then fovGui:Destroy(); fovGui = nil; fovFrame = nil end
        stopped = true
        finishFire()
        state.locked, state.lastLocked, state.rageTarget = nil, nil, nil
        state.rageExpectedLook = nil
        state.candidates, state.velEMA, state.rollCache, state.rollAt = {}, {}, {}, {}
        Config.Enabled = false
        Config.RageEnabled = false
        Config.TriggerEnabled = false
        Config.HitboxEnabled = false
    end

    c.OnCleanup(function()
        Combat:Stop()
    end)

    --=========================================================================
    -- UI (Combat tab). Original flag names preserved.
    --=========================================================================
    local tab = c.Tabs.Combat
    tab:AddParagraph({ Title = "RageBot · 游戏内输入驱动",
        Content = "独立目标扫描、快速镜头锁定、自动开火；Android 将按执行器能力尝试模拟射击。输入成功不等于服务器实际命中。" })
    tab:AddToggle("BloxRageEnabled", {Title="RageBot 总开关", Default=false, Callback=function(v)
        Config.RageEnabled = v
        if not v then
            state.rageTarget = nil
            state.rageReason = "off"
            state.rageExpectedLook = nil
            state.rageCameraMisses, state.rageCameraHits = 0, 0
            if state.fireOwner == "rage" then finishFire() end
        end
    end})
    tab:AddDropdown("BloxRageMode", {Title="Rage 锁定", Values={"Fast", "Instant"}, Default="Fast",
        Callback=function(v) Config.RageMode = v end})
    tab:AddDropdown("BloxRageDelivery", {Title="Rage 瞄准输入", Values={"Auto", "Mouse", "Camera"}, Default="Auto",
        Callback=function(v)
            Config.RageDelivery = v
            state.rageExpectedLook = nil
            state.rageCameraMisses, state.rageCameraHits = 0, 0
        end})
    tab:AddDropdown("BloxRagePart", {Title="Rage 部位", Values={"Head", "Torso", "Nearest"}, Default="Head",
        Callback=function(v) Config.RagePart = v end})
    tab:AddToggle("BloxRageAutoFire", {Title="Rage 自动射击", Default=true,
        Callback=function(v) Config.RageAutoFire = v; if not v and state.fireOwner=="rage" then finishFire() end end})
    tab:AddToggle("BloxRageWallCheck", {Title="Rage 遮挡检查", Default=true,
        Callback=function(v) Config.RageWallCheck = v end})
    tab:AddSlider("BloxRageFOV", {Title="Rage 屏幕半径", Min=100, Max=1300, Default=700, Rounding=0,
        Callback=function(v) Config.RageFOV=v end})
    tab:AddSlider("BloxRageDistance", {Title="Rage 距离", Min=100, Max=2000, Default=900, Rounding=0,
        Callback=function(v) Config.RageDistance=v end})
    tab:AddSlider("BloxRageMaxAngle", {Title="Rage 最大夹角", Min=15, Max=120, Default=85, Rounding=0,
        Callback=function(v) Config.RageMaxAngle=v end})
    tab:AddSlider("BloxRageFireInterval", {Title="Rage 开火间隔 (s)", Min=0.08, Max=0.5, Default=0.14, Rounding=2,
        Callback=function(v) Config.RageFireInterval=v end})
    tab:AddSlider("BloxRageLead", {Title="Rage 运动预测 (s)", Min=0, Max=0.25, Default=0.09, Rounding=2,
        Callback=function(v) Config.RageLead=v end})
    tab:AddButton({Title="RageBot 状态诊断", Callback=function()
        local d=Combat:DebugSnapshot()
        print(("[Vortexion/Rage] enabled=%s target=%s scans=%d candidates=%d attempts=%d sent=%d aim=%s camera_misses=%d mouse_moves=%d mouse_error=%.1f fire=%s reason=%s")
            :format(tostring(d.rageEnabled),d.rageLocked,d.scans,d.candidates,d.rageAttempts,d.rageSent,
                d.rageAimBackend,d.rageCameraMisses,d.rageMouseMoves,d.rageMouseError,d.fireBackend,d.rageReason))
    end})
    tab:AddToggle("BloxAimEnabled", { Title = "自瞄辅助", Default = false, Callback = function(v)
        Config.Enabled = v
        c.Log("Combat", "aim", v, Config.Mode)
    end })
    tab:AddDropdown("BloxAimMode", { Title = "瞄准模式", Values = { "Camera", "Mouse", "Both" }, Default = "Camera",
        Callback = function(v) Config.Mode = v end })
    tab:AddDropdown("BloxAimPart", { Title = "瞄准部位", Values = { "Head", "Torso", "Arms", "Legs", "Random" }, Default = "Head",
        Callback = function(v) Config.Hitbox = v end })
    tab:AddToggle("BloxTouchAim", { Title = "按住瞄准（右键/触屏）", Default = false, Callback = function(v)
        Config.TriggerKey = v and "Hold" or "Always"
    end })
    tab:AddToggle("BloxWallCheck", { Title = "墙体检查", Default = true, Callback = function(v) Config.WallCheck = v end })
    tab:AddToggle("BloxTeamCheck", { Title = "仅敌方", Default = true, Callback = function(v) Config.TeamCheck = v end })
    tab:AddSlider("BloxAimFov", { Title = "自瞄 FOV", Min = 50, Max = 600, Default = 240, Rounding = 0,
        Callback = function(v) Config.FOV = v end })
    tab:AddSlider("BloxAimSmooth", { Title = "平滑（越小越快）", Min = 0.05, Max = 0.95, Default = 0.35, Rounding = 2,
        Callback = function(v) Config.Smoothness = v end })
    tab:AddSlider("BloxAimPrediction", { Title = "预测强度", Min = 0, Max = 0.5, Default = 0.12, Rounding = 2,
        Callback = function(v) Config.Prediction = v end })
    tab:AddSlider("BloxAimMaxAngle", { Title = "最大锁定角（度）", Min = 5, Max = 90, Default = 35, Rounding = 0,
        Callback = function(v) Config.MaxAngle = v end })
    tab:AddSlider("BloxAimHitChance", { Title = "本地辅助触发概率（%）", Min = 10, Max = 100, Default = 100, Rounding = 0,
        Callback = function(v) Config.HitChance = v / 100 end })
    tab:AddSlider("BloxAimTurnRate", {Title = "镜头最大转速（度/秒）", Min = 20, Max = 360,
        Default = 120, Rounding = 0, Callback = function(v) Config.AimTurnRate = v end})
    tab:AddDropdown("BloxAimPriority", {Title = "目标优先级", Values = {"Crosshair", "Distance", "LowHealth"},
        Default = "Crosshair", Callback = function(v) Config.Priority = v end})
    tab:AddButton({Title = "打印战斗识别诊断", Callback = function()
        local snapshot = Combat:DebugSnapshot()
        print(("[Vortexion/BloxCombat] 自瞄=%s 扫描=%d 目标=%d 锁定=%s 门控=%s 角度=%d")
            :format(tostring(snapshot.active), snapshot.scans, snapshot.candidates,
                snapshot.locked, snapshot.gate, Config.MaxAngle))
    end})
    tab:AddSlider("BloxAimAttraction", { Title = "鼠标吸附强度", Min = 0.1, Max = 1, Default = 0.6, Rounding = 2,
        Callback = function(v) Config.Attraction = v end })
    tab:AddSlider("BloxAimDistance", { Title = "最大锁定距离", Min = 50, Max = 2000, Default = 500, Rounding = 0,
        Callback = function(v) Config.MaxDistance = v end })
    tab:AddDropdown("BloxTouchRegion", { Title = "触屏控制区域", Values = { "Right", "All" }, Default = "Right",
        Callback = function(v) c.Touch.Region = v end })
    tab:AddDropdown("BloxFovColor", { Title = "FOV 配色", Values = { "Red", "Green", "Cyan" }, Default = "Red",
        Callback = function(v) fovColor = v; if fovStroke then fovStroke.Color = fovColors[v] or fovColors.Red end end })
    tab:AddToggle("BloxFovCircle", { Title = "FOV 圆圈", Default = true, Callback = function(v) Config.FOVCircle = v end })

    tab:AddToggle("BloxTriggerAssist", { Title = "自动开火", Default = false, Callback = function(v)
        Config.TriggerEnabled = v
        if not v then finishFire() end
        c.Log("Combat", "trigger", v, Config.TriggerMode)
    end })
    tab:AddDropdown("BloxTriggerMode", { Title = "开火条件", Values = { "Locked", "Always" }, Default = "Locked",
        Callback = function(v) Config.TriggerMode = v end })
    tab:AddSlider("BloxTriggerDelay", { Title = "开火按压时长", Min = 0.02, Max = 0.5, Default = 0.12, Rounding = 2,
        Callback = function(v) Config.TriggerDelay = v end })

    tab:AddToggle("BloxHitbox", { Title = "本地碰撞箱扩展", Default = false, Callback = function(v)
        Config.HitboxEnabled = v
        if not v then hitboxTick(0) end
        c.Log("Combat", "hitbox", v)
    end })
    tab:AddDropdown("BloxHitboxMode", { Title = "碰撞箱范围", Values = { "lockedOnly", "fullBody" }, Default = "fullBody",
        Callback = function(v) Config.HitboxMode = v end })
    tab:AddSlider("BloxHitboxSize", { Title = "碰撞箱倍率", Min = 1.1, Max = 3, Default = 1.6, Rounding = 1,
        Callback = function(v) Config.HitboxSize = v end })
    tab:AddParagraph({ Title = "碰撞箱说明",
        Content = "默认对视距内最多 8 个目标显示本地碰撞包络；服务器命中范围不会随 Size 扩大。子弹目标仍以原始部件大小约束，避免虚假命中。" })

    return Combat
end

end)()
local BloxBulletFactory = (function()
-- Vortexion BloxStrike bullet tracking.
--
-- Four paths, auto-selected by capability probe and live game structure:
--   A LeadOnly   - prediction already lives in Combat (velocity EMA + ping).
--                  Always on when aimbot prediction > 0; no hooks needed.
--   B Hitscan    - require the weapon module (ReplicatedStorage.Components.
--                  Weapon.Classes.Bullet and siblings), hook its raycast/fire
--                  functions and rewrite the direction argument so the local
--                  ray lands on the locked target. RaycastResult cannot be
--                  forged from Lua, so the input is the only honest lever.
--   C Remote     - hook __namecall and rewrite Vector3 arguments of weapon
--                  remotes (FireServer / InvokeServer): unit directions are
--                  re-pointed at the target, world-space hit points are
--                  clamped into the target's original-size envelope so the
--                  server-side check still sees a plausible hit.
--   D Projectile - watch Workspace for freshly spawned bullet parts and steer
--                  their velocity toward the predicted intercept point.
--
-- Every hook is pcall-wrapped, uninstallable, and skips executor-originated
-- calls (checkcaller) so this script's own remotes are never rewritten.
return function(c)
    local Players = c.Services.Players
    local Workspace = c.Services.Workspace
    local ReplicatedStorage = c.Services.ReplicatedStorage
    local RunService = c.Services.RunService
    local LocalPlayer = c.LocalPlayer

    local Config = {
        Enabled = false,
        Mode = "LeadOnly",      -- safe startup: no metatable or function hooks
        HitChance = 1,
        MaxAngle = 35,
        WallCheck = true,
        TeamCheck = true,
        Envelope = true,         -- clamp rewritten world points into orig size
        ProjectileTrack = true,
        ProjectileLerp = 0.35,
        ProjectileMax = 8,
        Debug = false,
        LinkCombat = true, -- LeadOnly needs aim prediction to be running
    }

    local state = {
        activePath = "LeadOnly",
        remoteHookOriginal = nil,
        remoteHookInstalled = false,
        weaponFunctions = {},     -- [original fn] = true (for uninstall)
        watchedRemotes = setmetatable({}, { __mode = "k" }), -- [remote] = true
        remoteCount = 0,
        bullets = {},             -- tracked projectile entries
        rollCache = {},
        rollAt = {},
        cost = 0,
        errors = 0,
        weaponProbe = "not run",
    }

    --==========================================================================
    -- R2.19: reversible game-specific weapon effect adapters.
    -- Based on observed BloxStrike class signatures, NOT a generic hook of
    -- every remote or every function. Enabled only after user toggles a mod.
    -- No server acceptance is presumed from local camera/spread changes.
    --==========================================================================
    local mods = {recoil=false, spread=false, patches={}, candidates=0,
        checked=0, status="not scanned", patchErrors=0, calls=0}
    local function recordPatch(owner, key, replacement)
        if type(owner) ~= "table" or type(rawget(owner, key)) ~= "function" then return false end
        for _, entry in ipairs(mods.patches) do
            if entry.owner == owner and entry.key == key then return true end
        end
        local original = rawget(owner, key)
        local ok = pcall(function() owner[key] = replacement(original) end)
        if not ok then mods.patchErrors += 1; return false end
        mods.patches[#mods.patches+1] = {owner=owner,key=key,original=original,wrapper=owner[key]}
        return true
    end
    local function restoreWeaponMods()
        for i = #mods.patches, 1, -1 do
            local patch = mods.patches[i]
            pcall(function()
                if patch.owner[patch.key] == patch.wrapper then
                    patch.owner[patch.key] = patch.original
                end
            end)
            mods.patches[i] = nil
        end
    end
    local function findWeaponTables()
        local results, dedup = {}, {}
        local function add(item)
            if type(item) ~= "table" or dedup[item] then return end
            dedup[item] = true
            results[#results+1] = item
        end
        local function requireAt(start, ...)
            local path = start
            for _, name in ipairs({...}) do
                path = path and path:FindFirstChild(name)
            end
            if path and path:IsA("ModuleScript") then
                local ok, value = pcall(require, path)
                if ok then add(value) end
            end
        end
        requireAt(ReplicatedStorage, "Controllers", "CameraController")
        requireAt(ReplicatedStorage, "Components", "Weapon", "Classes", "Bullet")
        -- Current community sources use a second, structurally different path.
        -- Probe only known ModuleScripts; never require arbitrary descendants.
        requireAt(ReplicatedStorage, "Classes", "WeaponComponent", "Classes", "Bullet")
        requireAt(ReplicatedStorage, "Controllers", "InventoryController")
        local scanGC = type(getgc) == "function" and getgc
        if scanGC then
            local ok, items = pcall(scanGC, true)
            if ok and type(items) == "table" then
                local seen = 0
                for _, item in pairs(items) do
                    seen += 1
                    if seen > 3500 then break end
                    if type(item) == "table" then
                        if type(rawget(item,"weaponKick")) == "function"
                            or type(rawget(item,"getTrueSpread")) == "function"
                            or type(rawget(item,"getSpreadForConfig")) == "function"
                            or type(rawget(item,"shoot")) == "function" then
                            add(item)
                        end
                    end
                end
                mods.checked = seen
            end
        end
        mods.candidates = #results
        return results
    end
    local function installWeaponMods()
        if not (mods.recoil or mods.spread) then
            restoreWeaponMods()
            mods.status = "disabled"
            return
        end
        -- Install once; wrappers read current flags. This avoids churn and
        -- avoids leaking closures cached by the game's own controller.
        if #mods.patches > 0 then
            mods.status = "active=" .. tostring(#mods.patches)
            return
        end
        local tables = findWeaponTables()
        local patched = 0
        for _, owner in ipairs(tables) do
            do
                for _, key in ipairs({"weaponKick", "setWeaponRecoil", "getWeaponKickRotation"}) do
                    local name = key
                    if recordPatch(owner, name, function(original)
                        return function(...)
                            if mods.recoil then
                                mods.calls += 1
                                if name == "getWeaponKickRotation" then return Vector3.zero end
                                return nil
                            end
                            return original(...)
                        end
                    end) then patched += 1 end
                end
            end
            do
                for _, key in ipairs({"getTrueSpread", "getSpreadForConfig", "getMovementSpreadForConfig",
                    "getBaseSpreadForConfig", "getBaseSpread"}) do
                    if recordPatch(owner, key, function(original)
                        return function(...)
                            local value = original(...)
                            if mods.spread then
                                if type(value) == "number" then mods.calls += 1; return 0 end
                                if typeof(value) == "Vector3" then mods.calls += 1; return Vector3.zero end
                            end
                            return value
                        end
                    end) then patched += 1 end
                end
            end
        end
        mods.status = patched > 0 and ("patched=" .. tostring(patched)) or "not supported: class unavailable"
    end
    local function setWeaponMod(kind, enabled)
        mods[kind] = enabled == true
        installWeaponMods()
    end
    c.OnCleanup(function()
        mods.recoil, mods.spread = false, false
        restoreWeaponMods()
    end)

    --=========================================================================
    -- Aim resolution: prefer the Combat lock, else the on-screen candidate
    -- nearest the crosshair. Shared by every rewrite path.
    --=========================================================================
    local function resolveAim()
        local combat = c.Combat
        if combat and combat.GetLock then
            local lock = combat.GetLock()
            if lock then
                return lock.point, lock.part, lock.player
            end
        end
        if combat and combat.GetCandidates then
            local camera = Workspace.CurrentCamera
            if not camera then return nil end
            local viewport = camera.ViewportSize
            local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
            local best, bestDist
            for _, entry in ipairs(combat.GetCandidates()) do
                local part = entry.head or entry.root
                if part then
                    local pos = combat.PredictPoint and combat.PredictPoint(entry.player, part) or part.Position
                    local screen, onScreen = camera:WorldToScreenPoint(pos)
                    if onScreen and screen.Z > 0 then
                        local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                        if not bestDist or dist < bestDist then
                            best, bestDist = pos, dist
                        end
                    end
                end
            end
            if best then return best, nil, nil end
        end
        return nil
    end

    --=========================================================================
    -- Gates: angle between current view and aim point, plus a per-shot roll
    -- so the server never sees a 100% conversion profile.
    --=========================================================================
    local function withinAngle(aimPos)
        local camera = Workspace.CurrentCamera
        if not camera then return false end
        local look = aimPos - camera.CFrame.Position
        if look.Magnitude < 0.01 then return true end
        local angle = math.acos(math.clamp(camera.CFrame.LookVector:Dot(look.Unit), -1, 1))
        return math.deg(angle) <= Config.MaxAngle
    end

    local function hitRoll(key)
        local now = tick()
        if not state.rollAt[key] or now - state.rollAt[key] > 0.5 then
            state.rollAt[key] = now
            state.rollCache[key] = math.random()
        end
        return state.rollCache[key] <= Config.HitChance
    end

    local function envelopeClamp(point, part)
        if not Config.Envelope or not part then return point end
        local center = part.Position
        local combat = c.Combat
        local half = combat and type(combat.GetEnvelope) == "function"
            and combat:GetEnvelope(part) or (part.Size * 0.5 + Vector3.new(0.5, 0.5, 0.5))
        local offset = point - center
        return center + Vector3.new(
            math.clamp(offset.X, -half.X, half.X),
            math.clamp(offset.Y, -half.Y, half.Y),
            math.clamp(offset.Z, -half.Z, half.Z)
        )
    end

    --=========================================================================
    -- Path B: hitscan input rewrite.
    --=========================================================================
    local WEAPON_NAME_HINTS = { "raycast", "cast", "fire", "perform", "shoot", "trace" }

    local function nameLooksWeapon(name)
        local lower = name:lower()
        for _, hint in ipairs(WEAPON_NAME_HINTS) do
            if lower:find(hint, 1, true) then return true end
        end
        return false
    end

    local function rewriteHitscanArgs(original, ...)
        if not Config.Enabled then return nil end
        local packed = table.pack(...)
        local vectors = {}
        for i = 1, math.min(packed.n, 8) do
            if typeof(packed[i]) == "Vector3" then
                table.insert(vectors, { index = i, value = packed[i] })
            end
        end
        if #vectors == 0 then return nil end

        local origin, direction
        for _, entry in ipairs(vectors) do
            local mag = entry.value.Magnitude
            if not origin and mag > 1.5 then
                origin = entry.value
            elseif not direction and mag > 0.95 and mag < 1.05 then
                direction = entry
            end
        end
        if not direction and #vectors >= 1 then
            for _, entry in ipairs(vectors) do
                if entry.value.Magnitude > 0.95 and entry.value.Magnitude < 1.05 then
                    direction = entry
                    break
                end
            end
        end
        if not direction then return nil end
        if not origin then
            local camera = Workspace.CurrentCamera
            if not camera then return nil end
            origin = camera.CFrame.Position
        end

        local aimPos, aimPart = resolveAim()
        if not aimPos then return nil end
        if not withinAngle(aimPos) then return nil end
        if not hitRoll("hitscan") then return nil end
        aimPos = envelopeClamp(aimPos, aimPart)

        local dir = (aimPos - origin)
        if dir.Magnitude < 0.01 then return nil end
        packed[direction.index] = dir.Unit * direction.value.Magnitude
        c.Log("Bullet", "hitscan rewrite idx", direction.index)
        return packed
    end

    local function installHitscanHooks()
        if not c.Caps.hookfunction then return false end
        local ok, err = pcall(function()
            local components = ReplicatedStorage:FindFirstChild("Components")
            local weaponRoot = components and components:FindFirstChild("Weapon")
            if not weaponRoot then
                c.Log("Bullet", "no Components.Weapon; hitscan unavailable")
                return
            end
            local classes = weaponRoot:FindFirstChild("Classes")
            local scanRoots = classes and { classes } or { weaponRoot }
            local hooked = 0
            for _, root in ipairs(scanRoots) do
                for _, module in ipairs(root:GetDescendants()) do
                    if module:IsA("ModuleScript") and hooked < 12 then
                        local okRequire, result = pcall(require, module)
                        if okRequire and type(result) == "table" then
                            for key, value in pairs(result) do
                                if type(value) == "function" and nameLooksWeapon(key) and hooked < 12 and not state.weaponFunctions[value] then
                                    local original
                                    local okHook = pcall(function()
                                        original = hookfunction(value, function(...)
                                            local okRw, rewritten = pcall(rewriteHitscanArgs, ...)
                                            if okRw and rewritten then
                                                return original(unpack(rewritten, 1, rewritten.n))
                                            end
                                            return original(...)
                                        end)
                                    end)
                                    if okHook and original then
                                        state.weaponFunctions[value] = original
                                        hooked += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
            c.Log("Bullet", "hitscan hooks", hooked)
        end)
        if not ok then
            state.errors += 1
            c.Log("Bullet", "hitscan install failed", err)
        end
        return ok and next(state.weaponFunctions) ~= nil
    end

    --=========================================================================
    -- Path C: remote argument rewrite via __namecall hook.
    --=========================================================================
    local REMOTE_NAME_HINTS = { "fire", "shoot", "bullet", "weapon", "hit", "damage", "replicate", "raycast" }

    local function remoteLooksWatched(name)
        local lower = name:lower()
        for _, hint in ipairs(REMOTE_NAME_HINTS) do
            if lower:find(hint, 1, true) then return true end
        end
        return false
    end

    local function scanRemotes()
        local count = 0
        for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
            if count >= 400 then break end
            if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
                count += 1
                if remoteLooksWatched(inst.Name) then
                    state.watchedRemotes[inst] = true
                end
            end
        end
        state.remoteCount = count
        c.Log("Bullet", "watched remotes", count)
    end

    local function rewriteRemoteArgs(...)
        local packed = table.pack(...)
        local aimPos, aimPart = resolveAim()
        if not aimPos then return nil end
        if not withinAngle(aimPos) then return nil end
        if not hitRoll("remote") then return nil end
        aimPos = envelopeClamp(aimPos, aimPart)
        local camera = Workspace.CurrentCamera
        if not camera then return nil end
        local camPos = camera.CFrame.Position
        local changed = false
        for i = 1, packed.n do
            local v = packed[i]
            if typeof(v) == "Vector3" then
                local mag = v.Magnitude
                if mag > 0.95 and mag < 1.05 then
                    local dir = aimPos - camPos
                    if dir.Magnitude > 0.01 then
                        packed[i] = dir.Unit * mag
                        changed = true
                    end
                elseif mag > 5 then
                    -- World-space point: clamp into the target envelope only
                    -- when it already sits near the target (hit report).
                    if (v - aimPos).Magnitude < 200 then
                        packed[i] = aimPos
                        changed = true
                    end
                end
            end
        end
        if changed then
            c.Log("Bullet", "remote rewrite")
            return packed
        end
        return nil
    end

    local function installRemoteHook()
        if not (c.Caps.hookmetamethod and c.Caps.getrawmetatable and c.Caps.checkcaller and c.Caps.getnamecallmethod) then
            return false
        end
        local ok, err = pcall(function()
            local metatable = getrawmetatable(game)
            local original = metatable.__namecall
            state.remoteHookOriginal = original
            local replacement = function(self, ...)
                if Config.Enabled and state.watchedRemotes[self] then
                    local methodOk, method = pcall(getnamecallmethod)
                    if methodOk and (method == "FireServer" or method == "InvokeServer") then
                        local callerOk, fromExecutor = pcall(checkcaller)
                        if not (callerOk and fromExecutor) then
                            local okRw, rewritten = pcall(rewriteRemoteArgs, ...)
                            if okRw and rewritten then
                                return original(self, unpack(rewritten, 1, rewritten.n))
                            end
                        end
                    end
                end
                return original(self, ...)
            end
            if c.Caps.newcclosure then
                replacement = newcclosure(replacement)
            end
            hookmetamethod(game, "__namecall", replacement)
            state.remoteHookInstalled = true
        end)
        if not ok then
            state.errors += 1
            c.Log("Bullet", "remote hook failed", err)
        end
        return ok
    end

    local function uninstallRemoteHook()
        if not state.remoteHookInstalled then return end
        pcall(function()
            hookmetamethod(game, "__namecall", state.remoteHookOriginal)
        end)
        state.remoteHookInstalled = false
        c.Log("Bullet", "remote hook removed")
    end

    --=========================================================================
    -- Path D: projectile tracking. A part spawned close to the camera with
    -- velocity and no anchor is treated as a local bullet for 3 seconds.
    --=========================================================================
    local bulletConns = {}

    local function trackBullet(inst)
        if #state.bullets >= Config.ProjectileMax then return end
        local part = inst
        if inst:IsA("Model") then
            part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        end
        if not part or not part:IsA("BasePart") then return end
        if part.Anchored then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        if (part.Position - camera.CFrame.Position).Magnitude > 60 then return end
        local localChar = LocalPlayer and LocalPlayer.Character
        if localChar and part:IsDescendantOf(localChar) then return end
        table.insert(state.bullets, { part = part, since = tick() })
        c.Log("Bullet", "tracking projectile", part:GetFullName())
    end

    local function projectileTick(dt)
        if not (Config.Enabled and Config.ProjectileTrack) then
            if #state.bullets > 0 then state.bullets = {} end
            return
        end
        local now = tick()
        for i = #state.bullets, 1, -1 do
            local bullet = state.bullets[i]
            local part = bullet.part
            if not part or not part.Parent or now - bullet.since > 3 then
                table.remove(state.bullets, i)
            else
                local aimPos = resolveAim()
                if aimPos then
                    local pos = part.Position
                    local dir = aimPos - pos
                    if dir.Magnitude > 0.5 then
                        local current = part.AssemblyLinearVelocity
                        if current and current.Magnitude > 1 then
                            local speed = current.Magnitude
                            local desired = dir.Unit * speed
                            part.AssemblyLinearVelocity = current:Lerp(desired, math.clamp(Config.ProjectileLerp, 0.05, 1))
                        end
                    end
                end
            end
        end
    end

    local function installProjectileWatch()
        local conn = Workspace.DescendantAdded:Connect(function(inst)
            if not Config.Enabled then return end
            if inst:IsA("BasePart") then
                trackBullet(inst)
            elseif inst:IsA("Model") then
                task.defer(function()
                    if inst.Parent then trackBullet(inst) end
                end)
            end
        end)
        table.insert(bulletConns, conn)
    end

    -- Recent public BloxStrike Luau sources identify runtime weapon classes
    -- by getgc tables (shoot/setupRecoil/getSpread), not solely by a fixed
    -- ReplicatedStorage.Components.Weapon path. Read-only and bounded: native
    -- hooking is intentionally never initiated by this diagnostic probe.
    local function probeRuntimeWeapon()
        local seen = 0
        local gun, bullet, camera = false, false, false
        if type(getgc) ~= "function" then
            state.weaponProbe = "getgc unavailable; only game hierarchy can be inspected"
            return state.weaponProbe
        end
        local ok, items = pcall(getgc, true)
        if not ok or type(items) ~= "table" then
            state.weaponProbe = "getgc unsupported or returned non-table"
            return state.weaponProbe
        end
        for _, item in pairs(items) do
            seen += 1
            if seen > 2500 then break end
            if type(item) == "table" then
                if rawget(item, "shoot") and rawget(item, "setupRecoil") then gun = true end
                if rawget(item, "getTrueSpread") and rawget(item, "getSpreadForConfig") then bullet = true end
                if rawget(item, "weaponKick") and rawget(item, "setWeaponRecoil") then camera = true end
            end
        end
        state.weaponProbe = ("runtime classes: gun=%s bullet=%s camera=%s scanned=%d")
            :format(tostring(gun), tostring(bullet), tostring(camera), seen)
        return state.weaponProbe
    end

    local function linkAimAssistant()
        if not Config.LinkCombat then return end
        local bridge = c.UI
        local option = bridge and bridge.Options and bridge.Options.BloxAimEnabled
        if option and option.Value ~= true and type(option.SetValue) == "function" then
            -- Native SetValue keeps the actual control and game state aligned.
            option:SetValue(true)
        end
    end

    --=========================================================================
    -- Mode resolution.
    --=========================================================================
    local function resolveMode()
        if Config.Mode ~= "Auto" then
            return Config.Mode
        end
        local hitscan = next(state.weaponFunctions) ~= nil
        local remote = next(state.watchedRemotes) ~= nil
        if hitscan then return "Hitscan" end
        if remote then return "Remote" end
        return "LeadOnly"
    end

    --=========================================================================
    -- Public interface.
    --=========================================================================
    local Bullet = {}

    function Bullet:Start()
        if Config.Enabled then return end
        Config.Enabled = true
        linkAimAssistant()
        -- On mobile, never attempt native/global hooks merely because the
        -- user enables the generic toggle. Explicit high-risk modes can be
        -- selected separately; LeadOnly remains a hook-free safe default.
        local mode = Config.Mode
        local mobile = c.Services.UserInputService and c.Services.UserInputService.TouchEnabled
        if mode == "Hitscan" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Hitscan", installHitscanHooks)
        end
        if mode == "Remote" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Scan", scanRemotes)
            c.Guard("Bullet.Remote", installRemoteHook)
        end
        if mode == "Projectile" or mode == "Auto" then
            if #bulletConns == 0 then installProjectileWatch() end
        end
        state.activePath = resolveMode()
        c.Log("Bullet", "started, path", state.activePath)
    end

    function Bullet:Stop()
        Config.Enabled = false
        uninstallRemoteHook()
        for value, original in pairs(state.weaponFunctions) do
            pcall(hookfunction, value, original)
        end
        state.weaponFunctions = {}
        for k in pairs(state.watchedRemotes) do state.watchedRemotes[k] = nil end
        state.bullets = {}
        state.activePath = "LeadOnly"
        c.Log("Bullet", "stopped")
    end

    function Bullet:IsActive()
        return Config.Enabled
    end

    function Bullet:Update(dt)
        if not Config.Enabled then
            if #state.bullets > 0 then state.bullets = {} end
            return
        end
        local t0 = tick()
        c.Guard("Bullet.Projectile", projectileTick, dt)
        state.cost = tick() - t0
    end

    function Bullet:Status()
        return {
            path = state.activePath,
            hooks = (function() local n = 0; for _ in pairs(state.weaponFunctions) do n += 1 end; return n end)(),
            remotes = (function() local n = 0; for _ in pairs(state.watchedRemotes) do n += 1 end; return n end)(),
            totalRemotes = state.remoteCount,
            bullets = #state.bullets,
            errors = state.errors,
            costMs = math.floor(state.cost * 100000) / 100,
            probe = state.weaponProbe,
            needsAim = state.activePath == "LeadOnly" and not (c.Combat and c.Combat.IsActive and c.Combat:IsActive()),
            weaponMods = mods.status, weaponCalls = mods.calls,
            weaponCandidates = mods.candidates, weaponPatchErrors = mods.patchErrors,
        }
    end

    function Bullet:Rescan()
        for k in pairs(state.watchedRemotes) do state.watchedRemotes[k] = nil end
        local mode = Config.Mode
        local mobile = c.Services.UserInputService and c.Services.UserInputService.TouchEnabled
        if mode == "Remote" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Scan", scanRemotes)
        end
        if mode == "Hitscan" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Hitscan", installHitscanHooks)
        end
        state.activePath = resolveMode()
    end

    c.OnCleanup(function()
        Bullet:Stop()
        for _, conn in ipairs(bulletConns) do
            pcall(function() conn:Disconnect() end)
        end
        bulletConns = {}
    end)

    --=========================================================================
    -- UI (Weapon tab): bullet tracking controls replace the old placeholder.
    --=========================================================================
    local tab = c.Tabs.Weapon
    tab:AddParagraph({Title="BloxStrike 武器模块增强", Content="优先检查 CameraController 和 Bullet 实际方法签名；仅在主动开启时安装可撤销的本地方法适配。无法取得类时报告不支持，不伪造效果。"})
    tab:AddToggle("BloxWeaponNoRecoilR219", {Title="降低本地枪械后坐力", Default=false,
        Callback=function(v) setWeaponMod("recoil", v) end})
    tab:AddToggle("BloxWeaponNoSpreadR219", {Title="本地枪械散布控制", Default=false,
        Callback=function(v) setWeaponMod("spread", v) end})
    tab:AddButton({Title="检查武器修改器状态", Callback=function()
        local snapshot = Bullet:Status()
        print(("[Vortexion/WeaponMods] status=%s candidates=%d calls=%d errors=%d")
            :format(snapshot.weaponMods, snapshot.weaponCandidates, snapshot.weaponCalls, snapshot.weaponPatchErrors))
    end})
    tab:AddParagraph({ Title = "子弹追踪",
        Content = "默认 LeadOnly 只提供瞄准预测，不会改写子弹；联动开启瞄准辅助后才有客户端可见效果。Hitscan/Remote 需有效游戏接口和执行器权限，未确认服务器命中。" })
    tab:AddToggle("BloxBulletLinkCombat", { Title = "子弹追踪联动开启瞄准辅助", Default = true,
        Callback = function(v) Config.LinkCombat = v end })
    tab:AddButton({ Title = "检查真实武器类（只读安全扫描）", Callback = function()
        local msg = probeRuntimeWeapon()
        print("[Vortexion/Blox/Weapon] " .. msg)
        if c.Notify then c.Notify("武器接口", msg) end
    end })
    tab:AddToggle("BloxBulletEnabled", { Title = "启用子弹追踪", Default = false, Callback = function(v)
        if v then Bullet:Start() else Bullet:Stop() end
    end })
    tab:AddDropdown("BloxBulletMode", { Title = "追踪路径", Values = { "Auto", "LeadOnly", "Hitscan", "Remote", "Projectile" },
        Default = "LeadOnly", Callback = function(v)
            -- Switching path while active must release the old hook first.
            local wasEnabled = Config.Enabled
            if wasEnabled then Bullet:Stop() end
            Config.Mode = v
            state.activePath = resolveMode()
            if wasEnabled then Bullet:Start() end
        end })
    tab:AddSlider("BloxBulletHitChance", { Title = "改写命中率（%）", Min = 10, Max = 100, Default = 100, Rounding = 0,
        Callback = function(v) Config.HitChance = v / 100 end })
    tab:AddSlider("BloxBulletMaxAngle", { Title = "改写最大角（度）", Min = 5, Max = 90, Default = 35, Rounding = 0,
        Callback = function(v) Config.MaxAngle = v end })
    tab:AddToggle("BloxBulletEnvelope", { Title = "命中点包络回投", Default = true, Callback = function(v)
        Config.Envelope = v end })
    tab:AddToggle("BloxBulletWallCheck", { Title = "墙体检查", Default = true, Callback = function(v)
        Config.WallCheck = v end })
    tab:AddToggle("BloxBulletProjectile", { Title = "投射物追踪", Default = true, Callback = function(v)
        Config.ProjectileTrack = v end })
    tab:AddSlider("BloxBulletLerp", { Title = "投射物转向强度", Min = 0.05, Max = 1, Default = 0.35, Rounding = 2,
        Callback = function(v) Config.ProjectileLerp = v end })
    tab:AddToggle("BloxBulletDebug", { Title = "调试日志", Default = false, Callback = function(v)
        Config.Debug = v
        c.Debug = v
    end })
    tab:AddButton({ Title = "重新扫描武器接口", Callback = function()
        Bullet:Rescan()
        local status = Bullet:Status()
        c.Notify("子弹追踪", ("路径 %s · 钩子 %d · 监听远程 %d/%d"):format(
            status.path, status.hooks, status.remotes, status.totalRemotes)
            .. " / " .. tostring(status.probe))
    end })

    return Bullet
end

end)()
local BloxVisualFactory = (function()
-- Vortexion BloxStrike visual: player ESP, fullbright, movement helpers.
--
-- R2.22: primary 2D ScreenGui projection plus optional native Billboard fallback.
-- One non-interactive entry per valid player, throttled update and cleanup.
--
-- Speed keeps the WalkSpeed writer for game compatibility but adds the
-- pulse/coast AssemblyLinearVelocity cycle from the SCP branch: a constant
-- max-speed stream is a lagback signature, 100ms boost + 150ms coast is not.
return function(c)
    local Players = c.Services.Players
    local Workspace = c.Services.Workspace
    local RunService = c.Services.RunService
    local UserInputService = c.Services.UserInputService
    local LocalPlayer = c.LocalPlayer

    local Config = {
        ESPEnabled = false,
        ESPTeam = true,
        ESPDistance = 500,
        ESPNames = true,
        ESPHealth = true,
        ESPRange = true,
        ESPVisibility = false, -- optional visibility tint: rays are OFF by default
        ESPWorldHighlight = false, -- optional 3D GPU highlight; native billboard is default
        ESPWeapon = true,
        ESPBox = true,
        ESPTracer = false,
        ESPOverlay = true, -- independent 2D ScreenGui projection; billboard fallback
        Fullbright = false,
        SpeedEnabled = false,
        SpeedValue = 24,
        PulseBoostMs = 100,
        PulseCoastMs = 150,
        CoastFactor = 0.16,
        FlyEnabled = false,
        TouchFly = true,
        FlySpeed = 60,
        Noclip = false,
    }

    --=========================================================================
    -- R2.19: native BillboardGui ESP. Roblox positions billboards in its
    -- renderer: no per-frame WorldToViewportPoint / GetBoundingBox / 3D
    -- Highlight allocations. One billboard per live replicated character.
    -- Only roster reconciliation and text are throttled in Lua.
    --=========================================================================
    local highlights = {}
    local overlayGui
    local overlayCreates = 0
    local overlayDraws = 0
    local function ensureOverlay()
        if overlayGui and overlayGui.Parent then return overlayGui end
        local parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not parent and type(c.GetGuiParent) == "function" then
            local ok, fallback = pcall(c.GetGuiParent)
            if ok then parent = fallback end
        end
        if not parent then return nil end
        local screen = Instance.new("ScreenGui")
        screen.Name = "VortexionBloxESP2D222"
        screen.ResetOnSpawn = false
        screen.IgnoreGuiInset = true -- WorldToViewportPoint is viewport-local.
        screen.DisplayOrder = 70
        screen.Enabled = Config.ESPEnabled and Config.ESPOverlay
        screen.Parent = parent
        overlayGui = screen
        return screen
    end
    local function makeOverlay(entry)
        if entry.overlay and entry.overlay.Parent then return end
        local screen = ensureOverlay()
        if not screen then return end
        local bounds = Instance.new("Frame")
        bounds.Name = "Target"
        bounds.BackgroundTransparency = 1
        bounds.BorderSizePixel = 0
        bounds.Active = false
        bounds.Visible = false
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(243, 93, 93)
        stroke.Thickness = 1.25
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = bounds
        local label = Instance.new("TextLabel")
        label.Name = "Info"
        label.AnchorPoint = Vector2.new(0.5, 1)
        label.Position = UDim2.new(0.5, 0, 0, -3)
        label.Size = UDim2.fromOffset(190, 65)
        label.BackgroundTransparency = 1
        label.TextColor3 = stroke.Color
        label.TextStrokeTransparency = 0.3
        label.TextSize = 13
        label.TextWrapped = false
        label.Active = false
        label.Text = ""
        label.Parent = bounds
        bounds.Parent = screen
        entry.overlay, entry.overlayStroke, entry.overlayText = bounds, stroke, label
        overlayCreates += 1
    end
    local function projectOverlay(entry, camera)
        if not Config.ESPOverlay then
            if entry.overlay then entry.overlay.Visible = false end
            entry.gui.Enabled = Config.ESPEnabled
            return
        end
        -- Keep the independent 2D path authoritative on Android; the existing
        -- BillboardGui survives as a fallback when viewport projection fails.
        if not camera or not camera.WorldToViewportPoint then return end
        makeOverlay(entry)
        if not entry.overlay then return end
        local root = entry.root
        if not root or not root.Parent then
            entry.overlay.Visible = false
            return
        end
        local upper = entry.model:FindFirstChild("Head")
        local top = upper and upper:IsA("BasePart") and (upper.Position + Vector3.new(0, 0.65, 0))
            or (root.Position + Vector3.new(0, 2.7, 0))
        local bottom = root.Position - Vector3.new(0, 2.8, 0)
        local a = camera:WorldToViewportPoint(top)
        local b = camera:WorldToViewportPoint(bottom)
        local middle, inView = camera:WorldToViewportPoint(root.Position)
        -- On mobile a nearby character's head can project above the screen
        -- even while the torso is visible. Testing the head's inView here
        -- removed valid targets. Cull by depth and the actual box instead.
        if a.Z <= 0 or b.Z <= 0 or middle.Z <= 0 then
            entry.overlay.Visible = false
            entry.gui.Enabled = false
            return
        end
        local rawTop, rawBottom = math.min(a.Y, b.Y), math.max(a.Y, b.Y)
        local vw, vh = camera.ViewportSize.X, camera.ViewportSize.Y
        local rawHeight = math.max(rawBottom - rawTop, 18)
        local rawWidth = math.clamp(rawHeight * 0.52, 14, vw * 0.3)
        local rawLeft = (a.X + b.X - rawWidth) * 0.5
        if not inView and (rawBottom < 0 or rawTop > vh or rawLeft > vw or rawLeft + rawWidth < 0) then
            entry.overlay.Visible = false
            entry.gui.Enabled = false
            return
        end
        local topY = math.clamp(rawTop, 0, vh)
        local bottomY = math.clamp(rawBottom, 0, vh)
        local height = math.max(1, bottomY - topY)
        local width = rawWidth
        entry.overlay.Position = UDim2.fromOffset(math.floor(rawLeft), math.floor(topY))
        entry.overlay.Size = UDim2.fromOffset(math.floor(width), math.floor(height))
        entry.overlay.Visible = true
        entry.gui.Enabled = false
        entry.overlayStroke.Enabled = Config.ESPBox
        entry.overlayText.Text = entry.text.Text
        entry.overlayText.Visible = entry.text.Visible
        entry.overlayStroke.Color = entry.stroke.Color
        entry.overlayText.TextColor3 = entry.stroke.Color
        overlayDraws += 1
    end
    local function hideOverlay(entry)
        if entry and entry.overlay then entry.overlay.Visible = false end
    end
    local espStats = {refreshes=0, scanned=0, eligible=0, markers=0,
        noHumanoid=0, creates=0, writes=0, lastError="none"}
    local MAX_ESP_TARGETS = 24
    local ESP_GRACE_SECONDS = 1.25
    -- Distances are hysteretic: existing labels survive small camera offsets.
    local ESP_DISTANCE_SLACK = 35
    local espAccum = 0
    local visibilityParams = RaycastParams.new()
    visibilityParams.FilterType = Enum.RaycastFilterType.Exclude
    visibilityParams.IgnoreWater = true
    local function renderRoot(model)
        local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("LowerTorso")
            or model:FindFirstChild("Torso") or model:FindFirstChild("Head") or model.PrimaryPart
        if part and part:IsA("BasePart") then return part end
        return model:FindFirstChildWhichIsA("BasePart", true)
    end
    local function clearEntry(player)
        local entry = highlights[player]
        if not entry then return end
        highlights[player] = nil
        if entry.overlay then pcall(function() entry.overlay:Destroy() end) end
        if entry.gui then pcall(function() entry.gui:Destroy() end) end
        if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
        if entry.tracer then pcall(function() entry.tracer:Remove() end) end
    end
    local function clearESP()
        for player in pairs(highlights) do clearEntry(player) end
        espStats.markers = 0
        if overlayGui then
            pcall(function() overlayGui:Destroy() end)
            overlayGui = nil
        end
    end
    local function makeEntry(player, model, root)
        local parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not parent and type(c.GetGuiParent) == "function" then
            local ok, fallback = pcall(c.GetGuiParent)
            if ok then parent = fallback end
        end
        if not parent then return nil end
        local gui = Instance.new("BillboardGui")
        gui.Name = "VortexionBloxESP219"
        gui.Adornee = root
        gui.AlwaysOnTop = true
        gui.LightInfluence = 0
        gui.Size = UDim2.new(4, 0, 6, 0)
        gui.StudsOffsetWorldSpace = Vector3.new(0, 1.15, 0)
        gui.MaxDistance = Config.ESPDistance + ESP_DISTANCE_SLACK
        gui.Active = false
        gui.Enabled = Config.ESPEnabled
        local box = Instance.new("Frame")
        box.Name = "Bounds"
        box.Size = UDim2.fromScale(1, 1)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Active = false
        box.Parent = gui
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.25
        stroke.Color = Color3.fromRGB(243, 93, 93)
        stroke.Parent = box
        local text = Instance.new("TextLabel")
        text.Name = "Info"
        text.AnchorPoint = Vector2.new(0.5, 1)
        text.Position = UDim2.new(0.5, 0, 0, -4)
        text.Size = UDim2.fromOffset(190, 54)
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 0.3
        text.TextColor3 = stroke.Color
        text.TextSize = 13
        text.TextWrapped = false
        text.Active = false
        text.Text = ""
        text.Parent = box
        local healthBack = Instance.new("Frame")
        healthBack.Name = "HealthBackground"
        healthBack.AnchorPoint = Vector2.new(1, 0)
        healthBack.Position = UDim2.fromScale(0, 0)
        healthBack.Size = UDim2.new(0, 3, 1, 0)
        healthBack.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
        healthBack.BorderSizePixel = 0
        healthBack.Visible = false
        healthBack.Active = false
        healthBack.Parent = box
        local healthFill = Instance.new("Frame")
        healthFill.Name = "HealthFill"
        healthFill.AnchorPoint = Vector2.new(0, 1)
        healthFill.Position = UDim2.fromScale(0, 1)
        healthFill.Size = UDim2.fromScale(1, 1)
        healthFill.BackgroundColor3 = Color3.fromRGB(92, 222, 132)
        healthFill.BorderSizePixel = 0
        healthFill.Active = false
        healthFill.Parent = healthBack
        gui.Parent = parent
        espStats.creates += 1
        return {gui=gui, box=box, stroke=stroke, text=text, healthBack=healthBack,
            healthFill=healthFill, model=model, root=root, lastSeen=os.clock(), nextInfo=0}
    end
    local function modelWeapon(model)
        local weapon = model:GetAttribute("Weapon") or model:GetAttribute("CurrentWeapon")
            or model:GetAttribute("EquippedWeapon")
        if type(weapon) == "string" and #weapon > 0 then return weapon end
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("Tool") then return child.Name end
        end
        return nil
    end
    local function updateInfo(entry, player, model, vitals, distance)
        local now = os.clock()
        if now < entry.nextInfo then return end
        entry.nextInfo = now + 0.3
        local info = {}
        if Config.ESPNames then info[#info+1] = tostring(player.DisplayName or player.Name) end
        local health, maximum
        if vitals then
            local h = vitals.Health
            local mx = vitals.MaxHealth
            if type(h) == "number" and type(mx) == "number" and mx > 0
                and (type(vitals) ~= "table" or vitals.HealthKnown ~= false) then
                health, maximum = math.max(0, h), mx
            end
        end
        if Config.ESPHealth and health then info[#info+1] = ("HP %d/%d"):format(math.floor(health), math.floor(maximum)) end
        if Config.ESPRange then info[#info+1] = ("%d studs"):format(math.floor(distance)) end
        if Config.ESPWeapon then
            local weapon = modelWeapon(model)
            if weapon then info[#info+1] = "W " .. weapon:sub(1, 26) end
        end
        local newText = table.concat(info, "\n")
        if entry.text.Text ~= newText then
            entry.text.Text = newText
            espStats.writes += 1
        end
        if entry.text.Visible ~= (#info > 0) then entry.text.Visible = #info > 0 end
        local visible = health ~= nil and Config.ESPHealth
        if entry.healthBack.Visible ~= visible then entry.healthBack.Visible = visible end
        if visible then
            local fraction = math.clamp(health / maximum, 0, 1)
            if fraction ~= entry.lastHealth then
                entry.healthFill.Size = UDim2.fromScale(1, fraction)
                entry.lastHealth = fraction
            end
        end
    end
    local function updateESP()
        if not Config.ESPEnabled then clearESP(); return end
        espStats.scanned, espStats.eligible, espStats.noHumanoid = 0, 0, 0
        local camera = Workspace.CurrentCamera
        local parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not parent and type(c.GetGuiParent) == "function" then
            local ok, fallback = pcall(c.GetGuiParent)
            if ok then parent = fallback end
        end
        if not camera or not parent then
            espStats.lastError = "camera or GUI parent unavailable"
            return
        end
        local now = os.clock()
        local left = MAX_ESP_TARGETS
        local origin = camera.CFrame.Position
        for _, player in ipairs(type(c.Targets) == "function" and c.Targets() or Players:GetPlayers()) do
            if player ~= LocalPlayer then
                espStats.scanned += 1
                local model, vitals = c.Living(player)
                if model and vitals and not model:FindFirstChildOfClass("Humanoid") then
                    espStats.noHumanoid += 1
                end
                local permitted = (not Config.ESPTeam) or c.Enemy(player, true)
                local root = model and renderRoot(model)
                local dist = root and (root.Position - origin).Magnitude or math.huge
                local valid = model and vitals and vitals.Health > 0 and root and permitted
                    and dist <= Config.ESPDistance + (highlights[player] and ESP_DISTANCE_SLACK or 0) and left > 0
                local entry = highlights[player]
                if valid then
                    left -= 1
                    espStats.eligible += 1
                    if entry and (entry.model ~= model or entry.root ~= root or not entry.gui.Parent) then
                        clearEntry(player)
                        entry = nil
                    end
                    if not entry then
                        entry = makeEntry(player, model, root)
                        if entry then highlights[player] = entry end
                    end
                    if entry then
                        entry.lastSeen = now
                        if not entry.gui.Enabled then entry.gui.Enabled = true end
                        local maxDistance = Config.ESPDistance + ESP_DISTANCE_SLACK
                        if entry.gui.MaxDistance ~= maxDistance then
                            entry.gui.MaxDistance = maxDistance
                        end
                        if entry.stroke.Enabled ~= Config.ESPBox then
                            entry.stroke.Enabled = Config.ESPBox
                        end
                        updateInfo(entry, player, model, vitals, dist)
                        if Config.ESPVisibility then
                            local ignore = c.Character(LocalPlayer)
                            visibilityParams.FilterDescendantsInstances = ignore and {ignore} or {}
                            local hit = Workspace:Raycast(origin, root.Position - origin, visibilityParams)
                            local unobstructed = not hit or (hit.Instance and hit.Instance:IsDescendantOf(model))
                            local color = unobstructed and Color3.fromRGB(86, 231, 144)
                                or Color3.fromRGB(243, 93, 93)
                            if entry.stroke.Color ~= color then
                                entry.stroke.Color = color
                                entry.text.TextColor3 = color
                            end
                        elseif entry.visibilityTinted then
                            local color = Color3.fromRGB(243, 93, 93)
                            entry.stroke.Color = color
                            entry.text.TextColor3 = color
                        end
                        entry.visibilityTinted = Config.ESPVisibility
                        -- The native Billboard alone is not reliable for all
                        -- custom rigs/mobile renderers; mirror into 2D.
                        local projected, projectionError = pcall(projectOverlay, entry, camera)
                        if not projected then
                            espStats.lastError = "2D projection: " .. tostring(projectionError):sub(1, 150)
                            hideOverlay(entry)
                            entry.gui.Enabled = Config.ESPEnabled
                        end
                        if Config.ESPWorldHighlight then
                            if not entry.highlight then
                                local h = Instance.new("Highlight")
                                h.Adornee = model
                                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                h.FillTransparency = 0.85
                                h.OutlineTransparency = 0.15
                                h.Parent = model
                                entry.highlight = h
                            end
                        elseif entry.highlight then
                            entry.highlight:Destroy()
                            entry.highlight = nil
                        end
                        if Config.ESPTracer and c.HasDrawing then
                            if not entry.tracer then
                                entry.tracer = Drawing.new("Line")
                                entry.tracer.Thickness = 1
                            end
                            local point, onScreen = camera:WorldToViewportPoint(root.Position)
                            entry.tracer.Visible = onScreen and point.Z > 0
                            if entry.tracer.Visible then
                                entry.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                                entry.tracer.To = Vector2.new(point.X, point.Y)
                                entry.tracer.Color = entry.stroke.Color
                            end
                        elseif entry.tracer then
                            entry.tracer:Remove()
                            entry.tracer = nil
                        end
                    end
                elseif entry then
                    -- Preserve the instance for brief replication and roster swaps;
                    -- never leave a ghost marker visible during that grace period.
                    -- Hide immediately only if the target really disappeared or is no
                    -- longer an allowed team; transient distance/replication misses
                    -- remain visible until the grace window expires.
                    if (not model or not root or not permitted or now - entry.lastSeen >= ESP_GRACE_SECONDS)
                        and entry.gui.Enabled then entry.gui.Enabled = false end
                    hideOverlay(entry)
                    if entry.tracer then entry.tracer.Visible = false end
                    if now - entry.lastSeen >= ESP_GRACE_SECONDS or not entry.model.Parent then
                        clearEntry(player)
                    end
                end
            end
        end
        for player in pairs(highlights) do
            if not player.Parent or (player.IsVortexionNPC and
                (not player.Character or not player.Character.Parent)) then
                clearEntry(player)
            end
        end
        local count = 0
        for _ in pairs(highlights) do count += 1 end
        espStats.markers = count
    end
    local function startESP()
        espAccum = 0
        c.Guard("Visual.ESP", updateESP)
    end

    --=========================================================================
    -- Fullbright with a full backup/restore cycle.
    --=========================================================================
    local lightingBackup
    local function setLight(on)
        local Lighting = c.Lighting
        if on then
            if not lightingBackup then
                lightingBackup = {
                    Brightness = Lighting.Brightness,
                    ClockTime = Lighting.ClockTime,
                    Ambient = Lighting.Ambient,
                    OutdoorAmbient = Lighting.OutdoorAmbient,
                    GlobalShadows = Lighting.GlobalShadows,
                    FogEnd = Lighting.FogEnd,
                }
            end
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.Ambient = Color3.fromRGB(175, 175, 175)
            Lighting.OutdoorAmbient = Color3.fromRGB(175, 175, 175)
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e10
        elseif lightingBackup then
            for key, value in pairs(lightingBackup) do
                pcall(function() Lighting[key] = value end)
            end
            lightingBackup = nil
        end
    end

    --=========================================================================
    -- Movement: speed (pulse/coast), fly, noclip.
    --=========================================================================
    local speedBackup = nil
    local origWalkSpeed = nil
    local speedRoot, speedVelocity
    local pulseState = "idle"
    local pulseStart = 0

    local function restoreSpeed()
        if speedBackup and speedBackup.Parent and origWalkSpeed then
            pcall(function() speedBackup.WalkSpeed = origWalkSpeed end)
        end
        if speedRoot and speedRoot.Parent and speedVelocity then speedRoot.AssemblyLinearVelocity = speedVelocity end
        speedRoot, speedVelocity = nil, nil
        speedBackup = nil
        origWalkSpeed = nil
        pulseState = "idle"
    end

    local function updateSpeed()
        local model, humanoid = c.Living(LocalPlayer)
        if not (model and humanoid) then restoreSpeed(); return end
        -- Virtual HP records support target discovery only. They are NOT
        -- actual movement controllers; never write fake WalkSpeed onto them.
        if model:FindFirstChildOfClass("Humanoid") ~= humanoid then
            restoreSpeed()
            return
        end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then restoreSpeed(); return end
        if speedBackup ~= humanoid then
            restoreSpeed()
            speedBackup = humanoid
            origWalkSpeed = humanoid.WalkSpeed
            speedRoot, speedVelocity = hrp, hrp.AssemblyLinearVelocity
        end
        if humanoid.WalkSpeed ~= Config.SpeedValue then
            humanoid.WalkSpeed = Config.SpeedValue
        end
        local direction = humanoid.MoveDirection
        if direction.Magnitude <= 0 then return end

        local now = tick()
        if pulseState == "idle" then
            pulseState = "boost"
            pulseStart = now
        end
        local boosting
        if pulseState == "boost" then
            if now - pulseStart >= Config.PulseBoostMs / 1000 then
                pulseState = "coast"
                pulseStart = now
                boosting = false
            else
                boosting = true
            end
        else
            if now - pulseStart >= Config.PulseCoastMs / 1000 then
                pulseState = "boost"
                pulseStart = now
                boosting = true
            else
                boosting = false
            end
        end

        local target = direction.Unit * (boosting and Config.SpeedValue or Config.SpeedValue * Config.CoastFactor)
        hrp.AssemblyLinearVelocity = Vector3.new(target.X, hrp.AssemblyLinearVelocity.Y, target.Z)
    end

    local flyRoot, flyVelocity
    local function restoreFly()
        if flyRoot and flyRoot.Parent and flyVelocity then flyRoot.AssemblyLinearVelocity = flyVelocity end
        flyRoot, flyVelocity = nil, nil
    end

    local function updateFly()
        local model, humanoid = c.Living(LocalPlayer)
        if not (model and humanoid) then restoreFly(); return end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then restoreFly(); return end
        if flyRoot ~= hrp then
            restoreFly()
            flyRoot, flyVelocity = hrp, hrp.AssemblyLinearVelocity
        end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
        if Config.TouchFly and c.Touch.Enabled and c.Touch.Held then
            local drag, vertical = c.Touch:Drag()
            if drag.Magnitude > 10 then
                move += camera.CFrame.RightVector * math.clamp(drag.X / 120, -1, 1)
                move -= camera.CFrame.LookVector * math.clamp(-drag.Y / 120, -1, 1)
            end
            if math.abs(vertical) > 30 then
                move += Vector3.new(0, math.clamp(-vertical / 120, -1, 1), 0)
            end
        end
        if move.Magnitude > 0 then
            hrp.AssemblyLinearVelocity = move.Unit * Config.FlySpeed
        else
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    local collisionBackup = {}
    local collisionModel
    local function restoreNoclip()
        for part, value in pairs(collisionBackup) do
            if part.Parent then part.CanCollide = value end
            collisionBackup[part] = nil
        end
        collisionModel = nil
    end
    local function updateNoclip()
        local model = c.Character()
        if model ~= collisionModel then restoreNoclip(); collisionModel = model end
        if not model then return end
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                if collisionBackup[part] == nil then collisionBackup[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end

    -- Third-person ownership: one post-camera render pass, not periodic
    -- CameraMode/CameraType writes fighting the game's first-person controller.
    local thirdPerson = {enabled = false, distance = 12, saved = nil,
        overrides = 0, lastApplied = nil, lastBase = nil, bound = false}
    local cameraBindName = "VortexionBloxThirdPerson_" .. tostring(LocalPlayer.UserId)
    local function restoreThirdPerson()
        if thirdPerson.bound then
            RunService:UnbindFromRenderStep(cameraBindName)
            thirdPerson.bound = false
        end
        local saved = thirdPerson.saved
        thirdPerson.saved = nil
        local cam = Workspace.CurrentCamera
        if cam and thirdPerson.lastBase and thirdPerson.lastApplied
            and cam.CFrame == thirdPerson.lastApplied then
            pcall(function() cam.CFrame = thirdPerson.lastBase end)
        end
        thirdPerson.lastApplied, thirdPerson.lastBase = nil, nil
        if not saved then return end
        pcall(function()
            LocalPlayer.CameraMaxZoomDistance = math.max(saved.maxZoom, saved.minZoom)
            LocalPlayer.CameraMinZoomDistance = saved.minZoom
            LocalPlayer.CameraMaxZoomDistance = saved.maxZoom
            LocalPlayer.CameraMode = saved.mode
        end)
    end
    local function updateThirdPerson()
        if not thirdPerson.enabled then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local observed = cam.CFrame
        -- If the native camera didn't update, never apply the offset twice.
        local base = observed
        if thirdPerson.lastApplied and observed == thirdPerson.lastApplied then
            base = thirdPerson.lastBase or observed
        end
        local d = math.clamp(thirdPerson.distance, 5, 24)
        local origin = base.Position
        local goal = origin - base.LookVector * d + Vector3.new(0, 1.3, 0)
        local filter = c.Character(LocalPlayer)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = filter and {filter} or {}
        params.IgnoreWater = true
        local hit = Workspace:Raycast(origin, goal-origin, params)
        if hit then goal = origin + (hit.Position-origin)*0.85 end
        local placed = CFrame.lookAt(goal, goal + base.LookVector)
        thirdPerson.lastBase, thirdPerson.lastApplied = base, placed
        cam.CFrame = placed
        thirdPerson.overrides += 1
    end
    local function setThirdPerson(enabled)
        enabled = enabled == true
        if not enabled then
            thirdPerson.enabled = false
            restoreThirdPerson()
            return
        end
        if not thirdPerson.saved then
            thirdPerson.saved = {
                mode = LocalPlayer.CameraMode,
                minZoom = LocalPlayer.CameraMinZoomDistance,
                maxZoom = LocalPlayer.CameraMaxZoomDistance,
            }
            -- One-time setup. The per-frame pass only changes the final CFrame.
            pcall(function() LocalPlayer.CameraMode = Enum.CameraMode.Classic end)
            pcall(function()
                LocalPlayer.CameraMaxZoomDistance = math.max(thirdPerson.distance, LocalPlayer.CameraMaxZoomDistance)
                LocalPlayer.CameraMinZoomDistance = math.min(thirdPerson.distance, LocalPlayer.CameraMaxZoomDistance)
            end)
        end
        thirdPerson.enabled = true
        if not thirdPerson.bound then
            RunService:BindToRenderStep(cameraBindName, Enum.RenderPriority.Last.Value + 5, function()
                if c.IsCurrent() then c.Guard("Visual.ThirdPerson", updateThirdPerson) end
            end)
            thirdPerson.bound = true
        end
    end
    c.OnCleanup(function() thirdPerson.enabled = false; restoreThirdPerson() end)
    local cameraChanged = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        thirdPerson.lastApplied, thirdPerson.lastBase = nil, nil
    end)
    c.OnCleanup(function() cameraChanged:Disconnect() end)

    local moveAccum = 0
    local espInterval = 0.25
    local espRefreshes = 0
    local function visualInterval()
        local base = Config.ESPOverlay and 0.08 or 0.25
        if c.VisualInterval then
            local ok, value = pcall(c.VisualInterval, base)
            if ok and type(value) == "number" and value == value and value > 0 then return math.max(base, value) end
        end
        return base
    end
    local function refreshESP()
        espRefreshes += 1
        espStats.refreshes = espRefreshes
        local ok, err = pcall(updateESP)
        if not ok then
            espStats.lastError = tostring(err):sub(1, 240)
            warn("[Vortexion/Blox/ESP] " .. espStats.lastError)
        end
    end
    local function cameraESPRebind()
        -- Native billboards track world parts independently of CurrentCamera.
        -- Never destroy/recreate every marker on a game camera replacement.
        espAccum = espInterval
    end
    local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraESPRebind)
    local frameConnection = RunService.Heartbeat:Connect(function(dt)
        if not c.IsCurrent() then return end
        -- Before enabling any feature, skip ALL camera, raycast, or movement
        -- calculations. The Heartbeat connection stays lightweight for toggles.
        if not Config.ESPEnabled and not Config.SpeedEnabled and not Config.FlyEnabled and not Config.Noclip and not thirdPerson.enabled then
            espAccum, moveAccum = 0, 0
            return
        end
        -- Third-person camera is bound at Camera+10, not polled on Heartbeat.
        -- Non-critical visual pacing is owned by the shared bridge (ctx.UI),
        -- re-read every frame so a VisualHz switch takes effect immediately.
        -- Movement, input and recovery paths below keep their original cadence.
        espInterval = visualInterval()
        espAccum += dt
        if Config.ESPEnabled and espAccum >= espInterval then
            espAccum = 0
            refreshESP()
        end
        moveAccum += dt
        if moveAccum >= 0.05 then
            moveAccum = 0
            if Config.SpeedEnabled and not Config.FlyEnabled then c.Guard("Visual.Speed", updateSpeed) end
            if Config.Noclip then c.Guard("Visual.Noclip", updateNoclip) end
        end
        if Config.FlyEnabled then c.Guard("Visual.Fly", updateFly) end
    end)
    c.OnCleanup(function() frameConnection:Disconnect() end)
    c.OnCleanup(function() pcall(function() cameraConnection:Disconnect() end) end)

    c.OnCleanup(function()
        Config.ESPEnabled = false
        Config.SpeedEnabled = false
        Config.FlyEnabled = false
        Config.Noclip = false
        clearESP()
        restoreSpeed()
        restoreFly()
        restoreNoclip()
        setLight(false)
        setThirdPerson(false)
    end)
    function Config:Status()
        return {
            markers = espStats.markers, scanned = espStats.scanned,
            eligible = espStats.eligible, refreshes = espStats.refreshes,
            noHumanoid = espStats.noHumanoid, error = espStats.lastError,
            creates = espStats.creates, writes = espStats.writes,
            renderer = Config.ESPOverlay and "Viewport2D+BillboardFallback" or "NativeBillboard",
            overlayCreates = overlayCreates, overlayDraws = overlayDraws,
            overlayParent = overlayGui ~= nil and overlayGui.Parent ~= nil,
            thirdPerson = thirdPerson.enabled, thirdOverrides = thirdPerson.overrides,
        }
    end
    function Config.ESPRefreshCount() return espRefreshes end
    function Config.ESPInterval() return espInterval end

    --=========================================================================
    -- UI.
    --=========================================================================
    local tab = c.Tabs.Visual
    tab:AddToggle("BloxESP", { Title = "原生穿墙 ESP（低负载）", Default = false, Callback = function(v)
        Config.ESPEnabled = v
        if v then startESP() else clearESP() end
    end })
    tab:AddToggle("BloxESP2D", { Title = "2D 屏幕 ESP（手机推荐）", Default = true,
        Callback = function(v)
            Config.ESPOverlay = v
            if overlayGui then overlayGui.Enabled = v and Config.ESPEnabled end
            if v then c.Guard("Visual.ESP2D", updateESP)
            else for _, entry in pairs(highlights) do hideOverlay(entry); entry.gui.Enabled = Config.ESPEnabled end end
        end })
    tab:AddToggle("BloxESPWorldHighlight", { Title = "额外启用 3D 高亮（性能消耗较高）", Default = false,
        Callback = function(v) Config.ESPWorldHighlight = v end })
    tab:AddToggle("BloxESPTeam", { Title = "仅显示敌方", Default = true, Callback = function(v)
        Config.ESPTeam = v
        c.Guard("Visual.ESP", updateESP)
    end })
    tab:AddSlider("BloxESPDistance", { Title = "ESP 距离", Min = 100, Max = 2000, Default = 500, Rounding = 0,
        Callback = function(v) Config.ESPDistance = v end })
    tab:AddToggle("BloxESPNames", { Title = "ESP 名称", Default = true, Callback = function(v) Config.ESPNames = v end })
    tab:AddToggle("BloxESPHealth", { Title = "ESP 血量", Default = true, Callback = function(v) Config.ESPHealth = v end })
    tab:AddToggle("BloxESPRange", { Title = "ESP 距离标签", Default = true, Callback = function(v) Config.ESPRange = v end })
    tab:AddToggle("BloxESPWeapon", { Title = "ESP 显示当前武器", Default = true, Callback = function(v) Config.ESPWeapon = v end })
    tab:AddToggle("BloxESPVisibility", { Title = "ESP 可见性配色（额外射线开销）", Default = false, Callback = function(v) Config.ESPVisibility = v end })
    tab:AddToggle("BloxESPBox", { Title = "ESP 穿墙原生方框", Default = true, Callback = function(v) Config.ESPBox = v end })
    tab:AddToggle("BloxESPTracer", { Title = "ESP 追踪线（需 Drawing）", Default = false, Callback = function(v) Config.ESPTracer = v end })
    tab:AddToggle("BloxFullbright", { Title = "全亮", Default = false, Callback = function(v)
        Config.Fullbright = v
        setLight(v)
    end })
    tab:AddButton({Title = "打印 ESP 目标诊断", Callback = function()
        local status = Config:Status()
        print(("[Vortexion/BloxESP] 开关=%s 玩家=%d 合格=%d 无Humanoid=%d 高亮=%d 刷新=%d 错误=%s")
            :format(tostring(Config.ESPEnabled), status.scanned, status.eligible,
                status.noHumanoid, status.markers, status.refreshes, status.error))
        print(("[Vortexion/BloxESP] 渲染=%s 2D创建=%d 2D绘制=%d 2D容器=%s")
            :format(status.renderer, status.overlayCreates, status.overlayDraws, tostring(status.overlayParent)))
    end})
    tab:AddParagraph({ Title = "视觉刷新节流",
        Content = "默认将目标投影到不拦截触控的 2D ScreenGui（独立于 3D Highlight 的可见性）；保留可切换的 BillboardGui 作为兼容兜底。2D 投影约 12Hz、目标文字约 3Hz，最多 24 个，关闭立即清理。" })

    local movement = c.Tabs.Movement
    movement:AddToggle("BloxThirdPerson", {Title = "第三人称视角", Default = false,
        Callback = setThirdPerson})
    movement:AddSlider("BloxThirdDistance", {Title = "第三人称镜头距离", Min = 5, Max = 24,
        Default = 12, Rounding = 0, Callback = function(value)
            thirdPerson.distance = value
            if thirdPerson.enabled then thirdPerson.lastApplied = nil end
        end})
    movement:AddParagraph({Title="第三人称说明", Content="启用后每帧于相机和战斗更新之后只偏移最终镜头，不再周期抢写 CameraMode；关闭后解绑并恢复。游戏强制镜头仍可能影响实际观感。"})
    movement:AddToggle("BloxSpeedEnabled", { Title = "自定义移动速度", Default = false, Callback = function(v)
        Config.SpeedEnabled = v
        if not v then restoreSpeed() end
    end })
    movement:AddSlider("BloxWalkSpeed", { Title = "移动速度", Min = 16, Max = 65, Default = 24, Rounding = 0,
        Callback = function(v)
            Config.SpeedValue = v
            if speedBackup and speedBackup.Parent then
                speedBackup.WalkSpeed = v
            end
        end })
    movement:AddToggle("BloxFlyEnabled", { Title = "飞行", Default = false, Callback = function(v)
        Config.FlyEnabled = v
        if v then restoreSpeed() else restoreFly() end
    end })
    movement:AddSlider("BloxFlySpeed", { Title = "飞行速度", Min = 20, Max = 200, Default = 60, Rounding = 0,
        Callback = function(v) Config.FlySpeed = v end })
    movement:AddToggle("BloxTouchFly", { Title = "触屏拖动飞行", Default = true, Callback = function(v)
        Config.TouchFly = v
    end })
    movement:AddToggle("BloxNoclip", { Title = "穿墙", Default = false, Callback = function(v)
        Config.Noclip = v
        if not v then restoreNoclip() end
    end })
    movement:AddParagraph({ Title = "移动兼容性",
        Content = "速度与穿墙按 20Hz 更新；飞行优先于速度并逐帧更新。关闭与重生恢复原始属性；右半屏未被界面消费的拖动控制飞行，两指控制升降。" })

    return Config
end

end)()
local BloxCosmeticFactory = (function()
-- BloxStrike camera appearance, capability-based local previews.
return function(c)
    local tab,knifeTab=c.Tabs.Appearance,c.Tabs.Knife
    local state={enabled=false,selected={},wear="Factory New",knife=false,knifeName="Butterfly Knife",touchButtons=false,gloveMode="自动",sleeves=true}
    local original={}
    local applied={}
    local dirty = false
    local reconcileKnife
    local knifeSource, knifeCamera
    local cameraConnection
    local stopNative, tryNative, updateNative
    local nativeTrack, nativeMode, nativeStarted
    local actionSerial, swingIndex = 0, 0
    local stopKnifeSounds, destroyAttachments, refreshButtons, destroyButtons, knifeApi
    -- Procedural local preview state: pose animation, one-shot sounds, arm attachments.
    local anim={mode="idle",started=0,duration=0}
    local activeSounds={}
    local attached={}
    local buttonGui, inspectButton, swingButton, stopButton
    local ANIM={equip=0.35,inspect=1.1,swing=0.28}
    local supportedKnives={"Butterfly Knife","Karambit","M9 Bayonet","Flip Knife","Gut Knife"}
    local knifeOffsets={
        ["Butterfly Knife"]=CFrame.new(0,-1.5,1.5),Karambit=CFrame.new(0,-1.5,1.5),
        ["M9 Bayonet"]=CFrame.new(0,-1.5,1),["Flip Knife"]=CFrame.new(0,-1.5,1.25),
        ["Gut Knife"]=CFrame.new(0,-1.5,0.5)
    }
    local knifeModel
    local hidden={}
    local knifeFollow
    local function roots()
        local assets=c.ReplicatedStorage:FindFirstChild("Assets")
        return assets,assets and assets:FindFirstChild("Skins")
    end
    -- Find a native view-model animation for a preview mode without loading it:
    -- hop-by-hop pcall lookups only, returns (animator,animation) or nil. Never
    -- creates a controller/animator, never waits, never loads the animation.
    local function findNativeAnimation(model,mode)
        if mode~="Equip" and mode~="Idle" and mode~="Inspect" and mode~="Heavy Swing" and mode~="Swing1" and mode~="Swing2" then return nil end
        if not c.IsCurrent() then return nil end
        if not model or not model.Parent then return nil end
        if model~=knifeModel then return nil end
        local animation
        local ok=pcall(function()
            local assets=c.ReplicatedStorage:FindFirstChild("Assets")
            local weaponAnimations=assets and assets:FindFirstChild("WeaponAnimations")
            local perKnife=weaponAnimations and weaponAnimations:FindFirstChild(state.knifeName)
            local cameraAnimations=perKnife and perKnife:FindFirstChild("CameraAnimations")
            animation=cameraAnimations and cameraAnimations:FindFirstChild(mode)
            if not (animation and animation:IsA("Animation")) then animation=nil end
        end)
        if not ok or not animation then return nil end
        local animator
        ok=pcall(function()
            animator=model:FindFirstChildWhichIsA("Animator",true)
            if not (animator and animator:IsA("Animator") and animator.Parent) then animator=nil end
        end)
        if not ok or not animator then return nil end
        if not c.IsCurrent() or model~=knifeModel or not model or not model.Parent then return nil end
        return animator,animation
    end
    local function restoreParts()
        for part,data in pairs(original) do
            if applied[part] then applied[part]:Destroy(); applied[part]=nil end
            if data and data.Parent==nil then
                if part and part.Parent then data.Parent=part else data:Destroy() end
            end
            original[part]=nil
        end
    end
    local function restoreKnife()
        knifeSource, knifeCamera = nil, nil
        actionSerial += 1
        if stopNative then stopNative() end
        if knifeModel then knifeModel:Destroy();knifeModel=nil end
        if stopKnifeSounds then stopKnifeSounds() end
        if destroyAttachments then destroyAttachments() end
        anim.mode="idle"
        if refreshButtons then refreshButtons() end
        for part,transparency in pairs(hidden) do
            if part and part.Parent then part.Transparency=transparency end
            hidden[part]=nil
        end
    end
    -- One-shot knife sounds: clone ReplicatedStorage/Sounds/<knife>/<folder>/<index>,
    -- parent under the view model, reclaim on Ended, on a bounded lifetime, or on any
    -- teardown path (disable/respawn/camera/cleanup).
    local SOUND_MAX_LIFETIME=5
    local previewSpeed,previewVolume=1,1
    local soundConnections={}
    local function disposeSound(sound)
        local connection=soundConnections[sound]
        local owned=activeSounds[sound]~=nil or connection~=nil
        activeSounds[sound],soundConnections[sound]=nil,nil
        if connection then pcall(function() connection:Disconnect() end) end
        if owned then pcall(function() sound:Destroy() end) end
    end
    local function playKnifeSound(folder,index)
        if not knifeModel then return nil end
        local sounds,perKnife,group,template
        local ok=pcall(function()
            sounds=c.ReplicatedStorage:FindFirstChild("Sounds")
            perKnife=sounds and sounds:FindFirstChild(state.knifeName)
            group=perKnife and perKnife:FindFirstChild(folder)
            template=group and group:FindFirstChild(index or "1")
        end)
        if not ok or not template then return nil end
        local clone
        local ok=pcall(function()
            clone=template:Clone()
            clone.Name=c.RandomName()
            clone.Parent=knifeModel
            if previewVolume~=1 and type(previewVolume)=="number" and previewVolume==previewVolume then
                local vol=tonumber(clone.Volume)
                if vol then clone.Volume=math.clamp(vol*previewVolume,0,10) end
            end
            clone:Play()
        end)
        if not ok or not clone then
            if clone then pcall(function() clone:Destroy() end) end
            return nil
        end
        activeSounds[clone]=tick()
        local connected,connection=pcall(function()
            local ended=clone.Ended
            if ended and type(ended.Connect)=="function" then
                return ended:Connect(function() disposeSound(clone) end)
            end
        end)
        if connected and connection then
            if activeSounds[clone]~=nil then soundConnections[clone]=connection
            else pcall(function() connection:Disconnect() end) end
        end
        return clone
    end
    -- A missing Ended capability still has a bounded lifetime.
    local function reclaimSounds(maxAge)
        for sound,born in pairs(activeSounds) do
            local ok,parent=pcall(function() return sound.Parent end)
            if not ok or not parent or tick()-born>=(maxAge or SOUND_MAX_LIFETIME) then
                disposeSound(sound)
            end
        end
    end
    function stopKnifeSounds()
        for sound in pairs(activeSounds) do disposeSound(sound) end
        for sound in pairs(soundConnections) do disposeSound(sound) end
    end
    -- Motor6D needs real BaseParts on both sides; a Model exposes PrimaryPart, a
    -- BasePart does not, so never read PrimaryPart unconditionally.
    local function firstBasePart(inst)
        if not inst then return nil end
        if inst:IsA("BasePart") then return inst end
        if inst:IsA("Model") then
            local primary=inst.PrimaryPart
            if primary and primary:IsA("BasePart") then return primary end
            return inst:FindFirstChildWhichIsA("BasePart",true)
        end
        return nil
    end
    -- Glove / sleeve attachment: clone the arm asset onto the view model arms with a
    -- Motor6D. Missing assets are skipped silently instead of fabricating ids, and a
    -- half-finished clone/motor pair is rolled back before anything is committed.
    local function attachArmAsset(folder,armName,assetName,offset)
        if not knifeModel or not folder then return nil end
        local arm=firstBasePart(knifeModel:FindFirstChild(armName,true))
        if not arm then return nil end
        local template=folder:FindFirstChild(assetName)
        if not template then return nil end
        local clone,motor
        local ok=pcall(function()
            clone=template:Clone()
            clone.Name=c.RandomName()
            clone.Parent=arm
            motor=Instance.new("Motor6D")
            motor.Name=c.RandomName()
            motor.Part0=arm
            motor.Part1=firstBasePart(clone)
            motor.C0=offset
            motor.Parent=arm
        end)
        if not ok or not clone or not motor then
            if motor then motor:Destroy() end
            if clone then clone:Destroy() end
            return nil
        end
        attached[clone]=true
        attached[motor]=true
        return clone
    end
    local function attachGloves()
        if not knifeModel then return end
        local living=c.Living(c.LocalPlayer)
        if not living then return end
        local assets=c.ReplicatedStorage:FindFirstChild("Assets")
        local weapons=assets and assets:FindFirstChild("Weapons")
        local sleeves=assets and assets:FindFirstChild("Sleeves")
        -- Glove source: 自动 follows the live team, T/CT force that branch, 不附着
        -- attaches nothing; any unrecognized value falls back to 自动, never invented.
        local mode=state.gloveMode
        if mode~="T Glove" and mode~="CT Glove" and mode~="不附着" then
            mode=living.Parent and living.Parent.Name=="Terrorists" and "T Glove" or "CT Glove"
        end
        if mode=="不附着" then return end
        local gloveOffset=CFrame.new(0,0,-1.5)
        local sleeveOffset=CFrame.new(0,0,0.5)
        if mode=="T Glove" then
            local gloves=weapons and weapons:FindFirstChild("T Glove")
            attachArmAsset(gloves,"Left Arm","Left Arm",gloveOffset)
            attachArmAsset(gloves,"Right Arm","Right Arm",gloveOffset)
        else
            local ctGloves=weapons and weapons:FindFirstChild("CT Glove")
            local sleeve=state.sleeves and sleeves and sleeves:FindFirstChild("IDF")
            attachArmAsset(sleeve,"Left Arm","Left Arm",sleeveOffset)
            attachArmAsset(ctGloves,"Left Arm","Left Arm",gloveOffset)
            attachArmAsset(sleeve,"Right Arm","Right Arm",sleeveOffset)
            attachArmAsset(ctGloves,"Right Arm","Right Arm",gloveOffset)
        end
    end
    function destroyAttachments()
        for obj in pairs(attached) do
            if obj then obj:Destroy() end
            attached[obj]=nil
        end
    end
    -- Own only tracks and rig changes on the disposable camera clone.
    local nativeSerial, nativeRig = 0, {}
    local function disposeNative(track)
        if track then
            pcall(function() track:Stop(0) end)
            pcall(function() track:Destroy() end)
        end
    end
    stopNative = function()
        nativeSerial += 1
        local track, rig = nativeTrack, nativeRig
        nativeTrack, nativeMode, nativeStarted, nativeRig = nil, nil, nil, {}
        disposeNative(track)
        for object, saved in pairs(rig) do
            pcall(function()
                if object.Parent then
                    if saved.transform then object.Transform = saved.transform
                    else object.Anchored = saved.anchored end
                end
            end)
        end
    end
    tryNative = function(name)
        local model = knifeModel
        stopNative()
        local serial = nativeSerial
        local animator, animation = findNativeAnimation(model, name)
        if not animator then return false end
        local function current()
            local ok, value = pcall(function()
                return c.IsCurrent() and state.knife and serial == nativeSerial and model == knifeModel
                    and model.Parent == knifeCamera and knifeCamera == c.Workspace.CurrentCamera
                    and animator:IsDescendantOf(model)
            end)
            return ok and value == true
        end
        local track
        local loaded = pcall(function() track = animator:LoadAnimation(animation) end)
        if not loaded or not track or not current() then disposeNative(track); return false end
        local prepared = pcall(function()
            for _, joint in ipairs(model:GetDescendants()) do
                if joint:IsA("Motor6D") then
                    nativeRig[joint] = {transform = joint.Transform}
                    local part = joint.Part1
                    if part and part ~= model.PrimaryPart and part:IsDescendantOf(model) then
                        if not nativeRig[part] then nativeRig[part] = {anchored = part.Anchored} end
                        part.Anchored = false
                    end
                end
            end
        end)
        if not prepared or not current() then
            if serial == nativeSerial then stopNative() end
            disposeNative(track)
            return false
        end
        nativeTrack, nativeMode, nativeStarted = track, name, tick()
        local played = pcall(function()
            track.Looped = name == "Idle"
            track:Play(0.05, 1, previewSpeed)
        end)
        if not played or not current() or nativeTrack ~= track then
            if nativeTrack == track then stopNative() else disposeNative(track) end
            return false
        end
        return true
    end
    updateNative = function()
        if not nativeTrack then return false end
        local playing, age = false, tick() - nativeStarted
        local ok = pcall(function() playing = nativeTrack.IsPlaying end)
        if not ok or (not playing and age >= 0.1) or (nativeMode ~= "Idle" and age >= 30) then
            local wasIdle = nativeMode == "Idle"
            stopNative()
            anim.mode = "idle"
            if not wasIdle then tryNative("Idle") end
        end
        return nativeTrack ~= nil
    end

    -- Procedural preview poses: local-only motion derived from tick(), never presented
    -- as the original animation set. Idle keeps the previous static offset exactly.
    local function startAnim(mode,duration,nativeName)
        actionSerial += 1
        local request, model = actionSerial, knifeModel
        anim.mode=mode
        anim.started=tick()
        local speed=previewSpeed
        if type(speed)~="number" or speed~=speed or not (speed>0 and speed<math.huge) then speed=1 end
        anim.duration=(duration or ANIM[mode] or 0)/math.clamp(speed,0.25,2)
        if not nativeName then
            if mode=="swing" then swingIndex=swingIndex%2+1; nativeName="Swing"..swingIndex
            else nativeName=mode=="equip" and "Equip" or "Inspect" end
        end
        tryNative(nativeName)
        return request==actionSerial and model==knifeModel and c.IsCurrent()
    end
    local function knifePose()
        local base=knifeOffsets[state.knifeName] or CFrame.new(0,-1.5,1.5)
        if nativeTrack or anim.mode=="idle" or anim.duration<=0 then return base end
        local t=tick()-anim.started
        if t>=anim.duration then return base end
        local k=t/anim.duration
        local p=base.Position
        if anim.mode=="equip" then
            local ease=1-(1-k)*(1-k)*(1-k)
            local from=CFrame.new(0,-1.9,0.9).Position
            return CFrame.new(from.X+(p.X-from.X)*ease,from.Y+(p.Y-from.Y)*ease,from.Z+(p.Z-from.Z)*ease)
        elseif anim.mode=="inspect" then
            local wave=math.sin(k*math.pi*2)
            local tilt=math.sin(k*math.pi*4)
            return CFrame.new(p.X+0.12*wave,p.Y+0.06*tilt,p.Z+0.05*math.sin(k*math.pi*2+1.5708))
        end
        local arc=math.sin(k*math.pi)
        return CFrame.new(p.X,p.Y-0.55*arc,p.Z+0.35*arc)
    end
    -- Touch actions: real production callbacks, built only when a touch device and a
    -- permissioned GUI parent exist; otherwise the buttons are simply not created.
    local function makeButton(parent,text,onClick)
        local btn=Instance.new("TextButton")
        btn.Name=c.RandomName()
        btn.Text=text
        btn.Size=UDim2.new(0,110,0,44)
        btn.Parent=parent
        local conn=btn.MouseButton1Click or btn.Activated
        if conn then pcall(function()conn:Connect(onClick) end) end
        return btn
    end
    local function buildButtons()
        if buttonGui or not state.touchButtons or not knifeModel then return end
        if not (c.Touch and c.Touch.Enabled) then return end
        local parent=c.GetGuiParent and c.GetGuiParent()
        if not parent then return end
        local gui,inspect,swing,stop
        local ok=pcall(function()
            gui=Instance.new("ScreenGui")
            gui.Name=c.RandomName()
            gui.Parent=parent
            inspect=makeButton(gui,"Inspect",function()knifeApi.Inspect() end)
            swing=makeButton(gui,"Swing",function()knifeApi.Swing() end)
            stop=makeButton(gui,"Stop",function()knifeApi.Stop() end)
            inspect.Position=UDim2.new(0,12,1,-56)
            swing.Position=UDim2.new(0,130,1,-56)
            stop.Position=UDim2.new(0,248,1,-56)
        end)
        if not ok or not gui or not inspect or not swing or not stop then
            if gui then gui:Destroy() end
            return
        end
        buttonGui=gui
        inspectButton,swingButton,stopButton=inspect,swing,stop
    end
    function refreshButtons()
        if state.touchButtons and knifeModel then
            buildButtons()
        elseif buttonGui then
            destroyButtons()
        end
    end
    function destroyButtons()
        if buttonGui then buttonGui:Destroy();buttonGui=nil end
        inspectButton,swingButton,stopButton=nil,nil,nil
    end
    knifeApi={
        Inspect=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("inspect",ANIM.inspect) then return false end
            playKnifeSound("Inspect","1")
            return true
        end,
        Swing=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("swing",ANIM.swing) then return false end
            local roll=math.random(2,3)
            playKnifeSound(roll==2 and "HitTwo" or "HitThree","1")
            return true
        end,
        HeavySwing=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("swing",ANIM.swing,"Heavy Swing") then return false end
            playKnifeSound("HitThree","1")
            return true
        end,
        Stop=function()
            actionSerial += 1
            stopNative()
            stopKnifeSounds()
            anim.mode="idle"
            return true
        end,
        State=function()return anim.mode,knifeModel~=nil,next(activeSounds)~=nil end,
    }
    local function applySurface(part,source)
        if not part:IsA("BasePart") then return end
        local texture=source
        if source and not source:IsA("SurfaceAppearance") then
            texture=source:FindFirstChildOfClass("SurfaceAppearance")
        end
        if not texture then return end
        if original[part]==nil then
            local old=part:FindFirstChildOfClass("SurfaceAppearance")
            original[part]=old or false
            if old then old.Parent=nil end
        end
        if applied[part] then applied[part]:Destroy();applied[part]=nil end
        local clone=texture:Clone()
        clone.Name=c.RandomName()
        clone.Parent=part
        if c.Cloak then clone=c.Cloak.Protect(clone) end
        applied[part]=clone
    end
    local function applyModel(model, categoryName)
        if not state.enabled or not model or not model:IsA("Model") then return end
        local _,skins=roots()
        if not skins then return end
        local gloveCategory = skins:FindFirstChild("Sports Gloves")
        local gloveSkin = gloveCategory and gloveCategory:FindFirstChild(state.selected["Sports Gloves"] or "")
        local gloveCamera = gloveSkin and gloveSkin:FindFirstChild("Camera")
        local gloveWear = gloveCamera and (gloveCamera:FindFirstChild(state.wear) or gloveCamera:FindFirstChild("Factory New"))
        if gloveWear then
            for _, side in ipairs({"Left Arm", "Right Arm"}) do
                local arm = model:FindFirstChild(side, true)
                local glove = arm and arm:FindFirstChild("Glove", true)
                local source = gloveWear:FindFirstChild(side)
                if glove and source then applySurface(glove, source) end
            end
        end
        categoryName = categoryName or model.Name
        local selectedName=state.selected[categoryName]
        if not selectedName then return end
        local category=skins:FindFirstChild(categoryName)
        local skin=category and category:FindFirstChild(selectedName)
        local camera=skin and skin:FindFirstChild("Camera")
        local source=camera and (camera:FindFirstChild(state.wear) or camera:FindFirstChild("Factory New"))
        if not source then return end
        local weapon=model:FindFirstChild("Weapon")
        if not weapon then weapon=model end
        for _,part in ipairs(weapon:GetDescendants()) do
            if part:IsA("BasePart") then
                local match=source:FindFirstChild(part.Name)
                if match then applySurface(part,match) end
            end
        end
    end
    local function updateCamera()
        restoreParts()
        if not state.enabled then return end
        local camera=c.Workspace.CurrentCamera
        if camera then
            for _,model in ipairs(camera:GetChildren()) do
                applyModel(model, model == knifeModel and state.knifeName or nil)
            end
        end
    end
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
        local camera=c.Workspace.CurrentCamera
        if camera then
            cameraConnection=camera.ChildAdded:Connect(function(model)
                if c.IsCurrent() and model ~= knifeModel then dirty = true end
            end)
        end
    end
    local skinEnabledOption = tab:AddToggle("BloxSkinEnabled",{Title="启用本地皮肤替换",Default=false,Callback=function(v)
        state.enabled=v
        updateCamera()
        dirty = true
        watchCamera()
    end})
    tab:AddDropdown("BloxSkinWear",{Title="磨损版本",Values={"Factory New","Minimal Wear","Field-Tested","Well-Worn","Battle-Scarred"},
        Default="Factory New",Callback=function(v)state.wear=v;updateCamera() end})
    local created, usedIds = {}, {}
    local skinFolderConn, resourcesConn
    local refreshing, queuedRefresh = false, false
    local function skinValues(category)
        local values = {}
        for _, skin in ipairs(category:GetChildren()) do
            if skin:IsA("Folder") or skin:IsA("Model") then table.insert(values, skin.Name) end
        end
        table.sort(values)
        return values
    end
    local function addCategory(category)
        if not c.IsCurrent() or not category or not category:IsA("Folder") then return false end
        local values = skinValues(category)
        if #values == 0 then return false end
        local categoryName = category.Name
        local existing = created[categoryName]
        if existing then
            -- Newly replicated skins extend the current dropdown in place.
            if existing.option and type(existing.option.SetValues) == "function" then
                local changed = #existing.values ~= #values
                if not changed then
                    for i, v in ipairs(values) do
                        if existing.values[i] ~= v then changed = true; break end
                    end
                end
                if changed then
                    local ok = pcall(function() existing.option:SetValues(values) end)
                    if ok then existing.values = values end
                end
            end
            return false
        end
        local optionId = "BloxSkin_" .. categoryName:gsub("[^%w]", "_")
        if usedIds[optionId] and usedIds[optionId] ~= categoryName then
            local suffix = ""
            for i = 1, #categoryName do suffix ..= ("%02x"):format(categoryName:byte(i)) end
            optionId ..= "_" .. suffix
        end
        local default = state.selected[categoryName]
        if not default or not table.find(values, default) then default = values[1] end
        local targetTab = tab
        if categoryName:find("Knife") or categoryName:find("Glove") or categoryName == "Karambit" then
            targetTab = knifeTab
        end
        -- Reserve id before creating the native option; restore on exception so refresh can retry.
        created[categoryName] = {values = values}
        local ok, option = pcall(function()
            return targetTab:AddDropdown(optionId, {Title = categoryName .. " · 皮肤", Values = values,
                Default = default, Callback = function(v)
                    state.selected[categoryName] = v
                    if state.enabled then updateCamera() end
                end})
        end)
        if not ok or not option then
            created[categoryName] = nil
            warn("[Vortexion/BloxStrike] skin dropdown " .. categoryName .. ": " .. tostring(option))
            return false
        end
        created[categoryName].option = option
        usedIds[optionId] = categoryName
        state.selected[categoryName] = default
        return true
    end
    local createSkinControls
    local function queueSkinRefresh()
        if queuedRefresh or not c.IsCurrent() then return end
        queuedRefresh = true
        task.defer(function()
            queuedRefresh = false
            if c.IsCurrent() and createSkinControls then createSkinControls(false) end
        end)
    end
    createSkinControls = function(manual)
        if not c.IsCurrent() or refreshing then return end
        local _, skins = roots()
        if not skins then
            if manual then c.Notify("皮肤资源", "Assets/Skins 尚未加载，正在等待资源出现") end
            return
        end
        refreshing = true
        local list = skins:GetChildren()
        table.sort(list, function(a, b) return a.Name < b.Name end)
        local createdCount = 0
        -- Bound startup UI allocation on mobile. Remaining categories can
        -- still be loaded manually after the current batch completes.
        local addedThisPass = 0
        local maxPerPass = manual and 64 or 24
        for _, category in ipairs(list) do
            if not c.IsCurrent() or addedThisPass >= maxPerPass then break end
            if addCategory(category) then
                createdCount += 1
                addedThisPass += 1
                -- Keep each frame below the UI allocation budget.
                if addedThisPass % 2 == 0 then task.wait() end
            end
        end
        refreshing = false
        if skinFolderConn then skinFolderConn:Disconnect(); skinFolderConn = nil end
        if skins.DescendantAdded then
            skinFolderConn = skins.DescendantAdded:Connect(queueSkinRefresh)
        else
            skinFolderConn = skins.ChildAdded:Connect(queueSkinRefresh)
        end
        if manual and c.IsCurrent() then
            c.Notify("皮肤菜单", ("当前 %d 个分类，新增 %d 个控件"):format(#list, createdCount))
        end
    end
    -- No busy polling: react only when Assets/Skins is replicated or its children change.
    if c.ReplicatedStorage.DescendantAdded then
        resourcesConn = c.ReplicatedStorage.DescendantAdded:Connect(function(obj)
            if obj.Name == "Skins" or (obj.Parent and obj.Parent.Name == "Skins") then
                queueSkinRefresh()
            end
        end)
    else
        resourcesConn = c.ReplicatedStorage.ChildAdded:Connect(queueSkinRefresh)
    end
    tab:AddButton({Title="刷新皮肤分类与下拉框",Callback=function()
        task.spawn(function() createSkinControls(true) end)
    end})
    tab:AddButton({Title="查看皮肤资源状态",Callback=function()
        local assets, skins = roots()
        local total = skins and #skins:GetChildren() or 0
        local selectors = 0
        for _ in pairs(created) do selectors += 1 end
        c.Notify("皮肤资源状态", ("Assets=%s · Skins=%s · 分类=%d · 控件=%d"):format(
            assets and "就绪" or "缺失", skins and "就绪" or "缺失", total, selectors))
    end})
    tab:AddButton({Title="恢复默认皮肤",Callback=function()
        -- Synchronize the visible toggle and the internal state (avoids stale UI).
        if skinEnabledOption and type(skinEnabledOption.SetValue) == "function" then
            skinEnabledOption:SetValue(false)
        else
            state.enabled = false
        end
        restoreParts()
        c.Notify("已恢复","本地已修改的材质已撤销")
    end})
    reconcileKnife = function()
        local cam = c.Workspace.CurrentCamera
        local old = cam and (cam:FindFirstChild("T Knife") or cam:FindFirstChild("CT Knife"))
        local living = c.Living(c.LocalPlayer)
        if not state.knife or not cam or not old or not living then
            if knifeModel then restoreParts(); restoreKnife() end
            return
        end
        if knifeModel and knifeSource == old and knifeCamera == cam then return end
        restoreParts()
        restoreKnife()
        local assets = c.ReplicatedStorage:FindFirstChild("Assets")
        local weapons = assets and assets:FindFirstChild("Weapons")
        local template = weapons and weapons:FindFirstChild(state.knifeName)
        local cameraModel = template and template:FindFirstChild("Camera")
        if not cameraModel then return end
        local clone = cameraModel:Clone()
        clone.Name = c.RandomName()
        if not clone.PrimaryPart then clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true) end
        if not clone.PrimaryPart then clone:Destroy(); return end
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.Anchored=true
            end
        end
        knifeModel, knifeSource, knifeCamera = clone, old, cam
        clone.Parent = cam
        if c.Cloak then c.Cloak.Protect(clone) end
        for _, part in ipairs(old:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Texture") then
                hidden[part]=part.Transparency; part.Transparency=1
            end
        end
        attachGloves()
        if not startAnim("equip",ANIM.equip) then return end
        playKnifeSound("Equip","1")
        refreshButtons()
        dirty = true
    end
    -- Local preview only: no weapon hooks, raycasts or remote calls.
    local TRAIL_LIFETIME, TRAIL_LIMIT = 0.5, 32
    local trailEnabled, trailStopped = false, false
    local trailColor = Color3.new(1, 1, 1)
    local trailEntries = {}
    local function removeTrail(index)
        local entry = trailEntries[index]
        if not entry then return end
        table.remove(trailEntries, index)
        local part = entry.part
        entry.part = nil
        if part then pcall(function() part:Destroy() end) end
    end
    local function clearTrailPreview()
        while #trailEntries > 0 do removeTrail(#trailEntries) end
    end
    local function finiteTrailNumber(n)
        return type(n) == "number" and n == n and math.abs(n) < math.huge
    end
    local function validTrailVector(v)
        return typeof(v) == "Vector3" and finiteTrailNumber(v.X) and finiteTrailNumber(v.Y) and finiteTrailNumber(v.Z)
    end
    local function previewTrail()
        if trailStopped or not trailEnabled or not c.IsCurrent() then return false end
        local camera = c.Workspace.CurrentCamera
        if not camera then return false end
        local ok, origin, direction = pcall(function() return camera.CFrame.Position, camera.CFrame.LookVector end)
        if not ok or not validTrailVector(origin) or not validTrailVector(direction) then return false end
        local magnitude = direction.Magnitude
        if not finiteTrailNumber(magnitude) or magnitude < 0.000001 then return false end
        direction = direction / magnitude
        origin = origin + direction * 2
        if #trailEntries >= TRAIL_LIMIT then removeTrail(1) end
        if #trailEntries >= TRAIL_LIMIT or trailStopped or not trailEnabled or not c.IsCurrent() then return false end
        local entry = {camera = camera, born = tick()}
        local success, committed = pcall(function()
            local part = Instance.new("Part")
            entry.part = part
            table.insert(trailEntries, entry)
            if trailStopped or not trailEnabled or not c.IsCurrent() or camera ~= c.Workspace.CurrentCamera then return false end
            part.Name = "VortexionTrailPreview"
            part.Anchored = true
            part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = false, false, false, false
            part.Material, part.Color, part.Transparency = Enum.Material.Neon, trailColor, 0
            part.Size = Vector3.new(0.1, 0.1, 50)
            local midpoint = origin + direction * 25
            part.CFrame = CFrame.lookAt(midpoint, midpoint + direction)
            if not entry.part or trailStopped or not trailEnabled or not c.IsCurrent() or camera ~= c.Workspace.CurrentCamera then return false end
            part.Parent = camera
            return entry.part == part and not trailStopped and trailEnabled and c.IsCurrent() and camera == c.Workspace.CurrentCamera and part.Parent == camera
        end)
        if not success or not committed then
            for i = #trailEntries, 1, -1 do if trailEntries[i] == entry then removeTrail(i); break end end
            return false
        end
        return true
    end
    local function updateTrailPreview()
        if #trailEntries == 0 then return end
        if trailStopped or not trailEnabled or not c.IsCurrent() then clearTrailPreview(); return end
        local now, camera = tick(), c.Workspace.CurrentCamera
        for i = #trailEntries, 1, -1 do
            local entry = trailEntries[i]
            if entry then
                local age = now - entry.born
                if age >= TRAIL_LIFETIME or age < 0 or camera ~= entry.camera then
                    removeTrail(i)
                else
                    local updated, kept = pcall(function()
                        local part = entry.part
                        if not part or part.Parent ~= entry.camera then return false end
                        local fade = (1 - age / TRAIL_LIFETIME) ^ 2
                        part.Transparency = 1 - fade
                        part.Size = Vector3.new(0.1 * fade, 0.1 * fade, 50)
                        return true
                    end)
                    if not updated or not kept then removeTrail(i) end
                end
            end
        end
    end
    tab:AddToggle("BloxTrailPreview", {Title = "本地拖尾预览", Default = false, Callback = function(v)
        if trailStopped or not c.IsCurrent() then return end
        trailEnabled = v == true
        if not trailEnabled then clearTrailPreview() end
    end})
    tab:AddColorpicker("BloxTrailPreviewColor", {Title = "预览拖尾颜色", Default = trailColor, Callback = function(v)
        if trailStopped or not c.IsCurrent() or typeof(v) ~= "Color3" then return end
        local r, g, b = v.R, v.G, v.B
        if not finiteTrailNumber(r) or not finiteTrailNumber(g) or not finiteTrailNumber(b) or r < 0 or r > 1 or g < 0 or g > 1 or b < 0 or b > 1 then return end
        trailColor = v
    end})
    tab:AddButton({Title = "预览本地拖尾", Callback = previewTrail})
    tab:AddParagraph({Title = "拖尾预览范围", Content = "先开启预览，再点击按钮显示50 studs本地拖尾，0.5秒消退。仅手动预览，不连接真实开火、命中重写或网络事件。"})
    knifeTab:AddToggle("BloxCustomKnife",{Title="启用本地刀具模型",Default=false,Callback=function(v)
        state.knife=v
        if not v then restoreParts(); restoreKnife() end
        reconcileKnife()
        updateCamera()
    end})
    knifeTab:AddDropdown("BloxKnifeType",{Title="自定义刀具",Values=supportedKnives,
        Default="Butterfly Knife",Callback=function(v)
            state.knifeName=v
            if state.knife then
                restoreParts(); restoreKnife()
                reconcileKnife(); updateCamera()
            end
        end})
    knifeTab:AddToggle("BloxKnifeTouch",{Title="触屏刀具动作按钮",Default=false,Callback=function(v)
        state.touchButtons=v
        refreshButtons()
        c.Notify("刀具按钮",v and "触屏检视/挥动按钮已开启" or "触屏刀具按钮已关闭")
    end})
    knifeTab:AddSlider("BloxKnifePreviewSpeed",{Title="预览速度 %",Min=25,Max=200,Default=100,Callback=function(v)
        if not c.IsCurrent() then return end
        local n=tonumber(v)
        previewSpeed=(type(n)=="number" and n==n and n~=math.huge and n~=-math.huge and n>0) and math.clamp(n,25,200)/100 or 1
    end})
    knifeTab:AddSlider("BloxKnifeSoundVolume",{Title="音效音量 %",Min=0,Max=100,Default=100,Callback=function(v)
        if not c.IsCurrent() then return end
        local n=tonumber(v)
        previewVolume=(type(n)=="number" and n==n and n~=math.huge and n~=-math.huge and n>=0) and math.clamp(n,0,100)/100 or 1
    end})
    knifeTab:AddDropdown("BloxKnifeGloveMode",{Title="本地手套来源",Values={"自动","T Glove","CT Glove","不附着"},
        Default="自动",Callback=function(v)
            if not c.IsCurrent() then return end
            local mode=(v=="T Glove" or v=="CT Glove" or v=="不附着") and v or "自动"
            if state.gloveMode==mode then return end
            state.gloveMode=mode
            if knifeModel then destroyAttachments();if c.IsCurrent() and knifeModel then attachGloves() end end
        end})
    knifeTab:AddToggle("BloxKnifeSleeves",{Title="袖套开关（仅 CT 有效）",Default=true,Callback=function(v)
        if not c.IsCurrent() then return end
        local enabled=v==true
        if state.sleeves==enabled then return end
        state.sleeves=enabled
        if knifeModel then destroyAttachments();if c.IsCurrent() and knifeModel then attachGloves() end end
    end})
    knifeTab:AddButton({Title="刀具检视动画",Callback=function()knifeApi.Inspect() end})
    knifeTab:AddButton({Title="刀具挥动动画",Callback=function()knifeApi.Swing() end})
    knifeTab:AddButton({Title="刀具重挥动画",Callback=function()knifeApi.HeavySwing() end})
    knifeTab:AddButton({Title="停止动画与声音",Callback=function()knifeApi.Stop() end})
    knifeTab:AddParagraph({Title="刀具预览说明",
        Content="优先读取 Assets/WeaponAnimations/<刀具>/CameraAnimations 的 Equip、Idle、Inspect、Heavy Swing、Swing1、Swing2，只在本地模型自带 Animator 时播放；缺资源或加载失败则降级为程序式姿态。速度用于下一次本地预览，停止同时回收动画与声音。声音及手套/袖套按实际存在的资源使用；这些选项不修改服务器伤害、库存或游戏全局动画设置。"})
    knifeTab:AddParagraph({Title="外观规则",
        Content="皮肤由游戏 Assets/Skins 目录生成选择项。武器材质和刀具只作客户端视觉更改，不更改库存或服务器伤害。"})
    watchCamera()
    local cameraChanged = c.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        clearTrailPreview(); restoreParts(); restoreKnife(); watchCamera(); dirty = true
    end)
    local elapsed = 0
    knifeFollow = c.RunService.RenderStepped:Connect(function(dt)
        if not c.IsCurrent() then clearTrailPreview(); return end
        -- Avoid allocations, effects and camera work while appearance is off.
        if not state.enabled and not state.knife and not knifeModel and next(activeSounds)==nil and anim.mode=="idle" and #trailEntries==0 then
            elapsed=0
            return
        end
        updateTrailPreview()
        if not state.enabled and not state.knife and not knifeModel and next(activeSounds)==nil and anim.mode=="idle" then
            elapsed=0
            return
        end
        elapsed += dt
        if elapsed >= 0.1 then
            elapsed = 0
            reconcileKnife()
            if dirty then dirty = false; updateCamera() end
        end
        reclaimSounds()
        local nativePlaying = updateNative()
        if not nativePlaying and anim.mode~="idle" and tick()-anim.started>=anim.duration then
            anim.mode="idle"
            tryNative("Idle")
        end
        local cam = c.Workspace.CurrentCamera
        if knifeModel and knifeModel.PrimaryPart and cam then
            knifeModel:PivotTo(cam.CFrame * knifePose())
        end
    end)
    c.OnCleanup(function()
        trailStopped = true
        trailEnabled = false
        clearTrailPreview()
        knifeFollow:Disconnect(); cameraChanged:Disconnect()
        state.enabled=false;state.knife=false
        if cameraConnection then cameraConnection:Disconnect() end
        if skinFolderConn then skinFolderConn:Disconnect() end
        if resourcesConn then resourcesConn:Disconnect() end
        destroyButtons()
        restoreParts();restoreKnife()
    end)
    -- Give the UI and replicated game resources time to settle before the
    -- first skin category build. Reentrancy and generation guards remain.
    task.delay(3, function()
        if c.IsCurrent() then createSkinControls(false) end
    end)
end

end)()
-- Vortexion - BloxStrike v3: game-specific entry, unified WindUI UI.
-- Do not copy source implementations: use lifecycle-managed services in separate modules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local global = (getgenv and getgenv()) or _G
if type(global.VortexionBloxCleanup) == "function" then
    pcall(global.VortexionBloxCleanup)
end
global.VortexionBloxGeneration = (global.VortexionBloxGeneration or 0) + 1
local generation = global.VortexionBloxGeneration
local connections = {}
local cleanups = {}
local function isCurrent()
    return global.VortexionBloxGeneration == generation
end
local function ownConnection(conn)
    if conn then table.insert(connections,conn) end
    return conn
end
local function ownCleanup(fn)
    table.insert(cleanups,fn)
end
local cleaned = false
local function cleanup()
    if cleaned then return end
    cleaned = true
    if global.VortexionBloxGeneration == generation then
        global.VortexionBloxGeneration += 1
    end
    for i=#connections,1,-1 do
        pcall(function() connections[i]:Disconnect() end)
        connections[i]=nil
    end
    for i=#cleanups,1,-1 do
        pcall(cleanups[i])
        cleanups[i]=nil
    end
end
global.VortexionBloxCleanup=cleanup

-- Executor identity is telemetry, not a compatibility oracle.
-- Earlier builds blacklisted Xeno/Velocity/LX63 and returned before creating
-- any UI, making all game features appear broken. Capability-dependent
-- features must degrade individually, not terminate the complete script.
local executorName = "unknown"
pcall(function()
    if type(identifyexecutor) == "function" then
        executorName = tostring(identifyexecutor() or "unknown")
    end
end)
global.VortexionExecutorName = executorName

--=========================================================================
-- UI: WindUI bridge (vendored, zero network).
--=========================================================================
local ok,ui=pcall(function() return WindBridgeFactory(WindUI) end)
if not ok or not ui then
    global.VortexionBootError = "BloxStrike Bridge: " .. tostring(ui)
    warn("[Vortexion/BloxStrike] WindUI initialization failed: "..tostring(ui))
    return
end
global.VortexionBloxNotify=function(title,content)
    pcall(function() ui:Notify({Title=title, Content=content, Duration=4}) end)
end
local function notify(title, content)
    if global.VortexionBloxNotify then
        global.VortexionBloxNotify(title,content)
    end
end
local okWindow, window = pcall(function()
    return ui:CreateWindow({Title="BloxStrike", Size=UDim2.fromOffset(580,460)})
end)
if not okWindow or not window then
    global.VortexionBootError = "BloxStrike/CreateWindow: " .. tostring(window)
    warn("[Vortexion/BloxStrike] " .. global.VortexionBootError)
    pcall(function() ui:Destroy() end)
    cleanup()
    return
end
ui:OnDestroy(cleanup)
ownCleanup(function()
    if global.VortexionBloxCleanup == cleanup then
        global.VortexionBloxCleanup = nil
        global.VortexionBloxNotify = nil
    end
    pcall(function() ui:Destroy() end)
end)
local bootFailures = {}
local function reportBootFailure(component, message)
    local detail = tostring(component) .. ": " .. tostring(message):sub(1, 160)
    table.insert(bootFailures, detail)
    ui.BootStatus, ui.BootError = "partial", table.concat(bootFailures, "; ")
    warn("[Vortexion/BloxStrike] " .. detail)
end
local tabs={
    Combat=window:AddTab({Title="战斗",Icon="lucide-crosshair"}),
    Weapon=window:AddTab({Title="武器",Icon="lucide-target"}),
    Visual=window:AddTab({Title="视觉",Icon="lucide-eye"}),
    Appearance=window:AddTab({Title="枪械皮肤",Icon="lucide-palette"}),
    Knife=window:AddTab({Title="刀具与手套",Icon="lucide-swords"}),
    Movement=window:AddTab({Title="移动",Icon="lucide-activity"}),
    Settings=window:AddTab({Title="设置",Icon="lucide-settings"}),
}
window:InstallSettings(tabs.Settings)

--=========================================================================
-- Team folder cache: the old code re-walked Workspace.Characters twice per
-- player per frame. One 250ms map rebuild serves every caller.
--=========================================================================
local folderCache = { at = 0, map = {}, roster = {}, npcs = 0 }
local npcByModel = setmetatable({}, {__mode="k"})
local function rebuildFolderMap()
    local map = {}
    local roster = Players:GetPlayers()
    local root = Workspace:FindFirstChild("Characters")
    local count = 0
    if root then
        local function visit(model, folder)
            if not model:IsA("Model") then return end
            map[model.Name] = folder
            local owner = Players:FindFirstChild(model.Name)
            if owner and not owner:IsA("Player") then owner = nil end
            if not owner then
                local ok, player = pcall(function() return Players:GetPlayerFromCharacter(model) end)
                if ok then owner = player end
            end
            if not owner then
                local id = model:GetAttribute("UserId") or model:GetAttribute("PlayerUserId")
                if type(id) == "number" and id > 0 then
                    local ok, player = pcall(function() return Players:GetPlayerByUserId(id) end)
                    if ok then owner = player end
                end
            end
            if owner then return end
            -- The latest BloxStrike rounds may add bots as bare Models under
            -- Workspace.Characters; Players:GetPlayers() omits these actors.
            local proxy = npcByModel[model]
            if not proxy then
                proxy = {IsVortexionNPC=true, Name=model.Name, DisplayName=model.Name, Character=model}
                function proxy:GetAttribute(key) return self.Character:GetAttribute(key) end
                npcByModel[model] = proxy
            end
            proxy.Parent = model.Parent
            proxy.TeamFolder = folder
            proxy.Name, proxy.DisplayName = model.Name, model.Name
            roster[#roster + 1] = proxy
            count = count + 1
        end
        for _, container in ipairs(root:GetChildren()) do
            if container:IsA("Model") then
                visit(container, root)
            elseif container:IsA("Folder") then
                for _, model in ipairs(container:GetChildren()) do
                    visit(model, container)
                end
            end
        end
    end
    folderCache.map, folderCache.roster, folderCache.npcs = map, roster, count
    folderCache.at = tick()
end
local function ensureRoster()
    if tick()-folderCache.at > 0.25 then rebuildFolderMap() end
end
local function targets()
    ensureRoster()
    return folderCache.roster
end
local function teamFolder(player)
    if not player then return nil end
    ensureRoster()
    if player.IsVortexionNPC then return player.TeamFolder end
    return folderCache.map[player.Name]
end
local function characterOf(player)
    if not player then return LocalPlayer and LocalPlayer.Character end
    if player.IsVortexionNPC then return player.Character end
    local team=teamFolder(player)
    local candidate=team and team:FindFirstChild(player.Name)
    if candidate and candidate:IsA("Model") then return candidate end
    return player.Character
end
-- In BloxStrike the authoritative client roster is Workspace.Characters.
-- Counter-Strike style character models do not necessarily use a Humanoid.
-- Requiring one removed EVERY target from ESP, aim assist and trigger logic.
local virtualVitals = setmetatable({}, {__mode = "k"})
local renderPartCache = setmetatable({}, {__mode = "k"})
local function numberVitals(model, player)
    local health = model:GetAttribute("Health")
    local maximum = model:GetAttribute("MaxHealth")
    local healthObject = model:FindFirstChild("Health")
    if health == nil and healthObject and healthObject:IsA("NumberValue") then health = healthObject.Value end
    if maximum == nil then
        local maxObject = model:FindFirstChild("MaxHealth")
        if maxObject and maxObject:IsA("NumberValue") then maximum = maxObject.Value end
    end
    local known = type(health) == "number"
    if known and health <= 0 then return nil end
    local vitals = virtualVitals[model]
    if not vitals then
        vitals = { Health = 1, MaxHealth = 1, HealthKnown = false }
        virtualVitals[model] = vitals
    end
    vitals.Health = known and health or 1
    vitals.MaxHealth = (type(maximum) == "number" and maximum > 0) and maximum or (known and math.max(health, 1) or 1)
    vitals.HealthKnown = known
    return vitals
end
local function livingCharacter(player)
    local model = characterOf(player)
    if not model or not model.Parent or not model:IsA("Model") or model:GetAttribute("Dead") == true then return nil end
    if model:GetAttribute("Alive") == false then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 then return nil end
        return model, hum
    end
    -- Cache the renderable-part probe: Combat revalidates locked targets
    -- every frame, and recursive FindFirstChildWhichIsA is not free on mobile.
    local part = renderPartCache[model]
    if not part or not part.Parent then
        part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            or model:FindFirstChildWhichIsA("BasePart", true)
        renderPartCache[model] = part
    end
    if not part then return nil end
    local vitals = numberVitals(model, player)
    if vitals then return model, vitals end
    return nil
end

local function isEnemy(player,checkTeam)
    if player==LocalPlayer then return false end
    if checkTeam==false or Workspace:GetAttribute("Gamemode")=="Deathmatch" then return true end
    local localTeam=teamFolder(LocalPlayer)
    local otherTeam=teamFolder(player)
    if localTeam and otherTeam then return localTeam~=otherTeam end
    local a,b=LocalPlayer:GetAttribute("Team"),player:GetAttribute("Team")
    if a~=nil and b~=nil then return a~=b end
    if LocalPlayer.Team and player.Team then return LocalPlayer.Team~=player.Team end
    return true
end
local function playerFromModel(model)
    if not model then return nil end
    local byName=Players:FindFirstChild(model.Name)
    if byName and byName:IsA("Player") then return byName end
    local player = Players:GetPlayerFromCharacter(model)
    return player or npcByModel[model]
end

local ctx={
    Players=Players,RunService=RunService,Workspace=Workspace,
    ReplicatedStorage=ReplicatedStorage,Lighting=Lighting,Input=UserInputService,
    LocalPlayer=LocalPlayer,UI=ui,Window=window,Tabs=tabs,
    Notify=notify,IsCurrent=isCurrent,Own=ownConnection,OnCleanup=ownCleanup,
    Character=characterOf,Living=livingCharacter,TeamFolder=teamFolder,
    Enemy=isEnemy,PlayerFromModel=playerFromModel,Targets=targets,
}

--=========================================================================
-- Module assembly. Common first (capability probe, guards, cloak target),
-- then cloak, then features. A failed factory leaves a no-op stub behind so
-- one broken subsystem never takes the UI down.
--=========================================================================
local function emptyModule()
    local empty = {Failed = true}
    function empty:Update() end
    function empty:Start() end
    function empty:Stop() end
    function empty:GetLock() return nil end
    function empty:GetCandidates() return {} end
    function empty:PredictPoint(_, part) return part and part.Position or nil end
    function empty:GetEnvelope() return Vector3.zero end
    function empty:GetEnvelopeMargin() return 0.5 end
    function empty:Status() return {} end
    function empty:Rescan() end
    function empty:DebugSnapshot() return {} end
    return empty
end

local function setup(name, factory, key)
    if type(factory) ~= "function" then
        reportBootFailure(name, "factory missing")
        if key then ctx[key] = emptyModule() end
        return
    end
    local passed, result = pcall(factory, ctx)
    if not passed then
        reportBootFailure(name, result)
        notify(name.." 模块失败", tostring(result))
        if key then ctx[key] = emptyModule() end
    elseif type(result) == "table" and key then
        ctx[key] = result
    end
end

setup("Common", BloxCommonFactory)
local common = ctx
ownCleanup(function()
    if type(common.Cloak) == "table" and type(common.Cloak.Stop) == "function" then pcall(common.Cloak.Stop) end
    for i = #(common.Disposers or {}), 1, -1 do
        pcall(common.Disposers[i])
        common.Disposers[i] = nil
    end
end)
local passedCloak, cloak = false, "cloak factory missing"
if type(BloxCloakFactory) == "function" then
    passedCloak, cloak = pcall(BloxCloakFactory, common)
end
if passedCloak and type(cloak) == "table" then
    common.Cloak = cloak
else
    reportBootFailure("Cloak", cloak)
    common.Cloak = nil
end

setup("战斗", BloxCombatFactory, "Combat")
setup("子弹追踪", BloxBulletFactory, "Bullet")
setup("视觉", BloxVisualFactory, "Visual")
setup("皮肤", BloxCosmeticFactory)
if type(ui.RegisterFeatureHealth) == "function" then
    ui:RegisterFeatureHealth("BloxStrike", function()
        local function status(key)
            local item = common[key]
            return item == nil and "missing" or (item.Failed and "failed" or "ready")
        end
        local visual = common.Visual
        local snapshot = visual and type(visual.Status) == "function" and visual:Status() or {}
        local combat = common.Combat and type(common.Combat.DebugSnapshot) == "function" and common.Combat:DebugSnapshot() or {}
        return ("存活=%s 战斗=%s 子弹=%s 视觉=%s 失败=%d NPC=%d 目标=%d ESP=%d/%d/%.0f 倍镜=%s")
            :format(tostring(isCurrent()), status("Combat"), status("Bullet"), status("Visual"),
                #bootFailures, (function() ensureRoster(); return folderCache.npcs end)(),
                tonumber(combat.candidates) or 0, tonumber(snapshot.markers) or 0,
                tonumber(snapshot.scanned) or 0, tonumber(snapshot.refreshes) or 0,
                tostring(snapshot.thirdPerson or false))
    end)
end

-- R2.6: no global __namecall/metatable hook during boot.  Some mobile
-- executors can terminate the host process inside hookmetamethod, where
-- pcall cannot recover. Protect() remains an optional weak registry, but
-- does NOT claim to hide instances from game code in this safe mode.
common.CloakAutoHookDisabled = true

--=========================================================================
-- Shared render loop: one BindToRenderStep(Last) drives Combat and Bullet.
-- Per-frame dt below 4ms-worth is skipped (physics hiccups), each subsystem
-- is guard-wrapped, and over-budget frames are counted for the debug channel.
--=========================================================================
local budgets = { Combat = 1.2, Bullet = 0.6 }
local costs = { Combat = 0, Bullet = 0 }
local slowLoops = 0
local frameName = "VortexionBloxFrame_" .. tostring(generation)
RunService:BindToRenderStep(frameName, Enum.RenderPriority.Last.Value, function(dt)
    if not isCurrent() then return end
    if dt < 0.004 then return end
    -- Idle load is deliberately zero: off means no combat/projectile scans.
    local combatActive = ctx.Combat and type(ctx.Combat.IsActive) == "function" and ctx.Combat:IsActive()
    if combatActive then
        local t0 = tick()
        common.Guard("Frame.Combat", function() ctx.Combat:Update(dt) end)
        costs.Combat = tick() - t0
    else
        costs.Combat = 0
    end
    local bulletActive = ctx.Bullet and type(ctx.Bullet.IsActive) == "function" and ctx.Bullet:IsActive()
    if bulletActive then
        local t0 = tick()
        common.Guard("Frame.Bullet", function() ctx.Bullet:Update(dt) end)
        costs.Bullet = tick() - t0
    else
        costs.Bullet = 0
    end
    for name, cost in pairs(costs) do
        if cost * 1000 > budgets[name] then slowLoops += 1 end
    end
end)
ownCleanup(function() RunService:UnbindFromRenderStep(frameName) end)

task.spawn(function()
    while isCurrent() do
        task.wait(2)
        if not isCurrent() then break end
        if common.Debug then
            local combat = ctx.Combat and ctx.Combat:DebugSnapshot() or {}
            local bullet = ctx.Bullet and ctx.Bullet:Status() or {}
            print(("[Vortexion/BloxStrike] frame combat=%s cand=%d hit=%d(%.2fms) bullet path=%s bullets=%d(%.2fms) slow=%d hooks=%d remotes=%d/%d"):format(
                tostring(combat.locked or "-"), tonumber(combat.candidates) or 0, tonumber(combat.hitEntries) or 0, costs.Combat * 1000,
                tostring(bullet.path or "-"), tonumber(bullet.bullets) or 0, costs.Bullet * 1000,
                slowLoops,
                tonumber(bullet.hooks) or 0,
                tonumber(bullet.remotes) or 0, tonumber(bullet.totalRemotes) or 0))
        end
    end
end)

--=========================================================================
-- Settings tab: debug channel, performance readout, environment probe,
-- unload.
--=========================================================================
tabs.Settings:AddToggle("BloxDebug",{Title="调试日志",Default=false,Callback=function(v)
    common.Debug = v
end})
tabs.Settings:AddParagraph({Title="BloxStrike 兼容说明",
    Content="R2.6 稳定启动模式：默认不安装全局枚举 Hook。战斗/追踪全部关闭时跳过其帧计算；皮肤分类延后限量生成。武器页手动开启的高级追踪仍依赖执行器能力，异常时应关闭。"})
tabs.Settings:AddButton({Title="子模块初始化诊断",Callback=function()
    notify("BloxStrike 启动诊断",#bootFailures > 0 and table.concat(bootFailures, " / ")
        or "模块工厂未报告失败；功能运行仍需实际测试")
end})
tabs.Settings:AddButton({Title="检查运行状态",Callback=function()
    local assets=ReplicatedStorage:FindFirstChild("Assets")
    local skins=assets and assets:FindFirstChild("Skins")
    local characters=Workspace:FindFirstChild("Characters")
    local components=ReplicatedStorage:FindFirstChild("Components")
    local weapon=components and components:FindFirstChild("Weapon")
    local bullet=weapon and weapon:FindFirstChild("Classes") and weapon.Classes:FindFirstChild("Bullet")
    local status=ctx.Bullet and ctx.Bullet:Status() or {}
    notify("运行环境检查",(characters and "角色目录正常" or "角色目录未加载")
        .." / "..(skins and "皮肤目录正常" or "皮肤目录未加载")
        .." / "..(weapon and "武器组件正常" or "武器组件未加载")
        .." / "..(bullet and "Bullet 模块存在" or "Bullet 模块未找到")
        .." / 追踪路径 "..tostring(status.path or "-"))
end})
tabs.Settings:AddButton({Title="性能状态",Callback=function()
    notify("性能状态",("战斗 %.2fms / 子弹 %.2fms，超预算帧 %d"):format(
        costs.Combat*1000, costs.Bullet*1000, slowLoops))
end})
tabs.Settings:AddButton({Title="卸载全部 BloxStrike 功能",Callback=function()
    cleanup()
    pcall(function() ui:Destroy() end)
end})

window:SelectTab(1)
notify("Vortexion - BloxStrike","功能模块已加载；进入对局后启用对应功能")

end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "BloxStrike")
