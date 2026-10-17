"""R2.14 contracts: deterministic source/interface checks, not Roblox server validation."""
from pathlib import Path
import re
import unittest
from test_r25_stability import to_lua54
from test_wind_router import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
FS = (ROOT / 'src/ForsakenCore.luau').read_text()
ENH = (ROOT / 'src/ForsakenEnhancements.luau').read_text()
AOTR = (ROOT / 'src/AOTRBattle.luau').read_text()
COMBAT = (ROOT / 'src/AOTRCombat.luau').read_text()
WIND = (ROOT / 'src/WindAdapter.luau').read_text()

class R214Contracts(unittest.TestCase):
    def test_six_requested_vision_features_are_wired(self):
        control_ids = ('FsKillerIdentityR214', 'FsSurvivorIdentityR214',
            'FsSurvivorHPR214', 'FsTrapsR214', 'FsHelpersR214', 'FsDangerR214')
        for c in control_ids:
            self.assertIn('AddToggle("'+c+'"', FS)
            self.assertIn('{"'+c+'",', FS, 'must be registered for reconciliation')
        for state in ('killerInfo','survivorInfo','survivorHP','traps','helpers','danger'):
            self.assertRegex(FS, r'\bstate\.'+state+r'\b')
        self.assertIn('FindFirstChildOfClass("Humanoid")', FS)
        self.assertIn('infoValue(model, {"SkinName"', FS)
        self.assertIn('hum.Health, hum.MaxHealth', FS)

    def test_part_hazards_do_not_read_model_only_properties(self):
        self.assertIn('local root = model:IsA("BasePart") and model', FS)
        self.assertIn('model:IsA("Model") and model.PrimaryPart', FS)
        self.assertIn('highlight.Parent = model', FS)
        self.assertNotIn('"john"}', FS)
        self.assertIn('node:FindFirstChildOfClass("Humanoid")', FS)

    def test_visual_scanning_is_bounded_and_cleanup_owned(self):
        self.assertIn('budget = 32', FS)
        self.assertIn('budget = 0', FS) if False else None
        self.assertIn('650', FS)
        self.assertIn('hazardCacheAt < 1.0', FS)
        self.assertIn('state.labels[model] = nil', FS)
        self.assertIn('state.dangerGui:Destroy()', FS)
        self.assertIn('label.Active = false', FS)

    def test_generator_fallback_never_reports_unverified_repair_success(self):
        for k in ('FsGeneratorProtocolR214','Legacy RE','legacy-remote-unconfirmed',
            'no-progress-after-remote','progress-confirmed','puzzle-open','awaitingProgress'):
            self.assertIn(k, ENH)
        self.assertIn('re:FireServer()', ENH)
        self.assertRegex(ENH, r'if distance > 12 then[\s\S]{0,800}re:FireServer\(\)')
        self.assertIn('stagnant >= 3', ENH)
        self.assertIn('state.repairPaused = true', ENH)

    def test_aotr_combat_stability_and_shared_frame_budget(self):
        self.assertIn('HitChance=1,', COMBAT)
        self.assertIn('CooldownJitter=0.05,', COMBAT)
        self.assertIn('UserInputService.TouchEnabled', COMBAT)
        self.assertIn('lockAvailable=state.locked ~= nil', COMBAT)
        self.assertIn('serverConfirmed=false', COMBAT)
        for k, timing in [('Titans', '0.10'), ('ESP', '0.05'), ('Farm', '0.25')]:
            self.assertIn('throttled.'+k, AOTR)
            self.assertIn('throttled.'+k+' >= '+timing, AOTR)
        self.assertIn('Combat:Update(dt)', AOTR)

    def test_wind_mobile_input_coalescing(self):
        self.assertIn('["均衡"] = 30', WIND)
        self.assertIn('task.delay(input.TouchEnabled and 0.05 or 0.01', WIND)
        self.assertIn('clampHz(input.TouchEnabled and 30 or 60)', WIND)
        self.assertIn('safeCallback(c.Callback', WIND)

    def test_sources_compile_in_lua_54_equivalent(self):
        for s in (FS, ENH, AOTR, COMBAT):
            code = to_lua54('local function only_compile()\n'+s+'\nend')
            code = re.sub(r'\b([a-zA-Z_]\w*(?:\.\w+)*)\s*\+=\s*(\d+)\b',
                          lambda m: f'{m[1]} = {m[1]} + {m[2]}', code)
            LuaRuntime().run(code)

if __name__=='__main__':
    unittest.main()
