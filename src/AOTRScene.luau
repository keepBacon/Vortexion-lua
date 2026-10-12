-- Pure AOTR place classification. Unknown places remain unsupported.
local Scene = {}
Scene.UNIVERSE = 4658598196
Scene.MENU = 13379208636
Scene.LOBBY = 14916516914
Scene.MISSION = 13379349730
Scene.TRADE = 14932214603
function Scene.resolve(universe, place)
    if tonumber(universe) ~= Scene.UNIVERSE then return nil end
    place=tonumber(place)
    if place==Scene.MENU or place==Scene.LOBBY then return "lobby" end
    if place==Scene.TRADE then return nil end
    if place==Scene.MISSION then return "battle" end
    -- Other sub-places are not assumed to be combat without mission evidence.
    return nil
end
return Scene
