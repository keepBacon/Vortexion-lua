// R34: Swords world-particle hide/restore contract for src/ForsakenVisual.luau.
// Default mode executes the checked-in instrumented fixture
// tests/test_world_r34.luau, which embeds the real production function bodies
// (restoreResourceWorld / resourceCurrent / findResourceWorldRoot /
// updateResourceWorld) verbatim. Mutation modes re-slice the production
// source and assemble mutated fixtures in memory only; nothing
// under tests/ is written at runtime. Health failures throw so a parent
// runner cannot swallow a non-zero exit.
// Usage:
//   node tests/run_world_r34.mjs                  # positive fixture
//   node tests/run_world_r34.mjs --mutations=all  # negative controls
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';

const root = path.resolve(import.meta.dirname, '..');
const srcRel = 'src/ForsakenVisual.luau';
const fixtureRel = 'tests/test_world_r34.luau';

const localModule = new URL('../node_modules/luau-web/src/index.js', import.meta.url).pathname;
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(localModule) ? localModule : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname);
const { LuauState } = await import(pathToFileURL(modulePath).href);

function slice(source, startMarker, endMarker, label) {
  const s = source.indexOf(startMarker);
  if (s < 0) throw new Error('anchor start missing (' + label + '): ' + startMarker.trim());
  if (source.indexOf(startMarker, s + 1) >= 0) throw new Error('anchor start not unique (' + label + ')');
  const e = source.indexOf(endMarker, s + 1);
  if (e < 0) throw new Error('anchor end missing (' + label + '): ' + endMarker.trim());
  const text = source.slice(s, e).replace(/\s+$/, '');
  if (!text.endsWith('end')) throw new Error('slice truncated (' + label + ')');
  return text + '\n';
}

const MUTATIONS = {
  filter: {
    slice: 'world',
    from: 'and isResourceSwordParticle(object, root) and',
    to: 'and true and',
    expect: 'B.e4Preserved',
    label: 'delete Swords filter (non-Swords particles also hidden)',
  },
  budget: {
    slice: 'world',
    from: 'if #batch >= 32 then break end',
    to: 'if false then break end',
    expect: 'C.budget32',
    label: 'delete per-tick 32-item budget',
  },
  restore: {
    slice: 'restore',
    from: 'for object, original in pairs(saved or {}) do',
    to: 'for object, original in pairs({}) do',
    expect: 'H.restoreTrue',
    label: 'restore loop disabled (old particles never restored)',
  },
  disconnect: {
    slice: 'restore',
    from: 'if subscription then pcall(function() subscription:Disconnect() end) end',
    to: 'if false then pcall(function() subscription:Disconnect() end) end',
    expect: 'D.oldConnectionDisconnected',
    label: 'old connection never disconnected (listener leak on map swap)',
  },
};

async function runLuauText(text, label) {
  const out = [];
  const state = await LuauState.createAsync({ print: (s) => out.push(String(s)), warn: (s) => out.push(String(s)) });
  try {
    const fn = state.loadstring(text, label, true);
    await fn();
    return { status: 0, out: out.join('\n') };
  } catch (error) {
    return { status: 1, out: out.join('\n') + '\n' + String((error && error.stack) || error) };
  } finally {
    state.destroy();
  }
}

async function main() {
  const source = fs.readFileSync(path.join(root, srcRel), 'utf8');
  const sha = crypto.createHash('sha256').update(source).digest('hex');
  const slices = {
    restore: slice(source, 'local function restoreResourceWorld(record)', 'local function releaseResourceRecord(record)', 'restoreResourceWorld'),
    current: slice(source, 'local function resourceCurrent(serial, char)', 'local function resourceWrite(record, object, key, value, equal)', 'resourceCurrent'),
    world: slice(source, 'local function findResourceWorldRoot()', 'local function resourceColorSequenceEqual(a, b)', 'world block'),
  };

  const fixture = fs.readFileSync(path.join(root, fixtureRel), 'utf8');
  for (const key of ['restore', 'current', 'world']) {
    if (!fixture.includes(slices[key].trimEnd())) throw new Error('fixture drift: ' + key + ' not embedded verbatim');
  }

  const arg = process.argv.find(a => a.startsWith('--mutations='));
  const only = arg ? arg.slice('--mutations='.length).split(',').filter(Boolean) : [];
  const names = only.length && !only.includes('all') ? only : Object.keys(MUTATIONS);
  for (const name of names) {
    if (!MUTATIONS[name]) throw new Error('unknown mutation: ' + name);
  }

  console.log('R34 world fixture');
  console.log('source: ' + srcRel + ' sha256=' + sha + ' bytes=' + source.length);
  console.log('fixture: ' + fixtureRel + ' sha256=' + crypto.createHash('sha256').update(fixture).digest('hex'));

  if (!arg) {
    const run = await runLuauText(fixture, 'test_world_r34.luau');
    const ok = run.status === 0 && run.out.includes('R34 PASS');
    console.log('default: ' + (ok ? 'PASS' : 'FAIL') + ' ' + (run.out.trim().split('\n').pop() || ''));
    if (!ok) throw new Error('R34 default fixture failed:\n' + run.out.trim());
  }

  for (const name of names) {
    const mutation = MUTATIONS[name];
    if (!fixture.includes(mutation.from)) throw new Error('mutation ' + name + ': pattern absent');
    const mutated = fixture.split(mutation.from).join(mutation.to);
    const run = await runLuauText(mutated, 'world_r34_' + name + '.luau');
    const ok = run.status !== 0 && run.out.includes('R34 FAIL') && run.out.includes(mutation.expect);
    console.log('mutation ' + name + ' (' + mutation.label + '): ' + (ok ? 'FAIL-AS-EXPECTED' : 'UNEXPECTED'));
    if (!ok) throw new Error('R34 mutation ' + name + ' behaved unexpectedly:\n' + run.out.trim());
  }

  console.log('R34 RESULT: all stages behaved as expected; production source untouched');
}

await main();
