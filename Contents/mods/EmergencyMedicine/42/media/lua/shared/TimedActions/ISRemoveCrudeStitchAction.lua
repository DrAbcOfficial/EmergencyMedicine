-- Excise the crude stitching with a scalpel (reusable -- nothing is
-- consumed): the "CrudeStitched" state is taken off and the wound
-- REOPENS as a deep wound whose severity follows the stitching's age
-- (default quartiles, 4 = freshest -> 18/15/8/3 deepWoundTime), with
-- moderate bleeding and a painful sting. Eligibility lives in
-- EMRemoveCrudeStitch_IsEligiblePart.
--
-- MP: complete() runs on the server (see EMBodyPartAction.lua), which
-- applies the shared op directly; singleplayer runs the same code on
-- the local process.
ISRemoveCrudeStitchAction = EMBodyPartAction:derive("ISRemoveCrudeStitchAction")

function ISRemoveCrudeStitchAction:new(character, patient, tool, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, tool, {
        duration = 120,
        jobKey = "IGUI_health_RemoveCrudeStitch",
    })
end

function ISRemoveCrudeStitchAction:isEligible()
    return EMRemoveCrudeStitch_IsEligiblePart(self.patient, self.bodyPart)
end

function ISRemoveCrudeStitchAction:applyTreatment()
    EMTreatment_RemoveCrudeStitch(self.patient, self.bodyPart)
end
