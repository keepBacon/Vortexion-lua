-- Vortexion Neverlose - generated offline; publishing must be performed separately.
-- Neverlose attribution is retained in vendor/Neverlose/README.md.
-- Forsaken retains runtime model rbxassetid://132866968194043.
-- Modify src/*.luau and run python3 build.py; do not edit this output.
return function(kernel)
assert(type(kernel) == 'table' and type(kernel.WindBridgeFactory) == 'function', 'Invalid Vortexion core')
local WindUI, WindBridgeFactory, GameRouter = kernel.WindUI, kernel.WindBridgeFactory, kernel.GameRouter
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
end
