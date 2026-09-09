-- EmergencyMedicine: the standard EveryOneMinute player iteration,
-- shared by every per-minute simulation (opioid, amphetamine, drug
-- side-effect statuses, wound upkeep) and by the hourly modData
-- refresh. The server iterates online players; the client iterates
-- every local player (split-screen), nil/dead guarded. Bind rules as
-- minuteTick(player) and register once:
--   EM_Sim.EveryOneMinute(minuteTick)

EM_Sim = {}

function EM_Sim.ForOnlinePlayers(visit)
	local players = getOnlinePlayers()
	for i = 0, players:size() - 1 do
		visit(players:get(i))
	end
end

function EM_Sim.ForLocalPlayers(visit)
	for i = 0, getNumActivePlayers() - 1 do
		local player = getSpecificPlayer(i)
		if player ~= nil and not player:isDead() and player:isLocalPlayer() then
			visit(player)
		end
	end
end

-- register minuteTick(player) on the EveryOneMinute event; the server
-- and client branches are handled here
function EM_Sim.EveryOneMinute(minuteTick)
	Events.EveryOneMinute.Add(function()
		if isServer() then
			EM_Sim.ForOnlinePlayers(minuteTick)
		else
			EM_Sim.ForLocalPlayers(minuteTick)
		end
	end)
end
