-- Peel the sufentanil patch off the right upper arm: no tool, no
-- conditions (health panel right-click via RemovePatchHandler).
-- Removing the "FentanylPatch" state stops its per-minute upkeep
-- immediately; the accumulated painkiller wears off like any big dose
-- would.
--
-- MP: complete() runs on the server (see EMBodyPartAction.lua), which
-- applies the shared op directly; singleplayer runs the same code on
-- the local process.
ISRemovePatchAction = EMBodyPartAction:derive("ISRemovePatchAction")

function ISRemovePatchAction:new(character, patient, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, nil, {
        duration = 60,
    })
end

function ISRemovePatchAction:isEligible()
    return EM_Wound_Has(self.patient, self.bodyPart, "FentanylPatch")
end

function ISRemovePatchAction:applyTreatment()
    EMTreatment_RemovePatch(self.patient, self.bodyPart)
end
