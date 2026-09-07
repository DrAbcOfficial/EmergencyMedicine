-- Methamphetamine: a central nervous system stimulant. One dose wipes
-- the fatigue stat instantly (fully awake) and starts a one-game-hour
-- ramp that pushes the amphetamine addiction to the cap (the ramp is
-- applied per minute by AmphetamineSimulation.lua). Once the hour is
-- over, the full amphetamine withdrawal cycle takes over (severe within
-- half a day). No wound, no bandage animation -- plain pill-taking.
local METH_HIGH_HOURS = 1.0

function TakeMethamphetamine(player)
    player:getStats():set(CharacterStat.FATIGUE, 0.0)
    EM_Meth_SetHigh(player, METH_HIGH_HOURS)
end
