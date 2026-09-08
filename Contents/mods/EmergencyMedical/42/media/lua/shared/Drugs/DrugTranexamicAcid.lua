-- Tranexamic acid: antifibrinolytic -- clots a share of every part's
-- bleeding per dose, and the clotted amount lands on the part as extra
-- wound severity (hemostasis is paid for in wound weight, not granted
-- for free). Glass-shard parts are skipped: their vanilla bleeding
-- floor can't be clotted. Side effects: hypotensive weakness
-- (endurance crushed), nausea, and a lingering drug headache
-- (pain-floor status; replaces the old one-time pain bump).
local STOP_RATIO = 0.7          -- share of bleedingTime clotted per dose
local WEAKNESS_ENDURANCE = 0.1  -- hypotension: endurance crushed to this
local SEDATION_FATIGUE = 0.2    -- antifibrinolytic malaise
local NAUSEA = 20.0             -- FOOD_SICKNESS bump (0..100, self-decays)

function TakeTranexamicAcid(player)
    EMDrug_StopBleedingProportional(player, STOP_RATIO)
    local stats = player:getStats()
    stats:set(CharacterStat.ENDURANCE, math.min(stats:get(CharacterStat.ENDURANCE), WEAKNESS_ENDURANCE))
    stats:set(CharacterStat.FATIGUE, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.FATIGUE) + SEDATION_FATIGUE))
    EMDrug_AddFoodSickness(player, NAUSEA)
    -- lingering headache status; DrugEffectSimulation floors the head's
    -- pain by the status level (instant top-up so it aches now)
    local head = EMDrug_GetHeadPart(player)
    EM_DrugFx_Add(player, "DrugHeadache", { painFloor = EM_DRUG_HEADACHE_PAIN_FLOOR })
    if head:getAdditionalPain() < EM_DRUG_HEADACHE_PAIN_FLOOR then
        head:setAdditionalPain(EM_DRUG_HEADACHE_PAIN_FLOOR)
    end
end
