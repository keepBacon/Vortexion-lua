"""R2.6 BloxStrike startup regression. Lua54 mocks are NOT Roblox device tests."""
import hashlib
import json
import re
import unittest
from pathlib import Path
from test_wind_router import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'src'
CORE = (SRC/'BloxStrikeCore.luau').read_text(encoding='utf-8')
COMBAT = (SRC/'BloxStrikeCombat.luau').read_text(encoding='utf-8')
BULLET = (SRC/'BloxStrikeBullet.luau').read_text(encoding='utf-8')
VISUAL = (SRC/'BloxStrikeVisual.luau').read_text(encoding='utf-8')
COSMETIC = (SRC/'BloxStrikeCosmetic.luau').read_text(encoding='utf-8')


def lua54(s):
    return s.replace("global.VortexionBloxGeneration += 1", "global.VortexionBloxGeneration = global.VortexionBloxGeneration + 1").replace("slowLoops += 1", "slowLoops = slowLoops + 1")

STUBS = '''
getgenv = function() return _G end
warn = function(m) table.insert(__warn,m) end
__warn,__steps,__uiCount = {},{},0
__frame = nil
__combatOn, __bulletOn = false,false
__combatUpdates,__bulletUpdates,__cloakHooks = 0,0,0
local fake = {LocalPlayer={Name='local'}}
local services={Players=fake,RunService={},Workspace={},ReplicatedStorage={},Lighting={},UserInputService={}}
game={GetService=function(_,name) assert(services[name],name);return services[name] end}
UDim2={fromOffset=function(x,y)return {x=x,y=y} end}
Enum={RenderPriority={Last={Value=100}}}
tick=function() return 10 end
task={spawn=function(fn) end,wait=function() end}
function services.RunService:BindToRenderStep(name,order,callback)
   __frame=callback
   __frameName=name
end
function services.RunService:UnbindFromRenderStep(name)
   assert(name==__frameName)
   __frame=nil
end
BloxCommonFactory=function(c)
   c.Caps={}; c.Disposers={}; c.Debug=false
   c.Guard=function(_,cb) local ok,err=pcall(cb);assert(ok,err) end
   return c
end
BloxCloakFactory=function(c)
   return {Start=function()__cloakHooks=__cloakHooks+1 end, Stop=function() end,
           Protect=function(x)return x end}
end
BloxCombatFactory=function(c)
   return {IsActive=function()return __combatOn end,
           Update=function(_,dt)__combatUpdates=__combatUpdates+1 end,
           DebugSnapshot=function()return {} end}
end
BloxBulletFactory=function(c)
   return {IsActive=function()return __bulletOn end,
           Update=function(_,dt)__bulletUpdates=__bulletUpdates+1 end,
           Status=function()return {} end}
end
BloxVisualFactory=function(c) end
BloxCosmeticFactory=function(c) end
local bridge={Active=true}
local window={}
local tab={AddParagraph=function()end,AddButton=function()end,
           AddToggle=function()end,AddSlider=function()end,AddDropdown=function()end}
function window:AddTab()return tab end
function window:InstallSettings()end
function window:SelectTab()end
function bridge:CreateWindow() __uiCount=__uiCount+1;return window end
function bridge:OnDestroy(fn)self.onDestroy=fn end
function bridge:Destroy()if self.onDestroy then self.onDestroy() end end
function bridge:Notify()end
WindBridgeFactory=function()return bridge end
WindUI={}
'''

class BloxR26(unittest.TestCase):
    def test_source_has_no_boot_hook_and_separate_failure_capture(self):
        self.assertIn('common.CloakAutoHookDisabled = true', CORE)
        self.assertNotIn('common.Guard("Cloak", common.Cloak.Start)', CORE)
        self.assertIn('pcall(function()\n    return ui:CreateWindow', CORE)
        self.assertIn('VortexionBootError = "BloxStrike/CreateWindow:', CORE)
        self.assertIn('function Combat:IsActive()', COMBAT)
        self.assertIn('function Bullet:IsActive()', BULLET)
        self.assertIn('if not Config.ESPEnabled and not Config.SpeedEnabled', VISUAL)
        self.assertIn('task.delay(3, function()', COSMETIC)
        self.assertIn('Mode = "LeadOnly"', BULLET)
        self.assertIn('Default = "LeadOnly"', BULLET)
        self.assertIn('if mode == "Hitscan" or (mode == "Auto" and not mobile)', BULLET)
        self.assertIn('if mode == "Remote" or (mode == "Auto" and not mobile)', BULLET)
        self.assertIn('c.Caps.getrawmetatable', BULLET)
        self.assertIn('if addedThisPass % 2 == 0 then task.wait()', COSMETIC)

    def test_mock_startup_is_idle_until_feature_enabled(self):
        src=CORE
        for name in ['BloxCommonFactory','BloxCloakFactory','BloxCombatFactory','BloxBulletFactory',
                     'BloxVisualFactory','BloxCosmeticFactory','WindBridgeFactory','WindUI']:
            src=src.replace('local '+name+' = nil\n','')
        test=STUBS+lua54(src)+'''
assert(__uiCount==1, 'window not created')
assert(__cloakHooks==0, 'global hook started automatically')
assert(__frame, 'frame callback missing')
__frame(0.016)
assert(__combatUpdates==0 and __bulletUpdates==0,'idle work unexpectedly runs')
__combatOn=true; __frame(0.016)
assert(__combatUpdates==1 and __bulletUpdates==0,'combat update not gated')
__combatOn=false; __bulletOn=true; __frame(0.016)
assert(__combatUpdates==1 and __bulletUpdates==1,'bullet update not gated')
__bulletOn=false; __frame(0.016)
assert(__combatUpdates==1 and __bulletUpdates==1,'idle resumed incorrectly')
VortexionBloxCleanup()
assert(__frame==nil, 'render callback not unbound on cleanup')
assert(__cloakHooks==0, 'hook installed during cleanup')
'''
        LuaRuntime().run(test)

    def test_generated_bundles_match_hash_manifest(self):
        mf=json.loads((ROOT/'dist/runtime-manifest.json').read_text())
        self.assertRegex(mf['build_tag'], r'r2\.(6|7|8)')
        for item in [mf['core'],*mf['modules'].values()]:
            raw=(ROOT/item['path']).read_bytes()
            self.assertEqual(item['bytes'],len(raw))
            self.assertEqual(item['sha256'],hashlib.sha256(raw).hexdigest())
        bundle=(ROOT/'dist/Vortexion_Module_BloxStrike.lua').read_text()
        self.assertIn('common.CloakAutoHookDisabled = true',bundle)
        self.assertNotIn('common.Guard("Cloak", common.Cloak.Start)',bundle)

if __name__=='__main__': unittest.main()
