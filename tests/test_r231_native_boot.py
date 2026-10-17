"""R231: reproduce the Android constructor failure in the vendored native UI.

These tests use the actual vendored SystemT and window source, not a fake
Neverlose implementation; the host is a minimal Lua stub, not Roblox Android.
"""
import re
import json
import hashlib
import unittest
from pathlib import Path
from test_wind_router import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / 'vendor/Neverlose/Source.lua'

MOCK = r'''
getgenv=function()return _G end
warn=function(...)end
spawn=function(fn)end
task={wait=function()return end,spawn=function(fn)end,defer=function(fn)end,delay=function(_s,fn)end}
wait=function()return end
math.clamp=function(x,l,h)return math.max(l,math.min(h,x))end
function table.find(t,x)for i,v in ipairs(t)do if v==x then return i end end end
local function signal()
 return {Connect=function(self,fn)return {Disconnect=function()end} end,Wait=function()end}
end
local fakeMethods={}
local function instance(kind)
 local obj={ClassName=kind,Visible=true,AbsoluteSize={X=100,Y=100},AbsolutePosition={X=0,Y=0},
   AbsoluteContentSize={X=0,Y=0},Text='',Image='',UserId=3}
 local mt={}
 function mt.__index(t,k)
  if k=='GetPropertyChangedSignal' then return function()return signal()end end
  if k=='FindFirstChild' or k=='FindFirstChildOfClass' or k=='WaitForChild' then return function()return nil end end
  if k=='GetChildren' or k=='GetDescendants' or k=='GetPlayers' then return function()return {}end end
  if k=='IsA' then return function(self,ty)return ty==self.ClassName or ty=='GuiObject' end end
  if k=='Destroy' then return function(self)self.Destroyed=true end end
  if k=='GetMouse' then return function()return instance('Mouse')end end
  if k=='GetUserThumbnailAsync' then return function()return '' end end
  if k=='GetNameFromUserIdAsync' then return function()return 'test' end end
  if k=='GenerateGUID' then return function()return 'AB123'end end
  if k=='JSONEncode' then return function()return '{}'end end
  if k=='JSONDecode' then return function()return {}end end
  if k=='Create' then return function()return {Play=function()end,Completed=signal()}end end
  if k=='GetGuiInset' then return function()return {X=0,Y=0},{X=0,Y=0}end end
  if k=='GetService' then return function(self,n)
    if n=='Players' then return __players end
    return instance(n)
  end end
  local s=k:find('Mouse',1,true) or k:find('Input',1,true) or k=='Changed' or k=='FocusLost' or k=='ChildAdded'
  if s then local v=signal();rawset(t,k,v);return v end
  if k=='TextBounds' then return {X=100,Y=20} end
  if k=='Transparency' then return 0 end
  if k=='AbsoluteCanvasSize' then return {X=100,Y=100}end
  if k=='Parent' then return nil end
  return nil
 end
 setmetatable(obj,mt)
 return obj
end
local function value(...)
 local args={...}
 local mt={}
 mt.__index=function(t,k)if k=='X' then return {Offset=10,Scale=0}end if k=='Y' then return {Offset=10,Scale=0}end return 0 end
 mt.__add=function(a,b)return value(1)end;mt.__sub=mt.__add;mt.__mul=mt.__add;mt.__div=mt.__add
 return setmetatable({R=args[1] or 0,G=args[2] or 0,B=args[3] or 0},mt)
end
Color3={fromRGB=value,new=value,fromHSV=value,toHSV=function()return 0,0,0 end}
UDim={new=value};UDim2={new=value,fromOffset=value,fromScale=value};Vector2={new=value};Vector3={new=value}
TweenInfo={new=function()return {}end};NumberSequence={new=value};ColorSequence={new=value};NumberRange={new=value};ColorSequenceKeypoint={new=value};NumberSequenceKeypoint={new=value}
Enum=setmetatable({},{__index=function(self,k)
 local inner=setmetatable({},{__index=function(t,q)return q end})
 rawset(self,k,inner)
 return inner
end})
Instance={new=function(kind)
 if kind=='TextButton' or kind=='TextLabel' or kind=='Frame' or kind=='ImageLabel' or kind=='ScreenGui' then
   _G.__created[kind]=(_G.__created[kind] or 0)+1
 end
 return instance(kind)
end}
__created={}
__players=instance('Players')
__players.LocalPlayer=instance('Player')
__players.LocalPlayer.Name='TestUser'
__players.LocalPlayer.DisplayName='TestUser'
__players.LocalPlayer.UserId=1234
__players.LocalPlayer.PlayerGui=instance('PlayerGui')
__players.LocalPlayer.GetMouse=function()return instance('Mouse')end
__players.LocalPlayer.Character=instance('Model')
__gameServices={}
game={GetService=function(self,k)
 if k=='Players' then return __players end
 if not __gameServices[k] then __gameServices[k]=instance(k)end
 return __gameServices[k]
end}
workspace=instance('Workspace')
workspace.CurrentCamera=instance('Camera')
'''

class NativeConstructorR231(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.src=VENDOR.read_text(encoding='utf-8')

    def test_malformed_toggle_title_reproduced_and_fixed(self):
        # This identifier was nil in SystemT() on all game routes.
        self.assertNotRegex(self.src,r'(?m)^\s+ToggleTitle\.TextTruncate\s*=')
        self.assertIn('SetupSystemToggleTitle.TextTruncate = Enum.TextTruncate.AtEnd',self.src)

    def test_key_system_not_initialized_when_disabled(self):
        self.assertRegex(self.src, r'if Allow_KeySystem then\s+local KeyFrame = Instance\.new\("Frame"\)')
        self.assertRegex(self.src, r'KeyFrame:Destroy\(\)\s+end -- Allow_KeySystem\s+local MainFrame = Instance\.new')

    def test_real_vendor_window_can_construct_without_key_screen(self):
        code=MOCK+'\nlocal library=(function()\n'+self.src+'\nend)()\n'+r'''
assert(type(library.Window)=='function','native constructor missing')
local w=library:Window({Title='VORTEXION',CFG='Vortexion',Key=Enum.KeyCode.RightControl,External={KeySystem=false,Key={}}})
assert(type(w)=='table' and library.MainFrame and library.Root,'native window failed')
assert(__created.ScreenGui>=1,'root missing')
assert(__created.Frame>0,'window absent')
assert(library.SettingsFlags['Remember My Key']==nil,'disabled key UI was still initialized')
local sec=w:TSection('游戏')
local tab=sec:Tab('SCP','rbxassetid://6031097226')
local panel=tab:Section('Main')
local toggle=panel:Toggle('Enable ESP',function()end)
assert(toggle~=nil,'native controls unavailable')
local dropdown=panel:Dropdown('样式',{'2D','3D'},function()end)
local slider=panel:Slider('距离',0,100,50,function()end)
local color=panel:Colorpicker('颜色',Color3.fromRGB(11,22,33),function()end)
local input=panel:TextBox('配置',function()end)
assert(type(toggle.Set)=='function' and dropdown and slider and color and input,'native widgets missing')
assert(pcall(function()toggle:Set(true)end),'native toggle unusable')
'''
        LuaRuntime().run(code)


    def test_every_game_includes_patched_native_window(self):
        dist=ROOT/'dist'
        expected={'Forsaken','BloxStrike','SCP','AOTR_Lobby','AOTR_Battle'}
        core=(dist/'Vortexion_Core.lua').read_text()
        self.assertIn('SetupSystemToggleTitle.TextTruncate = Enum.TextTruncate.AtEnd',core)
        self.assertIn('if Allow_KeySystem then',core)
        self.assertNotIn('ToggleTitle.TextTruncate = Enum.TextTruncate.AtEnd',core.replace('SetupSystemToggleTitle.TextTruncate = Enum.TextTruncate.AtEnd',''))
        runtime=json.loads((dist/'runtime-manifest.json').read_text())
        self.assertEqual(set(runtime['modules']),expected)
        self.assertIn('r231',runtime['build_tag'])
        for entry in [runtime['core'],*runtime['modules'].values()]:
            binary=(ROOT/entry['path']).read_bytes()
            self.assertEqual(len(binary),entry['bytes'])
            self.assertEqual(hashlib.sha256(binary).hexdigest(),entry['sha256'])
        for name in expected:
            script=(dist/f'Vortexion_{name}.lua').read_text()
            self.assertIn('if Allow_KeySystem then',script)
            self.assertIn('SetupSystemToggleTitle.TextTruncate = Enum.TextTruncate.AtEnd',script)

if __name__=='__main__':unittest.main()
