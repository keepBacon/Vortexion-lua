local suites, checks = 0, 0
local function check(value, message) checks += 1; assert(value, message) end
local function test(name, fn)
    local ok, err = pcall(fn)
    if not ok then error("R20 FAIL " .. name .. ": " .. tostring(err), 0) end
    suites += 1; print("R20 PASS " .. name)
end
local now, world = 0, nil
function tick() return now end
local V = {}; V.__index = function(v,k) if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end return V[k] end
V.__sub = function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},V) end
Vector3 = {new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},V) end}
Vector2 = {new=function(x,y) return {X=x,Y=y} end}
Color3 = {new=function(r,g,b) return {R=r,G=g,B=b} end,fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
UDim2 = {new=function(a,b,c,d) return {X={Scale=a,Offset=b},Y={Scale=c,Offset=d}} end,fromOffset=function(x,y) return {X={Offset=x},Y={Offset=y}} end,fromScale=function(x,y) return {X={Scale=x},Y={Scale=y}} end}
Enum = {Font={GothamBold="GothamBold",Gotham="Gotham",SourceSans="SourceSans",Code="Code"},HighlightDepthMode={AlwaysOnTop="AlwaysOnTop"}}
local props = {}
for name in string.gmatch("Parent Name ClassName Adornee Enabled Visible Size Position AlwaysOnTop StudsOffset MaxDistance BackgroundTransparency BackgroundColor3 BorderSizePixel Text TextSize TextColor3 TextStrokeTransparency TextStrokeColor3 Font FillTransparency OutlineTransparency DepthMode FillColor OutlineColor LineThickness SurfaceTransparency Color3 ResetOnSpawn DisplayOrder Center Outline Thickness From To Color Ended", "%S+") do props[name]=true end
local function newWorld()
    local f={all={},meta={},counts={},connections={}}
    function f:create(class)
        self.counts[class]=(self.counts[class] or 0)+1
        if self.failClass==class and (not self.failAt or self.counts[class]==self.failAt) then error("injected allocation failure",0) end
        local object={}
        local d={props={ClassName=class,Name=class,Enabled=true,Visible=true},children={},writes={},dead=false,destroys=0}
        self.meta[object]=d; table.insert(self.all,object)
        local function parent(value)
            local old=d.props.Parent
            if old and self.meta[old] then self.meta[old].children[object]=nil end
            d.props.Parent=value
            if value and self.meta[value] then self.meta[value].children[object]=true end
        end
        local methods={}
        methods.Destroy=function()
            d.destroys+=1
            if d.dead then return end
            if d.destroyFails then error("injected Destroy failure",0) end
            d.dead=true; parent(nil)
            local children={}; for child in pairs(d.children) do table.insert(children,child) end
            for _,child in ipairs(children) do child:Destroy() end
        end
        methods.Remove=methods.Destroy
        methods.IsA=function(_,kind) return class==kind or (class=="Part" and kind=="BasePart") end
        methods.FindFirstChild=function(_,name) for child in pairs(d.children) do if child.Name==name then return child end end end
        methods.Clone=function() return f:create(class) end
        methods.Play=function() if f.playFails then error("injected Play failure",0) end end
        setmetatable(object,{
            __index=function(_,key)
                if d.unreadable==key then error("injected read failure",0) end
                if methods[key] then return methods[key] end
                if not props[key] then error("unknown Instance property "..key,0) end
                return d.props[key]
            end,
            __newindex=function(_,key,value)
                if not props[key] then error("unknown Instance property "..key,0) end
                if d.dead or (f.blockClass==class and f.blockKey==key) then error("injected property failure "..key,0) end
                d.writes[key]=(d.writes[key] or 0)+1
                if key=="Parent" then parent(value) else d.props[key]=value end
            end,
        })
        if class=="Sound" then
            local signal={}
            function signal:Connect(fn)
                if f.signalFails then error("signal unavailable",0) end
                local cn={Connected=true,callback=fn}
                function cn:Disconnect() self.Connected=false end
                table.insert(f.connections,cn)
                if f.syncEnd then fn() end
                return cn
            end
            d.props.Ended=not f.noSignal and signal or nil
        end
        return object
    end
    function f:live(class) local n=0;for _,o in ipairs(self.all) do if not self.meta[o].dead and o.ClassName==class then n+=1 end end;return n end
    function f:last(class) for i=#self.all,1,-1 do local o=self.all[i];if o.ClassName==class and not self.meta[o].dead then return o end end end
    function f:connected() local n=0;for _,cn in ipairs(self.connections) do if cn.Connected then n+=1 end end;return n end
    world=f; now=0; return f
end
Instance = {new=function(class) return world:create(class) end}
Drawing = {new=function(kind) return world:create("Drawing"..kind) end}

local function scpFixture()
    local f=newWorld()
    f.parent=f:create("PlayerGui"); f.character=f:create("Model");f.character.Name="Fixture"
    local head=f:create("Part");head.Name="Head";head.Parent=f.character
    local common={HasDrawing=true,RandomName=function() return "fixture" end,GetGuiParent=function() if f.parentFails then error("parent unavailable",0) end return f.parent end}
    __SCP_CONFIG__
    __SCP_DRAWING__
    __SCP_HELPERS__
    f.config=Config;f.common=common;f.entry=newEntry(f.character,nil)
    f.ensure=ensureNativeLabel; f.draw=drawNativeLabel;f.dispose=destroyEntry;f.chams=ensureChams
    f.line=createLine;f.label=createLabel;f.lines=ensureLines;f.style=labelStyle
    return f
end
test("drawing setup rollback",function()
    for _,case in ipairs({{"DrawingLine","Thickness","line"},{"DrawingText","Outline","label"}}) do
        local f=scpFixture();f.blockClass,f.blockKey=case[1],case[2]
        local ok,value=pcall(f[case[3]])
        check(ok and value==nil,"constructor failure contained")
        check(f:live(case[1])==0,"failed drawing owns no live object")
    end
end)
test("drawing partial pool rollback and guarded methods",function()
    local f=scpFixture();f.failClass="DrawingLine";f.failAt=3;f.lines(f.entry,"health",4)
    check(#f.entry.health==0 and f:live("DrawingLine")==0,"partial line group retired")
    f.failClass=nil;local label=f.label();local raw=f:last("DrawingText");raw:Destroy()
    check(pcall(function() label:set({},"x",{});label:hide();label:remove() end),"destroyed drawing methods isolated")
end)
test("native GUI reuse and missing parent",function()
    local f=scpFixture();local e=f.entry;f.ensure(e,f.character)
    check(e.nativeLabel and e.nativeText and e.nativeLabel.Adornee==f.character:FindFirstChild("Head"),"BasePart adornment")
    local gui=e.nativeLabel;for _=1,100 do f.ensure(e,f.character) end
    check(e.nativeLabel==gui and f:live("BillboardGui")==1,"stable GUI reused")
    f.parent=nil;f.ensure(e,f.character)
    check(not e.nativeLabel and f:live("BillboardGui")==0 and f:live("TextLabel")==0,"missing parent retires tree")
end)
test("native detached GUI is rebuilt",function()
    local f=scpFixture();local e=f.entry;f.ensure(e,f.character);local old=e.nativeLabel
    old.Parent=nil;f.ensure(e,f.character)
    check(e.nativeLabel~=old and f.meta[old].dead,"detached GUI replaced")
    check(f:live("BillboardGui")==1 and f:live("TextLabel")==1,"one live tree")
end)
test("native detached text is rebuilt",function()
    local f=scpFixture();local e=f.entry;f.ensure(e,f.character);local old,text=e.nativeLabel,e.nativeText
    text.Parent=f.parent;f.ensure(e,f.character)
    check(e.nativeLabel~=old and f.meta[text].dead,"detached child retired independently")
    check(f:live("TextLabel")==1,"no orphan text")
end)
test("native root replacement and inaccessible properties",function()
    local f=scpFixture();local e=f.entry;f.ensure(e,f.character);local old=e.nativeLabel
    f.parent=f:create("PlayerGui");f.ensure(e,f.character)
    check(e.nativeLabel~=old and e.nativeLabel.Parent==f.parent,"current parent identity honored")
    f.meta[e.nativeText].unreadable="Parent";check(pcall(f.ensure,e,f.character),"bad reference isolated")
    f.parentFails=true;check(pcall(f.ensure,e,f.character) and not e.nativeLabel,"parent lookup failure retires owned tree")
end)
test("native construction rollback",function()
    for _,case in ipairs({{"BillboardGui","Size"},{"TextLabel","Font"},{"TextLabel","Parent"},{"BillboardGui","Parent"}}) do
        local f=scpFixture();f.blockClass,f.blockKey=case[1],case[2];f.ensure(f.entry,f.character)
        check(not f.entry.nativeLabel and not f.entry.nativeText,"failed tree not published")
        check(f:live("BillboardGui")==0 and f:live("TextLabel")==0,"all partial objects retired")
    end
end)
test("native text commit retries after failed write",function()
    local f=scpFixture();local e=f.entry;f.ensure(e,f.character)
    f.blockClass,f.blockKey="TextLabel","TextColor3";f.draw(e,f.character,12,f.config.ColorEnemy)
    check(e.labelText==nil,"failed text write does not commit cache")
    f.blockClass=nil;f.draw(e,f.character,12,f.config.ColorEnemy)
    check(e.labelText=="Fixture [12]" and e.nativeText.TextColor3==f.config.ColorEnemy,"retry commits complete write")
    local writes=f.meta[e.nativeText].writes.Text;f.draw(e,f.character,12,f.config.ColorEnemy)
    check(f.meta[e.nativeText].writes.Text==writes,"stable text has no extra writes")
end)
test("native style controls and cache",function()
    local f=scpFixture();local e=f.entry;f.ensure(e,f.character);local gui=e.nativeLabel
    check(e.nativeText.TextSize==14 and e.nativeText.BackgroundTransparency==1,"legacy defaults retained")
    f.config.LabelTextSize=28;f.config.LabelFont="Code";f.config.LabelStroke=false;f.config.LabelBackgroundTransparency=0.35
    f.ensure(e,f.character)
    check(e.nativeText.TextSize==28 and e.nativeLabel.Size.Y.Offset==40,"live size and layout applied")
    check(e.nativeText.Font==Enum.Font.Code and e.nativeText.TextStrokeTransparency==1 and e.nativeText.BackgroundTransparency==0.35,"font stroke background applied")
    local writes=f.meta[e.nativeText].writes.TextSize;for _=1,100 do f.ensure(e,f.character) end
    check(e.nativeLabel==gui and f.meta[e.nativeText].writes.TextSize==writes,"stable style no rebuild or rewrites")
    f.config.LabelTextSize=20;f.blockClass,f.blockKey="TextLabel","TextSize";f.ensure(e,f.character)
    check(e.labelSize==28,"failed style not cached")
    f.blockClass=nil;f.ensure(e,f.character);check(e.nativeText.TextSize==20 and e.labelSize==20,"style retried")
end)
test("style sanitization and Drawing live style",function()
    local f=scpFixture();for _,bad in ipairs({0/0,math.huge,-math.huge,"bad"}) do
        f.config.LabelTextSize=bad;f.config.LabelBackgroundTransparency=bad;f.config.LabelFont="MissingFont"
        local size,font,stroke,alpha=f.style();check(size==14 and font==Enum.Font.GothamBold and stroke and alpha==1,"invalid style defaults")
    end
    f.config.LabelTextSize=999;f.config.LabelBackgroundTransparency=-10;local size,_,_,alpha=f.style();check(size==28 and alpha==0,"finite style clamped")
    local label=f.label();f.config.LabelTextSize=18;f.config.LabelStroke=false;label:set({},"name",{})
    local raw=f:last("DrawingText");check(raw.Size==18 and raw.Outline==false,"Drawing consumes size and stroke")
end)
test("chams setup rollback and detached cleanup",function()
    local f=scpFixture();f.config.Chams=true;f.blockClass,f.blockKey="Highlight","FillColor";f.chams(f.entry,f.character)
    check(not f.entry.chams and f:live("Highlight")==0,"failed highlight retired")
    f.blockClass=nil;f.chams(f.entry,f.character);local h=f.entry.chams;h.Parent=nil;f.dispose(f.entry)
    check(f.meta[h].dead and f.entry.chams==nil,"detached highlight retired")
    check(pcall(f.dispose,f.entry),"entry cleanup idempotent")
end)
test("four UI controls reach actual label configuration",function()
    local f=scpFixture();local ESP={Config=f.config};local controls={};local tabs={Visual={}}
    for _,kind in ipairs({"AddSlider","AddDropdown","AddToggle"}) do tabs.Visual[kind]=function(_,id,info) check(not controls[id],"unique control ID");controls[id]=info;return {} end end
    __SCP_CONTROLS__
    controls.SCPESPLabelTextSize.Callback(22);controls.SCPESPLabelFont.Callback("Gotham")
    controls.SCPESPLabelStroke.Callback(false);controls.SCPESPLabelBackground.Callback(25)
    f.ensure(f.entry,f.character)
    check(f.entry.nativeText.TextSize==22 and f.entry.nativeText.Font==Enum.Font.Gotham,"real callbacks consumed")
    check(f.entry.nativeText.BackgroundTransparency==0.25 and f.entry.nativeText.TextStrokeTransparency==1,"percent and toggle consumed")
    check(controls.SCPESPLabelTextSize.Min==10 and controls.SCPESPLabelTextSize.Max==28 and controls.SCPESPLabelFont.Default=="GothamBold","UI ranges match renderer")
end)

local function forsakenFixture()
    local f=newWorld();local objects={};local destroyed=false;local loops=0
    local clock=function() return now end;local ensureLoop=function() loops+=1 end
    __FV_HELPERS__
    __FV_MARKER__
    local function sweep(time) local now=time; __FV_SWEEP__ end
    f.objects=objects;f.helper=findOrCreateByModel;f.mark=highlightTarget;f.clear=clearMarkers;f.sweep=sweep;f.loops=function() return loops end
    f.destroy=function() destroyed=true;clearMarkers() end
    return f
end
test("Forsaken allocation rollback",function()
    local f=forsakenFixture();local model=f:create("Model");f.blockClass,f.blockKey="Highlight","Name"
    check(f.helper(model,model,"Highlight","helper")==nil,"failed helper not returned")
    check(f:live("Highlight")==0 and next(f.objects)==nil,"failed helper owns no live object")
    f.blockClass,f.blockKey="SelectionBox","Color3";check(f.mark(model,2)==nil and f:live("SelectionBox")==0,"failed marker rolled back")
end)
test("Forsaken borrowed helper and owned orphan",function()
    local f=forsakenFixture();local model=f:create("Model");local existing=f:create("Highlight");existing.Name="borrowed";existing.Parent=model
    check(f.helper(model,model,"Highlight","borrowed")==existing and next(f.objects)==nil,"borrowed object not owned")
    local owned=f.helper(model,model,"Highlight","new");check(f.objects[owned] and f.loops()==1,"owned helper starts collector")
    owned.Parent=nil;f.sweep(0);f.clear()
    check(f.meta[owned].dead and not f.meta[existing].dead,"orphan retired without deleting borrowed object")
end)
test("Forsaken invalid duration and isolated cleanup",function()
    local f=forsakenFixture();local model=f:create("Model");local a=f.mark(model,0/0);local b=f.mark(model,math.huge)
    check(f.objects[a]==2 and f.objects[b]==2,"invalid duration bounded")
    f.meta[a].destroyFails=true;f.meta[a].unreadable="Parent";f.sweep(2)
    check(next(f.objects)==nil and f.meta[b].dead,"failed read or Destroy does not block other marker")
    check(pcall(f.clear),"repeat cleanup contained")
end)

local function soundFixture()
    local f=newWorld();local root=f:create("Model");local sounds=f:create("Model");sounds.Name="Sounds";sounds.Parent=root
    local per=f:create("Model");per.Name="Knife";per.Parent=sounds
    local group=f:create("Model");group.Name="Equip";group.Parent=per
    local template=f:create("Sound");template.Name="1";template.Parent=group
    local c={ReplicatedStorage=root,RandomName=function() return "sound" end}
    local state={knifeName="Knife"};local knifeModel=f:create("Model");local activeSounds={};local stopKnifeSounds
    __SOUNDS__
    f.storage=root;f.play=playKnifeSound;f.sweep=reclaimSounds;f.stop=stopKnifeSounds;f.active=activeSounds;f.connectionsOwned=soundConnections
    return f
end
test("sound stop disconnects subscriptions",function()
    local f=soundFixture();local a=f.play("Equip")
    check(a and f:connected()==1,"sound subscribed")
    f.stop();check(f:connected()==0,"owned sound connection disconnected")
    check(next(f.active)==nil and next(f.connectionsOwned)==nil and f.meta[a].dead,"sound records retired")
    local calls=f.meta[a].destroys;for _,cn in ipairs(f.connections) do cn.callback() end;f.stop()
    check(f.meta[a].destroys==calls,"late callback and repeat stop are no-ops")
end)
test("sound timeout and missing signal fallback",function()
    local f=soundFixture();f.noSignal=true;local a=f.play("Equip");now=5;f.sweep()
    check(f.meta[a].dead and next(f.active)==nil,"five second fallback bounds sound")
    f.noSignal=false;f.signalFails=true;local b=f.play("Equip");now=11;f.sweep()
    check(f.meta[b].dead and next(f.active)==nil,"subscription failure still reclaimed")
end)
test("sound synchronous Ended and playback failure",function()
    local f=soundFixture();f.syncEnd=true;local a=f.play("Equip")
    check(f.meta[a].dead and f:connected()==0 and next(f.connectionsOwned)==nil,"synchronous callback cannot strand connection")
    f.syncEnd=false;f.playFails=true;check(f.play("Equip")==nil and f:live("Sound")==1,"failed clone playback rolled back")
end)
test("sound one Destroy failure does not retain other owners",function()
    local f=soundFixture();local a=f.play("Equip");local b=f.play("Equip");f.meta[a].destroyFails=true;f.stop()
    check(next(f.active)==nil and f:connected()==0 and f.meta[b].dead,"all registrations cleared despite one broken destructor")
end)

local aotrFactory=__AOTR_FACTORY__
local function aotrFixture()
    local f=newWorld();local parent=f:create("PlayerGui");local model=f:create("Model");model.Name="Fixture";model.Parent=parent
    local part=f:create("Part");part.Parent=model
    local entry={model=model,nape=part,boss=false};f.pool={entry};f.errors={};f.stops={}
    local app={Services={Players={LocalPlayer={}},Workspace={}},Titans={All=function() return f.pool end}}
    function app.GetGuiParent() return parent end
    function app.RandomName() return "fixture" end
    function app:Character() return nil,nil,nil end
    function app:OnStop(fn) table.insert(f.stops,fn) end
    function app.Guard(_,fn) local ok,err=pcall(fn);if not ok then table.insert(f.errors,err) end end
    f.module=aotrFactory(app);f.module.Config.Enabled=true;f.module.Config.Distance=false;f.module.Config.Health=false
    f.step=function() f.module:Update(0.1) end;return f
end
test("AOTR orphan child rebuilt",function()
    local f=aotrFixture();f.step();check(#f.errors==0,"initial UI setup")
    local old=f:last("BillboardGui");local text=f:last("TextLabel");text.Parent=nil;f.step()
    check(f:last("BillboardGui")~=old and f.meta[text].dead,"orphan child triggers transaction rebuild")
    check(f:live("BillboardGui")==1 and f:live("TextLabel")==2 and #f.errors==0,"only one complete replacement tree")
end)
test("AOTR cleanup independently retires detached children",function()
    local f=aotrFixture();f.step();local text=f:last("TextLabel");local frame=f:last("Frame");text.Parent=nil;frame.Parent=nil
    f.module:Stop()
    check(f.meta[text].dead and f.meta[frame].dead,"detached children independently retired")
    check(f:live("BillboardGui")==0 and f:live("Frame")==0 and f:live("TextLabel")==0,"all owned UI retired")
    check(pcall(f.module.Stop,f.module),"repeat stop idempotent")
end)
test("AOTR parent read failure isolated and unload stays final",function()
    local f=aotrFixture();f.step();local text=f:last("TextLabel");f.meta[text].unreadable="Parent";f.step()
    check(#f.errors==0 and f.meta[text].dead,"read failure rebuilds rather than breaking refresh")
    for _,fn in ipairs(f.stops) do fn() end
    local count=#f.all;f.step();check(#f.all==count and f:live("BillboardGui")==0,"late update cannot revive disposed module")
end)
test("failed existing helper lookup does not allocate",function()
    local f=forsakenFixture();local model=f:create("Model");f.meta[model].unreadable="FindFirstChild"
    check(f.helper(model,model,"Highlight","x")==nil and f:live("Highlight")==0,"lookup errors cause no allocation")
end)
test("failed sound lookup does not allocate",function()
    local f=soundFixture();f.meta[f.storage].unreadable="FindFirstChild"
    check(f.play("Equip")==nil and f:live("Sound")==1,"sound lookup errors cause no clone")
end)
local scpFactory=__SCP_FACTORY__
test("disposed SCP ignores late event and frame delivery",function()
    local f=newWorld();local function event()
        local s={callbacks={}}
        function s:Connect(fn)
            local cn={Connected=true};function cn:Disconnect() self.Connected=false end
            table.insert(f.connections,cn);table.insert(self.callbacks,fn);return cn
        end
        function s:Late(value) for _,fn in ipairs(self.callbacks) do fn(value) end end
        return s
    end
    local added,removing=event(),event();local target={CharacterAdded=event(),CharacterRemoving=event(),Character={}}
    local players={GetPlayers=function() return {target} end,PlayerAdded=added,PlayerRemoving=removing}
    local reads=0;local workspace=setmetatable({},{__index=function(_,key) if key=="CurrentCamera" then reads+=1;return nil end;error("unexpected workspace access") end})
    local cleanup;local module=scpFactory({Services={Players=players,Workspace=workspace},LocalPlayer={},OnCleanup=function(fn) cleanup=fn end})
    check(f:connected()==4,"initial signal ownership registered")
    cleanup();cleanup();check(f:connected()==0,"all initial connections retired")
    local late={CharacterAdded=event(),CharacterRemoving=event(),Character={}}
    added:Late(late);target.CharacterAdded:Late({});target.CharacterRemoving:Late();removing:Late(target);module:Update(1)
    check(f:connected()==0 and #f.connections==4,"late events create no new subscriptions")
    check(reads==0,"disposed update reads no camera")
end)
print("R20_RESULT suites="..suites.." checks="..checks.." failures=0")
