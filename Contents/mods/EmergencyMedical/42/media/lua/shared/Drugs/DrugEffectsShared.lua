-- Shared helpers for the drug effect functions (DrugMorphine.lua,
-- DrugNaloxone.lua, ...). Global EMDrug_* namespace because these cross
-- file boundaries; drug files call them at runtime.
--
-- Vanilla reference for the painkiller state: IsoGameCharacter.PainMeds
-- (potency) is exactly what the vanilla painkiller pill runs
-- (BodyDamage.JustTookPill calls it with 0.15 per dose). It starts a
-- 5400-second timer during which the PAIN stat drains constantly
-- (0.0233/tick) and pain stops feeding back into the health
-- calculations. potency 1.0 = the full-strength state.
--
-- BOREDOM / UNHAPPINESS / PANIC are CharacterStats in 0..100; addiction
-- values are the mod's 0..1 scale (see Status/Opioid/OpioidAddiction.lua).

function EMDrug_HealToFull(player)
    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getHealth() < EM_CONST.HEALTH_MAX then
        local parts = bodyDamage:getBodyParts()
        for i = 0, parts:size() - 1 do
            local part = parts:get(i)
            local gap = 100 - part:getHealth()
            if gap > 0 then
                part:AddHealth(gap)
            end
        end
    end
end

function EMDrug_FullPainkiller(player)
    player:PainMeds(1.0)
end

function EMDrug_ClearMind(player)
    local stats = player:getStats()
    stats:set(CharacterStat.BOREDOM, 0.0)
    stats:set(CharacterStat.UNHAPPINESS, 0.0)
    stats:set(CharacterStat.PANIC, 0.0)
end

function EMDrug_HalveMind(player)
    local stats = player:getStats()
    stats:set(CharacterStat.BOREDOM, stats:get(CharacterStat.BOREDOM) * 0.5)
    stats:set(CharacterStat.UNHAPPINESS, stats:get(CharacterStat.UNHAPPINESS) * 0.5)
    stats:set(CharacterStat.PANIC, stats:get(CharacterStat.PANIC) * 0.5)
end

-- Direct addiction change from a drug (naloxone/fentanyl/oxycontin).
-- The morphine path goes through EM_Addiction_UseInjection instead.
function EMDrug_ChangeAddiction(player, amount)
    EM_Addiction_Set(player, EM_Addiction_Get(player) + amount)
    -- MP: effects run on the server (TakeDrug command) -> broadcast;
    -- a client may only push its own player's table up (SP needs none)
    EM_Dependence_Transmit(player)
end

-- head part helper (head pain is the shared side effect of three drugs)
function EMDrug_GetHeadPart(player)
    return player:getBodyDamage():getBodyParts():get(BodyPartType.ToIndex(BodyPartType.Head))
end

-- the shared head-pain side effect: each drug passes its own amount
-- (moderate 30 / severe 70 live as locals in the drug files)
function EMDrug_HeadPain(player, amount)
    local head = EMDrug_GetHeadPart(player)
    head:setAdditionalPain(math.min(head:getAdditionalPain() + amount, EM_CONST.PAIN_MAX))
end

-- stop every part's bleeding (tranexamic acid). Glass shards keep the
-- vanilla floor trickling (DamageUpdate re-raises bleedingTime to 3
-- while haveGlass) -- shards still in, still oozing.
function EMDrug_StopAllBleeding(player)
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if part:bleeding() or part:getBleedingTime() > 0.0 then
            part:setBleeding(false)
            part:setBleedingTime(0.0)
        end
    end
end

-- clear the LOCAL wound infection on every part (sulfadimidine) -- NOT
-- the Knox virus (IsInfected is deliberately not touched)
function EMDrug_ClearWoundInfection(player)
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if part:isInfectedWound() or part:getWoundInfectionLevel() > 0.0 then
            part:setInfectedWound(false)
            part:setWoundInfectionLevel(0.0)
        end
    end
end

-- wipe every VANILLA wound from every part: scratches, cuts, bites,
-- deep wounds, burns, fractures, bleeding, local wound infections and
-- the vanilla cauterized flag. The Knox virus (IsInfected) is NOT a
-- wound and is deliberately untouched; so are bullets and glass shards
-- (foreign objects with their own vanilla removal flows).
function EMDrug_ClearAllWounds(player)
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        part:setScratched(false, true)
        part:setCut(false)
        part:SetBitten(false, false)
        part:setScratchTime(0.0)
        part:setCutTime(0.0)
        part:setBiteTime(0.0)
        part:setDeepWounded(false)
        part:setDeepWoundTime(0.0)
        part:setFractureTime(0.0)
        part:setBleeding(false)
        part:setBleedingTime(0.0)
        part:setBurnTime(0.0)
        part:setInfectedWound(false)
        part:setWoundInfectionLevel(0.0)
        part:SetCauterized(false)
    end
end

-- remove every CUSTOM wound state (EM_Wound_*) from every part -- the
-- cauterized scab, crude stitching, improvised fixation, fentanyl patch
-- ...
function EMDrug_ClearAllCustomWounds(player)
    for id in pairs(EM_Wound_GetRegisteredTypes()) do
        EM_Wound_RemoveAllOf(player, id)
    end
end
