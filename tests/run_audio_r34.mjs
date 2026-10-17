import fs from "node:fs";
import crypto from "node:crypto";
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";
const root = new URL("../", import.meta.url).pathname;
const nl = String.fromCharCode(10);
const sha = value => crypto.createHash("sha256").update(value).digest("hex");
const local = root + "node_modules/luau-web/src/index.js";
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(local) ? local : root + "../wind-tools/node_modules/luau-web/src/index.js");
const { LuauState } = await import(pathToFileURL(modulePath).href);
function read(name) {
    const b = fs.readFileSync(root + name);
    console.log("R34_INPUT_SHA256 " + name + " " + sha(b) + " bytes=" + b.length);
    return b.toString("utf8");
}
function replace(body, marker, value) {
    assert.equal(body.split(marker).length, 2, "unique marker " + marker);
    return body.replace(marker, () => value);
}
const ranges = {
    "__AUDIO_CHARACTER__": [119, 121, "\tlocal function character()", "\tend"],
    "__AUDIO_DEFS__": [310, 321, "\tlocal resourceSoundDefs = {", "\tlocal resourceAudioEnabled, resourceAudioChoice = false, \"挥鞭\""],
    "__AUDIO_DISPOSE__": [326, 351, "\tlocal function disposeResourceObject(object)", "\tend"],
    "__AUDIO_RELEASE__": [352, 404, "\tlocal function restoreResourceWorld(record)", "\tend"],
    "__AUDIO_CURRENT__": [405, 426, "\tlocal function resourceCurrent(serial, char)", "\tend"],
    "__AUDIO_PULSE__": [852, 872, "\tlocal function hideResourcePulse(record)", "\tend"],
    "__AUDIO_UPDATE__": [873, 919, "\tlocal function resourceAudioCurrent(record)", "\tend"],
    "__AUDIO_ACTION__": [920, 966, "\tlocal function updateResourceAction(record)", "\tend"],
};
function slice(source, start, end, first, last) {
    const lines = source.split(nl);
    const picked = lines.slice(start - 1, end);
    assert.equal(picked.length, end - start + 1, "range " + start + "-" + end + " exists");
    assert.equal(picked[0], first, "range " + start + " first line drifted");
    assert.equal(picked[picked.length - 1], last, "range " + start + " last line drifted");
    return picked.join(nl);
}
const args = process.argv.slice(2);
const negative = args.find(a => a.startsWith("--negative="))?.slice(11);
const mutations = {
    "no-delay": ["due = clock() + (delay or 0)", "due = clock()", "whip holds 0.45s"],
    "no-expiry": ["if clock() >= entry.expires or not sound.Parent then", "if not sound.Parent then", "2s lifetime reclaims sound"],
    "no-validity-guard": ["if not current() or not record.audioSounds[sound] then", "if false then", "superseded sound never plays"],
};
if (negative) assert(mutations[negative], "known negative control");
const production = read("src/ForsakenVisual.luau");
// Default release mode validates healthy behavior and every negative control.
for (const mode of (negative ? [negative] : [null, ...Object.keys(mutations)])) {
    const mutated = mode ? (() => {
        const [from, to] = mutations[mode];
        assert.equal(production.split(from).length, 2, "unique mutation target " + from);
        return production.replace(from, () => to);
    })() : production;
    let body = read("tests/test_audio_r34.luau");
    for (const [marker, [start, end, first, last]] of Object.entries(ranges)) {
        body = replace(body, marker, slice(mutated, start, end, first, last));
    }
    assert(!body.match(/__[A-Z_]+__/), "all markers resolved");
    const buffer = Buffer.from(body);
    console.log("R34_ASSEMBLED_SHA256 audio " + sha(buffer) + " bytes=" + buffer.length + " mode=" + (mode || "healthy"));
    const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
    try {
        const execute = state.loadstring(body, "audio_r34", true);
        let caught;
        try { await execute(); } catch (e) { caught = e; }
        if (mode) {
            assert(caught && String(caught).includes(mutations[mode][2]), "mode must reach expected assertion: " + String(caught));
            console.log("R34_NEGATIVE_CAPTURED " + mode + " expected=" + mutations[mode][2]);
        } else if (caught) throw caught;
        else console.log("PASS R34 audio real local-sound contracts");
    } finally { state.destroy(); }
}
