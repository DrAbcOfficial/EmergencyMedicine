-- Drug side-effect status engine: decaying status records for the four
-- drug debuff statuses (DrugHeadache / DrugFever / ShoddySedation /
-- CoughSuppress). A thin adapter over the generic timed-record core
-- (EM_TimedStatus.lua): player-level family (no scope), records are
-- { applied, progress, ...custom params }, transmitted on change.
-- These are NOT body-wound states -- no body part is involved. In MP
-- the effects run on the server (the pill action's complete is
-- server-executed, see DrugPillHook), so the authoritative copy
-- is the saved one and the broadcast carries it to clients for the
-- status icons.
--
-- DOSES STACK: every dose decays the carried progress up to now, then
-- adds the "DrugStatusDoseGain" sandbox gain (default 0.2 = 20% of the
-- full status), capped at 1.0. Decay is COMPUTED on read via the core
-- (DrugStatusDecayPerHour sandbox rate): every peer derives the same
-- effective progress from its own clock -- no per-tick writes, no
-- transmit spam. The status ends (and is lazily pruned on read) once
-- the effective progress reaches zero.
--
-- The effective progress quartile IS the displayed level (1-4,
-- matching the user-written descriptions); the simulation scales the
-- debuff floors by effective progress x "DrugStatusDebuffRate", so the
-- status icon and the debuff always agree.
--
-- API:
--   EM_DrugFx_Add(player, id, params, gain) -- add a dose to a status;
--       params: optional plain table copied onto the record
--       gain: optional per-dose progress override (nil = the
--       DrugStatusDoseGain sandbox value)
--   EM_DrugFx_Get(player, id)          -- record or nil (prunes decayed out)
--   EM_DrugFx_Progress(record, now)    -- effective progress 0..1
--   EM_DrugFx_GetLevel(player, id)     -- 0 = none, else 1..4
--   EM_DrugFx_Remove(player, id)       -- priority overrides (morphine,
--                                      -- amphetamine supplant weaker statuses)

local DATA_KEY = "EM_DrugFx"
EM_DrugFx_DATA_KEY = DATA_KEY

-- effective progress of a record at time `now` (sandbox rate read at
-- call time, never cached at load)
function EM_DrugFx_Progress(record, now)
	return EM_TimedStatus.EffectiveProgress(record, now, EM_Sandbox_Get("DrugStatusDecayPerHour"))
end

function EM_DrugFx_Add(player, id, params, gain)
	local statuses = EM_TimedStatus.Table(player, DATA_KEY, nil)
	if statuses == nil then
		return nil
	end
	local now = player:getHoursSurvived()
	-- decay whatever the previous doses left, then stack this dose on top
	local previous = statuses[id]
	local carried = previous ~= nil and EM_DrugFx_Progress(previous, now) or 0.0
	-- sandbox read at call time (never cached at load); an explicit gain
	-- overrides it (continuous accumulators like the amphetamine
	-- withdrawal pass their own per-hour rate)
	if gain == nil then
		gain = EM_Sandbox_Get("DrugStatusDoseGain")
	end
	local record = {
		applied = now,
		progress = math.min(EM_CONST.STAT_SCALE_MAX, carried + gain),
	}
	if params ~= nil then
		for k, v in pairs(params) do
			record[k] = v
		end
	end
	EM_TimedStatus.Set(player, DATA_KEY, nil, id, record, true)
	return record
end

function EM_DrugFx_Get(player, id)
	local record = EM_TimedStatus.Get(player, DATA_KEY, nil, id)
	if record ~= nil and EM_DrugFx_Progress(record, player:getHoursSurvived()) <= 0.0 then
		-- decayed out: lazily prune (every peer does this on its own
		-- clock, no transmit needed -- same philosophy as the wound
		-- manager's lazy expiry)
		EM_TimedStatus.Remove(player, DATA_KEY, nil, id, false)
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
	return EM_TimedStatus.ProgressQuartile(EM_DrugFx_Progress(record, player:getHoursSurvived()))
end

-- stronger drugs supplant weaker statuses (the "priority" rule):
-- morphine wipes the shoddy sedative and the drug headache, amphetamine
-- wipes the antitussive drowsiness -- uppers cancel downers
function EM_DrugFx_Remove(player, id)
	EM_TimedStatus.Remove(player, DATA_KEY, nil, id, true)
end
