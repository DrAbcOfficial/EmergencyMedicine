-- Remove a cauterized scab with a scalpel (reusable): the scab state is
-- taken off and replaced by a scratch whose severity follows the scab's
-- AGE (EM_Wound_GetLevel quartiles -> EMTreatment_RemoveScab's mapping:
-- level 4 = 18, panel "Severe" at >17 / 3 = 15 "Moderate" >14 / 2 = 8 /
-- 1 = 3). setScratched(true, true) forces NO zombie-infection roll; the
-- cleared IsCauterized flag re-enables cauterization on the part.
--
-- MP: server-authoritative -- applyTreatment sends the client command
-- and the server applies the shared op; singleplayer calls it directly.
ISRemoveScabAction = EMBodyPartAction:derive("ISRemoveScabAction")

function ISRemoveScabAction:new(character, patient, tool, bodyPart)
    return EMBodyPartAction.new(self, character, patient, bodyPart, tool, {
        duration = 120,
        jobKey = "IGUI_health_RemoveScab",
        treatmentCommand = "RemoveScab",
    })
end

function ISRemoveScabAction:isEligible()
    return EMRemoveScab_IsEligiblePart(self.patient, self.bodyPart)
end

function ISRemoveScabAction:applyTreatment()
    if isClient() then
        self:sendTreatmentCommand()
    else
        EMTreatment_RemoveScab(self.patient, self.bodyPart)
    end
end
