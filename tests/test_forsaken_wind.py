#!/usr/bin/env python3
"""Forsaken WindUI migration invariants; does not simulate Roblox runtime."""
from pathlib import Path
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT / "src/ForsakenCore.luau").read_text(encoding="utf-8")
GUEST = (ROOT / "src/ForsakenGuest.luau").read_text(encoding="utf-8")
OPTION = re.compile(r'Add(?:Toggle|Slider|Dropdown|Input)\(\s*"([^"]+)"')

def assert_migration():
    for source in (CORE, GUEST):
        assert "Starlight" not in source
        assert 'Instance.new("TextButton")' not in source
    assert "local WindBridgeFactory = nil" in CORE
    assert "local WindUI = nil" in CORE
    assert "return WindBridgeFactory(WindUI)" in CORE
    assert "FORSAKEN_WIND_BUNDLE_HEADER" in CORE
    assert "LoadAutoloadConfig" not in CORE
    assert "ExtraLabels" not in CORE
    assert "ThemeOptions" not in CORE
    assert "CreateMobileLauncher" not in CORE
    assert "https://pastebin.com/raw/ztnYv27k" not in CORE
    assert "guest.triggerFakeBlock()" in CORE
    assert CORE.count('Instance.new("ScreenGui")') == 1
    assert 'videoGui = Instance.new("ScreenGui")' in CORE
    assert 'Instance.new("ScreenGui")' not in GUEST
    assert CORE.index("local Window, Tabs, Fluent") < CORE.index("local function KillerEmoteGUI()")
    assert "local success, Fluent" not in CORE
    assert 'remote:FireServer("PlayEmote", "Animations", name)' in CORE
    assert "for slot = 1, 8 do" in CORE
    assert "getEquippedEmotes()[emoteSlot]" in CORE
    assert "Window:SelectTab(6)" in CORE
    assert "Window:SelectTab(7)" in CORE
    titles = re.findall(r'Window:AddTab\(\{\s*Title\s*=\s*"([^"]+)"', CORE)
    assert len(titles) == 7, titles
    assert 'Tabs.System:AddSlider("ForsakenFOVValue"' in CORE
    assert 'Tabs.System:AddToggle("ForsakenFOVEnabled"' in CORE
    assert "math.min(fovValue, 120)" in CORE
    assert "Tabs.Stats:AddButton" in CORE
    assert "native:SetTitle(updatedText)" in CORE
    assert 'setclipboard(LocalPlayer.Name .. " - " .. timeText)' in CORE
    assert "Fluent:OnDestroy(function()" in CORE
    assert "statsGui:Destroy()" in CORE
    assert "while true do" not in CORE
    assert 'Tabs.Guest:AddToggle("GuestFakeBlockGui"' in GUEST
    assert "Callback = triggerFakeBlock" in GUEST
    assert "guestState.FakeBlock" in GUEST
    assert "buildFakeBlockGui = buildFakeBlockGui" in GUEST
    assert "destroyFakeBlockGui = destroyFakeBlockGui" in GUEST
    assert "ensureSingleGui = ensureSingleGui" in GUEST

def compare_baseline(archive):
    with zipfile.ZipFile(archive) as bundle:
        for name, current in (("ForsakenCore.luau", CORE), ("ForsakenGuest.luau", GUEST)):
            path = next(p for p in bundle.namelist() if p.endswith("src/" + name))
            original = bundle.read(path).decode("utf-8")
            assert sorted(OPTION.findall(original)) == sorted(OPTION.findall(current)), name
            if name == "ForsakenCore.luau":
                start = original.index("local timeAhead = 0.2")
                end = original.index("-- Stats tracker UI creation")
                # This entire game/ESP section survives byte-for-byte.
                assert original[start:end] in current
            print(f"{name}: option IDs preserved ({len(OPTION.findall(current))})")

if __name__ == "__main__":
    assert_migration()
    if len(sys.argv) > 1:
        compare_baseline(sys.argv[1])
    print("Forsaken WindUI static migration: pass")
