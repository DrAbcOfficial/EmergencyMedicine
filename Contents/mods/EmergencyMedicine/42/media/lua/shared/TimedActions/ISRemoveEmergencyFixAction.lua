-- Tear the improvised fixation ("EmergencyFixed" state) off a body
-- part: no tool, no conditions (health panel right-click via
-- RemoveEmergencyFixHandler). The hidden fracture comes back WORSE --
-- the time spent in the bad splint is added to its severity
-- (EMTreatment_RemoveEmergencyFix).
--
-- MP: complete() runs on the server (see EMBodyPartAction.lua), which
-- applies the shared op directly; singleplayer runs the same code on
-- the local process.
ISRemoveEmergencyFixAction = EMBodyPartAction:derive("ISRemoveEmergencyFixAction")

function ISRemoveEmergencyFixAction:new(character, patient, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, nil, {
        duration = 100,
    })
end

function ISRemoveEmergencyFixAction:isEligible()
    return EM_Wound_Has(self.patient, self.bodyPart, "EmergencyFixed")
end

function ISRemoveEmergencyFixAction:applyTreatment()
    EMTreatment_RemoveEmergencyFix(self.patient, self.bodyPart)
end
