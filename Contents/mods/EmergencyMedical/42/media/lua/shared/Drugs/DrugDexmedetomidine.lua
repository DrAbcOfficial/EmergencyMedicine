-- Dexmedetomidine hydrochloride: a potent sedative used in veterinary
-- medicine for small animals. What circulates among survivors is
-- repackaged animal stock, so every dose is a coin flip -- usually it
-- wipes panic and stress outright, but it can just as well backfire
-- into paradoxical agitation and SPIKE both. The "ShoddySedation"
-- marker rides the head for the duration (pure display row, no
-- upkeep; the roll result rides along as state.outcome). Sedation
-- drowsiness and severe head pain remain either way.
local HEAD_PAIN = 70.0
local SEDATION_FATIGUE = 0.3
local SEDATION_HOURS = 12.0
local CALM_CHANCE = 60          -- % roll for the calm outcome
local AGITATION_PANIC = 40.0    -- paradoxical agitation bump (0..100)
local AGITATION_STRESS = 0.4    -- paradoxical agitation bump (0..1)

function TakeDexmedetomidine(player)
    local stats = player:getStats()
    local head = EMDrug_GetHeadPart(player)
    local state = EM_Wound_Add(player, head, "ShoddySedation", SEDATION_HOURS / EM_CONST.HOURS_PER_GAME_DAY)
    if ZombRand(100) < CALM_CHANCE then
        -- the good vial: full calm
        if state ~= nil then
            state.outcome = "calm"
        end
        stats:set(CharacterStat.PANIC, 0.0)
        stats:set(CharacterStat.STRESS, 0.0)
    else
        -- the bad vial: paradoxical agitation, worse than not dosing
        if state ~= nil then
            state.outcome = "agitated"
        end
        stats:set(CharacterStat.PANIC, math.min(EM_CONST.STAT_SCALE_MAX_100, stats:get(CharacterStat.PANIC) + AGITATION_PANIC))
        stats:set(CharacterStat.STRESS, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.STRESS) + AGITATION_STRESS))
    end
    stats:set(CharacterStat.FATIGUE, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.FATIGUE) + SEDATION_FATIGUE))
    EMDrug_HeadPain(player, HEAD_PAIN)
end
