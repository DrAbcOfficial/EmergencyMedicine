-- Crude stitch: glue / stapler field repair of a deep wound. Right-click
-- an open deep wound in the health panel -> "粗糙缝合" when glue, wood
-- glue (both drainable -- one use per repair) or the stapler (not
-- consumed) is carried nearby. Eligibility lives in
-- EMCrudeStitch_IsEligiblePart (shared/Wound/TreatmentOps.lua; both
-- sides resolve it at runtime).
local Handler = EMBodyPartHandler:derive("EMCrudeStitchHandler")

local CRUDE_STITCH_TOOL_TYPES = {
    ["Base.Glue"] = true,
    ["Base.Woodglue"] = true,
    ["Base.Stapler"] = true,
}

function Handler:matchesItem(item)
    return item ~= nil and CRUDE_STITCH_TOOL_TYPES[item:getFullType()] == true
end

function Handler:isEligible()
    return EMCrudeStitch_IsEligiblePart(self:getPatient(), self.bodyPart)
end

function Handler:getLabel()
    return getText("IGUI_health_CrudeStitch")
end

function Handler:createAction(doctor, patient, item)
    return ISCrudeStitchAction:new(doctor, patient, item, self.bodyPart)
end

EMBodyPartHandler.Register(Handler)
