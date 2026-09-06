-- EmergencyMedical: shared treatment operations for the body-part wound
-- actions. The timed actions run on the acting player's client, but in
-- B42 MP body damage and player modData are SERVER-authoritative:
-- syncBodyPart is a server-only call (a no-op on clients, LuaManager
-- GlobalObject) and the server streams its whole BodyDamage copy over
-- the owning client's. So in multiplayer the actions send a client
-- command and these functions run on the server instead
-- (server/EmergencyMedical_ClientCommands.lua); in singleplayer the
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
-- (IsInfected) is deliberately NOT touched.
function EMTreatment_Cauterize(patient, part)
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
    part:setAdditionalPain(math.min(part:getAdditionalPain() + EM_Sandbox_Get("CauterizePain"), 100.0))
    part:ReduceHealth(EM_Sandbox_Get("CauterizeDamage"))
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
    return EM_Wound_Add(patient, part, "Cauterized")
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
    part:setAdditionalPain(math.min(part:getAdditionalPain() + EM_Sandbox_Get("RemoveScabPain"), 100.0))
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
    part:setAdditionalPain(math.min(part:getAdditionalPain() + EM_Sandbox_Get("DigBulletPain"), 100.0))
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
end

-- peel the sufentanil patch off: no body-part flags change, the wound
-- state removal transmits itself
function EMTreatment_RemovePatch(patient, part)
    EM_Wound_Remove(patient, part, "FentanylPatch")
end
