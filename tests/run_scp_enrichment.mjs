import fs from "node:fs";
import { pathToFileURL } from "node:url";
const root = new URL("../", import.meta.url).pathname;
const local = new URL("../node_modules/luau-web/src/index.js", import.meta.url).pathname;
const runtime = fs.existsSync(local) ? local : new URL("../../wind-tools/node_modules/luau-web/src/index.js", import.meta.url).pathname;
const { LuauState } = await import(pathToFileURL(runtime).href);
const names = ["Common", "Candidates", "Camera", "Hitbox", "Movement", "ESP", "SilentAim", "Cloak"];
const factories = "{\n" + names.map(name => {
  const file = name === "Cloak" ? "SCPCloak.lua" : "SCP" + name + ".luau";
  return name + " = (function()\n" + fs.readFileSync(root + "src/" + file, "utf8") + "\nend)(),";
}).join("\n") + "\n}";
let core = fs.readFileSync(root + "src/SCPCore.luau", "utf8");
for (const name of names) core = core.replace("local SCP" + name + "Factory = nil", "local SCP" + name + "Factory = factories." + name);
core = core.replace("local SCPCloakFactory = nil", "local SCPCloakFactory = function() return { Start = function() end, Protect = function() end } end");
core = core.replace("local WindBridgeFactory = nil", "local WindBridgeFactory = function() return fixtureUI end");
let source = fs.readFileSync(root + "tests/test_scp_enrichment.luau", "utf8").replace("__FACTORIES__", factories).replace("__CORE__", core);
const state = await LuauState.createAsync({ print: console.log, warn: console.warn });
try { await state.loadstring(source, "test_scp_enrichment", true)(); } catch (error) { console.error(error.stack || error); process.exitCode = 1; } finally { state.destroy(); }
