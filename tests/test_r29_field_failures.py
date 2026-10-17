"""R2.9 field-failure guards. Structural checks are not Roblox in-game verification."""
from pathlib import Path
import hashlib
import json
import unittest

ROOT=Path(__file__).resolve().parents[1]
read=lambda p:(ROOT/p).read_text(encoding='utf-8')

class FieldFailures(unittest.TestCase):
    def test_invalid_childremoving_not_in_runtime(self):
        titan=read('src/AOTRTitans.luau')
        self.assertNotIn('ChildRemoving',titan)
        self.assertIn('folder.ChildRemoved:Connect',titan)
        self.assertIn('folder.ChildAdded:Connect',titan)
        self.assertIn('disconnectFolder()',titan)

    def test_lifecycle_fixture_does_not_mask_real_api_failure(self):
        fixture=read('tests/test_aotr_titans_lifecycle.luau')
        self.assertNotIn('ChildRemoving',fixture)
        self.assertIn('ChildRemoved=signal()',fixture)
        self.assertIn('ChildRemoved:Fire(child)',fixture)

    def test_forsaken_diagnostic_disambiguates_disabled_and_empty(self):
        source=read('src/ForsakenCore.luau')
        self.assertIn('countReadyCharacters',source)
        self.assertIn('感知开关关闭（不扫描）',source)
        self.assertIn('kReady, kTotal',source)
        self.assertIn('sReady, sTotal',source)

    def test_built_outputs_and_sources_match(self):
        manifest=json.loads(read('dist/build-manifest.json'))
        for relative,expected in manifest['sources'].items():
            self.assertEqual(hashlib.sha256((ROOT/relative).read_bytes()).hexdigest(), expected, relative)
        self.assertIn('folder.ChildRemoved:Connect',read('dist/Vortexion_Module_AOTR_Battle.lua'))
        self.assertNotIn('folder.ChildRemoving:Connect',read('dist/Vortexion_Module_AOTR_Battle.lua'))
        self.assertIn('感知开关关闭（不扫描）',read('dist/Vortexion_Module_Forsaken.lua'))

if __name__=='__main__': unittest.main()
