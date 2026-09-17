-- Cauterize a scratch / laceration (cut) / bite: press the burning tool
-- (lighter, disposable lighter, gunpowder) into the wound. The vanilla
-- wound is removed and replaced by the scab state; pain spike + small
-- burn damage (EMTreatment_Cauterize, which also stores the burned-out
-- wounds onto the state). Consumes one use of the drainable tool.
--
-- MP: complete() runs on the server (see EMBodyPartAction.lua), which
-- applies the shared op directly; singleplayer runs the same code on
-- the local process.
ISCauterizeAction = EMBodyPartAction:derive("ISCauterizeAction")

function ISCauterizeAction:new(character, patient, tool, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, tool, {
        duration = 150,
        jobKey = "IGUI_health_Cauterize",
        consumeTool = "drainable",
    })
end

function ISCauterizeAction:isEligible()
    return EMCauterize_IsEligiblePart(self.bodyPart)
end

function ISCauterizeAction:applyTreatment()
    EMTreatment_Cauterize(self.patient, self.bodyPart)
end
