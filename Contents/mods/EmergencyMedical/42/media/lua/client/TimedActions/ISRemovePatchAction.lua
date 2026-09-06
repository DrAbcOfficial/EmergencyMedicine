-- Peel the sufentanil patch off the right upper arm: no tool, no
-- conditions (health panel right-click via RemovePatchHandler). Removing
-- the "FentanylPatch" state stops its per-minute upkeep immediately; the
-- accumulated painkiller wears off like any big dose would. Signature
-- mirrors ISCauterizeAction/ISRemoveScabAction (character = doctor,
-- patient = treated player).
--
-- MP: server-authoritative like every treatment -- complete() sends a
-- client command and the server applies it; singleplayer calls the
-- shared op directly (shared/Wound/TreatmentOps.lua).
require "TimedActions/ISBaseTimedAction"

ISRemovePatchAction = ISBaseTimedAction:derive("ISRemovePatchAction")

function ISRemovePatchAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    return EM_Wound_Has(self.patient, self.bodyPart, "FentanylPatch")
end

function ISRemovePatchAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISRemovePatchAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISRemovePatchAction:start()
    if self.character == self.patient then
        self:setActionAnim(CharacterActionAnims.Bandage)
        self:setAnimVariable("BandageType", ISHealthPanel.getBandageType(self.bodyPart))
        self.character:reportEvent("EventBandage")
    else
        self:setActionAnim("Loot")
        self.character:SetVariable("LootPosition", "Mid")
        self.character:reportEvent("EventLootItem")
    end
end

function ISRemovePatchAction:complete()
    if isClient() then
        sendClientCommand(self.character, "EmergencyMedical", "RemovePatch", {
            id = self.patient:getOnlineID(),
            part = self.bodyPart:getIndex(),
        })
    else
        EMTreatment_RemovePatch(self.patient, self.bodyPart)
    end
    return true
end

function ISRemovePatchAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 60
end

function ISRemovePatchAction:new(character, patient, bodyPart)
    local o = ISBaseTimedAction.new(self, character)
    o.patient = patient
    o.bodyPart = bodyPart
    o.stopOnWalk = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.stopOnRun = true
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.maxTime = o:getDuration()
    return o
end
