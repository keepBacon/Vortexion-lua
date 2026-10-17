import fs from 'node:fs';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
const root = new URL('../', import.meta.url).pathname;
const local = root + 'node_modules/luau-web/src/index.js';
const runtime = fs.existsSync(local) ? local : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname;
const { LuauState } = await import(pathToFileURL(runtime).href);
const vendor = fs.readFileSync(root + 'vendor/WindUI/Source.lua', 'utf8');
function between(start, end) {
  const occurrences = vendor.split(start).length - 1;
  if (occurrences !== 1) throw new Error('Vendor start marker must occur exactly once, got ' + occurrences + ': ' + start);
  const a = vendor.indexOf(start); const b = vendor.indexOf(end, a + start.length);
  if (a < 0 || b < 0) throw new Error('Vendor contract marker missing: ' + start);
  return vendor.slice(a, b);
}
const sliderMath = between('local function FormatValue(au)', 'local au,av');
const sliderSet = between('function al.Set(az,aA,aB)', 'function al.SetMax(az,aA)');
const configLoad = between('function ai.Load(aj)', 'function ai.Delete(aj)');
const dropdownRefresh = between('function as.Refresh(au,av)', '\nas:Refresh(ap.Values)');
const dropdownCommit = dropdownRefresh.slice(dropdownRefresh.lastIndexOf('ap.UIElements.MenuCanvas.Size=UDim2.new('));
if (!dropdownCommit.startsWith('ap.UIElements.MenuCanvas.Size=UDim2.new(')) throw new Error('Vendor dropdown commit marker missing');
const dropdownCallback = between('local function Callback(au)', '\nfunction as.LockValues(au,av)');
const dropdownSelect = between('function as.Select(au,av)', '\nRecalculateListSize()');
const parsers = between('Parser={', 'function ae.Init(af,ag)').slice(7).trim().slice(0, -1).trim();
const base = fs.readFileSync(root + 'tests/test_wind_adapter.luau', 'utf8').split('local env, stops = {}, 0')[0];
const harnessRaw = fs.readFileSync(root + 'tests/wind_native_harness.luau', 'utf8');
for (const marker of ['__VENDOR_SLIDER__', '__VENDOR_CONFIG_LOAD__', '__VENDOR_PARSERS__']) {
  const occurrences = harnessRaw.split(marker).length - 1;
  if (occurrences !== 1) throw new Error('Harness marker must occur exactly once, got ' + occurrences + ': ' + marker);
}
// Function replacements keep vendor slices literal: a string replacement would
// interpret $&, $1, $$ and friends inside the injected Lua source.
const harness = harnessRaw
  .replace('__VENDOR_SLIDER__', () => sliderMath + sliderSet)
  .replace('__VENDOR_CONFIG_LOAD__', () => configLoad)
  .replace('__VENDOR_PARSERS__', () => parsers);
if (base.split('local createBridge = __FACTORY__').length - 1 !== 1) throw new Error('Base mock must declare the factory hook exactly once');
const testbody = fs.readFileSync(root + 'tests/test_wind_input_queue_r14.luau', 'utf8');
for (const marker of ['__VENDOR_DROPDOWN_CALLBACK__', '__VENDOR_DROPDOWN_COMMIT__', '__VENDOR_DROPDOWN_SELECT__']) {
  const occurrences = testbody.split(marker).length - 1;
  if (occurrences !== 1) throw new Error('Test body marker must occur exactly once, got ' + occurrences + ': ' + marker);
}
let source = base + harness + testbody;
source = source
  .replace('__VENDOR_DROPDOWN_CALLBACK__', () => dropdownCallback)
  .replace('__VENDOR_DROPDOWN_COMMIT__', () => dropdownCommit)
  .replace('__VENDOR_DROPDOWN_SELECT__', () => dropdownSelect);
const adapter = fs.readFileSync(root + 'src/WindAdapter.luau', 'utf8');
source = source.replace('__FACTORY__', () => '(function()\n' + adapter + '\nend)()');
for (const marker of ['__VENDOR_', '__FACTORY__']) {
  if (source.includes(marker)) throw new Error('Unsubstituted fixture marker survived assembly: ' + marker);
}
function sha256(text) { return crypto.createHash('sha256').update(text).digest('hex'); }
function utf8Bytes(text) { return Buffer.byteLength(text, 'utf8'); }
console.log('R14 snapshot: runtime=' + runtime);
console.log('R14 snapshot: windAdapterSha256=' + sha256(adapter) + ' bytes=' + utf8Bytes(adapter));
console.log('R14 snapshot: testbodySha256=' + sha256(testbody) + ' bytes=' + utf8Bytes(testbody));
console.log('R14 snapshot: harnessSha256=' + sha256(harness) + ' bytes=' + utf8Bytes(harness));
console.log('R14 snapshot: baseSha256=' + sha256(base) + ' bytes=' + utf8Bytes(base));
console.log('R14 snapshot: vendorSha256=' + sha256(vendor) + ' bytes=' + utf8Bytes(vendor));
const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
try { await state.loadstring(source, 'wind_input_queue_r14', true)(); } catch (error) { console.error(error.stack || error); process.exitCode = 1; } finally { state.destroy(); }
