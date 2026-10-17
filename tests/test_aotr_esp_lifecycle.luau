local checks, failures = 0, 0
local function expect(value, message) checks += 1;assert(value, message) end
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then print("PASS " .. name) else failures += 1;print("FAIL " .. name .. ": " .. tostring(err)) end
end
local V = {}
V.__index = function(v,k) if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end return V[k] end
V.__sub = function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},V) end
Vector3 = {new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},V) end}
Color3 = {fromRGB=function(r,g,b)
    local c={R=r/255,G=g/255,B=b/255}
    function c:Lerp(o,t) return Color3.fromRGB((self.R+(o.R-self.R)*t)*255,(self.G+(o.G-self.G)*t)*255,(self.B+(o.B-self.B)*t)*255) end
    return c
end}
UDim2 = {new=function(a,b,c,d) return {X={Scale=a,Offset=b},Y={Scale=c,Offset=d}} end,fromOffset=function(x,y) return {X={Offset=x},Y={Offset=y}} end,fromScale=function(x,y) return {X={Scale=x},Y={Scale=y}} end}
Enum = {Font={Gotham="Gotham",GothamBold="GothamBold"},HighlightDepthMode={AlwaysOnTop="AlwaysOnTop"}}
local function fixture()
    local allocated, children = {}, {}
    local failClass, failOccurrence, occurrence = nil, 0, 0
    local function create(class)
        if class==failClass then occurrence+=1;if occurrence==failOccurrence then error("injected allocation failure: "..class) end end
        local data={ClassName=class,Enabled=true,Visible=true,Destroyed=false}
        local o={};children[o]={}
        setmetatable(o,{__index=data,__newindex=function(self,k,v)
            if k=="Parent" then
                local old=data.Parent
                if old and children[old] then children[old][self]=nil end
                if v and children[v] then children[v][self]=true end
            end
            data[k]=v
        end})
        function o:Destroy()
            if self.Destroyed then return end
            self.Destroyed=true
            local owned={}
            for child in pairs(children[self]) do table.insert(owned,child) end
            for _,child in ipairs(owned) do child:Destroy() end
            self.Parent=nil
        end
        table.insert(allocated,o);return o
    end
    Instance={new=create}
    local parent=create("PlayerGui")
    local root={Position=Vector3.new(0,0,0)}
    local pool, readCount = {}, 0
    local app={Services={Players={LocalPlayer={}},Workspace={}},disposers={},errors={},active=true,Cloak=nil}
    function app:OnStop(fn) table.insert(self.disposers,fn) end
    function app:Character() if root then return {},{},root end end
    function app.GetGuiParent() return parent end
    function app.RandomName() return "fixture" end
    function app.Guard(_,fn) local ok,err=pcall(fn);if not ok then table.insert(app.errors,err) end end
    app.Titans={All=function() readCount+=1;return pool end}
    local module=__FACTORY__(app)
    local f={app=app,module=module,pool=pool,allocated=allocated,visualInterval=nil}
    app.GetVisualInterval=function(_,base) return f.visualInterval or base end
    function f:Entry(name,distance)
        local e={model={Name=name,Parent=true},nape={Position=Vector3.new(distance,0,0),Parent=true},humanoid={Health=50,MaxHealth=100},boss=false}
        table.insert(pool,e);return e
    end
    function f:Live(class)
        local out={}
        for _,o in ipairs(allocated) do if not o.Destroyed and o.ClassName==class then table.insert(out,o) end end
        return out
    end
    function f:Step(dt) module:Update(dt or 0.1) end
    function f:NoRoot() root=nil end
    function f:Fail(class,n) failClass=class;failOccurrence=n;occurrence=0 end
    function f:Recover() failClass=nil end
    function f:Reads() return readCount end
    function f:Stop() app.active=false;for _,fn in ipairs(app.disposers) do fn() end end
    return f
end
test("disabled path allocates no GUI and reads no candidates",function()
    local f=fixture();for _=1,60 do f:Step(1/60) end
    expect(#f.allocated==1,"disabled module must not allocate")
    expect(f:Reads()==0,"disabled module must not read pool")
end)
test("10Hz refresh reuses records and updates labels",function()
    local f=fixture();local e=f:Entry("Normal",25);f.module.Config.Enabled=true
    f:Step(0.01);expect(#f:Live("BillboardGui")==0,"cadence defers allocation")
    f:Step(0.1);expect(#f:Live("BillboardGui")==1,"first refresh builds one record")
    local b=f:Live("BillboardGui")[1];local allocated=#f.allocated
    for _=1,100 do f:Step() end
    expect(#f.allocated==allocated,"stable entries must reuse instances")
    expect(f:Reads()==101,"one candidate read per refresh")
    e.model.Name="Renamed";e.humanoid.Health=25;f:Step()
    local name,fill
    for _,o in ipairs(f:Live("TextLabel")) do if o.Name=="Name" then name=o end end
    for _,o in ipairs(f:Live("Frame")) do if o.Name=="BarFill" then fill=o end end
    expect(name.Text=="Renamed","model rename must update existing label")
    expect(fill.Size.X.Scale==0.25,"health updates existing bar")
    expect(f:Live("BillboardGui")[1]==b,"record identity is stable")
end)
test("live display settings apply without respawn",function()
    local f=fixture();local e=f:Entry("Normal",25);local c=f.module.Config;c.Enabled=true;f:Step()
    local b=f:Live("BillboardGui")[1]
    local name
    for _,o in ipairs(f:Live("TextLabel")) do if o.Name=="Name" then name=o end end
    c.Tags=false;f:Step();expect(name.Visible==false,"Tags toggle must hide name label")
    expect(b.Enabled==true,"independent health/distance remain enabled")
    c.Tags=true;c.MaxDistance=80;f:Step();expect(name.Visible==true and b.MaxDistance==80,"Tags and range updates apply")
    c.Tags=false;c.Health=false;c.Distance=false;f:Step();expect(b.Enabled==false,"all display channels off hides billboard")
    c.Tags=true;c.Health=true;c.Distance=true
    c.NapeHighlight=true;f:Step();expect(#f:Live("Highlight")==1,"enable highlight after allocation")
    local h=f:Live("Highlight")[1];e.boss=true;f:Step()
    expect(h.FillColor==c.BossColor and h.OutlineColor==c.BossColor,"highlight color follows entry classification")
    c.NapeHighlight=false;f:Step();expect(#f:Live("Highlight")==0,"disable highlight reclaims instance")
end)
test("replacement nape does not leave stale billboard adornee",function()
    local f=fixture();local e=f:Entry("Normal",25);f.module.Config.Enabled=true;f:Step()
    local b=f:Live("BillboardGui")[1];e.nape.Parent=nil;e.nape={Parent=true,Position=Vector3.new(10,0,0)};f:Step()
    expect(b.Adornee==e.nape,"existing billboard must track replacement part")
    expect(#f:Live("BillboardGui")==1,"replacement does not allocate duplicate tag")
end)
test("despawn disabled path and stop reclaim render objects",function()
    local f=fixture();f:Entry("Normal",25);local c=f.module.Config;c.Enabled=true;c.NapeHighlight=true;f:Step()
    table.clear(f.pool);f:Step();expect(#f:Live("BillboardGui")==0 and #f:Live("Highlight")==0,"despawn reclaims record")
    f:Entry("Next",30);f:Step();c.Enabled=false;f:Step()
    expect(#f:Live("BillboardGui")==0 and #f:Live("Highlight")==0,"disable reclaims records")
    f:Stop();f:Stop();expect(#f:Live("ScreenGui")==0,"stop reclaims root GUI idempotently")
end)
test("pool loss clears stale render records",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true;f:Step()
    f.app.Titans=nil;f:Step();expect(#f:Live("BillboardGui")==0,"missing pool clears stale tags")
end)
test("root GUI external removal rebuilds one owned tree",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true;f:Step()
    f:Live("ScreenGui")[1]:Destroy();f:Step()
    expect(#f:Live("ScreenGui")==1 and #f:Live("BillboardGui")==1,"external destruction repairs root")
    f:Stop();expect(#f:Live("ScreenGui")==0,"repaired root is owned by stop")
end)
test("unparented GUI is replaced rather than leaked",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true;f:Step()
    local old=f:Live("ScreenGui")[1];old.Parent=nil;f:Step()
    expect(old.Destroyed,"unparented root must be reclaimed")
    expect(#f:Live("ScreenGui")==1 and #f:Live("BillboardGui")==1,"replacement is one valid tree")
    f:Stop();expect(#f:Live("ScreenGui")==0,"unparented replacement remains owned")
end)
test("missing root hides distance and health clamps",function()
    local f=fixture();local e=f:Entry("Normal",25);f.module.Config.Enabled=true;f:Step();f:NoRoot();e.humanoid.Health=-10;f:Step()
    for _,o in ipairs(f:Live("TextLabel")) do if o.Name=="Sub" then expect(o.Visible==false,"no character hides stale distance") end end
    for _,o in ipairs(f:Live("Frame")) do if o.Name=="BarFill" then expect(o.Size.X.Scale==0,"negative health clamps") end end
end)
test("allocation failures do not leak partial records",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true;f:Fail("TextLabel",2);f:Step()
    expect(#f.app.errors==1,"fixture failure is captured by guard")
    expect(#f:Live("BillboardGui")==0 and #f:Live("TextLabel")==0,"partially allocated record must be destroyed")
    f:Recover();f:Step();expect(#f:Live("BillboardGui")==1,"retry builds exactly one record")
    f:Stop();expect(#f:Live("TextLabel")==0,"retry cleanup owns all labels")
end)
test("highlight allocation failure preserves owned record for retry",function()
    local f=fixture();f:Entry("Normal",25);local c=f.module.Config;c.Enabled=true;f:Step()
    c.NapeHighlight=true;f:Fail("Highlight",1);f:Step()
    expect(#f.app.errors==1 and #f:Live("BillboardGui")==1,"failed highlight does not orphan existing tag")
    expect(#f:Live("Highlight")==0,"failed highlight has no live allocation")
    f:Recover();f:Step();expect(#f:Live("Highlight")==1,"highlight recovers without recreating tag")
    f:Stop();expect(#f:Live("BillboardGui")==0 and #f:Live("Highlight")==0,"retry is included in cleanup")
end)
test("missing GUI parent causes no detached allocations",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true
    local parent=f.app.GetGuiParent();f.app.GetGuiParent=function() return nil end;f:Step()
    expect(#f:Live("ScreenGui")==0 and #f:Live("BillboardGui")==0,"missing parent does not allocate")
    f.app.GetGuiParent=function() return parent end;f:Step()
    expect(#f:Live("BillboardGui")==1,"parent availability permits retry")
    f:Stop()
end)
test("unloaded module cannot revive GUI from a late update",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true;f:Step();f:Stop()
    local allocated=#f.allocated;f.module.Config.Enabled=true;f:Step()
    expect(#f.allocated==allocated and #f:Live("ScreenGui")==0,"late update cannot resurrect disposed render state")
end)
test("disabled cadence does not retain a partial active frame",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true;f:Step(0.08)
    f.module.Config.Enabled=false;f:Step();f.module.Config.Enabled=true;f:Step(0.03)
    expect(#f:Live("BillboardGui")==0,"re-enable starts a fresh cadence")
    f:Step(0.1);expect(#f:Live("BillboardGui")==1,"fresh cadence eventually refreshes")
    f:Stop()
end)
test("root setup failure rolls back the uncommitted GUI",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true
    local original=f.app.RandomName;f.app.RandomName=function() error("injected root setup failure") end;f:Step()
    expect(#f.app.errors==1 and #f:Live("ScreenGui")==0,"root setup error rolls back allocated screen")
    f.app.RandomName=original;f:Step();expect(#f:Live("ScreenGui")==1 and #f:Live("BillboardGui")==1,"root setup retries cleanly")
    f:Stop();expect(#f:Live("ScreenGui")==0,"root retry is reclaimed")
end)
test("highlight setup failure rolls back only its new instance",function()
    local f=fixture();f:Entry("Normal",25);f.module.Config.Enabled=true;f:Step();f.module.Config.NapeHighlight=true
    local original=f.app.RandomName;f.app.RandomName=function() error("injected highlight setup failure") end;f:Step()
    expect(#f.app.errors==1 and #f:Live("Highlight")==0,"highlight setup error rolls back allocated highlight")
    expect(#f:Live("BillboardGui")==1,"record remains owned after highlight setup error")
    f.app.RandomName=original;f:Step();expect(#f:Live("Highlight")==1,"highlight setup retries")
    f:Stop();expect(#f:Live("Highlight")==0,"highlight retry is reclaimed")
end)
test("throttled visual cadence defers refresh and still reclaims immediately",function()
    local f=fixture();local e=f:Entry("Normal",25);f.module.Config.Enabled=true
    f.visualInterval=0.5
    local reads=f:Reads()
    for _=1,4 do f:Step(0.1) end
    expect(f:Reads()==reads,"sub-threshold accumulated time does not refresh")
    f:Step(0.1)
    expect(f:Reads()==reads+1,"reaching the interval refreshes exactly once")
    f:NoRoot();f:Step(0.01)
    for _,o in ipairs(f:Live("TextLabel")) do if o.Name=="Sub" then expect(o.Visible==false,"character loss hides distance immediately under throttle") end end
    f.visualInterval=nil
    local baselineReads=f:Reads()
    for _=1,3 do f:Step(0.1) end
    expect(f:Reads()>baselineReads,"degraded cadence returns to 10Hz default")
    e.model.Name="Late";f.module.Config.Enabled=false;f:Step()
    expect(#f:Live("BillboardGui")==0,"disable reclaims immediately regardless of cadence")
    f:Stop()
end)
print((failures==0 and "GREEN " or "RED ")..checks.." AOTR render checks; "..failures.." failed suites")
assert(failures==0,"AOTR render lifecycle regression")
