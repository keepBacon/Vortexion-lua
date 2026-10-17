"""R2.10 cross-game state reconciliation and instrumentation checks (mock only)."""
from pathlib import Path
import re, unittest, json, hashlib
from test_wind_router import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
def read(file): return (ROOT/file).read_text(encoding='utf8')

class CrossGameStateR210(unittest.TestCase):
    def test_all_game_entrypoints_register_health(self):
        for path,needle in (
            ('src/ForsakenCore.luau','RegisterFeatureHealth("Forsaken"'),
            ('src/AOTRBattle.luau','RegisterFeatureHealth("AOTR 战斗"'),
            ('src/AOTRLobby.luau','RegisterFeatureHealth("AOTR 大厅"'),
            ('src/BloxStrikeCore.luau','RegisterFeatureHealth("BloxStrike"'),
            ('src/SCPCore.luau','RegisterFeatureHealth("SCP"'),
        ):
            with self.subTest(path=path): self.assertIn(needle,read(path))

    def test_toggle_reconcile_mock_execution(self):
        source=read('src/WindAdapter.luau')
        start=source.index('    function bridge:ReconcileGameplayOptions()')
        end=source.index('    local gameSyncSignal', start)
        code=source[start:end]
        code=re.sub(r'(?m)^(\s*)([a-zA-Z_][\w]*) \+= ([^\n]+)$',
                    lambda m: m[1]+m[2]+' = '+m[2]+' + '+m[3],code)
        lua="""
local syncSamples, syncRepairs, syncFailures = 0, 0, 0
local original=false
local changeCount=0
local option={Kind='Toggle',Value=false}
function option:GetNativeValue()return original end
function option:SyncFromNative()
  if self.Value==original then return false end
  self.Value=original
  changeCount=changeCount+1
  return true
end
local slider={Kind='Slider',GetNativeValue=function()error('slider must not be polled')end}
local bridge={Active=true,Options={test=option,slider=slider},LastError=nil}
""" + code + """
assert(bridge:ReconcileGameplayOptions()==0)
original=true
assert(bridge:ReconcileGameplayOptions()==1)
assert(option.Value==true and changeCount==1)
assert(bridge:ReconcileGameplayOptions()==0 and changeCount==1)
original=false
assert(bridge:ReconcileGameplayOptions()==1 and changeCount==2)
bridge.Active=false
original=true
assert(bridge:ReconcileGameplayOptions()==0 and changeCount==2)
assert(syncSamples==4 and syncRepairs==2 and syncFailures==0)
"""
        LuaRuntime().run(lua)

    def test_health_provider_scope_precedes_cleanup(self):
        source=read('src/WindAdapter.luau')
        self.assertLess(source.index('local healthProviders = {}'), source.index('local function cleanup()'))
        self.assertIn('table.clear(healthProviders)',source)
        self.assertIn('table.insert(connections, gameSyncSignal)',source)

    def test_game_startup_status_not_pretend_success(self):
        for path in ('src/AOTRBattle.luau','src/SCPCore.luau','src/BloxStrikeCore.luau'):
            self.assertIn('#bootFailures',read(path))
        self.assertIn('Failed = true',read('src/BloxStrikeCore.luau'))

    def test_forsaken_spectator_continuity(self):
        fs=read('src/ForsakenCore.luau')
        for needle in ('state.scanMode = "spectator"','camera.CFrame.Position','CharacterRemoving:Connect','option:SyncFromNative()','watchConnection:Disconnect()'):
            self.assertIn(needle,fs)

    def test_modules_and_source_integrity(self):
        manifest=json.loads(read('dist/build-manifest.json'))
        runtime=json.loads(read('dist/runtime-manifest.json'))
        self.assertRegex(runtime['build_tag'], r'r2\.\d+')
        for path,sha in manifest['sources'].items():
            self.assertEqual(hashlib.sha256((ROOT/path).read_bytes()).hexdigest(),sha,path)
        for filename in ('Forsaken','BloxStrike','AOTR_Lobby','AOTR_Battle','SCP'):
            self.assertIn('RegisterFeatureHealth',read('dist/Vortexion_Module_'+filename+'.lua'))

if __name__=='__main__': unittest.main()
