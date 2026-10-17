-- Vortexion R2.16: read-only, touch-transparent performance telemetry.
-- No screen-sized frames, buttons, modal capture or CoreGui modifications.
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

    local function elapsedString(seconds)
        local n = math.max(0, math.floor(seconds))
        return string.format("%02d:%02d:%02d", math.floor(n / 3600), math.floor(n / 60) % 60, n % 60)
    end
    local function textReport()
        return ("FPS %d [%d-%d] | %.1fms\nPING %s | RAM %s MB\nPEAK %.0fms | >50ms %d\nUP %s | UI %sHz"):format(
            fps, samples > 0 and minimum or 0, maximum, lastAverageFrameMs,
            lastPing and tostring(math.floor(lastPing + 0.5)) .. "ms" or "--",
            lastMemory and tostring(math.floor(lastMemory + 0.5)) or "--",
            peakFrameMs, stutterCount, elapsedString(os.clock() - startedAt),
            tostring(math.floor(tonumber(bridge.VisualHz) or 0)))
    end
    local function makeGui()
        if screenGui or not active then return end
        local parent
        pcall(function() parent = localPlayer:FindFirstChildOfClass("PlayerGui") end)
        if not parent then return end
        -- A stale HUD from an earlier executor run must not remain as an input overlay.
        pcall(function()
            local stale = parent:FindFirstChild("VortexionPerformanceHUD")
            if stale then stale:Destroy() end
        end)
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionPerformanceHUD"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = false
        gui.DisplayOrder = -1000  -- Never compete with game / Roblox menus.
        pcall(function() gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets end)
        local content = Instance.new("TextLabel")
        content.Name = "Metrics"
        content.AnchorPoint = Vector2.new(1, 0)
        content.Position = UDim2.new(1, -6, 0, 5)
        content.Size = UDim2.fromOffset(0, 0)
        if Enum.AutomaticSize then content.AutomaticSize = Enum.AutomaticSize.XY end
        content.BackgroundColor3 = Color3.fromRGB(12, 16, 21)
        content.BackgroundTransparency = 0.45
        content.BorderSizePixel = 0
        content.TextColor3 = Color3.fromRGB(236, 241, 246)
        content.TextStrokeTransparency = 0.7
        content.Font = Enum.Font.Code
        content.TextSize = 12
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.TextWrapped = false
        content.Text = textReport()
        content.Active = false
        content.Selectable = false
        pcall(function() content.Interactable = false end)
        pcall(function() content.InputSink = Enum.InputSink.None end)
        -- Padding belongs to the text itself: no oversized backdrop frame.
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 3)
        padding.PaddingRight = UDim.new(0, 3)
        padding.PaddingTop = UDim.new(0, 2)
        padding.PaddingBottom = UDim.new(0, 2)
        padding.Parent = content
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 3)
        corner.Parent = content
        content.Parent = gui
        local ok = pcall(function() gui.Parent = parent end)
        if not ok or not gui.Parent then gui:Destroy(); return end
        screenGui, label = gui, content
    end
    local function snapshot()
        return {
            fps = fps, minFps = samples > 0 and minimum or 0, maxFps = maximum,
            avgFrameMs = lastAverageFrameMs, peakFrameMs = peakFrameMs,
            stutters = stutterCount, pingMs = lastPing, memoryMb = lastMemory,
            samples = samples, uptimeSeconds = math.floor(os.clock() - startedAt),
            gameId = game.GameId, placeId = game.PlaceId,
        }
    end
    local function update(dt)
        if not active or not running then return end
        local delta = tonumber(dt)
        if not delta or delta ~= delta or delta < 0 or delta == math.huge then return end
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
        if label and label.Parent then label.Text = textReport() end
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
        if label and label.Parent then label.Text = textReport() end
    end
    local function setEnabled(value)
        if not active then return end
        if not value then stop(); return end
        if running then return end
        makeGui()
        if not screenGui then
            bridge:Notify({Title = "性能监控", Content = "PlayerGui HUD 创建失败", Duration = 4})
            return
        end
        running = true
        frameConnection = RunService.Heartbeat:Connect(update)
    end
    tab:AddParagraph({Title = "性能与触控", Content = "紧凑 HUD 只含文本及 2-3px 内边距；位于系统安全区，不接收触摸，不修改 Roblox 菜单。"})
    tab:AddToggle("VortexionPerfHUD", {Title = "显示性能 HUD", Default = false, Callback = setEnabled})
    tab:AddSlider("VortexionPerfSampleSeconds", {Title = "采样间隔（秒）", Min = 1, Max = 5, Default = 1, Rounding = 0,
        Callback = function(v)
            local n = tonumber(v)
            if not n or n ~= n or n == math.huge or n == -math.huge then n = 1 end
            sampleInterval = math.max(1, math.min(5, n))
        end})
    tab:AddButton({Title = "紧急关闭性能 HUD（排查 Roblox 菜单）", Callback = function()
        stop()
        local option = bridge.Options and bridge.Options.VortexionPerfHUD
        if option and option.SetValue then option:SetValue(false) end
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
