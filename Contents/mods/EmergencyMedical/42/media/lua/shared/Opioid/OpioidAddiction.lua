-- EmergencyMedical: opioid ADDICTION -- the baseline dependence value.
-- Value management only: get/set, display levels/tiers, and the "one
-- opioid injection happened" entry point (addiction +0.5, withdrawal
-- relief, modData sync). The coupled per-minute dynamics live in
-- OpioidSimulation.lua; withdrawal value management in
-- OpioidWithdrawal.lua.
--
-- Multiplayer: values live in player modData, changed on the player's
-- own client and sent up with transmitModData() so the server saves it.

local MOD_KEY = "EM_OpioidAddiction"
-- per-injection gain is the "MorphineAddictionGain" sandbox option
-- (default 0.5), read at injection time

local function ModData(player)
    local data = player and player:getModData()
    if data == nil then
        return nil
    end
    return data
end

function EM_Addiction_Get(player)
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

function EM_Addiction_Set(player, value)
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

-- Display levels share the withdrawal thresholds: 0.15/0.3/0.5/0.7.
function EM_Addiction_GetLevel(player)
    local value = EM_Addiction_Get(player)
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
function EM_Addiction_GetTier(player)
    local level = EM_Addiction_GetLevel(player)
    if level <= 0 then
        return 0
    elseif level == 1 then
        return 1
    elseif level >= 4 then
        return 3
    end
    return 2
end

-- One opioid injection happened: the baseline dependence rises by half,
-- the withdrawal sickness is relieved, and the new values are synced to
-- the server. Called from the morphine drug effect.
function EM_Addiction_UseInjection(player)
    local data = ModData(player)
    if data == nil then
        return
    end
    EM_Addiction_Set(player, EM_Addiction_Get(player) + EM_Sandbox_Get("MorphineAddictionGain"))
    EM_Withdrawal_Relieve(player)
    if isClient() and player:isLocalPlayer() then
        player:transmitModData()
    end
end
