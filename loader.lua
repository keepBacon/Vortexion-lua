-- Vortexion unified loader: exact Roblox experience routing.
-- Match Universe/GameId first so that all sub-places of a game share one branch.
local ROUTES = {
    [6331902150] = "dist/Vortexion_Forsaken.lua",
    [7633926880] = "dist/Vortexion_BloxStrike.lua",
    [1742264997] = "dist/Vortexion_SCPRoleplay.lua",
}
local PLACE_FALLBACK = {
    [18687417158] = "dist/Vortexion_Forsaken.lua",
    [114234929420007] = "dist/Vortexion_BloxStrike.lua",
    [5041144419] = "dist/Vortexion_SCPRoleplay.lua",
}
local base = "https://raw.githubusercontent.com/keepBacon/Vortexion-lua/main/"
local universe = tonumber(game.GameId)
local place = tonumber(game.PlaceId)
local path = ROUTES[universe] or PLACE_FALLBACK[place]
if not path then
    warn(("[Vortexion] Unsupported experience: GameId=%s, PlaceId=%s"):format(tostring(universe), tostring(place)))
    return
end
local ok, err = pcall(function()
    local code = game:HttpGet(base .. path)
    local entry = loadstring(code)
    assert(type(entry) == "function", "Downloaded script did not compile")
    entry()
end)
if not ok then warn("[Vortexion] Load failed (" .. path .. "): " .. tostring(err)) end
