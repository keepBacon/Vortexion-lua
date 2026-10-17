"""R223 targeted source contracts + Lua 5.4 simulated farm execution. NOT a live Roblox server test."""
from pathlib import Path
import re
import unittest
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_wind_router import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
FARM=(ROOT/'src/AOTRFarm.luau').read_text(encoding='utf-8')
BATTLE=(ROOT/'src/AOTRBattle.luau').read_text(encoding='utf-8')
COMMON=(ROOT/'src/AOTRCommon.luau').read_text(encoding='utf-8')

def compat_lua(src):
    def convert(m):
        body,sep,comment=m[3].partition(' --')
        return f'{m[1]}{m[2]}={m[2]}+({body.rstrip()})' + (sep + comment if sep else '')
    return re.sub(r'(?m)^(\s*)([\w.]+)\s*\+=\s*(.+)$',convert,src)

SETUP=r'''
local CLOCK=100
os.clock=function() return CLOCK end
local function vector(x)
    return setmetatable({x=x}, {__sub=function(a,b) return vector(a.x-b.x) end,
        __index=function(self,key) if key=='Magnitude' then return math.abs(self.x) end end})
end
local function child(name,class)
    local obj={Name=name,ClassName=class or 'Folder',Parent=true,children={}}
    function obj:IsA(klass) return self.ClassName==klass end
    function obj:FindFirstChild(k)
        return self.children[k]
    end
    function obj:GetChildren()
        local list={} for _,v in pairs(self.children) do list[#list+1]=v end return list
    end
    function obj:GetDescendants()
        local res={}
        local function visit(node)
            for _,v in pairs(node.children) do res[#res+1]=v;visit(v) end
        end
        visit(self)
        return res
    end
    function obj:GetFullName() return 'Workspace/'..self.Name end
    function obj:GetAttribute(key) return self.attrs and self.attrs[key] end
    return obj
end
local workspace=child('Workspace')
local unclimbable=child('Unclimbable')
local reloads=child('Reloads')
local gastanks=child('GasTanks')
local refill=child('Refill','BasePart'); refill.Position=vector(700)
gastanks.children.Refill=refill
reloads.children.GasTanks=gastanks
unclimbable.children.Reloads=reloads
workspace.children.Unclimbable=unclimbable
local char=child('Character');char.HumanoidRootPart=child('HumanoidRootPart')
char.HumanoidRootPart.Position=vector(0)
char.children.HumanoidRootPart=char.HumanoidRootPart
local rig=child('Rig_Tester');local hand=child('LeftHand')
local blade=child('Blade_1','BasePart');blade.Transparency=1
hand.children.Blade_1=blade;rig.children.LeftHand=hand;char.children.Rig_Tester=rig
function char:FindFirstChildOfClass(klass) if klass=='Humanoid' then return {Health=100} end end
local player=child('Tester');player.Character=char;player.Name='Tester';player.weapon='Blades'
function player:GetAttribute(key) if key=='Weapon' then return self.weapon end end
local bladeHud={Text='2/4',Parent=true};local spearHud={Text='3/5',Parent=true};local gasHud={Text='85%',Parent=true}
local app={Services={Players={LocalPlayer=player},Workspace=workspace},
 Remotes={GET=nil,POST=nil},HUD={blades=bladeHud,spears=spearHud,gas=gasHud}}
local GET,POST={callCount=0},{callCount=0}
function GET:IsA(k) return k=='RemoteFunction' end
function POST:IsA(k) return k=='RemoteEvent' end
function GET:InvokeServer(a,b,part)
    self.callCount=self.callCount+1
    if a=='Blades' and b=='Reload' then blade.Transparency=0
    elseif a=='Attacks' and b=='Reload' then bladeHud.Text='4/4';gasHud.Text='100%' end
    return true
end
function POST:FireServer(a,b,part)
    self.callCount=self.callCount+1
    if a=='Attacks' and b=='Reload' then spearHud.Text='5/5';gasHud.Text='100%' end
end
local probes=0
function app.ProbeRemotes()
    probes=probes+1
    app.Remotes.GET=GET
    app.Remotes.POST=POST
end
function app.ProbeHUD() end
function app.ReadCount(obj)
    if not obj then return nil end
    local a,b=obj.Text:match('(%d+)%s*/%s*(%d+)')
    return tonumber(a),tonumber(b)
end
function app.ReadPercent(obj)
    if not obj then return nil end
    return tonumber(obj.Text:match('(%d+)'))
end
function app.Guard(name,fn,...) local ok,e=pcall(fn,...);assert(ok, name..': '..tostring(e));return ok end
function app:OnStop(fn) self.stopFn=fn end
local factory=__FACTORY__
local farm=factory(app)
local conf=farm.Config
local function update(t)
    CLOCK=t
    farm:Update(0.5)
end
'''
TESTS=r'''
-- 1. Weapon equipped detection, reload reserve behavior and remote rediscovery.
conf.AutoReload=true
update(100)
assert(probes>0,'remote rediscovery skipped')
assert(GET.callCount==1,'broken blade should reload when reserve nonzero')
assert(farm:DebugSnapshot().reloadStatus=='equip requested; awaiting blade model')
update(100.5)
assert(farm:DebugSnapshot().reloadVerified==1,'equip confirmation missing')
assert(GET.callCount==1,'no repeated reload when blade is equipped')

-- 2. Empty reserves from a remote station should submit one request;
-- successful HUD change is distinct from FireServer return.
conf.AutoRefill=true
bladeHud.Text='0/4';blade.Transparency=1
update(104)
local r=farm:DebugSnapshot()
assert(r.attempts==1 and r.refills==1 and r.refillVerified==0)
assert(GET.callCount==2,'blade resupply uses GET first')
assert(r.distance>18,'far-away station should not block request')
update(104.5)
r=farm:DebugSnapshot()
assert(r.refillVerified==1,'HUD confirmation missing')
assert(r.status:find('confirmed by HUD',1,true),'incorrect status')
assert(r.attempts==1,'duplicate request while full')

-- 3. Spear full refill should prefer POST and confirm actual increase.
player.weapon='Spears';spearHud.Text='0/5'
update(109)
r=farm:DebugSnapshot()
assert(r.attempts==2 and POST.callCount==1,'spear must use POST')
update(109.5)
assert(farm:DebugSnapshot().refillVerified==2,'spear confirmation missing')

-- 4. AutoRefill off must stop attempting, manual diagnosis still works.
conf.AutoRefill=false
spearHud.Text='0/5'
update(113)
assert(farm:DebugSnapshot().attempts==2,'automatic refill ignored toggle off')
assert(farm:ManualRefill()==true,'manual resupply control should operate')
assert(farm:DebugSnapshot().attempts==3,'manual request not recorded')

-- 5. Clean up keeps toggles off.
app.stopFn()
assert(not conf.AutoRefill and not conf.AutoReload)
'''

TEST_FALLBACK=r'''
-- GET is accepted by client but does not replenish blades: alternate safely.
conf.AutoRefill=true
bladeHud.Text='0/4'
GET.InvokeServer=function(self,a,b,part) self.callCount=self.callCount+1;return true end
update(100)
assert(farm:DebugSnapshot().attempts==1 and farm:DebugSnapshot().refillVerified==0)
update(101)
assert(farm:DebugSnapshot().attempts==1,'pending should block repeated remote calls')
update(103.3)
assert(farm:DebugSnapshot().attempts==2, 'unconfirmed attempt should try alternate remote once')
assert(POST.callCount==1, 'fallback POST not invoked')
update(104)
assert(farm:DebugSnapshot().refillVerified==0,'unrelated gas/spear should not confirm blade replenishment')
assert(farm:DebugSnapshot().unconfirmed>=1,'server rejection not surfaced')
'''

class AOTRFarmR223(unittest.TestCase):
    def test_dynamic_lua_5_4(self):
        body=compat_lua(FARM)
        source=SETUP.replace('__FACTORY__', '(function()\n'+body+'\nend)()') + TESTS
        LuaRuntime().run(source)
    def test_server_unconfirmed_switches_channel_without_spam(self):
        body=compat_lua(FARM)
        LuaRuntime().run(SETUP.replace('__FACTORY__', '(function()\n'+body+'\nend)()')+TEST_FALLBACK)
    def test_lifecycle_and_debug_wiring(self):
        self.assertIn('RunService.Heartbeat:Connect(function(dt)',BATTLE)
        self.assertNotIn('if Farm and throttled.Farm',BATTLE)
        self.assertIn('AOTRGasRefillThreshold',BATTLE)
        self.assertIn('Farm:ManualRefill()',BATTLE)
        self.assertIn('Farm:RefreshStation()',BATTLE)
        self.assertIn('"7","Blades","Sets"',COMMON)
        self.assertIn('"7","Spears","Spears"',COMMON)
    def test_no_unbounded_resupply_calls(self):
        self.assertIn('if state.pending or now()-state.lastRefillAt<Config.RefillCooldown',FARM)
        self.assertIn('state.refillVerified+=1',FARM)
        self.assertIn('state.reloadVerified+=1',FARM)

if __name__=='__main__': unittest.main()
