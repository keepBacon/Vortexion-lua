-- Visual budget contract snapshot regression (R14) for WindAdapter:GetVisualInterval.
-- Fixture-only: the real Adapter factory runs against tripwire stubs that throw on any
-- control read, GUI creation, or scheduling. Nothing here runs on a device; reported time
-- is fixture wall time, not phone FPS. The adapter source may change between runs, so this
-- is snapshot regression evidence, not frozen acceptance.
local createBridge = __FACTORY__

local assertions = 0
local function check(ok, message)
    assertions += 1
    if not ok then error(message, 2) end
end

-- Independent oracle: the documented contract re-derived from semantics, not copied calls.
-- Cap the non-critical visual refresh at VisualHz, clamp Hz into [5, 60] with half-up
-- rounding, treat non-finite/non-numeric Hz as 60, sanitize a bad base to 0, and never
-- accelerate the caller's own cadence (max with the base).
local ORACLE_HZ_MIN, ORACLE_HZ_MAX = 5, 60
local function oracleClampHz(value)
    local hz = tonumber(value)
    if hz == nil or hz ~= hz or hz == math.huge or hz == -math.huge then return ORACLE_HZ_MAX end
    hz = math.floor(hz + 0.5)
    if hz < ORACLE_HZ_MIN then return ORACLE_HZ_MIN end
    if hz > ORACLE_HZ_MAX then return ORACLE_HZ_MAX end
    return hz
end
local function oracleSanitizeBase(value)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge or n < 0 then return 0 end
    return n
end
local function oracleInterval(hz, base)
    return math.max(oracleSanitizeBase(base), 1 / oracleClampHz(hz))
end

-- Scheduling tripwire: the visual budget path must never queue deferred or spawned work.
-- The counter increments before the throw, so even a production pcall(task.spawn, ...)
-- that swallows the sentinel error is still caught by the end-of-run zero assertion.
local scheduleCalls = {defer = 0, spawn = 0, wait = 0}
local function forbiddenSchedule(name)
    return function()
        scheduleCalls[name] += 1
        error("visual budget path must not schedule via task." .. name, 2)
    end
end
task = {defer = forbiddenSchedule("defer"), spawn = forbiddenSchedule("spawn"), wait = forbiddenSchedule("wait")}

-- Minimal legal WindUI stub: CreateWindow must exist as a function so the factory's own
-- precondition assert passes, but invoking it is a contract violation and is counted.
-- ScreenGui is an inert reference marker; the factory only stores the reference.
local createWindowCalls = 0
local screenGuiMarker = {__fixture = "ScreenGui"}
local wind = {
    ScreenGui = screenGuiMarker,
    CreateWindow = function()
        createWindowCalls += 1
        error("visual budget path must not create a WindUI window", 2)
    end,
}

-- Only the two services the factory reads at construction are legal; any other
-- acquisition trips. Every call is counted, but the measured extra counter only runs once
-- the getter is armed (after each legal construction baseline), so the factory's own two
-- reads never trip the end-of-run zero assertion while a swallowed sentinel error still does.
local inputService = {TouchEnabled = true}
local world = {CurrentCamera = nil}
local getServiceCalls = 0
local getServiceExtra = 0
local getServiceArmed = false
game = {
    GameId = 0, PlaceId = 0, JobId = "",
    GetService = function(_, name)
        getServiceCalls += 1
        if getServiceArmed then
            getServiceExtra += 1
        end
        if name == "UserInputService" then return inputService end
        if name == "Workspace" then return world end
        error("visual budget path must not acquire service: " .. tostring(name), 2)
    end,
}
workspace = world

local env = {}
local fixtureStart = os.clock()

-- Phase 1: the real factory constructs a bridge without creating any GUI.
local bridge = createBridge(wind, {Name = "VisualBudgetFixture", Env = env})
check(type(bridge) == "table", "factory returns the bridge table")
check(bridge.Active == true, "bridge starts active")
check(createWindowCalls == 0, "factory construction must not create a window")
check(bridge.Window() == nil, "no window handle exists before CreateWindow")
check(bridge.GUI == screenGuiMarker, "bridge only references the ScreenGui stub")
check(env.VortexionWindBridge == bridge, "bridge published to the fixture env")
check(bridge.VisualHz == 15, "touch fixture default tier is 15Hz")
print("phase1 factory-no-gui PASS")

-- Arm the service-getter measurement window: the construction baseline (the factory's two
-- legal reads) is complete, so any later acquisition is a violation even if swallowed.
getServiceArmed = true

-- Phase 2: default tiers and the three perf tiers 5/15/60.
inputService.TouchEnabled = false
getServiceArmed = false -- legal construction baseline for the second factory instance
local desktopBridge = createBridge(wind, {Name = "DesktopVisualBudgetFixture", Env = {}})
getServiceArmed = true
check(desktopBridge.VisualHz == 60, "non-touch fixture default tier is 60Hz")
check(desktopBridge:GetVisualInterval(0) == 1 / 60, "desktop default interval")
desktopBridge:Destroy()
check(createWindowCalls == 0, "desktop construction creates no GUI")
inputService.TouchEnabled = true
bridge.VisualHz = 5
check(bridge:GetVisualInterval(0) == 1 / 5, "5Hz tier caps the interval at 0.2s")
check(bridge:GetVisualInterval(1) == 1, "a base above the cap is never accelerated")
bridge.VisualHz = 15
check(bridge:GetVisualInterval(0) == 1 / 15, "15Hz tier caps the interval at 1/15s")
bridge.VisualHz = 60
check(bridge:GetVisualInterval(0) == 1 / 60, "60Hz tier caps the interval at 1/60s")
check(bridge:GetVisualInterval(0.5) == 0.5, "a slower caller cadence survives the 60Hz cap")
print("phase2 tiers-5-15-60 PASS")

-- Phase 3: custom Hz values, out-of-range clamping, rounding, and bad inputs.
local boundCases = {
    {hz = 20, expected = 20},
    {hz = 24, expected = 24},
    {hz = 1, expected = 5},
    {hz = 3, expected = 5},
    {hz = 4.6, expected = 5},
    {hz = 100, expected = 60},
    {hz = 59.6, expected = 60},
    {hz = 0 / 0, expected = 60},
    {hz = math.huge, expected = 60},
    {hz = -math.huge, expected = 60},
    {hz = "24", expected = 24},
    {hz = "abc", expected = 60},
    {hz = true, expected = 60},
    {hz = false, expected = 60},
    {hz = {}, expected = 60},
    {hz = nil, expected = 60},
}
for index, case in ipairs(boundCases) do
    bridge.VisualHz = case.hz
    local actual = bridge:GetVisualInterval(0)
    check(actual == 1 / case.expected, string.format("bound case %d (hz=%s) expected 1/%s got %s", index, tostring(case.hz), tostring(case.expected), tostring(actual)))
end
print("phase3 custom-bounds PASS")

-- Phase 4: base contract for finite, NaN, inf, negative, string, and nil bases.
bridge.VisualHz = 15
local baseCases = {
    {base = 0.5, expected = 0.5},
    {base = 0, expected = 1 / 15},
    {base = 1 / 15, expected = 1 / 15},
    {base = 0.01, expected = 1 / 15},
    {base = 0 / 0, expected = 1 / 15},
    {base = math.huge, expected = 1 / 15},
    {base = -math.huge, expected = 1 / 15},
    {base = -1, expected = 1 / 15},
    {base = -0.0001, expected = 1 / 15},
    {base = "0.5", expected = 0.5},
    {base = "0", expected = 1 / 15},
    {base = "bad", expected = 1 / 15},
    {base = true, expected = 1 / 15},
    {base = false, expected = 1 / 15},
    {base = {}, expected = 1 / 15},
}
for index, case in ipairs(baseCases) do
    local actual = bridge:GetVisualInterval(case.base)
    check(actual == case.expected, string.format("base case %d (base=%s) expected %s got %s", index, tostring(case.base), tostring(case.expected), tostring(actual)))
end
check(bridge:GetVisualInterval(nil) == 1 / 15, "explicit nil base uses the cap only")
check(bridge:GetVisualInterval() == 1 / 15, "missing base argument uses the cap only")
print("phase4 base-contract PASS")

-- Phase 5: GetVisualInterval reads bridge.VisualHz, never the option controls.
-- First with sentinel controls that would change the answer if they were read...
bridge.Options = {wind_perf_tier = {Value = "save-power"}, wind_visual_hz = {Value = 5}}
bridge.VisualHz = 60
check(bridge:GetVisualInterval(0) == 1 / 60, "control values must not override bridge.VisualHz")
check(bridge:GetVisualInterval(0.5) == 0.5, "control values must not affect the base path")
-- ...then with an Options table whose every read and write throws.
local poisonHits = 0
bridge.Options = setmetatable({}, {
    __index = function(_, key)
        poisonHits += 1
        error("GetVisualInterval must not read Options." .. tostring(key), 2)
    end,
    __newindex = function(_, key)
        poisonHits += 1
        error("GetVisualInterval must not write Options." .. tostring(key), 2)
    end,
})
check(bridge:GetVisualInterval(0) == 1 / 60, "poisoned Options still computes the same interval")
check(bridge:GetVisualInterval(0.5) == 0.5, "poisoned Options still honors the base")
check(poisonHits == 0, "no Options access happened during computation")
print("phase5 controls-not-read PASS")

-- Phase 6: at least 150000 consistency assertions against the independent oracle.
-- Every call also runs under the poisoned-Options and forbidden-scheduling tripwires.
local hzSamples = {5, 15, 60, 1, 100, 17, 59.6, 3.4, -8, 0 / 0, math.huge, -math.huge, "20", "abc", true, {}, 24.5}
local HZ_COUNT = 17
local baseSamples = {0, 0.2, 1 / 15, 0.05, 1, 2.5, 0.0167, 100, 0 / 0, math.huge, -math.huge, -1, -0.001, "0.5", "0", "bad", true, false, {}}
local BASE_COUNT = 19
local LOOP = 150000
for i = 1, LOOP do
    local hz = hzSamples[(i - 1) % HZ_COUNT + 1]
    local base = baseSamples[(i - 1) // HZ_COUNT % BASE_COUNT + 1]
    bridge.VisualHz = hz
    local expected = oracleInterval(hz, base)
    local actual = bridge:GetVisualInterval(base)
    if actual ~= expected then
        error(string.format("consistency mismatch i=%d hz=%s base=%s expected=%s actual=%s", i, tostring(hz), tostring(base), tostring(expected), tostring(actual)), 2)
    end
    if bridge:GetVisualInterval(base) ~= actual then
        error("repeat call drifted at i=" .. tostring(i), 2)
    end
    assertions += 2
end
-- Zero-access assertion after the loop. The phase-5 spot check above only runs at VisualHz=60,
-- so a pcall-swallowed poisoned read hidden behind an hz==5 branch stays green there and only
-- accumulates here, where hzSamples includes 5.
check(poisonHits == 0, string.format("no Options access happened across the consistency loop (hits=%d)", poisonHits))
check(assertions >= 150000, "at least 150000 consistency assertions are required")
print("phase6 consistency-150000 PASS")

-- Phase 7: destruction and the post-destroy computation contract.
check(bridge.Active == true, "bridge still active before destroy")
bridge:Destroy()
check(bridge.Active == false, "destroy deactivates the bridge")
check(env.VortexionWindBridge == nil, "destroy unpublishes the bridge")
bridge:Destroy()
check(bridge.Active == false, "a second destroy is a no-op")
bridge.VisualHz = 5
check(bridge:GetVisualInterval(0) == 1 / 5, "post-destroy 5Hz contract")
check(bridge:GetVisualInterval(1) == 1, "post-destroy base path")
bridge.VisualHz = 60
check(bridge:GetVisualInterval(0) == 1 / 60, "post-destroy 60Hz contract")
check(bridge:GetVisualInterval(0 / 0) == 1 / 60, "post-destroy NaN base")
check(bridge:GetVisualInterval(-1) == 1 / 60, "post-destroy negative base")
check(createWindowCalls == 0, "no GUI was created across the whole run")
-- Zero-delta assertions: a production path that pcall-wraps the tripwire errors and keeps
-- running still lands here with a nonzero counter and fails.
local scheduleTotal = scheduleCalls.defer + scheduleCalls.spawn + scheduleCalls.wait
check(scheduleTotal == 0, string.format("visual budget path must not schedule work (defer=%d spawn=%d wait=%d)", scheduleCalls.defer, scheduleCalls.spawn, scheduleCalls.wait))
check(getServiceExtra == 0, string.format("visual budget path must not acquire services after the construction baseline (extra=%d of %d)", getServiceExtra, getServiceCalls))
-- Zero-access assertion after destroy: the final trap for a swallowed poisoned read that only
-- fires on the 5Hz tier exercised by the post-destroy checks.
check(poisonHits == 0, string.format("no Options access happened across the whole run (hits=%d)", poisonHits))
print("phase7 post-destroy PASS")

local elapsedMs = math.floor((os.clock() - fixtureStart) * 1000 + 0.5)
print(string.format("wind visual budget r14 PASS assertions=%d fixtureElapsedMs=%d createWindowCalls=%d scheduleCalls=%d getServiceExtra=%d", assertions, elapsedMs, createWindowCalls, scheduleTotal, getServiceExtra))
