-- Remove the crude stitching with a scalpel (reusable -- nothing is
-- consumed): the "CrudeStitched" state comes off and the wound REOPENS
-- as a deep wound whose severity follows the stitching's age. Matches
-- fullType Base.Scalpel. Eligibility lives in
-- EMRemoveCrudeStitch_IsEligiblePart (shared/Wound/TreatmentOps.lua;
-- both sides resolve it at runtime).
local Handler = EMBodyPartHandler:derive("EMRemoveCrudeStitchHandler")

function Handler:matchesItem(item)
    return item ~= nil and item:getFullType() == "Base.Scalpel"
end

function Handler:isEligible()
    return EMRemoveCrudeStitch_IsEligiblePart(self:getPatient(), self.bodyPart)
end

function Handler:getLabel()
    return getText("IGUI_health_RemoveCrudeStitch")
end

function Handler:createAction(doctor, patient, item)
    return ISRemoveCrudeStitchAction:new(doctor, patient, item, self.bodyPart)
end

EMBodyPartHandler.Register(Handler)
