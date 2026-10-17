"""R227 local native-API smoke and static layout assertions; not Roblox Android verification."""
from pathlib import Path
import unittest,sys,json,hashlib
sys.path.insert(0,str(Path(__file__).parent))
from test_wind_router import LuaRuntime
R=Path(__file__).resolve().parents[1]
MOCK=r'''
table.clear=function(t)for k in pairs(t)do t[k]=nil end end
getgenv=function() return _G end
warn=function()end
local function signal()
 local o={listeners={}}
 function o:Connect(fn)table.insert(self.listeners,fn)return {Disconnect=function()end}end
 function o:Fire(...)for _,fn in ipairs(self.listeners)do fn(...)end end
 return o
end
local function vec(x,y)return {X=x,Y=y}end
Vector2={new=vec}
UDim2={fromOffset=function(x,y)return {X={Offset=x},Y={Offset=y}}end}
Color3={fromRGB=function(r,g,b)return {R=r/255,G=g/255,B=b/255}end}
typeof=function(t)if type(t)=='table' and t.R then return 'Color3' end return type(t)end
Enum={KeyCode={RightControl=9},UserInputType={Touch=1,MouseButton1=2,MouseMovement=3},Font={GothamBold=4}}
Instance={new=function(kind)return {Kind=kind,MouseButton1Click=signal(),InputBegan=signal(),InputChanged=signal(),InputEnded=signal()}end}
task={wait=function()return end,defer=function(fn)fn()end}
__viewport=vec(1000,600)
local camera={ViewportSize=__viewport,GetPropertyChangedSignal=function()return signal()end}
__workspace={CurrentCamera=camera,GetPropertyChangedSignal=function()return signal()end}
__uis={TouchEnabled=true,InputChanged=signal(),InputEnded=signal()}
__gui={GetGuiInset=function()return vec(0,20),vec(0,0)end,GetPropertyChangedSignal=function()return signal()end}
__run={Heartbeat=signal()}
__http={JSONEncode=function()return '{}'end,JSONDecode=function()return {}end}
game={GetService=function(_,name)
 local services={Workspace=__workspace,UserInputService=__uis,GuiService=__gui,RunService=__run,HttpService=__http}
 return assert(services[name],name)
end}
local function newControl(def,callback)
 local c={Value=def,Callback=callback}
 function c:Set(v)self.Value=v;if self.Callback then self.Callback(v) end end
 function c:Get()return self.Value end
 function c:Refresh(new)self.Items=new end
 return c
end
local function section(title)
 local s={Title=title,Created={}}
 local function add(k,name,c)
  local ctrl=newControl(nil,c)
  s.Created[#s.Created+1]={kind=k,label=name,control=ctrl}
  return ctrl
 end
 function s:Toggle(name,cb)return add('Toggle',name,cb) end
 function s:Slider(name,low,high,value,cb)local control=add('Slider',name,cb);control.Value=value;return control end
 function s:Dropdown(name,values,cb)local control=add('Dropdown',name,cb);control.Items=values;return control end
 function s:TextBox(name,cb)return add('Input',name,cb) end
 function s:Colorpicker(name,value,cb)local control=add('Colorpicker',name,cb);control.Value=value;return control end
 function s:Paragraph(name,txt)local r={title=name,text=txt};function r:SetDesc(v)self.text=v end;return r end
 function s:Button(name,callback)return {Title=name,Click=callback}end
 return s
end
local root={Visible=true}
function root:FindFirstChild()return nil end
local screen={Destroy=function()_G.__destroyed=true end,FindFirstChild=function()return nil end}
__library={MainFrame=root,Root=screen}
__groups={}
function __library:Window(c)
 assert(c.Title=='VORTEXION' and c.External.KeySystem==false,'wrong vendor window API')
 local w={}
 function w:TSection(name)
  local group={Name=name,Tabs={}}
  table.insert(__groups,group)
  function group:Tab(label)
    local page={Title=label,Sections={}}
    table.insert(self.Tabs,page)
    function page:Section(name)
     local sec=section(name)
     table.insert(self.Sections,sec)
     return sec
    end
    function page:Select()_G.__selected=self.Title end
    return page
  end
  return group
 end
 return w
end
function __library:Notify(v)_G.__notify=v end
function __library:VisMain(show)root.Visible=show end
local build=(function()
<<ADAPTER>>
end)()
local bridge=build(__library,{ServerSwitchFactory=function(tab)
 assert(tab.AddToggle and tab.AddInput)
 return {Stop=function()_G.__stopped=true end}
end})
local win=bridge:CreateWindow({Title='Vortexion'})
assert(bridge.Active and bridge.SettingsTabs['调试'],'settings created')
local pg=win:AddTab({Title='ESP'})
local calls={}
local one=pg:AddToggle('esp_enabled',{Title='ESP 开关',Default=false,Callback=function(v)calls[#calls+1]=v end})
assert(#calls==1 and one.Value==false,'initial dispatch once')
one.Native:Set(true)
assert(one:GetValue() == true and #calls==2,'native tap dispatch')
assert(one:SetValue(false) and #calls==3,'programmatic SetValue')
local slider=pg:AddSlider('range',{Title='距离',Min=0,Max=100,Default=35,Rounding=1})
assert(slider.Value==35 and slider:SetValue(999) and slider.Value==100,'clamp')
local modes=pg:AddDropdown('style',{Title='ESP样式',Values={'3D','2D'},Default='3D'})
assert(modes:SetValues({'框','边缘'}) and modes.Value=='框','dynamic items refresh')
local text=pg:AddInput('config',{Title='名称',Default='preset'})
assert(text:SetValue('another') and text:GetValue()=='another','input control')
local color=pg:AddColorpicker('color',{Title='颜色',Default=Color3.fromRGB(3,5,8)})
assert(color.Kind=='Colorpicker','color control')
for n=1,19 do pg:AddToggle('ex'..n,{Title='更多功能'..n,Default=false}) end
assert(#pg.Sections>=3,'grouped sections retained')
assert(pg.Sections[1].Title=='Main','original section order')
win:SelectTab(1)
assert(__selected=='ESP','page select')
assert(bridge.LastViewport and bridge.LastViewport:find('原生双列'),'native two-column viewport')
local first=bridge.LastViewport
__workspace.CurrentCamera.ViewportSize=vec(450,950)
bridge:FitViewport()
assert(bridge.LastViewport~=first,'viewport resize')
bridge:Destroy()
assert(__destroyed and __stopped and not bridge.Active,'cleanup')
assert(_G.VortexionWindBridge==nil,'global cleanup')
'''
class NativeNeverloseR227(unittest.TestCase):
 def test_bridge_native_api_runtime(self):
  adapter=(R/'src/NeverloseAdapter.luau').read_text()
  LuaRuntime().run(MOCK.replace('<<ADAPTER>>',adapter))
 def test_source_parses_under_lua54(self):
  for file in ['src/NeverloseAdapter.luau','vendor/Neverlose/Source.lua']:
   source=(R/file).read_text()
   LuaRuntime().run('local function compileOnly()\n'+source+'\nend')
 def test_original_dual_column_intact(self):
  v=(R/'vendor/Neverlose/Source.lua').read_text()
  a=(R/'src/NeverloseAdapter.luau').read_text()
  self.assertIn('SectionHolder1',v)
  self.assertIn('SectionHolder2',v)
  self.assertIn('nativeSectionCount % 2 == 1',v)
  self.assertNotIn('if UserInputService.TouchEnabled then\n                        Section.Parent = SectionHolder1',v)
  self.assertIn('local sectionLimit=8',a)
  self.assertIn('203*applied',a)
  self.assertNotIn('Columns=mobile and 1',a)
  self.assertIn('SliderFrame.InputBegan:Connect(begin)',v)
  self.assertIn('input.UserInputType == Enum.UserInputType.Touch',v)
 def test_business_modules_identical_to_r226(self):
  old=Path('/mnt/data/vortexion_r226_work/wind-project/src')
  for f in (R/'src').glob('*.lua*'):
   if f.name == 'NeverloseAdapter.luau':continue
   self.assertEqual(f.read_bytes(),(old/f.name).read_bytes(),f.name)
 def test_release_manifest_parity(self):
  manifest=json.loads((R/'dist/build-manifest.json').read_text())
  self.assertEqual(len(manifest['bundles']),7)
  self.assertEqual(len(manifest['modular_bundles']),6)
  for name,d in manifest['bundles'].items():
   p=R/'dist'/name
   self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),d['sha256'])
if __name__=='__main__':unittest.main()
