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
        local inspected = 0
        for _, item in ipairs(pg:GetDescendants()) do
            inspected += 1
            if inspected > 300 then break end
            local name = item.Name:lower()
            if (name:find("generator", 1, true) or name:find("puzzle", 1, true)
                or name:find("wire", 1, true))
                and (item:IsA("ScreenGui") and item.Enabled
                    or item:IsA("GuiObject") and item.Visible) then
                return true
            end
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
        if puzzleIsOpen() then
            state.repairPhase = "puzzle-open"
            state.repairPaused = true
            state.lastAction = "已出现发电机拼图；未适配拼图节点与连线协议，不能谎报自动完成"
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
        state.nextRepair = os.clock() + 0.25
        if state.autoRepair then manageScheduler() end
        notify("发电机", "已重置失败计数，等待下一次修理")
    end})
    local repairStatusParagraph=tabs.generators:AddParagraph({Title="修理诊断", Content="点击查看修理与防御诊断，状态在此显示，不覆盖手机触控"})
    tabs.generators:AddButton({Title="查看修理与防御诊断", Callback=function()
        local detail=("交互尝试=%d 进度变化=%d 弹窗=%d 阶段=%s\n%s\n速度模式=%s 实测WalkSpeed=%.2f\n错误：%s")
            :format(state.repairsSent, state.progressSeen, state.popupsClosed,
                state.repairPhase, state.lastAction, state.speedMode,
                state.speedObserved, state.lastError)
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
    tabs.generators:AddParagraph({Title="修理限制", Content="旧版 RE 仅作兼容尝试并验证 Progress；谜题可能具有不同阶段或 7×7 格。已支持只读端点分析和路径规划，但缺少真实输入协议，不会伪造自动完成。"})
    return {Destroy = shutdown, State = state, EnumerateGenerators = enumerateGenerators}
end
