-- Migrated from the Build 41 NotSimpleTrade mod (InjectMorphine).
-- Inject morphine: heal up to 75% health, or take a penalty if already above.
function InjectMorphine(player)
    local bodyDamage = player:getBodyDamage()
    local health = bodyDamage:getHealth()
    if health < 75 then
        local gap = 75 - health
        bodyDamage:AddGeneralHealth(gap * bodyDamage:getBodyParts():size())
        player:Say(getText("IGUI_Morphine_Success"))
    else
        bodyDamage:ReduceGeneralHealth(health - 75)
        local pPart = bodyDamage:getBodyParts():get(BodyPartType.ToIndex(BodyPartType.Head))
        local flPain = pPart:getPain()
        pPart:setAdditionalPain(flPain + 33)
        player:Say(getText("IGUI_Morphine_Failed"))
    end
end
