import fs from 'node:fs';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
const root = new URL('../', import.meta.url).pathname;
const local = root + 'node_modules/luau-web/src/index.js';
const runtime = fs.existsSync(local) ? local : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname;
const { LuauState } = await import(pathToFileURL(runtime).href);
const vendor = fs.readFileSync(root + 'vendor/WindUI/Source.lua', 'utf8');
function between(start, end) {
  const a = vendor.indexOf(start); const b = vendor.indexOf(end, a + start.length);
  if (a < 0 || b < 0) throw new Error('Vendor contract marker missing: ' + start);
  return vendor.slice(a, b);
}
const sliderMath = between('local function FormatValue(au)', 'local au,av');
const sliderSet = between('function al.Set(az,aA,aB)', 'function al.SetMax(az,aA)');
const configLoad = between('function ai.Load(aj)', 'function ai.Delete(aj)');
const colorpickerSet = between('function aw.Update(ay,az,aA)', '\naa.AddSignal(aw.UIElements.Colorpicker.MouseButton1Click');
const dropdownRefresh = between('function as.Refresh(au,av)', '\nas:Refresh(ap.Values)');
const dropdownCommit = dropdownRefresh.slice(dropdownRefresh.lastIndexOf('ap.UIElements.MenuCanvas.Size=UDim2.new('));
if (!dropdownCommit.startsWith('ap.UIElements.MenuCanvas.Size=UDim2.new(')) throw new Error('Vendor dropdown commit marker missing');
const dropdownCallback = between('local function Callback(au)', '\nfunction as.LockValues(au,av)');
const dropdownSelect = between('function as.Select(au,av)', '\nRecalculateListSize()');
const parsers = between('Parser={', 'function ae.Init(af,ag)').slice(7).trim().slice(0, -1).trim();
const base = fs.readFileSync(root + 'tests/test_wind_adapter.luau', 'utf8').split('local env, stops = {}, 0')[0];
const harness = fs.readFileSync(root + 'tests/wind_native_harness.luau', 'utf8').replace('__VENDOR_SLIDER__', sliderMath + sliderSet).replace('__VENDOR_CONFIG_LOAD__', configLoad).replace('__VENDOR_PARSERS__', parsers);
let source = base + harness + fs.readFileSync(root + 'tests/test_wind_native_contracts.luau', 'utf8').replace('local createBridge = __FACTORY__', '');
source = source.replace('__VENDOR_DROPDOWN_CALLBACK__', dropdownCallback).replace('__VENDOR_DROPDOWN_COMMIT__', dropdownCommit).replace('__VENDOR_DROPDOWN_SELECT__', dropdownSelect);
source = source.replace('__VENDOR_COLORPICKER__', () => colorpickerSet);
source = source.replace('__FACTORY__', () => '(function()\n' + fs.readFileSync(root + 'src/WindAdapter.luau', 'utf8') + '\nend)()');
async function execute(text, echo) {
  const lines = [];
  const log = (...args) => { const line = args.map(String).join(' '); lines.push(line); if (echo) console.log(line); };
  const state = await LuauState.createAsync({ print: log, warn: log });
  let error;
  try { await state.loadstring(text, 'wind_native_contracts', true)(); }
  catch (e) { error = String(e.stack || e); }
  finally { state.destroy(); }
  return { lines, error };
}
const healthy = await execute(source, true);
if (healthy.error) { console.error(healthy.error); process.exit(1); }

// A silent native update must not masquerade as a restored business value.
const anchor = 'if option.Native == element then option:SetValue(color); return end';
if (source.split(anchor).length !== 2) throw new Error('Color config synchronization anchor must be unique');
const mutated = source.replace(anchor, 'if option.Native == element then element:Set(color); return end');
const control = await execute(mutated, false);
const hit = control.lines.find(line => line.startsWith('RED contract color config round trip') && line.includes('color config restores business callback, option and native swatch'));
if (!hit || !control.error?.includes('WIND_NATIVE_CONTRACTS_RED:')) {
  console.error('R37_NC color-config-sync NOT-CAPTURED ' + (control.error || control.lines.join('\n')));
  process.exit(1);
}
console.log('R37_NC color-config-sync CAPTURED sha256=' + crypto.createHash('sha256').update(mutated).digest('hex') + ' bytes=' + Buffer.byteLength(mutated) + ' by: ' + hit);
