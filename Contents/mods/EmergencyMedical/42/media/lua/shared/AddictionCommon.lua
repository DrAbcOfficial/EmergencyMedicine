-- EmergencyMedical: opioid addiction + withdrawal statuses.
-- Two stacked 0..1 values (both vanilla-thirst style):
--
-- * Addiction (EM_OpioidAddiction) is the baseline dependence. Every
--   morphine injection pushes it up by 0.5 instantly (two shots from
--   clean = fully addicted); there is no timed use window. It has no
--   direct gameplay penalty of its own and decays only while withdrawal
--   is severe -- going cold turkey through the sickness is the only way
--   to lose dependence.
-- * Withdrawal (EM_OpioidWithdrawal) is the active suffering state. It
--   chases the addiction baseline: while below it climbs at
--   baseline * (1/180) per minute, so whatever the gap to the baseline
--   (at most the full 0..1 scale) closes within 3 game hours; while
--   above it (fresh relief) it wears off back toward the baseline at a
--   much slower 0.0002 per minute -- slower than the cold-turkey decay,
--   so a full baseline can burn down to zero inside one severe stretch.
--   When the baseline reaches zero the sickness ends immediately.
--   A morphine injection knocks withdrawal down by a flat 0.35.
-- * Symptom (client-only, see client/EMWithdrawalEffects.lua): a
--   fullscreen dark haze scales with the raw withdrawal value, up to
--   0.87 alpha at full withdrawal -- deliberately dark enough to hamper
--   play. (A heartbeat and a limp were tried here too but never took
--   effect in game; see the history note in EMWithdrawalEffects.lua.)
--   The old PANIC-stat press is gone.
--
-- Displayed as custom moodle-style icons in the vanilla moodle column
-- (see client/ISUI/OpioidAddictionStatus.lua and
-- client/ISUI/OpioidWithdrawalStatus.lua).
--
-- Multiplayer model (matches vanilla IsoPlayer:setUnwanted):
--  * values live in player modData, changed on the player's own client
--    and sent up with transmitModData() so the server saves it;
--  * every-minute tick runs on both sides at the same rate;
--  * the symptom effects are purely client-side (local player).

local MOD_KEY = "EM_OpioidAddiction"
local WITHDRAWAL_KEY = "EM_OpioidWithdrawal"
-- withdrawal tier 3 ("severe"): the addiction decay gate and the limp
-- tier -- exactly where the display flips to the severe description
local SEVERE_LEVEL = 0.5
local ADDICTION_PER_INJECTION = 0.5
local DECAY_PER_MINUTE = 0.0005
local WITHDRAWAL_RISE = 1 / 180
local WITHDRAWAL_FALL = 0.0002
local WITHDRAWAL_RELIEF = 0.35

local function ModData(player)
    local data = player and player:getModData()
    if data == nil then
        return nil
    end
    return data
end

function EM_Addiction_Get(player)
    local data = ModData(player)
    if data == nil then
        return 0
    end
    local value = data[MOD_KEY]
    if value == nil then
        return 0
    end
    return tonumber(value) or 0
end

function EM_Addiction_Set(player, value)
    local data = ModData(player)
    if data == nil then
        return
    end
    value = tonumber(value) or 0
    if value <= 0 then
        data[MOD_KEY] = nil
    else
        value = math.min(value, 1)
        data[MOD_KEY] = value
    end
end

function EM_Withdrawal_Get(player)
    local data = ModData(player)
    if data == nil then
        return 0
    end
    local value = data[WITHDRAWAL_KEY]
    if value == nil then
        return 0
    end
    return tonumber(value) or 0
end

function EM_Withdrawal_Set(player, value)
    local data = ModData(player)
    if data == nil then
        return
    end
    value = tonumber(value) or 0
    if value <= 0 then
        data[WITHDRAWAL_KEY] = nil
    else
        value = math.min(value, 1)
        data[WITHDRAWAL_KEY] = value
    end
end

function EM_Addiction_UseInjection(player)
    local data = ModData(player)
    if data == nil then
        return
    end
    -- Every shot pushes the baseline dependence up by half.
    EM_Addiction_Set(player, EM_Addiction_Get(player) + ADDICTION_PER_INJECTION)
    -- The shot relieves the withdrawal sickness.
    EM_Withdrawal_Set(player, EM_Withdrawal_Get(player) - WITHDRAWAL_RELIEF)
    if isClient() and player:isLocalPlayer() then
        player:transmitModData()
    end
end

function EM_Addiction_GetLevel(player)
    local value = EM_Addiction_Get(player)
    if value >= 0.7 then
        return 4
    elseif value >= 0.5 then
        return 3
    elseif value >= 0.3 then
        return 2
    elseif value >= 0.15 then
        return 1
    end
    return 0
end

-- Display tier for flavour text: 1 = mild (level 1), 2 = moderate
-- (levels 2-3), 3 = severe (level 4). 0 = no addiction.
function EM_Addiction_GetTier(player)
    local level = EM_Addiction_GetLevel(player)
    if level <= 0 then
        return 0
    elseif level == 1 then
        return 1
    elseif level >= 4 then
        return 3
    end
    return 2
end

function EM_Withdrawal_GetLevel(player)
    local value = EM_Withdrawal_Get(player)
    if value >= 0.7 then
        return 4
    elseif value >= 0.5 then
        return 3
    elseif value >= 0.3 then
        return 2
    elseif value >= 0.15 then
        return 1
    end
    return 0
end

function EM_Withdrawal_IsSevere(player)
    return EM_Withdrawal_Get(player) >= SEVERE_LEVEL
end

function EM_Withdrawal_GetSevereLevel()
    return SEVERE_LEVEL
end

local function minuteTick(player)
    if player == nil then
        return
    end
    local data = ModData(player)
    if data == nil or (data[MOD_KEY] == nil and data[WITHDRAWAL_KEY] == nil) then
        return
    end
    local addiction = EM_Addiction_Get(player)
    -- No baseline, no sickness: withdrawal ends immediately.
    if addiction <= 0 then
        EM_Withdrawal_Set(player, 0)
        return
    end
    local withdrawal = EM_Withdrawal_Get(player)
    -- Withdrawal chases the baseline: climbs fast while below it (the
    -- whole gap closes within 3 game hours), wears off slowly above it.
    local newWithdrawal = withdrawal
    if withdrawal < addiction then
        newWithdrawal = math.min(addiction, withdrawal + addiction * WITHDRAWAL_RISE)
    elseif withdrawal > addiction then
        newWithdrawal = math.max(addiction, withdrawal - WITHDRAWAL_FALL)
    end
    if newWithdrawal ~= withdrawal then
        EM_Withdrawal_Set(player, newWithdrawal)
    end
    -- Only severe withdrawal (cold turkey) grinds the baseline down.
    if newWithdrawal >= SEVERE_LEVEL then
        EM_Addiction_Set(player, addiction - DECAY_PER_MINUTE)
        if EM_Addiction_Get(player) <= 0 then
            EM_Withdrawal_Set(player, 0)
        end
    end
end

local function AddictionDecay()
    if isServer() then
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            minuteTick(players:get(i))
        end
    else
        local player = getSpecificPlayer(0)
        if player ~= nil and player:isLocalPlayer() then
            minuteTick(player)
        end
    end
end

Events.EveryOneMinute.Add(AddictionDecay)
