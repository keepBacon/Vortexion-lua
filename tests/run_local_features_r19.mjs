import fs from "node:fs";
import crypto from "node:crypto";
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";

const root = new URL("../", import.meta.url).pathname;
const localModule = root + "node_modules/luau-web/src/index.js";
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(localModule) ? localModule : root + "../wind-tools/node_modules/luau-web/src/index.js");
const { LuauState } = await import(pathToFileURL(modulePath).href);
const sha = b => crypto.createHash("sha256").update(b).digest("hex");
function input(name) {
    const buffer = fs.readFileSync(root + name);
    console.log("R19_INPUT_SHA256 " + name + " " + sha(buffer) + " bytes=" + buffer.length);
    return buffer.toString("utf8");
}
function unique(source, text) {
    assert.equal(source.split(text).length - 1, 1, "expected unique anchor: " + text);
}
function before(source, start, end) {
    unique(source, start); unique(source, end);
    const a = source.indexOf(start), b = source.indexOf(end, a + start.length);
    assert(b > a, "missing ordered end anchor: " + end);
    return source.slice(a, b);
}
function change(source, oldText, newText) { unique(source, oldText); return source.replace(oldText, newText); }
const forsaken = input("src/ForsakenVisual.luau");
const cosmetic = input("src/BloxStrikeCosmetic.luau");
const lobby = input("src/AOTRLobby.luau");
const server = input("src/ServerSwitch.luau");
const adapter = input("src/WindAdapter.luau");
let body = input("tests/test_local_features_r19.luau");
const fragments = {
    __RESTORE_EXTRAS__: before(forsaken, "local function restoreExtras()", "local function applyHighlight(char)"),
    __RESTORE_HIGHLIGHT__: before(forsaken, "local function restoreHighlight()", "-- 本地皮肤：只读取"),
    __SCALE_HELPERS__: before(forsaken, "local function restoreScale(except)", "local appearanceAppliers = {"),
    __COSMETIC_FRAME__: before(cosmetic, "knifeFollow = c.RunService.RenderStepped:Connect(function(dt)", "c.OnCleanup(function()"),
    __LOBBY_ENTRY__: lobby,
    __SERVER_FINITE__: before(server, "local function finite(n)", "local function validIP(ip)"),
    __SERVER_STATUS__: before(server, "local function showSampleStatus()", "tab:AddButton({Title = \"查看切服采样状态\""),
    __SAFE_CALLBACK__: before(adapter, "local callbackErrorRevision = 0", "local function copy(value)"),
    __PRESET_CONTROLS__: before(adapter, "local function applyRecommended(label, ordered)", "debugPage:AddToggle(\"wind_debug\""),
};
const negative = process.argv.slice(2).find(a => a.startsWith("--negative="))?.slice(11);
const controls = {
    restore: ["__RESTORE_EXTRAS__","object:IsA(\"Model\")","object:IsA(\"MissingModel\")","strict-instance appearance restoration","Model restored without Destroyed property"],
    baseline: ["__SCALE_HELPERS__", "appearanceScaleSaved[char] = original", "appearanceScaleSaved[char] = 1", "Model baseline retained across repeated applications", "original baseline not overwritten"],
    character: ["__SCALE_HELPERS__", "restoreScale(char)", "-- negative: omitted previous-character restoration", "character replacement restores previous model before new application", "old character restored immediately"],
    idle: ["__COSMETIC_FRAME__","if not state.enabled and not state.knife and not knifeModel and next(activeSounds)==nil and anim.mode==\"idle\" then","if false then","cosmetic idle fast path preserves every active condition","idle does no frame work"],
    clipboard: ["__LOBBY_ENTRY__", "copied=ok and result~=false", "copied=ok", "lobby clipboard fallback decline", "snapshot fallback, not false success"],
    acceptance: ["__PRESET_CONTROLS__", "if result ~= true or bridge.Options[entry[1]].Value ~= entry[2] then", "if false then", "preset stops on deferred", "stops at first unconfirmed setter"],
    callback: ["__PRESET_CONTROLS__", "callbackErrorRevision ~= previousErrors", "false", "preset stops on callback", "stops at first unconfirmed setter"],
};
if (negative) {
    assert(controls[negative], "unknown negative control " + negative);
    const [key, oldText, newText] = controls[negative];
    fragments[key] = change(fragments[key], oldText, newText);
}
for (const [marker, source] of Object.entries(fragments)) { unique(body, marker); body = body.replace(marker, () => source); }
assert(!body.match(/__[A-Z_]+__/), "unresolved fixture marker");
const buffer = Buffer.from(body, "utf8");
console.log("R19_ASSEMBLED_SHA256 " + sha(buffer) + " bytes=" + buffer.length + " mode=" + (negative || "healthy"));
const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
try {
    const run = state.loadstring(buffer.toString("utf8"), "local_features_r19", true);
    let caught;
    try { await run(); } catch (error) { caught = error; }
    if (negative) {
        const message = String(caught);
        assert(caught && message.includes("R19 FAIL " + controls[negative][3] + ":") && message.includes(controls[negative][4]), "negative did not fail at its expected assertion: " + message);
        console.log("R19_NEGATIVE_CAPTURED " + negative + " expected=" + controls[negative][4]);
    } else if (caught) { throw caught; }
} finally { state.destroy(); }
