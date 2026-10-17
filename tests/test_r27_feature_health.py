"""R2.7 deterministic regression. Lua54 mocks do not validate Roblox Android gameplay."""
from pathlib import Path
import json, re, unittest
from test_wind_router import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
READ = lambda x: (ROOT / x).read_text(encoding='utf-8')

class FeatureHealthR27(unittest.TestCase):
    def test_old_executor_name_guard_was_real_and_removed(self):
        for filename in ('src/AOTRCommon.luau','src/BloxStrikeCore.luau','src/SCPCore.luau'):
            src=READ(filename)
            self.assertNotIn('executor unsupported:',src,filename)
            self.assertNotIn('for _, bad in ipairs({ "Xeno", "Velocity", "LX63" })',src,filename)
            self.assertNotIn('for _,bad in ipairs({"Xeno","Velocity","LX63"})',src,filename)
            self.assertIn('identifyexecutor',src)
            self.assertIn('ExecutorName',src)

    def test_executor_does_not_block_aotr_initialization(self):
        source=READ('src/AOTRCommon.luau')
        # Exercise the real AOTR prefix through the capabilities table with a blacklist-matching name.
        end=source.index('    app.CanCloak=')
        start=source.index('return function(scene, WindUI, Bridge)')
        cut=source[start:end].replace('return function(scene, WindUI, Bridge)', 'function(scene, WindUI, Bridge)', 1)
        # No executable Roblox calls beyond GetService and earlier local state setup.
        stub='''
getgenv=function()return _G end
identifyexecutor=function()return "Velocity Android" end
warn=function() error('unexpected warning') end
local players={LocalPlayer={}}
local services={Players=players,RunService={},Workspace={},ReplicatedStorage={},Lighting={},UserInputService={},Stats={}}
game={GetService=function(self,s) return assert(services[s],s) end}
local factory = '''+cut+'''\nreturn app.ExecutorName\nend
assert(factory('battle', {}, {})=='Velocity Android','AOTR hard blocked by executor brand')
'''
        LuaRuntime().run(stub)

    def test_scp_blox_executor_gate_continues(self):
        for path,prefix in (('src/BloxStrikeCore.luau','global.VortexionExecutorName = executorName'),('src/SCPCore.luau','global.VortexionExecutorName = executorName')):
            src=READ(path)
            start=src.index('local Players =')
            end=src.index('--=========================================================================\n-- UI:',src.index(prefix))
            cut=src[start:end].replace('global.VortexionBloxGeneration += 1','global.VortexionBloxGeneration = global.VortexionBloxGeneration + 1').replace('global.VortexionSCPGeneration += 1','global.VortexionSCPGeneration = global.VortexionSCPGeneration + 1')
            stub='''
getgenv=function() return _G end
identifyexecutor=function()return "LX63" end
warn=function()error('unexpected executor block')end
local services={Players={LocalPlayer={}},RunService={},Workspace={},ReplicatedStorage={},Lighting={},UserInputService={},VirtualUser={},HttpService={},TeleportService={}}
game={GetService=function(_,name)return assert(services[name],name)end}
local function try()\n'''+cut+'''\nreturn global.VortexionExecutorName\nend
assert(try()=='LX63','module stopped before window')
'''
            LuaRuntime().run(stub)

    def test_callback_probe_and_partial_status_integrated(self):
        adapter=READ('src/WindAdapter.luau')
        loader=READ('loader.lua')
        self.assertIn('wind_input_probe',adapter)
        self.assertIn('原生控件事件:',adapter)
        self.assertIn('nativeMismatch += 1',adapter)
        self.assertIn('lastNativeEvent = tostring(id)',adapter)
        self.assertIn('partial and "partial" or "success"',loader)
        self.assertIn('bridge.BootStatus == "partial"',loader)
        self.assertNotIn('error("Game module initialization incomplete',loader)
        self.assertIn('2.7.0-feature-health',loader)

    def test_built_dist_contains_all_three_fixes(self):
        core=READ('dist/Vortexion_Core.lua')
        self.assertIn('wind_input_probe',core)
        for name in ('AOTR_Battle','AOTR_Lobby','BloxStrike','SCP'):
            src=READ('dist/Vortexion_Module_'+name+'.lua')
            self.assertNotIn('executor unsupported:',src)
        data=json.loads(READ('dist/runtime-manifest.json'))
        self.assertIn('r2.7',data['build_tag'])

    def test_callback_native_filter_no_longer_opaque(self):
        src=READ('src/WindAdapter.luau')
        method=src[src.index('            local function changed(value)'):src.index('            local settings =',src.index('            local function changed(value)'))]
        method=re.sub(r'(?m)^(\s*)(\w+)\s*\+=\s*(\d+)$',lambda m:f'{m[1]}{m[2]} = {m[2]} + {m[3]}',method)
        lua='''
local bridge={Active=true}
local ready=true
local nativeEvents,nativeMismatch,revision,dispatchRevision=0,0,0,0
local lastNativeEvent="none"
local option={Value=false}
local nativeState=true
local function normalize(v)return v end
local function nativeValue()return nativeState end
local function equal(a,b)return a==b end
local function emit(v)option.Value=v;dispatchRevision=dispatchRevision+1 end
'''+method+'''
changed(true)
assert(nativeEvents==1 and nativeMismatch==0 and dispatchRevision==1 and option.Value==true)
changed(false) -- native state is still true, so stale event ignored
assert(nativeEvents==2 and nativeMismatch==1 and dispatchRevision==1)
assert(lastNativeEvent=='probe=false')
'''
        lua=lua.replace('local option={Value=false}','local option={Value=false}\nlocal id="probe"')
        LuaRuntime().run(lua)

if __name__=='__main__':unittest.main()
