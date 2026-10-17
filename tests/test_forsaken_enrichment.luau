local _G = {}
local assertions = 0
local function check(value, message)
    assertions += 1
    assert(value, message)
end
local function equal(actual, expected, message)
    check(actual == expected, message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end
local function signal()
    local s = {connections = {}}
    function s:Connect(fn)
        local c = {Connected = true, fn = fn}
        function c:Disconnect() self.Connected = false end
        function c:Fire(...) if self.Connected then self.fn(...) end end
        table.insert(self.connections, c)
        return c
    end
    function s:Fire(...)
        local list = table.clone(self.connections)
        for _, c in ipairs(list) do c:Fire(...) end
    end
    function s:Count()
        local n = 0
        for _, c in ipairs(self.connections) do if c.Connected then n += 1 end end
        return n
    end
    return s
end
local vectorMT = {}
local function vector(x, y, z) return setmetatable({X = x or 0, Y = y or 0, Z = z or 0}, vectorMT) end
vectorMT.__add = function(a, b) return vector(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMT.__sub = function(a, b) return vector(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vectorMT.__mul = function(a, b) return vector(a.X * b, a.Y * b, a.Z * b) end
vectorMT.__div = function(a, b) return vector(a.X / b, a.Y / b, a.Z / b) end
vectorMT.__index = function(a, key)
    if key == 'Magnitude' then return math.sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) end
    if key == 'Unit' then return a / a.Magnitude end
    if key == 'Dot' then return function(self, b) return self.X*b.X + self.Y*b.Y + self.Z*b.Z end end
end
Vector3 = {new = vector, zero = vector(0, 0, 0)}
local originalTypeof = typeof
typeof = function(v) if getmetatable(v) == vectorMT then return 'Vector3' end; return originalTypeof(v) end
local function cf(pos, target)
    local t = {Position = pos, LookVector = target and (target - pos).Unit or vector(0, 0, -1)}
    function t:Lerp(other, alpha) self.lastAlpha = alpha; return other end
    return t
end
CFrame = {new = function(pos) return cf(pos) end, lookAt = cf}
Color3 = {new = function(r, g, b) return {r, g, b} end, fromRGB = function(r, g, b) return {r/255, g/255, b/255} end}
Enum = {KeyCode = {Q = 'Q', LeftAlt = 'LeftAlt'}, UserInputType = {MouseButton2 = 'MouseButton2', Touch = 'Touch'}, RaycastFilterType = {Exclude = 'Exclude'}}
RaycastParams = {new = function() return {} end}
OverlapParams = {new = function() return {} end}
local created, loadCount, stopCount = {}, 0, 0
local methods = {}
local instanceMT = {}
instanceMT.__index = function(t, k)
    if k == 'Parent' then return rawget(t, '_parent') end
    if k == 'Position' and t._attrs.CFrame then return t._attrs.CFrame.Position end
    return methods[k] or t._attrs[k]
end
instanceMT.__newindex = function(t, k, v)
    if k == 'Parent' then
        local old = rawget(t, '_parent')
        if old then for i, child in ipairs(old._children) do if child == t then table.remove(old._children, i); break end end end
        rawset(t, '_parent', v)
        if v then table.insert(v._children, t) end
    else t._attrs[k] = v end
end
function methods:IsA(class)
    return self.ClassName == class or (class == 'BasePart' and self.ClassName == 'Part')
        or (class == 'PostEffect' and (self.ClassName == 'BloomEffect' or self.ClassName == 'BlurEffect'))
end
function methods:FindFirstChild(name, recursive)
    for _, child in ipairs(self._children) do
        if child.Name == name then return child end
        if recursive then local found = child:FindFirstChild(name, true); if found then return found end end
    end
end
function methods:FindFirstChildOfClass(class)
    for _, child in ipairs(self._children) do if child:IsA(class) then return child end end
end
function methods:GetChildren() return table.clone(self._children) end
function methods:IsDescendantOf(parent)
    local current = self.Parent
    while current do if current == parent then return true end; current = current.Parent end
    return false
end
function methods:Destroy()
    self.Destroyed = true
    self.Parent = nil
    for _, child in ipairs(self:GetChildren()) do child:Destroy() end
end
function methods:Move(v) self.LastMove = v end
function methods:GetScale()
    assert(self:IsA('Model'), 'GetScale is a Model API')
    return self.LastScale or 1
end
function methods:ScaleTo(v)
    assert(self:IsA('Model'), 'ScaleTo is a Model API')
    self.LastScale = v
end
function methods:Clone()
    local copy = setmetatable({_attrs = {}, _children = {}}, instanceMT)
    for k, v in pairs(self._attrs) do copy._attrs[k] = v end
    for _, child in ipairs(self._children) do child:Clone().Parent = copy end
    return copy
end
function methods:LoadAnimation(animation)
    loadCount += 1
    self.LastId = animation.AnimationId
    if self.FailLoad then error('injected load error') end
    local t = {Stopped = signal(), Playing = false, Destroyed = false}
    function t:Play() self.Playing = true end
    function t:Stop() stopCount += 1; self.Playing = false; self.Stopped:Fire() end
    function t:Destroy() self.Destroyed = true end
    self.LastTrack = t
    return t
end
local function inst(class, name, parent)
    local t = setmetatable({_attrs = {ClassName = class, Name = name or class}, _children = {}}, instanceMT)
    t.Parent = parent
    if class == 'Part' then t.CFrame = cf(vector()); t.Size = vector(2, 2, 1); t.CanCollide = false end
    if class == 'Humanoid' then t.WalkSpeed = 0; t.JumpPower = 0; t.AutoRotate = false; t.Health = 100 end
    if class == 'Camera' then t.CFrame = cf(vector(0, 4, 0)); t.FieldOfView = 70 end
    if class == 'BloomEffect' or class == 'BlurEffect' then t.Enabled = true end
    table.insert(created, t)
    return t
end
Instance = {new = function(class) return inst(class) end}
local now, queueSpawn, pending = 0, false, {}
task = {
    spawn = function(fn) if queueSpawn then table.insert(pending, fn) else fn() end end,
    wait = function() error('frame callback yielded') end,
    delay = function() error('unmanaged delayed job') end,
}
getconnections = function(s) return s and s.connections or {} end
local workspace = inst('Workspace')
workspace.FallenPartsDestroyHeight = -500
workspace.CurrentCamera = inst('Camera', 'Camera', workspace)
workspace.Overlap = {}
workspace.Wall = nil
workspace.Grounded = true
local ground = inst('Part', 'Ground', workspace); ground.CanCollide = true
function workspace:GetPartBoundsInBox() return self.Overlap end
function workspace:Raycast(_, direction)
    if direction.X == 0 and direction.Z == 0 and direction.Y < 0 then return self.Grounded and {Instance = ground} or nil end
    return self.Wall and {Instance = self.Wall} or nil
end
local playersFolder = inst('Folder', 'Players', workspace)
local killers = inst('Folder', 'Killers', playersFolder)
local survivors = inst('Folder', 'Survivors', playersFolder)
local localPlayer = inst('Player', 'LocalPlayer')
localPlayer.CharacterAdded = signal()
localPlayer.PlayerGui = inst('PlayerGui', 'PlayerGui', localPlayer)
local function character(name, z, parent, health)
    local c = inst('Model', name, parent)
    local h = inst('Humanoid', 'Humanoid', c); h.Health = health or 100
    local a = inst('Animator', 'Animator', h)
    local root = inst('Part', 'HumanoidRootPart', c); root.CFrame = cf(vector(0, 4, z))
    return c, h, root, a
end
local char, hum, root, animator = character('Elliot', 0, survivors)
localPlayer.Character = char
local far, farHum, farRoot = character('Far', -20, killers)
local near, nearHum, nearRoot = character('Near', -8, killers)
local hurt, hurtHum, hurtRoot = character('Hurt', -15, survivors, 30)
local healthy = character('Healthy', -3, survivors, 90)
local main = inst('Frame', 'MainUI', localPlayer.PlayerGui)
local abilityContainer = inst('Frame', 'AbilityContainer', main)
local dagger = inst('TextButton', 'Dagger', abilityContainer)
dagger.Activated, dagger.MouseButton1Click = signal(), signal()
local cooldown = inst('TextLabel', 'CooldownTime', dagger); cooldown.Text = ''
local attacks = 0
dagger.Activated:Connect(function() attacks += 1 end)
local qcd = inst('NumberValue', 'QCooldown', char); qcd.Value = 0
local lighting = inst('Lighting')
lighting.Brightness, lighting.Ambient, lighting.OutdoorAmbient = 1, 'ambient', 'outdoor'
lighting.GlobalShadows, lighting.ClockTime, lighting.GeographicLatitude = true, 0, 0
lighting.FogEnd, lighting.FogStart, lighting.ExposureCompensation = 100, 12, 0
local bloom = inst('BloomEffect', 'Bloom', lighting)
local disabledEffect = inst('BlurEffect', 'Disabled', lighting); disabledEffect.Enabled = false
local coreGui, storage = inst('CoreGui'), inst('ReplicatedStorage')
-- Local Forsaken character appearance fixtures: Highlight / Life1 / Life2 / ExtraModels / local skin assets.
local charHighlight = inst('Highlight', 'Highlight', char)
charHighlight.FillTransparency, charHighlight.OutlineTransparency, charHighlight.Enabled = 0.3, 0.5, true
local life1 = inst('Model', 'Life1', char)
local life2 = inst('Model', 'Life2', char)
local life1Head = inst('Part', 'Head', life1)
local life2Head = inst('Part', 'Head', life2)
life1Head.Transparency, life2Head.Transparency = 0, 0
local extraModels = inst('Model', 'ExtraModels', char)
inst('Part', 'ExtraPart', extraModels)
local skinAssets = inst('Folder', 'Assets', storage)
local skinSkins = inst('Folder', 'Skins', skinAssets)
local skinSurvivors = inst('Folder', 'Survivors', skinSkins)
local elliotSkins = inst('Folder', 'Elliot', skinSurvivors)
local skinSource = inst('Model', 'Milestone100TwoTime', elliotSkins)
local skinHead = inst('Part', 'Head', skinSource)
local keyEvents = {}
local vim = {}
function vim:SendKeyEvent(down, key) table.insert(keyEvents, {down = down, key = key}) end
local services = {Lighting = lighting, CoreGui = coreGui, ReplicatedStorage = storage, VirtualInputManager = vim}
game = {GetService = function(_, name) assert(services[name], 'missing service ' .. name); return services[name] end}
local runService = {Heartbeat = signal(), RenderStepped = signal()}
local uis = {InputBegan = signal(), InputEnded = signal(), WindowFocusReleased = signal(), Typing = false}
function uis:GetFocusedTextBox() return self.Typing and {} or nil end
local fluent = {Options = {}, destroyCallbacks = {}, notifications = {}}
function fluent:Notify(cfg) table.insert(self.notifications, cfg) end
function fluent:OnDestroy(fn) table.insert(self.destroyCallbacks, fn) end
local tab = {buttons = {}, rows = {}}
local function option(id, cfg)
    check(not fluent.Options[id], 'duplicate option ' .. id)
    local o = {Value = cfg.Default, Callback = cfg.Callback}
    function o:SetValue(v) self.Value = v; if self.Callback then self.Callback(v) end end
    fluent.Options[id] = o
    return o
end
function tab:AddToggle(id, cfg) return option(id, cfg) end
function tab:AddSlider(id, cfg) return option(id, cfg) end
function tab:AddInput(id, cfg) return option(id, cfg) end
function tab:AddDropdown(id, cfg) return option(id, cfg) end
function tab:AddButton(cfg) table.insert(self.buttons, cfg); return cfg end
function tab:AddParagraph(cfg)
    local row = {Content = cfg.Content}
    function row:SetDesc(v) self.Content = v end
    table.insert(self.rows, row)
    return row
end
local tabs = {Combat = tab, Visual = tab, Survival = tab, Guest = tab, System = tab, Stats = tab}
local tracked = {}
local requires = 0
local ctx = {LocalPlayer = localPlayer, RunService = runService, Workspace = workspace, UserInputService = uis, Tabs = tabs, Fluent = fluent, sessionEnv = {VortexionSessionId = 1}, thisSessionId = 1, clock = function() return now end, track = function(c) table.insert(tracked, c); return c end, requireModule = function(source) requires += 1; return source.Module end}
local factory = __FACTORY__
local api = factory(ctx)
local function heartbeat(t, dt) now = t; runService.Heartbeat:Fire(dt or 0.016) end
local function render(t, dt) now = t; runService.RenderStepped:Fire(dt or 0.016) end
local function change(id, v) local o = fluent.Options[id]; check(o ~= nil, 'missing option ' .. id); o:SetValue(v) end
if api.startBackstab then
    equal(api.safeUnit(vector(), 'fallback'), 'fallback', 'zero unit guard')
    check(api.isBehindTarget(root, nearRoot), 'behind geometry')
    nearRoot.CFrame = root.CFrame; check(not api.isBehindTarget(root, nearRoot), 'coincident geometry'); nearRoot.CFrame = cf(vector(0, 4, -8))
    equal(api.selectTarget(false), nearRoot, 'nearest killer instead of first')
    equal(api.selectTarget(true), hurtRoot, 'injured ally excludes self and healthy')
    hum.Health = 0; equal(api.selectTarget(false), nil, 'dead local character excluded'); hum.Health = 100
    workspace.Wall = ground; equal(api.selectTarget(false), nil, 'wall check blocks target'); workspace.Wall = nil
    nearHum.Health = 0; equal(api.selectTarget(false), farRoot, 'dead target excluded'); nearHum.Health = 100
    check(api.cooldownReady(qcd), 'zero numeric cooldown ready'); qcd.Value = 3; check(not api.cooldownReady(qcd), 'positive cooldown blocked'); qcd.Value = 0
    check(not api.cooldownReady(nil), 'unknown cooldown blocked')
    cooldown.Text = '12'; check(not api.cooldownReady(cooldown), 'text cooldown blocked'); cooldown.Text = ''; check(api.cooldownReady(cooldown), 'empty known cooldown ready')
    api.aimStateSave(hum); hum.WalkSpeed = 30; hum.JumpPower = 50; hum.AutoRotate = true
    local other = inst('Humanoid'); other.WalkSpeed = 17; api.aimStateRestore(other); equal(other.WalkSpeed, 17, 'restore cannot cross humanoid')
    api.aimStateRestore(hum); equal(hum.WalkSpeed, 0, 'restore zero speed'); equal(hum.JumpPower, 0, 'restore zero jump'); equal(hum.AutoRotate, false, 'restore false rotate')
    api.startBackstab(12); api.startBackstab(12); equal(runService.Heartbeat:Count(), 1, 'backstab singleton')
    for _ = 1, 100 do heartbeat(0) end
    equal(attacks, 1, '100 same-time frames only one backstab, no yield')
    heartbeat(0.2); equal(attacks, 2, 'backstab interval continues'); api.stopBackstab(); equal(runService.Heartbeat:Count(), 0, 'backstab disabled disconnects')
    change('CombatAbilityReady', true); cooldown.Text = '2'; api.startBackstab(12); heartbeat(0.3); equal(attacks, 2, 'readiness gate used by backstab'); cooldown.Text = ''; heartbeat(0.5); equal(attacks, 3, 'readiness resumes'); api.stopBackstab()
    change('CombatHoldMode', true); api.setAssist('Aim', true); local before = workspace.CurrentCamera.CFrame
    heartbeat(0.6); equal(workspace.CurrentCamera.CFrame, before, 'hold gates camera')
    local key = {KeyCode = 'LeftAlt', UserInputType = 'Keyboard'}
    uis.InputBegan:Fire(key, true); heartbeat(0.7); equal(workspace.CurrentCamera.CFrame, before, 'processed input ignored')
    uis.InputBegan:Fire(key, false); heartbeat(0.8); check(workspace.CurrentCamera.CFrame ~= before, 'hold input moves camera')
    uis.Typing = true; uis.InputEnded:Fire(key); before = workspace.CurrentCamera.CFrame; heartbeat(0.9); equal(workspace.CurrentCamera.CFrame, before, 'release works while typing')
    uis.Typing = false; change('CombatTouchHeld', true); heartbeat(1.0); check(workspace.CurrentCamera.CFrame ~= before, 'touch held works')
    uis.WindowFocusReleased:Fire(); before = workspace.CurrentCamera.CFrame; heartbeat(1.1); equal(workspace.CurrentCamera.CFrame, before, 'focus loss releases')
    change('CombatHoldMode', false); api.setAssist('Elliot', true); heartbeat(1.2); equal(workspace.CurrentCamera.CFrame.LookVector.Z < 0, true, 'elliot points toward ally')
    api.setAssist('Elliot', false); api.setAssist('Slash', true); heartbeat(1.4); equal(#keyEvents, 2, 'slash Q down/up')
    heartbeat(1.5); equal(#keyEvents, 2, 'slash throttled'); qcd.Value = 2; heartbeat(2); equal(#keyEvents, 2, 'slash cooldown gate')
    uis.Typing = true; heartbeat(2.3); equal(#keyEvents, 2, 'typing blocks automatic slash'); uis.Typing = false
    qcd.Value = 0; workspace.CurrentCamera = inst('Camera', 'Camera2', workspace); heartbeat(2.5); equal(#keyEvents, 4, 'camera replacement and cooldown recovery')
    api.Destroy(); api.Destroy(); equal(runService.Heartbeat:Count(), 0, 'combat destroy disconnects'); equal(uis.InputBegan:Count(), 0, 'combat input cleanup')
    api.startBackstab(12); equal(runService.Heartbeat:Count(), 0, 'destroyed module stays stopped')
elseif api.startInfiniteStamina then
    local source = inst('ModuleScript', 'Stamina', char); source.Module = {Stamina = 0, MaxStamina = 75, StaminaLossDisabled = false}
    api.startInfiniteStamina(); api.startInfiniteStamina(); equal(runService.Heartbeat:Count(), 1, 'stamina singleton')
    heartbeat(0); equal(source.Module.Stamina, 75, 'clamped stamina refill'); equal(source.Module.StaminaLossDisabled, true, 'stamina loss disabled')
    for _ = 1, 100 do heartbeat(0) end; equal(requires, 1, 'require once under 100 frames')
    heartbeat(0.4); equal(requires, 1, 'cached module reuse')
    api.stopInfiniteStamina(); equal(source.Module.Stamina, 0, 'restore initial zero stamina'); equal(source.Module.StaminaLossDisabled, false, 'restore false loss flag')
    api.startInfiniteStamina(); heartbeat(1)
    local replacement, newHum, newRoot = character('Replacement', 0, survivors)
    local newSource = inst('ModuleScript', 'Stamina', replacement); newSource.Module = {Stamina = 22, MaxStamina = 110}
    localPlayer.Character = nil; heartbeat(1.2); equal(source.Module.Stamina, 0, 'nil character restores outgoing module')
    localPlayer.Character = replacement; heartbeat(1.4); equal(source.Module.Stamina, 0, 'respawn restores old module'); equal(newSource.Module.Stamina, 100, 'respawn binds new module'); equal(requires, 2, 'one require per character')
    api.stopInfiniteStamina(); equal(newSource.Module.Stamina, 22, 'new character original restored')
    localPlayer.Character = char; api.startInfiniteStamina(); heartbeat(2)
    check(api.isSafePosition(char, root.Position), 'clear grounded position valid')
    workspace.Overlap = {ground}; check(not api.isSafePosition(char, root.Position), 'overlap blocks'); workspace.Overlap = {}
    workspace.Grounded = false; check(not api.isSafePosition(char, root.Position), 'void blocked'); workspace.Grounded = true
    check(not api.isSafePosition(char, vector(0, -495, 0)), 'destroy height margin')
    check(not api.isSafePosition(char, vector(0/0, 4, 0)), 'nan rejected')
    check(api.saveSafePoint(), 'save grounded point'); local saved = root.CFrame
    root.CFrame = cf(vector(30, 4, 0)); check(api.returnSafePoint(), 'return saved point'); equal(root.CFrame, saved, 'saved cframe restored')
    workspace.Overlap = {ground}; check(not api.returnSafePoint(), 'return revalidates obstruction'); workspace.Overlap = {}
    localPlayer.Character = replacement; check(not api.returnSafePoint(), 'saved point scoped to character')
    -- Single-flight resolver; disabling invalidates a late completion.
    local third = character('Third', 0, survivors); local late = inst('ModuleScript', 'Stamina', third); late.Module = {Stamina = 4}
    localPlayer.Character = third; queueSpawn = true; heartbeat(3); heartbeat(3.3); equal(#pending, 1, 'single pending resolver')
    api.stopInfiniteStamina(); local fn = table.remove(pending, 1); fn(); equal(late.Module.Stamina, 4, 'late load after disable has no mutation')
    queueSpawn = false; api.Destroy(); api.Destroy(); equal(runService.Heartbeat:Count(), 0, 'stamina destroy disconnects')
    api.startInfiniteStamina(); equal(runService.Heartbeat:Count(), 0, 'stamina remains destroyed')
    check(not api.saveSafePoint(), 'destroyed safe point stays inactive'); equal(api.getStaminaModule(), nil, 'destroyed resolver stays inactive')
elseif api.applyFullbright then
    equal(api.nearestKiller(), nearRoot, 'visual nearest selection')
    api.applyFullbright(); api.applyFullbright(); equal(runService.RenderStepped:Count(), 1, 'visual single render connection')
    equal(lighting.Brightness, 3, 'fullbright applies'); equal(lighting.GlobalShadows, false, 'shadows disabled')
    change('VisualNoFog', true); api.restoreLighting(); equal(lighting.Brightness, 1, 'fullbright restores while fog stays'); equal(lighting.FogEnd, 1e6, 'fog remains while enabled')
    change('VisualNoFog', false); equal(lighting.FogEnd, 100, 'fog original restored'); equal(lighting.FogStart, 12, 'fog start restored')
    change('VisualNoPostEffects', true); equal(bloom.Enabled, false, 'post effects disabled'); equal(disabledEffect.Enabled, false, 'pre-disabled effect stays false')
    local oldCamera = workspace.CurrentCamera; local oldEffect = inst('BloomEffect', 'Old', oldCamera); render(1)
    equal(oldEffect.Enabled, false, 'camera effects captured')
    workspace.CurrentCamera = inst('Camera', 'NewCamera', workspace); local newEffect = inst('BloomEffect', 'New', workspace.CurrentCamera); render(2)
    equal(oldEffect.Enabled, true, 'old camera effect restored'); equal(newEffect.Enabled, false, 'new camera effect disabled')
    change('VisualNoPostEffects', false); equal(bloom.Enabled, true, 'lighting effect original restored'); equal(disabledEffect.Enabled, false, 'false baseline restored'); equal(newEffect.Enabled, true, 'new camera restored')
    local box = api.highlightTarget(nearRoot, 2); render(3); check(not box.Destroyed, 'box survives duration'); render(4.1); check(box.Destroyed, 'box expires')
    change('VisualTargetMarker', true); render(5); local marked
    for _, child in ipairs(nearRoot:GetChildren()) do if child:IsA('SelectionBox') then marked = child end end
    check(marked ~= nil, 'nearest target actually marked'); equal(#farRoot:GetChildren(), 0, 'far first target not marked')
    change('VisualTargetMarker', true); equal(runService.RenderStepped:Count(), 1, 'marker toggle idempotent'); change('VisualTargetMarker', false); check(marked.Destroyed, 'disable destroys marks immediately')
    change('VisualPerformance', true); for i = 1, 60 do render(6 + i/60, 1/60) end
    check(math.abs(api.getFPS() - 60) < 0.01, 'performance samples real render dt')
    api.applyFullbright(); local owned = api.highlightTarget(nearRoot, 30); api.cleanupVisual(); equal(lighting.Brightness, 1, 'cleanup restores lighting'); check(owned.Destroyed, 'cleanup destroys marker'); equal(runService.RenderStepped:Count(), 0, 'cleanup disconnects')
    -- 本地外观：桥接缺失回退、动态降档、即时恢复、销毁后无调度
    equal(api.getVisualInterval(0.1), 0.1, 'bridge missing keeps base interval')
    equal(api.getVisualInterval(2), 2, 'bridge missing keeps long base')
    local visualHzMock = 5
    function fluent:GetVisualInterval(base) return math.max(base, 1 / visualHzMock) end
    equal(api.getVisualInterval(0.1), 0.2, 'bridge caps interval at visual hz')
    equal(api.getVisualInterval(2), 2, 'base longer than bridge wins')
    fluent.GetVisualInterval = function(_, base) return 0.01 end
    equal(api.getVisualInterval(0.1), 0.1, 'shorter bridge result ignored')
    fluent.GetVisualInterval = function(_, base) return 'bad' end
    equal(api.getVisualInterval(0.1), 0.1, 'non-number bridge result ignored')
    fluent.GetVisualInterval = function(_, base) return math.huge end
    equal(api.getVisualInterval(0.1), 0.1, 'infinite bridge result ignored')
    fluent.GetVisualInterval = function(_, base) return -math.huge end
    equal(api.getVisualInterval(0.1), 0.1, 'negative infinite bridge result ignored')
    fluent.GetVisualInterval = function(_, base) return 0 / 0 end
    equal(api.getVisualInterval(0.1), 0.1, 'nan bridge result ignored')
    fluent.GetVisualInterval = function(_, base) return -1 end
    equal(api.getVisualInterval(0.1), 0.1, 'negative bridge result ignored')
    fluent.GetVisualInterval = function(_, base) return 0 end
    equal(api.getVisualInterval(0.1), 0.1, 'zero bridge result ignored')
    function fluent:GetVisualInterval(base) return math.max(base, 1 / visualHzMock) end
    change('VisualLifeHidden', true)
    equal(life1Head.Transparency, 1, 'life1 hidden on enable')
    equal(life2Head.Transparency, 1, 'life2 hidden on enable')
    equal(runService.RenderStepped:Count(), 1, 'appearance keeps single render loop')
    local before = api.appearanceTicks()
    for i = 1, 200 do render(8 + i * 0.05, 0.05) end
    local lowTicks = api.appearanceTicks() - before
    check(lowTicks >= 45 and lowTicks <= 55, 'low visual hz throttles appearance: ' .. lowTicks)
    life1Head.Transparency = 0
    render(18.3)
    equal(life1Head.Transparency, 1, 'enforcement re-hides after game reset')
    visualHzMock = 10
    before = api.appearanceTicks()
    for i = 1, 200 do render(18 + i * 0.05, 0.05) end
    local midTicks = api.appearanceTicks() - before
    check(midTicks >= 70 and midTicks <= 90, 'mid visual hz runs at base cadence: ' .. midTicks)
    check(midTicks >= lowTicks * 1.3, 'raising visual hz increases refresh count: ' .. lowTicks .. ' -> ' .. midTicks)
    visualHzMock = 60
    before = api.appearanceTicks()
    for i = 1, 200 do render(28 + i * 0.05, 0.05) end
    local highTicks = api.appearanceTicks() - before
    check(highTicks >= 70 and highTicks <= 90, 'high visual hz keeps cadence: ' .. highTicks)
    check(highTicks >= lowTicks * 1.3, 'high visual hz raises refresh count: ' .. lowTicks .. ' -> ' .. highTicks)
    check(math.abs(highTicks - midTicks) <= 8, 'base interval caps high hz: ' .. midTicks .. ' -> ' .. highTicks)
    print('appearance tier counts: low=' .. lowTicks .. ' mid=' .. midTicks .. ' high=' .. highTicks)
    change('VisualLifeHidden', false)
    equal(life1Head.Transparency, 0, 'life1 restored immediately on disable')
    equal(life2Head.Transparency, 0, 'life2 restored immediately on disable')
    equal(runService.RenderStepped:Count(), 0, 'appearance disable stops loop')
    change('VisualKillerExtrasHidden', true)
    equal(extraModels.Parent, nil, 'extra models hidden')
    render(38.9)
    equal(extraModels.Parent, nil, 'extra models stay hidden under enforcement')
    change('VisualKillerExtrasHidden', false)
    equal(extraModels.Parent, char, 'extra models restored')
    change('VisualLocalSkin', true)
    check(api.isDegraded('Skin'), 'empty skin name degrades')
    check(#fluent.notifications > 0, 'degradation notifies')
    change('VisualLocalSkinName', 'Milestone100TwoTime')
    check(not api.isDegraded('Skin'), 'named local skin clears degradation')
    local skinClone
    for _, child in ipairs(char:GetChildren()) do if child.Name == 'VortexionLocalSkin' then skinClone = child end end
    check(skinClone ~= nil, 'local skin cloned onto character')
    check(skinClone.Parent == char, 'skin parented to character')
    change('VisualLocalSkin', false)
    check(skinClone.Destroyed, 'skin destroyed immediately on disable')
    change('VisualCharHighlight', true)
    equal(charHighlight.FillTransparency, 0.5, 'highlight fill applied')
    change('VisualCharHighlightFill', 20)
    equal(charHighlight.FillTransparency, 0.2, 'slider re-applies live value')
    render(39)
    equal(charHighlight.FillTransparency, 0.2, 'enforcement keeps highlight fill')
    change('VisualCharHighlight', false)
    equal(charHighlight.FillTransparency, 0.3, 'highlight original restored')
    char:ScaleTo(1.17)
    check(not pcall(function() hum:ScaleTo(1.06) end), 'humanoid has no ScaleTo API')
    change('VisualCharScale', true)
    equal(char:GetScale(), 1.06, 'model scale applied')
    equal(hum.LastScale, nil, 'humanoid not scaled')
    change('VisualCharScaleValue', 1.5)
    equal(char:GetScale(), 1.5, 'model scale slider live')
    change('VisualCharScale', false)
    equal(char:GetScale(), 1.17, 'actual model scale restored, not assumed one')
    local modelScaleTo = methods.ScaleTo
    methods.ScaleTo = nil
    change('VisualCharScale', true)
    check(api.isDegraded('Scale'), 'missing ScaleTo degrades')
    change('VisualCharScale', false)
    methods.ScaleTo = modelScaleTo
    change('VisualLifeHidden', true)
    equal(life1Head.Transparency, 1, 'life hidden before respawn')
    local replacement, newHum, newRoot = character('Replacement', 0, survivors)
    local newLife = inst('Model', 'Life1', replacement)
    local newLifeHead = inst('Part', 'Head', newLife); newLifeHead.Transparency = 0
    localPlayer.Character = replacement
    localPlayer.CharacterAdded:Fire(replacement)
    render(40)
    equal(newLifeHead.Transparency, 1, 'respawn re-applies appearance next frame')
    equal(life1Head.Transparency, 0, 'outgoing character restored on swap')
    check(runService.RenderStepped:Count() == 1, 'respawn keeps single render loop')
    local tickBefore = api.appearanceTicks()
    api.Destroy(); api.Destroy()
    equal(runService.RenderStepped:Count(), 0, 'destroy stops render loop')
    equal(localPlayer.CharacterAdded:Count(), 0, 'destroy disconnects respawn listener')
    localPlayer.Character = char
    localPlayer.CharacterAdded:Fire(char)
    for i = 1, 60 do render(41 + i / 60, 1 / 60) end
    equal(api.appearanceTicks(), tickBefore, 'no appearance scheduling after destroy')
    equal(runService.RenderStepped:Count(), 0, 'destroyed module stays stopped')
    change('VisualLifeHidden', true)
    equal(life1Head.Transparency, 0, 'destroyed module ignores enable')
    equal(localPlayer.CharacterAdded:Count(), 0, 'no listener rebind after destroy')
    api.Destroy(); api.Destroy(); api.applyFullbright(); equal(runService.RenderStepped:Count(), 0, 'destroyed visual stays stopped')
elseif api.playCustomAnim then
    api.setEnabled('FakeBlock', true); check(api.triggerFakeBlock(), 'fake block has actual animation'); equal(animator.LastId, 'rbxassetid://72722244508749', 'normal fakeblock asset')
    local firstTrack = animator.LastTrack; equal(loadCount, 1, 'animation loaded')
    check(not api.playCustomAnim('123'), 'animation rate limit'); now = 0.4
    change('GuestFakeBlockVariant', 'M3 / M4'); check(api.triggerFakeBlock(), 'alternate fakeblock plays'); equal(animator.LastId, 'rbxassetid://96959123077498', 'alternate asset'); check(firstTrack.Destroyed, 'previous track disposed')
    check(not api.playCustomAnim('https://example.test/a'), 'invalid asset string rejected')
    now = 1; animator.FailLoad = true; check(not api.playCustomAnim('123'), 'load failure returned'); animator.FailLoad = false
    check(api.playCustomAnim('123'), 'failed load does not consume throttle'); equal(animator.LastId, 'rbxassetid://123', 'numeric id normalized')
    for _, object in ipairs(created) do if object:IsA('Animation') then check(object.Destroyed, 'temporary Animation disposed') end end
    local playing = animator.LastTrack; api.stopAnimations(); check(playing.Destroyed, 'explicit stop disposes track')
    api.chargeStateSave(hum); hum.WalkSpeed = 20; hum.JumpPower = 30
    local other = inst('Humanoid'); other.WalkSpeed = 16; api.chargeStateRestore(other); equal(other.WalkSpeed, 16, 'charge save not applied to different humanoid')
    api.chargeStateRestore(hum); equal(hum.WalkSpeed, 0, 'charge zero speed restored'); equal(hum.JumpPower, 0, 'charge zero jump restored')
    now = 2; check(api.playCustomAnim('456'), 'play after interval'); playing = animator.LastTrack
    local replacement = character('Replacement', 0, survivors); localPlayer.Character = replacement; localPlayer.CharacterAdded:Fire(replacement); check(playing.Destroyed, 'respawn disposes animation')
    localPlayer.Character = char; now = 3; check(api.playCustomAnim('789'), 'restart on live character'); playing = animator.LastTrack
    api.destroyFakeBlockGui(); check(playing.Destroyed, 'fakeblock disable stops track')
    api.Destroy(); api.Destroy(); equal(localPlayer.CharacterAdded:Count(), 0, 'guest respawn connection cleanup'); check(not api.playCustomAnim('789'), 'destroyed guest stays stopped')
elseif api.startDash then
    api.startDash(); api.startDash(); equal(runService.RenderStepped:Count(), 1, 'core dash singleton'); render(0); equal(hum.WalkSpeed, 60, 'core dash speed')
    local replacement, newHum = character('Replacement', 0, survivors); newHum.WalkSpeed = 22; newHum.AutoRotate = true
    localPlayer.Character = replacement; render(1); equal(hum.WalkSpeed, 0, 'core dash restores previous humanoid zero'); equal(hum.AutoRotate, false, 'core dash restores previous false rotate'); equal(newHum.WalkSpeed, 60, 'new humanoid overridden')
    api.stopDash(); equal(newHum.WalkSpeed, 22, 'core dash exact replacement speed'); equal(newHum.AutoRotate, true, 'core dash exact replacement rotate')
    local firstCamera = workspace.CurrentCamera; change('ForsakenFOVValue', 200); change('ForsakenFOVEnabled', true); equal(firstCamera.FieldOfView, 120, 'core fov clamp')
    local secondCamera = inst('Camera', 'SecondCamera', workspace); secondCamera.FieldOfView = 95; workspace.CurrentCamera = secondCamera; heartbeat(2); equal(firstCamera.FieldOfView, 70, 'old camera restored on swap'); equal(secondCamera.FieldOfView, 120, 'new camera fov applied')
    workspace.CurrentCamera = nil; heartbeat(2.3); equal(secondCamera.FieldOfView, 95, 'nil camera restores outgoing camera'); workspace.CurrentCamera = secondCamera; heartbeat(2.6)
    change('ForsakenFOVEnabled', false); equal(secondCamera.FieldOfView, 95, 'new camera restores own baseline')
    for _ = 1, 200 do api.startDash(); api.stopDash() end; check(api.trackedCount() <= 2, 'disconnected bucket pruned under repeated toggles')
    change('ForsakenFOVEnabled', true); api.startDash(); render(3); for _, callback in ipairs(fluent.destroyCallbacks) do callback() end; equal(secondCamera.FieldOfView, 95, 'fov on destroy restore'); equal(runService.Heartbeat:Count(), 0, 'fov listener stopped')
    equal(runService.RenderStepped:Count(), 0, 'core cleanup stops dash'); equal(newHum.WalkSpeed, 22, 'core cleanup restores humanoid')
    equal(api.groupDestroyCount(), 2, 'actual core cleanup destroys groups'); equal(ctx.sessionEnv.One, nil, 'core cleanup clears owned API')
    api.cleanup(); equal(api.groupDestroyCount(), 2, 'core cleanup idempotent')
    -- ESP 非关键投影节流：CheckHz 有界 + 桥接返回必须 finite 正数，inf/nan/负值拒绝
    equal(api.espInterval(), 0.1, 'esp interval defaults to 10hz')
    api.setEspCheckHz(2); equal(api.espInterval(), 0.5, 'esp hz clamped low')
    api.setEspCheckHz(20); equal(api.espInterval(), 0.05, 'esp hz clamped high')
    api.setEspCheckHz(100); equal(api.espInterval(), 0.05, 'esp hz bounded at 20')
    api.setEspCheckHz(1); equal(api.espInterval(), 0.5, 'esp hz bounded at 2')
    api.setEspCheckHz(0 / 0); equal(api.espInterval(), 0.1, 'nan check hz falls back to default')
    api.setEspCheckHz(math.huge); equal(api.espInterval(), 0.1, 'infinite check hz falls back to default')
    api.setEspCheckHz(-math.huge); equal(api.espInterval(), 0.1, 'negative infinite check hz falls back to default')
    api.setEspCheckHz(10)
    function fluent:GetVisualInterval(base) return math.max(base, 1 / 5) end
    equal(api.espInterval(), 0.2, 'esp bridge extends interval')
    fluent.GetVisualInterval = function(_, base) return math.huge end
    equal(api.espInterval(), 0.1, 'esp bridge infinite ignored')
    fluent.GetVisualInterval = function(_, base) return 0 / 0 end
    equal(api.espInterval(), 0.1, 'esp bridge nan ignored')
    fluent.GetVisualInterval = function(_, base) return -1 end
    equal(api.espInterval(), 0.1, 'esp bridge negative ignored')
    fluent.GetVisualInterval = function(_, base) return 0 end
    equal(api.espInterval(), 0.1, 'esp bridge zero ignored')
    fluent.GetVisualInterval = function(_, base) return 0.01 end
    equal(api.espInterval(), 0.1, 'esp bridge shorter value capped by max')
    fluent.GetVisualInterval = nil
    equal(api.espInterval(), 0.1, 'esp bridge missing keeps base')
else error('unknown factory') end
print('Forsaken executed assertions: ' .. assertions)
