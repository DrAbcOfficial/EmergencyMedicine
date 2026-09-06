-- Glue / stapler field repair of a deep wound: crude stitching. The
-- wound itself stays (vanilla state untouched); the part gains the
-- "CrudeStitched" state for 120 days, during which every wound on it
-- hurts +20% (pain floor in BodyWoundSimulation.lua). Tools: glue,
-- wood glue (drainable -- one use per repair) or the stapler (not
-- consumed). Eligibility lives in EMCrudeStitch_IsEligiblePart
-- (shared/Wound/TreatmentOps.lua, re-validated server-side). Signature
-- mirrors the other body-part actions (character = doctor, patient =
-- treated player).
--
-- MP: server-authoritative like every treatment -- complete() sends a
-- client command and the server applies it; singleplayer calls the
-- shared op directly.
require "TimedActions/ISBaseTimedAction"

ISCrudeStitchAction = ISBaseTimedAction:derive("ISCrudeStitchAction")

function ISCrudeStitchAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if not EMCrudeStitch_IsEligiblePart(self.patient, self.bodyPart) then
        return false
    end
    if isClient() then
        return self.character:getInventory():containsID(self.tool:getID())
    end
    return self.character:getInventory():contains(self.tool)
end

function ISCrudeStitchAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISCrudeStitchAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.tool:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISCrudeStitchAction:start()
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
    self.tool:setJobType(getText("IGUI_health_CrudeStitch"))
    self.tool:setJobDelta(0.0)
end

function ISCrudeStitchAction:stop()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function ISCrudeStitchAction:perform()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.perform(self)
end

function ISCrudeStitchAction:complete()
    -- glue / wood glue are drainable: burn one use per repair; the
    -- stapler is a plain item and is not consumed
    if self.tool ~= nil and self.tool:IsDrainable() then
        self.tool:UseAndSync()
    end
    if isClient() then
        sendClientCommand(self.character, "EmergencyMedical", "CrudeStitch", {
            id = self.patient:getOnlineID(),
            part = self.bodyPart:getIndex(),
        })
    else
        EMTreatment_CrudeStitch(self.patient, self.bodyPart)
    end
    return true
end

function ISCrudeStitchAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 150
end

function ISCrudeStitchAction:new(character, patient, tool, bodyPart)
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
