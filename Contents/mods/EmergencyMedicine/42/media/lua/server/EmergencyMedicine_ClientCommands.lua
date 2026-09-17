-- EmergencyMedicine: server side of the client commands that are NOT
-- timed actions. The body-part wound treatments are NOT here: B42
-- executes their Lua timed actions on this very server (the net timed
-- action rebuilds the shared action class and runs complete() here --
-- see shared/TimedActions/EMBodyPartAction.lua), so they apply through
-- the shared ops directly. Same for the pill effects: the
-- ISTakePillAction hook runs here and calls EMDrug_ApplyEffect directly.
-- What remains is the auto-injector watch, whose trigger lives in
-- OnPlayerUpdate on the owning client.
if isClient() then
    return
end

local function onClientCommand(module, command, player, args)
    if module ~= "EmergencyMedicine" or player == nil or args == nil then
        return
    end
    if command == "AutoInject" then
        -- the auto-injector watch trigger: the client detected the health
        -- gate; EMAutoInjector_TryInject re-validates everything server-side
        -- (alive, health below threshold, watch worn, drug whitelisted,
        -- physical ampoule present) before applying and consuming. On a
        -- real shot the owning client gets the AutoInjectSound echo so it
        -- plays the injection sound locally (server-side playSound is a
        -- no-op dummy emitter, and the sound must stay user-only anyway)
        if type(args.drug) == "string" then
            if EMAutoInjector_TryInject(player, args.drug) then
                sendServerCommand(player, "EmergencyMedicine", "AutoInjectSound", {})
            end
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)
