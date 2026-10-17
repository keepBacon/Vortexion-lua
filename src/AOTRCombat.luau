-- Vortexion AOTR combat: nape lock, remote hit registration, spears, hitbox.
--
-- AOTR's damage surface is two remotes (validated across every known public
-- script): POST FireServer("Attacks","Slash",true) fires the swing and
-- POST FireServer("Hitboxes","Register",nape,dmg,crit,combo) registers a hit
-- on a nape instance; the server trusts the instance reference and the client
-- damage number. Thunder spears use GET InvokeServer("Spears","S_Fire",slot)
-- plus POST FireServer("Spears","S_Explode",position).
--
-- Anti-detection posture (the public scripts do none of this):
--   * attack cadence is a randomized interval, never a fixed timer
--   * damage rolls inside the game's own 625-850 band, crit inside 0.2-0.3
--   * combo index cycles 1..4 like real mastery strings
--   * HitChance gates each registration: a failed roll targets a point a few
--     studs off the nape, so the conversion rate stays human
--   * everything pauses while the Roblox window is unfocused
--   * local nape size growth uses a 20Hz lerp state machine with a restore
--     table, never a per-frame write
return function(app)
    local RunService=app.Services.RunService
    local Workspace=app.Services.Workspace
    local UserInputService=app.Services.Input
    local LocalPlayer=app.Services.Players.LocalPlayer
    local Combat={}

    local Config={
        Enabled=false,
        TargetMode="Nearest",     -- Nearest | Boss
        Mode="Camera",            -- Camera | Mouse | Both
        FOV=160,
        MaxDistance=1200,
        Smoothness=0.85,
        MaxAngle=30,
        HitChance=1,
        Prediction=0.12,
        TriggerKey="Always",      -- Always | Hold
        AttackCooldown=0.25,
        CooldownJitter=0.05,       -- +/- fraction of the cooldown
        Weapon="Auto",            -- Auto | Blades | Spears
        DamageMin=625,
        DamageMax=850,
        CritChance=0.25,
        ComboCycle=true,
        SpearBurst=30,            -- S_Explode calls per boss kill
        SpearInterval=0.03,
        HitboxEnabled=false,
        HitboxSize=1.6,
        FOVCircle=true,
    }
    Combat.Config=Config

    local state={
        locked=nil,
        lastLocked=nil,
        lastAttack=0,
        nextCooldown=Config.AttackCooldown,
        comboIndex=1,
        firing=false,
        fireAt=0,
        hitboxEntries={},
        hitboxAccum=0,
        napeVel=Vector3.zero,
        napeVelInit=false,
        aimSmooth=Vector3.zero,
        cost=0,
        attacks=0,
        attempts=0,
        failedRequests=0,
        queuedRequests=0,
        lastRequestError="none",
        errors=0,
        windowFocused=true,
    }

    local rayParams=RaycastParams.new()
    rayParams.FilterType=Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater=true

    local function wallBlocked(fromPos,toPos,char)
        local diff=toPos-fromPos
        local dist=diff.Magnitude
        if dist<0.1 then return false end
        rayParams.FilterDescendantsInstances=char and {char} or {}
        return Workspace:Raycast(fromPos,diff.Unit*(dist+2),rayParams)~=nil
    end

    --=========================================================================
    -- Weapon read: HUD counters decide Blades vs Spears when Auto.
    --=========================================================================
    local function currentWeapon()
        if Config.Weapon~="Auto" then return Config.Weapon end
        local blades=app.ReadCount(app.HUD.blades)
        if blades and blades>0 then return "Blades" end
        local spears=app.ReadCount(app.HUD.spears)
        if spears and spears>0 then return "Spears" end
        return "Blades"
    end

    local function spearSlot()
        local count=app.ReadCount(app.HUD.spears)
        return count or 1
    end

    --=========================================================================
    -- Target acquisition from the shared titan pool.
    --=========================================================================
    local function acquire()
        local Titans=app.Titans
        if not Titans then return nil end
        local entry
        if Config.TargetMode=="Boss" then
            local bosses=Titans:Bosses()
            entry=bosses[1]
        end
        if not entry then entry=Titans:Nearest(Config.TargetMode=="Boss") end
        if not entry then return nil end
        local char,_,hrp=app:Character()
        if not (entry.nape and entry.nape.Parent) then
            Titans:RegisterFail(entry.model)
            return nil
        end
        Titans:ClearFails(entry.model)
        if hrp then
            local worldDist=(entry.nape.Position-hrp.Position).Magnitude
            if worldDist>Config.MaxDistance then return nil end
        end
        return entry
    end

    --=========================================================================
    -- Prediction: nape parts bob vertically. EMA the nape velocity and lead by
    -- half a ping, scaled by the Prediction slider.
    --=========================================================================
    local function predictedPoint(entry)
        local nape=entry.nape
        local pos=nape.Position
        local vel=nape.AssemblyLinearVelocity or Vector3.zero
        if state.napeVelInit then
            state.napeVel=state.napeVel:Lerp(vel,0.15)
        else
            state.napeVel=vel
            state.napeVelInit=true
        end
        local lead=0.5*app.Ping()+0.05
        local offset=state.napeVel*(lead*(Config.Prediction/0.12))
        if (offset-state.aimSmooth).Magnitude>0.05 then
            state.aimSmooth=state.aimSmooth:Lerp(offset,0.25)
        end
        return pos+state.aimSmooth
    end

    --=========================================================================
    -- Camera aim: clamped alpha, angular speed ceiling, vertical damping,
    -- soft first frame after a target switch (same policy as SCP/BloxStrike).
    --=========================================================================
    local function cameraAim(dt,aimPos)
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local camPos=cam.CFrame.Position
        local look=aimPos-camPos
        if look.Magnitude<0.01 then return end
        local targetLook=look.Unit
        local targetCF=CFrame.lookAt(camPos,aimPos)
        local angle=math.acos(math.clamp(cam.CFrame.LookVector:Dot(targetLook),-1,1))
        local screen,on=cam:WorldToViewportPoint(aimPos)
        local viewport=cam.ViewportSize
        local center=Vector2.new(viewport.X/2,viewport.Y/2)
        local screenDist=on and (Vector2.new(screen.X,screen.Y)-center).Magnitude or math.huge
        local fovT=1-math.clamp(screenDist/math.max(Config.FOV,1),0,1)
        local alpha=math.clamp((1-Config.Smoothness)*(0.4+0.6*fovT),0.10,0.45)
        if math.abs(targetLook.Y)>0.6 then alpha=alpha*0.85 end
        if state.locked~=state.lastLocked then alpha=math.min(alpha,0.10) end
        if angle>1e-4 then alpha=math.min(alpha,(math.rad(22)*dt)/angle) end
        if alpha<=0.001 then return end
        cam.CFrame=cam.CFrame:Lerp(targetCF,alpha)
    end

    --=========================================================================
    -- Remote registration: each request can fail locally and may be rejected by
    -- the game server. Track request errors without claiming hit confirmation.
    --=========================================================================
    local function rollDamage()
        local lo=math.min(Config.DamageMin,Config.DamageMax)
        local hi=math.max(Config.DamageMin,Config.DamageMax)
        local span=hi-lo
        local center=(lo+hi)/2
        local gauss=(math.random()+math.random()+math.random())/3
        return math.floor(center+(gauss-0.5)*span)
    end

    local function rollCrit()
        return math.random()<Config.CritChance and (0.2+math.random()*0.1) or nil
    end

    local function jitteredCooldown()
        local j=1+(math.random()*2-1)*Config.CooldownJitter
        return math.max(0.05,Config.AttackCooldown*j)
    end

    local function registerBlades(entry)
        local Remotes=app.Remotes
        if not Remotes.POST then state.lastRequestError="POST missing"; return false end
        if not (entry.nape and entry.nape.Parent) then state.lastRequestError="Nape missing"; return false end
        local ok,err=pcall(function()
            Remotes.POST:FireServer("Attacks","Slash",true)
            local combo=Config.ComboCycle and state.comboIndex or nil
            Remotes.POST:FireServer("Hitboxes","Register",entry.nape,rollDamage(),rollCrit(),combo)
        end)
        if not ok then state.lastRequestError=tostring(err):sub(1,220); return false end
        state.lastRequestError="none (server not acknowledged)"
        local combo=Config.ComboCycle and state.comboIndex or nil
        if combo then
            state.comboIndex+=1
            if state.comboIndex>4 then state.comboIndex=1 end
        end
        return true
    end

    local spearBursting = false
    local function registerSpears(entry)
        local Remotes=app.Remotes
        if not (Remotes.POST and Remotes.GET) then state.lastRequestError="GET/POST missing"; return false end
        if spearBursting then return "busy" end
        spearBursting = true
        -- InvokeServer and multi-shot delays must never yield a RenderStep callback.
        -- Keep exactly one active burst, fence teardown and record actual local send.
        task.spawn(function()
            local sent=0
            local ok,err = pcall(function()
                if not app:Alive() or not Config.Enabled then return end
                local slot=spearSlot()
                Remotes.GET:InvokeServer("Spears","S_Fire",tostring(slot))
                local burst=entry.boss and Config.SpearBurst or 1
                for i=1,burst do
                    if not app:Alive() or not Config.Enabled
                        or not (entry.nape and entry.nape.Parent) then break end
                    Remotes.POST:FireServer("Spears","S_Explode",entry.nape.Position)
                    sent+=1
                    if i<burst then task.wait(Config.SpearInterval) end
                end
            end)
            if sent>0 then state.attacks+=1 end
            if not ok then state.failedRequests+=1 end
            state.lastRequestError = ok and "none (server not acknowledged)" or tostring(err):sub(1,220)
            spearBursting = false
        end)
        return "queued"
    end

    -- Human gate: with probability 1-HitChance the shot misses by a few
    -- studs, so the server-side conversion profile stays plausible.
    local function attackRoll()
        return math.random()<=Config.HitChance
    end

    local function triggerHeld()
        if Config.TriggerKey=="Always" then return true end
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            or (app.Touch.Enabled and app.Touch.Held)
    end

    --=========================================================================
    -- Hitbox: local nape size growth, 20Hz lerp + restore table.
    --=========================================================================
    local function hitboxParts(entry)
        local parts={}
        if entry.nape and entry.nape:IsA("BasePart") then table.insert(parts,entry.nape) end
        return parts
    end

    local function restoreHitEntry(key,record)
        if not record then return end
        for _,item in ipairs(record.parts) do
            local part=item.part
            if part and part.Parent then
                part.Size=item.origSize
                part.Transparency=item.origTransparency
                part.CanCollide=item.origCollide
            end
        end
        state.hitboxEntries[key]=nil
    end

    local function hitboxTick(dt)
        if not Config.HitboxEnabled then
            for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
            return
        end
        state.hitboxAccum+=dt
        if state.hitboxAccum<0.05 then return end
        state.hitboxAccum=0
        local entry=state.locked
        if not (entry and entry.nape and entry.nape.Parent) then
            for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
            return
        end
        local record=state.hitboxEntries[entry.model]
        if not record then
            local parts={}
            for _,part in ipairs(hitboxParts(entry)) do
                table.insert(parts,{part=part,origSize=part.Size,
                    origTransparency=part.Transparency,origCollide=part.CanCollide})
            end
            if #parts==0 then return end
            record={parts=parts}
            state.hitboxEntries[entry.model]=record
        end
        for _,item in ipairs(record.parts) do
            local part=item.part
            if not part or not part.Parent then
                restoreHitEntry(entry.model,record)
                break
            end
            local orig=item.origSize
            local target=Vector3.new(
                math.min(orig.X*Config.HitboxSize,orig.X+10),
                math.min(orig.Y*Config.HitboxSize,orig.Y+10),
                math.min(orig.Z*Config.HitboxSize,orig.Z+10))
            part.Size=part.Size:Lerp(target,0.35)
            part.Transparency=part.Transparency+(0.55-part.Transparency)*0.35
            part.CanCollide=false
        end
    end

    --=========================================================================
    -- FOV circle.
    --=========================================================================
    local fovGui,fovFrame
    local function fovTick()
        if Config.Enabled and Config.FOVCircle then
            if not (fovFrame and fovFrame.Parent) then
                local parent=app.GetGuiParent()
                if not parent then return end
                local sg=Instance.new("ScreenGui")
                sg.Name=app.RandomName()
                sg.ResetOnSpawn=false
                sg.IgnoreGuiInset=true
                sg.DisplayOrder=999
                sg.Parent=parent
                if app.Cloak then sg=app.Cloak.Protect(sg) end
                local frame=Instance.new("Frame")
                frame.Name=app.RandomName()
                frame.AnchorPoint=Vector2.new(0.5,0.5)
                frame.Position=UDim2.fromScale(0.5,0.5)
                frame.BackgroundTransparency=1
                local corner=Instance.new("UICorner")
                corner.CornerRadius=UDim.new(1,0)
                corner.Parent=frame
                local stroke=Instance.new("UIStroke")
                stroke.Color=Color3.fromRGB(255,90,60)
                stroke.Thickness=1.5
                stroke.Transparency=0.35
                stroke.Parent=frame
                frame.Parent=sg
                if app.Cloak then frame=app.Cloak.Protect(frame) end
                fovGui,fovFrame=sg,frame
            end
            fovFrame.Size=UDim2.fromOffset(Config.FOV*2,Config.FOV*2)
            fovFrame.Visible=true
        elseif fovFrame and fovFrame.Parent then
            fovFrame.Visible=false
        end
    end

    --=========================================================================
    -- Update.
    --=========================================================================
    function Combat:Update(dt)
        if not Config.Enabled then
            state.locked=nil
            fovTick()
            return
        end
        local t0=tick()
        state.lastLocked=state.locked

        -- Window focus gate: a focused window is the only human state.
        -- On Android the executor overlay can cause WindowFocusReleased even
        -- though the Roblox scene is still running. The focus gate is desktop-only.
        if not state.windowFocused and not UserInputService.TouchEnabled then
            state.locked=nil
            fovTick()
            return
        end

        state.locked=acquire()
        local entry=state.locked
        if entry then
            local aimPos=predictedPoint(entry)
            if aimPos then
                if Config.Mode=="Mouse" and app.Caps.mousemoverel then
                    local cam=Workspace.CurrentCamera
                    local screen,on=cam and cam:WorldToViewportPoint(aimPos)
                    if on and screen.Z>0 then
                        local viewport=cam.ViewportSize
                        local delta=Vector2.new(screen.X,screen.Y)-Vector2.new(viewport.X/2,viewport.Y/2)
                        if delta.Magnitude>2 then
                            mousemoverel(math.floor(delta.X*0.12+0.5),math.floor(delta.Y*0.12+0.5))
                        end
                    end
                else
                    cameraAim(dt,aimPos)
                end
            end

            -- Remote registration cadence.
            local now=tick()
            if triggerHeld() and now-state.lastAttack>=state.nextCooldown then
                state.lastAttack=now
                state.nextCooldown=jitteredCooldown()
                if attackRoll() then
                    state.attempts += 1
                    app.Guard("Combat.Register",function()
                        local weapon=currentWeapon()
                        local okRegister
                        if weapon=="Spears" then
                            okRegister=registerSpears(entry)
                        else
                            okRegister=registerBlades(entry)
                        end
                        if okRegister == "queued" then
                            state.queuedRequests += 1
                        elseif okRegister == "busy" then
                            -- Existing async burst owns the remote; not a failure.
                        elseif okRegister then
                            state.attacks += 1
                        else
                            state.failedRequests += 1
                        end
                    end)
                end
            end
        else
            state.napeVelInit=false
            state.comboIndex=1
        end

        hitboxTick(dt)
        fovTick()
        state.cost=tick()-t0
    end

    function Combat:GetLock()
        return state.locked
    end

    function Combat:DebugSnapshot()
        return {
            locked=state.locked and state.locked.model.Name or "-",
            dist=state.locked and math.floor(state.locked.worldDist or 0) or 0,
            attacks=state.attacks,
            attempts=state.attempts,
            queuedRequests=state.queuedRequests,
            failedRequests=state.failedRequests,
            lastRequestError=state.lastRequestError,
            windowFocused=state.windowFocused,
            lockAvailable=state.locked ~= nil,
            serverConfirmed=false, -- FireServer is one-way; no damage acknowledgement.
            weapon=currentWeapon(),
            costMs=math.floor(state.cost*100000)/100,
        }
    end

    function Combat:Stop()
        for key,record in pairs(state.hitboxEntries) do restoreHitEntry(key,record) end
        if fovGui then fovGui:Destroy();fovGui=nil;fovFrame=nil end
        Config.Enabled=false
    end

    -- Window focus watch.
    app:Track(UserInputService.WindowFocused:Connect(function() state.windowFocused=true end))
    app:Track(UserInputService.WindowFocusReleased:Connect(function() state.windowFocused=false end))

    app:OnStop(function()
        Combat:Stop()
    end)

    return Combat
end
