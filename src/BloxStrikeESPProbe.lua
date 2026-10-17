-- Vortexion R233 / BloxStrike read-only client environment probe.
-- No hooks, ESP creation, remote calls or game state writes.
local lines = {"[Vortexion R233 BloxStrike read-only ESP probe]"}
local function add(label, value)
    lines[#lines + 1] = tostring(label) .. ": " .. tostring(value)
end
local function attempt(label, callback)
    local ok, value = pcall(callback)
    add(label, ok and value or ("ERROR " .. tostring(value):sub(1, 180)))
    return ok and value or nil
end
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local workspaceService = game:GetService("Workspace")
local characters = workspaceService:FindFirstChild("Characters")
add("GameId", game.GameId)
add("PlaceId", game.PlaceId)
add("LocalPlayerAvailable", localPlayer ~= nil)
add("Players", #players:GetPlayers())
add("CharacterFolder", characters and characters.ClassName or "missing")
add("LocalPlayer.Character", localPlayer and localPlayer.Character ~= nil)
add("CurrentCamera", workspaceService.CurrentCamera ~= nil)
attempt("PlayerGui", function() return localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui") ~= nil end)
attempt("TeamAttribute", function() return localPlayer and localPlayer:GetAttribute("Team") end)
attempt("RobloxTeam", function() return localPlayer and localPlayer.Team and localPlayer.Team.Name end)
attempt("GameMode", function() return workspaceService:GetAttribute("Gamemode") end)
attempt("CTCharacter", function() return workspaceService:GetAttribute("CTCharacter") end)
attempt("TCharacter", function() return workspaceService:GetAttribute("TCharacter") end)
if characters then
    local folders, models, nested, modelRoots, healthAttrs = 0, 0, 0, 0, 0
    for _, child in ipairs(characters:GetChildren()) do
        if child:IsA("Folder") then
            folders = folders + 1
            for _, node in ipairs(child:GetChildren()) do
                if node:IsA("Model") then nested = nested + 1 end
            end
        elseif child:IsA("Model") then
            models = models + 1
            if child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart then modelRoots = modelRoots + 1 end
            if child:GetAttribute("Health") ~= nil then healthAttrs = healthAttrs + 1 end
        end
    end
    add("Characters immediate models / folders / nested models", tostring(models) .. " / " .. tostring(folders) .. " / " .. tostring(nested))
    add("Immediate models with root / Health attribute", tostring(modelRoots) .. " / " .. tostring(healthAttrs))
end
local shared = (getgenv and getgenv()) or _G
add("Wind bridge", type(shared.VortexionWindBridge) == "table" and shared.VortexionWindBridge.Active == true)
add("Blox visual module diagnostic available", type(shared.VortexionBloxESPDiagnostics) == "function")
if type(shared.VortexionBloxESPDiagnostics) == "function" then
    local ok, detail = pcall(shared.VortexionBloxESPDiagnostics)
    if ok then add("Live ESP", detail) else add("Live ESP Error", detail) end
end
local output = table.concat(lines, "\n")
print(output)
if type(setclipboard) == "function" then pcall(setclipboard, output) end
return output
