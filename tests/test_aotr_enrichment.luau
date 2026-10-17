local env={}
getgenv=function() return env end

local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local c={Connected=true}
        function c:Disconnect() self.Connected=false end
        table.insert(self.listeners,{fn=fn,connection=c})
        return c
    end
    function s:Fire(...) for _,h in ipairs(self.listeners) do if h.connection.Connected then h.fn(...) end end end
    return s
end

local Vec={}
Vec.__index=function(v,k)
    if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if k=="Unit" then return v/v.Magnitude end
    return Vec[k]
end
Vec.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},Vec) end
Vec.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},Vec) end
Vec.__mul=function(a,b) if type(a)=="number" then a,b=b,a end return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},Vec) end
Vec.__div=function(a,b) return setmetatable({X=a.X/b,Y=a.Y/b,Z=a.Z/b},Vec) end
function Vec:Lerp(b,t) return self+(b-self)*t end
function Vec:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
Vector2={zero=setmetatable({X=0,Y=0,Z=0},Vec),new=function(x,y) return setmetatable({X=x,Y=y,Z=0},Vec) end}
Vector3={zero=setmetatable({X=0,Y=0,Z=0},Vec),new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},Vec) end}
Color3={fromRGB=function(r,g,b) return Vector3.new(r/255,g/255,b/255) end}
UDim2={new=function(...) return {...} end,fromOffset=function(...) return {...} end,fromScale=function(...) return {...} end}
CFrame={new=function(pos) return {Position=pos or Vector3.zero,LookVector=Vector3.new(0,0,-1),Lerp=function(self,other) return other end} end,lookAt=function(pos) return CFrame.new(pos) end}
Enum={UserInputType={Touch="Touch",MouseButton2="MouseButton2"},RaycastFilterType={Blacklist="Blacklist",Exclude="Exclude"},Font={Gotham="Gotham",GothamBold="GothamBold"},HighlightDepthMode={AlwaysOnTop="AlwaysOnTop"}}
RaycastParams={new=function() return {} end}

local function node(class,name)
    local o={ClassName=class,Name=name or class,Parent=true,children={}}
    function o:IsA(k) return self.ClassName==k or (k=="BasePart" and self.ClassName=="Part") end
    function o:FindFirstChild() return nil end
    function o:FindFirstChildOfClass() return nil end
    function o:FindFirstChildWhichIsA() return nil end
    function o:GetChildren() return self.children end
    function o:GetDescendants() return {} end
    function o:GetAttribute() return nil end
    function o:WaitForChild() return nil end
    function o:Destroy() self.Destroyed=true self.Parent=nil end
    return o
end
Instance={new=node}
task={wait=function() end,spawn=function(fn) return fn() end,delay=function(_,fn) return fn() end}

local function fixture()
    local input={TouchEnabled=true,InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),TouchStarted=signal(),TouchMoved=signal(),TouchEnded=signal(),WindowFocused=signal(),WindowFocusReleased=signal()}
    function input:IsMouseButtonPressed() return false end
    local player=node("Player","LocalPlayer")
    player.Idled=signal(); player.CharacterAdded=signal(); player.CharacterRemoving=signal(); player.Character=nil
    local workspaceFixture=node("Workspace","Workspace")
    workspaceFixture.CurrentCamera=nil
    workspaceFixture.ChildAdded=signal(); workspaceFixture.ChildRemoving=signal()
    function workspaceFixture:FindFirstChild() return nil end
    function workspaceFixture:GetPropertyChangedSignal() return signal() end
    function workspaceFixture:Raycast() return nil end
    local services={
        Players={LocalPlayer=player},RunService={Heartbeat=signal()},Workspace=workspaceFixture,
        ReplicatedStorage={FindFirstChild=function() return nil end},Lighting={},UserInputService=input,Input=input,Stats={Network={ServerStatsItem={}}},
        VirtualUser={Button2Down=function() end,Button2Up=function() end},TeleportService={Teleport=function() end},
    }
    game={PlaceId=123,GetService=function(_,name) return services[name] end}
    workspace=workspaceFixture
    local app={Services=services,player=player,connections={},disposers={},active=true,flags={},Caps={},Remotes={GET=nil,POST=nil},HUD={blades=nil,spears=nil},Touch={Enabled=false,Held=false},Cloak=nil}
    function app:Track(c) table.insert(self.connections,c); return c end
    function app:OnStop(fn) table.insert(self.disposers,fn); return fn end
    function app:Alive() return self.active end
    function app:Character() return nil end
    function app:Loop(id) self.flags[id]=true end
    function app:StopLoop(id) self.flags[id]=false end
    function app.Guard(_,fn,...) return pcall(fn,...) end
    function app.GetGuiParent() return node("PlayerGui","PlayerGui") end
    function app.RandomName() return "fixture" end
    function app.ReadCount() return nil end
    function app.Ping() return 0.08 end
    function app.Log() end
    return app,input
end

local function assertEqual(actual,expected,message)
    assert(actual==expected,message.." (got "..tostring(actual)..", expected "..tostring(expected)..")")
end

local factory=__FACTORY__
local bootstrap=fixture()
local directOk,directValue=pcall(factory,"battle",{},function() return nil end)
if directOk and type(directValue)=="table" and directValue.Services then
    local app=directValue
    local input=app.Services.UserInputService
    local cleanupCalls=0
    app.OnCleanup(function() cleanupCalls+=1 end)
    local filtered={UserInputType="Touch",Position=Vector2.new(1,2)}
    input.InputBegan:Fire(filtered,true)
    assertEqual(app.Touch.Held,false,"processed touch must be ignored")
    local first={UserInputType="Touch",Position=Vector2.new(10,20)}
    local second={UserInputType="Touch",Position=Vector2.new(5,5)}
    input.InputBegan:Fire(first,false); input.InputBegan:Fire(second,false)
    first.Position=Vector2.new(18,30); second.Position=Vector2.new(5,10)
    input.InputChanged:Fire(first); input.InputChanged:Fire(second)
    local drag,vertical=app.Touch:Drag()
    assertEqual(drag.X,8,"drag keeps the first touch origin")
    assertEqual(drag.Y,10,"drag returns horizontal touch delta")
    assertEqual(vertical,5,"two-finger drag returns vertical delta")
    input.InputEnded:Fire(first); input.InputEnded:Fire(second)
    assertEqual(app.Touch.Held,false,"touch release clears held state")
    app.Services.Workspace.CurrentCamera={ViewportSize=Vector2.new(1000,600)}
    local left={UserInputType="Touch",Position=Vector2.new(100,200)}
    input.InputBegan:Fire(left,false)
    assertEqual(app.Touch.Held,false,"left-side movement touch must be ignored")
    input.InputBegan:Fire({UserInputType="MouseButton2",Position=Vector2.new(800,200)},false)
    assertEqual(app.Touch.Held,false,"mobile tracking accepts touch input only")
    local rightOne={UserInputType="Touch",Position=Vector2.new(600,200)}
    local rightTwo={UserInputType="Touch",Position=Vector2.new(650,250)}
    local rightThree={UserInputType="Touch",Position=Vector2.new(700,300)}
    input.InputBegan:Fire(rightOne,false);input.InputBegan:Fire(rightTwo,false);input.InputBegan:Fire(rightThree,false)
    rightOne.Position=Vector2.new(620,230);rightTwo.Position=Vector2.new(670,290)
    input.InputChanged:Fire(rightOne);input.InputChanged:Fire(rightTwo)
    input.InputBegan:Fire(rightOne,false)
    local ordered,orderedVertical=app.Touch:Drag()
    assertEqual(ordered.X,20,"duplicate begin preserves oldest touch origin")
    assertEqual(ordered.Y,30,"first touch order stays stable")
    assertEqual(orderedVertical,40,"second touch vertical keeps stable ownership")
    input.InputEnded:Fire(left)
    assertEqual(app.Touch.Held,true,"foreign release leaves held touches intact")
    input.InputEnded:Fire(rightOne)
    local promoted=app.Touch:Drag()
    assertEqual(promoted.X,20,"next oldest touch is promoted without losing its origin")
    input.WindowFocusReleased:Fire()
    assertEqual(app.Touch.Held,false,"focus loss cancels held touches")
    assertEqual(app.Touch:Drag().Magnitude,0,"focus loss clears displacement")
    env.VortexionAOTRCleanup();env.VortexionAOTRCleanup()
    assertEqual(cleanupCalls,1,"OnCleanup callback runs once during cleanup")
    assertEqual(app:Alive(),false,"cleanup marks app inactive")
    input.InputBegan:Fire(rightOne,false)
    assertEqual(app.Touch.Held,false,"cleanup disconnects touch handlers")
    local _,fallbackInput=fixture()
    fallbackInput.InputBegan=nil
    local fallbackApp=factory("battle",{},function() return nil end)
    fallbackInput.TouchStarted:Fire(rightOne,true)
    assertEqual(fallbackApp.Touch.Held,false,"fallback preserves processed touch flag")
    fallbackInput.TouchStarted:Fire(rightOne,false)
    assertEqual(fallbackApp.Touch.Held,true,"fallback accepts unprocessed touch")
    fallbackInput.WindowFocusReleased:Fire()
    assertEqual(fallbackApp.Touch.Held,false,"fallback focus release clears held touch")
    env.VortexionAOTRCleanup()
    print("PASS AOTR Common lifecycle/touch region/order/focus/fallback")
else
    local app=fixture()
    local ok,module=pcall(factory,app)
    assert(ok,"AOTR factory must initialize with the shared app fixture: "..tostring(module))
    assert(type(module)=="table","AOTR factory must return a module table")
    if module.Config~=nil then
        assert(type(module.Config)=="table","AOTR module exposes its legacy configuration")
    end
    assert(#app.disposers>0,"AOTR factory registers a stop disposer")
    print("PASS AOTR factory contract")
end
