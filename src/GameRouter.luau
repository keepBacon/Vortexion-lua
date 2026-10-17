-- Exact experience routing, independent from game feature initialization.
local Router = {}
local UNIVERSE_ROUTES = {
    [6331902150] = "Forsaken",
    [7633926880] = "BloxStrike",
    [1742264997] = "SCP",
}
local PLACE_FALLBACK = {
    [18687417158] = "Forsaken",
    [114234929420007] = "BloxStrike",
    [5041144419] = "SCP",
}
local AOTR_UNIVERSE = 4658598196
local AOTR_PLACES = {
    [13379208636] = "AOTR_Lobby",
    [14916516914] = "AOTR_Lobby",
    [13379349730] = "AOTR_Battle",
    [14638336319] = "AOTR_Battle",
    [14012874501] = "AOTR_Battle",
    [13904207646] = "AOTR_Battle",
}

function Router.Resolve(universe, place)
    universe, place = tonumber(universe), tonumber(place)
    -- Do not fall through to another game from an unknown AOTR scene.
    if universe == AOTR_UNIVERSE then
        local entry = AOTR_PLACES[place]
        return entry, entry and "aotr-place" or "unsupported-aotr-scene"
    end
    local entry = UNIVERSE_ROUTES[universe]
    if entry then return entry, "universe" end
    entry = PLACE_FALLBACK[place]
    return entry, entry and "place-fallback" or "unsupported-experience"
end

function Router.ShowUnsupported(WindUI, WindBridgeFactory, universe, place, reason, detail)
    local bridge = WindBridgeFactory(WindUI, {
        Name = "Vortexion", Folder = "VortexionWind", Section = "V O R T E X I O N",
    })
    local window = bridge:CreateWindow({Title = "Vortexion"})
    local info = window:AddTab({Title = "游戏说明", Icon = "lucide-info"})
    info:AddParagraph({
        Title = detail and "游戏功能初始化未完成"
            or (reason == "unsupported-aotr-scene" and "AOTR 未识别场景" or "未支持的游戏"),
        Content = ("GameId: %s / PlaceId: %s\n%s")
            :format(tostring(universe), tostring(place), detail
                or "仅加载 Wind 通用功能和 UI 设置，未启动任何游戏功能。"),
    })
    info:AddParagraph({
        Title = "支持的游戏",
        Content = "Forsaken、BloxStrike、SCP；AOTR 主菜单与大厅加载大厅模块，已核实的任务地图加载战斗模块。交易中心及未知 AOTR 场景保留通用界面。",
    })
    window:SelectTab(1)
    return bridge
end

-- Keep the generic interface visible when a game exits before creating its UI.
function Router.Run(WindUI, WindBridgeFactory, entry, universe, place, reason)
    local ok, result = true, nil
    if entry then ok, result = pcall(entry) end
    local client = (getgenv and getgenv()) or _G
    local bridge = client.VortexionWindBridge
    local summary = not ok and tostring(result):sub(1, 500) or nil
    local failure = client.VortexionBootError
    -- Prefer the actual constructor error over the caller's abbreviated Lua location.
    -- Entry points often rethrow at CreateWindow({...}), losing the vendor frame.
    if type(failure) == "string" and failure:find("WindUI/CreateWindow", 1, true) then
        summary = failure:sub(1, 1400)
    elseif failure and not summary then
        summary = tostring(failure):sub(1, 800)
    end
    local window
    if type(bridge) == "table" and bridge.Active ~= false then
        if type(bridge.Window) == "function" then
            local windowOk, value = pcall(bridge.Window, bridge)
            if windowOk then window = value end
        else
            window = bridge.Window
        end
    end
    if entry and window then
        if summary then
            warn("[Vortexion/Wind] Game initialization: " .. summary)
            if type(bridge.Notify) == "function" then
                pcall(function() bridge:Notify({Title = "游戏初始化失败", Content = summary, Duration = 6}) end)
            end
        end
        local existingPartial = bridge.BootStatus == "partial"
        bridge.BootStatus = (summary or existingPartial) and "partial" or "ready"
        bridge.BootError = summary or (existingPartial and bridge.BootError or nil)
        return ok and result or bridge
    end
    if entry then
        reason = "game-initialization-incomplete"
        summary = summary or "游戏入口提前结束，尚未创建功能界面。"
        client.VortexionBootError = summary
        warn("[Vortexion/Wind] Game initialization: " .. summary)
    end
    if type(bridge) == "table" and type(bridge.Destroy) == "function" then
        pcall(function() bridge:Destroy() end)
    end
    -- A failed vendor CreateWindow destroys the ScreenGui and its Window folder.
    -- Retrying ShowUnsupported against this *same* WindUI object only hides the
    -- first error with "Window is not a valid member of ScreenGui". The loader's
    -- already-visible diagnostic UI is the safe fallback for this case.
    -- Constructor failure can destroy the vendor ScreenGui even when the entry's
    -- error string is just the outer calling line. Never reuse this WindUI instance.
    if (summary and string.find(summary, "WindUI/CreateWindow", 1, true))
        or (type(failure) == "string" and failure:find("WindUI/CreateWindow", 1, true)) then
        client.VortexionBootError = type(failure) == "string" and failure or summary
        warn("[Vortexion/Wind] Skipping unsafe UI fallback after constructor failure: " .. tostring(client.VortexionBootError))
        return nil
    end
    local fallbackOk, fallback = pcall(Router.ShowUnsupported, WindUI, WindBridgeFactory, universe, place, reason, summary)
    if fallbackOk and type(fallback) == "table" then
        fallback.BootStatus = entry and "partial" or "unsupported"
        fallback.BootError = summary
        return fallback
    end
    client.VortexionBootError = "Generic UI fallback: " .. tostring(fallback)
        .. (summary and ("; Original failure: " .. summary) or "")
    warn("[Vortexion/Wind] " .. client.VortexionBootError)
    return nil
end

return Router
