-- EmergencyMedical: amphetamine ADDICTION -- the baseline dependence
-- value. Thin wrapper over the EM_Dependence engine (EM_Dependence.lua)
-- bound to the "EM_AmphAddiction" modData key, mirroring the opioid
-- split: value management only -- the addiction itself has NO gameplay
-- effect; the per-minute dynamics live in AmphetamineSimulation.lua.

local ADDICTION_KEY = "EM_AmphAddiction"

function EM_AmphAddiction_Get(player)
    return EM_Dependence_Get(player, ADDICTION_KEY)
end

function EM_AmphAddiction_Set(player, value)
    EM_Dependence_Set(player, ADDICTION_KEY, value)
end

function EM_AmphAddiction_GetLevel(player)
    return EM_Dependence_GetLevel(player, ADDICTION_KEY)
end

function EM_AmphAddiction_GetTier(player)
    return EM_Dependence_GetTier(player, ADDICTION_KEY)
end
