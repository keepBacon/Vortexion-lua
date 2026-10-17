"""R2.16: puzzle-phase extraction and safe path planning under Lua mocks."""
from pathlib import Path
import re
import unittest
from test_wind_router import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT/'src/ForsakenPuzzlePlanner.luau').read_text(encoding='utf-8')
SOURCE = re.sub(r'(?m)^(\s*)([A-Za-z][\w.]*) \+= (.*)$',
                lambda m: m.group(1) + m.group(2) + ' = ' + m.group(2) + ' + ' + m.group(3), SOURCE)

LUA_MOCK = r'''
table.clone = function(t) local out={} for k,v in pairs(t) do out[k]=v end return out end
local planner=(function()
'''+SOURCE+r'''
end)()()
local solved,why,steps=planner.Solve(3,{
 {id='A',a=1,b=3},{id='B',a=7,b=9}
})
assert(why=='solved' and solved and #solved.A==3 and #solved.B==3, 'valid independent paths')
assert(solved.A[1]==1 and solved.A[3]==3 and solved.B[1]==7 and solved.B[3]==9)
local bad,reason=planner.Solve(3,{{id='A',a=1,b=3},{id='B',a=3,b=8}})
assert(bad==nil and reason=='ambiguous endpoints')
local function frame(name)
 local f={Name=name,Visible=true,Active=false,BackgroundColor3={R=1,G=0,B=0},ClassName='Frame',children={}}
 function f:FindFirstChild(k) return self.children[k] end
 function f:GetChildren() local out={} for _,v in pairs(self.children) do out[#out+1]=v end return out end
 function f:IsA(k) return k=='GuiObject' or k=='Frame' end
 function f:GetFullName() return 'PuzzleUI' end
 return f
end
local puzzle=frame('PuzzleUI')
local container=frame('Container');puzzle.children.Container=container
local holder=frame('GridHolder');container.children.GridHolder=holder
local grid=frame('Grid');holder.children.Grid=grid
for i=1,49 do
 local cell=frame(tostring(i));grid.children[tostring(i)]=cell
 if i==1 or i==7 or i==43 or i==49 then
  local circle=frame('Circle');cell.children.Circle=circle
  local number=frame('Number'); number.ClassName='TextLabel'
  function number:IsA(class)return class=='TextLabel' end
  number.Text=(i==1 or i==7) and 'A' or 'B'
  circle.children.Number=number
  local button=frame('Button');function button:IsA(class)return class=='GuiButton' end
  cell.children.Button=button
 end
end
local result,err=planner.Read(puzzle)
assert(result and not err and result.phase=='grid' and result.size==7 and result.count==49)
assert(#result.pairs==2 and result.ambiguous==0,'pair extraction')
local summary=planner.Summary(result)
assert(summary:find('planner=solved',1,true), summary)
assert(summary:find('cell=49',1,true) and summary:find('number=B',1,true),summary)
local gear=frame('PuzzleUI')
local _,missing=planner.Read(gear)
assert(missing:find('GridHolder.Grid',1,true))
'''

class R216PuzzleTests(unittest.TestCase):
    def test_planner_real_function_under_lua(self):
        LuaRuntime().run(LUA_MOCK)

    def test_puzzle_ui_wiring_and_version(self):
        code = (ROOT/'src/ForsakenEnhancements.luau').read_text(encoding='utf8')
        self.assertIn('分析当前发电机谜题（端点/颜色/路径）',code)
        self.assertIn('puzzle-analyzed-not-actuated',code)
        built = (ROOT/'build.py').read_text(encoding='utf8')
        self.assertIn('ForsakenPuzzlePlannerFactory',built)

if __name__=='__main__':
    unittest.main()
