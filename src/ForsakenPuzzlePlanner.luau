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
        if not grid then return nil, "GridHolder.Grid missing (gear / transition phase?)" end
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
                local color = circle and rgb(circle.BackgroundColor3) or "-"
                local button = sub(item, "Button")
                local record = {
                    index = i,
                    mark = circle ~= nil,
                    number = markerText,
                    color = color,
                    button = button ~= nil and button:IsA("GuiButton"),
                    buttonActive = button and button.Active or false,
                    visible = item.Visible,
                }
                cells[#cells + 1] = record
                if circle then
                    -- The text may be a unique cell index, not a pair identifier;
                    -- only exactly two identical markers form a candidate pair.
                    local key = markerText ~= "" and "text:" .. markerText or "color:" .. color
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
