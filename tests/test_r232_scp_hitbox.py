"""R232 SCP hitbox: execute the actual module against a Lua physics/UI stub.

This validates client-side modifications and restoration, NOT server hit registration.
"""
from pathlib import Path
import re
import unittest
from test_wind_router import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "src" / "SCPHitbox.luau").read_text(encoding="utf-8")

def vanilla_lua(source):
    # Lua 5.4 harness has no Luau compound assignments.
    source = re.sub(r"([A-Za-z_][\w.]*)\s*\+=\s*([^\n]+)",
                  lambda m: f"{m.group(1)} = {m.group(1)} + ({m.group(2)})", source)
    return re.sub(r"([A-Za-z_][\w.]*)\s*%=\s*([^\n]+)",
                  lambda m: f"{m.group(1)} = {m.group(1)} % ({m.group(2)})", source)

MOCK = r'''
math.clamp=function(x,lo,hi)return math.max(lo,math.min(x,hi))end
local function V(x,y,z)
  local t={X=x,Y=y,Z=z}
  local mt={}
  mt.__index=function(a,k)
    if k=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=='Lerp' then return function(self,to,alpha)return V(self.X+(to.X-self.X)*alpha,self.Y+(to.Y-self.Y)*alpha,self.Z+(to.Z-self.Z)*alpha)end end
    return nil
  end
  mt.__add=function(a,b)return V(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
  mt.__sub=function(a,b)return V(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
  mt.__mul=function(a,b)
    if type(a)=='number' then return V(a*b.X,a*b.Y,a*b.Z) end
    return V(a.X*b,a.Y*b,a.Z*b)
  end
  return setmetatable(t,mt)
end
Vector3={new=V};Vector2={new=function(x,y)return V(x,y,0) end}
Color3={fromRGB=function(...)return {...}end}
function signal()
 local sig={}
 function sig:Connect(fn)self.fn=fn;return {Disconnect=function()end}end
 return sig
end
local previews={}
Instance={new=function(name)
 assert(name=='BoxHandleAdornment')
 local obj={ClassName=name,Parent=nil}
 function obj:Destroy()self.Parent=nil;self.destroyed=true end
 previews[#previews+1]=obj
 return obj
end}
local function part(name,x)
 local p={Name=name,Size=V(2,2,2),Position=V(x,0,0),Transparency=0,CanCollide=true,Parent=true}
 function p:IsA(typ)return typ=='BasePart' end
 return p
end
local function model(name,props)
 local m={Name=name,Parent=true,props=props,attributes={}}
 function m:FindFirstChild(k)return self.props[k]end
 function m:FindFirstChildWhichIsA(cls)if cls=='BasePart' then return self.PrimaryPart end return self.humanoid end
 function m:GetAttribute(k)return self.attributes[k]end
 return m
end
local ourCharacter=model('our',{HumanoidRootPart=part('HumanoidRootPart',0)})
local enemy=model('enemy',{Head=part('Head',14),UpperTorso=part('UpperTorso',14)})
enemy.humanoid={Health=100}
local monster=model('SCP-096',{CustomCore=part('CustomCore',30)})
monster.PrimaryPart=monster.props.CustomCore
local lp={Character=ourCharacter}
local other={Character=enemy}
local players={LocalPlayer=lp,PlayerRemoving=signal()}
function players:GetPlayers()return {lp,other}end
function players:GetPlayerFromCharacter(m)if m==enemy then return other end return nil end
local camera={ViewportSize=V(800,600,0),CFrame={Position=V(0,0,0)}}
function camera:WorldToViewportPoint(pos)return V(400+pos.X,300,3),true end
local workspace={CurrentCamera=camera,DescendantRemoving=signal()}
local cleanup={}
local common={Services={Players=players,Workspace=workspace},LocalPlayer=lp,
  OnCleanup=function(fn)cleanup[#cleanup+1]=fn end,
  Candidates={NPCs={[monster]=true},Get=function()return {}end,
     IsHostile=function(self,c)return c.Player==other or c.Character==monster end},
}
'''

TEST = r'''
local hb=(function() __SOURCE__ end)()(common)
local originalHead=enemy.props.Head.Size
local originalNpc=monster.PrimaryPart.Size
hb.Config.Enabled=true
hb:Update(0.1)
assert(hb.Stats.Eligible==2,'candidate pool must not cap targets')
assert(hb.Stats.Expanded==2,'human and custom SCP entity both selected')
assert(hb.Stats.Verified>=2,'client part Size must actually change')
assert(hb.Stats.Preview>=2,'local bounds must be visible by default')
assert(enemy.props.Head.Size.X>originalHead.X,'player head expanded')
assert(monster.PrimaryPart.Size.X>originalNpc.X,'no-Humanoid SCP PrimaryPart expanded')
assert(hb:GetEnvelope(enemy.props.Head).X==originalHead.X,'original envelope retained')
assert(enemy.props.Head.CanCollide==false,'collision flags locally disabled')
-- Simulate the game overwriting local hitboxes between updates.
enemy.props.Head.Size=V(2,2,2)
hb:Update(0.1)
assert(hb.Stats.ExternalResets>0,'external Size reset recorded')
hb.Config.ShowBounds=false
hb:Update(0.1)
assert(hb.Stats.Preview==0,'bounds hidden on next tick')
hb.Config.OnlyHostile=true
hb:Update(0.1)
assert(hb.Stats.Eligible==2,'hostile filter accepts verified targets')
hb.Config.Enabled=false
hb:Update(0)
assert(enemy.props.Head.Size.X==originalHead.X,'player original Size restored')
assert(monster.PrimaryPart.Size.X==originalNpc.X,'NPC original Size restored')
assert(enemy.props.Head.CanCollide==true,'original CanCollide restored')
hb.Config.Enabled=true
hb:Update(0.1)
assert(enemy.props.Head.Size.X>2,'expansion restored after reenabling')
workspace.DescendantRemoving.fn(enemy)
assert(enemy.props.Head.Size.X==2,'model removal must immediately restore hitboxes')
for _,fn in ipairs(cleanup)do fn()end
'''

class R232Hitbox(unittest.TestCase):
    def test_client_hitbox_runtime(self):
        LuaRuntime().run(MOCK + TEST.replace('__SOURCE__', vanilla_lua(SOURCE)))

    def test_custom_scp_npc_discovery(self):
        pool = (ROOT / "src" / "SCPCandidates.luau").read_text(encoding="utf-8")
        start = pool.index("\t\tlocal function consider(model)")
        end = pool.index("\n\t\tlocal connAdded", start)
        snippet = pool[start:end]
        pre = r''' 
local Candidates={NPCs={}}
local Players={GetPlayerFromCharacter=function(self,model)return nil end}
local function entity(name, tag, humanoid)
    local part={IsA=function(self,kind)return kind=='BasePart'end}
    local m={Name=name}
    function m:IsA(kind)return kind=='Model'end
    function m:GetAttribute(k)if k=='IsSCP' then return tag end end
    function m:FindFirstChildWhichIsA(kind)return humanoid and {Health=100} or nil end
    function m:GetChildren()return {part} end
    return m
end
'''
        post = r'''
local anomalous = entity('SCP-096',false,false)
local neutralProp = entity('DoorFrame',false,false)
local attributed = entity('CustomAnomaly',true,false)
consider(anomalous)
consider(neutralProp)
consider(attributed)
assert(Candidates.NPCs[anomalous]==true,'SCP-096 should be indexed')
assert(Candidates.NPCs[attributed]==true,'SCP attribute should be indexed')
assert(Candidates.NPCs[neutralProp]==nil,'environment models should be rejected')
'''
        LuaRuntime().run(pre + snippet + post)

    def test_shared_heartbeat_and_ui(self):
        core = (ROOT / 'src' / 'SCPCore.luau').read_text(encoding='utf-8')
        for term in ('HitboxHeartbeat', 'SCPHitboxBounds', 'SCPHitboxBoundsAlpha',
                     'SCPHitboxUseFov', '检查碰撞箱实际生效情况'):
            self.assertIn(term, core)
        self.assertNotIn('if Hitbox.Config and Hitbox.Config.Enabled then\n            common.Guard("Hitbox"', core)

    def test_bundle_contains_update(self):
        for filename in ('Vortexion_SCP.lua', 'Vortexion_Module_SCP.lua', 'Vortexion_Neverlose.lua'):
            content=(ROOT/'dist'/filename).read_text(encoding='utf-8')
            self.assertIn('VortexionSCPHitboxBounds',content)
            self.assertIn('r232', (ROOT/'dist'/'runtime-manifest.json').read_text(encoding='utf-8'))

if __name__ == '__main__': unittest.main()
