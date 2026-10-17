-- Vortexion AOTR movement: hover glide, teleport follow, noclip, speed, anti-AFK.
--
-- Hover drives AssemblyLinearVelocity toward a hold point above the locked
-- titan (the same shape the game's own ODM flight uses), which replicates as
-- ordinary motion. The teleport mode exists for completeness but is the
-- noisy path; hover is the default.
return function(app)
    local RunService=app.Services.RunService
    local Workspace=app.Services.Workspace
    local UserInputService=app.Services.Input
    local LocalPlayer=app.Services.Players.LocalPlayer
    local Movement={}

    local Config={
        FollowEnabled=false,
        MoveMode="Hover",        -- Hover | Teleport
        HeightOffset=25,         -- studs above the titan HRP hold point
        BehindOffset=30,         -- studs behind the titan HRP
        GlideSpeed=120,
        FollowBossOnly=false,
        SpeedEnabled=false,
        SpeedValue=24,
        Noclip=false,
        AntiAFK=true,
        TouchAssist=false,     -- mobile touch-fly assist: strafe / forward-back / lift
        TouchFlySpeed=120,
    }
    Movement.Config=Config

    local state={
        pulse="idle",
        pulseAt=0,
        speedBackup=nil,
        speedHumanoid=nil,
        collisionBackup={},
        noclipAccum=0,
        following=false,
        lastDragX=0,
        lastDragY=0,
        lastVertical=0,
    }

    local function restoreSpeed()
        local hum=state.speedHumanoid
        if hum and hum.Parent and state.speedBackup~=nil then
            pcall(function() hum.WalkSpeed=state.speedBackup end)
        end
        state.speedHumanoid=nil
        state.speedBackup=nil
        state.pulse="idle"
    end

    local function restoreCollision()
        for part,value in pairs(state.collisionBackup) do
            if part.Parent then pcall(function() part.CanCollide=value end) end
            state.collisionBackup[part]=nil
        end
        state.noclipAccum=0
    end

    local function holdPoint(entry)
        if not entry then return nil end
        local model=entry.model
        local hrp=model:FindFirstChild("HumanoidRootPart")
        if hrp then
            return (hrp.CFrame*CFrame.new(0,Config.HeightOffset,Config.BehindOffset)).Position
        end
        if entry.nape and entry.nape.Parent then
            return entry.nape.Position+Vector3.new(0,Config.HeightOffset,0)
        end
        return nil
    end

    local function updateFollow(dt)
        local char,hum,hrp=app:Character()
        if not (char and hrp) then return end
        local entry=app.Combat and app.Combat:GetLock()
        if not entry and app.Titans then entry=app.Titans:Nearest(false) end
        if not entry then return end
        if Config.FollowBossOnly and not entry.boss then return end
        local target=holdPoint(entry)
        if not target then return end

        if Config.MoveMode=="Teleport" then
            hrp.CFrame=CFrame.new(target)
        else
            local dir=target-hrp.Position
            if dir.Magnitude>2 then
                hrp.AssemblyLinearVelocity=dir.Unit*Config.GlideSpeed
            else
                hrp.AssemblyLinearVelocity=Vector3.zero
            end
        end
    end

    local function updateSpeed()
        local char,hum,hrp=app:Character()
        if not (char and hum and hrp) then return end
        if state.speedHumanoid~=hum then
            restoreSpeed()
            state.speedHumanoid=hum
            state.speedBackup=hum.WalkSpeed
        end
        hum.WalkSpeed=Config.SpeedValue
        local dir=hum.MoveDirection
        if dir.Magnitude<=0 then return end
        local now=tick()
        if state.pulse=="idle" then state.pulse="boost";state.pulseAt=now end
        local boosting
        if state.pulse=="boost" then
            if now-state.pulseAt>=0.1 then state.pulse="coast";state.pulseAt=now;boosting=false
            else boosting=true end
        else
            if now-state.pulseAt>=0.15 then state.pulse="boost";state.pulseAt=now;boosting=true
            else boosting=false end
        end
        local target=dir.Unit*(boosting and Config.SpeedValue or Config.SpeedValue*0.16)
        hrp.AssemblyLinearVelocity=Vector3.new(target.X,hrp.AssemblyLinearVelocity.Y,target.Z)
    end

    local function updateNoclip(dt)
        state.noclipAccum=(state.noclipAccum or 0)+(dt or 0)
        if state.noclipAccum<0.05 then return end
        state.noclipAccum=0
        local char=app.Character and select(1,app:Character())
        if not char then
            local c=LocalPlayer.Character
            char=c
        end
        if not char then return end
        for _,part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if state.collisionBackup[part]==nil then state.collisionBackup[part]=part.CanCollide end
                part.CanCollide=false
            end
        end
    end

    -- Mobile touch-fly assist: right-half drag drives camera-relative motion.
    -- Single-finger X strafes, single-finger Y moves forward/back, two-finger
    -- vertical lifts. Release stops assist writes and keeps current momentum
    -- (no automatic braking). Runs on the same Heartbeat cadence as the rest
    -- of movement; never throttled by the visual interval.
    local function updateTouchFly()
        local touch=app.Touch
        if not (touch and touch.Enabled and touch.Held) then
            -- Released or disabled: only the input deltas reset. Any velocity
            -- already written stays; the assist never brakes the character.
            state.lastDragX=0
            state.lastDragY=0
            state.lastVertical=0
            return
        end
        local ok,drag,vertical=pcall(function() return touch:Drag() end)
        if not ok or not drag then
            state.lastDragX=0
            state.lastDragY=0
            state.lastVertical=0
            return
        end
        local dx=drag.X-state.lastDragX
        local dy=drag.Y-state.lastDragY
        local dv=(tonumber(vertical) or 0)-state.lastVertical
        state.lastDragX=drag.X
        state.lastDragY=drag.Y
        state.lastVertical=vertical or 0
        local _,_,hrp=app:Character()
        if not hrp then return end
        local camera=Workspace.CurrentCamera
        local cf=camera and camera.CFrame
        local vel=hrp.AssemblyLinearVelocity
        local hx,hz=vel.X,vel.Z
        if dx~=0 and cf then
            local rx,rz=cf.RightVector.X,cf.RightVector.Z
            local mag=math.sqrt(rx*rx+rz*rz)
            if mag>0.0001 then
                local scale=math.clamp(dx/8,-1,1)*Config.TouchFlySpeed
                hx,hz=(rx/mag)*scale,(rz/mag)*scale
            end
        end
        if dy~=0 and cf then
            -- Forward/back along the flattened camera LookVector. Downward
            -- drag (positive deltaY in screen space) moves backward.
            local lx,lz=cf.LookVector.X,cf.LookVector.Z
            local mag=math.sqrt(lx*lx+lz*lz)
            if mag>0.0001 then
                local scale=-math.clamp(dy/8,-1,1)*Config.TouchFlySpeed
                hx,hz=hx+(lx/mag)*scale,hz+(lz/mag)*scale
            end
        end
        local vy=vel.Y
        if dv~=0 then
            vy=math.clamp(dv/8,-1,1)*Config.TouchFlySpeed
        end
        hrp.AssemblyLinearVelocity=Vector3.new(hx,vy,hz)
    end

    local function teleportLobby()
        local Remotes=app.Remotes
        if Remotes.GET then
            local ok=pcall(function()
                Remotes.GET:InvokeServer("Functions","Teleport","Lobby")
            end)
            if ok then return true end
        end
        local TeleportService=game:GetService("TeleportService")
        pcall(function()
            TeleportService:Teleport(game.PlaceId,LocalPlayer)
        end)
        return false
    end
    Movement.TeleportLobby=teleportLobby

    if LocalPlayer.CharacterRemoving then
        app:Track(LocalPlayer.CharacterRemoving:Connect(function()
            restoreSpeed()
            restoreCollision()
        end))
    end
    if LocalPlayer.CharacterAdded then
        app:Track(LocalPlayer.CharacterAdded:Connect(function()
            restoreSpeed()
            restoreCollision()
        end))
    end

    local function antiAFK()
        local VirtualUser=game:GetService("VirtualUser")
        app:Track(LocalPlayer.Idled:Connect(function()
            if not Config.AntiAFK then return end
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0,0),Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0),Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
            end)
        end))
    end
    antiAFK()

    -- Heartbeat loop: velocity writes must land before the physics solver.
    app:Track(RunService.Heartbeat:Connect(function(dt)
        if not app:Alive() then return end
        app.Guard("Movement",function()
            if Config.FollowEnabled then updateFollow(dt) end
            if Config.SpeedEnabled then updateSpeed() else restoreSpeed() end
            if Config.Noclip then updateNoclip(dt) else restoreCollision() end
            if Config.TouchAssist then updateTouchFly() end
        end)
    end))

    app:OnStop(function()
        Config.FollowEnabled=false
        Config.SpeedEnabled=false
        Config.Noclip=false
        Config.TouchAssist=false
        state.lastDragX=0
        state.lastDragY=0
        state.lastVertical=0
        restoreSpeed()
        restoreCollision()
    end)

    return Movement
end
