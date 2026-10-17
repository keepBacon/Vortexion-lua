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
