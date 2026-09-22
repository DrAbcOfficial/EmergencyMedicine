-- Base class for the health-panel body-part timed actions. Every EM
-- treatment action shares the same body: patient-move guard, the part
-- eligibility hook, the bandage (self-treatment) / loot (treating
-- someone else) animation pair, the tool job bar, the instant-check
-- duration and the authoritative treatment execution. Subclasses only
-- declare what differs:
--
--   local Action = EMBodyPartAction:derive("ISMyAction")
--
--   function Action:new(character, patient, tool, bodyPart)
--       return EMBodyPartAction.new(self, character, patient, bodyPart,
--           tool, {
--               duration = 150,                      -- ticks (or override getDuration)
--               jobKey = "IGUI_health_MyAction",     -- tool job bar text
--               consumeTool = "drainable",           -- or "remove" / nil
--           })
--   end
--
--   function Action:isEligible() ... end       -- part predicate (shared op)
--   function Action:applyTreatment() ... end   -- the shared EMTreatment_* op
--
-- tool: nil for the bare-hand actions -- skips the inventory guard, the
-- hand model override and the job bar. consumeTool: "drainable" burns
-- one use (UseAndSync), "remove" consumes a plain item outright (vanilla
-- ISApplyBandage pattern), nil = reusable tool.
--
-- B42 MP timed actions are SERVER-EXECUTED (decompiled LuaTimedActionNew /
-- NetTimedAction / IsoGameCharacter.update): the client only animates --
-- start/update/isValid/perform run there, but the game never calls the
-- Lua complete() on a multiplayer client. Instead the action is sent to
-- the server as a "net timed action" (global class name + the new()
-- constructor arguments, matched by parameter name), REBUILT in the
-- server's Lua, and its complete() runs there once the action time
-- elapsed; only then is the owning client released and its queue
-- advanced. Consequences this file is built around:
--   * the action classes MUST live in shared Lua (a client-only class
--     cannot be rebuilt server-side: the client bar hangs forever and
--     the treatment never happens -- the bug this file's location
--     fixed);
--   * complete() runs on the server in MP, on the local process in SP --
--     always where body damage is authoritative, so applyTreatment()
--     calls the shared EMTreatment_* op directly, no client commands;
--   * every per-instance value complete() needs must be a new()
--     parameter (serialized by name) or recomputable from those --
--     config tables are rebuilt inside new(), not transmitted;
--   * isEligible() is re-checked inside complete() server-side: the
--     client checked its own copy for the whole action, the server
--     re-validates against its authoritative copy.
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
    -- must NOT be named consumeTool: an instance field by that name
    -- would shadow the consumeTool() method below and self:consumeTool()
    -- in complete() would try to call this string (runtime __call error)
    o.consumeMode = config.consumeTool
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

function EMBodyPartAction:consumeTool()
    if self.tool == nil then
        return
    end
    if self.consumeMode == "drainable" then
        -- one use of a drainable tool (lighter, glue ...)
        if self.tool:IsDrainable() then
            self.tool:UseAndSync()
        end
    elseif self.consumeMode == "remove" then
        self.character:getInventory():Remove(self.tool)
        if isServer() then
            sendRemoveItemFromContainer(self.character:getInventory(), self.tool)
        end
    end
end

-- the treatment itself; runs after the eligibility re-check, always on
-- the authoritative side (the server in MP, the local process in SP).
-- Subclasses call their shared EMTreatment_* op here.
function EMBodyPartAction:applyTreatment()
end

function EMBodyPartAction:complete()
    -- server-side (MP) / local (SP) treatment: the client's isValid held
    -- for the whole cast, this is the authoritative re-validation -- an
    -- ineligible part (latency desync) is left alone, tool included
    if self:isEligible() then
        self:consumeTool()
        self:applyTreatment()
    end
    return true
end
