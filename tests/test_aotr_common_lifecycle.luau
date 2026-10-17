-- Pure local fixtures; the production Common factory is injected by run_luau.mjs.
local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local c={Connected=true,disconnects=0}
        function c:Disconnect() self.disconnects+=1;self.Connected=false end
        table.insert(self.listeners,{fn=fn,connection=c})
        return c
    end
    function s:Fire(...)
        for _,h in ipairs(self.listeners) do
            if h.connection.Connected then h.fn(...) end
        end
    end
    return s
end

local Common=__FACTORY__
local checks,passed,failed=0,0,0
local function check(value,label)
    checks+=1
    if value then passed+=1 else failed+=1;print("FAIL check: "..label) end
end
local function fixture(mode)
    local f={mode=mode,warnings={},bridgeCalls=0,ordinaryCalls=0,stops=0}
    local client={}
    getgenv=function() return client end
    warn=function(message) table.insert(f.warnings,tostring(message)) end
    tick=function() return 100 end
    Enum={UserInputType={Touch="Touch"}}
    Vector2={zero={X=0,Y=0},new=function(x,y) return {X=x,Y=y} end}
    local input={TouchEnabled=true,InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal()}
    local services={Players={LocalPlayer={}},RunService={},Workspace={CurrentCamera={ViewportSize={X=1000,Y=600}}},
        ReplicatedStorage={},Lighting={},UserInputService=input,Stats={}}
    game={GetService=function(_,name) assert(services[name],"unexpected service: "..name);return services[name] end}
    f.input=input
    f.client=client
    f.ui={destroyCalls=0,onDestroyCalls=0,createCalls=0}
    f.visualValue=nil
    f.visualError=false
    function f.ui:GetVisualInterval(base)
        if f.visualError then error("fixture visual cadence error") end
        return f.visualValue or base
    end
    f.window={}
    function f.ui:OnDestroy(fn)
        self.onDestroyCalls+=1
        self.callback=fn
        if f.mode=="on_destroy_error" then error("fixture OnDestroy registration failed") end
        if f.mode=="destroy_on_register" then fn() end
    end
    function f.ui:CreateWindow(config)
        self.createCalls+=1
        f.windowConfig=config
        if f.mode=="window_error" then error("fixture CreateWindow failed") end
        if f.mode=="window_nil" then return nil end
        if f.mode=="destroy_on_create" then self.callback() end
        if f.mode=="yield_window" then coroutine.yield("window pending") end
        return f.window
    end
    function f.ui:Destroy()
        self.destroyCalls+=1
        if self.callback then self.callback() end
    end
    local wind={}
    local function bridge(actualWind,config)
        f.bridgeCalls+=1
        f.bridgeConfig=config
        assert(actualWind==wind,"original WindUI argument preserved")
        if f.mode=="bridge_error" then error("fixture Bridge failed") end
        if f.mode=="bridge_nil" then return nil end
        if f.mode=="yield_bridge" then coroutine.yield("bridge pending") end
        return f.ui
    end
    f.app=Common("lobby",wind,bridge)
    assert(f.app and f.app:Alive(),"fixture must construct a live real Common app")
    assert(#input.InputBegan.listeners==1 and #input.InputChanged.listeners==1 and #input.InputEnded.listeners==1
        and #input.WindowFocusReleased.listeners==1,"fixture must exercise production touch listeners")
    f.ordinary=signal()
    f.connection=f.app:Track(f.ordinary:Connect(function() f.ordinaryCalls+=1 end))
    f.app:OnStop(function() f.stops+=1 end)
    f.cleanup=client.VortexionAOTRCleanup
    input.InputBegan:Fire({UserInputType="Touch",Position={X=800,Y=300}},false)
    assert(f.app.Touch.Held,"fixture must activate production touch state")
    return f
end

local function checkClean(f,label,owned)
    check(not f.app:Alive(),label..": inactive")
    check(not f.connection.Connected and f.connection.disconnects==1,label..": ordinary listener reclaimed once")
    for _,name in ipairs({"InputBegan","InputChanged","InputEnded","WindowFocusReleased"}) do
        local c=f.input[name].listeners[1].connection
        check(not c.Connected and c.disconnects==1,label..": "..name.." reclaimed once")
    end
    check(not f.app.Touch.Held,label..": touch state cleared")
    check(f.stops==1,label..": disposer ran once")
    check(f.ui.destroyCalls==(owned and 1 or 0),label..": UI ownership reclaimed once")
    local before=f.ordinaryCalls
    f.ordinary:Fire()
    check(f.ordinaryCalls==before,label..": no late ordinary callback")
end
local function checkRepeatAndLate(f,label,owned)
    f.cleanup();f.cleanup()
    if f.ui.callback then f.ui.callback() end
    checkClean(f,label.." repeated cleanup",owned)
    local calls=f.bridgeCalls
    f.mode="ok"
    local ok,result=pcall(function() return f.app:Open() end)
    check(ok and result==nil,label..": late Open returns nil")
    check(f.bridgeCalls==calls,label..": late Open does not invoke Bridge")
    check(not f.app:Alive(),label..": late Open stays inactive")
    check(f.ui.destroyCalls==(owned and 1 or 0),label..": late Open creates no orphan")
end

-- A successful production flow proves syntax, service and Bridge fixture health.
local healthy=fixture("ok")
local ok,window=pcall(function() return healthy.app:Open() end)
check(ok and window==healthy.window,"healthy Open returns actual window")
check(healthy.app:Alive(),"healthy Open stays alive")
check(healthy.app.ui==healthy.ui,"healthy Open owns Bridge UI")
check(healthy.ui.onDestroyCalls==1 and healthy.ui.createCalls==1,"healthy initialization order completes")
check(healthy.bridgeConfig.Name=="AOTR" and healthy.bridgeConfig.Folder=="VortexionAOTR"
    and healthy.bridgeConfig.Section=="A T T A C K  O N  T I T A N","existing bridge IDs preserved")
check(healthy.windowConfig.Title=="AOTR 大厅","existing lobby title preserved")
healthy.cleanup()
checkClean(healthy,"healthy cleanup",true)
print("FIXTURE HEALTH: healthy real Common flow executed")

-- Visual cadence helper degrades exactly like the bridge contract.
local vf=fixture("ok")
local vok=pcall(function() return vf.app:Open() end)
check(vok,"visual helper: healthy Open for cadence fixture")
check(vf.app:GetVisualInterval(0.1)==0.1,"visual helper: no bridge value degrades to base")
vf.visualValue=0.5
check(vf.app:GetVisualInterval(0.1)==0.5,"visual helper: bridge value above base is honored")
vf.visualValue=0.05
check(vf.app:GetVisualInterval(0.1)==0.1,"visual helper: bridge value below base degrades to base")
vf.visualValue=math.huge
check(vf.app:GetVisualInterval(0.1)==0.1,"visual helper: infinite bridge value degrades to base")
vf.visualValue=-5
check(vf.app:GetVisualInterval(0.1)==0.1,"visual helper: non-positive bridge value degrades to base")
vf.visualValue=0.3
check(vf.app:GetVisualInterval(0.1)==0.3,"visual helper: fractional bridge value honored")
vf.visualValue=nil
check(vf.app:GetVisualInterval(math.huge)==0.1,"visual helper: infinite base sanitized to default")
check(vf.app:GetVisualInterval(0/0)==0.1,"visual helper: NaN base sanitized to default")
vf.visualError=true
check(vf.app:GetVisualInterval(0.25)==0.25,"visual helper: bridge error degrades to base")
vf.cleanup()
print("VISUAL CADENCE: app:GetVisualInterval degradation verified")

for _,mode in ipairs({"bridge_error","bridge_nil","on_destroy_error","window_error","window_nil"}) do
    local f=fixture(mode)
    local openOk,result=pcall(function() return f.app:Open() end)
    local owned=mode~="bridge_error" and mode~="bridge_nil"
    check(openOk,mode..": initialization error contained")
    check(openOk and result==nil,mode..": no half-initialized window returned")
    check(#f.warnings==1 and string.find(f.warnings[1],"WindUI initialization failed",1,true)~=nil,mode..": diagnostic emitted")
    checkClean(f,mode,owned)
    checkRepeatAndLate(f,mode,owned)
    -- Isolate cases even while intentionally running against broken production.
    f.cleanup()
end

for _,mode in ipairs({"destroy_on_register","destroy_on_create"}) do
    local f=fixture(mode)
    local openOk,result=pcall(function() return f.app:Open() end)
    check(openOk and result==nil,mode..": synchronous cleanup returns no stale window")
    if mode=="destroy_on_register" then check(f.ui.createCalls==0,mode..": no window creation after cleanup") end
    checkClean(f,mode,true)
    checkRepeatAndLate(f,mode,true)
end

for _,mode in ipairs({"yield_bridge","yield_window"}) do
    local f=fixture(mode)
    local result="not returned"
    local pending=coroutine.create(function() result=f.app:Open() end)
    local resumed,stage=coroutine.resume(pending)
    check(resumed and coroutine.status(pending)=="suspended" and stage~=nil,mode..": Open suspended locally")
    f.cleanup()
    local settled=coroutine.resume(pending)
    check(settled and coroutine.status(pending)=="dead" and result==nil,mode..": late completion returns no window")
    checkClean(f,mode,true)
    checkRepeatAndLate(f,mode,true)
end

print(string.format("AOTR Common lifecycle: passed=%d failed=%d checks=%d",passed,failed,checks))
assert(failed==0,string.format("production lifecycle assertions failed: %d/%d",failed,checks))
