-- Remove-scab: an EMBodyPartHandler subclass. Right-click a part that
-- carries the "Cauterized" scab while holding a scalpel (Base.Scalpel,
-- reusable -- nothing is consumed) -> "移除结痂" option. The scab is
-- scraped off and becomes a scratch whose severity follows the scab's
-- age (see ISRemoveScabAction).
local Handler = EMBodyPartHandler:derive("EMRemoveScabHandler")

function Handler:matchesItem(item)
    return item ~= nil and item:getFullType() == "Base.Scalpel"
end

function Handler:isEligible()
    return EMRemoveScab_IsEligiblePart(self:getPatient(), self.bodyPart)
end

function Handler:getLabel()
    return getText("IGUI_health_RemoveScab")
end

function Handler:createAction(doctor, patient, item)
    return ISRemoveScabAction:new(doctor, patient, item, self.bodyPart)
end

EMBodyPartHandler.Register(Handler)
