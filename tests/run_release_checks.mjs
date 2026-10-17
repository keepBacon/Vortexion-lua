import fs from "node:fs";
import path from "node:path";
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
const node = process.env.NODE_BINARY || process.execPath;
const nodeLauncher = process.env.NODE_LAUNCHER;
const python = process.env.PYTHON_BINARY || "python3";
const lua = process.env.LUA_BINARY || "lua5.4";
const env = { ...process.env, WIND_ROUTER_LUAU_WEB: "0", NODE_BINARY: node };
const hash = file => createHash("sha256").update(fs.readFileSync(path.join(root, file))).digest("hex");
const snapshotTests = () => {
    const snapshot = {};
    for (const name of fs.readdirSync(path.join(root, "tests")).sort()) {
        if ([".mjs", ".luau", ".lua", ".py"].includes(path.extname(name)) || name === "wind_option_ids_baseline.json") snapshot["tests/" + name] = hash("tests/" + name);
    }
    for (const file of ["build.py", "tools/package_release.py"]) snapshot[file] = hash(file);
    return snapshot;
};
const testHashes = snapshotTests();
const cases = [];
const add = (name, command, args) => cases.push({ name, command, args });
const addNode = (name, args) => add(name, nodeLauncher || node, nodeLauncher ? [node, ...args] : args);
const luau = (name, factory, test) => addNode(name, ["tests/run_luau.mjs", "--execute", "--factory", factory, test]);
add("build-six-bundles", python, ["build.py"]);
addNode("release-runner-contracts", ["tests/test_release_runner.mjs"]);
add("release-package-contracts", python, ["tests/test_package_release.py"]);
luau("shared-adapter", "src/WindAdapter.luau", "tests/test_wind_adapter.luau");
addNode("native-contracts", ["tests/run_wind_native_contracts.mjs"]);
addNode("wind-visual-budget-r14", ["tests/run_wind_visual_budget_r14.mjs"]);
addNode("wind-viewport-edges-r14", ["tests/run_wind_viewport_edges_r14.mjs"]);
addNode("wind-input-queue-r14", ["tests/run_wind_input_queue_r14.mjs"]);
addNode("wind-acrylic-policy-r16", ["tests/run_wind_acrylic_policy_r16.mjs"]);
addNode("aotr-hud-contract-r18", ["tests/run_aotr_hud_contract_r18.mjs"]);
addNode("local-features-r19", ["tests/run_local_features_r19.mjs"]);
addNode("visual-resources-r20", ["tests/run_visual_resources_r20.mjs"]);
add("server-switch", lua, ["tests/test_server_switch.lua"]);
add("wind-router", python, ["tests/test_wind_router.py"]);
add("migration-ids-and-hashes", python, ["tests/test_wind_migration.py"]);
add("forsaken-wind-static", python, ["tests/test_forsaken_wind.py"]);
for (const name of ["forsaken", "bloxstrike", "scp"]) addNode(name + "-enrichment", ["tests/run_" + name + "_enrichment.mjs"]);
add("aotr-static", python, ["tests/test_aotr.py"]);
for (const name of ["Common", "Titans", "Combat", "Movement", "ESP", "Farm", "Cloak"]) {
    luau("aotr-" + name.toLowerCase() + "-factory", "src/AOTR" + name + (name === "Cloak" ? ".lua" : ".luau"), "tests/test_aotr_enrichment.luau");
}
luau("aotr-lobby-camera", "src/AOTRLobby.luau", "tests/test_aotr_lobby_runtime.luau");
luau("aotr-property-restoration", "src/AOTRMovement.luau", "tests/test_aotr_movement_lifecycle.luau");
luau("aotr-render-lifecycle", "src/AOTRESP.luau", "tests/test_aotr_esp_lifecycle.luau");
luau("aotr-cache-lifecycle", "src/AOTRTitans.luau", "tests/test_aotr_titans_lifecycle.luau");
luau("aotr-common-lifecycle", "src/AOTRCommon.luau", "tests/test_aotr_common_lifecycle.luau");
addNode("aotr-entry-lifecycle", ["tests/run_aotr_entry_lifecycle.mjs"]);
addNode("compile-active-sources-and-six-bundles", ["tests/run_luau.mjs"]);

const results = [];
for (const item of cases) {
    const started = Date.now();
    const result = spawnSync(item.command, item.args, { cwd: root, env, encoding: "utf8", timeout: 60000, maxBuffer: 8 * 1024 * 1024 });
    const skipped = /\b(?:skipped|SkipTest)\b/i.test((result.stdout || "") + (result.stderr || ""));
    const passed = result.status === 0 && !result.error && !skipped;
    results.push({ ...item, passed, skipped, exitCode: result.status, durationMs: Date.now() - started, stdout: result.stdout || "", stderr: result.stderr || "", error: result.error ? String(result.error) : null });
    console.log((passed ? "PASS " : "FAIL ") + item.name);
    if (!passed) { console.error(result.stdout || "", result.stderr || "", result.error || ""); break; }
}
const testsStable = JSON.stringify(testHashes) === JSON.stringify(snapshotTests());
const manifestPath = path.join(root, "dist/build-manifest.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const inputsStable = Object.entries(manifest.sources).every(([file, expected]) => hash(file) === expected);
const outputsStable = Object.entries(manifest.bundles).every(([file, metadata]) => hash("dist/" + file) === metadata.sha256 && fs.statSync(path.join(root, "dist/", file)).size === metadata.bytes);
const passed = results.length === cases.length && results.every(item => item.passed) && inputsStable && outputsStable && testsStable;
if (passed) {
    manifest.luau_compiler_tested = true;
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n");
}
const evidence = {
    stage: "wind_release_checks", status: passed ? "offline_verified_runtime_unverified" : "failed",
    generatedAt: new Date().toISOString(), expectedStages: cases.length, passedStages: results.filter(item => item.passed).length,
    engine: "luau-web 1.5.1", router_and_server_switch_engine: "Lua 5.4", inputsStable, outputsStable, testsStable, source_sha256: manifest.sources, test_sha256: testHashes,
    bundles: manifest.bundles, build_manifest_sha256: hash("dist/build-manifest.json"), results,
    roblox_android_tested: false, roblox_pc_tested: false, game_features_live_verified: false,
    publication: "not_published_to_github", reference_loaders_executed: false,
    notes: ["Native contracts execute selected unmodified vendor function bodies in an instrumented Luau fixture, not the full Roblox GUI.", "Game mocks, compiler and router/build gates do not prove live game protocols or Android rendering.", "The shared fixture callback failure warning is intentionally injected and asserted."]
};
fs.writeFileSync(path.join(root, "tests/release-test-results.json"), JSON.stringify(evidence, null, 2) + "\n");
console.log((passed ? "PASS " : "FAIL ") + results.filter(item => item.passed).length + "/" + cases.length + " release stages; source/output hashes " + (inputsStable && outputsStable && testsStable ? "stable" : "changed") + "; Roblox runtime unverified");
process.exitCode = passed ? 0 : 1;
