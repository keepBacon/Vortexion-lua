#!/usr/bin/env python3
"""BloxStrike v2 static source integration and UI declaration regressions."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
core=(R/'src/BloxStrikeCore.luau').read_text()
combat=(R/'src/BloxStrikeCombat.luau').read_text()
visual=(R/'src/BloxStrikeVisual.luau').read_text()
cosmetic=(R/'src/BloxStrikeCosmetic.luau').read_text()
vendor=(R/'vendor/Starlight/Source.lua').read_text()
bridge=(R/'src/StarlightAdapter.luau').read_text()
bundle=(R/'dist/Vortexion_BloxStrike.lua').read_text()
expect=('-- Vortexion BloxStrike independent build\n'
        '-- Starlight © Nebula Softworks, CC BY-NC 4.0 (see vendor/Starlight/LICENSE)\n')
for name,source in [('Starlight',vendor),('StarlightBridgeFactory',bridge),
                    ('BloxCombatFactory',combat),('BloxVisualFactory',visual),
                    ('BloxCosmeticFactory',cosmetic)]:
    expect+=f'local {name} = (function()\n'+source+'\nend)()\n'
expect+=re.sub(r'local (?:BloxCombatFactory|BloxVisualFactory|BloxCosmeticFactory|StarlightBridgeFactory|Starlight) = nil\n','',core)
checks={
    'exact reproducible bundle': expect==bundle,
    'module context is shared': all(x in core for x in ['BloxCombatFactory','BloxVisualFactory','BloxCosmeticFactory','TeamFolder=teamFolder']),
    'BloxStrike live character folders': all(x in core for x in ['Terrorists','Counter-Terrorists','Workspace:FindFirstChild("Characters")']),
    'touch aim': '"BloxTouchAim"' in combat,
    'aim target and LOS checks': 'WorldToViewportPoint' in combat and 'Workspace:Raycast' in combat,
    'functional esp': 'Instance.new("Highlight")' in visual,
    'skin selectors created from assets': 'targetTab:AddDropdown(optionId' in cosmetic and 'category:GetChildren()' in cosmetic,
    'camera skin application': 'applySurface(part,match)' in cosmetic and 'find' not in cosmetic[:1],
    'undo skin modifications': 'restoreParts()' in cosmetic,
    'knife model select and rollback': 'BloxKnifeType' in cosmetic and 'restoreKnife()' in cosmetic,
    'old controls retained': all(i in bundle for i in ['BloxAimEnabled','BloxESP','BloxFullbright','BloxSpeedEnabled']),
    'single shared UI library': bundle.count('function Starlight:CreateWindow')==1,
}
for n,ok in checks.items(): print(('PASS' if ok else 'FAIL'),n)
assert all(checks.values())
print('Static checks only; game runtime and executor compatibility remain unverified')
