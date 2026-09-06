-- EmergencyMedical: the amphetamine per-minute simulation (dynamics +
-- behavioural effects). Mirrors OpioidSimulation.lua's cadence/branching
-- (server iterates online players, client handles the local player).
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
-- * during MILD or MODERATE withdrawal (levels 1-2) the FATIGUE stat
--   (0..1) is drained by "AmphSleepReductionPerMinute" per minute --
--   the character cannot sleep;
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

-- drug effects call this with the ramp duration in game hours
function EM_Meth_SetHigh(player, durationHours)
    local data = player and player:getModData()
    if data == nil then
        return
    end
    data[METH_HIGH_KEY] = player:getHoursSurvived() + durationHours
    -- MP: effects run on the server (TakeDrug command) -> broadcast;
    -- a client may only push its own player's table up
    if isServer() then
        player:transmitModData()
    elseif isClient() and player:isLocalPlayer() then
        player:transmitModData()
    end
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
    local addiction = EM_AmphAddiction_Get(player)
    if addiction <= 0 then
        EM_AmphWithdrawal_Set(player, 0)
    else
        local withdrawal = EM_AmphWithdrawal_Get(player)
        local newWithdrawal = withdrawal
        if withdrawal < addiction then
            local climbMinutes = EM_Sandbox_Get("AmphWithdrawalClimbMinutes")
            newWithdrawal = math.min(addiction, withdrawal + addiction / math.max(climbMinutes, 1))
        elseif withdrawal > addiction then
            newWithdrawal = math.max(addiction, withdrawal - EM_Sandbox_Get("AmphDecayRate") / 1440)
        end
        if newWithdrawal ~= withdrawal then
            EM_AmphWithdrawal_Set(player, newWithdrawal)
        end
        -- only severe withdrawal (cold turkey) grinds the baseline down
        if newWithdrawal >= EM_AmphWithdrawal_GetSevereLevel() then
            EM_AmphAddiction_Set(player, addiction - EM_Sandbox_Get("AmphDecayRate") / 1440)
            if EM_AmphAddiction_Get(player) <= 0 then
                EM_AmphWithdrawal_Set(player, 0)
            end
        end
    end

    local withdrawal = EM_AmphWithdrawal_Get(player)
    if withdrawal > 0 then
        local stats = player:getStats()
        local panic = EM_Sandbox_Get("AmphPanicPerMinute")
        if panic > 0 then
            stats:set(CharacterStat.PANIC, math.min(100.0, stats:get(CharacterStat.PANIC) + panic))
        end
        local unhappiness = EM_Sandbox_Get("AmphUnhappinessPerMinute")
        if unhappiness > 0 then
            stats:set(CharacterStat.UNHAPPINESS, math.min(100.0, stats:get(CharacterStat.UNHAPPINESS) + unhappiness))
        end
        -- drunk kicks in at severe withdrawal or worse
        if withdrawal >= EM_AmphWithdrawal_GetSevereLevel() then
            local drunk = EM_Sandbox_Get("AmphDrunkPerMinute")
            if drunk > 0 then
                stats:set(CharacterStat.DRUNK, math.min(1.0, stats:get(CharacterStat.DRUNK) + drunk))
            end
        end
    end

    -- mild/moderate withdrawal keeps the character awake (fatigue drained)
    local level = EM_AmphWithdrawal_GetLevel(player)
    if level == 1 or level == 2 then
        local sleepReduction = EM_Sandbox_Get("AmphSleepReductionPerMinute")
        if sleepReduction > 0 then
            local stats = player:getStats()
            stats:set(CharacterStat.FATIGUE, math.max(0.0, stats:get(CharacterStat.FATIGUE) - sleepReduction))
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
