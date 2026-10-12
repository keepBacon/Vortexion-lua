#!/usr/bin/env python3
"""Static SCP integration checks. This is not an in-game runtime test."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
loader=(root/"loader.lua").read_text(encoding="utf-8")
src=(root/"src/SCPRoleplayCore.luau").read_text(encoding="utf-8")
metadata=(root/"src/SCPRoleplayMetadata.luau").read_text(encoding="utf-8")
bundle=(root/"dist/Vortexion_SCPRoleplay.lua").read_text(encoding="utf-8")
adapter=(root/"src/StarlightAdapter.luau").read_text(encoding="utf-8")
checks={
    "SCP universe": '[1742264997] = "dist/Vortexion_SCPRoleplay.lua"' in loader,
    "SCP place": '[5041144419] = "dist/Vortexion_SCPRoleplay.lua"' in loader,
    "previous experiences preserved": "[6331902150]" in loader and "[7633926880]" in loader,
    "metadata available": "function Metadata.Snapshot" in metadata and "function Metadata.Rank" in metadata,
    "rank fallback": 'return "未知职位"' in metadata,
    "SCP UI available": 'SCPShowIdentity' in src and 'VortexionSCP' in src,
    "bounded work": "accumulator>=1/state.UpdateHz" in src and "MaxDistance=state.Distance" in src,
    "cleanup": "VortexionSCPCleanup" in src and "clearAll()" in src,
    "independent bundle": "function Metadata.Rank" in bundle and "SCPShowIdentity" in bundle,
    "shared Starlight": "function handle:AddToggle" in bundle,
    "dynamic branding": 'config.Title or "Forsaken"' in adapter,
    "no combat remote injection": "FireServer" not in src and "hookmetamethod" not in src,
}
for name,ok in checks.items(): print(("PASS" if ok else "FAIL"),name)
assert all(checks.values())
print("PASS",len(checks),"static checks; Roblox runtime unverified")
