import fs from 'node:fs';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';

const local = new URL('../node_modules/luau-web/src/index.js', import.meta.url).pathname;
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(local) ? local : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname);
const { LuauState } = await import(pathToFileURL(modulePath).href);
const sourceUrl = name => new URL('../src/BloxStrike' + name + '.luau', import.meta.url);
let source = fs.readFileSync(new URL('./test_bloxstrike_enrichment.luau', import.meta.url), 'utf8');
for (const name of ['Common', 'Combat', 'Visual', 'Cosmetic']) {
  const token = '__' + name.toUpperCase() + '__';
  if (source.split(token).length !== 2) throw new Error('Expected exactly one ' + token);
  source = source.replace(token, () => '(function()\n' + fs.readFileSync(sourceUrl(name), 'utf8') + '\nend)()');
}
const originalIds = {
  Combat: ['BloxAimEnabled', 'BloxAimMode', 'BloxAimPart', 'BloxTouchAim', 'BloxWallCheck', 'BloxTeamCheck', 'BloxAimFov', 'BloxAimSmooth', 'BloxAimPrediction', 'BloxAimMaxAngle', 'BloxAimHitChance', 'BloxAimAttraction', 'BloxFovCircle', 'BloxTriggerAssist', 'BloxTriggerMode', 'BloxTriggerDelay', 'BloxHitbox', 'BloxHitboxMode', 'BloxHitboxSize'],
  Visual: ['BloxESP', 'BloxESPTeam', 'BloxESPDistance', 'BloxFullbright', 'BloxSpeedEnabled', 'BloxWalkSpeed', 'BloxFlyEnabled', 'BloxFlySpeed', 'BloxTouchFly', 'BloxNoclip'],
  Cosmetic: ['BloxSkinEnabled', 'BloxSkinWear', 'BloxCustomKnife', 'BloxKnifeType', 'BloxTrailPreview', 'BloxTrailPreviewColor'],
};
for (const [name, ids] of Object.entries(originalIds)) {
  const factory = fs.readFileSync(sourceUrl(name), 'utf8');
  for (const id of ids) if (!factory.includes(JSON.stringify(id))) throw new Error('Removed UI ID: ' + id);
}
const core = fs.readFileSync(sourceUrl('Core'), 'utf8');
for (const marker of ['UnbindFromRenderStep(frameName)', 'local cleaned = false', 'ui:Destroy()', 'common.Disposers[i] = nil']) {
  if (!core.includes(marker)) throw new Error('Missing Core lifecycle contract: ' + marker);
}
if (core.includes('tostring(bullet.path), tostring(bullet.slowMode)')) throw new Error('Core debug argument drift');
let coreRuntime = core;
for (const [name, binding] of Object.entries({ BloxCommonFactory: 'Common', BloxCombatFactory: 'Combat', BloxVisualFactory: 'Visual', BloxCosmeticFactory: 'Cosmetic', BloxCloakFactory: 'CloakStub', BloxBulletFactory: 'BulletStub', WindBridgeFactory: 'BridgeStub', WindUI: '{}' })) {
  const declaration = 'local ' + name + ' = nil';
  if (!coreRuntime.includes(declaration)) throw new Error('Missing Core binding ' + name);
  coreRuntime = coreRuntime.replace(declaration, 'local ' + name + ' = ' + binding);
}
source = source.replace('__CORE__', () => '(function()\n' + coreRuntime + '\nend)');
async function execute(body, echo) {
  const log = echo ? console.log : () => {};
  const state = await LuauState.createAsync({ print: log, warn: log });
  try { await state.loadstring(body, 'test_bloxstrike_enrichment', true)(); }
  catch (error) { return String(error.stack || error); }
  finally { state.destroy(); }
}
const healthyError = await execute(source, true);
if (healthyError) throw new Error(healthyError);
console.log('PASS BloxStrike executable enrichment regressions; Core reload/unload/debug runtime');

// Fresh VM: retain every other teardown rule but deliberately remove time expiry.
const expiry = 'age >= TRAIL_LIFETIME or age < 0 or camera ~= entry.camera';
if (source.split(expiry).length !== 2) throw new Error('Expected one trail expiry anchor');
const mutant = source.replace(expiry, () => 'false or age < 0 or camera ~= entry.camera');
const negativeError = await execute(mutant, false);
if (!negativeError?.includes('trail preview expires at 0.5 seconds')) {
  throw new Error('R38 trail expiry negative missed its intended assertion: ' + negativeError);
}
console.log('R38_NC trail-expiry CAPTURED sha256=' + crypto.createHash('sha256').update(mutant).digest('hex') + ' bytes=' + Buffer.byteLength(mutant) + ' by: trail preview expires at 0.5 seconds');
