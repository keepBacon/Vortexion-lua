import fs from "node:fs";
import crypto from "node:crypto";
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";
const root = new URL("../", import.meta.url).pathname;
const local = root + "node_modules/luau-web/src/index.js";
const runtime = fs.existsSync(local) ? local : root + "../wind-tools/node_modules/luau-web/src/index.js";
const { LuauState } = await import(pathToFileURL(runtime).href);
const nl = String.fromCharCode(10);
const hash = text => crypto.createHash("sha256").update(text).digest("hex");
const read = path => { const text = fs.readFileSync(root + path, "utf8"); console.log("R39_INPUT_SHA256 " + path + " " + hash(text)); return text; };
const fixture = read("tests/test_forsaken_enrichment.luau");
const boundary = "if api.startBackstab then";
assert.equal(fixture.split(boundary).length, 2, "unique harness boundary");
const prefix = fixture.slice(0, fixture.indexOf(boundary));
assert.equal(prefix.split("__FACTORY__").length, 2, "unique factory marker");
const factory = read("src/ForsakenGuest.luau");
const cases = read("tests/test_sil_animation_r39.luau");
async function execute(text, echo) {
    const body = prefix.replace("__FACTORY__", () => "(function()" + nl + text + nl + "end)()") + cases;
    const lines = [];
    const log = (...args) => { const line = args.map(String).join(" "); lines.push(line); if (echo) console.log(line); };
    const state = await LuauState.createAsync({ print: log, warn: log });
    let error;
    try { await state.loadstring(body, "sil_animation_r39", true)(); } catch (e) { error = String(e.stack || e); }
    finally { state.destroy(); }
    return { lines, error, sha256: hash(body), bytes: Buffer.byteLength(body) };
}
const healthy = await execute(factory, true);
assert(!healthy.error, healthy.error);
assert(healthy.lines.some(line => /^test_sil_animation_r39 assertions: [1-9][0-9]*$/.test(line)), "fixture must reach final assertion summary");
console.log("R39_ASSEMBLED_SHA256 " + healthy.sha256 + " bytes=" + healthy.bytes);
console.log("PASS R39 Sil real factory animation contracts");
const anchor = '["93368339913846"] = {id = "140035118771958", delay = 0.45, speed = 1}';
assert.equal(factory.split(anchor).length, 2, "unique finisher delay mutation");
const mutant = factory.replace(anchor, () => anchor.replace("delay = 0.45", "delay = 0"));
const negative = await execute(mutant, false);
assert(negative.error && negative.error.includes("delayed id does not replace immediately"), "finisher delay negative control must hit its named business assertion: " + negative.error);
console.log("R39_NC finisher-delay CAPTURED sha256=" + negative.sha256 + " bytes=" + negative.bytes + " by: " + negative.error.split(nl)[0]);
