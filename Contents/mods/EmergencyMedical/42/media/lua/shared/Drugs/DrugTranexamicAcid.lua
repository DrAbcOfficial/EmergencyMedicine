-- Tranexamic acid: antifibrinolytic -- clots a share of every part's
-- bleeding per dose, and the clotted amount lands on the part as extra
-- wound severity (hemostasis is paid for in wound weight, not granted
-- for free). Glass-shard parts are skipped: their vanilla bleeding
-- floor can't be clotted. Side effects: hypotensive weakness
-- (endurance crushed), nausea, and a lingering drug headache
-- (pain-floor state on the head; replaces the old one-time pain bump).
local STOP_RATIO = 0.7          -- share of bleedingTime clotted per dose
local WEAKNESS_ENDURANCE = 0.1  -- hypotension: endurance crushed to this
local SEDATION_FATIGUE = 0.2    -- antifibrinolytic malaise
local NAUSEA = 20.0             -- FOOD_SICKNESS bump (0..100, self-decays)
local HEADACHE_FLOOR = 12.0     -- DrugHeadache pain floor
local HEADACHE_HOURS = 9.0

function TakeTranexamicAcid(player)
    EMDrug_StopBleedingProportional(player, STOP_RATIO)
    local stats = player:getStats()
    stats:set(CharacterStat.ENDURANCE, math.min(stats:get(CharacterStat.ENDURANCE), WEAKNESS_ENDURANCE))
    stats:set(CharacterStat.FATIGUE, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.FATIGUE) + SEDATION_FATIGUE))
    EMDrug_AddFoodSickness(player, NAUSEA)
    -- lingering headache: state on the head, its painFloor custom param
    -- maintained by BodyWoundSimulation (instant top-up so it aches now)
    local head = EMDrug_GetHeadPart(player)
    local state = EM_Wound_Add(player, head, "DrugHeadache", HEADACHE_HOURS / EM_CONST.HOURS_PER_GAME_DAY)
    if state ~= nil then
        state.painFloor = HEADACHE_FLOOR
        if head:getAdditionalPain() < HEADACHE_FLOOR then
            head:setAdditionalPain(HEADACHE_FLOOR)
        end
    end
end
