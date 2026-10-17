#!/usr/bin/env python3
"""Build self-contained Neverlose UI bundles offline; never publishes files."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent
VENDOR = "vendor/Neverlose/Source.lua"
BRIDGE = "src/NeverloseAdapter.luau"
SERVER_SWITCH = "src/ServerSwitch.luau"
ROUTER = "src/GameRouter.luau"
MONITOR = "src/RuntimeMonitor.luau"
ROUTE_CONFIG = "src/loader_routes.json"

BLOX_MODULES = [
    ("BloxCommonFactory", "BloxStrikeCommon.luau"),
    ("BloxCloakFactory", "BloxStrikeCloak.lua"),
    ("BloxCombatFactory", "BloxStrikeCombat.luau"),
    ("BloxBulletFactory", "BloxStrikeBullet.luau"),
    ("BloxVisualFactory", "BloxStrikeVisual.luau"),
    ("BloxCosmeticFactory", "BloxStrikeCosmetic.luau"),
]
AOTR_BATTLE_MODULES = [
    ("AOTRTitansFactory", "AOTRTitans.luau"),
    ("AOTRCombatFactory", "AOTRCombat.luau"),
    ("AOTRMovementFactory", "AOTRMovement.luau"),
    ("AOTRESPFactory", "AOTRESP.luau"),
    ("AOTRFarmFactory", "AOTRFarm.luau"),
]
SCP_MODULES = [
    ("SCPCommonFactory", "SCPCommon.luau"),
    ("SCPCandidatesFactory", "SCPCandidates.luau"),
    ("SCPCloakFactory", "SCPCloak.lua"),
    ("SCPCameraFactory", "SCPCamera.luau"),
    ("SCPSilentAimFactory", "SCPSilentAim.luau"),
    ("SCPHitboxFactory", "SCPHitbox.luau"),
    ("SCPMovementFactory", "SCPMovement.luau"),
    ("SCPESPFactory", "SCPESP.luau"),
]
GAMES = {
    "Forsaken": ("ForsakenCore.luau", [("ForsakenEnhancementsFactory", "ForsakenEnhancements.luau"), ("ForsakenPuzzlePlannerFactory", "ForsakenPuzzlePlanner.luau"), ("ForsakenPuzzleAutoFactory", "ForsakenPuzzleAuto.luau")]),
    "BloxStrike": ("BloxStrikeCore.luau", BLOX_MODULES),
    "AOTR_Lobby": ("AOTRLobby.luau", [("AOTRCommon", "AOTRCommon.luau")]),
    "AOTR_Battle": ("AOTRBattle.luau", [("AOTRCommon", "AOTRCommon.luau")] + AOTR_BATTLE_MODULES),
    "SCP": ("SCPCore.luau", SCP_MODULES),
}

HEADER = (
    "-- Vortexion Neverlose - generated offline; publishing must be performed separately.\n"
    "-- Neverlose attribution is retained in vendor/Neverlose/README.md.\n"
    "-- Forsaken retains runtime model rbxassetid://132866968194043.\n"
    "-- Modify src/*.luau and run python3 build.py; do not edit this output.\n"
)
PRELOAD = (
    "local client = (getgenv and getgenv()) or _G\n"
    "local previousBridge = client.VortexionWindBridge\n"
    "if type(previousBridge) == \"table\" and type(previousBridge.Destroy) == \"function\" then\n"
    "    local ok, err = pcall(function() previousBridge:Destroy() end)\n"
    "    if not ok then warn(\"[Vortexion/UI] Previous UI cleanup: \" .. tostring(err)) end\n"
    "    if client.VortexionWindBridge == previousBridge then client.VortexionWindBridge = nil end\n"
    "    task.wait(0.5)\n"
    "end\n"
)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def embed(name, source):
    return "local " + name + " = (function()\n" + source + "\nend)()\n"


def strip_placeholder(source, name):
    pattern = r"(?m)^local " + re.escape(name) + r"\s*=\s*nil[ \t]*\n"
    matches = list(re.finditer(pattern, source))
    if len(matches) > 1:
        raise ValueError("Duplicate placeholder: " + name)
    return re.sub(pattern, "", source, count=1)


def patch_vendor_text_compat(source):
    """Normalize malformed vendor Text properties in *generated* bundles only.

    The checked-in third-party WindUI source stays byte-for-byte untouched. This
    compatibility shim operates at the shared Creator.New boundary so it also
    covers components constructed by vendored submodules.
    """
    marker = 'if z~="ThemeTag"then\nx[z]=A\nend'
    # Build unit tests also use a minimal WindUI stub without Creator.New.
    if 'function p.New(r,u,v)' not in source:
        return source
    if source.count('function p.New(r,u,v)') != 1 or source.count(marker) != 1:
        raise ValueError('WindUI Creator.New changed; review text compatibility shim')
    replacement = '''if z~="ThemeTag"then
if z=="Text" and type(A)=="table" then
    local raw=A
    local fallback=raw.Text or raw.Title or raw.Content or raw.Desc or raw.Name or raw[1] or raw.en or ""
    if type(fallback)~="string" then fallback=tostring(fallback) end
    local ctx="class="..tostring(r).." name="..tostring(u and u.Name or "?")
    local env=(getgenv and getgenv()) or _G
    env.VortexionTextCompatCount=(tonumber(env.VortexionTextCompatCount) or 0)+1
    env.VortexionTextCompatLast=ctx.." text="..string.sub(fallback,1,80)
    if env.VortexionTextCompatCount<=3 then
        warn("[Vortexion/Wind/TextCompat] "..env.VortexionTextCompatLast)
    end
    A=fallback
end
x[z]=A
end'''
    return source.replace(marker, replacement, 1)


def build(root=ROOT):
    root = Path(root)
    sources = {}
    source_hashes = {}

    def read(relative):
        if relative not in sources:
            path = root / relative
            if not path.is_file():
                raise FileNotFoundError("Wind build dependency not ready: " + str(path))
            data = path.read_bytes()
            source = data.decode("utf-8")
            source_hashes[relative] = hashlib.sha256(data).hexdigest()
            if not source.strip():
                raise ValueError("Empty build dependency: " + relative)
            sources[relative] = source
        return sources[relative]

    # The vendored WindUI banner contains trailing spaces inside its ASCII-art
    # block comment. Normalize only that embedded comment for Git whitespace
    # checks, without modifying the vendor file or its audited SHA-256.
    vendor_source = read(VENDOR)
    banner, terminator, remainder = vendor_source.partition("]]")
    if terminator and banner.startswith("--[["):
        clean_banner = "\n".join(line.rstrip(" \t") for line in banner.split("\n"))
        vendor_source = clean_banner + terminator + remainder
    shared = HEADER + PRELOAD + embed("WindUI", vendor_source)
    # Adapter closures must capture the already-declared server controller factory.
    for name, path in (("ServerSwitchFactory", SERVER_SWITCH), ("RuntimeMonitorFactory", MONITOR), ("WindBridgeFactory", BRIDGE)):
        source = read(path)
        if "return function(" not in source:
            raise ValueError("Missing factory return: " + path)
        shared += embed(name, source)
    router = read(ROUTER)
    game_bodies = {}
    outputs = {}
    for name, (core_file, modules) in GAMES.items():
        body = read("src/" + core_file)
        if re.search(r"\bStarlight(?:BridgeFactory)?\b", body):
            raise ValueError("Core WindUI rename not ready: " + core_file)
        body = strip_placeholder(strip_placeholder(body, "WindBridgeFactory"), "WindUI")
        prefix = ""
        for factory, filename in modules:
            source = read("src/" + filename)
            if "return function(" not in source:
                raise ValueError("Missing module factory return: " + filename)
            prefix += embed(factory, source)
            body = strip_placeholder(body, factory)
        # Even standalone entries retain module-local scope and their original early returns.
        game_bodies[name] = prefix + body + "\n"
        outputs["Vortexion_" + name + ".lua"] = (
            shared + embed("GameRouter", router)
            + "local entry = function()\n" + game_bodies[name] + "end\n"
            + "return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "
            + json.dumps(name) + ")\n"
        )

    unified = shared + embed("GameRouter", router)
    unified += "local GameEntries = {\n"
    for name, body in game_bodies.items():
        unified += "    [" + json.dumps(name) + "] = function()\n" + body + "    end,\n"
    unified += (
        "}\n"
        "local route, reason = GameRouter.Resolve(game.GameId, game.PlaceId)\n"
        "local entry = route and GameEntries[route] or nil\n"
        "return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, reason)\n"
    )
    outputs["Vortexion_Wind.lua"] = unified
    outputs["Vortexion_Neverlose.lua"] = unified  # preferred Neverlose name, old route alias retained

    # V2 runtime bundles: isolate UI / common services from game code.
    # Loader retrieves the shared core and only the current game's module.
    # Standalone V1 outputs remain for backwards compatibility and diagnostics.
    core_source = shared + embed("GameRouter", router) + (
        "return {WindUI=WindUI, WindBridgeFactory=WindBridgeFactory, "
        "ServerSwitchFactory=ServerSwitchFactory, GameRouter=GameRouter}\n"
    )
    modular_outputs = {"Vortexion_Core.lua": core_source}
    for name, body in game_bodies.items():
        modular_outputs["Vortexion_Module_" + name + ".lua"] = (
            HEADER
            + "return function(kernel)\n"
            + "assert(type(kernel) == 'table' and type(kernel.WindBridgeFactory) == 'function', 'Invalid Vortexion core')\n"
            + "local WindUI, WindBridgeFactory, GameRouter = kernel.WindUI, kernel.WindBridgeFactory, kernel.GameRouter\n"
            + "local entry = function()\n" + body + "end\n"
            + "return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "
            + json.dumps(name) + ")\n"
            + "end\n"
        )

    # Validate all inputs before replacing any distributable.
    dist = root / "dist"
    dist.mkdir(exist_ok=True)
    bundles = {}
    for filename, source in outputs.items():
        out = dist / filename
        out.write_text(source, encoding="utf-8")
        bundles[filename] = {"sha256": sha(out), "bytes": out.stat().st_size}
    modular_bundles = {}
    for filename, source in modular_outputs.items():
        target = dist / filename
        target.write_text(source, encoding="utf-8")
        modular_bundles[filename] = {"path": "dist/" + filename, "bytes": target.stat().st_size, "sha256": sha(target)}

    # Route manifest is generated from one checked-in data source. Assert parity
    # with the embedded legacy router, so old and new entrypoints do not diverge.
    routes = json.loads(read(ROUTE_CONFIG))
    for field in ("universes", "places", "aotr_places"):
        if not isinstance(routes.get(field), dict):
            raise ValueError("Invalid routes field: " + field)
    for field in ("universes", "places", "aotr_places"):
        for key, name in routes[field].items():
            if name not in GAMES:
                raise ValueError("Unknown route: " + field + ":" + key)
            # Legacy GameRouter uses bracketed numeric literal maps.
            token = "[" + str(int(key)) + "] = " + json.dumps(name)
            if token not in router:
                raise ValueError("Router drift: " + token)
    if "local AOTR_UNIVERSE = " + str(routes["aotr_universe"]) not in router:
        raise ValueError("AOTR universe mismatch")
    runtime_manifest = {
        "schema": 2,
        "build_tag": "loader-v2-modular-r2.22-neverlose-mobile",
        "core": modular_bundles["Vortexion_Core.lua"],
        "modules": {name: modular_bundles["Vortexion_Module_" + name + ".lua"] for name in GAMES},
        "routes": routes,
        "fallback": "standalone-bundle-manual-only",
    }
    (dist / "runtime-manifest.json").write_text(
        json.dumps(runtime_manifest, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8"
    )

    manifest = {
        "project_name": "Vortexion Neverlose",
        "build_tag": "neverlose-mobile-r222",
        "status": "local_build_unpublished",
        "publication": "not_published_to_github",
        "repository": "keepBacon/Vortexion-lua",
        "vendor_path": VENDOR,
        "vendor_sha256": source_hashes[VENDOR],
        "neverlose_source_sha256": source_hashes[VENDOR],
        "sources": {path: source_hashes[path] for path in sorted(sources)},
        "bundles": bundles,
        "outputs": sorted(bundles),
        "unified_entry": "dist/Vortexion_Neverlose.lua",
        "roblox_android_tested": False,
        "luau_compiler_tested": False,
        "old_repo_touched": False,
        "modular_bundles": modular_bundles,
        "runtime_manifest": "dist/runtime-manifest.json",
        "notice": "Offline build only; no upload or Roblox Android runtime verification.",
    }
    (dist / "build-manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return manifest


if __name__ == "__main__":
    result = build()
    for filename, metadata in result["bundles"].items():
        print(filename, metadata["bytes"], metadata["sha256"])
    print("PASS", len(result["outputs"]), "offline outputs; GitHub unpublished; Roblox Android unverified")
