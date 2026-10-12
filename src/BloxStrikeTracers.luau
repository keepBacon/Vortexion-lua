-- Vortexion BloxStrike: passive per-shot tracer visualization.
-- Observes the local Bullet._performRaycast result without changing aim, hits or remotes.
return function(c)
    local tab = c.Tabs.Weapon
    local enabled = false
    local width = 0.11
    local lifetime = 0.65
    local tint = "青蓝"
    local palette = {
        ["青蓝"] = Color3.fromRGB(65, 205, 255),
        ["红色"] = Color3.fromRGB(255, 83, 99),
        ["金色"] = Color3.fromRGB(255, 214, 85),
        ["紫色"] = Color3.fromRGB(182, 113, 250),
        ["白色"] = Color3.fromRGB(250, 250, 250)
    }
    local original, hooked, bulletClass
    local isInstalled = false
    local retryWorker
    local traceRoot
    local visibleTraces = {}
    local statistics = {Rays = 0, Rendered = 0, Invalid = 0}
    local debris = game:GetService("Debris")
    local MAX_TRACES = 96

    local function clearTraces()
        if traceRoot then traceRoot:Destroy(); traceRoot = nil end
        table.clear(visibleTraces)
    end

    local function getTraceRoot()
        if traceRoot and traceRoot.Parent then return traceRoot end
        traceRoot = Instance.new("Folder")
        traceRoot.Name = "VortexionBloxTracers"
        traceRoot.Parent = c.Workspace
        return traceRoot
    end

    local function extractRay(result)
        if type(result) ~= "table" then return nil end
        local origin = result.Origin
        if typeof(origin) ~= "Vector3" then return nil end
        local destination
        if type(result.Hits) == "table" then
            for _, hit in ipairs(result.Hits) do
                if type(hit) == "table" and typeof(hit.Position) == "Vector3" then
                    destination = hit.Position
                    break
                end
            end
        end
        if not destination then
            local direction = result.Direction
            local distance = result.Distance
            if typeof(direction) ~= "Vector3" or type(distance) ~= "number" then return nil end
            if distance <= 0 or distance ~= distance then return nil end
            if direction.Magnitude < 0.001 then return nil end
            destination = origin + direction.Unit * math.min(distance, 2500)
        end
        local span = destination - origin
        if span.Magnitude < 0.05 or span.Magnitude > 2500 then return nil end
        return origin, destination
    end

    local function drawRay(origin, destination)
        -- A single transparent part contains two attachments and one camera-facing Beam.
        for i = #visibleTraces, 1, -1 do
            if not visibleTraces[i].Parent then
                table.remove(visibleTraces, i)
            end
        end
        if #visibleTraces >= MAX_TRACES then
            local oldest = table.remove(visibleTraces, 1)
            if oldest then oldest:Destroy() end
        end
        local marker = Instance.new("Part")
        marker.Name = "Tracer"
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanTouch = false
        marker.CanQuery = false
        marker.CastShadow = false
        marker.Transparency = 1
        marker.Size = Vector3.new(0.05, 0.05, 0.05)
        marker.CFrame = CFrame.new(origin)
        local startAttachment = Instance.new("Attachment")
        startAttachment.Name = "Start"
        startAttachment.Parent = marker
        local endAttachment = Instance.new("Attachment")
        endAttachment.Name = "End"
        endAttachment.Position = destination - origin
        endAttachment.Parent = marker
        local beam = Instance.new("Beam")
        beam.Attachment0 = startAttachment
        beam.Attachment1 = endAttachment
        beam.FaceCamera = true
        beam.Segments = 2
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Width0 = width
        beam.Width1 = math.max(0.015, width * 0.55)
        beam.Color = ColorSequence.new(palette[tint] or palette["青蓝"])
        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(1, 0.75)
        })
        beam.Parent = marker
        marker.Parent = getTraceRoot()
        table.insert(visibleTraces, marker)
        statistics.Rendered += 1
        debris:AddItem(marker, lifetime)
    end

    local function assignRaycast(target, replacement)
        local succeeded = pcall(function() target._performRaycast = replacement end)
        if succeeded then return true end
        if type(setreadonly) ~= "function" then return false end
        local oldStatus
        if type(isreadonly) == "function" then
            pcall(function() oldStatus = isreadonly(target) end)
        end
        if not pcall(function() setreadonly(target, false) end) then return false end
        succeeded = pcall(function() target._performRaycast = replacement end)
        -- Restore the original read-only state, never force true if unknown.
        if oldStatus ~= nil then
            pcall(function() setreadonly(target, oldStatus) end)
        end
        return succeeded
    end

    local function stopCapture()
        enabled = false
        if isInstalled and bulletClass and bulletClass._performRaycast == hooked then
            if not assignRaycast(bulletClass, original) then
                warn("[Vortexion/Tracers] Bullet method could not be restored")
            end
        end
        isInstalled = false
        original, hooked, bulletClass = nil, nil, nil
    end

    local function getBullet()
        local components = c.ReplicatedStorage:FindFirstChild("Components")
        local weapon = components and components:FindFirstChild("Weapon")
        local classes = weapon and weapon:FindFirstChild("Classes")
        local module = classes and classes:FindFirstChild("Bullet")
        if not (module and module:IsA("ModuleScript")) then
            return nil, "未发现 Bullet 模块"
        end
        local ok, class = pcall(require, module)
        if not ok then return nil, "Bullet 模块加载失败" end
        if type(class) ~= "table" or type(class._performRaycast) ~= "function" then
            return nil, "当前游戏版本没有 _performRaycast"
        end
        return class
    end

    local function startCapture()
        if isInstalled then return true end
        local class, reason = getBullet()
        if not class then return false, reason end
        local previous = class._performRaycast
        local capture = function(self, ...)
            -- Preserve the game's own raycast and returned hit data unchanged.
            local result = previous(self, ...)
            if enabled and c.IsCurrent() then
                statistics.Rays += 1
                local origin, destination = extractRay(result)
                if origin then
                    local ok = pcall(drawRay, origin, destination)
                    if not ok then statistics.Invalid += 1 end
                else
                    statistics.Invalid += 1
                end
            end
            return result
        end
        if not assignRaycast(class, capture) then
            return false, "执行器不支持观察 Bullet 方法"
        end
        bulletClass, original, hooked = class, previous, capture
        isInstalled = true
        return true
    end

    local function activate()
        if retryWorker then return end
        retryWorker = task.spawn(function()
            local lastReason
            while enabled and c.IsCurrent() and not isInstalled do
                local ok, reason = startCapture()
                if ok then break end
                lastReason = reason
                task.wait(2)
            end
            if enabled and not isInstalled and lastReason then
                c.Notify("子弹轨迹尚未生效", lastReason)
            end
            retryWorker = nil
        end)
    end

    tab:AddParagraph({
        Title = "逐发子弹轨迹",
        Content = "从实际 Bullet._performRaycast 的原始结果绘制独立 3D 光束。不改变命中、弹道方向或服务器数据。"
    })
    tab:AddToggle("BloxBulletTracers", {
        Title = "开启真实子弹轨迹", Default = false,
        Callback = function(value)
            if not value then
                stopCapture()
                clearTraces()
            else
                enabled = true
                activate()
            end
        end
    })
    tab:AddDropdown("BloxBulletTraceColor", {
        Title = "轨迹颜色", Values = {"青蓝", "红色", "金色", "紫色", "白色"},
        Default = "青蓝", Callback = function(value) tint = value end
    })
    tab:AddSlider("BloxBulletTraceWidth", {
        Title = "轨迹粗细", Min = 2, Max = 35, Default = 11, Rounding = 0,
        Callback = function(value) width = value / 100 end
    })
    tab:AddSlider("BloxBulletTraceLife", {
        Title = "轨迹保留时间 (ms)", Min = 150, Max = 2000, Default = 650, Rounding = 0,
        Callback = function(value) lifetime = value / 1000 end
    })
    tab:AddButton({Title = "查看子弹轨迹状态", Callback = function()
        local class, reason = getBullet()
        c.Notify("轨迹状态",
            (class and "Bullet 类可用" or tostring(reason)) ..
            " / 捕获=" .. tostring(isInstalled) ..
            " / 子弹=" .. tostring(statistics.Rays) ..
            " / 已绘制=" .. tostring(statistics.Rendered) ..
            " / 无有效轨迹=" .. tostring(statistics.Invalid))
    end})
    tab:AddButton({Title = "清空轨迹", Callback = clearTraces})
    c.OnCleanup(function()
        stopCapture()
        clearTraces()
    end)
end
