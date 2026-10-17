#!/usr/bin/env python3
"""Static dual-game router checks; not a Roblox runtime test."""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
loader=(root/"loader.lua").read_text(encoding="utf-8")
core=(root/"src/BloxStrikeCore.luau").read_text(encoding="utf-8")
ui=(root/"src/StarlightAdapter.luau").read_text(encoding="utf-8")
dist=(root/"dist/Vortexion_BloxStrike.lua").read_text(encoding="utf-8")
forsaken=(root/"dist/Vortexion_Forsaken.lua").read_text(encoding="utf-8")
checks={
 "Forsaken universe": '[6331902150]' in loader and "dist/Vortexion_Forsaken.lua" in loader,
 "BloxStrike universe": '[7633926880]' in loader and "dist/Vortexion_BloxStrike.lua" in loader,
 "unknown game fails closed": 'if not path then' in loader and 'return' in loader,
 "BloxStrike uses shared Starlight": "local StarlightBridgeFactory = (function()" in dist,
 "BloxStrike app is separate": 'BloxAimEnabled' in core and 'BloxESP' in core,
 "bundle includes game module": "local function findTarget(camera)" in dist,
 "touch capable bridge": "function handle:AddToggle" in ui and "function handle:AddSlider" in ui,
 "Forsaken bundle untouched": "Tabs.GuestSettings" in forsaken,
 "no remote URLs in BloxStrike module": "game:HttpGet" not in core,
 "new module static lifecycle": "VortexionBloxSession" in core,
}
for title,passed in checks.items():
 print(("PASS" if passed else "FAIL"),title)
assert all(checks.values()),"Static checks failed"
print(f"PASS {len(checks)} static checks; Roblox runtime unverified")
