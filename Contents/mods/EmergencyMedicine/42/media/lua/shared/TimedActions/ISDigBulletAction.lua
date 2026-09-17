-- Dig a bullet out with BARE HANDS: the risky, tool-less alternative to
-- the vanilla tweezer removal. Digging always leaves a deep wound and
-- makes things worse across the board (all sandbox-configurable):
--   - the bullet comes out (setHaveBullet(false, 0) -- no doctor XP)
--   - generateDeepWound() + "DigBulletSeverity" extra deepWoundTime
--   - bleeding is caused or worsened ("DigBulletBleeding" extra time)
--   - a local wound infection is caused or worsened
--   ("DigBulletInfection" level bump -- NOT the Knox virus)
--   - "DigBulletPain" extra pain
--
-- MP: complete() runs on the server (see EMBodyPartAction.lua), which
-- applies the shared op directly; singleplayer runs the same code on
-- the local process.
ISDigBulletAction = EMBodyPartAction:derive("ISDigBulletAction")

function ISDigBulletAction:new(character, patient, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, nil, {
        duration = 150,
    })
end

function ISDigBulletAction:isEligible()
    return self.bodyPart:haveBullet()
end

function ISDigBulletAction:applyTreatment()
    EMTreatment_DigBullet(self.patient, self.bodyPart)
end
