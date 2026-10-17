from pathlib import Path
import re,sys
from test_wind_router import LuaRuntime
s=(Path(__file__).resolve().parents[1]/'src/BloxStrikeVisual.luau').read_text()
extract=s[s.index('    local highlights = {}'):s.index('    local function startESP()')]
extract=re.sub(r'(?m)^(\s*)([\w.]+) \+= (.*)$',lambda m: m.group(1)+m.group(2)+' = '+m.group(2)+' + '+m.group(3),extract)
extract=extract.replace('count += 1','count = count + 1').replace('espStats.eligible += 1','espStats.eligible = espStats.eligible + 1').replace('espStats.scanned += 1','espStats.scanned = espStats.scanned + 1').replace('espStats.noHumanoid += 1','espStats.noHumanoid = espStats.noHumanoid + 1').replace('budget -= 1','budget = budget - 1')
base='''
local vectorMeta={}
function vectorMeta.__sub(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},vectorMeta) end
function vectorMeta.__index(t,k)
 if k=='Magnitude' then return math.sqrt(t.x*t.x+t.y*t.y+t.z*t.z) end
 return rawget(t,k)
end
local function vec(x,y,z)return setmetatable({x=x,y=y,z=z},vectorMeta)end
math.clamp=function(v,lo,hi)return math.max(lo,math.min(hi,v))end
local camera={CFrame={Position=vec(0,0,0)},ViewportSize={X=1000,Y=700}}
function camera:WorldToViewportPoint(pos)return {X=500,Y=350,Z=3},true end
local Workspace={CurrentCamera=camera,Raycast=function()return nil end}
local model={Parent={Name='Terrorists'}, part={Position=vec(10,0,0),Parent=true,IsA=function(_,what) return what=='BasePart' end}, AncestryChanged={Connect=function(self,fn) return {Disconnect=function()end}end}}
function model:FindFirstChild(name)if name=='HumanoidRootPart' or name=='Head' then return self.part end end
function model:FindFirstChildWhichIsA(which)return self.part end
function model:FindFirstChildOfClass(which)return nil end
local guiRoot={Parent=true}
local localplayer={Parent=true,Name='local'}
local enemy={Parent=true,Name='other',DisplayName='ENEMY'}
local Players={GetPlayers=function()return {localplayer,enemy}end}
local humanoid={Health=1,MaxHealth=1,HealthKnown=false}
local c={Living=function(p)if p==enemy then return model,humanoid end end,
 Enemy=function()return true end,HasDrawing=false,Character=function()return {Name='local'}end,
 RandomName=function()return 'mark' end, GetGuiParent=function()return guiRoot end}
local Config={ESPWorldHighlight=false, ESPOverlay=true, ESPEnabled=true,ESPTeam=true,ESPDistance=500,ESPVisibility=false,ESPNames=true,
  ESPHealth=true,ESPRange=true,ESPBox=false,ESPTracer=false}
local LocalPlayer=localplayer
local Enum={RaycastFilterType={Blacklist='Blacklist'},HighlightDepthMode={AlwaysOnTop='AlwaysOnTop'}}
local RaycastParams={new=function()return {}end}
local Color3={fromRGB=function(r,g,b)return {r,g,b}end}
local UDim2={fromOffset=function()return {}end,fromScale=function()return {}end,new=function()return {}end}
local Vector3={new=function()return {}end}
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local Instance={new=function(_,class)
 local obj={ClassName=class,Destroy=function(self)self.Parent=nil;self.Destroyed=true end,
  Remove=function(self)self.Parent=nil end}
 return obj
end}
'''
# typo: function signature Instance.new for dot colon? call Instance.new('Highlight'), definition `function(_,class)` class=nil but no difference
script=base+extract+'''
updateESP()
assert(espStats.scanned==1 and espStats.eligible==1 and espStats.markers==1,'eligible no-Humanoid model should yield an ESP Highlight')
assert(highlights[enemy].model.Parent==model)
assert(highlights[enemy].overlay.Visible,'2D marker should render even if 3D Highlight is culled')
assert(highlights[enemy].model.Enabled == false,'no heavy 3D highlight by default')
assert(highlights[enemy].label.Text=='ENEMY\\n10 studs',highlights[enemy].label.Text)
Config.ESPEnabled=false
updateESP()
assert(next(highlights)==nil,'disabling ESP releases all highlight resources')
'''
def test_visual_update_without_humanoid():
    LuaRuntime().run(script)

import unittest
class R215VisualTest(unittest.TestCase):
    def test_model_esp_creation_and_teardown(self):
        test_visual_update_without_humanoid()
