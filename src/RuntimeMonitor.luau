-- Vortexion / shared mobile runtime diagnostics (opt-in, no idle frame listener).
-- One owner per Wind bridge; subscriptions and HUD are removed on teardown.
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

    local function makeGui()
        if screenGui or not active then return end
        local parent = nil
        pcall(function() parent = localPlayer:FindFirstChildOfClass("PlayerGui") end)
        if not parent then return end
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionPerformanceHUD"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = false
        gui.DisplayOrder = 100
        local frame = Instance.new("Frame")
        frame.Name = "Telemetry"
        frame.AnchorPoint = Vector2.new(1, 0)
        frame.Position = UDim2.new(1, -12, 0, 48)
        frame.Size = UDim2.fromOffset(206, 92)
        frame.BackgroundColor3 = Color3.fromRGB(24, 27, 32)
        frame.BackgroundTransparency = 0.12
        frame.BorderSizePixel = 0
        frame.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        local content = Instance.new("TextLabel")
        content.Name = "Metrics"
        content.Size = UDim2.new(1, -16, 1, -10)
        content.Position = UDim2.fromOffset(8, 5)
        content.BackgroundTransparency = 1
        content.TextColor3 = Color3.fromRGB(228, 232, 238)
        content.Font = Enum.Font.Code
        content.TextSize = 12
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Center
        content.Text = "FPS -- · Frame --\nStutters -- · Ping --\nMemory -- · Sampling"
        content.Parent = frame
        local ok = pcall(function() gui.Parent = parent end)
        if not ok or not gui.Parent then gui:Destroy(); return end
        screenGui, label = gui, content
    end

    local function snapshot()
        return {
            fps = fps,
            minFps = samples > 0 and minimum or 0,
            maxFps = maximum,
            avgFrameMs = lastAverageFrameMs,
            peakFrameMs = peakFrameMs,
            stutters = stutterCount,
            pingMs = lastPing,
            memoryMb = lastMemory,
            samples = samples,
            uptimeSeconds = math.floor(os.clock() - startedAt),
            gameId = game.GameId,
            placeId = game.PlaceId,
        }
    end

    local function update(dt)
        if not active or not running then return end
        -- O(1) accumulation; expensive service reads occur only on the sampling cadence.
        local delta = tonumber(dt)
        if not delta or delta ~= delta or delta < 0 or delta == math.huge then return end
        -- Track actual frame gaps before capping the FPS integration delta.
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
        if label and label.Parent then
            label.Text = ("FPS %d (Min %d)\nFrame %.1fms / Peak %.0fms\nStutters %d · Ping %s ms\nMemory %s MB"):format(
                fps, minimum, lastAverageFrameMs, peakFrameMs, stutterCount,
                lastPing and tostring(math.floor(lastPing + 0.5)) or "--",
                lastMemory and tostring(math.floor(lastMemory + 0.5)) or "--")
        end
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
        if label and label.Parent then
            label.Text = "FPS -- · Frame --\nStutters -- · Ping --\nMemory -- · Sampling"
        end
    end
    local function setEnabled(value)
        if not active then return end
        if not value then stop(); return end
        if running then return end
        makeGui()
        if not screenGui then
            bridge:Notify({Title = "性能监控", Content = "无法创建 PlayerGui HUD，监控未开启。", Duration = 5})
            return
        end
        running = true
        frameConnection = RunService.Heartbeat:Connect(update)
    end

    tab:AddParagraph({Title = "运行时性能", Content = "按需采样 FPS / Ping / 内存；默认关闭，没有空闲帧循环。不改变游戏画质或帧率。"})
    tab:AddToggle("VortexionPerfHUD", {Title = "显示性能 HUD", Default = false, Callback = setEnabled})
    tab:AddSlider("VortexionPerfSampleSeconds", {Title = "采样间隔（秒）", Min = 1, Max = 5, Default = 1, Rounding = 0,
        Callback = function(v)
            local n = tonumber(v)
            if not n or n ~= n or n == math.huge or n == -math.huge then n = 1 end
            sampleInterval = math.max(1, math.min(5, n))
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
