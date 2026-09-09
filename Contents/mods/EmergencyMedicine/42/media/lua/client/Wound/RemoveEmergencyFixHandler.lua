-- Remove-fixation: a tool-less EMBodyPartHandler subclass (isToolless)
-- -- the improvised fixation is torn off unconditionally from the
-- health panel right-click. matchesItem stays false so the container
-- scan never collects anything for this handler.
local Handler = EMBodyPartHandler:derive("EMRemoveEmergencyFixHandler")
Handler.isToolless = true

function Handler:isEligible()
    return EM_Wound_Has(self:getPatient(), self.bodyPart, "EmergencyFixed")
end

function Handler:getLabel()
    return getText("IGUI_health_RemoveEmergencyFix")
end

function Handler:createAction(doctor, patient, _item)
    return ISRemoveEmergencyFixAction:new(doctor, patient, self.bodyPart)
end

EMBodyPartHandler.Register(Handler)
