"""R2.3: preserve the original vendor error, prevent stale-GUI reentry."""
from pathlib import Path
import unittest
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tests'))
from test_wind_router import LuaRuntime

class VendorFailureR23(unittest.TestCase):
    def test_constructor_error_wins_over_rethrow_at_game_entry(self):
        router=(ROOT/'src/GameRouter.luau').read_text('utf-8')
        sample='''
local env = {}
getgenv = function() return env end
local logs={}
warn = function(msg) table.insert(logs,msg) end
local router=(function()\n''' + router + '''\nend)()
local calls=0
local function badEntry()
    env.VortexionBootError='WindUI/CreateWindow: [vendor-constructor] Text property expected string'
    error('game-entry:5471: Unable to assign property Text. string expected, got table')
end
local function bridgeFactory()
    calls=calls+1
    error('unexpected stale GUI reuse')
end
local result=router.Run({},bridgeFactory,badEntry,6331902150,83645629621104,'universe')
assert(result==nil)
assert(calls==0)
assert(env.VortexionBootError=='WindUI/CreateWindow: [vendor-constructor] Text property expected string')
assert(not string.find(table.concat(logs,' '), 'Generic UI fallback',1,true))
'''
        LuaRuntime().run(sample)

    def test_ctor_failure_also_skips_fallback_for_nonexception_early_exit(self):
        router=(ROOT/'src/GameRouter.luau').read_text('utf-8')
        script='''
local env = {}
getgenv = function() return env end
warn = function() end
local router=(function()\n''' + router + '''\nend)()
local times=0
local function entry() env.VortexionBootError='WindUI/CreateWindow: ctor fail'; return nil end
local result=router.Run({},function() times=times+1; error('bad fallback') end,entry,1,2,'failure')
assert(result==nil and times==0)
assert(env.VortexionBootError=='WindUI/CreateWindow: ctor fail')
'''
        LuaRuntime().run(script)

    def test_vendor_call_is_xpcall_and_phase_preserved(self):
        adapter=(ROOT/'src/WindAdapter.luau').read_text('utf-8')
        self.assertIn('local vendorOK, vendorValue = xpcall(function()',adapter)
        self.assertIn('WindUI vendor constructor:',adapter)
        self.assertIn('debug.traceback',adapter)
        self.assertIn('debug.info',adapter)
        self.assertIn('recordStartupFailure("CreateWindow", "[" .. creationPhase',adapter)

if __name__=='__main__': unittest.main()
