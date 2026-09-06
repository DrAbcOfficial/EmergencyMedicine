-- Dexmedetomidine hydrochloride: potent sedative -- wipes panic and
-- stress outright, but sedation means moderately increased fatigue.
-- Side effect: severe head pain.
function TakeDexmedetomidine(player)
    local stats = player:getStats()
    stats:set(CharacterStat.PANIC, 0.0)
    stats:set(CharacterStat.STRESS, 0.0)
    stats:set(CharacterStat.FATIGUE, math.min(1.0, stats:get(CharacterStat.FATIGUE) + 0.3))
    EMDrug_GetHeadPart(player):setAdditionalPain(math.min(
        EMDrug_GetHeadPart(player):getAdditionalPain() + 70.0, 100.0))
end
