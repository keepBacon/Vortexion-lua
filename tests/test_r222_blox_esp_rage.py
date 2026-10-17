"""R222 standalone Lua 5.4 fragment regressions and build contracts.
This cannot prove Roblox camera/fire/server outcomes or Android executor input."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).parent))
from test_wind_router import LuaRuntime
from test_r219_billboard_weapon import BASE, lower
ROOT=Path(__file__).resolve().parents[1]
VISUAL=(ROOT/'src/BloxStrikeVisual.luau').read_text()
COMBAT=(ROOT/'src/BloxStrikeCombat.luau').read_text()
CORE=(ROOT/'src/BloxStrikeCore.luau').read_text()

class R222Tests(unittest.TestCase):
    def test_esp_2d_projection_real_lua_and_cleanup(self):
        fragment=VISUAL[VISUAL.index('    local highlights = {}'):VISUAL.index('    --=========================================================================\n    -- Fullbright')]
        script=BASE.replace('local camera={CFrame={Position=vec(0,0,0)}}','''local camera={CFrame={Position=vec(0,0,0)},ViewportSize={X=900,Y=600},
 WorldToViewportPoint=function(self,pt)return {X=450+pt.x,Y=300-pt.y*20,Z=20},pt.y<=0.5 end}''')
        script=script.replace('local Vector3={new=vec}', '''local Vector3={new=vec}''')
        script=script.replace('function VM.__sub(a,b)', 'function VM.__add(a,b) return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},VM) end\nfunction VM.__sub(a,b)')
        script=script.replace('local Config={ESPWorldHighlight=false,ESPOverlay=true', 'local Config={ESPWorldHighlight=false,ESPOverlay=true')
        script=script.replace('local c={Living=', 'local c={Living=')
        script+=lower(fragment)+'''
updateESP()
local entry=highlights[enemy]
assert(entry and entry.overlay and entry.overlay.Parent, 'screen overlay missing')
assert(entry.overlay.Visible==true, '2d viewport not displayed when head outside view')
assert(entry.overlay.Active==false, 'touch blocking overlay')
assert(overlayGui and overlayGui.IgnoreGuiInset == true and overlayGui.ResetOnSpawn==false)
assert(entry.gui.Enabled==false, 'billboard should not duplicate 2D')
assert(overlayCreates==1 and overlayDraws==1)
local old=entry.overlay
updateESP()
assert(overlayCreates==1 and overlayDraws==2, 'cached overlay not reused')
Config.ESPEnabled=false
updateESP()
assert(next(highlights)==nil and old.Destroyed==true, '2D cleanup failed')
assert(overlayGui==nil)
'''
        LuaRuntime().run(script)

    def test_rage_target_fire_and_stop_in_lua(self):
        rage=COMBAT[COMBAT.index('    local function ragePart(entry)'):COMBAT.index('    --=========================================================================\n    -- Public interface')]
        script=r'''
math.clamp=function(v,a,b)return math.min(math.max(a,v),b)end
local VM={}
function VM.__index(t,k)
 if k=='Magnitude' then return math.sqrt(t.x*t.x+t.y*t.y+t.z*t.z) end
 if k=='Unit' then local n=math.sqrt(t.x*t.x+t.y*t.y+t.z*t.z);return setmetatable({x=t.x/n,y=t.y/n,z=t.z/n},VM) end
 return VM[k]
end
function VM.__add(a,b) return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},VM) end
function VM.__sub(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},VM) end
function VM.__mul(a,b)
 if type(a)=='number' then return setmetatable({x=a*b.x,y=a*b.y,z=a*b.z},VM) end
 return setmetatable({x=a.x*b,y=a.y*b,z=a.z*b},VM)
end
function VM:Dot(other) return self.x*other.x+self.y*other.y+self.z*other.z end
local function v(x,y,z)return setmetatable({x=x,y=y,z=z},VM)end
Vector3={zero=v(0,0,0)}
local look=v(0,0,1)
local camera={CFrame={Position=v(0,0,0),LookVector=look,Lerp=function(self,cf,alpha)return cf end}}
CFrame={lookAt=function(position,target)return {Position=position, LookVector=(target-position).Unit,Lerp=function(self,cf,alpha)return cf end} end}
local Workspace={CurrentCamera=camera}
local target={Parent=true,Position=v(0,0,55),AssemblyLinearVelocity=v(0,0,0)}
local model={FindFirstChild=function(self,k) if k=='Head' then return target end end}
local entry={player={},model=model,head=target,root=target,screenDist=0,worldDist=55}
local state={candidates={entry}, rageTarget=nil,rageLastSwitch=0,rageAttempts=0,rageSent=0,rageReason='off',velEMA={},fireAt=0,firing=false,fireBackend='mock'}
local Config={RageEnabled=true,RageMode='Instant',RageAutoFire=true,RageFOV=700,RageDistance=900,RageMaxAngle=85,RagePart='Head',RageWallCheck=true,RageFireInterval=0.14,RageLead=0.09,RageSwitchDelay=0.09}
local function entryValid(e,isRage)return e==entry and isRage end
local function gateHeld()return true end
local function pressFire(time,owner)assert(owner=='rage');return true end
local c={Ping=function()return 0 end}
'''+lower(rage)+r'''
rageTick(0.016,1)
assert(state.rageTarget==entry and state.rageAttempts==1 and state.rageSent==1, 'no rage shot')
assert(state.rageReason=='input sent (hit unverified)')
rageTick(0.016,1.02)
assert(state.rageAttempts==1,'fire-rate gate lost')
Config.RageEnabled=false
rageTick(0.016,1.2)
assert(state.rageTarget==nil and state.rageReason=='off','rage stop failed')
'''
        LuaRuntime().run(script)

    def test_rage_camera_override_automatically_uses_mouse(self):
        # Exercise the real delivery fragment: a game resets camera yaw every
        # frame even after our Last-priority render callback wrote a new CFrame.
        frag=COMBAT[COMBAT.index('    local function resolveRageMouse()'):COMBAT.index('    local function rageTick(dt, now)')]
        mock=r'''
math.clamp=function(v,a,b)return math.min(math.max(v,a),b)end
local VM={}
function VM.__index(t,k)
 if k=='Magnitude' then return math.sqrt(t.x*t.x+t.y*t.y+t.z*t.z) end
 if k=='Unit' then local n=math.sqrt(t.x*t.x+t.y*t.y+t.z*t.z);return setmetatable({x=t.x/n,y=t.y/n,z=t.z/n},VM) end
 return VM[k]
end
function VM.__add(a,b)return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},VM)end
function VM.__sub(a,b)return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},VM)end
function VM.__mul(a,b)return setmetatable({x=a.x*b,y=a.y*b,z=a.z*b},VM)end
function VM:Dot(o)return self.x*o.x+self.y*o.y+self.z*o.z end
local function v(x,y,z)return setmetatable({x=x,y=y,z=z},VM)end
local function frame(look)
 return {Position=v(0,0,0),LookVector=look,Lerp=function(self,dest,alpha)return dest end}
end
local default=v(0,0,1)
local camera={CFrame=frame(default),ViewportSize=setmetatable({X=900,Y=600}, {__mul=function(t,n)return {X=t.X*n,Y=t.Y*n}end}),
 WorldToViewportPoint=function(self,p)return {X=450+p.x*10,Y=300,Z=10},true end}
local n=0
local function mousemoverel(x,y)n=n+1;assert(x>0 and x<=120);assert(y==0)end
local Config={RageMode='Instant',RageDelivery='Auto'}
local state={rageExpectedLook=nil,rageCameraHits=0,rageCameraMisses=0,rageMouseMoves=0,rageAimBackend='none'}
local target=v(10,0,50)
local targetCF=frame(target.Unit)
'''+lower(frag)+r'''
for i=1,7 do
 local aligned,reason=rageDeliverAim(0.016,camera,target,targetCF)
 camera.CFrame=frame(default) -- game controller rewrites camera immediately
end
assert(state.rageCameraMisses>=4,'camera overwrite probe missed')
assert(state.rageAimBackend=='Mouse','input fallback did not activate')
assert(n>0 and state.rageMouseMoves==n,'mouse movement path inactive')
Config.RageDelivery='Camera'
local aligned=rageDeliverAim(0.016,camera,target,targetCF)
assert(state.rageAimBackend=='Camera','explicit camera mode ignored')
'''
        LuaRuntime().run(mock)

    def test_real_and_npc_roster_lua(self):
        roster=CORE[CORE.index('local folderCache = '):CORE.index('-- In BloxStrike the authoritative client roster')]
        mock=r'''
local now=10
local function tick() return now end
local function model(name)
 local m={Name=name,Parent=true}
 function m:IsA(kind)return kind=='Model' end
 function m:GetAttribute(k)return nil end
 return m
end
local localM=model('LocalPlayer')
local enemyM=model('Enemy')
local botM=model('Robot5')
local allyBotM=model('Robot6')
local function folder(name,children)
 local f={Name=name,children=children}
 function f:IsA(kind)return kind=='Folder' end
 function f:GetChildren() return self.children end
 function f:FindFirstChild(name)
   for _,a in ipairs(self.children) do if a.Name==name then return a end end
 end
 for _,m in ipairs(children) do m.Parent=f end
 return f
end
local ct=folder('Counter-Terrorists',{localM,allyBotM})
local t=folder('Terrorists',{enemyM,botM})
local root={GetChildren=function()return {ct,t} end}
local LocalPlayer={Name='LocalPlayer',Character=localM,Parent=true}
local enemyPlayer={Name='Enemy',Character=enemyM,Parent=true}
local Players={}
function Players:GetPlayers()return {LocalPlayer,enemyPlayer}end
function Players:FindFirstChild(name)
 if name=='Enemy' then return enemyPlayer end
 if name=='LocalPlayer' then return LocalPlayer end
end
function LocalPlayer:IsA(cls)return cls=='Player'end
function enemyPlayer:IsA(cls)return cls=='Player'end
function Players:GetPlayerFromCharacter(m)
 if m==localM then return LocalPlayer end
 if m==enemyM then return enemyPlayer end
end
local Workspace={FindFirstChild=function(self,k) if k=='Characters' then return root end end}
'''
        code=mock+lower(roster)+r'''
local all=targets()
assert(#all==4,'player and bot roster must merge')
assert(folderCache.npcs==2,'non-Player models should become NPC proxies')
local bot=all[3]
assert(bot.IsVortexionNPC and characterOf(bot)==allyBotM)
assert(teamFolder(bot)==ct)
assert(characterOf(enemyPlayer)==enemyM)
now=10.1
assert(targets()[3]==bot,'NPC proxy identity must remain stable within refresh')
now=11
assert(targets()[3]==bot,'NPC identity must persist across rescans')
'''
        LuaRuntime().run(code)

    def test_build_contract_and_labels(self):
        for symbol in ['BloxRageEnabled','BloxRageMode','BloxRageAutoFire','BloxRageWallCheck',
                       'BloxRageFOV','BloxRageDistance','BloxRagePart','BloxRageFireInterval','BloxRageDelivery']:
            self.assertIn('"'+symbol+'"',COMBAT)
        self.assertIn('Config.RageEnabled or Config.TriggerEnabled',COMBAT)
        self.assertIn('Targets=targets',CORE)
        self.assertIn('if Config.RageEnabled then',COMBAT)
        self.assertIn('Config.ESPOverlay and "Viewport2D+BillboardFallback"',VISUAL)
        self.assertIn('overlayGui:Destroy()',VISUAL)
        self.assertIn('entry.overlay.Active = false', VISUAL.replace('bounds.Active = false','entry.overlay.Active = false'))
        dist=(ROOT/'dist/Vortexion_BloxStrike.lua').read_text()
        for symbol in ['BloxRageEnabled','BloxESP2D','VortexionBloxESP2D222']:
            self.assertIn(symbol,dist)

if __name__=='__main__': unittest.main()
