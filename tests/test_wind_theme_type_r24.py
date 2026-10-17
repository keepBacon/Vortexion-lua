"""R2.4: real vendor SetTheme -> Dropdown.Display type-failure regression."""
from pathlib import Path
import hashlib
import unittest
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from test_wind_router import LuaRuntime

VENDOR = ROOT / "vendor/WindUI/Source.lua"
ADAPTER = ROOT / "src/WindAdapter.luau"


def block(source: str, before: str, after: str) -> str:
    start = source.index(before)
    end = source.index(after, start)
    return source[start:end]


class WindThemeRootFix(unittest.TestCase):
    def test_prove_vendor_table_to_text_regression_and_fix(self):
        vendor = VENDOR.read_text(encoding="utf-8")
        adapter = ADAPTER.read_text(encoding="utf-8")
        # Actual vendor functions, not rewritten equivalent mocks.
        theme_functions = block(vendor, "function aa.SetTheme(az,aA)", "function aa.GetTransparency(az)")
        dropdown_display = block(vendor, "function as.Display(au)", "local function Callback(au)")
        resolver = block(adapter, "        local function resolveThemeName(configuredName)", "        local themeOption =")
        fixture = r'''
local aa = {Themes = {Dark = {Name = 'Dark', Background = {}}, Light = {Name = 'Light', Background = {}}}}
local as = {SetTheme = function() end}
''' + theme_functions + r'''
local WindUI = aa
local function themes()
    local names = {}
    for key in pairs(WindUI:GetThemes()) do table.insert(names, key) end
    table.sort(names)
    return names
end
''' + resolver + r'''
local function textLabel()
    return setmetatable({}, {__newindex = function(self, key, value)
        if key == 'Text' and type(value) ~= 'string' then
            error('Unable to assign property Text. string expected, got ' .. type(value))
        end
        rawset(self, key, value)
    end})
end
local ap = {Multi = false, UIElements = {Dropdown = {Frame = {Frame = {TextLabel = textLabel()}}}}}
local as = {}
typeof = type
''' + dropdown_display + r'''
assert(aa:SetTheme('Dark') ~= nil)
assert(type(WindUI.Theme) == 'table')
-- Reproduce old adapter fallback and its exact vendor failure.
ap.Value = WindUI.Theme
local oldOK, oldErr = pcall(function() as:Display() end)
assert(not oldOK and oldErr:find('string expected, got table', 1, true))
assert(resolveThemeName(nil) == 'Dark')
assert(resolveThemeName('Light') == 'Light')
assert(resolveThemeName('NotRegistered') == 'Dark')
assert(resolveThemeName({Name = 'Light'}) == 'Dark')
ap.Value = resolveThemeName(nil)
as:Display()
assert(ap.UIElements.Dropdown.Frame.Frame.TextLabel.Text == 'Dark')
ap.Value = resolveThemeName('Light')
as:Display()
assert(ap.UIElements.Dropdown.Frame.Frame.TextLabel.Text == 'Light')
'''
        LuaRuntime().run(fixture)

    def test_no_bad_default_in_sources_or_bundles(self):
        old = 'config.Theme or WindUI.Theme or "Dark"'
        self.assertNotIn(old, ADAPTER.read_text(encoding="utf-8"))
        for file in sorted((ROOT / 'dist').glob('Vortexion_*.lua')):
            self.assertNotIn(old, file.read_text(encoding='utf-8'), file.name)
        self.assertEqual(hashlib.sha256(VENDOR.read_bytes()).hexdigest(),
                         'e29ebad6907d6293731d1de042d6aec4a9428fcddbed8a8f19ef5f4ce05c6d05')

    def test_build_contains_string_validated_theme_selection(self):
        for name in ('Vortexion_Core.lua', 'Vortexion_Wind.lua', 'Vortexion_Forsaken.lua'):
            content=(ROOT/'dist'/name).read_text('utf-8')
            self.assertIn('Default = resolveThemeName(config.Theme)', content)
            self.assertIn('local function resolveThemeName(configuredName)', content)

if __name__ == '__main__':
    unittest.main()
