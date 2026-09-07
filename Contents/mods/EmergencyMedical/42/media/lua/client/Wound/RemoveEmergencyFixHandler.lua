-- Remove-fixation: an EMBodyPartHandler subclass that needs NO item --
-- the improvised fixation is torn off unconditionally from the health
-- panel right-click. It overrides addToMenu/onSelected because the base
-- ties its option to a found inventory item; matchesItem stays false so
-- the container scan never collects anything for this handler.
local Handler = EMBodyPartHandler:derive("EMRemoveEmergencyFixHandler")

function Handler:isEligible()
    return EM_Wound_Has(self:getPatient(), self.bodyPart, "EmergencyFixed")
end

function Handler:getLabel()
    return getText("IGUI_health_RemoveEmergencyFix")
end

function Handler:addToMenu(context)
    if not self:isEligible() then
        return
    end
    context:addOption(self:getLabel(), self, self.onSelected)
end

function Handler:onSelected()
    ISTimedActionQueue.add(ISRemoveEmergencyFixAction:new(self:getDoctor(), self:getPatient(), self.bodyPart))
end

EMBodyPartHandler.Register(Handler)
