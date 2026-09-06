-- Cauterize a scratch / laceration (cut) / bite: press the burning tool
-- (lighter, disposable lighter, gunpowder) into the wound. Signature
-- mirrors the vanilla health-panel actions (ISCleanBurn/ISDisinfect):
-- character = doctor, patient = the player whose part is treated (same
-- object for self-treatment). Self-treatment plays the vanilla bandage
-- animation (ISHealthPanel.getBandageType); treating someone else plays
-- the Loot animation and faces the patient.
--
-- Effects (see shared/Wound/TreatmentOps.lua: EMTreatment_Cauterize):
--   - the vanilla wound is removed and part:SetCauterized(true) set (the
--     vanilla Java flag, unused by vanilla Lua -- stops the bleeding,
--     clears stemmed/deep-wound/bandage, persists in the save; a NEW
--     wound on the part clears the flag again, vanilla behaviour)
--   - pain spike + small burn damage on the part
--   - EM_Wound_Add(..., "Cauterized"): the long-lived scab state
--     (default 90 days, sandbox option; custom manager, shared/Wound/)
--
-- MP: body damage + wound states are server-authoritative (the
-- client-side syncBodyPart is a no-op there), so complete() sends a
-- client command and the server applies the treatment; singleplayer
-- calls it directly. The tool is consumed client-side either way (the
-- vanilla drainable sync carries it).
require "TimedActions/ISBaseTimedAction"

ISCauterizeAction = ISBaseTimedAction:derive("ISCauterizeAction")

-- Pain spike and burn damage are sandbox-configurable
-- (EM_Sandbox_Get "CauterizePain" / "CauterizeDamage")
-- EMCauterize_IsEligiblePart and EM_BODYWOUND_SYNC_FLAGS live in
-- shared/Wound/TreatmentOps.lua (the server command handler needs them
-- too, and the server does not load client files)

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
    if isClient() then
        sendClientCommand(self.character, "EmergencyMedical", "Cauterize", {
            id = self.patient:getOnlineID(),
            part = self.bodyPart:getIndex(),
        })
    else
        EMTreatment_Cauterize(self.patient, self.bodyPart)
    end
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
