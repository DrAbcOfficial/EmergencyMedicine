-- Methamphetamine: a central nervous system stimulant. One dose wipes
-- the fatigue stat instantly (fully awake), tops the endurance back up,
-- and starts a one-game-hour ramp that pushes the amphetamine addiction
-- to the cap (the ramp is applied per minute by
-- AmphetamineSimulation.lua). Once the hour is over, the full
-- amphetamine withdrawal cycle takes over (severe within half a day).
-- Priority: the stimulant supplants the antitussive drowsiness --
-- uppers cancel downers. No wound, no bandage animation -- plain
-- pill-taking.
local METH_HIGH_HOURS = 1.0

function TakeMethamphetamine(player)
    local stats = player:getStats()
    stats:set(CharacterStat.FATIGUE, 0.0)
    stats:set(CharacterStat.ENDURANCE, EM_CONST.STAT_SCALE_MAX)
    EM_DrugFx_Remove(player, "CoughSuppress")
    EM_Meth_SetHigh(player, METH_HIGH_HOURS)
end
