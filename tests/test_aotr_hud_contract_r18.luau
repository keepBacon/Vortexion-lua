-- r18 HUD contract fixture (offline, no game factory / remotes / network).
-- The runner injects verbatim byte slices at exactly one placeholder each:
--   HUD-HELP       Common HUD helper section (probeHUD/readCount/findLabel)
--   LOBBY-BUTTON   Lobby HUD AddButton block
--   BATTLE-BUTTON  Battle HUD AddButton block
--   BATTLE-INIT    Battle initial HUD probe line
--   LOBBY-GAS-HELPERS  Lobby finite/hudText/gasText helper block
--   LOBBY-GAS / BATTLE-GAS / LOBBY-REFRESH  Gas + refresh AddButton blocks
-- Only the injected helpers + the five entry buttons + the init line execute here.
local failures = 0
local function check(cond, msg)
    if cond then
        print("green " .. msg)
    else
        failures = failures + 1
        print("RED " .. msg)
    end
end

--===== controllable clock (Roblox tick global is absent offline) =====
local _r18clock = 1000
tick = function() return _r18clock end

--===== fake Roblox env (local, shared with injected sections) =====
local notifications = {}
local aliveFlag = true
local probeCalls, readCalls = 0, 0
local lastProbeArg, lastReadArg = nil, nil
local initProbeArg = nil

local function makeLabel(text, name)
    local l = { ClassName = "TextLabel", Name = name, Text = text, Parent = nil }
    function l:IsA(c) return self.ClassName == c end
    return l
end
local function makeFolder(name)
    local f = { ClassName = "Folder", Name = name, Parent = nil, children = {} }
    function f:IsA(c) return self.ClassName == c end
    function f:FindFirstChild(n, recursive)
        for _, ch in ipairs(self.children) do
            if ch.Name == n then return ch end
        end
        if recursive then
            for _, ch in ipairs(self.children) do
                local r = ch.FindFirstChild and ch:FindFirstChild(n, true)
                if r then return r end
            end
        end
        return nil
    end
    return f
end
local function link(parent, child)
    child.Parent = parent
    table.insert(parent.children, child)
    return child
end

local gui = makeFolder("PlayerGui")
local interface = link(gui, makeFolder("Interface"))
local hud = link(interface, makeFolder("HUD"))
local main = link(hud, makeFolder("Main"))
local top = link(main, makeFolder("Top"))
local bladesFolder = link(top, makeFolder("Blades"))
local spearsFolder = link(top, makeFolder("Spears"))
local bladesLabel = link(bladesFolder, makeLabel("3/8", "Sets"))
local spearsLabel = link(spearsFolder, makeLabel("2/4", "Spears"))

local fakePlayer = {
    FindFirstChild = function(_, n)
        if n == "PlayerGui" then return gui end
        return nil
    end,
}
local Players = { LocalPlayer = fakePlayer }

local app = {}
function app:Alive() return aliveFlag end
function app:Notify(msg) notifications[#notifications + 1] = msg end
function app:ProbeRemotes() end
function app:Guard(_, fn) fn() end

local capturedLobby, capturedBattle = nil, nil
local capturedLobbyGas, capturedBattleGas, capturedLobbyRefresh = nil, nil, nil
-- Route by Title so the R36 gas/refresh entries land in their own slots instead of
-- overwriting the original blades/spears captures.
local overview = { AddButton = function(_, cfg)
    if cfg.Title == "查看燃气余量" then capturedLobbyGas = cfg.Callback
    elseif cfg.Title == "立即刷新全部余量" then capturedLobbyRefresh = cfg.Callback
    else capturedLobby = cfg.Callback end
end }
local tabs = { visual = { AddButton = function(_, cfg)
    if cfg.Title == "查看燃气余量" then capturedBattleGas = cfg.Callback
    else capturedBattle = cfg.Callback end
end } }

local function clearNotes()
    for i = #notifications, 1, -1 do notifications[i] = nil end
end

--===== injected verbatim Common HUD helper =====
__R18_HUD_HELP__

--===== observe-only spies: record call arg types, delegate to real helpers =====
local realProbe, realRead = app.ProbeHUD, app.ReadCount
app.ProbeHUD = function(force)
    probeCalls = probeCalls + 1
    lastProbeArg = force
    return realProbe(force)
end
app.ReadCount = function(label)
    readCalls = readCalls + 1
    lastReadArg = label
    return realRead(label)
end

--===== observe-only spy for the strict percentage reader =====
local realPercent, percentCalls = app.ReadPercent, 0
local percentDeactivate = false
check(type(app.ReadPercent) == "function", "common helper exposes ReadPercent")
if realPercent then
    app.ReadPercent = function(label)
        percentCalls = percentCalls + 1
        if percentDeactivate then aliveFlag = false end
        return realPercent(label)
    end
end

local function stale() app.HUD.lastProbe = 0 end
local function joined() return table.concat(notifications, "|") end

--===== injected verbatim Battle init probe line =====
__R18_BATTLE_INIT__
initProbeArg = lastProbeArg

--===== injected verbatim entry buttons =====
__R18_LOBBY_BUTTON__
__R18_BATTLE_BUTTON__

--===== R36 injected verbatim lobby helpers + gas entry buttons =====
-- LOBBY-GAS-HELPERS must be the verbatim AOTRLobby.luau helper block that
-- defines finite/hudText/gasText.  The gas entries below are captured by Title.
__R36_LOBBY_HELPERS__
__R36_LOBBY_GAS_BUTTON__
__R36_BATTLE_GAS_BUTTON__
__R36_LOBBY_REFRESH_BUTTON__

check(type(capturedLobby) == "function", "lobby HUD button registered")
check(type(capturedBattle) == "function", "battle HUD button registered")
check(type(initProbeArg) == "boolean" and initProbeArg == true,
    "battle init forces boolean true (got " .. type(initProbeArg) .. ")")
check(type(capturedLobbyGas) == "function", "lobby gas button registered")
check(type(capturedBattleGas) == "function", "battle gas button registered")
check(type(capturedLobbyRefresh) == "function", "lobby refresh button registered")
check(type(gasText) == "function", "gasText helper injected")
check(type(hudText) == "function", "hudText helper injected")

--===== R36 gas fixture: exact path tree + recursive-only decoy =====
-- Interface/HUD/Main/Top/7/Gas/Percentage is the only accepted terminal path.
local gasSeven = link(top, makeFolder("7"))
local gasFolder = link(gasSeven, makeFolder("Gas"))
local gasLabel = link(gasFolder, makeLabel("42.5%", "Percentage"))
-- Reachable only by a recursive search; the exact walk must never land here.
local decoyRoot = link(top, makeFolder("Backup"))
local decoySeven = link(decoyRoot, makeFolder("7"))
local decoyGas = link(decoySeven, makeFolder("Gas"))
local decoyLabel = link(decoyGas, makeLabel("99.9%", "Percentage"))

local function unlinkChild(parent, child)
    for i = #parent.children, 1, -1 do
        if parent.children[i] == child then table.remove(parent.children, i) end
    end
    child.Parent = nil
end
local function relinkChild(parent, child)
    if child.Parent ~= parent then
        child.Parent = parent
        table.insert(parent.children, child)
    end
end

--===== R36 gas label whose field access throws =====
local function throwingLabel(field, name)
    return setmetatable({
        ClassName = "TextLabel", Name = name,
        IsA = function(self, c) return self.ClassName == c end,
    }, { __index = function(_, k) if k == field then error(field .. " boom") end end })
end

local function buildGui(gasValue, bladesValue, spearsValue)
    local g = makeFolder("PlayerGui")
    local i = link(g, makeFolder("Interface"))
    local h = link(i, makeFolder("HUD"))
    local m = link(h, makeFolder("Main"))
    local t = link(m, makeFolder("Top"))
    local bf = link(t, makeFolder("Blades"))
    link(bf, makeLabel(bladesValue, "Sets"))
    local sf = link(t, makeFolder("Spears"))
    link(sf, makeLabel(spearsValue, "Spears"))
    local seven = link(t, makeFolder("7"))
    local gf = link(seven, makeFolder("Gas"))
    link(gf, makeLabel(gasValue, "Percentage"))
    return g
end

local guiVisible, guiRoot = true, gui
fakePlayer.FindFirstChild = function(_, n)
    if n == "PlayerGui" then return guiVisible and guiRoot or nil end
    return nil
end

local function rebuildGasWorld()
    unlinkChild(top, gasSeven)
    unlinkChild(top, decoyRoot)
    relinkChild(top, gasSeven)
    relinkChild(top, decoyRoot)
    top.children = { bladesFolder, spearsFolder, gasSeven, decoyRoot }
    gasSeven.children = { gasFolder }
    gasFolder.children = { gasLabel }
    decoyRoot.children = { decoySeven }
    decoySeven.children = { decoyGas }
    decoyGas.children = { decoyLabel }
    gasLabel.Parent = gasFolder
    gasLabel.Text = "42.5%"
    gasFolder.Parent = gasSeven
    gasSeven.Parent = top
    decoyLabel.Parent = decoyGas
    decoyLabel.Text = "99.9%"
    decoyGas.Parent = decoySeven
    decoySeven.Parent = decoyRoot
    decoyRoot.Parent = top
    bladesFolder.children = { bladesLabel }
    bladesLabel.Parent = bladesFolder
    bladesLabel.Text = "3/8"
    spearsFolder.children = { spearsLabel }
    spearsLabel.Parent = spearsFolder
    spearsLabel.Text = "2/4"
    gui.children = { interface }
    interface.children = { hud }
    hud.children = { main }
    main.children = { top }
    guiVisible = true
    guiRoot = gui
    stale()
    clearNotes()
end
rebuildGasWorld()

--===== suite: healthy values 3/8 + 2/4 on both entries =====
do
    bladesLabel.Text = "3/8"
    spearsLabel.Text = "2/4"
    stale()
    clearNotes()
    local ok = pcall(capturedLobby)
    check(ok, "lobby callback runs on healthy labels")
    check(string.find(joined(), "刀片 3/8 · 雷枪 2/4", 1, true) ~= nil,
        "lobby notifies blades 3/8 spears 2/4 (got: " .. joined() .. ")")
    clearNotes()
    pcall(capturedBattle)
    check(string.find(joined(), "刀片 3/8 · 雷枪 2/4", 1, true) ~= nil,
        "battle notifies blades 3/8 spears 2/4 (got: " .. joined() .. ")")
end

--===== suite: zero counts (Lua 0 is truthy -> n/n path) =====
do
    bladesLabel.Text = "0/5"
    spearsLabel.Text = "0/0"
    stale()
    clearNotes()
    pcall(capturedLobby)
    check(string.find(joined(), "刀片 0/5 · 雷枪 0/0", 1, true) ~= nil,
        "zero counts reported as n/n (got: " .. joined() .. ")")
end

--===== suite: single integer without slash -> n/n =====
do
    bladesLabel.Text = "7"
    spearsLabel.Text = "9"
    stale()
    clearNotes()
    pcall(capturedLobby)
    check(string.find(joined(), "刀片 7/7 · 雷枪 9/9", 1, true) ~= nil,
        "single integer reported as n/n (got: " .. joined() .. ")")
end

--===== suite: missing label (findLabel returns nil) =====
do
    bladesFolder.children = {}
    bladesLabel.Parent = nil
    stale()
    clearNotes()
    pcall(capturedLobby)
    check(string.find(joined(), "刀片 未读取", 1, true) ~= nil,
        "missing blades label reports 未读取 (got: " .. joined() .. ")")
    bladesFolder.children = { bladesLabel }
    bladesLabel.Parent = bladesFolder
end

--===== suite: label detached from Parent =====
do
    bladesLabel.Parent = nil
    stale()
    clearNotes()
    pcall(capturedLobby)
    check(string.find(joined(), "刀片 未读取", 1, true) ~= nil,
        "detached-parent label reports 未读取 (got: " .. joined() .. ")")
    bladesLabel.Parent = bladesFolder
end

--===== suite: non-numeric string text =====
do
    bladesLabel.Text = "restock"
    stale()
    clearNotes()
    pcall(capturedLobby)
    check(string.find(joined(), "刀片 未读取", 1, true) ~= nil,
        "non-numeric text reports 未读取 (got: " .. joined() .. ")")
    bladesLabel.Text = "3/8"
end

--===== suite: nil text -> 未读取, no crash =====
do
    bladesLabel.Text = nil
    stale()
    clearNotes()
    pcall(capturedLobby)
    check(string.find(joined(), "刀片 未读取", 1, true) ~= nil,
        "nil text reports 未读取 (got: " .. joined() .. ")")
    bladesLabel.Text = "3/8"
end

--===== suite: reading Text throws -> 未读取 via pcall, no crash =====
do
    local errLabel = setmetatable({
        ClassName = "TextLabel", Name = "Sets", Parent = bladesFolder,
        IsA = function(self, c) return self.ClassName == c end,
    }, { __index = function(_, k) if k == "Text" then error("text boom") end end })
    bladesFolder.children = { errLabel }
    stale()
    clearNotes()
    pcall(capturedLobby)
    check(string.find(joined(), "刀片 未读取", 1, true) ~= nil,
        "throwing Text read reports 未读取 (got: " .. joined() .. ")")
    bladesFolder.children = { bladesLabel }
    bladesLabel.Parent = bladesFolder
end

--===== suite: numeric text is engine-coerced, one notification =====
do
    bladesLabel.Text = 123
    stale()
    clearNotes()
    pcall(capturedLobby)
    check(#notifications == 1,
        "numeric text completes exactly one notification (got " .. #notifications .. ")")
    bladesLabel.Text = "3/8"
end

--===== suite: probeHUD cache 0.5 / 1.99 / 2s + change visibility =====
do
    stale()
    app.ProbeHUD(false)
    local first = app.HUD.blades
    check(first == bladesLabel, "direct probe resolves blades label")
    local swapped = makeLabel("5/9", "Sets")
    bladesFolder.children = { swapped }
    swapped.Parent = bladesFolder
    app.HUD.lastProbe = tick() - 0.5
    app.ProbeHUD(false)
    check(app.HUD.blades == first, "0.5s cache hit keeps old label")
    app.HUD.lastProbe = tick() - 1.99
    app.ProbeHUD(false)
    check(app.HUD.blades == first, "1.99s cache hit keeps old label")
    app.HUD.lastProbe = tick() - 2
    app.ProbeHUD(false)
    check(app.HUD.blades == swapped, "2s expiry rescans and exposes new label")
    bladesFolder.children = { bladesLabel }
    bladesLabel.Parent = bladesFolder
    stale()
end

--===== suite: entry button honours probe cache (no forced rescan) =====
do
    stale()
    app.ProbeHUD(false)
    local old = app.HUD.blades
    local swapped = makeLabel("5/9", "Sets")
    bladesFolder.children = { swapped }
    swapped.Parent = bladesFolder
    app.HUD.lastProbe = tick() - 0.5
    clearNotes()
    pcall(capturedLobby)
    check(app.HUD.blades == old,
        "lobby button cache hit keeps old label (no forced rescan)")
    bladesFolder.children = { bladesLabel }
    bladesLabel.Parent = bladesFolder
    stale()
end

--===== suite: destroyed app blocks late clicks (no scan / no notify) =====
do
    stale()
    aliveFlag = false
    local pc = probeCalls
    local n0 = #notifications
    pcall(capturedLobby)
    check(probeCalls == pc, "destroyed: no HUD probe after unload (lobby)")
    check(#notifications == n0, "destroyed: no notify after unload (lobby)")
    pcall(capturedBattle)
    check(probeCalls == pc, "destroyed: no HUD probe after unload (battle)")
    check(#notifications == n0, "destroyed: no notify after unload (battle)")
    aliveFlag = true
end

--===== R36 suite: gas resolves only via the exact 7/Gas/Percentage path =====
do
    rebuildGasWorld()
    app.ProbeHUD(false)
    check(app.HUD.gas == gasLabel, "exact gas path resolves Percentage label")

    rebuildGasWorld()
    unlinkChild(top, gasSeven)
    stale()
    app.ProbeHUD(false)
    check(app.HUD.gas == nil, "missing Top/7 hop rejects gas path")

    rebuildGasWorld()
    gasFolder.children = { makeFolder("Percentage") }
    stale()
    app.ProbeHUD(false)
    check(app.HUD.gas == nil, "wrong terminal type rejects gas path")

    rebuildGasWorld()
    unlinkChild(top, gasSeven)
    stale()
    app.ProbeHUD(false)
    check(top:FindFirstChild("Percentage", true) == decoyLabel,
        "decoy is reachable only by a recursive search")
    check(app.HUD.gas == nil, "gas exact path rejects decoy")

    rebuildGasWorld()
    gasFolder.children = { throwingLabel("Text", "Percentage") }
    local t = throwingLabel("Text", "Percentage")
    t.Parent = gasFolder
    gasFolder.children = { t }
    stale()
    clearNotes()
    local ok = pcall(capturedLobbyGas)
    check(ok, "gas button survives throwing Text")
    check(string.find(joined(), "燃气: 未读取", 1, true) ~= nil,
        "throwing gas Text reports unread")

    rebuildGasWorld()
    local p = throwingLabel("Parent", "Percentage")
    gasFolder.children = { p }
    stale()
    clearNotes()
    ok = pcall(capturedLobbyGas)
    check(ok, "gas button survives throwing Parent")
    check(string.find(joined(), "燃气: 未读取", 1, true) ~= nil,
        "throwing gas Parent reports unread")
end

--===== R36 suite: gas accepts 0/100/42.5/legal blanks, rejects everything else =====
do
    local goodCases = {
        { "0", "0.0%" }, { "100", "100.0%" }, { "42.5", "42.5%" },
        { " 42.5 ", "42.5%" }, { " 42.5 %", "42.5%" }, { "\t42.5%\n", "42.5%" },
        { "0.0", "0.0%" }, { "100.00", "100.0%" },
    }
    for _, case in ipairs(goodCases) do
        rebuildGasWorld()
        gasLabel.Text = case[1]
        clearNotes()
        local ok = pcall(capturedLobbyGas)
        check(ok, "gas button survives valid value " .. case[1])
        check(string.find(joined(), "燃气: " .. case[2], 1, true) ~= nil,
            "gas accepts valid value " .. case[1] .. " (got: " .. joined() .. ")")
        rebuildGasWorld()
        gasLabel.Text = case[1]
        clearNotes()
        ok = pcall(capturedBattleGas)
        check(ok, "battle gas button survives valid value " .. case[1])
        check(string.find(joined(), "燃气: " .. case[2], 1, true) ~= nil,
            "battle gas accepts valid value " .. case[1] .. " (got: " .. joined() .. ")")
    end

    local badValues = { "-5", "150", "-0.5", "100.5", "42.5abc", "abc42.5%",
        "42.5 %x", "", "%", "42.", ".5", "+42", "1e3", "0x10", "1/2", "42,5",
        "NaN", "inf", "nan", "   ", "12 34", "42.5.5", "..", "--5", "5-", "1.2.3" }
    local rangeKeywords = { ["-5"] = true, ["150"] = true, ["-0.5"] = true, ["100.5"] = true }
    for _, v in ipairs(badValues) do
        rebuildGasWorld()
        gasLabel.Text = v
        clearNotes()
        local ok = pcall(capturedLobbyGas)
        check(ok, "gas button survives invalid value " .. tostring(v))
        local kw = rangeKeywords[v] and "gas rejects outside range"
            or "gas rejects malformed text"
        if rangeKeywords[v] then
            check(realPercent(gasLabel) == nil, kw .. " helper for " .. v)
        end
        check(string.find(joined(), "燃气: 未读取", 1, true) ~= nil,
            kw .. " for " .. tostring(v) .. " (got: " .. joined() .. ")")
    end

    local nonStrings = { [1] = nil, [2] = 42.5, [3] = 0 / 0, [4] = math.huge,
        [5] = -math.huge, [6] = true, [7] = setmetatable({}, {}) }
    for i = 1, 7 do
        rebuildGasWorld()
        gasLabel.Text = nonStrings[i]
        clearNotes()
        local ok = pcall(capturedLobbyGas)
        check(ok, "gas button survives non-string value " .. tostring(i))
        check(string.find(joined(), "燃气: 未读取", 1, true) ~= nil,
            "gas rejects non-string value " .. tostring(i) .. " (got: " .. joined() .. ")")
    end
end

--===== R36 suite: refresh entry reports blades/spears/gas together =====
do
    rebuildGasWorld()
    clearNotes()
    local ok = pcall(capturedLobbyRefresh)
    check(ok, "refresh button runs")
    check(string.find(joined(), "刀片 3/8", 1, true) ~= nil,
        "refresh reports blades (got: " .. joined() .. ")")
    check(string.find(joined(), "雷枪 2/4", 1, true) ~= nil,
        "refresh reports spears (got: " .. joined() .. ")")
    check(string.find(joined(), "燃气 42.5%", 1, true) ~= nil,
        "refresh reports gas (got: " .. joined() .. ")")
end

--===== R36 suite: HUD swap, missing PlayerGui, 2s cache vs forced rescan =====
do
    rebuildGasWorld()
    app.ProbeHUD(false)
    local first = app.HUD.gas
    local swapped = makeLabel("77.7%", "Percentage")
    swapped.Parent = gasFolder
    gasFolder.children = { swapped }
    app.HUD.lastProbe = tick() - 0.5
    clearNotes()
    pcall(capturedLobbyGas)
    check(app.HUD.gas == first, "gas button cache hit keeps old label")
    check(string.find(joined(), "燃气: 42.5%", 1, true) ~= nil,
        "gas button reports cached value (got: " .. joined() .. ")")

    rebuildGasWorld()
    local swapped2 = makeLabel("88.8%", "Percentage")
    swapped2.Parent = gasFolder
    gasFolder.children = { swapped2 }
    app.HUD.lastProbe = tick() - 0.5
    clearNotes()
    pcall(capturedLobbyRefresh)
    check(app.HUD.gas == swapped2, "refresh button forces rescan and exposes new gas label")
    check(string.find(joined(), "燃气 88.8%", 1, true) ~= nil,
        "refresh reports forced gas value (got: " .. joined() .. ")")

    rebuildGasWorld()
    guiRoot = buildGui("77.7%", "1/2", "3/4")
    stale()
    clearNotes()
    pcall(capturedLobbyRefresh)
    check(string.find(joined(), "刀片 1/2", 1, true) ~= nil,
        "replaced HUD resolves new blades (got: " .. joined() .. ")")
    check(string.find(joined(), "雷枪 3/4", 1, true) ~= nil,
        "replaced HUD resolves new spears (got: " .. joined() .. ")")
    check(string.find(joined(), "燃气 77.7%", 1, true) ~= nil,
        "replaced HUD resolves new gas (got: " .. joined() .. ")")

    -- No PlayerGui at all: all three cached references must be dropped, not just gas.
    rebuildGasWorld()
    app.ProbeHUD(false)
    check(app.HUD.blades == bladesLabel, "blades cached before gui loss")
    check(app.HUD.spears == spearsLabel, "spears cached before gui loss")
    check(app.HUD.gas == gasLabel, "gas cached before gui loss")
    guiVisible = false
    stale()
    app.ProbeHUD(false)
    check(app.HUD.gas == nil, "no PlayerGui: gas reference cleared")
    check(app.HUD.blades == nil, "no PlayerGui: blades reference cleared")
    check(app.HUD.spears == nil, "no PlayerGui: spears reference cleared")
    clearNotes()
    pcall(capturedLobbyRefresh)
    check(string.find(joined(), "刀片 未读取", 1, true) ~= nil,
        "no PlayerGui: refresh reports blades unread (got: " .. joined() .. ")")
    check(string.find(joined(), "雷枪 未读取", 1, true) ~= nil,
        "no PlayerGui: refresh reports spears unread (got: " .. joined() .. ")")
    check(string.find(joined(), "燃气 未读取", 1, true) ~= nil,
        "no PlayerGui: refresh reports gas unread (got: " .. joined() .. ")")
    clearNotes()
    pcall(capturedLobbyGas)
    check(string.find(joined(), "燃气: 未读取", 1, true) ~= nil,
        "no PlayerGui: gas entry reports unread (got: " .. joined() .. ")")
    clearNotes()
    pcall(capturedBattleGas)
    check(string.find(joined(), "燃气: 未读取", 1, true) ~= nil,
        "no PlayerGui: battle gas entry reports unread (got: " .. joined() .. ")")
    guiVisible = true
end

--===== R36 suite: gas entries honour the Alive gate before and during a read =====
do
    rebuildGasWorld()
    aliveFlag = false
    local pc, rc = probeCalls, percentCalls
    clearNotes()
    pcall(capturedLobbyGas)
    check(probeCalls == pc, "gas destroyed: no HUD probe after unload (lobby)")
    check(percentCalls == rc, "gas destroyed: no percent read after unload (lobby)")
    check(#notifications == 0, "gas destroyed: no notify after unload (lobby)")
    pcall(capturedBattleGas)
    check(probeCalls == pc, "gas destroyed: no HUD probe after unload (battle)")
    check(percentCalls == rc, "gas destroyed: no percent read after unload (battle)")
    check(#notifications == 0, "gas destroyed: no notify after unload (battle)")
    pcall(capturedLobbyRefresh)
    check(probeCalls == pc, "gas destroyed: no HUD probe on refresh (lobby)")
    check(#notifications == 0, "gas destroyed: no notify on refresh (lobby)")
    aliveFlag = true

    for _, entry in ipairs({
        { capturedLobbyGas, "lobby" },
        { capturedBattleGas, "battle" },
        { capturedLobbyRefresh, "refresh" },
    }) do
        aliveFlag = true
        percentDeactivate = true
        rebuildGasWorld()
        local before = percentCalls
        check(pcall(entry[1]), "gas mid-read deactivate: callback completes (" .. entry[2] .. ")")
        check(percentCalls == before + 1, "gas mid-read deactivate: percent reached (" .. entry[2] .. ")")
        check(not aliveFlag, "gas mid-read deactivate: actually deactivated (" .. entry[2] .. ")")
        check(#notifications == 0, "gas mid-read deactivate: no notify (" .. entry[2] .. ")")
    end
    percentDeactivate = false
    aliveFlag = true

    rebuildGasWorld()
    clearNotes()
    pcall(capturedLobbyGas)
    check(string.find(joined(), "燃气: 42.5%", 1, true) ~= nil,
        "gas works again after re-enable (got: " .. joined() .. ")")
end

if failures == 0 then
    print("R18_RESULT GREEN")
else
    print("R18_RESULT RED " .. failures)
end
