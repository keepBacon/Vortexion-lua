"""Shared error observability regression checks; real Android runtime remains unverified."""
from pathlib import Path
import hashlib, json, sys, unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tests'))
from test_wind_router import LuaRuntime

class BootErrorTests(unittest.TestCase):
    def test_router_preserves_original_module_failure(self):
        source = (ROOT / 'src/GameRouter.luau').read_text(encoding='utf-8')
        runtime = LuaRuntime()
        script = '''
local env = {}
getgenv = function() return env end
warn = function() end
local router = (function()\n''' + source + '''\nend)()
local function badEntry()
    env.VortexionBootError = 'WindUI/CreateWindow: unsupported rendering backend'
    return nil
end
local function badBridge() error('fallback is also unavailable') end
local result = router.Run({}, badBridge, badEntry, 1, 2, 'manual-test')
assert(result == nil)
assert(string.find(env.VortexionBootError, 'unsupported rendering backend', 1, true))
assert(string.find(env.VortexionBootError, 'Generic UI fallback', 1, true))
'''
        runtime.run(script)

    def test_wind_adapter_reports_exact_error_before_cleanup(self):
        adapter = (ROOT / 'src/WindAdapter.luau').read_text(encoding='utf-8')
        self.assertIn('recordStartupFailure("CreateWindow", result)', adapter)
        self.assertLess(adapter.index('recordStartupFailure("CreateWindow", result)'), adapter.index('self:Destroy()',adapter.index('if not initialized or cancelled then')))
        self.assertIn('Acrylic = not input.TouchEnabled', adapter)
        self.assertIn('pcall(function()\n                native:EditOpenButton(', adapter)

    def test_loader_validate_reports_original_cause(self):
        loader = (ROOT / 'loader.lua').read_text(encoding='utf-8')
        self.assertIn('env.VortexionBootError = nil', loader)
        self.assertIn('Root cause:', loader)
        self.assertIn('env.VortexionBootError or (type(bridge)', loader)

    def test_regenerated_runtime_manifest_hashes(self):
        m=json.loads((ROOT/'dist/runtime-manifest.json').read_text())
        items=[m['core'],*m['modules'].values()]
        for item in items:
            data=(ROOT/item['path']).read_bytes()
            self.assertEqual(item['bytes'],len(data))
            self.assertEqual(item['sha256'],hashlib.sha256(data).hexdigest())

if __name__ == '__main__':unittest.main()
