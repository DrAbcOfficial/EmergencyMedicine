-- EmergencyMedical: per-minute upkeep for the body-part wound states
-- (values live in BodyWoundManager.lua). Same cadence/branching as the
-- opioid simulation: the server iterates online players, the client
-- handles the local player.
--
-- Rules, every game minute:
-- * a part carrying the "Cauterized" scab keeps a fixed pain floor:
--   additionalPain never drops below the "ScabPainFloor" sandbox value
--   while the scab lasts. Pain would otherwise decay away within a day;
--   the scab aches for as long as it exists (painkillers buy relief
--   until the next tick tops the part back up). 0 disables the floor.

local function minuteTick(player)
    if player == nil then
        return
    end
    local painFloor = EM_Sandbox_Get("ScabPainFloor")
    if painFloor == nil or painFloor <= 0 then
        return
    end
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if EM_Wound_Has(player, part, "Cauterized") and part:getAdditionalPain() < painFloor then
            part:setAdditionalPain(painFloor)
        end
    end
end

local function simulate()
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

Events.EveryOneMinute.Add(simulate)
