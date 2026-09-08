-- Drug side-effect status engine: decaying status records for the four
-- drug debuff statuses (DrugHeadache / DrugFever / ShoddySedation /
-- CoughSuppress). These are NOT body-wound states -- no body part is
-- involved; a status is a plain player-level record in one modData
-- table (EM_DrugFx[id] = { applied, progress, ...custom params }, in
-- hoursSurvived) with the standard dual-branch transmitModData on
-- change. In MP the effects run on the server (TakeDrug), so the
-- authoritative copy is the saved one and the broadcast carries it to
-- clients for the status icons.
--
-- DOSES STACK: every dose decays the carried progress up to now, then
-- adds the "DrugStatusDoseGain" sandbox gain (default 0.2 = 20% of the
-- full status), capped at 1.0.
--
-- DECAY IS COMPUTED, NOT WRITTEN: the effective progress is always
-- stored progress minus (hours since the last dose) x
-- "DrugStatusDecayPerHour" -- every peer derives the same value from
-- the synced record and its own clock, so no per-tick writes and no
-- transmit spam. The status ends (and is lazily pruned on read) once
-- the effective progress reaches zero.
--
-- The effective progress quartile IS the displayed level (1-4,
-- matching the user-written descriptions); the simulation scales the
-- debuff floors by effective progress x "DrugStatusDebuffRate", so the
-- status icon and the debuff always agree.
--
-- API:
--   EM_DrugFx_Add(player, id, params)  -- add a dose to a status;
--       params: optional plain table copied onto the record
--   EM_DrugFx_Get(player, id)          -- record or nil (prunes decayed out)
--   EM_DrugFx_Progress(record, now)    -- effective progress 0..1
--   EM_DrugFx_GetLevel(player, id)     -- 0 = none, else 1..4
--   EM_DrugFx_Remove(player, id)       -- priority overrides (morphine,
--                                      -- amphetamine supplant weaker statuses)
--   EM_DrugFx_DATA_KEY                 -- raw-read key for the tick

local DATA_KEY = "EM_DrugFx"
EM_DrugFx_DATA_KEY = DATA_KEY

local function transmit(player)
    -- same dual branch as every modData writer (MP fact 4)
    EM_Dependence_Transmit(player)
end

-- effective progress of a record at time `now`: stored value minus the
-- natural decay since the last dose (never below zero)
function EM_DrugFx_Progress(record, now)
    local decayed = record.progress - (now - record.applied) * EM_Sandbox_Get("DrugStatusDecayPerHour")
    if decayed < 0.0 then
        return 0.0
    end
    return decayed
end

function EM_DrugFx_Add(player, id, params)
    local modData = player and player:getModData()
    if modData == nil then
        return nil
    end
    local statuses = modData[DATA_KEY]
    if statuses == nil then
        statuses = {}
        modData[DATA_KEY] = statuses
    end
    local now = player:getHoursSurvived()
    -- decay whatever the previous doses left, then stack this dose on top
    local previous = statuses[id]
    local carried = previous ~= nil and EM_DrugFx_Progress(previous, now) or 0.0
    -- sandbox read at call time (never cached at load)
    local record = {
        applied = now,
        progress = math.min(EM_CONST.STAT_SCALE_MAX, carried + EM_Sandbox_Get("DrugStatusDoseGain")),
    }
    if params ~= nil then
        for k, v in pairs(params) do
            record[k] = v
        end
    end
    statuses[id] = record
    transmit(player)
    return record
end

function EM_DrugFx_Get(player, id)
    local modData = player and player:getModData()
    local statuses = modData ~= nil and modData[DATA_KEY] or nil
    local record = statuses ~= nil and statuses[id] or nil
    if record ~= nil and EM_DrugFx_Progress(record, player:getHoursSurvived()) <= 0.0 then
        -- decayed out: lazily prune (every peer does this on its own
        -- clock, no transmit needed -- same philosophy as the wound
        -- manager's lazy expiry)
        statuses[id] = nil
        record = nil
    end
    return record
end

-- level from the effective progress quartiles: 0-25% mild -> 75-100%
-- extreme (with the default 20% gain: dose 1 = level 1 ... dose 4+ =
-- level 4)
function EM_DrugFx_GetLevel(player, id)
    local record = EM_DrugFx_Get(player, id)
    if record == nil then
        return 0
    end
    local progress = EM_DrugFx_Progress(record, player:getHoursSurvived())
    if progress <= 0.25 then
        return 1
    elseif progress <= 0.5 then
        return 2
    elseif progress <= 0.75 then
        return 3
    end
    return 4
end

-- stronger drugs supplant weaker statuses (the "priority" rule):
-- morphine wipes the shoddy sedative and the drug headache, amphetamine
-- wipes the antitussive drowsiness -- uppers cancel downers
function EM_DrugFx_Remove(player, id)
    local modData = player and player:getModData()
    local statuses = modData ~= nil and modData[DATA_KEY] or nil
    if statuses ~= nil and statuses[id] ~= nil then
        statuses[id] = nil
        transmit(player)
    end
end
