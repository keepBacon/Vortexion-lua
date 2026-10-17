import fs from 'node:fs';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
const root = new URL('../', import.meta.url).pathname;
const local = root + 'node_modules/luau-web/src/index.js';
const runtime = fs.existsSync(local) ? local : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname;
const { LuauState } = await import(pathToFileURL(runtime).href);
const vendor = fs.readFileSync(root + 'vendor/WindUI/Source.lua', 'utf8');
function countOf(s, marker) { return s.split(marker).length - 1; }
function between(start, end) {
  const a = vendor.indexOf(start); const b = vendor.indexOf(end, a + start.length);
  if (a < 0 || b < 0) throw new Error('Vendor contract marker missing: ' + start);
  if (vendor.indexOf(start, a + start.length) >= 0 && vendor.indexOf(start, a + start.length) < b) throw new Error('Vendor start marker not unique: ' + start);
  return vendor.slice(a, b);
}
function replaceOnce(s, marker, value) {
  const n = countOf(s, marker);
  if (n !== 1) throw new Error('marker must appear exactly once before replace: ' + marker + ' (found ' + n + ')');
  return s.replace(marker, () => value);
}
// Real vendor code, unmodified: the slider math/config/parsers the shared harness needs, plus the three acrylic
// lifecycle functions under test (Open force-enable, Close force-disable, ToggleAcrylic model/blur mutation).
const sliderMath = between('local function FormatValue(au)', 'local au,av');
const sliderSet = between('function al.Set(az,aA,aB)', 'function al.SetMax(az,aA)');
const configLoad = between('function ai.Load(aj)', 'function ai.Delete(aj)');
const parsers = between('Parser={', 'function ae.Init(af,ag)').slice(7).trim().slice(0, -1).trim();
const vendorOpen = between('function aw.Open(F)', 'function aw.Close(F)');
const vendorClose = between('function aw.Close(F)', 'function aw.Destroy(F)');
const vendorToggleAcrylic = between('function aa.ToggleAcrylic(az,aA)', 'function aa.Gradient(az,aA,aB)');
if (!vendorOpen.includes('ToggleAcrylic(true)')) throw new Error('Vendor Open force-enable marker missing');
if (!vendorClose.includes('ToggleAcrylic(false)')) throw new Error('Vendor Close force-disable marker missing');
if (countOf(vendorClose, 'function G.Destroy(H)') !== 1) throw new Error('Vendor Close nested G.Destroy missing');
if (!vendorToggleAcrylic.includes('au.Enable()')) throw new Error('Vendor ToggleAcrylic blur marker missing');
const base = fs.readFileSync(root + 'tests/test_wind_adapter.luau', 'utf8').split('local env, stops = {}, 0')[0];
const harness = fs.readFileSync(root + 'tests/wind_native_harness.luau', 'utf8')
  .replace('__VENDOR_SLIDER__', () => sliderMath + sliderSet)
  .replace('__VENDOR_CONFIG_LOAD__', () => configLoad)
  .replace('__VENDOR_PARSERS__', () => parsers);
let source = base + harness + fs.readFileSync(root + 'tests/test_wind_acrylic_policy_r16.luau', 'utf8');
source = replaceOnce(source, '__VENDOR_OPEN__', vendorOpen);
source = replaceOnce(source, '__VENDOR_CLOSE__', vendorClose);
source = replaceOnce(source, '__VENDOR_TOGGLE_ACRYLIC__', vendorToggleAcrylic);
source = replaceOnce(source, '__FACTORY__', '(function()\n' + fs.readFileSync(root + 'src/WindAdapter.luau', 'utf8') + '\nend)()');
for (const marker of ['__VENDOR_OPEN__', '__VENDOR_CLOSE__', '__VENDOR_TOGGLE_ACRYLIC__', '__FACTORY__']) {
  if (countOf(source, marker) !== 0) throw new Error('marker not fully consumed: ' + marker);
}
console.log('R16_SOURCE_SHA256: ' + crypto.createHash('sha256').update(source).digest('hex'));
const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
try { await state.loadstring(source, 'wind_acrylic_policy_r16', true)(); } catch (error) { console.error(error.stack || error); process.exitCode = 1; } finally { state.destroy(); }
