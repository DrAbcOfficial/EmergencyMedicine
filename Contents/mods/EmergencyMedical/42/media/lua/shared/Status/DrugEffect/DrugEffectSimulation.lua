-- Drug side-effect status simulation: per-minute upkeep for the four
-- EM_DrugFx statuses (records in DrugEffectStatus.lua, same folder).
-- Same cadence/branching as the opioid/amphetamine simulations: the
-- server iterates online players, the client handles the local player.
--
-- The effective progress (stored value minus natural decay, computed
-- on read -- see DrugEffectStatus.lua) drives everything, scaled by
-- the "DrugStatusDebuffRate" sandbox conversion rate:
-- * "DrugHeadache" (tranexamic acid): the head's additionalPain floors
--   at the record's painFloor x progress x rate.
-- * "DrugFever" (sulfadimidine): the TEMPERATURE stat is pinned
--   between 37 and the record's tempFloor peak x progress x rate,
--   against the thermoregulator's pull back to 37.
-- * "CoughSuppress" (dextromethorphan): while any progress remains, the
--   sneeze/cough countdown (BodyDamage timeToSneezeOrCough,
--   real-world-seconds) is held at SNEEZE_HOLD -- a head cold goes
--   quiet; the cold itself (moodle, coldStrength) is untouched. Both
--   ends run the push, so MP suppresses the client's own countdown too.
-- * "ShoddySedation" (veterinary dexmedetomidine) is a pure marker --
--   the calm/agitation roll happened at dosing.
--
-- Records whose progress has decayed to zero are pruned locally (every
-- peer derives the same state from its own clock -- no transmit).

-- vanilla-normal body temperature (Celsius scale of the TEMPERATURE stat)
local NORMAL_TEMPERATURE = 37.0

-- the sneeze/cough countdown is held no lower than this while
-- "CoughSuppress" lasts (vanilla delays run 200-800; between two
-- per-minute ticks the countdown sheds ~60 units, so 90 always outruns
-- it -- the short tail after expiry is a feature: one last sniffle as
-- it wears off)
local SNEEZE_HOLD = 90.0

local function minuteTick(player)
    local now = player:getHoursSurvived()
    local drugFx = player:getModData()[EM_DrugFx_DATA_KEY]
    if drugFx == nil then
        return
    end
    local debuffRate = EM_Sandbox_Get("DrugStatusDebuffRate")
    local headache = drugFx["DrugHeadache"]
    if headache ~= nil then
        local progress = EM_DrugFx_Progress(headache, now)
        if progress <= 0.0 then
            drugFx["DrugHeadache"] = nil
        elseif headache.painFloor ~= nil then
            local floor = headache.painFloor * progress * debuffRate
            if floor > 0.0 then
                local head = EMDrug_GetHeadPart(player)
                if head:getAdditionalPain() < floor then
                    head:setAdditionalPain(floor)
                end
            end
        end
    end
    local fever = drugFx["DrugFever"]
    if fever ~= nil then
        local progress = EM_DrugFx_Progress(fever, now)
        if progress <= 0.0 then
            drugFx["DrugFever"] = nil
        elseif fever.tempFloor ~= nil then
            local floor = NORMAL_TEMPERATURE + (fever.tempFloor - NORMAL_TEMPERATURE) * progress * debuffRate
            local stats = player:getStats()
            if stats:get(CharacterStat.TEMPERATURE) < floor then
                stats:set(CharacterStat.TEMPERATURE, floor)
            end
        end
    end
    local suppress = drugFx["CoughSuppress"]
    if suppress ~= nil then
        if EM_DrugFx_Progress(suppress, now) <= 0.0 then
            drugFx["CoughSuppress"] = nil
        else
            -- dextromethorphan: hold the sneeze/cough countdown back so
            -- the head cold makes no noise for the duration
            local bodyDamage = player:getBodyDamage()
            if bodyDamage:getTimeToSneezeOrCough() < SNEEZE_HOLD then
                bodyDamage:setTimeToSneezeOrCough(SNEEZE_HOLD)
            end
        end
    end
end

local function simulate()
    if isServer() then
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            minuteTick(players:get(i))
        end
    else
        -- every local player (split-screen), not just index 0
        for i = 0, getNumActivePlayers() - 1 do
            local player = getSpecificPlayer(i)
            if player ~= nil and not player:isDead() and player:isLocalPlayer() then
                minuteTick(player)
            end
        end
    end
end

Events.EveryOneMinute.Add(simulate)
