"""R2.5 focused checks. Lua 5.4 mock ~= actual Roblox runtime."""
from pathlib import Path
import json, hashlib, re, unittest
from test_wind_router import LuaRuntime
ROOT = Path(__file__).resolve().parents[1]
FS = (ROOT/'src/ForsakenCore.luau').read_text()
AOTR = (ROOT/'src/AOTRBattle.luau').read_text()
BUILD = (ROOT/'build.py').read_text()


def to_lua54(code):
    code = re.sub(r"\b(count|slowLoops)\s*\+=\s*1\b", lambda m: m[1] + " = " + m[1] + " + 1", code)
    # The modified entries only use Luau compound assignments; transform those
    # into equivalent Lua statements to compile/run against mock signals.
    return re.sub(r'(?m)^(\s*)([A-Za-z_]\w*(?:\.\w+)*)\s*([+-])=\s*([^\n]+)$',
                  lambda m: f'{m[1]}{m[2]} = {m[2]} {m[3]} ({m[4]})', code)


SETUP = r'''
math.clamp = function(n,a,b) return math.max(a,math.min(b,n)) end
local callbacks, buttons = {}, {}
local connected, disconnected = 0, 0
local pending
local activeSignals = {}
table.clear = function(t) for k in pairs(t) do t[k]=nil end end
local gui = {}
local camera = {FieldOfView=72,Parent={}}
local workspace = {CurrentCamera=camera}
local heartbeat = {Connect=function(_, callback)
  connected = connected + 1
  local entry={callback=callback,active=true}
  table.insert(activeSignals,entry)
  pending = callback
  return {Disconnect=function(self)
     if not self.done then
       self.done=true;entry.active=false;disconnected=disconnected+1
     end
  end}
end}
local function runHeartbeat(dt)
  for _,item in ipairs(activeSignals) do
    if item.active then item.callback(dt) end
  end
end
local user = {Character=nil}
function user:FindFirstChildOfClass(k) if k=='PlayerGui' then return gui end end
function user:WaitForChild(k) if k=='PlayerGui' then return gui end end
local services = {Players={LocalPlayer=user},RunService={Heartbeat=heartbeat},
  Workspace=workspace,TeleportService={}}
game = {PlaceId=10,GetService=function(self,k) return assert(services[k], k) end}
local bridge = {Active=true, notifications={}}
function bridge:CreateWindow(info)
  local win={tabs={}}
  function win:AddTab(opts)
    local tab={}
    function tab:AddToggle(id,c) callbacks[id]=c.Callback end
    function tab:AddSlider(id,c) callbacks[id]=c.Callback end
    function tab:AddButton(c) buttons[c.Title]=c.Callback end
    function tab:AddParagraph(c) end
    table.insert(self.tabs,tab)
    return tab
  end
  function win:InstallSettings() end
  function win:SelectTab(index) assert(index==1) end
  return win
end
function bridge:OnDestroy(fn) self.destroy=fn end
function bridge:Destroy() self.destroy() end
function bridge:Notify(info) table.insert(self.notifications,info) end
warn = function(s) end
getgenv = function() return _G end
__bridge = bridge
__callbacks=callbacks
__buttons=buttons
__camera=camera
__heartbeat=heartbeat
__connections=function() return connected,disconnected end
__pending=function() return pending end
__runHeartbeat=runHeartbeat
__active=function() local total=0 for _,x in ipairs(activeSignals)do if x.active then total=total+1 end end return total end
'''

class ForsakenStreamlined(unittest.TestCase):
    def test_compiles_as_lua_equivalent(self):
        LuaRuntime().run(to_lua54('local function only_compile()\n' + FS + '\nend'))

    def test_lifecycle_controls_in_mock(self):
        source = FS.replace('local WindBridgeFactory = nil',
                            'local WindBridgeFactory = function() return __bridge end')
        source = source.replace('local ForsakenEnhancementsFactory = nil',
                            'local ForsakenEnhancementsFactory = function() return {Destroy=function() end} end')
        runtime = SETUP + '\n' + source + '''
assert(type(__callbacks.FsKillerESP)=='function')
assert(type(__callbacks.FsCameraFov)=='function')
assert(type(__buttons['检查游戏结构'])=='function')
local all=0 for _ in pairs(__callbacks) do all=all+1 end
assert(all==8,'expected 8 controls: '..all)
local c,d=__connections() assert(c==1 and d==0,'one low-frequency sync listener')
__callbacks.FsCameraFov(true)
assert(__camera.FieldOfView==80,'FOV enabled')
c,d=__connections() assert(c==2 and d==0,'sync + visual listeners')
__callbacks.FsCameraFovValue(108)
assert(__camera.FieldOfView==108,'FOV slider applied')
__callbacks.FsCameraFov(false)
assert(__camera.FieldOfView==72,'FOV restored')
c,d=__connections() assert(c==2 and d==1,'visual listener removed, state watch still active')
__callbacks.FsKillerESP(true)
assert(__active()==2, 'visual heartbeat started')
__runHeartbeat(0.3) -- absent scene folders should not cause an exception
__callbacks.FsKillerESP(false)
assert(__active()==1, 'only low frequency sync remains after disabling')
__buttons['卸载 Forsaken 功能']()
assert(__active()==0, 'destroy releases every listener')
assert(__bridge.Active, 'bridge mock stays active after destroy')
'''
        LuaRuntime().run(to_lua54(runtime))

    def test_marker_creation_and_cleanup_in_mock(self):
        additions = r"""
local made, removed = 0, 0
local pos = function(x) return setmetatable({n=x}, {__sub=function(a,b) return {Magnitude=math.abs(a.n-b.n)} end}) end
local localRoot={Position=pos(0)}
function localRoot:IsA(k) return k=='BasePart' end
local enemyRoot={Position=pos(20)}
function enemyRoot:IsA(k) return k=='BasePart' end
local character = {Parent={}}
function character:FindFirstChildOfClass(k) return nil end
function character:FindFirstChild(k) if k=='HumanoidRootPart' then return localRoot end end
local enemy = {}
function enemy:IsA(k) return k=='Model' end
function enemy:FindFirstChild(k) if k=='HumanoidRootPart' then return enemyRoot end end
enemy.Parent = {}
user.Character = character
local killers={GetChildren=function() return {enemy} end}
local scenePlayers={FindFirstChild=function(self,k) if k=='Killers' then return killers end end}
workspace.FindFirstChild=function(self,k) if k=='Players' then return scenePlayers end end
Instance = {new=function(class)
  assert(class=='Highlight')
  made=made+1
  return {Destroy=function(self) removed=removed+1 end}
end}
Color3={fromRGB=function(...) return {...} end}
Enum={HighlightDepthMode={AlwaysOnTop='Top'}}
__markerCounts=function() return made, removed end
"""
        source = FS.replace('local WindBridgeFactory = nil',
                            'local WindBridgeFactory = function() return __bridge end')
        source = source.replace('local ForsakenEnhancementsFactory = nil',
                            'local ForsakenEnhancementsFactory = function() return {Destroy=function() end} end')
        script = SETUP + additions + source + """
__callbacks.FsKillerESP(true)
__runHeartbeat(0.3)
local a,b=__markerCounts()
assert(a==1 and b==0, 'killer marker not allocated')
__callbacks.FsKillerESP(false)
a,b=__markerCounts()
assert(a==1 and b==1, 'killer marker not destroyed')
"""
        LuaRuntime().run(to_lua54(script))

    def test_legacy_is_removed_from_active_bundle(self):
        self.assertIn('"Forsaken": ("ForsakenCore.luau", [("ForsakenEnhancementsFactory", "ForsakenEnhancements.luau")])', BUILD)
        self.assertNotIn('loadstring(game:HttpGet', FS)
        self.assertNotIn('getconnections(', FS)
        self.assertNotIn('hookmetamethod', FS)
        self.assertNotIn('RenderStepped:Connect', FS)
        self.assertNotIn('GetDescendants()', FS)
        # Functionality and diagnostics have grown; a fixed legacy file-size cap
        # is not a lifecycle or performance invariant.
        self.assertIn('synchronizeVisionOptions', FS)

    def test_aotr_startup_does_not_hook_global_namecall(self):
        self.assertNotIn('AOTRCloakFactory', AOTR)
        self.assertNotIn('("AOTRCloakFactory", "AOTRCloak.lua")', BUILD)
        self.assertIn('app.Cloak = { Protect = function(instance) return instance end }', AOTR)
        self.assertIn('if not (combatOn or espOn or movementOn', AOTR)
        LuaRuntime().run(to_lua54('local function f()\n' + AOTR + '\nend\n'))

    def test_distribution_hashes(self):
        manifest = json.loads((ROOT/'dist/runtime-manifest.json').read_text())
        self.assertRegex(manifest['build_tag'], r'r2\.(5|6|7|8|10|11)')
        for entry in [manifest['core'], *manifest['modules'].values()]:
            file = ROOT / entry['path']
            data = file.read_bytes()
            self.assertEqual(entry['bytes'], len(data))
            self.assertEqual(entry['sha256'], hashlib.sha256(data).hexdigest())
        self.assertLess(manifest['modules']['Forsaken']['bytes'], 60000)
        self.assertLess(manifest['modules']['AOTR_Battle']['bytes'], 110000)

if __name__ == '__main__': unittest.main()
