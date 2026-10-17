-- P0 loader contract tests using a deterministic mocked Roblox host.
-- Run: texlua tests/test_loader_p0.lua (or any Lua 5.3+ interpreter).
local loaderPath = "loader.lua"
local loadScript = assert(loadfile(loaderPath))
local originalLoad = loadScript
local tests = 0
local function contains(s, part)
    assert(type(s) == "string" and s:find(part, 1, true), ("expected '%s' in '%s'"):format(part, tostring(s)))
end
local function fakeSource(code)
    return code .. string.rep("\n-- asset placeholder padding", 10)
end
local function reset(opts)
    opts = opts or {}
    local context = {warnings = {}, instances = {}, calls = 0, source = opts.source or fakeSource('getgenv().VortexionWindBridge = {Active=true}'), shouldFail = opts.shouldFail}
    local environment = {VortexionSourceBase = opts.base}
    _G.getgenv = function() return environment end
    _G.loadstring = load
    _G.warn = function(msg) table.insert(context.warnings, tostring(msg)) end
    _G.Color3 = {fromRGB=function(r,g,b) return {r,g,b} end}
    _G.UDim2 = {new=function(...) return {...} end}
    _G.UDim = {new=function(...) return {...} end}
    _G.Vector2 = {new=function(...) return {...} end}
    _G.Enum = {TextXAlignment={Left=1},TextYAlignment={Center=1,Top=2},Font={GothamBold=1,Gotham=2,GothamMedium=3}}
    local root = {kind="CoreGui"}
    _G.Instance = {new=function(class)
        local obj = {ClassName=class, Destroy=function(self) self.destroyed=true end, MouseButton1Click={}}
        obj.MouseButton1Click.Connect=function(_, callback) obj.click=callback end
        table.insert(context.instances,obj)
        return obj
    end}
    if opts.noUi then _G.Instance=nil end
    _G.gethui = nil
    _G.task = {
        spawn=function(fn) fn() end,
        wait=function() end,
    }
    _G.game = {
        GameId=6331902150, PlaceId=18687417158,
        IsLoaded=function() return true end,
        GetService=function(_,service)
            if service == "CoreGui" then
                if opts.noParent then error("CoreGui denied") end
                return root
            elseif service == "Players" then return {} end
        end,
        HttpGet=function(_,url)
            context.calls=context.calls+1; context.url=url
            if context.shouldFail then error("fixture network failed") end
            return context.source
        end,
    }
    _G.setclipboard=function(text) context.clipboard=text end
    _G.toclipboard=nil
    context.env=environment
    return context
end

local function runCase(name, fn)
    local ok,err=pcall(fn)
    _G.Instance=nil;_G.task=nil;_G.game=nil
    if not ok then error("FAIL "..name..": "..tostring(err)) end
    tests=tests+1;print("PASS "..name)
end

runCase("success creates diagnostic panel and reports live bridge", function()
    local c=reset({base="https://example.test/base///"})
    originalLoad()
    local st=c.env.VortexionLoaderV2
    assert(st and st.status=="success" and st.stage=="complete")
    assert(c.calls==1)
    assert(c.url=="https://example.test/base/dist/Vortexion_Wind.lua")
    assert(st.gui and st.gui.Parent and st.ui.detail and st.ui.status)
    contains(st.GetDiagnostics(),"GameId: 6331902150")
    contains(st.GetDiagnostics(),"Active WindUI bridge registered")
end)

runCase("download failure stays visible and retry succeeds", function()
    local c=reset({shouldFail=true})
    originalLoad()
    local st=c.env.VortexionLoaderV2
    assert(st.status=="failed" and st.stage=="download" and st.ui.retry.Visible)
    contains(st.error,"fixture network failed")
    assert(c.calls==1)
    c.shouldFail=false
    st.ui.retry.click()
    assert(st.status=="success" and c.calls==2)
    st.ui.copy.click()
    contains(c.clipboard,"Stage: complete")
end)

runCase("compilation failures diagnosed independently", function()
    local c=reset({source=fakeSource("bad lua code ..")})
    originalLoad()
    local st=c.env.VortexionLoaderV2
    assert(st.status=="failed" and st.stage=="compile")
    contains(st.error,"Luau compile error")
end)

runCase("runtime failures diagnosed independently", function()
    local c=reset({source=fakeSource('error("module exploded")')})
    originalLoad()
    local st=c.env.VortexionLoaderV2
    assert(st.status=="failed" and st.stage=="runtime")
    contains(st.error,"module exploded")
end)

runCase("missing bridge is not reported as success", function()
    local c=reset({source=fakeSource('local result = true')})
    originalLoad()
    local st=c.env.VortexionLoaderV2
    assert(st.status=="failed" and st.stage=="runtime")
    contains(st.error,"VortexionWindBridge")
end)

runCase("invalid source base fails before HTTP call", function()
    local c=reset({base="file:///etc"})
    originalLoad()
    local st=c.env.VortexionLoaderV2
    assert(st.status=="failed" and st.stage=="source" and c.calls==0)
end)

runCase("missing GUI privileges degrade to console diagnostics", function()
    local c=reset({noUi=true,shouldFail=true})
    originalLoad()
    local st=c.env.VortexionLoaderV2
    assert(st.status=="failed" and st.gui==nil and c.calls==1)
    assert(#c.warnings>2)
    contains(st.GetDiagnostics(),"fixture network failed")
end)

runCase("rerun replaces only previous loader panel", function()
    local c=reset()
    originalLoad()
    local old=c.env.VortexionLoaderV2
    local ui=old.gui
    originalLoad()
    assert(old.cancelled and ui.destroyed)
    assert(c.env.VortexionLoaderV2~=old and c.env.VortexionLoaderV2.status=="success")
end)

print("PASS "..tests.." loader P0 test scenarios")
