-- BloxStrike ballistic module (v3). The hook runs only at the game's Bullet class.
-- The gameplay sample supplies _performRaycast(self, spread) and a hit-result table.
return function(c)
    local tab = c.Tabs.Weapon
    local config = {
        Redirect = false, Tracers = false, Team = true, Wall = false,
        Radius = 550, MaxDistance = 1800, Selection = "准星范围",
        Prediction = 0, TrailWidth = 0.12, TrailLife = 0.7,
        TrailColor = "青蓝", ShowStatus = true
    }
    local colors = {
        ["青蓝"] = Color3.fromRGB(51, 202, 255),
        ["赤红"] = Color3.fromRGB(255, 68, 88),
        ["金黄"] = Color3.fromRGB(255, 215, 80),
        ["紫色"] = Color3.fromRGB(200, 114, 255),
        ["白色"] = Color3.fromRGB(245, 245, 255)
    }
    local stats = {Rays = 0, Redirected = 0, Drawn = 0, NoTarget = 0, Errors = 0}
    local bulletClass, originalRaycast, hookedRaycast, nextRetry = nil,nil,nil,0
    local hooked = false
    local renderFolder
    local trails = {}
    local cachedPart, cachedAt = nil, 0
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    local function ensureFolder()
        if renderFolder and renderFolder.Parent then return renderFolder end
        renderFolder = Instance.new("Folder")
        renderFolder.Name = "VortexionBloxBulletTraces"
        renderFolder.Parent = c.Workspace
        return renderFolder
    end

    local function clearTraces()
        if renderFolder then renderFolder:Destroy(); renderFolder = nil end
        table.clear(trails)
    end

    -- Exactly one Beam represents one raycast call. No ESP lines or RenderStepped updates.
    local function drawTrace(origin, destination)
        if not config.Tracers or not c.IsCurrent() then return end
        if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3" then return end
        local displacement = destination - origin
        local length = displacement.Magnitude
        if length < 0.05 or length > 10000 then return end
        for i = #trails, 1, -1 do
            if not trails[i].Parent then table.remove(trails, i) end
        end
        -- Bound retained visuals even when using automatic weapons.
        if #trails >= 128 then
            local oldest = table.remove(trails, 1)
            if oldest then oldest:Destroy() end
        end
        local anchor = Instance.new("Part")
        anchor.Name = "BulletRay"
        anchor.Size = Vector3.new(0.05, 0.05, 0.05)
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.CastShadow = false
        anchor.Transparency = 1
        anchor.CFrame = CFrame.new(origin)
        local p0 = Instance.new("Attachment")
        p0.Name = "Origin"
        p0.Parent = anchor
        local p1 = Instance.new("Attachment")
        p1.Name = "Impact"
        p1.Position = displacement
        p1.Parent = anchor
        local beam = Instance.new("Beam")
        beam.Name = "Trace"
        beam.Attachment0 = p0
        beam.Attachment1 = p1
        beam.FaceCamera = true
        beam.Segments = 2
        beam.Width0 = config.TrailWidth
        beam.Width1 = math.max(0.02, config.TrailWidth * 0.45)
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Color = ColorSequence.new(colors[config.TrailColor] or colors["青蓝"])
        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.06),
            NumberSequenceKeypoint.new(0.8, 0.12),
            NumberSequenceKeypoint.new(1, 0.9)
        })
        beam.Parent = anchor
        anchor.Parent = ensureFolder()
        table.insert(trails, anchor)
        stats.Drawn += 1
        -- Guaranteed non-yielding cleanup independent of the FPS.
        game:GetService("Debris"):AddItem(anchor, config.TrailLife)
    end

    local function findRayOrigin(result)
        if typeof(result) == "table" and typeof(result.Origin) == "Vector3" then
            return result.Origin
        end
        local camera = c.Workspace.CurrentCamera
        return camera and camera.CFrame.Position or nil
    end

    local function normalEndpoint(result)
        if type(result) ~= "table" then return nil end
        if type(result.Hits) == "table" then
            for _,hit in ipairs(result.Hits) do
                if type(hit) == "table" and typeof(hit.Position) == "Vector3" then
                    return hit.Position
                end
            end
        end
        if typeof(result.Origin) == "Vector3" and typeof(result.Direction) == "Vector3"
                and type(result.Distance) == "number" and result.Distance > 0 then
            return result.Origin + result.Direction * math.min(result.Distance, 3000)
        end
        return nil
    end

    local function hasLineOfSight(origin, head, character)
        if not config.Wall then return true end
        local ignore = {}
        local mine = c.Character(c.LocalPlayer)
        if mine then table.insert(ignore, mine) end
        local camera = c.Workspace.CurrentCamera
        if camera then table.insert(ignore, camera) end
        rayParams.FilterDescendantsInstances = ignore
        local cast = c.Workspace:Raycast(origin, head.Position - origin, rayParams)
        return not cast or cast.Instance:IsDescendantOf(character)
    end

    -- The target is picked only when a bullet raycast occurs, never on RenderStepped.
    local function findHead(origin, maxRange)
        local camera = c.Workspace.CurrentCamera
        if not camera then return nil end
        local center = camera.ViewportSize * 0.5
        local bestScore = math.huge
        local chosen = nil
        local radiusSquared = config.Radius * config.Radius
        for _, player in ipairs(c.Players:GetPlayers()) do
            if c.Enemy(player, config.Team) then
                local character = c.Living(player)
                local head = character and character:FindFirstChild("Head")
                if head and head:IsA("BasePart") and head.Parent then
                    local diff = head.Position - origin
                    local rangeSq = diff:Dot(diff)
                    if rangeSq > 1 and rangeSq <= maxRange * maxRange then
                        local screen, visible = camera:WorldToViewportPoint(head.Position)
                        if visible and screen.Z > 0 then
                            local dx, dy = screen.X-center.X, screen.Y-center.Y
                            local screenDist = dx*dx + dy*dy
                            if (config.Selection ~= "准星范围" or screenDist <= radiusSquared) then
                                local score = config.Selection == "最近敌人" and rangeSq or screenDist
                                if score < bestScore and hasLineOfSight(origin, head, character) then
                                    bestScore, chosen = score, head
                                end
                            end
                        end
                    end
                end
            end
        end
        return chosen
    end

    local function readRange(self)
        local value = config.MaxDistance
        if type(self) == "table" then
            local properties = rawget(self, "Properties")
            local range = type(properties) == "table" and tonumber(properties.Range)
            if range and range > 0 then value = math.min(value, range) end
        end
        return value
    end

    local function copyHeadResult(result, origin, head)
        local aim = head.Position
        -- Prediction is optional and defaults to zero for exact visual head alignment.
        if config.Prediction > 0 then
            aim += head.AssemblyLinearVelocity * config.Prediction
        end
        local travel = aim - origin
        local distance = travel.Magnitude
        if distance <= 0.05 then return nil end
        local candidate = table.clone(result)
        candidate.Origin = origin
        candidate.Direction = travel.Unit
        candidate.Distance = distance
        candidate.Hits = {{
            Instance = head,
            Position = aim,
            Normal = Vector3.zero,
            Material = "Plastic",
            Exit = false
        }}
        return candidate
    end

    local function doRaycast(self, spread, ...)
        -- Always run the native method first, preserving its actual shot origin/range.
        local result = originalRaycast(self, spread, ...)
        if not c.IsCurrent() then return result end
        stats.Rays += 1
        local origin = findRayOrigin(result)
        if config.Redirect and origin and type(result) == "table" then
            local head = findHead(origin, readRange(self))
            if head then
                local replaced = copyHeadResult(result, origin, head)
                if replaced then result = replaced; stats.Redirected += 1 end
            else
                stats.NoTarget += 1
            end
        end
        if config.Tracers and origin then
            local endpoint = normalEndpoint(result)
            if endpoint then
                local ok = pcall(drawTrace, origin, endpoint)
                if not ok then stats.Errors += 1 end
            end
        end
        return result
    end

    local function getBulletClass()
        local components = c.ReplicatedStorage:FindFirstChild("Components")
        local weapon = components and components:FindFirstChild("Weapon")
        local classes = weapon and weapon:FindFirstChild("Classes")
        local module = classes and classes:FindFirstChild("Bullet")
        if not (module and module:IsA("ModuleScript")) then return nil, "Bullet 模块尚未加载" end
        local ok, loaded = pcall(require, module)
        if not ok then return nil, "require Bullet 失败: " .. tostring(loaded) end
        if type(loaded) ~= "table" or type(loaded._performRaycast) ~= "function" then
            return nil, "Bullet._performRaycast 不存在（版本可能变动）"
        end
        return loaded, nil
    end

    local function assignFunction(t, fn)
        local ok = pcall(function() t._performRaycast = fn end)
        if ok then return true end
        if type(setreadonly) ~= "function" then return false end
        local initiallyReadOnly = nil
        if type(isreadonly) == "function" then
            pcall(function() initiallyReadOnly = isreadonly(t) end)
        end
        local unlocked = pcall(function() setreadonly(t, false) end)
        if not unlocked then return false end
        local changed = pcall(function() t._performRaycast = fn end)
        -- Restore previous readonly policy whenever it is discoverable.
        pcall(function() setreadonly(t, initiallyReadOnly == nil and true or initiallyReadOnly) end)
        return changed
    end

    local function uninstall()
        if hooked and bulletClass and bulletClass._performRaycast == hookedRaycast then
            if not assignFunction(bulletClass, originalRaycast) then
                warn("[Vortexion/Ballistics] Unable to restore original Bullet method")
            end
        end
        hooked = false
        bulletClass, originalRaycast, hookedRaycast = nil, nil, nil
    end

    local function install()
        if hooked then return true end
        local klass, err = getBulletClass()
        if not klass then return false, err end
        bulletClass, originalRaycast = klass, klass._performRaycast
        hookedRaycast = doRaycast
        if not assignFunction(klass, hookedRaycast) then
            bulletClass, originalRaycast, hookedRaycast = nil,nil,nil
            return false, "执行器无法修改 Bullet._performRaycast"
        end
        hooked = true
        return true
    end

    local function syncHook()
        if config.Redirect or config.Tracers then
            local success, err = install()
            if not success then
                c.Notify("弹道模块未挂载", err or "未知原因")
                warn("[Vortexion/Ballistics] " .. tostring(err))
            end
        else
            uninstall()
            clearTraces()
        end
    end

    tab:AddParagraph({Title="BloxStrike · 子弹追踪",
        Content="按真实 Bullet._performRaycast 调用识别每发弹道；射击时修正到 Head。仅客户端射线结果，不保证服务器确认爆头。"})
    tab:AddToggle("BloxBulletHeadTrack",{
        Title="暴力爆头弹道追踪", Default=false,
        Callback=function(v) config.Redirect = v; syncHook() end
    })
    tab:AddToggle("BloxBulletTracers",{
        Title="每发子弹独立轨迹", Default=false,
        Callback=function(v) config.Tracers = v; syncHook() end
    })
    tab:AddDropdown("BloxBulletMode",{
        Title="目标锁定模式", Values={"准星范围","最近敌人"},
        Default="准星范围", Callback=function(v) config.Selection=v end
    })
    tab:AddSlider("BloxBulletRadius",{
        Title="准星检索半径 (px)", Min=50, Max=2000, Default=550,
        Rounding=0, Callback=function(v) config.Radius=v end
    })
    tab:AddSlider("BloxBulletRange",{
        Title="最大目标射程 (studs)", Min=100, Max=3000, Default=1800,
        Rounding=0, Callback=function(v) config.MaxDistance=v end
    })
    tab:AddToggle("BloxBulletTeam",{
        Title="过滤队友", Default=true, Callback=function(v) config.Team=v end
    })
    tab:AddToggle("BloxBulletWall",{
        Title="必须可见（不穿墙）", Default=false, Callback=function(v) config.Wall=v end
    })
    tab:AddSlider("BloxBulletLead",{
        Title="移动预判 (ms)", Min=0, Max=300, Default=0, Rounding=0,
        Callback=function(v) config.Prediction=v/1000 end
    })
    tab:AddDropdown("BloxBulletTraceColor",{
        Title="弹道轨迹颜色", Values={"青蓝","赤红","金黄","紫色","白色"},
        Default="青蓝", Callback=function(v) config.TrailColor=v end
    })
    tab:AddSlider("BloxBulletTraceWidth",{
        Title="轨迹粗细", Min=2, Max=45, Default=12, Rounding=0,
        Callback=function(v) config.TrailWidth=v/100 end
    })
    tab:AddSlider("BloxBulletTraceLife",{
        Title="轨迹持续时间 (ms)", Min=150, Max=2500, Default=700, Rounding=0,
        Callback=function(v) config.TrailLife=v/1000 end
    })
    tab:AddButton({Title="检测弹道模块及实际触发次数", Callback=function()
        local klass, err = getBulletClass()
        c.Notify("弹道诊断",
            (klass and "Bullet 类可用" or tostring(err)) ..
            " / Hook=" .. tostring(hooked) ..
            " / 原始射线=" .. tostring(stats.Rays) ..
            " / 本地修正=" .. tostring(stats.Redirected) ..
            " / 绘制=" .. tostring(stats.Drawn) ..
            " / 无目标=" .. tostring(stats.NoTarget))
    end})
    tab:AddButton({Title="清除全部弹道轨迹",Callback=clearTraces})
    c.OnCleanup(function()
        config.Redirect=false; config.Tracers=false
        uninstall()
        clearTraces()
    end)
end
