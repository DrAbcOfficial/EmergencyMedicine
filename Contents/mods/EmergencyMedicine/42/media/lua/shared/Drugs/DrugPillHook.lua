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
-- MP: B42 executes Lua timed actions on the SERVER (the net timed
-- action rebuilds ISTakePillAction there; the client's own Lua
-- complete() is skipped entirely) -- this hook therefore runs on the
-- server and EMDrug_ApplyEffect applies directly where body damage /
-- stats / modData are authoritative; the vanilla syncDamage/syncStats
-- pushes carry the results back to the taker, and the modData transmits
-- inside the effects broadcast from the server. Singleplayer runs the
-- same code on the local process. The dispatch table doubles as the
-- whitelist on both sides: EMDrug_ApplyEffect only knows this mod's own
-- ten fullTypes.
local DRUG_EFFECTS = {
    ["EmergencyMedicine.morphine"] = InjectMorphine,
    ["EmergencyMedicine.naloxone"] = InjectNaloxone,
    ["EmergencyMedicine.fentanyl"] = InjectFentanyl,
    ["EmergencyMedicine.methamphetamine"] = TakeMethamphetamine,
    ["EmergencyMedicine.oxycontin"] = TakeOxyContin,
    ["EmergencyMedicine.dexmedetomidine"] = TakeDexmedetomidine,
    ["EmergencyMedicine.dextromethorphan"] = TakeDextromethorphan,
    -- DrugSufentanil.lua sorts AFTER this file (S > P), so its global
    -- does not exist yet at load time: resolve lazily at dispatch.
    ["EmergencyMedicine.sufentanil"] = function(player) return TakeSufentanil(player) end,
    ["EmergencyMedicine.sulfadimidine"] = function(player) return TakeSulfadimidine(player) end,
    ["EmergencyMedicine.tranexamicacid"] = function(player) return TakeTranexamicAcid(player) end,
}

-- One dispatch entry point for every path (pill hook here, the
-- auto-injector watch on the server, debug) so all of them run exactly
-- this table.
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
                EMDrug_ApplyEffect(self.character, fullType)
                -- ampoule drugs play the injection sound at the moment the
                -- needle goes in. In SP complete() runs on the taker's own
                -- process and the local-only playSound reaches exactly the
                -- user; in MP complete() runs on the SERVER, whose
                -- playSound is a silent dummy emitter -- echo a server
                -- command so the taker's client plays it locally
                -- (AutoInjectSound pattern)
                if EM_INJECT_AMPOULE_DRUGS[fullType] then
                    if isServer() then
                        sendServerCommand(self.character, "EmergencyMedicine", "InjectSound", {})
                    else
                        EM_Inject_PlaySound(self.character)
                    end
                end
            end
        end
        return ret
    end
end
