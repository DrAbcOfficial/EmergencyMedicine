-- Dextromethorphan: the OTC cough suppressant from every family
-- bathroom cabinet, named plainly because that is all it is. While the
-- dose lasts it holds the sneezing/coughing down (CoughSuppress marker
-- state on the head; BodyWoundSimulation pins the vanilla sneeze
-- countdown) and feeds the vanilla coldReduction channel -- the game's
-- own flu-medicine hook, which forces the recovering branch and doubles
-- the recovery rate while it lasts. The cold itself is NOT touched:
-- coldStrength only falls to rest/warmth/food, the drug buys the window
-- to rest in. Side effects: heavy drowsiness and a dry mouth -- which
-- is the point, sleep is how you actually recover. Short-window
-- overdosing piles on nausea and knocks you out cold.
local SUPPRESS_HOURS = 6.0        -- CoughSuppress marker duration
local COLD_REDUCTION = 12.0       -- vanilla coldReduction feed per dose
local SEDATION_FATIGUE = 0.3      -- antihistamine drowsiness
local DRY_MOUTH_THIRST = 0.15     -- antihistamine dry mouth
local OVERDOSE_WINDOW_HOURS = 6.0 -- rolling dose-recall window
local OVERDOSE_DOSES = 3          -- doses within the window = overdose
local OVERDOSE_NAUSEA = 25.0      -- FOOD_SICKNESS bump on overdose

-- rolling dose log (hoursSurvived stamps, pruned to the window);
-- lives on the taker's modData -- effects run on the server in MP, so
-- the authoritative copy is the saved one
local function recordDose(player, now)
    local modData = player:getModData()
    local doses = modData.EM_DXM_Doses
    local fresh = {}
    if doses ~= nil then
        for i = 1, #doses do
            if now - doses[i] <= OVERDOSE_WINDOW_HOURS then
                fresh[#fresh + 1] = doses[i]
            end
        end
    end
    fresh[#fresh + 1] = now
    modData.EM_DXM_Doses = fresh
    return #fresh
end

function TakeDextromethorphan(player)
    local bodyDamage = player:getBodyDamage()
    -- the vanilla flu-medicine channel: forces recovering + doubles the
    -- cold recovery rate while the feed lasts (consumes itself)
    bodyDamage:setColdReduction(bodyDamage:getColdReduction() + COLD_REDUCTION)
    -- cough suppression marker; the tick holds the sneeze countdown back
    local head = EMDrug_GetHeadPart(player)
    EM_Wound_Add(player, head, "CoughSuppress", SUPPRESS_HOURS / EM_CONST.HOURS_PER_GAME_DAY)
    -- antihistamine side effects: drowsy is the trade that steers you to
    -- the bed the cold needs anyway
    local stats = player:getStats()
    stats:set(CharacterStat.FATIGUE, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.FATIGUE) + SEDATION_FATIGUE))
    stats:set(CharacterStat.THIRST, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.THIRST) + DRY_MOUTH_THIRST))
    -- chugging: nausea and lights out where you stand
    if recordDose(player, player:getHoursSurvived()) >= OVERDOSE_DOSES then
        EMDrug_AddFoodSickness(player, OVERDOSE_NAUSEA)
        stats:set(CharacterStat.FATIGUE, EM_CONST.STAT_SCALE_MAX)
    end
end
