"""R228 UI visual contract checks (source + mock APIs; no Roblox render host)."""
import unittest,re
from pathlib import Path
from test_wind_router import LuaRuntime
R=Path(__file__).resolve().parents[1]
class VisualR228(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.ui=(R/'vendor/Neverlose/Source.lua').read_text()
  cls.adapter=(R/'src/NeverloseAdapter.luau').read_text()
 def test_source_lua_parses(self):
  LuaRuntime().run('local function compile_only()\n'+self.ui+'\nend')
 def test_theme_consistent(self):
  for color in ('Color3.fromRGB(15, 19, 21)','Color3.fromRGB(23, 29, 32)','Color3.fromRGB(103, 181, 191)'):
   self.assertIn(color,self.ui)
  self.assertNotIn('Color3.fromRGB(48, 168, 254)',self.ui)
  self.assertNotIn('Color3.fromRGB(3, 168, 245)',self.ui)
 def test_tab_selection_resets_other_icons(self):
  self.assertIn('local active = other == Tab',self.ui)
  self.assertIn('other.TabTitle.TextColor3 = active',self.ui)
  self.assertIn('ico.ImageColor3 = active',self.ui)
  self.assertIn('function Sections:Select()',self.ui)
 def test_section_bounds_content_driven(self):
  self.assertIn('local function syncSectionBounds()',self.ui)
  self.assertIn('SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize")',self.ui)
  self.assertIn('SectionHolder1Layout:GetPropertyChangedSignal("AbsoluteContentSize")',self.ui)
  self.assertNotIn('CanvasSize.Y.Offset + UniNum',self.ui)
  self.assertIn('openPopupExtra',self.ui)
 def test_popup_anchoring_and_bounded_animation(self):
  self.assertIn('DropdownFrameHold.Parent = Dropdown',self.ui)
  self.assertIn('DropdownFrameHold.Position = UDim2.fromOffset(8, 33)',self.ui)
  self.assertIn('DropToggled = not DropToggled',self.ui)
  self.assertNotIn('repeat task.wait() until DropdownFrameHold.Size',self.ui)
  self.assertNotIn('repeat task.wait() until SearchBar.Size',self.ui)
  self.assertIn('Item.Size = UDim2.fromOffset(230, 30)',self.ui)
 def test_touch_and_visibility(self):
  self.assertIn('input.UserInputType == Enum.UserInputType.Touch',self.ui)
  self.assertIn('TouchHitbox',self.ui)
  self.assertIn('if v:IsA("GuiObject")',self.ui)
  self.assertNotIn('local state = t or nil',self.ui)
 def test_text_length_and_columns(self):
  for name,wide in [('ToggleTitle',194),('ButtonTitle',194),('DropdownTitle',166),('SliderTitle',128),('SectionTitle',250)]:
   self.assertIn(f'{name}.Size = UDim2.new(0, {wide}, 0, ',self.ui)
  self.assertIn('Section.Parent = (nativeSectionCount % 2 == 1) and SectionHolder1 or SectionHolder2',self.ui)
  self.assertIn('Container.ScrollBarThickness = 3',self.ui)
 def test_icon_ids_are_vendor_shipped(self):
  assets=re.findall(r"(?:id=|rbxassetid://)(\d+)",self.ui)
  ids=dict(re.findall(r"(\w+)='(\d+)'",self.adapter.split('local navIcons = {',1)[1].split('}',1)[0]))
  self.assertTrue(ids)
  for _key,asset in ids.items():self.assertIn(asset,assets)
 def test_every_branch_embeds_new_assets(self):
  for name in ['Vortexion_SCP.lua','Vortexion_BloxStrike.lua','Vortexion_Neverlose.lua']:
   bundle=(R/'dist'/name).read_text()
   self.assertIn('VortexionSCPESP2D',bundle) if name=='Vortexion_SCP.lua' else None
   self.assertIn('function Tabs:Tab(title, iconAsset)',bundle)
if __name__=='__main__':unittest.main()
