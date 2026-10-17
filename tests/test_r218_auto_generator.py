"""R2.18 puzzle path actuation guards and actual sample-board solver tests."""
import io
import json
import re
import unittest
import zipfile
from pathlib import Path
from test_wind_router import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
AUTO=(ROOT/'src/ForsakenPuzzleAuto.luau').read_text(encoding='utf-8')
PLANNER=(ROOT/'src/ForsakenPuzzlePlanner.luau').read_text(encoding='utf-8')

def lua54(code):
    return re.sub(r'(?m)^(\s*)([A-Za-z][\w.]*) \+= (.*)$',
                  lambda m:m.group(1)+m.group(2)+' = '+m.group(2)+' + '+m.group(3),code)

class R218Tests(unittest.TestCase):
    def test_two_live_paths_with_observable_confirmation(self):
        source=lua54(AUTO)
        runtime=r'''
local function cell(n)
 local self={Name=tostring(n),Parent=true,AbsolutePosition={X=50+n*20,Y=70},AbsoluteSize={X=10,Y=10}}
 return self
end
local cells={} for i=1,9 do cells[i]=cell(i) end
local lines={}
local grid={Parent=true}
function grid:GetDescendants() return lines end
local puzzle={Parent=true,Enabled=true}
function puzzle:IsA(k)return k=='ScreenGui' end
local planner={}
function planner.Read(p)
 return {phase='grid',count=9,size=3,container=puzzle,grid=grid,nodes=cells,
 pairs={{id='A',a=1,b=3},{id='B',a=7,b=9}},ambiguous=0}
end
function planner.Solve(n,p,b)
 assert(n==3 and #p==2 and b==14000)
 return {A={1,2,3},B={7,8,9}},'solved',10
end
local touches,moves=0,0
local vi={}
function vi:SendMouseButtonEvent(x,y,button,down,g,z)
 if not down then touches=touches+1;lines[#lines+1]={Name='HalfLine',Visible=true,IsA=function(self,k)return k=='GuiObject' end} end
end
function vi:SendMouseMoveEvent(x,y,g) moves=moves+1 end
local game={GetService=function(self,name)return vi end}
local task={spawn=function(fn)fn()end,wait=function(dt)end}
local getgenv=function()return {}end
local auto=(function()
''' + source + r'''
end)()(planner, {})
local states={};local ok=auto:Try(puzzle,function()return true end,function(s,d)states[#states+1]=s end)
assert(ok and auto.Active==false, 'worker should complete')
assert(touches==2 and moves>=6, 'should drag both paths')
assert(auto.Paths==2 and auto.Failed==0, auto.Detail)
assert(auto.Status=='await-next-board', auto.Status..' '..auto.Detail)
assert(auto:Try(puzzle,function()return true end,function(s,d)end))
assert(auto.Status=='waiting' and touches==2, 'do not replay same puzzle')
'''
        LuaRuntime().run(runtime)

    def test_mobile_touch_backend_and_release(self):
        source=lua54(AUTO)
        runtime=r'''
local n1={Parent=true,AbsolutePosition={X=10,Y=20},AbsoluteSize={X=20,Y=20}}
local n2={Parent=true,AbsolutePosition={X=30,Y=20},AbsoluteSize={X=20,Y=20}}
local lines={}; local grid={Parent=true,GetDescendants=function()return lines end}
local puzzle={Parent=true,Enabled=true,IsA=function(self,k)return k=='ScreenGui' end}
local planner={Read=function()return {phase='grid',size=2,count=4,pairs={{id='a',a=1,b=2}},ambiguous=0,
  container=puzzle,grid=grid,nodes={[1]=n1,[2]=n2}} end,
 Solve=function()return {a={1,2}} end}
local calls,beginState,endState={},0,2
local vim={}
function vim:SendTouchEvent(id,state,x,y)
  calls[#calls+1]={id=id,state=state,x=x,y=y}
  if state==endState then lines[#lines+1]={Name='VerticalLine',Visible=true,IsA=function()return true end} end
end
local ui={TouchEnabled=true}
local game={GetService=function(self,k)if k=='UserInputService'then return ui else return vim end end}
local Enum={UserInputState={Begin={Value=beginState},Change={Value=1},End={Value=endState}}}
local task={spawn=function(fn)fn()end,wait=function(t)end}
local getgenv=function()return {}end
local worker=(function()
'''+source+r'''
end)()(planner,{})
worker:Try(puzzle,function()return true end,function()end)
assert(worker.Status=='await-next-board' and worker.Paths==1,worker.Detail)
assert(#calls>=4 and calls[2].state==0 and calls[#calls].state==2)
assert(calls[1].id==43182 and calls[#calls].id==43182)
'''
        LuaRuntime().run(runtime)

    def test_no_guessed_input_or_false_success(self):
        source=lua54(AUTO)
        runtime=r'''
local p={Parent=true,Enabled=true,IsA=function(self,k)return k=='ScreenGui' end}
local cell={Parent=true,AbsolutePosition={X=50,Y=70},AbsoluteSize={X=10,Y=10}}
local planner={}
local grid={Parent=true,GetDescendants=function()return {}end}
function planner.Read()
 return {phase='grid',count=4,size=2,container=p,grid=grid,
   nodes={[1]=cell,[2]=cell},pairs={{id='A',a=1,b=2}},ambiguous=0}
end
function planner.Solve() return {A={1,2}} end
local game={GetService=function()error('denied') end}
local task={spawn=function(fn)fn()end,wait=function(dt)end}
local getgenv=function()return {}end
local auto=(function()
''' +source + r'''
end)()(planner,{})
assert(auto:Try(p,function()return true end,function(s,d)end))
assert(auto.Status=='input-unavailable' and auto.Paths==0 and auto.Failed==0)
'''
        LuaRuntime().run(runtime)

    def test_real_uploaded_board_fixture_solutions(self):
        # Fixed user-supplied endpoint configurations (no account identifiers).
        boards=[
            [(2,9),(19,25),(44,45),(13,18),(34,49),(47,48),(1,15),(16,23),(28,35),(40,46),(22,30),(27,43)],
            [(38,47),(12,13),(19,33),(30,37),(42,48),(28,35),(9,15),(8,39)],
            [(40,46),(20,43),(33,44),(1,18),(48,49),(14,35),(15,17),(27,42),(12,13),(2,7),(23,29)],
        ]
        literal='{' + ','.join('{' + ','.join("{id='p%d',a=%d,b=%d}"%(j,*pair) for j,pair in enumerate(board)) + '}' for board in boards) + '}'
        runtime=r'''
table.clone=function(t)local o={}for i,v in pairs(t)do o[i]=v end return o end
local planner=(function()
'''+lua54(PLANNER)+r'''
end)()()
local boards='''+literal+r'''
for _,board in ipairs(boards)do
 local routes,status,visits=planner.Solve(7,board,14000)
 assert(status=='solved' and routes, tostring(status)..' visits='..tostring(visits))
 local occupied={}
 local covered=0
 for _,pair in ipairs(board)do
  local route=routes[pair.id]
  assert(route[1]==pair.a and route[#route]==pair.b, 'wrong endpoint')
  for i,index in ipairs(route)do
   assert(index>=1 and index<=49 and not occupied[index], 'crossed or repeated')
   occupied[index]=true;covered=covered+1
   if i>1 then
    local prev=route[i-1]
    local r1,c1=math.floor((prev-1)/7),(prev-1)%7
    local r2,c2=math.floor((index-1)/7),(index-1)%7
    assert(math.abs(r1-r2)+math.abs(c1-c2)==1,'non-adjacent move')
   end
  end
 end
 assert(covered >= #board*2)
end
'''
        LuaRuntime().run(runtime)

    def test_blobs_color_pairs_and_gear_phase_reader(self):
        runtime=r'''
local planner=(function()
'''+lua54(PLANNER)+r'''
end)()()
local function frame(name,r,g,b)
 local self={Name=name,Parent=true,children={},Visible=true,Active=true,
 BackgroundColor3={R=r or 0,G=g or 0,B=b or 0}}
 function self:FindFirstChild(k)return self.children[k] end
 function self:GetChildren()local out={}for _,v in pairs(self.children)do out[#out+1]=v end return out end
 function self:IsA(k)return k=='GuiObject' end
 function self:GetFullName()return 'PuzzleUI' end
 return self
end
local puzzle=frame('PuzzleUI')
local container=frame('Container');puzzle.children.Container=container
local holder=frame('GridHolder');container.children.GridHolder=holder
local grid=frame('Grid');holder.children.Grid=grid
local blobs=frame('Blobs');grid.children.Blobs=blobs
for i=1,12 do
 local color=math.ceil(i/2)/6
 local c=frame(tostring(i),color,0.2,1-color)
 local number=frame('Number');number.Text=tostring(i)
 function number:IsA(k)return k=='GuiObject' or k=='TextLabel' end
 c.children.Number=number
 blobs.children[tostring(i)]=c
end
local data,err=planner.Read(puzzle)
assert(data and data.phase=='blobs' and #data.pairs==6 and data.ambiguous==0,tostring(err))
local gear=frame('PuzzleUI');local box=frame('Container');gear.children.Container=box
box.children.Inventory=frame('Inventory')
local gearData=planner.Read(gear)
assert(gearData and gearData.phase=='gear')
'''
        LuaRuntime().run(runtime)

    def test_wired_to_forsaken_and_release_builder(self):
        core=(ROOT/'src/ForsakenCore.luau').read_text()
        enhancements=(ROOT/'src/ForsakenEnhancements.luau').read_text()
        build=(ROOT/'build.py').read_text()
        self.assertIn('ForsakenPuzzleAutoFactory',build)
        self.assertIn('PuzzleAuto=puzzleAuto',core)
        self.assertIn('puzzleAuto:Try(',enhancements)
        self.assertIn('if puzzleAuto then puzzleAuto:Stop() end',enhancements)
        self.assertLess(enhancements.index('if puzzleIsOpen() then'),enhancements.index('local gen, distance, part = nearestGenerator()', enhancements.index('local function repairOnce()')))

if __name__=='__main__': unittest.main()
