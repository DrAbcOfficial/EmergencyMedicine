-- Improvised fixation of a fracture with the TemporarySplint item: the
-- fracture is TEMPORARILY REMOVED from the body and its severity rides
-- the "EmergencyFixed" state as a custom param (shared/Wound/
-- TreatmentOps.lua); no vanilla splint flags are set. Eligibility lives
-- in EMTemporarySplint_IsEligiblePart (vanilla splint rules + fixation
-- not present yet), re-validated server-side. Duration scales with the
-- doctor perk like the vanilla splint. The splint item itself is
-- consumed on the acting side (vanilla ISApplyBandage consumption
-- pattern).
--
-- MP: server-authoritative -- applyTreatment sends the client command
-- and the server applies the shared op; singleplayer calls it directly.
ISTemporarySplintAction = EMBodyPartAction:derive("ISTemporarySplintAction")

function ISTemporarySplintAction:new(character, patient, tool, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, tool, {
        jobKey = "IGUI_health_TemporarySplint",
        treatmentCommand = "TemporarySplint",
        consumeTool = "remove",
    })
end

function ISTemporarySplintAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 140 - (self.character:getPerkLevel(Perks.Doctor) * 4)
end

function ISTemporarySplintAction:isEligible()
    return EMTemporarySplint_IsEligiblePart(self.patient, self.bodyPart)
end

function ISTemporarySplintAction:applyTreatment()
    if isClient() then
        self:sendTreatmentCommand()
    else
        EMTreatment_TemporarySplint(self.patient, self.bodyPart)
    end
end
