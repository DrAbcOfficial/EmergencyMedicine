-- Grass bandage hook: applying an EmergencyMedicine.GrassBandage
-- GUARANTEES a local wound infection on the treated part (crude grass on
-- an open wound -- NOT the Knox virus), and REMOVING one destroys the
-- bandage instead of returning it (vanilla ISApplyBandage.complete
-- re-creates the stored bandage type into the inventory on removal --
-- the grass bandage is consumed like the Bandaid, so it is deleted
-- again). Infection: EMTreatment_InfectWound runs wherever complete()
-- runs -- in MP that is the SERVER (B42 rebuilds the shared
-- ISApplyBandage class there and executes its complete()), in SP the
-- local process; body damage is authoritative on both.
--
-- ISApplyBandage fields used: item (the bandage; nil when removing),
-- doIt (true = apply, false = remove), otherPlayer (the patient; same
-- as character for self-treatment), bodyPart.
if ISApplyBandage then
    local ISApplyBandage_complete = ISApplyBandage.complete
    function ISApplyBandage.complete(self)
        -- capture the stored bandage type BEFORE vanilla clears it
        local removingGrassBandage = self.doIt == false
            and self.bodyPart ~= nil
            and self.bodyPart:getBandageType() == "EmergencyMedicine.GrassBandage"
        local ret = ISApplyBandage_complete(self)
        local item = self.item
        if item ~= nil and item:getFullType() == "EmergencyMedicine.GrassBandage" then
            -- application: guaranteed wound infection
            local patient = self.otherPlayer or self.character
            EMTreatment_InfectWound(patient, self.bodyPart)
        elseif removingGrassBandage then
            -- removal: vanilla returned a fresh GrassBandage into the
            -- inventory -- delete it again
            local inv = self.character:getInventory()
            local items = inv:getItems()
            for i = items:size() - 1, 0, -1 do
                local it = items:get(i)
                if it:getFullType() == "EmergencyMedicine.GrassBandage" then
                    inv:Remove(it)
                    break
                end
            end
        end
        return ret
    end
end
