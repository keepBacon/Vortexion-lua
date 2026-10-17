import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import vm from "node:vm";
import { createHash } from "node:crypto";
const source = fs.readFileSync(new URL("run_release_checks.mjs", import.meta.url), "utf8");
const executable = source.split("\n").filter(line => !line.startsWith("import ")).join("\n").replaceAll("import.meta.url", JSON.stringify("file:///fixture/tests/run_release_checks.mjs"));
const sha = data => createHash("sha256").update(data).digest("hex");
const success = { status: 0, stdout: "PASS fixture", stderr: "" };
const shared = [
    ["wind-visual-budget-r14", "run_wind_visual_budget_r14.mjs", "test_wind_visual_budget_r14.luau"],
    ["wind-viewport-edges-r14", "run_wind_viewport_edges_r14.mjs", "test_wind_viewport_edges_r14.luau"],
    ["wind-input-queue-r14", "run_wind_input_queue_r14.mjs", "test_wind_input_queue_r14.luau"],
    ["wind-acrylic-policy-r16", "run_wind_acrylic_policy_r16.mjs", "test_wind_acrylic_policy_r16.luau"],
    ["aotr-hud-contract-r18", "run_aotr_hud_contract_r18.mjs", "test_aotr_hud_contract_r18.luau"],
    ["local-features-r19", "run_local_features_r19.mjs", "test_local_features_r19.luau"],
    ["visual-resources-r20", "run_visual_resources_r20.mjs", "test_visual_resources_r20.luau"]
];
// Independent inventory pins every pre-existing stage, including its exact arguments.
const original = [
    ["build-six-bundles", "python", ["build.py"]],
    ["release-runner-contracts", "node", ["tests/test_release_runner.mjs"]],
    ["release-package-contracts", "python", ["tests/test_package_release.py"]],
    ["shared-adapter", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/WindAdapter.luau", "tests/test_wind_adapter.luau"]],
    ["native-contracts", "node", ["tests/run_wind_native_contracts.mjs"]],
    ["server-switch", "lua", ["tests/test_server_switch.lua"]],
    ["wind-router", "python", ["tests/test_wind_router.py"]],
    ["migration-ids-and-hashes", "python", ["tests/test_wind_migration.py"]],
    ["forsaken-wind-static", "python", ["tests/test_forsaken_wind.py"]],
    ["forsaken-enrichment", "node", ["tests/run_forsaken_enrichment.mjs"]],
    ["bloxstrike-enrichment", "node", ["tests/run_bloxstrike_enrichment.mjs"]],
    ["scp-enrichment", "node", ["tests/run_scp_enrichment.mjs"]],
    ["aotr-static", "python", ["tests/test_aotr.py"]],
    ["aotr-common-factory", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRCommon.luau", "tests/test_aotr_enrichment.luau"]],
    ["aotr-titans-factory", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRTitans.luau", "tests/test_aotr_enrichment.luau"]],
    ["aotr-combat-factory", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRCombat.luau", "tests/test_aotr_enrichment.luau"]],
    ["aotr-movement-factory", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRMovement.luau", "tests/test_aotr_enrichment.luau"]],
    ["aotr-esp-factory", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRESP.luau", "tests/test_aotr_enrichment.luau"]],
    ["aotr-farm-factory", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRFarm.luau", "tests/test_aotr_enrichment.luau"]],
    ["aotr-cloak-factory", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRCloak.lua", "tests/test_aotr_enrichment.luau"]],
    ["aotr-lobby-camera", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRLobby.luau", "tests/test_aotr_lobby_runtime.luau"]],
    ["aotr-property-restoration", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRMovement.luau", "tests/test_aotr_movement_lifecycle.luau"]],
    ["aotr-render-lifecycle", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRESP.luau", "tests/test_aotr_esp_lifecycle.luau"]],
    ["aotr-cache-lifecycle", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRTitans.luau", "tests/test_aotr_titans_lifecycle.luau"]],
    ["aotr-common-lifecycle", "node", ["tests/run_luau.mjs", "--execute", "--factory", "src/AOTRCommon.luau", "tests/test_aotr_common_lifecycle.luau"]],
    ["aotr-entry-lifecycle", "node", ["tests/run_aotr_entry_lifecycle.mjs"]],
    ["compile-active-sources-and-six-bundles", "node", ["tests/run_luau.mjs"]]
];
const expected = [...original.slice(0, 5), ...shared.map(([name, file]) => [name, "node", ["tests/" + file]]), ...original.slice(5)];
function run(mutate, result = success, environment = {}) {
    const files = new Map([["build.py", "builder"], ["tools/package_release.py", "packager"], ["src/mock.luau", "source"], ["tests/mock.luau", "test"], ["tests/wind_option_ids_baseline.json", "{}"], ["dist/fixture.lua", "bundle"]]);
    for (const [, runner, test] of shared) { files.set("tests/" + runner, "runner"); files.set("tests/" + test, "test"); }
    files.set("dist/build-manifest.json", JSON.stringify({ sources: { "src/mock.luau": sha("source") }, bundles: { "fixture.lua": { sha256: sha("bundle"), bytes: 6 } }, luau_compiler_tested: false }));
    const relative = file => String(file).replace("/fixture/", "");
    const writes = [];
    const mockFs = {
        readFileSync(file) { const key = relative(file); assert(files.has(key), "missing fixture " + key); return files.get(key); },
        writeFileSync(file, data) { writes.push(relative(file)); files.set(relative(file), data); },
        statSync(file) { return { size: Buffer.byteLength(files.get(relative(file))) }; },
        readdirSync() { return [...files.keys()].filter(key => key.startsWith("tests/")).map(key => key.slice(6)); }
    };
    const process = { env: { NODE_BINARY: "/fixture/node", PYTHON_BINARY: "/fixture/python", LUA_BINARY: "/fixture/lua", ...environment }, execPath: "/fixture/current-node", exitCode: undefined };
    const invocations = [];
    vm.runInNewContext(executable, { fs: mockFs, path, assert, createHash, URL, Date, JSON, fileURLToPath: () => "/fixture/", process, console: { log() {}, error() {} },
        spawnSync(command, args, options) {
            invocations.push({ command, args: [...args], cwd: options.cwd, env: { ...options.env } });
            if (invocations.length === 1 && mutate) mutate(files);
            return typeof result === "function" ? result({ command, args, options, files, call: invocations.length }) : result;
        }
    }, { timeout: 3000 });
    return { report: JSON.parse(files.get("tests/release-test-results.json")), manifest: JSON.parse(files.get("dist/build-manifest.json")), exitCode: process.exitCode, calls: invocations.length, invocations, writes };
}
let suites = 0;
function check(name, fn) { fn(); suites++; console.log("PASS " + name); }
function failed(r) {
    assert.equal(r.exitCode, 1);
    assert.equal(r.report.status, "failed");
    assert.equal(r.manifest.luau_compiler_tested, false);
    assert(!r.writes.includes("dist/build-manifest.json"), "failed verification must never promote compiler evidence");
}
check("stable input snapshot promotes compiler evidence", () => { const r = run(); assert.equal(r.exitCode, 0); assert.equal(r.report.testsStable, true); assert.equal(r.manifest.luau_compiler_tested, true); assert.equal(r.report.passedStages, 34); assert.equal(r.report.expectedStages, 34); });
for (const [name, file] of [["test changed during execution", "tests/mock.luau"], ["baseline changed during execution", "tests/wind_option_ids_baseline.json"], ["new unexecuted test appeared", "tests/new.luau"], ["packager changed during verification", "tools/package_release.py"], ["builder changed during verification", "build.py"]]) {
    check(name, () => { const r = run(files => files.set(file, "changed")); failed(r); assert.equal(r.report.testsStable, false); });
}
for (const [name, file, field] of [["source input changed", "src/mock.luau", "inputsStable"], ["bundle output changed", "dist/fixture.lua", "outputsStable"]]) {
    check(name, () => { const r = run(files => files.set(file, "changed")); failed(r); assert.equal(r.report[field], false); });
}
check("nonzero stage exits stop the pipeline", () => { const r = run(null, { status: 1, stdout: "", stderr: "fixture failure" }); failed(r); assert.equal(r.calls, 1); assert.equal(r.report.results[0].exitCode, 1); });
check("omitted tests never count as verification", () => { const r = run(null, { status: 0, stdout: "1 skipped", stderr: "" }); failed(r); assert.equal(r.report.results[0].skipped, true); assert.equal(r.report.passedStages, 0); });
for (const [mode, environment] of [["direct", {}], ["launcher", { NODE_LAUNCHER: "/fixture/linker64" }]]) {
    check(mode + " registers the local-feature gate once and preserves all 33 prior stages", () => {
        const r = run(null, success, environment);
        assert.equal(original.length, 27);
        assert.equal(r.exitCode, 0);
        assert.equal(r.calls, 34);
        const commands = { node: "/fixture/node", python: "/fixture/python", lua: "/fixture/lua" };
        const inventory = expected.map(([name, kind, args]) => ({ name, command: kind === "node" && environment.NODE_LAUNCHER ? environment.NODE_LAUNCHER : commands[kind], args: kind === "node" && environment.NODE_LAUNCHER ? [commands.node, ...args] : args }));
        assert.deepEqual(r.report.results.map(({ name, command, args }) => ({ name, command, args })), inventory);
        assert.deepEqual(r.invocations.map(({ command, args }) => ({ command, args })), inventory.map(({ command, args }) => ({ command, args })));
        for (const [name, runner] of shared) {
            assert.equal(r.report.results.filter(item => item.name === name).length, 1);
            assert.equal(r.invocations.filter(item => item.args.includes("tests/" + runner)).length, 1);
        }
        for (const invocation of r.invocations) {
            assert.equal(invocation.cwd, "/fixture/");
            assert.equal(invocation.env.NODE_BINARY, "/fixture/node");
            assert.equal(invocation.env.NODE_LAUNCHER, environment.NODE_LAUNCHER);
            assert.equal(invocation.env.WIND_ROUTER_LUAU_WEB, "0");
        }
    });
    for (const [name, runner, test] of shared) {
        for (const [failure, stageResult] of [["nonzero", { status: 9, stdout: "", stderr: "fixture failure" }], ["skip", { status: 0, stdout: "", stderr: "SkipTest: fixture omitted" }]]) {
            check(mode + " " + name + " " + failure + " blocks promotion", () => {
                const r = run(null, ({ args }) => args.includes("tests/" + runner) ? stageResult : success, environment);
                failed(r);
                const index = expected.findIndex(item => item[0] === name);
                assert.equal(r.calls, index + 1);
                assert.equal(r.report.passedStages, index);
                assert.equal(r.report.expectedStages, 34);
                assert.equal(r.report.results.at(-1).name, name);
                assert.equal(r.report.results.at(-1).skipped, failure === "skip");
                assert.equal(r.report.results.at(-1).exitCode, stageResult.status);
                for (const field of ["testsStable", "inputsStable", "outputsStable"]) assert.equal(r.report[field], true);
            });
        }
        for (const file of [runner, test]) {
            check(mode + " " + file + " changes during its stage block promotion", () => {
                const r = run(null, ({ args, files }) => { if (args.includes("tests/" + runner)) files.set("tests/" + file, "changed during stage"); return success; }, environment);
                failed(r);
                assert.equal(r.calls, 34);
                assert.equal(r.report.passedStages, 34);
                assert.equal(r.report.testsStable, false);
                assert.equal(r.report.inputsStable, true);
                assert.equal(r.report.outputsStable, true);
                assert.equal(r.report.test_sha256["tests/" + file], sha(file === runner ? "runner" : "test"));
            });
        }
    }
}
check("unset NODE_BINARY preserves the desktop current-Node default", () => {
    const r = run(null, success, { NODE_BINARY: undefined });
    assert.equal(r.exitCode, 0);
    for (const [index, [, kind, args]] of expected.entries()) {
        if (kind === "node") { assert.equal(r.invocations[index].command, "/fixture/current-node"); assert.deepEqual(r.invocations[index].args, args); }
    }
});
console.log("GREEN " + suites + " release-runner contract suites");
