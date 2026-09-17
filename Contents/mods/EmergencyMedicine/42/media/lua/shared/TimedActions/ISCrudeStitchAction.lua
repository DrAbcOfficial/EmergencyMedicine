-- Glue / stapler field repair of a deep wound: crude stitching. The
-- wound itself is closed and the part gains the "CrudeStitched" state
-- (the closed wound rides the state as custom params; every wound on
-- the part hurts +20% while it lasts). Glue / wood glue are drainable
-- (one use per repair), the stapler is reusable. Eligibility lives in
-- EMCrudeStitch_IsEligiblePart.
--
-- MP: complete() runs on the server (see EMBodyPartAction.lua), which
-- applies the shared op directly; singleplayer runs the same code on
-- the local process.
ISCrudeStitchAction = EMBodyPartAction:derive("ISCrudeStitchAction")

function ISCrudeStitchAction:new(character, patient, tool, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, tool, {
        duration = 150,
        jobKey = "IGUI_health_CrudeStitch",
        consumeTool = "drainable",
    })
end

function ISCrudeStitchAction:isEligible()
    return EMCrudeStitch_IsEligiblePart(self.patient, self.bodyPart)
end

function ISCrudeStitchAction:applyTreatment()
    EMTreatment_CrudeStitch(self.patient, self.bodyPart)
end
