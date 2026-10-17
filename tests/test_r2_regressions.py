"""R2 isolated source contracts and Lua5.4 router/cache behavior (not Roblox live tests)."""
from pathlib import Path
import unittest
from tests.test_wind_router import LuaRuntime
from tests import test_wind_router as router_tests

ROOT = Path(__file__).resolve().parents[1]

class R2Regressions(unittest.TestCase):
    def test_existing_partial_boot_not_overwritten(self):
        source = (ROOT / 'src/GameRouter.luau').read_text(encoding='utf-8')
        LuaRuntime().run('''
local original = {Active=true, BootStatus='partial', BootError='skins subsystem unavailable', Window=function() return {} end}
local env = {VortexionWindBridge=original}
getgenv=function() return env end
warn=function() end
''' + '\nlocal router=(function()\n' + source + '\nend)()\n' + '''
local result=router.Run({},function() error('unexpected') end,function() return 1 end,7,8,'fixture')
assert(result==1)
assert(original.BootStatus=='partial')
assert(original.BootError=='skins subsystem unavailable')
original.BootStatus='ready'; original.BootError='old'
result=router.Run({},function() error('unexpected') end,function() return 2 end,7,8,'fixture')
assert(result==2 and original.BootStatus=='ready' and original.BootError==nil)
''')

    def test_cache_hit_is_preserved_after_failed_module_retry(self):
        fixture = router_tests.ModularTests.loader_script(case='success')
        LuaRuntime().run(fixture + r'''
local loader=env.VortexionLoaderV2
assert(loader.status=='success')
local coreKey=string.rep('1',64)
local moduleKey=string.rep('2',64)
assert(env.VortexionLoaderCache[coreKey])
env.VortexionLoaderCache[moduleKey]=nil
local original=game.HttpGet
game.HttpGet=function(self,url)
    if url:find('Vortexion_Module_Forsaken.lua',1,true) then return 'bad' end
    return original(self,url)
end
loader.Retry()
assert(loader.status=='failed' and loader.stage=='download-module')
assert(loader.cacheHits == 1)
assert(env.VortexionLoaderCache[coreKey], 'validated core cache was incorrectly deleted')
''')

    def test_skin_controls_cover_async_replication_and_refresh(self):
        source = (ROOT / 'src/BloxStrikeCosmetic.luau').read_text(encoding='utf-8')
        self.assertIn('resourcesConn = c.ReplicatedStorage.DescendantAdded:Connect', source)
        self.assertIn('existing.option:SetValues(values)', source)
        self.assertIn('created[categoryName] = nil', source)
        self.assertIn('if resourcesConn then resourcesConn:Disconnect() end', source)
        self.assertIn('if skinFolderConn then skinFolderConn:Disconnect() end', source)
        self.assertIn('skinEnabledOption:SetValue(false)', source)
        self.assertIn('Title="查看皮肤资源状态"', source)

    def test_game_module_failures_propagate_to_bootstrap(self):
        for path in ['src/BloxStrikeCore.luau','src/SCPCore.luau']:
            source = (ROOT / path).read_text(encoding='utf-8')
            self.assertIn('ui.BootStatus, ui.BootError = "partial", table.concat(bootFailures', source)
            self.assertIn('reportBootFailure(', source)

    def test_aotr_cloak_factory_failure_isolated(self):
        source = (ROOT / 'src/AOTRBattle.luau').read_text(encoding='utf-8')
        self.assertIn('pcall(AOTRCloakFactory, app)', source)
        self.assertIn('reportBootFailure("cloak", value)', source)
        self.assertIn('reportBootFailure(name, result)', source)
        self.assertIn('app.ui.BootStatus = "partial"', source)

    def test_scp_cloak_fallback_preserves_instances(self):
        source = (ROOT / 'src/SCPCore.luau').read_text(encoding='utf-8')
        self.assertIn('Protect = function(object) return object end', source)

    def test_runtime_hud_metrics_and_reset_are_opt_in(self):
        source = (ROOT / 'src/RuntimeMonitor.luau').read_text(encoding='utf-8')
        self.assertIn('STUTTER_THRESHOLD_MS = 50', source)
        self.assertIn('Title = "重置性能采样"', source)
        self.assertIn('if not value then stop(); return end', source)

if __name__ == '__main__': unittest.main()
