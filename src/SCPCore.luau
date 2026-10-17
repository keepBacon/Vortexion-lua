-- Vortexion - SCP v3: game-specific entry, unified WindUI UI.
-- Reference-informed feature coverage: modular subsystems, one
-- budgeted render loop, capability probing and version adaptation instead of
-- the original single mixed RenderStepped/Heartbeat loop.
-- Do not copy source implementations: use lifecycle-managed services in separate modules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local SCPCommonFactory = nil
local SCPCandidatesFactory = nil
local SCPCloakFactory = nil
local SCPCameraFactory = nil
local SCPSilentAimFactory = nil
local SCPHitboxFactory = nil
local SCPMovementFactory = nil
local SCPESPFactory = nil
local SCPInteractFactory = nil
local WindBridgeFactory = nil
local WindUI = nil

--=========================================================================
-- Lifecycle: one live generation. A re-execute of the loader bumps the
-- generation and tears the previous instance down instead of stacking loops.
--=========================================================================
local global = (getgenv and getgenv()) or _G
if type(global.VortexionSCPCleanup) == "function" then
    pcall(global.VortexionSCPCleanup)
end
global.VortexionSCPGeneration = (global.VortexionSCPGeneration or 0) + 1
local generation = global.VortexionSCPGeneration
local connections = {}
local cleanups = {}
local function isCurrent()
    return global.VortexionSCPGeneration == generation
end
local function ownConnection(conn)
    if conn then table.insert(connections, conn) end
    return conn
end
local function ownCleanup(fn)
    table.insert(cleanups, fn)
end
local function cleanup()
    if global.VortexionSCPGeneration == generation then
        global.VortexionSCPGeneration += 1
    end
    for i = #connections, 1, -1 do
        pcall(function() connections[i]:Disconnect() end)
        connections[i] = nil
    end
    for i = #cleanups, 1, -1 do
        pcall(cleanups[i])
        cleanups[i] = nil
    end
end
global.VortexionSCPCleanup = cleanup

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
-- UI: WindUI bridge (vendored, zero network). The original script loaded
-- Rayfield over HttpGet, which is both a dependency risk and a client-side
-- trace; the vendored UI keeps the whole hub self-contained.
--=========================================================================
local ok, ui = pcall(function() return WindBridgeFactory(WindUI) end)
if not ok or not ui then
    global.VortexionBootError = "SCP Bridge: " .. tostring(ui)
    warn("[Vortexion/SCP] WindUI initialization failed: " .. tostring(ui))
    return
end
-- R224: a UI constructor or Page registration may fail on an unsupported
-- Android executor. Fail closed with a readable bootstrap reason rather than
-- allowing the entire SCP entrypoint to abort halfway through initialization.
local windowOK, windowResult = pcall(function()
    return ui:CreateWindow({ Title = "Vortexion | SCP", Size = UDim2.fromOffset(790, 590) })
end)
if not windowOK or type(windowResult) ~= "table" or type(windowResult.AddTab) ~= "function" then
    local detail = windowOK and "invalid UI window" or tostring(windowResult)
    global.VortexionBootError = "SCP UI Window: " .. detail
    warn("[Vortexion/SCP] UI window unavailable: " .. detail)
    pcall(function() ui:Destroy() end)
    cleanup()
    return
end
local window = windowResult
ui:OnDestroy(cleanup)
local tabsOK, tabsResult = pcall(function()
    return {
        Aim = window:AddTab({ Title = "自瞄", Icon = "lucide-crosshair" }),
        Silent = window:AddTab({ Title = "静默", Icon = "lucide-target" }),
        Hitbox = window:AddTab({ Title = "碰撞箱", Icon = "lucide-box" }),
        Visual = window:AddTab({ Title = "视觉", Icon = "lucide-eye" }),
        Move = window:AddTab({ Title = "移动", Icon = "lucide-activity" }),
        World = window:AddTab({ Title = "世界", Icon = "lucide-globe" }),
        Info = window:AddTab({ Title = "信息", Icon = "lucide-info" }),
    }
end)
if not tabsOK or type(tabsResult) ~= "table" then
    local detail = tabsOK and "invalid page registry" or tostring(tabsResult)
    global.VortexionBootError = "SCP UI Pages: " .. detail
    warn("[Vortexion/SCP] UI pages unavailable: " .. detail)
    pcall(function() ui:Destroy() end)
    cleanup()
    return
end
local tabs = tabsResult

--=========================================================================
-- common singleton: every subsystem reads capabilities and shared state from
-- this table; nothing module-private leaks into the global environment.
--=========================================================================
local common = {
    Services = {
        Players = Players,
        RunService = RunService,
        Workspace = Workspace,
        HttpService = HttpService,
        TeleportService = TeleportService,
        VirtualUser = VirtualUser,
        Lighting = Lighting,
        Input = UserInputService,
    },
    LocalPlayer = LocalPlayer,
    UI = ui,
    Window = window,
    Tabs = tabs,
    IsCurrent = isCurrent,
    Own = ownConnection,
    OnCleanup = ownCleanup,
    Debug = false,
    PlaceId = game.PlaceId,
    GameVersion = "scp-v3",
}

local bootFailures = {}
local function reportBootFailure(component, message)
    local detail = tostring(component) .. ": " .. tostring(message):sub(1, 160)
    table.insert(bootFailures, detail)
    ui.BootStatus, ui.BootError = "partial", table.concat(bootFailures, "; ")
    warn("[Vortexion/SCP] " .. detail)
end
local function setup(name, factory)
    if type(factory) ~= "function" then
        reportBootFailure(name, "factory missing")
        return nil
    end
    local passed, result = pcall(factory, common)
    if not passed then
        reportBootFailure(name, result)
        return nil
    end
    return result
end

-- Order matters: capabilities first, then the shared candidate pool, then
-- consumers (cloak protects instances the aim/visual layers create).
setup("common", SCPCommonFactory)
common.Log = common.Log or function() end
common.Guard = common.Guard or function(_, fn, ...) local ok, err = pcall(fn, ...) if not ok then warn(tostring(err)) end return ok end
common.Cloak = setup("cloak", SCPCloakFactory) or { Protect = function(object) return object end, Stop = function() end, Start = function() end }
-- R224: never install global __namecall interception during SCP bootstrap.
-- Previous code hooked the entire game BEFORE UI/render setup; on some
-- executors this is a process-level crash, not a catchable Luau exception.
-- Runtime hooking is optional and is not a prerequisite for ESP/UI startup.
common.CloakStatus = "disabled by default (safe bootstrap)"
common.Candidates = setup("candidates", SCPCandidatesFactory) or { Update = function() end, Get = function() return {} end, NPCs = nil }
common.Camera = setup("camera", SCPCameraFactory) or { Update = function() end, GetCurrentTarget = function() end, Config = { Enabled = false } }
common.SilentAim = setup("silentaim", SCPSilentAimFactory) or { Update = function() end, Config = { Enabled = false } }
common.Hitbox = setup("hitbox", SCPHitboxFactory) or { Update = function() end, Config = { Enabled = false } }
common.Movement = setup("movement", SCPMovementFactory) or { Update = function() end, Start = function() end, Config = { SpeedEnabled = false } }
common.ESP = setup("esp", SCPESPFactory) or { Update = function() end, Config = { Enabled = false } }
common.Interact = (type(SCPInteractFactory)=="function" and setup("interact", SCPInteractFactory)) or {SetEnabled=function()end,Stats={Visible=0}}

local Camera = common.Camera
local SilentAim = common.SilentAim
local Hitbox = common.Hitbox
local Movement = common.Movement
local ESP = common.ESP
local Interact = common.Interact
local Candidates = common.Candidates
if type(ui.RegisterFeatureHealth) == "function" then
    ui:RegisterFeatureHealth("SCP", function()
        local frame = Candidates and Candidates.Frame or 0
        return ("存活=%s 角色=%s 候选扫描=%s 模块失败=%d")
            :format(tostring(isCurrent()), tostring(LocalPlayer.Character ~= nil),
                tostring(frame), #bootFailures)
    end)
end


--=========================================================================
-- NPC scan: SCP roleplay populates the map with humanoid NPCs; without the
-- scanner they are invisible to every targeting feature.
--=========================================================================
task.defer(function()
    if isCurrent() then
        common.Guard("Candidates", function()
            if Candidates.StartNPCScan then Candidates:StartNPCScan() end
        end)
    end
end)

--=========================================================================
-- Movement runs on Heartbeat (physics step), not the render step: velocity
-- writes land before the physics solver reads them.
--=========================================================================
common.Guard("Movement", function() Movement:Start() end)
ownConnection(RunService.Heartbeat:Connect(function(dt)
    if not isCurrent() then return end
    common.Guard("Movement", function() Movement:Update(dt) end)
end))

--=========================================================================
-- World features preserved from the original script, re-hosted on the shared
-- loop with low-frequency timers instead of per-frame work.
--=========================================================================
local world = {
    Fullbright = false,
    AntiRagdoll = false,
    AntiAFK = true,
    DeleteDoors = false,
}
local origLighting = nil
local function captureLighting()
    origLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
end

local function applyFullbright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 12
    Lighting.FogEnd = 1e10
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
end

local function restoreLighting()
    if not origLighting then return end
    Lighting.Brightness = origLighting.Brightness
    Lighting.ClockTime = origLighting.ClockTime
    Lighting.FogEnd = origLighting.FogEnd
    Lighting.Ambient = origLighting.Ambient
    Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
    origLighting = nil
end
ownCleanup(restoreLighting)

local afkHeld = false
ownCleanup(function()
    if afkHeld then pcall(function() VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end) afkHeld = false end
end)
ownConnection(LocalPlayer.Idled:Connect(function()
    if not isCurrent() or not world.AntiAFK or afkHeld then return end
    pcall(function()
        afkHeld = true
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
        task.wait(1)
        if afkHeld then
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
            afkHeld = false
        end
    end)
end))

--=========================================================================
-- Triggerbot: fires while the aimbot holds a lock. Uses executor mouse
-- functions when present, VirtualUser otherwise.
--=========================================================================
local trigger = {
    Enabled = false,
    Mode = "Locked",        -- Locked | Always
    IntervalMs = 180,
    lastFire = 0,
    firing = false,
}
local function mouseDown()
    if type(mouse1press) == "function" then
        mouse1press()
    else
        pcall(function() VirtualUser:Button1Down(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end)
    end
end
local function mouseUp()
    if type(mouse1release) == "function" then
        mouse1release()
    else
        pcall(function() VirtualUser:Button1Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()) end)
    end
end
local function updateTrigger()
    if not trigger.Enabled then
        if trigger.firing then mouseUp() trigger.firing = false end
        return
    end
    local locked = Camera.GetCurrentTarget and Camera:GetCurrentTarget()
    local shouldFire = (trigger.Mode == "Always") or (locked ~= nil)
    local now = tick() * 1000
    if shouldFire and now - trigger.lastFire >= trigger.IntervalMs then
        trigger.lastFire = now
        if not trigger.firing then
            mouseDown()
            trigger.firing = true
            task.delay(0.08, function()
                if trigger.firing then
                    mouseUp()
                    trigger.firing = false
                end
            end)
        end
    elseif not shouldFire and trigger.firing then
        mouseUp()
        trigger.firing = false
    end
end

--=========================================================================
-- Single render loop: one BindToRenderStep(Last) drives every visual-side
-- subsystem. Per-subsystem costs and over-budget streaks are reported in
-- the debug snapshot; Guard isolates errors and throttles warnings.
--
-- Candidate/ESP/hitbox accumulators handle cadence independently of render FPS.
--=========================================================================
local budgets = { Aim = 1.2, Hitbox = 0.6, ESP = 1.0 }
local costs = { Aim = 0, Hitbox = 0, ESP = 0, Candidates = 0 }
local slowLoops = { Aim = 0, Hitbox = 0, ESP = 0 }
local lastSnapshot = 0
local lowFreqTimer = 0

local renderName = "VortexionSCPFrame"
local function renderFrame(dt)
    if not isCurrent() then return end
    common.Guard("Frame", function()
        -- Low-frequency world features (0.5 s cadence).
        lowFreqTimer += dt
        if lowFreqTimer >= 0.5 then
            lowFreqTimer = 0
            if world.Fullbright then applyFullbright() end
            if world.AntiRagdoll and LocalPlayer.Character then
                local rag = LocalPlayer.Character:FindFirstChild("Ragdoll")
                if rag then pcall(function() rag:Destroy() end) end
            end
        end


        -- R226: keep idle frame cost near zero. Each disabled module's toggle
        -- synchronously calls its own reset/restore entrypoint.
        local needCandidates = (Camera.Config and Camera.Config.Enabled)
            or (SilentAim.Config and SilentAim.Config.Enabled)
            or (Hitbox.Config and Hitbox.Config.Enabled)
            or (ESP.Config and ESP.Config.Enabled)
        local t0=tick()
        if needCandidates then common.Guard("Candidates", function() Candidates:Update(dt) end) end
        costs.Candidates=needCandidates and (tick()-t0)*1000 or 0
        t0=tick()
        if Camera.Config and Camera.Config.Enabled then
            common.Guard("Camera", function() Camera:Update(dt) end)
        end
        costs.Aim=(Camera.Config and Camera.Config.Enabled) and (tick()-t0)*1000 or 0
        if SilentAim.Config and SilentAim.Config.Enabled then
            common.Guard("SilentAim", function() SilentAim:Update() end)
        end
        t0=tick()
        if Hitbox.Config and Hitbox.Config.Enabled then
            common.Guard("Hitbox", function() Hitbox:Update(dt) end)
        end
        costs.Hitbox=(Hitbox.Config and Hitbox.Config.Enabled) and (tick()-t0)*1000 or 0
        t0=tick()
        if ESP.Config and ESP.Config.Enabled then
            common.Guard("ESP", function() ESP:Update(dt) end)
        end
        costs.ESP=(ESP.Config and ESP.Config.Enabled) and (tick()-t0)*1000 or 0
        if trigger.Enabled or trigger.firing then common.Guard("Trigger", updateTrigger) end

        -- Budget watchdog: count consecutive over-budget frames per
        -- subsystem; the snapshot surfaces them for tuning.
        for name, cost in pairs(costs) do
            local budget = budgets[name]
            if budget and cost > budget then
                slowLoops[name] = (slowLoops[name] or 0) + 1
            elseif slowLoops[name] then
                slowLoops[name] = 0
            end
        end

        -- Debug snapshot: 2 s cadence, one line per subsystem.
        if common.Debug and tick() - lastSnapshot >= 2 then
            lastSnapshot = tick()
            local locked = Camera.GetCurrentTarget and Camera:GetCurrentTarget()
            common.Log("Frame", ("cand=%.2fms aim=%.2fms hitbox=%.2fms esp=%.2fms slow(a/h/e)=%d/%d/%d lock=%s")
                :format(costs.Candidates, costs.Aim, costs.Hitbox, costs.ESP,
                    slowLoops.Aim or 0, slowLoops.Hitbox or 0, slowLoops.ESP or 0,
                    locked and tostring(locked.Player and locked.Player.Name or "NPC") or "-"))
        end
    end)
end
local renderOk,renderErr=pcall(function()
    RunService:BindToRenderStep(renderName, Enum.RenderPriority.Last.Value, renderFrame)
end)
if not renderOk then
    reportBootFailure("render", renderErr)
    ownConnection(RunService.RenderStepped:Connect(renderFrame))
else
    ownCleanup(function() pcall(function() RunService:UnbindFromRenderStep(renderName) end) end)
end
ownCleanup(function() if trigger.firing then mouseUp() trigger.firing = false end end)

--=========================================================================
-- UI wiring.
--=========================================================================
tabs.Aim:AddToggle("SCPAimEnabled", { Title = "自瞄总开关", Default = false, Callback = function(v) Camera.Config.Enabled = v if not v then Camera:Update(0) end end })
tabs.Aim:AddDropdown("SCPAimMode", { Title = "模式", Values = { "Camera", "Mouse", "Both" }, Default = "Camera", Callback = function(v) Camera.Config.Mode = v end })
tabs.Aim:AddSlider("SCPAimFov", { Title = "FOV (px)", Min = 20, Max = 650, Default = 240, Rounding = 0, Callback = function(v) Camera.Config.FOV = v end })
tabs.Aim:AddSlider("SCPAimDist", { Title = "最大距离 (studs)", Min = 50, Max = 2000, Default = 700, Rounding = 0, Callback = function(v) Camera.Config.MaxDistance = v end })
tabs.Aim:AddSlider("SCPAimSmooth", { Title = "平滑度", Min = 50, Max = 99, Default = 85, Rounding = 0, Callback = function(v) Camera.Config.Smoothness = v / 100 end })
tabs.Aim:AddDropdown("SCPAimPart", { Title = "部位", Values = { "Head", "Torso", "Arms", "Legs", "Random" }, Default = "Head", Callback = function(v) Camera.Config.Hitbox = v end })
tabs.Aim:AddSlider("SCPAimAngle", { Title = "最大夹角 (度)", Min = 5, Max = 90, Default = 30, Rounding = 0, Callback = function(v) Camera.Config.MaxAngle = v end })
tabs.Aim:AddSlider("SCPAimPrediction", { Title = "预瞄", Min = 0, Max = 50, Default = 12, Rounding = 0, Callback = function(v) Camera.Config.Prediction = v / 100 end })
tabs.Aim:AddSlider("SCPAimHitChance", { Title = "锁定命中率", Min = 10, Max = 100, Default = 100, Rounding = 0, Callback = function(v) Camera.Config.HitChance = v / 100 end })
tabs.Aim:AddToggle("SCPAimWall", { Title = "遮挡检查", Default = true, Callback = function(v) Camera.Config.WallCheck = v end })
tabs.Aim:AddToggle("SCPAimTeam", { Title = "只锁定敌对阵营", Default = true, Callback = function(v) Camera.Config.TeamCheck = v end })
tabs.Aim:AddToggle("SCPAimNPC", { Title = "锁定 NPC", Default = true, Callback = function(v) Camera.Config.TargetNPCs = v end })
tabs.Aim:AddDropdown("SCPAimKey", { Title = "触发键", Values = { "Right", "Left", "None", "Touch", "Always" }, Default = Camera.Config.TriggerKey or "Always", Callback = function(v) Camera.Config.TriggerKey = v if Camera.ResetTrigger then Camera:ResetTrigger() end end })
tabs.Aim:AddToggle("SCPAimFovCircle", { Title = "FOV 圈", Default = true, Callback = function(v) Camera.Config.FOVCircle = v end })
tabs.Aim:AddToggle("SCPTrigger", { Title = "自动开火（锁定时）", Default = false, Callback = function(v) trigger.Enabled = v if not v then updateTrigger() end end })

tabs.Silent:AddToggle("SCPSilentEnabled", { Title = "静默瞄准总开关", Default = false, Callback = function(v) SilentAim.Config.Enabled = v end })
tabs.Silent:AddSlider("SCPSilentAngle", { Title = "最大夹角 (度)", Min = 5, Max = 60, Default = 15, Rounding = 0, Callback = function(v) SilentAim.Config.MaxAngle = v end })
tabs.Silent:AddSlider("SCPSilentChance", { Title = "命中率", Min = 10, Max = 100, Default = 72, Rounding = 0, Callback = function(v) SilentAim.Config.HitChance = v / 100 end })
tabs.Silent:AddToggle("SCPSilentWall", { Title = "遮挡检查", Default = true, Callback = function(v) SilentAim.Config.WallCheck = v end })
tabs.Silent:AddToggle("SCPSilentTeam", { Title = "队伍过滤", Default = false, Callback = function(v) SilentAim.Config.TeamCheck = v end })
tabs.Silent:AddParagraph({ Title = "静默瞄准说明", Content = "改写客户端发往服务端的命中参数；参数按单位方向/世界坐标两种形态标定，命中点限制在服务端可判定的原始包络内。" })

tabs.Hitbox:AddToggle("SCPHitboxEnabled", { Title = "碰撞箱扩展", Default = false, Callback = function(v) Hitbox.Config.Enabled = v if not v then Hitbox:Update(0) end end })
tabs.Hitbox:AddDropdown("SCPHitboxMode", { Title = "模式", Values = { "all", "fullBody", "lockedOnly" }, Default = "all", Callback = function(v) Hitbox.Config.Mode = v end })
tabs.Hitbox:AddSlider("SCPHitboxScale", { Title = "峰值倍率", Min = 10, Max = 30, Default = 18, Rounding = 0, Callback = function(v) Hitbox.Config.ScaleMax = v / 10 end })
tabs.Hitbox:AddSlider("SCPHitboxDist", { Title = "作用距离 (studs)", Min = 50, Max = 1000, Default = 500, Rounding = 0, Callback = function(v) Hitbox.Config.MaxDistance = v end })
tabs.Hitbox:AddSlider("SCPHitboxFov", { Title = "屏幕门 (px)", Min = 50, Max = 1000, Default = 600, Rounding = 0, Callback = function(v) Hitbox.Config.FOV = v end })
tabs.Hitbox:AddSlider("SCPHitboxActive", { Title = "同帧目标数", Min = 1, Max = 16, Default = 8, Rounding = 0, Callback = function(v) Hitbox.Config.MaxActive = v end })
tabs.Hitbox:AddToggle("SCPHitboxHostile", {Title="只处理敌对阵营",Default=false,Callback=function(v)Hitbox.Config.OnlyHostile=v end})
tabs.Hitbox:AddToggle("SCPHitboxNPC", {Title="包含SCP收容体",Default=true,Callback=function(v)Hitbox.Config.TargetNPCs=v end})
tabs.Hitbox:AddParagraph({ Title = "碰撞箱说明", Content = "20Hz 节流、尺寸平滑与距离衰减；关闭或角色替换时恢复尺寸、透明度和碰撞属性。" })

-- R226 five essential ESP diagnostics: faction, names, hitbox style, role, SCP classification/color.
tabs.Visual:AddToggle("SCPESPEnabled", {Title="ESP 总开关",Default=false,Callback=function(v)ESP.Config.Enabled=v if not v then ESP:Update(0) end end})
tabs.Visual:AddToggle("SCPESPHostile", {Title="仅显示敌对阵营",Default=false,Callback=function(v)ESP.Config.OnlyHostile=v end})
tabs.Visual:AddToggle("SCPESPNames", {Title="显示名称",Default=true,Callback=function(v)ESP.Config.ShowNames=v end})
tabs.Visual:AddDropdown("SCPESPNameFormat", {Title="名称类型",Values={"用户名","实体名"},Default="用户名",Callback=function(v)ESP.Config.NameFormat=v end})
tabs.Visual:AddDropdown("SCPESPStyle", {Title="ESP 样式（碰撞箱）",Values={"3D","2D"},Default="3D",Callback=function(v)ESP.Config.Style=v end})
tabs.Visual:AddToggle("SCPESPJob", {Title="显示职位 / 军衔",Default=false,Callback=function(v)ESP.Config.ShowJob=v end})
tabs.Visual:AddToggle("SCPESPNPC", {Title="显示 SCP收容体",Default=true,Callback=function(v)ESP.Config.TargetNPCs=v end})
tabs.Visual:AddColorpicker("SCPESPColorSCP", {Title="SCP收容体颜色（默认黑）",Default=ESP.Config.ColorSCP,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorSCP=v end end})
tabs.Visual:AddColorpicker("SCPESPColorEnemy", {Title="敌对阵营颜色",Default=ESP.Config.ColorEnemy,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorEnemy=v end end})
tabs.Visual:AddColorpicker("SCPESPColorAlly", {Title="其他阵营颜色",Default=ESP.Config.ColorAlly,Callback=function(v)if typeof(v)=="Color3" then ESP.Config.ColorAlly=v end end})
tabs.Visual:AddSlider("SCPESPDist", {Title="显示距离",Min=100,Max=2000,Default=850,Rounding=0,Callback=function(v)ESP.Config.MaxDistance=v end})
tabs.Visual:AddSlider("SCPESPFPS", {Title="刷新率（Hz）",Min=8,Max=30,Default=20,Rounding=0,Callback=function(v)ESP.Config.TickRate=v end})
-- R228: ESP appearance controls preserve existing IDs and add separate label/color settings.
tabs.Visual:AddSlider("SCPESPAlpha3D", {Title="3D 盒子透明度 (%)",Min=0,Max=100,Default=30,Rounding=0,Callback=function(v)ESP.Config.Transparency3D=v/100 end})
tabs.Visual:AddSlider("SCPESPAlpha2D", {Title="2D 方框透明度 (%)",Min=0,Max=100,Default=15,Rounding=0,Callback=function(v)ESP.Config.Transparency2D=v/100 end})
tabs.Visual:AddToggle("SCPESPJobColor", {Title="职位跟随游戏队伍颜色",Default=true,Callback=function(v)ESP.Config.JobTeamColor=v end})
tabs.Visual:AddToggle("SCPESPJobZH", {Title="职位中文翻译",Default=true,Callback=function(v)ESP.Config.JobTranslate=v end})
tabs.Visual:AddSlider("SCPESPNameFont", {Title="名称文字大小",Min=10,Max=26,Default=14,Rounding=0,Callback=function(v)ESP.Config.NameSize=v end})
tabs.Visual:AddSlider("SCPESPJobFont", {Title="职位文字大小",Min=10,Max=26,Default=13,Rounding=0,Callback=function(v)ESP.Config.JobSize=v end})
tabs.Visual:AddSlider("SCPESPBoxWidth", {Title="2D 方框线宽",Min=1,Max=4,Default=2,Rounding=0,Callback=function(v)ESP.Config.BoxThickness=v end})
tabs.Visual:AddSlider("SCPESPLabelOffset", {Title="文字显示高度",Min=0,Max=60,Default=24,Rounding=0,Callback=function(v)ESP.Config.LabelOffset=v/10 end})
tabs.Visual:AddToggle("SCPESPDistance", {Title="显示目标距离",Default=false,Callback=function(v)ESP.Config.ShowDistance=v end})
tabs.Visual:AddToggle("SCPESPHealth", {Title="显示目标生命值",Default=false,Callback=function(v)ESP.Config.ShowHealth=v end})
tabs.Visual:AddSlider("SCPESPMaxTargets", {Title="ESP 最大目标数",Min=8,Max=64,Default=36,Rounding=0,Callback=function(v)ESP.Config.MaxEntries=v end})
tabs.Visual:AddParagraph({Title="性能与模式",Content="3D原生渲染自动跟随碰撞部件；2D按刷新率投影实际头/躯干碰撞框，默认不依赖Drawing；关闭后清理全部对象。"})

tabs.Move:AddToggle("SCPSpeed", { Title = "加速", Default = false, Callback = function(v) Movement.Config.SpeedEnabled = v end })
tabs.Move:AddSlider("SCPSpeedVal", { Title = "速度值", Min = 16, Max = 150, Default = 16, Rounding = 0, Callback = function(v) Movement.Config.SpeedValue = v end })
tabs.Move:AddToggle("SCPFly", { Title = "飞行", Default = false, Callback = function(v) Movement.Config.FlyEnabled = v end })
tabs.Move:AddToggle("SCPTouchFly", { Title = "触屏拖动飞行", Default = true, Callback = function(v) Movement.Config.TouchFly = v end })
tabs.Move:AddSlider("SCPFlySpeed", { Title = "飞行速度", Min = 10, Max = 300, Default = 60, Rounding = 0, Callback = function(v) Movement.Config.FlySpeed = v end })
tabs.Move:AddToggle("SCPNoclip", { Title = "穿墙", Default = false, Callback = function(v) if Movement.SetNoclip then Movement:SetNoclip(v) else Movement.Config.Noclip = v end end })
tabs.Move:AddToggle("SCPJump", { Title = "超级跳", Default = false, Callback = function(v) Movement.Config.JumpEnabled = v end })
tabs.Move:AddSlider("SCPJumpVal", { Title = "跳跃力", Min = 20, Max = 250, Default = 50, Rounding = 0, Callback = function(v) Movement.Config.JumpValue = v end })

tabs.World:AddToggle("SCPInstantInteract", {Title="秒交互（ProximityPrompt）",Default=false,Callback=function(v)Interact:SetEnabled(v) end})
tabs.World:AddParagraph({Title="秒交互说明",Content="仅对当前显示的交互提示清零按住时间；不增加交互距离、不越过权限或服务端验证。"})
tabs.World:AddToggle("SCPFullbright", { Title = "全亮", Default = false, Callback = function(v)
    if v and not world.Fullbright then captureLighting() end
    world.Fullbright = v
    if v then applyFullbright() else restoreLighting() end
end })
tabs.World:AddToggle("SCPAntiRagdoll", { Title = "反布娃娃", Default = false, Callback = function(v) world.AntiRagdoll = v end })
tabs.World:AddToggle("SCPAntiAFK", { Title = "反挂机", Default = true, Callback = function(v) world.AntiAFK = v end })
tabs.World:AddButton({ Title = "删除门", Callback = function()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if string.lower(obj.Name):find("door") then
            pcall(function() obj:Destroy() end)
        end
    end
end })
tabs.World:AddButton({ Title = "重新加入", Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end })
tabs.World:AddButton({ Title = "低延迟切服（通用）", Callback = function()
    if not ui.ServerSwitch then return end
    local ok, reason = ui.ServerSwitch:Switch()
    if not ok then ui:Notify({Title = "低延迟切服", Content = reason, Duration = 4}) end
end })

tabs.Info:AddButton({Title="ESP / 自瞄 / 碰撞箱诊断",Callback=function()
    local es=ESP.Stats or {} local cs=Camera.Stats or {} local hs=Hitbox.Stats or {}
    local text=("ESP %s: %d/%d, %.2fms; 自瞄: %s (%s); 碰撞箱: %d/%d; 秒交互: %d")
        :format(tostring(es.Mode or "3D"),es.Visible or 0,es.Seen or 0,es.AverageMs or 0,
          tostring(cs.Reason or "未知"),tostring(cs.Locked or "-"),hs.Expanded or 0,hs.Eligible or 0,
          Interact.Stats and Interact.Stats.Modified or 0)
    pcall(function()ui:Notify({Title="SCP R226 运行诊断",Content=text,Duration=8})end)
end})
tabs.Info:AddToggle("SCPDebug", { Title = "调试输出", Default = false, Callback = function(v) common.Debug = v end })
tabs.Info:AddParagraph({ Title = "兼容性说明",
    Content = ("PlaceId %d / 构建 scp-v3。R15 与 R6 角色自适应；Drawing 缺失时线条停用、Chams 可独立工作；元表钩子缺失时静默瞄准自动停用；候选与绘制刷新率独立于帧率；触屏默认右侧按住。")
        :format(game.PlaceId) })
tabs.Info:AddToggle("SCPAdvancedCloak", {Title="高级隐藏 Hook（兼容性风险，默认关闭）",Default=false,Callback=function(v)
    if type(common.Cloak.Start)~="function" then return end
    if v then
        common.CloakStatus="user enabled"
        common.Guard("Cloak",function() common.Cloak.Start() end)
    else
        common.CloakStatus="user disabled"
        common.Guard("Cloak",function() common.Cloak.Stop() end)
    end
end})
tabs.Info:AddButton({ Title = "子模块初始化诊断", Callback = function()
    pcall(function() ui:Notify({Title = "SCP 启动诊断",
        Content = #bootFailures > 0 and table.concat(bootFailures, " / ") or "模块工厂未报告失败；功能运行仍需实际测试", Duration = 6}) end)
end })
tabs.Info:AddButton({ Title = "检查运行状态", Callback = function()
    local caps = common.Caps or {}
    pcall(function()
        ui:Notify({ Title = "Vortexion SCP", Content = ("Drawing=%s 钩子=%s 鼠标=%s gethui=%s 目标=%d")
            :format(tostring(caps.Drawing or caps.DrawingUserdata), tostring(caps.hookmetamethod or caps.getrawmetatable),
                tostring(caps.mousemoverel), tostring(caps.gethui), #(Candidates:Get() or {})), Duration = 5 })
    end)
end })
tabs.Info:AddButton({ Title = "卸载全部 SCP 功能", Callback = function()
    cleanup()
    pcall(function() ui:Destroy() end)
end })
tabs.Info:AddButton({ Title = "一键恢复普通视角", Callback = function()
    if not isCurrent() then return end
    Camera.Config.Enabled = false
    pcall(function() Camera:ResetTrigger() end)
    pcall(function() Camera:Update(0) end)
    local aimOption = ui and ui.Options and ui.Options.SCPAimEnabled
    if aimOption and type(aimOption.SetValue) == "function" then pcall(function() aimOption:SetValue(false) end) end
    if not isCurrent() then return end
    local ready, cam, hum = pcall(function()
        local char = LocalPlayer and LocalPlayer.Character
        return Workspace.CurrentCamera, char and char:FindFirstChildWhichIsA("Humanoid")
    end)
    if not ready or not cam or not hum then
        pcall(function() ui:Notify({ Title = "Vortexion SCP", Content = "已关闭视角辅助；角色或相机尚未就绪", Duration = 4 }) end)
        return
    end
    local restored = pcall(function()
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    end)
    if not isCurrent() then return end
    pcall(function() ui:Notify({ Title = "Vortexion SCP", Content = restored and "已恢复普通视角" or "视角属性更新未完成", Duration = 4 }) end)
end })

tabs.Aim:AddDropdown("SCPTouchMode", { Title = "触屏触发方式", Values = { "Hold", "Toggle" }, Default = "Hold", Callback = function(v) Camera.Config.TouchMode = v if Camera.ResetTrigger then Camera:ResetTrigger() end end })
tabs.Aim:AddDropdown("SCPTouchRegion", { Title = "触屏区域（避开摇杆）", Values = { "Right", "Full" }, Default = "Right", Callback = function(v) common.Touch.Region = v end })
tabs.Aim:AddSlider("SCPAimAttraction", { Title = "鼠标吸附力度", Min = 10, Max = 100, Default = 60, Rounding = 0, Callback = function(v) Camera.Config.Attraction = v / 100 end })
tabs.Aim:AddToggle("SCPAimDampening", { Title = "近准星减速", Default = true, Callback = function(v) Camera.Config.Dampening = v end })
tabs.Aim:AddSlider("SCPTriggerInterval", { Title = "开火间隔 (ms)", Min = 100, Max = 1000, Default = 180, Rounding = 0, Callback = function(v) trigger.IntervalMs = v end })
tabs.Hitbox:AddSlider("SCPHitboxHeadScale", { Title = "头部独立倍率", Min = 10, Max = 30, Default = 10, Rounding = 0, Callback = function(v) Hitbox.Config.HeadScale = v / 10 end })
tabs.Hitbox:AddSlider("SCPHitboxTorsoScale", { Title = "躯干独立倍率", Min = 10, Max = 25, Default = 10, Rounding = 0, Callback = function(v) Hitbox.Config.TorsoScale = v / 10 end })
tabs.Visual:AddToggle("SCPESPLabels", { Title = "名字 / 距离", Default = false, Callback = function(v) ESP.Config.Labels = v end })
tabs.Visual:AddDropdown("SCPTracerOrigin", { Title = "射线起点", Values = { "Bottom", "Center" }, Default = "Bottom", Callback = function(v) ESP.Config.TracerOrigin = v end })
tabs.Visual:AddSlider("SCPESPRefresh", { Title = "绘制刷新率 (Hz)", Min = 5, Max = 60, Default = 20, Rounding = 0, Callback = function(v) ESP.Config.TickRate = v end })
tabs.Visual:AddSlider("SCPESPBudget", { Title = "显示目标上限", Min = 8, Max = 96, Default = 64, Rounding = 0, Callback = function(v) ESP.Config.MaxEntries = v end })
tabs.Move:AddSlider("SCPTouchDeadzone", { Title = "触屏拖动死区 (px)", Min = 5, Max = 50, Default = 10, Rounding = 0, Callback = function(v) Movement.Config.TouchDeadzone = v end })
tabs.Move:AddSlider("SCPTouchSensitivity", { Title = "满速拖动距离 (px)", Min = 40, Max = 240, Default = 120, Rounding = 0, Callback = function(v) Movement.Config.TouchSensitivity = v end })
tabs.Info:AddSlider("SCPCandidateRefresh", { Title = "候选刷新率 (Hz)", Min = 5, Max = 60, Default = 20, Rounding = 0, Callback = function(v) if Candidates.Config then Candidates.Config.TickRate = v end end })
tabs.Visual:AddToggle("SCPESPOffScreen", { Title = "屏外方向箭头", Default = false, Callback = function(v) ESP.Config.OffScreen = v if not v then ESP:Update(0) end end })
tabs.Visual:AddToggle("SCPESPOffScreenDistance", { Title = "屏外距离数字（需Drawing）", Default = false, Callback = function(v) ESP.Config.OffScreenDistance = v if not v then ESP:Update(0) end end })
tabs.Visual:AddSlider("SCPESPOffScreenBudget", { Title = "屏外目标独立上限", Min = 1, Max = 64, Default = 16, Rounding = 0, Callback = function(v) ESP.Config.MaxOffScreen = v end })
tabs.Visual:AddSlider("SCPESPOffScreenSize", { Title = "屏外箭头尺寸(px)", Min = 8, Max = 30, Default = 14, Rounding = 0, Callback = function(v)
    if not isCurrent() then return end
    local n = tonumber(v)
    if not n or n ~= n or math.abs(n) == math.huge then n = 14 end
    ESP.Config.OffScreenSize = math.floor(math.clamp(n, 8, 30) + 0.5)
end })
tabs.Visual:AddSlider("SCPESPOffScreenMargin", { Title = "屏外箭头边距(px)", Min = 8, Max = 80, Default = 28, Rounding = 0, Callback = function(v)
    if not isCurrent() then return end
    local n = tonumber(v)
    if not n or n ~= n or math.abs(n) == math.huge then n = 28 end
    ESP.Config.OffScreenMargin = math.floor(math.clamp(n, 8, 80) + 0.5)
end })
tabs.Visual:AddToggle("SCPESPNativeLabels", { Title = "原生标签（无 Drawing 可用）", Default = false, Callback = function(v) ESP.Config.NativeLabels = v if not v then ESP:Update(0) end end })
tabs.Visual:AddSlider("SCPESPLabelTextSize", { Title = "标签字号", Min = 10, Max = 28, Default = 14, Rounding = 0, Callback = function(v) ESP.Config.LabelTextSize = v end })
tabs.Visual:AddDropdown("SCPESPLabelFont", { Title = "原生标签字体", Values = { "GothamBold", "Gotham", "SourceSans", "Code" }, Default = "GothamBold", Callback = function(v) ESP.Config.LabelFont = v end })
tabs.Visual:AddToggle("SCPESPLabelStroke", { Title = "标签文字描边", Default = true, Callback = function(v) ESP.Config.LabelStroke = v end })
tabs.Visual:AddSlider("SCPESPLabelBackground", { Title = "原生标签背景透明度", Min = 0, Max = 100, Default = 100, Rounding = 0, Callback = function(v) ESP.Config.LabelBackgroundTransparency = v / 100 end })
tabs.Move:AddButton({ Title = "立即起跳", Callback = function() Movement:RequestJump(true) end })
tabs.Move:AddSlider("SCPTeleportDist", { Title = "前向传送距离 (studs)", Min = 10, Max = 200, Default = 50, Rounding = 0, Callback = function(v) Movement.Config.TeleportDistance = v end })
tabs.Move:AddButton({ Title = "向前传送", Callback = function() Movement:TeleportForward() end })

window:SelectTab(1)
pcall(function()
    ui:Notify({ Title = "Vortexion - SCP", Content = "模块已加载；进入场景后启用对应功能", Duration = 4 })
end)
common.Log("Core", "loaded place=" .. tostring(game.PlaceId) .. " gen=" .. tostring(generation))
