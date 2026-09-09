-- EmergencyMedicine: hourly whole-modData refresh. The event-driven
-- transmits (injection, wound add/remove, meth high) keep values roughly
-- current; this low-frequency pass additionally bounds the server-copy
-- drift for saving and lets late joiners see current wound states
-- without waiting for the next treatment. transmitModData sends the
-- player's WHOLE modData table, so one pass covers every
-- EmergencyMedicine value at once; the server relays it to nearby
-- clients, so other players' views stay fresh too.
local SYNC_INTERVAL_MINUTES = 60
local minutes = 0

local function onMinute()
    if isServer() then
        return
    end
    minutes = minutes + 1
    if minutes < SYNC_INTERVAL_MINUTES then
        return
    end
    minutes = 0
    EM_Sim.ForLocalPlayers(function(player)
        player:transmitModData()
    end)
end

Events.EveryOneMinute.Add(onMinute)
