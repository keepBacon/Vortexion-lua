#!/usr/bin/env python3
"""Toggle touch regression: verifies structure, not Roblox runtime."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
s=(R/'vendor/Starlight/Source.lua').read_text()
b=s.split('function Groupbox:CreateToggle(ElementSettings, Index)',1)[1].split('function Groupbox:CreateSlider(',1)[0]
checks={
    'cross platform Activated for both switch and checkbox': b.count('button.Activated:Connect(fire)')==1 and 'bindToggleTap(ElementInstance, ElementInstance.Switch.Interact, function()' in b and 'bindToggleTap(ElementInstance, ElementInstance.Checkbox.Interact, function()' in b,
    'no mouse-only toggle handlers': 'ElementInstance.Switch.Interact.MouseButton1Click:Connect' not in b and 'ElementInstance.Checkbox.Interact.MouseButton1Click:Connect' not in b,
    'entire row touch begins': 'row.InputBegan:Connect(begin)' in b,
    'inner button touch begins': 'button.InputBegan:Connect(begin)' in b,
    'pointer identity': 'finished ~= captured' in b,
    'scroll gesture filter': 'moved <= 18 and elapsed <= 0.8 and inside' in b,
    'touch release inside same row': 'pos.X >= rect.X' in b and 'pos.Y >= rect.Y' in b,
    'short event deduplication': 'now - lastActivation < 0.16' in b,
    'touch listener released': 'endedConn:Disconnect()' in b and 'row.AncestryChanged:Connect' in b,
    'respects modal overlay': 'not mainWindow.Content.Interactable' in b,
    'callback error handling kept': b.count('Element.Values.Callback(Element.Values.CurrentValue)')>=3,
    'Slider v6 preserved': 'publishSlider(inputObject.Position.X, true)' in s,
    'mobile sidebar drag fix preserved': 'if not UserInputService.TouchEnabled then\n            makeDraggable(mainWindow.Sidebar' in s,
}
for name,passed in checks.items(): print(('PASS' if passed else 'FAIL')+' '+name)
out={'type':'static_source_checks','check_count':len(checks),'passed':sum(checks.values()),'failed':[x for x,v in checks.items() if not v],'roblox_android_tested':False}
(R/'dist/test-toggle-v7.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
assert all(checks.values())
