"""R2.12 actual extracted Luau source tests under Lua 5.4 mocks.
No claim of Roblox-server or Android-executor integration validation.
"""
import unittest
from pathlib import Path
from test_wind_router import LuaRuntime
from test_r210_state import SETUP, SCENE, TARGET
from test_r25_stability import to_lua54

ROOT=Path(__file__).resolve().parents[1]
FS=(ROOT/'src/ForsakenCore.luau').read_text()
ADAPTER=(ROOT/'src/WindAdapter.luau').read_text()

PROBE=ADAPTER[ADAPTER.index('        local runtimeProbeBusy = false'):ADAPTER.index('        debugPage:AddToggle("wind_debug"')]

MOCK=r'''
local buttons={}
local messages={}
local lastCopied=nil
local cnt, active=0,nil
local camera={FieldOfView=70}
local person={Name='Tester',Health=100}
local character={Name='PlayerRig'}
function character:FindFirstChildOfClass(s) if s=='Humanoid' then return person end end
local user={Character=character}
local run={Heartbeat={Connect=function(_,cb)
 active=cb
 return {Disconnect=function()active=nil end}
end}}
game={PlaceId=5041144419,GetService=function(self,k)
 if k=='RunService' then return run end
 if k=='Players' then return {LocalPlayer=user} end
 error('missing '..k)
end}
local world={CurrentCamera=camera}
local bridge={Active=true}
function bridge:FeatureHealth()return 'SCP: role=active' end
function bridge:Notify(record)table.insert(messages, record)end
local debugPage={AddButton=function(self,record)buttons[record.Title]=record.Callback end}
local env={}
local task={}
function task.spawn(fn) fn()end
function task.wait(t)
 if t==0.3 then
  for i=1,3 do if active then active() end end
 end
end
function setclipboard(s)lastCopied=s end
'''

class RuntimeR212(unittest.TestCase):
    def test_forsaken_highlight_owned_by_target_model(self):
        code=SETUP+SCENE+TARGET+r'''
__callbacks.FsKillerESP(true)
__runHeartbeat(0.3)
local a,b=__markers()
assert(a==1 and b==0)
assert(__active()>0)
__buttons['检查游戏结构']()
local text=__bridge.notifications[#__bridge.notifications].Content
assert(text:find('候选=1',1,true),text)
assert(text:find('范围内=1',1,true),text)
__buttons['卸载 Forsaken 功能']()
'''
        LuaRuntime().run(to_lua54(code))
        self.assertIn('highlight.Parent = model',FS)
        self.assertNotIn('highlight.Parent = gui',FS)

    def test_client_probe_returns_fov_and_cleans_signal(self):
        code=MOCK+PROBE+r'''
assert(type(buttons['运行客户端自检（短暂检测相机FOV）'])=='function')
buttons['运行客户端自检（短暂检测相机FOV）']()
assert(active==nil,'Heartbeat listener leaked')
assert(camera.FieldOfView==70,'camera FOV not restored')
assert(bridge.RuntimeProbeLast:find('HeartbeatFrames/0.3s=3',1,true))
assert(bridge.RuntimeProbeLast:find('CameraWriteImmediate=true',1,true))
assert(bridge.RuntimeProbeLast:find('CameraWriteAfter0.18s=true',1,true))
assert(bridge.RuntimeProbeLast:find('GameFeatureHealth=SCP: role=active',1,true))
buttons['复制客户端自检结果']()
assert(lastCopied==bridge.RuntimeProbeLast)
'''
        LuaRuntime().run(code)

    def test_probe_handles_missing_camera_without_crashing(self):
        code=MOCK+PROBE+r'''
world.CurrentCamera=nil
buttons['运行客户端自检（短暂检测相机FOV）']()
assert(bridge.RuntimeProbeLast:find('CameraAvailable=false',1,true))
assert(active==nil)
'''
        LuaRuntime().run(code)

    def test_probe_recovers_from_frame_error(self):
        code=MOCK+PROBE+r'''
task.wait=function()error('fixture failure')end
buttons['运行客户端自检（短暂检测相机FOV）']()
assert(active==nil,'probe should disconnect Heartbeat on failure')
assert(bridge.RuntimeProbeLast:find('ProbeError=',1,true))
'''
        LuaRuntime().run(code)

    def test_built_every_game_core_includes_probe(self):
        core=(ROOT/'dist/Vortexion_Core.lua').read_text()
        self.assertIn('运行客户端自检（短暂检测相机FOV）',core)
        for game in ['Forsaken','BloxStrike','AOTR_Lobby','AOTR_Battle','SCP']:
            self.assertIn('return GameRouter.Run', (ROOT/'dist'/f'Vortexion_Module_{game}.lua').read_text())

if __name__=='__main__': unittest.main()
