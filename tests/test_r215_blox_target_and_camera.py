"""R2.15 BloxStrike model-health and third-person lifecycle regression.

The Lua 5.4 mock executes the real isolated functions; this is NOT a Roblox device test.
"""
from pathlib import Path
import hashlib, json, unittest
from test_wind_router import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
CORE=(ROOT/'src/BloxStrikeCore.luau').read_text()
VISUAL=(ROOT/'src/BloxStrikeVisual.luau').read_text()
COMBAT=(ROOT/'src/BloxStrikeCombat.luau').read_text()

class BloxR215(unittest.TestCase):
    def test_nonhumanoid_models_are_stable_live_targets(self):
        start=CORE.index('local virtualVitals = ')
        end=CORE.index('\nlocal function isEnemy(',start)
        runtime='''
local model={Parent=true, class='Model', attributes={}}
function model:IsA(cls)return cls==self.class end
function model:GetAttribute(key)return self.attributes[key] end
function model:FindFirstChild(key)return nil end
function model:FindFirstChildOfClass(key)return self.humanoid end
function model:FindFirstChildWhichIsA(key,recursive) return self.part and {ClassName='BasePart'} or nil end
model.part=true
local current=model
local function characterOf(pl)return current end
''' + CORE[start:end] + '''
local pl={Name='target'}
local a,health=livingCharacter(pl)
assert(a==model and health.Health==1 and health.HealthKnown==false, 'model without Humanoid was wrongly discarded')
local b,nextHealth=livingCharacter(pl)
assert(b==model and nextHealth==health, 'stable health reference required for lock revalidation')
model.attributes.Health=30
model.attributes.MaxHealth=70
local c,changed=livingCharacter(pl)
assert(c==model and changed==health and changed.Health==30 and changed.MaxHealth==70 and changed.HealthKnown)
model.attributes.Health=0
assert(livingCharacter(pl)==nil, 'zero health should be excluded')
model.attributes.Health=nil
model.attributes.Dead=true
assert(livingCharacter(pl)==nil,'dead flag should be excluded')
model.attributes.Dead=nil
model.humanoid={Health=50,MaxHealth=100}
local d,actual=livingCharacter(pl)
assert(d==model and actual==model.humanoid,'real humanoid must take priority')
model.humanoid.Health=0
assert(livingCharacter(pl)==nil)
'''
        LuaRuntime().run(runtime)

    def test_thirdperson_actual_restore_in_lua_mock(self):
        start=VISUAL.index('    local thirdPerson = ')
        end=VISUAL.index('    local moveAccum = 0',start)
        src=VISUAL[start:end].replace('thirdPerson.overrides += 1','thirdPerson.overrides = thirdPerson.overrides + 1')
        script='''
local player={CameraMode='Locked',CameraMinZoomDistance=0.5,CameraMaxZoomDistance=0.5}
local subject={Parent=true}
local camera={Parent=true,CameraType='Scriptable',CameraSubject=subject}
local model={}
function model:FindFirstChildOfClass()return nil end
function model:FindFirstChild(name) if name=='HumanoidRootPart' then return subject end end
function model:FindFirstChildWhichIsA()return subject end
local signal={Connect=function(self,fn)return {Disconnect=function()end} end}
local Workspace={CurrentCamera=camera,GetPropertyChangedSignal=function()return signal end}
local LocalPlayer=player
local Enum={CameraMode={Classic='Classic'},CameraType={Scriptable='Scriptable',Custom='Custom'}}
local savedCleanups={}
local c={Character=function()return model end,OnCleanup=function(fn)table.insert(savedCleanups,fn)end,
Guard=function(name,fn)assert(pcall(fn))end}
''' + src + '''
setThirdPerson(true)
assert(player.CameraMode=='Classic' and player.CameraMinZoomDistance==12 and player.CameraMaxZoomDistance==12)
assert(camera.CameraType=='Custom' and camera.CameraSubject==subject)
thirdPerson.distance=19
updateThirdPerson()
assert(player.CameraMinZoomDistance==19 and player.CameraMaxZoomDistance==19)
setThirdPerson(false)
assert(player.CameraMode=='Locked' and player.CameraMinZoomDistance==0.5 and player.CameraMaxZoomDistance==0.5)
assert(camera.CameraType=='Scriptable' and camera.CameraSubject==subject)
assert(thirdPerson.saved==nil)
'''
        LuaRuntime().run(script)

    def test_all_blox_modules_connected_and_dist_generated(self):
        self.assertIn('setup("视觉", BloxVisualFactory, "Visual")',CORE)
        self.assertIn('function Config:Status()',VISUAL)
        self.assertIn('BloxThirdPerson',VISUAL)
        self.assertIn('BloxThirdDistance',VISUAL)
        self.assertIn('espStats.noHumanoid',VISUAL)
        self.assertIn('type(humanoid) ~= "table" or humanoid.HealthKnown ~= false',VISUAL)
        self.assertIn('type(entry.humanoid) == "table" and entry.humanoid.HealthKnown == false',COMBAT)
        self.assertIn('AimTurnRate = 120',COMBAT)
        self.assertIn('Default = 100, Rounding = 0',COMBAT)
        self.assertIn('BloxAimPriority',COMBAT)
        dist=ROOT/'dist'
        manifest=json.loads((dist/'runtime-manifest.json').read_text())
        self.assertIn('r2.15',manifest['build_tag'])
        for item in [manifest['core'],*manifest['modules'].values()]:
            payload=(ROOT/item['path']).read_bytes()
            self.assertEqual(hashlib.sha256(payload).hexdigest(),item['sha256'])
        self.assertIn('BloxThirdPerson',(dist/'Vortexion_Module_BloxStrike.lua').read_text())

if __name__=='__main__':unittest.main()
