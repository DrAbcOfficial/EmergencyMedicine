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
require "TimedActions/ISBaseTimedAction"

ISRemoveScabAction = ISBaseTimedAction:derive("ISRemoveScabAction")

local REMOVE_SCAB_PAIN_OPTION = "RemoveScabPain"
-- scratchTime sandbox option per scab age level (see EM_Wound_GetLevel default)
local SCAB_SCRATCH_OPTION = { [4] = "ScabScratchSevere", [3] = "ScabScratchModerate", [2] = "ScabScratchLight", [1] = "ScabScratchOld" }

function EMRemoveScab_IsEligiblePart(patient, part)
    if patient == nil or part == nil then
        return false
    end
    return EM_Wound_Has(patient, part, "Cauterized")
end

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
    local part = self.bodyPart
    -- read the scab age BEFORE taking the state off
    local level = EM_Wound_GetLevel(self.patient, part, "Cauterized")
    -- scab state off: the pain floor in BodyWoundSimulation stops on its own
    EM_Wound_Remove(self.patient, part, "Cauterized")
    -- the vanilla flag goes too, so the fresh scratch can be re-cauterized
    part:SetCauterized(false)
    -- forceNoInfection = true: picking a scab must never roll the Knox virus
    part:setScratched(true, true)
    part:setScratchTime(EM_Sandbox_Get(SCAB_SCRATCH_OPTION[level] or "ScabScratchModerate"))
    part:setAdditionalPain(math.min(part:getAdditionalPain() + EM_Sandbox_Get(REMOVE_SCAB_PAIN_OPTION), 100.0))
    syncBodyPart(part, EM_BODYWOUND_SYNC_FLAGS)
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
