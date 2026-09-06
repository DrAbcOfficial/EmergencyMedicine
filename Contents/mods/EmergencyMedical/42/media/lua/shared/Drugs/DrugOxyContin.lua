-- OxyContin: +15% health and +15% addiction, boredom/unhappiness/panic
-- halved, withdrawal relieved by a fifth per dose (five doses clear it).
-- AddGeneralHealth distributes the amount across the damaged body parts
-- (guarded when nothing is damaged), so 15 = +15% overall.
function TakeOxyContin(player)
    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getHealth() < 100 then
        bodyDamage:AddGeneralHealth(15)
    end
    EMDrug_HalveMind(player)
    EM_Withdrawal_Relieve(player, 0.2)
    EMDrug_ChangeAddiction(player, 0.15)
end
