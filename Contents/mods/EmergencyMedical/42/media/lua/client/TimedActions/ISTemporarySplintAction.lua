-- Improvised fixation of a fracture with the TemporarySplint item: the
-- part is splinted exactly like the vanilla splint (splint factor by
-- doctor skill) AND gains the "EmergencyFixed" state, which freezes the
-- fracture and hurts more until it comes off (shared/Wound/
-- TreatmentOps.lua). Eligibility lives in EMTemporarySplint_IsEligiblePart
-- (vanilla splint rules + fixation not present yet), re-validated
-- server-side. Signature mirrors the other body-part actions (character
-- = doctor, patient = treated player).
--
-- MP: server-authoritative like every treatment -- complete() sends a
-- client command and the server applies it; singleplayer calls the
-- shared op directly. The splint item itself is consumed on the acting
-- side (vanilla ISApplyBandage consumption pattern).
require "TimedActions/ISBaseTimedAction"

ISTemporarySplintAction = ISBaseTimedAction:derive("ISTemporarySplintAction")

function ISTemporarySplintAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if not EMTemporarySplint_IsEligiblePart(self.patient, self.bodyPart) then
        return false
    end
    if isClient() then
        return self.character:getInventory():containsID(self.tool:getID())
    end
    return self.character:getInventory():contains(self.tool)
end

function ISTemporarySplintAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISTemporarySplintAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.tool:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISTemporarySplintAction:start()
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
    self.tool:setJobType(getText("IGUI_health_TemporarySplint"))
    self.tool:setJobDelta(0.0)
end

function ISTemporarySplintAction:stop()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function ISTemporarySplintAction:perform()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.perform(self)
end

function ISTemporarySplintAction:complete()
    -- a plain (non-drainable) item: removed like the vanilla bandage
    -- plank consumption
    self.character:getInventory():Remove(self.tool)
    if isServer() then
        sendRemoveItemFromContainer(self.character:getInventory(), self.tool)
    end
    local splintFactor = (self.character:getPerkLevel(Perks.Doctor) + 1) / 2
    if isMultiplayer() and self.character:getRole():hasCapability(Capability.CanMedicalCheat) then
        splintFactor = 5.5
    end
    if isClient() then
        sendClientCommand(self.character, "EmergencyMedical", "TemporarySplint", {
            id = self.patient:getOnlineID(),
            part = self.bodyPart:getIndex(),
            factor = splintFactor,
        })
    else
        EMTreatment_TemporarySplint(self.patient, self.bodyPart, splintFactor)
    end
    return true
end

function ISTemporarySplintAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 140 - (self.character:getPerkLevel(Perks.Doctor) * 4)
end

function ISTemporarySplintAction:new(character, patient, tool, bodyPart)
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
