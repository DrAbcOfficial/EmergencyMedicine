-- Remove-patch: a tool-less EMBodyPartHandler subclass (isToolless) --
-- the patch is peeled off unconditionally from the health panel
-- right-click. matchesItem stays false so the container scan never
-- collects anything for this handler.
local Handler = EMBodyPartHandler:derive("EMRemovePatchHandler")
Handler.isToolless = true

function Handler:isEligible()
    return EM_Wound_Has(self:getPatient(), self.bodyPart, "FentanylPatch")
end

function Handler:getLabel()
    return getText("IGUI_health_RemovePatch")
end

function Handler:createAction(doctor, patient, _item)
    return ISRemovePatchAction:new(doctor, patient, self.bodyPart)
end

EMBodyPartHandler.Register(Handler)
