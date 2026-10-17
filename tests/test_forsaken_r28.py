"""R2.8 behavioral mocks + build coverage. Not Roblox/server integration tests."""
from pathlib import Path
import hashlib
import json
import re
import unittest
from test_wind_router import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
ENH = (ROOT / "src/ForsakenEnhancements.luau").read_text(encoding="utf-8")
CORE = (ROOT / "src/ForsakenCore.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")

def lua54(source):
    return re.sub(r'(?m)^(\s*)([\w.]+)\s*([+-])=\s*([^\n]+)$',
                  lambda m: f'{m[1]}{m[2]} = {m[2]} {m[3]} ({m[4]})', source)

STUB = r'''
math.clamp = function(x,a,b) return math.max(a,math.min(x,b)) end
table.clear = function(t) for k in pairs(t) do t[k] = nil end end
warn = function(s) __warnings[#__warnings+1]=s end
__warnings,__callbacks,__buttons,__events={}, {}, {}, {}
__connected,__disconnected=0,0
local function signal()
  local sig={}
  function sig:Connect(fn)
    __connected=__connected+1
    local entry={callback=fn, owner=sig}
    __events[#__events+1]=entry
    return {Disconnect=function()
      if not entry.disconnected then entry.disconnected=true;__disconnected=__disconnected+1 end
    end}
  end
  return sig
end
__beat = signal()
local function node(name, typ)
 local o={Name=name,Parent={}, Children={},kind=typ or 'Folder'}
 function o:IsA(what)
   return self.kind == what or (what=='GuiObject' and self.kind=='Frame')
 end
 function o:FindFirstChild(k) return self.Children[k] end
 function o:FindFirstChildOfClass(k)
   if k=='PlayerGui' then return self.Children.PlayerGui end
   if k=='Humanoid' then return self.Children.Humanoid end
 end
 function o:FindFirstChildWhichIsA(k,recurse)
   if k=='Humanoid' then return self.Children.Humanoid end
   if k=='BasePart' then return self.Children.Main end
   return nil
 end
 function o:GetChildren() local out={} for _,v in pairs(self.Children)do out[#out+1]=v end return out end
 function o:GetDescendants() local out={} for _,v in pairs(self.Children)do out[#out+1]=v end return out end
 function o:Add(v) v.Parent=self; self.Children[v.Name]=v;return v end
 return o
end
local pos=setmetatable({n=0},{__sub=function(a,b)return {Magnitude=math.abs(a.n-b.n)}end})
__char=node('Character','Model')
__hum=__char:Add(node('Humanoid','Humanoid'))
__hum.WalkSpeed=12;__hum.Health=100
__root=__char:Add(node('HumanoidRootPart','BasePart'));__root.Position=pos
__player={Character=__char,CharacterAdded=signal()}
__gui=node('PlayerGui','PlayerGui');__gui.DescendantAdded=signal()
function __player:FindFirstChildOfClass(k) if k=='PlayerGui' then return __gui end end
__stamina={Stamina=55,MaxStamina=100,StaminaLoss=10,StaminaGain=20,StaminaLossDisabled=false}
local mod=node('Sprinting','ModuleScript')
local replicated=node('ReplicatedStorage')
replicated:Add(node('Systems')):Add(node('Character')):Add(node('Game')):Add(mod)
local speed=__char:Add(node('SpeedMultipliers'))
__slow=speed:Add(node('SlowedStatus','NumberValue'));__slow.Value=0.5
local fov=__char:Add(node('FOVMultipliers'))
__fovslow=fov:Add(node('SlowedStatus','NumberValue'));__fovslow.Value=0.4
__lighting=node('Lighting');__lighting.ChildAdded=signal()
__workspace=node('Workspace')
local map=__workspace:Add(node('Map')):Add(node('Ingame')):Add(node('Map'))
__generator=map:Add(node('Generator','Model'))
__progress=__generator:Add(node('Progress','NumberValue'));__progress.Value=10
local base=__generator:Add(node('Main','BasePart'));base.Position=pos
__re=__generator:Add(node('Remotes')):Add(node('RE','RemoteEvent'))
__fires=0
function __re:FireServer() __fires=__fires+1 end
local services={Players={LocalPlayer=__player},ReplicatedStorage=replicated,
    RunService={Heartbeat=__beat},Workspace=__workspace,Lighting=__lighting}
game={GetService=function(_,name) if name=='VirtualInputManager' then error('not available') end return assert(services[name],name) end}
local origRequire=require
require=function(x) if x==mod then return __stamina end return origRequire(x) end
__bridge={Notify=function(self,p)end}
local function tab()
 local t={}
 function t:AddToggle(k,v) __callbacks[k]=v.Callback end
 function t:AddSlider(k,v) __callbacks[k]=v.Callback end
 function t:AddButton(v) __buttons[v.Title]=v.Callback end
 function t:AddParagraph()end
 return t
end
__tabs={player=tab(),defense=tab(),generators=tab()}
local factory = (function()
'''

END = r'''
end)()
__enh=factory({Player=__player,Bridge=__bridge,Tabs=__tabs})
assert(__enh.State.alive)
local n=0 for _ in pairs(__callbacks)do n=n+1 end
assert(n==8,'seven requested plus auto approach = 8, got '..n)
local function beat()
 for _,e in ipairs(__events) do if e.owner==__beat and not e.disconnected then e.callback(.3) end end
end
__beat_tick=beat
'''

class R28Forsaken(unittest.TestCase):
    def test_source_standalone_factory_compiles(self):
        LuaRuntime().run(lua54(STUB + ENH + END))

    def test_stamina_restore_and_slow_restore(self):
        test = r'''
__callbacks.FsInfiniteStaminaR28(true)
__callbacks.FsAntiSlowR28(true)
__beat_tick()
assert(__stamina.StaminaLossDisabled==true,'missing stamina ' .. __enh.State.lastError)
assert(__stamina.StaminaLoss==0 and __stamina.Stamina>=100)
assert(__slow.Value==1 and __fovslow.Value==1)
__callbacks.FsInfiniteStaminaR28(false)
__callbacks.FsAntiSlowR28(false)
assert(__stamina.StaminaLossDisabled==false and __stamina.StaminaLoss==10)
assert(__slow.Value==0.5 and __fovslow.Value==0.4)
__enh:Destroy()
assert(__connected==__disconnected)
'''
        LuaRuntime().run(lua54(STUB + ENH + END + test))

    def test_movement_not_compounded_and_restored(self):
        test = r'''
__callbacks.FsMovementMultiplierR28(1.5)
__beat_tick();assert(__hum.WalkSpeed==18)
__beat_tick();assert(__hum.WalkSpeed==18)
__callbacks.FsMovementMultiplierR28(2)
__beat_tick();assert(__hum.WalkSpeed==24)
__callbacks.FsMovementMultiplierR28(1)
assert(__hum.WalkSpeed==12)
__enh:Destroy()
'''
        LuaRuntime().run(lua54(STUB + ENH + END + test))

    def test_popups_and_taph_are_client_reversible(self):
        test = r'''
local temp=__gui:Add(node('TemporaryUI'))
local popup=temp:Add(node('1x1x1x1Popup','Frame'))
popup.Visible=true
local main=__gui:Add(node('MainUI'))
local fx=main:Add(node('Subspaced','Frame'));fx.Visible=true
__callbacks.FsPopupR28(true)
__callbacks.FsAntiTaphR28(true)
assert(popup.Visible==false and fx.Visible==false)
__callbacks.FsPopupR28(false)
__callbacks.FsAntiTaphR28(false)
assert(popup.Visible==true and fx.Visible==true)
__enh:Destroy()
'''
        # Expose node constructor for deterministic structure additions.
        program=(STUB + ENH + END + test).replace('local function node(name, typ)', 'function node(name, typ)',1)
        LuaRuntime().run(lua54(program))

    def test_generator_interval_and_remote_single_fire(self):
        test = r'''
__callbacks.FsRepairDelayR28(2.5)
assert(__enh.State.repairDelay==2.5)
__callbacks.FsAutoRepairR28(true)
__enh.State.nextRepair=0
__beat_tick()
assert(__fires==1,'no RE call ' .. __enh.State.lastAction .. ' / ' .. __enh.State.lastError)
__beat_tick()
assert(__fires==1,'unexpected extra RE call')
__progress.Value=20
__enh:Destroy()
assert(__connected==__disconnected)
'''
        LuaRuntime().run(lua54(STUB + ENH + END + test))

    def test_integrated_bundles_and_unchanged_other_games(self):
        self.assertIn('ForsakenEnhancementsFactory',CORE)
        self.assertIn('"ForsakenEnhancements.luau"',BUILD)
        r=json.loads((ROOT/'dist/runtime-manifest.json').read_text())
        self.assertIn('r2.8', r['build_tag'])
        for k in ['core',*r['modules'].keys()]:
            d=r[k] if k=='core' else r['modules'][k]
            raw=(ROOT/d['path']).read_bytes()
            self.assertEqual(hashlib.sha256(raw).hexdigest(),d['sha256'])
        for name in ('Forsaken','AOTR_Battle','BloxStrike','SCP'):
            p=(ROOT/'dist'/('Vortexion_Module_'+name+'.lua')).read_text()
            if name=='Forsaken': self.assertIn('FsAutoRepairR28',p)
            else: self.assertNotIn('FsAutoRepairR28',p)

if __name__ == '__main__': unittest.main()
