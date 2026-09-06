-- OxyContin: +15% health and +15% addiction, boredom/unhappiness/panic
-- halved. AddGeneralHealth distributes the amount across the damaged
-- body parts (guarded when nothing is damaged), so 15 = +15% overall.
function TakeOxyContin(player)
    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getHealth() < 100 then
        bodyDamage:AddGeneralHealth(15)
    end
    EMDrug_HalveMind(player)
    EMDrug_ChangeAddiction(player, 0.15)
end
