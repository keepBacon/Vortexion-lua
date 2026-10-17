"""R224 focused offline tests. Lua5.4 host mocks do not establish Android/Roblox runtime success."""
from pathlib import Path
import base64, hashlib, re, unittest, sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from test_wind_router import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

class R224(unittest.TestCase):
    def test_embedded_user_brand_png_is_exact(self):
        original=ROOT/'assets/ui/Vortexion_Original.png'
        packaged=ROOT/'assets/ui/Vortexion_Logo_256.png'
        self.assertTrue(original.exists() and packaged.exists())
        self.assertGreater(original.stat().st_size,50_000)
        data=packaged.read_bytes();self.assertEqual(data[:8],b'\x89PNG\r\n\x1a\n')
        source=(ROOT/'src/VortexionLogoEmbedded.lua').read_text()
        encoded=re.search(r'local encoded = \[\[([A-Za-z0-9+/=]+)\]\]',source).group(1)
        self.assertEqual(base64.b64decode(encoded),data)
        self.assertIn('getcustomasset',source)
        self.assertIn('Vortexion_r224_brand-',source)

    def test_brand_png_lua_decoder_and_capability_fallback(self):
        source=(ROOT/'src/VortexionLogoEmbedded.lua').read_text()
        fixture=r'''
local __env={} getgenv=function()return __env end
local bytes,output
writefile=function(path,data)bytes=data assert(path:find('Vortexion_r224_brand',1,true))end
getcustomasset=function(path)output='rbxasset://tests/brand.png' return output end
'''+source+r'''
local result,mode=VortexionLogoAssetFactory()
assert(result=='rbxasset://tests/brand.png' and mode=='embedded PNG',tostring(mode))
assert(bytes:sub(1,8)==string.char(137,80,78,71,13,10,26,10))
assert(#bytes>30000 and #bytes<100000)
local cached=VortexionLogoAssetFactory() assert(cached==result)
getcustomasset=nil writefile=nil
__env.VortexionR224BrandAsset=nil
local absent,reason=VortexionLogoAssetFactory()
assert(absent==nil and reason:find('PNG',1,true))
'''
        LuaRuntime().run(fixture)

    def test_neverlose_reference_style_and_logo_not_tinted(self):
        vendor=(ROOT/'vendor/Neverlose/Source.lua').read_text()
        bridge=(ROOT/'src/NeverloseAdapter.luau').read_text()
        self.assertIn('FromRGB(66, 173, 190)',vendor)
        self.assertIn('Window.Logo:find("://", 1, true)',vendor)
        self.assertIn('Parent = Items["Logo"].Instance,\n                    Name = "\\0",\n                    Enabled = false',vendor)
        self.assertIn('Parent = Items["FloatingLogo"].Instance,\n                        Name = "\\0",\n                        Enabled = false',vendor)
        self.assertIn('VortexionLogoAssetFactory()',bridge)
        self.assertIn('Columns=mobile and 1 or 2',bridge)
        self.assertIn('FitViewport',bridge)

    def test_scp_safe_bootstrap_mock(self):
        core=(ROOT/'src/SCPCore.luau').read_text()
        self.assertNotIn('common.Guard("Cloak", common.Cloak.Start)',core)
        self.assertIn('task.defer(function()\n    if isCurrent()',core)
        self.assertIn('RunService.RenderStepped:Connect(renderFrame)',core)
        self.assertIn('SCPAdvancedCloak',core)
        self.assertIn('"SCP UI Window: "',core)
        self.assertIn('"SCP UI Pages: "',core)
        self.assertIn('local tabsOK, tabsResult = pcall(function()',core)
        core=core.replace('global.VortexionSCPGeneration += 1','global.VortexionSCPGeneration = global.VortexionSCPGeneration + 1').replace('lowFreqTimer += dt','lowFreqTimer = lowFreqTimer + dt')
        core=re.sub(r'^local SCP(\w+)Factory = nil$',lambda m:'local SCP'+m.group(1)+'Factory = factories.'+m.group(1),core,flags=re.M)
        core=core.replace('local WindBridgeFactory = nil','local WindBridgeFactory = function() return fixtureUI end')
        source=r'''
local env={} function getgenv() return env end
function warn(e) error('WARN:'..tostring(e)) end
function tick()return 100 end
math.clamp=function(v,lo,hi)return math.max(lo,math.min(hi,v))end
function typeof(v)if type(v)=='table' and v.R then return 'Color3' end return type(v) end
local signals = {}
local function signal()return {Connect=function(self,fn)signals[#signals+1]=fn return {Disconnect=function()end} end} end
local tabs={}
local functions={}
local function makeTab()
    local tab={}
    function tab:AddToggle(id,opts)
        functions[id]=opts.Callback
        if opts.Callback then opts.Callback(opts.Default) end
    end
    function tab:AddSlider(id,opts) functions[id]=opts.Callback if opts.Callback then opts.Callback(opts.Default) end end
    function tab:AddDropdown(id,opts) functions[id]=opts.Callback if opts.Callback then opts.Callback(opts.Default) end end
    function tab:AddColorpicker(id,opts) functions[id]=opts.Callback if opts.Callback then opts.Callback(opts.Default) end end
    function tab:AddButton(info)functions[info.Title]=info.Callback end
    function tab:AddParagraph(info)end
    return tab
end
local win={SelectTab=function()end}
function win:AddTab(info) tabs[info.Title]=makeTab() return tabs[info.Title] end
fixtureUI={Options={},OnDestroy=function(self,fn)end,CreateWindow=function(self,data)return win end,RegisterFeatureHealth=function()end}
local universe={}
local player={Character={FindFirstChild=function()end},Idled=signal(),Name='Tester',Team='A',GetMouse=function()return {}end}
local run={Heartbeat=signal(),RenderStepped=signal(),BindToRenderStep=function()end,UnbindFromRenderStep=function()end}
local light={Brightness=1,ClockTime=10,FogEnd=100,Ambient={},OutdoorAmbient={}}
local cam={CFrame={},ViewportSize={X=600,Y=400}}
local workspace={CurrentCamera=cam,DescendantAdded=signal(),DescendantRemoving=signal()}
local uis={TouchEnabled=false}
local services={Players={LocalPlayer=player},RunService=run,Workspace=workspace,Lighting=light,TeleportService={},VirtualUser={},UserInputService=uis,HttpService={}}
game={GameId=1742264997,PlaceId=5041144419,GetService=function(self,name) assert(services[name],name) return services[name] end}
Vector2={new=function()return {}end}
UDim2={fromOffset=function()return {}end}
Color3={fromRGB=function(r,g,b)return {R=r/255,G=g/255,B=b/255}end,new=function()return {}end}
Enum={RenderPriority={Last={Value=2000}}}
task={defer=function(f)f()end,delay=function()end,spawn=function()end}
local counters={cloak=0,scan=0}
local cfg=function()return {Enabled=false,Hitbox='Head',TouchMode='Hold',MaxDistance=300,ColorEnemy=Color3.fromRGB(255,0,0),ColorAlly=Color3.fromRGB(0,255,0),ColorLowHealth=Color3.fromRGB(255,255,0)}end
local function simpleFactory(name)
 return function(common)
    local o={Config=cfg(),Update=function()end,Start=function()end,Get=function() return {} end}
    if name=='Common' then
        common.Caps={};common.Touch={Region='Right'};common.Guard=function(_,fn,...)return pcall(fn,...)end
        common.OnCleanup=function(fn)end
    elseif name=='Cloak' then
        o.Start=function() counters.cloak=counters.cloak+1 end
        o.Stop=function()end
    elseif name=='Candidates' then
        o.StartNPCScan=function() counters.scan=counters.scan+1 end
    end
    return o
 end
end
local factories={}
for _,name in ipairs({'Common','Candidates','Cloak','Camera','SilentAim','Hitbox','Movement','ESP'}) do factories[name]=simpleFactory(name) end
'''+core+r'''
assert(counters.cloak==0,'Cloak installed during bootstrap')
assert(counters.scan==1,'NPC scan not deferred to guarded task')
assert(functions.SCPAdvancedCloak,'safe mode control missing')
functions.SCPAdvancedCloak(true)
assert(counters.cloak==1,'user opt-in did not enable cloak')
assert(env.VortexionSCPGeneration==1)
'''
        LuaRuntime().run(source)
        # A broken UI window or tab constructor must preserve a readable boot
        # reason instead of aborting or installing any optional global hooks.
        baseline = source.split("assert(counters.cloak==0,'Cloak installed during bootstrap')")[0]
        baseline = baseline.replace(
            "function warn(e) error('WARN:'..tostring(e)) end",
            "function warn(e) __lastwarn=tostring(e) end")
        broken_window = baseline.replace(
            "CreateWindow=function(self,data)return win end",
            "CreateWindow=function(self,data) error('unsupported mobile window') end")
        LuaRuntime().run(broken_window + """
assert(type(env.VortexionBootError)=='string')
assert(env.VortexionBootError:find('SCP UI Window:',1,true))
assert(counters.cloak==0 and counters.scan==0)
""")
        broken_page = baseline.replace(
            "function win:AddTab(info) tabs[info.Title]=makeTab() return tabs[info.Title] end",
            "function win:AddTab(info) error('broken mobile page') end")
        LuaRuntime().run(broken_page + """
assert(type(env.VortexionBootError)=='string')
assert(env.VortexionBootError:find('SCP UI Pages:',1,true))
assert(counters.cloak==0 and counters.scan==0)
""")

    def test_npc_scan_runtime_budgeted(self):
        # Execute the real candidate factory in a Lua5.4 mock after translating
        # Luau arithmetic assignments, then verify bounded startup work.
        original=(ROOT/'src/SCPCandidates.luau').read_text()
        original=re.sub(r'(?m)([A-Za-z_][\w.]*)\s*([+%])=\s*([^;\n]+)',
                        lambda m: m.group(1)+' = '+m.group(1)+' '+m.group(2)+' ('+m.group(3)+')',original)
        fixture=r'''
table.clear=function(t)for k in pairs(t)do t[k]=nil end end
table.find=function(t,v)for i,x in ipairs(t)do if x==v then return i end end end
local events={}
local function sig()return {Connect=function(_,fn)return {Disconnect=function()end}end}end
local function inst(kind)
  local v={ClassName=kind,children={}}
  function v:IsA(k)return self.ClassName==k end
  function v:GetChildren()return self.children end
  function v:FindFirstChildWhichIsA(k)for _,c in ipairs(self.children) do if c:IsA(k)then return c end end end
  return v
end
local scene=inst('Workspace')
for i=1,900 do
  local model=inst('Model') local hum=inst('Humanoid') hum.Parent=model
  model.Parent=scene model.children[1]=hum scene.children[i]=model
end
local added=sig();local removed=sig()
scene.DescendantAdded=added scene.DescendantRemoving=removed
local players={PlayerAdded=sig(),PlayerRemoving=sig(),LocalPlayer={}}
function players:GetPlayers()return {} end
function players:GetPlayerFromCharacter() return nil end
scene.CurrentCamera={}
local disposer={}
local common={Services={Players=players,Workspace=scene},OnCleanup=function(f)disposer[#disposer+1]=f end}
local job,visited
local initialVisits=0
local realChildren=scene.GetChildren
function scene:GetChildren()initialVisits=initialVisits+1 return realChildren(self) end
task={}
function task.spawn(fn)
 job=coroutine.create(fn)
 local ok,err=coroutine.resume(job) assert(ok,err)
 return job
end
function task.wait()coroutine.yield()end
local factory=(function()
'''+original+r'''
end)()
local obj=factory(common)
obj:StartNPCScan()
assert(coroutine.status(job)=='suspended','must yield during large scene scan')
local steps=0
while coroutine.status(job)=='suspended' do
 steps=steps+1 assert(steps<50,'scanner did not finish')
 local ok,err=coroutine.resume(job) assert(ok,err)
end
local count=0 for _ in pairs(obj.NPCs) do count=count+1 end
assert(count==900,'scanner lost NPC models: '..count)
assert(initialVisits==1)
for _,f in ipairs(disposer)do f()end
assert(obj.NPCs==nil,'cleanup should drop roster')
'''
        LuaRuntime().run(fixture)

    def test_npc_scan_defers_heavy_map_walk(self):
        s=(ROOT/'src/SCPCandidates.luau').read_text()
        scan=s.split('function Candidates:StartNPCScan()',1)[1].split('return Candidates',1)[0]
        self.assertNotIn('Workspace:GetDescendants()',scan)
        self.assertIn('front%160==0 then task.wait()',scan)
        self.assertIn('stopped=true',scan)
        self.assertIn('Workspace.DescendantAdded:Connect',scan)

if __name__=='__main__':unittest.main()
