-- EmergencyMedicine: amphetamine WITHDRAWAL -- the active suffering
-- value. Thin wrapper over the EM_Dependence engine (EM_Dependence.lua)
-- bound to the "EM_AmphWithdrawal" modData key: value management + the
-- severe threshold; the per-minute dynamics and the behavioural effects
-- live in AmphetamineSimulation.lua.

local WITHDRAWAL_KEY = "EM_AmphWithdrawal"

function EM_AmphWithdrawal_Get(player)
    return EM_Dependence_Get(player, WITHDRAWAL_KEY)
end

function EM_AmphWithdrawal_Set(player, value)
    EM_Dependence_Set(player, WITHDRAWAL_KEY, value)
end

function EM_AmphWithdrawal_GetLevel(player)
    return EM_Dependence_GetLevel(player, WITHDRAWAL_KEY)
end

function EM_AmphWithdrawal_IsSevere(player)
    return EM_Dependence_IsSevere(player, WITHDRAWAL_KEY)
end

function EM_AmphWithdrawal_GetSevereLevel()
    return EM_Dependence_SEVERE
end
