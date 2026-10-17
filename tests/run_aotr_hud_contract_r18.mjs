import fs from 'node:fs';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
const localMod = new URL('../node_modules/luau-web/src/index.js', import.meta.url).pathname;
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(localMod) ? localMod : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname);
const { LuauState } = await import(pathToFileURL(modulePath).href);
const NL = String.fromCharCode(10);
const CR = String.fromCharCode(13);
const TAB = String.fromCharCode(9);
const testsDir = new URL('.', import.meta.url).pathname;
const srcDir = new URL('../src/', import.meta.url).pathname;
function loadInput(name, p) {
    const b = fs.readFileSync(p);
    const s = b.toString('utf8');
    console.log('R18_INPUT_SHA256 ' + name + ' ' + crypto.createHash('sha256').update(b).digest('hex') + ' bytes ' + b.length);
    return s;
}
function fail(msg) { console.error('R18_ERROR ' + msg); process.exit(2); }
function countOf(hay, needle) { return hay.split(needle).length - 1; }
function unique(src, needle, label) { const n = countOf(src, needle); if (n !== 1) fail(label + ' anchor count ' + n + ' (expected exactly 1)'); }
function sliceBetween(src, startA, endA, label) {
    unique(src, startA, label + ' start');
    unique(src, endA, label + ' end');
    const si = src.indexOf(startA);
    const ei = src.indexOf(endA, si);
    if (ei < 0) fail(label + ' end-after-start missing');
    return src.slice(si, ei + endA.length);
}
function buttonBlock(src, label, title = "查看刀片/雷枪余量") {
    const marker = 'AddButton({Title="' + title + '"';
    unique(src, marker, label + ' button title');
    const mi = src.indexOf(marker);
    const lineStart = src.lastIndexOf(NL, mi) + 1;
    const close = src.indexOf('end})', mi);
    if (close < 0) fail(label + ' button close missing');
    return src.slice(lineStart, close + 5);
}
function trimEnd(s) {
    let line = s;
    while (line.length) {
        const c = line[line.length - 1];
        if (c === ' ' || c === TAB || c === CR || c === NL) line = line.slice(0, -1);
        else break;
    }
    return line;
}
function initLine(src) {
    const marker = 'ProbeHUD(true)';
    unique(src, marker, 'battle init');
    const mi = src.indexOf(marker);
    const lineStart = src.lastIndexOf(NL, mi) + 1;
    let lineEnd = src.indexOf(NL, mi);
    if (lineEnd < 0) lineEnd = src.length;
    return trimEnd(src.slice(lineStart, lineEnd));
}

const common = loadInput('common', srcDir + 'AOTRCommon.luau');
const lobby = loadInput('lobby', srcDir + 'AOTRLobby.luau');
const battle = loadInput('battle', srcDir + 'AOTRBattle.luau');
const template = loadInput('body', testsDir + 'test_aotr_hud_contract_r18.luau');

const hudHelp = sliceBetween(common, 'local HUD={blades=nil,spears=nil,lastProbe=0}', 'app.ReadPercent=readPercent', 'common HUD helper');
let lobbyBtn = buttonBlock(lobby, 'lobby');
let battleBtn = buttonBlock(battle, 'battle');
let battleInit = initLine(battle);
const finiteHelp = sliceBetween(lobby, 'local function finite(v)', 'local function snapshotValue(name)', 'finite helper').slice(0, -'local function snapshotValue(name)'.length);
const gasHelp = sliceBetween(lobby, 'local function hudText(label)', 'overview:AddButton({Title="查看燃气余量"', 'gas text helpers').slice(0, -'overview:AddButton({Title="查看燃气余量"'.length);
const gasLobby = buttonBlock(lobby, 'lobby gas', '查看燃气余量');
const gasBattle = buttonBlock(battle, 'battle gas', '查看燃气余量');
const refreshLobby = buttonBlock(lobby, 'lobby refresh', '立即刷新全部余量');

const ncArg = process.argv.find((a) => a.startsWith('--nc='));
const nc = ncArg ? ncArg.slice(5) : null;
const ncChanges = [];

function revertDotToColon(s, dot, colon, label) {
    const before = countOf(s, dot);
    if (before < 1) fail(label + ': expected at least one ' + dot + ', found 0');
    const out = s.split(dot).join(colon);
    if (countOf(out, dot) !== 0) fail(label + ': dot form remains after NC revert');
    return { text: out, changed: before };
}

if (nc === 'readcount') {
    let r = revertDotToColon(lobbyBtn, 'app.ReadCount(', 'app:ReadCount(', 'readcount lobby'); lobbyBtn = r.text; ncChanges.push('readcount lobby x' + r.changed);
    r = revertDotToColon(battleBtn, 'app.ReadCount(', 'app:ReadCount(', 'readcount battle'); battleBtn = r.text; ncChanges.push('readcount battle x' + r.changed);
} else if (nc === 'probe') {
    let r = revertDotToColon(lobbyBtn, 'app.ProbeHUD(false)', 'app:ProbeHUD(false)', 'probe lobby'); lobbyBtn = r.text; ncChanges.push('probe lobby x' + r.changed);
    r = revertDotToColon(battleBtn, 'app.ProbeHUD(false)', 'app:ProbeHUD(false)', 'probe battle'); battleBtn = r.text; ncChanges.push('probe battle x' + r.changed);
} else if (nc === 'init') {
    let r = revertDotToColon(battleInit, 'app.ProbeHUD(true)', 'app:ProbeHUD(true)', 'init'); battleInit = r.text; ncChanges.push('init x' + r.changed);
} else if (nc === 'alive') {
    const gate = 'if not app:Alive() then return end';
    let n = countOf(lobbyBtn, gate); if (n < 1) fail('alive lobby: expected gate, found 0'); lobbyBtn = lobbyBtn.split(gate).join(''); ncChanges.push('alive lobby gate-removed x' + n);
    n = countOf(battleBtn, gate); if (n < 1) fail('alive battle: expected gate, found 0'); battleBtn = battleBtn.split(gate).join(''); ncChanges.push('alive battle gate-removed x' + n);
} else if (nc) {
    fail('unknown --nc ' + nc);
}

const parts = [
    ['__R18_HUD_HELP__', hudHelp],
    ['__R18_LOBBY_BUTTON__', lobbyBtn],
    ['__R18_BATTLE_BUTTON__', battleBtn],
    ['__R18_BATTLE_INIT__', battleInit],
    ['__R36_LOBBY_HELPERS__', finiteHelp + NL + gasHelp],
    ['__R36_LOBBY_GAS_BUTTON__', gasLobby],
    ['__R36_BATTLE_GAS_BUTTON__', gasBattle],
    ['__R36_LOBBY_REFRESH_BUTTON__', refreshLobby],
];
// full-string guard: each placeholder literal must appear exactly once across the whole
// template (comments and inline tails included), then be fully consumed by substitution.
for (const [m] of parts) {
    const n = countOf(template, m);
    if (n !== 1) fail('assembly marker ' + m + ' literal count ' + n + ' (expected exactly 1, full-string incl comments)');
}
let source = template;
for (const [m, v] of parts) source = source.split(m).join(v);
for (const [m] of parts) {
    if (countOf(source, m) !== 0) fail('assembly marker ' + m + ' literal remains after substitution (full-string, incl comments)');
}

const buf = Buffer.from(source, 'utf8');
const executed = buf.toString('utf8');
const sha = crypto.createHash('sha256').update(buf).digest('hex');

async function execute(text, name) {
    const out = [];
    const state = await LuauState.createAsync({ print: s => out.push(String(s)), warn: s => out.push('WARN ' + String(s)) });
    let crashed = null;
    try { await state.loadstring(text, name, true)(); }
    catch (e) { crashed = String((e && e.stack) || e); }
    finally { state.destroy(); }
    return { out, crashed };
}
const { out, crashed } = await execute(executed, 'r18-hud-contract');
const stdout = out.join(NL);
console.log(stdout);
console.log('R18_EXECUTED_BYTES ' + buf.length);
console.log('R18_EXECUTED_SHA256 ' + sha);
const lines = stdout.split(NL);
const resultLine = lines.filter((l) => l.startsWith('R18_RESULT')).pop();
const redLines = lines.filter((l) => l.startsWith('RED '));

if (nc) {
    const expect = {
        readcount: 'notifies blades 3/8',
        probe: 'cache hit keeps old label',
        init: 'battle init forces boolean',
        alive: 'destroyed: no HUD probe',
    }[nc];
    if (crashed) { console.error('R18_NC ' + nc + ' NOT-CAPTURED driver-crash: ' + crashed); process.exit(1); }
    if (!resultLine || resultLine.indexOf('R18_RESULT RED') !== 0) { console.error('R18_NC ' + nc + ' NOT-CAPTURED no-red-result'); process.exit(1); }
    const hits = redLines.filter((l) => l.indexOf(expect) >= 0);
    if (hits.length === 0) { console.error('R18_NC ' + nc + ' NOT-CAPTURED wrong-assertion'); process.exit(1); }
    console.log('R18_NC ' + nc + ' CAPTURED changes=[' + ncChanges.join(', ') + '] by: ' + hits.join(' ;; '));
    process.exit(0);
}

if (crashed) { console.error('R18_FAIL driver-crash: ' + crashed); process.exit(1); }
if (!resultLine || resultLine !== 'R18_RESULT GREEN') { console.error('R18_FAIL expected GREEN got: ' + (resultLine || '<none>')); process.exit(1); }
console.log('R18_PASS hud contract green checks=' + lines.filter(l => l.startsWith('green ')).length);

// Run each gas mutation in a fresh VM; a crash is not assertion coverage.
const aliveGate = 'if not app:Alive() then return end';
unique(gasLobby, aliveGate, 'gas lobby alive');
unique(gasBattle, aliveGate, 'gas battle alive');
const gasControls = [
    ['hud-loss', 'no PlayerGui: blades reference cleared', [['HUD.blades=nil; HUD.spears=nil; HUD.gas=nil; return HUD', 'HUD.gas=nil; return HUD']]],
    ['gas-range', 'gas rejects outside range', [['if value<0 or value>100 then return nil end', 'if false then return nil end']]],
    ['gas-exact', 'gas exact path rejects decoy', [['cur:FindFirstChild(name)', 'cur:FindFirstChild(name,true)']]],
    ['gas-alive', 'gas destroyed: no HUD probe', [[gasLobby, gasLobby.replace(aliveGate, '')], [gasBattle, gasBattle.replace(aliveGate, '')]]],
];
for (const [name, expected, edits] of gasControls) {
    let changed = executed;
    for (const [from, to] of edits) { unique(changed, from, name); changed = changed.replace(from, () => to); }
    const result = await execute(changed, name);
    const hits = result.out.filter(l => l.startsWith('RED ') && l.includes(expected));
    if (result.crashed || !result.out.some(l => l.startsWith('R18_RESULT RED')) || hits.length === 0) {
        console.error('R36_NC ' + name + ' NOT-CAPTURED ' + (result.crashed || result.out.join(NL)));
        process.exit(1);
    }
    const bytes = Buffer.from(changed, 'utf8');
    console.log('R36_NC ' + name + ' CAPTURED sha256=' + crypto.createHash('sha256').update(bytes).digest('hex') + ' bytes=' + bytes.length + ' by: ' + hits.join(' ;; '));
}
process.exit(0);
