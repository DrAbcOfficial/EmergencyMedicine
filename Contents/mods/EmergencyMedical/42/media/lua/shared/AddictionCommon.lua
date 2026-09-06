-- EmergencyMedical: Opioid addiction status (morphine dependence).
-- Modeled after vanilla thirst/hunger: a 0..1 status value that rises
-- while the drug use window is active (+0.02 per game hour, i.e. +2 per
-- game hour on the old 0..100 scale) and decays in withdrawal.
-- Displayed as a custom moodle-style icon in the vanilla moodle column
-- (see client/ISUI/OpioidAddictionIcon.lua) and on the health panel.
-- Mild levels (below 0.6) have no gameplay effect; severe addiction
-- presses the vanilla PANIC stat -- the official B42 "senses impaired"
-- mechanism (vision cone -36 deg at moodle level 4, heartbeat audio,
-- FMOD panic mix, detection penalties).
--
-- Multiplayer model (matches vanilla IsoPlayer:setUnwanted):
--  * value lives in player modData, changed on the player's own client
--    and sent up with transmitModData() so the server saves it;
--  * every-minute tick runs on both sides at the same rate;
--  * panic floor is maintained on the server (authoritative) and
--    mirrored on each client for local responsiveness.

local MOD_KEY = "EM_OpioidAddiction"
local WINDOW_KEY = "EM_OpioidWindow"
local SEVERE_LEVEL = 0.6
local WINDOW_MINUTES = 240
local GAIN_PER_MINUTE = 0.02 / 60
local DECAY_PER_MINUTE = 0.0005
local PANIC_FLOOR = 82

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

function EM_Addiction_UseInjection(player)
    local data = ModData(player)
    if data == nil then
        return
    end
    local window = tonumber(data[WINDOW_KEY]) or 0
    data[WINDOW_KEY] = math.max(window, WINDOW_MINUTES)
    if data[MOD_KEY] == nil then
        data[MOD_KEY] = 0
    end
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

function EM_Addiction_IsSevere(player)
    return EM_Addiction_Get(player) >= SEVERE_LEVEL
end

function EM_Addiction_GetSevereLevel()
    return SEVERE_LEVEL
end

local function applyPanicFloor(player)
    if player == nil or player:isDead() or player:isAsleep() then
        return
    end
    if not EM_Addiction_IsSevere(player) then
        return
    end
    local stats = player:getStats()
    local panic = stats:get(CharacterStat.PANIC)
    if panic < PANIC_FLOOR then
        stats:set(CharacterStat.PANIC, PANIC_FLOOR)
    end
end

local function AddictionTick()
    if isServer() then
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            applyPanicFloor(players:get(i))
        end
    else
        local player = getSpecificPlayer(0)
        if player ~= nil and player:isLocalPlayer() then
            applyPanicFloor(player)
        end
    end
end

local function minuteTick(player)
    if player == nil then
        return
    end
    local data = ModData(player)
    if data == nil or data[MOD_KEY] == nil then
        return
    end
    local window = tonumber(data[WINDOW_KEY]) or 0
    if window > 0 then
        data[WINDOW_KEY] = math.max(0, window - 1)
        EM_Addiction_Set(player, EM_Addiction_Get(player) + GAIN_PER_MINUTE)
    else
        local value = EM_Addiction_Get(player) - DECAY_PER_MINUTE
        if value < DECAY_PER_MINUTE then
            value = 0
        end
        EM_Addiction_Set(player, value)
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

Events.OnTick.Add(AddictionTick)
Events.EveryOneMinute.Add(AddictionDecay)
