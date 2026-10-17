"""R228 design and SCP ESP behavior contracts; mock runtime is not Android Roblox."""
import unittest
from pathlib import Path
from test_wind_router import LuaRuntime
from test_r226_native_esp_runtime import transpile,F
ROOT=Path(__file__).resolve().parents[1]
class R228(unittest.TestCase):
 def test_native_icon_and_dual_column(self):
  src=(ROOT/'vendor/Neverlose/Source.lua').read_text()
  bridge=(ROOT/'src/NeverloseAdapter.luau').read_text()
  self.assertIn('function Tabs:Tab(title, iconAsset)',src)
  self.assertIn('TabIcon.Name = "TabIcon"',src)
  self.assertIn('TabIcon.Image = iconAsset',src)
  self.assertIn('Section.Parent = (nativeSectionCount % 2 == 1) and SectionHolder1 or SectionHolder2',src)
  self.assertIn('SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize")',src)
  self.assertIn('syncNativeCanvas()',src)
  self.assertIn('SectionTitle.Size = UDim2.new(0, 250, 0, 23)',src)
  self.assertIn('DropdownTitle.Size = UDim2.new(0, 166, 0, 20)',src)
  self.assertIn('ToggleTitle.Size = UDim2.new(0, 194, 0, 20)',src)
  self.assertIn('pageIcon(pageName)',bridge)
  self.assertIn('fit*1.08*uiScale',bridge)
  self.assertIn('Color3.fromRGB(103, 181, 191)',src)
  self.assertNotIn('function Tabs:Tab(title)\n',src)
 def test_scp_registration(self):
  src=(ROOT/'src/SCPCore.luau').read_text()
  for key in ('SCPESPAlpha3D','SCPESPAlpha2D','SCPESPJobColor','SCPESPJobZH','SCPESPNameFont','SCPESPJobFont','SCPESPBoxWidth','SCPESPLabelOffset','SCPESPDistance','SCPESPHealth','SCPESPMaxTargets'):
   self.assertIn(key,src)
  self.assertIn('SCPESPColorSCP',src)
 def test_role_and_render_config_applied(self):
  code=(ROOT/'src/SCPESP.luau').read_text()
  code=transpile(code)
  fixture=F.replace('local player={Name=\'Enemy\',Team={Name=\'Chaos Insurgency\'}}', '''local player={Name='Enemy',Team={Name='Chaos Insurgency',TeamColor={Color=Color3.fromRGB(210,63,79)}}}
function player:GetAttribute(k)return nil end''')
  fixture=fixture.replace("Enum={Font={GothamBold='GothamBold'},ApplyStrokeMode={Border='Border'}}", "Enum={Font={GothamBold='GothamBold'},ApplyStrokeMode={Border='Border'},TextTruncate={AtEnd='AtEnd'}}\ntypeof=function(v) if type(v)=='table' and v.R then return 'Color3' end return type(v) end")
  fixture=fixture.replace('UDim2={fromScale=', 'UDim2={new=function(...)return {...}end,fromScale=')
  tail='''
local esp=(function() '''+code+''' end)()(common)
esp.Config.Enabled=true
esp.Config.ShowJob=true
esp.Config.NameSize=19
esp.Config.JobSize=16
esp.Config.Transparency3D=.6
esp.Config.Transparency2D=.37
esp.Config.ShowDistance=true
esp.Config.ShowHealth=true
esp:Update(.2)
assert(esp.Stats.Visible==1)
local first3d
for _,v in ipairs(instances) do
 if v.ClassName=='BoxHandleAdornment' then first3d=v;break end
end
assert(first3d and first3d.Transparency==.6)
local name,job,meta
for _,v in ipairs(instances) do
 if v.Name=='ESPName' then name=v elseif v.Name=='ESPJob' then job=v elseif v.Name=='ESPMeta' then meta=v end
end
assert(name and name.TextSize==19 and name.Text=='Enemy')
assert(job and job.TextSize==16)
assert(job.TextColor3.R>0.7 and job.TextColor3.G<0.4, 'live game team color')
assert(meta and meta.Text:find('studs') and meta.Text:find('HP'))
esp.Config.Style='2D'
esp:Update(.2)
local stroke
for _,v in ipairs(instances) do if v.ClassName=='UIStroke' then stroke=v end end
assert(stroke and stroke.Transparency==.37)
esp.Config.NameSize=12
esp.Config.JobSize=22
esp:Update(.2)
assert(name.TextSize==12 and job.TextSize==22)
esp:Cleanup()
assert(first3d.Destroyed)
'''
  LuaRuntime().run(fixture+tail)
if __name__=='__main__':unittest.main()
