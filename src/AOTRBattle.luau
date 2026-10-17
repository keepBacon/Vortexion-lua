-- AOTR battle: full combat suite (nape lock, remote registration, spears,
-- hitbox, follow, ESP, farm) wired through one budgeted render loop.
local AOTRTitansFactory = nil
local AOTRCombatFactory = nil
local AOTRMovementFactory = nil
local AOTRESPFactory = nil
local AOTRFarmFactory = nil
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

--=========================================================================
-- Shared render loop: one BindToRenderStep(Last), dt gate, per-subsystem
-- budget, 2s debug snapshot. Movement runs on Heartbeat inside its module.
--=========================================================================
local budgets={Titans=0.4,Combat=1.5,ESP=1.0,Farm=0.2}
local costs={Titans=0,Combat=0,ESP=0,Farm=0}
local slowLoops=0
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
        if Titans then
            local t0=tick()
            app.Guard("Titans",function() Titans:Update(dt) end)
            costs.Titans=tick()-t0
        end
        if Combat then
            local t0=tick()
            app.Guard("Combat",function() Combat:Update(dt) end)
            costs.Combat=tick()-t0
        end
        if ESP then
            local t0=tick()
            app.Guard("ESP",function() ESP:Update(dt) end)
            costs.ESP=tick()-t0
        end
        if Farm then
            local t0=tick()
            app.Guard("Farm",function() Farm:Update(dt) end)
            costs.Farm=tick()-t0
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
    tab:AddSlider("AOTRAimHitChance",{Title="注册命中率（%）",Min=10,Max=100,Default=85,Rounding=0,
        Callback=function(v) c.HitChance=v/100 end})
    tab:AddDropdown("AOTRAimKey",{Title="触发键",Values={"Always","Hold"},Default="Always",
        Callback=function(v) c.TriggerKey=v end})
    tab:AddSlider("AOTRAttackCd",{Title="攻击间隔（秒）",Min=0.08,Max=1.5,Default=0.25,Rounding=2,
        Callback=function(v) c.AttackCooldown=v end})
    tab:AddSlider("AOTRAttackJitter",{Title="节奏抖动（±）",Min=0,Max=0.8,Default=0.4,Rounding=2,
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
tabs.settings:AddButton({Title="运行状态",Callback=function()
    local Titans,Combat,Farm=app.Titans,app.Combat,app.Farm
    local remotes=app.Remotes
    local titanInfo=Titans and ("巨人 "..tostring(Titans:Count())) or "巨人池未加载"
    local combatInfo=Combat and ("锁定 "..tostring(Combat:DebugSnapshot().locked)) or "战斗未加载"
    app:Notify(("GET=%s POST=%s / %s / %s"):format(
        tostring(remotes.GET~=nil),tostring(remotes.POST~=nil),titanInfo,combatInfo))
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
