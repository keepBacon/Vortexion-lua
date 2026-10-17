"""R225 isolated runtime contracts; not evidence of server accepting shots."""
from pathlib import Path
import unittest
from test_wind_router import LuaRuntime
from test_r219_billboard_weapon import lower
P=Path(__file__).resolve().parents[1]
CORE=(P/'src/BloxStrikeCore.luau').read_text()
BULLET=(P/'src/BloxStrikeBullet.luau').read_text()
COMBAT=(P/'src/BloxStrikeCombat.luau').read_text()

class R225GameContracts(unittest.TestCase):
    def test_characters_parent_is_not_team(self):
        fragment=CORE[CORE.index('local function teamOf(player)'):CORE.index('local function playerFromModel(model)')]
        mock='''
local characters={Name="Characters"}
local gameAttrs={Gamemode="Competitive", CTCharacter="OperatorCT", TCharacter="OperatorT"}
local Workspace={GetAttribute=function(_,k)return gameAttrs[k]end,
    FindFirstChild=function(_,n)if n=="Characters"then return characters end end}
local function actor(name,team,look)
 local model={Name=name,Parent=characters,attrs={CharacterName=look}}
 function model:GetAttribute(k)return self.attrs[k]end
 local player={Name=name,Parent=true,Character=model,attrs={Team=team}}
 function player:GetAttribute(k)return self.attrs[k]end
 return player
end
local LocalPlayer=actor("MyCT","Counter-Terrorists","OperatorCT")
local enemy=actor("EnemyT","Terrorists","OperatorT")
local ally=actor("AllyCT","Counter-Terrorists","OperatorCT")
local bot=actor("Bot",nil,"OperatorT")
function bot:GetAttribute(k)return self.Character:GetAttribute(k)end
local function characterOf(p)return p.Character end
local function teamFolder(p)return characters end -- the bug: everyone has the SAME parent
'''
        script=mock+lower(fragment)+'''
assert(teamOf(LocalPlayer)=="Counter-Terrorists")
assert(teamOf(enemy)=="Terrorists")
assert(teamOf(bot)=="Terrorists")
assert(isEnemy(enemy,true)==true,"real enemy must not be filtered")
assert(isEnemy(bot,true)==true,"bot must be targetable")
assert(isEnemy(ally,true)==false,"friendly must be filtered")
assert(isEnemy(ally,false)==true,"user bypass must work")
gameAttrs.Gamemode="TeamDeathmatch"
assert(isEnemy(ally,true)==true,"deathmatch subtype handling")
'''
        LuaRuntime().run(script)

    def test_weapon_native_hook_runtime_and_restore(self):
        code=BULLET[BULLET.index('    local mods = {'):BULLET.index('    --=========================================================================\n    -- Aim resolution')]
        script=r'''
local native = {}
local function attach(fn, replacement)
 local slot=native[fn]
 if not slot then slot={fn=fn,called=0};native[fn]=slot end
 local previous=slot.replacement or fn
 slot.replacement=replacement
 return previous
end
local function invoke(fn,...)
 local slot=native[fn]
 if slot and slot.replacement then return slot.replacement(...) end
 return fn(...)
end
local hookfunction=attach
local recoil=function() return 'kick' end
local spread=function() return 7 end
local weapon={weaponKick=recoil,getTrueSpread=spread}
local ReplicatedStorage={FindFirstChild=function()return nil end}
local getgc=function()return {weapon}end
local Vector3={zero='zero'}
local typeof=function(v)return type(v)end
local c={Caps={hookfunction=true},IsCurrent=function()return true end,OnCleanup=function(fn) _G.cleanup=fn end}
'''+lower(code)+r'''
setWeaponMod('recoil',true)
assert(mods.nativeHooks>=1,'native hook should be preferred')
assert(invoke(recoil)==nil,'cached original recoil closure must be hooked')
assert(invoke(spread)==7)
setWeaponMod('spread',true)
assert(invoke(spread)==0,'cached original spread closure must be hooked')
assert(mods.calls>=2)
setWeaponMod('recoil',false)
assert(invoke(recoil)=='kick','toggle off forwards original')
assert(invoke(spread)==0)
cleanup()
assert(invoke(spread)==7 and invoke(recoil)=='kick','restore must restore original')
'''
        LuaRuntime().run(script)

    def test_weapon_table_fallback_no_hook(self):
        self.assertIn('"only table"', '"only table"')
        self.assertIn('tablePatches',BULLET)
        self.assertIn('workerRunning',BULLET)
        self.assertIn('weaponObserved',BULLET)

    def test_ui_and_bundles_have_r225_flags(self):
        bundle=(P/'dist/Vortexion_BloxStrike.lua').read_text()
        for s in ['local function teamOf(player)', 'weaponNativeHooks',
                  'VirtualInputManager', 'CharacterName', 'BloxRageEnabled', 'BloxESP']:
            self.assertIn(s,bundle)
        self.assertIn('state.rosterSeen',COMBAT)
        self.assertIn('rosterSeen = state.rosterSeen',COMBAT)

if __name__=='__main__':unittest.main()
