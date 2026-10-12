#!/usr/bin/env python3
"""SCP Roleplay static integration checks; not a substitute for Roblox testing."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
loader=(root/"loader.lua").read_text(encoding="utf-8")
core=(root/"src/SCPRoleplayCore.luau").read_text(encoding="utf-8")
meta=(root/"src/SCPRoleplayMetadata.luau").read_text(encoding="utf-8")
build=(root/"build.py").read_text(encoding="utf-8")
bundle=(root/"dist/Vortexion_SCPRoleplay.lua").read_text(encoding="utf-8")
adapter=(root/"src/StarlightAdapter.luau").read_text(encoding="utf-8")
checks={
 "SCP universe route": "[1742264997]" in loader,
 "SCP place fallback": "[5041144419]" in loader,
 "Forsaken and BloxStrike preserved": "[6331902150]" in loader and "[7633926880]" in loader,
 "SCP own configuration": 'Folder="VortexionSCP"' in core,
 "SCP own title": 'Name="SCP: Roleplay"' in core,
 "adapter uses game-specific name": "config.Name" in adapter,
 "team and rank reader": "function Metadata.Rank" in meta and "function Metadata.Team" in meta,
 "rank unknown fallback": 'return "未知职位"' in meta,
 "ESP team and role controls": "SCPShowRank" in core and "SCPShowTeam" in core,
 "bounded label updates": "accumulator>=1/state.UpdateHz" in core,
 "re-injection cleanup": "VortexionSCPCleanup" in core,
 "SCP bundle generator": "scp_file=DIST/" in build,
 "BloxStrike v2 builder preserved": "BloxCombatFactory" in build and "BloxCosmeticFactory" in build,
 "SCP bundle includes metadata": "function Metadata.Rank" in bundle,
 "SCP bundle includes UI": "function handle:AddToggle" in bundle and "SCPShowIdentity" in bundle,
 "module does not spoof server calls": "FireServer" not in core and "InvokeServer" not in core,
}
for name,passed in checks.items(): print(("PASS" if passed else "FAIL"),name)
assert all(checks.values()), "SCP static regression detected"
print("PASS",len(checks),"static checks; in-game behavior unverified")
