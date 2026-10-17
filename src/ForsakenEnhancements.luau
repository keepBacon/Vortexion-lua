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
    local state = {
        alive = true, stamina = false, antiSlow = false, antiTaph = false,
        autoPopup = false, moveMultiplier = 1, autoRepair = false,
        repairDelay = 4, approach = false,
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
    local links = {}
    local heartbeat
    local elapsed = 0
    local lastTarget, lastProgress, stagnant = nil, nil, 0
    local awaitingProgress = false
    local lastClick = setmetatable({}, {__mode = "k"})
    local savedPosition

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
    local function applyWalk()
        if state.moveMultiplier <= 1.001 then return end
        local _, hum = character()
        if not hum or hum.Health <= 0 then return end
        local rec = walkSnapshot[hum]
        local current = hum.WalkSpeed
        if not rec then
            rec = {base=current, applied=current}
            walkSnapshot[hum] = rec
        elseif math.abs(current - rec.applied) > 0.15 then
            -- The game changed its base speed; do not compound multipliers.
            rec.base = current
        end
        rec.applied = math.clamp(rec.base * state.moveMultiplier, 0, 200)
        if math.abs(current - rec.applied) >= 0.05 then hum.WalkSpeed = rec.applied end
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
        -- Mouse synthesis is optional on Android. Visibility fallback is always local.
        local okVim, vim = pcall(function() return game:GetService("VirtualInputManager") end)
        if not okVim then vim = nil end
        if vim then
            local target = popup
            for _, child in ipairs(popup:GetDescendants()) do
                if child:IsA("GuiButton") and child.Visible then
                    target = child
                    if child.Name:lower():find("close") or child.Name:lower() == "x" then break end
                end
            end
            safe("popup click", function()
                local pos, size = target.AbsolutePosition, target.AbsoluteSize
                local x, y = pos.X + size.X / 2, pos.Y + size.Y / 2
                vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
                vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end)
        end
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
    local function generatorContainer()
        local map = Workspace:FindFirstChild("Map")
        local ingame = map and map:FindFirstChild("Ingame")
        return (ingame and ingame:FindFirstChild("Map"))
            or (ingame and ingame:FindFirstChild("Generators"))
            or (map and map:FindFirstChild("Generators"))
    end
    local function nearestGenerator()
        local _, hum, root = character()
        local folder = generatorContainer()
        if not root or not hum or hum.Health <= 0 or not folder then return nil end
        local selected, closest, position
        for _, gen in ipairs(folder:GetChildren()) do
            if gen.Name == "Generator" and gen:IsA("Model") then
                local progress = gen:FindFirstChild("Progress")
                local main = gen:FindFirstChild("Main")
                local part = main and (main:IsA("BasePart") and main or main:FindFirstChildWhichIsA("BasePart"))
                part = part or gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                if progress and (progress:IsA("IntValue") or progress:IsA("NumberValue"))
                    and progress.Value < 100 and part then
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
    local function repairOnce()
        if not state.autoRepair then return end
        local gen, distance, part, root = nearestGenerator()
        if not gen then state.lastAction = "未找到未完成发电机/角色未就绪"; return end
        local progress = gen:FindFirstChild("Progress")
        if gen ~= lastTarget then
            lastTarget, lastProgress, stagnant = gen, progress.Value, 0
            awaitingProgress = false
        end
        if distance > 16 then
            if not state.approach then
                state.lastAction = ("发电机距离 %.0f，需靠近或启用自动前往"):format(distance)
                return
            end
            if not savedPosition then savedPosition = {root=root, cf=root.CFrame} end
            safe("approach generator", function()
                local pos = part.Position - part.CFrame.LookVector * 5 + Vector3.new(0, 2, 0)
                root.CFrame = CFrame.new(pos, part.Position)
            end)
            state.lastAction = "已尝试接近发电机，等待下一轮确认距离"
            return
        end
        local remotes = gen:FindFirstChild("Remotes")
        local re = remotes and remotes:FindFirstChild("RE")
        if not re or not re:IsA("RemoteEvent") then
            state.lastAction = "找不到已知的 Generator.Remotes.RE"
            return
        end
        -- Count stagnation only after real requests, never while traveling.
        if awaitingProgress then
            if progress.Value > (lastProgress or -1) then
                state.progressSeen += 1
                stagnant = 0
            else
                stagnant += 1
            end
            if stagnant >= 4 then
                state.repairPaused = true
                state.lastAction = "进度连续未变化，已暂停自动修理（关闭再开启可重试）"
                notify("发电机已暂停", "连续多次请求后没有进度变化，请检查地图或服务器接口")
                restorePosition()
                return
            end
        end
        lastProgress = progress.Value
        local main = gen:FindFirstChild("Main")
        local prompt = main and (main:IsA("ProximityPrompt") and main or main:FindFirstChildWhichIsA("ProximityPrompt", true))
        if prompt and type(fireproximityprompt) == "function" then
            safe("generator prompt", function() fireproximityprompt(prompt) end)
        end
        local ok = safe("generator RE", function() re:FireServer() end)
        if ok then
            awaitingProgress = true
            state.repairsSent += 1
            state.lastAction = "已发送一次修理请求；等待服务器确认进度"
        end
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
        stopScheduler()
        for _, link in ipairs(links) do safe("disconnect", function() link:Disconnect() end) end
        table.clear(links)
        restoreStamina()
        restoreValues(slowSnapshot)
        restoreWalk()
        restoreHidden()
        restorePosition()
    end
    table.insert(links, player.CharacterAdded:Connect(function()
        restoreWalk()
        restoreValues(slowSnapshot)
        staminaInstance, staminaModule = nil, nil
        lastTarget, lastProgress, stagnant = nil, nil, 0
        awaitingProgress = false
        savedPosition = nil
        state.nextRepair = os.clock() + state.repairDelay
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
            if mult <= 1.001 then restoreWalk() end
            state.moveMultiplier = mult
            manageScheduler()
        end})
    tabs.defense:AddToggle("FsAntiTaphR28", {Title="反塔夫亚空间炸弹（本地视觉效果）", Default=false,
        Callback=function(v) switch("antiTaph", v) end})
    tabs.defense:AddToggle("FsPopupR28", {Title="自动关闭 1x1x1x1 弹窗", Default=false,
        Callback=function(v) switch("autoPopup", v) end})
    tabs.defense:AddParagraph({Title="防御范围", Content="塔夫处理本地 Subspaced 视觉效果；不声称免疫服务器 Helpless 状态。弹窗先尝试触控，失败时只隐藏本地界面。"})
    tabs.generators:AddToggle("FsAutoRepairR28", {Title="自动修发电机", Default=false,
        Callback=function(v) switch("autoRepair", v) end})
    tabs.generators:AddSlider("FsRepairDelayR28", {Title="修发电机延迟（秒）", Min=2.5, Max=10,
        Default=4, Rounding=1, Callback=function(v)
            state.repairDelay = math.clamp(tonumber(v) or 4, 2.5, 10)
        end})
    tabs.generators:AddToggle("FsAutoApproachR28", {Title="自动前往发电机（可选）", Default=false,
        Callback=function(v) state.approach = not not v end})
    tabs.generators:AddButton({Title="重新尝试发电机修理", Callback=function()
        stagnant = 0
        lastTarget, lastProgress = nil, nil
        awaitingProgress = false
        state.repairPaused = false
        state.nextRepair = os.clock() + 0.25
        if state.autoRepair then manageScheduler() end
        notify("发电机", "已重置失败计数，等待下一次修理")
    end})
    tabs.generators:AddButton({Title="查看修理与防御诊断", Callback=function()
        notify("Forsaken R2.8", ("请求=%d 进度变化=%d 弹窗=%d\n%s\n错误：%s")
            :format(state.repairsSent, state.progressSeen, state.popupsClosed,
                state.lastAction, state.lastError))
    end})
    tabs.generators:AddParagraph({Title="修理限制", Content="按已知 Generator.Remotes.RE 请求修理，最短间隔 2.5 秒；服务器拒绝时不会虚报完成。缺少游戏接口会暂停或提示。自动前往默认关闭。"})
    return {Destroy = shutdown, State = state}
end
