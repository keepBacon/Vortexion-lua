-- Vortexion AOTR cloak: hides script-created instances from game scripts.
--
-- Adapted from the Vanity-General-Roblox design (local sandbox study). Game
-- anti-cheat / anti-ESP logic that enumerates children cannot see instances
-- registered here. The hook only rewrites enumeration calls made by game
-- threads (checkcaller() == false); executor-side reads are untouched.
--
-- Two defenses compose:
--   1. Enumeration filter - GetChildren/GetDescendants/FindFirstChild* skip
--      protected instances for game-thread callers.
--   2. RandomName - every created instance gets a 14-letter random name so
--      static name signatures ("_chams", "ESP") never match.
return function(common)
    local Workspace = common.Services.Workspace
    local Players = common.Services.Players

    local Cloak = {}
    local protectedSet = setmetatable({}, { __mode = "k" })
    local hookInstalled = false
    local namecallConnection = nil
    local inFilter = false

    local FILTERED_METHODS = {
        GetChildren = true,
        GetDescendants = true,
        FindFirstChild = true,
        FindFirstChildOfClass = true,
        FindFirstChildWhichIsA = true,
    }

    local function isHidden(instance)
        local current = instance
        local depth = 0
        while current and depth < 64 do
            if protectedSet[current] then return true end
            current = current.Parent
            depth += 1
        end
        return false
    end
    Cloak.IsHidden = isHidden

    -- Instances parented into Workspace or PlayerGui are game-visible surfaces:
    -- a hidden instance there still needs its enumeration filtered (handled by
    -- the hook), but gethui-parented instances are outside the game tree and
    -- need nothing. This distinction keeps the hook's hot path short.
    local function exposedToGame(instance)
        local current = instance
        local depth = 0
        while current and depth < 64 do
            if current == Workspace then return true end
            local playerGui = current == Players.LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then return true end
            current = current.Parent
            depth += 1
        end
        return false
    end
    Cloak.ExposedToGame = exposedToGame

    function Cloak.Protect(instance)
        if typeof(instance) ~= "Instance" then return instance end
        protectedSet[instance] = true
        return instance
    end

    function Cloak.Unprotect(instance)
        protectedSet[instance] = nil
    end

    --=========================================================================
    -- Hook. newcclosure wrapping keeps the hook invisible to islclosure /
    -- getinfo / string.dump probing (looks like a C closure). hookmetamethod
    -- is preferred over getrawmetatable + __namecall assignment because it
    -- restores cleanly and does not disturb other executor hooks.
    --=========================================================================
    local function installHook()
        if hookInstalled then return end
        if not (common.Caps.hookmetamethod and common.Caps.checkcaller) then
            common.Log("Cloak", "hook unavailable; enumeration filter disabled")
            return
        end

        local ok, err = pcall(function()
            local gameMetatable = getrawmetatable(game)
            local originalNamecall = gameMetatable.__namecall
            local namecallHook

            namecallHook = hookmetamethod(game, "__namecall", function(self, ...)
                -- Only game threads are filtered. Executor threads (this
                -- script, the UI library) must see everything or the UI dies.
                local fromGameScript = false
                if common.Caps.checkcaller then
                    local okCaller, caller = pcall(checkcaller)
                    fromGameScript = okCaller and (caller == false)
                end

                if fromGameScript and not inFilter then
                    local method = getnamecallmethod and getnamecallmethod() or nil
                    if method and FILTERED_METHODS[method] then
                        inFilter = true
                        local arguments = table.pack(...)
                        local okFilter, result = pcall(function()
                            if isHidden(self) then
                                -- The container itself is hidden: report it empty.
                                if method == "GetChildren" or method == "GetDescendants" then
                                    return {}
                                end
                                return nil
                            end
                            local children = originalNamecall(self, table.unpack(arguments, 1, arguments.n))
                            if method == "GetChildren" or method == "GetDescendants" then
                                local visible = {}
                                for _, child in ipairs(children) do
                                    if not isHidden(child) then
                                        table.insert(visible, child)
                                    end
                                end
                                return visible
                            end
                            return children
                        end)
                        inFilter = false
                        if okFilter then return result end
                    end
                end
                return originalNamecall(self, ...)
            end)

            if common.Caps.newcclosure then
                namecallHook = newcclosure(namecallHook)
            end
            namecallConnection = namecallHook
            hookInstalled = true
            common.Log("Cloak", "enumeration hook installed")
        end)

        if not ok then
            warn("[Vortexion/AOTR/Cloak] install failed: " .. tostring(err))
        end
    end

    function Cloak.Start()
        installHook()
    end

    function Cloak.Stop()
        -- The metatable hook cannot be surgically removed without the original
        -- reference on every executor; the filter is inert once protectedSet is
        -- cleared, so clearing is the supported teardown.
        table.clear(protectedSet)
        hookInstalled = false
        namecallConnection = nil
    end

    -- Keep the factory contract symmetric with the other AOTR modules.
    common:OnStop(function()
        Cloak.Stop()
    end)

    return Cloak
end
