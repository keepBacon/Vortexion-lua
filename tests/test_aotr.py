#!/usr/bin/env python3
"""Static AOTR branch regression checks; not a Roblox client simulation."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
loader=(root/"loader.lua").read_text(encoding="utf-8")
scene=(root/"src/AOTRScene.luau").read_text(encoding="utf-8")
router=(root/"src/GameRouter.luau").read_text(encoding="utf-8")
common=(root/"src/AOTRCommon.luau").read_text(encoding="utf-8")
lobby=(root/"src/AOTRLobby.luau").read_text(encoding="utf-8")
battle=(root/"src/AOTRBattle.luau").read_text(encoding="utf-8")
builder=(root/"build.py").read_text(encoding="utf-8")
adapter=(root/"src/WindAdapter.luau").read_text(encoding="utf-8")
checks={
 "AOTR universe guard": "local AOTR_UNIVERSE = 4658598196" in router,
 "main menu route": "[13379208636]" in router and "AOTR_Lobby" in router and "Scene.MENU = 13379208636" in scene,
 "lobby route": "[14916516914]" in router and "AOTR_Lobby" in router and "Scene.LOBBY = 14916516914" in scene,
 "mission route": "[13379349730]" in router and "AOTR_Battle" in router,
 "other mission routes": all(p in router for p in ("14638336319","14012874501","13904207646")) and all(v in scene for v in ("Scene.MISSION_FOREST","Scene.MISSION_TROST","Scene.MISSION_OUTSKIRTS")),
 "trade excluded": "[14932214603]" not in router and "Scene.TRADE" in scene,
 "fails closed": "return entry, entry and \"aotr-place\" or \"unsupported-aotr-scene\"" in router,
 "two independent bundles": "AOTR_Lobby" in builder and "AOTRLobby.luau" in builder and "AOTR_Battle" in builder and "AOTRBattle.luau" in builder,
 "separate configuration": 'Folder="VortexionAOTR"' in common,
 "wind configurable": 'config.Name or "Vortexion"' in adapter and "config.Folder or appName" in adapter,
 "cleanup on reexecute": "VortexionAOTRCleanup" in common,
 "bounded monitor": "while app:Alive() do" in battle and "task.wait(2)" in battle,
 "stale loop token invalidation": "self.flags[id]==generation" in common,
 "AOTR uses real newlines": '"local Starlight = (function()\\\\n"' not in builder, 
 "no AOTR raw HTTP loads": "game:HttpGet" not in lobby+battle+common,
 "legacy routes preserved": "[6331902150]" in router and "[7633926880]" in router,
}
for name,ok in checks.items(): print(("PASS" if ok else "FAIL"),name)
assert all(checks.values()),"AOTR regression check failed"
print("AOTR static checks passed; runtime remains unverified")
