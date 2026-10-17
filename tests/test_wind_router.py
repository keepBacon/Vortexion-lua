#!/usr/bin/env python3
"""Offline Wind router/build/loader checks; Lua mocks are not Roblox tests."""
from pathlib import Path
import ctypes
import ctypes.util
import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("wind_build", ROOT / "build.py")
BUILD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILD)


class LuaRuntime:
    """Run the Lua-compatible router with the locally installed Lua 5.4 library."""

    def __init__(self):
        self.web = os.environ.get("WIND_ROUTER_LUAU_WEB") == "1"
        if self.web:
            return
        library = ctypes.util.find_library("lua5.4")
        if not library:
            raise unittest.SkipTest("Lua 5.4 shared library not installed")
        self.lib = ctypes.CDLL(library)
        self.lib.luaL_newstate.restype = ctypes.c_void_p
        self.lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
        self.lib.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_char_p]
        self.lib.luaL_loadbufferx.restype = ctypes.c_int
        self.lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ssize_t, ctypes.c_void_p]
        self.lib.lua_pcallk.restype = ctypes.c_int
        self.lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
        self.lib.lua_tolstring.restype = ctypes.c_char_p
        self.lib.lua_close.argtypes = [ctypes.c_void_p]

    def run(self, source):
        if self.web:
            with tempfile.TemporaryDirectory(prefix="wind-luau-", dir=ROOT / "tests") as directory:
                script = Path(directory) / "mock.luau"
                script.write_text(source, encoding="utf-8")
                result = subprocess.run(
                    [os.environ.get("NODE_BINARY", "node"), str(ROOT / "tests/run_luau.mjs"),
                     "--execute", str(script)], cwd=ROOT, text=True, capture_output=True, timeout=30
                )
                if result.returncode:
                    raise AssertionError(result.stdout + result.stderr)
            return
        state = self.lib.luaL_newstate()
        if not state:
            raise MemoryError("luaL_newstate failed")
        try:
            self.lib.luaL_openlibs(state)
            encoded = source.encode("utf-8")
            status = self.lib.luaL_loadbufferx(state, encoded, len(encoded), b"wind-test", None)
            if status == 0:
                status = self.lib.lua_pcallk(state, 0, 0, 0, 0, None)
            if status != 0:
                error = self.lib.lua_tolstring(state, -1, None)
                raise AssertionError(error.decode("utf-8", "replace") if error else "Lua error " + str(status))
        finally:
            self.lib.lua_close(state)


MOCK_SETUP = """
__env = {Unrelated = 'preserved'}
__entries, __modules, __order, __tabs, __warnings = {}, {}, {}, {}, {}
__notifications, __paragraphs = {}, {}
__vendor_count, __bridges, __common, __settings = 0, 0, 0, 0
getgenv = function() return __env end
warn = function(message) table.insert(__warnings, message) end
task = {wait = function(seconds)
    assert(seconds == 0.5)
    table.insert(__order, 'wait')
end}
__env.VortexionWindBridge = {Destroy = function() table.insert(__order, 'destroy') end}
"""
MOCK_VENDOR = """
table.insert(__order, 'vendor')
__vendor_count = __vendor_count + 1
return {Name = 'mock-WindUI'}
"""
MOCK_BRIDGE = """
assert(type(ServerSwitchFactory) == 'function', 'ServerSwitch not captured')
return function(WindUI, config)
    assert(WindUI.Name == 'mock-WindUI')
    __bridges = __bridges + 1
    local handle
    local bridge = {Active = true, Window = function() return handle end}
    function bridge:Destroy()
        self.Active = false
        handle = nil
        if __env.VortexionWindBridge == self then __env.VortexionWindBridge = nil end
    end
    function bridge:Notify(options)
        assert(type(options) == "table")
        table.insert(__notifications, options)
    end
    function bridge:CreateWindow(options)
        __common = __common + 1
        local window = {}
        function window:AddTab(options)
            table.insert(__tabs, options.Title)
            return {AddParagraph = function(_, paragraph)
                assert(type(paragraph.Content) == "string")
                table.insert(__paragraphs, paragraph)
            end}
        end
        function window:InstallSettings(tab) __settings = __settings + 1 end
        function window:SelectTab(index) __selected = index end
        handle = window
        return window
    end
    __env.VortexionWindBridge = bridge
    return bridge
end
"""

CASES = [
    (6331902150, 0, "Forsaken"),
    (7633926880, 0, "BloxStrike"),
    (1742264997, 0, "SCP"),
    (0, 18687417158, "Forsaken"),
    (0, 114234929420007, "BloxStrike"),
    (0, 5041144419, "SCP"),
    (4658598196, 13379208636, "AOTR_Lobby"),
    (4658598196, 14916516914, "AOTR_Lobby"),
    (4658598196, 13379349730, "AOTR_Battle"),
    (4658598196, 14638336319, "AOTR_Battle"),
    (4658598196, 14012874501, "AOTR_Battle"),
    (4658598196, 13904207646, "AOTR_Battle"),
    (4658598196, 14932214603, None),
    (4658598196, 999, None),
    (4658598196, 18687417158, None),
    (999, 999, None),
    (0, 13379349730, None),
    (6331902150, 5041144419, "Forsaken"),
    (6331902151, 18687417159, None),
]


def write_fixture(root):
    for path, source in ((BUILD.VENDOR, MOCK_VENDOR), (BUILD.BRIDGE, MOCK_BRIDGE),
                         (BUILD.SERVER_SWITCH, "return function(tab, notify) return {} end\n"),
                         (BUILD.ROUTER, (ROOT / BUILD.ROUTER).read_text(encoding="utf-8"))):
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(source, encoding="utf-8")
    for name, (core, modules) in BUILD.GAMES.items():
        body = "local WindBridgeFactory = nil\nlocal WindUI = nil\n"
        for factory, filename in modules:
            body += "local " + factory + " = nil\n"
            (root / "src" / filename).write_text(
                "table.insert(__modules, " + json.dumps(factory) + ")\nreturn function() end\n", encoding="utf-8"
            )
        for factory, _ in modules:
            body += "assert(type(" + factory + ") == 'function')\n"
        body += "local bridge = WindBridgeFactory(WindUI, {})\nbridge:CreateWindow({})\n"
        body += "table.insert(__entries, " + json.dumps(name) + ")\nreturn " + json.dumps(name) + "\n"
        (root / "src" / core).write_text(body, encoding="utf-8")


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="wind-router-", dir=ROOT / "tests")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        write_fixture(self.root)
        self.manifest = BUILD.build(self.root)

    def test_six_outputs_manifest_and_determinism(self):
        self.assertEqual(len(self.manifest["outputs"]), 6)
        self.assertFalse(self.manifest["roblox_android_tested"])
        self.assertEqual(self.manifest["publication"], "not_published_to_github")
        self.assertEqual(self.manifest["vendor_sha256"], BUILD.sha(self.root / BUILD.VENDOR))
        for filename, metadata in self.manifest["bundles"].items():
            output = self.root / "dist" / filename
            self.assertEqual(metadata["sha256"], BUILD.sha(output))
            self.assertEqual(metadata["bytes"], output.stat().st_size)
        self.assertEqual(self.manifest, BUILD.build(self.root))

    def test_manifest_hashes_the_consumed_source_snapshot(self):
        previous_hash = BUILD.sha(self.root / BUILD.VENDOR)
        mkdir = Path.mkdir

        def change_source_after_render(path, *args, **kwargs):
            if path == self.root / "dist":
                (self.root / BUILD.VENDOR).write_text(MOCK_VENDOR + "-- edited after render\n", encoding="utf-8")
            return mkdir(path, *args, **kwargs)

        with mock.patch.object(Path, "mkdir", new=change_source_after_render):
            manifest = BUILD.build(self.root)
        self.assertEqual(manifest["vendor_sha256"], previous_hash)
        self.assertEqual(manifest["sources"][BUILD.VENDOR], previous_hash)
        self.assertNotEqual(BUILD.sha(self.root / BUILD.VENDOR), previous_hash)
        source = (self.root / "dist/Vortexion_Wind.lua").read_text(encoding="utf-8")
        self.assertNotIn("edited after render", source)

    def test_single_vendor_and_no_ui_placeholders(self):
        for filename in self.manifest["outputs"]:
            source = (self.root / "dist" / filename).read_text(encoding="utf-8")
            self.assertEqual(source.count("local WindUI = (function()"), 1)
            self.assertNotIn("local WindUI = nil", source)
            self.assertNotIn("local WindBridgeFactory = nil", source)
            self.assertNotIn("vendor/Starlight", source)
            self.assertIn("rbxassetid://132866968194043", source)
            self.assertLess(source.index("local ServerSwitchFactory"), source.index("local WindBridgeFactory"))

    def test_missing_dependency_leaves_dist_unchanged(self):
        output = self.root / "dist/Vortexion_Wind.lua"
        previous = output.read_bytes()
        (self.root / BUILD.SERVER_SWITCH).unlink()
        with self.assertRaisesRegex(FileNotFoundError, "dependency not ready"):
            BUILD.build(self.root)
        self.assertEqual(previous, output.read_bytes())

    def test_duplicate_placeholder_fails(self):
        with self.assertRaisesRegex(ValueError, "Duplicate placeholder"):
            BUILD.strip_placeholder("local WindUI = nil\nlocal WindUI = nil\n", "WindUI")

    def test_generated_unified_routes_only_one_game(self):
        lua = LuaRuntime()
        source = (self.root / "dist/Vortexion_Wind.lua").read_text(encoding="utf-8")
        for universe, place, expected in CASES:
            with self.subTest(universe=universe, place=place):
                expected_lua = json.dumps(expected) if expected else "nil"
                module_count = len(BUILD.GAMES[expected][1]) if expected else 0
                setup = MOCK_SETUP + f"game = {{GameId={universe}, PlaceId={place}}}\n"
                check = (
                    f"local expected = {expected_lua}\n"
                    "assert(#__entries == (expected and 1 or 0), 'wrong entry count')\n"
                    "assert(__entries[1] == expected, 'wrong game entry')\n"
                    f"assert(#__modules == {module_count}, 'foreign game module initialized')\n"
                    "assert(__vendor_count == 1 and __bridges == 1 and __common == 1)\n"
                    "assert(__order[1] == 'destroy' and __order[2] == 'wait' and __order[3] == 'vendor')\n"
                    "assert(__env.Unrelated == 'preserved')\n"
                    "if not expected then assert(#__tabs == 1 and __settings == 0 and __selected == 1) end\n"
                )
                lua.run(setup + "local result = (function()\n" + source + "\nend)()\n" + check)

    def test_entry_early_return_and_errors_keep_one_generic_window(self):
        lua = LuaRuntime()
        cases = [
            ("return nil\n", False, "游戏入口提前结束"),
            ("local bridge = WindBridgeFactory(WindUI, {})\nreturn nil\n", False, "游戏入口提前结束"),
            ("error('fixture initialization failure')\n", False, "fixture initialization failure"),
            ("local bridge = WindBridgeFactory(WindUI, {})\nbridge:CreateWindow({})\n"
             "error('fixture after window failure')\n", True, "fixture after window failure"),
        ]
        for body, has_window, detail in cases:
            (self.root / "src/ForsakenCore.luau").write_text(body, encoding="utf-8")
            BUILD.build(self.root)
            for filename in ("Vortexion_Wind.lua", "Vortexion_Forsaken.lua"):
                with self.subTest(body=body, output=filename):
                    source = (self.root / "dist" / filename).read_text(encoding="utf-8")
                    expected_bridges = 2 if "WindBridgeFactory" in body and not has_window else 1
                    check = f"assert(__bridges == {expected_bridges} and __common == 1 and __env.VortexionWindBridge:Window())\n"
                    check += "assert(#__warnings > 0)\n"
                    if has_window:
                        check += "assert(#__notifications == 1 and #__tabs == 0)\n"
                        check += "assert(__notifications[1].Content:find(" + json.dumps(detail) + ", 1, true))\n"
                    else:
                        check += "assert(#__notifications == 0 and #__tabs == 1 and __settings == 0)\n"
                        check += "assert(__paragraphs[1].Content:find(" + json.dumps(detail, ensure_ascii=False) + ", 1, true))\n"
                    lua.run(MOCK_SETUP + "game = {GameId=6331902150, PlaceId=0}\n"
                            + "local result = (function()\n" + source + "\nend)()\n" + check)

    def test_generic_ui_failure_warns_without_claiming_window(self):
        (self.root / BUILD.BRIDGE).write_text(
            "return function(WindUI, config) error('fixture library failure') end\n", encoding="utf-8")
        BUILD.build(self.root)
        source = (self.root / "dist/Vortexion_Wind.lua").read_text(encoding="utf-8")
        LuaRuntime().run(MOCK_SETUP + "game = {GameId=0, PlaceId=0}\n"
                         + "local result = (function()\n" + source + "\nend)()\n"
                         + "assert(result == nil and __env.VortexionWindBridge == nil and __common == 0)\n"
                         + "assert(#__warnings == 1 and __warnings[1]:find('fixture library failure', 1, true))\n")

    def test_all_standalone_entries_execute(self):
        lua = LuaRuntime()
        for name, (_, modules) in BUILD.GAMES.items():
            with self.subTest(game=name):
                source = (self.root / "dist" / ("Vortexion_" + name + ".lua")).read_text(encoding="utf-8")
                lua.run(MOCK_SETUP + "game = {GameId=0, PlaceId=0}\nlocal result = (function()\n" + source +
                        "\nend)()\nassert(#__entries == 1 and __entries[1] == " + json.dumps(name) + ")\n" +
                        f"assert(#__modules == {len(modules)} and __vendor_count == 1)\n")


class RouterTests(unittest.TestCase):
    def test_numeric_strings_and_aotr_guard(self):
        source = (ROOT / BUILD.ROUTER).read_text(encoding="utf-8")
        LuaRuntime().run("local Router = (function()\n" + source + "\nend)()\n" + """
assert(Router.Resolve('6331902150', '5041144419') == 'Forsaken')
assert(Router.Resolve(nil, nil) == nil)
assert(Router.Resolve('bad', 'bad') == nil)
local route, reason = Router.Resolve(4658598196, 5041144419)
assert(route == nil and reason == 'unsupported-aotr-scene')
""")


class LoaderTests(unittest.TestCase):
    def run_loader(self, base, code="__loaded = true", transport_error=False):
        loader = (ROOT / "loader.lua").read_text(encoding="utf-8")
        encoded_base = "nil" if base is None else json.dumps(base)
        setup = (
            "local env = {VortexionSourceBase = " + encoded_base + "}\n"
            "getgenv = function() return env end\n"
            "loadstring = load\n__requests, __warnings = {}, {}\n"
            "warn = function(message) table.insert(__warnings, message) end\n"
            "game = {HttpGet = function(_, url) table.insert(__requests, url)\n"
        )
        setup += "error('transport failed')\n" if transport_error else "return " + json.dumps(code) + "\n"
        return setup + "end}\n(function()\n" + loader + "\nend)()\n"

    def test_base_override_and_only_unified_download(self):
        LuaRuntime().run(self.run_loader("https://example.test/wind///") + """
assert(#__requests == 1 and __requests[1] == 'https://example.test/wind/dist/Vortexion_Wind.lua')
assert(__loaded and #__warnings == 0)
""")

    def test_default_is_explicitly_unpublished(self):
        LuaRuntime().run(self.run_loader(None) + """
assert(#__requests == 1 and __requests[1] == 'https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/dist/Vortexion_Wind.lua')
assert(#__warnings == 1 and string.find(__warnings[1], 'not published', 1, true))
""")

    def test_invalid_base_does_not_download(self):
        lua = LuaRuntime()
        for base in ("", "file:///tmp", "ftp://example.test", 123, False):
            with self.subTest(base=base):
                lua.run(self.run_loader(base) + "assert(#__requests == 0 and #__warnings == 1)\n")

    def test_transport_compile_and_runtime_errors_are_reported(self):
        lua = LuaRuntime()
        for code, transport in (("", True), ("this is not lua", False), ("error('entry failed')", False)):
            with self.subTest(code=code, transport=transport):
                lua.run(self.run_loader("https://example.test", code, transport) +
                        "assert(#__requests == 1 and #__warnings == 1 and string.find(__warnings[1], 'Load failed', 1, true))\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
