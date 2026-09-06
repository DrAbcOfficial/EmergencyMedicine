-- Dig-bullet: an EMBodyPartHandler subclass that needs NO item -- bare
-- hands. Right-click a gunshot wound in the health panel -> "用手抠出子弹",
-- the risky removal: deep wound, worse severity, bleeding and infection
-- (see ISDigBulletAction.lua). Overrides addToMenu/onSelected because the
-- base ties its option to a found inventory item.
local Handler = EMBodyPartHandler:derive("EMDigBulletHandler")

function Handler:isEligible()
    return self.bodyPart:haveBullet()
end

function Handler:getLabel()
    return getText("IGUI_health_DigBullet")
end

function Handler:addToMenu(context)
    if not self:isEligible() then
        return
    end
    context:addOption(self:getLabel(), self, self.onSelected)
end

function Handler:onSelected()
    ISTimedActionQueue.add(ISDigBulletAction:new(self:getDoctor(), self:getPatient(), self.bodyPart))
end

EMBodyPartHandler.Register(Handler)
