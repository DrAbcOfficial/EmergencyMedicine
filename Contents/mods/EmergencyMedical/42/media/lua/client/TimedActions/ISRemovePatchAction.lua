-- Peel the sufentanil patch off the right upper arm: no tool, no
-- conditions (health panel right-click via RemovePatchHandler).
-- Removing the "FentanylPatch" state stops its per-minute upkeep
-- immediately; the accumulated painkiller wears off like any big dose
-- would.
--
-- MP: server-authoritative -- applyTreatment sends the client command
-- and the server applies the shared op; singleplayer calls it directly.
ISRemovePatchAction = EMBodyPartAction:derive("ISRemovePatchAction")

function ISRemovePatchAction:new(character, patient, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, nil, {
        duration = 60,
        treatmentCommand = "RemovePatch",
    })
end

function ISRemovePatchAction:isEligible()
    return EM_Wound_Has(self.patient, self.bodyPart, "FentanylPatch")
end

function ISRemovePatchAction:applyTreatment()
    if isClient() then
        self:sendTreatmentCommand()
    else
        EMTreatment_RemovePatch(self.patient, self.bodyPart)
    end
end
