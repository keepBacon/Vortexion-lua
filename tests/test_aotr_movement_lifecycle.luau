local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local c={Connected=true}
        function c:Disconnect() self.Connected=false end
        table.insert(self.listeners,{fn=fn,connection=c})
        return c
    end
    function s:Fire(...)
        for _,h in ipairs(self.listeners) do if h.connection.Connected then h.fn(...) end end
    end
    return s
end
local Vec={}
Vec.__index=function(v,k) if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end return Vec[k] end
Vector3={zero=setmetatable({X=0,Y=0,Z=0},Vec),new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},Vec) end}
Vector2={new=function(x,y) return {X=x,Y=y} end}
CFrame={new=function() return {} end}
tick=function() return 1 end
task={wait=function() end}
local heartbeat=signal()
local player={Idled=signal(),CharacterAdded=signal(),CharacterRemoving=signal()}
local function character(speed)
    local hum={Parent=true,WalkSpeed=speed,MoveDirection=Vector3.zero}
    local parts={{Parent=true,CanCollide=true},{Parent=true,CanCollide=false}}
    for _,part in ipairs(parts) do function part:IsA(k) return k=="BasePart" end end
    local char={Parent=true,parts=parts,hum=hum,root={Parent=true,AssemblyLinearVelocity=Vector3.zero}}
    function char:FindFirstChildOfClass(k) return k=="Humanoid" and self.hum end
    function char:GetDescendants() return self.parts end
    return char
end
local first=character(16)
player.Character=first
local app={active=true,connections={},disposers={},Services={RunService={Heartbeat=heartbeat},Workspace={},Input={},Players={LocalPlayer=player}}}
function app:Track(c) table.insert(self.connections,c);return c end
function app:OnStop(fn) table.insert(self.disposers,fn) end
function app:Alive() return self.active end
function app:Character() local c=player.Character;if c then return c,c.hum,c.root end end
function app.Guard(_,fn) fn() end
local touchState={dx=0,dy=0,vert=0}
app.Touch={Enabled=false,Held=false,Drag=function() return Vector2.new(touchState.dx,touchState.dy),touchState.vert end}
game={GetService=function(_,name) assert(name=="VirtualUser");return {} end}
local module=__FACTORY__(app)
module.Config.AntiAFK=false
module.Config.SpeedEnabled=true;module.Config.SpeedValue=30
module.Config.Noclip=true
heartbeat:Fire(0.06)
assert(first.hum.WalkSpeed==30,"speed fixture activates")
assert(first.parts[1].CanCollide==false,"collision fixture activates")
module.Config.SpeedEnabled=false;module.Config.Noclip=false
heartbeat:Fire(0.06)
assert(first.hum.WalkSpeed==16,"disable restores speed immediately on next frame")
assert(first.parts[1].CanCollide==true,"disable restores collidable part")
assert(first.parts[2].CanCollide==false,"disable preserves originally noncollidable part")
module.Config.SpeedEnabled=true;module.Config.Noclip=true
heartbeat:Fire(0.06)
local added={Parent=true,CanCollide=true,IsA=function(_,k) return k=="BasePart" end}
table.insert(first.parts,added)
heartbeat:Fire(0.06)
assert(added.CanCollide==false,"new part participates in property snapshot")
player.CharacterRemoving:Fire(first)
assert(first.hum.WalkSpeed==16,"respawn restores exact old humanoid")
assert(first.parts[1].CanCollide==true and added.CanCollide==true,"respawn restores old part snapshots")
local second=character(22)
player.Character=second
player.CharacterAdded:Fire(second)
heartbeat:Fire(0.06)
assert(second.hum.WalkSpeed==30,"new humanoid receives active setting")
-- Touch-fly assist: vertical drag delta maps to vertical velocity on the same
-- Heartbeat cadence as movement (never throttled by the visual interval).
module.Config.TouchAssist=true
module.Config.TouchFlySpeed=120
touchState.dx=0;touchState.dy=0;touchState.vert=16
app.Touch.Enabled=true;app.Touch.Held=true
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.Y==120,"touch assist maps drag delta to vertical velocity")
touchState.vert=16
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.Y==120,"repeated identical drag does not drift (incremental)")
touchState.vert=0
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.Y==-120,"reversed drag inverts vertical velocity")
app.Touch.Held=false
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.Y==-120,"release stops assist writes without touching velocity")
module.Config.TouchAssist=false;app.Touch.Enabled=false
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.Y==-120,"disabled assist performs no writes")
-- Full 2D touch assist: single-finger Y drives forward/back from the camera
-- LookVector, X strafes from RightVector, two-finger vertical lifts. Deltas
-- are incremental, so a zero delta writes no new horizontal velocity.
app.Services.Workspace.CurrentCamera={CFrame={RightVector={X=1,Z=0},LookVector={X=0,Z=1}}}
app.Touch.Enabled=true;app.Touch.Held=true
module.Config.TouchAssist=true
touchState.dx=0;touchState.dy=0;touchState.vert=0
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.X==0 and second.root.AssemblyLinearVelocity.Z==0,"zero delta writes no new horizontal velocity")
touchState.dy=16
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.Z==-120,"downward drag moves backward from camera LookVector")
touchState.dy=0
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.Z==0,"upward drift cancels backward motion")
touchState.dy=-16
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.Z==120,"upward drag moves forward")
touchState.dx=16;touchState.dy=16
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.X==120 and second.root.AssemblyLinearVelocity.Z==-120,"strafe and depth compose from camera basis")
app.Touch.Held=false;app.Touch.Enabled=false;module.Config.TouchAssist=false
app.Services.Workspace.CurrentCamera=nil
heartbeat:Fire(0.06)
assert(second.root.AssemblyLinearVelocity.X==120 and second.root.AssemblyLinearVelocity.Z==-120,"release keeps composed momentum without braking")
app.active=false
for _,c in ipairs(app.connections) do c:Disconnect() end
for _,dispose in ipairs(app.disposers) do dispose() end
assert(second.hum.WalkSpeed==22,"cleanup restores new humanoid own baseline")
assert(second.parts[1].CanCollide==true and second.parts[2].CanCollide==false,"cleanup restores mixed collision state")
local previous=second.hum.WalkSpeed
heartbeat:Fire(0.06)
assert(second.hum.WalkSpeed==previous,"cleanup disconnects background driver")
for _,c in ipairs(app.connections) do assert(not c.Connected,"connection reclaimed") end
print("PASS AOTR movement disable/respawn/dynamic parts/cleanup restoration")
