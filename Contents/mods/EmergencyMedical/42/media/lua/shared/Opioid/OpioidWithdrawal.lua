-- EmergencyMedical: opioid WITHDRAWAL -- the active suffering value.
-- Value management only: get/set, display levels, the severe threshold
-- and the relief operation. The coupled per-minute dynamics live in
-- OpioidSimulation.lua; the addiction baseline in OpioidAddiction.lua.

local WITHDRAWAL_KEY = "EM_OpioidWithdrawal"
-- tier 3 ("severe") entry: the addiction decay gate and the display flip
-- to the severe description -- exactly where the levels are aligned
local SEVERE_LEVEL = 0.5

local function ModData(player)
    local data = player and player:getModData()
    if data == nil then
        return nil
    end
    return data
end

function EM_Withdrawal_Get(player)
    local data = ModData(player)
    if data == nil then
        return 0
    end
    local value = data[WITHDRAWAL_KEY]
    if value == nil then
        return 0
    end
    return tonumber(value) or 0
end

function EM_Withdrawal_Set(player, value)
    local data = ModData(player)
    if data == nil then
        return
    end
    value = tonumber(value) or 0
    if value <= 0 then
        data[WITHDRAWAL_KEY] = nil
    else
        value = math.min(value, 1)
        data[WITHDRAWAL_KEY] = value
    end
end

-- Display levels share the addiction thresholds: 0.15/0.3/0.5/0.7. The
-- four description tiers map straight onto these levels.
function EM_Withdrawal_GetLevel(player)
    local value = EM_Withdrawal_Get(player)
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

function EM_Withdrawal_IsSevere(player)
    return EM_Withdrawal_Get(player) >= SEVERE_LEVEL
end

function EM_Withdrawal_GetSevereLevel()
    return SEVERE_LEVEL
end

-- One opioid shot knocks the sickness down by the "InjectionRelief"
-- sandbox amount (default 0.35); drugs with a different strength pass
-- their own amount.
function EM_Withdrawal_Relieve(player, amount)
    if amount == nil then
        amount = EM_Sandbox_Get("InjectionRelief")
    end
    EM_Withdrawal_Set(player, EM_Withdrawal_Get(player) - amount)
end
