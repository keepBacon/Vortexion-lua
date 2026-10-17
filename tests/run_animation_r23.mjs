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
    const b=fs.readFileSync(root+name);
    console.log("R23_INPUT_SHA256 " + name + " " + sha(b) + " bytes=" + b.length);
    return b.toString("utf8");
}
function replace(body, marker, value) {
    assert.equal(body.split(marker).length, 2, "unique marker " + marker);
    return body.replace(marker, () => value);
}
function prefix(body, marker) {
    assert.equal(body.split(marker).length, 2, "unique prefix boundary " + marker);
    return body.slice(0, body.indexOf(marker));
}
const args=process.argv.slice(2);
const suiteArg=args.find(a=>a.startsWith("--suite="));
const suites=suiteArg ? [suiteArg.slice(8)] : ["native", "guest"];
const negative=args.find(a=>a.startsWith("--negative="))?.slice(11);
const mutations={
    "native-speed": ["track:Play(0.05, 1, previewSpeed)", "track:Play(0.05, 1, 100)", "native Equip uses 1x speed"],
    "native-epoch": ["and serial == nativeSerial", "and true", "late Load after Stop never plays"],
    "guest-speed": ["animationSpeed / 100", "animationSpeed", "default 100 percent plays at 1x"],
    "guest-epoch": ["and revision == animationRevision", "and true", "stop during load invalidates play"],
    "guest-disposal": ["if current and not disposedTracks[current] then", "if current then", "synchronous stopped disposes once"],
};
if(negative) assert(mutations[negative] && suites.length===1 && negative.startsWith(suites[0]+"-"), "select the matching single suite with a known negative");
for(const suite of suites) {
    assert(["native", "guest"].includes(suite), "known suite");
    const production=suite==="native" ? "src/BloxStrikeCosmetic.luau" : "src/ForsakenGuest.luau";
    let factory=read(production);
    if(negative) factory=replace(factory, mutations[negative][0], mutations[negative][1]);
    const wrapped="(function()"+nl+factory+nl+"end)()";
    let body;
    if(suite==="native") {
        body=prefix(read("tests/test_bloxstrike_enrichment.luau"), "-- UI-consumed movement-stick touches");
        body=replace(body,"__COMMON__", "(function()"+nl+read("src/BloxStrikeCommon.luau")+nl+"end)()");
        body=replace(body,"__COMBAT__", "{}");
        body=replace(body,"__VISUAL__", "{}");
        body=replace(body,"__COSMETIC__", wrapped);
        body+=read("tests/test_native_animation_r23.luau");
    } else {
        body=prefix(read("tests/test_forsaken_enrichment.luau"), "if api.startBackstab then");
        body=replace(body,"__FACTORY__", wrapped);
        body+=read("tests/test_guest_animation_r23.luau");
    }
    assert(!body.match(/__[A-Z_]+__/), "all markers resolved");
    const buffer=Buffer.from(body);
    console.log("R23_ASSEMBLED_SHA256 " + suite + " " + sha(buffer) + " bytes="+buffer.length+" mode="+(negative||"healthy"));
    const state=await LuauState.createAsync({print:console.log,warn:console.warn});
    try {
        const execute=state.loadstring(body,"animation_r23_"+suite,true);
        let caught;
        try { await execute(); } catch(e) { caught=e; }
        if(negative) {
            assert(caught && String(caught).includes(mutations[negative][2]), "negative must reach expected assertion: " + String(caught));
            console.log("R23_NEGATIVE_CAPTURED " + negative + " expected=" + mutations[negative][2]);
        } else if(caught) throw caught;
        else console.log("PASS R23 " + suite + " real factory animation contracts");
    } finally { state.destroy(); }
}
