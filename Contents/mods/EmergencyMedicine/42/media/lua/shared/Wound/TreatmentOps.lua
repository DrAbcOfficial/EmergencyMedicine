-- EmergencyMedicine: shared treatment operations for the body-part wound
-- actions. The timed actions run on the acting player's client, but in
-- B42 MP body damage and player modData are SERVER-authoritative:
-- syncBodyPart is a server-only call (a no-op on clients, LuaManager
-- GlobalObject) and the server streams its whole BodyDamage copy over
-- the owning client's. So in multiplayer the actions send a client
-- command and these functions run on the server instead
-- (server/EmergencyMedicine_ClientCommands.lua); in singleplayer the
-- actions call them directly. Same code both sides, same effects.
--
-- Every body-part op ends with syncBodyPart: a no-op in singleplayer,
-- the MP broadcast on the server (vanilla ClientCommands.lua pattern).
-- EM_Wound changes transmit from the server via BodyWoundManager's
-- transmit branches.

-- BodyPartSyncPacket bits (sum): Health|bandaged|bleeding|IsBleedingStemmed|
-- IsCauterized|deepWounded|bleedingTime|deepWoundTime|additionalPain|
-- bitten|scratched|scratchTime|biteTime|woundInfectionLevel|infectedWound|
-- haveBullet|cut|cutTime
-- global: shared with the client timed actions
EM_BODYWOUND_SYNC_FLAGS = 1 + 2 + 8 + 16 + 32 + 256 + 131072 + 262144 + 4194304
    + 4 + 64 + 4096 + 8192 + 32768 + 65536
    + 274877906944 + 549755813888 + 1073741824

-- the cut-bite op also touches the embedded-glass flag
-- (BodyPartSyncPacket BD_haveGlass = 524288)
EM_CUTBITE_SYNC_FLAGS = EM_BODYWOUND_SYNC_FLAGS + 524288

-- the grass-bandage op only touches the local wound infection flags
-- (BodyPartSyncPacket BD_woundInfectionLevel = 32768, BD_infectedWound = 65536)
EM_INFECT_SYNC_FLAGS = 32768 + 65536

-- the splint ops touch the fracture and the splint layer
-- (BD_fractureTime + BD_splint + BD_splintFactor + BD_splintItem,
-- the vanilla ISSplint syncParam 0x430000000 plus the fracture time)
EM_SPLINT_SYNC_FLAGS = 134217728 + 268435456 + 536870912 + 17179869184

-- a bite's biteTime starts at 50-80 (Fast Healer 30-50, Slow Healer
-- 80-150) and ONLY decays from there -- the bite is considered
-- established (the Knox virus has had time to transfer) once it decayed
-- below this threshold; cutting must happen while the bite is fresh
EM_CUTBITE_FRESH_BITETIME = 30

-- a re-opened crude stitch bleeds moderately regardless of its age
local EXCISION_BLEEDING = 10.0

-- a fresh grass-bandage infection starts at its minimum level
local MIN_WOUND_INFECTION = 1.0

-- scratch / laceration / bite, without deep wound; bandages must come
-- off first; parts already carrying the vanilla cauterized flag are done
function EMCauterize_IsEligiblePart(part)
    if part == nil or part:deepWounded() or part:bandaged() or part:IsCauterized() then
        return false
    end
    return part:getScratchTime() > 0 or part:getCutTime() > 0 or part:getBiteTime() > 0
end

-- the part carries the cauterized scab state
function EMRemoveScab_IsEligiblePart(patient, part)
    if patient == nil or part == nil then
        return false
    end
    return EM_Wound_Has(patient, part, "Cauterized")
end

-- scratchTime sandbox option per scab age level (see EM_Wound_GetLevel
-- default quartiles: 4 = freshest -> 1 = oldest)
local SCAB_SCRATCH_OPTION = { [4] = "ScabScratchSevere", [3] = "ScabScratchModerate", [2] = "ScabScratchLight", [1] = "ScabScratchOld" }

-- burn the wound shut: the vanilla wound is REMOVED and replaced by the
-- scab state below (the setters' false paths only clear their flag +
-- bleeding; SetCauterized additionally clears stemmed/deep-wound/bandage).
-- A local wound infection is seared out as well -- the Knox virus
-- (IsInfected) is deliberately NOT touched. The burned-out wounds ride
-- the state as custom params and COME BACK if the part is wounded again
-- (BodyWoundSimulation pops the scab; EMTreatment_PopCauterized).
function EMTreatment_Cauterize(patient, part)
    -- the state goes on first so the wounds can be captured onto it
    -- before they are cleared
    local state = EM_Wound_Add(patient, part, "Cauterized")
    if state ~= nil then
        state.scratchTime = part:getScratchTime()
        state.cutTime = part:getCutTime()
        state.biteTime = part:getBiteTime()
    end
    part:setScratched(false, true)
    part:setCut(false)
    part:SetBitten(false, false)
    part:setScratchTime(0.0)
    part:setCutTime(0.0)
    part:setBiteTime(0.0)
    part:setInfectedWound(false)
    part:setWoundInfectionLevel(0.0)
    part:SetCauterized(true)
    part:setBleedingTime(0.0)
    part:setAdditionalPain(math.min(part:getAdditionalPain() + EM_Sandbox_Get("CauterizePain"), EM_CONST.PAIN_MAX))
    part:ReduceHealth(EM_Sandbox_Get("CauterizeDamage"))
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
    return state
end

-- scrape the scab off: becomes a scratch whose severity follows the
-- scab's AGE (panel shows "Severe" at scratchTime > 17, "Moderate" > 14);
-- setScratched(true, true) forces NO zombie-infection roll; the fresh
-- scratch re-enables cauterization on the part
function EMTreatment_RemoveScab(patient, part)
    -- read the scab age BEFORE taking the state off
    local level = EM_Wound_GetLevel(patient, part, "Cauterized")
    -- scab state off: the pain floor in BodyWoundSimulation stops on its own
    EM_Wound_Remove(patient, part, "Cauterized")
    -- the vanilla flag goes too, so the fresh scratch can be re-cauterized
    part:SetCauterized(false)
    part:setScratched(true, true)
    part:setScratchTime(EM_Sandbox_Get(SCAB_SCRATCH_OPTION[level] or "ScabScratchModerate"))
    part:setAdditionalPain(math.min(part:getAdditionalPain() + EM_Sandbox_Get("RemoveScabPain"), EM_CONST.PAIN_MAX))
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
end

-- dig a bullet out with BARE HANDS: the risky, tool-less alternative to
-- the vanilla tweezer removal. Digging always leaves a deep wound and
-- makes things worse across the board (all sandbox-configurable).
function EMTreatment_DigBullet(patient, part)
    -- bare hands, no doctor XP
    part:setHaveBullet(false, 0)
    -- the hole becomes a deep wound, and a botched dig makes it nastier
    part:generateDeepWound()
    part:setDeepWoundTime(part:getDeepWoundTime() + EM_Sandbox_Get("DigBulletSeverity"))
    -- bleeding caused or worsened
    part:setBleeding(true)
    part:setBleedingTime(part:getBleedingTime() + EM_Sandbox_Get("DigBulletBleeding"))
    -- a local wound infection is caused or worsened (NOT the Knox virus)
    part:setInfectedWound(true)
    part:setWoundInfectionLevel(part:getWoundInfectionLevel() + EM_Sandbox_Get("DigBulletInfection"))
    part:setAdditionalPain(math.min(part:getAdditionalPain() + EM_Sandbox_Get("DigBulletPain"), EM_CONST.PAIN_MAX))
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
end

-- peel the sufentanil patch off: no body-part flags change, the wound
-- state removal transmits itself
function EMTreatment_RemovePatch(patient, part)
    EM_Wound_Remove(patient, part, "FentanylPatch")
end

-- a FRESH bite can be cut out with a blade (sharp knife / broken glass):
-- the bite and the part-level Knox flag it carries are excised before
-- the virus establishes itself. Eligibility: the bite is fresh
-- (EM_CUTBITE_FRESH_BITETIME), not bandaged up (wound access), and the
-- part has no other open deep wound.
function EMCutBite_IsEligiblePart(part)
    if part == nil or not part:bitten() or part:bandaged() or part:deepWounded() then
        return false
    end
    return part:getBiteTime() >= EM_CUTBITE_FRESH_BITETIME
end

-- the excision itself: the bite becomes a deep wound (vanilla severity
-- roll, already "severe" on the panel) at MAX bleeding and MAX pain;
-- broken glass leaves shards embedded (vanilla haveGlass, removable
-- through the vanilla health panel). The overall Knox state is only
-- reset when no OTHER part carries the infection -- cutting must never
-- cure an infection that already established itself elsewhere.
function EMTreatment_CutBite(patient, part, useGlass)
    -- SetBitten(false, *) does NOT clear isInfected -- set explicitly
    part:SetBitten(false, false)
    part:setBiteTime(0.0)
    part:SetInfected(false)
    part:SetFakeInfected(false)

    part:generateDeepWound()
    part:setBleeding(true)
    part:setBleedingTime(EM_CONST.WOUND_TIME_MAX)
    part:setAdditionalPain(EM_CONST.PAIN_MAX)
    if useGlass then
        part:setHaveGlass(true)
    end
    syncBodyPart(part, EM_CUTBITE_SYNC_FLAGS)

    local bodyDamage = patient:getBodyDamage()
    if bodyDamage:isInfected() then
        local infectedElsewhere = false
        local parts = bodyDamage:getBodyParts()
        for i = 0, parts:size() - 1 do
            if i ~= part:getIndex() and parts:get(i):IsInfected() then
                infectedElsewhere = true
                break
            end
        end
        if not infectedElsewhere then
            bodyDamage:setInfected(false)
            bodyDamage:setInfectionTime(-1.0)
            bodyDamage:setInfectionMortalityDuration(-1.0)
            local stats = patient:getStats()
            stats:set(CharacterStat.ZOMBIE_INFECTION, 0.0)
            stats:set(CharacterStat.ZOMBIE_FEVER, 0.0)
        end
    end
end

-- crude grass bandage: GUARANTEES a local wound infection on the treated
-- part (dirty grass on an open wound -- NOT the Knox virus). The level
-- starts minimal and grows per the vanilla wound-infection rules; an
-- already-infected part keeps its existing level.
function EMTreatment_InfectWound(patient, part)
    if not part:isInfectedWound() then
        part:setInfectedWound(true)
        part:setWoundInfectionLevel(MIN_WOUND_INFECTION)
    end
    syncBodyPart(part, EM_INFECT_SYNC_FLAGS)
end

-- glue / stapler field repair of a deep wound: the crude repair CLOSES
-- the wound -- deep wound and bleeding are removed (the reopen happens
-- on scalpel excision, by age) and the part gains the "CrudeStitched"
-- state for "CrudeStitchedDurationDays" (per-minute pain boost in
-- BodyWoundSimulation.lua). Eligibility: an open deep wound, not
-- bandaged up, not properly stitched, no crude stitching yet.
function EMCrudeStitch_IsEligiblePart(patient, part)
    if part == nil or not part:deepWounded() or part:getDeepWoundTime() <= 0.0 then
        return false
    end
    if part:bandaged() or part:stitched() then
        return false
    end
    if patient ~= nil and EM_Wound_Has(patient, part, "CrudeStitched") then
        return false
    end
    return true
end

function EMTreatment_CrudeStitch(patient, part)
    -- the state goes on first so the wound can be captured onto it
    -- before it is closed
    local state = EM_Wound_Add(patient, part, "CrudeStitched")
    if state ~= nil then
        state.deepWoundTime = part:getDeepWoundTime()
        state.bleedingTime = part:getBleedingTime()
    end
    -- close the wound: deep wound and bleeding are gone (the reopen
    -- happens on scalpel excision, by age -- or when the part is
    -- wounded again: EMTreatment_PopCrudeStitch)
    part:setDeepWoundTime(0.0)
    part:setDeepWounded(false)
    part:setBleeding(false)
    part:setBleedingTime(0.0)
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
    -- duration comes from the CrudeStitched def ("CrudeStitchedDurationDays")
    return state
end

-- scalpel excision of the crude stitching: the wound REOPENS as a deep
-- wound whose severity follows the stitching's age (default quartiles,
-- 4 = freshest). panel deep-wound severity: > 10 severe, > 8 moderate.
-- sandbox option names per age level (resolved at removal time).
local CRUDE_STITCH_REOPEN_OPTION = { [4] = "CrudeStitchReopenSevere", [3] = "CrudeStitchReopenModerate", [2] = "CrudeStitchReopenLight", [1] = "CrudeStitchReopenOld" }

function EMRemoveCrudeStitch_IsEligiblePart(patient, part)
    if patient == nil or part == nil then
        return false
    end
    return EM_Wound_Has(patient, part, "CrudeStitched")
end

function EMTreatment_RemoveCrudeStitch(patient, part)
    -- read the stitching age BEFORE taking the state off
    local level = EM_Wound_GetLevel(patient, part, "CrudeStitched")
    EM_Wound_Remove(patient, part, "CrudeStitched")
    -- reopen: deep wound by age, moderate bleeding, pain pushed to the
    -- "RemoveCrudeStitchPain" sandbox value (default 100 = max)
    part:setDeepWounded(true)
    part:setDeepWoundTime(EM_Sandbox_Get(CRUDE_STITCH_REOPEN_OPTION[level] or "CrudeStitchReopenModerate"))
    part:setBleeding(true)
    part:setBleedingTime(EXCISION_BLEEDING)
    part:setAdditionalPain(math.max(part:getAdditionalPain(), EM_Sandbox_Get("RemoveCrudeStitchPain")))
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
end

-- improvised splint on a fracture: mirrors the vanilla splint rules
-- (ISHealthPanel HSplint) -- no head/chest, a fracture must be present,
-- and the part must not be splinted yet; never on a part already
-- carrying the fixation state.
function EMTemporarySplint_IsEligiblePart(patient, part)
    if part == nil then
        return false
    end
    local partType = part:getType()
    if partType == BodyPartType.Head or partType == BodyPartType.Torso_Upper or partType == BodyPartType.Torso_Lower then
        return false
    end
    if part:getFractureTime() <= 0.0 or part:getSplintFactor() > 0.0 then
        return false
    end
    if patient ~= nil and EM_Wound_Has(patient, part, "EmergencyFixed") then
        return false
    end
    return true
end

-- apply the improvised fixation: the fracture is TEMPORARILY REMOVED
-- from the body -- its severity is zeroed (no fracture line, no limp,
-- no fracture damage, nothing for the vanilla UI to show) and the true
-- value rides on the wound state as a custom param
-- (state.fractureTime), written right after EM_Wound_Add. No vanilla
-- splint flags are set: the part presents as unwounded except for the
-- "EmergencyFixed" state itself, and the fracture comes back on
-- removal (EMTreatment_RemoveEmergencyFix).
function EMTreatment_TemporarySplint(patient, part)
    local state = EM_Wound_Add(patient, part, "EmergencyFixed")
    if state ~= nil then
        state.fractureTime = part:getFractureTime()
    end
    part:setFractureTime(0.0)
    syncBodyPart(part, EM_SPLINT_SYNC_FLAGS)
    return state
end

-- tear the improvised fixation off (unconditional): the "removed"
-- fracture comes back -- worse than when it was hidden, the time spent
-- in the bad splint added to its severity (capped at 100, panel
-- "Severe" at >50). A NEW fracture suffered while fixated keeps
-- whichever severity is higher.
function EMTreatment_RemoveEmergencyFix(patient, part)
    -- read the hidden severity BEFORE taking the state off
    local state = EM_Wound_GetState(patient, part, "EmergencyFixed")
    EM_Wound_Remove(patient, part, "EmergencyFixed")
    if state ~= nil then
        local daysHeld = (patient:getHoursSurvived() - state.applied) / EM_CONST.HOURS_PER_GAME_DAY
        -- the worsening rate is a 0-1 fraction of the fracture scale
        -- per day (default 0.01 = one severity point per day)
        local restored = (state.fractureTime or 0.0)
            + daysHeld * EM_Sandbox_Get("EmergencyFixWorsenPerDay") * EM_CONST.WOUND_TIME_MAX
        part:setFractureTime(math.min(math.max(part:getFractureTime(), restored), EM_CONST.WOUND_TIME_MAX))
    end
    -- a save from a build that splinted the part: the vanilla splint
    -- layer goes with the state
    if part:getSplintItem() == "EmergencyMedicine.TemporarySplint" then
        part:setSplint(false, 0)
        part:setSplintItem("")
    end
    syncBodyPart(part, EM_SPLINT_SYNC_FLAGS)
end

-- the fixation state ran out ("EmergencyFixDurationDays" days): the
-- limb has healed up around the splint -- the hidden fracture (and any
-- fresh one suffered while fixated) heals together with it. Called
-- from the per-minute simulation (BodyWoundSimulation.lua), which
-- spots the expiry by reading the raw wound state's expire field
-- BEFORE the manager's lazy cleanup scrubs it; syncBodyPart only
-- really acts on a server.
function EMTreatment_EmergencyFixExpired(player, part)
    part:setFractureTime(0.0)
    if part:getSplintItem() == "EmergencyMedicine.TemporarySplint" then
        part:setSplint(false, 0)
        part:setSplintItem("")
    end
    EM_Wound_Remove(player, part, "EmergencyFixed")
    syncBodyPart(part, EM_SPLINT_SYNC_FLAGS)
end

-- the stored-wound states (cauterized scab / crude stitching /
-- improvised fixation) POP when the part takes a new wound (detected
-- per minute in BodyWoundSimulation): the stored severity returns at
-- once and the state is removed. A new wound of the SAME type as the
-- stored one absorbs it -- the stored severity stacks onto the new
-- wound, capped at 100; a different-type new wound leaves the stored
-- wound standing on its own alongside. Restored wounds never roll the
-- Knox virus (the ignore-infection setter paths only).
local function stackSeverity(newValue, stored)
    return math.min(newValue + stored, EM_CONST.WOUND_TIME_MAX)
end

function EMTreatment_PopCauterized(patient, part, state)
    EM_Wound_Remove(patient, part, "Cauterized")
    -- clear the vanilla flag explicitly so the part can be re-cauterized
    part:SetCauterized(false)
    local storedScratch = state.scratchTime or 0.0
    local storedCut = state.cutTime or 0.0
    local storedBite = state.biteTime or 0.0
    if part:getScratchTime() > 0.0 then
        if storedScratch > 0.0 then
            part:setScratchTime(stackSeverity(part:getScratchTime(), storedScratch))
        end
    elseif storedScratch > 0.0 then
        part:setScratched(true, true)
        part:setScratchTime(storedScratch)
    end
    if part:getCutTime() > 0.0 then
        if storedCut > 0.0 then
            part:setCutTime(stackSeverity(part:getCutTime(), storedCut))
        end
    elseif storedCut > 0.0 then
        part:setCut(true, true)
        part:setCutTime(storedCut)
    end
    if part:getBiteTime() > 0.0 then
        if storedBite > 0.0 then
            part:setBiteTime(stackSeverity(part:getBiteTime(), storedBite))
        end
    elseif storedBite > 0.0 then
        -- infected=false: the Knox outcome was settled long ago, the
        -- wound just comes back
        part:SetBitten(true, false)
        part:setBiteTime(storedBite)
    end
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
end

function EMTreatment_PopCrudeStitch(patient, part, state)
    EM_Wound_Remove(patient, part, "CrudeStitched")
    local stored = state.deepWoundTime or 0.0
    if part:getDeepWoundTime() > 0.0 then
        -- a new deep wound on the stitched part: it absorbs the stored one
        part:setDeepWoundTime(stackSeverity(part:getDeepWoundTime(), stored))
    elseif stored > 0.0 then
        -- the stored deep wound tears back open on its own
        part:setDeepWounded(true)
        part:setDeepWoundTime(stored)
    end
    local storedBleeding = state.bleedingTime or 0.0
    if storedBleeding > 0.0 then
        part:setBleeding(true)
        part:setBleedingTime(part:getBleedingTime() + storedBleeding)
    end
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
end

function EMTreatment_PopEmergencyFix(patient, part, state)
    -- the trigger IS a fresh fracture on the fixated part: it absorbs
    -- the hidden severity (no removal worsening here -- that is the
    -- price of tearing the fixation off by choice)
    EM_Wound_Remove(patient, part, "EmergencyFixed")
    part:setFractureTime(stackSeverity(part:getFractureTime(), state.fractureTime or 0.0))
    if part:getSplintItem() == "EmergencyMedicine.TemporarySplint" then
        part:setSplint(false, 0)
        part:setSplintItem("")
    end
    syncBodyPart(part, EM_SPLINT_SYNC_FLAGS)
end
