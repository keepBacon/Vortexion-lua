"""R2.13 field-failure tests, not a Roblox real-server validation."""
import unittest
from pathlib import Path
from test_r25_stability import SETUP, to_lua54
from test_r210_state import SCENE, TARGET
from test_wind_router import LuaRuntime
ROOT = Path(__file__).resolve().parents[1]
ADAPTER = (ROOT/'src/WindAdapter.luau').read_text()
FS = (ROOT/'src/ForsakenCore.luau').read_text()
ENH = (ROOT/'src/ForsakenEnhancements.luau').read_text()

class FieldFixesR213(unittest.TestCase):
    def test_mobile_notifications_suppressed_but_logged(self):
        source = ADAPTER[ADAPTER.index('    -- WindUI native notifications own'):ADAPTER.index('    local callbackErrorRevision')]
        LuaRuntime().run(r'''
local nativeCount=0
local bridge={Active=true}
local input={TouchEnabled=true}
local appName='Forsaken'
local print=function()end
local WindUI={NotificationGui={Enabled=true}}
function WindUI:Notify(info)nativeCount=nativeCount+1 end
'''+source+r'''
assert(bridge.NativeNoticesEnabled==false)
assert(WindUI.NotificationGui.Enabled==false)
bridge:Notify({Title='test',Content='recorded'})
assert(nativeCount==0)
assert(bridge.LastNotice=='test: recorded')
assert(#bridge.NoticeHistory==1)
setNativeNotices(true)
bridge:Notify({Title='desktop',Content='optin'})
assert(nativeCount==1)
assert(WindUI.NotificationGui.Enabled==true)
''')

    def test_esp_occlusion_distinct_alpha_and_stable_on_transient_loss(self):
        LuaRuntime().run(to_lua54(SETUP+SCENE+r'''
__lastMarker=nil
local oldNew=Instance.new
Instance.new=function(k)
 local marker=oldNew(k)
 __lastMarker=marker
 return marker
end
local blocked=true
RaycastParams={new=function()return {}end}
Enum.RaycastFilterType={Exclude='Exclude'}
workspace.Raycast=function()
 if blocked then
  return {Instance={IsDescendantOf=function()return false end}}
 end
 return nil
end
__block=function(v)blocked=v end
'''+TARGET+r'''
__callbacks.FsKillerESP(true)
__runHeartbeat(0.3)
assert(__lastMarker.FillTransparency==0.65, tostring(__lastMarker.FillTransparency))
__block(false)
__runHeartbeat(0.3)
assert(__lastMarker.FillTransparency==0.65,'should debounce occlusion flip')
__runHeartbeat(0.3)
assert(__lastMarker.FillTransparency==0.2,'clear alpha missing')
__callbacks.FsVisibleAlphaR213(45)
__runHeartbeat(0.3)
assert(__lastMarker.FillTransparency==0.45,'clear slider not applied')
__callbacks.FsKillerESP(false)
local _, removed=__markers()
assert(removed==1,'disable must still cleanup immediately')
'''))

    def test_no_pointer_injection_from_popup(self):
        self.assertNotIn('SendMouseButtonEvent(',ENH)
        self.assertNotIn('re:FireServer()',ENH)
        self.assertIn('prompt:InputHoldBegin()',ENH)
        self.assertIn('"SpeedMultipliers"',ENH)
        self.assertIn('VortexionMoveMultiplier',ENH)
        self.assertIn('"FsOccludedAlphaR213"',FS)
        self.assertIn('"FsVisibleAlphaR213"',FS)

if __name__=='__main__':unittest.main()
