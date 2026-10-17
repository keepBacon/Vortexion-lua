"""R229 mock UI lifecycle tests; not an Android Roblox test."""
import json
import hashlib
import unittest
from pathlib import Path
from test_wind_router import LuaRuntime
from test_r227_native_ui import MOCK as VENDOR_MOCK

ROOT = Path(__file__).resolve().parents[1]

EMERGENCY_MOCK = r'''
warn=function(...)end
gethui=function()return nil end
local function signal()
 local sig={}
 function sig:Connect(fn)self.fn=fn;return {Disconnect=function()end}end
 function sig:Fire(...)if self.fn then self.fn(...)end end
 return sig
end
local function create(kind)
 local obj={ClassName=kind,AbsolutePosition={X=0,Y=0},AbsoluteSize={X=75,Y=29},Visible=true,
 InputBegan=signal(), InputChanged=signal(), InputEnded=signal(), MouseButton1Click=signal(),FocusLost=signal()}
 function obj:FindFirstChild()return nil end
 function obj:FindFirstChildOfClass(n) return nil end
 function obj:WaitForChild()return self end
 function obj:Destroy()self.Parent=nil;self.destroyed=true end
 return obj
end
Instance={new=create}
UDim={new=function(...)return {...}end}
UDim2={new=function(...)return {...}end,fromOffset=function(x,y)return {X={Offset=x},Y={Offset=y}}end,fromScale=function(x,y)return {X={Scale=x},Y={Scale=y}}end}
Vector2={new=function(x,y)return {X=x,Y=y}end}
Color3={fromRGB=function(r,g,b)return {R=r,G=g,B=b}end}
Enum={Font={Gotham=1,GothamMedium=2},TextXAlignment={Left=1},TextTruncate={AtEnd=1,None=2},
 AutomaticSize={Y=1},SortOrder={LayoutOrder=1},UserInputType={Touch=1,MouseButton1=2,MouseMovement=3}}
local core=create('CoreGui')
local player={FindFirstChildOfClass=function()return create('PlayerGui')end}
game={GetService=function(_,name)if name=='CoreGui'then return core elseif name=='Players'then return {LocalPlayer=player} elseif name=='UserInputService'then return {}end end}
local src=(function()
<<EMERGENCY>>
end)()
local lib={}
local groups=src(lib,'simulated native constructor crash')
assert(lib.Root and lib.MainFrame and type(groups.TSection)=='function')
local a=groups:TSection('游戏')
local page=a:Tab('SCP','rbxassetid://123')
local sec1,sec2=page:Section('Main'),page:Section('World ESP')
local hits={}
local toggle=sec1:Toggle('ESP',function(v)table.insert(hits,v)end)
local drop=sec2:Dropdown('Style',{'3D','2D'},function(v)table.insert(hits,v)end)
local slider=sec1:Slider('Distance',1,100,30,function(v)table.insert(hits,v)end)
local name=sec2:TextBox('Name',function(v)table.insert(hits,v)end)
local color=sec1:Colorpicker('Color',Color3.fromRGB(1,2,3),function(v)table.insert(hits,v)end)
local p=sec2:Paragraph('Note','Some text')
p:SetDesc('new text')
sec1:Button('Test',function()table.insert(hits,'click')end)
assert(type(toggle.Set)=='function' and type(toggle.Get)=='function')
toggle:Set(true);assert(toggle:Get()==true)
drop:Set('2D');assert(drop:Get()=='2D')
drop:Refresh({'a','b'});assert(drop:Get()=='a')
slider:Set(500);assert(slider:Get()==100)
name:Set('SCP');assert(name:Get()=='SCP')
color:Set(Color3.fromRGB(3,4,5));assert(type(color:Get())=='table')
page:Select(); assert(#hits>=6)
assert(page.Left and page.Right,'native two-column order lost')
'''

class R229StartupRecovery(unittest.TestCase):
    def test_emergency_gui_creates_controls_and_double_columns(self):
        source=(ROOT/'src/NeverloseEmergency.luau').read_text()
        LuaRuntime().run(EMERGENCY_MOCK.replace('<<EMERGENCY>>',source))

    def test_adapter_native_failure_enters_emergency_and_callbacks_work(self):
        # Reuse original robust R227 mock but force native Window failure,
        # and give the emergency adapter an equivalent mock native API.
        code=VENDOR_MOCK
        old='local build=(function()\n<<ADAPTER>>\nend)()'
        self.assertIn(old, code)
        injection='''
        local originalWindow=__library.Window
        function __library:Window()error('Simulated unsupported UI call')end
        EmergencyWindowFactory=function(lib,cause)
            assert(type(cause)=='string' and cause:find('Simulated unsupported UI call'))
            return originalWindow(lib,{Title='VORTEXION',External={KeySystem=false}})
        end
        '''
        code=code.replace(old,injection+old)
        code=code.replace("assert(bridge.Active and bridge.SettingsTabs['调试'],'settings created')",
                          "assert(bridge.Active and bridge.SettingsTabs['调试'],'settings created')\nassert(bridge.UIBackend=='EmergencyNeverlose' and type(bridge.NativeError)=='string')")
        LuaRuntime().run(code.replace('<<ADAPTER>>',(ROOT/'src/NeverloseAdapter.luau').read_text()))

    def test_build_routes_and_manifest_complete(self):
        m=json.loads((ROOT/'dist/runtime-manifest.json').read_text())
        self.assertIn('r230',m['build_tag'], 'R229 startup recovery retained in R230 manifest')
        self.assertEqual(set(m['modules']),{'Forsaken','BloxStrike','SCP','AOTR_Lobby','AOTR_Battle'})
        for entry in [m['core'],*m['modules'].values()]:
            raw=(ROOT/entry['path']).read_bytes()
            self.assertEqual(entry['bytes'],len(raw))
            self.assertEqual(entry['sha256'],hashlib.sha256(raw).hexdigest())
        for name in ['SCP','BloxStrike','Forsaken','AOTR_Lobby','AOTR_Battle']:
            module=(ROOT/'dist'/f'Vortexion_Module_{name}.lua').read_text()
            self.assertIn('GameRouter.Run',module)
            self.assertIn('local entry = function()',module)
        core=(ROOT/'dist/Vortexion_Core.lua').read_text()
        self.assertIn('EmergencyWindowFactory',core)
        self.assertIn('Both native and emergency UI failed',core)

    def test_loader_preserves_original_ui_error(self):
        code=(ROOT/'loader.lua').read_text()
        self.assertIn('env.VortexionBootError or bridge.BootError',code)
        self.assertIn('Neverlose bridge active but no valid window. Root cause:',code)
        self.assertIn('2.19.0-r229-startup-recovery',code)

if __name__=='__main__':unittest.main()
