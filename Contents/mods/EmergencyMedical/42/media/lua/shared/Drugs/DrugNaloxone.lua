-- Naloxone hydrochloride: -25% addiction, +25% hunger and thirst
-- (HUNGER/THIRST are CharacterStats in 0..1).
function InjectNaloxone(player)
    EMDrug_ChangeAddiction(player, -0.25)
    local stats = player:getStats()
    stats:set(CharacterStat.HUNGER, math.min(1.0, stats:get(CharacterStat.HUNGER) + 0.25))
    stats:set(CharacterStat.THIRST, math.min(1.0, stats:get(CharacterStat.THIRST) + 0.25))
end
