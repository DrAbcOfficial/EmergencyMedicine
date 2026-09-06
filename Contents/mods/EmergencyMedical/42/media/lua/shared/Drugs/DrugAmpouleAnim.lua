-- Ampoule drugs (morphine / naloxone / fentanyl / dexmedetomidine) play
-- the bandage animation for the head/neck instead of the pill-taking
-- animation: the vanilla self-bandage flow (ISApplyBandage.lua:start) does
--   setActionAnim(CharacterActionAnims.Bandage)
--   setAnimVariable("BandageType", ISHealthPanel.getBandageType(part))
--   reportEvent("EventBandage")
-- and getBandageType maps both Head and Neck body parts to "Head", so
-- BandageType "Head" IS the neck-wrapping animation. OxyContin (pills)
-- keeps the normal pill animation. Sufentanil plays the RIGHT UPPER ARM
-- bandage animation (the patch is applied there).
--
-- ISTakePillAction re-asserts its own action animation from update()
-- every frame (TakePills/Eat), so the override has to happen there too;
-- the EventBandage event fires once from start(). Vanilla keeps holding
-- the item in the off-hand (setOverrideHandModels in start) -- kept.
local PILL_BANDAGE_ANIM = {
    ["EmergencyMedical.morphine"] = "Head",
    ["EmergencyMedical.naloxone"] = "Head",
    ["EmergencyMedical.fentanyl"] = "Head",
    ["EmergencyMedical.dexmedetomidine"] = "Head",
    ["EmergencyMedical.sufentanil"] = "RightArm",
}

if ISTakePillAction then
    local ISTakePillAction_start = ISTakePillAction.start
    local ISTakePillAction_update = ISTakePillAction.update

    function ISTakePillAction:start()
        ISTakePillAction_start(self)
        local bandageType = self.item and PILL_BANDAGE_ANIM[self.item:getFullType()]
        if bandageType then
            self:setActionAnim(CharacterActionAnims.Bandage)
            self:setAnimVariable("BandageType", bandageType)
            self.character:reportEvent("EventBandage")
        end
    end

    function ISTakePillAction:update()
        ISTakePillAction_update(self)
        local bandageType = self.item and PILL_BANDAGE_ANIM[self.item:getFullType()]
        if bandageType then
            self:setActionAnim(CharacterActionAnims.Bandage)
            self:setAnimVariable("BandageType", bandageType)
        end
    end
end
