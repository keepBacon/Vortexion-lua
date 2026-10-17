-- Execute real entries with inert local modules; no services or remotes.
local scene=__SCENE__
local checks=0
local builtinAssert=assert
local function assert(v,message) checks+=1;builtinAssert(v,message) end
local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local c={Connected=true}
        function c:Disconnect() self.Connected=false end
        table.insert(s.listeners,{fn=fn,c=c});return c
    end
    function s:Fire() for _,h in ipairs(self.listeners) do if h.c.Connected then h.fn() end end end
    return s
end
local function runEntry() local result=__ENTRY__ end
local function fixture(noWindow,initialFov)
    local changed=signal()
    local first={FieldOfView=initialFov or 70}
    workspace={CurrentCamera=first,GetPropertyChangedSignal=function() return changed end}
    game={PlaceId=14916516914}
    Enum={RenderPriority={Last={Value=2000}}}
    local queue={}
    task={spawn=function(fn) table.insert(queue,coroutine.create(fn)) end,wait=function() coroutine.yield() end}
    local clock=10
    tick=function() clock+=0.00001;return clock end
    local env={}
    getgenv=function() return env end
    warn=function() end
    local run={bindings={},unbinds=0}
    function run:BindToRenderStep(name,_,fn) self.bindings[name]=fn end
    function run:UnbindFromRenderStep(name) self.bindings[name]=nil;self.unbinds+=1 end
    local app={active=true,options={},buttons={},connections={},disposers={},notifications={},errors={},updates={},snapshots=0,Remotes={},Services={Workspace=workspace,RunService=run},player={}}
    function app.player:GetAttribute() return nil end
    function app:Alive() return self.active end
    function app:OnStop(fn) table.insert(self.disposers,fn) end
    function app:Track(c) if c then table.insert(self.connections,c) end;return c end
    function app:Notify(message) table.insert(self.notifications,message) end
    function app:Character() return nil end
    function app:Status() end
    function app:ProbeRemotes() end
    function app:ProbeHUD() end
    function app.Log() end
    function app.Guard(tag,fn) local ok,err=pcall(fn);if not ok then table.insert(app.errors,tag) end;return ok,err end
    function app:Cleanup()
        if not self.active then return end
        self.active=false
        for _,c in ipairs(self.connections) do c:Disconnect() end
        for _,fn in ipairs(self.disposers) do fn() end
    end
    env.VortexionAOTRCleanup=function() app:Cleanup() end
    local window={}
    function window:AddTab()
        local tab={}
        for _,method in ipairs({'AddToggle','AddSlider','AddDropdown'}) do
            tab[method]=function(_,id,cfg) assert(not app.options[id],'duplicate option '..id);app.options[id]=cfg end
        end
        function tab:AddButton(cfg) app.buttons[cfg.Title]=cfg end
        function tab:AddParagraph() end
        return tab
    end
    function window:InstallSettings() end
    function window:SelectTab(index) app.selected=index end
    function window:Destroy() app:Cleanup() end
    function app:Open() if noWindow then return nil end;self.ui=window;return window end
    AOTRCommon=function(actualScene) assert(string.lower(scene)==actualScene,'scene correct');return app end
    WindUI={};WindBridgeFactory=function() end
    __fixtureFactories={}
    for _,name in ipairs({'Cloak','Titans','Combat','Movement','ESP','Farm'}) do
        __fixtureFactories[name]=function(owner)
            assert(owner==app,'same module owner')
            local module={Config={}}
            function module.Start() end
            function module:Update(dt) app.updates[name]=(app.updates[name] or 0)+1 end
            function module:Count() return 0 end
            function module:DebugSnapshot() app.snapshots+=1;return {} end
            return module
        end
    end
    runEntry()
    local function option(suffix) return app.options[(scene=='Lobby' and 'AOTRLobby' or 'AOTRCamera')..suffix] end
    return {app=app,first=first,changed=changed,run=run,queue=queue,option=option,workspace=workspace}
end
local tests={}
local function test(name,fn) table.insert(tests,{name=name,fn=fn}) end

test('camera default options are registered',function()
    local f=fixture();assert(f.app.selected==1,'first tab selected')
    assert(f.option('Fov') and f.option(scene=='Lobby' and 'FovEnabled' or 'FovOn'),'camera controls exist')
end)
test('initial FOV matches bounded integer control default',function()
    for _,value in ipairs({50,80.5,120}) do
        local f=fixture(false,value);local toggle=f.option(scene=='Lobby' and 'FovEnabled' or 'FovOn')
        toggle.Callback(true)
        assert(f.first.FieldOfView==f.option('Fov').Default,'enabled value equals displayed control default')
        toggle.Callback(false);assert(f.first.FieldOfView==value,'out-of-range or fractional original restored')
        f.app:Cleanup()
    end
end)
test('missing window prevents partial entry installation',function()
    local f=fixture(true)
    assert(next(f.app.options)==nil,'no controls without window')
    assert(next(f.run.bindings)==nil,'no frame callback without window')
    assert(#f.queue==0,'no debug worker without window')
    assert(#f.changed.listeners==0,'no camera observer without window')
end)
test('many camera replacements release retired ownership',function()
    local f=fixture();local toggle=f.option(scene=='Lobby' and 'FovEnabled' or 'FovOn')
    toggle.Callback(true);f.option('Fov').Callback(105)
    local previous=f.first;local baseline=70
    for i=1,100 do
        local current={FieldOfView=75+i*0.1};f.workspace.CurrentCamera=current;f.changed:Fire()
        assert(previous.FieldOfView==baseline,'retired camera '..i..' restored immediately')
        previous.FieldOfView=77
        previous=current;baseline=75+i*0.1
    end
    f.app:Cleanup()
    assert(previous.FieldOfView==baseline,'last replacement baseline restored')
    assert(f.first.FieldOfView==77,'released camera external changes preserved')
end)
test('disabled observer preserves unowned camera changes',function()
    local f=fixture();f.first.FieldOfView=82
    local second={FieldOfView=90};f.workspace.CurrentCamera=second;f.changed:Fire()
    second.FieldOfView=96
    f.app:Cleanup()
    assert(f.first.FieldOfView==82,'untouched first camera not restored to startup')
    assert(second.FieldOfView==96,'untouched replacement camera not overwritten')
end)
test('each enable cycle captures its own baseline',function()
    local f=fixture();local toggle=f.option(scene=='Lobby' and 'FovEnabled' or 'FovOn')
    f.first.FieldOfView=82;toggle.Callback(true);f.option('Fov').Callback(105)
    toggle.Callback(false);assert(f.first.FieldOfView==82,'first activation baseline restored')
    f.first.FieldOfView=96;toggle.Callback(true);f.option('Fov').Callback(110)
    toggle.Callback(false);assert(f.first.FieldOfView==96,'second activation baseline restored')
    f.first.FieldOfView=99;f.app:Cleanup()
    assert(f.first.FieldOfView==99,'released baseline never overwrites external changes')
end)
test('late camera callbacks cannot revive a stopped entry',function()
    local f=fixture();local toggle=f.option(scene=='Lobby' and 'FovEnabled' or 'FovOn')
    toggle.Callback(true);f.option('Fov').Callback(105);f.app:Cleanup()
    assert(f.first.FieldOfView==70,'cleanup restores owned camera')
    toggle.Callback(true);f.option('Fov').Callback(120)
    assert(f.first.FieldOfView==70,'late callbacks leave restored camera unchanged')
    local second={FieldOfView=90};f.workspace.CurrentCamera=second;f.changed:Fire()
    f.option('Fov').Callback(115);toggle.Callback(false)
    assert(second.FieldOfView==90,'late callbacks do not claim replacement camera')
end)
test('camera replacement releases previous ownership immediately',function()
    local f=fixture();local toggle=f.option(scene=='Lobby' and 'FovEnabled' or 'FovOn')
    toggle.Callback(true);f.option('Fov').Callback(105)
    local second={FieldOfView=90};f.workspace.CurrentCamera=second;f.changed:Fire()
    assert(f.first.FieldOfView==70,'retired camera immediately restored')
    assert(second.FieldOfView==105,'new camera receives requested FOV')
    f.workspace.CurrentCamera=nil;f.changed:Fire()
    assert(second.FieldOfView==90,'camera disappearing releases prior ownership')
    local third={FieldOfView=85};f.workspace.CurrentCamera=third;f.changed:Fire()
    assert(third.FieldOfView==105,'camera arriving after gap receives requested FOV')
    f.app:Cleanup();assert(third.FieldOfView==85,'gap replacement restored on cleanup')
end)
test('disabling restores all cameras before reuse',function()
    local f=fixture()
    local toggle=f.option(scene=='Lobby' and 'FovEnabled' or 'FovOn')
    toggle.Callback(true);f.option('Fov').Callback(105)
    local second={FieldOfView=90};f.workspace.CurrentCamera=second;f.changed:Fire()
    assert(second.FieldOfView==105,'new camera modified')
    toggle.Callback(false)
    assert(f.first.FieldOfView==70,'inactive camera restored on disable')
    assert(second.FieldOfView==90,'current camera restored on disable')
    f.workspace.CurrentCamera=f.first;f.changed:Fire()
    assert(f.first.FieldOfView==70,'disabled reused camera stays original')
end)
if scene=='Battle' then
    test('sleeping debug task does not read modules after cleanup',function()
        local f=fixture();f.app.Debug=true
        assert(#f.queue==1,'one background debug loop')
        assert(coroutine.resume(f.queue[1]),'debug loop starts and yields')
        f.app:Cleanup();assert(coroutine.resume(f.queue[1]),'debug loop resumes after cleanup')
        assert(f.app.snapshots==0,'stopped debug task performs no snapshot reads')
        assert(coroutine.status(f.queue[1])=='dead','stopped debug task terminates')
    end)
    test('frame gate and late callback preserve inert module lifecycle',function()
        local f=fixture();local frame=f.run.bindings.VortexionAOTRFrame
        frame(0.003);assert(next(f.app.updates)==nil,'small dt performs no module updates')
        frame(0.016)
        for _,name in ipairs({'Titans','Combat','ESP','Farm'}) do assert(f.app.updates[name]==1,'one normal inert update for '..name) end
        assert(f.app.updates.Movement==nil,'movement is not double-ticked by entry')
        f.app:Cleanup();frame(0.016)
        for _,name in ipairs({'Titans','Combat','ESP','Farm'}) do assert(f.app.updates[name]==1,'late callback performs no update for '..name) end
    end)
    test('cleanup unbinds named render callback',function()
        local f=fixture();assert(f.run.bindings.VortexionAOTRFrame,'frame initially bound')
        f.app:Cleanup();assert(f.run.bindings.VortexionAOTRFrame==nil,'named frame unbound')
        f.app:Cleanup();assert(f.run.unbinds==1,'unbind once')
    end)
end
local failed=0
for _,item in ipairs(tests) do
    local ok,err=pcall(item.fn)
    if ok then print('PASS '..scene..' '..item.name) else failed+=1;print('FAIL '..scene..' '..item.name..': '..tostring(err)) end
end
print('AOTR '..scene..' entry: '..(#tests-failed)..' passed, '..failed..' failed, '..#tests..' total, '..checks..' checks')
assert(failed==0,'entry lifecycle failures')
