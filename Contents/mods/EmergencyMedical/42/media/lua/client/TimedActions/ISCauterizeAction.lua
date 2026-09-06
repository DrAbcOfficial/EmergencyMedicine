-- Cauterize a scratch / laceration (cut) / bite: press the burning tool
-- (lighter, disposable lighter, gunpowder) into the wound. Signature
-- mirrors the vanilla health-panel actions (ISCleanBurn/ISDisinfect):
-- character = doctor, patient = the player whose part is treated (same
-- object for self-treatment). Self-treatment plays the vanilla bandage
-- animation (ISHealthPanel.getBandageType); treating someone else plays
-- the Loot animation and faces the patient.
--
-- Effects in complete():
--   - part:SetCauterized(true): the vanilla Java flag (unused by vanilla
--     Lua) -- stops the bleeding, clears stemmed/deep-wound/bandage, and
--     persists + syncs over MP for free (BodyDamageSync BD_IsCauterized).
--     A NEW wound on the part clears the flag again (vanilla behaviour).
--   - pain spike + small burn damage on the part
--   - EM_Wound_Add(..., "Cauterized"): the long-lived scab state
--     (default 90 days, sandbox option; custom manager, shared/Wound/).
-- The eligibility predicate is shared with the health-panel hook (both
-- resolve it at runtime).
require "TimedActions/ISBaseTimedAction"

ISCauterizeAction = ISBaseTimedAction:derive("ISCauterizeAction")

-- Pain spike and burn damage are sandbox-configurable
-- (EM_Sandbox_Get "CauterizePain" / "CauterizeDamage")
-- BodyPartSyncPacket bits (sum): Health|bandaged|bleeding|IsBleedingStemmed|
-- IsCauterized|deepWounded|bleedingTime|deepWoundTime|additionalPain|
-- bitten|scratched|scratchTime|biteTime|woundInfectionLevel|infectedWound|
-- cut|cutTime
-- global: shared with the other body-part wound actions (ISRemoveScabAction)
EM_BODYWOUND_SYNC_FLAGS = 1 + 2 + 8 + 16 + 32 + 256 + 131072 + 262144 + 4194304
    + 4 + 64 + 4096 + 8192 + 32768 + 65536
    + 274877906944 + 549755813888

-- scratch / laceration / bite, without deep wound; bandages must come
-- off first; parts already carrying the vanilla cauterized flag are done
function EMCauterize_IsEligiblePart(part)
    if part == nil or part:deepWounded() or part:bandaged() or part:IsCauterized() then
        return false
    end
    return part:getScratchTime() > 0 or part:getCutTime() > 0 or part:getBiteTime() > 0
end

function ISCauterizeAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if not EMCauterize_IsEligiblePart(self.bodyPart) then
        return false
    end
    if isClient() then
        return self.character:getInventory():containsID(self.tool:getID())
    end
    return self.character:getInventory():contains(self.tool)
end

function ISCauterizeAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISCauterizeAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.tool:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISCauterizeAction:start()
    if isClient() then
        self.tool = self.character:getInventory():getItemById(self.tool:getID())
    end
    if self.character == self.patient then
        self:setActionAnim(CharacterActionAnims.Bandage)
        self:setAnimVariable("BandageType", ISHealthPanel.getBandageType(self.bodyPart))
        self.character:reportEvent("EventBandage")
    else
        self:setActionAnim("Loot")
        self.character:SetVariable("LootPosition", "Mid")
        self.character:reportEvent("EventLootItem")
    end
    self:setOverrideHandModels(nil, self.tool)
    self.tool:setJobType(getText("IGUI_health_Cauterize"))
    self.tool:setJobDelta(0.0)
end

function ISCauterizeAction:stop()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function ISCauterizeAction:perform()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.perform(self)
end

function ISCauterizeAction:complete()
    -- every cauterize tool is a drainable: burn one use
    if self.tool ~= nil and self.tool:IsDrainable() then
        self.tool:UseAndSync()
    end
    local part = self.bodyPart
    -- burn the wound shut: the vanilla wound is REMOVED and replaced by
    -- the scab state below (the setters' false paths only clear their
    -- flag + bleeding; SetCauterized additionally clears
    -- stemmed/deep-wound/bandage). A local wound infection is seared out
    -- as well -- the Knox virus (IsInfected) is deliberately NOT touched.
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
    EM_Wound_Add(self.patient, part, "Cauterized")
    return true
end

function ISCauterizeAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 150
end

function ISCauterizeAction:new(character, patient, tool, bodyPart)
    local o = ISBaseTimedAction.new(self, character)
    o.patient = patient
    o.tool = tool
    o.bodyPart = bodyPart
    o.stopOnWalk = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.stopOnRun = true
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.maxTime = o:getDuration()
    return o
end
