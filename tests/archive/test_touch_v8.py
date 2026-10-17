#!/usr/bin/env python3
"""Vortexion v8: source/gesture-model regression, NOT Roblox runtime automation."""
from pathlib import Path
import json,re,hashlib
P=Path(__file__).resolve().parents[1]
s=(P/'vendor/Starlight/Source.lua').read_text(encoding='utf-8')
core=(P/'src/ForsakenCore.luau').read_text(encoding='utf-8')
dist=(P/'dist/Vortexion_Forsaken.lua').read_text(encoding='utf-8')
bridge=(P/'src/StarlightAdapter.luau').read_text(encoding='utf-8')
manifest=json.loads((P/'dist/build-manifest.json').read_text())
toggle=s.split('function Groupbox:CreateToggle(ElementSettings, Index)',1)[1].split('function Groupbox:CreateSlider(',1)[0]
slider=s.split('function Groupbox:CreateSlider(ElementSettings, Index)',1)[1].split('function Groupbox:CreateInput(',1)[0]
button=s.split('function Groupbox:CreateButton(ElementSettings, Index)',1)[1].split('function Groupbox:CreateToggle(ElementSettings, Index)',1)[0]
checks={
  'single shared router declaration':s.count('local VortexionTouch = {')==1,
  'router one global InputBegan':s.count('UserInputService.InputBegan:Connect(function(touch) beginMobileTouch(touch) end)')==1,
  'fallback TouchStarted':s.count('UserInputService.TouchStarted:Connect(function(touch) beginMobileTouch(touch) end)')==1,
  'TouchMoved independently handled':s.count('UserInputService.TouchMoved:Connect(function(touch) moveMobileTouch(touch) end)')==1,
  'InputEnded and TouchEnded':all(x in s for x in ['UserInputService.TouchEnded:Connect(function(touch) endMobileTouch(touch) end)','UserInputService.InputEnded:Connect(function(touch) endMobileTouch(touch) end)']),
  'single InputObject capture': 'VortexionTouch.pointers[touch]' in s and 'if VortexionTouch.pointers[touch] then return end' in s,
  'tap requires minimal displacement':'(pos-capture.start).Magnitude <= 16' in s,
  'swipe does not trigger toggle':'and touchEligible(item,pos)' in s,
  'scroll viewport clip respected':'current:IsA("ScrollingFrame") or current.ClipsDescendants' in s,
  'invisible page not interactive':'not current.Visible or not current.Interactable' in s,
  'modal popup masks input':all(x in s for x in ['modal.Visible then return false','popup.Visible then return false']),
  'processed GUI InputBegan not discarded':'function(touch) beginMobileTouch(touch)' in s,
  'toggle whole row tracked':'VortexionTouch:Register(row, "tap", callback, mainWindow, 0)' in toggle,
  'toggle native touch activation filtered':'inputObject.UserInputType == Enum.UserInputType.Touch then return end' in toggle,
  'native toggle callbacks preserved':toggle.count('Element.Values.Callback(Element.Values.CurrentValue)')>=3,
  'buttons registered':'VortexionTouch:Register(ElementInstance,"tap",activateButton,mainWindow)' in button,
  'slider shared touch state': 'VortexionTouch:Register(Element.Instance.PART_Backdrop, "slider",onSliderPointer,mainWindow,12)' in slider,
  'slider uses true touch absolute X':'publishSlider(x,final)' in slider and 'bar.AbsolutePosition.X' in slider,
  'slider locks and restores scroll':all(x in slider for x in ['parentScroll.ScrollingEnabled=false','parentScroll.ScrollingEnabled=oldScrollEnabled']),
  'slider throttles callbacks':'now-lastPublish>=0.05' in slider,
  'mobile tooltips no per-widget render loop':'if UserInputService.TouchEnabled or String.IsEmptyOrNull(InfoStr) then' in s,
  'previous toggle touch event removed':'row.InputBegan:Connect(begin)' not in toggle,
  'previous slider touch event removed':'Element.Instance.PART_Backdrop.Interact.InputBegan:Connect(beginDrag)' not in slider,
  'modal restores content after closing':'mainWindow.Content.Interactable = true' in s,
  'UI owns router lifecycle':'VortexionTouch.running=false' in s and 'StarlightUI.Destroying:Connect(function()' in s,
  'sidebar not draggable on mobile':'if not UserInputService.TouchEnabled then\n            makeDraggable(mainWindow.Sidebar' in s,
  'reinject invalidates old throttled jobs':'while sessionEnv.VortexionSessionId == thisSessionId do' in core,
  'red and green colors preserved':'COLOR_KILLER = Color3.fromRGB(255, 0, 0)' in core and 'COLOR_SURVIVOR = Color3.fromRGB(0, 255, 0)' in core,
  'ESP opacity preserved': 'PLAYER_ESP_OFFSCREEN_ALPHA = 0' in core and 'PLAYER_ESP_ONSCREEN_ALPHA = 0.80' in core,
  'single Starlight vendored bundle':dist.count('local Starlight = (function()')==1 and s in dist and bridge in dist,
  'build sha matches':manifest['output_sha256']==hashlib.sha256((P/'dist/Vortexion_Forsaken.lua').read_bytes()).hexdigest(),
  'Starlight license included':(P/'vendor/Starlight/LICENSE').exists(),
}

# Small event-driven state model for common user gestures. This models the
# state policy only, not the Roblox UI rendering engine or InputObject delivery.
def model_gesture(start,end,elapsed,inside=True,modal=False):
    displacement=((end[0]-start[0])**2+(end[1]-start[1])**2)**0.5
    return displacement<=16 and elapsed<=1 and inside and not modal
cases={
    'fast touch':model_gesture((100,100),(100,100),.14),
    'slight finger jitter':model_gesture((100,100),(110,109),.4),
    'vertical scroll not toggle':not model_gesture((100,100),(101,148),.4),
    'horizontal scroll not toggle':not model_gesture((100,100),(142,102),.4),
    'long press not toggle':not model_gesture((100,100),(100,101),1.2),
    'outside release not toggle':not model_gesture((100,100),(101,101),.3,inside=False),
    'modal not toggle':not model_gesture((100,100),(100,100),.2,modal=True),
}
for k,v in {**checks,**cases}.items(): print(('PASS ' if v else 'FAIL ')+k)
failed=[k for k,v in {**checks,**cases}.items() if not v]
result={'type':'static+policy_model','checks':len(checks)+len(cases),'passed':len(checks)+len(cases)-len(failed),'failures':failed,'roblox_android_tested':False,'luau_compiler_tested':False,'claim_runtime_fixed':False}
(P/'dist/test-touch-v8.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
assert not failed
