-- Glue / stapler field repair of a deep wound: crude stitching. The
-- wound itself is closed and the part gains the "CrudeStitched" state
-- (the closed wound rides the state as custom params; every wound on
-- the part hurts +20% while it lasts). Glue / wood glue are drainable
-- (one use per repair), the stapler is reusable. Eligibility lives in
-- EMCrudeStitch_IsEligiblePart.
--
-- MP: server-authoritative -- applyTreatment sends the client command
-- and the server applies the shared op; singleplayer calls it directly.
ISCrudeStitchAction = EMBodyPartAction:derive("ISCrudeStitchAction")

function ISCrudeStitchAction:new(character, patient, tool, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, tool, {
        duration = 150,
        jobKey = "IGUI_health_CrudeStitch",
        treatmentCommand = "CrudeStitch",
        consumeTool = "drainable",
    })
end

function ISCrudeStitchAction:isEligible()
    return EMCrudeStitch_IsEligiblePart(self.patient, self.bodyPart)
end

function ISCrudeStitchAction:applyTreatment()
    if isClient() then
        self:sendTreatmentCommand()
    else
        EMTreatment_CrudeStitch(self.patient, self.bodyPart)
    end
end
