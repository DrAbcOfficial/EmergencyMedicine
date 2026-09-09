-- EmergencyMedicine: opioid WITHDRAWAL -- the active suffering value.
-- Thin wrapper over the EM_Dependence engine (EM_Dependence.lua) bound
-- to the "EM_OpioidWithdrawal" modData key: get/set, display levels,
-- the severe threshold and the relief operation. The coupled per-minute
-- dynamics live in OpioidSimulation.lua; the addiction baseline in
-- OpioidAddiction.lua.

local WITHDRAWAL_KEY = "EM_OpioidWithdrawal"

function EM_Withdrawal_Get(player)
    return EM_Dependence_Get(player, WITHDRAWAL_KEY)
end

function EM_Withdrawal_Set(player, value)
    EM_Dependence_Set(player, WITHDRAWAL_KEY, value)
end

function EM_Withdrawal_GetLevel(player)
    return EM_Dependence_GetLevel(player, WITHDRAWAL_KEY)
end

function EM_Withdrawal_IsSevere(player)
    return EM_Dependence_IsSevere(player, WITHDRAWAL_KEY)
end

function EM_Withdrawal_GetSevereLevel()
    return EM_Dependence_SEVERE
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
