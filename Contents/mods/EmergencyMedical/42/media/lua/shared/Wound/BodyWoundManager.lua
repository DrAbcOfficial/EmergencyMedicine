-- EmergencyMedical: custom per-body-part wound state manager.
-- Generic registry for limb-abnormality states: a feature registers a
-- wound type once (EM_Wound_Register) and attaches timed states to body
-- parts. Values live in player modData
-- (EM_BodyWounds[partKey][id] = { applied, expire } in hoursSurvived),
-- so they persist in the save and sync to MP clients via
-- transmitModData (same pattern as the opioid values).
--
-- partKey is the BodyPartType.ToString() string ("Hand_L", ...); the
-- EM_Wound_* functions accept either that string or a BodyPart object.
-- Expiry is lazy: every read drops expired entries first, so no tick
-- event is needed and every peer derives the same state from the clock.
--
-- To add a new limb state: register a type in WoundTypes.lua (or any
-- shared file), then EM_Wound_Add / EM_Wound_Has / EM_Wound_GetLevel
-- from wherever the feature applies.

local DATA_KEY = "EM_BodyWounds"
local DEFAULT_DURATION_DAYS = 90

-- exported for the one consumer that must read a state BEFORE the lazy
-- expiry below scrubs it (BodyWoundSimulation's fixation expiry check);
-- read-only access -- mutate states only through the API functions
EM_Wound_DATA_KEY = DATA_KEY

local types = {}

local function partKeyOf(part)
    if type(part) == "string" then
        return part
    end
    return BodyPartType.ToString(part:getType())
end

-- Kahlua has no next(); emptiness checks must iterate with pairs
local function isEmpty(t)
    for _ in pairs(t) do
        return false
    end
    return true
end

local function dataOf(player, create)
    local modData = player and player:getModData()
    if modData == nil then
        return nil
    end
    local data = modData[DATA_KEY]
    if data == nil then
        if not create then
            return nil
        end
        data = {}
        modData[DATA_KEY] = data
    end
    local t = player:getHoursSurvived()
    for partKey, states in pairs(data) do
        for id, state in pairs(states) do
            if t >= state.expire then
                states[id] = nil
            end
        end
        if isEmpty(states) then
            data[partKey] = nil
        end
    end
    return data
end

local function transmit(player)
    -- MP: a server (dedicated, or the hidden coop-host server) broadcasts
    -- its copy to every relevant client; a client may only push its OWN
    -- player's table up -- the server applies and relays it. Changes made
    -- on a client for a REMOTE player (doctor treatments) must therefore
    -- run on the server instead: client/Wound actions route through a
    -- client command (server/EmergencyMedical_ClientCommands.lua).
    EM_Dependence_Transmit(player)
end

-- def = {
--   durationDays = number | function  -- default 90; a function is
--                                     -- resolved when the state is added
--                                     -- (sandbox-configurable durations)
--   panelLabelKey = "IGUI_..."       -- health panel wound line label
--                                    -- (rendered by client/Wound/BodyPartPanel.lua)
-- }
--
-- Feature-specific data travels as CUSTOM PARAMS on the state table
-- itself (plain fields, persisted and synced with the modData): write
-- them right after EM_Wound_Add returns. The add-time transmit won't
-- carry them yet, so only code running on the side that applied the
-- state (the server, in MP) may rely on them immediately -- remote
-- copies pick them up with the next transmit.
function EM_Wound_Register(id, def)
    def = def or {}
    def.id = id
    def.durationDays = def.durationDays or DEFAULT_DURATION_DAYS
    types[id] = def
end

function EM_Wound_GetType(id)
    return types[id]
end

-- read-only map id -> def; do not mutate
function EM_Wound_GetRegisteredTypes()
    return types
end

function EM_Wound_Add(player, part, id, durationDays)
    local def = types[id]
    if def == nil then
        return nil
    end
    local data = dataOf(player, true)
    if data == nil then
        return nil
    end
    local partKey = partKeyOf(part)
    local states = data[partKey]
    if states == nil then
        states = {}
        data[partKey] = states
    end
    local t = player:getHoursSurvived()
    local days = durationDays ~= nil and durationDays or def.durationDays
    if type(days) == "function" then
        days = days()
    end
    if days == nil then
        days = DEFAULT_DURATION_DAYS
    end
    local state = { applied = t, expire = t + days * EM_CONST.HOURS_PER_GAME_DAY }
    states[id] = state
    transmit(player)
    return state
end

function EM_Wound_Remove(player, part, id)
    local data = dataOf(player, false)
    if data == nil then
        return
    end
    local partKey = partKeyOf(part)
    local states = data[partKey]
    if states ~= nil and states[id] ~= nil then
        states[id] = nil
        if isEmpty(states) then
            data[partKey] = nil
        end
        transmit(player)
    end
end

function EM_Wound_RemoveAllOf(player, id)
    local data = dataOf(player, false)
    if data == nil then
        return
    end
    local removed = false
    for partKey, states in pairs(data) do
        if states[id] ~= nil then
            states[id] = nil
            if isEmpty(states) then
                data[partKey] = nil
            end
            removed = true
        end
    end
    if removed then
        transmit(player)
    end
end

-- state table or nil (nil once expired)
function EM_Wound_GetState(player, part, id)
    local data = dataOf(player, false)
    if data == nil then
        return nil
    end
    local states = data[partKeyOf(part)]
    if states == nil then
        return nil
    end
    return states[id]
end

function EM_Wound_Has(player, part, id)
    return EM_Wound_GetState(player, part, id) ~= nil
end

-- 0 = none; levels derive purely from the state's own data: age
-- quartiles 4 (fresh) -> 1 (oldest) over the state's lifetime
-- (EM_TimedStatus.AgeLevel)
function EM_Wound_GetLevel(player, part, id)
    local state = EM_Wound_GetState(player, part, id)
    if state == nil then
        return 0
    end
    return EM_TimedStatus.AgeLevel(state, player:getHoursSurvived())
end

-- all part keys currently carrying the state (fresh table per call)
function EM_Wound_GetPartsOf(player, id)
    local result = {}
    local data = dataOf(player, false)
    if data ~= nil then
        for partKey, states in pairs(data) do
            if states[id] ~= nil then
                result[#result + 1] = partKey
            end
        end
    end
    return result
end

-- every state id attached to one part
function EM_Wound_GetForPart(player, part)
    local result = {}
    local data = dataOf(player, false)
    if data ~= nil then
        local states = data[partKeyOf(part)]
        if states ~= nil then
            for id in pairs(states) do
                result[#result + 1] = id
            end
        end
    end
    return result
end

function EM_Wound_PartKey(part)
    return partKeyOf(part)
end
