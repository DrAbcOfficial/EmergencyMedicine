-- EmergencyMedical: the generic timed-record core behind every player
-- status/value family in the mod (the wound manager's part states, the
-- drug side-effect statuses, the methamphetamine high). It owns the
-- storage shape, the standard dual-branch transmit, the two level
-- derivations and the computed-decay formula -- new status systems bind
-- a modData key here instead of copying the plumbing. Thin adapters:
-- BodyWoundManager.lua, DrugEffectStatus.lua, AmphetamineSimulation.lua.
--
-- Storage shape: modData[dataKey][scope][id] = record -- scope keys a
-- sub-family (the wound manager scopes by body part; player-level
-- systems pass nil). Records are plain tables; two shapes are in use:
--   { applied, expire, ... }   -- fixed lifetime; level = age quartile
--   { applied, progress, ... } -- decaying 0..1 value; level = progress quartile
-- The mod is unreleased: the layout is free to change, no save
-- migration is maintained.
--
-- All helpers are nil-safe; transmit is always the standard
-- EM_Dependence_Transmit dual branch (MP fact 4), opt-in per call.

EM_TimedStatus = {}

-- the modData record family for one system: dataKey[scope][id] =
-- record, created on demand (scope = nil for player-level families)
function EM_TimedStatus.Table(player, dataKey, scope)
	local modData = player and player:getModData()
	if modData == nil then
		return nil
	end
	local family = modData[dataKey]
	if family == nil then
		family = {}
		modData[dataKey] = family
	end
	if scope ~= nil then
		local scoped = family[scope]
		if scoped == nil then
			scoped = {}
			family[scope] = scoped
		end
		return scoped
	end
	return family
end

function EM_TimedStatus.Get(player, dataKey, scope, id)
	local modData = player and player:getModData()
	local family = modData ~= nil and modData[dataKey] or nil
	local scoped = family ~= nil and scope ~= nil and family[scope] or family
	return scoped ~= nil and scoped[id] or nil
end

function EM_TimedStatus.Set(player, dataKey, scope, id, record, transmit)
	local scoped = EM_TimedStatus.Table(player, dataKey, scope)
	if scoped == nil then
		return
	end
	scoped[id] = record
	if transmit then
		EM_Dependence_Transmit(player)
	end
end

function EM_TimedStatus.Remove(player, dataKey, scope, id, transmit)
	local modData = player and player:getModData()
	local family = modData ~= nil and modData[dataKey] or nil
	local scoped = family ~= nil and scope ~= nil and family[scope] or family
	if scoped ~= nil and scoped[id] ~= nil then
		scoped[id] = nil
		if transmit then
			EM_Dependence_Transmit(player)
		end
	end
end

-- a fixed-lifetime record: {applied, expire} in hoursSurvived
function EM_TimedStatus.TimedRecord(now, hours)
	return { applied = now, expire = now + hours * EM_CONST.HOURS_PER_GAME_DAY }
end

-- level derivations -------------------------------------------------

-- level off a {applied, expire} record: the freshest quarter of the
-- lifetime is level 4, the oldest is level 1 (zero/negative duration
-- reads as level 1)
function EM_TimedStatus.AgeLevel(record, now)
	local duration = record.expire - record.applied
	if duration <= 0 then
		return 1
	end
	return EM_TimedStatus.ElapsedQuartile((now - record.applied) / duration)
end

-- elapsed-life FRACTION (0..1) -> level 4 (<= 0.25) .. 1 (> 0.75)
function EM_TimedStatus.ElapsedQuartile(frac)
	if frac <= 0.25 then
		return 4
	elseif frac <= 0.5 then
		return 3
	elseif frac <= 0.75 then
		return 2
	end
	return 1
end

-- 0..1 value -> level 1 (<= 0.25) .. 4 (> 0.75)
function EM_TimedStatus.ProgressQuartile(progress)
	if progress <= 0.25 then
		return 1
	elseif progress <= 0.5 then
		return 2
	elseif progress <= 0.75 then
		return 3
	end
	return 4
end

-- computed decay ----------------------------------------------------

-- effective 0..1 value of a {progress, applied} record at `now`:
-- stored progress minus the hours since it was set times decayPerHour
-- -- computed on read, never written back, so every peer derives the
-- same value from its own clock (no per-tick writes, no transmit spam)
function EM_TimedStatus.EffectiveProgress(record, now, decayPerHour)
	local decayed = record.progress - (now - record.applied) * decayPerHour
	if decayed < 0.0 then
		return 0.0
	end
	return decayed
end
