-- Excise the crude stitching with a scalpel (reusable -- nothing is
-- consumed): the "CrudeStitched" state is taken off and the wound
-- REOPENS as a deep wound whose severity follows the stitching's age
-- (default quartiles, 4 = freshest -> 18/15/8/3 deepWoundTime), with
-- moderate bleeding and a painful sting. Eligibility lives in
-- EMRemoveCrudeStitch_IsEligiblePart (shared/Wound/TreatmentOps.lua).
-- Signature mirrors the other body-part actions (character = doctor,
-- patient = treated player).
--
-- MP: server-authoritative like every treatment -- complete() sends a
-- client command and the server applies it; singleplayer calls the
-- shared op directly.
require "TimedActions/ISBaseTimedAction"

ISRemoveCrudeStitchAction = ISBaseTimedAction:derive("ISRemoveCrudeStitchAction")

function ISRemoveCrudeStitchAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if not EMRemoveCrudeStitch_IsEligiblePart(self.patient, self.bodyPart) then
        return false
    end
    if isClient() then
        return self.character:getInventory():containsID(self.tool:getID())
    end
    return self.character:getInventory():contains(self.tool)
end

function ISRemoveCrudeStitchAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISRemoveCrudeStitchAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.tool:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISRemoveCrudeStitchAction:start()
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
    self.tool:setJobType(getText("IGUI_health_RemoveCrudeStitch"))
    self.tool:setJobDelta(0.0)
end

function ISRemoveCrudeStitchAction:stop()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function ISRemoveCrudeStitchAction:perform()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.perform(self)
end

function ISRemoveCrudeStitchAction:complete()
    if isClient() then
        sendClientCommand(self.character, "EmergencyMedical", "RemoveCrudeStitch", {
            id = self.patient:getOnlineID(),
            part = self.bodyPart:getIndex(),
        })
    else
        EMTreatment_RemoveCrudeStitch(self.patient, self.bodyPart)
    end
    return true
end

function ISRemoveCrudeStitchAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 120
end

function ISRemoveCrudeStitchAction:new(character, patient, tool, bodyPart)
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
