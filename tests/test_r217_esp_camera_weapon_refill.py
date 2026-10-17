"""R2.17 source/behavior contracts. Offline mocks do not prove Roblox server effects."""
from pathlib import Path
import re
import unittest
from test_wind_router import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
VISUAL=(ROOT/'src/BloxStrikeVisual.luau').read_text()
BULLET=(ROOT/'src/BloxStrikeBullet.luau').read_text()
FARM=(ROOT/'src/AOTRFarm.luau').read_text()

class R217Tests(unittest.TestCase):
    def test_esp_projected_overlay_survives_highlight_occlusion(self):
        self.assertIn('Instance.new("BillboardGui")',VISUAL)
        self.assertIn('gui.AlwaysOnTop = true',VISUAL)
        self.assertIn('gui.Active = false',VISUAL)
        self.assertIn('MAX_ESP_TARGETS = 24',VISUAL)
        self.assertIn('math.max(0.25, value)',VISUAL)
        self.assertIn('makeEntry(player, model, root)',VISUAL)

    def test_third_person_uses_one_post_camera_binding(self):
        self.assertIn('RunService:BindToRenderStep(cameraBindName, Enum.RenderPriority.Last.Value + 5', VISUAL)
        self.assertIn('RunService:UnbindFromRenderStep(cameraBindName)', VISUAL)
        self.assertNotIn('thirdPerson.accumulator', VISUAL)
        self.assertIn('thirdPerson.lastBase or observed', VISUAL)

    def test_weapon_zero_effect_path_is_visible(self):
        self.assertIn('LinkCombat = true', BULLET)
        self.assertIn('option:SetValue(true)', BULLET)
        self.assertIn('function Bullet:Status()', BULLET)
        self.assertIn('runtime classes: gun=', BULLET)
        self.assertIn('seen > 2500', BULLET)
        self.assertIn('needsAim =', BULLET)

    def test_aotr_refill_actual_factory_lua_mock(self):
        code=re.sub(r'([A-Za-z][\w.]*)\s*\+=\s*([A-Za-z0-9_.]+)',lambda m:m.group(1)+' = '+m.group(1)+' + '+m.group(2),FARM)
        runtime=r'''
local V={};function V.__sub(a,b)return setmetatable({n=a.n-b.n},V) end
function V.__index(t,k) if k=='Magnitude' then return math.abs(t.n) end end
local function vec(x)return setmetatable({n=x},V) end
local function item(name,children,pos)
 local t={Name=name,Parent=true,child=children or {},Position=pos}
 function t:FindFirstChild(k)return self.child[k] end
 function t:IsA(k)return k=='BasePart' and self.Position~=nil end
 function t:GetChildren() local a={}for _,v in pairs(self.child)do a[#a+1]=v end return a end
 function t:GetDescendants() local a={}local function walk(x)for _,v in pairs(x.child or {})do a[#a+1]=v;walk(v)end end;walk(self);return a end
 return t
end
local close=item('Refill',{},vec(3));local far=item('Refill',{},vec(500))
local gas=item('GasTanks',{Refill=close})
local stations=item('Reloads',{GasTanks=gas,Other=item('Other',{Refill=far})})
local world=item('World',{Unclimbable=item('Unclimbable',{Reloads=stations})})
local me={Character=item('Char',{HumanoidRootPart=item('HumanoidRootPart',{},vec(0))})}
local Players={LocalPlayer=me}
local calls=0;local remote={FireServer=function(self,...)calls=calls+1 end}
local gasValue=50
local app={Services={Workspace=world,Players=Players},Remotes={POST=remote},HUD={gas=true,spears=true,blades=true},
 ReadPercent=function(p)return gasValue end, ReadCount=function(p)return 3,3 end,
 ProbeHUD=function()end,Log=function()end,OnStop=function(self,fn)end,
 Guard=function(name,fn,...)local ok,result=pcall(fn,...);assert(ok,tostring(result));return result end}
local makeFarm=(function()
'''+code+r'''
end)()
local ok,farmOrError=xpcall(function() return makeFarm(app) end,debug.traceback)
assert(ok, farmOrError)
local Farm=farmOrError
assert(Farm.ResolveRefill()==close,'must pick nearest refill, not the first returned station')
Farm.Config.AutoRefill=true
Farm:Update(0.6)
assert(calls==1, 'must send one request while needing gas')
local snapshot=Farm:DebugSnapshot()
assert(snapshot.attempts==1 and snapshot.distance==3 and snapshot.status:find('awaiting'), snapshot.status)
Farm:Update(0.6)
assert(calls==1,'must throttle refill even when Update is called repeatedly')
'''
        LuaRuntime().run(runtime)

if __name__=='__main__':unittest.main()
