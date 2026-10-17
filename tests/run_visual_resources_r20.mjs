import fs from "node:fs";
import crypto from "node:crypto";
import assert from "node:assert/strict";
import {pathToFileURL} from "node:url";
const root=new URL("../",import.meta.url).pathname;
const local=root+"node_modules/luau-web/src/index.js";
const runtime=process.env.LUAU_WEB_MODULE||(fs.existsSync(local)?local:root+"../wind-tools/node_modules/luau-web/src/index.js");
const {LuauState}=await import(pathToFileURL(runtime).href);
const sha=b=>crypto.createHash("sha256").update(b).digest("hex");
function input(name){const b=fs.readFileSync(root+name);console.log("R20_INPUT_SHA256 "+name+" "+sha(b)+" bytes="+b.length);return b.toString("utf8");}
function unique(s,t){assert.equal(s.split(t).length-1,1,"expected unique anchor: "+t);}
function before(s,a,z){unique(s,a);unique(s,z);const i=s.indexOf(a),j=s.indexOf(z,i+a.length);assert(j>i,"invalid endpoint: "+z);return s.slice(i,j);}
const scp=input("src/SCPESP.luau"),core=input("src/SCPCore.luau"),fv=input("src/ForsakenVisual.luau"),sound=input("src/BloxStrikeCosmetic.luau"),aotr=input("src/AOTRESP.luau");
let body=input("tests/test_visual_resources_r20.luau");
const fragments={
__SCP_CONFIG__:before(scp,"local Config = {","ESP.Config = Config"),
__SCP_DRAWING__:before(scp,"local function createLine()","local function drawBox("),
__SCP_HELPERS__:before(scp,"local function hideEntry(entry)","local function drawOffscreenArrow("),
__SCP_CONTROLS__:before(core,"tabs.Visual:AddSlider(\"SCPESPLabelTextSize\"","tabs.Move:AddButton({ Title = \"立即起跳\""),
__FV_HELPERS__:before(fv,"local function findOrCreateByModel(","local function restoreBaseline()"),
__FV_MARKER__:before(fv,"local function highlightTarget(","local function nearestKiller()"),
__FV_SWEEP__:before(fv,"for inst, expiry in pairs(objects) do","if now >= nextLighting then"),
__SOUNDS__:before(sound,"local SOUND_MAX_LIFETIME=5","-- Motor6D needs"),
__AOTR_FACTORY__:"(function()\n"+aotr+"\nend)()",
__SCP_FACTORY__:"(function()\n"+scp+"\nend)()",
};
const mode=process.argv.slice(2).find(a=>a.startsWith("--negative="))?.slice(11);
const controls={"drawing":["__SCP_DRAWING__","if obj then pcall(function() obj:Remove() end) end","if false then pcall(function() obj:Remove() end) end","drawing setup rollback","failed drawing owns no live object"],"gui":["__SCP_HELPERS__","and entry.nativeLabel and entry.nativeLabel.Parent == parent","and entry.nativeLabel","native detached GUI is rebuilt","detached GUI replaced"],"child":["__SCP_HELPERS__","and entry.nativeText and entry.nativeText.Parent == entry.nativeLabel","and entry.nativeText","native detached text is rebuilt","detached child retired independently"],"cache":["__SCP_HELPERS__","if ok then entry.labelText, entry.labelColor = text, color end","if true then entry.labelText, entry.labelColor = text, color end","native text commit retries after failed write","failed text write does not commit cache"],"style":["__SCP_HELPERS__","if entry.labelSize ~= size then","if false then","native style controls and cache","live size and layout applied"],"helper":["__FV_HELPERS__","if inst then pcall(function() inst:Destroy() end) end","if false then pcall(function() inst:Destroy() end) end","Forsaken allocation rollback","failed helper owns no live object"],"sound":["__SOUNDS__","if connection then pcall(function() connection:Disconnect() end) end","if false then pcall(function() connection:Disconnect() end) end","sound stop disconnects subscriptions","owned sound connection disconnected"],"aotr":["__AOTR_FACTORY__","if not validEntry(record) then","if not record then","AOTR orphan child rebuilt","orphan child triggers transaction rebuild"],"dispose":["__SCP_FACTORY__","function ESP:Update(dt)\n\t\tif disposed then return end","function ESP:Update(dt)\n\t\t-- negative: removed disposed gate","disposed SCP ignores late event and frame delivery","disposed update reads no camera"],"chams":["__SCP_HELPERS__","elseif box then pcall(function() box:Destroy() end) end","elseif false then pcall(function() box:Destroy() end) end","chams setup rollback and detached cleanup","failed highlight retired"],"owned-child":["__AOTR_FACTORY__",'{"nameLabel","subLabel","barFill","barBack","highlight","billboard"}','{"highlight","billboard"}',"AOTR orphan child rebuilt","orphan child triggers transaction rebuild"]};
if(mode){assert(controls[mode],"unknown negative control");const [key,oldText,newText]=controls[mode];unique(fragments[key],oldText);fragments[key]=fragments[key].replace(oldText,()=>newText);}
for(const [marker,source]of Object.entries(fragments)){unique(body,marker);body=body.replace(marker,()=>source);}
assert(!body.match(/__[A-Z_]+__/),"unresolved fixture marker");
const buffer=Buffer.from(body,"utf8");console.log("R20_ASSEMBLED_SHA256 "+sha(buffer)+" bytes="+buffer.length+" mode="+(mode||"healthy"));
const state=await LuauState.createAsync({print:console.log,warn:console.warn});
try{const run=state.loadstring(buffer.toString("utf8"),"visual_resources_r20",true);let caught;try{await run();}catch(e){caught=e;}
if(mode){const text=String(caught);assert(caught&&text.includes("R20 FAIL "+controls[mode][3]+":")&&text.includes(controls[mode][4]),"negative failed outside intended assertion: "+text);console.log("R20_NEGATIVE_CAPTURED "+mode+" expected="+controls[mode][4]);}else if(caught){throw caught;}
}finally{state.destroy();}
