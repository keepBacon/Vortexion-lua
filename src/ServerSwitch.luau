-- Standalone factory; controller methods use colon syntax.
return function(tab, notify)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local player, placeId = Players.LocalPlayer, game.PlaceId
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local apiRequest = (syn and syn.request) or http_request or request
        or (http and http.request) or (fluxus and fluxus.request)
    local config = {
        PreferredCountries = {"HK", "JP", "SG", "TW", "KR"},
        PreferredIPPrefixes = {}, AutoSwitch = false, StrictRegion = true,
        PingThresholdMs = 180, PingSamplesRequired = 4, SampleIntervalSeconds = 5,
        InitialDelaySeconds = 20, SwitchCooldownSeconds = 240,
        MaxServerPages = 3, MaxIPLookups = 12, MinAvailableSlots = 1,
        MinimumServerFPS = 35, CountryLookupUrl = "https://ipwho.is/",
        RequestTimeoutSeconds = 10, TeleportTimeoutSeconds = 20,
        MaxTeleportAttempts = 3, RetryDelaySeconds = 2,
    }
    local bounds = {
        PingThresholdMs = {50, 1000}, PingSamplesRequired = {1, 12},
        SampleIntervalSeconds = {1, 60}, InitialDelaySeconds = {0, 120},
        SwitchCooldownSeconds = {10, 1800}, MaxServerPages = {1, 10},
        MaxIPLookups = {1, 30}, MinAvailableSlots = {1, 100},
        MinimumServerFPS = {0, 60}, RequestTimeoutSeconds = {1, 60},
        TeleportTimeoutSeconds = {5, 120}, MaxTeleportAttempts = {1, 5},
        RetryDelaySeconds = {1, 30},
    }
    local function copy(value)
        if type(value) ~= "table" then return value end
        local result = {}
        for k, v in pairs(value) do result[k] = copy(v) end
        return result
    end
    local function finite(n)
        return type(n) == "number" and n == n and n > -math.huge and n < math.huge
    end
    local function validIP(ip)
        if type(ip) ~= "string" then return false end
        local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
        if not a then return false end
        a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
        if a > 255 or b > 255 or c > 255 or d > 255 then return false end
        return not (a == 0 or a == 10 or a == 127 or a >= 224
            or (a == 169 and b == 254) or (a == 172 and b >= 16 and b <= 31)
            or (a == 192 and b == 168) or (a == 100 and b >= 64 and b <= 127))
    end
    local running, busy, generation = true, false, 0
    local highSamples, lastSearch, enabledAt = 0, -math.huge, os.clock()
    local requestInFlight, pendingTeleport = false, nil
    local listeners, regionCache = {}, {}
    local blocked = {[game.JobId] = true}
    local status = {Phase = "idle", Message = "自动切服默认关闭", Busy = false,
        Running = true, AutoSwitch = false, HighSamples = 0, Requests = 0,
        Pages = 0, IPChecks = 0, ResolvedIPs = 0, TeleportAttempts = 0}
    local paragraph
    local controller = {}
    local function emit(phase, message, fields)
        if phase then status.Phase = phase end
        if message then status.Message = message end
        for k, v in pairs(fields or {}) do status[k] = v end
        status.Busy, status.Running = busy, running
        status.AutoSwitch, status.HighSamples = config.AutoSwitch, highSamples
        status.RequestInFlight = requestInFlight
        status.CooldownRemaining = math.max(0, config.SwitchCooldownSeconds - (os.clock() - lastSearch))
        if paragraph and type(paragraph.SetDesc) == "function" then
            local ping = status.PingMs and (tostring(status.PingMs) .. " ms") or "暂无采样"
            pcall(paragraph.SetDesc, paragraph, status.Message .. "\n客户端延迟：" .. ping
                .. " | 连续高延迟：" .. highSamples .. "/" .. config.PingSamplesRequired
                .. "\n列表页：" .. status.Pages .. " | IP 查询：" .. status.IPChecks
                .. " | 传送尝试：" .. status.TeleportAttempts)
        end
        local callbacks = {}
        for fn in pairs(listeners) do callbacks[#callbacks + 1] = fn end
        for _, fn in ipairs(callbacks) do
            if listeners[fn] then pcall(fn, copy(status)) end
        end
    end
    local function alive(token) return running and token == generation end
    local function pause(token, duration)
        local deadline = os.clock() + duration
        while alive(token) and os.clock() < deadline do task.wait(math.min(0.1, deadline - os.clock())) end
        return alive(token)
    end
    -- Keep the physical request fence after timeout; late results never commit state.
    local function bounded(token, timeout, fn)
        if not alive(token) then return nil, "已停止" end
        if requestInFlight then return nil, "上次超时请求尚未返回" end
        requestInFlight = true
        local done, expired, ok, result = false, false, false, nil
        local deadline = os.clock() + timeout
        task.spawn(function()
            if not alive(token) then requestInFlight = false; return end
            local success, value = pcall(fn)
            requestInFlight = false
            if not expired and alive(token) and os.clock() <= deadline then
                ok, result, done = success, value, true
            end
        end)
        while alive(token) and not done and os.clock() < deadline do task.wait(0.05) end
        if not alive(token) then expired = true; return nil, "已停止" end
        if not done then expired = true; return nil, "请求超时" end
        if not ok then return nil, "请求失败：" .. tostring(result) end
        return result
    end
    local function json(token, cfg, method, url, body)
        status.Requests = status.Requests + 1
        local response, reason = bounded(token, cfg.RequestTimeoutSeconds, function()
            if type(apiRequest) == "function" then
                return apiRequest({Url = url, Method = method, Body = body,
                    Headers = {["Content-Type"] = "application/json", Accept = "application/json"}})
            end
            if method == "GET" then return {Body = game:HttpGet(url)} end
            error("执行器未提供 POST 请求接口")
        end)
        if not alive(token) then return nil, "已停止" end
        if type(response) ~= "table" then return nil, reason or "响应格式错误" end
        local code = tonumber(response.StatusCode or response.Status or response.status_code)
        if code and (code < 200 or code >= 300) then return nil, "HTTP " .. code end
        local bodyText = response.Body or response.body
        if type(bodyText) ~= "string" then return nil, "响应正文缺失" end
        local ok, data = pcall(HttpService.JSONDecode, HttpService, bodyText)
        if not alive(token) then return nil, "已停止" end
        if ok and type(data) == "table" then return data end
        return nil, "JSON 解析失败"
    end
    local function resolve(token, cfg, id)
        if type(env.VortexionResolveServerIP) == "function" then
            local ip = bounded(token, cfg.RequestTimeoutSeconds, function()
                return env.VortexionResolveServerIP(placeId, id)
            end)
            if not alive(token) then return nil end
            if validIP(ip) then return ip end
            if requestInFlight then return nil end
        end
        if type(apiRequest) ~= "function" then return nil end
        local body = HttpService:JSONEncode({placeId = placeId, gameId = id,
            gameJoinAttemptId = id, isTeleport = false})
        local data = json(token, cfg, "POST", "https://gamejoin.roblox.com/v1/join-game-instance", body)
        local js = data and data.joinScript
        if type(js) ~= "table" then return nil end
        for _, key in ipairs({"UdmuxEndpoints", "ServerConnections"}) do
            if type(js[key]) == "table" then
                for _, endpoint in ipairs(js[key]) do
                    if type(endpoint) == "table" and validIP(endpoint.Address) then return endpoint.Address end
                end
            end
        end
        return validIP(js.MachineAddress) and js.MachineAddress or nil
    end
    local function rankIP(token, cfg, ip)
        for i, prefix in ipairs(cfg.PreferredIPPrefixes) do
            if ip:sub(1, #prefix) == prefix then return i, "IP 前缀 " .. prefix end
        end
        local cache = regionCache
        local country = cache[ip]
        if not country then
            local geo = json(token, cfg, "GET", cfg.CountryLookupUrl .. ip)
            if not alive(token) then return nil end
            country = geo and geo.success == true and geo.country_code
            if type(country) ~= "string" then return nil, "地区未知" end
            country = country:upper()
            cache[ip] = country
        end
        for i, wanted in ipairs(cfg.PreferredCountries) do
            if country == wanted then return i + #cfg.PreferredIPPrefixes, country end
        end
        return nil, country
    end
    local function candidates(token, cfg)
        local results, seen, cursors = {}, {}, {}
        local cursor
        for _ = 1, cfg.MaxServerPages do
            if not alive(token) then return {} end
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(placeId)
            if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local data, reason = json(token, cfg, "GET", url)
            if not alive(token) then return {} end
            if not data or type(data.data) ~= "table" then return results, reason or "服务器列表格式错误" end
            status.Pages = status.Pages + 1
            for _, server in ipairs(data.data) do
                if type(server) == "table" then
                    local slots = (tonumber(server.maxPlayers) or 0) - (tonumber(server.playing) or 0)
                    local fps = tonumber(server.fps) or 0
                    local listPing = tonumber(server.ping)
                    if type(server.id) == "string" and server.id ~= "" and not blocked[server.id]
                        and not seen[server.id] and slots >= cfg.MinAvailableSlots and fps >= cfg.MinimumServerFPS then
                        seen[server.id] = true
                        results[#results + 1] = {id = server.id, slots = slots,
                            listPing = finite(listPing) and listPing >= 0 and listPing or nil}
                    end
                end
            end
            cursor = data.nextPageCursor
            if type(cursor) ~= "string" or cursor == "" or cursors[cursor] then break end
            cursors[cursor] = true
            if not pause(token, 0.4) then return {} end
        end
        table.sort(results, function(a, b)
            return (a.listPing or math.huge) < (b.listPing or math.huge)
        end)
        return results
    end
    local function search(token, cfg)
        local list, listError = candidates(token, cfg)
        if not alive(token) then return {} end
        if #list == 0 then return {}, listError or "没有可用的公共服务器" end
        local matches = {}
        for _, server in ipairs(list) do
            if not alive(token) or requestInFlight or status.IPChecks >= cfg.MaxIPLookups then break end
            status.IPChecks = status.IPChecks + 1
            local ip = resolve(token, cfg, server.id)
            if not alive(token) then return {} end
            if ip then
                status.ResolvedIPs = status.ResolvedIPs + 1
                local rank, country = rankIP(token, cfg, ip)
                if not alive(token) then return {} end
                if rank or not cfg.StrictRegion then
                    server.ip, server.country, server.rank = ip, country or "地区未知", rank or math.huge
                    matches[#matches + 1] = server
                end
            end
            emit("searching", "正在确认候选服务器 IP 与地区")
            if not pause(token, 0.4) then return {} end
        end
        table.sort(matches, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            return (a.listPing or math.huge) < (b.listPing or math.huge)
        end)
        if #matches > 0 then return matches end
        if status.ResolvedIPs == 0 then return {}, "IP 解析失败；未使用虚构 IP 或仅按列表延迟切服" end
        return {}, "没有已确认且符合偏好地区的 IP"
    end
    local failureConnection = TeleportService.TeleportInitFailed:Connect(function(who, result, message, failedPlace, options)
        local attempt = pendingTeleport
        if not running or not attempt or who ~= player or failedPlace ~= placeId then return end
        local identified = false
        if options then
            local ok, id = pcall(function() return options.ServerInstanceId end)
            if ok and type(id) == "string" and id ~= "" then
                if id ~= attempt.id then return end
                identified = true
            end
        end
        if attempt.failed then return end
        -- Legacy events without a target id are terminal, not a basis for chained retries.
        attempt.retryable = identified
        attempt.failed = "传送失败：" .. tostring(message or result)
        if attempt.uncertain then
            pendingTeleport = nil
            emit("failed", attempt.failed, {TeleportUncertain = false})
        end
    end)
    local function finish(token, phase, message)
        if not alive(token) then return end
        busy = false
        emit(phase, message)
        if alive(token) and type(notify) == "function" then pcall(notify, message) end
    end
    function controller:Switch()
        if not running then return false, "已停止" end
        if busy then return false, "正在搜索或传送" end
        if pendingTeleport then return false, "前次传送结果仍待确认，请勿重复切服" end
        if requestInFlight then return false, "前次请求仍在返回中" end
        if os.clock() - lastSearch < config.SwitchCooldownSeconds then return false, "切服冷却中" end
        busy, lastSearch, generation = true, os.clock(), generation + 1
        local token, cfg = generation, copy(config)
        highSamples = 0
        status.Pages, status.IPChecks, status.ResolvedIPs, status.Requests, status.TeleportAttempts = 0, 0, 0, 0, 0
        status.Target, status.LastError, status.TeleportUncertain = nil, nil, false
        emit("searching", "正在搜索低延迟地区服务器")
        task.spawn(function()
            local ok, err = pcall(function()
                local matches, reason = search(token, cfg)
                if not alive(token) then return end
                if #matches == 0 then finish(token, "failed", reason); return end
                for i = 1, math.min(#matches, cfg.MaxTeleportAttempts) do
                    if not alive(token) then return end
                    local target = matches[i]
                    local attempt = {id = target.id}
                    pendingTeleport = attempt
                    status.Target = {id = target.id, ip = target.ip, country = target.country,
                        listPing = target.listPing, slots = target.slots}
                    status.TeleportAttempts = i
                    emit("teleporting", "正在切服至 " .. target.country .. "；列表延迟仅作排序参考")
                    if not alive(token) then return end
                    blocked[target.id] = true
                    local deadline = os.clock() + cfg.TeleportTimeoutSeconds
                    task.spawn(function()
                        if not alive(token) or pendingTeleport ~= attempt then return end
                        attempt.dispatched = true
                        local sent, sendError = pcall(function()
                            TeleportService:TeleportToPlaceInstance(placeId, target.id, player)
                        end)
                        if not alive(token) or pendingTeleport ~= attempt then return end
                        if not sent and not attempt.failed then
                            attempt.failed = "传送调用失败：" .. tostring(sendError)
                            attempt.retryable = true
                            if attempt.uncertain then
                                pendingTeleport = nil
                                emit("failed", attempt.failed, {TeleportUncertain = false})
                            end
                        end
                    end)
                    while alive(token) and not attempt.failed and os.clock() < deadline do task.wait(0.1) end
                    if not alive(token) then return end
                    if not attempt.failed then
                        -- Absence of failure is not success. Never retry an outcome-unknown teleport.
                        attempt.uncertain = true
                        status.TeleportUncertain = true
                        finish(token, "uncertain", "传送等待超时，结果未确认；已阻止重复传送")
                        return
                    end
                    pendingTeleport = nil
                    status.LastError = attempt.failed
                    if not attempt.retryable or i >= math.min(#matches, cfg.MaxTeleportAttempts) then break end
                    emit("retrying", attempt.failed .. "；尝试下一候选服务器")
                    if not pause(token, cfg.RetryDelaySeconds) then return end
                end
                finish(token, "failed", status.LastError or "传送失败")
            end)
            if not ok and alive(token) then
                pendingTeleport = nil
                finish(token, "failed", "切服流程错误：" .. tostring(err))
            end
        end)
        return true
    end
    function controller:Stop()
        if not running then return end
        running, busy, generation = false, false, generation + 1
        config.AutoSwitch, highSamples = false, 0
        failureConnection:Disconnect()
        local dispatched = pendingTeleport and pendingTeleport.dispatched
        pendingTeleport = nil
        emit("stopped", dispatched and "已停止后续操作；已发出的传送由客户端处理" or "已停止切服与采样")
        listeners = {}
    end
    function controller:GetStatus()
        local snapshot = copy(status)
        snapshot.RequestInFlight = requestInFlight
        snapshot.HighSamples, snapshot.AutoSwitch = highSamples, config.AutoSwitch
        snapshot.CooldownRemaining = math.max(0, config.SwitchCooldownSeconds - (os.clock() - lastSearch))
        return snapshot
    end
    function controller:OnChange(fn)
        assert(type(fn) == "function", "OnChange expects a function")
        if not running then return function() end end
        listeners[fn] = true
        pcall(fn, self:GetStatus())
        return function() listeners[fn] = nil end
    end
    function controller:Config(patch)
        if patch == nil then return copy(config) end
        if not running then return false, "已停止" end
        if type(patch) ~= "table" then return false, "配置须为表" end
        local nextConfig = copy(config)
        for key, value in pairs(patch) do
            if bounds[key] then
                local range = bounds[key]
                if not finite(value) or value < range[1] or value > range[2] then return false, "配置数值越界：" .. key end
                nextConfig[key] = math.floor(value)
            elseif key == "AutoSwitch" or key == "StrictRegion" then
                if type(value) ~= "boolean" then return false, "配置须为布尔值：" .. key end
                nextConfig[key] = value
            elseif key == "PreferredCountries" or key == "PreferredIPPrefixes" then
                if type(value) ~= "table" or #value > 30 then return false, "地区配置格式错误" end
                local items = {}
                for _, item in ipairs(value) do
                    if type(item) ~= "string" or item == "" then return false, "地区配置格式错误" end
                    if key == "PreferredCountries" then
                        item = item:upper()
                        if not item:match("^[A-Z][A-Z]$") then return false, "国家代码须为两位字母" end
                    elseif not item:match("^%d[%d%.]*$") or #item > 15 then
                        return false, "IP 前缀格式错误"
                    end
                    items[#items + 1] = item
                end
                nextConfig[key] = items
            elseif key == "CountryLookupUrl" then
                if type(value) ~= "string" or not value:match("^https://") then return false, "地区接口须使用 HTTPS" end
                nextConfig[key] = value
            else return false, "未知配置：" .. tostring(key) end
        end
        if nextConfig.AutoSwitch ~= config.AutoSwitch then enabledAt = os.clock(); highSamples = 0 end
        if nextConfig.PingThresholdMs ~= config.PingThresholdMs or nextConfig.PingSamplesRequired ~= config.PingSamplesRequired then highSamples = 0 end
        if nextConfig.CountryLookupUrl ~= config.CountryLookupUrl then regionCache = {} end
        config = nextConfig
        emit(nil, nil)
        return true
    end
    local function set(key, value)
        local ok, reason = controller:Config({[key] = value})
        if not ok and type(notify) == "function" then pcall(notify, reason) end
    end
    paragraph = tab:AddParagraph({Title = "低延迟切服状态", Content = status.Message})
    tab:AddParagraph({Title = "切服说明", Content = "真实延迟来自客户端 GetNetworkPing 采样。服务器列表 ping 不是你的客户端延迟，也不保证换服后更低。默认严格确认 IP 地区；IP 失败则停止搜索，不虚构地区。冷却同时适用于手动与自动切服。"})
    tab:AddToggle("ServerSwitchAuto", {Title = "持续高延迟时自动切服", Default = false, Callback = function(v) set("AutoSwitch", v) end})
    tab:AddToggle("ServerSwitchStrictRegion", {Title = "严格匹配已确认 IP 地区", Default = true, Callback = function(v) set("StrictRegion", v) end})
    local sliders = {
        {"PingThresholdMs", "客户端延迟阈值（ms）"}, {"PingSamplesRequired", "连续高延迟采样次数"},
        {"SampleIntervalSeconds", "采样间隔（秒）"}, {"SwitchCooldownSeconds", "切服冷却（秒）"},
        {"MaxServerPages", "服务器列表页数预算"}, {"MaxIPLookups", "候选 IP 查询预算"},
        {"MinimumServerFPS", "最低服务器 FPS"},
    }
    for _, item in ipairs(sliders) do
        local key = item[1]
        tab:AddSlider("ServerSwitch" .. key, {Title = item[2], Min = bounds[key][1], Max = bounds[key][2],
            Default = config[key], Rounding = 0, Callback = function(v) set(key, v) end})
    end
    local function split(text)
        local items = {}
        for item in tostring(text):gmatch("[^,%s]+") do items[#items + 1] = item end
        return items
    end
    tab:AddInput("ServerSwitchCountries", {Title = "地区优先顺序（逗号分隔）", Default = "HK,JP,SG,TW,KR", Callback = function(v) set("PreferredCountries", split(v)) end})
    tab:AddInput("ServerSwitchIPPrefixes", {Title = "优先 IP 前缀（可留空）", Default = "", Callback = function(v) set("PreferredIPPrefixes", split(v)) end})
    tab:AddButton({Title = "立即搜索并切服", Callback = function()
        local ok, reason = controller:Switch()
        if not ok and type(notify) == "function" then pcall(notify, reason) end
    end})
    local function showSampleStatus()
        local text
        if not running then
            text = "此切服模块已停止，没有新的采样数据"
        else
            local snapshot = controller:GetStatus()
            local message = (type(snapshot.Message) == "string" and snapshot.Message ~= "") and snapshot.Message or "未采样"
            local ping = finite(snapshot.PingMs) and (tostring(math.floor(snapshot.PingMs * 100 + 0.5) / 100) .. " ms") or "未采样"
            local high = finite(snapshot.HighSamples) and tostring(math.floor(snapshot.HighSamples + 0.5)) or "未采样"
            local cooldown = finite(snapshot.CooldownRemaining) and (tostring(math.floor(snapshot.CooldownRemaining * 100 + 0.5) / 100) .. " 秒") or "未采样"
            text = table.concat({
                "切服采样状态：" .. message,
                "客户端延迟：" .. ping,
                "连续高延迟采样：" .. high .. "/" .. config.PingSamplesRequired,
                "切服冷却剩余：" .. cooldown,
                "请求进行中：" .. (snapshot.RequestInFlight and "是" or "否"),
                "自动切服：" .. (snapshot.AutoSwitch and "开启" or "关闭"),
            }, "\n")
        end
        if type(notify) == "function" then pcall(notify, text) else pcall(paragraph.SetDesc, paragraph, text) end
    end
    tab:AddButton({Title = "查看切服采样状态", Callback = showSampleStatus})
    tab:AddButton({Title = "停止此切服模块", Callback = function() controller:Stop() end})
    emit(nil, nil)
    task.spawn(function()
        while running do
            local ok, seconds = pcall(function() return player:GetNetworkPing() end)
            if not running then return end
            local ping = ok and finite(seconds) and seconds >= 0 and math.floor(seconds * 1000 + 0.5) or nil
            status.PingMs = ping
            local ready = config.AutoSwitch and os.clock() - enabledAt >= config.InitialDelaySeconds
            if ready and ping and ping >= config.PingThresholdMs then highSamples = highSamples + 1 else highSamples = 0 end
            emit(nil, nil)
            if running and config.AutoSwitch and highSamples >= config.PingSamplesRequired then
                controller:Switch()
                highSamples = 0
            end
            local deadline = os.clock() + config.SampleIntervalSeconds
            while running and os.clock() < deadline do task.wait(0.1) end
        end
    end)
    return controller
end
