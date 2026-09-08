-- EmergencyMedical: per-minute upkeep for the body-part wound states
-- (values live in BodyWoundManager.lua). Same cadence/branching as the
-- opioid simulation: the server iterates online players, the client
-- handles the local player.
--
-- All states are maintained PURE-DATA here: the tick reads the part's
-- wound states straight off the raw modData (EM_Wound_DATA_KEY) with an
-- expire guard per entry -- no manager reads, no hooks. The raw read
-- also sees an EXPIRED state before the manager's lazy cleanup would
-- scrub it, which is what lets the "EmergencyFixed" fixation heal the
-- fracture it hides (the one state that needs an expiry treatment; the
-- others just fade).
--
-- Rules, every game minute:
-- * "CrudeStitched" (glue/stapler field repair): every wound on the
--   part hurts +20% -- additionalPain floors at the wound-generated
--   pain x the "CrudeStitchPainBoost" sandbox multiplier. The part
--   taking a NEW deep wound pops the state: the stored deep wound
--   tears back open, stacked onto the new one.
-- * "EmergencyFixed" (improvised splint): the fracture is REMOVED from
--   the body while the state lasts (fractureTime zeroed at
--   application, true severity riding the state as a custom param), so
--   there is nothing to maintain -- but every wound on the part hurts
--   +45% (pain floor x "EmergencyFixPainBoost"), and once the expire
--   time passes the hidden fracture heals together with the state. The
--   two pain boosts stack by taking the max, not the sum. A fresh
--   fracture while fixated pops the state: the hidden severity stacks
--   onto the new fracture.
-- * "Cauterized" (scab): additionalPain never drops below the
--   "ScabPainFloor" sandbox value while the scab lasts. Pain would
--   otherwise decay away within a day; the scab aches for as long as
--   it exists (painkillers buy relief until the next tick tops the
--   part back up). 0 disables the floor. The part taking a new
--   scratch/cut/bite pops the scab: the burned-out wounds return
--   (stacked onto a same-type new wound).
-- * "FentanylPatch" (sufentanil, right upper arm): feeds a painkiller
--   dose, relieves withdrawal, grows addiction and pins
--   pain/panic/unhappiness/boredom at zero -- rates via sandbox
--   options.
--
-- Drug side-effect statuses (DrugHeadache / DrugFever / ShoddySedation /
-- CoughSuppress) are NOT wound states and are NOT maintained here:
-- they are player-level EM_DrugFx records with their own simulation
-- (shared/Status/DrugEffect/DrugEffectSimulation.lua) and their own
-- status icons (client/ISUI/StatusDrugEffects.lua).

local PATCH_PART_KEY = "UpperArm_R"

-- the stored painkiller dose caps at full strength (vanilla PainMeds
-- potency 1.0)
local PAINKILLER_CAP = 1.0

-- the sufentanil patch upkeep; the loop supplies an unexpired patch
-- state, rates via sandbox options
local function tickFentanylPatch(player)
    local painkiller = EM_Sandbox_Get("SufentanilPainkillerPerMinute")
    if painkiller > 0 then
        -- PainMeds ACCUMULATES painDelta (and restarts its 5400s timer);
        -- cap the stored dose at 1.0 without stopping the refresh
        local painDelta = player:getPainDelta()
        player:PainMeds(math.min(painkiller, math.max(0.0, PAINKILLER_CAP - painDelta)))
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
    local parts = player:getBodyDamage():getBodyParts()
    local painFloor = EM_Sandbox_Get("ScabPainFloor")
    local now = player:getHoursSurvived()
    -- one raw modData read per player; every entry is guarded by its
    -- own expire time below, so an expired-but-not-yet-cleaned state
    -- can't trip any effect
    local wounds = player:getModData()[EM_Wound_DATA_KEY]
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        local states = wounds ~= nil and wounds[EM_Wound_PartKey(part)] or nil
        if states ~= nil then
            local woundPain = part:getPain() - part:getAdditionalPain(true)
            local boostFloor = 0.0
            local stitched = states["CrudeStitched"]
            if stitched ~= nil and now < stitched.expire then
                if part:getDeepWoundTime() > 0.0 then
                    -- the part was wounded again: the stored deep wound
                    -- tears back open, stacked onto the new one
                    EMTreatment_PopCrudeStitch(player, part, stitched)
                else
                    -- crude stitching: every wound on the part hurts +20%
                    -- while the state lasts (floor = the wound-generated
                    -- pain x the "CrudeStitchPainBoost" sandbox multiplier;
                    -- 0 disables)
                    local floor = woundPain * EM_Sandbox_Get("CrudeStitchPainBoost")
                    if floor > boostFloor then
                        boostFloor = floor
                    end
                end
            end
            local fix = states["EmergencyFixed"]
            if fix ~= nil then
                if now >= fix.expire then
                    -- the fixation ran its full course: the hidden
                    -- fracture heals together with the state (removal
                    -- transmits)
                    EMTreatment_EmergencyFixExpired(player, part)
                elseif part:getFractureTime() > 0.0 then
                    -- a fresh fracture while fixated: it absorbs the
                    -- hidden severity and the fixation breaks
                    EMTreatment_PopEmergencyFix(player, part, fix)
                else
                    -- improvised fixation: every wound on the part hurts
                    -- +45% ("EmergencyFixPainBoost"); the fracture itself
                    -- is removed from the body for the duration, nothing
                    -- to maintain there
                    local floor = woundPain * EM_Sandbox_Get("EmergencyFixPainBoost")
                    if floor > boostFloor then
                        boostFloor = floor
                    end
                end
            end
            if boostFloor > 0.0 and part:getAdditionalPain() < boostFloor then
                part:setAdditionalPain(boostFloor)
            end
            local scab = states["Cauterized"]
            if scab ~= nil and now < scab.expire then
                if part:getScratchTime() > 0.0 or part:getCutTime() > 0.0 or part:getBiteTime() > 0.0 then
                    -- the part was wounded again: the burned-out wounds
                    -- return (stacked onto a same-type new wound), the
                    -- scab pops
                    EMTreatment_PopCauterized(player, part, scab)
                elseif painFloor ~= nil and painFloor > 0
                    and part:getAdditionalPain() < painFloor then
                    part:setAdditionalPain(painFloor)
                end
            end
            if EM_Wound_PartKey(part) == PATCH_PART_KEY then
                local patch = states["FentanylPatch"]
                if patch ~= nil and now < patch.expire then
                    tickFentanylPatch(player)
                end
            end
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
