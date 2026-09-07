-- EmergencyMedical: the generic dependence-value engine behind the
-- opioid (Status/Opioid/*.lua) and amphetamine
-- (Status/Amphetamine/*.lua) systems.
-- Anything that stores one clamped 0..1 value in player modData and
-- reads display levels off it lives here ONCE -- the per-substance
-- files are thin wrappers that bind a modData key (and keep the public
-- EM_* API).
--
--   EM_Dependence_Get / Set(player, key)   -- the slot: nil when
--                                           -- drained to <= 0, cap 1
--   EM_Dependence_GetLevel(player, key)    -- thresholds 0.15/0.3/0.5/0.7
--   EM_Dependence_GetTier(player, key)     -- 1 = L1, 2 = L2-3, 3 = L4
--   EM_Dependence_IsSevere(player, key)    -- >= 0.5 (tier 3 entry)
--   EM_Dependence_Transmit(player)         -- the MP dual-branch push
--   EM_Dependence_TickCore(...)            -- the chase/fall/grind core
--
-- The transmit helper is shared by every modData write in the mod
-- (wound manager, drug effects, meth high): a server broadcasts its
-- copy, a client may only push its OWN player's table up (MP fact 4).
function EM_Dependence_Transmit(player)
    if isServer() then
        player:transmitModData()
    elseif isClient() and player:isLocalPlayer() then
        player:transmitModData()
    end
end

function EM_Dependence_Get(player, key)
    local data = player and player:getModData()
    if data == nil then
        return 0
    end
    local value = data[key]
    if value == nil then
        return 0
    end
    return tonumber(value) or 0
end

function EM_Dependence_Set(player, key, value)
    local data = player and player:getModData()
    if data == nil then
        return
    end
    value = tonumber(value) or 0
    if value <= 0 then
        data[key] = nil
    else
        data[key] = math.min(value, 1)
    end
end

-- display levels: LEVEL_THRESHOLDS[i] -> level i (identical for
-- addiction and withdrawal, both substances)
function EM_Dependence_GetLevel(player, key)
    local value = EM_Dependence_Get(player, key)
    for level = #EM_Dependence_LEVEL_THRESHOLDS, 1, -1 do
        if value >= EM_Dependence_LEVEL_THRESHOLDS[level] then
            return level
        end
    end
    return 0
end

-- flavour-text tier: 1 = mild (level 1), 2 = moderate (levels 2-3),
-- 3 = severe (level 4). 0 = none.
function EM_Dependence_GetTier(player, key)
    local level = EM_Dependence_GetLevel(player, key)
    if level <= 0 then
        return 0
    elseif level == 1 then
        return 1
    elseif level >= 4 then
        return 3
    end
    return 2
end

-- tier 3 ("severe") entry, deliberately not sandbox-exposed: the
-- addiction decay gate and the display flip are aligned with it
EM_Dependence_SEVERE = 0.5

-- display level thresholds (level 1..4 at >= 0.15/0.3/0.5/0.7);
-- exported read-only for consumers aligned with the levels (the
-- withdrawal haze starts at level 1)
EM_Dependence_LEVEL_THRESHOLDS = { 0.15, 0.3, 0.5, 0.7 }

function EM_Dependence_IsSevere(player, key)
    return EM_Dependence_Get(player, key) >= EM_Dependence_SEVERE
end

-- the per-minute dynamics core shared by OpioidSimulation.lua and
-- AmphetamineSimulation.lua (the behavioural effects differ per
-- substance and stay in their files):
--   * withdrawal chases the baseline: climbs at
--     baseline/climbMinutes while below it, wears off at
--     fallPerDay/1440 while above it;
--   * at severe withdrawal or worse the baseline grinds down at
--     decayPerDay/1440;
--   * a zero baseline ends the withdrawal immediately.
-- fallPerDay/decayPerDay are fractions of the full value per game day
-- (converted to per-minute here).
function EM_Dependence_TickCore(player, addictionKey, withdrawalKey, severeLevel, climbMinutes, fallPerDay, decayPerDay)
    local addiction = EM_Dependence_Get(player, addictionKey)
    if addiction <= 0 then
        EM_Dependence_Set(player, withdrawalKey, 0)
        return
    end
    local withdrawal = EM_Dependence_Get(player, withdrawalKey)
    local newWithdrawal = withdrawal
    if withdrawal < addiction then
        newWithdrawal = math.min(addiction, withdrawal + addiction / math.max(climbMinutes, 1))
    elseif withdrawal > addiction then
        newWithdrawal = math.max(addiction, withdrawal - fallPerDay / EM_CONST.MINUTES_PER_GAME_DAY)
    end
    if newWithdrawal ~= withdrawal then
        EM_Dependence_Set(player, withdrawalKey, newWithdrawal)
    end
    if newWithdrawal >= severeLevel then
        EM_Dependence_Set(player, addictionKey, EM_Dependence_Get(player, addictionKey) - decayPerDay / EM_CONST.MINUTES_PER_GAME_DAY)
        if EM_Dependence_Get(player, addictionKey) <= 0 then
            EM_Dependence_Set(player, withdrawalKey, 0)
        end
    end
end
