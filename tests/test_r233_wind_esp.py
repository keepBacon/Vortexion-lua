"""R233 Wind migration and BloxStrike ESP projection / fallback contracts.
Offline mocks do not verify actual Android rendering or server behavior.
"""
import hashlib
import json
import re
import unittest
from pathlib import Path
from test_wind_router import LuaRuntime
from test_r219_billboard_weapon import BASE, lower

ROOT = Path(__file__).resolve().parents[1]
SRC = (ROOT / 'src/BloxStrikeVisual.luau').read_text()
FRAGMENT = SRC[SRC.index('    local highlights = {}'):SRC.index('    --=========================================================================\n    -- Fullbright')]

class WindESPTests(unittest.TestCase):
    def test_wind_ui_shared_all_routes(self):
        manifest = json.loads((ROOT/'dist/build-manifest.json').read_text())
        runtime = json.loads((ROOT/'dist/runtime-manifest.json').read_text())
        assert manifest['vendor_path'] == 'vendor/WindUI/Source.lua'
        assert manifest['unified_entry'] == 'dist/Vortexion_Wind.lua'
        assert 'r233' in runtime['build_tag']
        expected = hashlib.sha256((ROOT/'vendor/WindUI/Source.lua').read_bytes()).hexdigest()
        assert expected == 'e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05'
        assert manifest['windui_source_sha256'] == expected
        for artifact in ['Vortexion_Core.lua', *['Vortexion_Module_' + n + '.lua' for n in ['SCP','BloxStrike','Forsaken','AOTR_Lobby','AOTR_Battle']]]:
            text = (ROOT / 'dist' / artifact).read_text()
            assert 'NeverloseEmergency' not in text
            assert 'NeverloseAdapter' not in text
        assert (ROOT/'dist/Vortexion_Wind.lua').read_bytes()==(ROOT/'dist/Vortexion_Neverlose.lua').read_bytes()

    def test_esp_diagnostics_and_scope(self):
        assert SRC.index('local espStats = ') < SRC.index('local function projectOverlay')
        for field in ['noModel', 'noRoot', 'teamFiltered', 'rangeFiltered', 'guiFailed', 'rendered2D','fallback3D']:
            assert field in SRC
        assert 'ESP 画面自检（独立于敌人识别）' in SRC
        assert '复制完整 ESP 运行诊断' in SRC
        assert 'VortexionBloxESPDiagnostics' in SRC

    def test_real_2d_path_and_native_fallback_mock(self):
        # The old mock lacks Camera.WorldToViewportPoint, which is useful for
        # exercising the native 3D fallback instead of silently hiding all ESP.
        code = BASE + lower(FRAGMENT) + r'''
updateESP()
assert(espStats.scanned==1 and espStats.eligible==1 and espStats.markers==1)
local entry=highlights[enemy]
assert(entry and entry.gui and entry.gui.Parent==guiRoot)
assert(espStats.fallback3D==1 and entry.highlight and entry.highlight.Enabled)
assert(espStats.rendered2D==0)
assert(entry.gui.Enabled==true)
-- No per-refresh reallocation.
local count=espStats.creates
updateESP()
assert(espStats.creates==count)
Config.ESPEnabled=false
updateESP()
assert(next(highlights)==nil and entry.gui.Destroyed)
'''
        LuaRuntime().run(code)

    def test_screen_projection_runtime(self):
        code = BASE + r"""
function VM.__add(a,b) return vec(a.x+b.x,a.y+b.y,a.z+b.z) end
camera.ViewportSize={X=720,Y=480}
function camera:WorldToViewportPoint(v)
    return {X=360+v.x*2,Y=220-v.y*20,Z=30},true
end
""" + lower(FRAGMENT) + r"""
updateESP()
local entry=highlights[enemy]
assert(entry and entry.overlay and entry.overlay.Visible)
assert(espStats.rendered2D==1 and espStats.fallback3D==0)
assert(entry.gui.Enabled==false)
assert(entry.overlayStroke.Enabled)
assert(entry.overlayText.Text=='ENEMY\n12 studs')
"""
        LuaRuntime().run(code)

    def test_main_game_ids_retained(self):
        routes=json.loads((ROOT/'src/loader_routes.json').read_text())
        assert set(routes['universes'].values()) == {'BloxStrike','Forsaken','SCP'}
        assert set(routes['aotr_places'].values()) == {'AOTR_Lobby','AOTR_Battle'}

if __name__ == '__main__':unittest.main()
