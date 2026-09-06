-- EmergencyMedical: amphetamine WITHDRAWAL -- the active suffering
-- value. Mirrors OpioidWithdrawal.lua: value management + the severe
-- threshold; the per-minute dynamics and the behavioural effects live in
-- AmphetamineSimulation.lua.

local MOD_KEY = "EM_AmphWithdrawal"
-- tier 3 ("severe") entry, aligned with the display level table
local SEVERE_LEVEL = 0.5

local function ModData(player)
    local data = player and player:getModData()
    if data == nil then
        return nil
    end
    return data
end

function EM_AmphWithdrawal_Get(player)
    local data = ModData(player)
    if data == nil then
        return 0
    end
    local value = data[MOD_KEY]
    if value == nil then
        return 0
    end
    return tonumber(value) or 0
end

function EM_AmphWithdrawal_Set(player, value)
    local data = ModData(player)
    if data == nil then
        return
    end
    value = tonumber(value) or 0
    if value <= 0 then
        data[MOD_KEY] = nil
    else
        value = math.min(value, 1)
        data[MOD_KEY] = value
    end
end

-- Display levels share the opioid thresholds: 0.15/0.3/0.5/0.7 -> 1..4.
function EM_AmphWithdrawal_GetLevel(player)
    local value = EM_AmphWithdrawal_Get(player)
    if value >= 0.7 then
        return 4
    elseif value >= 0.5 then
        return 3
    elseif value >= 0.3 then
        return 2
    elseif value >= 0.15 then
        return 1
    end
    return 0
end

function EM_AmphWithdrawal_IsSevere(player)
    return EM_AmphWithdrawal_Get(player) >= SEVERE_LEVEL
end

function EM_AmphWithdrawal_GetSevereLevel()
    return SEVERE_LEVEL
end
