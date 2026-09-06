-- EmergencyMedical: per-minute upkeep for the body-part wound states
-- (values live in BodyWoundManager.lua). Same cadence/branching as the
-- opioid simulation: the server iterates online players, the client
-- handles the local player.
--
-- Rules, every game minute:
-- * a part carrying the "CrudeStitched" state (glue/stapler field
--   repair) hurts +20% more from its wounds: additionalPain floors at
--   the wound-generated pain x 0.2 while the state lasts
-- * a part carrying the "Cauterized" scab keeps a fixed pain floor:
--   additionalPain never drops below the "ScabPainFloor" sandbox value
--   while the scab lasts. Pain would otherwise decay away within a day;
--   the scab aches for as long as it exists (painkillers buy relief
--   until the next tick tops the part back up). 0 disables the floor.
-- * the "FentanylPatch" state (sufentanil, right upper arm) feeds a
--   painkiller dose, relieves withdrawal, grows addiction and pins
--   pain/panic/unhappiness/boredom at zero -- rates via sandbox options.

local function tickFentanylPatch(player)
    if not EM_Wound_Has(player, "UpperArm_R", "FentanylPatch") then
        return
    end
    local painkiller = EM_Sandbox_Get("SufentanilPainkillerPerMinute")
    if painkiller > 0 then
        -- PainMeds ACCUMULATES painDelta (and restarts its 5400s timer);
        -- cap the stored dose at 1.0 without stopping the refresh
        local painDelta = player:getPainDelta()
        player:PainMeds(math.min(painkiller, math.max(0.0, 1.0 - painDelta)))
    end
    local relief = EM_Sandbox_Get("SufentanilWithdrawalRelief")
    if relief > 0 then
        EM_Withdrawal_Set(player, EM_Withdrawal_Get(player) - relief)
    end
    local addictionGain = EM_Sandbox_Get("SufentanilAddictionPerMinute")
    if addictionGain > 0 then
        EM_Addiction_Set(player, EM_Addiction_Get(player) + addictionGain)
    end
    if EM_Sandbox_Get("SufentanilClearMind") then
        local stats = player:getStats()
        stats:set(CharacterStat.PAIN, 0.0)
        stats:set(CharacterStat.PANIC, 0.0)
        stats:set(CharacterStat.UNHAPPINESS, 0.0)
        stats:set(CharacterStat.BOREDOM, 0.0)
    end
end

local function minuteTick(player)
    if player == nil then
        return
    end
    tickFentanylPatch(player)
    local parts = player:getBodyDamage():getBodyParts()
    local painFloor = EM_Sandbox_Get("ScabPainFloor")
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if EM_Wound_Has(player, part, "CrudeStitched") then
            -- crude stitching: every wound on the part hurts +20% while
            -- the state lasts (floor = the wound-generated pain x the
            -- "CrudeStitchPainBoost" sandbox multiplier; 0 disables)
            local woundPain = part:getPain() - part:getAdditionalPain(true)
            local floor = woundPain * EM_Sandbox_Get("CrudeStitchPainBoost")
            if floor > 0 and part:getAdditionalPain() < floor then
                part:setAdditionalPain(floor)
            end
        end
        if painFloor ~= nil and painFloor > 0
            and EM_Wound_Has(player, part, "Cauterized") and part:getAdditionalPain() < painFloor then
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
        -- every local player (split-screen), not just index 0
        for i = 0, getNumActivePlayers() - 1 do
            local player = getSpecificPlayer(i)
            if player ~= nil and not player:isDead() and player:isLocalPlayer() then
                minuteTick(player)
            end
        end
    end
end

Events.EveryOneMinute.Add(simulate)
