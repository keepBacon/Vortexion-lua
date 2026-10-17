-- Vortexion R223 AOTR resource automation.
-- No claim of successful resupply is made until an observable state changes.
-- GET/POST are game protocol candidates documented by independent public implementations.
return function(app)
    local Players=app.Services.Players
    local Workspace=app.Services.Workspace
    local player=Players.LocalPlayer
    local Farm={}
    local Config={
        AutoReload=false,
        AutoRefill=false,
        CheckInterval=0.5,
        GasThreshold=35,
        RefillCooldown=3.0,
        ReloadCooldown=1.8,
        FPSSettings=false,
        Settings={Damage_Indicator="Off",Shadows="Off",Blur="Off",Player_Effects="Off",Effects=0,Music=0},
    }
    Farm.Config=Config

    local state={
        reloads=0, reloadAttempts=0, reloadVerified=0, reloadStatus="idle",
        refills=0, refillAttempts=0, refillVerified=0, denied=0,
        lastRefillStatus="idle", lastRefillDistance=nil,
        lastRefillAt=-math.huge, lastReloadAt=-math.huge,
        refillPart=nil, lastStationScan=-math.huge, candidates={},
        pending=nil, reloadPending=nil, settingsApplied=false,
        lastWeapon="unknown", lastRead={}, lastRemoteProbe=-math.huge,
        channelSwitches=0, manual=false,
    }
    local function now() return os.clock() end
    local function safeName(v)
        if not v then return "-" end
        local ok,n=pcall(function() return v:GetFullName() end)
        return ok and n or tostring(v.Name or "?")
    end
    local function aliveRoot()
        local char=player and player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not root or (hum and hum.Health<=0) then return nil end
        return root
    end
    local function readHUD(force)
        app.ProbeHUD(force==true)
        local hud=app.HUD
        local b,bMax=app.ReadCount(hud.blades)
        local s,sMax=app.ReadCount(hud.spears)
        local gas=app.ReadPercent(hud.gas)
        return {blades=b,bladesMax=bMax,spears=s,spearsMax=sMax,gas=gas}
    end
    local function weaponType()
        local weapon
        pcall(function() weapon=player:GetAttribute("Weapon") end)
        if type(weapon)=="string" then
            if string.find(string.lower(weapon),"blade",1,true) then return "Blades" end
            if string.find(string.lower(weapon),"spear",1,true) then return "Spears" end
        end
        local gui=player and player:FindFirstChild("PlayerGui")
        local frame=gui and gui:FindFirstChild("Interface")
        frame=frame and frame:FindFirstChild("HUD")
        frame=frame and frame:FindFirstChild("Main")
        frame=frame and frame:FindFirstChild("Top")
        frame=frame and frame:FindFirstChild("7")
        if frame then
            local blades=frame:FindFirstChild("Blades")
            local spears=frame:FindFirstChild("Spears")
            if blades and blades.Visible then return "Blades" end
            if spears and spears.Visible then return "Spears" end
        end
        return "unknown"
    end
    local function bladeMissing()
        local char=player and player.Character
        local rig=char and char:FindFirstChild("Rig_" .. player.Name)
        if not rig then return nil end
        local parts={}
        for _,side in ipairs({"LeftHand","RightHand"}) do
            local hand=rig:FindFirstChild(side)
            if hand then
                for _,child in ipairs(hand:GetChildren()) do
                    if child:IsA("BasePart") and string.find(child.Name,"Blade_",1,true)==1 then
                        parts[#parts+1]=child
                    end
                end
            end
        end
        if #parts==0 then return nil end
        for _,blade in ipairs(parts) do
            if blade.Transparency<0.9 and blade:GetAttribute("Broken")~=true then
                return false
            end
        end
        return true
    end
    local function findRemotes()
        local remotes=app.Remotes
        if not remotes then return nil,nil end
        if (not remotes.GET or not remotes.POST) and now()-state.lastRemoteProbe>=2 then
            state.lastRemoteProbe=now()
            app.ProbeRemotes()
        end
        if remotes.GET and not remotes.GET:IsA("RemoteFunction") then remotes.GET=nil end
        if remotes.POST and not remotes.POST:IsA("RemoteEvent") then remotes.POST=nil end
        return remotes.GET,remotes.POST
    end
    -- Map data is dynamic. Build the cache infrequently and re-check Instance ancestry.
    local function scanStations()
        local roots={}
        local waves=Workspace:FindFirstChild("Waves")
        local climbable=Workspace:FindFirstChild("Climbable")
        local unclimbable=Workspace:FindFirstChild("Unclimbable")
        if waves then roots[#roots+1]=waves end
        if climbable then roots[#roots+1]=climbable end
        if unclimbable then roots[#roots+1]=unclimbable end
        local stations,seen={},{}
        local function take(node)
            if not node or not node:IsA("BasePart") or seen[node] then return end
            seen[node]=true
            stations[#stations+1]=node
        end
        for _,root in ipairs(roots) do
            -- Waves maps frequently put the usable part under Zones.Refill.Hitbox.
            for _,node in ipairs(root:GetDescendants()) do
                if node:IsA("BasePart") then
                    if node.Name=="Refill" then
                        take(node)
                    elseif node.Name=="Hitbox" and node.Parent and
                        (node.Parent.Name=="Refill" or node.Parent.Name=="Gas") then
                        take(node)
                    elseif (node.Name=="Gas" or node.Name=="Refill") and
                        node.Parent and node.Parent.Name=="Props" then
                        take(node)
                    end
                end
            end
        end
        state.candidates=stations
        state.lastStationScan=now()
        return stations
    end
    local function resolveRefill(force)
        local root=aliveRoot()
        if not root then return nil end
        if force or now()-state.lastStationScan>5 then scanStations() end
        local best,dist=nil,math.huge
        for _,part in ipairs(state.candidates) do
            if part.Parent then
                local d=(part.Position-root.Position).Magnitude
                if d<dist then best,dist=part,d end
            end
        end
        state.refillPart=best
        state.lastRefillDistance=best and dist or nil
        return best
    end
    Farm.ResolveRefill=resolveRefill

    local function changed(before,after,reason)
        if not before or not after then return false end
        -- Confirm the requested resource, not an unrelated gauge increasing.
        local key=reason=="blades" and "blades" or reason=="spears" and "spears" or "gas"
        return type(before[key])=="number" and type(after[key])=="number"
            and after[key]>before[key]
    end
    local function observe()
        if state.reloadPending then
            local p=state.reloadPending
            local missing=bladeMissing()
            if missing==false then
                state.reloadVerified+=1
                state.reloadStatus="equipped blade confirmed"
                state.reloadPending=nil
            elseif now()-p.at>3 then
                state.reloadStatus="GET returned; blade equip not confirmed"
                state.reloadPending=nil
            end
        end
        if not state.pending then return end
        local p=state.pending
        local after=readHUD(true)
        local root=aliveRoot()
        local moved=root and p.origin and (root.Position-p.origin).Magnitude>25
        if changed(p.before,after,p.reason) then
            state.refillVerified+=1
            state.lastRefillStatus="confirmed by HUD ("..p.channel..")"
            state.pending=nil
            state.channelSwitches=0
        elseif now()-p.at>=3.0 then
            state.denied+=1
            state.channelSwitches+=1
            state.lastRefillStatus=(moved and "station relocation; HUD unchanged" or
                "server unconfirmed ("..p.channel..", HUD unchanged)")
            state.pending=nil
        end
    end
    local function doReload(view,weapon)
        if not Config.AutoReload or weapon~="Blades" then return false end
        if state.reloadPending or now()-state.lastReloadAt<Config.ReloadCooldown then return false end
        local missing=bladeMissing()
        if missing==nil then state.reloadStatus="blade rig unavailable"; return false end
        if not missing then state.reloadStatus="blades equipped"; return false end
        if view.blades==nil then state.reloadStatus="blade reserve HUD missing"; return false end
        if view.blades<=0 then state.reloadStatus="reserves empty; refill needed"; return false end
        local GET=findRemotes()
        if not GET then state.reloadStatus="GET missing (retrying discovery)"; return false end
        state.reloadAttempts+=1
        state.lastReloadAt=now()
        local ok,result=pcall(function() return GET:InvokeServer("Blades","Reload") end)
        if ok then
            state.reloads+=1
            state.reloadPending={at=now()}
            state.reloadStatus="equip requested; awaiting blade model"
        else
            state.reloadStatus="GET rejected: "..tostring(result):sub(1,105)
        end
        return ok
    end
    local function needRefill(view,weapon)
        -- Refilling reserves and equipping a held blade are two separate actions.
        if weapon=="Blades" then
            if type(view.blades)=="number" and view.blades<=0 then return true,"blades" end
        elseif weapon=="Spears" then
            if type(view.spears)=="number" and view.spears<=0 then return true,"spears" end
        end
        if type(view.gas)=="number" and view.gas<=Config.GasThreshold then return true,"gas" end
        return false,"healthy or HUD unavailable"
    end
    local function doRefill(view,weapon,manual)
        if state.pending or now()-state.lastRefillAt<Config.RefillCooldown then return false end
        local needs,reason=needRefill(view,weapon)
        if not needs and not manual then
            state.lastRefillStatus=reason
            return false
        end
        local part=resolveRefill(false)
        if not part then
            state.lastRefillStatus="station not found (scan needed)"
            return false
        end
        local GET,POST=findRemotes()
        if not GET and not POST then
            state.lastRefillStatus="GET/POST missing (retrying discovery)"
            return false
        end
        -- Public implementations use both variants; for blades prefer GET,
        -- for spears / gas prefer POST. A failed confirmation changes preference
        -- for the next attempt, and no second request is fired simultaneously.
        local preferGET=weapon=="Blades" and reason=="blades"
        if state.channelSwitches%2==1 then preferGET=not preferGET end
        local channel,remote
        if preferGET then channel,remote="GET",GET or POST else channel,remote="POST",POST or GET end
        if remote==POST then channel="POST" else channel="GET" end
        local root=aliveRoot()
        if not root then state.lastRefillStatus="character not ready"; return false end
        local origin=root.Position
        state.lastRefillAt=now()
        state.refillAttempts+=1
        local ok,err=pcall(function()
            if channel=="GET" then
                remote:InvokeServer("Attacks","Reload",part)
            else
                remote:FireServer("Attacks","Reload",part)
            end
        end)
        if ok then
            state.refills+=1 -- request sent, not verified
            state.pending={at=now(),before=view,origin=origin,channel=channel,reason=reason}
            state.lastRefillStatus="requested "..reason.." via "..channel.."; verifying"
        else
            state.denied+=1
            state.channelSwitches+=1
            state.lastRefillStatus="remote "..channel.." failed: "..tostring(err):sub(1,95)
        end
        return ok
    end
    function Farm:ManualRefill()
        if state.pending then return false end
        local view=readHUD(true)
        local weapon=weaponType()
        state.lastWeapon=weapon
        return doRefill(view,weapon,true)
    end
    function Farm:RefreshStation()
        local part=resolveRefill(true)
        return part~=nil
    end

    local function applySettings()
        if state.settingsApplied then return end
        local GET=findRemotes()
        if not GET then return end
        local ok=pcall(function()
            for key,value in pairs(Config.Settings) do
                GET:InvokeServer("Functions","Settings",key,value)
                task.wait(0.05)
            end
        end)
        state.settingsApplied=ok
    end
    local elapsed=0
    function Farm:Update(dt)
        if Config.FPSSettings and not state.settingsApplied then app.Guard("Farm.Settings",applySettings) end
        if not Config.AutoReload and not Config.AutoRefill and not state.pending and not state.reloadPending then return end
        elapsed+=math.min(tonumber(dt) or 0.25,0.5)
        if elapsed<Config.CheckInterval then return end
        elapsed=0
        local root=aliveRoot()
        if not root then
            state.reloadStatus="character not ready"
            state.lastRefillStatus="character not ready"
            return
        end
        local view=readHUD(false)
        local weapon=weaponType()
        state.lastRead=view
        state.lastWeapon=weapon
        app.Guard("Farm.Observe",observe)
        if Config.AutoReload then app.Guard("Farm.Reload",doReload,view,weapon) end
        if Config.AutoRefill then app.Guard("Farm.Refill",doRefill,view,weapon,false) end
    end
    function Farm:DebugSnapshot()
        return {
            reloads=state.reloads,reloadAttempts=state.reloadAttempts,
            reloadVerified=state.reloadVerified,reloadStatus=state.reloadStatus,
            refills=state.refills, attempts=state.refillAttempts,
            refillVerified=state.refillVerified,
            refill=state.refillPart and state.refillPart.Parent~=nil or false,
            station=safeName(state.refillPart), stations=#state.candidates,
            status=state.lastRefillStatus,distance=state.lastRefillDistance,
            unconfirmed=state.denied,weapon=state.lastWeapon,
            blades=state.lastRead.blades,spears=state.lastRead.spears,gas=state.lastRead.gas,
            GET=app.Remotes.GET~=nil,POST=app.Remotes.POST~=nil,
        }
    end
    app:OnStop(function()
        Config.AutoReload=false
        Config.AutoRefill=false
        state.pending=nil
        state.reloadPending=nil
    end)
    return Farm
end
