-- Runtime fixtures use actual module factories, strict vector math and event delivery.
local now, queued, drawings, instances = 0, {}, {}, {}
function tick() return now end
local testEnvironment = {}
function getgenv() return testEnvironment end
local function signal()
    local s = { listeners = {} }
    function s:Connect(fn)
        local cn = { Connected = true }
        function cn:Disconnect() self.Connected = false end
        table.insert(self.listeners, { fn = fn, cn = cn })
        return cn
    end
    function s:Fire(...) for _, h in ipairs(self.listeners) do if h.cn.Connected then h.fn(...) end end end
    return s
end
local Vec = {}
Vec.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z) end
    if k == "Unit" then return v / v.Magnitude end
    return Vec[k]
end
local function vector(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0}, Vec) end
Vec.__add = function(a,b) assert(type(a)=="table" and type(b)=="table", "vector addition requires two vectors") return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
Vec.__sub = function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
Vec.__mul = function(a,b) if type(a)=="number" then a,b=b,a end return vector(a.X*b,a.Y*b,a.Z*b) end
Vec.__div = function(a,b) return vector(a.X/b,a.Y/b,a.Z/b) end
function Vec:Lerp(b,t) return self+(b-self)*t end
function Vec:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
Vector2 = {new=vector,zero=vector()}
Vector3 = {new=vector,zero=vector()}
local baseTypeof = typeof
local function color(r,g,b)
    local v=vector(r,g,b) v.R,v.G,v.B=v.X,v.Y,v.Z v._color3=true return v
end
Color3 = {new=color, fromRGB=function(r,g,b) return color(r/255,g/255,b/255) end}
function typeof(v)
    if type(v)=="table" and rawget(v,"_color3") then return "Color3" end
    return baseTypeof(v)
end
UDim = {new=function(...) return {...} end}
UDim2 = {fromScale=function(...) return {...} end, fromOffset=function(...) return {...} end, new=function(...) return {...} end}
local function frame(pos, target)
    local cf = {Position=pos or vector(),LookVector=target and (target-pos).Unit or vector(0,0,-1),RightVector=vector(1,0,0)}
    function cf:Lerp(other,alpha) other.Alpha=alpha return other end
    return cf
end
CFrame = {new=frame,lookAt=frame}
Enum = {HumanoidRigType={R6="R6",R15="R15"},HumanoidStateType={Freefall="Freefall"},UserInputType={MouseButton1="Left",MouseButton2="Right"},KeyCode={W="W",S="S",A="A",D="D",Space="Space",LeftShift="Shift"},HighlightDepthMode={AlwaysOnTop="AlwaysOnTop"},RaycastFilterType={Exclude="Exclude"},RenderPriority={Last={Value=2000}},Font={GothamBold="GothamBold"}}
RaycastParams = {new=function() return {} end}
local function instance(class,name)
    local o = {ClassName=class,Name=name or class,children={},Parent=nil,DescendantAdded=signal(),DescendantRemoving=signal(),CharacterAdded=signal(),CharacterRemoving=signal(),Idled=signal(),changed=signal()}
    function o:IsA(k) return self.ClassName==k or (k=="BasePart" and self.ClassName=="Part") end
    function o:FindFirstChild(k) for _,c in ipairs(self.children) do if c.Name==k then return c end end end
    function o:WaitForChild(k) return self:FindFirstChild(k) end
    function o:FindFirstChildWhichIsA(k) for _,c in ipairs(self.children) do if c:IsA(k) then return c end end end
    function o:GetChildren() return self.children end
    function o:GetDescendants()
        self.Walks=(self.Walks or 0)+1
        local result={}
        local function walk(n) for _,c in ipairs(n.children) do table.insert(result,c) walk(c) end end
        walk(self) return result
    end
    function o:IsDescendantOf(root) local p=self.Parent while p do if p==root then return true end p=p.Parent end return false end
    function o:GetPropertyChangedSignal() return self.changed end
    function o:ChangeState(s) self.State=s end
    function o:Destroy() self.Destroyed=true self.Parent=nil end
    table.insert(instances,o)
    return setmetatable(o,{__index=function(t,k) if class=="Model" and k=="Character" then error("Character is not a valid member of Model") end return nil end})
end
Instance = {new=instance}
local failDrawingAt=nil
Drawing = {new=function(kind)
    if failDrawingAt and #drawings+1>=failDrawingAt then error("drawing fixture allocation failure") end
    local d={Kind=kind,Visible=false}
    function d:Remove() self.Removed=true self.Visible=false end
    table.insert(drawings,d) return d
end}
task = {}
function task.spawn(fn) local co=coroutine.create(fn) local ok,err=coroutine.resume(co) assert(ok,err) return co end
function task.wait() local co=coroutine.running() table.insert(queued,co) return coroutine.yield() end
function task.delay(_,fn) table.insert(queued,fn) end
function task.cancel(co) if coroutine.status(co)~="dead" then coroutine.close(co) end end
local function advance(dt)
    now+=dt or 0.05
    local old=queued queued={}
    for _,job in ipairs(old) do if type(job)=="function" then job() elseif coroutine.status(job)=="suspended" then local ok,err=coroutine.resume(job) assert(ok,err) end end
end
local function add(parent,child) child.Parent=parent table.insert(parent.children,child) return child end
local function character(name,pos,rig)
    local c=instance("Model",name)
    local function part(n,dy) local p=add(c,instance("Part",n)) p.Size=vector(2,2,2) p.Position=pos+vector(0,dy or 0,0) p.CFrame=frame(p.Position) p.AssemblyLinearVelocity=vector(0,7,0) p.Transparency=0.2 p.CanCollide=true return p end
    part("HumanoidRootPart") part("Head",3) part(rig=="R6" and "Torso" or "UpperTorso",1)
    for _,n in ipairs(rig=="R6" and {"Left Arm","Right Arm","Left Leg","Right Leg"} or {"LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}) do part(n,1) end
    local h=add(c,instance("Humanoid")) h.Health=100 h.MaxHealth=100 h.RigType=rig or "R15" h.MoveDirection=vector(1,0,0)
    return c
end
local factories = __FACTORIES__
local workspaceFixture, services, lp, enemy, common
local function reset()
    now=0 queued={} drawings={} instances={} failDrawingAt=nil
    getrawmetatable=nil hookmetamethod=nil checkcaller=nil newcclosure=nil
    workspaceFixture=instance("Workspace") workspaceFixture.CurrentCamera={CFrame=frame(),ViewportSize=vector(800,600)}
    function workspaceFixture.CurrentCamera:WorldToViewportPoint(p) return vector(400+p.X,300-p.Y,p.Z+100),math.abs(p.X)<400 and math.abs(p.Y)<300 and p.Z>-100 end
    function workspaceFixture:Raycast() return self.Blocked and {Instance=self.Blocked} or nil end
    lp=instance("Player","Local") lp.Team="A" lp.Character=add(workspaceFixture,character("LocalChar",vector(0,0,-5))) add(lp,instance("PlayerGui"))
    enemy=instance("Player","Enemy") enemy.Team="B" enemy.Character=add(workspaceFixture,character("EnemyChar",vector(10,0,-30)))
    local players={LocalPlayer=lp,List={lp,enemy},PlayerAdded=signal(),PlayerRemoving=signal(),Calls=0}
    function players:GetPlayers() self.Calls+=1 return table.clone(self.List) end
    function players:GetPlayerFromCharacter(c) for _,p in ipairs(self.List) do if p.Character==c then return p end end end
    local input={TouchEnabled=true,TouchStarted=signal(),TouchMoved=signal(),TouchEnded=signal(),WindowFocusReleased=signal(),JumpRequest=signal(),Focused=false,Keys={},MouseButtons={}}
    function input:IsMouseButtonPressed(button) return self.MouseButtons[button] or self.Pressed or false end
    function input:IsKeyDown(k) return self.Keys[k] or false end
    function input:GetMouseLocation() return vector(400,300) end
    function input:GetFocusedTextBox() return self.Focused and {} or nil end
    local run={Heartbeat=signal(),Bindings={}}
    function run:BindToRenderStep(n,_,fn) self.Bindings[n]=fn end
    function run:UnbindFromRenderStep(n) self.Bindings[n]=nil end
    local vu={Down=0,Up=0}
    function vu:Button1Down() self.Down+=1 end
    function vu:Button1Up() self.Up+=1 end
    function vu:Button2Down() self.Down+=1 end
    function vu:Button2Up() self.Up+=1 end
    local tele={Calls=0}
    function tele:Teleport() self.Calls+=1 end
    services={Players=players,UserInputService=input,Input=input,RunService=run,Workspace=workspaceFixture,Lighting={Brightness=1,ClockTime=5,FogEnd=200,Ambient=vector(.1,.1,.1),OutdoorAmbient=vector(.2,.2,.2)},VirtualUser=vu,HttpService={},TeleportService=tele}
    workspace=workspaceFixture
    game={PlaceId=123,JobId="fixture",GetService=function(_,n) return services[n] or {} end,FindService=function() return nil end}
    common={Services=services,LocalPlayer=lp,Disposers={},Caps={},HasDrawing=true,Touch={Enabled=true,Held=true,Presses=0},Cloak={Protect=function() end},RandomName=function() return "fixture" end,GetGuiParent=function() return lp:FindFirstChild("PlayerGui") end,Log=function() end,Guard=function(_,fn,...) return fn(...) end}
    common.OnCleanup=function(fn) table.insert(common.Disposers,fn) end
end
local function finish() for i=#common.Disposers,1,-1 do common.Disposers[i]() end end
local function same(a,b) return (a-b).Magnitude<1e-5 end
local failures,passed=0,0
local function test(name,fn)
    reset()
    local ok,err=pcall(fn)
    if ok then passed+=1 print("PASS "..name) else failures+=1 warn("FAIL "..name..": "..tostring(err)) end
end

test("candidate camera loss empties pool and nearest cap",function()
    for i=1,26 do local p=instance("Player","P"..i) p.Character=add(workspaceFixture,character("PChar"..i,vector(100-i*3,0,-30))) table.insert(services.Players.List,p) end
    local c=factories.Candidates(common) c:Update(1)
    assert(#c:Get()==24,"bounded candidate cap")
    for i=2,#c:Get() do assert(c:Get()[i-1].WorldDistance<=c:Get()[i].WorldDistance,"nearest ordering") end
    workspaceFixture.CurrentCamera=nil c:Update(0.001) assert(#c:Get()==0,"stale camera pool")
    finish()
end)
test("NPC pool accepts Model without Character access and reuses nonrefresh",function()
    local npc=add(workspaceFixture,character("NestedNPC",vector(20,0,-20))) common.Candidates={NPCs={[npc]=true}}
    local esp=factories.ESP(common) esp.Config.Enabled=true esp.Config.TargetNPCs=true
    esp:Update(.05) local count=#drawings
    esp:Update(.001) esp:Update(.001) assert(#drawings==count,"nonrefresh allocations")
    esp:Cleanup() for _,d in ipairs(drawings) do assert(d.Removed,"drawing cleanup") end
end)
test("box allocation partial failure rolls back",function()
    failDrawingAt=3 common.HasDrawing=true common.Candidates={NPCs={}}
    local esp=factories.ESP(common) esp.Config.Enabled=true esp:Update(.05) esp:Cleanup()
    for _,d in ipairs(drawings) do assert(d.Removed,"partial allocation leaked") end
end)

local function candidates() common.Candidates=factories.Candidates(common) common.Candidates:Update(.05) return common.Candidates end
local function aim()
    candidates()
    common.Camera=factories.Camera(common)
    common.Camera.Config.Enabled=true common.Camera.Config.TriggerKey="Always" common.Camera.Config.HitChance=1 common.Camera.Config.Prediction=0
    return common.Camera
end
local function visibleDrawings() local n=0 for _,d in ipairs(drawings) do if d.Visible and not d.Removed then n+=1 end end return n end

test("shared cleanup and touch filtered origin order focus",function()
    local own=common.OnCleanup local cache=common.Services
    factories.Common(common)
    assert(common.OnCleanup==own and common.Services==cache and common.Services.Input==common.Services.UserInputService,"shared wiring preserved")
    local input=services.Input local a={Position=vector(500,300)} local b={Position=vector(700,300)}
    input.TouchStarted:Fire({Position=vector(600,100)},true) assert(not common.Touch.Held,"processed UI ignored")
    input.TouchStarted:Fire({Position=vector(100,300)},false) assert(not common.Touch.Held,"left joystick ignored")
    input.TouchStarted:Fire(a,false) input.TouchStarted:Fire(b,false)
    a.Position=vector(560,280) b.Position=vector(700,250) input.TouchMoved:Fire(a) input.TouchMoved:Fire(b)
    local drag,vertical=common.Touch:Drag() assert(same(drag,vector(60,-20)) and vertical==-50,"stable origin/arrival")
    input.TouchEnded:Fire(a) assert(common.Touch.Held,"second touch retained")
    input.WindowFocusReleased:Fire() assert(not common.Touch.Held,"background releases hold")
    common.Touch.Region="Full" input.TouchStarted:Fire({Position=vector(100,300)},false) assert(common.Touch.Held,"full screen optional")
    finish() assert(not common.Touch.Held,"unload releases hold")
    for _,s in ipairs({input.TouchStarted,input.TouchMoved,input.TouchEnded,input.WindowFocusReleased}) do for _,h in ipairs(s.listeners) do assert(not h.cn.Connected,"touch disposer wired to core") end end
end)
test("cloak cleanup restores hook lifecycle",function()
    local original=function() end
    local metatable={__namecall=original}
    getrawmetatable=function(object) assert(object==game,"game metatable target") return metatable end
    hookmetamethod=function(object,method,replacement)
        local previous=metatable[method]
        metatable[method]=replacement
        return previous
    end
    checkcaller=function() return false end
    common.Caps.hookmetamethod=true common.Caps.checkcaller=true common.Caps.newcclosure=false
    local cloak=factories.Cloak(common)
    cloak:Start()
    assert(metatable.__namecall~=original,"hook installed")
    finish()
    assert(metatable.__namecall==original,"cleanup restores original hook")
end)
test("candidate roster throttles and nested late humanoid events",function()
    local nested=add(workspaceFixture,instance("Folder","Nested")) local npc=add(nested,character("NestedNPC",vector(20,0,-20)))
    local c=candidates() c:StartNPCScan() assert(c.NPCs[npc],"initial nested humanoid")
    local calls,frames=services.Players.Calls,c.Frame
    for _=1,10 do c:Update(.001) end assert(c.Frame==frames and services.Players.Calls==calls,"no frame roster rebuild")
    local late=add(nested,instance("Model","LateNPC")) workspaceFixture.DescendantAdded:Fire(late) assert(not c.NPCs[late],"model without humanoid not yet NPC")
    local h=add(late,instance("Humanoid")) h.Health=100 workspaceFixture.DescendantAdded:Fire(h) assert(c.NPCs[late],"late humanoid discovered")
    workspaceFixture.DescendantRemoving:Fire(h) assert(not c.NPCs[late],"humanoid removal drops NPC")
    local joined=instance("Player","Joined") joined.Character=add(workspaceFixture,character("JoinChar",vector(1,0,-15))) table.insert(services.Players.List,joined) services.Players.PlayerAdded:Fire(joined)
    c:Update(.001) local found=false for _,cand in ipairs(c:Get()) do if cand.Player==joined then found=true end end assert(found,"event roster immediate")
    services.Players.PlayerRemoving:Fire(joined) c:Update(.001) for _,cand in ipairs(c:Get()) do assert(cand.Player~=joined,"removed player excluded") end
    finish() assert(#c:Get()==0 and c.NPCs==nil,"candidate teardown")
end)
test("camera lock persists revalidates team wall death and clears gates",function()
    local camera=aim() camera.Config.MaxAngle=90 camera:Update(1/60) assert(camera:GetCurrentTarget(),"acquires head lock")
    local first=camera:GetCurrentTarget()
    enemy.Character:FindFirstChild("HumanoidRootPart").Position=vector(150,0,-30) enemy.Character:FindFirstChild("Head").Position=vector(150,3,-30)
    common.Candidates:Update(.05) camera:Update(1/60) assert(camera:GetCurrentTarget(),"head lock survives FOV hysteresis")
    camera.Config.TeamCheck=true enemy.Team=lp.Team camera:Update(1/60) assert(not camera:GetCurrentTarget(),"locked team revalidated")
    enemy.Team="B" enemy.Character:FindFirstChild("Head").Position=vector(10,3,-30) camera:Update(1/60) assert(camera:GetCurrentTarget(),"reacquire")
    workspaceFixture.Blocked=add(workspaceFixture,instance("Part","Wall")) camera:Update(1/60) assert(not camera:GetCurrentTarget(),"locked wall revalidated")
    workspaceFixture.Blocked=nil camera:Update(1/60) assert(camera:GetCurrentTarget(),"wall removal reacquire")
    camera.Config.HitChance=-1 camera:Update(1/60) assert(not camera:GetCurrentTarget(),"failed acquisition roll not published")
    camera.Config.HitChance=1 camera.Config.MaxAngle=0 workspaceFixture.CurrentCamera.CFrame.LookVector=vector(-1,0,0) camera:Update(1/60) assert(not camera:GetCurrentTarget(),"cone failure not published")
    camera.Config.MaxAngle=30 enemy.Character:FindFirstChildWhichIsA("Humanoid").Health=0 camera:Update(1/60) assert(not camera:GetCurrentTarget(),"dead locked character")
    finish()
end)
test("camera mobile mouse fallback replacement alpha and reusable marker",function()
    local camera=aim() common.Caps.mousemoverel=true camera.Config.Mode="Mouse"
    local original=workspaceFixture.CurrentCamera.CFrame camera:Update(1/60) assert(workspaceFixture.CurrentCamera.CFrame~=original,"touch mouse falls back to camera")
    local alpha=workspaceFixture.CurrentCamera.CFrame.Alpha
    assert(math.abs(alpha-.15)<1e-6,"60Hz alpha")
    local markers=0 for _,i in ipairs(instances) do if i.ClassName=="Highlight" then markers+=1 end end
    camera.Config.TriggerKey="None" camera:Update(1/60) assert(not camera:GetCurrentTarget(),"release clears target")
    camera.Config.TriggerKey="Always" camera:Update(1/60) local count=0 for _,i in ipairs(instances) do if i.ClassName=="Highlight" then count+=1 end end assert(count==markers,"marker reuse")
    local replacement={CFrame=frame(),ViewportSize=vector(400,300),WorldToViewportPoint=function(_,p) return vector(200+p.X,150-p.Y,100+p.Z),true end}
    workspaceFixture.CurrentCamera=replacement common.Candidates:Update(.001) camera:Update(1/30)
    assert(replacement.CFrame.Alpha and math.abs(replacement.CFrame.Alpha-(1-(1-alpha)^2))<1e-6,"new camera dt-adjusted")
    camera.Config.Enabled=false camera:Update(.001) assert(not camera:GetCurrentTarget(),"off clears target")
    finish() for _,i in ipairs(instances) do if i.ClassName=="Highlight" or i.ClassName=="ScreenGui" then assert(i.Destroyed,"camera instances disposed") end end
end)
test("camera touch hold toggle focus and text entry suppression",function()
    factories.Common(common) local camera=aim() camera.Config.TriggerKey="Touch" camera:ResetTrigger()
    local input=services.Input local touch={Position=vector(600,300)}
    camera:Update(.02) assert(not camera:GetCurrentTarget(),"hold idle")
    input.TouchStarted:Fire(touch,false) camera:Update(.02) assert(camera:GetCurrentTarget(),"hold starts")
    input.TouchEnded:Fire(touch) camera:Update(.02) assert(not camera:GetCurrentTarget(),"hold release")
    camera.Config.TouchMode="Toggle" camera:ResetTrigger() input.TouchStarted:Fire(touch,false) input.TouchEnded:Fire(touch) camera:Update(.02) assert(camera:GetCurrentTarget(),"toggle stays after release")
    input.WindowFocusReleased:Fire() camera:Update(.02) assert(not camera:GetCurrentTarget(),"focus cancels toggle")
    input.TouchStarted:Fire(touch,false) input.TouchEnded:Fire(touch) input.Focused=true camera:Update(.02) assert(not camera:GetCurrentTarget(),"typing suppression")
    input.Focused=false camera:Update(.02) assert(not camera:GetCurrentTarget(),"typing resets latch")
    finish()
end)
test("hitbox throttled independent scales numeric lerp and immediate restore",function()
    candidates() local c=common.Candidates:Get()[1] common.Camera={GetCurrentTarget=function() return table.clone(c) end}
    local h=factories.Hitbox(common) h.Config.Enabled=true h.Config.AnisoXZ=1 h.Config.AnisoY=1 h.Config.GrowAlpha=1 h.Config.ScaleMax=1 h.Config.HeadScale=2 h.Config.TorsoScale=1
    local head=enemy.Character:FindFirstChild("Head") local torso=enemy.Character:FindFirstChild("UpperTorso") local size,trans,collide=head.Size,head.Transparency,head.CanCollide
    h:Update(.01) assert(same(head.Size,size),"tick gate") h:Update(.04) assert(head.Size.X>size.X and same(torso.Size,size),"independent head multiplier and lock character identity")
    assert(head.Transparency==h.Config.Transparency and not head.CanCollide,"numeric interpolation and collision")
    assert(same(h:GetEnvelope(head),size) and same(h:GetEnvelopeMargin(head),size*.5+vector(.5,.5,.5)),"original envelope")
    h.Config.Enabled=false h:Update(0) assert(same(head.Size,size) and head.Transparency==trans and head.CanCollide==collide,"off restores immediately")
    finish()
end)
test("hitbox mode rig respawn and removal restore",function()
    candidates() local h=factories.Hitbox(common) h.Config.Enabled=true h.Config.Mode="fullBody" h.Config.GrowAlpha=1
    local limb=enemy.Character:FindFirstChild("LeftUpperArm") local original=limb.Size h:Update(.05) assert(not same(limb.Size,original),"full body")
    h.Config.Mode="all" h:Update(.05) assert(same(limb.Size,original) and limb.CanCollide,"mode restores excluded limb")
    h.Config.Mode="fullBody" h:Update(.05) local old=enemy.Character local oldHead=old:FindFirstChild("Head")
    enemy.CharacterRemoving:Fire(old) assert(same(oldHead.Size,vector(2,2,2)),"character removing")
    enemy.Character=add(workspaceFixture,character("R6Respawn",vector(15,0,-30),"R6")) common.Candidates:Update(.05) h:Update(.05)
    local torso=enemy.Character:FindFirstChild("Torso") assert(torso.Size.X>2,"R6 adapted") services.Players.PlayerRemoving:Fire(enemy) assert(same(torso.Size,vector(2,2,2)),"player removal")
    finish()
end)
test("movement single driver speed Y fly priority and restore",function()
    local m=factories.Movement(common) m:Start() m:Start()
    assert(#services.RunService.Heartbeat.listeners==0,"no extra heartbeat loops") assert(#services.Input.JumpRequest.listeners==1,"idempotent start")
    local root=lp.Character:FindFirstChild("HumanoidRootPart") local original=root.AssemblyLinearVelocity
    m.Config.SpeedEnabled=true m.Config.SpeedValue=80 m:Update(.05) assert(root.AssemblyLinearVelocity.X==80 and root.AssemblyLinearVelocity.Y==7,"speed preserves Y")
    now=.11 m:Update(.05) assert(math.abs(root.AssemblyLinearVelocity.X-80*m.Config.CoastFactor)<1e-5,"legacy coast retained")
    m.Config.FlyEnabled=true common.Touch.Held=false services.Input.Keys.W=true m:Update(.05) assert(root.AssemblyLinearVelocity.Z==-m.Config.FlySpeed,"fly priority")
    m.Config.FlyEnabled=false m.Config.SpeedEnabled=false m:Update(.05) assert(same(root.AssemblyLinearVelocity,original),"owned velocity restored")
    m.Config.SpeedEnabled=true m:Update(.05) root.AssemblyLinearVelocity=vector(3,4,5) m.Config.SpeedEnabled=false m:Update(.05) assert(same(root.AssemblyLinearVelocity,vector(3,4,5)),"external physics velocity preserved")
    finish()
end)
test("movement touch fly uses displacement and two finger vertical",function()
    factories.Common(common) local m=factories.Movement(common) m:Start() m.Config.FlyEnabled=true
    local t={Position=vector(500,300)} services.Input.TouchStarted:Fire(t,false) t.Position=vector(620,300) services.Input.TouchMoved:Fire(t) m:Update(.05)
    local root=lp.Character:FindFirstChild("HumanoidRootPart") assert(math.abs(root.AssemblyLinearVelocity.X-m.Config.FlySpeed)<1e-5,"horizontal touch fly")
    local t2={Position=vector(700,300)} services.Input.TouchStarted:Fire(t2,false) t2.Position=vector(700,180) services.Input.TouchMoved:Fire(t2) m:Update(.05) assert(root.AssemblyLinearVelocity.Y>0,"second finger vertical")
    services.Input.WindowFocusReleased:Fire() m:Update(.05) assert(same(root.AssemblyLinearVelocity,vector()),"no stuck background movement") finish()
end)
test("noclip restores false true dynamic parts and respawn with one walk",function()
    local m=factories.Movement(common) m:Start() m:SetNoclip(true)
    local char=lp.Character local head=char:FindFirstChild("Head") head.CanCollide=false local root=char:FindFirstChild("HumanoidRootPart")
    m:Update(.05) assert(not root.CanCollide and not head.CanCollide,"collision disabled") local walks=char.Walks
    for _=1,20 do m:Update(.05) end assert(char.Walks==walks,"cached descendant walk")
    local late=add(char,instance("Part","Late")) late.CanCollide=true char.DescendantAdded:Fire(late) m:Update(.05) assert(not late.CanCollide,"new part tracked")
    char.DescendantRemoving:Fire(late) assert(late.CanCollide,"removed part restored")
    m:SetNoclip(false) assert(root.CanCollide and not head.CanCollide,"original true and false restored")
    m:SetNoclip(true) m:Update(.05) lp.CharacterRemoving:Fire(char) assert(root.CanCollide,"respawn old rig restore")
    lp.Character=add(workspaceFixture,character("NewLocal",vector(0,0,-5))) m:Update(.05) local newroot=lp.Character:FindFirstChild("HumanoidRootPart") assert(not newroot.CanCollide,"respawn new rig bound")
    finish() assert(newroot.CanCollide,"unload collision restored")
end)
test("jump event deferred debounce respawn cancel and teleport cancel",function()
    local m=factories.Movement(common) m:Start() m.Config.JumpEnabled=true
    local old=lp.Character local root=old:FindFirstChild("HumanoidRootPart") services.Input.JumpRequest:Fire() services.Input.JumpRequest:Fire() assert(#queued==1,"jump debounce") advance(.02) assert(root.AssemblyLinearVelocity.Y==m.Config.JumpValue,"JumpRequest wired")
    root.AssemblyLinearVelocity=vector(0,7,0) services.Input.JumpRequest:Fire() lp.CharacterRemoving:Fire(old) lp.Character=add(workspaceFixture,character("NewLocal",vector(0,0,-5))) advance(.02) assert(root.AssemblyLinearVelocity.Y==7,"pending jump cancelled across respawn")
    local newroot=lp.Character:FindFirstChild("HumanoidRootPart") m:TeleportTo(vector(100,0,-5)) local first=newroot.CFrame.Position
    lp.CharacterRemoving:Fire(lp.Character) lp.Character=add(workspaceFixture,character("Again",vector(0,0,-5))) local finalroot=lp.Character:FindFirstChild("HumanoidRootPart") advance(.05) assert(same(newroot.CFrame.Position,first) and same(finalroot.CFrame.Position,vector(0,0,-5)),"teleport never crosses respawn")
    m:TeleportTo(vector(100,0,-5)) local stopped=finalroot.CFrame.Position m:Cleanup() advance(.05) assert(same(finalroot.CFrame.Position,stopped),"unload cancels teleport") finish()
end)
test("ESP late subfeature enable independent health labels tracer and immediate hide",function()
    common.Candidates={NPCs={}} local e=factories.ESP(common) e.Config.Enabled=true e.Config.Box=false e.Config.Health=false e:Update(.05) assert(#drawings==0,"disabled features lazy")
    e.Config.Health=true enemy.Character:FindFirstChildWhichIsA("Humanoid").Health=25 e:Update(.05) assert(visibleDrawings()==2,"health independent of box")
    local bar=drawings[2] local bg=drawings[1] assert(math.abs((bar.To.Y-bar.From.Y)/(bg.To.Y-bg.From.Y)-.25)<1e-5,"health visible ratio")
    e.Config.Box=true e.Config.Skeleton=true e.Config.Tracer=true e.Config.Labels=true e:Update(.05) assert(visibleDrawings()>10,"late enables allocate")
    local foundText,foundTracer=false,false for _,d in ipairs(drawings) do if d.Kind=="Text" and d.Text:find("Enemy") then foundText=true end if d.From and d.From.Y==600 and d.From.X==400 then foundTracer=true end end assert(foundText and foundTracer,"label and bottom tracer")
    e.Config.Box=false e.Config.Health=false e.Config.Skeleton=false e.Config.Tracer=false e.Config.Labels=false e:Update(.001) assert(visibleDrawings()==0,"subfeature off immediate")
    e.Config.Health=true e:Update(.05) local count=#drawings for _=1,10 do e:Update(.001) end assert(#drawings==count,"no nonrefresh allocations")
    enemy.Character:FindFirstChild("HumanoidRootPart").Position=vector(500,0,-30) e:Update(.05) assert(visibleDrawings()==0,"offscreen cull")
    e.Config.Enabled=false e:Update(0) e:Cleanup() for _,d in ipairs(drawings) do assert(d.Removed,"all draws disposed") end
end)
test("ESP NPC disable R6 switch and chams without Drawing",function()
    local npc=add(workspaceFixture,character("NPC",vector(20,0,-30))) common.Candidates={NPCs={[npc]=true}} local e=factories.ESP(common) e.Config.Enabled=true e.Config.TargetNPCs=true e.Config.Skeleton=true e.Config.Chams=true e:Update(.05) local count=#drawings
    for _=1,10 do e:Update(.001) end assert(#drawings==count,"NPC objects reused")
    local old=enemy.Character enemy.CharacterRemoving:Fire(old) enemy.Character=add(workspaceFixture,character("R6",vector(10,0,-30),"R6")) enemy.CharacterAdded:Fire(enemy.Character) e:Update(.05)
    e.Config.TargetNPCs=false e:Update(.001) for _,i in ipairs(instances) do if i.ClassName=="Highlight" and i.Adornee==npc then assert(not i.Enabled,"NPC off immediate") end end
    workspaceFixture.CurrentCamera=nil e:Update(.001) assert(visibleDrawings()==0,"camera loss hides geometry")
    e:Cleanup()
    common.HasDrawing=false drawings={} local noDraw=factories.ESP(common) noDraw.Config.Enabled=true noDraw.Config.Chams=true
    workspaceFixture.CurrentCamera={CFrame=frame(),ViewportSize=vector(800,600),WorldToViewportPoint=function(_,p) return vector(400+p.X,300-p.Y,100+p.Z),true end}
    noDraw:Update(.05) local found=false for _,i in ipairs(instances) do if i.ClassName=="Highlight" and not i.Destroyed and i.Adornee==enemy.Character then found=true end end assert(found and #drawings==0,"Highlight works without Drawing")
    noDraw.Config.Enabled=false noDraw:Update(0) noDraw:Cleanup()
end)

local fixtureUI
local function runCore()
__CORE__
end
local function coreFixture()
    fixtureUI={Options={},Buttons={},ServerSwitch={Calls=0}}
    function fixtureUI.ServerSwitch:Switch() self.Calls+=1 return true end
    function fixtureUI:Notify() end
    function fixtureUI:OnDestroy(fn) self.Disposer=fn end
    function fixtureUI:Destroy() if self.Disposer then self.Disposer() end end
    function fixtureUI:CreateWindow()
        local w={}
        function w:AddTab()
            local t={}
            local function option(_,id,cfg) fixtureUI.Options[id]=cfg return cfg end
            t.AddToggle=option t.AddDropdown=option t.AddSlider=option t.AddColorpicker=option
            function t:AddButton(cfg) fixtureUI.Buttons[cfg.Title]=cfg.Callback return cfg end
            function t:AddParagraph() end
            return t
        end
        function w:SelectTab() end
        return w
    end
    runCore()
    return fixtureUI
end
test("core old option IDs new parameters fullbright snapshot server reuse teardown",function()
    local ui=coreFixture() assert(services.RunService.Bindings.VortexionSCPFrame,"render bound")
    for _,id in ipairs({"SCPAimEnabled","SCPAimMode","SCPAimFov","SCPAimDist","SCPAimSmooth","SCPAimPart","SCPAimAngle","SCPAimPrediction","SCPAimHitChance","SCPAimWall","SCPAimTeam","SCPAimNPC","SCPAimKey","SCPAimFovCircle","SCPTrigger","SCPSilentEnabled","SCPSilentAngle","SCPSilentChance","SCPSilentWall","SCPSilentTeam","SCPHitboxEnabled","SCPHitboxMode","SCPHitboxScale","SCPHitboxDist","SCPHitboxFov","SCPHitboxActive","SCPESPEnabled","SCPESPBox","SCPESPHealth","SCPSkeleton","SCPTracer","SCPChams","SCPESPNPC","SCPESPDist","SCPESPTeam","SCPSpeed","SCPSpeedVal","SCPFly","SCPTouchFly","SCPFlySpeed","SCPNoclip","SCPJump","SCPJumpVal","SCPFullbright","SCPAntiRagdoll","SCPAntiAFK","SCPDebug"}) do assert(ui.Options[id],"legacy ID missing "..id) end
    for _,id in ipairs({"SCPTouchMode","SCPTouchRegion","SCPAimAttraction","SCPAimDampening","SCPTriggerInterval","SCPHitboxHeadScale","SCPHitboxTorsoScale","SCPESPLabels","SCPTracerOrigin","SCPESPRefresh","SCPESPBudget","SCPTouchDeadzone","SCPTouchSensitivity","SCPCandidateRefresh","SCPESPOffScreen","SCPESPOffScreenDistance","SCPESPOffScreenBudget","SCPESPOffScreenSize","SCPESPOffScreenMargin","SCPESPNativeLabels","SCPESPLabelTextSize","SCPESPLabelFont","SCPESPLabelStroke","SCPESPLabelBackground","SCPTeleportDist"}) do assert(ui.Options[id],"enrichment ID missing "..id) end
    assert(ui.Options.SCPTeleportDist.Default==50,"teleport slider default is a value, not an off state")
    local legacy=0 for _ in pairs(ui.Options) do legacy+=1 end
    assert(legacy==75,"legacy 47 plus 25 existing and 3 color option IDs, buttons carry no ID")
    assert(ui.Buttons["立即起跳"] and ui.Buttons["向前传送"],"mobile buttons missing")
    ui.Options.SCPTeleportDist.Callback(80) ui.Options.SCPESPEnabled.Callback(true) ui.Options.SCPESPOffScreen.Callback(true)
    enemy.Character:FindFirstChild("HumanoidRootPart").Position=vector(400,0,-30)
    services.RunService.Bindings.VortexionSCPFrame(.05) assert(visibleDrawings()>=3,"core offscreen arrow wired")
    ui.Options.SCPESPOffScreen.Callback(false) services.RunService.Bindings.VortexionSCPFrame(.001) assert(visibleDrawings()==0,"core offscreen off immediate")
    ui.Buttons["向前传送"]() for _=1,10 do advance(.05) end
    assert(same(lp.Character:FindFirstChild("HumanoidRootPart").CFrame.Position,vector(0,0,-85)),"core forward teleport uses slider distance")
    ui.Buttons["立即起跳"]() advance(.02) assert(lp.Character:FindFirstChildWhichIsA("Humanoid").Jump==true,"core mobile jump button")
    services.Lighting.Brightness=3 services.Lighting.ClockTime=8 ui.Options.SCPFullbright.Callback(true) assert(services.Lighting.Brightness==2,"immediate fullbright") ui.Options.SCPFullbright.Callback(false) assert(services.Lighting.Brightness==3 and services.Lighting.ClockTime==8,"enable time snapshot")
    ui.Options.SCPFullbright.Callback(true) ui.Options.SCPNoclip.Callback(true) services.RunService.Heartbeat:Fire(.05) assert(not lp.Character:FindFirstChild("HumanoidRootPart").CanCollide,"core movement driver")
    ui.Buttons["低延迟切服（通用）"]() assert(ui.ServerSwitch.Calls==1,"shared server adapter reused") ui.Buttons["重新加入"]() assert(services.TeleportService.Calls==1,"rejoin preserved")
    ui:Destroy() assert(services.RunService.Bindings.VortexionSCPFrame==nil,"unbind teardown") assert(services.Lighting.Brightness==3 and lp.Character:FindFirstChild("HumanoidRootPart").CanCollide,"lighting collision restored at destroy")
end)
test("core color controls update rendered colors and fence invalid or late values",function()
    local ui=coreFixture()
    local ids={"SCPESPColorEnemy","SCPESPColorAlly","SCPESPColorLowHealth"}
    for _,id in ipairs(ids) do assert(ui.Options[id] and typeof(ui.Options[id].Default)=="Color3","color ID and default: "..id) end
    local function visibleColor(wanted)
        for _,d in ipairs(drawings) do if d.Visible and d.Color==wanted then return true end end
        return false
    end
    local selected=Color3.fromRGB(31,47,83)
    ui.Options.SCPESPEnabled.Callback(true)
    ui.Options.SCPESPColorEnemy.Callback(selected)
    services.RunService.Bindings.VortexionSCPFrame(.1)
    assert(visibleColor(selected),"enemy picker reaches the next visual tick")
    for _,bad in ipairs({false,"#ffffff",{},Color3.new(2,0,0),Color3.new(0/0,0,0),Color3.new(math.huge,0,0)}) do
        ui.Options.SCPESPColorEnemy.Callback(bad)
        services.RunService.Bindings.VortexionSCPFrame(.1)
        assert(visibleColor(selected),"invalid color preserves the previous render color")
    end
    local low=Color3.fromRGB(71,113,157)
    enemy.Character:FindFirstChildWhichIsA("Humanoid").Health=1
    ui.Options.SCPESPColorLowHealth.Callback(low)
    services.RunService.Bindings.VortexionSCPFrame(.1)
    assert(visibleColor(low),"low-health picker reaches the next visual tick")
    local reads=0
    local late=setmetatable({_color3=true},{__index=function() reads+=1 return .5 end})
    ui:Destroy()
    for _,id in ipairs(ids) do ui.Options[id].Callback(late) end
    assert(reads==0,"unloaded color callbacks stop before reading color components")
end)

test("core high FPS trigger release reload and anti ragdoll",function()
    local ui=coreFixture() ui.Options.SCPAimEnabled.Callback(true) ui.Options.SCPAimKey.Callback("Always") ui.Options.SCPAimHitChance.Callback(100) ui.Options.SCPTrigger.Callback(true)
    now=1 services.RunService.Bindings.VortexionSCPFrame(.001) assert(services.VirtualUser.Down==1,"high fps does not skip target/trigger")
    ui:Destroy() assert(services.VirtualUser.Up==1,"unload releases held trigger") advance(.1) assert(services.VirtualUser.Up==1,"old delayed callback no duplicate input")
    ui=coreFixture() ui.Options.SCPAntiRagdoll.Callback(true) local rag=add(lp.Character,instance("BoolValue","Ragdoll")) services.RunService.Bindings.VortexionSCPFrame(.5) assert(rag.Destroyed,"legacy ragdoll preserved")
    ui:Destroy() for _,h in ipairs(services.RunService.Heartbeat.listeners) do assert(not h.cn.Connected,"generation heartbeats disposed") end
end)
test("core anti AFK pending release on destroy",function()
    local ui=coreFixture() task.spawn(function() lp.Idled:Fire() end) assert(services.VirtualUser.Down==1,"anti AFK down") ui:Destroy() assert(services.VirtualUser.Up==1,"anti AFK held input released") advance(1) assert(services.VirtualUser.Up==1,"pending AFK coroutine inert")
end)

test("desktop legacy buttons mouse both modes and no-capability fallback",function()
    services.Input.TouchEnabled=false common.Touch.Enabled=false local camera=aim() camera.Config.TriggerKey="Right"
    services.Input.MouseButtons.Left=true camera:Update(.02) assert(not camera:GetCurrentTarget(),"left does not satisfy right")
    services.Input.MouseButtons.Right=true camera:Update(.02) assert(camera:GetCurrentTarget(),"right button legacy")
    camera.Config.TriggerKey="Left" services.Input.MouseButtons.Right=false camera:Update(.02) assert(camera:GetCurrentTarget(),"left button legacy")
    camera.Config.MaxAngle=90 camera.Config.Mode="Mouse" common.Caps.mousemoverel=true
    local moves=0 mousemoverel=function() moves+=1 end
    enemy.Character:FindFirstChild("Head").Position=vector(80,3,-30) local before=workspaceFixture.CurrentCamera.CFrame camera:Update(.02) assert(moves==1 and workspaceFixture.CurrentCamera.CFrame==before,"mouse only modality")
    camera.Config.Mode="Both" camera:Update(.02) assert(workspaceFixture.CurrentCamera.CFrame~=before,"both coarse camera")
    common.Caps.mousemoverel=false camera.Config.Mode="Mouse" before=workspaceFixture.CurrentCamera.CFrame camera:Update(.02) assert(workspaceFixture.CurrentCamera.CFrame~=before,"missing mouse capability fallback")
    common.Caps.hookmetamethod=false local silent=factories.SilentAim(common) silent.Config.Enabled=true silent:Update() silent.Config.Enabled=false silent:Update() silent:Cleanup()
    mousemoverel=nil finish()
end)
test("candidate projection work bounded and fractional refresh remainder retained",function()
    for i=1,120 do local p=instance("Player","Load"..i) p.Character=add(workspaceFixture,character("LoadChar"..i,vector(i,0,-30))) table.insert(services.Players.List,p) end
    local cam=workspaceFixture.CurrentCamera local original=cam.WorldToViewportPoint local projections=0
    cam.WorldToViewportPoint=function(self,p) projections+=1 return original(self,p) end
    local c=candidates() assert(projections==24*3,"only bounded nearest pool projected")
    local baseline=c.Frame local calls=services.Players.Calls
    for _=1,100 do c:Update(.013) end assert(c.Frame-baseline>=25 and c.Frame-baseline<=26,"cadence retains fractional remainder")
    assert(services.Players.Calls==calls,"roster cache under load") finish()
end)
test("hitbox grace collapse numeric transparency and removal listeners released",function()
    candidates() local h=factories.Hitbox(common) h.Config.Enabled=true h.Config.Mode="all" h.Config.GrowAlpha=1 h.Config.PendingMs=50 h:Update(.05)
    local head=enemy.Character:FindFirstChild("Head") common.Candidates.Pool={} for _=1,20 do h:Update(.05) end
    assert(same(head.Size,vector(2,2,2)) and head.Transparency==.2 and head.CanCollide,"grace collapse fully restores")
    services.Players.PlayerRemoving:Fire(enemy) for _,s in ipairs({enemy.CharacterRemoving,enemy.changed}) do for _,listener in ipairs(s.listeners) do assert(not listener.cn.Connected,"removed player listeners released") end end finish()
end)
test("fly forward touch direction and jump can resume after teleport cancels pending",function()
    factories.Common(common) local m=factories.Movement(common) m:Start() m.Config.FlyEnabled=true
    local touch={Position=vector(500,300)} services.Input.TouchStarted:Fire(touch,false) touch.Position=vector(500,180) services.Input.TouchMoved:Fire(touch) m:Update(.05) local root=lp.Character:FindFirstChild("HumanoidRootPart") assert(root.AssemblyLinearVelocity.Z<0,"up drag moves forward")
    services.Input.Focused=true m:Update(.05) assert(root.AssemblyLinearVelocity.Z==0,"text input does not steer flight")
    m.Config.FlyEnabled=false m.Config.JumpEnabled=true services.Input.JumpRequest:Fire() m:TeleportTo(vector(20,0,-5)) services.Input.JumpRequest:Fire() advance(.02) assert(root.AssemblyLinearVelocity.Y==m.Config.JumpValue,"teleport epoch resets pending debounce")
    finish() advance(.05)
end)

test("shared visual clamp only slows cadence and rejects bad bridge values",function()
    factories.Common(common)
    local vi=common.VisualInterval
    assert(math.abs(vi(0.05)-0.05)<1e-9,"missing bridge keeps beat")
    common.UI={GetVisualInterval=function(_,base) return base*4 end}
    assert(math.abs(vi(0.05)-0.2)<1e-9,"bridge slows the beat")
    common.UI={GetVisualInterval=function(_,base) return base/10 end}
    assert(math.abs(vi(0.05)-0.05)<1e-9,"never accelerates")
    common.UI={GetVisualInterval=function() return 0/0 end}
    assert(math.abs(vi(0.05)-0.05)<1e-9,"NaN rejected")
    common.UI={GetVisualInterval=function() return math.huge end}
    assert(math.abs(vi(0.05)-0.05)<1e-9,"infinity rejected")
    common.UI={GetVisualInterval=function() return -1 end}
    assert(math.abs(vi(0.05)-0.05)<1e-9,"negative rejected")
    common.UI={GetVisualInterval=function() return "1" end}
    assert(math.abs(vi(0.05)-0.05)<1e-9,"non-number rejected")
    common.UI={GetVisualInterval=function() error("bridge down") end}
    assert(math.abs(vi(0.05)-0.05)<1e-9,"raising bridge keeps beat")
    common.UI={}
    assert(math.abs(vi(0.05)-0.05)<1e-9,"non-function field keeps beat")
    common.UI={GetVisualInterval=function(_,base) return base end}
    assert(math.abs(vi(0.05)-0.05)<1e-9,"identity bridge keeps beat")
    assert(math.abs(vi(0))<1e-9,"non-positive base untouched")
    assert(vi(nil)==nil,"non-numeric base passthrough")
    finish()
end)
test("ESP projection consumes shared clamp and camera swap forces refresh",function()
    factories.Common(common)
    common.UI={GetVisualInterval=function(_,base) return base*20 end}
    common.Candidates={NPCs={}}
    local e=factories.ESP(common) e.Config.Enabled=true
    local cam=workspaceFixture.CurrentCamera
    local original=cam.WorldToViewportPoint local projections=0
    local function counted(_,p) projections+=1 return original(_,p) end
    cam.WorldToViewportPoint=counted
    for _=1,40 do e:Update(0.01) end
    assert(projections<=4,"slow clamp keeps projections near zero: "..projections)
    local slow=projections
    common.UI={GetVisualInterval=function(_,base) return base end}
    projections=0
    for _=1,40 do e:Update(0.01) end
    assert(projections>=18,"default beat projects every 50ms: "..projections)
    assert(projections>slow*3,"clamp measurably reduces refresh count")
    common.UI={GetVisualInterval=function(_,base) return base*20 end}
    projections=0
    for _=1,20 do e:Update(0.01) end
    local throttled=projections
    local before=projections
    workspaceFixture.CurrentCamera={CFrame=cam.CFrame,ViewportSize=cam.ViewportSize,WorldToViewportPoint=counted}
    e:Update(0.001)
    assert(projections>before,"camera replacement forces refresh under the clamp")
    assert(projections-before>=3 and throttled<=4,"replacement refresh is not throttled away")
    e.Config.Enabled=false e:Update(0) e:Cleanup()
end)
test("ESP offscreen arrow native label and immediate teardown",function()
    factories.Common(common)
    common.UI={GetVisualInterval=function(_,base) return base*20 end}
    common.Candidates={NPCs={}}
    local e=factories.ESP(common) e.Config.Enabled=true e.Config.MaxDistance=2000 e.Config.OffScreen=true
    local cam=workspaceFixture.CurrentCamera
    local function forceRefresh()
        workspaceFixture.CurrentCamera={CFrame=cam.CFrame,ViewportSize=cam.ViewportSize,WorldToViewportPoint=cam.WorldToViewportPoint}
        e:Update(0.001)
    end
    enemy.Character:FindFirstChild("HumanoidRootPart").Position=vector(900,0,-30)
    e:Update(0.05)
    assert(visibleDrawings()>=3,"offscreen arrow drawn behind the camera")
    e.Config.OffScreen=false e:Update(0.001)
    assert(visibleDrawings()==0,"arrow disabled hides immediately under the slow clamp")
    e.Config.Labels=true e.Config.NativeLabels=true
    enemy.Character:FindFirstChild("HumanoidRootPart").Position=vector(10,0,-30)
    forceRefresh()
    local billboards,labelObj=0,nil
    for _,i in ipairs(instances) do
        if i.ClassName=="BillboardGui" and not i.Destroyed then billboards+=1 end
        if i.ClassName=="TextLabel" then labelObj=i end
    end
    assert(billboards==1 and labelObj,"native billboard label created")
    local gui=labelObj.Parent
    assert(gui.ClassName=="BillboardGui" and gui.Adornee==enemy.Character:FindFirstChild("Head"),"native label adorns a BasePart")
    local writes=0
    labelObj.Text=nil
    local textIndex=getmetatable(labelObj).__index local textShadow={}
    setmetatable(labelObj,{__index=function(t,k) if k=="Text" then return textShadow[k] end return textIndex(t,k) end,__newindex=function(t,k,v) if k=="Text" then writes+=1 textShadow[k]=v return end rawset(t,k,v) end})
    forceRefresh()
    assert(writes==0,"unchanged label text is not rewritten on a forced refresh")
    enemy.Character:FindFirstChild("HumanoidRootPart").Position=vector(12,0,-30)
    forceRefresh()
    assert(writes==1,"changed distance rewrites the label once")
    e.Config.Enabled=false e:Update(0) assert(gui.Enabled==false,"module off disables native label")
    e.Config.Enabled=true forceRefresh() assert(gui.Enabled==true,"valid render re-enables native label")
    enemy.Character:FindFirstChildWhichIsA("Humanoid").Health=0 e:Update(0.001) assert(gui.Enabled==false,"dead character hides native label")
    enemy.Character:FindFirstChildWhichIsA("Humanoid").Health=100 forceRefresh() assert(gui.Enabled==true,"living character restores native label")
    enemy.Team=lp.Team e.Config.TeamCheck=true e:Update(0.001) assert(gui.Enabled==false,"team filter hides native label")
    enemy.Team="B" e.Config.TeamCheck=false forceRefresh() assert(gui.Enabled==true,"team filter release restores native label")
    e.Config.Labels=false e:Update(0.001)
    local alive=0 for _,i in ipairs(instances) do if i.ClassName=="BillboardGui" and not i.Destroyed then alive+=1 end end
    assert(alive==0,"native label destroyed on disable")
    local before=#drawings
    common.HasDrawing=false
    local noDraw=factories.ESP(common) noDraw.Config.Enabled=true noDraw.Config.Labels=true noDraw.Config.NativeLabels=true
    noDraw:Update(0.05)
    local native=false for _,i in ipairs(instances) do if i.ClassName=="BillboardGui" and not i.Destroyed then native=true end end
    assert(native and #drawings==before,"native label works without the Drawing API")
    noDraw.Config.Enabled=false noDraw:Update(0) noDraw:Cleanup() e:Cleanup()
end)
test("forward teleport steps along look vector and mobile jump falls back",function()
    local m=factories.Movement(common) m:Start() m.Config.TeleportDistance=50
    local root=lp.Character:FindFirstChild("HumanoidRootPart")
    assert(m:TeleportForward()==true,"forward teleport accepted")
    for _=1,8 do advance(.05) end
    assert(same(root.CFrame.Position,vector(0,0,-55)),"forward teleport follows the look vector")
    m.Config.JumpEnabled=false
    services.Input.JumpRequest:Fire() assert(#queued==0,"jump request ignored while super jump is off")
    m:RequestJump(true) assert(#queued==1,"mobile jump button queues the deferred jump")
    advance(.02) assert(lp.Character:FindFirstChildWhichIsA("Humanoid").Jump==true,"humanoid fallback jump")
    m.Config.JumpEnabled=true m.Config.JumpValue=70 m:RequestJump(true) advance(.02)
    assert(root.AssemblyLinearVelocity.Y==70,"forced jump still uses the multiplier")
    m:Cleanup() assert(m:TeleportForward()==false,"teleport forward inert after unload")
    finish()
end)


test("ESP native label MaxDistance follows config without redundant writes",function()
    factories.Common(common)
    common.UI={GetVisualInterval=function(_,base) return base*20 end}
    common.Candidates={NPCs={}}
    local e=factories.ESP(common) e.Config.Enabled=true e.Config.Labels=true e.Config.NativeLabels=true e.Config.MaxDistance=120
    local cam=workspaceFixture.CurrentCamera
    local function forceRefresh()
        workspaceFixture.CurrentCamera={CFrame=cam.CFrame,ViewportSize=cam.ViewportSize,WorldToViewportPoint=cam.WorldToViewportPoint}
        e:Update(0.001)
    end
    forceRefresh()
    local gui for _,i in ipairs(instances) do if i.ClassName=="BillboardGui" and not i.Destroyed then gui=i end end
    assert(gui,"native label built")
    assert(gui.MaxDistance==120,"built billboard captures the configured distance")
    local writes=0
    gui.MaxDistance=nil
    local guiIndex=getmetatable(gui).__index local guiShadow={}
    setmetatable(gui,{__index=function(t,k) if k=="MaxDistance" then return guiShadow[k] end return guiIndex(t,k) end,__newindex=function(t,k,v) if k=="MaxDistance" then writes+=1 guiShadow[k]=v return end rawset(t,k,v) end})
    forceRefresh() forceRefresh()
    assert(writes==0,"unchanged MaxDistance is not rewritten on forced refreshes")
    e.Config.MaxDistance=900 forceRefresh()
    assert(gui.MaxDistance==900 and writes==1,"raising MaxDistance reaches the existing billboard")
    e.Config.MaxDistance=60 forceRefresh()
    assert(gui.MaxDistance==60 and writes==2,"lowering MaxDistance reaches the existing billboard")
    -- Invalid distance values are finite-cleaned before any comparison: the
    -- billboard keeps its last valid distance and the on-screen path keeps
    -- rendering on the loaded default, so deleting the guard fails here (nil and
    -- the string raise, the negative value culls every entry, and any accepted
    -- rewrite trips the write counter).
    local function invalidDistance(value,label)
        e.Config.MaxDistance=value forceRefresh()
        assert(writes==3,label.." leaves the billboard untouched")
        assert(gui.MaxDistance==200,label.." keeps the last valid distance")
        assert(gui.Enabled==true and visibleDrawings()>=1,label.." keeps rendering on the fallback distance")
    end
    e.Config.MaxDistance=200 forceRefresh()
    assert(gui.MaxDistance==200 and writes==3,"valid distance matches the cached billboard")
    invalidDistance(nil,"nil MaxDistance")
    invalidDistance(0/0,"NaN MaxDistance")
    invalidDistance(math.huge,"infinite MaxDistance")
    invalidDistance(-math.huge,"negative-infinite MaxDistance")
    invalidDistance(0,"zero MaxDistance")
    invalidDistance(-30,"negative MaxDistance")
    invalidDistance("far","non-numeric MaxDistance")
    e.Config.MaxDistance="200" forceRefresh()
    assert(writes==3,"numeric-string distance is accepted and matches the cached billboard")
    e.Config.MaxDistance=250 forceRefresh()
    assert(gui.MaxDistance==250 and writes==4,"valid distance resumes syncing")
    e.Config.Labels=false e:Update(0.001) e:Cleanup()
end)
test("ESP native label rolls back a half-built gui and refuses a detached parent",function()
    factories.Common(common)
    common.UI={GetVisualInterval=function(_,base) return base*20 end}
    common.Candidates={NPCs={}}
    local e=factories.ESP(common) e.Config.Enabled=true e.Config.Labels=true e.Config.NativeLabels=true
    local cam=workspaceFixture.CurrentCamera
    local function forceRefresh()
        workspaceFixture.CurrentCamera={CFrame=cam.CFrame,ViewportSize=cam.ViewportSize,WorldToViewportPoint=cam.WorldToViewportPoint}
        e:Update(0.001)
    end
    local function leaked()
        local n=0 for _,i in ipairs(instances) do if (i.ClassName=="BillboardGui" or i.ClassName=="TextLabel") and not i.Destroyed then n+=1 end end return n
    end
    common.RandomName=function() error("name allocation failed") end
    forceRefresh()
    assert(leaked()==0,"half-built billboard disposed, never parked in the pool")
    common.RandomName=function() return "fixture" end
    forceRefresh()
    assert(leaked()==2,"label rebuilt after the transient failure")
    common.GetGuiParent=function() return nil end
    forceRefresh()
    assert(leaked()==0,"missing gui parent disposes instead of leaving a detached billboard")
    common.GetGuiParent=function() return lp:FindFirstChild("PlayerGui") end
    forceRefresh()
    assert(leaked()==2,"parent restored rebuilds the billboard")
    e.Config.Labels=false e:Update(0.001) e:Cleanup()
end)
print(("SCP runtime suites: %d passed, %d failed"):format(passed,failures))
assert(failures==0,"SCP runtime regression failures")
