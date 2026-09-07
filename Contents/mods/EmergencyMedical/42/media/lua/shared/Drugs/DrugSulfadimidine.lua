-- Sulfadimidine: sulfonamide antibiotic -- clears the LOCAL wound
-- infection on every body part (NOT the Knox virus). Side effects:
-- severe head pain and a moderate fever (the thermoregulator pulls the
-- raised temperature back to 37 over time, so the fever fades).
local HEAD_PAIN = 70.0
local FEVER_TEMPERATURE = 38.5

function TakeSulfadimidine(player)
    EMDrug_ClearWoundInfection(player)
    EMDrug_HeadPain(player, HEAD_PAIN)
    player:getStats():set(CharacterStat.TEMPERATURE, FEVER_TEMPERATURE)
end
