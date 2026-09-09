-- Cauterize a scratch / laceration (cut) / bite: press the burning tool
-- (lighter, disposable lighter, gunpowder) into the wound. The vanilla
-- wound is removed and replaced by the scab state; pain spike + small
-- burn damage (EMTreatment_Cauterize, which also stores the burned-out
-- wounds onto the state). Consumes one use of the drainable tool.
--
-- MP: server-authoritative -- applyTreatment sends the client command
-- and the server applies the shared op; singleplayer calls it directly.
ISCauterizeAction = EMBodyPartAction:derive("ISCauterizeAction")

function ISCauterizeAction:new(character, patient, tool, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, tool, {
        duration = 150,
        jobKey = "IGUI_health_Cauterize",
        treatmentCommand = "Cauterize",
        consumeTool = "drainable",
    })
end

function ISCauterizeAction:isEligible()
    return EMCauterize_IsEligiblePart(self.bodyPart)
end

function ISCauterizeAction:applyTreatment()
    if isClient() then
        self:sendTreatmentCommand()
    else
        EMTreatment_Cauterize(self.patient, self.bodyPart)
    end
end
