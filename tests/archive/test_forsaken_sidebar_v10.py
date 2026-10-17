#!/usr/bin/env python3
"""Static Forsaken sidebar/FOV regression; Android runtime is not simulated."""
from pathlib import Path
import hashlib, json, re
root=Path(__file__).resolve().parents[1]
vendor=(root/"vendor/Starlight/Source.lua").read_text(encoding="utf-8")
core=(root/"src/ForsakenCore.luau").read_text(encoding="utf-8")
forsaken=(root/"dist/Vortexion_Forsaken.lua").read_text(encoding="utf-8")
manifest=json.loads((root/"dist/build-manifest.json").read_text(encoding="utf-8"))
titles=re.findall(r'Window:AddTab\(\{\s*Title\s*=\s*"([^"]+)"',core)
assert titles==["玩家","游戏","其他","高风险功能","Guest 1337 专项","自定义动画","社区","设置"],titles
assert "navigation = scroller" in vendor
assert "scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y" in vendor
assert "scroller.ScrollingEnabled = true" in vendor
assert 'child.Name == "NavigationSectionTemplate"' in vendor
assert "if not UserInputService.TouchEnabled then" in vendor
assert core.index('Tabs.Settings:AddSlider("ForsakenFOVValue"') < core.index("Window:InstallSettings(Tabs.Settings)")
assert core.index('Tabs.Settings:AddToggle("ForsakenFOVEnabled"') < core.index("Window:InstallSettings(Tabs.Settings)")
assert 'Min = 80, Max = 200' in core
assert 'local effective = math.min(fovValue, 120)' in core
assert "VortexionNavigationScroll" in forsaken
assert manifest["output_bytes"]==(root/"dist/Vortexion_Forsaken.lua").stat().st_size
assert manifest["output_sha256"]==hashlib.sha256((root/"dist/Vortexion_Forsaken.lua").read_bytes()).hexdigest()
assert manifest["starlight_source_sha256"]==hashlib.sha256((root/"vendor/Starlight/Source.lua").read_bytes()).hexdigest()
for n in ("Vortexion_BloxStrike.lua","Vortexion_AOTR_Lobby.lua","Vortexion_AOTR_Battle.lua"):
    assert "VortexionNavigationScroll" in (root/"dist"/n).read_text(encoding="utf-8")
print("Forsaken v10 static regression: pass")
