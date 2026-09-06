-- Dig a bullet out with BARE HANDS: the risky, tool-less alternative to
-- the vanilla tweezer removal. Digging always leaves a deep wound and
-- makes things worse across the board (all sandbox-configurable):
--   - the bullet comes out (setHaveBullet(false, 0) -- no doctor XP)
--   - generateDeepWound() + "DigBulletSeverity" extra deepWoundTime
--   - bleeding is caused or worsened ("DigBulletBleeding" extra time)
--   - a local wound infection is caused or worsened
--   ("DigBulletInfection" level bump -- NOT the Knox virus)
--   - "DigBulletPain" extra pain
-- Signature mirrors the other body-part actions (character = doctor,
-- patient = treated player).
require "TimedActions/ISBaseTimedAction"

ISDigBulletAction = ISBaseTimedAction:derive("ISDigBulletAction")

function ISDigBulletAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if not self.bodyPart:haveBullet() then
        return false
    end
    return true
end

function ISDigBulletAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISDigBulletAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISDigBulletAction:start()
    if self.character == self.patient then
        self:setActionAnim(CharacterActionAnims.Bandage)
        self:setAnimVariable("BandageType", ISHealthPanel.getBandageType(self.bodyPart))
        self.character:reportEvent("EventBandage")
    else
        self:setActionAnim("Loot")
        self.character:SetVariable("LootPosition", "Mid")
        self.character:reportEvent("EventLootItem")
    end
end

function ISDigBulletAction:complete()
    local part = self.bodyPart
    -- bare hands, no doctor XP
    part:setHaveBullet(false, 0)
    -- the hole becomes a deep wound, and a botched dig makes it nastier
    part:generateDeepWound()
    part:setDeepWoundTime(part:getDeepWoundTime() + EM_Sandbox_Get("DigBulletSeverity"))
    -- bleeding caused or worsened
    part:setBleeding(true)
    part:setBleedingTime(part:getBleedingTime() + EM_Sandbox_Get("DigBulletBleeding"))
    -- a local wound infection is caused or worsened (NOT the Knox virus)
    part:setInfectedWound(true)
    part:setWoundInfectionLevel(part:getWoundInfectionLevel() + EM_Sandbox_Get("DigBulletInfection"))
    part:setAdditionalPain(math.min(part:getAdditionalPain() + EM_Sandbox_Get("DigBulletPain"), 100.0))
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
    return true
end

function ISDigBulletAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 150
end

function ISDigBulletAction:new(character, patient, bodyPart)
    local o = ISBaseTimedAction.new(self, character)
    o.patient = patient
    o.bodyPart = bodyPart
    o.stopOnWalk = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.stopOnRun = true
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.maxTime = o:getDuration()
    return o
end
