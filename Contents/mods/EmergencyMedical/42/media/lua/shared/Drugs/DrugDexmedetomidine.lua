-- Dexmedetomidine hydrochloride: potent sedative -- wipes panic and
-- stress outright, but sedation means moderately increased fatigue.
-- Side effect: severe head pain.
local HEAD_PAIN = 70.0
local SEDATION_FATIGUE = 0.3

function TakeDexmedetomidine(player)
    local stats = player:getStats()
    stats:set(CharacterStat.PANIC, 0.0)
    stats:set(CharacterStat.STRESS, 0.0)
    stats:set(CharacterStat.FATIGUE, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.FATIGUE) + SEDATION_FATIGUE))
    EMDrug_HeadPain(player, HEAD_PAIN)
end
