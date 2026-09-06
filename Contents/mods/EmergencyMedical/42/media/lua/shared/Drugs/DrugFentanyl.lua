-- Fentanyl: instant full heal, every wound severity knocked down to its
-- minimum of 1 (still present, just barely -- not removed), the vanilla
-- painkiller state at full strength, boredom/unhappiness/panic wiped,
-- withdrawal cut by the "FentanylRelief" fraction (1.0 = cleared
-- outright), + "FentanylAddiction" addiction (default 1.0 = the cap).
function InjectFentanyl(player)
    EMDrug_HealToFull(player)
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if part:getScratchTime() > 0 then
            part:setScratchTime(1)
        end
        if part:getCutTime() > 0 then
            part:setCutTime(1)
        end
        if part:getBurnTime() > 0 then
            part:setBurnTime(1)
        end
        if part:getDeepWoundTime() > 0 then
            part:setDeepWoundTime(1)
        end
        if part:getBiteTime() > 0 then
            part:setBiteTime(1)
        end
        if part:getFractureTime() > 0 then
            part:setFractureTime(1)
        end
        if part:getBleedingTime() > 0 then
            part:setBleedingTime(1)
        end
    end
    EMDrug_FullPainkiller(player)
    EMDrug_ClearMind(player)
    EM_Withdrawal_Set(player, EM_Withdrawal_Get(player) * (1 - EM_Sandbox_Get("FentanylRelief")))
    EMDrug_ChangeAddiction(player, EM_Sandbox_Get("FentanylAddiction"))
end
