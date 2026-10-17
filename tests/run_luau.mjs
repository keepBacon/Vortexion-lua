import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const localModule = new URL('../node_modules/luau-web/src/index.js', import.meta.url).pathname;
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(localModule) ? localModule : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname);
const { LuauState } = await import(pathToFileURL(modulePath).href);
const args = process.argv.slice(2);
const execute = args.includes('--execute');
const factoryPos = args.indexOf('--factory');
let factory;
if (factoryPos >= 0) factory = args.splice(factoryPos, 2)[1];
const files = args.filter(a => a !== '--execute');
if (!files.length && !execute) {
  const root = new URL('../', import.meta.url).pathname;
  for (const folder of ['src', 'dist']) {
    for (const name of fs.readdirSync(path.join(root, folder)).sort()) {
      if ((name.endsWith('.lua') || name.endsWith('.luau')) && name !== 'StarlightAdapter.luau') files.push(path.join(root, folder, name));
    }
  }
  files.push(path.join(root, 'vendor/WindUI/Source.lua'), path.join(root, 'loader.lua'));
}
const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
let failures = 0;
for (const file of files) {
  try {
    let source = fs.readFileSync(file, 'utf8');
    if (factory) source = source.replace('__FACTORY__', () => '(function()\n' + fs.readFileSync(factory, 'utf8') + '\nend)()');
    const fn = state.loadstring(source, path.basename(file), true);
    if (execute) await fn();
    console.log('PASS ' + (execute ? 'execute ' : 'compile ') + file);
  } catch (error) {
    failures++;
    console.error('FAIL ' + file + ': ' + (error.stack || error));
  }
}
state.destroy();
process.exitCode = failures ? 1 : 0;
