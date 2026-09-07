-- Fentanyl: instant full heal, every wound severity knocked down to its
-- minimum of 1 (still present, just barely -- not removed), the vanilla
-- painkiller state at full strength, boredom/unhappiness/panic wiped,
-- withdrawal cut by the "FentanylRelief" fraction (1.0 = cleared
-- outright), + "FentanylAddiction" addiction (default 1.0 = the cap).
-- every wound survives at this bare-minimum severity instead of
-- being removed outright
local MIN_WOUND_SEVERITY = 1

function InjectFentanyl(player)
    EMDrug_HealToFull(player)
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if part:getScratchTime() > 0 then
            part:setScratchTime(MIN_WOUND_SEVERITY)
        end
        if part:getCutTime() > 0 then
            part:setCutTime(MIN_WOUND_SEVERITY)
        end
        if part:getBurnTime() > 0 then
            part:setBurnTime(MIN_WOUND_SEVERITY)
        end
        if part:getDeepWoundTime() > 0 then
            part:setDeepWoundTime(MIN_WOUND_SEVERITY)
        end
        if part:getBiteTime() > 0 then
            part:setBiteTime(MIN_WOUND_SEVERITY)
        end
        if part:getFractureTime() > 0 then
            part:setFractureTime(MIN_WOUND_SEVERITY)
        end
        if part:getBleedingTime() > 0 then
            part:setBleedingTime(MIN_WOUND_SEVERITY)
        end
    end
    EMDrug_FullPainkiller(player)
    EMDrug_ClearMind(player)
    EM_Withdrawal_Set(player, EM_Withdrawal_Get(player) * (1 - EM_Sandbox_Get("FentanylRelief")))
    EMDrug_ChangeAddiction(player, EM_Sandbox_Get("FentanylAddiction"))
end
