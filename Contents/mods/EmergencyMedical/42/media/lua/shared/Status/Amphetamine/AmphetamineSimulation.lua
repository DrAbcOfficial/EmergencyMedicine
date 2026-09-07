-- EmergencyMedical: the amphetamine per-minute simulation (dynamics +
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
-- * at severe withdrawal or worse the DRUNK stat (0..1) creeps up by
--   "AmphDrunkPerMinute" as well;
-- * during MILD or MODERATE withdrawal (levels 1-2) the stimulant
--   keeps the body running: HUNGER is drained by
--   "AmphHungerSuppressionPerMinute" and FATIGUE by
--   "AmphSleepReductionPerMinute" per minute (the defaults outpace the
--   vanilla stat gains -- the character never feels hungry or tired),
--   and ENDURANCE keeps recovering at "AmphEnduranceRestorePerMinute";
-- * at severe withdrawal or worse the crash sets in: the DRUNK stat
--   (0..1) creeps up by "AmphDrunkPerMinute", and HUNGER and THIRST
--   climb by "AmphCrashAppetitePerDay" of the full stat scale per game
--   day (default 1.0 = starved and parched within one day);
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
    local data = player and player:getModData()
    if data == nil then
        return
    end
    data[METH_HIGH_KEY] = player:getHoursSurvived() + durationHours
    EM_Dependence_Transmit(player)
end

local function tickMethHigh(player)
    local data = player and player:getModData()
    if data == nil or data[METH_HIGH_KEY] == nil then
        return
    end
    if player:getHoursSurvived() < data[METH_HIGH_KEY] then
        EM_AmphAddiction_Set(player, EM_AmphAddiction_Get(player) + 1 / 60)
    else
        data[METH_HIGH_KEY] = nil
    end
end

local function minuteTick(player)
    if player == nil then
        return
    end
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
        local panic = EM_Sandbox_Get("AmphPanicPerMinute")
        if panic > 0 then
            stats:set(CharacterStat.PANIC, math.min(EM_CONST.STAT_SCALE_MAX_100, stats:get(CharacterStat.PANIC) + panic))
        end
        local unhappiness = EM_Sandbox_Get("AmphUnhappinessPerMinute")
        if unhappiness > 0 then
            stats:set(CharacterStat.UNHAPPINESS, math.min(EM_CONST.STAT_SCALE_MAX_100, stats:get(CharacterStat.UNHAPPINESS) + unhappiness))
        end
        -- severe withdrawal or worse: the crash -- drunkenness plus a
        -- ravenous appetite (hunger and thirst climb a full stat scale
        -- per game day at the default rate)
        if withdrawal >= EM_AmphWithdrawal_GetSevereLevel() then
            local drunk = EM_Sandbox_Get("AmphDrunkPerMinute")
            if drunk > 0 then
                stats:set(CharacterStat.DRUNK, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.DRUNK) + drunk))
            end
            local appetite = EM_Sandbox_Get("AmphCrashAppetitePerDay")
            if appetite > 0 then
                local bump = appetite / EM_CONST.MINUTES_PER_GAME_DAY
                stats:set(CharacterStat.HUNGER, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.HUNGER) + bump))
                stats:set(CharacterStat.THIRST, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.THIRST) + bump))
            end
        end
    end

    -- mild/moderate withdrawal: the stimulant keeps the body running --
    -- hunger and sleepiness are suppressed (the defaults outpace the
    -- vanilla gains: never hungry, never tired) and endurance keeps
    -- recovering
    local level = EM_AmphWithdrawal_GetLevel(player)
    if level == 1 or level == 2 then
        local stats = player:getStats()
        local hungerSuppression = EM_Sandbox_Get("AmphHungerSuppressionPerMinute")
        if hungerSuppression > 0 then
            stats:set(CharacterStat.HUNGER, math.max(0.0, stats:get(CharacterStat.HUNGER) - hungerSuppression))
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

    -- opioid + amphetamine withdrawal stacking: health drains until death
    local crossLoss = EM_Sandbox_Get("CrossWithdrawalHealthLoss")
    if crossLoss > 0 and withdrawal > 0 and EM_Withdrawal_Get(player) > 0 then
        player:getBodyDamage():ReduceGeneralHealth(crossLoss / 60)
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
