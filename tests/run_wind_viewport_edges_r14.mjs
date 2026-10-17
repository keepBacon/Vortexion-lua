// Step 5 Preview (r14): isolated executor for the viewport edge regression (normal shared GUI only).
// SNAPSHOT REGRESSION, NOT FROZEN ACCEPTANCE: the source under test may change under us (a sibling worker owns
// src/WindAdapter.luau and may patch it concurrently); the snapshot lines below pin exactly which bytes produced
// the result. Re-run after any source change and refresh docs/VIEWPORT_EDGES_R14.md.
// Evidence contract: every input is read ONCE into a captured byte snapshot; the printed hashes and the assembled
// source both come from those same bytes, so a concurrent edit between hashing and assembly can never mis-attribute
// a hash to different bytes. Marker validation: the cut marker and the factory marker must each occur exactly once
// before assembly, and neither may survive replacement; any missing / duplicated / residual marker fails the run
// explicitly (exit 1) before any Luau executes. Nothing here writes to the project tree.
import fs from 'node:fs';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';

const root = new URL('../', import.meta.url).pathname;
const local = root + 'node_modules/luau-web/src/index.js';
const runtime = fs.existsSync(local)
    ? local
    : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname;
if (!fs.existsSync(runtime)) {
    console.error('r14 FAIL: luau-web runtime not found: ' + runtime);
    process.exit(1);
}

const baseFile = root + 'tests/test_wind_adapter.luau';
const bodyFile = root + 'tests/test_wind_viewport_edges_r14.luau';
const targetFile = root + 'src/WindAdapter.luau';
const cut = 'local env, stops = {}, 0';
const factory = '__FACTORY__';
const fail = (message) => {
    console.error('r14 FAIL: ' + message);
    process.exit(1);
};

// Single capture: hashing and assembly share these exact bytes.
let baseBuf, bodyBuf, targetBuf;
try {
    baseBuf = fs.readFileSync(baseFile);
    bodyBuf = fs.readFileSync(bodyFile);
    targetBuf = fs.readFileSync(targetFile);
} catch (error) {
    fail('cannot read inputs: ' + (error && error.message));
}
const full = baseBuf.toString('utf8');
const body = bodyBuf.toString('utf8');
const target = targetBuf.toString('utf8');
const sha256hex = (buf) => crypto.createHash('sha256').update(buf).digest('hex');
const occurrences = (haystack, needle) => haystack.split(needle).length - 1;

// Pre-assembly marker validation: exactly one cut marker in the base file, exactly one factory marker in the
// sliced base. Missing or duplicated markers fail loudly instead of silently slicing the wrong region.
const cutCount = occurrences(full, cut);
if (cutCount !== 1) fail('fixture cut marker must occur exactly once in ' + baseFile + ', found ' + cutCount);
const base = full.split(cut)[0];
const factoryCount = occurrences(base, factory);
if (factoryCount !== 1) fail('factory marker must occur exactly once in the sliced base of ' + baseFile + ', found ' + factoryCount);

// Assembly uses the captured bytes only. Function replacement keeps any '$' sequences literal.
const assembled = (base + body).replace(factory, () => '(function()\n' + target + '\nend)()');
// Post-assembly residue: neither marker may survive replacement.
for (const [label, marker] of [['factory', factory], ['cut', cut]]) {
    const left = occurrences(assembled, marker);
    if (left !== 0) fail(label + ' marker residue after assembly: ' + left + ' occurrence(s) remain');
}

console.log('r14 runtime: ' + runtime);
console.log('r14 snapshot base ' + baseFile + ' bytes=' + baseBuf.length + ' sha256=' + sha256hex(baseBuf));
console.log('r14 snapshot body ' + bodyFile + ' bytes=' + bodyBuf.length + ' sha256=' + sha256hex(bodyBuf));
console.log('r14 snapshot target ' + targetFile + ' bytes=' + targetBuf.length + ' sha256=' + sha256hex(targetBuf));
console.log('r14 snapshot assembled bytes=' + Buffer.byteLength(assembled, 'utf8') + ' sha256=' + crypto.createHash('sha256').update(assembled, 'utf8').digest('hex'));

const { LuauState } = await import(pathToFileURL(runtime).href);
async function executeCase(source, mode, expected) {
    const lines = [];
    const state = await LuauState.createAsync({
        print: (...args) => { const line = args.join(" "); lines.push(line); console.log(line); },
        warn: console.warn,
    });
    let caught;
    try { await state.loadstring(source, "wind_viewport_edges_r14_" + mode, true)(); }
    catch (error) { caught = error; }
    finally { state.destroy(); }
    if (!expected) {
        if (caught) throw caught;
        if (!lines.includes("WIND_VIEWPORT_EDGES_R14: passed=19 failed=0 checks=19"))
            throw new Error("healthy viewport run must complete all 19 scenarios");
    } else {
        if (!caught || !String(caught).includes("WIND_VIEWPORT_EDGES_R14_RED: 1 scenario(s) failed")
            || !lines.includes("WIND_VIEWPORT_EDGES_R14: passed=19 failed=1 checks=20")
            || !lines.some(line => line.startsWith("RED viewport-edge R46 injected ") && line.includes(expected)))
            throw new Error("negative " + mode + " must expose injected error and continue all scenarios: " + String(caught));
        console.log("R46_VIEWPORT_NEGATIVE_CAPTURED " + mode + " expected=" + expected);
    }
}
try {
    await executeCase(assembled, "healthy");
    const anchor = "-- === 1)";
    if (occurrences(assembled, anchor) !== 1) throw new Error("unique viewport injection anchor required");
    const probes = [
        ["async-error", "R46_ASYNC_INJECTED", "check('R46 injected async', function() task.defer(function() error('R46_ASYNC_INJECTED', 0) end); drainLayout() end)"],
        ["cleanup-error", "R46_CLEANUP_INJECTED", "check('R46 injected cleanup', function() activeBridge = {Active = true, Destroy = function() error('R46_CLEANUP_INJECTED', 0) end} end)"],
    ];
    for (const [mode, expected, injection] of probes) {
        const source = assembled.replace(anchor, () => injection + String.fromCharCode(10) + anchor);
        console.log("R46_VIEWPORT_ASSEMBLED " + mode + " sha256=" + sha256hex(Buffer.from(source)));
        await executeCase(source, mode, expected);
    }
} catch (error) {
    console.error(error.stack || String(error));
    process.exitCode = 1;
}

// Concurrency witness: the inputs are owned by other workers, so re-read after the run and report drift. This
// never changes the exit code; it only records whether the snapshot above still describes the tree.
for (const [file, buf] of [[baseFile, baseBuf], [bodyFile, bodyBuf], [targetFile, targetBuf]]) {
    let now;
    try { now = fs.readFileSync(file); } catch { continue; }
    if (!now.equals(buf)) {
        console.error('r14 drift: ' + file + ' changed during the run; snapshot sha256=' + sha256hex(buf) + ' now=' + sha256hex(now));
    }
}
