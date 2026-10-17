-- Vortexion - Forsaken · WindUI 中文手机版 (based on NumanLUAU/Goonsaken-Hub, source 2026-05-13)
-- Community modification: UI localization + Android touch compatibility.
-- No guarantee of executor compatibility or live-game feature support.
-- Phase 1 has no published independent loader yet; NEVER reload the old repo on teleport.
-- Phase 2 will populate this with the verified standalone GitHub raw URL.
local hubLoader = nil
if type(hubLoader) == "string" and hubLoader ~= "" then
    if queue_on_teleport then
        queue_on_teleport(hubLoader)
    elseif syn and syn.queue_on_teleport then
        syn.queue_on_teleport(hubLoader)
    end
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RNG = Random.new()
-- v8: stop previous session's throttled background jobs on reinjection.
local sessionEnv = (getgenv and getgenv()) or _G
if type(sessionEnv.VortexionForsakenCleanup) == "function" then
    pcall(sessionEnv.VortexionForsakenCleanup)
end
sessionEnv.VortexionSessionId = (sessionEnv.VortexionSessionId or 0) + 1
local thisSessionId = sessionEnv.VortexionSessionId
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local TextChatService = game:GetService("TextChatService")
local chatWindow = TextChatService:FindFirstChild("ChatWindowConfiguration")
local Do1x1PopupsLoop = false
local AntiSlow = false
local hubLoaded = false
local timeforonegen = 2.5
local loopgen = false
local autofixgenerator = false
local infinitestamina
local ChargeSpeedLoop = false
local GuestChargeSpeed = 2.833
local Sprinting
local stamina
-- Throttled task runner
local function runEvery(interval, fn)
    task.spawn(function()
        while sessionEnv.VortexionSessionId == thisSessionId do
            local ok, err = pcall(fn)
            if not ok then warn("[runEvery]", err) end
            task.wait(interval)
        end
    end)
end

-- Simple connection bucket so we can clean up safely if needed
local Connections = {}
local function track(conn)
    -- Retain active connections only across repeated native UI toggles.
    for i = #Connections, 1, -1 do
        if not Connections[i].Connected then table.remove(Connections, i) end
    end
    table.insert(Connections, conn)
    return conn
end
local function disconnectAll()
    for i = #Connections, 1, -1 do local c = Connections[i]
        if c and c.Disconnect then pcall(function() c:Disconnect() end) end
        Connections[i] = nil
    end
end


local executor = sessionEnv.identifyexecutor and sessionEnv.identifyexecutor() or "RobloxClientApp"

--[[
if executor == "Xeno" or executor == "Velocity" or executor == "LX63" then
	print("This script and game will NOT work on " .. tostring(executor) .. " as the entire game will break if you inject it even without loading a script. It's recommended to use Swift as it supports the require function. and the game often calls a require function everytime you spawn in as a killer or survivor since the game needs to load in the stamina module as well as sprinting and abilities so when your executor injects this. it will fail on requiring the stamina module and the game will halt without being able to load anything else.")
	return
end
]]--

local ORIGINAL_DASH_SPEED = 60

local isOverrideActive = false
local connection
local dashHumanoid, dashSaved = nil, {}
local function restoreDash(hum)
    local saved = hum and dashSaved[hum]
    if not saved then return end
    pcall(function()
        hum.WalkSpeed, hum.AutoRotate = saved.WalkSpeed, saved.AutoRotate
        hum:Move(Vector3.zero)
    end)
    dashSaved[hum] = nil
end
local function startvoidrushcontrol()
    if isOverrideActive then return end
    isOverrideActive = true
    connection = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if dashHumanoid ~= hum then restoreDash(dashHumanoid); dashHumanoid = hum end
        if not (hum and root and hum.Health > 0) then return end
        if not dashSaved[hum] then dashSaved[hum] = {WalkSpeed = hum.WalkSpeed, AutoRotate = hum.AutoRotate} end
        hum.WalkSpeed, hum.AutoRotate = ORIGINAL_DASH_SPEED, false
        local direction = root.CFrame.LookVector
        local horizontal = Vector3.new(direction.X, 0, direction.Z)
        hum:Move(horizontal.Magnitude > 0.01 and horizontal.Unit or Vector3.new(0, 0, -1))
    end)
    track(connection)
end
local function stopvoidrushcontrol()
    isOverrideActive = false
    if connection then connection:Disconnect(); connection = nil end
    for hum in pairs(dashSaved) do restoreDash(hum) end
    dashHumanoid = nil
end

local function fireproximityprompt(Obj, Amount, Skip)
    if Obj.ClassName == "ProximityPrompt" then 
        Amount = Amount or 1
        local PromptTime = Obj.HoldDuration
        if Skip then 
            Obj.HoldDuration = 0
        end
        for i = 1, Amount do 
            Obj:InputHoldBegin()
            if not Skip then 
                task.wait(Obj.HoldDuration)
            end
            Obj:InputHoldEnd()
        end
        Obj.HoldDuration = PromptTime
    else 
        error("userdata<ProximityPrompt> expected")
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local NameProtectActive = false
local function NameProtect()
	while NameProtectActive do
		task.wait(0.3)
        local gui = LocalPlayer.PlayerGui
        if not gui then return end

        --  TemporaryUI.PlayerInfo.CurrentSurvivors -> Username
        local currentSurvivors = gui:FindFirstChild("TemporaryUI") 
            and gui.TemporaryUI:FindFirstChild("PlayerInfo") 
            and gui.TemporaryUI.PlayerInfo:FindFirstChild("CurrentSurvivors")

        if currentSurvivors then
            for _, v in pairs(currentSurvivors:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Username" then
                    v.Text = "Protected"
                end
            end
        end

        --  TemporaryUI -> any TextLabel named "Title3"
        local tempUI = gui:FindFirstChild("TemporaryUI")
        if tempUI then
            for _, v in pairs(tempUI:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Title3" then
                    v.Text = "Protected"
                end
            end
        end

        --  MainUI.PlayerListHolder.Contents.Players -> Username
        local mainPlayers = gui:FindFirstChild("MainUI") 
            and gui.MainUI:FindFirstChild("PlayerListHolder") 
            and gui.MainUI.PlayerListHolder:FindFirstChild("Contents") 
            and gui.MainUI.PlayerListHolder.Contents:FindFirstChild("Players")

        if mainPlayers then
            for _, v in pairs(mainPlayers:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Username" then
                    v.Text = "Protected"
                end
            end
        end

        --  TemporaryUI -> PlayerName / PlayerUsername text labels matching LocalPlayer usernames
        if tempUI then
            for _, v in pairs(tempUI:GetDescendants()) do
                if v:IsA("TextLabel") and (v.Name == "PlayerName" or v.Name == "PlayerUsername") then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if v.Text == plr.Name then
                            v.Text = "Protected"
                            v.Text = "@Protected" -- optional
                        end
                    end
                end
            end
        end

        --  Workspace.Players.Spectating -> humanoids, set DisplayDistanceType to None
        local spectatingFolder = workspace:FindFirstChild("Players") 
            and workspace.Players:FindFirstChild("Spectating")

        if spectatingFolder then
            for _, char in pairs(spectatingFolder:GetChildren()) do
                local humanoid = char:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                end
            end
        end

        --  ImageLabels named after LocalPlayers
        for _, plr in pairs(Players:GetPlayers()) do
            local imgLabel = gui:FindFirstChild(plr.Name, true) -- recursive
            if imgLabel and imgLabel:IsA("ImageLabel") then
                local basicInfo = imgLabel:FindFirstChild("BasicInfo")
                if basicInfo then
                    local nameLabel = basicInfo:FindFirstChild("PlayerName")
                    if nameLabel and nameLabel:IsA("TextLabel") then
                        nameLabel.Text = "Protected"
                    end
                    local usernameLabel = basicInfo:FindFirstChild("PlayerUsername")
                    if usernameLabel and usernameLabel:IsA("TextLabel") then
                        usernameLabel.Text = "Protected"
                    end
                end
            end
        end

        --  MainUI.Spectate -> Username
        local spectateUI = gui:FindFirstChild("MainUI") 
            and gui.MainUI:FindFirstChild("Spectate")

        if spectateUI then
            for _, v in pairs(spectateUI:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Username" then
                    v.Text = "Protected"
                end
            end
        end

        --  EndScreen -> ChosenValue.Title
        local chosenTitle = gui:FindFirstChild("EndScreen")
            and gui.EndScreen:FindFirstChild("Main")
            and gui.EndScreen.Main:FindFirstChild("PlayerStats")
            and gui.EndScreen.Main.PlayerStats:FindFirstChild("Header")
            and gui.EndScreen.Main.PlayerStats.Header:FindFirstChild("PlayerDropdown")
            and gui.EndScreen.Main.PlayerStats.Header.PlayerDropdown:FindFirstChild("DropdownFrame")
            and gui.EndScreen.Main.PlayerStats.Header.PlayerDropdown.DropdownFrame:FindFirstChild("ChosenValue")
            and gui.EndScreen.Main.PlayerStats.Header.PlayerDropdown.DropdownFrame.ChosenValue:FindFirstChild("Title")

        if chosenTitle and chosenTitle:IsA("TextLabel") then
            chosenTitle.Text = "Protected"
        end

        --  EndScreen.WinnerTitle.Usernames
        local winnerUsernames = gui:FindFirstChild("EndScreen")
            and gui.EndScreen:FindFirstChild("WinnerTitle")
            and gui.EndScreen.WinnerTitle:FindFirstChild("Usernames")

        if winnerUsernames and winnerUsernames:IsA("TextLabel") then
            winnerUsernames.Text = "Protected"
        end
	end
end

local multiplierNames = {
    "FallSlowness",
    "Medkit",
    "BloxyColaItem",
	"GuestBlocking",
	"BeheadAbility",
	"GuestChargeEnded"
}

-- Function to check and force multipliers
local function enforceMultipliers()
    local character = LocalPlayer.Character
    if not character then return end

    local speedMultipliers = character:FindFirstChild("SpeedMultipliers")
    if not speedMultipliers then return end

    for _, name in ipairs(multiplierNames) do
        local mult = speedMultipliers:FindFirstChild(name)
        if mult then
            mult.Value = 1
        end
    end
end

local function firetouchinterest(totouch, whattotouchwith,nilvalue)
    pcall(function()
        local clone = totouch:Clone()
        local orgpos = totouch.CFrame
        totouch.CFrame = whattotouchwith.CFrame
        task.wait(0.5)
        totouch.CFrame = orgpos
        clone:Destroy()
    end)
end

track(LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if LocalPlayer.Character ~= char or sessionEnv.VortexionSessionId ~= thisSessionId then return end
    Humanoid, HumanoidRootPart = hum, root
    Animator = hum and hum:FindFirstChildOfClass("Animator")
end))

local function checkAndSetSlowStatus()
    if AntiSlow == false then
        return
    end
	local Character = LocalPlayer.Character
	if not Character then return end
	local Humanoid = Character:WaitForChild("Humanoid")

    local speedMultipliers = Character:FindFirstChild("SpeedMultipliers")
    if not speedMultipliers then return end

    local slowedStatus = speedMultipliers:FindFirstChild("SlowedStatus")
    if not slowedStatus or not slowedStatus:IsA("NumberValue") then return end

    slowedStatus.Value = 1

    local fovMultipliers = Character:FindFirstChild("FOVMultipliers")
    if not fovMultipliers then return end

    local fovSlowedStatus = fovMultipliers:FindFirstChild("SlowedStatus")
    if not fovSlowedStatus or not fovSlowedStatus:IsA("NumberValue") then return end

    fovSlowedStatus.Value = 1

    -- Remove Slowness UI if it exists
    local LocalPlayerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if LocalPlayerGui then
        local mainUI = LocalPlayerGui:FindFirstChild("MainUI")
        if mainUI then
            local statusContainer = mainUI:FindFirstChild("StatusContainer")
            if statusContainer then
                local slownessUI = statusContainer:FindFirstChild("Slowness")
                if slownessUI then
                    slownessUI.Visible = false
                end
            end
        end
    end
end

-- VirtualInputManager once (it was used but never defined)
local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local function Do1x1x1x1Popups()
    -- Single cancellable worker; does not leave duplicate polling loops after toggling.
    while Do1x1PopupsLoop do
        local ok, err = pcall(function()
            local tempUI = PlayerGui:FindFirstChild("TemporaryUI")
            if not tempUI or not VIM then return end
            for _, popup in ipairs(tempUI:GetChildren()) do
                if popup.Name == "1x1x1x1Popup" and popup:IsA("GuiObject") then
                    local cx = popup.AbsolutePosition.X + popup.AbsoluteSize.X * 0.5
                    local cy = popup.AbsolutePosition.Y + popup.AbsoluteSize.Y * 0.5
                    VIM:SendMouseButtonEvent(cx, cy, Enum.UserInputType.MouseButton1.Value, true, PlayerGui, 1)
                    VIM:SendMouseButtonEvent(cx, cy, Enum.UserInputType.MouseButton1.Value, false, PlayerGui, 1)
                end
            end
        end)
        if not ok then warn("[Vortexion] 弹窗触控失败: " .. tostring(err)) end
        task.wait(0.1)
    end
end

local existence
local animTrack
local running = false
local timebetweenpuzzles = 3

local MaxRange = 120
local hitboxmodificationEnabled = false

local function ToggleInvis(enabled)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    if enabled then
        running = true
        spawn(function()
            while running do
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end
                print("got humanoid")

                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then
                    animator = Instance.new("Animator")
                    animator.Parent = humanoid
                end

                if true then
                    if not animTrack or not animTrack.IsPlaying then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = "rbxassetid://75804462760596"
                        animTrack = animator:LoadAnimation(animation)
                        animTrack.Looped = true
                        animTrack:Play()
                        animTrack:AdjustSpeed(0)
                        humanoid.Parent.HumanoidRootPart.Transparency = 0.4
                    end
                else
                    if animTrack and animTrack.IsPlaying then
                        animTrack:Stop()
                        animTrack = nil
                        humanoid.Parent.HumanoidRootPart.Transparency = 1
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        running = false
        if animTrack and animTrack.IsPlaying then
            animTrack:Stop()
            animTrack = nil
            humanoid.Parent.HumanoidRootPart.Transparency = 1
        end
    end
end

local function handleToggle(enabled)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    if enabled then
        running = true
        spawn(function()
            while running do
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end

                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then
                    animator = Instance.new("Animator")
                    animator.Parent = humanoid
                end
                
                local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                if torso and torso.Transparency ~= 0 then
                    if not animTrack or not animTrack.IsPlaying then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = "rbxassetid://75804462760596"
                        animTrack = animator:LoadAnimation(animation)
                        animTrack.Looped = true
                        animTrack:Play()
                        animTrack:AdjustSpeed(0)
						humanoid.Parent.HumanoidRootPart.Transparency = 0.4
                    end
                else
                    if animTrack and animTrack.IsPlaying then
                        animTrack:Stop()
                        animTrack = nil
						humanoid.Parent.HumanoidRootPart.Transparency = 1
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        running = false
        if animTrack and animTrack.IsPlaying then
            animTrack:Stop()
            animTrack = nil
			humanoid.Parent.HumanoidRootPart.Transparency = 1
        end
    end
end

local LMSSongs = {
    ["Burnout"] = "rbxassetid://130101085745481",
    ["Compass"] = "rbxassetid://127298326178102",
    ["Vanity"] = "rbxassetid://137266220091579",
    ["Close To Me"] = "rbxassetid://90022574613230",
    ["Plead"] = "rbxassetid://80564889711353",
    ["Creation Of Hatred"] = "rbxassetid://115884097233860",
}

local GuestSettingsTriggerAnims = {
    "126830014841198", "126355327951215", "121086746534252", "18885909645",
    "98456918873918", "105458270463374", "83829782357897", "125403313786645",
    "118298475669935", "82113744478546", "70371667919898", "99135633258223",
    "97167027849946", "109230267448394", "139835501033932", "126896426760253",
    "109667959938617", "126681776859538", "129976080405072", "121293883585738",
    "81639435858902", "137314737492715", "92173139187970", "106847695270773"
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local blockingKillers = {}
local GuestSettingsLoop -- will hold the connection

local function getKillerActiveTriggerAnim(killer)
    local hum = killer:FindFirstChildWhichIsA("Humanoid")
    if hum and hum:FindFirstChild("Animator") then
        for _, track in ipairs(hum.Animator:GetPlayingAnimationTracks()) do
            local animId = track.Animation.AnimationId
            for _, id in ipairs(GuestSettingsTriggerAnims) do
                if string.find(animId, id) then
                    return animId
                end
            end
        end
    end
    return nil
end

local function getPunchCharges()
    local guiObj = localPlayer.PlayerGui:FindFirstChild("MainUI")
    if guiObj then
        local abilityContainer = guiObj:FindFirstChild("AbilityContainer", true)
        if abilityContainer and abilityContainer:FindFirstChild("Punch") then
            local punchObj = abilityContainer.Punch:FindFirstChild("Charges")
            if punchObj then
                return tostring(punchObj.Text)
            end
        end
    end
    return nil
end

local function startBlockTp(state)
    if state then return end -- Already running

    GuestSettingsLoop = RunService.RenderStepped:Connect(function()
        local char = localPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end

        local killersFolder = workspace.Players and workspace.Players:FindFirstChild("Killers")
        if not killersFolder then return end
        for _, killer in ipairs(killersFolder:GetChildren()) do
            if not (killer:IsA("Model") and killer:FindFirstChild("HumanoidRootPart")) then
                blockingKillers[killer] = nil
                continue
            end

            local activeAnim = getKillerActiveTriggerAnim(killer)
            if not activeAnim then
                blockingKillers[killer] = nil
                continue
            end

            if blockingKillers[killer] == activeAnim or getPunchCharges() ~= "0" then
                continue
            end

            -- Mark killer as blocking
            blockingKillers[killer] = activeAnim
            local originalCF = char.HumanoidRootPart.CFrame

            -- Fire block
            local okFireBlock = pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local modules = rs:FindFirstChild("Modules")
                local network = modules and modules:FindFirstChild("Network")
                local remote = network and network:FindFirstChild("RemoteEvent")
                if remote then
                    remote:FireServer("UseActorAbility", "Block")
                end
            end)
            if not okFireBlock then continue end

            -- Teleport in front of killer
            local killerHRP = killer.HumanoidRootPart
            local function teleportInFront()
                char.HumanoidRootPart.CFrame = CFrame.new(killerHRP.Position + killerHRP.CFrame.LookVector * 2)
            end
            teleportInFront()

            -- Keep teleporting until animation ends or punch charge = "1"
            task.spawn(function()
                while sessionEnv.VortexionSessionId == thisSessionId do
                    task.wait(0.05)
                    if not (localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")) then break end

                    teleportInFront()

                    local charges = getPunchCharges()
                    local currentAnim = getKillerActiveTriggerAnim(killer)
                    if charges == "1" or currentAnim ~= activeAnim then
                        -- Restore original position
                        if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            localPlayer.Character.HumanoidRootPart.CFrame = originalCF
                        end
                        blockingKillers[killer] = nil
                        break
                    end
                end
            end)
        end
    end)
end

local selectedSong = "Burnout" -- default

local soundPlayer = Instance.new("Sound")
soundPlayer.Name = "GoonsakenHub_Sound"
soundPlayer.Parent = Workspace
soundPlayer.Looped = false
soundPlayer.Volume = 5

-- Forward declarations keep menu callbacks bound to this session.
local Window, Tabs, Fluent
local emoteButtons = {}
local function getEquippedEmotes()
    local data = LocalPlayer:FindFirstChild("PlayerData")
    local equipped = data and data:FindFirstChild("Equipped")
    local emotes = equipped and equipped:FindFirstChild("Emotes")
    return string.split(emotes and emotes.Value or "", "|")
end

local function KillerEmoteGUI()
    if not (Window and Tabs and Tabs.Emotes) then return end
    local legacy = PlayerGui:FindFirstChild("KillerEmoteGUI")
    if legacy then legacy:Destroy() end
    local emotes = getEquippedEmotes()
    for slot = 1, 8 do
        if not emoteButtons[slot] then
            local emoteSlot = slot
            emoteButtons[slot] = Tabs.Emotes:AddButton({
                Title = "表情槽 " .. tostring(slot),
                Callback = function()
                    local name = getEquippedEmotes()[emoteSlot]
                    if not name or name == "" then
                        Fluent:Notify({ Title = "杀手表情", Content = "此槽位未装备表情。", Duration = 3 })
                        return
                    end
                    pcall(function()
                        local modules = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
                        local network = modules and modules:FindFirstChild("Network")
                        local remote = network and network:FindFirstChild("RemoteEvent")
                        if remote then remote:FireServer("PlayEmote", "Animations", name) end
                    end)
                end
            })
        end
        local button = emoteButtons[slot] and (emoteButtons[slot].Native or emoteButtons[slot])
        if button and button.SetTitle then
            local name = emotes[slot]
            button:SetTitle("表情槽 " .. tostring(slot) .. " · " .. ((name and name ~= "") and name or "未装备"))
        end
    end
    Window:SelectTab(6)
    if Window.Native and Window.Native.Open then Window.Native:Open() end
end

local timeAhead = 0.2

-- Prevent duplicate hub (if still present from other runs)
local existingGui = PlayerGui:FindFirstChild("GoonsakenHub")
if existingGui then
    existingGui:Destroy()
end

-- Preserve original logic variables
local statsGui
local ESP = {}
ESP.Enabled = false
-- Stage 2: category filters, details and a bounded, adjustable LOS refresh budget.
ESP.ShowKillers = true
ESP.ShowSurvivors = true
ESP.ShowLabels = true
ESP.ShowDetails = false
ESP.VisibleAlpha = 0.80
ESP.CheckHz = 10
ESP.LastCheck = 0
-- Feature architecture: OPAI generator-status ESP + c00lSaken threat awareness.
ESP.GeneratorDetails = false
ESP.CompletedGenerators = false
ESP.GeneratorLabelRecords = setmetatable({}, {__mode = "k"})

local PLAYER_ESP_NAME = "PlayerESP"
local ITEM_ESP_NAME = "ToolESPHighlight"
local GENERATOR_ESP_NAME = "GeneratorESP"
local TRAPSANDSPIKES_ESP_NAME = "TrapsandSpikesESP"

local aimbotConnection

local function findNearestGenerator()
    local mapFolder = Workspace:FindFirstChild("Map")
    if not mapFolder then return nil end
    local ingameMap = mapFolder:FindFirstChild("Ingame")
    if not ingameMap then return nil end
    local map = ingameMap:FindFirstChild("Map")
    if not map then return nil end

    local generators = {}
    for _, obj in pairs(map:GetChildren()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            table.insert(generators, obj)
        end
    end

    if #generators == 0 then return nil end

    local LocalPlayerRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not LocalPlayerRoot then return nil end

    local nearestGen = nil
    local nearestDist = math.huge

    for _, gen in pairs(generators) do
        local genRoot = gen:FindFirstChild("HumanoidRootPart") or gen.PrimaryPart
        if genRoot then
            local dist = (genRoot.Position - LocalPlayerRoot.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestGen = gen
            end
        end
    end

    return nearestGen
end

local function findNearestValidGenerator()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    local ingame = map:FindFirstChild("Ingame")
    if not ingame then return nil end
    local container = ingame:FindFirstChild("Map")
    if not container then return nil end

    local nearest
    local shortestDist = math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    for _, gen in ipairs(container:GetDescendants()) do
        if gen.Name == "Generator" and gen:IsA("Model") and gen:FindFirstChild("Progress") and gen.Progress.Value < 100 then
            local dist = (gen.PrimaryPart.Position - root.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                nearest = gen
            end
        end
    end

    return nearest
end

local function triggerNearestGenerator(shouldLoop)
	while shouldLoop do
		looping = true
		task.wait(timeforonegen + math.random() * 0.5)
		local MapFolder = workspace:FindFirstChild("Map")
			and workspace.Map:FindFirstChild("Ingame")
			and workspace.Map.Ingame:FindFirstChild("Map")
		local character = LocalPlayer.Character; local hrp = character and character:FindFirstChild("HumanoidRootPart"); if MapFolder and hrp then
			local closestGenerator, closestDistance = nil, math.huge
			local playerPosition = hrp.Position
			for _, g in ipairs(MapFolder:GetChildren()) do
				local progress = g:FindFirstChild("Progress"); local main = g:FindFirstChild("Main"); if g.Name == "Generator" and progress and main and progress.Value < 100 then
					local distance = (main.Position - playerPosition).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						closestGenerator = g
					end
				end
			end
			if closestGenerator then
				local remotes = closestGenerator:FindFirstChild("Remotes"); local re = remotes and remotes:FindFirstChild("RE"); if re then re:FireServer() end
			end
		end
	end
	looping = false
end

-- Enable aimbot function
local function enableAimbot()
    local lastPositions = {}
    local deltaTime = 0.03

    aimbotConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Parent then
            local flintlock = humanoid.Parent:FindFirstChild("Flintlock")
            if flintlock and flintlock.Transparency == 0 then
                local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
                if killersFolder then
                    for _, killerModel in pairs(killersFolder:GetChildren()) do
                        if killerModel:IsA("Model") and killerModel:FindFirstChild("HumanoidRootPart") then
                            local hrp = killerModel.HumanoidRootPart
                            local currentPos = hrp.Position
                            local prevPos = lastPositions[killerModel]
                            local velocity = Vector3.new(0, 0, 0)

                            if prevPos then
                                velocity = (currentPos - prevPos) / deltaTime
                            end
                            lastPositions[killerModel] = currentPos

                            local predictedPos = currentPos + velocity * timeAhead

                            local rootPart = character:FindFirstChild("HumanoidRootPart")
                            if rootPart and (predictedPos - rootPart.Position).Magnitude > 0.01 then
								if humanoid then
									humanoid.AutoRotate = false
								end
                                rootPart.CFrame = CFrame.new(rootPart.Position, predictedPos)
                            end
                        end
                    end
                end
			else
				if humanoid then
					humanoid.AutoRotate = true
				end
			end        
		end	
    end)
end

-- Disable aimbot function
local function disableAimbot()
    if aimbotConnection then
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

local COLOR_SURVIVOR = Color3.fromRGB(0, 255, 0)
local COLOR_KILLER = Color3.fromRGB(255, 0, 0)
local COLOR_TRAPSANDSPIKES = Color3.fromRGB(255, 0, 0)
local COLOR_MEDKIT = Color3.fromRGB(0, 255, 0)
local COLOR_COLA = Color3.fromRGB(0, 150, 255)
local COLOR_GENERATOR = Color3.fromRGB(255, 255, 0)

-- Store all highlights to toggle visibility
local allHighlights = {}

local function setHighlightVisibility(highlight, visible)
    if visible then
        highlight.FillTransparency = 0.8
        highlight.OutlineTransparency = 0
    else
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 1
    end
end

-- Player ESP
local PlayersFolder = Workspace:WaitForChild("Players", 30) or Instance.new("Folder")

do
-- v3: Trap ESP is indexed once per map and incrementally maintained on instance additions.
-- Avoid the old every-0.5s GetDescendants() scan with nested descendant searches.
local trapFolder, trapAddedConnection
local function trapHighlight(target, color)
    if not target or target:FindFirstChild(TRAPSANDSPIKES_ESP_NAME) then return end
    local hl = Instance.new("Highlight")
    hl.Name = TRAPSANDSPIKES_ESP_NAME
    hl.FillColor = color or COLOR_TRAPSANDSPIKES
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.Adornee = target
    hl.Parent = target
    setHighlightVisibility(hl, ESP.Enabled)
    allHighlights[hl] = true
end
local SPECIAL_ESP_COLORS = {
    PizzaDeliveryRig = Color3.fromRGB(255, 170, 45),
    PizzaBot = Color3.fromRGB(255, 170, 45),
    Zombie = Color3.fromRGB(255, 96, 96),
    Tripwire = Color3.fromRGB(184, 110, 255),
    Tripmine = Color3.fromRGB(232, 90, 255),
    Graffiti = Color3.fromRGB(245, 245, 245),
    GroundBulb = Color3.fromRGB(22, 225, 202),
    Vine = Color3.fromRGB(146, 82, 255),
}
local function inspectTrapNode(node, ingame)
    if not (node:IsA("BasePart") or node:IsA("Model")) then return end
    local name = node.Name
    local special = SPECIAL_ESP_COLORS[name]
    if special then
        trapHighlight(node, special)
        return
    end
    if name == "Spike" or name == "SubspaceTripmine" or name == "Shadow" or name:find("RespawnLocation", 1, true) then
        if name == "Shadow" or name:find("RespawnLocation", 1, true) then
            if node:IsA("BasePart") then
                if node.Transparency ~= 0 then node.Transparency = 0 end
            elseif node:IsA("Model") then
                for _, part in ipairs(node:GetDescendants()) do
                    if part:IsA("BasePart") and part.Transparency ~= 0 then part.Transparency = 0 end
                end
            end
        end
        trapHighlight(node)
    elseif name == "Hook1" and node:IsA("BasePart") then
        -- Highlight the smallest containing trap model instead of the entire level.
        local parent = node.Parent
        while parent and parent ~= ingame and not parent:IsA("Model") do
            parent = parent.Parent
        end
        if parent and parent ~= ingame and parent:IsA("Model") then trapHighlight(parent) end
    end
end
local function bindTrapFolder(ingame)
    if not ingame or trapFolder == ingame then return end
    if trapAddedConnection then trapAddedConnection:Disconnect(); trapAddedConnection = nil end
    trapFolder = ingame
    trapAddedConnection = ingame.DescendantAdded:Connect(function(node)
        inspectTrapNode(node, ingame)
    end)
    task.spawn(function()
        local nodes = ingame:GetDescendants()
        for i, node in ipairs(nodes) do
            if trapFolder ~= ingame or not ingame.Parent then return end
            inspectTrapNode(node, ingame)
            if i % 200 == 0 then task.wait() end -- bounded startup cost
        end
    end)
end
local function bindCurrentTrapMap()
    local map = Workspace:FindFirstChild("Map")
    local ingame = map and map:FindFirstChild("Ingame")
    if ingame then bindTrapFolder(ingame) end
end
bindCurrentTrapMap()
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        local ingame = child:FindFirstChild("Ingame")
        if ingame then bindTrapFolder(ingame) end
        child.ChildAdded:Connect(function(part)
            if part.Name == "Ingame" then bindTrapFolder(part) end
        end)
    end
end)
if not trapFolder then
    -- In case the original Map container appears after startup.
    task.spawn(function()
        for _ = 1, 30 do
            if trapFolder then return end
            bindCurrentTrapMap()
            task.wait(1)
        end
    end)
end

end -- scoped performance/UI helpers

-- 独立的玩家 ESP：杀手红色、幸存者绿色。
-- 玩家可见性 = 位于屏幕内且相机至角色之间无实体障碍物（Raycast）。
-- 修订需求：被墙体遮挡或屏幕外 0% 透明（实体高亮完全不透明）；无遮挡 80% 透明。
-- 透明度 0 = 不透明；1 = 完全不可见。目标在物理屏幕外时无法实际绘制到屏幕中。
local PLAYER_ESP_ONSCREEN_ALPHA = 0.80
local PLAYER_ESP_OFFSCREEN_ALPHA = 0
local playerESPRecords = {}

-- 手机端性能约束：共用记录内的 RaycastParams，不在每帧重建配置；
-- 每位玩家最多 2 条射线（身体 + 头部），由既有 0.1s 调度器驱动。
local function isPlayerVisibleFromCamera(record, camera, targetPosition)
    local screenPoint, isOnScreen = camera:WorldToViewportPoint(targetPosition)
    if not (isOnScreen and screenPoint.Z > 0) then return false end

    local params = record.LOSParams
    if not params then
        params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        params.RespectCanCollide = true
        record.LOSParams = params
    end

    -- 排除自己的角色和目标角色本体，否则会把目标身体错误判成遮挡。
    local ownCharacter = LocalPlayer.Character
    if record.LOSOwnCharacter ~= ownCharacter then
        record.LOSOwnCharacter = ownCharacter
        local excluded = { record.Character }
        if ownCharacter then table.insert(excluded, ownCharacter) end
        params.FilterDescendantsInstances = excluded
    end

    local origin = camera.CFrame.Position
    local direction = targetPosition - origin
    if direction.Magnitude <= 0.01 then return true end
    local hit = Workspace:Raycast(origin, direction, params)
    return hit == nil or hit.Distance >= direction.Magnitude - 0.25
end

local function getESPUsername(character)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        return player.Name
    end
    for _, name in ipairs({ "Username", "UserName", "PlayerName" }) do
        local value = character:GetAttribute(name)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    local matchingPlayer = Players:FindFirstChild(character.Name)
    if matchingPlayer and matchingPlayer:IsA("Player") then
        return matchingPlayer.Name
    end
    return "未知玩家"
end

local function getESPRole(character)
    -- Forsaken 使用角色名称命名 Workspace.Players.Killers/Survivors 下的模型。
    local characterName = character:GetAttribute("CharacterName")
    if type(characterName) == "string" and characterName ~= "" then
        return characterName
    end
    local role = character:GetAttribute("Role")
    if type(role) == "string" and role ~= "" then
        return role
    end
    return character.Name
end

local function createESPText(parent, y, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 20)
    label.Position = UDim2.fromOffset(4, y)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.15
    label.TextTransparency = PLAYER_ESP_OFFSCREEN_ALPHA
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = parent
    return label
end

local function updatePlayerESP(record, camera)
    local character = record.Character
    local highlight = record.Highlight
    local billboard = record.Billboard
    if not character.Parent or not highlight.Parent or not billboard.Parent then
        return false
    end

    -- 每次刷新角色名称/阵营，以兼容换角色与中途回合变化。
    local side = character.Parent.Name
    local color = side == "Killers" and COLOR_KILLER or COLOR_SURVIVOR
    if highlight.FillColor ~= color then highlight.FillColor = color end
    if highlight.OutlineColor ~= color then highlight.OutlineColor = color end
    if record.RoleLabel.TextColor3 ~= color then record.RoleLabel.TextColor3 = color end

    local now = os.clock()
    if now >= (record.NextMetadataUpdate or 0) then
        local username = "用户名：" .. getESPUsername(character)
        local role = "角色：" .. getESPRole(character)
        if record.UsernameLabel.Text ~= username then record.UsernameLabel.Text = username end
        if record.RoleLabel.Text ~= role then record.RoleLabel.Text = role end
        record.NextMetadataUpdate = now + 1.0
    end

    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    if not (root and root:IsA("BasePart")) then root = nil end
    if root and billboard.Adornee ~= root then
        billboard.Adornee = root
        billboard.StudsOffsetWorldSpace = Vector3.new(0, root.Name == "Head" and -5 or -3.1, 0)
    end

    local unobstructed = false
    local selectedFaction = (side == "Killers" and ESP.ShowKillers) or (side == "Survivors" and ESP.ShowSurvivors)
    if ESP.Enabled and selectedFaction and camera and root and root:IsA("BasePart") then
        unobstructed = isPlayerVisibleFromCamera(record, camera, root.Position)
        -- 上半身露出掩体时也算可见，避免只测身体造成误判。
        if not unobstructed then
            local head = character:FindFirstChild("Head")
            if head and head:IsA("BasePart") and head ~= root then
                unobstructed = isPlayerVisibleFromCamera(record, camera, head.Position)
            end
        end
    end

    -- 墙后目标不能再使用 `Enabled = unobstructed`：那样会把 0% 透明度目标直接隐藏。
    -- 不显示本阵营或关掉 ESP 时才真正禁用；不可见或被墙遮挡则用 0% 透明度显示。
    local shouldShow = ESP.Enabled and selectedFaction and root ~= nil and root:IsA("BasePart")
    local alpha = shouldShow and (unobstructed and ESP.VisibleAlpha or PLAYER_ESP_OFFSCREEN_ALPHA) or 1
    if highlight.FillTransparency ~= alpha then highlight.FillTransparency = alpha end
    if highlight.OutlineTransparency ~= alpha then highlight.OutlineTransparency = alpha end
    if highlight.Enabled ~= shouldShow then highlight.Enabled = shouldShow end
    local showLabels = shouldShow and ESP.ShowLabels
    if billboard.Enabled ~= showLabels then billboard.Enabled = showLabels end
    if record.UsernameLabel.TextTransparency ~= alpha then record.UsernameLabel.TextTransparency = alpha end
    if record.RoleLabel.TextTransparency ~= alpha then record.RoleLabel.TextTransparency = alpha end
    if record.UsernameLabel.TextStrokeTransparency ~= alpha then record.UsernameLabel.TextStrokeTransparency = alpha end
    if record.RoleLabel.TextStrokeTransparency ~= alpha then record.RoleLabel.TextStrokeTransparency = alpha end

    -- 健康与距离是可选的；用限频采样避免手机上每个 ESP 周期重算。
    local detailLabel = record.DetailLabel
    if detailLabel then
        if detailLabel.Visible ~= ESP.ShowDetails then detailLabel.Visible = ESP.ShowDetails end
        if ESP.ShowDetails then
            if detailLabel.TextTransparency ~= alpha then detailLabel.TextTransparency = alpha end
            if detailLabel.TextStrokeTransparency ~= alpha then detailLabel.TextStrokeTransparency = alpha end
            if now >= (record.NextStatsUpdate or 0) then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local distance = myRoot and root and math.floor((myRoot.Position - root.Position).Magnitude + 0.5) or 0
                local health = humanoid and math.floor(humanoid.Health + 0.5) or 0
                local maxHealth = humanoid and math.floor(humanoid.MaxHealth + 0.5) or 0
                detailLabel.Text = string.format("生命：%d/%d · 距离：%d", health, maxHealth, distance)
                record.NextStatsUpdate = now + 0.5
            end
        end
    end
    return true
end

local function applyPlayerESP(character, color)
    if not character:IsA("Model") or character == LocalPlayer.Character then return end
    if character.Parent == nil then return end
    local earlyRoot = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    if not (earlyRoot and earlyRoot:IsA("BasePart")) then
        return -- 刚出生时延后到下次扫描，不阻塞线程
    end

    local record = playerESPRecords[character]
    if record and record.Highlight.Parent and record.Billboard.Parent then
        -- 继续使用原来的对象；updatePlayerESP 会处理角色换边。
        return
    end
    playerESPRecords[character] = nil

    local existingHighlight = character:FindFirstChild(PLAYER_ESP_NAME)
    if existingHighlight and not existingHighlight:IsA("Highlight") then
        existingHighlight:Destroy()
        existingHighlight = nil
    end
    local highlight = existingHighlight or Instance.new("Highlight")
    highlight.Name = PLAYER_ESP_NAME
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = PLAYER_ESP_OFFSCREEN_ALPHA
    highlight.OutlineTransparency = PLAYER_ESP_OFFSCREEN_ALPHA
    highlight.Enabled = false -- 开关关闭时必须保持不可见，首次 update 再确定阵营状态
    highlight.Parent = character
    allHighlights[highlight] = true

    local previousBillboard = character:FindFirstChild("PlayerESPBillboard", true)
    if previousBillboard then previousBillboard:Destroy() end

    local root = earlyRoot
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerESPBillboard"
    billboard.Adornee = root
    billboard.Size = UDim2.fromOffset(220, 64)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, root.Name == "Head" and -5 or -3.1, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.MaxDistance = 5000
    billboard.Parent = root

    local usernameLabel = createESPText(billboard, 0, Color3.fromRGB(245, 245, 245))
    usernameLabel.Name = "Username"
    local roleLabel = createESPText(billboard, 20, color)
    roleLabel.Name = "Role"
    local detailLabel = createESPText(billboard, 40, Color3.fromRGB(225, 225, 225))
    detailLabel.Name = "HealthDistance"
    detailLabel.Visible = false

    record = {
        Character = character,
        Highlight = highlight,
        Billboard = billboard,
        UsernameLabel = usernameLabel,
        RoleLabel = roleLabel,
        DetailLabel = detailLabel,
    }
    playerESPRecords[character] = record
    updatePlayerESP(record, Workspace.CurrentCamera)
end

-- 非关键 ESP 投影刷新节流：CheckHz 与桥接返回都有界化，
-- 拒绝 inf/nan 造成冻结或绕过节流（与其余三路同一契约）。
local function espThrottleInterval()
    local checkHz = tonumber(ESP.CheckHz) or 10
    if checkHz ~= checkHz or checkHz == math.huge or checkHz == -math.huge then checkHz = 10 end
    local interval = 1 / math.max(2, math.min(20, checkHz))
    local bridgeOk, bridged = pcall(function()
        if Fluent and type(Fluent.GetVisualInterval) == "function" then
            return Fluent:GetVisualInterval(interval)
        end
        return nil
    end)
    if bridgeOk and type(bridged) == "number" and bridged == bridged
        and bridged ~= math.huge and bridged ~= -math.huge and bridged > 0 then
        interval = math.max(interval, bridged)
    end
    return interval
end

-- 固定最多约 10 次/秒检查屏幕投影，避免在手机端逐帧扫描地图。
runEvery(0.05, function()
    if not ESP.Enabled then return end
    local now = os.clock()
    local espInterval = espThrottleInterval()
    if now - ESP.LastCheck < espInterval then return end
    ESP.LastCheck = now
    local camera = Workspace.CurrentCamera
    for character, record in pairs(playerESPRecords) do
        if not updatePlayerESP(record, camera) then
            allHighlights[record.Highlight] = nil
            playerESPRecords[character] = nil
        end
    end
end)

-- Item ESP
local function applyItemHighlight(tool, color)
    if not tool:FindFirstChild(ITEM_ESP_NAME) then
        local highlight = Instance.new("Highlight")
        highlight.Name = ITEM_ESP_NAME
        highlight.Adornee = tool
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.Parent = tool

        -- Set initial visibility
        setHighlightVisibility(highlight, ESP.Enabled)
        allHighlights[highlight] = true
    end
end

local function highlightToolIfNeeded(tool)
    if tool:IsA("Tool") then
        if tool.Name == "Medkit" then
            applyItemHighlight(tool, COLOR_MEDKIT)
        elseif tool.Name == "BloxyCola" or tool.Name == "Cola" then
            applyItemHighlight(tool, COLOR_COLA)
        end
    end
end

do
-- Generator ESP
local function addGeneratorHighlight(model)
    if model:FindFirstChild(GENERATOR_ESP_NAME) then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = GENERATOR_ESP_NAME
    highlight.FillColor = COLOR_GENERATOR
    highlight.Adornee = model
    highlight.Parent = model

    -- Set initial visibility
    setHighlightVisibility(highlight, ESP.Enabled)
    allHighlights[highlight] = true
end

local function removeGeneratorHighlight(model)
    local existing = model:FindFirstChild(GENERATOR_ESP_NAME)
    if existing then
        allHighlights[existing] = nil
        existing:Destroy()
    end
end

-- Generator details: progress and remaining distance are sampled on demand.
-- Use existing generator index and Progress.Changed, never a second map traversal.
local function updateGeneratorLabel(generator, genModel, progress, includeDistance)
    local record = ESP.GeneratorLabelRecords[generator]
    local completed = tonumber(progress.Value) and tonumber(progress.Value) >= 100
    local visible = ESP.Enabled and ESP.GeneratorDetails and (not completed or ESP.CompletedGenerators)
    if not visible and not record then return end
    if not record and visible then
        local part = genModel.PrimaryPart or genModel:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end
        local gui = Instance.new("BillboardGui")
        gui.Name = "VortexionGeneratorLabel"
        gui.Size = UDim2.fromOffset(165, 35)
        gui.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
        gui.AlwaysOnTop = true
        gui.MaxDistance = 1200
        gui.Adornee = part
        gui.Parent = genModel
        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.fromRGB(255, 223, 90)
        text.TextStrokeTransparency = 0.2
        text.TextSize = 13
        text.Font = Enum.Font.GothamBold
        text.Parent = gui
        record = {Gui=gui, Label=text, Part=part, LastDistance=-1}
        ESP.GeneratorLabelRecords[generator] = record
    end
    if not record.Gui.Parent then ESP.GeneratorLabelRecords[generator] = nil; return end
    record.Gui.Enabled = visible
    if not visible then return end
    local percentage = math.clamp(tonumber(progress.Value) or 0, 0, 100)
    local distance = record.LastDistance
    if includeDistance or distance < 0 then
        local ownRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        distance = ownRoot and math.floor((ownRoot.Position - record.Part.Position).Magnitude + 0.5) or -1
        record.LastDistance = distance
    end
    local text = (completed and "已完成" or ("修理 " .. tostring(math.floor(percentage)) .. "%"))
    if distance >= 0 then text = text .. " · " .. tostring(distance) .. " studs" end
    if record.Label.Text ~= text then record.Label.Text = text end
    local color = completed and Color3.fromRGB(155, 164, 176) or Color3.fromRGB(255, 223, 90)
    if record.Label.TextColor3 ~= color then record.Label.TextColor3 = color end
end

function ESP:RefreshGeneratorLabels()
    for generator in pairs(self.GeneratorLabelRecords) do
        local progress = generator:FindFirstChild("Progress")
        local instances = generator:FindFirstChild("Instances")
        local genModel = instances and instances:FindFirstChild("Generator")
        if not (generator.Parent and progress and genModel) then
            local record = self.GeneratorLabelRecords[generator]
            if record and record.Gui.Parent then record.Gui:Destroy() end
            self.GeneratorLabelRecords[generator] = nil
        else
            updateGeneratorLabel(generator, genModel, progress, true)
        end
    end
end

-- One slow worker already shared with the existing generator registry.
runEvery(1.0, function()
    if ESP.Enabled and ESP.GeneratorDetails then ESP:RefreshGeneratorLabels() end
end)

local trackedGeneratorProgress = setmetatable({}, {__mode = "k"})
local function trackGenerator(generator)
    if trackedGeneratorProgress[generator] then return end
    local progress = generator:FindFirstChild("Progress")
    local instances = generator:FindFirstChild("Instances")

    if not progress or not instances then return end

    local genModel = instances:FindFirstChild("Generator")
    if not genModel or not genModel:IsA("Model") then return end

    if progress.Value < 100 then
        addGeneratorHighlight(genModel)
    else
        removeGeneratorHighlight(genModel)
    end

    updateGeneratorLabel(generator, genModel, progress, false)
    trackedGeneratorProgress[generator] = progress:GetPropertyChangedSignal("Value"):Connect(function()
        if not generator.Parent then
            local connection = trackedGeneratorProgress[generator]
            if connection then connection:Disconnect() end
            trackedGeneratorProgress[generator] = nil
            return
        end
        if progress.Value >= 100 then
            removeGeneratorHighlight(genModel)
        else
            addGeneratorHighlight(genModel)
        end
        updateGeneratorLabel(generator, genModel, progress, false)
    end)
end

local function trackGeneratorsInFolder(folder)
    if not folder then return end
    for _, gen in ipairs(folder:GetDescendants()) do
        if gen.Name == "Generator" and gen:IsA("Model") then
            trackGenerator(gen)
        end
    end
end

-- Listen for Map creation / reload
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(1)
        local ingame = child:FindFirstChild("Ingame")
        local mapContainer = ingame and ingame:FindFirstChild("Map")
        if mapContainer then
            trackGeneratorsInFolder(mapContainer)
        end
    end
end)

-- Also listen for new generators being added mid-game
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "Generator" and obj:IsA("Model") then
        trackGenerator(obj)
    end
end)

runEvery(0.5, function()
    if not ESP.Enabled then return end -- No per-player discovery cost while ESP is off.
    -- 回合切换时回收旧角色 ESP，避免多局游戏后累积失效对象。
    for character, record in pairs(playerESPRecords) do
        if not character:IsDescendantOf(PlayersFolder)
            or not record.Highlight.Parent
            or not record.Billboard.Parent then
            allHighlights[record.Highlight] = nil
            if record.Highlight.Parent then record.Highlight:Destroy() end
            if record.Billboard.Parent then record.Billboard:Destroy() end
            playerESPRecords[character] = nil
        end
    end

    local survivors = PlayersFolder:FindFirstChild("Survivors")
    if survivors then
        for _, char in ipairs(survivors:GetChildren()) do
            applyPlayerESP(char, COLOR_SURVIVOR)
        end
    end

    local killers = PlayersFolder:FindFirstChild("Killers")
    if killers then
        for _, char in ipairs(killers:GetChildren()) do
            applyPlayerESP(char, COLOR_KILLER)
        end
    end

    -- Trap ESP is event-driven; no full-map poll here.
end)

-- v3: Single asynchronous initial tool scan; future tools are handled by events.
Workspace.DescendantAdded:Connect(highlightToolIfNeeded)
task.spawn(function()
    for i, tool in ipairs(Workspace:GetDescendants()) do
        highlightToolIfNeeded(tool)
        if i % 250 == 0 then task.wait() end
    end
end)

-- Generator ESP loop
-- Find map once (with retries), then track generators, plus a 0.5s poll for *new* generators
task.spawn(function()
    local mapContainer
    repeat
        local mapRoot = Workspace:FindFirstChild("Map")
        local ingame = mapRoot and mapRoot:FindFirstChild("Ingame")
        mapContainer = ingame and ingame:FindFirstChild("Map")
        task.wait(0.5)
    until mapContainer

    -- initial pass
    for _, gen in ipairs(mapContainer:GetChildren()) do
        if gen.Name == "Generator" and gen:IsA("Model") then
            trackGenerator(gen)  -- your existing function (it adds/removes a Highlight and binds to Progress)
        end
    end

    -- Later generators are already captured by Workspace.DescendantAdded.
end)

end -- scoped performance/UI helpers

-- Function to toggle ESP on/off
function ESP:SetEnabled(state)
    ESP.Enabled = not not state
    self:RefreshGeneratorLabels()
    -- 非玩家高亮维持原来的逻辑；玩家高亮无遮挡 80%，遮挡或屏幕外 0%。
    for highlight in pairs(allHighlights) do
        if highlight.Parent == nil then
            allHighlights[highlight] = nil
        elseif highlight.Name ~= PLAYER_ESP_NAME then
            setHighlightVisibility(highlight, ESP.Enabled)
        end
    end
    local camera = Workspace.CurrentCamera
    for character, record in pairs(playerESPRecords) do
        if not updatePlayerESP(record, camera) then
            allHighlights[record.Highlight] = nil
            playerESPRecords[character] = nil
        end
    end
end

-- Player statistics are game controls; native WindUI owns the list and scrolling.
local function createStatsTracker()
    local existing = PlayerGui:FindFirstChild("TimePlayedGUI")
    if existing then existing:Destroy() end
    local controller = { Enabled = false, Alive = true, Rows = {} }
    function controller:Destroy()
        self.Alive = false
        self.Enabled = false
        for _, element in pairs(self.Rows) do
            local native = element.Native or element
            if native.Destroy then pcall(function() native:Destroy() end) end
        end
        table.clear(self.Rows)
    end
    if not (Tabs and Tabs.Stats) then return controller end

    local function formatTime(seconds)
        local days = math.floor(seconds / 86400)
        seconds = seconds % 86400
        local hours = math.floor(seconds / 3600)
        seconds = seconds % 3600
        local minutes = math.floor(seconds / 60)
        seconds = seconds % 60
        return string.format("%d天 %02d时 %02d分 %02d秒", days, hours, minutes, math.floor(seconds))
    end

    local function createPlayerRow(LocalPlayer)
        if controller.Rows[LocalPlayer] then return end
        local button = Tabs.Stats:AddButton({
            Title = LocalPlayer.Name .. " · 正在读取…",
            Callback = function()
                local timeValue = LocalPlayer:FindFirstChild("PlayerData")
                    and LocalPlayer.PlayerData:FindFirstChild("Stats")
                    and LocalPlayer.PlayerData.Stats:FindFirstChild("General")
                    and LocalPlayer.PlayerData.Stats.General:FindFirstChild("TimePlayed")

                local timeText = timeValue and formatTime(timeValue.Value) or "N/A"
                if setclipboard then
                    setclipboard(LocalPlayer.Name .. " - " .. timeText)
                end
            end
        })
        controller.Rows[LocalPlayer] = button
        task.spawn(function()
            local previousText
            while controller.Alive and sessionEnv.VortexionSessionId == thisSessionId do
                task.wait(1.0)
                if not controller.Alive or sessionEnv.VortexionSessionId ~= thisSessionId then return end
                if not LocalPlayer:IsDescendantOf(Players) then
                    local native = button.Native or button
                    if native.Destroy then native:Destroy() end
                    controller.Rows[LocalPlayer] = nil
                    return
                end
                if not controller.Enabled then continue end
                local stats = LocalPlayer:FindFirstChild("PlayerData") and LocalPlayer.PlayerData:FindFirstChild("Stats")
                local general = stats and stats:FindFirstChild("General")
                local killer = stats and stats:FindFirstChild("KillerStats")
                local survivor = stats and stats:FindFirstChild("SurvivorStats")
                local equipped = LocalPlayer:FindFirstChild("PlayerData") and LocalPlayer.PlayerData:FindFirstChild("Equipped")

                local timePlayed = general and general:FindFirstChild("TimePlayed")
                local killerWins = killer and killer:FindFirstChild("KillerWins")
                local killerLosses = killer and killer:FindFirstChild("KillerLosses")
                local survivorWins = survivor and survivor:FindFirstChild("SurvivorWins")
                local survivorLosses = survivor and survivor:FindFirstChild("SurvivorLosses")
                local kills = killer and killer:FindFirstChild("Kills")
                local emotes = equipped and equipped:FindFirstChild("Emotes")

                local timeText = timePlayed and formatTime(timePlayed.Value) or "N/A"
                local kw = killerWins and killerWins.Value or "N/A"
                local kl = killerLosses and killerLosses.Value or "N/A"
                local sw = survivorWins and survivorWins.Value or "N/A"
                local sl = survivorLosses and survivorLosses.Value or "N/A"
                local killCount = kills and kills.Value or "N/A"
                local emoteText = emotes and emotes.Value or "None"

                local updatedText = string.format(
                    "%s\n游戏时长：%s\n幸存者胜场：%s | 败场：%s\n杀手胜场：%s | 败场：%s | 击杀：%s\n表情：%s",
                    LocalPlayer.Name,
                    timeText,
                    sw, sl,
                    kw, kl, killCount,
                    emoteText
                )
                if previousText ~= updatedText then
                    local native = button.Native or button
                    if native.SetTitle then native:SetTitle(updatedText) end
                    previousText = updatedText
                end
            end
        end)
    end

    for _, OtherPlayer in ipairs(Players:GetPlayers()) do
        if OtherPlayer ~= Players.LocalPlayer then createPlayerRow(OtherPlayer) end
    end
    track(Players.PlayerAdded:Connect(function(OtherPlayer)
        if controller.Alive and sessionEnv.VortexionSessionId == thisSessionId and OtherPlayer ~= Players.LocalPlayer then
            createPlayerRow(OtherPlayer)
        end
    end))
    return controller
end

-- Default toggles and helpers (we will hook these to Fluent UI)
local toggles = {
    StatsTracker = false,
    ESP = false,
    infiniteStamina = false,
    AutoRejoinOnKick = true
}
local activeConnections = {}
local guiRefs = {}

-- Anim Ids
local GuestSettingsTriggerAnims = {
    "126830014841198", "126355327951215", "121086746534252", "18885909645",
    "98456918873918", "105458270463374", "83829782357897", "125403313786645",
    "118298475669935", "82113744478546", "70371667919898", "99135633258223",
    "97167027849946", "109230267448394", "139835501033932", "126896426760253",
    "109667959938617", "126681776859538", "129976080405072", "121293883585738",
    "81639435858902", "137314737492715",
    "92173139187970"
}

-- State Variables
local GuestSettingsOn = false
local strictRangeOn = false
local looseFacing = true
local detectionRange = 18

local predictiveBlockOn = false
local AutoPunchEnabled = false
local detectionRange = 10
local edgeKillerDelay = 3
local killerInRangeSince = nil
local predictiveCooldown = 0

local GuestSettingsOn = false
local flingPunchOn = false
local flingPower = 10000
local hiddenfling = false
local aimPunch = false

local customBlockEnabled = false
local customBlockAnimId = ""
local customPunchEnabled = false
local customPunchAnimId = ""

local infiniteStamina = false

local lastBlockTime = 0
local lastPunchTime = 0
local lastBlockTpTime = 0

local blockAnimIds = {
"72722244508749",
"96959123077498"
}
local punchAnimIds = {
"87259391926321"
}

local customChargeEnabled = false
local customChargeAnimId = ""
local chargeAnimIds = { "106014898528300" }

-- Goon animation
local function startGoon()
    local LocalPlayer = Players.LocalPlayer
    local animationId = "rbxassetid://72042024"
    if not guiRefs.GoonAnim then guiRefs.GoonAnim = nil end

    local function playGoonAnim()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        local animTrack = humanoid:LoadAnimation(animation)
        animTrack.Looped = true
        animTrack:Play()
        guiRefs.GoonAnim = animTrack
    end

    playGoonAnim()
    guiRefs.GoonConnection = LocalPlayer.CharacterAdded:Connect(function()
        if toggles.Goon then
            playGoonAnim()
        end
    end)
end

local function stopGoon()
    if guiRefs.GoonAnim then
        guiRefs.GoonAnim:Stop()
        guiRefs.GoonAnim = nil
    end
    if guiRefs.GoonConnection then
        guiRefs.GoonConnection:Disconnect()
        guiRefs.GoonConnection = nil
    end
end

-- LayDown animation
local function startLayDown()
    local LocalPlayer = Players.LocalPlayer
    local animationId = "rbxassetid://181526230"
    local skipTime = 0.2

    if not guiRefs.LayDownAnim then guiRefs.LayDownAnim = nil end

    local function playLayDownAnim()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        local animTrack = humanoid:LoadAnimation(animation)
        animTrack.Looped = true
        animTrack:Play()
        animTrack.TimePosition = skipTime
        guiRefs.LayDownAnim = animTrack
    end

    playLayDownAnim()
    guiRefs.LayDownConnection = LocalPlayer.CharacterAdded:Connect(function()
        if toggles.LayDown then
            playLayDownAnim()
        end
    end)
end

local function generatorDoAll()
    local LocalPlayer = game.Players.LocalPlayer
    local Workspace = game.Workspace

    local function findGenerators()
        local mapFolder = Workspace:FindFirstChild("Map")
        local ingameMap = mapFolder and mapFolder:FindFirstChild("Ingame")
        local map = ingameMap and ingameMap:FindFirstChild("Map")
        local generators = {}

        if map then
            for _, gen in ipairs(map:GetChildren()) do
                if gen.Name == "Generator" and gen:IsA("Model") and gen:FindFirstChild("Progress") and gen.Progress.Value < 100 then
                    -- Check if any LocalPlayers are within 25 studs of generator's Main part
                    local LocalPlayersNearby = false
                    for _, LocalPlayer in ipairs(game.Players:GetPlayers()) do
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and gen:FindFirstChild("Main") then
                            local dist = (hrp.Position - gen.Main.Position).Magnitude
                            if dist < 25 then
                                LocalPlayersNearby = true
                                break
                            end
                        end
                    end

                    if not LocalPlayersNearby then
                        table.insert(generators, gen)
                    end
                end
            end
        end

        return generators
    end

    -- Save current LocalPlayer position to return later
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local lastPosition = humanoidRootPart.CFrame

    -- Main loop: keep working generators until none left
    while sessionEnv.VortexionSessionId == thisSessionId do
        local generators = findGenerators()
        if #generators == 0 then
            break
        end
        -- 长任务中角色可能重生：每轮刷新引用，失效即退出，避免对已销毁部件写 CFrame
        local currentChar = LocalPlayer.Character
        local currentHRP = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not currentHRP then break end

        for _, gen in ipairs(generators) do
            if gen:FindFirstChild("Main") and gen:FindFirstChild("Remotes") and gen.Remotes:FindFirstChild("RE") and gen.Remotes:FindFirstChild("RF") and gen:FindFirstChild("Positions") and gen.Positions:FindFirstChild("Center") and gen:FindFirstChild("Instances") and gen.Instances:FindFirstChild("Generator") then
                -- Compute direction to face generator cube (if it exists)
				local generatorPosition = gen.Positions.Center.Position
				local generatorDirection

				if gen.Instances.Generator:FindFirstChild("Cube") and gen.Instances.Generator.Cube:IsA("BasePart") then
					local cubePos = gen.Instances.Generator.Cube.Position
					local cubeDelta = cubePos - generatorPosition
					generatorDirection = cubeDelta.Magnitude > 0.01 and cubeDelta.Unit or Vector3.new(0, 0, 1)
				else
					generatorDirection = Vector3.new(0, 0, 1) -- fallback direction forward
				end

				-- Teleport LocalPlayer to generator, facing the cube (or forward)
				currentHRP.CFrame = CFrame.new(
					generatorPosition + Vector3.new(0, 0.5, 0),
					generatorPosition + Vector3.new(generatorDirection.X, 0, generatorDirection.Z)
				)

                task.wait(timebetweenpuzzles / 2) -- adjust wait time as needed

                -- Fire the proximity prompt
                local prompt = gen.Main:FindFirstChildOfClass("ProximityPrompt")
                if not prompt then
                    prompt = gen.Main:FindFirstChild("Prompt")
                end
                if prompt then
                    fireproximityprompt(prompt, 1.5, false)
                else
                    warn("No prompt found on generator:", gen.Name)
                end

                -- Fire the remote server call multiple times (6 times as in your example)
                for _ = 1, 6 do
                    task.wait(2.5)
                    gen.Remotes.RE:FireServer()
                end

                task.wait(timebetweenpuzzles / 5) -- small delay before leaving

                -- Invoke the "leave" remote
                gen.Remotes.RF:InvokeServer("leave")
            end
        end
    end

    -- Return LocalPlayer to original position
    if humanoidRootPart and humanoidRootPart.Parent then humanoidRootPart.CFrame = lastPosition end
end

local function stopLayDown()
    if guiRefs.LayDownAnim then
        guiRefs.LayDownAnim:Stop()
        guiRefs.LayDownAnim = nil
    end
    if guiRefs.LayDownConnection then
        guiRefs.LayDownConnection:Disconnect()
        guiRefs.LayDownConnection = nil
    end
end

-- Frontflip implementation
local function createFrontflip()
    return function()
        local sausageHolder
        pcall(function()
            sausageHolder = game.CoreGui.TopBarApp.TopBarApp.UnibarLeftFrame.UnibarMenu["2"]
        end)

        if not sausageHolder then
            -- If TopBar isn't available, skip creating the button but still provide the flip on keypress.
        end

        local FlipCooldown
        local function FortniteFlips()
            if FlipCooldown then
                return
            end

            FlipCooldown = true
            local character = game:GetService("Players").LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            if not hrp or not humanoid then
                FlipCooldown = false
                return
            end
            local savedTracks = {}

            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    savedTracks[#savedTracks + 1] = { track = track, time = track.TimePosition }
                    track:Stop(0)
                end
            end

            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

            local duration = 0.45
            local steps = 120
            local startCFrame = hrp.CFrame
            local forwardVector = startCFrame.LookVector
            local upVector = Vector3.new(0, 1, 0)
            task.spawn(function()
                pcall(function()
                local startTime = tick()
                for i = 1, steps do
                    local t = i / steps
                    local height = 4 * (t - t ^ 2) * 10
                    local nextPos = startCFrame.Position + forwardVector * (35 * t) + upVector * height
                    local rotation = startCFrame.Rotation * CFrame.Angles(-math.rad(i * (360 / steps)), 0, 0)

                    hrp.CFrame = CFrame.new(nextPos) * rotation
                    local elapsedTime = tick() - startTime
                    local expectedTime = (duration / steps) * i
                    local waitTime = expectedTime - elapsedTime
                    if waitTime > 0 then
                        task.wait(waitTime)
                    end
                end

                hrp.CFrame = CFrame.new(startCFrame.Position + forwardVector * 35) * startCFrame.Rotation
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
                humanoid:ChangeState(Enum.HumanoidStateType.Running)

                if animator then
                    for _, data in ipairs(savedTracks) do
                        local track = data.track
                        track:Play()
                        track.TimePosition = data.time
                    end
                end
                task.wait(0.25)
                end)
                FlipCooldown = false
            end)
        end

        -- keybind F
        track(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then return end
            local focused = UserInputService:GetFocusedTextBox()
            if focused then return end
            if input.KeyCode == Enum.KeyCode.P then
                FortniteFlips()
            end
        end))

        return {
            Flip = FortniteFlips,
            SausageHolder = sausageHolder
        }
    end
end

local frontflipObj = createFrontflip()()

-- Active UI references
-- FORSAKEN_WIND_BUNDLE_HEADER
-- build.py replaces these placeholders with an embedded, vendored WindUI source
local WindBridgeFactory = nil
local WindUI = nil
-- Four feature-group module factories (Combat / Visual / Survival / Guest).
-- build.py injects them as embedded IIFE factories and removes these stubs.
local ForsakenCombatFactory = nil
local ForsakenVisualFactory = nil
local ForsakenSurvivalFactory = nil
local ForsakenGuestFactory = nil
local FluentLoaded = false
local success
success, Fluent = pcall(function()
    return WindBridgeFactory(WindUI)
end)
if success and Fluent then
    FluentLoaded = true
else
    warn("[Forsaken] WindUI 无法启动：" .. tostring(Fluent))
end

-- Create the native WindUI window through the compatibility bridge.
local IsMobile = UserInputService.TouchEnabled
-- Mobile sizing and scroll safety live in the WindUI bridge.
if FluentLoaded then
    Window = Fluent:CreateWindow({
    	Title = "Forsaken",
    	SubTitle = "",
    	TabWidth = 160,
    	Size = UDim2.fromOffset(580, 460),
    	Theme = "Dark",
    	MinimizeKey = Enum.KeyCode.K
	})

	Tabs = {
		Combat = Window:AddTab({ Title = "战斗", Icon = "lucide-swords" }),
		Visual = Window:AddTab({ Title = "视觉", Icon = "lucide-eye" }),
		Survival = Window:AddTab({ Title = "生存", Icon = "lucide-heart-pulse" }),
		Guest = Window:AddTab({ Title = "Guest 1337", Icon = "lucide-leaf" }),
		System = Window:AddTab({ Title = "系统", Icon = "lucide-settings" }),
		Emotes = Window:AddTab({ Title = "杀手表情", Icon = "lucide-smile" }),
		Stats = Window:AddTab({ Title = "玩家统计", Icon = "lucide-chart-column" })
	}

    -- Put FOV controls before native theme/config groups on mobile.
    local fovValue, fovActive, fovCamera, fovListener = 80, false, nil, nil
    local savedFov = {}
    local function restoreFov()
        fovActive = false
        if fovListener then fovListener:Disconnect(); fovListener = nil end
        for camera, value in pairs(savedFov) do pcall(function() camera.FieldOfView = value end) end
        table.clear(savedFov)
        fovCamera = nil
    end
    Fluent:OnDestroy(restoreFov)
    local function applyFovValue()
        local camera = Workspace.CurrentCamera
        if not fovActive then return end
        if fovCamera ~= camera then
            if fovCamera and savedFov[fovCamera] ~= nil then
                pcall(function() fovCamera.FieldOfView = savedFov[fovCamera] end)
                savedFov[fovCamera] = nil
            end
            fovCamera = camera
        end
        if not camera then return end
        if savedFov[camera] == nil then savedFov[camera] = camera.FieldOfView end
        local effective = math.min(fovValue, 120) -- Roblox engine camera limit
        if math.abs(camera.FieldOfView - effective) > 0.01 then
            camera.FieldOfView = effective
        end
    end
    Tabs.System:AddSlider("ForsakenFOVValue", {
        Title = "视场角（80–200）", Default = 80, Min = 80, Max = 200, Rounding = 0,
        Callback = function(value)
            fovValue = math.clamp(tonumber(value) or 80, 80, 200)
            applyFovValue()
        end
    })
    Tabs.System:AddToggle("ForsakenFOVEnabled", {
        Title = "应用视场角", Default = false,
        Callback = function(enabled)
            fovActive = enabled
            if not enabled then
                restoreFov()
            else
                applyFovValue()
                if not fovListener then
                    local nextCheck = 0
                    fovListener = RunService.Heartbeat:Connect(function()
                        if sessionEnv.VortexionSessionId ~= thisSessionId then
                            restoreFov()
                            return
                        end
                        local now = os.clock()
                        if now >= nextCheck then
                            nextCheck = now + 0.2
                            applyFovValue()
                        end
                    end)
                end
            end
        end
    })
    Tabs.System:AddParagraph({
        Title = "视场角限制",
        Content = "控制当前相机。引擎实际限制为 120°；没有证据证实游戏设置值可直接改写到 200°。"
    })
    Window:InstallSettings(Tabs.System)

	Fluent:Notify({
		Title = "正在加载…",
		Content = "正在加载 Vortexion - Forsaken 功能模块…",
		Duration = 5,
		Image = "ban",
	})
end

local GuestSettingsOn = false
local strictRangeOn = false
local looseFacing = true
local detectionRange = 18

local predictiveBlockOn = false
local detectionRange = 10
local edgeKillerDelay = 3
local killerInRangeSince = nil
local predictiveCooldown = 0

local GuestSettingsOn = false
local flingPunchOn = false
local flingPower = 10000
local hiddenfling = false
local aimPunch = false

local customBlockEnabled = false
local customBlockAnimId = ""
local customPunchEnabled = false
local customPunchAnimId = ""

local infiniteStamina = false

local lastBlockTime = 0
local lastPunchTime = 0
local lastBlockTpTime = 0

local blockAnimIds = {
"72722244508749",
"96959123077498"
}
local punchAnimIds = {
"87259391926321"
}

local customChargeEnabled = false
local customChargeAnimId = ""
local chargeAnimIds = { "106014898528300" }

-- Stats updates start only when the existing game toggle is enabled.
statsGui = createStatsTracker()
statsGui.Enabled = false

-- Original Goonsaken callback bindings mapped through the native WindUI bridge
if FluentLoaded then
    Tabs.Survival:AddSlider("Walkspeed", {
        Title = "移动速度倍率",
        Default = 1,
        Min = 1,
        Max = 5,
        Rounding = 1,
        Suffix = "x",
        Callback = function(value)
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Parent:FindFirstChild("SpeedMultipliers") then
                humanoid.Parent.SpeedMultipliers.Sprinting.Value = value
            end
        end
    })

    Tabs.Survival:AddSlider("JumpPower", {
        Title = "跳跃力度",
        Default = 50,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(value)
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = value
            end
        end
    })

    Tabs.Survival:AddToggle("Goon", {
        Title = "Goon 动作",
        Default = false,
        Callback = function(state)
            toggles.Goon = state
            if state then
                startGoon()
            else
                stopGoon()
            end
        end
    })

    Tabs.Survival:AddToggle("LayDown", {
        Title = "趴下动作",
        Default = false,
        Callback = function(state)
            toggles.LayDown = state
            if state then
                startLayDown()
            else
                stopLayDown()
            end
        end
    })

    Tabs.Survival:AddButton({
        Title = "前空翻（P 键 / 手机快捷操作） · Fartsaken",
        Callback = function()
            if frontflipObj and frontflipObj.Flip then
                frontflipObj.Flip()
            end
        end
    })

    Tabs.Survival:AddToggle("AntiSlowness", {
        Title = "防减速",
        Default = false,
        Callback = function(state)
            AntiSlow = state
        end
    })

	Tabs.Survival:AddToggle("VoidRushControl", {
    	Title = "虚空冲刺控制（感谢 golden）",
    	Default = false,
    	Callback = function(state)
    	    if state then
    	        startvoidrushcontrol()
    	    else
    	        stopvoidrushcontrol()
    	    end
    	end
	})

    Tabs.Combat:AddButton({
        Title = "404 自动招架",
        Callback = function()
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NumanTF3/auto-404-parry/refs/heads/main/main.lua"))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.Combat:AddButton({
        Title = "Raging Pace 自动招架",
        Callback = function()
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NumanTF3/auto-raging-pace/refs/heads/main/main.lua"))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.Combat:AddToggle("ChanceAimbot", {
        Title = "Chance 自动瞄准",
        Default = false,
        Callback = function(state)
            if state then
                enableAimbot()
            else
                disableAimbot()
            end
        end
    })

	Tabs.Combat:AddSlider("ChanceAimbotPredictionValue", {
        Title = "Chance 预判参数",
        Default = 0.2,
        Min = 0.1,
        Max = 2,
        Rounding = 1,
        Callback = function(value)
			timeAhead = value
        end
    })

    Tabs.Combat:AddButton({
        Title = "极限闪避（自动躲避杀手）",
        Callback = function()
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/NumanTF3/forsaken-ultra-instinct/refs/heads/main/main.lua'))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.Combat:AddButton({
        Title = "Two Time 自动背刺与瞄准",
        Callback = function()
			if setclipboard then setclipboard("https://discord.gg/ETTV2g8kxS") end
			Fluent:Notify({
    			Title = "Two Time 自动背刺",
    			Content = "由 skibisaken 制作，已复制 Discord 链接。",
    			Duration = 8
			})
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/NumanTF3/two-time-backstab/refs/heads/main/main.lua'))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.Visual:AddToggle("Invisible", {
        Title = "角色隐身",
        Default = false,
        Callback = function(state)
            if state then
                Fluent:Notify({
                    Title = "使用说明",
                    Content = "画面中央方块用于指示自身位置；其他玩家不会看到该方块。",
                    Duration = 6.5,
                    Image = "lucide-leaf",
                })
            end
            ToggleInvis(state)
        end
    })

    Tabs.Visual:AddToggle("Invis007n7", {
        Title = "007n7 克隆时完全隐身",
        Default = false,
        Callback = function(state)
            if state then
                Fluent:Notify({
                    Title = "使用说明",
                    Content = "克隆后画面中央方块仅用于显示自身位置，其他玩家不会看到。",
                    Duration = 6.5,
                    Image = "lucide-leaf",
                })
            end
            handleToggle(state)
        end
    })

    Tabs.Combat:AddToggle("HitboxModifier", {
        Title = "命中范围修改（基于 IYRE）",
        Default = false,
        Callback = function(Value)
            hitboxmodificationEnabled = Value
        end
    })

    Tabs.Combat:AddInput("HitboxDetectionDistance", {
        Title = "命中判定距离",
        Default = "120",
        Placeholder = "120",
        Numeric = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                MaxRange = num
            end
        end
    })

    --------------------------------------------------------------------------
    -- Game Tab
    --------------------------------------------------------------------------
    Tabs.Visual:AddToggle("ESPToggle", {
        Title = "ESP 透视（杀手红 / 幸存者绿）",
        Description = "无墙遮挡时透明度 80%；有墙遮挡或屏幕外 0%（高亮完全显示）",
        Default = false,
        Callback = function(state)
            toggles.ESP = state
            ESP:SetEnabled(state)
        end
    })

    -- Stage 2: independently maintained category-based ESP options, inspired by
    -- c00lSaken/OPAI references, using the existing raycast renderer (no duplicate ESP loops).
    Tabs.Visual:AddToggle("EspKillers", {
        Title = "显示杀手（红色）", Default = true,
        Callback = function(v) ESP.ShowKillers = v; ESP:SetEnabled(ESP.Enabled) end
    })
    Tabs.Visual:AddToggle("EspSurvivors", {
        Title = "显示幸存者（绿色）", Default = true,
        Callback = function(v) ESP.ShowSurvivors = v; ESP:SetEnabled(ESP.Enabled) end
    })
    Tabs.Visual:AddToggle("EspIdentity", {
        Title = "用户名与使用角色", Default = true,
        Callback = function(v) ESP.ShowLabels = v; ESP:SetEnabled(ESP.Enabled) end
    })
    Tabs.Visual:AddSlider("EspVisibleTransparency", {
        Title = "无遮挡透明度", Min = 0, Max = 95, Default = 80, Rounding = 0, Suffix = "%",
        Callback = function(v) ESP.VisibleAlpha = math.clamp(v / 100, 0, 0.95) end
    })
    Tabs.Visual:AddToggle("EspHealthDistance", {
        Title = "显示生命值与距离", Default = false,
        Callback = function(v) ESP.ShowDetails = v; ESP:SetEnabled(ESP.Enabled) end
    })
    Tabs.Visual:AddSlider("EspRefreshRate", {
        Title = "遮挡检测频率", Min = 2, Max = 20, Default = 10, Rounding = 0, Suffix = "Hz",
        Callback = function(v) ESP.CheckHz = math.clamp(v, 2, 20) end
    })

    -- Vortexion: generator readout uses the current generator index and a 1Hz
    -- distance sampler. It never duplicates auto-solve or generator listeners.
    Tabs.Visual:AddToggle("GeneratorProgressESP", {
        Title = "发电机进度与距离标签", Default = false,
        Callback = function(v) ESP.GeneratorDetails = v; ESP:RefreshGeneratorLabels() end
    })
    Tabs.Visual:AddToggle("GeneratorShowCompleted", {
        Title = "标签包含已完成发电机", Default = false,
        Callback = function(v) ESP.CompletedGenerators = v; ESP:RefreshGeneratorLabels() end
    })

    -- Reimplemented from the *idea* of c00lSaken's killer tracking and
    -- OPAI's proximity options, not pasted from either reference source.
    do
        local alert = { Enabled=false, Range=35, Generation=0, LastGlobal=0, Cooldown=6, LastByCharacter=setmetatable({}, {__mode="k"}) }
        function alert:SetEnabled(state)
            state = not not state
            if self.Enabled == state then return end
            self.Enabled = state
            self.Generation += 1
            if not state then return end
            local generation = self.Generation
            task.spawn(function()
                while self.Enabled and self.Generation == generation do
                    local own = LocalPlayer.Character
                    local ownRoot = own and own:FindFirstChild("HumanoidRootPart")
                    local folders = Workspace:FindFirstChild("Players")
                    local killers = folders and folders:FindFirstChild("Killers")
                    if ownRoot and killers then
                        local nearest, minDistance = nil, self.Range
                        for _, model in ipairs(killers:GetChildren()) do
                            if model ~= own then
                                local root = model:FindFirstChild("HumanoidRootPart")
                                local humanoid = model:FindFirstChildOfClass("Humanoid")
                                if root and (not humanoid or humanoid.Health > 0) then
                                    local dist = (root.Position - ownRoot.Position).Magnitude
                                    if dist <= minDistance then nearest, minDistance = model, dist end
                                end
                            end
                        end
                        local now = os.clock()
                        if nearest and now - self.LastGlobal >= self.Cooldown
                            and now - (self.LastByCharacter[nearest] or -100) >= self.Cooldown then
                            self.LastGlobal = now
                            self.LastByCharacter[nearest] = now
                            pcall(function()
                                Fluent:Notify({Title = "杀手接近警报", Content = nearest.Name .. " · " .. tostring(math.floor(minDistance)) .. " studs", Duration = 2.5})
                            end)
                        end
                    end
                    task.wait(0.4) -- 2.5 Hz, no work while switched off
                end
            end)
        end
        Tabs.Visual:AddToggle("KillerProximityAlert", {
            Title = "杀手接近提醒（手机友好）", Default = false,
            Callback = function(v) alert:SetEnabled(v) end
        })
        Tabs.Visual:AddSlider("KillerProximityRadius", {
            Title = "提醒距离", Min = 10, Max = 100, Default = 35, Rounding = 0, Suffix = " studs",
            Callback = function(v) alert.Range = math.clamp(v,10,100) end
        })
    end

    Tabs.Survival:AddToggle("StatsTrackerToggle", {
        Title = "玩家数据统计",
        Default = false,
        Callback = function(state)
            toggles.StatsTracker = state
            if statsGui then
                statsGui.Enabled = state
                if state and Window then Window:SelectTab(7) end
            end
        end
    })

    -- v4: 角色切换/杀手回合会重新初始化 Sprinting 参数，单一标志位不够稳定。
    -- 此处只有一个后台维护任务；关闭时按开启前的实际值恢复，不把 nil 强改为 false。
    do
        local controller = {
            Enabled = false,
            Generation = 0,
            ModuleInstance = nil,
            Module = nil,
            Original = setmetatable({}, { __mode = "k" }),
            LastWarnAt = -10,
        }

        function controller:FindSprintingModule()
            local systems = game:GetService("ReplicatedStorage"):FindFirstChild("Systems")
            local characters = systems and (systems:FindFirstChild("Character") or systems:FindFirstChild("character"))
            local gameFolder = characters and (characters:FindFirstChild("Game") or characters:FindFirstChild("game"))
            return gameFolder and (gameFolder:FindFirstChild("Sprinting") or gameFolder:FindFirstChild("sprinting"))
        end

        function controller:Resolve()
            local moduleInstance = self:FindSprintingModule()
            if not moduleInstance then
                self.Module = nil
                self.ModuleInstance = nil
                return nil
            end
            if moduleInstance == self.ModuleInstance and type(self.Module) == "table" then
                return self.Module
            end
            local ok, module = pcall(require, moduleInstance)
            if not ok or type(module) ~= "table" then
                self.Module = nil
                if os.clock() - self.LastWarnAt > 8 then
                    self.LastWarnAt = os.clock()
                    warn("[Vortexion] Sprinting 模块不可用（执行器可能不支持 require）：", module)
                end
                return nil
            end
            self.ModuleInstance = moduleInstance
            self.Module = module
            return module
        end

        function controller:Apply()
            if not self.Enabled then return end
            local module = self:Resolve()
            if not module or not self.Enabled then return end
            if not self.Original[module] then
                -- value 字段以表包裹，能区分原来的 nil 与 false。
                local snapshot = {}
                for _, key in ipairs({"StaminaLossDisabled", "StaminaLoss", "StaminaGain"}) do
                    snapshot[key] = { value = module[key] }
                end
                self.Original[module] = snapshot
            end
            if module.StaminaLossDisabled ~= true then module.StaminaLossDisabled = true end
            if type(module.StaminaLoss) == "number" and module.StaminaLoss ~= 0 then
                module.StaminaLoss = 0
            end
            local maximum = module.MaxStamina
            if type(maximum) ~= "number" or maximum <= 0 then maximum = 100 end
            -- 杀手原版体力上限通常高于幸存者：不强制覆盖 MaxStamina。
            local gain = math.max(maximum * 6, 200)
            if type(module.StaminaGain) == "number" and module.StaminaGain < gain then
                module.StaminaGain = gain
            end
            if type(module.Stamina) == "number" and module.Stamina < maximum then
                module.Stamina = maximum
                local changed = module.__staminaChangedEvent
                if changed then
                    pcall(function()
                        if type(changed.Fire) == "function" then changed:Fire() end
                    end)
                end
            end
        end

        function controller:Restore()
            for module, snapshot in pairs(self.Original) do
                for key, entry in pairs(snapshot) do
                    pcall(function() module[key] = entry.value end)
                end
                self.Original[module] = nil
            end
            self.Module = nil
            self.ModuleInstance = nil
        end

        function controller:SetEnabled(state)
            state = not not state
            if self.Enabled == state then return end
            self.Enabled = state
            self.Generation += 1
            local generation = self.Generation
            if not state then
                self:Restore()
                return
            end
            -- 开关即时响应；游戏回合或角色重新加载时每 0.15s 自恢复。
            pcall(function() self:Apply() end)
            task.spawn(function()
                while self.Enabled and self.Generation == generation do
                    local ok, err = pcall(function() self:Apply() end)
                    if not ok and os.clock() - self.LastWarnAt > 8 then
                        self.LastWarnAt = os.clock()
                        warn("[Vortexion] 无限体力维护失败：", err)
                    end
                    task.wait(0.15)
                end
            end)
        end

        -- 重新出生/切换杀手或幸存者时保留开关状态并刷新模块引用。
        LocalPlayer.CharacterAdded:Connect(function()
            controller.Module = nil
            controller.ModuleInstance = nil
            if controller.Enabled then
                task.defer(function()
                    if controller.Enabled then pcall(function() controller:Apply() end) end
                end)
            end
        end)

        Tabs.Survival:AddToggle("InfiniteStamina", {
            Title = "无限体力（杀手 / 幸存者）",
            Description = "持续维护体力，回合切换后自动恢复；需要执行器支持 require",
            Default = false,
            Callback = function(value)
                controller:SetEnabled(value)
            end
        })
    end
	
    -- Auto Rejoin on Kick (default ON)
    Tabs.Survival:AddToggle("AutoRejoinToggle", {
        Title = "被踢出后自动重进",
        Default = true,
        Callback = function(state)
            toggles.AutoRejoinOnKick = state
            if state then
                if not activeConnections.AutoRejoin then
                    activeConnections.AutoRejoin = GuiService.ErrorMessageChanged:Connect(function(msg)
                        if msg and msg ~= "" then
                            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
                        end
                    end)
                end
            else
                if activeConnections.AutoRejoin then
                    activeConnections.AutoRejoin:Disconnect()
                    activeConnections.AutoRejoin = nil
                end
            end
        end
    })

    Tabs.Survival:AddButton({
        Title = "重新加入当前服务器",
        Callback = function()
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
        end
    })
    
    Tabs.Survival:AddToggle("autofixgen", {
        Title = "自动解当前发电机（需进入解谜）",
		Default = false,
        Callback = function(state)
			triggerNearestGenerator(state)
        end
    })

	Tabs.Survival:AddSlider("OneGenSpeedValue", {
        Title = "当前发电机解谜间隔",
        Default = 2.5,
        Min = 2.5,
        Max = 10,
        Rounding = 1,
        Callback = function(value)
            timeforonegen = value
        end
    })

    Tabs.Survival:AddToggle("auto1x1x1x1popups", {
        Title = "自动关闭 1x1x1x1 弹窗",
        Default = false,
        Callback = function(state)
            Do1x1PopupsLoop = state
            if state then
                task.spawn(Do1x1x1x1Popups)
            end
        end
    })
    
    --------------------------------------------------------------------------
    -- Misc Tab
    --------------------------------------------------------------------------
    Tabs.System:AddButton({
        Title = "加载 Infinite Yield",
        Callback = function()
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.System:AddToggle("NameProtect", {
        Title = "名字保护（隐藏玩家用户名）",
        Default = false,
        Callback = function(state)
            if NameProtectActive == state then return end
            NameProtectActive = state
            if state then
                task.spawn(NameProtect)
            end
        end
    })

    Tabs.System:AddButton({
        Title = "FPS 性能优化（会降低画质）",
        Callback = function()
			local okLoad, errLoad = pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/NumanTF3/roblox-fpsboost-script/refs/heads/main/main.lua'))() end)
			if not okLoad then
			    warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
			    if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
			end
        end
    })

    Tabs.System:AddToggle("SettingsVideo", {
		Title = "暂停菜单播放 ONE MORE GAME 视频",
		Default = false,
		Callback = function(state)
            if state and (type(isfile) ~= "function" or type(writefile) ~= "function" or type(getcustomasset) ~= "function") then
                if Fluent then
                    Fluent:Notify({Title = "当前设备不支持", Content = "该视频功能需要执行器支持本地文件和视频资源加载。", Duration = 5})
                end
                return
            end
			if state then
				-- === Config ===
				local folderPath = "GoonsakenHub/Assets"
				local fileName = "onemoregame.webm"
				local fullPath = folderPath .. "/" .. fileName
				local videoUrl = "https://raw.githubusercontent.com/NumanTF3/Goonsaken-Hub/refs/heads/main/onemoregame.webm"

				-- Ensure folder exists
				if not isfolder("GoonsakenHub") then makefolder("GoonsakenHub") end
				if not isfolder(folderPath) then makefolder(folderPath) end

				-- Download if missing
				if not isfile(fullPath) then
					Fluent:Notify({
						Title = "视频资源",
						Content = "正在下载视频资源…",
						Duration = 5
					})

					local request = http_request or syn.request or request
					if not request then error("Executor does not support HTTP requests.") end

					local response = request({
						Url = videoUrl,
						Method = "GET"
					})

					if response and response.Success and response.Body then
						writefile(fullPath, response.Body)
						Fluent:Notify({
							Title = "视频资源",
							Content = "视频资源下载成功。",
							Duration = 5
						})
					else
						Fluent:Notify({
							Title = "视频资源",
							Content = "视频资源下载失败。",
							Duration = 5
						})
						return
					end
				else
					Fluent:Notify({
						Title = "视频资源",
						Content = "正在使用已缓存的视频。",
						Duration = 5
					})
				end

				-- Asset for VideoFrame
				local videoAsset = getcustomasset(fullPath)
				local CoreGui = game:GetService("CoreGui")
				local robloxGui = CoreGui:WaitForChild("RobloxGui", 10)
					local clippingShield = robloxGui and robloxGui:WaitForChild("SettingsClippingShield", 10)
					local SettingsShield = clippingShield and clippingShield:WaitForChild("SettingsShield", 10)

				local videoGui

				local function createVideo()
					if videoGui then return end
					videoGui = Instance.new("ScreenGui")
					videoGui.IgnoreGuiInset = true
					videoGui.ResetOnSpawn = false
					videoGui.Parent = PlayerGui

					local videoFrame = Instance.new("VideoFrame", videoGui)
					videoFrame.Name = "BackVideo"
					videoFrame.Size = UDim2.new(1, 0, 1, 0)
					videoFrame.Position = UDim2.new(0, 0, 0, 0)
					videoFrame.BackgroundTransparency = 1
					videoFrame.Video = videoAsset
					videoFrame.Looped = true
					videoFrame.Volume = 3
					videoFrame:Play()
				end

				local function removeVideo()
					if videoGui then
						videoGui:Destroy()
						videoGui = nil
					end
				end

				-- Monitor
				_G.SettingsVideoLoop = task.spawn(function() if not SettingsShield then return end
					local wasVisible = SettingsShield.Visible
					while state do
						local isVisible = SettingsShield.Visible
						if isVisible and not wasVisible then
							createVideo()
						elseif not isVisible and wasVisible then
							removeVideo()
						end
						wasVisible = isVisible
						task.wait(0.1)
					end
					removeVideo()
				end)

			else
				if _G.SettingsVideoLoop then
					task.cancel(_G.SettingsVideoLoop)
					_G.SettingsVideoLoop = nil
				end
			end
		end
	})

    Tabs.System:AddInput("PlaySoundByID", {
        Title = "按资源 ID 播放声音",
        Placeholder = "输入 Roblox 音效 ID",
        Numeric = true,
        Callback = function(input)
            local id = tonumber(input)
            if id then
                soundPlayer.SoundId = "rbxassetid://" .. id
                soundPlayer:Play()
            else
                warn("Invalid Sound ID: " .. tostring(input))
            end
        end
    })

    Tabs.System:AddDropdown("ChangeLMSSong", {
        Title = "选择 LMS 音乐",
        Values = {
            "Burnout", "Compass", "Vanity", "Close To Me", "Plead",
            "Creation Of Hatred"
        },
        Multi = false,
        Default = 1,
        Callback = function(Value)
            selectedSong = Value
            print("Selected LMS song:", selectedSong)
        end
    })

    Tabs.System:AddButton({
        Title = "替换 LMS 音乐",
        Callback = function()
            print("Waiting for Workspace.Themes.LastSurvivor to exist...")
            local theme = game.Workspace:WaitForChild("Themes", 30)
            if not theme then
                if Fluent then Fluent:Notify({Title = "LMS 音乐", Content = "未找到 Workspace.Themes，该功能仅限 LMS 模式可用。", Duration = 5}) end
                return
            end
            local lastSurvivor = theme:WaitForChild("LastSurvivor", 15)
            if not lastSurvivor then
                if Fluent then Fluent:Notify({Title = "LMS 音乐", Content = "未找到 Themes.LastSurvivor，可能尚未加载完成。", Duration = 5}) end
                return
            end
            local songId = LMSSongs[selectedSong]
            if songId then
                lastSurvivor.SoundId = songId
                lastSurvivor:Play()
                print("Changed LMS song to:", selectedSong)
            else
                warn("Invalid song name:", tostring(selectedSong))
            end
        end
    })
    --------------------------------------------------------------------------
    -- Blatant Tab
    --------------------------------------------------------------------------
    Tabs.Survival:AddButton({
        Title = "自动完成所有发电机",
        Callback = function()
            task.spawn(generatorDoAll)
        end
    })

    Tabs.Survival:AddSlider("GenSpeedValue", {
        Title = "全部发电机解谜间隔",
        Default = 3,
        Min = 3,
        Max = 10,
        Rounding = 1,
        Callback = function(value)
            timebetweenpuzzles = value
        end
    })

    --------------------------------------------------------------------------
    -- Auto Block Tab
    --------------------------------------------------------------------------
	Tabs.Guest:AddParagraph({
        Title = "致谢 Skibisaken",
        Content = "此功能组来自 skibisaken 的脚本，社区：https://discord.gg/ETTV2g8kxS"
    })

    -- One shared, detachable job instead of one permanent Stepped hook per toggle.
    local chargeConnection, chargeLastTime = nil, 0
    Tabs.Guest:AddToggle("ChargeSpeedToggle", {
        Title = "自定义冲锋速度", Default = false,
        Callback = function(enabled)
            if chargeConnection then chargeConnection:Disconnect(); chargeConnection = nil end
            if not enabled then return end
            chargeConnection = RunService.Heartbeat:Connect(function()
                if sessionEnv.VortexionSessionId ~= thisSessionId then
                    chargeConnection:Disconnect(); chargeConnection = nil
                    return
                end
                if os.clock() - chargeLastTime < 0.1 then return end
                chargeLastTime = os.clock()
                local character = LocalPlayer.Character
                local multipliers = character and character:FindFirstChild("SpeedMultipliers")
                local charge = multipliers and multipliers:FindFirstChild("Guest1337Charge")
                if charge and charge:IsA("NumberValue") and charge.Value ~= GuestChargeSpeed then
                    charge.Value = GuestChargeSpeed
                end
            end)
        end
    })

	Tabs.Guest:AddSlider("GuestChargeSpeed", {
        Title = "冲锋速度",
        Default = 2.833,
        Min = 2.833,
        Max = 15,
        Rounding = 1,
        Callback = function(Value)
            GuestChargeSpeed = Value
        end
    })

    -- Attack-sound awareness: event-driven, no frame-by-frame workspace scan.
    local guestSoundWarningEnabled = false
    local guestSoundWarningRange = 20
    local guestSoundWarnings = {}
    local guestSoundLastWarning = 0
    local guestSoundIds = {
        ["102228729296384"] = true, ["140242176732868"] = true,
        ["86174610237192"] = true, ["101199185291628"] = true,
        ["95079963655241"] = true, ["112809109188560"] = true,
        ["84307400688050"] = true, ["136323728355613"] = true
    }
    local function stopGuestSoundWarnings()
        guestSoundWarningEnabled = false
        for _, conn in ipairs(guestSoundWarnings) do
            if conn.Connected then conn:Disconnect() end
        end
        table.clear(guestSoundWarnings)
    end
    local function startGuestSoundWarnings()
        stopGuestSoundWarnings()
        guestSoundWarningEnabled = true
        local playersFolder = Workspace:FindFirstChild("Players")
        local killers = playersFolder and playersFolder:FindFirstChild("Killers")
        if not killers then
            guestSoundWarningEnabled = false
            return
        end
        local seen = {}
        local function check(sound)
            if not guestSoundWarningEnabled or sessionEnv.VortexionSessionId ~= thisSessionId then
                return
            end
            local id = tostring(sound.SoundId):match("%d+")
            if not guestSoundIds[id] or not sound:IsDescendantOf(killers) then return end
            local now = os.clock()
            if now - guestSoundLastWarning < 2 then return end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local model = sound:FindFirstAncestorOfClass("Model")
            local targetRoot = model and model:FindFirstChild("HumanoidRootPart")
            if not targetRoot then
                local ancestor = model and model.Parent
                if ancestor and ancestor:IsA("Model") then
                    targetRoot = ancestor:FindFirstChild("HumanoidRootPart")
                end
            end
            if not (root and targetRoot) then return end
            local offset = root.Position - targetRoot.Position
            if offset:Dot(offset) > guestSoundWarningRange * guestSoundWarningRange then return end
            guestSoundLastWarning = now
            Fluent:Notify({Title = "Guest 1337 · 攻击预警",
                Content = "检测到附近杀手攻击音效", Duration = 2})
        end
        local function observe(item)
            if not item:IsA("Sound") or seen[item] then return end
            seen[item] = true
            local function bindIfKnown()
                local id = tostring(item.SoundId):match("%d+")
                if not guestSoundIds[id] then return end
                table.insert(guestSoundWarnings, item.Played:Connect(function() check(item) end))
            end
            bindIfKnown()
        end
        for _, item in ipairs(killers:GetDescendants()) do observe(item) end
        table.insert(guestSoundWarnings, killers.DescendantAdded:Connect(observe))
    end
    Tabs.Combat:AddToggle("GuestSoundWarning", {
        Title = "杀手攻击音效预警", Default = false,
        Callback = function(enabled)
            if enabled then startGuestSoundWarnings() else stopGuestSoundWarnings() end
        end
    })
    Tabs.Combat:AddSlider("GuestSoundWarningRange", {
        Title = "攻击预警距离", Default = 20, Min = 8, Max = 45, Rounding = 0,
        Suffix = "studs", Callback = function(value)
            guestSoundWarningRange = math.clamp(tonumber(value) or 20, 8, 45)
        end
    })
    Tabs.Combat:AddParagraph({Title = "音效预警说明",
        Content = "参考上传源码重新实现。仅启用时监听杀手音效，2 秒通知冷却，关闭时释放连接；音效 ID 可能随游戏更新失效。"})

    Tabs.Combat:AddToggle("GuestSettingsToggle", {
        Title = "自动格挡",
        Default = false,
        Callback = function(Value)
            GuestSettingsOn = Value
        end
    })

    Tabs.Combat:AddToggle("StrictRangeToggle", {
        Title = "严格距离判定",
        Default = false,
        Callback = function(Value)
            strictRangeOn = Value
        end
    })

    Tabs.Combat:AddDropdown("FacingCheckDropdown", {
        Title = "朝向判定",
        Values = { "Loose", "Strict" },
        Multi = false,
        Default = "Loose",
        Callback = function(Option)
            looseFacing = Option == "Loose"
        end
    })

    Tabs.Combat:AddInput("DetectionRangeInput", {
        Title = "检测距离",
        Placeholder = "18",
        Numeric = true,
        Callback = function(Text)
            detectionRange = tonumber(Text) or detectionRange
        end
    })

    Tabs.Combat:AddParagraph({
        Title = "⚠️ 注意",
        Content = "不要同时启用格挡传送与假格挡，可能引发冲突。"
    })

    Tabs.Combat:AddParagraph({
        Title = "",
        Content = "提高检测距离有助于格挡传送，建议约 30 studs。"
    })

    Tabs.Combat:AddToggle("BlockTPToggle", {
        Title = "格挡传送",
        Default = false,
        Callback = function(Value)
            blockTPEnabled = Value
        end
    })

    --------------------------------------------------------------------------
    -- Predictive Auto Block Tab
    --------------------------------------------------------------------------
    Tabs.Combat:AddToggle("PredictiveBlockToggle", {
        Title = "预测式自动格挡",
        Default = false,
        Callback = function(Value)
            predictiveBlockOn = Value
        end
    })

    Tabs.Combat:AddInput("PredictiveDetectionRange", {
        Title = "检测距离",
        Placeholder = "10",
        Numeric = true,
        Callback = function(text)
            local num = tonumber(text)
            if num then
                detectionRange = num
            end
        end
    })

    Tabs.Combat:AddSlider("EdgeKillerSlider", {
        Title = "边缘目标延迟",
        Default = 3,
        Min = 0,
        Max = 7,
        Rounding = 1,
        Callback = function(val)
            edgeKillerDelay = val
        end
    })

	Tabs.Combat:AddParagraph({
        Title = "边缘目标延迟",
        Content = "目标进入范围后延迟格挡的秒数；离开范围将重置计时。"
    })

    --------------------------------------------------------------------------
    -- Fake Block Tab
    --------------------------------------------------------------------------
    Tabs.Guest:AddButton({
        Title = "触发假格挡（WindUI）",
        Callback = function()
            local legacy = PlayerGui:FindFirstChild("FakeBlockGui")
            if legacy then legacy:Destroy() end
            local guest = sessionEnv.VortexionGuest
            if guest and guest.buildFakeBlockGui and guest.triggerFakeBlock then
                guest.buildFakeBlockGui()
                guest.triggerFakeBlock()
                if Window then Window:SelectTab(4) end
            else
                Fluent:Notify({ Title = "假格挡", Content = "Guest 功能组尚未就绪。", Duration = 3 })
            end
        end
    })

    --------------------------------------------------------------------------
    -- Auto Punch Tab
    --------------------------------------------------------------------------
    Tabs.Combat:AddToggle("AutoPunchToggle", {
        Title = "自动出拳",
        Default = false,
        Callback = function(Value)
            AutoPunchEnabled = Value
        end
    })

    Tabs.Combat:AddToggle("FlingPunchToggle", {
        Title = "击退出拳",
        Default = false,
        Callback = function(Value)
            flingPunchOn = Value
        end
    })

    Tabs.Combat:AddToggle("PunchAimbotToggle", {
        Title = "出拳自动瞄准",
        Default = false,
        Callback = function(Value)
            aimPunch = Value
        end
    })

    local predictionValue = 4
    Tabs.Combat:AddSlider("AimPredictionSlider", {
        Title = "瞄准预判距离",
        Default = predictionValue,
        Min = 0,
        Max = 10,
        Rounding = 1,
        Suffix = "studs",
        Callback = function(Value)
            predictionValue = Value
        end
    })

    Tabs.Combat:AddSlider("FlingPowerSlider", {
        Title = "击退力度",
        Default = 10000,
        Min = 5000,
        Max = 50000000000000,
        Rounding = 0,
        Callback = function(Value)
            flingPower = Value
        end
    })

    --------------------------------------------------------------------------
    -- Custom Animations Tab
    --------------------------------------------------------------------------
    Tabs.Visual:AddInput("CustomBlockAnim", {
        Title = "自定义格挡动画",
        Placeholder = "动画 ID",
        Callback = function(Text)
            customBlockAnimId = Text
        end
    })

    Tabs.Visual:AddToggle("EnableCustomBlockAnim", {
        Title = "启用自定义格挡动画",
        Default = false,
        Callback = function(Value)
            customBlockEnabled = Value
        end
    })

    Tabs.Visual:AddInput("CustomPunchAnim", {
        Title = "自定义出拳动画",
        Placeholder = "动画 ID",
        Callback = function(Text)
            customPunchAnimId = Text
        end
    })

    Tabs.Visual:AddToggle("EnableCustomPunchAnim", {
        Title = "启用自定义出拳动画",
        Default = false,
        Callback = function(Value)
            customPunchEnabled = Value
        end
    })

    Tabs.Visual:AddInput("ChargeAnimID", {
        Title = "冲锋动画 ID",
        Placeholder = "输入动画 ID",
        Callback = function(input)
            customChargeAnimId = input
        end
    })

    Tabs.Visual:AddToggle("EnableCustomChargeAnim", {
        Title = "自定义冲锋动画",
        Default = false,
        Callback = function(value)
            customChargeEnabled = value
        end
    })

	Tabs.System:AddButton({
        Title = "复制 Discord 邀请链接",
        Callback = function()
			if setclipboard then setclipboard("https://discord.gg/aXNagEYb2f") end
			Fluent:Notify({
    			Title = "已复制 Discord 邀请链接",
    			Content = "邀请链接已复制到剪贴板。",
    			Duration = 8
			})
        end
    })
else
	-- Fluent not loaded fallback: wire minimal keybinds and defaults
    warn("WindUI not loaded; GUI controls unavailable; gameplay hooks retained.")
end

-- Native WindUI manages content scrolling and mobile layout.


-- Ensure AutoRejoin default ON (original script created a connection by default)
if not activeConnections.AutoRejoin and toggles.AutoRejoinOnKick then
    activeConnections.AutoRejoin = GuiService.ErrorMessageChanged:Connect(function(msg)
        if msg and msg ~= "" then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
        end
    end)
end

-- Initially disable ESP visuals (kept behavior)
ESP:SetEnabled(false)

local AttackAnimations = {
	"rbxassetid://131430497821198", "rbxassetid://83829782357897", "rbxassetid://126830014841198",
	"rbxassetid://126355327951215", "rbxassetid://121086746534252", "rbxassetid://105458270463374",
	"rbxassetid://127172483138092", "rbxassetid://18885919947", "rbxassetid://18885909645",
	"rbxassetid://87259391926321", "rbxassetid://106014898528300", "rbxassetid://86545133269813",
	"rbxassetid://89448354637442", "rbxassetid://90499469533503", "rbxassetid://116618003477002",
	"rbxassetid://106086955212611", "rbxassetid://107640065977686", "rbxassetid://77124578197357",
	"rbxassetid://101771617803133", "rbxassetid://134958187822107", "rbxassetid://111313169447787",
	"rbxassetid://71685573690338", "rbxassetid://129843313690921", "rbxassetid://97623143664485",
	"rbxassetid://136007065400978", "rbxassetid://86096387000557", "rbxassetid://108807732150251",
	"rbxassetid://138040001965654", "rbxassetid://73502073176819", "rbxassetid://86709774283672",
	"rbxassetid://140703210927645", "rbxassetid://96173857867228", "rbxassetid://121255898612475",
	"rbxassetid://98031287364865", "rbxassetid://119462383658044", "rbxassetid://77448521277146",
	"rbxassetid://103741352379819", "rbxassetid://131696603025265", "rbxassetid://122503338277352",
	"rbxassetid://97648548303678", "rbxassetid://94162446513587", "rbxassetid://84426150435898",
	"rbxassetid://93069721274110", "rbxassetid://114620047310688", "rbxassetid://97433060861952",
	"rbxassetid://82183356141401", "rbxassetid://100592913030351", "rbxassetid://121293883585738",
	"rbxassetid://70447634862911", "rbxassetid://92173139187970", "rbxassetid://106847695270773",
	"rbxassetid://125403313786645", "rbxassetid://81639435858902", "rbxassetid://137314737492715",
	"rbxassetid://120112897026015", "rbxassetid://82113744478546", "rbxassetid://118298475669935",
	"rbxassetid://126681776859538", "rbxassetid://129976080405072", "rbxassetid://109667959938617",
	"rbxassetid://74707328554358", "rbxassetid://133336594357903", "rbxassetid://86204001129974",
	"rbxassetid://124243639579224", "rbxassetid://70371667919898", "rbxassetid://131543461321709",
	"rbxassetid://136323728355613", "rbxassetid://109230267448394"
}

-- Helpers
local function fireRemoteBlock()
	local args = {"UseActorAbility", "Block"}
	local modules = ReplicatedStorage:WaitForChild("Modules", 10); local network = modules and modules:WaitForChild("Network", 10); local remote = network and network:WaitForChild("RemoteEvent", 10); if remote then remote:FireServer(unpack(args)) else warn("[Vortexion] Block remote unavailable") end
end

local function isFacing(localRoot, targetRoot)
    if not facingCheckEnabled then
        return true
    end
    if not localRoot or not targetRoot then
        return false
    end

    local offset = localRoot.Position - targetRoot.Position
    if offset.Magnitude == 0 then
        return false -- same position, can't determine facing
    end

    local dir = offset.Unit
    local dot = targetRoot.CFrame.LookVector:Dot(dir)

    if looseFacing then
        return dot > -0.3
    else
        return dot > 0
    end
end

local function playCustomAnim(animId, isPunch)
    if not Humanoid then
        warn("Humanoid missing")
        return
    end

    if not animId or animId == "" then
        warn("No animation ID provided")
        return
    end

    local now = tick()
    local lastTime = isPunch and lastPunchTime or lastBlockTime
    if now - lastTime < 1 then
        return
    end

    -- Stop other known anims
    for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
        local animNum = tostring(track.Animation.AnimationId):match("%d+")
        if table.find(isPunch and punchAnimIds or blockAnimIds, animNum) then
            track:Stop()
        end
    end

    -- Create and load the animation
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. animId

    local success, track = pcall(function()
        return Humanoid:LoadAnimation(anim)
    end)

    if success and track then
        print("Playing custom " .. (isPunch and "punch" or "block") .. " animation:", animId)
        track:Play()
        if isPunch then
            lastPunchTime = now
        else
            lastBlockTime = now
        end
    else
        warn("Failed to load or play custom animation: " .. animId)
    end
end

-- Removed a dead 10 Hz character lookup; it only created function-local shadows.

coroutine.wrap(function()
    local hrp, c, vel, movel = nil, nil, nil, 0.1
    while sessionEnv.VortexionSessionId == thisSessionId do
        task.wait(hiddenfling and 0.016 or 0.25)
        if hiddenfling then
            while hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
                RunService.Heartbeat:Wait()
                c = LocalPlayer.Character
                hrp = c and c:FindFirstChild("HumanoidRootPart")
            end
            if hiddenfling then
                vel = hrp.Velocity
                hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end
    end
end)()

do
-- v3: Combat feature checks run on a bounded budget; disabled features do not scan players.
local lastCombatScan = 0
RunService.Heartbeat:Connect(function()
    if not (GuestSettingsOn or blockTPEnabled or predictiveBlockOn or AutoPunchEnabled) then return end
    local now = os.clock()
    if now - lastCombatScan < 0.06 then return end
    lastCombatScan = now
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    Humanoid = myChar:FindFirstChildOfClass("Humanoid")
        -- Auto Block: Trigger block if a valid animation is played by a killer
    if GuestSettingsOn then for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            -- A player character is already sourced from Players:GetPlayers().
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local animTracks = hum and hum:FindFirstChildOfClass("Animator") and hum:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()

            if hrp and myRoot and (hrp.Position - myRoot.Position).Magnitude <= detectionRange then
                for _, track in ipairs(animTracks or {}) do
                    local id = tostring(track.Animation.AnimationId):match("%d+")
                    if table.find(GuestSettingsTriggerAnims, id) then
                        if GuestSettingsOn and (not strictRangeOn or (hrp.Position - myRoot.Position).Magnitude <= detectionRange) then
                            if isFacing(myRoot, hrp) then
                                fireRemoteBlock()
                                if customBlockEnabled and customBlockAnimId ~= "" then
                                    playCustomAnim(customBlockAnimId, false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    end -- GuestSettingsOn

    -- Detect if LocalPlayer is playing a block animation, and blockTP is enabled
    if blockTPEnabled and Humanoid and tick() - lastBlockTpTime >= 5 then
        for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
            local animId = tostring(track.Animation.AnimationId):match("%d+")
            if animId == "72722244508749" or animId == "96959123077498" then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local killers = {"c00lkidd", "Jason", "JohnDoe", "1x1x1x1", "Noli"}
                    for _, name in ipairs(killers) do
                        local killer = workspace:FindFirstChild("Players")
                            and workspace.Players:FindFirstChild("Killers")
                            and workspace.Players.Killers:FindFirstChild(name)


                        if killer and killer:FindFirstChild("HumanoidRootPart") then
                            lastBlockTpTime = tick()

                            task.spawn(function()
                                local startTime = tick()
                                while tick() - startTime < 0.5 do
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        local myRoot = LocalPlayer.Character.HumanoidRootPart
                                        local targetHRP = killer.Parent and killer:FindFirstChild("HumanoidRootPart")
                                        local direction = targetHRP and targetHRP.CFrame.LookVector
                                        local tpPosition = targetHRP and (targetHRP.Position + direction * 6)
                                        if tpPosition then myRoot.CFrame = CFrame.new(tpPosition) end
                                    end
                                    task.wait()
                                end
                            end)

                            break
                        end
                    end
                end
                break
            end
        end
    end

    -- Predictive Auto Block: Check killer range and time
    if predictiveBlockOn and tick() > predictiveCooldown then
        local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChild("Humanoid")

        if killersFolder and myHRP and myHum then
            local killerInRange = false

            for _, killer in ipairs(killersFolder:GetChildren()) do
	            if not game.Players:GetPlayerFromCharacter(killer) then
                	continue
            	end
                local hrp = killer:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (myHRP.Position - hrp.Position).Magnitude
                    if dist <= detectionRange then
                        killerInRange = true
                        break
                    end
                end
            end

            -- Handle killer entering range
            if killerInRange then
                if not killerInRangeSince then
                    killerInRangeSince = tick()  -- Start the timer when the killer enters the range
                elseif tick() - killerInRangeSince >= edgeKillerDelay then
                    -- Block if the killer has stayed in range long enough
                    fireRemoteBlock()
                    predictiveCooldown = tick() + 2  -- Set cooldown to avoid blocking too quickly again
                    killerInRangeSince = nil  -- Reset the timer
                end
            else
                killerInRangeSince = nil  -- Reset timer if the killer leaves range
            end
        end
    end



    -- Auto Punch
    if AutoPunchEnabled then
        local gui = PlayerGui:FindFirstChild("MainUI")
        local punchBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Punch")
        local charges = punchBtn and punchBtn:FindFirstChild("Charges")

        if charges and charges.Text == "1" then
            local killerNames = {"c00lkidd", "Jason", "JohnDoe", "1x1x1x1", "Noli"}
            for _, name in ipairs(killerNames) do
                local killer = workspace:FindFirstChild("Players")
                    and workspace.Players:FindFirstChild("Killers")
                    and workspace.Players.Killers:FindFirstChild(name)


                if killer and killer:FindFirstChild("HumanoidRootPart") then
                    local root = killer.HumanoidRootPart
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if root and myRoot and (root.Position - myRoot.Position).Magnitude <= 10 then
						
                        -- Aim Punch: Constant look at killer with prediction
						if aimPunch then
							local humanoid = myChar:FindFirstChild("Humanoid")
							if humanoid then
								humanoid.AutoRotate = false
							end

							task.spawn(function()
								local start = tick()
								while tick() - start < 2 do
									local myRootNow = myChar:FindFirstChild("HumanoidRootPart")
									local targetRoot = root 
										and root.Parent 
										and root.Parent:FindFirstChild("HumanoidRootPart")

									if myRootNow and targetRoot then
										local predictedPos = targetRoot.Position + (targetRoot.CFrame.LookVector * predictionValue)
										local lookDir = predictedPos - myRootNow.Position
										if lookDir.Magnitude > 0.01 then
											myRootNow.CFrame = CFrame.lookAt(
												myRootNow.Position, 
												predictedPos
											)
										end
									end
									task.wait()
								end

								if humanoid and humanoid.Parent then
									humanoid.AutoRotate = true
								end
							end)
						end

                        -- Trigger punch GUI button
                        for _, conn in ipairs(getconnections and getconnections(punchBtn.MouseButton1Click) or {}) do
                            pcall(function()
                                conn:Fire()
                            end)
                        end

                        -- Fling Punch: Constant TP 2 studs in front of killer for 1 second
                        if flingPunchOn then
                            hiddenfling = true
                            local targetHRP = root
                            task.spawn(function()
                                local start = tick()
                                while tick() - start < 1 do
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and targetHRP and targetHRP.Parent then
                                        local frontPos = targetHRP.Position + (targetHRP.CFrame.LookVector * 2)
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(frontPos, targetHRP.Position)
                                    end
                                    task.wait()
                                end
                                hiddenfling = false
                            end)
                        end

                        -- Play custom punch animation if enabled
                        if customPunchEnabled and customPunchAnimId ~= "" then
                            playCustomAnim(customPunchAnimId, true)
                        end

                        break -- Only punch one killer per frame
                    end
                end
            end
        end
    end

end)

end -- scoped performance/UI helpers

-- Cooldown tracking for each replacement type
local lastReplaceTime = {
    block = 0,
    punch = 0,
    charge = 0,
}

-- Continuous custom animation replacer (runs forever if toggled on)
task.spawn(function()
    while sessionEnv.VortexionSessionId == thisSessionId do
        local enabled = customBlockEnabled or customPunchEnabled or customChargeEnabled
        task.wait(enabled and 0.08 or 0.4)
        if not (customBlockEnabled or customPunchEnabled or customChargeEnabled) then continue end

        local char = LocalPlayer.Character
        if not char then continue end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then continue end

        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local animId = tostring(track.Animation.AnimationId):match("%d+")

            -- Block animation replacement
            if customBlockEnabled and customBlockAnimId ~= "" and table.find(blockAnimIds, animId) then
                if tick() - lastReplaceTime.block >= 3 then
                    lastReplaceTime.block = tick()
                    track:Stop()
                    local newAnim = Instance.new("Animation")
                    newAnim.AnimationId = "rbxassetid://" .. customBlockAnimId
                    local newTrack = animator:LoadAnimation(newAnim)
                    if newTrack then newTrack:Play() end
                    break
                end
            end

            -- Punch animation replacement
            if customPunchEnabled and customPunchAnimId ~= "" and table.find(punchAnimIds, animId) then
                if tick() - lastReplaceTime.punch >= 3 then
                    lastReplaceTime.punch = tick()
                    track:Stop()
                    local newAnim = Instance.new("Animation")
                    newAnim.AnimationId = "rbxassetid://" .. customPunchAnimId
                    local newTrack = animator:LoadAnimation(newAnim)
                    if newTrack then newTrack:Play() end
                    break
                end
            end

            -- Charge animation replacement
            if customChargeEnabled and customChargeAnimId ~= "" and table.find(chargeAnimIds, animId) then
                if tick() - lastReplaceTime.charge >= 3 then
                    lastReplaceTime.charge = tick()
                    track:Stop()
                    local newAnim = Instance.new("Animation")
                    newAnim.AnimationId = "rbxassetid://" .. customChargeAnimId
                    local newTrack = animator:LoadAnimation(newAnim)
                    if newTrack then newTrack:Play() end
                    break
                end
            end
        end
    end
end)

do
--// Hitbox ride logic: check at 20Hz when enabled, instead of each frame.
local lastHitboxScan = 0
RunService.Heartbeat:Connect(function()
    if not hitboxmodificationEnabled then return end
    local now = os.clock()
    if now - lastHitboxScan < 0.05 then return end
    lastHitboxScan = now
	if not HumanoidRootPart or not Humanoid then return end

	local playing = false
	for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
		if table.find(AttackAnimations, track.Animation.AnimationId)
			and (track.TimePosition / track.Length < 0.75) then
			playing = true
			break
		end
	end

	if not playing then return end

	local Target
	local NearestDist = MaxRange

	local function scanGroup(group)
		for _, obj in ipairs(group) do
			if obj == Character or not obj:FindFirstChild("HumanoidRootPart") then continue end
			local dist = (obj.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
			if dist < NearestDist then
				NearestDist = dist
				Target = obj
			end
		end
	end

	local playersFolder = workspace:FindFirstChild("Players")
	if playersFolder then scanGroup(playersFolder:GetDescendants()) end
	local npcs = workspace:FindFirstChild("Map", true) and workspace.Map:FindFirstChild("NPCs", true)
	if npcs then
		scanGroup(npcs:GetChildren())
	end

	if not Target then return end

	local ping = LocalPlayer:GetNetworkPing()
	local randomOffset = Vector3.new(RNG:NextNumber(-1.5, 1.5), 0, RNG:NextNumber(-1.5, 1.5))
	local predicted = Target.HumanoidRootPart.Position + randomOffset + (Target.HumanoidRootPart.Velocity * (ping * 1.25))
	local divisor = math.max(ping * 2, 0.05)
	local neededVelocity = (predicted - HumanoidRootPart.Position) / divisor

	local oldVelocity = HumanoidRootPart.Velocity
	HumanoidRootPart.Velocity = neededVelocity
	RunService.RenderStepped:Wait()
	HumanoidRootPart.Velocity = oldVelocity
end)

end -- scoped performance/UI helpers

runEvery(0.14, function()
    if not AntiSlow then return end
    checkAndSetSlowStatus()
    enforceMultipliers()
end)

-- Select the first tab on load
if Window then Window:SelectTab(1) end

-- Notify when loaded
if FluentLoaded then
Fluent:Notify({
    Title = "Forsaken",
    Content = "Vortexion - Forsaken 已加载。",
    Duration = 5
})
end

if FluentLoaded then
Fluent:Notify({
    Title = "手机端提示",
    Content = "使用 WindUI 原生触控入口展开菜单；主题与配置在统一 UI 分组管理。",
    Duration = 7
})
end

local hubLoaded = true

-- Native WindUI OpenButton owns the mobile launcher.
for _, previousName in ipairs({"GoonsakenMobileOverlay", "VortexionForsakenOverlay"}) do
    local previous = PlayerGui:FindFirstChild(previousName)
    if previous then previous:Destroy() end
end

local function SetOptionToggle(id)
    if not Fluent or not Fluent.Options then return end
    local option = Fluent.Options[id]
    if option and option.SetValue then option:SetValue(not option.Value) end
end

if FluentLoaded and Tabs then
    Tabs.Survival:AddButton({
        Title = "前空翻",
        Callback = function() if frontflipObj and frontflipObj.Flip then frontflipObj.Flip() end end
    })
    Tabs.Visual:AddButton({ Title = "ESP 快捷开关", Callback = function() SetOptionToggle("ESPToggle") end })
    Tabs.Survival:AddButton({ Title = "自动解谜快捷开关", Callback = function() SetOptionToggle("autofixgen") end })
    Tabs.Visual:AddButton({ Title = "杀手表情", Callback = KillerEmoteGUI })
    Tabs.Emotes:AddButton({ Title = "刷新装备表情", Callback = KillerEmoteGUI })
    -- Populate without changing the initial game page.
    KillerEmoteGUI()
    Window:SelectTab(1)
end

-- Avoid writes on every Heartbeat; chat config is optional in some clients.
if chatWindow then
    pcall(function() chatWindow.Enabled = true end)
end

---------------------------------------------------------------------------
-- 四个功能组模块装配 (Combat / Visual / Survival / Guest)
-- 借鉴 Forsaken-Script-main / Forsaken-Scripts-main 审计结论的增强实现，
-- 每个组自包含（pcall 隔离），单组失败不影响其余组与主界面。
---------------------------------------------------------------------------
local featureGroupApis = {}
if FluentLoaded and Tabs then
    local groupCtx = {
        Players = Players,
        LocalPlayer = LocalPlayer,
        RunService = RunService,
        Workspace = Workspace,
        UserInputService = UserInputService,
        TextChatService = TextChatService,
        Tabs = Tabs,
        Fluent = Fluent,
        track = track,
        Connections = Connections,
        disconnectAll = disconnectAll,
        runEvery = runEvery,
        sessionEnv = sessionEnv,
        thisSessionId = thisSessionId,
        IsMobile = IsMobile,
    }
    local FEATURE_GROUPS = {
        { key = "VortexionCombat",   name = "战斗组",   factory = ForsakenCombatFactory },
        { key = "VortexionVisual",   name = "视觉组",   factory = ForsakenVisualFactory },
        { key = "VortexionSurvival", name = "生存组",   factory = ForsakenSurvivalFactory },
        { key = "VortexionGuest",    name = "Guest 组", factory = ForsakenGuestFactory },
    }
    for _, group in ipairs(FEATURE_GROUPS) do
        if type(group.factory) == "function" then
            local ok, api = pcall(group.factory, groupCtx)
            if ok and type(api) == "table" then
                sessionEnv[group.key] = api
                featureGroupApis[group.key] = api
            else
                warn("[Forsaken] 功能组加载失败 " .. group.name .. ": " .. tostring(api))
            end
        end
    end
end


local cleaned = false
local function cleanupForsaken()
        if cleaned then return end
        cleaned = true
        for key, api in pairs(featureGroupApis) do
            if type(api.Destroy) == "function" then pcall(api.Destroy) end
            if sessionEnv[key] == api then sessionEnv[key] = nil end
        end
        if sessionEnv.VortexionSessionId == thisSessionId then
            sessionEnv.VortexionSessionId = thisSessionId + 1
        end
        -- Reset enabled callbacks before removing their event connections.
        for _, option in pairs(Fluent and Fluent.Options or {}) do
            if option.Value == true and option.SetValue then
                pcall(function() option:SetValue(false) end)
            end
        end
        for _, conn in pairs(activeConnections) do
            if conn and conn.Disconnect then pcall(function() conn:Disconnect() end) end
        end
        disconnectAll()
        if statsGui then pcall(function() statsGui:Destroy() end) end
        pcall(stopvoidrushcontrol)
        pcall(disableAimbot)
        pcall(function() ESP:SetEnabled(false) end)
end
sessionEnv.VortexionForsakenCleanup = cleanupForsaken
if FluentLoaded and Fluent.OnDestroy then
    Fluent:OnDestroy(function() cleanupForsaken() end)
end

