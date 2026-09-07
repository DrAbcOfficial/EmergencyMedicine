-- EmergencyMedical: per-minute upkeep for the body-part wound states
-- (values live in BodyWoundManager.lua). Same cadence/branching as the
-- opioid simulation: the server iterates online players, the client
-- handles the local player.
--
-- Rules, every game minute:
-- * a part carrying the "CrudeStitched" state (glue/stapler field
--   repair) hurts +20% more from its wounds: additionalPain floors at
--   the wound-generated pain x 0.2 while the state lasts
-- * a part carrying the "EmergencyFixed" state (improvised splint on a
--   fracture) freezes the fracture: fractureTime is restored to the
--   value frozen at application every minute, so it can never heal
--   naturally while the fixation lasts; on top, every wound on the
--   part hurts +45% (pain floor x "EmergencyFixPainBoost"). The two
--   pain boosts stack by taking the max, not the sum. The state's
--   expiry is detected HERE on the raw modData -- the manager's lazy
--   cleanup silently scrubs an expired state on any read, so this raw
--   read must come first: once the expire time passes, the fracture
--   the fixation kept alive heals together with it.
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

-- the improvised fixation carries its custom params on the state table
-- itself (fractureTime = severity frozen at application, expire = end of
-- the fixation). Read on the RAW modData: a manager read (EM_Wound_Has /
-- GetState) lazily deletes an expired state before the tick could act on
-- it, and the expiry must heal the fracture the state kept alive.
local function emergencyFixRawState(player, part)
    local wounds = player:getModData()[EM_Wound_DATA_KEY]
    if wounds == nil then
        return nil
    end
    local states = wounds[EM_Wound_PartKey(part)]
    if states == nil then
        return nil
    end
    return states["EmergencyFixed"]
end

local function minuteTick(player)
    if player == nil then
        return
    end
    tickFentanylPatch(player)
    local parts = player:getBodyDamage():getBodyParts()
    local painFloor = EM_Sandbox_Get("ScabPainFloor")
    local now = player:getHoursSurvived()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        local woundPain = part:getPain() - part:getAdditionalPain(true)
        local boostFloor = 0.0
        if EM_Wound_Has(player, part, "CrudeStitched") then
            -- crude stitching: every wound on the part hurts +20% while
            -- the state lasts (floor = the wound-generated pain x the
            -- "CrudeStitchPainBoost" sandbox multiplier; 0 disables)
            local floor = woundPain * EM_Sandbox_Get("CrudeStitchPainBoost")
            if floor > boostFloor then
                boostFloor = floor
            end
        end
        local fixState = emergencyFixRawState(player, part)
        if fixState ~= nil then
            if now >= fixState.expire then
                -- the fixation ran its full course: the fracture it kept
                -- alive heals together with the state (removal transmits)
                EMTreatment_EmergencyFixExpired(player, part)
            else
                -- improvised fixation: the fracture NEVER heals while the
                -- state lasts -- restore the severity frozen at
                -- application (the Java decay between ticks stays
                -- microscopic). The frozen value is a custom param on
                -- the state, written by the applying treatment.
                local frozen = fixState.fractureTime or 0.0
                if frozen > 0.0 and part:getFractureTime() > 0.0 and part:getFractureTime() < frozen then
                    part:setFractureTime(frozen)
                end
                -- ... and every wound hurts +45% ("EmergencyFixPainBoost")
                local floor = woundPain * EM_Sandbox_Get("EmergencyFixPainBoost")
                if floor > boostFloor then
                    boostFloor = floor
                end
            end
        end
        if boostFloor > 0.0 and part:getAdditionalPain() < boostFloor then
            part:setAdditionalPain(boostFloor)
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
