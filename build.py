#!/usr/bin/env python3
"""Reproducible build of Vortexion - Forsaken (Starlight UI).
No network requests or GitHub writes are performed.
"""
from pathlib import Path
import hashlib, json
ROOT=Path(__file__).resolve().parent
VENDOR=ROOT/'vendor/Starlight/Source.lua'
BRIDGE=ROOT/'src/StarlightAdapter.luau'
CORE=ROOT/'src/ForsakenCore.luau'
DIST=ROOT/'dist';DIST.mkdir(exist_ok=True)
core=CORE.read_text(encoding='utf-8')
starlight=VENDOR.read_text(encoding='utf-8')
bridge=BRIDGE.read_text(encoding='utf-8')
assert core.count('local StarlightBridgeFactory = nil\nlocal Starlight = nil\n')==1
assert starlight.rstrip().endswith('return Starlight')
assert bridge.lstrip().startswith('-- Vortexion - Forsaken')
prefix=(
    '-- Vortexion - Forsaken · Starlight UI · independent source package\n'
    '-- Starlight © Nebula Softworks, licensed CC BY-NC 4.0; retain vendor/Starlight/LICENSE.\n'
    '-- This bundle uses Roblox model rbxassetid://132866968194043 at runtime.\n'
    '-- Build output, do not edit: modify src/*.luau then run python3 build.py.\n'
    'local Starlight = (function()\n'+starlight+'\nend)()\n'
    'local StarlightBridgeFactory = (function()\n'+bridge+'\nend)()\n'
)
core=core.replace('local StarlightBridgeFactory = nil\nlocal Starlight = nil\n','',1)
out=DIST/'Vortexion_Forsaken.lua';out.write_text(prefix+core,encoding='utf-8')
sha=lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
manifest={'phase':5,'project_name':'Vortexion - Forsaken','ui_project_title':'Forsaken','ui_byline':'- Vortexion','repository_name_proposed':'Vortexion-lua', 'repository':'keepBacon/Vortexion-lua', 'build_tag':'touch-v8-router','status':'local_build_ready_for_publishing','starlight_source_sha256':sha(VENDOR),'core_sha256':sha(CORE),'bridge_sha256':sha(BRIDGE),'output_sha256':sha(out),'output_bytes':out.stat().st_size,'publication':'verify_github_main_after_push','github_repository':'https://github.com/keepBacon/Vortexion-lua','old_repo_touched':False,'roblox_android_tested':False,'luau_compiler_tested':False,'notice':'Build-time metadata cannot verify GitHub deployment; confirm main and Raw URLs after push.'}
(DIST/'build-manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps(manifest,indent=2,ensure_ascii=False))
