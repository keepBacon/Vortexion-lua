"""RuntimeMonitor lifecycle under Lua 5.4-compatible Roblox mocks, not live device."""
from pathlib import Path
import unittest
from tests.test_wind_router import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class RuntimeMonitorTests(unittest.TestCase):
    def test_off_by_default_and_destroy_cleans_listener_and_hud(self):
        source = (ROOT / "src/RuntimeMonitor.luau").read_text(encoding="utf-8")
        for before, after in (("frames += 1", "frames = frames + 1"),
                              ("accumulator += math.min", "accumulator = accumulator + math.min"),
                              ("samples += 1", "samples = samples + 1"),
                              ("stutterCount += 1", "stutterCount = stutterCount + 1"),
                              ("intervalFrameMs += ms", "intervalFrameMs = intervalFrameMs + ms"),
                              ("intervalFrames += 1", "intervalFrames = intervalFrames + 1")):
            source = source.replace(before, after)
        mock = r'''
local service = {connections={}, DisconnectCount=0}
local heartbeat = {}
function heartbeat:Connect(callback)
    local con={connected=true, callback=callback}
    function con:Disconnect() self.connected=false; service.DisconnectCount=service.DisconnectCount + 1 end
    table.insert(service.connections,con)
    return con
end
service.Heartbeat = heartbeat
local pingCalls, memoryCalls = 0, 0
local playerGui={}
local player = {
    FindFirstChildOfClass=function(self,key) assert(key=='PlayerGui'); return playerGui end,
    GetNetworkPing=function() pingCalls=pingCalls+1; return 0.075 end,
}
local stats = {GetTotalMemoryUsageMb=function() memoryCalls=memoryCalls+1; return 256 end}
game = {GameId=123, PlaceId=456,GetService=function(self,name)
    if name=='RunService' then return service end
    if name=='Players' then return {LocalPlayer=player} end
    if name=='Stats' then return stats end
    error('Unknown service '..name)
end}
Instance={new=function(class)
    local result={ClassName=class,destroyed=false,Destroy=function(self) self.destroyed=true end}
    return result
end}
UDim2={new=function(...) return {...} end,fromOffset=function(...) return {...} end}
UDim={new=function(...) return {...} end}
Vector2={new=function(...) return {...} end}
Color3={fromRGB=function(...) return {...} end}
Enum={Font={Code=1},TextXAlignment={Left=1},TextYAlignment={Center=1}}
setclipboard=function(msg) _G.lastCopy=msg end
local controls={}
local tab={
 AddParagraph=function(self,info) return info end,
 AddToggle=function(self,id,info) controls[id]=info; return info end,
 AddSlider=function(self,id,info) controls[id]=info; return info end,
 AddButton=function(self,info) controls[info.Title]=info; return info end,
}
local bridge={Active=true,Notify=function() end,OnDestroy=function(self,fn) self.destroy=fn end}
'''
        checks = r'''
assert(#service.connections==0, 'inactive monitor must not attach to Heartbeat')
assert(pingCalls==0 and memoryCalls==0)
assert(controls.VortexionPerfHUD and controls.VortexionPerfSampleSeconds)
controls.VortexionPerfHUD.Callback(true)
assert(#service.connections==1 and service.connections[1].connected)
for i=1,65 do service.connections[1].callback(1/60) end
local data=monitor.GetSnapshot()
assert(data.fps>=59 and data.fps<=61)
assert(data.pingMs==75 and data.memoryMb==256)
assert(data.samples==1 and data.minFps>=59 and data.maxFps<=61)
assert(data.avgFrameMs >= 16 and data.avgFrameMs <= 17)
assert(data.peakFrameMs >= 16 and data.peakFrameMs < 17 and data.stutters == 0)
controls['复制性能诊断'].Callback()
assert(lastCopy:find('PlaceId=456',1,true))
assert(lastCopy:find('FrameAvgMs=',1,true) and lastCopy:find('Stutters',1,true))
assert(controls['重置性能采样'])
controls['重置性能采样'].Callback()
local reset = monitor.GetSnapshot()
assert(reset.samples == 0 and reset.stutters == 0 and reset.peakFrameMs == 0)
bridge.destroy()
assert(not service.connections[1].connected and service.DisconnectCount==1)
assert(pingCalls==1 and memoryCalls==1)
controls.VortexionPerfHUD.Callback(true)
assert(#service.connections==1, 'no listener after bridge destroy')
'''
        LuaRuntime().run(mock + '\nlocal factory = (function()\n' + source + '\nend)()\n'
                         + 'local monitor=factory(tab,bridge)\n' + checks)

    def test_adapter_cleanup_includes_adaptive_listener(self):
        s = (ROOT / "src/WindAdapter.luau").read_text(encoding="utf-8")
        self.assertIn('function bridge:GetVisualInterval', s)
        self.assertIn('resetAdaptive()\n        if originalToggleAcrylic', s)
        self.assertIn('wind_adaptive_visual', s)
        self.assertIn('if self.AdaptiveVisualHz then', s)
        self.assertIn('if type(RuntimeMonitorFactory) == "function"', s)


if __name__ == '__main__':
    unittest.main()
