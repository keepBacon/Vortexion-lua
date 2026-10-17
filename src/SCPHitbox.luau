-- R232: SCP: Roleplay client-side hitbox adapter.
-- Independent of the crosshair candidate pool (which has a 56-target cap).
-- IMPORTANT: changing BasePart.Size on the client cannot enlarge the server's
-- authoritative hit registration. This adapter verifies LOCAL part writes and
-- optionally shows the enlarged local bounds; it does not claim server hits.
return function(common)
    local Players = common.Services.Players
    local Workspace = common.Services.Workspace
    local LocalPlayer = common.LocalPlayer or Players.LocalPlayer

    local Hitbox = {}
    local Config = {
        Enabled = false,
        Mode = "all", -- all / fullBody / lockedOnly
        ScaleMax = 1.8,
        HeadScale = 1,
        TorsoScale = 1,
        MaxDistance = 500,
        FOV = 600,
        UseFOV = false, -- mobile default: do not silently exclude side targets
        MaxActive = 8,
        TickRate = 12,
        GrowAlpha = 0.65,
        ShrinkAlpha = 0.7,
        PendingMs = 180,
        Transparency = 0.55,
        AnisoXZ = 1.0,
        AnisoY = 1.0,
        MaxEdge = 18,
        MaxRatio = 4,
        OnlyHostile = false,
        TargetNPCs = true,
        ShowBounds = true,
        BoundsColor = Color3.fromRGB(0, 195, 210),
        BoundsTransparency = 0.5,
    }
    Hitbox.Config = Config
    Hitbox.Stats = {
        Eligible = 0, Expanded = 0, PartsChanged = 0, Verified = 0,
        Preview = 0, Rejected = 0, ExternalResets = 0, LastError = "", Reason = "未开启",
        ServerVerified = false,
    }
    local states = {} -- key = Model; preserves original sizes across re-spawns
    local accumulator = 0
    local conns = {}

    local function isPart(inst)
        return inst and inst:IsA("BasePart") and inst.Parent ~= nil
    end
    local function findPart(model, names)
        for _,name in ipairs(names) do
            local part = model:FindFirstChild(name)
            if not part then part = model:FindFirstChild(name, true) end
            if isPart(part) then return part end
        end
        return nil
    end
    local function anchorFor(model)
        local anchor = findPart(model, {"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head"})
            or (isPart(model.PrimaryPart) and model.PrimaryPart or nil)
        if anchor then return anchor end
        -- Some SCP entities are custom Models without a PrimaryPart. Limit
        -- the fallback to direct children; never traverse the whole map.
        for _,child in ipairs(model:GetChildren()) do
            if isPart(child) then return child end
        end
        local nested = model:FindFirstChildWhichIsA("BasePart", true)
        return isPart(nested) and nested or nil
    end
    local function isAlive(model)
        if not model or not model.Parent then return false end
        if model:GetAttribute("Dead") == true then return false end
        local hp = model:GetAttribute("Health")
        if type(hp) == "number" and hp <= 0 then return false end
        local humanoid = model:FindFirstChildWhichIsA("Humanoid")
        return not humanoid or humanoid.Health > 0
    end
    local function targetsFor(model)
        local selected = {}
        local seen = {}
        local function add(part)
            if isPart(part) and not seen[part] then
                seen[part] = true
                selected[#selected + 1] = part
            end
        end
        for _,name in ipairs({"Head", "UpperTorso", "LowerTorso", "Torso"}) do
            add(findPart(model, {name}))
        end
        if Config.Mode == "fullBody" then
            for _,name in ipairs({
                "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
                "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
                "Left Arm", "Right Arm", "Left Leg", "Right Leg"
            }) do add(findPart(model, {name})) end
        end
        -- SCP custom entity models can lack Humanoid and standard torso names.
        -- Prefer their PrimaryPart as a bounded fallback, without touching
        -- HumanoidRootPart for standard player rigs (avoids physics instability).
        if #selected == 0 then add(anchorFor(model)) end
        return selected
    end
    local function multiplier(name, distance)
        local region = name == "Head" and Config.HeadScale
            or ((name == "Torso" or name == "UpperTorso" or name == "LowerTorso") and Config.TorsoScale or 1)
        local peak = math.max(1, Config.ScaleMax * region)
        local decay = math.clamp(1 - distance / math.max(1, Config.MaxDistance), 0, 1)
        return 1 + (peak - 1) * decay
    end
    local function expandedSize(original, part, distance)
        local factor = multiplier(part.Name, distance)
        local bounds = Vector3.new(
            original.X * factor * Config.AnisoXZ,
            original.Y * factor * Config.AnisoY,
            original.Z * factor * Config.AnisoXZ
        )
        return Vector3.new(
            math.max(original.X, math.min(bounds.X, original.X * Config.MaxRatio, Config.MaxEdge)),
            math.max(original.Y, math.min(bounds.Y, original.Y * Config.MaxRatio, Config.MaxEdge)),
            math.max(original.Z, math.min(bounds.Z, original.Z * Config.MaxRatio, Config.MaxEdge))
        )
    end
    local function removePreview(original)
        if original.preview then
            pcall(function() original.preview:Destroy() end)
            original.preview = nil
        end
    end
    local function restore(model)
        local state = states[model]
        if not state then return end
        for part,original in pairs(state.parts) do
            removePreview(original)
            if part.Parent then
                pcall(function()
                    part.Size = original.size
                    part.Transparency = original.transparency
                    part.CanCollide = original.canCollide
                end)
            end
        end
        states[model] = nil
    end
    local function createPreview(part, original)
        if original.preview or not Config.ShowBounds then return end
        local ok, adorn = pcall(function()
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "VortexionSCPHitboxBounds"
            box.Adornee = part
            box.AlwaysOnTop = true
            box.Color3 = Config.BoundsColor
            box.Transparency = Config.BoundsTransparency
            box.Size = part.Size
            box.Parent = part
            return box
        end)
        if ok then original.preview = adorn
        else Hitbox.Stats.LastError = "碰撞箱预览创建失败: " .. tostring(adorn) end
    end
    local function apply(model, parts, distance)
        local state = states[model]
        if not state then
            state = {parts = {}, lastSeen = os.clock()}
            states[model] = state
        end
        state.lastSeen = os.clock()
        local verified = 0
        for _,part in ipairs(parts) do
            local original = state.parts[part]
            if not original then
                original = {size = part.Size, transparency = part.Transparency, canCollide = part.CanCollide}
                state.parts[part] = original
            end
            local desired = expandedSize(original.size, part, distance)
            if original.lastApplied and (part.Size - original.size).Magnitude < 0.02
                and (original.lastApplied - original.size).Magnitude > 0.1 then
                Hitbox.Stats.ExternalResets += 1
            end
            local ok, err = pcall(function()
                part.Size = part.Size:Lerp(desired, Config.GrowAlpha)
                part.CanCollide = false
                part.Transparency = original.transparency + (Config.Transparency - original.transparency) * 0.35
            end)
            if ok then
                Hitbox.Stats.PartsChanged += 1
                original.lastApplied = part.Size
                if (part.Size - original.size).Magnitude > 0.025 then
                    verified += 1
                end
                if Config.ShowBounds then createPreview(part, original) else removePreview(original) end
                if original.preview then
                    pcall(function()
                        original.preview.Size = part.Size
                        original.preview.Color3 = Config.BoundsColor
                        original.preview.Transparency = Config.BoundsTransparency
                        original.preview.Visible = Config.ShowBounds
                    end)
                    Hitbox.Stats.Preview += 1
                end
            else
                Hitbox.Stats.LastError = "部件写入失败: " .. tostring(err)
                Hitbox.Stats.Rejected += 1
            end
        end
        return verified
    end
    local function addModel(list, model, owner, camera, origin, locked)
        if not isAlive(model) then return end
        if owner and owner.Character ~= model then return end
        if Config.OnlyHostile and common.Candidates and common.Candidates.IsHostile then
            if not common.Candidates:IsHostile({Player = owner, Character = model}) then return end
        end
        if Config.Mode == "lockedOnly" and (not locked or locked.Character ~= model) then return end
        local anchor = anchorFor(model)
        if not anchor then return end
        local distance = (anchor.Position - origin).Magnitude
        if distance > Config.MaxDistance then return end
        local screen, onScreen = camera:WorldToViewportPoint(anchor.Position)
        if not onScreen and screen.Z <= 0 then return end
        local center = camera.ViewportSize * 0.5
        if Config.UseFOV and (Vector2.new(screen.X, screen.Y) - center).Magnitude > Config.FOV then return end
        local parts = targetsFor(model)
        if #parts == 0 then return end
        list[#list + 1] = { model = model, parts = parts, distance = distance }
    end
    local function gather()
        local camera = Workspace.CurrentCamera
        if not camera then return {}, "摄像机未就绪" end
        local localChar = LocalPlayer and LocalPlayer.Character
        local localRoot = localChar and anchorFor(localChar)
        local origin = localRoot and localRoot.Position or camera.CFrame.Position
        local locked = common.Camera and common.Camera.GetCurrentTarget and common.Camera:GetCurrentTarget()
        local eligible = {}
        for _,player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                addModel(eligible, player.Character, player, camera, origin, locked)
            end
        end
        if Config.TargetNPCs and common.Candidates and common.Candidates.NPCs then
            for model in pairs(common.Candidates.NPCs) do
                if model ~= localChar and model.Parent and not Players:GetPlayerFromCharacter(model) then
                    addModel(eligible, model, nil, camera, origin, locked)
                end
            end
        end
        table.sort(eligible, function(a,b) return a.distance < b.distance end)
        return eligible, #eligible == 0 and "没有符合距离/FOV/阵营的目标" or "正常"
    end
    function Hitbox:GetEnvelope(part)
        for _,state in pairs(states) do
            local original = state.parts[part]
            if original then return original.size end
        end
        return part.Size
    end
    function Hitbox:GetEnvelopeMargin(part)
        return self:GetEnvelope(part) * 0.5 + Vector3.new(0.5, 0.5, 0.5)
    end
    function Hitbox:Cleanup()
        local keys = {}
        for model in pairs(states) do keys[#keys + 1] = model end
        for _,model in ipairs(keys) do restore(model) end
        Hitbox.Stats.Expanded, Hitbox.Stats.Preview = 0, 0
    end
    function Hitbox:Update(dt)
        if not Config.Enabled then
            self:Cleanup()
            accumulator = 0
            Hitbox.Stats.Reason = "未开启"
            return
        end
        accumulator += (dt or 0)
        local interval = 1 / math.clamp(Config.TickRate, 1, 60)
        if accumulator < interval then return end
        accumulator %= interval
        local eligible, reason = gather()
        Hitbox.Stats.Eligible = #eligible
        Hitbox.Stats.Reason = reason
        Hitbox.Stats.PartsChanged, Hitbox.Stats.Verified = 0, 0
        Hitbox.Stats.Preview, Hitbox.Stats.Rejected = 0, 0
        local active = {}
        local count = 0
        for _,item in ipairs(eligible) do
            if count >= Config.MaxActive then break end
            count += 1
            active[item.model] = true
            Hitbox.Stats.Verified += apply(item.model, item.parts, item.distance)
        end
        Hitbox.Stats.Expanded = count
        local expired = {}
        for model,state in pairs(states) do
            if not active[model] and (not model.Parent or (os.clock() - state.lastSeen) * 1000 > Config.PendingMs) then
                expired[#expired + 1] = model
            end
        end
        for _,model in ipairs(expired) do restore(model) end
        if count > 0 and Hitbox.Stats.Verified == 0 then
            Hitbox.Stats.Reason = "已选中目标，但本地尺寸未变化（被还原或尺寸受限）"
        end
    end
    conns[#conns+1] = Players.PlayerRemoving:Connect(function(player)
        if player.Character then restore(player.Character) end
    end)
    conns[#conns+1] = Workspace.DescendantRemoving:Connect(function(inst)
        if states[inst] then restore(inst) end
    end)
    common.OnCleanup(function()
        Hitbox:Cleanup()
        for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
    end)
    return Hitbox
end
