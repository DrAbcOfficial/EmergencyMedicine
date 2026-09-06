-- Grass bandage hook: applying an EmergencyMedical.GrassBandage
-- GUARANTEES a local wound infection on the treated part (crude grass on
-- an open wound -- NOT the Knox virus). Vanilla ISApplyBandage.complete
-- consumes the bandage and sets the bandage state; afterwards the
-- infection is applied -- on the server in MP via a client command
-- (body damage is server-authoritative), directly in SP.
--
-- ISApplyBandage fields used: item (the bandage), otherPlayer (the
-- patient; same as character for self-treatment), bodyPart.
if ISApplyBandage then
    local ISApplyBandage_complete = ISApplyBandage.complete
    function ISApplyBandage.complete(self)
        local ret = ISApplyBandage_complete(self)
        local item = self.item
        if item ~= nil and item:getFullType() == "EmergencyMedical.GrassBandage" then
            local patient = self.otherPlayer or self.character
            if isClient() then
                sendClientCommand(self.character, "EmergencyMedical", "InfectWound", {
                    id = patient:getOnlineID(),
                    part = self.bodyPart:getIndex(),
                })
            else
                EMTreatment_InfectWound(patient, self.bodyPart)
            end
        end
        return ret
    end
end
