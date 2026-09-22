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
    ["EmergencyMedicine.morphine"] = "Head",
    ["EmergencyMedicine.naloxone"] = "Head",
    ["EmergencyMedicine.fentanyl"] = "Head",
    ["EmergencyMedicine.dexmedetomidine"] = "Head",
    ["EmergencyMedicine.sufentanil"] = "RightArm",
}

-- the injection sound (GameSound registered in media/scripts/drugs_sounds.txt)
-- and the ampoule set that plays it when taken / auto-injected. B42 plays
-- file clips through GameSound script blocks (the old .snd scripts are
-- gone); the name GameSounds registers is the bare sound name, no module
-- prefix. playSoundLocal is the "user only" guarantee: it routes through
-- playSoundImpl, which is pure local FMOD with no network path (vanilla
-- map UI uses it the same way). Plain playSound is NOT local on a client --
-- FMODSoundEmitter.playSound sends a PlaySound packet under GameClient.client
-- and the server relays it to every nearby player (PlaySoundPacket.processServer).
EM_INJECT_SOUND = "EM_Inject"

EM_INJECT_AMPOULE_DRUGS = {
    ["EmergencyMedicine.morphine"] = true,
    ["EmergencyMedicine.naloxone"] = true,
    ["EmergencyMedicine.fentanyl"] = true,
    ["EmergencyMedicine.dexmedetomidine"] = true,
}

function EM_Inject_PlaySound(player)
    if player ~= nil and not isServer() then
        player:playSoundLocal(EM_INJECT_SOUND)
    end
end

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
