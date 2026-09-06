-- Ampoule drugs (morphine / naloxone / fentanyl) play the bandage
-- animation for the head/neck instead of the pill-taking animation: the
-- vanilla self-bandage flow (ISApplyBandage.lua:start) does
--   setActionAnim(CharacterActionAnims.Bandage)
--   setAnimVariable("BandageType", ISHealthPanel.getBandageType(part))
--   reportEvent("EventBandage")
-- and getBandageType maps both Head and Neck body parts to "Head", so
-- BandageType "Head" IS the neck-wrapping animation. OxyContin (pills)
-- keeps the normal pill animation.
--
-- ISTakePillAction re-asserts its own action animation from update()
-- every frame (TakePills/Eat), so the override has to happen there too;
-- the EventBandage event fires once from start(). Vanilla keeps holding
-- the item in the off-hand (setOverrideHandModels in start) -- kept.
local AMPOULE_DRUGS = {
    ["EmergencyMedical.morphine"] = true,
    ["EmergencyMedical.naloxone"] = true,
    ["EmergencyMedical.fentanyl"] = true,
}

if ISTakePillAction then
    local ISTakePillAction_start = ISTakePillAction.start
    local ISTakePillAction_update = ISTakePillAction.update

    function ISTakePillAction:start()
        ISTakePillAction_start(self)
        if self.item and AMPOULE_DRUGS[self.item:getFullType()] then
            self:setActionAnim(CharacterActionAnims.Bandage)
            self:setAnimVariable("BandageType", "Head")
            self.character:reportEvent("EventBandage")
        end
    end

    function ISTakePillAction:update()
        ISTakePillAction_update(self)
        if self.item and AMPOULE_DRUGS[self.item:getFullType()] then
            self:setActionAnim(CharacterActionAnims.Bandage)
            self:setAnimVariable("BandageType", "Head")
        end
    end
end
