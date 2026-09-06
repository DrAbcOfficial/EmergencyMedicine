-- Fentanyl: instant full heal, every wound severity knocked down to its
-- minimum of 1 (still present, just barely -- not removed), the vanilla
-- painkiller state at full strength, boredom/unhappiness/panic wiped,
-- +100% addiction (straight to the cap).
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
    EMDrug_ChangeAddiction(player, 1.0)
end
