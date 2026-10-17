-- Vortexion BloxStrike bullet tracking.
--
-- Four paths, auto-selected by capability probe and live game structure:
--   A LeadOnly   - prediction already lives in Combat (velocity EMA + ping).
--                  Always on when aimbot prediction > 0; no hooks needed.
--   B Hitscan    - require the weapon module (ReplicatedStorage.Components.
--                  Weapon.Classes.Bullet and siblings), hook its raycast/fire
--                  functions and rewrite the direction argument so the local
--                  ray lands on the locked target. RaycastResult cannot be
--                  forged from Lua, so the input is the only honest lever.
--   C Remote     - hook __namecall and rewrite Vector3 arguments of weapon
--                  remotes (FireServer / InvokeServer): unit directions are
--                  re-pointed at the target, world-space hit points are
--                  clamped into the target's original-size envelope so the
--                  server-side check still sees a plausible hit.
--   D Projectile - watch Workspace for freshly spawned bullet parts and steer
--                  their velocity toward the predicted intercept point.
--
-- Every hook is pcall-wrapped, uninstallable, and skips executor-originated
-- calls (checkcaller) so this script's own remotes are never rewritten.
return function(c)
    local Players = c.Services.Players
    local Workspace = c.Services.Workspace
    local ReplicatedStorage = c.Services.ReplicatedStorage
    local RunService = c.Services.RunService
    local LocalPlayer = c.LocalPlayer

    local Config = {
        Enabled = false,
        Mode = "LeadOnly",      -- safe startup: no metatable or function hooks
        HitChance = 1,
        MaxAngle = 35,
        WallCheck = true,
        TeamCheck = true,
        Envelope = true,         -- clamp rewritten world points into orig size
        ProjectileTrack = true,
        ProjectileLerp = 0.35,
        ProjectileMax = 8,
        Debug = false,
        LinkCombat = true, -- LeadOnly needs aim prediction to be running
    }

    local state = {
        activePath = "LeadOnly",
        remoteHookOriginal = nil,
        remoteHookInstalled = false,
        weaponFunctions = {},     -- [original fn] = true (for uninstall)
        watchedRemotes = setmetatable({}, { __mode = "k" }), -- [remote] = true
        remoteCount = 0,
        bullets = {},             -- tracked projectile entries
        rollCache = {},
        rollAt = {},
        cost = 0,
        errors = 0,
        weaponProbe = "not run",
        hitscanCalls = 0,
        hitscanRewrites = 0,
    }

    --==========================================================================
    -- R2.19: reversible game-specific weapon effect adapters.
    -- Based on observed BloxStrike class signatures, NOT a generic hook of
    -- every remote or every function. Enabled only after user toggles a mod.
    -- No server acceptance is presumed from local camera/spread changes.
    --==========================================================================
    local mods = {recoil=false, spread=false, patches={}, candidates=0,
        checked=0, status="not scanned", patchErrors=0, calls=0,
        nativeHooks=0, tablePatches=0, enabledAt=0, lastCallAt=0,
        retries=0, lastScan=0, workerRunning=false}
    -- R225: changing owner[key] alone does NOT affect functions captured by
    -- BloxStrike's controller at startup. Prefer a real executor hookfunction
    -- when supported. Record the original trampoline for explicit teardown.
    local function recordPatch(owner, key, replacement)
        if type(owner) ~= "table" or type(rawget(owner, key)) ~= "function" then return false end
        for _, item in ipairs(mods.patches) do
            if item.owner == owner and item.key == key then return true end
        end
        local target = rawget(owner, key)
        local hookOriginal
        local function forward(...)
            return (hookOriginal or target)(...)
        end
        local wrapper = replacement(forward)
        if c.Caps and c.Caps.hookfunction and type(hookfunction) == "function" then
            local ok, original = pcall(function()
                return hookfunction(target, wrapper)
            end)
            if ok and type(original) == "function" then
                hookOriginal = original
                mods.nativeHooks += 1
                mods.patches[#mods.patches + 1] = {
                    owner=owner, key=key, original=target, originalTrampoline=original,
                    wrapper=wrapper, native=true,
                }
                return true
            end
            mods.patchErrors += 1
        end
        -- Fallback for executors without hookfunction. Mark explicitly as a
        -- TABLE patch; it may be ineffective if the controller cached methods.
        local ok = pcall(function() owner[key] = wrapper end)
        if not ok then mods.patchErrors += 1; return false end
        mods.tablePatches += 1
        mods.patches[#mods.patches + 1] = {
            owner=owner, key=key, original=target, wrapper=wrapper, native=false,
        }
        return true
    end
    local function restoreWeaponMods()
        for i = #mods.patches, 1, -1 do
            local patch = mods.patches[i]
            if patch.native then
                -- Restoring only hooks we installed; never reset arbitrary
                -- unrelated functions or the global __namecall chain.
                if type(hookfunction) == "function" then
                    pcall(hookfunction, patch.original, patch.originalTrampoline)
                end
            else
                pcall(function()
                    if patch.owner[patch.key] == patch.wrapper then
                        patch.owner[patch.key] = patch.original
                    end
                end)
            end
            mods.patches[i] = nil
        end
        mods.nativeHooks, mods.tablePatches = 0, 0
    end
    local function findWeaponTables()
        local results, dedup = {}, {}
        local function add(item)
            if type(item) ~= "table" or dedup[item] then return end
            dedup[item] = true
            results[#results+1] = item
        end
        local function requireAt(start, ...)
            local path = start
            for _, name in ipairs({...}) do
                path = path and path:FindFirstChild(name)
            end
            if path and path:IsA("ModuleScript") then
                local ok, value = pcall(require, path)
                if ok then add(value) end
            end
        end
        requireAt(ReplicatedStorage, "Controllers", "CameraController")
        requireAt(ReplicatedStorage, "Components", "Weapon", "Classes", "Bullet")
        -- Current community sources use a second, structurally different path.
        -- Probe only known ModuleScripts; never require arbitrary descendants.
        requireAt(ReplicatedStorage, "Classes", "WeaponComponent", "Classes", "Bullet")
        requireAt(ReplicatedStorage, "Controllers", "InventoryController")
        local scanGC = type(getgc) == "function" and getgc
        if scanGC then
            local ok, items = pcall(scanGC, true)
            if ok and type(items) == "table" then
                local seen = 0
                for _, item in pairs(items) do
                    seen += 1
                    if seen > 12000 or #results >= 24 then break end
                    if type(item) == "table" then
                        if type(rawget(item,"weaponKick")) == "function"
                            or type(rawget(item,"getTrueSpread")) == "function"
                            or type(rawget(item,"getSpreadForConfig")) == "function"
                            or type(rawget(item,"shoot")) == "function" then
                            add(item)
                        end
                    end
                end
                mods.checked = seen
            end
        end
        mods.candidates = #results
        return results
    end
    local function installWeaponMods()
        if not (mods.recoil or mods.spread) then
            restoreWeaponMods()
            mods.status = "disabled"
            return
        end
        -- Install once; wrappers read current flags. This avoids churn and
        -- avoids leaking closures cached by the game's own controller.
        if #mods.patches > 0 then
            mods.status = "hooks=" .. tostring(mods.nativeHooks)
                .. " table=" .. tostring(mods.tablePatches)
                .. " calls=" .. tostring(mods.calls)
            return
        end
        local tables = findWeaponTables()
        local patched = 0
        for _, owner in ipairs(tables) do
            do
                for _, key in ipairs({"weaponKick", "setWeaponRecoil", "getWeaponKickRotation"}) do
                    local name = key
                    if recordPatch(owner, name, function(original)
                        return function(...)
                            if mods.recoil then
                                mods.calls += 1
                                mods.lastCallAt = os.clock()
                                if name == "getWeaponKickRotation" then return Vector3.zero end
                                return nil
                            end
                            return original(...)
                        end
                    end) then patched += 1 end
                end
            end
            do
                for _, key in ipairs({"getTrueSpread", "getSpreadForConfig", "getMovementSpreadForConfig",
                    "getBaseSpreadForConfig", "getBaseSpread"}) do
                    if recordPatch(owner, key, function(original)
                        return function(...)
                            local value = original(...)
                            if mods.spread then
                                if type(value) == "number" then
                                    mods.calls += 1
                                    mods.lastCallAt = os.clock()
                                    return 0
                                end
                                if typeof(value) == "Vector3" then
                                    mods.calls += 1
                                    mods.lastCallAt = os.clock()
                                    return Vector3.zero
                                end
                            end
                            return value
                        end
                    end) then patched += 1 end
                end
            end
        end
        mods.status = patched > 0
            and ("hooks=" .. tostring(mods.nativeHooks) .. " table=" .. tostring(mods.tablePatches)
                .. " observed calls=" .. tostring(mods.calls))
            or "unsupported: weapon methods not located"
    end
    local function setWeaponMod(kind, enabled)
        mods[kind] = enabled == true
        mods.enabledAt = os.clock()
        installWeaponMods()
        if not (mods.recoil or mods.spread) then return end
        -- Controller and gun modules often appear only after a match begins.
        -- Rescan at most eight times, bounded, without per-frame getgc calls.
        if mods.workerRunning or type(task) ~= "table" then return end
        if type(task.spawn) ~= "function" or type(task.wait) ~= "function" then return end
        mods.workerRunning = true
        task.spawn(function()
            for attempt = 1, 8 do
                task.wait(2.5)
                if not (mods.recoil or mods.spread) or not c.IsCurrent() then break end
                if #mods.patches == 0 then
                    mods.retries += 1
                    installWeaponMods()
                end
            end
            mods.workerRunning = false
        end)
    end
    c.OnCleanup(function()
        mods.recoil, mods.spread = false, false
        restoreWeaponMods()
    end)

    --=========================================================================
    -- Aim resolution: prefer the Combat lock, else the on-screen candidate
    -- nearest the crosshair. Shared by every rewrite path.
    --=========================================================================
    local function resolveAim()
        local combat = c.Combat
        if combat and combat.GetLock then
            local lock = combat.GetLock()
            if lock then
                return lock.point, lock.part, lock.player
            end
        end
        if combat and combat.GetCandidates then
            local camera = Workspace.CurrentCamera
            if not camera then return nil end
            local viewport = camera.ViewportSize
            local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
            local best, bestDist
            for _, entry in ipairs(combat.GetCandidates()) do
                local part = entry.head or entry.root
                if part then
                    local pos = combat.PredictPoint and combat.PredictPoint(entry.player, part) or part.Position
                    local screen, onScreen = camera:WorldToScreenPoint(pos)
                    if onScreen and screen.Z > 0 then
                        local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                        if not bestDist or dist < bestDist then
                            best, bestDist = pos, dist
                        end
                    end
                end
            end
            if best then return best, nil, nil end
        end
        return nil
    end

    --=========================================================================
    -- Gates: angle between current view and aim point, plus a per-shot roll
    -- so the server never sees a 100% conversion profile.
    --=========================================================================
    local function withinAngle(aimPos)
        local camera = Workspace.CurrentCamera
        if not camera then return false end
        local look = aimPos - camera.CFrame.Position
        if look.Magnitude < 0.01 then return true end
        local angle = math.acos(math.clamp(camera.CFrame.LookVector:Dot(look.Unit), -1, 1))
        return math.deg(angle) <= Config.MaxAngle
    end

    local function hitRoll(key)
        local now = tick()
        if not state.rollAt[key] or now - state.rollAt[key] > 0.5 then
            state.rollAt[key] = now
            state.rollCache[key] = math.random()
        end
        return state.rollCache[key] <= Config.HitChance
    end

    local function envelopeClamp(point, part)
        if not Config.Envelope or not part then return point end
        local center = part.Position
        local combat = c.Combat
        local half = combat and type(combat.GetEnvelope) == "function"
            and combat:GetEnvelope(part) or (part.Size * 0.5 + Vector3.new(0.5, 0.5, 0.5))
        local offset = point - center
        return center + Vector3.new(
            math.clamp(offset.X, -half.X, half.X),
            math.clamp(offset.Y, -half.Y, half.Y),
            math.clamp(offset.Z, -half.Z, half.Z)
        )
    end

    --=========================================================================
    -- Path B: hitscan input rewrite.
    --=========================================================================
    local WEAPON_NAME_HINTS = { "raycast", "cast", "fire", "perform", "shoot", "trace" }

    local function nameLooksWeapon(name)
        local lower = name:lower()
        for _, hint in ipairs(WEAPON_NAME_HINTS) do
            if lower:find(hint, 1, true) then return true end
        end
        return false
    end

    local function rewriteHitscanArgs(original, ...)
        if not Config.Enabled then return nil end
        local packed = table.pack(...)
        local vectors = {}
        for i = 1, math.min(packed.n, 8) do
            if typeof(packed[i]) == "Vector3" then
                table.insert(vectors, { index = i, value = packed[i] })
            end
        end
        if #vectors == 0 then return nil end

        local origin, direction
        for _, entry in ipairs(vectors) do
            local mag = entry.value.Magnitude
            if not origin and mag > 1.5 then
                origin = entry.value
            elseif not direction and mag > 0.95 and mag < 1.05 then
                direction = entry
            end
        end
        if not direction and #vectors >= 1 then
            for _, entry in ipairs(vectors) do
                if entry.value.Magnitude > 0.95 and entry.value.Magnitude < 1.05 then
                    direction = entry
                    break
                end
            end
        end
        if not direction then return nil end
        if not origin then
            local camera = Workspace.CurrentCamera
            if not camera then return nil end
            origin = camera.CFrame.Position
        end

        local aimPos, aimPart = resolveAim()
        if not aimPos then return nil end
        if not withinAngle(aimPos) then return nil end
        if not hitRoll("hitscan") then return nil end
        aimPos = envelopeClamp(aimPos, aimPart)

        local dir = (aimPos - origin)
        if dir.Magnitude < 0.01 then return nil end
        packed[direction.index] = dir.Unit * direction.value.Magnitude
        state.hitscanRewrites += 1
        c.Log("Bullet", "hitscan rewrite idx", direction.index)
        return packed
    end

    -- R225: the old module-only path no longer locates gun/bullet classes in
    -- modern BloxStrike. The game may instantiate them into GC tables before
    -- exposing a stable ReplicatedStorage.Components.Weapon class hierarchy.
    -- Only opt-in Hitscan/Auto (desktop) paths call this; no global hooks on boot.
    local function installHitscanHooks()
        if not c.Caps.hookfunction then return false end
        local function hookMethod(owner, key)
            if type(owner) ~= "table" then return false end
            local fn = rawget(owner, key)
            if type(fn) ~= "function" or state.weaponFunctions[fn] then return false end
            local original
            local ok = pcall(function()
                original = hookfunction(fn, function(...)
                    state.hitscanCalls += 1
                    local didRewrite, rewritten = pcall(rewriteHitscanArgs, ...)
                    if didRewrite and rewritten then
                        return original(table.unpack(rewritten, 1, rewritten.n))
                    end
                    return original(...)
                end)
            end)
            if ok and type(original) == "function" then
                state.weaponFunctions[fn] = original
                return true
            end
            state.errors += 1
            return false
        end
        local function hookClass(owner)
            if type(owner) ~= "table" then return 0 end
            -- 'shoot' / 'create' match current GunClass and Bullet signatures;
            -- do not blindly hook every function from game GC.
            local matched = 0
            for _, name in ipairs({"create", "shoot", "raycast", "cast", "trace"}) do
                if hookMethod(owner, name) then matched += 1 end
            end
            return matched
        end
        local hooked = 0
        local roots = {}
        local function addModule(start, ...)
            local node = start
            for _, key in ipairs({...}) do node = node and node:FindFirstChild(key) end
            if node and node:IsA("ModuleScript") then
                local ok, result = pcall(require, node)
                if ok and type(result) == "table" then roots[#roots + 1] = result end
            end
        end
        addModule(ReplicatedStorage, "Components", "Weapon", "Classes", "Bullet")
        addModule(ReplicatedStorage, "Controllers", "CameraController")
        if type(getgc) == "function" then
            local ok, items = pcall(getgc, true)
            if ok and type(items) == "table" then
                local examined = 0
                for _, item in pairs(items) do
                    examined += 1
                    if examined > 12000 or #roots >= 30 then break end
                    if type(item) == "table" then
                        local isGun = type(rawget(item, "shoot")) == "function"
                            and (type(rawget(item, "setupRecoil")) == "function"
                                 or type(rawget(item, "getSpread")) == "function")
                        local isBullet = type(rawget(item, "create")) == "function"
                            and (type(rawget(item, "getTrueSpread")) == "function"
                                 or type(rawget(item, "getSpreadForConfig")) == "function")
                        if isGun or isBullet then roots[#roots + 1] = item end
                    end
                end
            end
        end
        for _, owner in ipairs(roots) do
            hooked += hookClass(owner)
            if hooked >= 12 then break end
        end
        c.Log("Bullet", "game class hooks", hooked, "calls", state.hitscanCalls)
        return hooked > 0
    end

    --=========================================================================
    -- Path C: remote argument rewrite via __namecall hook.
    --=========================================================================
    local REMOTE_NAME_HINTS = { "fire", "shoot", "bullet", "weapon", "hit", "damage", "replicate", "raycast" }

    local function remoteLooksWatched(name)
        local lower = name:lower()
        for _, hint in ipairs(REMOTE_NAME_HINTS) do
            if lower:find(hint, 1, true) then return true end
        end
        return false
    end

    local function scanRemotes()
        local count = 0
        for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
            if count >= 400 then break end
            if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
                count += 1
                if remoteLooksWatched(inst.Name) then
                    state.watchedRemotes[inst] = true
                end
            end
        end
        state.remoteCount = count
        c.Log("Bullet", "watched remotes", count)
    end

    local function rewriteRemoteArgs(...)
        local packed = table.pack(...)
        local aimPos, aimPart = resolveAim()
        if not aimPos then return nil end
        if not withinAngle(aimPos) then return nil end
        if not hitRoll("remote") then return nil end
        aimPos = envelopeClamp(aimPos, aimPart)
        local camera = Workspace.CurrentCamera
        if not camera then return nil end
        local camPos = camera.CFrame.Position
        local changed = false
        for i = 1, packed.n do
            local v = packed[i]
            if typeof(v) == "Vector3" then
                local mag = v.Magnitude
                if mag > 0.95 and mag < 1.05 then
                    local dir = aimPos - camPos
                    if dir.Magnitude > 0.01 then
                        packed[i] = dir.Unit * mag
                        changed = true
                    end
                elseif mag > 5 then
                    -- World-space point: clamp into the target envelope only
                    -- when it already sits near the target (hit report).
                    if (v - aimPos).Magnitude < 200 then
                        packed[i] = aimPos
                        changed = true
                    end
                end
            end
        end
        if changed then
            c.Log("Bullet", "remote rewrite")
            return packed
        end
        return nil
    end

    local function installRemoteHook()
        if not (c.Caps.hookmetamethod and c.Caps.getrawmetatable and c.Caps.checkcaller and c.Caps.getnamecallmethod) then
            return false
        end
        local ok, err = pcall(function()
            local metatable = getrawmetatable(game)
            local original = metatable.__namecall
            state.remoteHookOriginal = original
            local replacement = function(self, ...)
                if Config.Enabled and state.watchedRemotes[self] then
                    local methodOk, method = pcall(getnamecallmethod)
                    if methodOk and (method == "FireServer" or method == "InvokeServer") then
                        local callerOk, fromExecutor = pcall(checkcaller)
                        if not (callerOk and fromExecutor) then
                            local okRw, rewritten = pcall(rewriteRemoteArgs, ...)
                            if okRw and rewritten then
                                return original(self, unpack(rewritten, 1, rewritten.n))
                            end
                        end
                    end
                end
                return original(self, ...)
            end
            if c.Caps.newcclosure then
                replacement = newcclosure(replacement)
            end
            hookmetamethod(game, "__namecall", replacement)
            state.remoteHookInstalled = true
        end)
        if not ok then
            state.errors += 1
            c.Log("Bullet", "remote hook failed", err)
        end
        return ok
    end

    local function uninstallRemoteHook()
        if not state.remoteHookInstalled then return end
        pcall(function()
            hookmetamethod(game, "__namecall", state.remoteHookOriginal)
        end)
        state.remoteHookInstalled = false
        c.Log("Bullet", "remote hook removed")
    end

    --=========================================================================
    -- Path D: projectile tracking. A part spawned close to the camera with
    -- velocity and no anchor is treated as a local bullet for 3 seconds.
    --=========================================================================
    local bulletConns = {}

    local function trackBullet(inst)
        if #state.bullets >= Config.ProjectileMax then return end
        local part = inst
        if inst:IsA("Model") then
            part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        end
        if not part or not part:IsA("BasePart") then return end
        if part.Anchored then return end
        local camera = Workspace.CurrentCamera
        if not camera then return end
        if (part.Position - camera.CFrame.Position).Magnitude > 60 then return end
        local localChar = LocalPlayer and LocalPlayer.Character
        if localChar and part:IsDescendantOf(localChar) then return end
        table.insert(state.bullets, { part = part, since = tick() })
        c.Log("Bullet", "tracking projectile", part:GetFullName())
    end

    local function projectileTick(dt)
        if not (Config.Enabled and Config.ProjectileTrack) then
            if #state.bullets > 0 then state.bullets = {} end
            return
        end
        local now = tick()
        for i = #state.bullets, 1, -1 do
            local bullet = state.bullets[i]
            local part = bullet.part
            if not part or not part.Parent or now - bullet.since > 3 then
                table.remove(state.bullets, i)
            else
                local aimPos = resolveAim()
                if aimPos then
                    local pos = part.Position
                    local dir = aimPos - pos
                    if dir.Magnitude > 0.5 then
                        local current = part.AssemblyLinearVelocity
                        if current and current.Magnitude > 1 then
                            local speed = current.Magnitude
                            local desired = dir.Unit * speed
                            part.AssemblyLinearVelocity = current:Lerp(desired, math.clamp(Config.ProjectileLerp, 0.05, 1))
                        end
                    end
                end
            end
        end
    end

    local function installProjectileWatch()
        local conn = Workspace.DescendantAdded:Connect(function(inst)
            if not Config.Enabled then return end
            if inst:IsA("BasePart") then
                trackBullet(inst)
            elseif inst:IsA("Model") then
                task.defer(function()
                    if inst.Parent then trackBullet(inst) end
                end)
            end
        end)
        table.insert(bulletConns, conn)
    end

    -- Recent public BloxStrike Luau sources identify runtime weapon classes
    -- by getgc tables (shoot/setupRecoil/getSpread), not solely by a fixed
    -- ReplicatedStorage.Components.Weapon path. Read-only and bounded: native
    -- hooking is intentionally never initiated by this diagnostic probe.
    local function probeRuntimeWeapon()
        local seen = 0
        local gun, bullet, camera = false, false, false
        if type(getgc) ~= "function" then
            state.weaponProbe = "getgc unavailable; only game hierarchy can be inspected"
            return state.weaponProbe
        end
        local ok, items = pcall(getgc, true)
        if not ok or type(items) ~= "table" then
            state.weaponProbe = "getgc unsupported or returned non-table"
            return state.weaponProbe
        end
        for _, item in pairs(items) do
            seen += 1
            if seen > 2500 then break end
            if type(item) == "table" then
                if rawget(item, "shoot") and rawget(item, "setupRecoil") then gun = true end
                if rawget(item, "getTrueSpread") and rawget(item, "getSpreadForConfig") then bullet = true end
                if rawget(item, "weaponKick") and rawget(item, "setWeaponRecoil") then camera = true end
            end
        end
        state.weaponProbe = ("runtime classes: gun=%s bullet=%s camera=%s scanned=%d")
            :format(tostring(gun), tostring(bullet), tostring(camera), seen)
        return state.weaponProbe
    end

    local function linkAimAssistant()
        if not Config.LinkCombat then return end
        local bridge = c.UI
        local option = bridge and bridge.Options and bridge.Options.BloxAimEnabled
        if option and option.Value ~= true and type(option.SetValue) == "function" then
            -- Native SetValue keeps the actual control and game state aligned.
            option:SetValue(true)
        end
    end

    --=========================================================================
    -- Mode resolution.
    --=========================================================================
    local function resolveMode()
        if Config.Mode ~= "Auto" then
            return Config.Mode
        end
        local hitscan = next(state.weaponFunctions) ~= nil
        local remote = next(state.watchedRemotes) ~= nil
        if hitscan then return "Hitscan" end
        if remote then return "Remote" end
        return "LeadOnly"
    end

    --=========================================================================
    -- Public interface.
    --=========================================================================
    local Bullet = {}

    function Bullet:Start()
        if Config.Enabled then return end
        Config.Enabled = true
        linkAimAssistant()
        -- On mobile, never attempt native/global hooks merely because the
        -- user enables the generic toggle. Explicit high-risk modes can be
        -- selected separately; LeadOnly remains a hook-free safe default.
        local mode = Config.Mode
        local mobile = c.Services.UserInputService and c.Services.UserInputService.TouchEnabled
        if mode == "Hitscan" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Hitscan", installHitscanHooks)
        end
        if mode == "Remote" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Scan", scanRemotes)
            c.Guard("Bullet.Remote", installRemoteHook)
        end
        if mode == "Projectile" or mode == "Auto" then
            if #bulletConns == 0 then installProjectileWatch() end
        end
        state.activePath = resolveMode()
        c.Log("Bullet", "started, path", state.activePath)
    end

    function Bullet:Stop()
        Config.Enabled = false
        uninstallRemoteHook()
        for value, original in pairs(state.weaponFunctions) do
            pcall(hookfunction, value, original)
        end
        state.weaponFunctions = {}
        for k in pairs(state.watchedRemotes) do state.watchedRemotes[k] = nil end
        state.bullets = {}
        state.activePath = "LeadOnly"
        c.Log("Bullet", "stopped")
    end

    function Bullet:IsActive()
        return Config.Enabled
    end

    function Bullet:Update(dt)
        if not Config.Enabled then
            if #state.bullets > 0 then state.bullets = {} end
            return
        end
        local t0 = tick()
        c.Guard("Bullet.Projectile", projectileTick, dt)
        state.cost = tick() - t0
    end

    function Bullet:Status()
        return {
            path = state.activePath,
            hooks = (function() local n = 0; for _ in pairs(state.weaponFunctions) do n += 1 end; return n end)(),
            remotes = (function() local n = 0; for _ in pairs(state.watchedRemotes) do n += 1 end; return n end)(),
            totalRemotes = state.remoteCount,
            bullets = #state.bullets,
            errors = state.errors,
            costMs = math.floor(state.cost * 100000) / 100,
            probe = state.weaponProbe,
            needsAim = state.activePath == "LeadOnly" and not (c.Combat and c.Combat.IsActive and c.Combat:IsActive()),
            hitscanCalls = state.hitscanCalls,
            hitscanRewrites = state.hitscanRewrites,
            weaponMods = mods.status, weaponCalls = mods.calls,
            weaponNativeHooks = mods.nativeHooks, weaponTablePatches = mods.tablePatches,
            weaponObserved = mods.calls > 0,
            weaponLastCallAt = mods.lastCallAt,
            weaponEnabled = mods.recoil or mods.spread,
            weaponRetries = mods.retries,
            weaponCandidates = mods.candidates, weaponPatchErrors = mods.patchErrors,
        }
    end

    function Bullet:Rescan()
        for k in pairs(state.watchedRemotes) do state.watchedRemotes[k] = nil end
        local mode = Config.Mode
        local mobile = c.Services.UserInputService and c.Services.UserInputService.TouchEnabled
        if mode == "Remote" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Scan", scanRemotes)
        end
        if mode == "Hitscan" or (mode == "Auto" and not mobile) then
            c.Guard("Bullet.Hitscan", installHitscanHooks)
        end
        state.activePath = resolveMode()
    end

    c.OnCleanup(function()
        Bullet:Stop()
        for _, conn in ipairs(bulletConns) do
            pcall(function() conn:Disconnect() end)
        end
        bulletConns = {}
    end)

    --=========================================================================
    -- UI (Weapon tab): bullet tracking controls replace the old placeholder.
    --=========================================================================
    local tab = c.Tabs.Weapon
    tab:AddParagraph({Title="BloxStrike 武器模块 R225", Content="按实战 controller/GC 类定位；优先 native hookfunction，失败才替换表方法。界面开关不等于武器方法被调用；可用下方诊断检查实时调用计数。"})
    tab:AddToggle("BloxWeaponNoRecoilR219", {Title="降低本地枪械后坐力", Default=false,
        Callback=function(v) setWeaponMod("recoil", v) end})
    tab:AddToggle("BloxWeaponNoSpreadR219", {Title="本地枪械散布控制", Default=false,
        Callback=function(v) setWeaponMod("spread", v) end})
    tab:AddButton({Title="检查武器修改器状态", Callback=function()
        local snapshot = Bullet:Status()
        print(("[Vortexion/WeaponMods] status=%s candidates=%d native=%d table=%d calls=%d retries=%d errors=%d")
            :format(snapshot.weaponMods, snapshot.weaponCandidates, snapshot.weaponNativeHooks,
                snapshot.weaponTablePatches, snapshot.weaponCalls, snapshot.weaponRetries, snapshot.weaponPatchErrors))
        if c.Notify then
            local detail = snapshot.weaponObserved and "调用已命中；服务器效果待实测"
                or (snapshot.weaponNativeHooks > 0 and "已 Hook 但尚无实际调用"
                or (snapshot.weaponTablePatches > 0 and "仅替换表方法，游戏可能已缓存函数"
                or "没有定位到武器方法；请在战斗中重试"))
            c.Notify("武器诊断", detail)
        end
    end})
    tab:AddParagraph({ Title = "子弹追踪",
        Content = "默认 LeadOnly 只提供瞄准预测，不会改写子弹；联动开启瞄准辅助后才有客户端可见效果。Hitscan/Remote 需有效游戏接口和执行器权限，未确认服务器命中。" })
    tab:AddToggle("BloxBulletLinkCombat", { Title = "子弹追踪联动开启瞄准辅助", Default = true,
        Callback = function(v) Config.LinkCombat = v end })
    tab:AddButton({ Title = "检查实际子弹 Hook 调用次数", Callback = function()
        local s = Bullet:Status()
        local info = ("路径=%s Hook=%d / 类方法调用=%d / 参数修改=%d / 错误=%d"):
            format(tostring(s.path),s.hooks,s.hitscanCalls,s.hitscanRewrites,s.errors)
        print("[Vortexion/Blox/Bullet] " .. info)
        if c.Notify then c.Notify("子弹 Hook 诊断",info) end
    end })
    tab:AddButton({ Title = "检查真实武器类（只读安全扫描）", Callback = function()
        local msg = probeRuntimeWeapon()
        print("[Vortexion/Blox/Weapon] " .. msg)
        if c.Notify then c.Notify("武器接口", msg) end
    end })
    tab:AddToggle("BloxBulletEnabled", { Title = "启用子弹追踪", Default = false, Callback = function(v)
        if v then Bullet:Start() else Bullet:Stop() end
    end })
    tab:AddDropdown("BloxBulletMode", { Title = "追踪路径", Values = { "Auto", "LeadOnly", "Hitscan", "Remote", "Projectile" },
        Default = "LeadOnly", Callback = function(v)
            -- Switching path while active must release the old hook first.
            local wasEnabled = Config.Enabled
            if wasEnabled then Bullet:Stop() end
            Config.Mode = v
            state.activePath = resolveMode()
            if wasEnabled then Bullet:Start() end
        end })
    tab:AddSlider("BloxBulletHitChance", { Title = "改写命中率（%）", Min = 10, Max = 100, Default = 100, Rounding = 0,
        Callback = function(v) Config.HitChance = v / 100 end })
    tab:AddSlider("BloxBulletMaxAngle", { Title = "改写最大角（度）", Min = 5, Max = 90, Default = 35, Rounding = 0,
        Callback = function(v) Config.MaxAngle = v end })
    tab:AddToggle("BloxBulletEnvelope", { Title = "命中点包络回投", Default = true, Callback = function(v)
        Config.Envelope = v end })
    tab:AddToggle("BloxBulletWallCheck", { Title = "墙体检查", Default = true, Callback = function(v)
        Config.WallCheck = v end })
    tab:AddToggle("BloxBulletProjectile", { Title = "投射物追踪", Default = true, Callback = function(v)
        Config.ProjectileTrack = v end })
    tab:AddSlider("BloxBulletLerp", { Title = "投射物转向强度", Min = 0.05, Max = 1, Default = 0.35, Rounding = 2,
        Callback = function(v) Config.ProjectileLerp = v end })
    tab:AddToggle("BloxBulletDebug", { Title = "调试日志", Default = false, Callback = function(v)
        Config.Debug = v
        c.Debug = v
    end })
    tab:AddButton({ Title = "重新扫描武器接口", Callback = function()
        Bullet:Rescan()
        local status = Bullet:Status()
        c.Notify("子弹追踪", ("路径 %s · 钩子 %d · 监听远程 %d/%d"):format(
            status.path, status.hooks, status.remotes, status.totalRemotes)
            .. " / " .. tostring(status.probe))
    end })

    return Bullet
end
