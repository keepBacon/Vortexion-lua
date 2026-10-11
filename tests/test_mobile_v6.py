#!/usr/bin/env python3
"""Static regression checks for the 2026-10-11 touch/feature update.
This is NOT an emulator/device test and cannot prove runtime behavior.
"""
from pathlib import Path
import json, hashlib, re
P=Path(__file__).resolve().parents[1]
ui=(P/'vendor/Starlight/Source.lua').read_text()
bridge=(P/'src/StarlightAdapter.luau').read_text()
core=(P/'src/ForsakenCore.luau').read_text()
full=(P/'dist/Vortexion_Forsaken.lua').read_text()
manifest=json.loads((P/'dist/build-manifest.json').read_text())
checks={
'original Starlight touch handler identified': 'The old slider only started its drag' in ui,
'no legacy frame step slider': 'local dragFunction = function(X)' not in ui,
'slider reads actual touch position': 'publishSlider(inputObject.Position.X, true)' in ui,
'slider follows touch input': 'changed == inputObject' in ui and 'UserInputService.InputChanged:Connect(function(changed)' in ui,
'slider pointer identity tracked': 'activePointer = inputObject' in ui and 'activePointer ~= inputObject' in ui,
'slider release tracked globally': 'UserInputService.InputEnded:Connect(function(finished)' in ui,
'slider disconnects temporary handlers': 'movedConnection:Disconnect()' in ui and 'endedConnection:Disconnect()' in ui,
'slider scrolling restored': 'parentScroll.ScrollingEnabled = scrollPreviouslyEnabled' in ui,
'slider callback throttled': 'now - lastPublish >= 0.05' in ui,
'UI touch sidebar not draggable': 'if not UserInputService.TouchEnabled then\n            makeDraggable(mainWindow.Sidebar' in ui,
'window topbar remains movable': 'makeDraggable(mainWindow.Content.Topbar, mainWindow, StarlightUI.Drag)' in ui,
'legacy scroll fix kept': 'column.ScrollingEnabled = true' in bridge,
'new gen ESP controls registered': all(f'"{x}"' in core for x in ('GeneratorProgressESP','GeneratorShowCompleted')),
'generator GUI reacts to progress event': 'updateGeneratorLabel(generator, genModel, progress, false)' in core,
'generator labels only active on demand': 'ESP.Enabled and ESP.GeneratorDetails' in core,
'generator distance update <=1 Hz': 'runEvery(1.0, function()\n    if ESP.Enabled and ESP.GeneratorDetails' in core,
'generator completed state tracked': 'ESP.CompletedGenerators' in core and '已完成' in core,
'gen label renderer only one': core.count('local function updateGeneratorLabel(')==1,
'killer alert controls registered': all(f'"{x}"' in core for x in ('KillerProximityAlert','KillerProximityRadius')),
'killer alert scans only if enabled': 'while self.Enabled and self.Generation == generation do' in core,
'killer alert 2.5 Hz': 'task.wait(0.4) -- 2.5 Hz' in core,
'killer alert cooldown': 'self.LastGlobal >= self.Cooldown' in core,
'red/green factions preserved': 'COLOR_KILLER = Color3.fromRGB(255, 0, 0)' in core and 'COLOR_SURVIVOR = Color3.fromRGB(0, 255, 0)' in core,
'ESP occluded zero': 'PLAYER_ESP_OFFSCREEN_ALPHA = 0' in core,
'ESP unobstructed eighty': 'PLAYER_ESP_ONSCREEN_ALPHA = 0.80' in core,
'no duplicate UI library loaders': full.count('local Starlight = (function()')==1,
'full build matches prefix and source': core.replace('local StarlightBridgeFactory = nil\nlocal Starlight = nil\n','',1) in full and bridge in full and ui in full,
'config IDs original preserved': set(json.loads((P/'tests/option_ids_baseline.json').read_text())) <= set(re.findall(r'Tabs\.\w+:Add(?:Toggle|Slider|Input|Dropdown)\(\s*["\']([^"\']+)["\']',core)),
'build matches checksum':manifest['output_sha256']==hashlib.sha256((P/'dist/Vortexion_Forsaken.lua').read_bytes()).hexdigest(),
'license retained':(P/'vendor/Starlight/LICENSE').exists(),
}
failed=[k for k,ok in checks.items() if not ok]
for k,ok in checks.items():print(('PASS' if ok else 'FAIL'),k)
result={'type':'static_source_checks','checks':len(checks),'passed':len(checks)-len(failed),'failed':failed,'video_reviewed':'1000547754.mp4 52.14 s, landscape, inspected frames 0-50 s','luau_compiler_tested':False,'roblox_android_tested':False,'claim_runtime_fixed':False}
(P/'dist/test-mobile-v6.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
assert not failed
