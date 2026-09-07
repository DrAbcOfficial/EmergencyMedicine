-- EmergencyMedical: opioid ADDICTION -- the baseline dependence value.
-- Thin wrapper over the EM_Dependence engine (EM_Dependence.lua) bound
-- to the "EM_OpioidAddiction" modData key: get/set, display levels and
-- tiers, plus the "one opioid injection happened" entry point
-- (addiction gain, withdrawal relief, modData sync). The coupled
-- per-minute dynamics live in OpioidSimulation.lua; withdrawal value
-- management in OpioidWithdrawal.lua.
--
-- Multiplayer: values live in player modData; the drug effects run on
-- the server (TakeDrug command) and broadcast with transmitModData(), a
-- client may only push its own player's table up.

local ADDICTION_KEY = "EM_OpioidAddiction"
-- per-injection gain is the "MorphineAddictionGain" sandbox option
-- (default 0.5), read at injection time

function EM_Addiction_Get(player)
    return EM_Dependence_Get(player, ADDICTION_KEY)
end

function EM_Addiction_Set(player, value)
    EM_Dependence_Set(player, ADDICTION_KEY, value)
end

function EM_Addiction_GetLevel(player)
    return EM_Dependence_GetLevel(player, ADDICTION_KEY)
end

function EM_Addiction_GetTier(player)
    return EM_Dependence_GetTier(player, ADDICTION_KEY)
end

-- One opioid injection happened: the baseline dependence rises by half,
-- the withdrawal sickness is relieved, and the new values are synced
-- (the server broadcasts; a client pushes its own table up). Called from
-- the morphine drug effect -- which runs on the server in MP (TakeDrug
-- command), directly in SP.
function EM_Addiction_UseInjection(player)
    EM_Addiction_Set(player, EM_Addiction_Get(player) + EM_Sandbox_Get("MorphineAddictionGain"))
    EM_Withdrawal_Relieve(player)
    EM_Dependence_Transmit(player)
end
