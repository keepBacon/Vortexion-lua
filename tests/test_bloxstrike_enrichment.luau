-- Deterministic Roblox API model: execute the real four factories, not copies.
local checked = 0
local function check(value, label)
    assert(value, label)
    checked += 1
end
local math = table.clone(math)
math.randomseed(12345)
local now, mouseMoves, presses, releases, cameraLerps = 0,0,0,0,0
local function tick() return now end
local function mousemoverel() mouseMoves += 1 end
local function mouse1press() presses += 1 end
local function mouse1release() releases += 1 end
local function warn(message) error(message) end
local deferred,holdDefers={},false
local task = { defer=function(fn,...) if holdDefers then local args=table.pack(...);table.insert(deferred,function()fn(table.unpack(args,1,args.n))end)else fn(...)end end, spawn=function(fn,...) fn(...) end, wait=function() end }
local function signal()
    local s = { items={} }
    function s:Connect(fn)
        local cn={Connected=true,fn=fn}
        function cn:Disconnect() self.Connected=false end
        table.insert(self.items,cn)
        return cn
    end
    function s:Fire(...)
        for _,cn in ipairs(table.clone(self.items)) do if cn.Connected then cn.fn(...) end end
    end
    function s:Count() local n=0; for _,cn in ipairs(self.items) do if cn.Connected then n+=1 end end; return n end
    return s
end
local V={}
local function vec(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},V) end
V.__index=function(v,k)
    if k=='Magnitude' then return math.sqrt(v.X^2+v.Y^2+v.Z^2) end
    if k=='Unit' then return v/v.Magnitude end
    return V[k]
end
V.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
V.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
V.__mul=function(a,b)if type(a)=='number' then a,b=b,a end;return vec(a.X*b,a.Y*b,a.Z*b)end
V.__div=function(a,b)return a*(1/b)end
V.__unm=function(a)return a*-1 end
V.__eq=function(a,b)return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
function V:Lerp(b,t)return self+(b-self)*t end
function V:Dot(b)return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
local Vector2={new=vec,zero=vec()}
local Vector3={new=vec,zero=vec()}
local CF={}
CF.__index=CF
local function cf(pos,look)return setmetatable({Position=pos or vec(),LookVector=look or vec(0,0,-1),RightVector=vec(1,0,0)},CF)end
function CF:Lerp(b) cameraLerps+=1; return b end
function CF:PointToWorldSpace(p)return self.Position+p end
CF.__mul=function(a,b)return cf(a.Position+b.Position,a.LookVector)end
local CFrame={new=function(x,y,z)return cf(type(x)=='table' and x or vec(x,y,z))end,lookAt=function(a,b)return cf(a,(b-a).Unit)end}
local Enum=setmetatable({}, {__index=function(t,k)local v=setmetatable({},{__index=function(_,x)return x end});rawset(t,k,v);return v end})
local C={}
function C.__eq(a,b)
    local ar,ag,ab=a.R or a.X,a.G or a.Y,a.B or a.Z
    local br,bg,bb=b.R or b.X,b.G or b.Y,b.B or b.Z
    return ar==br and ag==bg and ab==bb
end
local function color3(r,g,b)return setmetatable({R=r,G=g,B=b,X=r,Y=g,Z=b},C)end
local Color3={fromRGB=function(r,g,b)return color3(r/255,g/255,b/255)end,new=color3}
local function typeof(v)
    local mt=getmetatable(v)
    if mt==C then return 'Color3' end
    if mt==V then return 'Vector3' end
    return type(v)
end
local UDim2={fromOffset=function(x,y)return vec(x,y)end,fromScale=function(x,y)return vec(x,y)end,new=function(a,b,c,d)return {a,b,c,d}end}
local UDim={new=function(x,y)return vec(x,y)end}
local RaycastParams={new=function()return {}end}
local instances,drawings={},{}
local methods={}
local function node(class,name,parent)
    local p={ClassName=class,Name=name or class,ChildAdded=signal(),AncestryChanged=signal(),Destroyed=false}
    local n=setmetatable({_p=p,_children={},_changed={}}, {
        __index=function(t,k)return methods[k] or t._p[k]end,
        __newindex=function(t,k,v)
            if k=='Parent' and v and v.DenyChildren then error('Parent access denied')end
            local old=t._p[k];t._p[k]=v
            if k=='Parent' and old~=v then
                if old then for i,ch in ipairs(old._children)do if ch==t then table.remove(old._children,i);break end end end
                if v then table.insert(v._children,t);v.ChildAdded:Fire(t)end
                t.AncestryChanged:Fire(t,v)
            end
            if t._changed[k] then t._changed[k]:Fire()end
        end
    })
    if class=='Part' then
        p.Size=vec(2,2,2);p.Position=vec(5,0,-50);p.CFrame=cf(p.Position);p.CanCollide=true;p.Transparency=0.2;p.AssemblyLinearVelocity=vec()
    elseif class=='Humanoid' then p.Health=100;p.MaxHealth=100;p.WalkSpeed=16;p.MoveDirection=vec(1,0,0) end
    if class=='TextButton' then p.MouseButton1Click=signal() end
    table.insert(instances,n)
    n.Parent=parent
    return n
end
function methods:IsA(k)return self.ClassName==k or (k=='BasePart' and self.ClassName=='Part')end
function methods:GetChildren()return table.clone(self._children)end
function methods:GetDescendants()local out={};local function visit(n)for _,ch in ipairs(n:GetChildren())do table.insert(out,ch);visit(ch)end end;visit(self);return out end
function methods:FindFirstChild(name,recursive)for _,ch in ipairs(self:GetChildren())do if ch.Name==name then return ch end end;if recursive then for _,ch in ipairs(self:GetDescendants())do if ch.Name==name then return ch end end end end
function methods:FindFirstChildOfClass(class)for _,ch in ipairs(self:GetChildren())do if ch:IsA(class)then return ch end end end
function methods:FindFirstChildWhichIsA(class,recursive)for _,ch in ipairs(recursive and self:GetDescendants() or self:GetChildren())do if ch:IsA(class)then return ch end end end
function methods:IsDescendantOf(n)local p=self.Parent;while p do if p==n then return true end;p=p.Parent end;return false end
function methods:Destroy()if self.Destroyed then return end;self.Destroyed=true;for _,ch in ipairs(self:GetChildren())do ch:Destroy()end;self.Parent=nil end
function methods:GetPropertyChangedSignal(k)if not self._changed[k]then self._changed[k]=signal()end;return self._changed[k]end
function methods:Clone()
    local copy=node(self.ClassName,self.Name)
    for k,v in pairs(self._p)do if k~='Parent' and k~='ChildAdded' and k~='AncestryChanged' then copy[k]=v end end
    copy.PrimaryPart=nil
    for _,ch in ipairs(self:GetChildren())do local c=ch:Clone();c.Parent=copy;if self.PrimaryPart==ch then copy.PrimaryPart=c end end
    return copy
end
function methods:PivotTo(c)self.Pivot=c end
function methods:GetAttribute(k)return self._attributes and self._attributes[k]end
function methods:GetBoundingBox()return cf(self:FindFirstChild('HumanoidRootPart').Position),vec(4,6,2)end
local Instance={new=function(k)return node(k)end}
local Drawing={new=function(k)local d={Kind=k};function d:Remove()self.Removed=true;self.Visible=false end;table.insert(drawings,d);return d end}
local workspace=node('Workspace')
workspace.DescendantRemoving=signal()
local function camera()
    local c=node('Camera','Camera',workspace);c.CFrame=cf();c.ViewportSize=vec(800,600)
    c.WorldToViewportPoint=function(_,p)return vec(400+p.X,300-p.Y,-p.Z),true end
    return c
end
workspace.CurrentCamera=camera()
workspace.Raycast=function()return workspace.rayHit end
local localPlayer=node('Player','Local')
local remotePlayer=node('Player','Enemy')
localPlayer.Parent=workspace;remotePlayer.Parent=workspace
remotePlayer.DisplayName='Opponent'
local function character(name)
    local m=node('Model',name,workspace);local h=node('Humanoid','Humanoid',m)
    local r=node('Part','HumanoidRootPart',m);local head=node('Part','Head',m);head.Position=r.Position+vec(0,2,0)
    return m,h,r,head
end
local localModel,localHum,localRoot,localHead=character('LocalCharacter')
local enemyModel,enemyHum,enemyRoot,enemyHead=character('EnemyCharacter')
local uis={TouchEnabled=true,TouchStarted=signal(),TouchMoved=signal(),TouchEnded=signal(),WindowFocusReleased=signal(),InputBegan=signal(),InputEnded=signal(),IsKeyDown=function()return false end,IsMouseButtonPressed=function()return false end}
local run={Heartbeat=signal(),RenderStepped=signal()}
local players={LocalPlayer=localPlayer,PlayerRemoving=signal(),GetPlayers=function()return {localPlayer,remotePlayer}end,GetPlayerFromCharacter=function(_,m)if m==enemyModel then return remotePlayer end;return localPlayer end}
local replicated=node('Folder','ReplicatedStorage')
local lighting={Brightness=0.5,ClockTime=1,Ambient=vec(1,2,3),OutdoorAmbient=vec(4,5,6),GlobalShadows=true,FogEnd=900}
local pingReads=0
local stats={Network={ServerStatsItem={['Data Ping']={GetValue=function()pingReads+=1;return 100 end}}}}
local services={Players=players,RunService=run,UserInputService=uis,Workspace=workspace,ReplicatedStorage=replicated,Lighting=lighting,Stats=stats,VirtualUser={Button1Down=function()presses+=1 end,Button1Up=function()releases+=1 end}}
local gui=node('Folder','Gui')
local game={GetService=function(_,k)return services[k] or {}end,FindService=function()return gui end}
local Common=__COMMON__
local Combat=__COMBAT__
local Visual=__VISUAL__
local Cosmetic=__COSMETIC__
local controls={}
local buttons={}
local tab={}
local function add(_,id,opts)check(not controls[id],'unique UI ID '..id);controls[id]=opts;return opts end
tab.AddToggle=add;tab.AddDropdown=add;tab.AddSlider=add;tab.AddColorpicker=add
function tab:AddParagraph()end
function tab:AddButton(opts)buttons[opts.Title]=opts.Callback;return opts end
local current,enemy=true,true
local function context()
    controls={};buttons={}
    local c=Common({Services=services})
    for k,v in pairs(services)do c[k]=v end
    c.Tabs={Combat=tab,Visual=tab,Movement=tab,Appearance=tab,Knife=tab}
    c.Character=function()return localModel end
    c.Living=function(p)if p==localPlayer then return localModel,localHum else return enemyModel,enemyHum end end
    c.Enemy=function()return enemy end
    c.IsCurrent=function()return current end
    c.Notify=function()end
    c.Guard=function(_,fn,...)fn(...);return true end
    c.GetGuiParent=function()return gui end
    return c
end
local function set(id,value)assert(controls[id],id).Callback(value)end
local function cleanup(c)for i=#c.Disposers,1,-1 do c.Disposers[i]()end end
local function frame(dt)now+=dt;run.Heartbeat:Fire(dt);run.RenderStepped:Fire(dt)end
local function active(class,parent)local n=0;for _,v in ipairs(instances)do if v:IsA(class) and not v.Destroyed and (not parent or v:IsDescendantOf(parent))then n+=1 end end;return n end

-- UI-consumed movement-stick touches stay out of aim/fly; origins never drift.
do
    local raw=Common({Services=services});local playerGui=node('Folder','PlayerGui',localPlayer)
    gui.DenyChildren=true;check(raw.GetGuiParent()==playerGui,'CoreGui permission fallback to PlayerGui');gui.DenyChildren=false;cleanup(raw)
    local c=context()
    local first={Position=vec(600,100)};local second={Position=vec(610,100)}
    uis.TouchStarted:Fire(first,true);check(not c.Touch.Held,'processed UI touch ignored')
    uis.TouchStarted:Fire({Position=vec(100,100)},false);check(not c.Touch.Held,'left movement stick ignored')
    uis.TouchStarted:Fire(first,false);uis.TouchStarted:Fire(second,false)
    first.Position=vec(640,80);second.Position=vec(650,40)
    uis.TouchMoved:Fire(second);uis.TouchMoved:Fire(first)
    local drag,vertical=c.Touch:Drag()
    check(drag==vec(40,-20) and vertical==-60,'stable two-finger origins and arrival order')
    uis.TouchEnded:Fire(first);drag,vertical=c.Touch:Drag()
    check(c.Touch.Held and drag==vec(40,-60) and vertical==0,'remaining finger promoted')
    uis.WindowFocusReleased:Fire();check(not c.Touch.Held,'focus loss cancels touch')
    for _=1,100 do check(c.Ping()==0.1,'cached ping value')end
    check(pingReads==1,'ping sampled once per interval');now+=0.6;c.Ping();check(pingReads==2,'ping cache expires')
    cleanup(c);check(uis.TouchStarted:Count()==0 and uis.WindowFocusReleased:Count()==0,'touch cleanup disconnects')
end

-- Hitbox/trigger operate independently; stale target gates re-run immediately.
do
    local c=context();local combat=Combat(c)
    local size,alpha,collision=enemyHead.Size,enemyHead.Transparency,enemyHead.CanCollide
    set('BloxHitboxMode','fullBody');set('BloxHitbox',true)
    for _=1,80 do now+=0.1;combat:Update(0.1)end
    check(enemyHead.Size.X>size.X and enemyHead.Size.X<=size.X+4.4,'independent bounded hitbox')
    players.PlayerRemoving:Fire(remotePlayer)
    check(enemyHead.Size==size and #combat:GetCandidates()==0,'player removal restores hitbox and clears candidate references')
    now+=0.1;combat:Update(0.1);check(enemyHead.Size.X>size.X,'hitbox re-enters after player event fixture')
    set('BloxHitbox',false)
    check(enemyHead.Size==size and enemyHead.Transparency==alpha and enemyHead.CanCollide==collision,'hitbox immediate full restore')
    set('BloxAimEnabled',true);set('BloxAimHitChance',100);set('BloxAimMode','Both')
    local moves=mouseMoves;combat:Update(0.1)
    check(mouseMoves>moves,'Both near-center keeps viewport second return')
    check(combat:GetLock()~=nil,'visible enemy lock')
    set('BloxFovColor','Cyan')
    local stroke=gui:FindFirstChildWhichIsA('UIStroke',true);check(stroke and stroke.Color==Color3.fromRGB(0,180,255),'FOV color updates existing stroke')
    set('BloxAimDistance',50);check(combat:GetLock()==nil,'distance setting enforced');set('BloxAimDistance',500)
    local project=workspace.CurrentCamera.WorldToViewportPoint
    workspace.CurrentCamera.WorldToViewportPoint=function(_,p)return vec(400+p.X,300-p.Y,-p.Z),false end
    check(combat:GetLock()==nil,'off-screen return invalidates lock');workspace.CurrentCamera.WorldToViewportPoint=project
    node('Part','Torso',enemyModel);node('Part','LeftUpperArm',enemyModel);set('BloxAimPart','Random')
    local random=math.random
    math.random=function(a,b)if b then return b elseif a then return random(a)else return random()end end
    local lock=combat:GetLock();math.random=random
    check(lock.part==enemyHead,'sparse Random model caches fallback after six misses')
    for _=1,20 do check(combat:GetLock().part==lock.part,'random part stable across consumers')end;set('BloxAimPart','Head')
    workspace.rayHit={Instance=enemyHead};check(combat:GetLock()~=nil,'target itself does not block wall check')
    local wall=node('Part','Wall',workspace);workspace.rayHit={Instance=wall};check(combat:GetLock()==nil,'new wall invalidates lock immediately')
    workspace.rayHit=nil;enemy=false;check(combat:GetLock()==nil,'team flip invalidates cached lock');enemy=true
    enemyHum.Health=0;check(combat:GetLock()==nil,'dead target invalidates lock');enemyHum.Health=100
    local oldRoot=enemyRoot.Position;enemyRoot.Position=vec(50,0,-10);check(combat:GetLock()==nil,'maximum angle enforced');enemyRoot.Position=oldRoot
    local old=enemyModel;enemyModel=node('Model','Respawn',workspace);check(combat:GetLock()==nil,'model identity revalidated');enemyModel=old
    set('BloxAimHitChance',0);check(combat:GetLock()==nil,'hit chance enforced on bullet accessor');set('BloxAimHitChance',100)
    set('BloxTouchAim',true);check(combat:GetLock()==nil,'hold gate enforced without input')
    uis.TouchStarted:Fire({Position=vec(600,100)},false);check(combat:GetLock()~=nil,'touch hold allows lock')
    uis.WindowFocusReleased:Fire();set('BloxTouchAim',false)
    set('BloxAimEnabled',false);set('BloxTriggerAssist',true)
    combat:Update(0.1);check(presses>0 and combat:DebugSnapshot().firing,'independent trigger press')
    local releaseBefore=releases;set('BloxTriggerAssist',false);check(releases==releaseBefore+1,'disable pairs trigger release')
    set('BloxTriggerAssist',true);now+=0.2;combat:Update(0.1);releaseBefore=releases
    combat:Stop();check(releases==releaseBefore+1 and #combat:GetCandidates()==0,'Stop releases mouse and clears target cache')
    local before=presses;combat:Update(1);check(presses==before,'stopped combat does not restart')
    cleanup(c);check(active('ScreenGui')==0,'combat GUI cleanup')
end

-- ESP pooling and movement use one scheduler, preserve original false values.
do
    local c=context();c.HasDrawing=true;local config=Visual(c)
    local count=active('Highlight');set('BloxESPTeam',false);check(active('Highlight')==count,'team toggle while ESP off creates nothing')
    set('BloxESP',true);set('BloxESPBox',true);set('BloxESPTracer',true);frame(0.1)
    check(active('Highlight')==1 and active('BillboardGui')==1,'one ESP entry')
    local firstCount=#instances;frame(0.1);check(#instances==firstCount,'steady ESP allocates no objects')
    check(#drawings==2 and drawings[1].Visible and drawings[2].Visible,'drawing box and tracer projected')
    local label=enemyModel:FindFirstChildOfClass('BillboardGui'):FindFirstChildOfClass('TextLabel')
    check(label.Text:find('HP') and label.Text:find('studs') and label.Text:find('Opponent'),'ESP name health distance')
    set('BloxESPBox',false);set('BloxESPTracer',false);frame(0.1);check(not drawings[1].Visible and not drawings[2].Visible,'disabled drawings hidden')
    set('BloxESP',false);check(active('Highlight')==0 and drawings[1].Removed and drawings[2].Removed,'ESP cleanup destroys draw pool')
    local speed=localHum.WalkSpeed;set('BloxSpeedEnabled',true);frame(0.1);check(localHum.WalkSpeed==24,'speed applied')
    local oldHum,oldModel=localHum,localModel
    localModel,localHum,localRoot,localHead=character('RespawnLocal');localHum.WalkSpeed=18;frame(0.1)
    check(oldHum.WalkSpeed==speed and localHum.WalkSpeed==24,'respawn restores old humanoid and tracks new one')
    set('BloxSpeedEnabled',false);check(localHum.WalkSpeed==18,'new humanoid original speed restored')
    localHead.CanCollide=false;set('BloxNoclip',true);frame(0.1);check(not localRoot.CanCollide,'noclip applied')
    set('BloxNoclip',false);check(localRoot.CanCollide and not localHead.CanCollide,'noclip restores true and false values')
    local originalVelocity=vec(3,2,1);localRoot.AssemblyLinearVelocity=originalVelocity
    set('BloxFlyEnabled',true);frame(0.1);check(localRoot.AssemblyLinearVelocity==vec(),'fly neutral stops velocity')
    set('BloxFlyEnabled',false);check(localRoot.AssemblyLinearVelocity==originalVelocity,'fly velocity restored')
    set('BloxFullbright',true);check(not lighting.GlobalShadows,'fullbright applies')
    cleanup(c);check(lighting.GlobalShadows and lighting.ClockTime==1 and lighting.FogEnd==900,'lighting restored')
    check(run.Heartbeat:Count()==0,'single scheduler cleanup')
end
do
    local c=context();c.HasDrawing=false;Visual(c)
    set('BloxESPBox',true);set('BloxESP',true);frame(0.1)
    check(active('SelectionBox')==1,'native ESP box when Drawing unavailable')
    enemyModel.Parent=nil;check(active('Highlight')==0 and active('SelectionBox')==0,'ancestry removal destroys native ESP entry');enemyModel.Parent=workspace
    for _=1,50 do set('BloxESP',false);set('BloxESP',true);frame(0.05)end
    check(active('Highlight')==1 and active('BillboardGui')==1 and run.Heartbeat:Count()==1,'rapid toggles keep one entry and scheduler')
    cleanup(c);check(active('SelectionBox')==0,'native box cleanup')
end
do
    local c=context();c.Caps.mouse1press=false;c.Caps.mouse1release=false
    local combat=Combat(c);set('BloxAimHitChance',100);set('BloxTriggerAssist',true);set('BloxTouchAim',true)
    local finger={Position=vec(600,100)};uis.TouchStarted:Fire(finger,false)
    now+=1;combat:Update(0.1);check(combat:DebugSnapshot().firing,'VirtualUser fallback fires independently')
    local before=releases;uis.WindowFocusReleased:Fire();combat:Update(0.1)
    check(releases==before+1 and not combat:DebugSnapshot().firing,'focus loss releases fallback mouse')
    cleanup(c)
end

-- Asset-driven preview rebinding, wear/gloves and detached-surface cleanup.
do
    local assets=node('Folder','Assets',replicated);local skins=node('Folder','Skins',assets)
    local weapons=node('Folder','Weapons',assets)
    local function skin(category,partName)
        local folder=node('Folder',category,skins);local style=node('Folder','Style',folder)
        local cam=node('Folder','Camera',style);local wear=node('Folder','Factory New',cam)
        local part=node('Part',partName,wear);local surface=node('SurfaceAppearance','SurfaceAppearance',part);surface.ColorMap='original'
        return folder,wear
    end
    local _,wear=skin('Rifle','Body');local worn=node('Folder','Battle-Scarred',wear.Parent);local wornPart=node('Part','Body',worn);local wornSurface=node('SurfaceAppearance','SurfaceAppearance',wornPart);wornSurface.ColorMap='worn'
    local _,gloveWear=skin('Sports Gloves','Left Arm');local right=node('Part','Right Arm',gloveWear);node('SurfaceAppearance','SurfaceAppearance',right)
    skin('A-B','Body');skin('A B','Body')
    for _,name in ipairs({'Butterfly Knife','Karambit'})do local w=node('Folder',name,weapons);local m=node('Model','Camera',w);m.PrimaryPart=node('Part','Blade',m)end
    local cam=workspace.CurrentCamera;local model=node('Model','Rifle',cam);local weapon=node('Model','Weapon',model);local body=node('Part','Body',weapon)
    local original=node('SurfaceAppearance','SurfaceAppearance',body)
    for _,side in ipairs({'Left Arm','Right Arm'})do local arm=node('Model',side,model);node('Part','Glove',arm)end
    local c=context();Cosmetic(c)
    check(controls.BloxSkin_A_B and controls.BloxSkin_A_B_412d42,'category ID collision resolved')
    set('BloxSkinEnabled',true)
    check(original.Parent==nil and body:FindFirstChildOfClass('SurfaceAppearance')~=original,'original material preserved off-tree')
    check(model:FindFirstChild('Glove',true):FindFirstChildOfClass('SurfaceAppearance')~=nil,'glove mapped to arm')
    set('BloxSkinWear','Battle-Scarred');check(body:FindFirstChildOfClass('SurfaceAppearance').ColorMap=='worn','wear source selected')
    local applied=body:FindFirstChildOfClass('SurfaceAppearance');body.Parent=nil;set('BloxSkinEnabled',false)
    check(applied.Destroyed and original.Destroyed,'detached part surfaces disposed')
    local oldKnife=node('Model','T Knife',cam);local oldBlade=node('Part','Blade',oldKnife)
    set('BloxCustomKnife',true);check(oldBlade.Transparency==1 and #cam:GetChildren()==3,'knife hides original and creates preview')
    local preview=cam:GetChildren()[3];set('BloxKnifeType','Karambit');check(preview.Destroyed and oldBlade.Transparency==1,'knife selection replaces preview immediately')
    oldKnife.Parent=nil;frame(0.1);check(oldBlade.Transparency==0.2,'unequip restores original knife')
    local newCamera=camera();workspace.CurrentCamera=newCamera
    check(cam.ChildAdded:Count()==0 and newCamera.ChildAdded:Count()==1,'camera listener rebound')
    local knife=node('Model','CT Knife',newCamera);local blade=node('Part','Blade',knife);frame(0.1);check(blade.Transparency==1,'camera replacement equips preview')
    local late=node('Folder','Late');node('Folder','Style',late);holdDefers=true;late.Parent=skins
    current=false;cleanup(c);for _,fn in ipairs(deferred)do fn()end;holdDefers=false;current=true
    check(not controls.BloxSkin_Late,'deferred category creates no UI after cleanup')
    check(blade.Transparency==0.2 and #newCamera:GetChildren()==1,'knife cleanup restores appearance')
    check(run.RenderStepped:Count()==0 and skins.ChildAdded:Count()==0 and newCamera.ChildAdded:Count()==0,'cosmetic connections cleanup')
end

-- Procedural knife preview: equip/inspect/swing poses, one-shot sounds, glove/sleeve
-- attachment, touch action buttons and reclamation on every teardown path.
do
    local assets=replicated:FindFirstChild('Assets')
    local weapons=assets:FindFirstChild('Weapons')
    local sleeves=node('Folder','Sleeves',assets)
    local sounds=node('Folder','Sounds',replicated)
    local function knifeSound(knife,folder)
        local perKnife=sounds:FindFirstChild(knife) or node('Folder',knife,sounds)
        local group=node('Folder',folder,perKnife)
        local s=node('Sound','1',group)
        s.Play=function(self)self.Played=true end
        local ended=signal()
        -- Real Sound.Ended is one RBXScriptSignal: Connect and Once share the same
        -- handler list, so firing it must reach both. The stub previously split them,
        -- which left production's ended:Connect(disposeSound) unreachable.
        function ended:Once(fn)
            local cn
            cn=ended:Connect(function(...)
                cn:Disconnect()
                fn(...)
            end)
        end
        ended.FireOnce=function(...)ended:Fire(...)end
        s.Ended=ended
        return s
    end
    for _,folder in ipairs({'Equip','Inspect','HitTwo','HitThree'})do knifeSound('Butterfly Knife',folder)end
    local knifeFolder=weapons:FindFirstChild('Butterfly Knife')
    local cameraModel=knifeFolder:FindFirstChild('Camera')
    for _,side in ipairs({'Left Arm','Right Arm'})do if not cameraModel:FindFirstChild(side) then node('Part',side,cameraModel)end end
    local function armAsset(parent,name)
        local m=node('Model',name,parent)
        m.PrimaryPart=node('Part',name,m)
        return m
    end
    local tGloves=node('Folder','T Glove',weapons)
    local ctGloves=node('Folder','CT Glove',weapons)
    local sleeve=node('Folder','IDF',sleeves)
    for _,side in ipairs({'Left Arm','Right Arm'})do armAsset(tGloves,side);armAsset(ctGloves,side);armAsset(sleeve,side)end
    local team=node('Folder','Terrorists',workspace);localModel.Parent=team
    local cam=camera();workspace.CurrentCamera=cam
    local oldKnife=node('Model','T Knife',cam);local oldBlade=node('Part','Blade',oldKnife)
    local c=context();Cosmetic(c)
    set('BloxCustomKnife',true)
    frame(0.1)
    local preview=cam:GetChildren()[2]
    check(preview and preview~=oldKnife,'view model cloned into the camera')
    check(oldBlade.Transparency==1,'original knife hidden behind the preview')
    local equipSound=preview:FindFirstChildOfClass('Sound')
    check(equipSound and equipSound.Played,'equip sound cloned from Assets/Sounds and played')
    -- The reclamation must come from production's Ended:Connect handler, not from any
    -- once-only sugar: exactly one live connection exists before the fire and none after.
    check(equipSound.Ended:Count()==1,'one-shot sound registers a single Ended:Connect reclaimer')
    equipSound.Ended:FireOnce()
    check(equipSound.Destroyed and active('Sound',preview)==0,'sound reclaimed on Ended')
    check(equipSound.Ended:Count()==0,'Ended reclaimer disconnected after reclaim')
    check(active('Motor6D',preview)==2,'T gloves attached to both view model arms')
    local arm=preview:FindFirstChild('Left Arm',true)
    check(arm and #arm:GetChildren()==2,'one glove clone plus its Motor6D per arm')
    check(preview.Pivot and preview.Pivot.Position.Y<-1.5,'equip animation lowers the view model')
    frame(0.4)
    check(preview.Pivot and preview.Pivot.Position.Y==-1.5,'equip animation settles on the base offset')
    set('BloxKnifeTouch',true)
    local layer
    for _,v in ipairs(gui:GetChildren())do if v.ClassName=='ScreenGui' then layer=v end end
    check(layer and active('ScreenGui',gui)==1,'touch layer created only for a touch device')
    local buttons={}
    for _,v in ipairs(layer:GetDescendants())do if v.ClassName=='TextButton'then table.insert(buttons,v)end end
    check(#buttons==3,'inspect, swing and stop buttons built')
    buttons[1].MouseButton1Click:Fire()
    frame(0.05)
    check(preview.Pivot.Position.X~=0,'inspect button drives the procedural preview pose')
    check(preview:FindFirstChildOfClass('Sound')~=nil,'inspect button plays its own sound')
    buttons[2].MouseButton1Click:Fire()
    frame(0.05)
    check(preview.Pivot.Position.Z>1.5,'swing button pushes the view model forward')
    buttons[3].MouseButton1Click:Fire()
    check(active('Sound',preview)==0,'stop button reclaims playing sounds')
    frame(0.05)
    check(preview.Pivot.Position.X==0 and preview.Pivot.Position.Y==-1.5 and preview.Pivot.Position.Z==1.5,'stop returns the base pose')
    set('BloxKnifeTouch',false)
    check(active('ScreenGui',gui)==0,'closing the toggle reclaims the button layer')
    local counterTeam=node('Folder','Counter-Terrorists',workspace);localModel.Parent=counterTeam;team:Destroy()
    local cam2=camera();workspace.CurrentCamera=cam2
    check(active('Motor6D')==0,'camera swap reclaims attachments before the next rebuild')
    node('Model','CT Knife',cam2);frame(0.1)
    check(active('Motor6D',cam2)==4,'replacement camera rebuilds CT sleeve and glove attachments')
    local ctArm=cam2:GetChildren()[2]:FindFirstChild('Right Arm',true)
    check(ctArm and #ctArm:GetChildren()==4,'sleeve plus glove plus two Motor6D per arm')
    set('BloxKnifeType','Karambit');frame(0.2)
    check(active('Motor6D')==0 and active('Sound',cam2)==0,'knife without sound or glove assets degrades per asset')
    set('BloxKnifeType','Bayonet');frame(0.2)
    check(#cam2:GetChildren()==1,'unknown knife equips nothing instead of inventing assets')
    set('BloxKnifeType','Butterfly Knife');frame(0.2)
    check(active('Motor6D',cam2)==4 and active('Sound',cam2)==1,'known knife rebuilds and replays its equip sound')
    set('BloxCustomKnife',false)
    check(active('Motor6D')==0 and active('Sound',cam2)==0 and active('ScreenGui',gui)==0,'disable reclaims attachments, sounds and buttons')
    -- Capability chain through the real Common touch flag and GetGuiParent: a non-touch
    -- device builds nothing, a denied GUI parent leaves no half-built layer, and a later
    -- grant builds the layer exactly once.
    local touchFlag=uis.TouchEnabled
    uis.TouchEnabled=false
    local flat=context();Cosmetic(flat)
    set('BloxCustomKnife',true);frame(0.1);set('BloxKnifeTouch',true);frame(0.1)
    check(active('ScreenGui',gui)==0,'non-touch device builds no knife buttons')
    set('BloxCustomKnife',false);cleanup(flat)
    uis.TouchEnabled=touchFlag
    local granted=context();Cosmetic(granted)
    set('BloxCustomKnife',true);frame(0.1);set('BloxKnifeTouch',true);frame(0.1)
    gui.DenyChildren=true;set('BloxKnifeTouch',false);set('BloxKnifeTouch',true);frame(0.1)
    check(active('ScreenGui',gui)==0,'denied GUI parenting leaves no half-built layer')
    gui.DenyChildren=false;set('BloxKnifeTouch',false);set('BloxKnifeTouch',true);frame(0.1)
    check(active('ScreenGui',gui)==1,'granted GUI parenting builds the layer once')
    set('BloxCustomKnife',false);frame(0.1)
    check(active('ScreenGui',gui)==0,'disabling the preview reclaims the granted layer')
    cleanup(granted)
    check(active('ScreenGui',gui)==0,'cleanup reclaims the granted layer')
    localModel.Parent=workspace
    cleanup(c)
    check(run.RenderStepped:Count()==0 and active('Motor6D')==0 and active('ScreenGui',gui)==0,'preview cleanup leaves no render loop or instances')
    check(oldBlade.Transparency==0.2,'original knife restored on cleanup')
end
check(uis.TouchStarted:Count()==0,'all context touch connections cleaned')
-- Local trail preview: manual only, camera-bound, self-expiring.
do
    local c=context()
    local rendersBefore,heartbeatsBefore=run.RenderStepped:Count(),run.Heartbeat:Count()
    Cosmetic(c)
    local rendersOwned,heartbeatsOwned=run.RenderStepped:Count(),run.Heartbeat:Count()
    local function trailCount()local n=0;for _,v in ipairs(instances)do if v.Name=='VortexionTrailPreview' and not v.Destroyed then n+=1 end end;return n end
    local function trailParts()local t={};for _,v in ipairs(instances)do if v.Name=='VortexionTrailPreview' and not v.Destroyed then t[#t+1]=v end end;return t end
    check(controls.BloxTrailPreview.Default==false,'trail preview toggle defaults off')
    check(controls.BloxTrailPreviewColor.Default.R==1 and controls.BloxTrailPreviewColor.Default.G==1 and controls.BloxTrailPreviewColor.Default.B==1,'trail preview color defaults white')
    check(type(buttons['预览本地拖尾'])=='function','trail preview button registered for collection')
    check(buttons['预览本地拖尾']()==false,'trail button refuses while the toggle is off')
    check(trailCount()==0,'no trail part spawned while disabled')
    set('BloxTrailPreview',true)
    check(buttons['预览本地拖尾']()==true,'trail button spawns one local part when enabled')
    check(run.RenderStepped:Count()==rendersOwned and run.Heartbeat:Count()==heartbeatsOwned,'trail preview reuses the existing render scheduler')
    local parts=trailParts()
    check(#parts==1,'exactly one trail part after one click')
    local part=parts[1]
    local cam=workspace.CurrentCamera
    check(part.Name=='VortexionTrailPreview','trail part named for identification')
    check(part.Anchored==true and part.CanCollide==false and part.CanTouch==false and part.CanQuery==false and part.CastShadow==false,'trail part flags stay inert')
    check(part.Material==Enum.Material.Neon,'trail part uses neon material')
    check(part.Transparency==0,'trail part starts fully opaque')
    check(part.Size.X==0.1 and part.Size.Y==0.1 and part.Size.Z==50,'trail part sized 0.1 x 0.1 x 50')
    check(part.Parent==cam,'trail part parented to the current camera')
    check(part.CFrame.Position==vec(0,0,-27),'trail midpoint sits at origin plus look vector times 25')
    check(part.Color.R==1 and part.Color.G==1 and part.Color.B==1,'trail part uses the current preview color')
    frame(0.25)
    check(not part.Destroyed,'trail preview survives the half way point')
    check(math.abs(part.Transparency-0.75)<0.000001,'trail preview is 75 percent transparent at 0.25 seconds')
    check(math.abs(part.Size.X-0.025)<0.000001 and part.Size.Z==50,'trail preview width shrinks with the fade')
    frame(0.25)
    check(part.Destroyed,'trail preview expires at 0.5 seconds')
    check(trailCount()==0,'trail entries released after expiry')
    check(buttons['预览本地拖尾']()==true,'trail button spawns again after expiry')
    check(trailCount()==1,'one trail part after the second click')
    workspace.CurrentCamera=camera()
    frame(0.05)
    check(trailCount()==0,'trail preview drops when the camera changes')
    workspace.CurrentCamera=cam
    check(buttons['预览本地拖尾']()==true,'trail spawns before the stale check')
    current=false
    frame(0.05)
    check(trailCount()==0,'trail preview clears when the script goes stale')
    current=true
    check(buttons['预览本地拖尾']()==true,'trail spawns before the limit loop')
    local oldest=trailParts()[1]
    check(buttons['预览本地拖尾']()==true,'trail spawns the second entry before the limit loop')
    local second=trailParts()[2]
    for _=3,33 do buttons['预览本地拖尾']() end
    check(trailCount()==32,'trail preview caps at 32 live entries')
    check(oldest.Destroyed,'oldest trail entry evicted at the cap')
    check(not second.Destroyed,'second trail entry survives the cap')
    set('BloxTrailPreview',false)
    check(trailCount()==0,'disabling the toggle reclaims every trail part')
    set('BloxTrailPreview',true)
    cam.DenyChildren=true
    check(buttons['预览本地拖尾']()==false,'trail button rolls back on a write failure')
    cam.DenyChildren=false
    check(trailCount()==0,'failed trail write destroys the partial part')
    check(buttons['预览本地拖尾']()==true,'trail button succeeds after the write failure clears')
    check(trailCount()==1,'failed write leaves no leaked entry')
    set('BloxTrailPreview',false)
    local reentry=cam.ChildAdded:Connect(function(child)
        if child.Name=='VortexionTrailPreview' then set('BloxTrailPreview',false) end
    end)
    set('BloxTrailPreview',true)
    check(buttons['预览本地拖尾']()==false,'trail button rolls back on a reentrant disable')
    check(trailCount()==0,'reentrant disable destroys the partial trail part')
    reentry:Disconnect()
    set('BloxTrailPreview',true)
    set('BloxTrailPreviewColor',Color3.new(0,1,0))
    check(buttons['预览本地拖尾']()==true,'trail spawns with a custom preview color')
    check(trailParts()[1].Color==Color3.new(0,1,0),'trail part uses the custom preview color')
    set('BloxTrailPreviewColor',vec(1,0,0))
    set('BloxTrailPreviewColor',Color3.new(0/0,1,1))
    set('BloxTrailPreviewColor',Color3.new(2,0,0))
    set('BloxTrailPreviewColor','red')
    set('BloxTrailPreview',false)
    check(trailCount()==0,'disabling clears before the invalid color check')
    set('BloxTrailPreview',true)
    check(buttons['预览本地拖尾']()==true,'trail spawns after invalid colors')
    check(trailParts()[1].Color==Color3.new(0,1,0),'invalid colors keep the previous preview color')
    cleanup(c)
    check(trailCount()==0,'unload reclaims every trail part')
    check(buttons['预览本地拖尾']()==false,'trail button refuses after unload')
    set('BloxTrailPreview',true)
    check(trailCount()==0,'toggle after unload stays inert')
    check(run.RenderStepped:Count()==rendersBefore and run.Heartbeat:Count()==heartbeatsBefore,'trail preview leaves no render or heartbeat connection')
end

-- Shared visual pacing contract: the bridge may only slow the cadence down.
do
    local c=context()
    local calls,firstBase=0,nil
    c.UI={GetVisualInterval=function(_,base)calls+=1;firstBase=firstBase or base;return base end}
    check(c.VisualInterval(0.05)==0.05,'bridge echoing base keeps cadence')
    check(firstBase==0.05,'base forwarded to bridge unchanged')
    c.UI.GetVisualInterval=function(_,base)return 1/10 end
    check(c.VisualInterval(0.05)==0.1,'VisualHz 10 widens the interval')
    c.UI.GetVisualInterval=function(_,base)return 1/120 end
    check(c.VisualInterval(0.05)==0.05,'bridge faster than base is ignored')
    c.UI.GetVisualInterval=function()return math.huge end
    check(c.VisualInterval(0.05)==0.05,'infinite bridge value ignored')
    c.UI.GetVisualInterval=function()return 0/0 end
    check(c.VisualInterval(0.05)==0.05,'NaN bridge value ignored')
    c.UI.GetVisualInterval=function()return -1 end
    check(c.VisualInterval(0.05)==0.05,'negative bridge value ignored')
    c.UI.GetVisualInterval=function()return 'wide' end
    check(c.VisualInterval(0.05)==0.05,'non-number bridge value ignored')
    c.UI.GetVisualInterval=function()error('bridge exploded')end
    check(c.VisualInterval(0.05)==0.05,'raising bridge falls back to base')
    local seen=calls
    c.UI.GetVisualInterval=nil
    check(c.VisualInterval(0.05)==0.05,'missing bridge method keeps base cadence')
    check(calls==seen,'absent bridge method is never invoked')
    check(c.VisualInterval(0)==0.05 and c.VisualInterval(math.huge)==0.05 and c.VisualInterval(0/0)==0.05 and c.VisualInterval('x')==0.05,'non-finite base falls back to the ESP default')
    cleanup(c)
end

-- Real Common driving real Visual: lowering VisualHz reduces ESP refreshes.
do
    local function measure(visualHz)
        local c=context()
        c.HasDrawing=false
        c.UI={GetVisualInterval=function(_,base)return math.max(base,1/visualHz)end}
        local config=Visual(c)
        set('BloxESP',true)
        set('BloxESPBox',true)
        for _=1,100 do frame(0.05)end
        local refreshes=config:ESPRefreshCount()
        cleanup(c)
        return refreshes,config
    end
    local fast=measure(60)
    local slow=measure(10)
    check(fast==100,'uncapped 60Hz bridge refreshes every 0.05 frame')
    check(slow==50,'VisualHz 10 halves ESP refreshes over the same wall clock')
    check(slow<fast,'lower VisualHz visibly reduces visual refresh count')
    local c=context()
    c.HasDrawing=false
    c.UI={GetVisualInterval=function(_,base)return math.max(base,0.5)end}
    local config=Visual(c)
    set('BloxESP',true)
    set('BloxESPBox',true)
    frame(0.3)
    frame(0.3)
    local before=config:ESPRefreshCount()
    local swapped=camera()
    workspace.CurrentCamera=swapped
    check(active('SelectionBox')==0,'camera replacement clears ESP without waiting for the throttled slot')
    frame(0.3)
    check(config:ESPRefreshCount()==before+1,'teardown re-arms the next slot instead of suppressing ESP')
    check(active('SelectionBox')==1,'ESP rebuilt for the replacement camera')
    check(config:ESPInterval()==0.5,'effective interval reflects the bridge answer')
    cleanup(c)
    check(active('SelectionBox')==0,'visual cleanup destroys native boxes')
end

-- Run the real Core entry with only bridge/cloak/bullet collaborators stubbed.
local coreGlobals,windows,renderBindings,debugTasks={},{},{},{}
local function getgenv()return coreGlobals end
local function BridgeStub()
    local ui={Destroyed=false}
    function ui:Notify()end
    function ui:OnDestroy(fn)self.destroyCallback=fn end
    function ui:Destroy()if self.Destroyed then return end;self.Destroyed=true;self.destroyCallback()end
    function ui:CreateWindow()
        local w={}
        function w:AddTab()return tab end
        function w:InstallSettings()end
        function w:SelectTab()end
        return w
    end
    table.insert(windows,ui);return ui
end
local cloakStops=0
local function CloakStub()return {Start=function()end,Stop=function()cloakStops+=1 end,Protect=function(v)return v end}end
local function BulletStub()return {Update=function()end,Status=function()return {path='fixture',bullets=0,hooks=0,remotes=0,totalRemotes=0}end}end
Enum.RenderPriority={Last={Value=2000}}
function run:BindToRenderStep(name,_,fn)check(not renderBindings[name],'render name unique');renderBindings[name]=fn end
function run:UnbindFromRenderStep(name)renderBindings[name]=nil end
task.spawn=function(fn)table.insert(debugTasks,fn)end
local Core=__CORE__
localPlayer.Character=localModel;remotePlayer.Character=enemyModel
controls={};Core()
local oldCleanup=coreGlobals.VortexionBloxCleanup
check(type(oldCleanup)=='function' and run.Heartbeat:Count()==1 and run.RenderStepped:Count()==1,'Core owns real feature schedulers')
set('BloxDebug',true)
local waits=0
task.wait=function()waits+=1;if waits==2 then oldCleanup()end end
debugTasks[1]()
check(waits==2 and windows[1].Destroyed and next(renderBindings)==nil,'debug formatter runs and cleanup ends debug loop')
check(coreGlobals.VortexionBloxCleanup==nil and coreGlobals.VortexionBloxNotify==nil,'owner globals released')
controls={};Core();controls={};Core()
check(windows[2].Destroyed and not windows[3].Destroyed and cloakStops==2,'reload destroys previous UI and cloak once')
local currentCleanup=coreGlobals.VortexionBloxCleanup;oldCleanup()
check(coreGlobals.VortexionBloxCleanup==currentCleanup and not windows[3].Destroyed,'stale cleanup preserves current owner')
currentCleanup();currentCleanup()
check(windows[3].Destroyed and cloakStops==3 and next(renderBindings)==nil,'idempotent unload unbinds exact render name')
check(run.Heartbeat:Count()==0 and run.RenderStepped:Count()==0 and uis.TouchStarted:Count()==0,'Core unload releases all real factories')
print('PASS BloxStrike checks: '..checked)
