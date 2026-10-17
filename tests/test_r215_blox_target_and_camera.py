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
local player={UserId=123,CameraMode='Locked',CameraMinZoomDistance=0.5,CameraMaxZoomDistance=0.5}
local base={Position={x=0,y=0,z=0},LookVector={x=0,y=0,z=1}}
local cm={__mul=function(a,b)return b end}
local vectorMeta={}
function vectorMeta.__sub(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},vectorMeta) end
function vectorMeta.__add(a,b) return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},vectorMeta) end
function vectorMeta.__mul(a,n) return setmetatable({x=a.x*n,y=a.y*n,z=a.z*n},vectorMeta) end
local function vec(x,y,z)return setmetatable({x=x,y=y,z=z},vectorMeta) end
base.Position=vec(0,0,0);base.LookVector=vec(0,0,1)
local camera={Parent=true,CFrame=base}
local renderCallbacks={}
local RunService={BindToRenderStep=function(self,name,priority,fn)renderCallbacks[name]=fn end,
UnbindFromRenderStep=function(self,name)renderCallbacks[name]=nil end}
local Workspace={CurrentCamera=camera,Raycast=function()return nil end,GetPropertyChangedSignal=function()
return {Connect=function(self,fn)return {Disconnect=function()end}end}end}
local LocalPlayer=player
local Enum={CameraMode={Classic='Classic'},RenderPriority={Camera={Value=200},Last={Value=2000}},RaycastFilterType={Exclude='Exclude'}}
local RaycastParams={new=function()return {}end}
local Vector3={new=vec}
local CFrame={lookAt=function(a,b)return {Position=a,LookVector=vec(0,0,1)} end}
math.clamp=function(v,lo,hi)return math.max(lo,math.min(hi,v))end
local savedCleanups={}
local c={Character=function()return nil end,OnCleanup=function(fn)table.insert(savedCleanups,fn)end,
Guard=function(name,fn)assert(pcall(fn))end,IsCurrent=function()return true end}
''' + src + '''
setThirdPerson(true)
assert(player.CameraMode=='Classic')
local k=next(renderCallbacks)
assert(k~=nil, 'third-person must bind after native camera')
renderCallbacks[k]()
assert(camera.CFrame~=base, 'camera offset should render at end of frame')
local first=camera.CFrame
renderCallbacks[k]()
assert(camera.CFrame.Position.x == first.Position.x and camera.CFrame.Position.z == first.Position.z, 'offset must never stack')
setThirdPerson(false)
assert(next(renderCallbacks)==nil)
assert(player.CameraMode=='Locked' and player.CameraMinZoomDistance==0.5 and player.CameraMaxZoomDistance==0.5)
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
        self.assertRegex(manifest['build_tag'], r'r2\.(?:1[5-9]|[2-9][0-9])')
        for item in [manifest['core'],*manifest['modules'].values()]:
            payload=(ROOT/item['path']).read_bytes()
            self.assertEqual(hashlib.sha256(payload).hexdigest(),item['sha256'])
        self.assertIn('BloxThirdPerson',(dist/'Vortexion_Module_BloxStrike.lua').read_text())

if __name__=='__main__':unittest.main()
