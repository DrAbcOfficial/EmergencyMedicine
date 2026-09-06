-- EmergencyMedical: amphetamine ADDICTION -- the baseline dependence
-- value. Mirrors the opioid split (OpioidAddiction.lua): value
-- management only -- the addiction itself has NO gameplay effect; the
-- per-minute dynamics (withdrawal chase + decay) live in
-- AmphetamineSimulation.lua. Values live in player modData and sync via
-- transmitModData().

local MOD_KEY = "EM_AmphAddiction"

local function ModData(player)
    local data = player and player:getModData()
    if data == nil then
        return nil
    end
    return data
end

function EM_AmphAddiction_Get(player)
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

function EM_AmphAddiction_Set(player, value)
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
function EM_AmphAddiction_GetLevel(player)
    local value = EM_AmphAddiction_Get(player)
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

-- Display tier for flavour text: 1 = mild (level 1), 2 = moderate
-- (levels 2-3), 3 = severe (level 4). 0 = no addiction.
function EM_AmphAddiction_GetTier(player)
    local level = EM_AmphAddiction_GetLevel(player)
    if level <= 0 then
        return 0
    elseif level == 1 then
        return 1
    elseif level >= 4 then
        return 3
    end
    return 2
end
