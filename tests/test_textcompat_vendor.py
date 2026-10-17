"""Exercise the generated WindUI Text compatibility boundary with a Luau runtime."""
from pathlib import Path
import importlib.util
import hashlib
import unittest
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tests'))
from test_wind_router import LuaRuntime
spec = importlib.util.spec_from_file_location('vortexion_build_r22', ROOT / 'build.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class VendorTextCompatTests(unittest.TestCase):
    def test_real_vendor_only_patched_in_output(self):
        original = (ROOT / 'vendor/WindUI/Source.lua').read_text('utf-8')
        digest = hashlib.sha256(original.encode('utf-8')).hexdigest()
        result = builder.patch_vendor_text_compat(original)
        self.assertNotEqual(original, result)
        self.assertEqual(original.count('function p.New(r,u,v)'), 1)
        self.assertIn('[Vortexion/Wind/TextCompat]', result)
        self.assertEqual(hashlib.sha256((ROOT / 'vendor/WindUI/Source.lua').read_bytes()).hexdigest(), digest)

    def test_creator_text_table_and_normal_string(self):
        original = (ROOT / 'vendor/WindUI/Source.lua').read_text('utf-8')
        output = builder.patch_vendor_text_compat(original)
        start = output.index('function p.New(r,u,v)')
        end = output.index('function p.Tween(', start)
        creator = output[start:end]
        fixture = '''
local env = {}
getgenv = function() return env end
warn = function(message) env.lastWarn = message end
Instance = { new = function(class) return { ClassName = class } end }
local p = {DefaultProperties={TextLabel={Text=""}}, Localization=nil}
''' + creator + '''
local a = p.New('TextLabel', {Name='Toolbar',Text={Title='Vortexion'}})
assert(a.Text == 'Vortexion')
local b = p.New('TextLabel', {Name='Empty',Text={}})
assert(b.Text == '')
local c = p.New('TextLabel', {Name='Original',Text='Untouched'})
assert(c.Text == 'Untouched')
assert(env.VortexionTextCompatCount == 2)
assert(string.find(env.VortexionTextCompatLast,'class=TextLabel',1,true))
assert(string.find(env.lastWarn,'TextCompat',1,true))
'''
        LuaRuntime().run(fixture)

    def test_stub_build_and_vendor_drift_guard(self):
        self.assertEqual(builder.patch_vendor_text_compat('return {}'), 'return {}')
        with self.assertRaisesRegex(ValueError, 'Creator.New changed'):
            builder.patch_vendor_text_compat('function p.New(r,u,v) end')

    def test_all_twelve_bundles_have_compat_layer(self):
        for file in sorted((ROOT / 'dist').glob('Vortexion_*.lua')):
            with self.subTest(file=file.name):
                if file.name.startswith('Vortexion_Module_'):
                    self.assertNotIn('[Vortexion/Wind/TextCompat]',file.read_text())
                else:
                    self.assertIn('[Vortexion/Wind/TextCompat]',file.read_text())

if __name__=='__main__':
    unittest.main()
