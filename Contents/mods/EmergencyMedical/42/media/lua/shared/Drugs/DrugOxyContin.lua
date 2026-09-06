-- OxyContin: +15% health and a sandbox-configurable addiction gain
-- ("OxycontinAddiction", default 0.15), boredom/unhappiness/panic
-- halved, withdrawal relieved by the "OxycontinRelief" fraction per dose
-- (default 0.2 -- five doses clear it). AddGeneralHealth distributes the
-- amount across the damaged body parts (guarded when nothing is
-- damaged), so 15 = +15% overall.
function TakeOxyContin(player)
    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getHealth() < 100 then
        bodyDamage:AddGeneralHealth(15)
    end
    EMDrug_HalveMind(player)
    EM_Withdrawal_Relieve(player, EM_Sandbox_Get("OxycontinRelief"))
    EMDrug_ChangeAddiction(player, EM_Sandbox_Get("OxycontinAddiction"))
end
