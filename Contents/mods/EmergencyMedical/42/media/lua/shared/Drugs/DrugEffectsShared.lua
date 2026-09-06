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
-- values are the mod's 0..1 scale (see Opioid/OpioidAddiction.lua).

function EMDrug_HealToFull(player)
    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getHealth() < 100 then
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
    if isServer() then
        player:transmitModData()
    elseif isClient() and player:isLocalPlayer() then
        player:transmitModData()
    end
end
