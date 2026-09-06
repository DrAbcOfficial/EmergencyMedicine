-- Cut-bite: excise a FRESH bite with a blade from the health panel --
-- sharp-knife-tag blades or broken glass (the smashed-bottle weapon
-- counts as broken glass too). The bite becomes a deep wound at max
-- bleeding and max pain; glass embeds shards (vanilla haveGlass).
-- Eligibility lives in EMCutBite_IsEligiblePart
-- (shared/Wound/TreatmentOps.lua, re-validated server-side; both sides
-- resolve it at runtime).
local Handler = EMBodyPartHandler:derive("EMCutBiteHandler")

local GLASS_TOOL_TYPES = { ["Base.SmashedBottle"] = true }

function Handler:matchesItem(item)
    if item == nil then
        return false
    end
    if GLASS_TOOL_TYPES[item:getFullType()] then
        return true
    end
    if ItemTag.BROKEN_GLASS ~= nil and item:hasTag(ItemTag.BROKEN_GLASS) then
        return true
    end
    return ItemTag.SHARP_KNIFE ~= nil and item:hasTag(ItemTag.SHARP_KNIFE)
end

function Handler:isEligible()
    return EMCutBite_IsEligiblePart(self.bodyPart)
end

function Handler:getLabel()
    return getText("IGUI_health_CutBite")
end

function Handler:createAction(doctor, patient, item)
    local fullType = item:getFullType()
    local useGlass = GLASS_TOOL_TYPES[fullType] == true
        or (ItemTag.BROKEN_GLASS ~= nil and item:hasTag(ItemTag.BROKEN_GLASS))
    return ISCutBiteAction:new(doctor, patient, item, self.bodyPart, useGlass)
end

EMBodyPartHandler.Register(Handler)
