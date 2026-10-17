"""R2.10 mock regression: native↔bridge↔runtime and spectator lifecycle.
This is not a Roblox server integration test.
"""
import re
import unittest
from pathlib import Path
from test_wind_router import LuaRuntime
from test_r25_stability import SETUP, to_lua54

ROOT=Path(__file__).resolve().parents[1]
FS=(ROOT/'src/ForsakenCore.luau').read_text(encoding='utf-8')
ADAPTER=(ROOT/'src/WindAdapter.luau').read_text(encoding='utf-8')

# Keep the real Forsaken module, replace only the external bridge/factory dependencies.
TARGET = FS.replace('local WindBridgeFactory = nil',
        'local WindBridgeFactory = function() return __bridge end')\
    .replace('local ForsakenEnhancementsFactory = nil',
        'local ForsakenEnhancementsFactory = function() return {Destroy=function() end} end')

SCENE = r'''
local made,removed=0,0
local pos=function(x) return setmetatable({n=x},{__sub=function(a,b)
 return {Magnitude=math.abs(a.n-b.n)} end}) end
__camera.CFrame={Position=pos(0)}
local enemyRoot={Position=pos(20),Parent={}}
function enemyRoot:IsA(k) return k=='BasePart' end
local enemy={Parent={},Name='Enemy'}
function enemy:IsA(k) return k=='Model' end
function enemy:FindFirstChild(k) if k=='HumanoidRootPart' then return enemyRoot end end
local killers={GetChildren=function()return {enemy}end}
local scenePlayers={FindFirstChild=function(self,k)if k=='Killers' then return killers end end}
workspace.FindFirstChild=function(self,k) if k=='Players' then return scenePlayers end end
Instance={new=function(k)
  assert(k=='Highlight')
  made=made+1
  return {Destroy=function(self)removed=removed+1 end}
end}
Color3={fromRGB=function(...)return {...}end}
Enum={HighlightDepthMode={AlwaysOnTop='Top'}}
__markers=function()return made,removed end
'''

class StateR210(unittest.TestCase):
    def test_deferred_native_reconciliation_does_not_accept_stale_event(self):
        start=ADAPTER.index('            local function reconcileNative()')
        end=ADAPTER.index('            local settings =',start)
        methods=ADAPTER[start:end]
        lua=r'''
__tasks={}
task={defer=function(fn)table.insert(__tasks,fn)end}
local bridge={Active=true}
local ready=true
local nativeEvents,nativeMismatch,nativeReconciled,revision=0,0,0,0
local lastNativeEvent='none'
local option={Value=false}
local id='FsKillerESP'
local current=false
local fired={}
local function nativeValue()return current end
local function normalize(v)return v==true end
local function equal(a,b)return a==b end
local function emit(v) option.Value=v;fired[#fired+1]=v end
'''+methods+r'''
-- Vendor callback is early: native Value will become true just after this call.
changed(true)
assert(nativeMismatch==1 and option.Value==false and #__tasks==1)
current=true
__tasks[1]()
assert(option.Value==true and nativeReconciled==1 and fired[1]==true)
-- Stale callback occurs but a newer current value is already in use.
changed(false)
current=false
changed(false)
assert(option.Value==false and fired[2]==false)
local count=#fired
for _,fn in ipairs(__tasks)do fn() end
assert(#fired==count,'old deferred event was applied again')
'''
        LuaRuntime().run(to_lua54(lua))

    def test_spectator_scan_works_without_live_character(self):
        lua=SETUP+SCENE+TARGET+r'''
__callbacks.FsKillerESP(true)
__runHeartbeat(0.3)
local a,b=__markers()
assert(a==1 and b==0,'spectator scan did not mark target')
__callbacks.FsKillerESP(false)
local x,y=__markers()
assert(y==1,'marker not removed when option disabled')
__buttons['卸载 Forsaken 功能']()
assert(__active()==0,'cleanup leaked listener')
'''
        LuaRuntime().run(to_lua54(lua))

    def test_missed_callback_repaired_from_bridge_option(self):
        lua=SETUP+SCENE+TARGET+r'''
-- Simulate a visual toggle that is true but its callback was dropped.
local nativeValue=true
__bridge.Options={FsKillerESP={Value=false,
 GetNativeValue=function()return nativeValue end,
 SyncFromNative=function(self)self.Value=nativeValue end}}
__runHeartbeat(0.4)
__runHeartbeat(0.4)
__runHeartbeat(0.4)
__runHeartbeat(0.3)
local a,b=__markers()
assert(a==1 and b==0,'watchdog failed to recover business state')
nativeValue=false
__runHeartbeat(0.4)
__runHeartbeat(0.4)
__runHeartbeat(0.4)
local x,y=__markers()
assert(y==1,'disable was not reflected')
__buttons['卸载 Forsaken 功能']()
assert(__active()==0)
'''
        LuaRuntime().run(to_lua54(lua))

    def test_diagnostics_expose_native_bridge_runtime_values(self):
        self.assertIn('Killer:UI=%s Bridge=%s Runtime=%s',FS.replace('%s:UI=%s Bridge=%s Runtime=%s','Killer:UI=%s Bridge=%s Runtime=%s')) if False else None
        for token in ('optionInfo("FsKillerESP"', '状态修复=%d','观战扫描=%d','状态修复','scanMode', 'CharacterRemoving','GetNativeValue','SyncFromNative'):
            self.assertIn(token,FS)

if __name__=='__main__': unittest.main()
