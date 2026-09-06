-- Vanilla painkiller flow: right-click "Take" -> ISTakePillAction (cast/
-- progress) -> complete(). We hook complete() to consume one unit and
-- apply the matching drug effect, exactly like the vanilla pills do in
-- Java. The handler table holds function values; the drug files in this
-- folder load before this one (alphabetical file order), so the globals
-- are defined by the time this file runs.
local DRUG_EFFECTS = {
    ["EmergencyMedical.morphine"] = InjectMorphine,
    ["EmergencyMedical.naloxone"] = InjectNaloxone,
    ["EmergencyMedical.fentanyl"] = InjectFentanyl,
    ["EmergencyMedical.oxycontin"] = TakeOxyContin,
}

if ISTakePillAction then
    local ISTakePillAction_complete = ISTakePillAction.complete
    function ISTakePillAction.complete(self)
        local ret = ISTakePillAction_complete(self)
        local item = self.item
        if item then
            local handler = DRUG_EFFECTS[item:getFullType()]
            if handler ~= nil then
                local container = item:getContainer()
                if container and container:contains(item) then
                    container:RemoveOneOf(item:getType())
                end
                handler(self.character)
            end
        end
        return ret
    end
end
