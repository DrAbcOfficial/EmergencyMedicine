-- Tear the improvised fixation ("EmergencyFixed" state) off a body
-- part: no tool, no conditions (health panel right-click via
-- RemoveEmergencyFixHandler). The fracture comes back WORSE -- the time
-- spent in the bad splint is added to its severity
-- (EMTreatment_RemoveEmergencyFix). Signature mirrors
-- ISRemovePatchAction (character = doctor, patient = treated player).
--
-- MP: server-authoritative like every treatment -- complete() sends a
-- client command and the server applies it; singleplayer calls the
-- shared op directly.
require "TimedActions/ISBaseTimedAction"

ISRemoveEmergencyFixAction = ISBaseTimedAction:derive("ISRemoveEmergencyFixAction")

function ISRemoveEmergencyFixAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    return EM_Wound_Has(self.patient, self.bodyPart, "EmergencyFixed")
end

function ISRemoveEmergencyFixAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISRemoveEmergencyFixAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISRemoveEmergencyFixAction:start()
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

function ISRemoveEmergencyFixAction:complete()
    if isClient() then
        sendClientCommand(self.character, "EmergencyMedical", "RemoveEmergencyFix", {
            id = self.patient:getOnlineID(),
            part = self.bodyPart:getIndex(),
        })
    else
        EMTreatment_RemoveEmergencyFix(self.patient, self.bodyPart)
    end
    return true
end

function ISRemoveEmergencyFixAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 100
end

function ISRemoveEmergencyFixAction:new(character, patient, bodyPart)
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
