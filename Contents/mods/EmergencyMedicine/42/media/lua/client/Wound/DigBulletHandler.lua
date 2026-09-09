-- Dig-bullet: a tool-less EMBodyPartHandler subclass (isToolless) --
-- bare hands. Right-click a gunshot wound in the health panel ->
-- "用手抠出子弹", the risky removal: deep wound, worse severity,
-- bleeding and infection (see ISDigBulletAction.lua). matchesItem stays
-- false so the container scan never collects anything for this handler.
local Handler = EMBodyPartHandler:derive("EMDigBulletHandler")
Handler.isToolless = true

function Handler:isEligible()
    return self.bodyPart:haveBullet()
end

function Handler:getLabel()
    return getText("IGUI_health_DigBullet")
end

function Handler:createAction(doctor, patient, _item)
    return ISDigBulletAction:new(doctor, patient, self.bodyPart)
end

EMBodyPartHandler.Register(Handler)
