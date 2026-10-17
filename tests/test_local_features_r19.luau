local suites, checks = 0, 0
local function check(value, message)
    checks += 1
    assert(value, message)
end
local function test(name, fn)
    local ok, err = pcall(fn)
    if not ok then error("R19 FAIL " .. name .. ": " .. tostring(err), 0) end
    suites += 1
    print("R19 PASS " .. name)
end
local function contains(text, part) return string.find(text, part, 1, true) ~= nil end

test("strict-instance appearance restoration", function()
    local appearanceSaved = {}
    local function object(className, blocked, unreadable)
        local properties, writes = {}, {count=0}
        return setmetatable({}, {
            __index=function(_, key)
                if key == "IsA" then return function(_, name)
                    if unreadable then error("IsA unavailable", 0) end
                    return name == className
                end end
                error("unknown Instance property " .. key, 0)
            end,
            __newindex=function(_, key, value)
                if blocked then error("destroyed write", 0) end
                properties[key]=value; writes.count += 1
            end,
        }), properties, writes
    end
    local model, modelProps, modelWrites = object("Model")
    local locked = object("Model", true)
    local highlight, highlightProps = object("Highlight")
    local part = object("BasePart")
    local invalid = object("Model", false, true)
    local parent = {}
    appearanceSaved[model]=parent; appearanceSaved[locked]=parent
    appearanceSaved[highlight]=0.35; appearanceSaved[part]=0.2; appearanceSaved[invalid]=parent
    __RESTORE_EXTRAS__
    __RESTORE_HIGHLIGHT__
    restoreExtras()
    check(modelProps.Parent == parent, "Model restored without Destroyed property")
    check(appearanceSaved[model] == nil and appearanceSaved[locked] == nil, "recognized models retired even on write failure")
    check(appearanceSaved[highlight] == 0.35 and appearanceSaved[part] == 0.2, "other types preserved")
    restoreHighlight()
    check(highlightProps.FillTransparency == 0.35 and appearanceSaved[highlight] == nil, "highlight restored")
    check(appearanceSaved[invalid] == parent and appearanceSaved[part] == 0.2, "failed IsA isolated")
    restoreExtras(); restoreHighlight()
    check(modelWrites.count == 1, "restore is idempotent")
end)

local function scaleFixture()
    local scaleValue, scaleBase, restoreOriginalScale = 1.06, 1, true
    local appearanceScaleSaved = setmetatable({}, {__mode="k"})
    __SCALE_HELPERS__
    return {apply=applyScale, restore=restoreScale, saved=appearanceScaleSaved,
        value=function(v) scaleValue=v end, manual=function(v) restoreOriginalScale=false; scaleBase=v end}
end
local function model(initial, readFails, writeFails)
    local state={scale=initial, writes=0}
    return setmetatable({
        GetScale=function() if readFails then error("GetScale missing",0) end; return state.scale end,
        ScaleTo=function(_, value)
            if writeFails then error("ScaleTo unavailable",0) end
            state.scale=value; state.writes+=1
        end,
    }, {__index=function(_, key) error("Model unknown "..key,0) end}), state
end
test("Model baseline retained across repeated applications", function()
    local f=scaleFixture(); local m,s=model(1.37)
    check(f.apply(m) and s.scale==1.06, "Model ScaleTo used")
    f.value(1.8); check(f.apply(m) and s.scale==1.8, "repeat applies current preference")
    check(f.saved[m]==1.37, "original baseline not overwritten")
    f.restore(); check(s.scale==1.37 and f.saved[m]==nil, "original restored, not default one")
    f.restore(); check(s.writes==3, "repeat cleanup has no writes")
end)
test("character replacement restores previous model before new application", function()
    local f=scaleFixture(); local a,sa=model(0.87); local b,sb=model(1.22)
    f.apply(a); f.apply(b)
    check(sa.scale==0.87 and sb.scale==1.06, "old character restored immediately")
    check(f.saved[a]==nil and f.saved[b]==1.22, "per-model ownership")
    f.restore(); check(sb.scale==1.22, "new model baseline restored")
end)
test("scale capability errors and invalid baselines fail closed", function()
    for _, value in ipairs({0,-1,math.huge,-math.huge,0/0}) do
        local f=scaleFixture(); local m,s=model(value)
        check(not f.apply(m) and s.writes==0 and f.saved[m]==nil, "invalid baseline skipped")
    end
    local f=scaleFixture(); local bad=model(1,true); check(not f.apply(bad), "GetScale failure contained")
    local locked=model(1.4,false,true); local good,s=model(0.91)
    check(not f.apply(locked), "ScaleTo failure contained")
    check(f.apply(good), "one bad model cannot interrupt the next")
    f.restore(); check(s.scale==0.91 and next(f.saved)==nil, "all remaining snapshots retired")
end)
test("explicit manual scale recovery remains available", function()
    local f=scaleFixture(); local m,s=model(1.37); f.manual(0.8); f.apply(m); f.restore()
    check(s.scale==0.8, "legacy manual scale value still consumed when explicitly selected")
end)

test("cosmetic idle fast path preserves every active condition", function()
    local state={enabled=false,knife=false}; local activeSounds={}; local anim={mode="idle",started=0,duration=1}
    local knifeModel, knifeFollow, elapsed, dirty=nil,nil,0,true
    local scans, redraws, reclaims, cameraReads=0,0,0,0
    local live=true
    local c={IsCurrent=function() return live end, RunService={RenderStepped={}},
        Workspace=setmetatable({}, {__index=function() cameraReads+=1; return nil end})}
    local callback
    function c.RunService.RenderStepped:Connect(fn) callback=fn; return {} end
    local function reconcileKnife() scans+=1 end
    local function updateCamera() redraws+=1 end
    local function reclaimSounds() reclaims+=1 end
    local function updateNative() return false end
    -- Trail lifetime and ownership are exercised by the complete cosmetic factory suite.
    local function updateTrailPreview() end
    local function clearTrailPreview() end
    local function tryNative() return false end
    local function tick() return 0 end
    __COSMETIC_FRAME__
    for _=1,100000 do callback(1/60) end
    check(scans==0 and reclaims==0 and cameraReads==0 and elapsed==0, "idle does no frame work")
    state.enabled=true; callback(0.2)
    check(scans==1 and redraws==1 and reclaims==1, "active skins still update dirty camera")
    state.enabled=false; state.knife=true; callback(0.2)
    check(scans==2 and reclaims==2, "knife activation is not skipped")
    state.knife=false; knifeModel={}; callback(0.2)
    check(scans==3 and reclaims==3, "remaining model is not skipped")
    knifeModel=nil; activeSounds.one=true; callback(0.2)
    check(scans==4 and reclaims==4, "remaining sounds reclaimed")
    activeSounds.one=nil; anim.mode="inspect"; callback(0.2)
    check(scans==5 and reclaims==5, "active animation not skipped")
    live=false; callback(0.2); check(scans==5 and reclaims==5, "lifecycle fence retained")
end)

local function bootLobby(mode, missing, broken)
    local state={alive=true,probes=0,reads=0,copies=0,messages={}}
    local callbacks={}
    local tab={}
    function tab:AddButton(info) callbacks[info.Title]=info.Callback end
    function tab:AddParagraph() return {} end
    function tab:AddSlider() return {} end
    function tab:AddToggle() return {} end
    local window={AddTab=function() return tab end, InstallSettings=function() end, SelectTab=function() end}
    local player={GetAttribute=function(_,name)
        if broken=="attribute" then error("attribute inaccessible",0) end
        return name=="Level" and 5 or 99
    end}
    local app={player=not missing and player or nil,HUD={blades={},spears={}}}
    function app:Open() return window end
    function app:Alive() return state.alive end
    function app:Notify(text) table.insert(state.messages,text) end
    function app:Status() end
    function app:OnStop() end
    function app:Track() end
    function app:Character()
        if missing then return nil end
        if broken=="health" then return {}, setmetatable({}, {__index=function() error("health inaccessible",0) end}) end
        return {}, {Health=75.8}
    end
    app.ProbeHUD=function(force)
        check(force==false, "HUD probing must use dot-call and cache")
        state.probes+=1
        if mode=="late-probe" then state.alive=false end
        if broken=="probe" then error("probe inaccessible",0) end
    end
    app.ReadCount=function(label)
        state.reads+=1
        if broken=="read" then error("label inaccessible",0) end
        if missing or label==nil then return nil,nil end
        if label==app.HUD.blades then return mode=="zero" and 0 or 3,8 end
        check(label==app.HUD.spears,"ReadCount received a self argument")
        return 2,4
    end
    local function clipboard(text)
        state.copies+=1
        if mode=="throw" then error("clipboard inaccessible",0) end
        if mode=="decline" then return false end
        state.text=text
        if mode=="late-copy" then state.alive=false end
    end
    local setclipboard=mode~="none" and clipboard or nil
    local toclipboard
    if mode=="secondary" then setclipboard=true; toclipboard=clipboard end
    local game={GameId=123,PlaceId=456}
    local workspace={CurrentCamera=not missing and {FieldOfView=broken=="fov" and math.huge or 80} or nil}
    function workspace:GetPropertyChangedSignal() return {Connect=function() return {Disconnect=function() end} end} end
    local AOTRCommon=function() return app end
    local WindUI,WindBridgeFactory={},{}
    do
        __LOBBY_ENTRY__
    end
    table.clear(state.messages)
    state.click=callbacks["复制大厅状态"]
    check(type(state.click)=="function","copy button actually registered")
    return state
end
test("lobby clipboard snapshot uses actual source and dot helpers", function()
    local s=bootLobby("success"); s.click()
    for _,text in ipairs({"GameId: 123","PlaceId: 456","等级: 5","经验: 99","75","80","3/8","2/4"}) do
        check(contains(s.text,text),"snapshot field "..text)
    end
    check(s.probes==1 and s.reads==2 and s.copies==1 and #s.messages==1,"one snapshot and one copy")
    check(contains(s.messages[1],"已复制"),"copy success explicit")
end)
for _,mode in ipairs({"none","throw","decline"}) do
    test("lobby clipboard fallback "..mode,function()
        local s=bootLobby(mode); s.click()
        check(#s.messages==1 and contains(s.messages[1],"GameId: 123"),"snapshot fallback, not false success")
    end)
end
test("lobby zero count and secondary clipboard capability",function()
    local s=bootLobby("zero"); s.click(); check(contains(s.text,"0/8"),"zero is valid")
    local secondary=bootLobby("secondary"); secondary.click(); check(secondary.copies==1,"malformed primary skips to valid secondary")
end)
test("lobby dead and late completion lifecycle fences",function()
    local s=bootLobby("success"); s.alive=false; s.click()
    check(s.probes==0 and s.copies==0 and #s.messages==0,"dead click has no effects")
    for _,mode in ipairs({"late-probe","late-copy"}) do
        local late=bootLobby(mode); late.click(); check(#late.messages==0,"late work cannot notify")
        if mode=="late-probe" then check(late.copies==0,"destroyed during read cannot copy") end
    end
end)
test("lobby missing or failing fields do not discard the remaining snapshot",function()
    local missing=bootLobby("success",true); missing.click()
    check(contains(missing.text,"未提供") and contains(missing.text,"未读取"),"missing sources readable")
    for _,broken in ipairs({"attribute","health","fov","probe","read"}) do
        local s=bootLobby("success",false,broken); s.click()
        check(contains(s.text,"GameId: 123") and contains(s.text,"未读取"),"isolated source failure "..broken)
    end
end)

local function bootStatus(snapshot, isRunning, hasNotify)
    local running=isRunning; local config={PingSamplesRequired=4}; local calls,outputs=0,{}
    local controller={GetStatus=function() calls+=1; return snapshot end}
    local notify=hasNotify and function(text) table.insert(outputs,text) end or nil
    local paragraph={SetDesc=function(_,text) table.insert(outputs,text) end}
    __SERVER_FINITE__
    __SERVER_STATUS__
    return function() showSampleStatus(); return calls,outputs end
end
test("server status button reads one snapshot with no server actions",function()
    local show=bootStatus({Message="idle",PingMs=42.25,HighSamples=2,CooldownRemaining=3,RequestInFlight=false,AutoSwitch=true},true,true)
    local calls,outputs=show(); check(calls==1 and #outputs==1,"one read and notification")
    check(contains(outputs[1],"42.25 ms") and contains(outputs[1],"2/4"),"status fields displayed")
end)
test("server status nonfinite fallback and stopped-state guard",function()
    local show=bootStatus({PingMs=0/0,HighSamples=math.huge,CooldownRemaining=math.huge},true,false)
    local calls,outputs=show(); check(calls==1 and #outputs==1 and contains(outputs[1],"未采样"),"paragraph fallback")
    check(not contains(outputs[1],"nan") and not contains(outputs[1],"inf"),"nonfinite values hidden")
    local stopped=bootStatus({},false,true); local stoppedCalls,stoppedOutput=stopped()
    check(stoppedCalls==0 and #stoppedOutput==1 and contains(stoppedOutput[1],"停止"),"stopped status does not read live state")
end)

local function bootPresets(mode)
    local bridge={Active=true,Options={}}
    local logs,calls,callbacks={},{},{}
    function bridge:Notify(info,content)
        if not self.Active then return end
        table.insert(logs,type(info)=="table" and info or {Title=info,Content=content})
    end
    local native={Debug=false}; local appName="fixture"
    __SAFE_CALLBACK__
    local ids={"wind_acrylic","wind_transparent","wind_perf_tier","wind_notification_lower","wind_readability_guard","wind_safe_area","wind_auto_fit"}
    for _,id in ipairs(ids) do
        local option={Value="before"}
        function option:SetValue(value)
            table.insert(calls,id)
            if id=="wind_perf_tier" then
                if mode=="throw" then error("setter failed",0) end
                if mode=="deferred" then return false end
                if mode=="nil" then return nil end
                if mode=="ignored" then return true end
                if mode=="callback" then safeCallback(function() error("same repeated callback failure",0) end) end
            end
            self.Value=value
            if mode=="destroy" and id=="wind_transparent" then bridge.Active=false end
            return true
        end
        bridge.Options[id]=option
    end
    bridge.Options.wind_min_scale={Value=0.71,SetValue=function() error("must not modify minimum scale",0) end}
    if mode=="missing" then bridge.Options.wind_auto_fit=nil end
    if mode=="capability" then bridge.Options.wind_auto_fit.SetValue=nil end
    if mode=="inactive" then bridge.Active=false end
    local view={AddButton=function(_,info) callbacks[info.Title]=info.Callback end}
    __PRESET_CONTROLS__
    return {bridge=bridge,logs=logs,calls=calls,touch=callbacks["应用触屏推荐设置"],desktop=callbacks["应用桌面推荐设置"]}
end
test("touch and desktop presets preserve unrelated values and ordering",function()
    local s=bootPresets("success"); s.touch()
    check(#s.calls==7 and s.calls[7]=="wind_auto_fit","auto-fit last")
    check(s.bridge.Options.wind_perf_tier.Value=="均衡" and s.bridge.Options.wind_safe_area.Value==true,"touch settings")
    check(s.bridge.Options.wind_acrylic.Value==false and s.bridge.Options.wind_notification_lower.Value==true,"touch presentation")
    check(s.bridge.Options.wind_min_scale.Value==0.71,"manual minimum untouched")
    s.desktop(); check(#s.calls==14 and s.calls[14]=="wind_auto_fit","desktop ordering")
    check(s.bridge.Options.wind_perf_tier.Value=="原速" and s.bridge.Options.wind_acrylic.Value==true,"desktop settings")
    check(s.bridge.Options.wind_safe_area.Value==false and s.bridge.Options.wind_notification_lower.Value==false,"desktop presentation")
    check(#s.logs==2 and contains(s.logs[2].Content,"已应用"),"only confirmed success notified")
end)
for _,mode in ipairs({"missing","capability","inactive"}) do
    test("preset preflight "..mode,function()
        local s=bootPresets(mode); s.touch(); check(#s.calls==0,"preflight makes no partial changes")
        check(#s.logs==(mode=="inactive" and 0 or 1),"preflight notification")
    end)
end
for _,mode in ipairs({"throw","deferred","nil","ignored","callback"}) do
    test("preset stops on "..mode,function()
        local s=bootPresets(mode); s.touch(); check(#s.calls==3,"stops at first unconfirmed setter")
        local last=s.logs[#s.logs]; check(last and not contains(last.Content,"已应用"),"no false success")
        if mode=="callback" then
            s.touch(); check(#s.calls==6,"identical repeated callback error also detected")
            check(not contains(s.logs[#s.logs].Content,"已应用"),"repeat cannot turn error green")
        end
    end)
end
test("preset stops immediately after teardown",function()
    local s=bootPresets("destroy"); s.touch()
    check(#s.calls==2 and #s.logs==0,"no writes or notifications after teardown")
end)
print("R19_RESULT suites="..suites.." checks="..checks.." failures=0")
