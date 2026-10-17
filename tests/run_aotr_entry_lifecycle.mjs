import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
const local = new URL('../node_modules/luau-web/src/index.js', import.meta.url).pathname;
const modulePath = process.env.LUAU_WEB_MODULE || (fs.existsSync(local) ? local : new URL('../../wind-tools/node_modules/luau-web/src/index.js', import.meta.url).pathname);
const { LuauState } = await import(pathToFileURL(modulePath).href);
const fixture = fs.readFileSync(new URL('test_aotr_entry_lifecycle.luau', import.meta.url), 'utf8');
let failures = 0;
for (const scene of ['Lobby', 'Battle']) {
    const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
    try {
        let entry = fs.readFileSync(new URL('../src/AOTR' + scene + '.luau', import.meta.url), 'utf8');
        for (const name of ['Cloak', 'Titans', 'Combat', 'Movement', 'ESP', 'Farm']) {
            entry = entry.replace('local AOTR' + name + 'Factory = nil', 'local AOTR' + name + 'Factory = __fixtureFactories.' + name);
        }
        const source = fixture.replace('__SCENE__', JSON.stringify(scene)).replace('__ENTRY__', '(function()\n' + entry + '\nend)()');
        await state.loadstring(source, 'AOTR' + scene + '-entry-lifecycle', true)();
    } catch (error) {
        failures++;
        console.error('FAIL AOTR ' + scene + ': ' + String(error));
    } finally { state.destroy(); }
}
process.exitCode = failures ? 1 : 0;
