-- Client side of the auto-injector watch: the load/unload context menu
-- (right-click a watch -> load one of the four ampoule drugs / unload)
-- and the auto-injection trigger loop. Loading consumes the physical
-- ampoule and records it on the watch item's modData; unloading spawns
-- a fresh ampoule (single-dose ampoules lose nothing in transit).
--
-- Trigger: OnPlayerUpdate -- the health check runs first so the worn
-- scan only happens in the emergency case. MP routes through the
-- AutoInject client command (the server re-validates everything and
-- consumes the physical ampoule); the local load is cleared
-- optimistically so the trigger fires once. Singleplayer calls
-- EMAutoInjector_TryInject directly.

local function onFillContextMenu(playerNum, context, items)
	local playerObj = getSpecificPlayer(playerNum)
	if playerObj == nil then
		return
	end
	local watch = nil
	for i = 1, #items do
		local entry = items[i]
		if instanceof(entry, "InventoryItem") and EMAutoInjector_IsWatch(entry) then
			watch = entry
			break
		end
	end
	if watch == nil then
		return
	end
	local inventory = playerObj:getInventory()
	local loaded = EMAutoInjector_GetLoaded(watch)

	local loadOption = context:addOption(getText("IGUI_health_AutoInjectLoad"), nil, nil)
	local loadMenu = ISContextMenu:getNew(context)
	context:addSubMenu(loadOption, loadMenu)
	local anyLoadable = false
	for a = 1, #EM_AUTOINJECT_AMPOULES do
		local drug = EM_AUTOINJECT_AMPOULES[a]
		local hasAmpoule = inventory:getFirstType(drug) ~= nil
		anyLoadable = anyLoadable or hasAmpoule
		local option = loadMenu:addOption(getText(drug), playerObj, function(p, w, d)
			local ampoule = p:getInventory():getFirstType(d)
			if ampoule == nil then
				return
			end
			p:getInventory():Remove(ampoule)
			w:getModData().EM_AutoInjectDrug = d
		end, watch, drug)
		if not hasAmpoule then
			option.notAvailable = true
		end
	end
	if not anyLoadable then
		loadOption.notAvailable = true
	end

	local unloadOption = context:addOption(getText("IGUI_health_AutoInjectUnload"), playerObj, function(p, w)
		local drug = EMAutoInjector_GetLoaded(w)
		if drug == nil then
			return
		end
		w:getModData().EM_AutoInjectDrug = nil
		p:getInventory():AddItem(drug)
	end, watch, loaded)
	if loaded == nil then
		unloadOption.notAvailable = true
	end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillContextMenu)

local function onPlayerUpdate(player)
	if player == nil then
		return
	end
	local bodyDamage = player:getBodyDamage()
	if bodyDamage == nil or bodyDamage:getHealth() >= EM_AUTOINJECT_HEALTH_THRESHOLD then
		return
	end
	local watch = EMAutoInjector_GetEquipped(player)
	if watch == nil then
		return
	end
	local drug = EMAutoInjector_GetLoaded(watch)
	if drug == nil then
		return
	end
	if isClient() then
		-- the server re-validates everything and consumes the physical
		-- ampoule; clear the local load so the trigger fires once
		sendClientCommand(player, "EmergencyMedical", "AutoInject", { drug = drug })
		watch:getModData().EM_AutoInjectDrug = nil
	else
		EMAutoInjector_TryInject(player, drug)
	end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
