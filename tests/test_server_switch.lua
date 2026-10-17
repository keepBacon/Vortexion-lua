-- Run from wind-project: lua5.4 tests/test_server_switch.lua
-- A Luau host may inject SERVER_SWITCH_FACTORY instead of using dofile.
local factory = SERVER_SWITCH_FACTORY or dofile("src/ServerSwitch.luau")
local total = 0
local function equal(actual, expected, label)
    assert(actual == expected, (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function server(id, ping, extras)
    local s = {id = id, ping = ping or 30, maxPlayers = 20, playing = 2, fps = 60}
    for k, v in pairs(extras or {}) do s[k] = v end
    return s
end
local function fixture(options)
    options = options or {}
    local now, jobs, order = 0, {}, 0
    local f = {calls = {}, teleports = {}, notifications = {}, decoded = 0, paragraphs = {}, controls = {}}
    os = {clock = function() return now end}
    local function schedule(thread, at)
        order = order + 1
        jobs[#jobs + 1] = {thread = thread, at = at, order = order}
    end
    task = {spawn = function(fn)
        local thread = coroutine.create(fn)
        schedule(thread, now)
        return thread
    end, wait = function(seconds) return coroutine.yield(math.max(seconds or 0, 0.001)) end}
    function f:run(duration)
        local deadline, steps = now + duration, 0
        while true do
            table.sort(jobs, function(a, b)
                if a.at ~= b.at then return a.at < b.at end
                return a.order < b.order
            end)
            local job = jobs[1]
            if not job or job.at > deadline then break end
            table.remove(jobs, 1)
            now = job.at
            local ok, delay = coroutine.resume(job.thread)
            assert(ok, tostring(delay))
            if coroutine.status(job.thread) ~= "dead" then schedule(job.thread, now + delay) end
            steps = steps + 1
            assert(steps < 100000, "scheduler stalled")
        end
        now = deadline
    end
    local handlers = {}
    local signal = {}
    function signal:Connect(fn)
        handlers[fn] = true
        return {Disconnect = function() handlers[fn] = nil end}
    end
    function signal:Fire(...)
        for fn in pairs(handlers) do fn(...) end
    end
    local player = {}
    function player:GetNetworkPing()
        if options.pingError then error("ping unavailable") end
        if type(options.ping) == "function" then return options.ping(now) end
        return options.ping or 0.250
    end
    f.player, f.signal = player, signal
    local jsonValues, jsonId = {}, 0
    local httpService = {}
    function httpService:JSONEncode(value)
        jsonId = jsonId + 1
        local key = "json" .. jsonId
        jsonValues[key] = value
        return key
    end
    function httpService:JSONDecode(value)
        f.decoded = f.decoded + 1
        assert(jsonValues[value], "bad json")
        return jsonValues[value]
    end
    function httpService:UrlEncode(value) return value end
    local teleportService = {TeleportInitFailed = signal}
    function teleportService:TeleportToPlaceInstance(place, id, who)
        f.teleports[#f.teleports + 1] = {place = place, id = id, who = who}
        if options.teleport then return options.teleport(f, id, #f.teleports) end
    end
    local services = {Players = {LocalPlayer = player}, HttpService = httpService, TeleportService = teleportService}
    game = {PlaceId = 12345, JobId = "current", GetService = function(_, name) return services[name] end}
    request = function(args)
        f.calls[#f.calls + 1] = args
        if options.requestDelay then task.wait(options.requestDelay) end
        local body, code
        if options.response then body, code = options.response(f, args, jsonValues[args.Body]) end
        if body == nil and code == nil then
            if args.Url:find("/servers/Public", 1, true) then
                body = options.list or {data = options.servers or {server("a"), server("b", 40)}}
            elseif args.Method == "POST" then
                local id = jsonValues[args.Body].gameId
                local ip = (options.ips or {})[id] or (id == "a" and "128.116.1.1" or "128.116.1.2")
                body = {joinScript = {UdmuxEndpoints = {{Address = ip}}}}
            else
                local ip = args.Url:match("(%d+%.%d+%.%d+%.%d+)$")
                body = (options.geos or {})[ip] or {success = true, country_code = "HK"}
            end
        end
        return {StatusCode = code or 200, Body = type(body) == "string" and body or httpService:JSONEncode(body)}
    end
    getgenv = function() return options.env or {} end
    syn, http_request, http, fluxus = nil, nil, nil, nil
    local tab = {}
    function tab:AddParagraph(value)
        local p = {Title = value.Title, Content = value.Content, updates = 0}
        function p:SetDesc(text) self.Content = text; self.updates = self.updates + 1 end
        f.paragraphs[#f.paragraphs + 1] = p
        return p
    end
    for _, method in ipairs({"AddToggle", "AddSlider", "AddInput"}) do
        tab[method] = function(_, id, value)
            f.controls[id] = value
            value.Callback(value.Default)
            return value
        end
    end
    function tab:AddButton(value) f.controls[value.Title] = value; return value end
    f.controller = factory(tab, function(message) f.notifications[#f.notifications + 1] = message end)
    return f
end
local function test(name, fn)
    fn()
    total = total + 1
    print("PASS " .. name)
end
test("default is passive and samples real client ping", function()
    local f = fixture()
    equal(f.controller:Config().AutoSwitch, false)
    equal(table.concat(f.controller:Config().PreferredCountries, ","), "HK,JP,SG,TW,KR")
    f:run(100)
    equal(#f.calls, 0); equal(#f.teleports, 0)
    equal(f.controller:GetStatus().PingMs, 250)
    equal(f.controller:GetStatus().HighSamples, 0)
    assert(f.paragraphs[1].updates > 0)
    f.controller:Stop()
end)
test("concurrent switch and uncertain teleport fence", function()
    local f = fixture()
    assert(f.controller:Switch())
    equal(f.controller:Switch(), false)
    f:run(25)
    equal(#f.teleports, 1)
    equal(f.controller:GetStatus().Phase, "uncertain")
    equal(f.controller:GetStatus().TeleportUncertain, true)
    f:run(300)
    equal(f.controller:Switch(), false)
    f.controller:Stop()
end)
test("identified async failure retries next candidate only", function()
    local f = fixture({teleport = function(self, id, count)
        if count == 1 then task.spawn(function()
            task.wait(0.3)
            self.signal:Fire(self.player, "Failure", "full", 12345, {ServerInstanceId = id})
            self.signal:Fire(self.player, "Failure", "duplicate", 12345, {ServerInstanceId = id})
        end) end
    end})
    assert(f.controller:Switch())
    f:run(6)
    equal(#f.teleports, 2)
    equal(f.teleports[1].id, "a"); equal(f.teleports[2].id, "b")
    f.signal:Fire(f.player, "Failure", "stale", 12345, {ServerInstanceId = "a"})
    f:run(1)
    equal(f.controller:GetStatus().Phase, "teleporting")
    f.controller:Stop()
end)
test("unidentified legacy failure is terminal not unsafe retry", function()
    local f = fixture({teleport = function(self) self.signal:Fire(self.player, "Failure", "legacy", 12345) end})
    f.controller:Switch(); f:run(5)
    equal(#f.teleports, 1); equal(f.controller:GetStatus().Phase, "failed")
    f.controller:Stop()
end)
test("synchronous teleport throw retries with bounded attempts", function()
    local f = fixture({teleport = function() error("teleport rejected") end})
    f.controller:Config({MaxTeleportAttempts = 1})
    f.controller:Switch(); f:run(4)
    equal(#f.teleports, 1); equal(f.controller:GetStatus().Busy, false)
    equal(f.controller:Switch(), false)
    f.controller:Stop()
end)
test("stop before scheduled work sends no requests", function()
    local f = fixture()
    f.controller:Switch(); f.controller:Stop(); f:run(30)
    equal(#f.calls, 0); equal(#f.teleports, 0)
    equal(f.controller:GetStatus().Phase, "stopped")
end)
test("stop during in-flight request discards response", function()
    local f = fixture({requestDelay = 3})
    f.controller:Switch(); f:run(0.2)
    f.controller:Stop()
    local updates, decoded = f.paragraphs[1].updates, f.decoded
    f:run(20)
    equal(#f.teleports, 0); equal(f.decoded, decoded)
    equal(f.paragraphs[1].updates, updates); equal(#f.notifications, 0)
end)
test("request timeout keeps fence and never decodes late result", function()
    local f = fixture({requestDelay = 20})
    f.controller:Config({RequestTimeoutSeconds = 1, SwitchCooldownSeconds = 10})
    f.controller:Switch(); f:run(12)
    equal(f.controller:GetStatus().Phase, "failed")
    equal(f.controller:GetStatus().RequestInFlight, true)
    equal(f.controller:Switch(), false)
    local decoded = f.decoded
    f:run(10)
    equal(f.decoded, decoded); equal(#f.teleports, 0)
    equal(f.controller:GetStatus().RequestInFlight, false)
    f.controller:Stop()
end)
test("IP failure never falls back even with strict region disabled", function()
    local f = fixture({ips = {a = "10.0.0.1", b = "127.0.0.1"}})
    f.controller:Config({StrictRegion = false})
    f.controller:Switch(); f:run(5)
    equal(#f.teleports, 0); equal(f.controller:GetStatus().ResolvedIPs, 0)
    equal(f.controller:GetStatus().Phase, "failed")
    f.controller:Stop()
end)
test("strict region rejects unconfirmed or unpreferred country", function()
    local f = fixture({geos = {["128.116.1.1"] = {success = false},
        ["128.116.1.2"] = {success = true, country_code = "US"}}})
    f.controller:Switch(); f:run(5)
    equal(#f.teleports, 0); equal(f.controller:GetStatus().ResolvedIPs, 2)
    f.controller:Stop()
end)
test("country priority outranks reported list ping", function()
    local f = fixture({servers = {server("a", 1), server("b", 900)},
        geos = {["128.116.1.1"] = {success = true, country_code = "JP"}}})
    f.controller:Switch(); f:run(5)
    equal(f.teleports[1].id, "b")
    equal(f.controller:GetStatus().Target.country, "HK")
    equal(f.controller:GetStatus().Target.listPing, 900)
    equal(f.controller:GetStatus().PingMs, 250)
    f.controller:Stop()
end)
test("page and lookup budgets with duplicate cursor and jobs", function()
    local f = fixture({list = {data = {server("a"), server("a"), server("b"), server("current")}, nextPageCursor = "same"}})
    f.controller:Config({MaxServerPages = 3, MaxIPLookups = 1})
    f.controller:Switch(); f:run(5)
    local status = f.controller:GetStatus()
    equal(status.Pages, 2); equal(status.IPChecks, 1); equal(status.Requests, 4)
    equal(#f.teleports, 1)
    f.controller:Stop()
end)
test("no slots or low fps is excluded", function()
    local f = fixture({servers = {server("a", 1, {playing = 20}), server("b", 2, {fps = 34})}})
    f.controller:Switch(); f:run(5)
    equal(#f.calls, 1); equal(#f.teleports, 0)
    f.controller:Stop()
end)
test("HTTP and malformed JSON failures release busy", function()
    for _, response in ipairs({function() return {}, 403 end, function() return "invalid json" end}) do
        local f = fixture({response = response})
        f.controller:Switch(); f:run(5)
        equal(f.controller:GetStatus().Busy, false)
        equal(f.controller:GetStatus().Phase, "failed"); equal(#f.teleports, 0)
        f.controller:Stop()
    end
end)
test("auto switch requires sustained client ping not list ping", function()
    local f = fixture()
    f.controller:Config({AutoSwitch = true, InitialDelaySeconds = 0, SampleIntervalSeconds = 1, PingSamplesRequired = 4})
    f:run(2.9); equal(#f.calls, 0)
    f:run(3); equal(#f.teleports, 1)
    f.controller:Stop()
    local low = fixture({ping = 0.020})
    low.controller:Config({AutoSwitch = true, InitialDelaySeconds = 0, SampleIntervalSeconds = 1})
    low:run(20); equal(#low.calls, 0)
    low.controller:Stop()
end)
test("invalid real ping resets sustained high counter", function()
    local f = fixture({ping = function(time) return time < 1.5 and 0.500 or 0 / 0 end})
    f.controller:Config({AutoSwitch = true, InitialDelaySeconds = 0, SampleIntervalSeconds = 1})
    f:run(10)
    equal(#f.calls, 0); equal(f.controller:GetStatus().PingMs, nil)
    equal(f.controller:GetStatus().HighSamples, 0)
    f.controller:Stop()
end)
test("stop from status observer before teleport prevents dispatch", function()
    local f = fixture()
    f.controller:OnChange(function(status)
        if status.Phase == "teleporting" then f.controller:Stop() end
    end)
    f.controller:Switch(); f:run(5)
    equal(#f.teleports, 0); equal(f.controller:GetStatus().Phase, "stopped")
end)
test("stop during retry delay suppresses next teleport", function()
    local f = fixture({teleport = function() error("rejected") end})
    f.controller:OnChange(function(status)
        if status.Phase == "retrying" then f.controller:Stop() end
    end)
    f.controller:Switch(); f:run(10)
    equal(#f.teleports, 1); equal(f.controller:GetStatus().Phase, "stopped")
end)
test("config and status snapshots isolate callers and unsubscribe works", function()
    local f = fixture()
    local cfg = f.controller:Config(); cfg.PreferredCountries[1] = "US"
    equal(f.controller:Config().PreferredCountries[1], "HK")
    equal(f.controller:Config({PingThresholdMs = 0 / 0}), false)
    equal(f.controller:Config({Unknown = true}), false)
    local calls = 0
    local off = f.controller:OnChange(function(s) calls = calls + 1; s.Message = "tampered" end)
    equal(calls, 1); off()
    f.controller:Config({PingThresholdMs = 200}); equal(calls, 1)
    assert(f.controller:GetStatus().Message ~= "tampered")
    f.controls.ServerSwitchCountries.Callback("JP, SG")
    equal(table.concat(f.controller:Config().PreferredCountries, ","), "JP,SG")
    f.controls.ServerSwitchPingThresholdMs.Callback(190)
    equal(f.controller:Config().PingThresholdMs, 190)
    f.controller:Stop()
end)
test("late identified failure clears uncertain fence without retry", function()
    local f = fixture()
    f.controller:Switch(); f:run(25)
    f.signal:Fire({}, "Failure", "other player", 12345, {ServerInstanceId = "a"})
    equal(f.controller:GetStatus().Phase, "uncertain")
    f.signal:Fire(f.player, "Failure", "late failure", 12345, {ServerInstanceId = "a"})
    equal(f.controller:GetStatus().Phase, "failed")
    equal(f.controller:GetStatus().TeleportUncertain, false)
    equal(#f.teleports, 1)
    f.controller:Stop()
end)
test("yielding teleport call times out and late error does not retry", function()
    local f = fixture({teleport = function() task.wait(30); error("late throw") end})
    f.controller:Config({TeleportTimeoutSeconds = 5})
    f.controller:Switch(); f:run(10)
    equal(f.controller:GetStatus().Phase, "uncertain"); equal(#f.teleports, 1)
    f:run(30)
    equal(f.controller:GetStatus().Phase, "failed"); equal(#f.teleports, 1)
    equal(f.controller:GetStatus().TeleportUncertain, false)
    f.controller:Stop()
end)
test("stop while teleport yields suppresses late updates and retries", function()
    local f = fixture({teleport = function() task.wait(10); error("late throw") end})
    f.controller:Switch(); f:run(5); f.controller:Stop()
    local updates = f.paragraphs[1].updates
    f:run(30)
    equal(f.controller:GetStatus().Phase, "stopped"); equal(#f.teleports, 1)
    equal(f.paragraphs[1].updates, updates); equal(#f.notifications, 0)
end)
print("ServerSwitch mock tests passed: " .. total)
