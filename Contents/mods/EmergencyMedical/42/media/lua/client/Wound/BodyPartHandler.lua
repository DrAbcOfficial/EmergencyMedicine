-- Base class for health-panel wound handlers: right-click a body part in
-- ISHealthPanel -> one menu option per registered handler that finds a
-- usable item on/near the doctor. Encapsulates the doctor/patient model
-- (doctor = acting player, patient = the panel owner -- the same object
-- when self-treating), container scanning, the transfer-before-treat
-- step and timed-action queueing. Future wound features derive this and
-- register, no menu plumbing needed.
--
-- ISHealthPanel:doBodyPartContextMenu builds its menu from per-wound
-- handler objects which it feeds through self:checkItems(handlers) (a
-- container scan calling each handler's checkItem) and then
-- handler:addToMenu(context). The vanilla BaseHandler is LOCAL to
-- ISHealthPanel.lua and cannot be inherited, so we wrap the panel-level
-- checkItems and append one instance per registered subclass.
--
-- Subclass contract (override):
--   matchesItem(item) -> bool   -- which inventory items are usable
--   isEligible() -> bool        -- whether bodyPart can be treated now
--   getLabel() -> string        -- context menu text
--   createAction(doctor, patient, item) -> ISBaseTimedAction
-- then EMBodyPartHandler.Register(class).
--
-- client/Wound sorts before client/XpSystem alphabetically, so the
-- vanilla health panel is not loaded yet at this point -- explicit
-- require below.
require "XpSystem/ISUI/ISHealthPanel"

EMBodyPartHandler = ISBaseObject:derive("EMBodyPartHandler")
EMBodyPartHandler.registered = {}

function EMBodyPartHandler.Register(class)
    table.insert(EMBodyPartHandler.registered, class)
end

function EMBodyPartHandler:new(panel, bodyPart)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.panel = panel
    o.bodyPart = bodyPart
    o.items = {}
    return o
end

function EMBodyPartHandler:getDoctor()
    return self.panel.otherPlayer or self.panel.character
end

function EMBodyPartHandler:getPatient()
    return self.panel.character
end

-- called by the panel's container scan for every reachable item
function EMBodyPartHandler:checkItem(item)
    if self:matchesItem(item) then
        table.insert(self.items, item)
    end
end

function EMBodyPartHandler:addToMenu(context)
    if #self.items == 0 or not self:isEligible() then
        return
    end
    context:addOption(self:getLabel(), self, self.onSelected)
end

function EMBodyPartHandler:onSelected()
    local item = self.items[1]
    if item == nil or not self:isEligible() then
        return
    end
    local doctor = self:getDoctor()
    local patient = self:getPatient()
    local action = self:createAction(doctor, patient, item)
    if action == nil then
        return
    end
    if item:getContainer() ~= doctor:getInventory() then
        -- item picked up from a nearby container: walk over and take it,
        -- then chain the treatment after the transfer. B42's addAfter has
        -- NO nil-previousAction fallback (B41 had one) -- passing nil
        -- silently drops the action, so the transfer is queued explicitly
        -- and never nil is passed to addAfter.
        local transfer = ISInventoryTransferUtil.newInventoryTransferAction(doctor, item, item:getContainer(), doctor:getInventory())
        ISTimedActionQueue.add(transfer)
        ISTimedActionQueue.addAfter(transfer, action)
    else
        ISTimedActionQueue.add(action)
    end
end

-- default stubs: subclasses override
function EMBodyPartHandler:matchesItem(item)
    return false
end

function EMBodyPartHandler:isEligible()
    return false
end

function EMBodyPartHandler:getLabel()
    return self.Type
end

function EMBodyPartHandler:createAction(doctor, patient, item)
    return nil
end

local origCheckItems = ISHealthPanel.checkItems
function ISHealthPanel:checkItems(handlers)
    if handlers[1] ~= nil and handlers[1].bodyPart ~= nil then
        for i = 1, #EMBodyPartHandler.registered do
            handlers[#handlers + 1] = EMBodyPartHandler.registered[i]:new(self, handlers[1].bodyPart)
        end
    end
    origCheckItems(self, handlers)
end
