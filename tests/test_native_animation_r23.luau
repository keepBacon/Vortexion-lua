-- Appended to the shared BloxStrike API fixture; factories remain production source.
local actions, tracks, loadedNames = {}, {}, {}
function tab:AddButton(info) actions[info.Title] = info.Callback end
local assets = node("Folder", "Assets", replicated)
local weapons = node("Folder", "Weapons", assets)
local knife = node("Folder", "Butterfly Knife", weapons)
local template = node("Model", "Camera", knife)
template.PrimaryPart = node("Part", "Root", template)
node("Part", "Blade", template)
local joint = node("Motor6D", "Joint", template)
joint.Transform = CFrame.new(0, 0, 0)
local controller = node("AnimationController", "AnimationController", template)
node("Animator", "Animator", controller)
local animations = node("Folder", "WeaponAnimations", assets)
local perKnife = node("Folder", "Butterfly Knife", animations)
local cameraAnimations = node("Folder", "CameraAnimations", perKnife)
local modes = {"Equip", "Idle", "Inspect", "Heavy Swing", "Swing1", "Swing2"}
for _, name in ipairs(modes) do node("Animation", name, cameraAnimations) end
local cam = workspace.CurrentCamera
local oldKnife = node("Model", "T Knife", cam)
local oldBlade = node("Part", "OldBlade", oldKnife)
local fault, onLoad, onPlay, latestModel
function methods:LoadAnimation(animation)
    check(self:IsA("Animator") and self:IsDescendantOf(cam), "loads only camera-clone Animator")
    local model = self.Parent.Parent
    latestModel = model
    model:FindFirstChild("Joint").Part1 = model:FindFirstChild("Blade")
    table.insert(loadedNames, animation.Name)
    if fault == "load" then error("injected native load failure") end
    local t = {Name=animation.Name, IsPlaying=false, Destroyed=false, Plays=0}
    function t:Play(fade, weight, speed)
        self.Fade, self.Weight, self.Speed = fade, weight, speed
        self.Plays += 1
        if fault == "play" then error("injected native play failure") end
        self.IsPlaying = true
        if onPlay then onPlay(self) end
    end
    function t:Stop() self.IsPlaying = false; self.Stops = (self.Stops or 0)+1 end
    function t:Destroy() self.Destroyed = true end
    table.insert(tracks, t)
    if onLoad then onLoad(t) end
    return t
end
local c = context()
Cosmetic(c)
set("BloxCustomKnife", true)
local equip = tracks[#tracks]
check(equip.Name=="Equip" and equip.Speed==1 and not equip.Looped, "native Equip uses 1x speed")
check(oldBlade.Transparency==1, "original model hidden while preview active")
local preview = latestModel
local blade = preview:FindFirstChild("Blade")
check(not blade.Anchored and preview.PrimaryPart.Anchored, "only clone joint child unanchored")
check(joint.Part1==nil, "original template rig remains untouched")
equip.IsPlaying=false; frame(0.2)
local idle = tracks[#tracks]
check(equip.Destroyed and idle.Name=="Idle" and idle.Looped, "finished Equip transitions to looped Idle")
actions["刀具检视动画"]()
local inspect = tracks[#tracks]
check(idle.Destroyed and inspect.Name=="Inspect", "Inspect replaces and disposes Idle")
frame(0.01)
check(preview.Pivot.Position.X==0 and preview.Pivot.Position.Y==-1.5, "native motion excludes procedural offset")
set("BloxKnifePreviewSpeed", 25); actions["刀具挥动动画"]()
check(tracks[#tracks].Name=="Swing1" and tracks[#tracks].Speed==0.25, "first Swing uses quarter speed")
set("BloxKnifePreviewSpeed", 200); actions["刀具挥动动画"]()
check(tracks[#tracks].Name=="Swing2" and tracks[#tracks].Speed==2, "second Swing alternates at double speed")
actions["刀具重挥动画"]()
local heavy = tracks[#tracks]
check(heavy.Name=="Heavy Swing", "Heavy Swing consumes exact existing name")
local baseTransform = preview:FindFirstChild("Joint").Transform
preview:FindFirstChild("Joint").Transform = CFrame.new(9, 9, 9)
actions["停止动画与声音"]()
check(heavy.Destroyed and blade.Anchored, "Stop reclaims native track and restores anchoring")
check(preview:FindFirstChild("Joint").Transform==baseTransform, "Stop restores saved Motor6D transform")
local count=#tracks; frame(0.2)
check(#tracks==count, "explicit Stop does not restart native Idle")
fault="load"; actions["刀具检视动画"](); frame(0.02)
check(preview.Pivot.Position.X~=0, "load failure falls back to procedural Inspect")
fault=nil; actions["停止动画与声音"]()
fault="play"; actions["刀具检视动画"]()
check(tracks[#tracks].Destroyed and blade.Anchored, "Play failure rolls back track and rig")
fault=nil; actions["停止动画与声音"]()
local inspectAsset=cameraAnimations:FindFirstChild("Inspect"); inspectAsset.Parent=nil
count=#tracks; actions["刀具检视动画"](); frame(0.02)
check(#tracks==count and preview.Pivot.Position.X~=0, "missing asset degrades without guessed asset")
inspectAsset.Parent=cameraAnimations; actions["停止动画与声音"]()
onLoad=function() actions["停止动画与声音"]() end
actions["刀具检视动画"](); onLoad=nil
check(tracks[#tracks].Destroyed and tracks[#tracks].Plays==0, "late Load after Stop never plays")
onPlay=function() actions["停止动画与声音"]() end
actions["刀具检视动画"](); onPlay=nil
check(tracks[#tracks].Destroyed and blade.Anchored, "Stop during Play rolls back published track")
actions["刀具检视动画"](); local bounded=tracks[#tracks]; frame(30.1)
check(bounded.Destroyed and tracks[#tracks].Name=="Idle", "stuck non-idle native track has 30-second bound")
local playing=tracks[#tracks]; count=#tracks
for _=1,100 do frame(0.016) end
check(#tracks==count and not playing.Destroyed, "playing Idle does not reload assets every frame")
local second = camera(); workspace.CurrentCamera=second
check(playing.Destroyed and preview.Destroyed and oldBlade.Transparency==0.2, "camera replacement fully restores prior ownership")
cam=second; node("Model", "T Knife", cam); frame(0.2)
check(tracks[#tracks].Name=="Equip", "replacement camera rebuilds one native Equip")
playing=tracks[#tracks]; set("BloxCustomKnife", false)
check(playing.Destroyed and latestModel.Destroyed, "disable reclaims native clone and track")
onLoad=function() set("BloxCustomKnife", false) end
set("BloxCustomKnife", true); onLoad=nil
check(tracks[#tracks].Destroyed and tracks[#tracks].Plays==0, "disable during Load destroys late candidate")
local sourceAnimator=controller:FindFirstChild("Animator")
sourceAnimator.Parent=nil
count=#tracks; set("BloxCustomKnife", true); frame(0.02)
check(#tracks==count, "missing clone Animator uses procedural preview without allocation")
set("BloxCustomKnife", false); sourceAnimator.Parent=controller
set("BloxCustomKnife", true); playing=tracks[#tracks]
cleanup(c)
check(playing.Destroyed and run.RenderStepped:Count()==0, "cleanup removes track and frame listener")
for _,t in ipairs(tracks) do check(t.Destroyed, "every native track disposed at teardown") end
check(active("Animator", template)==1, "template Animator survives without new Animator allocation")
print("R23 native animation assertions: "..checked)
return true
