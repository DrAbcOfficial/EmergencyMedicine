-- Cauterize: the first EMBodyPartHandler subclass. Right-click a scratch
-- / laceration (cut) / bite in the health panel -> "灼烧伤口" option when
-- a lighter-class tool (ItemTag.LIGHTER: zippo, disposable, BBQ, crafted
-- battery lighter) or gunpowder (Base.GunPowder) is carried nearby.
-- Eligibility lives in EMCauterize_IsEligiblePart (shared with the timed
-- action and the server command handler, see shared/Wound/TreatmentOps.lua;
-- all consumers resolve it at runtime).
local Handler = EMBodyPartHandler:derive("EMCauterizeHandler")

local CAUTERIZE_TOOL_TYPES = {
    ["Base.GunPowder"] = true,
}

function Handler:matchesItem(item)
    if item == nil then
        return false
    end
    if CAUTERIZE_TOOL_TYPES[item:getFullType()] then
        return true
    end
    return ItemTag ~= nil and ItemTag.LIGHTER ~= nil and item:hasTag(ItemTag.LIGHTER)
end

function Handler:isEligible()
    return EMCauterize_IsEligiblePart(self.bodyPart)
end

function Handler:getLabel()
    return getText("IGUI_health_Cauterize")
end

function Handler:createAction(doctor, patient, item)
    return ISCauterizeAction:new(doctor, patient, item, self.bodyPart)
end

EMBodyPartHandler.Register(Handler)
