-- Downloads only the unified WindUI entry; routing lives inside that bundle.
-- This isolated Wind build has NOT been published to the GitHub URL below.
local env = (getgenv and getgenv()) or _G
local base = env.VortexionSourceBase
local path = "dist/Vortexion_Wind.lua"
if base == nil then
    base = "https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/"
    warn("[Vortexion/Wind] This Wind build is not published to GitHub. Set VortexionSourceBase to your hosting base before loading.")
end
if type(base) ~= "string" or not base:match("^https?://") then
    warn("[Vortexion/Wind] VortexionSourceBase must be an HTTP(S) base URL")
    return
end
base = base:gsub("/+$", "") .. "/"
local ok, err = pcall(function()
    local code = game:HttpGet(base .. path)
    local entry, compileError = loadstring(code)
    assert(type(entry) == "function", "Unified Wind entry did not compile: " .. tostring(compileError))
    entry()
end)
if not ok then
    warn("[Vortexion/Wind] Load failed (" .. base .. path .. "): " .. tostring(err))
end
