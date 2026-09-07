-- Improvised splint: right-click a fracture in the health panel ->
-- "应急固定" when a TemporarySplint is carried nearby. Eligibility lives
-- in EMTemporarySplint_IsEligiblePart (shared/Wound/TreatmentOps.lua;
-- both sides resolve it at runtime).
local Handler = EMBodyPartHandler:derive("EMTemporarySplintHandler")

function Handler:matchesItem(item)
    return item ~= nil and item:getFullType() == "EmergencyMedical.TemporarySplint"
end

function Handler:isEligible()
    return EMTemporarySplint_IsEligiblePart(self:getPatient(), self.bodyPart)
end

function Handler:getLabel()
    return getText("IGUI_health_TemporarySplint")
end

function Handler:createAction(doctor, patient, item)
    return ISTemporarySplintAction:new(doctor, patient, item, self.bodyPart)
end

EMBodyPartHandler.Register(Handler)
