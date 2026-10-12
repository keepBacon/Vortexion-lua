-- SCP: Roleplay team/rank metadata resolver.
-- Only reads client-replicated properties; no remote calls or guesses.
local Metadata = {}
local rankFields = {"Rank", "Role", "Job", "JobTitle", "Position", "Title"}
local function clean(v)
    if type(v) == "string" and v ~= "" then return string.sub(v, 1, 64) end
    return nil
end
function Metadata.Team(player)
    local team = player and player.Team
    if team then return team.Name, team.TeamColor.Color end
    return "未知阵营", Color3.fromRGB(180, 180, 180)
end
function Metadata.Rank(player)
    if not player then return "未知职位" end
    for _, attr in ipairs(rankFields) do
        local value = clean(player:GetAttribute(attr))
        if value then return value end
    end
    local char = player.Character
    if char then
        for _, attr in ipairs(rankFields) do
            local value = clean(char:GetAttribute(attr))
            if value then return value end
        end
    end
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        for _, key in ipairs(rankFields) do
            local value = stats:FindFirstChild(key)
            if value and value:IsA("StringValue") then
                local name = clean(value.Value)
                if name then return name end
            end
        end
    end
    return "未知职位"
end
function Metadata.Snapshot(player)
    local team, color = Metadata.Team(player)
    return {team = team, color = color, rank = Metadata.Rank(player)}
end
return Metadata
