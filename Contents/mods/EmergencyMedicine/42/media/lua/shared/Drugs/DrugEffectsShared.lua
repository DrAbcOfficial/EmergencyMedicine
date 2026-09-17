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

-- the two drug-status peaks, shared by the dosing drugs (tranexamic
-- acid / sulfadimidine) AND the severe amphetamine withdrawal
-- accumulation (AmphetamineSimulation.lua) -- DrugEffectSimulation
-- scales them by status progress x DrugStatusDebuffRate
EM_DRUG_HEADACHE_PAIN_FLOOR = 12.0
EM_DRUG_FEVER_TEMPERATURE = 38.5

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
    -- MP: effects run on the server (the ISTakePillAction complete is
    -- server-executed, see DrugPillHook) -> broadcast;
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

-- nausea stat: B42 moved food poisoning to CharacterStat.FOOD_SICKNESS
-- (0..100, decays on its own, drives the Sick moodle)
function EMDrug_AddFoodSickness(player, amount)
    player:getStats():add(CharacterStat.FOOD_SICKNESS, amount)
end

-- pile a removed bleed/infection amount onto the part's dominant
-- (largest) existing wound time, capped -- a proportional
-- hemostasis/antibiosis dose shows up as a heavier wound instead of a
-- free fix. Fracture/stitch times are deliberately not targets; a part
-- without any wound time skips the transfer (nothing to worsen).
function EMDrug_TransferWoundSeverity(part, amount)
    if amount <= 0.0 then
        return
    end
    local dominant, maxTime = nil, 0.0
    local scratch, cut = part:getScratchTime(), part:getCutTime()
    local bite, deep, burn = part:getBiteTime(), part:getDeepWoundTime(), part:getBurnTime()
    if scratch > maxTime then
        dominant, maxTime = "scratch", scratch
    end
    if cut > maxTime then
        dominant, maxTime = "cut", cut
    end
    if bite > maxTime then
        dominant, maxTime = "bite", bite
    end
    if deep > maxTime then
        dominant, maxTime = "deep", deep
    end
    if burn > maxTime then
        dominant, maxTime = "burn", burn
    end
    if dominant == nil then
        return
    end
    local newTime = math.min(maxTime + amount, EM_CONST.WOUND_TIME_MAX)
    if dominant == "scratch" then
        part:setScratchTime(newTime)
    elseif dominant == "cut" then
        part:setCutTime(newTime)
    elseif dominant == "bite" then
        part:setBiteTime(newTime)
    elseif dominant == "deep" then
        part:setDeepWoundTime(newTime)
    else
        part:setBurnTime(newTime)
    end
end

-- proportional hemostasis (tranexamic acid): clots the given share of
-- every part's bleedingTime per dose, piling the removed amount 1:1
-- onto the part's dominant wound time. Glass-shard parts are skipped
-- outright: DamageUpdate keeps re-raising their bleeding floor, so the
-- reduction wouldn't stick while the severity transfer would -- repeat
-- dosing would farm wound severity for nothing.
function EMDrug_StopBleedingProportional(player, ratio)
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        local bleedingTime = part:getBleedingTime()
        if not part:haveGlass() and bleedingTime > 0.0 then
            local removed = bleedingTime * ratio
            part:setBleedingTime(bleedingTime - removed)
            EMDrug_TransferWoundSeverity(part, removed)
        end
    end
end

-- proportional antibiosis (sulfadimidine): clears the given share of
-- every part's LOCAL wound infection per dose (NOT the Knox virus),
-- piling the removed amount x transferFactor onto the dominant wound
-- time -- a heavy infection heals into a heavy wound. Remainders at or
-- under MIN_WOUND_INFECTION snap clean so repeated doses converge.
local MIN_WOUND_INFECTION = 1.0

function EMDrug_ClearWoundInfectionProportional(player, ratio, transferFactor)
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        local level = part:getWoundInfectionLevel()
        if level > 0.0 then
            local removed = level * ratio
            local newLevel = level - removed
            if newLevel <= MIN_WOUND_INFECTION then
                part:setInfectedWound(false)
                part:setWoundInfectionLevel(0.0)
            else
                part:setWoundInfectionLevel(newLevel)
            end
            EMDrug_TransferWoundSeverity(part, removed * transferFactor)
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
