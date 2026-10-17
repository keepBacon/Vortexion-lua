"""R226 native UI ESP mock; Lua 5.4 transpilation only for controlled test fixture."""
import re,unittest
from pathlib import Path
from test_wind_router import LuaRuntime
R=Path(__file__).resolve().parents[1]
def transpile(source):
 for pat,repl in [('accumulator += dt or 1/60','accumulator = accumulator + (dt or 1/60)'),('serial+=1','serial=serial+1'),('seen+=1','seen=seen+1'),('visible+=1','visible=visible+1')]:
  assert pat in source,pat
  source=source.replace(pat,repl)
 assert 'for _,cand in ipairs(roster) do' in source
 source=source.replace('for _,cand in ipairs(roster) do\n','for _,cand in ipairs(roster) do\n            do\n')
 assert '        for key,entry in pairs(entries) do' in source
 idx=source.index('for _,cand in ipairs(roster) do')
 source=source[:idx]+source[idx:].replace('        for key,entry in pairs(entries) do','            end\n            ::next_candidate::\n        for key,entry in pairs(entries) do',1)
 source=source.replace('continue','goto next_candidate')
 return source
F=r'''
math.clamp=function(x,lo,hi)return math.max(lo,math.min(hi,x))end
local V={}
V.__index=V
function V.new(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},V)end
function V.__mul(a,n)return V.new(a.X*n,a.Y*n,a.Z*n)end
function V.__add(a,b)return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
Vector3=V
local count={adorns=0,frames=0,stroke=0,billboards=0,boxes2D=0}
local instances={}
Instance={}
function Instance.new(class)
 local obj={ClassName=class,Parent=nil,Visible=false,Enabled=false,Size=V.new(0,0,0),Name=''}
 function obj:Destroy()self.Destroyed=true;self.Parent=nil end
 if class=='BoxHandleAdornment' then count.adorns=count.adorns+1
 elseif class=='Frame' then count.frames=count.frames+1
 elseif class=='UIStroke' then count.stroke=count.stroke+1
 elseif class=='BillboardGui' then count.billboards=count.billboards+1 end
 instances[#instances+1]=obj
 return obj
end
local color={new=function(r,g,b)return {R=r,G=g,B=b}end}
function color.fromRGB(r,g,b)return color.new(r/255,g/255,b/255)end
Color3=color
UDim2={fromScale=function(x,y)return {x,y}end,fromOffset=function(x,y)return {x,y}end}
Enum={Font={GothamBold='GothamBold'},ApplyStrokeMode={Border='Border'}}
local root={Name='root',Parent=true}
local world={}
local cam={ViewportSize={X=800,Y=600}}
function cam:WorldToViewportPoint(point)
 return {X=400+point.X*4,Y=300-point.Y*4,Z=point.Z}
end
world.CurrentCamera=cam
local function part(name,x,y,z)
 local p={Name=name,Size=V.new(2,2,2),Position=V.new(x,y,z),Parent=true}
 p.CFrame={}
 function p.CFrame:PointToWorldSpace(v)return p.Position+v end
 function p:IsA(name)return name=='BasePart' end
 return p
end
local head=part('Head',3,4,20)
local torso=part('UpperTorso',3,2,20)
local hrp=part('HumanoidRootPart',3,2,20)
local char={Parent=true,Name='EnemyChar',head=head,torso=torso,hrp=hrp}
function char:FindFirstChild(name)
 if name=='Head' then return head end
 if name=='UpperTorso' then return torso end
 if name=='HumanoidRootPart' then return hrp end
end
local player={Name='Enemy',Team={Name='Chaos Insurgency'}}
local target={Character=char,Player=player,Humanoid={Health=100},Head=head,HRP=hrp,Anchor=head,WorldDistance=25}
local candidates={}
function candidates:Get()return {target}end
function candidates:IsHostile(cand)return true end
function candidates:GetJob(cand)return 'Insurgency Command'end
local common={Services={Workspace=world,Players={}},
 LocalPlayer={},Candidates=candidates,GetGuiParent=function()return root end,
 VisualInterval=function(n)return n end,
 OnCleanup=function(fn)_G.cleanup=fn end}
'''
class TestNativeESP(unittest.TestCase):
 def test_3d_native_and_2d_native_projection(self):
  source=transpile((R/'src/SCPESP.luau').read_text())
  after='''
local ESP = (function() '''+source+''' end)()(common)
ESP.Config.Enabled=true
ESP.Config.ShowJob=true
ESP:Update(.1)
assert(ESP.Stats.Visible==1)
assert(count.adorns==2,'3D head and torso native adornee required')
assert(count.billboards==1,'native role/name label')
local active=0
for _,v in ipairs(instances)do if v.ClassName=='BoxHandleAdornment' and v.Visible then active=active+1 end end
assert(active==2)
ESP.Config.Style='2D'
ESP:Update(.1)
assert(ESP.Stats.Visible==1)
local visible2D=0
for _,v in ipairs(instances)do
 if v.ClassName=='Frame' and v.Name=='SCP2DCollisionBox' and v.Visible then visible2D=visible2D+1 end
end
assert(visible2D==2,'2D collision projection missing')
assert(count.stroke==2)
ESP:Cleanup()
for _,v in ipairs(instances)do
 if v.ClassName=='BoxHandleAdornment' or v.ClassName=='BillboardGui' then
  assert(v.Destroyed,'ESP resources not cleaned')
 end
end
'''
  LuaRuntime().run(F+after)
if __name__=='__main__':unittest.main()
