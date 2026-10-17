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
local ForsakenEnhancementsFactory = (function()
-- Forsaken R2.8: seven opt-in client features, one scheduler and deterministic cleanup.
-- Game remotes and local state are version dependent. UI never claims server success.
return function(options)
    assert(type(options) == "table" and options.Player and options.Bridge and options.Tabs,
        "Forsaken enhancements need Player, Bridge and Tabs")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local player, bridge, tabs = options.Player, options.Bridge, options.Tabs
    local puzzleAuto = options.PuzzleAuto
    local state = {
        alive = true, stamina = false, antiSlow = false, antiTaph = false,
        autoPopup = false, moveMultiplier = 1, autoRepair = false,
        repairDelay = 4, approach = false, repairProtocol = "Auto",
        repairsSent = 0, progressSeen = 0, popupsClosed = 0,
        lastError = "none", lastAction = "idle", lastWarning = -math.huge,
        repairPaused = false,
        nextRepair = 0, nextRequire = 0,
    }
    local staminaModule, staminaInstance
    local staminaSnapshot = setmetatable({}, {__mode = "k"})
    local slowSnapshot = setmetatable({}, {__mode = "k"})
    local hiddenSnapshot = setmetatable({}, {__mode = "k"})
    local walkSnapshot = setmetatable({}, {__mode = "k"})
    local speedMultiplierValue
    local speedMultiplierFolder
    state.speedMode = "inactive"
    state.speedObserved = 0
    state.measuredSpeed = 0
    state.repairPhase = "idle"
    local links = {}
    local heartbeat
    local elapsed = 0
    local lastTarget, lastProgress, stagnant = nil, nil, 0
    local awaitingProgress = false
    local promptToken = 0
    local promptInFlight = false
    local lastClick = setmetatable({}, {__mode = "k"})
    local savedPosition
    local lastSpeedRoot, lastSpeedPos, lastSpeedAt

    local function report(label, err)
        state.lastError = (tostring(label) .. ": " .. tostring(err)):sub(1, 320)
        if os.clock() - state.lastWarning >= 4 then
            state.lastWarning = os.clock()
            warn("[Vortexion/Forsaken/R2.8] " .. state.lastError)
        end
    end
    local function safe(label, fn)
        local ok, result = pcall(fn)
        if not ok then report(label, result) end
        return ok, result
    end
    local function notify(title, content)
        safe("notify", function() bridge:Notify({Title=title, Content=tostring(content), Duration=5}) end)
    end
    local function character()
        local c = player.Character
        local h = c and c:FindFirstChildWhichIsA("Humanoid")
        return c, h, c and c:FindFirstChild("HumanoidRootPart")
    end
    local function nested(parent, names)
        local cur = parent
        for _, name in ipairs(names) do
            cur = cur and cur:FindFirstChild(name)
            if not cur then return nil end
        end
        return cur
    end
    local function restoreValues(snapshots)
        for obj, record in pairs(snapshots) do
            if obj and obj.Parent then
                safe("restore value", function()
                    if obj:IsA("NumberValue") then
                        -- Don't clobber an unrelated update made after our last write.
                        if obj.Value == record.applied then obj.Value = record.old end
                    end
                end)
            end
            snapshots[obj] = nil
        end
    end
    local function resolveStamina()
        local instance = nested(ReplicatedStorage, {"Systems", "Character", "Game", "Sprinting"})
        if not instance or not instance:IsA("ModuleScript") then
            staminaInstance, staminaModule = nil, nil
            return nil
        end
        if instance == staminaInstance and type(staminaModule) == "table" then
            return staminaModule
        end
        if os.clock() < state.nextRequire then return nil end
        state.nextRequire = os.clock() + 3
        local ok, mod = pcall(require, instance)
        if not ok or type(mod) ~= "table" then
            report("Sprinting require", mod)
            return nil
        end
        staminaInstance, staminaModule = instance, mod
        return mod
    end
    local STAMINA_FIELDS = {"StaminaLossDisabled", "StaminaLoss", "StaminaGain"}
    local function restoreStamina()
        for mod, records in pairs(staminaSnapshot) do
            for key, entry in pairs(records) do
                safe("restore stamina", function()
                    if mod[key] == entry.applied then mod[key] = entry.old end
                end)
            end
            staminaSnapshot[mod] = nil
        end
        staminaInstance, staminaModule = nil, nil
    end
    local function applyStamina()
        if not state.stamina then return end
        local mod = resolveStamina()
        if not mod then return end
        local previous = staminaSnapshot[mod]
        if not previous then previous = {}; staminaSnapshot[mod] = previous end
        local targets = {
            StaminaLossDisabled = true,
            StaminaLoss = 0,
            StaminaGain = (type(mod.MaxStamina) == "number" and math.max(200, mod.MaxStamina * 6) or 600),
        }
        for _, key in ipairs(STAMINA_FIELDS) do
            local value = mod[key]
            local target = targets[key]
            if type(value) == type(target) then
                if not previous[key] then previous[key] = {old=value, applied=target} end
                if mod[key] ~= target then mod[key] = target end
            end
        end
        if type(mod.Stamina) == "number" and type(mod.MaxStamina) == "number" then
            if mod.Stamina < mod.MaxStamina then mod.Stamina = mod.MaxStamina end
        end
    end
    local function applyAntiSlow()
        if not state.antiSlow then return end
        local c = player.Character
        if not c then return end
        for _, folder in ipairs({"SpeedMultipliers", "FOVMultipliers"}) do
            local multiplier = nested(c, {folder, "SlowedStatus"})
            if multiplier and multiplier:IsA("NumberValue") and multiplier.Value < 1 then
                local rec = slowSnapshot[multiplier]
                if not rec then
                    slowSnapshot[multiplier] = {old=multiplier.Value, applied=1}
                end
                multiplier.Value = 1
            end
        end
    end
    local function restoreWalk()
        for hum, record in pairs(walkSnapshot) do
            if hum and hum.Parent then
                safe("restore speed", function()
                    if math.abs(hum.WalkSpeed - record.applied) < 0.15 then
                        hum.WalkSpeed = record.base
                    end
                end)
            end
            walkSnapshot[hum] = nil
        end
    end
    local function clearSpeedMultiplier()
        if speedMultiplierValue then
            local owned = speedMultiplierValue
            speedMultiplierValue = nil
            speedMultiplierFolder = nil
            safe("remove speed multiplier", function() if owned.Parent then owned:Destroy() end end)
        end
    end
    local function applyWalk()
        local _, _, measuredRoot = character()
        if measuredRoot and measuredRoot.Position then
            local now = os.clock()
            if lastSpeedRoot == measuredRoot and lastSpeedPos and lastSpeedAt and now > lastSpeedAt then
                local traveled = (measuredRoot.Position - lastSpeedPos).Magnitude
                local observed = traveled / (now - lastSpeedAt)
                if observed <= 100 then state.measuredSpeed = observed end
            end
            lastSpeedRoot, lastSpeedPos, lastSpeedAt = measuredRoot, measuredRoot.Position, now
        else
            lastSpeedRoot, lastSpeedPos, lastSpeedAt = nil, nil, nil
            state.measuredSpeed = 0
        end
        if state.moveMultiplier <= 1.001 then
            state.speedMode = "inactive"
            clearSpeedMultiplier()
            return
        end
        local characterModel, hum = character()
        if not hum or hum.Health <= 0 then
            state.speedMode = "waiting-character"
            return
        end
        -- Forsaken's own speed composition consumes SpeedMultipliers/NumberValues
        -- (confirmed by uploaded Terio_Survivor and statusModule references).
        -- Updating only Humanoid.WalkSpeed gets overwritten by its movement system.
        local folder = characterModel and characterModel:FindFirstChild("SpeedMultipliers")
        if folder then
            if speedMultiplierFolder ~= folder or not speedMultiplierValue
                or speedMultiplierValue.Parent ~= folder then
                clearSpeedMultiplier()
                local obj = Instance.new("NumberValue")
                obj.Name = "VortexionMoveMultiplier"
                obj.Value = state.moveMultiplier
                obj.Parent = folder
                speedMultiplierFolder, speedMultiplierValue = folder, obj
            elseif math.abs(speedMultiplierValue.Value - state.moveMultiplier) > 0.001 then
                speedMultiplierValue.Value = state.moveMultiplier
            end
            restoreWalk()
            state.speedMode = "game-SpeedMultipliers"
            state.speedObserved = hum.WalkSpeed
            return
        end
        clearSpeedMultiplier()
        state.speedMode = "WalkSpeed-fallback"
        local rec = walkSnapshot[hum]
        local current = hum.WalkSpeed
        if not rec then
            rec = {base=current, applied=current}
            walkSnapshot[hum] = rec
        elseif math.abs(current - rec.applied) > 0.15 then
            rec.base = current
        end
        rec.applied = math.clamp(rec.base * state.moveMultiplier, 0, 200)
        if math.abs(current - rec.applied) >= 0.05 then hum.WalkSpeed = rec.applied end
        state.speedObserved = hum.WalkSpeed
    end
    local function hide(obj, property)
        if not obj or not obj.Parent then return end
        if hiddenSnapshot[obj] then return end
        safe("hide client effect", function()
            local old = obj[property]
            if type(old) == "boolean" and old then
                hiddenSnapshot[obj] = {property=property, old=old}
                obj[property] = false
            end
        end)
    end
    local function restoreHidden(predicate)
        for obj, entry in pairs(hiddenSnapshot) do
            if not predicate or predicate(obj) then
                if obj.Parent then
                    safe("restore client effect", function()
                        if obj[entry.property] == false then obj[entry.property] = entry.old end
                    end)
                end
                hiddenSnapshot[obj] = nil
            end
        end
    end
    local function isTaphVisual(obj)
        local n = obj.Name:lower()
        return n == "subspaced" or n == "subspaceeffect" or n == "subspaceoverlay"
    end
    local function processVisual(obj)
        if not state.antiTaph or not isTaphVisual(obj) then return end
        if obj:IsA("GuiObject") then hide(obj, "Visible")
        elseif obj:IsA("ScreenGui") then hide(obj, "Enabled")
        elseif obj:IsA("PostEffect") then hide(obj, "Enabled") end
    end
    local function tryClickPopup(popup)
        if not popup:IsA("GuiObject") or not popup.Parent then return end
        if lastClick[popup] and os.clock() - lastClick[popup] < 0.25 then return end
        lastClick[popup] = os.clock()
        -- Only hide the local popup; synthetic mouse events can steal mobile touches.
        hide(popup, "Visible")
        state.popupsClosed += 1
    end
    local function processPopup(obj)
        if not state.autoPopup then return end
        if obj.Name == "1x1x1x1Popup" then
            if obj:IsA("GuiObject") then tryClickPopup(obj) end
        end
    end
    local function scanLocalUi()
        local gui = player:FindFirstChildOfClass("PlayerGui")
        if not gui then return end
        local temp = gui:FindFirstChild("TemporaryUI")
        if state.autoPopup and temp then
            for _, obj in ipairs(temp:GetDescendants()) do processPopup(obj) end
        end
        if state.antiTaph then
            for _, folderName in ipairs({"MainUI", "TemporaryUI"}) do
                local folder = gui:FindFirstChild(folderName)
                if folder then
                    for _, obj in ipairs(folder:GetDescendants()) do processVisual(obj) end
                end
            end
            for _, obj in ipairs(Lighting:GetDescendants()) do processVisual(obj) end
        end
    end
    -- All Forsaken generator features use this discovery routine. Versions may
    -- put Generator models directly in Ingame.Map or in a Generators folder.
    -- The previous first-non-nil folder selection silently discarded other paths.
    local generatorCache, generatorCachedAt = {}, -math.huge
    local function enumerateGenerators()
        if os.clock() - generatorCachedAt < 0.5 then return generatorCache end
        generatorCachedAt = os.clock()
        local found, seen, visited = {}, {}, 0
        local map = Workspace:FindFirstChild("Map")
        local inGame = map and map:FindFirstChild("Ingame")
        local innerMap = inGame and inGame:FindFirstChild("Map")
        local roots = {
            map and map:FindFirstChild("Generators"),
            inGame and inGame:FindFirstChild("Generators"),
            innerMap and innerMap:FindFirstChild("Generators"),
            innerMap,
        }
        local function collect(container)
            if not container or visited >= 192 then return end
            for _, item in ipairs(container:GetChildren()) do
                visited += 1
                if visited > 192 then break end
                if item:IsA("Model") and item.Name == "Generator" and not seen[item] then
                    seen[item] = true
                    found[#found + 1] = item
                end
            end
        end
        for _, root in pairs(roots) do collect(root) end
        generatorCache = found
        return found
    end
    local function nearestGenerator()
        local _, hum, root = character()
        if not root or not hum or hum.Health <= 0 then return nil end
        local selected, closest, position
        for _, gen in ipairs(enumerateGenerators()) do
            if gen.Parent then
                local progress = gen:FindFirstChild("Progress")
                local main = gen:FindFirstChild("Main")
                local part = main and (main:IsA("BasePart") and main or main:FindFirstChildWhichIsA("BasePart"))
                part = part or gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                -- Current game versions can expose generator completion as an
                -- attribute rather than Progress NumberValue. Do not reject a
                -- valid interactable model solely because the old field moved.
                local value = progress and (progress:IsA("IntValue") or progress:IsA("NumberValue"))
                    and progress.Value or nil
                local complete = gen:FindFirstChild("Completed")
                local done = complete and complete:IsA("BoolValue") and complete.Value
                if part and not done and (value == nil or value < 100) then
                    local distance = (root.Position - part.Position).Magnitude
                    if not closest or distance < closest then
                        selected, closest, position = gen, distance, part
                    end
                end
            end
        end
        return selected, closest, position, root
    end
    local function restorePosition()
        if not savedPosition then return end
        local rec = savedPosition
        savedPosition = nil
        local _, _, root = character()
        if root and root == rec.root then
            safe("restore position", function() root.CFrame = rec.cf end)
        end
    end
    -- A Forsaken generator is not a single FireServer call: after interaction,
    -- the game presents a multi-layer wire puzzle. Bare RE:FireServer() with no
    -- proven protocol is not a repair and is intentionally never issued.
    local function findGeneratorPrompt(gen)
        local count = 0
        for _, item in ipairs(gen:GetDescendants()) do
            count += 1
            if count > 128 then break end
            if item:IsA("ProximityPrompt") and item.Enabled then return item end
        end
        return nil
    end
    local function puzzleIsOpen()
        local pg = player:FindFirstChildOfClass("PlayerGui")
        if not pg then return false end
        local puzzle = pg:FindFirstChild("PuzzleUI")
        if puzzle then
            if puzzle:IsA("ScreenGui") and not puzzle.Enabled then return false end
            local frame = puzzle:FindFirstChild("Container")
            if frame and frame:IsA("GuiObject") then return frame.Visible end
            return puzzle:IsA("ScreenGui") and puzzle.Enabled == true
        end
        return false
    end
    local function repairOnce()
        if not state.autoRepair or promptInFlight then return end
        -- Legacy RemoteEvent mode is documented in several independently published
        -- scripts, but actual server acceptance is VERSION DEPENDENT. Verify progress
        -- after every attempt and stop after three unchanged observations.
        if awaitingProgress and lastTarget and lastProgress ~= nil then
            local progress = lastTarget:FindFirstChild("Progress")
            if progress and (progress:IsA("IntValue") or progress:IsA("NumberValue"))
                and progress.Value > lastProgress then
                state.progressSeen += 1
                stagnant = 0
                awaitingProgress = false
                state.repairPhase = "progress-confirmed"
            else
                stagnant += 1
                awaitingProgress = false
                if stagnant >= 3 then
                    state.repairPaused = true
                    state.repairPhase = "no-progress-after-remote"
                    state.lastAction = "旧版 RE 请求连续三次未观察到进度变化，已暂停以避免无效请求"
                    return
                end
            end
        end
        if puzzleIsOpen() then
            state.repairPhase = "puzzle-open"
            local pg = player:FindFirstChildOfClass("PlayerGui")
            local puzzle = pg and pg:FindFirstChild("PuzzleUI")
            if puzzleAuto and puzzle then
                local started = puzzleAuto:Try(puzzle,
                    function() return state.alive and state.autoRepair end,
                    function(phase, detail)
                        if state.alive then
                            state.repairPhase = "puzzle-" .. tostring(phase)
                            state.lastAction = tostring(detail)
                        end
                    end)
                if started then state.repairPhase = "puzzle-executing" end
            else
                state.repairPhase = "puzzle-unsupported"
                state.lastAction = "谜题界面存在，但本版本没有可用的解析与执行模块"
            end
            return
        end
        local gen, distance, part = nearestGenerator()
        if not gen then
            state.repairPhase = "no-target"
            state.lastAction = "未找到未完成发电机或角色不可用"
            return
        end
        local progress = gen:FindFirstChild("Progress")
        if gen ~= lastTarget then
            lastTarget, lastProgress, stagnant = gen, progress and progress.Value or nil, 0
            awaitingProgress = false
        end
        if distance > 16 then
            state.repairPhase = "out-of-range"
            if not state.approach then
                state.lastAction = ("距离 %.0f studs；请靠近或开启自动寻路"):format(distance)
                return
            end
            safe("approach generator", function()
                local _, humanoid = character()
                if humanoid then humanoid:MoveTo(part.Position - part.CFrame.LookVector * 5) end
            end)
            state.lastAction = "正在尝试使用 Humanoid:MoveTo 接近发电机"
            return
        end
        if stagnant >= 3 then
            state.repairPhase = "interaction-unconfirmed"
            state.repairPaused = true
            state.lastAction = "连续 3 次尝试交互仍未观察到拼图；已停止重试"
            return
        end
        local prompt = findGeneratorPrompt(gen)
        if state.repairProtocol == "Legacy RE" or (not prompt and state.repairProtocol == "Auto") then
            local remotes = gen:FindFirstChild("Remotes")
            local re = remotes and remotes:FindFirstChild("RE")
            if not (re and re:IsA("RemoteEvent")) then
                state.repairPhase = "no-known-interface"
                state.repairPaused = true
                state.lastAction = "没有交互提示，也没有旧版 Generator.Remotes.RE；已暂停"
                return
            end
            if distance > 12 then
                state.repairPhase = "remote-out-of-range"
                state.lastAction = "旧版 RE 兼容尝试只允许发电机附近；请靠近目标"
                return
            end
            local ok = safe("legacy Generator.RE", function() re:FireServer() end)
            if not ok then
                state.repairPhase = "legacy-remote-error"
                state.repairPaused = true
                return
            end
            state.repairsSent += 1
            state.repairPhase = "legacy-remote-unconfirmed"
            state.lastAction = "已发送单次旧版请求；等待 Progress 变化验证，失败自动停止"
            lastTarget, lastProgress = gen, progress and progress.Value or nil
            awaitingProgress = true
            return
        end
        if not prompt then
            state.repairPhase = "no-prompt"
            state.repairPaused = true
            state.lastAction = "当前模式要求原生交互，但没有找到 ProximityPrompt"
            return
        end
        local maxDistance = tonumber(prompt.MaxActivationDistance) or 10
        if distance > maxDistance then
            state.repairPhase = "prompt-out-of-range"
            state.lastAction = ("靠近至 %.1f studs 内才能触发交互"):format(maxDistance)
            return
        end
        promptToken += 1
        local thisToken = promptToken
        promptInFlight = true
        state.repairPhase = "prompt-hold"
        state.lastAction = "尝试触发游戏自带交互提示，等待拼图界面"
        task.spawn(function()
            local ok = safe("generator InputHoldBegin", function()
                prompt:InputHoldBegin()
            end)
            if ok then
                task.wait(math.clamp((tonumber(prompt.HoldDuration) or 0) + 0.12, 0.15, 6))
            end
            -- Finish a hold even if disabled mid-hold; never synthesize global
            -- touch/mouse events, which interfere with Android controls.
            safe("generator InputHoldEnd", function() prompt:InputHoldEnd() end)
            if state.alive and thisToken == promptToken then
                promptInFlight = false
                if ok then
                    state.repairsSent += 1
                    stagnant += 1
                    state.repairPhase = "interaction-attempted"
                    state.lastAction = "交互已尝试；仍需验证拼图是否出现并实现连线求解"
                else
                    state.repairPhase = "prompt-error"
                    state.repairPaused = true
                end
            end
        end)
    end
    local function stopScheduler()
        if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
    end
    local function active()
        return state.stamina or state.antiSlow or state.antiTaph or state.autoPopup
            or state.moveMultiplier > 1.001 or state.autoRepair
    end
    local function manageScheduler()
        if not state.alive or not active() then stopScheduler(); return end
        if heartbeat then return end
        elapsed = 0
        heartbeat = RunService.Heartbeat:Connect(function(dt)
            if not state.alive then return end
            elapsed += math.min(dt, 0.3)
            if elapsed < 0.25 then return end
            elapsed = 0
            safe("feature tick", function()
                applyStamina()
                applyAntiSlow()
                applyWalk()
                if state.antiTaph or state.autoPopup then
                    for obj, record in pairs(hiddenSnapshot) do
                        if obj.Parent and obj[record.property] == true then
                            obj[record.property] = false
                        end
                    end
                end
                if state.autoRepair and not state.repairPaused and os.clock() >= state.nextRepair then
                    state.nextRepair = os.clock() + state.repairDelay
                    repairOnce()
                end
            end)
        end)
    end
    local function switch(field, value)
        if not state.alive then return end
        state[field] = (value == true)
        if field == "stamina" and not value then restoreStamina() end
        if field == "antiSlow" and not value then restoreValues(slowSnapshot) end
        if field == "antiTaph" and not value then restoreHidden(isTaphVisual) end
        if field == "autoPopup" and not value then
            restoreHidden(function(obj) return obj.Name == "1x1x1x1Popup" end)
        end
        if field == "autoRepair" then
            if puzzleAuto then puzzleAuto:Stop() end
            promptToken += 1
            promptInFlight = false
            state.repairPhase = value and "waiting" or "disabled"
            state.repairPaused = false
            state.nextRepair = os.clock() + (value and 0.25 or 0)
            lastTarget, lastProgress, stagnant = nil, nil, 0
            awaitingProgress = false
            if not value then restorePosition() end
        end
        if value and (field == "antiTaph" or field == "autoPopup") then
            safe("initial effect scan", scanLocalUi)
        end
        manageScheduler()
    end
    local function shutdown()
        if not state.alive then return end
        state.alive = false
        if puzzleAuto then puzzleAuto:Stop() end
        promptToken += 1
        stopScheduler()
        for _, link in ipairs(links) do safe("disconnect", function() link:Disconnect() end) end
        table.clear(links)
        restoreStamina()
        restoreValues(slowSnapshot)
        restoreWalk()
        clearSpeedMultiplier()
        lastSpeedRoot, lastSpeedPos, lastSpeedAt = nil, nil, nil
        restoreHidden()
        restorePosition()
    end
    table.insert(links, player.CharacterAdded:Connect(function()
        clearSpeedMultiplier()
        restoreWalk()
        lastSpeedRoot, lastSpeedPos, lastSpeedAt = nil, nil, nil
        restoreValues(slowSnapshot)
        staminaInstance, staminaModule = nil, nil
        lastTarget, lastProgress, stagnant = nil, nil, 0
        awaitingProgress = false
        savedPosition = nil
        state.nextRepair = os.clock() + state.repairDelay
        promptToken += 1
        promptInFlight = false
    end))
    local gui = player:FindFirstChildOfClass("PlayerGui")
    if gui then
        table.insert(links, gui.DescendantAdded:Connect(function(obj)
            if not state.alive then return end
            if state.autoPopup then safe("popup added", function() processPopup(obj) end) end
            if state.antiTaph then safe("effect added", function() processVisual(obj) end) end
        end))
    end
    table.insert(links, Lighting.ChildAdded:Connect(function(obj)
        if state.alive and state.antiTaph then safe("lighting effect", function() processVisual(obj) end) end
    end))

    -- New controls follow Vortexion's native WindAdapter APIs and default to OFF.
    tabs.player:AddToggle("FsInfiniteStaminaR28", {Title="无限体力", Default=false,
        Callback=function(v) switch("stamina", v) end})
    tabs.player:AddToggle("FsAntiSlowR28", {Title="反减速", Default=false,
        Callback=function(v) switch("antiSlow", v) end})
    tabs.player:AddSlider("FsMovementMultiplierR28", {Title="移动倍数 (1.0–2.0)", Min=1, Max=2,
        Default=1, Rounding=2, Callback=function(v)
            local mult = math.clamp(tonumber(v) or 1, 1, 2)
            if mult <= 1.001 then restoreWalk(); clearSpeedMultiplier() end
            state.moveMultiplier = mult
            manageScheduler()
        end})
    tabs.player:AddButton({Title="查看移动倍率诊断", Callback=function()
        notify("Forsaken 移动倍率", ("倍率=%.2f 模式=%s Humanoid.WalkSpeed=%.2f\n估算位移速度=%.2f studs/s（仅供诊断）\n错误：%s")
            :format(state.moveMultiplier, state.speedMode, state.speedObserved,
                state.measuredSpeed, state.lastError))
    end})
    tabs.defense:AddToggle("FsAntiTaphR28", {Title="反塔夫亚空间炸弹（本地视觉效果）", Default=false,
        Callback=function(v) switch("antiTaph", v) end})
    tabs.defense:AddToggle("FsPopupR28", {Title="自动关闭 1x1x1x1 弹窗", Default=false,
        Callback=function(v) switch("autoPopup", v) end})
    tabs.defense:AddParagraph({Title="防御范围", Content="塔夫处理本地 Subspaced 视觉效果；不声称免疫服务器 Helpless 状态。弹窗仅在本地隐藏，不模拟鼠标点击以免抢占触控。"})
    tabs.generators:AddToggle("FsAutoRepairR28", {Title="自动修发电机（兼容协议＋进度检测）", Default=false,
        Callback=function(v) switch("autoRepair", v) end})
    tabs.generators:AddDropdown("FsGeneratorProtocolR214", {Title="修理协议", Values={"Auto", "Prompt", "Legacy RE"}, Default="Auto",
        Callback=function(v) if v == "Auto" or v == "Prompt" or v == "Legacy RE" then state.repairProtocol = v end end})
    tabs.generators:AddParagraph({Title="自动修理协议说明", Content="Auto 优先游戏原生交互；无提示时尝试公开脚本使用的旧版 RE。每次发出请求必须观察 Progress 增长，三次失败自动暂停；拼图界面仍需实际解谜。"})
    tabs.generators:AddSlider("FsRepairDelayR28", {Title="修发电机延迟（秒）", Min=2.5, Max=10,
        Default=4, Rounding=1, Callback=function(v)
            state.repairDelay = math.clamp(tonumber(v) or 4, 2.5, 10)
        end})
    tabs.generators:AddToggle("FsAutoApproachR28", {Title="自动前往发电机（可选）", Default=false,
        Callback=function(v) state.approach = not not v end})
    tabs.generators:AddButton({Title="重新尝试发电机修理", Callback=function()
        stagnant = 0
        promptToken += 1
        promptInFlight = false
        lastTarget, lastProgress = nil, nil
        awaitingProgress = false
        state.repairPaused = false
        if puzzleAuto then puzzleAuto:Reset() end
        state.nextRepair = os.clock() + 0.25
        if state.autoRepair then manageScheduler() end
        notify("发电机", "已重置失败计数，等待下一次修理")
    end})
    tabs.generators:AddParagraph({Title="新版发电机适配状态", Content="7×7 数字配对拼图：路径规划＋可用执行器虚拟鼠标输入；12 节点外围连线：仅在颜色成对时尝试；圆锁／齿轮：仅识别并提示，缺输入协议时不自动乱点。每条路径必须看到界面变化，否则停止。打开谜题后请收起 Vortexion 界面以避免遮挡。"})
    local repairStatusParagraph=tabs.generators:AddParagraph({Title="修理诊断", Content="点击查看修理与防御诊断，状态在此显示，不覆盖手机触控"})
    tabs.generators:AddButton({Title="查看修理与防御诊断", Callback=function()
        local detail=("交互尝试=%d 进度变化=%d 弹窗=%d 阶段=%s\n%s\n路径执行=%s / %d，失败=%d\n速度模式=%s 实测WalkSpeed=%.2f\n错误：%s")
            :format(state.repairsSent, state.progressSeen, state.popupsClosed,
                state.repairPhase, state.lastAction,
                puzzleAuto and puzzleAuto.Status or "unavailable",
                puzzleAuto and puzzleAuto.Paths or 0,
                puzzleAuto and puzzleAuto.Failed or 0,
                state.speedMode, state.speedObserved, state.lastError)
        if repairStatusParagraph and type(repairStatusParagraph.SetDesc)=="function" then
            repairStatusParagraph:SetDesc(detail)
        else
            print("[Vortexion/Forsaken] "..detail)
        end
    end})
    tabs.generators:AddButton({Title="分析当前发电机谜题（端点/颜色/路径）", Callback=function()
        local planner = options.PuzzlePlanner
        local pg = player:FindFirstChildOfClass("PlayerGui")
        local puzzle = pg and pg:FindFirstChild("PuzzleUI")
        if not planner or not puzzle then
            state.lastAction = "请先在游戏内打开 PuzzleUI，然后重新分析"
            return
        end
        local ok, data, reason = pcall(planner.Read, puzzle)
        if not ok or not data then
            state.lastAction = "谜题解析失败：" .. tostring(ok and reason or data)
            return
        end
        local output = planner.Summary(data)
        local env = (getgenv and getgenv()) or _G
        local clipboard = env.setclipboard or env.toclipboard or setclipboard or toclipboard
        if type(clipboard) == "function" then safe("copy puzzle planner", function() clipboard(output) end)
        else print(output) end
        state.lastAction = ("题型=%s 识别格=%d 成对端点=%d（已复制分析）"):
            format(data.phase, data.count, #data.pairs)
        state.repairPhase = "puzzle-analyzed-not-actuated"
    end})
    tabs.generators:AddButton({Title="复制当前连线谜题结构（供适配）", Callback=function()
        -- Diagnostic only. Puzzle layouts are not guaranteed across updates.
        -- Read bounded GUI geometry; never synthesize global touch/mouse events.
        local pg = player:FindFirstChildOfClass("PlayerGui")
        if not pg then state.lastAction = "PlayerGui 尚未出现"; return end
        local puzzle
        for _, entry in ipairs(pg:GetChildren()) do
            if entry.Name:lower():find("puzzle", 1, true)
                or entry.Name:lower():find("generator", 1, true) then
                puzzle = entry; break
            end
        end
        if not puzzle then
            state.lastAction = "找不到可见谜题界面，请先手动打开发电机谜题"
            return
        end
        local output = {"[Vortexion] PuzzleUI: " .. puzzle:GetFullName()}
        local count = 0
        for _, item in ipairs(puzzle:GetDescendants()) do
            if item:IsA("GuiObject") then
                count += 1
                if count > 160 then break end
                local ok, desc = pcall(function()
                    return string.format("%s | %s | pos=%s | size=%s | visible=%s",
                        item.Name, item.ClassName, tostring(item.AbsolutePosition),
                        tostring(item.AbsoluteSize), tostring(item.Visible))
                end)
                if ok then output[#output + 1] = desc end
            end
        end
        local text = table.concat(output, "\n")
        local env = (getgenv and getgenv()) or _G
        local clipboard = env.setclipboard or env.toclipboard or setclipboard or toclipboard
        if type(clipboard) == "function" then
            safe("copy puzzle", function() clipboard(text) end)
        else
            print(text)
        end
        state.lastAction = string.format("已采集 %d 个谜题 GUI 节点；用于验证当前版本结构", count)
    end})
    tabs.generators:AddButton({Title="复制齿轮／开锁动态结构（两次采样）", Callback=function()
        local planner = options.PuzzlePlanner
        local pg = player:FindFirstChildOfClass("PlayerGui")
        local puzzle = pg and pg:FindFirstChild("PuzzleUI")
        if not (planner and planner.InspectDynamic and puzzle) then
            state.lastAction = "请先手动打开齿轮/开锁谜题；当前无有效 PuzzleUI"
            return
        end
        task.spawn(function()
            local ok1, first = pcall(planner.InspectDynamic, puzzle, 260)
            task.wait(0.22)
            if not state.alive then return end
            local ok2, second = pcall(planner.InspectDynamic, puzzle, 260)
            local output = "[PuzzleUI dynamic before]\n" .. tostring(ok1 and first or "failed")
                .. "\n[PuzzleUI dynamic after 0.22s]\n" .. tostring(ok2 and second or "failed")
            local env = (getgenv and getgenv()) or _G
            local clipboard = env.setclipboard or env.toclipboard or setclipboard or toclipboard
            if type(clipboard) == "function" then safe("dynamic copy", function() clipboard(output) end)
            else print(output) end
            state.lastAction = "已采集两次 GUI 属性；用于确认动态指针／齿轮输入规则"
        end)
    end})
    tabs.generators:AddParagraph({Title="修理限制", Content="连线题根据当前 GUI 的真实端点规划路径，尝试执行器虚拟鼠标，并以界面连线变化作为确认。虚拟输入不被支持或不产生实际连线时立即暂停。圆锁/齿轮尚缺当前版本的实时控制信息及操作接口，不能保证自动完成。"})
    return {Destroy = shutdown, State = state, EnumerateGenerators = enumerateGenerators}
end

end)()
local ForsakenPuzzlePlannerFactory = (function()
-- R2.16: read-only Forsaken puzzle inspection and bounded Flow-path planning.
-- This module does not synthesize touches or claim remote/server completion.
return function()
    local planner = {}
    local function rgb(value)
        if not value then return "?" end
        return string.format("%03d,%03d,%03d", math.floor(value.R * 255 + 0.5),
            math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5))
    end
    local function sub(parent, name)
        return parent and parent:FindFirstChild(name)
    end
    local function path(parent, names)
        local item = parent
        for _, name in ipairs(names) do item = sub(item, name) end
        return item
    end
    function planner.Read(puzzle)
        if not puzzle then return nil, "PuzzleUI missing" end
        local container = sub(puzzle, "Container") or puzzle
        local grid = path(container, {"GridHolder", "Grid"})
        if not grid then
            local hasGears = sub(container, "Inventory") or sub(container, "CenterLeft") or sub(container, "CenterRight")
            if hasGears then
                return {phase="gear", cells={}, count=0, maxIndex=0, pairs={}, ambiguous=0,
                    path=puzzle:GetFullName(), container=container}, nil
            end
            return nil, "GridHolder.Grid missing (lock / transition / unknown phase)"
        end
        local source = sub(grid, "Blobs") or grid
        local cells = {}
        local detected = {}
        for _, item in ipairs(source:GetChildren()) do
            local n = tonumber(item.Name)
            if n and n > 0 and n <= 100 and math.floor(n) == n and item:IsA("GuiObject") then
                detected[n] = item
            end
        end
        local count = 0
        for i in pairs(detected) do if i > count then count = i end end
        if count == 0 then return nil, "No numbered grid cells (gear / animation?)" end
        if count > 81 then return nil, "Unsupported grid larger than 9x9" end
        local distinct = 0
        local groups = {}
        for i = 1, count do
            local item = detected[i]
            if item then
                distinct += 1
                local circle = sub(item, "Circle")
                local number = circle and sub(circle, "Number") or sub(item, "Number")
                local markerText = ""
                if number and number:IsA("TextLabel") then
                    markerText = tostring(number.Text or ""):match("^%s*(.-)%s*$") or ""
                end
                local color = circle and rgb(circle.BackgroundColor3) or rgb(item.BackgroundColor3)
                local button = sub(item, "Button")
                local record = {
                    index = i,
                    mark = circle ~= nil or source ~= grid,
                    number = markerText,
                    color = color,
                    button = button ~= nil and button:IsA("GuiButton"),
                    buttonActive = button and button.Active or false,
                    visible = item.Visible,
                }
                cells[#cells + 1] = record
                if circle or source ~= grid then
                    -- Blob labels may be perimeter indices; pair blobs by colour.
                    -- only exactly two identical markers form a candidate pair.
                    local key = (source ~= grid and "color:" .. color)
                            or (markerText ~= "" and "text:" .. markerText or "color:" .. color)
                    if key ~= "color:-" and key ~= "color:?" then
                        groups[key] = groups[key] or {}
                        groups[key][#groups[key] + 1] = i
                    end
                end
            end
        end
        local side = math.floor(math.sqrt(count) + 0.5)
        local square = side * side == count and distinct == count
        local pairedEndpoints, ambiguous = {}, 0
        for key, indexes in pairs(groups) do
            if #indexes == 2 then
                pairedEndpoints[#pairedEndpoints + 1] = {id = key, a = indexes[1], b = indexes[2]}
            else
                ambiguous += 1
            end
        end
        table.sort(pairedEndpoints, function(a, b) return a.id < b.id end)
        return {
            phase = source == grid and "grid" or "blobs", size = square and side or nil,
            cells = cells, count = distinct, maxIndex = count, pairs = pairedEndpoints, ambiguous = ambiguous,
            nodes = detected, grid = grid, container = container,
            path = puzzle:GetFullName(),
        }
    end
    local function dist(n, a, b)
        return math.abs(math.floor((a - 1) / n) - math.floor((b - 1) / n))
            + math.abs((a - 1) % n - (b - 1) % n)
    end
    function planner.Solve(n, pairsList, budget)
        if type(n) ~= "number" or n < 2 or n > 9 or n % 1 ~= 0 then return nil, "invalid size" end
        if type(pairsList) ~= "table" or #pairsList == 0 or #pairsList > 15 then return nil, "invalid pairs" end
        local endpoint, routes, paths = {}, {}, {}
        for k, pair in ipairs(pairsList) do
            local a, b = tonumber(pair.a), tonumber(pair.b)
            if not a or not b or a % 1 ~= 0 or b % 1 ~= 0 or a < 1 or b < 1 or a > n*n or b > n*n or a == b
                or endpoint[a] or endpoint[b] then return nil, "ambiguous endpoints" end
            endpoint[a], endpoint[b] = true, true
            routes[k] = {id = pair.id, a = a, b = b}
        end
        table.sort(routes, function(a, b) return dist(n, a.a, a.b) < dist(n, b.a, b.b) end)
        local occupied, visits, maximum = {}, 0, math.max(100, math.min(tonumber(budget) or 8000, 20000))
        local timedOut = false
        local function adjacent(index, goal)
            local row, col = math.floor((index - 1) / n), (index - 1) % n
            local out = {}
            if row > 0 then out[#out + 1] = index - n end
            if row < n - 1 then out[#out + 1] = index + n end
            if col > 0 then out[#out + 1] = index - 1 end
            if col < n - 1 then out[#out + 1] = index + 1 end
            table.sort(out, function(a, b) return dist(n, a, goal) < dist(n, b, goal) end)
            return out
        end
        local function solvePair(k)
            if k > #routes then return true end
            local pair = routes[k]
            local visited, trace = {[pair.a] = true}, {pair.a}
            local function visit(index)
                visits += 1
                if visits > maximum then timedOut = true; return false end
                if index == pair.b then
                    paths[pair.id] = table.clone(trace)
                    if solvePair(k + 1) then return true end
                    paths[pair.id] = nil
                    return false
                end
                for _, nextIndex in ipairs(adjacent(index, pair.b)) do
                    if not occupied[nextIndex] and not visited[nextIndex]
                        and (not endpoint[nextIndex] or nextIndex == pair.b) then
                        visited[nextIndex] = true
                        occupied[nextIndex] = true
                        trace[#trace + 1] = nextIndex
                        if visit(nextIndex) then return true end
                        trace[#trace] = nil
                        occupied[nextIndex] = nil
                        visited[nextIndex] = nil
                        if timedOut then return false end
                    end
                end
                return false
            end
            return visit(pair.a)
        end
        if solvePair(1) then return paths, "solved", visits end
        return nil, timedOut and "budget exceeded" or "no compatible routes", visits
    end
    -- Sample animated lock needles / gear inventory without reading unrelated game GUI.
    -- Capture twice from a user request; never synthesize input here.
    function planner.InspectDynamic(puzzle, maxItems)
        if not puzzle then return "PuzzleUI missing" end
        local output = {}
        local count = 0
        local limit = math.clamp(tonumber(maxItems) or 240, 40, 320)
        for _, item in ipairs(puzzle:GetDescendants()) do
            if item:IsA("GuiObject") then
                count += 1
                if count > limit then break end
                local ok, line = pcall(function()
                    local text = ""
                    if item:IsA("TextLabel") or item:IsA("TextButton") then text = tostring(item.Text):sub(1,60) end
                    local img = ""
                    if item:IsA("ImageLabel") or item:IsA("ImageButton") then
                        img = tostring(item.Image) .. "@" .. rgb(item.ImageColor3)
                    end
                    local attrs = {}
                    local found = 0
                    for key, val in pairs(item:GetAttributes()) do
                        found += 1
                        if found > 6 then break end
                        attrs[#attrs+1] = tostring(key) .. "=" .. tostring(val):sub(1,28)
                    end
                    local p, sz = item.AbsolutePosition, item.AbsoluteSize
                    return string.format("%s [%s] xy=(%.1f,%.1f) size=(%.1f,%.1f) rot=%.1f visible=%s active=%s bg=%s img=%s text=%s attrs=%s",
                        item.Name, item.ClassName, p.X,p.Y,sz.X,sz.Y,
                        item.Rotation, tostring(item.Visible), tostring(item.Active),
                        rgb(item.BackgroundColor3), img, text, table.concat(attrs,";"))
                end)
                if ok then output[#output+1] = line end
            end
        end
        output[#output+1] = "sampled=" .. tostring(#output) .. " cap=" .. tostring(limit)
        return table.concat(output,"\n")
    end
    function planner.Summary(data)
        if not data then return "没有可以读取的谜题结构" end
        local lines = {
            ("Puzzle phase=%s cells=%d maxIndex=%d side=%s pairs=%d ambiguous=%d"):
                format(data.phase, data.count, data.maxIndex, tostring(data.size or "?"), #data.pairs, data.ambiguous),
        }
        for _, cell in ipairs(data.cells) do
            if cell.mark then
                lines[#lines + 1] = string.format("cell=%d number=%s color=%s button=%s active=%s",
                    cell.index, cell.number, cell.color, tostring(cell.button), tostring(cell.buttonActive))
            end
        end
        if data.phase == "grid" and data.size and #data.pairs > 0 and data.ambiguous == 0 then
            local paths, status, visits = planner.Solve(data.size, data.pairs, 8000)
            lines[#lines + 1] = "planner=" .. tostring(status) .. " nodes=" .. tostring(visits)
            if paths then
                for _, pair in ipairs(data.pairs) do
                    lines[#lines + 1] = pair.id .. "=" .. table.concat(paths[pair.id], "->")
                end
            end
        else
            lines[#lines + 1] = "planner=waiting-for-complete-paired-endpoint-data"
        end
        lines[#lines + 1] = "Input operation / server acknowledgment not captured; automatic actuation disabled."
        return table.concat(lines, "\n")
    end
    return planner
end

end)()
local ForsakenPuzzleAutoFactory = (function()
-- R2.18: bounded, observable Forsaken puzzle path execution.
-- No guessed game remotes. Executes only paired endpoints verified from the current live GUI.
-- Requires an executor capable of virtual mouse input; mobile compatibility varies.
return function(planner, player)
    local worker = {Active = false, Status = "idle", Detail = "", Paths = 0, Failed = 0, LastPhase = "none"}
    local token, held = 0, false
    local lastX, lastY = 0, 0
    local releaseInput
    local inputSource, VIM
    local function inputBackend()
        if inputSource then return inputSource end
        local env = (getgenv and getgenv()) or _G
        local move = env.mousemoveabs or mousemoveabs
        local down = env.mouse1press or mouse1press
        local up = env.mouse1release or mouse1release
        if type(move) == "function" and type(down) == "function" and type(up) == "function" then
            inputSource = {
                name = "executor-mouse",
                move = function(x, y) move(math.floor(x+.5), math.floor(y+.5)) end,
                down = function(x, y) move(math.floor(x+.5), math.floor(y+.5)); down() end,
                up = function() up() end,
            }
            return inputSource
        end
        local ok, service = pcall(function() return game:GetService("VirtualInputManager") end)
        local hasTouch = false
        local uok, userInput = pcall(function() return game:GetService("UserInputService") end)
        if uok and userInput then hasTouch = userInput.TouchEnabled == true end
        -- Prefer a single dedicated touch ID on Android, never a screen-wide overlay.
        -- This API is RobloxScriptSecurity; normal game scripts cannot call it.
        -- An executor must provide access or we fail visibly rather than claiming success.
        if ok and service and hasTouch then
            local have, method = pcall(function() return service.SendTouchEvent end)
            if have and type(method) == "function" then
                local pointerId = 43182
                local begin = Enum.UserInputState.Begin.Value
                local changed = Enum.UserInputState.Change.Value
                local ended = Enum.UserInputState.End.Value
                inputSource = {
                    name = "virtual-touch",
                    move = function(x, y) service:SendTouchEvent(pointerId, changed, x, y) end,
                    down = function(x, y) service:SendTouchEvent(pointerId, begin, x, y) end,
                    up = function(x, y) service:SendTouchEvent(pointerId, ended, x, y) end,
                }
                return inputSource
            end
        end
        local haveMouse, hasMouse = false, false
        if ok and service then
            haveMouse, hasMouse = pcall(function()
                return type(service.SendMouseButtonEvent) == "function"
                    and type(service.SendMouseMoveEvent) == "function"
            end)
        end
        if haveMouse and hasMouse then
            VIM = service
            inputSource = {
                name = "virtual-mouse",
                move = function(x, y) service:SendMouseMoveEvent(x, y, game) end,
                down = function(x, y) service:SendMouseButtonEvent(x, y, 0, true, game, 0) end,
                up = function(x, y) service:SendMouseButtonEvent(x, y, 0, false, game, 0) end,
            }
            return inputSource
        end
        return nil
    end
    local function center(node)
        if not node or not node.Parent then return nil end
        local p, s = node.AbsolutePosition, node.AbsoluteSize
        if not p or not s or s.X < 1 or s.Y < 1 then return nil end
        return math.floor(p.X + s.X * .5), math.floor(p.Y + s.Y * .5)
    end
    local function connected(grid)
        local found, inspected = 0, 0
        for _, element in ipairs(grid:GetDescendants()) do
            inspected += 1
            if inspected > 650 then break end
            local name = element.Name:lower()
            if name:find("line", 1, true) and element:IsA("GuiObject") and element.Visible then
                found += 1
            end
        end
        return found
    end
    local function fingerprint(data)
        local pieces = {data.phase, tostring(data.count)}
        for _, pair in ipairs(data.pairs) do
            pieces[#pieces+1] = tostring(pair.id) .. ":" .. pair.a .. ":" .. pair.b
        end
        return table.concat(pieces, "/")
    end
    local lastFingerprint
    local function live(puzzle, grid)
        if not puzzle.Parent or not grid.Parent
            or (puzzle:IsA("ScreenGui") and not puzzle.Enabled) then return false end
        if type(puzzle.IsA) == "function" and puzzle:IsA("GuiObject") and puzzle.Visible == false then return false end
        if type(grid.IsA) == "function" and grid:IsA("GuiObject") and grid.Visible == false then return false end
        local ok, menuOpen = pcall(function()
            return game:GetService("GuiService").MenuIsOpen
        end)
        return not (ok and menuOpen == true)
    end
    local function drag(path, data, interface, myToken, enabled)
        local first, last
        local function put(node, kind)
            local x, y = center(node)
            if not x then error("grid cell has no screen position") end
            lastX, lastY = x, y
            if kind == "down" then
                interface.move(x, y)
                task.wait(0.035)
                interface.down(x, y)
                held = true
            elseif kind == "move" then
                interface.move(x, y)
            else
                interface.up(x, y)
                held = false
            end
            return x, y
        end
        for i, index in ipairs(path) do
            local node = data.nodes[index]
            if not node then error("missing cell " .. tostring(index)) end
            if myToken ~= token or not enabled() or not live(data.container, data.grid) then
                error("cancelled or puzzle changed")
            end
            if i == 1 then
                put(node, "down")
            else
                put(node, "move")
            end
            last = node
            task.wait(0.055)
        end
        put(last, "up")
        task.wait(0.16)
    end
    local function run(puzzle, enabled, update, myToken)
        local current, message = planner.Read(puzzle)
        if not current then
            worker.Status, worker.Detail = "unsupported", tostring(message)
            update(worker.Status, worker.Detail)
            return
        end
        worker.LastPhase = current.phase
        if current.phase ~= "grid" and current.phase ~= "blobs" then
            worker.Status, worker.Detail = "unsupported", "题型 " .. current.phase .. " 尚缺输入/求解规则"
            update(worker.Status, worker.Detail)
            return
        end
        if current.ambiguous > 0 or #current.pairs == 0 or (current.phase == "grid" and not current.size) then
            worker.Status, worker.Detail = "incomplete", "端点配对不完整或存在歧义"
            update(worker.Status, worker.Detail)
            return
        end
        local fp = fingerprint(current)
        if lastFingerprint == fp then
            worker.Status, worker.Detail = "waiting", "等待下一张不同的谜题界面"
            update(worker.Status, worker.Detail)
            return
        end
        local interface = inputBackend()
        if not interface then
            worker.Status, worker.Detail = "input-unavailable", "执行器未提供受支持的虚拟鼠标接口"
            update(worker.Status, worker.Detail)
            return
        end
        local paths
        if current.phase == "grid" then
            local why
            paths, why = planner.Solve(current.size, current.pairs, 14000)
            if not paths then
                worker.Status, worker.Detail = "unsolved", tostring(why)
                update(worker.Status, worker.Detail)
                return
            end
        else
            paths = {}
            -- This phase has perimeter points and straight, possibly intersecting lines.
            for _, pair in ipairs(current.pairs) do paths[pair.id] = {pair.a, pair.b} end
        end
        local initial = connected(current.grid)
        worker.Status, worker.Detail = "executing", "使用 " .. interface.name .. " 连接端点"
        update(worker.Status, worker.Detail)
        local changed = false
        for _, pair in ipairs(current.pairs) do
            if myToken ~= token or not enabled() then break end
            if not live(puzzle, current.grid) then changed = true; break end
            local route = paths[pair.id]
            if route then
                drag(route, current, interface, myToken, enabled)
                worker.Paths += 1
                local observed = connected(current.grid)
                local confirmed = observed > initial or not live(puzzle, current.grid)
                if confirmed then changed = true end
                initial = observed
                if not confirmed then
                    worker.Failed += 1
                    lastFingerprint = fp -- do not replay an unconfirmed board without reset
                    worker.Status, worker.Detail = "unconfirmed", "模拟输入后未观察到连线产生；已停止避免抢占触控"
                    update(worker.Status, worker.Detail)
                    return
                end
            end
        end
        lastFingerprint = fp -- Do not replay a possibly solved board.
        worker.Status, worker.Detail = "await-next-board", "已执行路径；等待游戏刷新下一谜题或进度"
        update(worker.Status, worker.Detail)
    end
    function worker:Try(puzzle, enabled, update)
        if self.Active then return false end
        if not puzzle or not puzzle.Parent then return false end
        token += 1
        local current = token
        self.Active = true
        task.spawn(function()
            local ok, err = xpcall(function() run(puzzle, enabled, update, current) end, debug.traceback)
            if held then
                local source = inputSource
                if source then pcall(function() source.up(lastX, lastY) end) end
                held = false
            end
            if not ok and current == token then
                self.Failed += 1
                self.Status, self.Detail = "error", tostring(err):sub(1,240)
                update(self.Status, self.Detail)
            end
            self.Active = false
        end)
        return true
    end
    function worker:Stop()
        token += 1
        -- Keep Active until the current coroutine exits to prevent overlapping input jobs.
        if held and inputSource then pcall(function() inputSource.up(lastX, lastY) end) end
        held = false
        self.Status, self.Detail = "stopped", ""
    end
    function worker:Reset()
        lastFingerprint = nil
        self:Stop()
    end
    return worker
end

end)()
-- Vortexion Forsaken R2.5: deliberately small, lifecycle-owned client runtime.
-- The legacy 3,800-line menu, external code loaders and speculative remotes
-- have been retired. Every remaining control owns its side effects.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local user = Players.LocalPlayer
assert(user, "Forsaken: LocalPlayer not ready")
local gui = user:FindFirstChildOfClass("PlayerGui") or user:WaitForChild("PlayerGui", 8)
assert(gui, "Forsaken: PlayerGui unavailable")
local env = (getgenv and getgenv()) or _G
if type(env.VortexionForsakenCleanup) == "function" then
    pcall(env.VortexionForsakenCleanup)
end

local bridge = WindBridgeFactory(WindUI, {Name = "Forsaken", Folder = "VortexionForsaken"})
assert(bridge and bridge.Active, "Forsaken: WindUI bridge unavailable")
local window = bridge:CreateWindow({Title = "Forsaken · R2.16"})
assert(window, "Forsaken: window creation failed")
local tabs = {
    vision = window:AddTab({Title = "感知", Icon = "lucide-eye"}),
    player = window:AddTab({Title = "角色", Icon = "lucide-user"}),
    defense = window:AddTab({Title = "防御", Icon = "lucide-shield"}),
    generators = window:AddTab({Title = "发电机", Icon = "lucide-wrench"}),
    system = window:AddTab({Title = "系统", Icon = "lucide-settings"}),
}
window:InstallSettings(tabs.system)

local puzzlePlanner = type(ForsakenPuzzlePlannerFactory) == "function" and ForsakenPuzzlePlannerFactory() or nil
local puzzleAuto = puzzlePlanner and type(ForsakenPuzzleAutoFactory) == "function"
    and ForsakenPuzzleAutoFactory(puzzlePlanner, user) or nil
local enhancements = ForsakenEnhancementsFactory({Player=user, Bridge=bridge, Tabs=tabs,
    PuzzlePlanner=puzzlePlanner, PuzzleAuto=puzzleAuto})

local state = {alive = true, killers = false, survivors = false,
    generators = false, alert = false, fovEnabled = false, fov = 80,
    killerInfo = false, survivorInfo = false, survivorHP = false,
    traps = false, helpers = false, danger = false,
    dangerText = nil, dangerGui = nil, lastDanger = "none", lastDangerAt = 0,
    hazardCache = {}, hazardCacheAt = 0, labels = {},
    maxDistance = 400, alertDistance = 35, markers = {}, lastAlert = 0,
    occludedTransparency = 65, visibleTransparency = 20,
    markerSeen = setmetatable({}, {__mode = "k"}),
    markerKinds = setmetatable({}, {__mode = "k"}),
    visibilityCache = setmetatable({}, {__mode = "k"}),
    blockedCount = 0, clearCount = 0, stalenessGrace = 1.25,
    ticker = nil, originalFov = setmetatable({}, {__mode="k"}),
    scans = 0, objects = 0, lastProblem = "none",
    candidateCount = 0, inRangeCount = 0, markerFailures = 0,
    lastScanReason = "尚未开始", scanMode = "idle", stateRepairs = 0,
    characterGeneration = 0, spectatorScans = 0, reconcileElapsed = 0,
    watchConnection = nil, lifecycleConnections = {}}
local function report(tag, err)
    local message = tostring(tag) .. ": " .. tostring(err)
    state.lastProblem = message:sub(1, 350)
    warn("[Vortexion/Forsaken] " .. state.lastProblem)
end
local function safe(tag, fn)
    local ok, result = pcall(fn)
    if not ok then report(tag, result) end
    return ok, result
end
local function clearMarker(model)
    local marker = state.markers[model]
    if marker then
        state.markers[model] = nil
        state.markerSeen[model] = nil
        state.markerKinds[model] = nil
        state.visibilityCache[model] = nil
        safe("marker cleanup", function() marker:Destroy() end)
    end
    local label = state.labels[model]
    if label then state.labels[model] = nil; safe("label cleanup", function() label:Destroy() end) end
end
local function clearMarkers()
    for model in pairs(state.markers) do clearMarker(model) end
    state.objects = 0
end
local function restoreFov()
    for camera, fov in pairs(state.originalFov) do
        safe("restore FOV", function() if camera.Parent then camera.FieldOfView = fov end end)
        state.originalFov[camera] = nil
    end
end
local function applyFov()
    if not state.fovEnabled then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    if state.originalFov[camera] == nil then
        state.originalFov[camera] = camera.FieldOfView
    end
    camera.FieldOfView = math.clamp(state.fov, 60, 120)
end
local function getRoot(model)
    if not model or not model.Parent then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso")
end
local function sourceFolders()
    local root = Workspace:FindFirstChild("Players")
    if not root then return nil, nil end
    return root:FindFirstChild("Killers"), root:FindFirstChild("Survivors")
end
local function countReadyCharacters(folder)
    if not folder then return 0, 0 end
    local total, ready = 0, 0
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            total += 1
            if getRoot(child) and child ~= user.Character then
                ready += 1
            end
        end
    end
    return total, ready
end

local function addCandidate(target, model, kind)
    if not model or not model:IsA("Model") or model == user.Character then return end
    if getRoot(model) then target[model] = kind end
end
-- Game-specific visual discovery; bounded and cached to avoid scanning all Workspace at 4Hz.
-- Name patterns are evidence of visible objects, not a proof that a hidden skill fired.
local HAZARD_NAMES = {"subspace", "tripmine", "tripwire", "trap", "spike", "snare", "landmine", "beartrap", "johnspike"}
local HELPER_NAMES = {"pizza", "delivery", "minion", "summoned", "summon", "helpernpc", "deliveryguy"}
local function matchesAny(name, names)
    local low = name:lower()
    for _, needle in ipairs(names) do if low:find(needle, 1, true) then return true end end
    return false
end
local function sceneryCandidates()
    local now = os.clock()
    if now - state.hazardCacheAt < 1.0 then return state.hazardCache end
    state.hazardCacheAt = now
    local found = {}
    local map = Workspace:FindFirstChild("Map")
    local ingame = map and map:FindFirstChild("Ingame")
    local roots = {
        ingame and ingame:FindFirstChild("Map"),
        ingame and ingame:FindFirstChild("Effects"),
        Workspace:FindFirstChild("Effects"),
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Minions"),
        Workspace:FindFirstChild("Traps"),
        Workspace:FindFirstChild("Projectiles"),
    }
    local visited, budget = {}, 650
    for _, root in pairs(roots) do
        if root then
            local stack = {root}
            while #stack > 0 and budget > 0 do
                local node = table.remove(stack)
                if not visited[node] then
                    visited[node] = true
                    budget -= 1
                    if node:IsA("Model") or node:IsA("BasePart") then
                        local kind = matchesAny(node.Name, HAZARD_NAMES) and "Trap"
                            or matchesAny(node.Name, HELPER_NAMES) and "Helper" or nil
                        if kind == "Helper" and not (node:IsA("Model")
                            and (node:FindFirstChildOfClass("Humanoid")
                                or node:FindFirstChild("HumanoidRootPart"))) then
                            kind = nil -- Do not mistake pizza decals and particles for NPCs.
                        end
                        if kind and (node:IsA("BasePart") or node.PrimaryPart
                            or node:FindFirstChildWhichIsA("BasePart")) then
                            found[node] = kind
                        end
                    end
                    if #stack < 700 then
                        for _, child in ipairs(node:GetChildren()) do
                            -- Inspect BasePart children too, but don't descend into their
                            -- large decorative attachments; still bounded to 650 objects.
                            table.insert(stack, child)
                        end
                    end
                end
            end
        end
    end
    state.hazardCache = found
    return found
end
local function infoValue(model, keys)
    for _, key in ipairs(keys) do
        local att = model:GetAttribute(key)
        if type(att) == "string" and att ~= "" then return att end
        local child = model:FindFirstChild(key)
        if child and child:IsA("StringValue") and child.Value ~= "" then return child.Value end
    end
    return nil
end
local function ensureLabel(model, anchorPart)
    local label = state.labels[model]
    if label and label.Parent and label.Adornee == anchorPart then return label end
    if label then label:Destroy() end
    label = Instance.new("BillboardGui")
    label.Name = "VortexionInfo"
    label.Adornee = anchorPart
    label.AlwaysOnTop = true
    label.Size = UDim2.fromOffset(190, 46)
    label.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    label.MaxDistance = math.min(state.maxDistance, 450)
    local text = Instance.new("TextLabel")
    text.Name = "Content"
    text.BackgroundTransparency = 1
    text.TextScaled = false
    text.TextSize = 13
    text.Font = Enum.Font.GothamBold
    text.TextStrokeTransparency = 0.35
    text.TextColor3 = Color3.fromRGB(245, 245, 245)
    text.Size = UDim2.fromScale(1, 1)
    text.TextWrapped = true
    text.Parent = label
    label.Parent = anchorPart
    state.labels[model] = label
    return label
end
local function updateLabel(model, kind, part)
    local show = (kind == "Killer" and state.killerInfo)
        or (kind == "Survivor" and (state.survivorInfo or state.survivorHP))
        or ((kind == "Trap" or kind == "Helper") and true)
    if not show then
        local old = state.labels[model]
        if old then old:Destroy(); state.labels[model] = nil end
        return
    end
    local parts = {}
    if kind == "Killer" or kind == "Survivor" then
        if (kind == "Killer" and state.killerInfo) or (kind == "Survivor" and state.survivorInfo) then
            local role = infoValue(model, {"CharacterName", "Character", "Role", "Class"}) or model.Name
            local skin = infoValue(model, {"SkinName", "Skin", "EquippedSkin", "CurrentSkin"})
            table.insert(parts, role .. (skin and ("  /  " .. skin) or "  /  皮肤未公开"))
        end
        if kind == "Survivor" and state.survivorHP then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum then table.insert(parts, string.format("HP %.0f/%.0f", hum.Health, hum.MaxHealth)) end
        end
    else
        table.insert(parts, (kind == "Trap" and "陷阱: " or "召唤物: ") .. model.Name)
    end
    if #parts == 0 then
        local old = state.labels[model]
        if old then old:Destroy(); state.labels[model] = nil end
        return
    end
    local label = ensureLabel(model, part)
    local content = label:FindFirstChild("Content")
    if content then
        local value = table.concat(parts, "\n")
        if content.Text ~= value then content.Text = value end
    end
end
local function ensureDangerBanner()
    if state.dangerGui and state.dangerGui.Parent then return end
    local screen = Instance.new("ScreenGui")
    screen.Name = "VortexionDangerNotice"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = false
    screen.DisplayOrder = 3
    local label = Instance.new("TextLabel")
    label.Name = "Warning"
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.fromScale(0.5, 0.09)
    label.Size = UDim2.fromOffset(310, 34)
    label.BackgroundColor3 = Color3.fromRGB(45, 15, 15)
    label.BackgroundTransparency = 0.25
    label.TextColor3 = Color3.fromRGB(255, 205, 170)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Active = false
    label.Selectable = false
    label.Visible = false
    label.Parent = screen
    screen.Parent = gui
    state.dangerGui, state.dangerText = screen, label
end
local function candidates()
    local selected = {}
    local killers, survivors = sourceFolders()
    if state.killers or state.alert or state.killerInfo or state.danger then
        if killers then for _, model in ipairs(killers:GetChildren()) do addCandidate(selected, model, "Killer") end end
    end
    if state.survivors or state.survivorInfo or state.survivorHP then
        if survivors then for _, model in ipairs(survivors:GetChildren()) do addCandidate(selected, model, "Survivor") end end
    end
    if state.generators and enhancements and type(enhancements.EnumerateGenerators) == "function" then
        for _, model in ipairs(enhancements.EnumerateGenerators()) do
            if model.Parent and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) then
                selected[model] = "Generator"
            end
        end
    end
    if state.traps or state.helpers or state.danger then
        for obj, kind in pairs(sceneryCandidates()) do
            if obj.Parent and ((kind == "Trap" and (state.traps or state.danger))
                or (kind == "Helper" and state.helpers)) then
                selected[obj] = kind
            end
        end
    end
    return selected
end
-- Roblox Highlight has one FillTransparency value. It cannot directly assign
-- separate transparency for occluded and unobstructed pixels simultaneously.
-- A bounded camera raycast selects the applicable alpha per target (4 Hz),
-- while DepthMode=AlwaysOnTop allows the occluded highlight to remain visible.
local function blockedByWorld(model, part, camera)
    if not camera or not camera.CFrame then return false end
    local origin = camera.CFrame.Position
    local direction = part.Position - origin
    if direction.Magnitude <= 0.25 then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = user.Character and {user.Character} or {}
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, params)
    return result ~= nil and not result.Instance:IsDescendantOf(model)
end
local function alphaFor(model, part, camera)
    local now = os.clock()
    local cache = state.visibilityCache[model]
    local ok, obstructed = safe("occlusion raycast", function()
        return blockedByWorld(model, part, camera)
    end)
    if not ok then return state.visibleTransparency / 100 end
    if cache and cache.blocked ~= obstructed then
        if cache.pending == obstructed then
            cache.samples = cache.samples + 1
        else
            cache.pending, cache.samples = obstructed, 1
        end
        if cache.samples >= 2 then
            cache.blocked, cache.pending, cache.samples = obstructed, nil, 0
        end
    elseif not cache then
        cache = {blocked = obstructed, pending = nil, samples = 0}
        state.visibilityCache[model] = cache
    else
        cache.pending, cache.samples = nil, 0
    end
    if cache.blocked then
        state.blockedCount += 1
    else
        state.clearCount += 1
    end
    return (cache.blocked and state.occludedTransparency or state.visibleTransparency) / 100
end
local function markerFor(model, kind, part, camera)
    local existing = state.markers[model]
    if existing and not existing.Parent then
        state.markers[model] = nil
        existing = nil
    end
    local highlight = existing
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "VortexionMarker"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = model
        highlight.FillColor = kind == "Killer" and Color3.fromRGB(235, 78, 78)
            or kind == "Survivor" and Color3.fromRGB(78, 176, 121)
            or kind == "Trap" and Color3.fromRGB(255, 120, 45)
            or kind == "Helper" and Color3.fromRGB(186, 109, 240)
            or Color3.fromRGB(245, 191, 85)
        highlight.OutlineColor = highlight.FillColor
        highlight.Parent = model
        state.markers[model] = highlight
    end
    local alpha = alphaFor(model, part, camera)
    highlight.FillTransparency = alpha
    highlight.OutlineTransparency = alpha
    state.markerKinds[model] = kind
    updateLabel(model, kind, part)
    return highlight
end
local function tickVisual()
    state.scans += 1
    state.candidateCount, state.inRangeCount = 0, 0
    state.blockedCount, state.clearCount = 0, 0
    -- The camera is an independent observer during death/spectate. Do not
    -- disable ESP merely because the player's previous character was removed.
    local playerRoot = getRoot(user.Character)
    local humanoid = user.Character and user.Character:FindFirstChildOfClass("Humanoid")
    local aliveCharacter = playerRoot and (not humanoid or humanoid.Health > 0)
    local camera = Workspace.CurrentCamera
    local origin = aliveCharacter and playerRoot.Position
        or (camera and camera.CFrame and camera.CFrame.Position)
    if not origin then
        state.scanMode = "no-origin"
        state.lastScanReason = "没有有效角色或观战相机"
        clearMarkers()
        return
    end
    if aliveCharacter then
        state.scanMode = "character"
        state.lastScanReason = "存活角色扫描"
    else
        state.scanMode = "spectator"
        state.spectatorScans += 1
        state.lastScanReason = "观战相机扫描"
    end
    local required = candidates()
    local visible = {}
    local now = os.clock()
    local budget = 32 -- Bound per-refresh allocations on mobile.
    local nearestThreat
    local nearestHazard, nearestHazardName
    for model, kind in pairs(required) do
        state.candidateCount += 1
        -- Trap candidates can be BasePart instances; only Model has PrimaryPart.
        local root = model:IsA("BasePart") and model
            or (getRoot(model) or (model:IsA("Model") and model.PrimaryPart)
                or model:FindFirstChildWhichIsA("BasePart"))
        if root and root:IsA("BasePart") then
            local distance = (root.Position - origin).Magnitude
            if kind == "Killer" and distance <= state.alertDistance then
                nearestThreat = math.min(nearestThreat or math.huge, distance)
            end
            if kind == "Trap" and distance <= 85 and (not nearestHazard or distance < nearestHazard) then
                nearestHazard, nearestHazardName = distance, model.Name
            end
            local show = (kind == "Killer" and (state.killers or state.killerInfo))
                or (kind == "Survivor" and (state.survivors or state.survivorInfo or state.survivorHP))
                or (kind == "Generator" and state.generators)
                or (kind == "Trap" and state.traps)
                or (kind == "Helper" and state.helpers)
            local exitHysteresis = state.markers[model] and 40 or 0
            if show and distance <= state.maxDistance + exitHysteresis then
                state.inRangeCount += 1
                if budget > 0 then
                    budget -= 1
                    local ok = safe("highlight", function() markerFor(model, kind, root, camera) end)
                    if ok then
                        visible[model] = true
                        state.markerSeen[model] = now
                    else state.markerFailures = state.markerFailures + 1 end
                end
            end
        end
    end
    for model in pairs(state.markers) do
        -- A temporary missing model, camera switch, or distance crossing should
        -- not destroy/recreate the highlight on every 250 ms scan.
        local kind = state.markerKinds[model]
        local enabled = (kind == "Killer" and (state.killers or state.killerInfo))
            or (kind == "Survivor" and (state.survivors or state.survivorInfo or state.survivorHP))
            or (kind == "Generator" and state.generators)
            or (kind == "Trap" and state.traps)
            or (kind == "Helper" and state.helpers)
        if not model.Parent or not enabled or
            (not visible[model] and now - (state.markerSeen[model] or 0) > state.stalenessGrace) then
            clearMarker(model)
        end
    end
    local count = 0
    for _ in pairs(state.markers) do count += 1 end
    state.objects = count
    if state.danger then
        ensureDangerBanner()
        local warning = nil
        if nearestHazard then
            warning = string.format("疑似陷阱 %s（%.0f studs）", nearestHazardName, nearestHazard)
        elseif nearestThreat and nearestThreat <= state.alertDistance then
            warning = string.format("杀手接近（%.0f studs）", nearestThreat)
        end
        if state.dangerText then
            state.dangerText.Visible = warning ~= nil
            if warning and state.dangerText.Text ~= warning then state.dangerText.Text = warning end
        end
        state.lastDanger = warning or "none"
    elseif state.dangerText then
        state.dangerText.Visible = false
    end
    if state.alert and nearestThreat and os.clock() - state.lastAlert > 5 then
        state.lastAlert = os.clock()
        bridge:Notify({Title="附近有杀手", Content=("距离约 %d studs"):format(nearestThreat), Duration=2})
    end
end
local function refreshScheduler()
    local enabled = state.killers or state.survivors or state.generators or state.alert or state.fovEnabled
        or state.traps or state.helpers or state.danger or state.killerInfo or state.survivorInfo or state.survivorHP
    if not enabled and state.ticker then state.ticker:Disconnect(); state.ticker=nil end
    if not enabled then
        state.scanMode = "off"
        state.lastScanReason = "感知功能关闭"
        clearMarkers()
        return
    end
    if state.ticker then return end
    local accumulated = 0
    state.ticker = RunService.Heartbeat:Connect(function(dt)
        if not state.alive then return end
        accumulated += math.min(dt, 0.3)
        if accumulated < 0.25 then return end -- 4Hz max, disabled = zero listeners.
        accumulated = 0
        safe("refresh", function()
            applyFov()
            if state.killers or state.survivors or state.generators or state.alert
                or state.traps or state.helpers or state.danger or state.killerInfo
                or state.survivorInfo or state.survivorHP then tickVisual() end
        end)
    end)
end
local function shutdown()
    if not state.alive then return end
    state.alive = false
    if enhancements then enhancements:Destroy() end
    if state.ticker then state.ticker:Disconnect(); state.ticker = nil end
    if state.watchConnection then state.watchConnection:Disconnect(); state.watchConnection = nil end
    for _, connection in ipairs(state.lifecycleConnections) do
        connection:Disconnect()
    end
    table.clear(state.lifecycleConnections)
    clearMarkers()
    if state.dangerGui then state.dangerGui:Destroy(); state.dangerGui = nil; state.dangerText = nil end
    restoreFov()
    if env.VortexionForsakenCleanup == shutdown then env.VortexionForsakenCleanup = nil end
end
env.VortexionForsakenCleanup = shutdown
bridge:OnDestroy(shutdown)
if type(bridge.RegisterFeatureHealth) == "function" then
    bridge:RegisterFeatureHealth("Forsaken", function()
        return ("活跃=%s 杀手=%s 幸存者=%s 发电机=%s 扫描=%d 标记=%d 观战扫描=%d 最近问题=%s")
            :format(tostring(state.alive), tostring(state.killers), tostring(state.survivors),
                tostring(state.generators), state.scans, state.objects, state.spectatorScans,
                tostring(state.lastProblem))
    end)
end

tabs.vision:AddParagraph({Title="运行架构", Content="感知与新增角色/防御/发电机功能均可独立开关，关闭后释放临时资源。"})
tabs.vision:AddToggle("FsKillerESP", {Title="杀手高亮", Default=false,
    Callback=function(v) state.killers=v; refreshScheduler() end})
tabs.vision:AddToggle("FsSurvivorESP", {Title="幸存者高亮", Default=false,
    Callback=function(v) state.survivors=v; refreshScheduler() end})
tabs.vision:AddToggle("FsGeneratorESP", {Title="发电机高亮", Default=false,
    Callback=function(v) state.generators=v; refreshScheduler() end})
tabs.vision:AddToggle("FsKillerIdentityR214", {Title="杀手角色及皮肤", Default=false,
    Callback=function(v) state.killerInfo=v; refreshScheduler() end})
tabs.vision:AddToggle("FsSurvivorIdentityR214", {Title="幸存者角色及皮肤", Default=false,
    Callback=function(v) state.survivorInfo=v; refreshScheduler() end})
tabs.vision:AddToggle("FsSurvivorHPR214", {Title="幸存者血量", Default=false,
    Callback=function(v) state.survivorHP=v; refreshScheduler() end})
tabs.vision:AddToggle("FsTrapsR214", {Title="陷阱显示（仅已复制对象）", Default=false,
    Callback=function(v) state.traps=v; refreshScheduler() end})
tabs.vision:AddToggle("FsHelpersR214", {Title="杀手帮手机器人显示", Default=false,
    Callback=function(v) state.helpers=v; refreshScheduler() end})
tabs.vision:AddToggle("FsDangerR214", {Title="危险提示（已复制的危险对象）", Default=false,
    Callback=function(v) state.danger=v; if not v and state.dangerText then state.dangerText.Visible=false end; refreshScheduler() end})
tabs.vision:AddParagraph({Title="危险判断范围", Content="根据地图中实际复制的陷阱模型和附近杀手提供提示；服务器隐藏的技能释放不可直接判断。"})
-- Reconcile the three layers (native WindUI, bridge option, gameplay state).
-- The user's preference is intentionally NOT cleared on CharacterRemoving,
-- Humanoid.Died or spectator camera transitions.
local function synchronizeVisionOptions()
    local settings = {
        {"FsKillerESP", "killers"},
        {"FsSurvivorESP", "survivors"},
        {"FsGeneratorESP", "generators"},
        {"FsKillerWarning", "alert"},
        {"FsKillerIdentityR214", "killerInfo"},
        {"FsSurvivorIdentityR214", "survivorInfo"},
        {"FsSurvivorHPR214", "survivorHP"},
        {"FsTrapsR214", "traps"},
        {"FsHelpersR214", "helpers"},
        {"FsDangerR214", "danger"},
    }
    local changed = false
    for _, entry in ipairs(settings) do
        local option = bridge.Options and bridge.Options[entry[1]]
        if option then
            if type(option.SyncFromNative) == "function" then
                safe("native sync " .. entry[1], function() option:SyncFromNative() end)
            end
            if type(option.Value) == "boolean" and state[entry[2]] ~= option.Value then
                state[entry[2]] = option.Value
                state.stateRepairs += 1
                changed = true
            end
        end
    end
    if changed then refreshScheduler() end
end

local function bindCharacterLifecycle(character)
    state.characterGeneration += 1
    clearMarkers()
    state.lastScanReason = "角色变化，等待重新扫描"
    -- The scanner and preferences remain alive through spectator transitions.
end
if user.CharacterAdded then
    table.insert(state.lifecycleConnections, user.CharacterAdded:Connect(bindCharacterLifecycle))
end
if user.CharacterRemoving then
    table.insert(state.lifecycleConnections, user.CharacterRemoving:Connect(function()
        clearMarkers()
        state.scanMode = "spectator"
        state.lastScanReason = "角色已移除，等待观战相机"
    end))
end
state.watchConnection = RunService.Heartbeat:Connect(function(dt)
    if not state.alive then return end
    state.reconcileElapsed += math.min(dt, 0.5)
    if state.reconcileElapsed < 1 then return end
    state.reconcileElapsed = 0
    synchronizeVisionOptions()
end)

tabs.vision:AddSlider("FsVisionDistance", {Title="高亮距离", Min=40, Max=600, Default=400, Rounding=0,
    Callback=function(v) state.maxDistance=v end})
tabs.vision:AddSlider("FsOccludedAlphaR213", {Title="ESP 遮挡时透明度 (%)", Min=0, Max=100,
    Default=65, Rounding=0, Callback=function(v) state.occludedTransparency = math.clamp(v, 0, 100) end})
tabs.vision:AddSlider("FsVisibleAlphaR213", {Title="ESP 无遮挡时透明度 (%)", Min=0, Max=100,
    Default=20, Rounding=0, Callback=function(v) state.visibleTransparency = math.clamp(v, 0, 100) end})
tabs.vision:AddParagraph({Title="ESP 透明度说明", Content="0% 完全不透明，100% 完全透明。通过限频射线检测遮挡，并提供短暂保留以减少闪烁。"})
tabs.vision:AddToggle("FsKillerWarning", {Title="附近杀手预警", Default=false,
    Callback=function(v) state.alert=v; refreshScheduler() end})
tabs.vision:AddSlider("FsWarningDistance", {Title="预警距离", Min=10, Max=100, Default=35, Rounding=0,
    Callback=function(v) state.alertDistance=v end})

tabs.player:AddToggle("FsCameraFov", {Title="自定义视场角", Default=false,
    Callback=function(v) state.fovEnabled=v; if not v then restoreFov() end; refreshScheduler(); if v then safe("FOV",applyFov) end end})
tabs.player:AddSlider("FsCameraFovValue", {Title="视场角 (60–120)", Min=60, Max=120, Default=80, Rounding=0,
    Callback=function(v) state.fov=v; if state.fovEnabled then safe("FOV", applyFov) end end})

tabs.system:AddButton({Title="检查游戏结构", Callback=function()
    local killers,survivors=sourceFolders()
    local kTotal,kReady=countReadyCharacters(killers)
    local sTotal,sReady=countReadyCharacters(survivors)
    local enabled=state.killers or state.survivors or state.generators or state.alert or state.traps or state.helpers or state.danger
    synchronizeVisionOptions()
    enabled=state.killers or state.survivors or state.generators or state.alert
    local mode=enabled and "扫描中" or "感知开关关闭（不扫描）"
    local function optionInfo(id, field)
        local option = bridge.Options and bridge.Options[id]
        local native = nil
        if option and type(option.GetNativeValue) == "function" then
            native = option:GetNativeValue()
        end
        return string.format("%s:UI=%s Bridge=%s Runtime=%s", field,
            tostring(native), tostring(option and option.Value), tostring(state[field]))
    end
    local msg = ("Killers=%s %d/%d Survivors=%s %d/%d Markers=%d Refresh=%d %s Error=%s\n" ..
        "%s / %s / %s\n模式=%s 原因=%s 状态修复=%d 角色代次=%d 观战扫描=%d 候选=%d 范围内=%d 高亮异常=%d")
        :format(tostring(killers~=nil), kReady, kTotal,
            tostring(survivors~=nil), sReady, sTotal,
            state.objects, state.scans, mode, state.lastProblem,
            optionInfo("FsKillerESP", "Killer"),
            optionInfo("FsSurvivorESP", "Survivor"),
            optionInfo("FsGeneratorESP", "Generator"),
            state.scanMode, state.lastScanReason, state.stateRepairs,
            state.characterGeneration, state.spectatorScans,
            state.candidateCount, state.inRangeCount, state.markerFailures)
    msg = msg .. string.format("\n危险=%s 标签=%s", tostring(state.lastDanger), tostring(state.labels ~= nil))
    msg = msg .. string.format("\n遮挡检测=%d 无遮挡检测=%d 遮挡透明度=%d%% 无遮挡透明度=%d%%",
        state.blockedCount, state.clearCount, state.occludedTransparency, state.visibleTransparency)
    bridge:Notify({Title="Forsaken 诊断", Content=msg, Duration=12})
end})
tabs.system:AddButton({Title="重进当前游戏", Callback=function()
    safe("rejoin",function() TeleportService:Teleport(game.PlaceId, user) end)
end})
tabs.system:AddButton({Title="卸载 Forsaken 功能", Callback=function()
    shutdown()
    bridge:Destroy()
end})
tabs.system:AddParagraph({Title="运行限制", Content="场景结构可能随游戏更新变化。检测不到目标时会保持空状态，不会伪造功能成功；未进行 Roblox 安卓实测。"})
window:SelectTab(1)
bridge:Notify({Title="Forsaken", Content="R2.14 已加载；感知功能需手动开启，菜单场景没有角色模型时不会生成标记", Duration=5})

end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "Forsaken")
