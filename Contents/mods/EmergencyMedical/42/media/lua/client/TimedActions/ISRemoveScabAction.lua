-- Remove a cauterized scab with a scalpel: the scab state is taken off
-- the part and replaced by a scratch whose severity follows the scab's
-- AGE (via EM_Wound_GetLevel's default quartiles, 4 = freshest):
--   level 4 -> scratchTime 18  (panel shows "Severe" at >17)
--   level 3 -> scratchTime 15  (panel shows "Moderate" at >14)
--   level 2 -> scratchTime 8
--   level 1 -> scratchTime 3   (old scar, barely more than a graze)
-- setScratched(true, true) forces NO zombie-infection roll; the fresh
-- scratch re-enables cauterization on the part (the vanilla IsCauterized
-- flag is cleared here, vanilla would clear it on the next wound anyway).
-- Signature mirrors ISCauterizeAction: character = doctor, patient =
-- the treated player (same object for self-treatment).
--
-- MP: server-authoritative like every treatment -- complete() sends a
-- client command and the server applies it (server/EmergencyMedical_
-- ClientCommands.lua); singleplayer calls the shared op directly. The
-- scratchTime mapping lives in shared/Wound/TreatmentOps.lua.
require "TimedActions/ISBaseTimedAction"

ISRemoveScabAction = ISBaseTimedAction:derive("ISRemoveScabAction")

-- EMRemoveScab_IsEligiblePart lives in shared/Wound/TreatmentOps.lua

function ISRemoveScabAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if not EMRemoveScab_IsEligiblePart(self.patient, self.bodyPart) then
        return false
    end
    if isClient() then
        return self.character:getInventory():containsID(self.tool:getID())
    end
    return self.character:getInventory():contains(self.tool)
end

function ISRemoveScabAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function ISRemoveScabAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    self.tool:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISRemoveScabAction:start()
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
    self.tool:setJobType(getText("IGUI_health_RemoveScab"))
    self.tool:setJobDelta(0.0)
end

function ISRemoveScabAction:stop()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function ISRemoveScabAction:perform()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.perform(self)
end

function ISRemoveScabAction:complete()
    if isClient() then
        sendClientCommand(self.character, "EmergencyMedical", "RemoveScab", {
            id = self.patient:getOnlineID(),
            part = self.bodyPart:getIndex(),
        })
    else
        EMTreatment_RemoveScab(self.patient, self.bodyPart)
    end
    return true
end

function ISRemoveScabAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 120
end

function ISRemoveScabAction:new(character, patient, tool, bodyPart)
    local o = ISBaseTimedAction.new(self, character)
    o.patient = patient
    o.tool = tool
    o.bodyPart = bodyPart
    o.stopOnWalk = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.stopOnRun = true
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.maxTime = o:getDuration()
    return o
end
