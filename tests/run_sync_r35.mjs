import fs from "node:fs";
import crypto from "node:crypto";
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";
const root = new URL("../", import.meta.url).pathname;
const sha = value => crypto.createHash("sha256").update(value).digest("hex");
const local = root + "node_modules/luau-web/src/index.js";
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(local) ? local : root + "../wind-tools/node_modules/luau-web/src/index.js");
const { LuauState } = await import(pathToFileURL(modulePath).href);
function read(name) {
    const b = fs.readFileSync(root + name);
    console.log("R35_INPUT_SHA256 " + name + " " + sha(b) + " bytes=" + b.length);
    return b.toString("utf8");
}
const startMarker = "-- Reference chat sync:";
const endMarker = "-- End reference chat sync.";
function extract(source) {
    const start = source.indexOf(startMarker);
    const end = source.indexOf(endMarker);
    assert(start >= 0, "sync helper start marker missing in src/ForsakenGuest.luau");
    assert(end > start, "sync helper end marker missing in src/ForsakenGuest.luau");
    return source.slice(start, end + endMarker.length);
}
function replace(body, marker, value) {
    assert.equal(body.split(marker).length, 2, "unique marker " + marker);
    return body.replace(marker, () => value);
}
const forbidden = ["FireServer", "InvokeServer", "HttpGet", "loadstring", "WaitForChild", "TakeDamage", "BindAction", "PostAsync", "GetAsync"];
function staticGate(helper, production) {
    for (const token of forbidden) {
        assert(!helper.includes(token), "static gate: helper must not reference " + token);
    }
    assert(production.includes('Tabs.Guest:AddToggle("GuestTwoTimeChatSync"'), "static gate: Guest chat sync toggle missing");
    const toggle = production.split("\n").find(line => line.includes('AddToggle("GuestTwoTimeChatSync"'));
    assert(toggle && /\bDefault\s*=\s*false\b/.test(toggle), "static gate: Guest chat sync toggle must default false");
    const destroyAt = production.indexOf("local function destroy()");
    assert(destroyAt >= 0, "static gate: destroy missing");
    const destroyBody = production.slice(destroyAt, destroyAt + 400);
    assert(destroyBody.includes("stopChatSync()"), "static gate: destroy must stop chat sync");
}
const mutations = {
    "loose-command": ["(message ~= \":syncScript\" and message ~= \"_sync_terio_\")","false","non exact message ignored"],
    "session-guard": ["ctx.sessionEnv.VortexionSessionId == ctx.thisSessionId", "true", "session switch reclaims blades"],
    "conditional-restore": ["if label.Text == record.LabelText then label.Text = original end", "label.Text = original", "external survivor name preserved"],
    "terio-icon-restore": ["if icon.Image == record.IconImage then icon.Image = original end", "icon.Image = original", "external Terio icon preserved"],
    "terio-frame-deadline": ["if record.LanceUntil and at >= record.LanceUntil then","if at - lastTick >= 0.25 and record.LanceUntil and at >= record.LanceUntil then","Terio deadline restores at exact two seconds"],
    "terio-look-restore": ["entry.Object.Parent == entry.Owner and entry.Object[entry.Property] == entry.Applied", "entry.Object.Parent == entry.Owner", "Terio external shirt preserved"],
    "terio-look-owner": ["entry.Object.Parent == entry.Owner and entry.Object[entry.Property] == entry.Applied", "entry.Object[entry.Property] == entry.Applied", "Terio handed-off shirt not rewritten"],
    "terio-look-late-write": ["\t\t\t\t\t\trestoreChatLook(entry)\n\t\t\t\t\t\treleaseChatRecord(record); return", "\t\t\t\t\t\treleaseChatRecord(record); return", "Terio setter interruption compensates late write close-before"],
    "terio-face-delay": ["record.FaceAt, record.FaceAnimator = clock() + 2, animator","record.FaceAt, record.FaceAnimator = clock() + 1.999, animator","Terio face delayed until two seconds"],
    "terio-face-deadline": ["local deadline = record.FaceAt + 0.55","local deadline = record.FaceAt + 1","Terio face restores at nominal deadline"],
    "terio-face-close": ["\t\tresetChatFace(record)\n\t\tfor i = #appearance","\t\tfor i = #appearance","Terio pulse close restores original face"],
    "terio-face-late-write": ["compensateChatFace(record, entry, appearance)\n\t\t\t\t\t\treleaseChatRecord(record); return","releaseChatRecord(record); return","Terio pulse compensates late write close-before"],
    "terio-skin-color": ['Property = "Color", Applied = Color3.new(1, 1, 1)', 'Property = "Color", Applied = Color3.new(0.99, 1, 1)', "Terio skin applies exact reference white"],
    "terio-skin-restore": ['entry.Object.Parent == entry.Owner and entry.Object[entry.Property] == entry.Applied', 'entry.Object.Parent == entry.Owner and (entry.Property == "Color" or entry.Object[entry.Property] == entry.Applied)', "Terio external skin preserved"],
    "terio-skin-owner": ['entry.Object.Parent == entry.Owner and entry.Object[entry.Property] == entry.Applied', '(entry.Property == "Color" or entry.Object.Parent == entry.Owner) and entry.Object[entry.Property] == entry.Applied', "Terio handed-off skin not rewritten"],
    "terio-skin-bound": ["if index > 256 then break end", "if index > 512 then break end", "Terio skin scan is bounded at 256 direct children"],
};
async function runOnce(mode, mutate) {
    const production = read("src/ForsakenGuest.luau");
    const helper = extract(production);
    staticGate(helper, production);
    const source = mutate ? (() => {
        const [from, to] = mutations[mode];
        assert.equal(production.split(from).length, 2, "unique mutation target " + from);
        return production.replace(from, () => to);
    })() : production;
    let body = read("tests/test_sync_r35.luau");
    body = replace(body, "__SYNC_HELPERS__", extract(source));
    assert(!body.match(/__[A-Z_]+__/), "all markers resolved");
    const buffer = Buffer.from(body);
    console.log("R35_ASSEMBLED_SHA256 sync " + sha(buffer) + " bytes=" + buffer.length + " mode=" + mode);
    let summary;
    const state = await LuauState.createAsync({ print: (...args) => {
        const line = args.join(" ");
        const match = /^test_sync_r35 assertions: (\d+) \(checks (\d+)\)$/.exec(line);
        if (match) summary = match;
        console.log(...args);
    }, warn: console.warn });
    try {
        const execute = state.loadstring(body, "sync_r35", true);
        let caught;
        try { await execute(); } catch (e) { caught = e; }
        if (mutate) {
            assert(caught && String(caught).includes(mutations[mode][2]), "negative " + mode + " must reach expected assertion: " + String(caught));
            console.log("R35_NEGATIVE_CAPTURED " + mode + " expected=" + mutations[mode][2]);
        } else if (caught) throw caught;
        else {
            assert(summary && Number(summary[1]) >= 1608 && summary[1] === summary[2], "healthy sync must reach final checked summary");
            console.log("PASS R35/R40/R41/R42/R43/R45 sync reference chat-sync contracts checks=" + summary[1]);
        }
    } finally { state.destroy(); }
}
const args = process.argv.slice(2);
const only = args.find(a => a.startsWith("--only="))?.slice(7);
await runOnce("healthy", false);
for (const mode of Object.keys(mutations)) {
    if (only && mode !== only) continue;
    await runOnce(mode, true);
}
