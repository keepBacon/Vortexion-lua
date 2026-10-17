#!/usr/bin/env python3
"""Verify exact release artifact bytes without external modules or a live Roblox client."""
from pathlib import Path
import json
import hashlib

ROOT = Path(__file__).resolve().parent
manifest = json.loads((ROOT / "dist/runtime-manifest.json").read_text(encoding="utf-8"))
assert manifest.get("schema") == 2, "Expected schema=2"
assert set(manifest["modules"]) == {"Forsaken", "BloxStrike", "SCP", "AOTR_Lobby", "AOTR_Battle"}
assets = [manifest["core"], *manifest["modules"].values()]
for item in assets:
    rel = item["path"]
    assert rel.startswith("dist/") and ".." not in rel
    data = (ROOT / rel).read_bytes()
    assert len(data) == item["bytes"], f"Size mismatch: {rel}"
    assert hashlib.sha256(data).hexdigest() == item["sha256"], f"SHA-256 mismatch: {rel}"
old = json.loads((ROOT / "dist/build-manifest.json").read_text())
for name, meta in old["bundles"].items():
    data = (ROOT / "dist" / name).read_bytes()
    assert len(data) == meta["bytes"]
    assert hashlib.sha256(data).hexdigest() == meta["sha256"]
print(f"PASS: {len(assets)} modular and {len(old['bundles'])} standalone bundles verified; loader file present={((ROOT/'loader.lua').is_file())}")
