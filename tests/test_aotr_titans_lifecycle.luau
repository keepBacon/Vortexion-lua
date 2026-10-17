-- Pure local instances, signals and clock; no Roblox services or loader.
local now=0
local checkCount=0
local builtinAssert=assert
local function assert(condition,message)
    checkCount+=1
    return builtinAssert(condition,message)
end
local os={clock=function() return now end}
tick=function() return now end
local Vec={}
Vec.__index=function(v,k)
    if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    return Vec[k]
end
Vec.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},Vec) end
local function vector(x,y,z) return setmetatable({X=x,Y=y,Z=z},Vec) end
Vector2={new=function(x,y) return {X=x,Y=y} end}
local function signal()
    local s={listeners={},connects=0,disconnects=0}
    function s:Connect(fn)
        self.connects+=1
        local c={Connected=true}
        function c:Disconnect()
            if self.Connected then s.disconnects+=1;self.Connected=false end
        end
        table.insert(self.listeners,{fn=fn,connection=c})
        return c
    end
    function s:Fire(...)
        for _,h in ipairs(self.listeners) do if h.connection.Connected then h.fn(...) end end
    end
    function s:Active()
        local n=0
        for _,h in ipairs(self.listeners) do if h.connection.Connected then n+=1 end end
        return n
    end
    return s
end
local function instance(name,class)
    local obj={Name=name,ClassName=class,children={},ChildAdded=signal(),ChildRemoving=signal(),reads=0,lookups=0}
    function obj:IsA(kind) return kind==self.ClassName or (kind=="BasePart" and self.ClassName=="Part") end
    function obj:Add(child)
        child.Parent=self;table.insert(self.children,child);self.ChildAdded:Fire(child)
    end
    function obj:Remove(child)
        for i,item in ipairs(self.children) do
            if item==child then self.ChildRemoving:Fire(child);table.remove(self.children,i);child.Parent=nil;return end
        end
    end
    function obj:GetChildren() self.reads+=1;return table.clone(self.children) end
    function obj:FindFirstChild(childName,recursive)
        self.lookups+=1
        for _,child in ipairs(self.children) do if child.Name==childName then return child end end
        if recursive then
            for _,child in ipairs(self.children) do local found=child:FindFirstChild(childName,true);if found then return found end end
        end
    end
    function obj:FindFirstChildOfClass(kind)
        for _,child in ipairs(self.children) do if child.ClassName==kind then return child end end
    end
    function obj:FindFirstChildWhichIsA(kind)
        for _,child in ipairs(self.children) do if child:IsA(kind) then return child end end
    end
    function obj:IsDescendantOf(parent)
        local current=self.Parent
        while current do if current==parent then return true end;current=current.Parent end
        return false
    end
    function obj:GetAttribute(key) return self.attributes and self.attributes[key] end
    return obj
end
local function titan(name,x)
    local model=instance(name or "Titan","Model")
    local hum=instance("Humanoid","Humanoid");hum.Health=100
    local root=instance("HumanoidRootPart","Part");root.Position=vector(x or 10,0,10)
    local nape=instance("Nape","Part");nape.Position=root.Position
    model:Add(hum);model:Add(root);model:Add(nape)
    return model,hum,root,nape
end
local factory=__FACTORY__
local function fixture(withFolder)
    now=10
    local workspace=instance("Workspace","Workspace")
    local camera={calls=0}
    function camera:WorldToViewportPoint(pos) self.calls+=1;return {X=pos.X,Y=pos.Y,Z=pos.Z},true end
    workspace.CurrentCamera=camera
    local folder=instance("Titans","Folder")
    if withFolder then workspace:Add(folder) end
    local app={active=true,connections={},disposers={},root={Position=vector(0,0,0)},Services={Workspace=workspace,Players={}}}
    function app:Track(c) table.insert(self.connections,c);return c end
    function app:OnStop(fn) table.insert(self.disposers,fn) end
    function app:Alive() return self.active end
    function app:Character() if self.root then return {},{},self.root end end
    function app.Log() end
    function app:Stop()
        self.active=false
        for _,c in ipairs(self.connections) do c:Disconnect() end
        for _,dispose in ipairs(self.disposers) do dispose() end
    end
    local module=factory(app)
    return {app=app,workspace=workspace,folder=folder,camera=camera,module=module}
end
local tests={}
local function test(name,fn) table.insert(tests,{name=name,fn=fn}) end

test("late folder subscribes once and spawn/despawn mark dirty",function()
    local f=fixture(false);f.module:Update(0)
    f.workspace:Add(f.folder);now+=0.11;f.module:Update(0)
    assert(f.folder.ChildAdded:Active()==1 and f.folder.ChildRemoving:Active()==1,"late folder listeners")
    local model=titan();f.folder:Add(model)
    assert(f.module:DebugSnapshot().dirty,"spawn dirty")
    f.module:Update(0);assert(#f.module:All()==1,"spawn scanned immediately")
    f.folder:Remove(model);assert(f.module:DebugSnapshot().dirty,"despawn dirty")
    f.module:Update(0);assert(f.module:DebugSnapshot().titans==0,"despawn removed")
    for _=1,20 do f.module:Update(0) end
    assert(f.folder.ChildAdded.connects==1 and f.folder.ChildRemoving.connects==1,"no duplicate listeners")
end)

test("folder replacement detaches old and dirties from new signals",function()
    local f=fixture(true);f.folder:Add(titan());f.module:Update(0)
    local replacement=instance("Titans","Folder")
    f.workspace:Remove(f.folder);f.workspace:Add(replacement);f.module:Update(0)
    assert(f.folder.ChildAdded:Active()==0 and f.folder.ChildRemoving:Active()==0,"old listeners detached")
    assert(replacement.ChildAdded:Active()==1 and replacement.ChildRemoving:Active()==1,"replacement subscribed")
    assert(f.module:DebugSnapshot().titans==0,"replacement clears old pool")
    f.folder.ChildAdded:Fire(titan());assert(not f.module:DebugSnapshot().dirty,"old signals inert")
    local model=titan();replacement:Add(model);assert(f.module:DebugSnapshot().dirty,"new spawn dirty")
    f.module:Update(0);replacement:Remove(model);assert(f.module:DebugSnapshot().dirty,"new despawn dirty")
end)

test("reparented folder no longer belongs to workspace",function()
    local f=fixture(true);f.module:Update(0)
    f.workspace:Remove(f.folder);instance("Elsewhere","Folder"):Add(f.folder)
    now+=0.11;f.module:Update(0)
    assert(f.folder.ChildAdded:Active()==0 and f.folder.ChildRemoving:Active()==0,"reparent detached")
    assert(f.module:DebugSnapshot().titans==0,"removed folder cleared")
end)

test("listener churn keeps app tracking bounded",function()
    local f=fixture(true);f.module:Update(0)
    local current=f.folder
    for _=1,30 do
        f.workspace:Remove(current)
        local replacement=instance("Titans","Folder");f.workspace:Add(replacement)
        now+=0.11;f.module:Update(0)
        assert(current.ChildAdded:Active()==0 and current.ChildRemoving:Active()==0,"replaced pair reclaimed")
        current=replacement
    end
    assert(#f.app.connections<=2,"app does not retain disconnected handles")
    assert(current.ChildAdded:Active()==1 and current.ChildRemoving:Active()==1,"exactly one live pair")
end)

test("stop is idempotent and never scans or resubscribes",function()
    local f=fixture(true);f.folder:Add(titan());f.module:Update(0)
    f.app:Stop();f.app:Stop()
    assert(f.folder.ChildAdded:Active()==0 and f.folder.ChildRemoving:Active()==0,"stop detaches")
    local connects=f.folder.ChildAdded.connects;local reads=f.folder.reads
    f.module:Update(0);f.module.Scan(true);f.module:Count();f.module:Nearest(false)
    assert(f.folder.ChildAdded.connects==connects,"no post-stop subscriptions")
    assert(f.folder.reads==reads,"no post-stop scans")
    assert(f.module:DebugSnapshot().titans==0 and #f.module:All()==0,"stopped cache stays empty")
end)

test("stable folder scans respect interval",function()
    local f=fixture(true);f.folder:Add(titan());f.module:Update(0)
    local reads=f.folder.reads
    for _=1,20 do now+=0.002;f.module:Update(0) end
    assert(f.folder.reads==reads,"stable frames do not scan")
    now+=0.11;f.module:Update(0);assert(f.folder.reads==reads+1,"interval scans once")
end)

test("missing folder idle does not force repeated scans",function()
    local f=fixture(false);f.module:Update(0)
    assert(not f.module:DebugSnapshot().dirty,"empty scan settles dirty")
    local lookups=f.workspace.lookups
    f.module.Scan(false);f.module.Scan(false)
    assert(f.workspace.lookups==lookups,"empty scan respects interval")
end)

local function primed()
    local f=fixture(true)
    local model,hum,root,nape=titan()
    f.folder:Add(model);f.module:Update(0)
    local entry=f.module:All()[1]
    assert(entry.screenPos and entry.onScreen and entry.worldDist>0 and entry.alive,"visual baseline")
    return f,model,hum,root,nape,entry
end
local function clearVisual(entry)
    assert(entry.screenPos==nil,"screen position cleared")
    assert(entry.onScreen==false,"on-screen flag cleared")
    assert(entry.worldDist==nil,"world distance cleared")
    assert(entry.outOfRange==false,"range flag cleared")
end

test("missing character root clears visuals but preserves titan health semantics",function()
    local f,_,hum,_,_,entry=primed()
    f.app.root=nil;now+=0.11;f.module:Update(0)
    clearVisual(entry);assert(entry.alive and entry.health==hum.Health,"alive is titan health, not character presence")
    assert(f.module:Nearest(false)==nil,"selection still requires character root")
    hum.Health=0;now+=0.11;f.module:Update(0)
    clearVisual(entry);assert(not entry.alive,"health refreshed without character root")
end)

test("missing character root clears previous out-of-range distance and flag",function()
    local f,_,_,_,nape,entry=primed()
    nape.Position=vector(1300,0,10);now+=0.11;f.module:Update(0)
    assert(entry.outOfRange and entry.worldDist>1200,"range baseline")
    f.app.root=nil;now+=0.11;f.module:Update(0)
    clearVisual(entry);assert(entry.alive,"live titan remains live")
end)

test("missing camera clears projection and recovers when camera returns",function()
    local f,_,_,_,_,entry=primed()
    f.workspace.CurrentCamera=nil;now+=0.11;f.module:Update(0)
    assert(entry.screenPos==nil and entry.onScreen==false,"no camera has no projection")
    assert(entry.worldDist>0 and not entry.outOfRange and entry.alive,"distance independent of camera")
    f.workspace.CurrentCamera=f.camera;now+=0.11;f.module:Update(0)
    assert(entry.screenPos and entry.onScreen,"camera recovery")
end)

test("out-of-range entries clear projection and return in range",function()
    local f,_,_,_,nape,entry=primed()
    nape.Position=vector(1300,0,10);now+=0.11;f.module:Update(0)
    assert(entry.screenPos==nil and entry.onScreen==false,"range exit clears projection")
    assert(entry.nape==nil and entry.outOfRange and entry.worldDist>1200 and entry.alive,"existing range semantics")
    nape.Position=vector(10,0,10);now+=0.11;f.module:Update(0)
    assert(entry.nape==nape and entry.screenPos and entry.onScreen and not entry.outOfRange,"range reentry")
end)

test("dead entries clear cached fields and revive without stale state",function()
    local f,_,hum,_,nape,entry=primed()
    hum.Health=0;now+=0.11;f.module:Update(0)
    clearVisual(entry);assert(not entry.alive and entry.health==0 and entry.nape==nil,"dead entry invalidated")
    assert(#f.module:All()==0 and f.module:Count()==0,"dead excluded")
    hum.Health=100;now+=0.11;f.module:Update(0)
    assert(entry.alive and entry.nape==nape and entry.onScreen and entry.health==100,"revived refreshed")
end)

test("reparented cached nape is re-resolved within its model",function()
    local f,model,_,_,nape,entry=primed()
    model:Remove(nape);instance("OtherModel","Model"):Add(nape)
    local replacement=instance("Nape","Part");replacement.Position=vector(30,0,10);model:Add(replacement)
    now+=0.11;f.module:Update(0)
    assert(entry.nape==replacement,"foreign nape not reused")
    assert(entry.screenPos.X==30,"replacement projection refreshed")
end)

test("missing nape invalidates cached projection and distance",function()
    local f,model,_,_,nape,entry=primed()
    model:Remove(nape);now+=0.11;f.module:Update(0)
    clearVisual(entry);assert(entry.nape==nil and not entry.alive,"missing nape invalidated")
end)

test("missing humanoid or root invalidates retired entry references",function()
    for _,missing in ipairs({"humanoid","root"}) do
        local f,model,hum,root,nape,entry=primed()
        if missing=="humanoid" then model:Remove(hum) else model:Remove(root);model:Remove(nape) end
        now+=0.11;f.module:Update(0)
        clearVisual(entry);assert(not entry.alive and entry.nape==nil,"invalid structure retired")
        assert(f.module:DebugSnapshot().titans==0,"invalid model removed from pool")
    end
end)

test("removed models invalidate held entry references",function()
    local f,model,_,_,_,entry=primed()
    f.folder:Remove(model);f.module:Update(0)
    clearVisual(entry);assert(not entry.alive and entry.nape==nil,"removed entry retired")
end)

test("folder removal within interval clears entries listeners and dirty",function()
    local f,_,_,_,_,entry=primed()
    f.workspace:Remove(f.folder);now+=0.001;f.module:Update(0)
    assert(f.module:DebugSnapshot().titans==0 and not f.module:DebugSnapshot().dirty,"missing folder settles immediately")
    assert(f.folder.ChildAdded:Active()==0 and f.folder.ChildRemoving:Active()==0,"missing folder detaches immediately")
    clearVisual(entry);assert(not entry.alive,"missing folder retires held entries")
    f.folder.ChildAdded:Fire(titan());assert(not f.module:DebugSnapshot().dirty,"removed folder events stay inert")
end)

test("stop invalidates held entry references",function()
    local f,_,_,_,_,entry=primed()
    f.app:Stop();f.app:Stop()
    clearVisual(entry);assert(not entry.alive and entry.nape==nil,"stop retires held entries")
end)

local failed=0
for _,case in ipairs(tests) do
    local ok,err=pcall(case.fn)
    if ok then print("PASS "..case.name) else failed+=1;print("FAIL "..case.name..": "..tostring(err)) end
end
print(string.format("AOTRTitans lifecycle: %d passed, %d failed, %d total, %d checks",#tests-failed,failed,#tests,checkCount))
builtinAssert(failed==0,"AOTRTitans lifecycle regressions")
