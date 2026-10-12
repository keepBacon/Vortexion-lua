#!/usr/bin/env python3
"""Static AOTR branch regression checks; not a Roblox client simulation."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
loader=(root/"loader.lua").read_text(encoding="utf-8")
scene=(root/"src/AOTRScene.luau").read_text(encoding="utf-8")
common=(root/"src/AOTRCommon.luau").read_text(encoding="utf-8")
lobby=(root/"src/AOTRLobby.luau").read_text(encoding="utf-8")
battle=(root/"src/AOTRBattle.luau").read_text(encoding="utf-8")
builder=(root/"build.py").read_text(encoding="utf-8")
adapter=(root/"src/StarlightAdapter.luau").read_text(encoding="utf-8")
checks={
 "AOTR universe guard": "4658598196" in loader,
 "main menu route": "[13379208636]" in loader and "Scene.MENU = 13379208636" in scene,
 "lobby route": "[14916516914]" in loader and "Scene.LOBBY = 14916516914" in scene,
 "mission route": "[13379349730]" in loader,
 "other mission routes": all(("["+p+"]") in loader and v in scene for p,v in (("14638336319","Scene.MISSION_FOREST"),("14012874501","Scene.MISSION_TROST"),("13904207646","Scene.MISSION_OUTSKIRTS"))),
 "trade excluded": "[14932214603]" not in loader and "Scene.TRADE" in scene,
 "fails closed": "if universe == AOTR_UNIVERSE and not AOTR_PLACES[place] then" in loader,
 "two independent bundles": '("Lobby","AOTRLobby.luau")' in builder and '("Battle","AOTRBattle.luau")' in builder,
 "separate configuration": 'Folder="VortexionAOTR"' in common,
 "starlight configurable": 'config.Name or "Forsaken"' in adapter,
 "cleanup on reexecute": "VortexionAOTRCleanup" in common,
 "bounded monitor": 'app:Loop("titans",1,' in battle,
 "stale loop token invalidation": "self.flags[id]==generation" in common,
 "AOTR uses real newlines": '"local Starlight = (function()\\\\n"' not in builder, 
 "no AOTR raw HTTP loads": "game:HttpGet" not in lobby+battle+common,
 "legacy routes preserved": "[6331902150]" in loader and "[7633926880]" in loader,
}
for name,ok in checks.items(): print(("PASS" if ok else "FAIL"),name)
assert all(checks.values()),"AOTR regression check failed"
print("AOTR static checks passed; runtime remains unverified")
