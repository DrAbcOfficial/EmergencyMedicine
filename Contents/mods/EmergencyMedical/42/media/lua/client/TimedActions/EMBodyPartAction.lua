-- Base class for the health-panel body-part timed actions. Every EM
-- treatment action shares the same body: patient-move guard, the part
-- eligibility hook, the bandage (self-treatment) / loot (treating
-- someone else) animation pair, the tool job bar, the instant-check
-- duration and the server-authoritative treatment dispatch. Subclasses
-- only declare what differs:
--
--   local Action = EMBodyPartAction:derive("ISMyAction")
--
--   function Action:new(character, patient, tool, bodyPart)
--       return EMBodyPartAction.new(self, character, patient, bodyPart,
--           tool, {
--               duration = 150,                      -- ticks (or override getDuration)
--               jobKey = "IGUI_health_MyAction",     -- tool job bar text
--               treatmentCommand = "MyAction",       -- MP client command
--               consumeTool = "drainable",           -- or "remove" / nil
--           })
--   end
--
--   function Action:isEligible() ... end       -- part predicate (shared op)
--   function Action:applyTreatment() ... end   -- MP: sendTreatmentCommand()
--                                              -- SP: the shared op directly
--
-- tool: nil for the bare-hand actions -- skips the inventory guard, the
-- hand model override and the job bar. consumeTool: "drainable" burns
-- one use (UseAndSync), "remove" consumes a plain item outright (vanilla
-- ISApplyBandage pattern), nil = reusable tool.
--
-- MP: body damage is server-authoritative -- applyTreatment sends the
-- client command and the server applies the shared op
-- (server/EmergencyMedical_ClientCommands.lua); singleplayer calls the
-- shared op directly.
require "TimedActions/ISBaseTimedAction"

EMBodyPartAction = ISBaseTimedAction:derive("EMBodyPartAction")

function EMBodyPartAction:new(character, patient, bodyPart, tool, config)
    config = config or {}
    local o = ISBaseTimedAction.new(self, character)
    o.patient = patient
    o.bodyPart = bodyPart
    o.tool = tool
    o.duration = config.duration or 150
    o.jobKey = config.jobKey
    o.treatmentCommand = config.treatmentCommand
    o.consumeTool = config.consumeTool
    o.stopOnWalk = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.stopOnRun = true
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.maxTime = o:getDuration()
    return o
end

-- the part predicate; default accepts anything (pure body-part guards
-- like haveBullet are plain overrides)
function EMBodyPartAction:isEligible()
    return true
end

function EMBodyPartAction:isValid()
    if ISHealthPanel.DidPatientMove(self.character, self.patient, self.patientX, self.patientY) then
        return false
    end
    if not self:isEligible() then
        return false
    end
    if self.tool ~= nil then
        if isClient() then
            return self.character:getInventory():containsID(self.tool:getID())
        end
        return self.character:getInventory():contains(self.tool)
    end
    return true
end

function EMBodyPartAction:waitToStart()
    if self.character == self.patient then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function EMBodyPartAction:update()
    if self.character ~= self.patient then
        self.character:faceThisObject(self.patient)
    end
    if self.tool ~= nil then
        self.tool:setJobDelta(self:getJobDelta())
    end
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function EMBodyPartAction:start()
    if self.tool ~= nil and isClient() then
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
    if self.tool ~= nil then
        self:setOverrideHandModels(nil, self.tool)
        self.tool:setJobType(getText(self.jobKey))
        self.tool:setJobDelta(0.0)
    end
end

function EMBodyPartAction:stop()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function EMBodyPartAction:perform()
    if self.tool ~= nil then
        self.tool:setJobDelta(0.0)
    end
    ISBaseTimedAction.perform(self)
end

function EMBodyPartAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return self.duration
end

-- the wire format of every body-part treatment: patient onlineID +
-- part index, plus any action-specific payload
function EMBodyPartAction:sendTreatmentCommand(extra)
    local args = { id = self.patient:getOnlineID(), part = self.bodyPart:getIndex() }
    if extra ~= nil then
        for key, value in pairs(extra) do
            args[key] = value
        end
    end
    sendClientCommand(self.character, "EmergencyMedical", self.treatmentCommand, args)
end

-- default: dispatch the treatment command with no extra payload. The
-- SP branch (the shared op in shared/Wound/TreatmentOps.lua) and any
-- extra payload (CutBite's glass) are per-subclass.
function EMBodyPartAction:applyTreatment()
    if isClient() then
        self:sendTreatmentCommand()
    end
end

function EMBodyPartAction:consumeTool()
    if self.tool == nil then
        return
    end
    if self.consumeTool == "drainable" then
        -- one use of a drainable tool (lighter, glue ...)
        if self.tool:IsDrainable() then
            self.tool:UseAndSync()
        end
    elseif self.consumeTool == "remove" then
        self.character:getInventory():Remove(self.tool)
        if isServer() then
            sendRemoveItemFromContainer(self.character:getInventory(), self.tool)
        end
    end
end

function EMBodyPartAction:complete()
    self:consumeTool()
    self:applyTreatment()
    return true
end
