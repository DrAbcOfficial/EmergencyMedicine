-- EmergencyMedicine: the amphetamine per-minute simulation (dynamics +
-- behavioural effects). Mirrors OpioidSimulation.lua's cadence/branching
-- (server iterates online players, client handles the local player);
-- the shared chase/fall/grind core lives in EM_Dependence.lua
-- (EM_Dependence_TickCore).
--
-- Rules, every game minute:
-- * withdrawal chases the addiction baseline at
--   baseline/"AmphWithdrawalClimbMinutes" per minute (default 1440):
--   with a full baseline the SEVERE threshold (0.5) is crossed after
--   half a game day -- the conversion is deliberate and inevitable;
-- * only severe withdrawal grinds the baseline down, at
--   "AmphDecayRate" per game day (default 0.36 -- about twice as slow
--   as the opioid cold turkey, so quitting takes much longer);
-- * while withdrawing, PANIC and UNHAPPINESS (both 0..100) creep up by
--   "AmphPanicPerMinute" / "AmphUnhappinessPerMinute" per minute;
-- * the stimulant benefits apply as soon as ANY withdrawal exists
--   (counted at least level 1 -- no waiting for the level-1 threshold)
--   and until it turns severe: HUNGER and THIRST are both drained by
--   "AmphHungerThirstSuppressionPerMinute" and FATIGUE by
--   "AmphSleepReductionPerMinute" per minute (the defaults outpace the
--   vanilla stat gains -- the character never feels hungry or tired),
--   and ENDURANCE keeps recovering at "AmphEnduranceRestorePerMinute"
--   (default 0.1 -- tuned to survive sustained sprinting);
-- * at severe withdrawal or worse the crash sets in: HUNGER and THIRST
--   climb by "AmphCrashAppetitePerDay" of the full stat scale per game
--   day (default 1.0 = starved and parched within one day), and the
--   drug headache + drug fever statuses ACCUMULATE at
--   "AmphWithdrawalHeadachePerHour" / "AmphWithdrawalFeverPerHour"
--   progress per game hour (one add per hour per status, on top of
--   their natural decay);
-- * while opioid AND amphetamine withdrawal are BOTH active, overall
--   health takes "CrossWithdrawalHealthLoss" percent per game hour
--   (÷60 per minute) until death.
--
-- The addiction itself has no gameplay effect (display only).
--
-- Methamphetamine high: after a dose the addiction ramps up to the cap
-- (1.0) over one game hour -- the pending deadline lives in modData
-- ("EM_MethHigh", hoursSurvived) and the ramp is applied here, +1/60
-- per minute (set via EM_Meth_SetHigh from the drug effect).

local METH_HIGH_KEY = "EM_MethHigh"
-- modData keys -- must match AmphetamineAddiction.lua /
-- AmphetamineWithdrawal.lua
local ADDICTION_KEY = "EM_AmphAddiction"
local WITHDRAWAL_KEY = "EM_AmphWithdrawal"

-- drug effects call this with the ramp duration in game hours
function EM_Meth_SetHigh(player, durationHours)
    EM_TimedStatus.Set(player, METH_HIGH_KEY, nil, "high",
        EM_TimedStatus.TimedRecord(player:getHoursSurvived(), durationHours), true)
end

local function tickMethHigh(player)
    local high = EM_TimedStatus.Get(player, METH_HIGH_KEY, nil, "high")
    if high == nil then
        return
    end
    if player:getHoursSurvived() < high.expire then
        EM_AmphAddiction_Set(player, EM_AmphAddiction_Get(player) + 1 / 60)
    else
        EM_TimedStatus.Remove(player, METH_HIGH_KEY, nil, "high", false)
    end
end

local function minuteTick(player)
    if player == nil then
        return
    end
    local now = player:getHoursSurvived()
    tickMethHigh(player)
    EM_Dependence_TickCore(player,
        ADDICTION_KEY,
        WITHDRAWAL_KEY,
        EM_AmphWithdrawal_GetSevereLevel(),
        EM_Sandbox_Get("AmphWithdrawalClimbMinutes"),
        EM_Sandbox_Get("AmphDecayRate"),
        EM_Sandbox_Get("AmphDecayRate"))

    local withdrawal = EM_AmphWithdrawal_Get(player)
    if withdrawal > 0 then
        local stats = player:getStats()
        -- the panic/unhappiness rates are 0-1 fractions of the stats'
        -- own 0..100 scale
        local panic = EM_Sandbox_Get("AmphPanicPerMinute")
        if panic > 0 then
            stats:set(CharacterStat.PANIC, math.min(EM_CONST.STAT_SCALE_MAX_100, stats:get(CharacterStat.PANIC) + panic * EM_CONST.STAT_SCALE_MAX_100))
        end
        local unhappiness = EM_Sandbox_Get("AmphUnhappinessPerMinute")
        if unhappiness > 0 then
            stats:set(CharacterStat.UNHAPPINESS, math.min(EM_CONST.STAT_SCALE_MAX_100, stats:get(CharacterStat.UNHAPPINESS) + unhappiness * EM_CONST.STAT_SCALE_MAX_100))
        end
        -- severe withdrawal or worse: the crash -- a ravenous appetite
        -- (hunger and thirst climb a full stat scale per game day at the
        -- default rate) plus the body accumulating the drug headache and
        -- drug fever statuses (one progress add per status per game
        -- hour, self-clocked off the record's applied time)
        if withdrawal >= EM_AmphWithdrawal_GetSevereLevel() then
            local appetite = EM_Sandbox_Get("AmphCrashAppetitePerDay")
            if appetite > 0 then
                local bump = appetite / EM_CONST.MINUTES_PER_GAME_DAY
                stats:set(CharacterStat.HUNGER, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.HUNGER) + bump))
                stats:set(CharacterStat.THIRST, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.THIRST) + bump))
            end
            local headache = EM_TimedStatus.Get(player, EM_DrugFx_DATA_KEY, nil, "DrugHeadache")
            if headache == nil or now - headache.applied >= 1.0 then
                EM_DrugFx_Add(player, "DrugHeadache", { painFloor = EM_DRUG_HEADACHE_PAIN_FLOOR }, EM_Sandbox_Get("AmphWithdrawalHeadachePerHour"))
            end
            local fever = EM_TimedStatus.Get(player, EM_DrugFx_DATA_KEY, nil, "DrugFever")
            if fever == nil or now - fever.applied >= 1.0 then
                EM_DrugFx_Add(player, "DrugFever", { tempFloor = EM_DRUG_FEVER_TEMPERATURE }, EM_Sandbox_Get("AmphWithdrawalFeverPerHour"))
            end
        end
    end

    -- stimulant benefits: ANY withdrawal counts, at least level 1 -- no
    -- waiting for the level-1 threshold -- and only until it turns
    -- severe: hunger AND thirst are suppressed, sleepiness suppressed,
    -- endurance keeps recovering (the default is tuned to survive
    -- sustained sprinting)
    if withdrawal > 0 and withdrawal < EM_AmphWithdrawal_GetSevereLevel() then
        local stats = player:getStats()
        local hungerThirst = EM_Sandbox_Get("AmphHungerThirstSuppressionPerMinute")
        if hungerThirst > 0 then
            stats:set(CharacterStat.HUNGER, math.max(0.0, stats:get(CharacterStat.HUNGER) - hungerThirst))
            stats:set(CharacterStat.THIRST, math.max(0.0, stats:get(CharacterStat.THIRST) - hungerThirst))
        end
        local sleepReduction = EM_Sandbox_Get("AmphSleepReductionPerMinute")
        if sleepReduction > 0 then
            stats:set(CharacterStat.FATIGUE, math.max(0.0, stats:get(CharacterStat.FATIGUE) - sleepReduction))
        end
        local enduranceRestore = EM_Sandbox_Get("AmphEnduranceRestorePerMinute")
        if enduranceRestore > 0 then
            stats:set(CharacterStat.ENDURANCE, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.ENDURANCE) + enduranceRestore))
        end
    end

    -- opioid + amphetamine withdrawal stacking: health drains until
    -- death (the option is a 0-1 fraction of the health scale per game
    -- hour)
    local crossLoss = EM_Sandbox_Get("CrossWithdrawalHealthLoss")
    if crossLoss > 0 and withdrawal > 0 and EM_Withdrawal_Get(player) > 0 then
        player:getBodyDamage():ReduceGeneralHealth(crossLoss * EM_CONST.HEALTH_MAX / 60)
    end
end

EM_Sim.EveryOneMinute(minuteTick)
