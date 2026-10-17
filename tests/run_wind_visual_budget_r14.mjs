import fs from 'node:fs';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';

// Isolated executor for the R14 visual budget contract snapshot regression.
// Borrowed pattern from tests/run_wind_native_contracts.mjs; that file is untouched.
// The real Adapter factory is inlined into the fixture test, which supplies its own
// tripwire stubs (Options poison, forbidden scheduling, counting WindUI.CreateWindow).
const root = new URL('../', import.meta.url).pathname;
const windTools = new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname;
const localModule = root + 'node_modules/luau-web/src/index.js';
const runtime = fs.existsSync(windTools) ? windTools : localModule;
if (!fs.existsSync(runtime)) {
  console.error('luau-web runtime not found (checked ' + windTools + ' and ' + localModule + ')');
  process.exit(1);
}
const { LuauState } = await import(pathToFileURL(runtime).href);

const factory = fs.readFileSync(root + 'src/WindAdapter.luau', 'utf8');
const test = fs.readFileSync(root + 'tests/test_wind_visual_budget_r14.luau', 'utf8');
// The placeholder must appear exactly once before substitution (String.replace only swaps the
// first hit), and zero times after; distinct messages separate missing from duplicated.
const marker = '__FACTORY__';
const markerCount = test.split(marker).length - 1;
if (markerCount === 0) {
  console.error(`fixture test source is missing the ${marker} placeholder: expected exactly 1 occurrence, found 0`);
  process.exit(1);
}
if (markerCount > 1) {
  console.error(`fixture test source contains ${markerCount} ${marker} placeholders: expected exactly 1, found ${markerCount}`);
  process.exit(1);
}
const source = test.replace(marker, () => '(function()\n' + factory + '\nend)()');
if (source.includes(marker)) {
  console.error(`${marker} placeholder survived substitution: expected 0 remaining occurrences`);
  process.exit(1);
}

const sha256 = (text) => crypto.createHash('sha256').update(text).digest('hex');
const started = Date.now();
const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
try {
  await state.loadstring(source, 'wind_visual_budget_r14', true)();
} catch (error) {
  console.error(error.stack || String(error));
  process.exitCode = 1;
} finally {
  state.destroy();
}
const wallMs = Date.now() - started;
console.log('R14-EVIDENCE ' + JSON.stringify({
  command: 'node tests/run_wind_visual_budget_r14.mjs',
  cwd: root,
  exitCode: process.exitCode || 0,
  wallMs,
  node: process.version,
  luauWeb: runtime,
  windAdapterSha256: sha256(factory),
  testSha256: sha256(test),
  runnerSha256: sha256(fs.readFileSync(new URL(import.meta.url).pathname, 'utf8')),
}));
