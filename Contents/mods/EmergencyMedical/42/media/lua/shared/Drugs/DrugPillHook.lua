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
local DRUG_EFFECTS = {
    ["EmergencyMedical.morphine"] = InjectMorphine,
    ["EmergencyMedical.naloxone"] = InjectNaloxone,
    ["EmergencyMedical.fentanyl"] = InjectFentanyl,
    ["EmergencyMedical.oxycontin"] = TakeOxyContin,
    -- DrugSufentanil.lua sorts AFTER this file (S > P), so its global
    -- does not exist yet at load time: resolve lazily at dispatch.
    ["EmergencyMedical.sufentanil"] = function(player) return TakeSufentanil(player) end,
}

if ISTakePillAction then
    local ISTakePillAction_complete = ISTakePillAction.complete
    function ISTakePillAction.complete(self)
        local ret = ISTakePillAction_complete(self)
        local item = self.item
        if item then
            local handler = DRUG_EFFECTS[item:getFullType()]
            if handler ~= nil then
                handler(self.character)
            end
        end
        return ret
    end
end
