-- Vanilla painkiller flow: right-click "Take" -> ISTakePillAction (cast/
-- progress) -> complete(). We hook complete() to apply the matching drug
-- effect. Consumption is NOT done here: ISTakePillAction:complete calls
-- BodyDamage:JustTookPill(item), which ends in pill.UseAndSync() -- that
-- drains one UseDelta per take and auto-removes the item when empty
-- (script disappearOnUse defaults to true). Removing the item here as
-- well would double-consume when carrying several units.
-- The handler table holds function values; the drug files in this folder
-- load before this one (alphabetical file order), so the globals are
-- defined by the time this file runs.
--
-- MP: body damage / stats / modData are server-authoritative, so the
-- effect runs ON THE SERVER via a client command ("TakeDrug"); the
-- vanilla syncDamage/syncStats pushes carry the results back to the
-- taker, and the modData transmits inside the effects broadcast from the
-- server. Singleplayer applies directly. The dispatch table doubles as
-- the whitelist on both sides: EMDrug_ApplyEffect only knows this mod's
-- own ten fullTypes.
local DRUG_EFFECTS = {
    ["EmergencyMedical.morphine"] = InjectMorphine,
    ["EmergencyMedical.naloxone"] = InjectNaloxone,
    ["EmergencyMedical.fentanyl"] = InjectFentanyl,
    ["EmergencyMedical.methamphetamine"] = TakeMethamphetamine,
    ["EmergencyMedical.oxycontin"] = TakeOxyContin,
    ["EmergencyMedical.dexmedetomidine"] = TakeDexmedetomidine,
    ["EmergencyMedical.dextromethorphan"] = TakeDextromethorphan,
    -- DrugSufentanil.lua sorts AFTER this file (S > P), so its global
    -- does not exist yet at load time: resolve lazily at dispatch.
    ["EmergencyMedical.sufentanil"] = function(player) return TakeSufentanil(player) end,
    ["EmergencyMedical.sulfadimidine"] = function(player) return TakeSulfadimidine(player) end,
    ["EmergencyMedical.tranexamicacid"] = function(player) return TakeTranexamicAcid(player) end,
}

-- One dispatch entry point so SP (direct call) and MP (server command
-- handler) run exactly this table.
function EMDrug_ApplyEffect(player, fullType)
    local handler = DRUG_EFFECTS[fullType]
    if handler ~= nil then
        handler(player)
    end
end

if ISTakePillAction then
    local ISTakePillAction_complete = ISTakePillAction.complete
    function ISTakePillAction.complete(self)
        local ret = ISTakePillAction_complete(self)
        local item = self.item
        if item then
            local fullType = item:getFullType()
            if DRUG_EFFECTS[fullType] ~= nil then
                if isClient() then
                    sendClientCommand(self.character, "EmergencyMedical", "TakeDrug", {
                        drug = fullType,
                    })
                else
                    EMDrug_ApplyEffect(self.character, fullType)
                end
            end
        end
        return ret
    end
end
