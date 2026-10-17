-- Vortexion AOTR farm: reload/refill automation, server-side FPS settings.
--
-- Reload triggers read the HUD blade counter; refills resolve once from
-- workspace.Unclimbable.Reloads and are re-resolved when the part leaves.
-- The FPS settings go through the game's own settings remote
-- (Functions/Settings), which is a server-side change: no local lighting or
-- render hacks that a client-side scan could notice.
return function(app)
    local Workspace=app.Services.Workspace
    local Players=app.Services.Players
    local Farm={}

    local Config={
        AutoReload=false,
        AutoRefill=false,
        CheckInterval=0.5,
        FPSSettings=false,
        Settings={
            Damage_Indicator="Off",
            Shadows="Off",
            Blur="Off",
            Player_Effects="Off",
            Effects=0,
            Music=0,
        },
    }
    Farm.Config=Config

    local state={
        refillPart=nil,
        settingsApplied=false,
        reloads=0,
        refills=0,
    }

    --=========================================================================
    -- Refill point: workspace.Unclimbable.Reloads.<something>.Refill
    --=========================================================================
    local function resolveRefill()
        local root=Workspace:FindFirstChild("Unclimbable")
        local reloads=root and root:FindFirstChild("Reloads")
        if not reloads then return nil end
        for _,station in ipairs(reloads:GetChildren()) do
            local refill=station:FindFirstChild("Refill")
            if refill and refill:IsA("BasePart") then return refill end
        end
        return nil
    end
    Farm.ResolveRefill=resolveRefill

    local function doReload()
        local Remotes=app.Remotes
        if not Remotes.GET then return false end
        local have,max=app.ReadCount(app.HUD.blades)
        if not have then return false end
        if have>0 then return false end
        local ok=pcall(function()
            Remotes.GET:InvokeServer("Blades","Reload")
        end)
        if ok then state.reloads+=1 end
        return ok
    end

    local function doRefill()
        local Remotes=app.Remotes
        if not Remotes.POST then return false end
        if not state.refillPart or not state.refillPart.Parent then
            state.refillPart=resolveRefill()
            if not state.refillPart then return false end
        end
        local ok=pcall(function()
            Remotes.POST:FireServer("Attacks","Reload",state.refillPart)
        end)
        if ok then state.refills+=1 end
        return ok
    end

    --=========================================================================
    -- Server-side settings: one-shot per session, idempotent.
    --=========================================================================
    local function applySettings()
        if state.settingsApplied then return end
        local Remotes=app.Remotes
        if not Remotes.GET then return end
        local ok=pcall(function()
            for key,value in pairs(Config.Settings) do
                Remotes.GET:InvokeServer("Functions","Settings",key,value)
                task.wait(0.05)
            end
        end)
        state.settingsApplied=ok
        app.Log("farm settings applied=%s",tostring(ok))
    end

    local accum=0
    local function tickFarm(dt)
        if Config.AutoReload then app.Guard("Farm.Reload",doReload) end
        if Config.AutoRefill then app.Guard("Farm.Refill",doRefill) end
    end

    function Farm:Update(dt)
        if Config.FPSSettings and not state.settingsApplied then
            app.Guard("Farm.Settings",applySettings)
        end
        accum+=dt
        if accum<Config.CheckInterval then return end
        accum=0
        app.Guard("Farm",tickFarm,dt)
    end

    function Farm:DebugSnapshot()
        return {reloads=state.reloads,refills=state.refills,
            refill=state.refillPart and state.refillPart.Parent and true or false}
    end

    app:OnStop(function()
        Config.AutoReload=false
        Config.AutoRefill=false
    end)

    return Farm
end
