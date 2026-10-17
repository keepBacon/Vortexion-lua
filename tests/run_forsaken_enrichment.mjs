import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const root = new URL('../', import.meta.url).pathname;
const localModule = new URL('../node_modules/luau-web/src/index.js', import.meta.url).pathname;
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(localModule) ? localModule : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname);
const { LuauState } = await import(pathToFileURL(modulePath).href);
const baseline = JSON.parse(fs.readFileSync(path.join(root, 'tests/wind_option_ids_baseline.json'), 'utf8'));
for (const [file, expected] of Object.entries(baseline)) {
  if (!file.startsWith('src/Forsaken')) continue;
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  const actual = [...source.matchAll(/Add(?:Toggle|Slider|Dropdown|Input)\(\s*"([^"]+)"/g)].map(match => match[1]);
  for (const id of expected) if (!actual.includes(id)) throw new Error('Missing legacy option ' + id);
  if (new Set(actual).size !== actual.length) throw new Error('Duplicate native option in ' + file);
  console.log('PASS legacy option IDs ' + file + ': ' + expected.length + ' preserved / ' + actual.length + ' total');
}
const harness = fs.readFileSync(path.join(root, 'tests/test_forsaken_enrichment.luau'), 'utf8');
const core = fs.readFileSync(path.join(root, 'src/ForsakenCore.luau'), 'utf8');
function slice(start, end) {
  const from = core.indexOf(start);
  const to = core.indexOf(end, from);
  if (from < 0 || to < 0) throw new Error('Core source anchors changed: ' + start);
  return core.slice(from, to);
}
// Execute the actual Core implementations, not copied restoration algorithms.
const coreFactory = 'return function(ctx)\nlocal LocalPlayer, RunService, Workspace = ctx.LocalPlayer, ctx.RunService, ctx.Workspace\nlocal Tabs, Fluent, track = ctx.Tabs, ctx.Fluent, ctx.track\nlocal sessionEnv, thisSessionId = ctx.sessionEnv, ctx.thisSessionId\nlocal os = {clock = ctx.clock}\nlocal ORIGINAL_DASH_SPEED = 60\n'
  + slice('local Connections = {}', '\n\nlocal executor')
  + slice('local isOverrideActive = false', 'local function fireproximityprompt')
  + slice('    local fovValue, fovActive, fovCamera, fovListener', '    Window:InstallSettings')
  + '\nlocal groupDestroyCount = 0\nlocal featureGroupApis = {One = {Destroy = function() groupDestroyCount += 1 end}, Two = {Destroy = function() groupDestroyCount += 1 end}}\nfor key, value in pairs(featureGroupApis) do sessionEnv[key] = value end\nlocal activeConnections = {}\nlocal statsGui = nil\nlocal disableAimbot = function() end\nlocal ESP = {SetEnabled = function() end, CheckHz = 10}\nlocal FluentLoaded = true\n'
  + slice('-- 非关键 ESP 投影刷新节流', '-- 固定最多约 10 次/秒')
  + core.slice(core.indexOf('local cleaned = false'))
  + '\nreturn {startDash = startvoidrushcontrol, stopDash = stopvoidrushcontrol, cleanup = cleanupForsaken, trackedCount = function() return #Connections end, groupDestroyCount = function() return groupDestroyCount end, espInterval = espThrottleInterval, setEspCheckHz = function(v) ESP.CheckHz = v end}\nend';
const factories = ['Combat', 'Survival', 'Visual', 'Guest'].map(name => [name, fs.readFileSync(path.join(root, 'src/Forsaken' + name + '.luau'), 'utf8')]);
factories.push(['Core lifecycle', coreFactory]);
const mutations = process.argv.includes('--mutations');
if (mutations) {
  const changes = [
    [['or clock() < nextAt', 'or false']],
    [['local function restoreStamina()', 'local function restoreStamina()\n if true then return end']],
    [['if d < distance then best, distance = root, d end', 'if not best then best, distance = root, d end'],
     ['if Fluent and type(Fluent.GetVisualInterval) == "function" then', 'if false then']],
    [['local lastAnimAt = -math.huge', 'local lastAnimAt = 0']],
    [['savedFov[camera] = camera.FieldOfView', 'savedFov[camera] = 70'],
     ['and bridged ~= math.huge and bridged ~= -math.huge and bridged > 0 then', 'and true then']],
  ];
  factories.forEach((entry, i) => {
    for (const [before, after] of changes[i]) {
      if (!entry[1].includes(before)) throw new Error('Mutation anchor missing: ' + before);
      entry[1] = entry[1].replace(before, after);
    }
  });
}
let failed = false;
for (const [name, source] of factories) {
  const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
  try {
    const executable = harness.replace('__FACTORY__', '(function()\n' + source + '\nend)()');
    await state.loadstring(executable, name, true)();
    if (mutations) {
      failed = true;
      console.error('FAIL mutation survived: ' + name);
    } else console.log('PASS Forsaken ' + name);
  } catch (error) {
    if (mutations) console.log('PASS mutation killed: ' + name + ': ' + String(error).split('\n')[0]);
    else {
      failed = true;
      console.error('FAIL Forsaken ' + name + ': ' + (error.stack || error));
    }
  } finally {
    state.destroy();
  }
}
// Keep the release inventory stable while checking real presentation helpers.
if (!failed && !mutations) {
  for (const runner of ["./run_animation_r23.mjs", "./run_world_r34.mjs", "./run_audio_r34.mjs", "./run_sync_r35.mjs", "./run_sil_animation_r39.mjs"]) {
    try { await import(runner); }
    catch (error) { failed = true; console.error("FAIL Forsaken extension " + runner + ": " + (error.stack || error)); break; }
  }
}
process.exitCode = failed ? 1 : 0;
