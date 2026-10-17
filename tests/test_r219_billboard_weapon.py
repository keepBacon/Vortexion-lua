"""R2.19 executable Lua 5.4 mocks: engine billboard geometry is delegated, not projected in Lua.
Mocks do not establish real Roblox/server behavior."""
from pathlib import Path
import re
import unittest
from test_wind_router import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
VISUAL=(ROOT/'src/BloxStrikeVisual.luau').read_text()
BULLET=(ROOT/'src/BloxStrikeBullet.luau').read_text()
COMBAT=(ROOT/'src/BloxStrikeCombat.luau').read_text()

def lower(s):
    # In tested fragments every augmented operand is a local numeric counter.
    return re.sub(r'(?<![\w.])([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*([+-])=\s*(\d+|[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)',
        lambda m:f'{m.group(1)} = {m.group(1)} {m.group(2)} {m.group(3)}',s)

BASE=r'''
local VM={}
function VM.__sub(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},VM) end
function VM.__index(t,k) if k=='Magnitude' then return math.sqrt(t.x*t.x+t.y*t.y+t.z*t.z) end end
local function vec(x,y,z)return setmetatable({x=x,y=y,z=z},VM) end
math.clamp=function(v,l,h)return math.max(l,math.min(h,v))end
local camera={CFrame={Position=vec(0,0,0)}}
local Workspace={CurrentCamera=camera,Raycast=function()return nil end}
local rootPart={Parent=true,Position=vec(12,0,0),Size=vec(2,2,2)}
function rootPart:IsA(k) return k=='BasePart' end
local model={Parent=true,Name='ENEMY',PrimaryPart=rootPart}
function model:FindFirstChild(n) if n=='HumanoidRootPart' or n=='Head' then return rootPart end end
function model:FindFirstChildOfClass(n)return nil end
function model:GetAttribute(n)return nil end
function model:GetChildren()return {} end
local guiRoot={Parent=true}
local localPlayer={Parent=true,Name='local',FindFirstChildOfClass=function(self,k)return guiRoot end}
local enemy={Parent=true,Name='enemy',DisplayName='ENEMY'}
local Players={GetPlayers=function()return {localPlayer,enemy} end}
local vital={Health=1,MaxHealth=1,HealthKnown=false}
local c={Living=function(player) if player==enemy then return model,vital end end,
 Enemy=function() return true end,HasDrawing=false}
local Config={ESPWorldHighlight=false,ESPOverlay=true,ESPEnabled=true,ESPTeam=true,ESPDistance=500,
 ESPNames=true,ESPHealth=true,ESPRange=true,ESPWeapon=true,ESPBox=true,ESPTracer=false}
local LocalPlayer=localPlayer
local Enum={HighlightDepthMode={AlwaysOnTop='AlwaysOnTop'},RaycastFilterType={Exclude='Exclude'},ApplyStrokeMode={Border='Border'}}
local RaycastParams={new=function()return {} end}
local Color3={fromRGB=function(r,g,b)return {r,g,b}end}
local UDim2={fromScale=function()return {}end,fromOffset=function()return {}end,
 new=function()return {}end}
local Vector3={new=vec}
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local Instance={new=function(class) return {ClassName=class,Parent=nil,Text='',Enabled=true,Visible=true,
 Destroy=function(self)self.Parent=nil;self.Destroyed=true end} end}
'''
class R219Tests(unittest.TestCase):
    def test_billboard_runtime_no_humanoid_occlusion_and_teardown(self):
        code=VISUAL[VISUAL.index('    local highlights = {}'):VISUAL.index('    --=========================================================================\n    -- Fullbright')]
        script=BASE+lower(code)+r'''
updateESP()
assert(espStats.scanned==1 and espStats.eligible==1 and espStats.markers==1)
local entry=highlights[enemy]
assert(entry and entry.gui.ClassName=='BillboardGui')
assert(entry.gui.AlwaysOnTop==true and entry.gui.Adornee==rootPart)
assert(entry.gui.Parent==guiRoot and entry.gui.Active==false)
assert(entry.stroke.Enabled and entry.text.Text=='ENEMY\n12 studs',entry.text.Text)
assert(entry.highlight==nil and entry.tracer==nil)
local n=espStats.creates
updateESP()
assert(espStats.creates==n,'reuse must avoid per-refresh allocations')
Config.ESPEnabled=false
updateESP()
assert(next(highlights)==nil and entry.gui.Destroyed==true,'teardown must destroy billboard')
'''
        LuaRuntime().run(script)

    def test_weapon_modifier_direct_table_runtime_and_restore(self):
        code=BULLET[BULLET.index('    local mods = {'):BULLET.index('    --=========================================================================\n    -- Aim resolution')]
        script=r'''
local modsTable={}
function modsTable.weaponKick() return 'kick' end
function modsTable.setWeaponRecoil() return 'recoil' end
function modsTable.getWeaponKickRotation()return 'rotation' end
function modsTable.getTrueSpread()return 8 end
function modsTable.getSpreadForConfig()return 6 end
local originals={kick=modsTable.weaponKick,spread=modsTable.getTrueSpread}
local ReplicatedStorage={FindFirstChild=function() return nil end}
local Vector3={zero='ZERO'}
local typeof=function(v)return type(v) end
local getgc=function() return {modsTable} end
local cleanup
local c={OnCleanup=function(fn)cleanup=fn end}
'''+lower(code)+r'''
setWeaponMod('recoil',true)
assert(modsTable.weaponKick() == 'kick' and modsTable.getWeaponKickRotation()=='ZERO', 'preserve unknown weaponKick return contract')
assert(modsTable.getTrueSpread()==8)
setWeaponMod('spread',true)
assert(modsTable.getTrueSpread()==0 and modsTable.getSpreadForConfig()==0)
setWeaponMod('recoil',false)
assert(modsTable.weaponKick()=='kick' and modsTable.getTrueSpread()==0)
cleanup()
assert(modsTable.weaponKick==originals.kick and modsTable.getTrueSpread==originals.spread)
'''
        LuaRuntime().run(script)

    def test_hitbox_server_envelope_uses_original_dimensions(self):
        self.assertIn('local size = originalSize(part)',COMBAT)
        self.assertIn('combat:GetEnvelope(part)',BULLET)
        self.assertIn('HitboxMode = "fullBody"',COMBAT)
        self.assertIn('HitboxMaxActive = 8',COMBAT)

    def test_esp_steady_state_avoids_expensive_projection(self):
        start=VISUAL.index('    local highlights = {}')
        end=VISUAL.index('    --=========================================================================\n    -- Fullbright')
        fragment=VISUAL[start:end]
        self.assertIn('Instance.new("BillboardGui")',fragment)
        self.assertIn('gui.AlwaysOnTop = true',fragment)
        self.assertNotIn('GetBoundingBox()',fragment)
        self.assertIn('if Config.ESPVisibility then',fragment)
        self.assertIn('entry.nextInfo = now + 0.3',fragment)
        self.assertIn('if not entry then',fragment)

if __name__=='__main__':unittest.main()
