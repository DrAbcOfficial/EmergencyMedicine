-- Cut a FRESH bite out with a blade (sharp knife / broken glass) before
-- the Knox virus establishes: the bite and its infection flag are
-- excised and replaced by a deep wound at MAX bleeding and MAX pain;
-- broken glass additionally embeds shards (vanilla haveGlass, removable
-- through the vanilla health panel). Eligibility lives in
-- EMCutBite_IsEligiblePart: fresh bite (EM_CUTBITE_FRESH_BITETIME), not
-- bandaged, no other deep wound on the part. The blade is reusable.
--
-- MP: server-authoritative -- applyTreatment sends the client command
-- (with the glass payload) and the server applies the shared op;
-- singleplayer calls it directly.
ISCutBiteAction = EMBodyPartAction:derive("ISCutBiteAction")

function ISCutBiteAction:new(character, patient, tool, bodyPart, useGlass)
    local o = EMBodyPartAction.new(self, character, patient, bodyPart, tool, {
        duration = 200,
        jobKey = "IGUI_health_CutBite",
        treatmentCommand = "CutBite",
    })
    o.useGlass = useGlass
    return o
end

function ISCutBiteAction:isEligible()
    return EMCutBite_IsEligiblePart(self.bodyPart)
end

function ISCutBiteAction:applyTreatment()
    if isClient() then
        self:sendTreatmentCommand({ glass = self.useGlass == true })
    else
        EMTreatment_CutBite(self.patient, self.bodyPart, self.useGlass == true)
    end
end
