-- Sulfadimidine: sulfonamide antibiotic -- clears the LOCAL wound
-- infection on every body part (NOT the Knox virus). Side effects:
-- severe head pain and a moderate fever (the thermoregulator pulls the
-- raised temperature back to 37 over time, so the fever fades).
function TakeSulfadimidine(player)
    EMDrug_ClearWoundInfection(player)
    EMDrug_GetHeadPart(player):setAdditionalPain(math.min(
        EMDrug_GetHeadPart(player):getAdditionalPain() + 70.0, 100.0))
    player:getStats():set(CharacterStat.TEMPERATURE, 38.5)
end
