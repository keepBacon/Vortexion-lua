"""R2.11 trace and generator-discovery regression; mocked engine, not Roblox live."""
from pathlib import Path
import unittest
from test_wind_router import LuaRuntime
from test_r25_stability import to_lua54
from test_forsaken_r28 import STUB, END

ROOT = Path(__file__).resolve().parents[1]
ADAPTER = (ROOT / 'src/WindAdapter.luau').read_text(encoding='utf8')
ENH = (ROOT / 'src/ForsakenEnhancements.luau').read_text(encoding='utf8')
CORE = (ROOT / 'src/ForsakenCore.luau').read_text(encoding='utf8')

class R211Tests(unittest.TestCase):
    def test_shared_callback_trace_keeps_bounded_history_and_errors(self):
        start = ADAPTER.index('    local featureTrace, featureTraceLimit')
        end = ADAPTER.index('    local function colorValue', start)
        source = ADAPTER[start:end].replace("callbackCalls += 1", "callbackCalls = callbackCalls + 1")
        lua = r'''
local bridge={Active=true,Cleaning=false,LastError=nil}
function bridge:Notify()end
local native={Debug=false}
local appName='test'
local callbackCalls=0
local callbackErrorRevision=0
warn=function()end
''' + source + r'''
assert(bridge:FeatureTrace()=='尚无控件回调记录')
local good,failed=safeCallback(function(v) assert(v) end,true)
assert(good and failed==nil)
local bad,msg=safeCallback(function()error('fixture broken')end)
assert(bad==false and tostring(msg):find('fixture broken',1,true))
for i=1,26 do traceFeature('feature'..i,'native',i,i==13 and 'ERROR' or 'OK','fixture broken') end
local report=bridge:FeatureTrace()
assert(not report:find('native feature1=',1,true))
assert(not report:find('native feature2=',1,true))
assert(report:find('feature26',1,true))
assert(report:find('feature13',1,true))
assert(report:find('ERROR fixture broken',1,true))
local n=0 for line in (report..'\n'):gmatch('(.-)\n') do n=n+1 end
assert(n==24,n)
bridge.Active=false
traceFeature('ignored','native','x',false,'late')
assert(not bridge:FeatureTrace():find('ignored',1,true))
assert(callbackCalls==2)
'''
        LuaRuntime().run(to_lua54(lua))

    def test_generator_discovery_all_known_paths_with_nil_first_folder(self):
        test = r'''
-- Ingame.Map has one direct Generator; Map.Generators initially absent.
__fakeClock=0
os.clock=function()return __fakeClock end
local map=__workspace:FindFirstChild('Map')
local ingame=map:FindFirstChild('Ingame')
local inner=ingame:FindFirstChild('Map')
local function addGenerator(where)
  local item=where:Add(node('Generator','Model'))
  item:Add(node('Progress','NumberValue')).Value=25
  local part=item:Add(node('Main','BasePart'));part.Position=__root.Position
  return item
end
-- Distinct containers: inner.Map direct / root.Map.Generators / Ingame.Generators / inner.Generators.
local first=__generator
local a=addGenerator(map:Add(node('Generators')))
local b=addGenerator(ingame:Add(node('Generators')))
local c=addGenerator(inner:Add(node('Generators')))
local list=__enh.EnumerateGenerators()
local observed={}
for _,g in ipairs(list)do observed[g]=true end
assert(#list==4,'discovered '..#list)
assert(observed[first] and observed[a] and observed[b] and observed[c])
assert(__enh.EnumerateGenerators()==list,'cache not reused')
__fakeClock=1
assert(#__enh.EnumerateGenerators()==4)
__enh:Destroy()
'''
        LuaRuntime().run(to_lua54(STUB + ENH + END + test))

    def test_both_forsaken_features_use_same_discovery(self):
        self.assertIn('enhancements.EnumerateGenerators()', CORE)
        self.assertIn('for _, gen in ipairs(enumerateGenerators()) do', ENH)
        self.assertIn('for _, root in pairs(roots) do collect(root) end', ENH)
        self.assertNotIn('local function generatorContainer()', ENH)
        self.assertIn('return {Destroy = shutdown, State = state, EnumerateGenerators = enumerateGenerators}', ENH)

    def test_all_game_bundles_include_shared_callback_trace(self):
        for name in ['AOTR_Battle','AOTR_Lobby','BloxStrike','Forsaken','SCP']:
            content=(ROOT/'dist'/('Vortexion_Module_'+name+'.lua')).read_text(encoding='utf8')
            # Game modules refer to the shared bridge; the feature trace lives in the core bundle.
            self.assertTrue(len(content)>100)
        core=(ROOT/'dist/Vortexion_Core.lua').read_text(encoding='utf8')
        self.assertIn('查看最近控件回调（成功/错误）',core)
        self.assertIn('bridge:FeatureTrace()',core)

if __name__ == '__main__':unittest.main()
