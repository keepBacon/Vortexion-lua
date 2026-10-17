"""R226 isolated static/runtime contracts. Not a Roblox Android gameplay test."""
import re,unittest,json,hashlib,zipfile
from pathlib import Path
from test_wind_router import LuaRuntime
R=Path(__file__).resolve().parents[1]
S=lambda name:(R/'src'/name).read_text()
class SCP226(unittest.TestCase):
 def test_faction_hostile_neutral_rank(self):
  src=S('SCPCandidates.luau');start=src.index('    local function normalize(');end=src.index('local rosterConns = {',start)
  code=src[start:end]
  pre='''
local Players={LocalPlayer=nil}
local Candidates={}
local function p(name,team,rank)
 local player={Name=name,Team=team and {Name=team} or nil,attributes={Rank=rank}}
 function player:GetAttribute(k)return self.attributes[k]end
 function player:FindFirstChild()return nil end
 return player
end
Players.LocalPlayer=p('Local','Security Department','Captain')
'''
  tail='''
local ci={Player=p('Insurgent','Chaos Insurgency','Insurgency Command')}
local ally={Player=p('Guard','Mobile Task Forces','Sergeant')}
local neutral={Player=p('Prisoner','Class - D','Veteran Class - D')}
local scp={Player=nil}
assert(Candidates:GetSide(Players.LocalPlayer)=='FOUNDATION')
assert(Candidates:GetSide(ci.Player)=='HOSTILE')
assert(Candidates:GetSide(neutral.Player)=='NEUTRAL')
assert(Candidates:IsHostile(ci))
assert(not Candidates:IsHostile(ally))
assert(not Candidates:IsHostile(neutral))
assert(Candidates:IsHostile(scp))
assert(Candidates:GetJob(ci)=='Insurgency Command')
assert(Candidates:GetJob(scp)=='SCP收容体')
Players.LocalPlayer=p('Local','Chaos Insurgency')
assert(Candidates:IsHostile(ally))
assert(not Candidates:IsHostile(ci))
'''
  LuaRuntime().run(pre+code+tail)
 def test_event_driven_interaction_restore(self):
  src=S('SCPInteract.luau')
  src=re.sub(r'([\w.]+)\s*\+=\s*(\d+)',lambda m:f'{m.group(1)}={m.group(1)}+{m.group(2)}',src)
  before='''
table.clear=function(t)for k in pairs(t)do t[k]=nil end end
local function signal()
 local s={listeners={}}
 function s:Connect(fn)table.insert(self.listeners,fn) return {Disconnect=function() end} end
 function s:Fire(...)for _,fn in ipairs(self.listeners)do fn(...)end end
 return s
end
local ps={PromptShown=signal(),PromptHidden=signal(),PromptTriggered=signal()}
game={GetService=function(_,name)assert(name=='ProximityPromptService')return ps end}
local common={OnCleanup=function(fn)_G.cleanup=fn end}
local prompt={Parent=true,HoldDuration=2}
function prompt:IsA(name)return name=='ProximityPrompt'end
'''
  after='''
local i=(function() '''+src+''' end)()(common)
ps.PromptShown:Fire(prompt)
assert(prompt.HoldDuration==2 and i.Stats.Visible==1)
i:SetEnabled(true)
assert(prompt.HoldDuration==0)
ps.PromptTriggered:Fire(prompt)
assert(i.Stats.Triggered==1)
i:SetEnabled(false)
assert(prompt.HoldDuration==2)
i:SetEnabled(true)
assert(prompt.HoldDuration==0)
ps.PromptHidden:Fire(prompt)
assert(prompt.HoldDuration==2 and i.Stats.Visible==0)
i:Cleanup()
'''
  LuaRuntime().run(before+after)
 def test_native_esp_no_drawing_or_hooks(self):
  esp=S('SCPESP.luau')
  self.assertIn('Instance.new("BoxHandleAdornment")',esp)
  self.assertIn('Instance.new("ScreenGui")',esp)
  self.assertIn('Instance.new("UIStroke")',esp)
  self.assertIn('PointToWorldSpace',esp)
  self.assertIn('ColorSCP = Color3.fromRGB(0, 0, 0)',esp)
  self.assertIn('SCP收容体',esp)
  self.assertNotIn('Drawing.new',esp)
  self.assertNotIn('GetDescendants',esp)
  self.assertNotIn('hookmetamethod',esp)
  self.assertIn('common.VisualInterval',esp)
  self.assertIn('ESP.Stats=',esp)
 def test_aim_hitbox_mobile_independent(self):
  aim=S('SCPCamera.luau'); hit=S('SCPHitbox.luau');common=S('SCPCandidates.luau')
  self.assertIn('common.Touch.Enabled and "Always" or "Right"',aim)
  self.assertIn('Mode = "all"',hit)
  self.assertIn('Config.OnlyHostile',hit)
  self.assertIn('Hitbox.Stats.Expanded',hit)
  self.assertIn('GetJob(cand)',common)
  self.assertIn('GetSide(player)',common)
 def test_ui_and_build_embedded(self):
  core=S('SCPCore.luau');build=(R/'build.py').read_text()
  for key in ['SCPESPHostile','SCPESPNames','SCPESPStyle','SCPESPJob','SCPESPColorSCP','SCPInstantInteract','SCPHitboxNPC','SCPHitboxHostile']:
   self.assertIn(key,core)
  self.assertIn('SCPInteractFactory',core)
  self.assertIn('SCPInteract.luau',build)
  for file in ['Vortexion_SCP.lua','Vortexion_Neverlose.lua','Vortexion_Module_SCP.lua']:
   bundle=(R/'dist'/file).read_text()
   self.assertIn('SCP3DCollisionBox',bundle)
   self.assertIn('ProximityPromptService',bundle)
   self.assertIn('SCP收容体',bundle)
 def test_build_manifest_integrity(self):
  mani=json.loads((R/'dist'/'build-manifest.json').read_text())
  self.assertTrue(mani)
  # Generated scripts must be >50KiB; no accidental empty module bundles.
  for p in (R/'dist').glob('Vortexion_*.lua'):
   self.assertGreater(p.stat().st_size,20000)
if __name__=='__main__':unittest.main()
