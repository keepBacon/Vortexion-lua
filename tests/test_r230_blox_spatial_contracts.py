"""R230 real Lua execution tests for regressions found in the R229 client code.
Does not assert actual Roblox server hit registration."""
from pathlib import Path
import unittest
from test_wind_router import LuaRuntime
from test_r219_billboard_weapon import lower
ROOT = Path(__file__).resolve().parents[1]
COMBAT=(ROOT/'src/BloxStrikeCombat.luau').read_text()
CORE=(ROOT/'src/BloxStrikeCore.luau').read_text()
BULLET=(ROOT/'src/BloxStrikeBullet.luau').read_text()
VISUAL=(ROOT/'src/BloxStrikeVisual.luau').read_text()

class R230Contracts(unittest.TestCase):
    def test_spatial_roster_independent_of_aim_fov(self):
        frag=COMBAT[COMBAT.index('    local function scan()'):COMBAT.index('    --=========================================================================\n    -- Target part selection')]
        stub=r'''
local VM={}
function VM.__index(t,k)
 if k=='Magnitude' then return math.sqrt(t.x*t.x+t.y*t.y+t.z*t.z)end
 return VM[k]
end
function VM.__sub(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},VM)end
function VM:Lerp(other,t) return other end
local function v(x,y,z)return setmetatable({x=x,y=y,z=z},VM) end
local Vector3={zero=v(0,0,0)}
local Vec2={}
function Vec2.__index(t,k)
 if k=='Magnitude' then return math.sqrt(t.x*t.x+t.y*t.y)end
 return Vec2[k]
end
function Vec2.__sub(a,b)return setmetatable({x=a.x-b.x,y=a.y-b.y},Vec2)end
local Vector2={new=function(x,y)return setmetatable({x=x,y=y},Vec2)end}
local root={Parent=true,Position=v(10,0,65),AssemblyLinearVelocity=Vector3.zero}
local model={Parent=true,PrimaryPart=root}
function model:FindFirstChild(key) if key=='HumanoidRootPart' then return root end end
local enemy={Parent=true,Name='enemy'}
local camera={CFrame={Position=v(0,0,0)},ViewportSize={X=800,Y=600}}
function camera:WorldToViewportPoint(pos)return {X=900,Y=300,Z=50},false end
local Workspace={CurrentCamera=camera}
local Players={GetPlayers=function()return {enemy}end}
local LocalPlayer={}
local Config={RageEnabled=false,MaxDistance=500,RageDistance=900,FOV=90,RageFOV=700,HitboxEnabled=true,TeamCheck=true}
local state={scans=0,candidates={},spatialTargets={},velEMA={}}
local c={Targets=function()return {enemy}end,Living=function(p)return model,{Health=100}end,Enemy=function()return true end}
'''
        LuaRuntime().run(stub+lower(frag)+r'''
scan()
assert(#state.spatialTargets == 1, 'hitboxes must use spatial target even offscreen')
assert(#state.candidates == 0, 'aim must respect FOV')
assert(state.enemySeen == 1 and state.liveSeen == 1)
''')

    def test_hitbox_eligibility_ignores_crosshair(self):
        frag=COMBAT[COMBAT.index('    local function hitboxEligible(entry)'):COMBAT.index('    local function targetSizeFor')]
        LuaRuntime().run(r'''
local model={Parent=true}
local root={Parent=true}
local enemy={Parent=true}
local Config={TeamCheck=true}
local c={Living=function()return model,{Health=100}end,Enemy=function()return true end}
local function entryValid()return false end
'''+lower(frag)+r'''
assert(hitboxEligible({player=enemy,model=model,root=root,worldDist=100})==true,
       'full body must not be limited by crosshair FOV')
assert(hitboxEligible({player=enemy,model=model,root=root,worldDist=700})==false)
''')

    def test_weapon_method_separate_enable_late(self):
        self.assertIn('if mods.recoil then\n                for _, key',BULLET)
        self.assertIn('if mods.spread then\n                for _, key',BULLET)
        self.assertIn('recordPatch checks individual owner/key pairs',BULLET)
        self.assertNotIn('"weaponKick", "setWeaponRecoil"',BULLET)

    def test_boot_frame_fallback_and_esp_renderer_fallback(self):
        self.assertIn('RunService.RenderStepped:Connect(bloxFrame)',CORE)
        self.assertIn('frameAttached = true',CORE)
        self.assertIn('entry.gui.Enabled = Config.ESPEnabled\n            espStats.lastError = "2D overlay unavailable',VISUAL)

if __name__=='__main__':unittest.main()
