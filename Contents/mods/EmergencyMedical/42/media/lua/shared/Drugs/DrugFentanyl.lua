-- Fentanyl: instant full heal and EVERY wound wiped from the body --
-- all vanilla wounds, infections and the vanilla cauterized flag, plus
-- all the mod's custom wound states (scab, crude stitching, improvised
-- fixation, fentanyl patch); bullets and glass shards stay (objects,
-- not wounds). Then the vanilla painkiller state at full strength,
-- boredom/unhappiness/panic wiped, withdrawal cut by the
-- "FentanylRelief" fraction (1.0 = cleared outright), +
-- "FentanylAddiction" addiction (default 1.0 = the cap).
function InjectFentanyl(player)
    EMDrug_HealToFull(player)
    EMDrug_ClearAllWounds(player)
    EMDrug_ClearAllCustomWounds(player)
    EMDrug_FullPainkiller(player)
    EMDrug_ClearMind(player)
    EM_Withdrawal_Set(player, EM_Withdrawal_Get(player) * (1 - EM_Sandbox_Get("FentanylRelief")))
    EMDrug_ChangeAddiction(player, EM_Sandbox_Get("FentanylAddiction"))
end
