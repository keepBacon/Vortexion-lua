"""R221 bridge runtime smoke with Lua5.4 Roblox UI mocks + source contract checks.
Not a claim of Android executor or actual Roblox GUI verification.
"""
from pathlib import Path
import hashlib
import json
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parent))
from test_wind_router import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

MOCK = r'''
table.clear = function(a) for k in pairs(a) do a[k]=nil end end
__env={}; getgenv=function() return __env end
warn=function() end
local function sig()
    local o={ callbacks={} }
    function o:Connect(f)
        table.insert(self.callbacks,f)
        return {Disconnect=function()end}
    end
    function o:Fire(...) for _,f in ipairs(self.callbacks) do f(...) end end
    return o
end
local function vec(x,y) return {X=x,Y=y} end
Vector2={new=vec}
UDim2={fromOffset=function(x,y)return {x=x,y=y} end,new=function(...) return {...} end}
Instance={new=function(kind)return {ClassName=kind,Scale=1} end}
Color3={fromRGB=function(r,g,b)return {R=r/255,G=g/255,B=b/255} end}
typeof=function(o)if type(o)=='table' and o.R then return 'Color3' end return type(o) end
Enum={TextTruncate={AtEnd='AtEnd'}}
task={wait=function()end,defer=function(fn)fn()end,delay=function(sec,fn)fn()end}
__fps=sig();__viewport=vec(390,844)
local camera={ViewportSize=__viewport,GetPropertyChangedSignal=function(self,key)return sig()end}
__workspace={CurrentCamera=camera,GetPropertyChangedSignal=function(self,key)return sig()end}
__uis={TouchEnabled=true}
__gui={GetGuiInset=function()return vec(0,24),vec(0,8) end,GetPropertyChangedSignal=function(self,key)return sig()end}
__run={Heartbeat=__fps}
__http={JSONEncode=function(_,v)return '{}' end,JSONDecode=function(_,v)return {} end}
game={GameId=6331902150,PlaceId=18687417158,JobId='test',GetService=function(self,service)
    local t={UserInputService=__uis,Workspace=__workspace,GuiService=__gui,RunService=__run,HttpService=__http}
    assert(t[service],service)
    return t[service]
end}
local function makeControl(data)
    local c={Value=data.Default,Items=data.Items,Callback=data.Callback}
    if data.Callback then data.Callback(c.Value) end
    function c:Get() return self.Value end
    function c:Set(value)
        self.Value=value
        if self.Callback then self.Callback(value) end
    end
    function c:Refresh(new) self.Items=new end
    return c
end
local function newSection()
    local sec={}
    for _,kind in ipairs({'Toggle','Slider','Dropdown','Textbox'}) do sec[kind]=function(self,opts)return makeControl(opts) end end
    function sec:Button(data)return data end
    function sec:Label(text)
        local o={text=text}
        function o:SetText(v)self.text=v end
        function o:Colorpicker(opts)return makeControl(opts) end
        return o
    end
    return sec
end
__ui={Holder={Instance={}},Theme={},Flags={},OpenFrames={}}
function __ui:Window(data)
    local n={Pages={},Items={MainFrame={Instance={}},LeftTabs={Instance={}},Content={Instance={}}}}
    function n:Category(name)end
    function n:Page(args)
        local pg={Active=#self.Pages==0,Items={Inactive={Instance={}},Text={Instance={}}}}
        function pg:Section(args)return newSection() end
        function pg:Turn(v)self.Active=v end
        table.insert(self.Pages,pg)
        return pg
    end
    function n:Init()self.initialized=true end
    function n:SetOpen(value)self.open=value end
    return n
end
function __ui:ChangeTheme(key,v)self.Theme[key]=v end
function __ui:Notification(opts)__notice=opts end
function __ui:Unload()__unloaded=true end
local build=(function()
<<ADAPTER>>
end)()
local bridge=build(__ui,{Name='Vortexion',ServerSwitchFactory=function(tab,notify)
    assert(tab.AddDropdown and tab.AddParagraph,'common tab API')
    return {Stop=function() __stopped=true end}
end})
assert(bridge.Active and bridge.VisualHz==30)
local window=bridge:CreateWindow({Title='Forsaken'})
assert(window.Native.initialized,'Init was not scheduled')
local page=window:AddTab({Title='Gameplay'})
local calls,values=0,{}
local toggle=page:AddToggle('fors_speed',{Title='Enable',Default=false,Callback=function(v)calls=calls+1;values[#values+1]=v end})
assert(calls==1 and toggle.Value==false and toggle:GetValue()==false,'default callback once')
local registered=0
local listener=function(v)registered=registered+1 end
toggle:OnChanged(listener)
assert(registered==1,'listener initial')
assert(toggle:SetValue(true) and toggle.Value==true)
assert(calls==2 and registered==2,'native:Set should not double-dispatch')
toggle.Native:Set(false)
assert(toggle.Value==false and calls==3,'tap path must reach business callback')
toggle.Native.Value=true -- simulate missed native event
assert(bridge:ReconcileGameplayOptions()==1 and toggle.Value==true,'missed toggle state reconciliation')
local slider=page:AddSlider('speed',{Title='Speed',Min=1,Max=3,Default=2,Rounding=1})
assert(slider:SetValue(99) and slider.Value==3,'clamp slider')
local dropdown=page:AddDropdown('mode',{Title='Mode',Values={'A','B'},Default='A'})
assert(dropdown:SetValues({'X','Y'}) and dropdown.Value=='X','refresh dynamic dropdown')
local text=page:AddInput('name',{Title='Name',Default='initial'})
assert(text:SetValue('new') and text.Value=='new','textbox updates')
window:SelectTab(1)
assert(page.Native.Active,'page selectable')
local first=bridge.EffectiveScale
assert(first and first>0 and first<=1.2)
__workspace.CurrentCamera.ViewportSize=vec(844,390)
bridge:FitViewport()
assert(bridge.EffectiveScale>0 and bridge.EffectiveScale~=first,'orientation fit')
local landscape=bridge.EffectiveScale
__workspace.CurrentCamera.ViewportSize=vec(0/0,390)
bridge:FitViewport()
assert(bridge.EffectiveScale==landscape,'NaN viewport must not alter UIScale')
__workspace.CurrentCamera.ViewportSize=vec(0,0)
bridge:FitViewport()
assert(bridge.EffectiveScale==landscape,'zero viewport must not alter UIScale')
__workspace.CurrentCamera.ViewportSize=vec(844,390)
bridge:FitViewport()
assert(bridge.Options.nl_touch_probe and bridge.Options.nl_accent and bridge.GetDiagnostics())
bridge.Options.nl_touch_probe:SetValue(true)
assert(bridge.LastTouchProbe and bridge.LastTouchProbe:find('true'),'tap diagnostic response')
assert(bridge.RefreshDiagnostics and bridge.LastViewport,'live diagnostic status')
bridge:RegisterFeatureHealth('example',function()return 'ok' end)
assert(bridge:FeatureHealth():find('example'),'health integration')
assert(bridge:FeatureTrace():find('fors_speed'),'trace integration')
assert(bridge:GetVisualInterval(0.01)>=1/30)
bridge:Destroy()
assert(__unloaded and __stopped and not bridge.Active,'cleanup')
assert(__env.VortexionWindBridge==nil,'global bridge teardown')
'''

class NeverloseMobileR221(unittest.TestCase):
    def test_adapter_mock_runtime(self):
        source=(ROOT/'src/NeverloseAdapter.luau').read_text(encoding='utf-8')
        # This one adapter is standard Lua 5.4 compatible to permit a mocked runtime.
        self.assertNotIn('+=',source)
        LuaRuntime().run(MOCK.replace('<<ADAPTER>>',source))

    def test_vendor_touch_and_mobile_guards(self):
        source=(ROOT/'vendor/Neverlose/Source.lua').read_text(encoding='utf-8')
        self.assertIn('AutomaticCanvasSize = Enum.AutomaticSize.Y',source)
        self.assertIn('ScrollingDirection = Enum.ScrollingDirection.Y',source)
        self.assertIn('IgnoreGuiInset = true',source)
        self.assertIn('Window:SetOpen(false) -- minimize',source)
        self.assertIn('IsMouseOverFrame = function(self, Frame, Input)',source)
        self.assertIn('Items["Toggle"]:Connect("Activated"',source)
        self.assertIn('if IsMobile then Data.Columns = 1 end',source)
        self.assertIn('IsMobile and 22 or 7',source)
        self.assertIn('IsMobile and 40 or 20',source)
        self.assertNotIn('Items["MainFrame"]:MakeResizeable(',source)

    def test_unmodified_gameplay_sources_intact(self):
        import zipfile
        upload=Path('/mnt/data/Vortexion_R220_合并R219完整源码.zip')
        if not upload.exists():self.skipTest('source archive not mounted')
        # R222 intentionally changes three BloxStrike gameplay modules;
        # all other game modules must remain byte-identical to R220.
        with zipfile.ZipFile(upload) as z:
            for file in (ROOT/'src').glob('*.*lua*'):
                if file.name in ('NeverloseAdapter.luau','WindAdapter.luau','StarlightAdapter.luau','BloxStrikeCore.luau','BloxStrikeCombat.luau','BloxStrikeCommon.luau','BloxStrikeVisual.luau'):continue
                original='wind-project/src/'+file.name
                self.assertEqual(file.read_bytes(),z.read(original),file.name)

    def test_all_outputs_bundle_neverlose(self):
        manifest=json.loads((ROOT/'dist/build-manifest.json').read_text())
        self.assertEqual(manifest['project_name'],'Vortexion Neverlose')
        self.assertEqual(len(manifest['bundles']),7)
        self.assertEqual(len(manifest['modular_bundles']),6)
        self.assertEqual(manifest['unified_entry'],'dist/Vortexion_Neverlose.lua')
        core=(ROOT/'dist/Vortexion_Core.lua').read_text()
        self.assertIn('VORTEXION · NEVERLOSE',core)
        self.assertIn('VortexionNeverloseBridge',core)
        self.assertNotIn('function p.New(r,u,v)',core) # previous minified WindUI creator

if __name__=='__main__':unittest.main()
