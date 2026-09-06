-- Cut a FRESH bite out with a blade (sharp knife / broken glass) before
-- the Knox virus establishes: the bite and its infection flag are
-- excised and replaced by a deep wound at MAX bleeding and MAX pain;
-- broken glass additionally embeds shards (vanilla haveGlass, removable
-- through the vanilla health panel). Eligibility lives in
-- EMCutBite_IsEligiblePart (shared/Wound/TreatmentOps.lua): fresh bite
-- (EM_CUTBITE_FRESH_BITETIME), not bandaged, no other deep wound on the
-- part. Signature mirrors the other body-part actions (character =
-- doctor, patient = treated player; useGlass selects the glass result).
--
-- MP: server-authoritative like every treatment -- complete() sends a
-- client command and the server applies it; singleplayer calls the
-- shared op directly.
require "TimedActions/ISBaseTimedAction"

ISCutBiteAction = ISBaseTimedAction:derive("ISCutBiteAction")

function ISCutBiteAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if not EMCutBite_IsEligiblePart(self.bodyPart) then
        return false
    end
    if isClient() then
        return self.character:getInventory():containsID(self.tool:getID())
    end
    return self.character:getInventory():contains(self.tool)
end

function ISCutBiteAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISCutBiteAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.tool:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISCutBiteAction:start()
    if isClient() then
        self.tool = self.character:getInventory():getItemById(self.tool:getID())
    end
    if self.character == self.patient then
        self:setActionAnim(CharacterActionAnims.Bandage)
        self:setAnimVariable("BandageType", ISHealthPanel.getBandageType(self.bodyPart))
        self.character:reportEvent("EventBandage")
    else
        self:setActionAnim("Loot")
        self.character:SetVariable("LootPosition", "Mid")
        self.character:reportEvent("EventLootItem")
    end
    self:setOverrideHandModels(nil, self.tool)
    self.tool:setJobType(getText("IGUI_health_CutBite"))
    self.tool:setJobDelta(0.0)
end

function ISCutBiteAction:stop()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function ISCutBiteAction:perform()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.perform(self)
end

function ISCutBiteAction:complete()
    if isClient() then
        sendClientCommand(self.character, "EmergencyMedical", "CutBite", {
            id = self.patient:getOnlineID(),
            part = self.bodyPart:getIndex(),
            glass = self.useGlass == true,
        })
    else
        EMTreatment_CutBite(self.patient, self.bodyPart, self.useGlass == true)
    end
    return true
end

function ISCutBiteAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 200
end

function ISCutBiteAction:new(character, patient, tool, bodyPart, useGlass)
    local o = ISBaseTimedAction.new(self, character)
    o.patient = patient
    o.tool = tool
    o.bodyPart = bodyPart
    o.useGlass = useGlass
    o.stopOnWalk = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.stopOnRun = true
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.maxTime = o:getDuration()
    return o
end
