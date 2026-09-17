-- Client side of the auto-injector watch: the load/unload context menu
-- (right-click a watch in ANY panel -- main inventory, backpack,
-- equipment) and the auto-injection trigger loop. The menu is mutually
-- exclusive: an empty watch offers loading (only the ampoule drugs
-- actually present in the inventory), a loaded watch offers unloading.
-- Loading consumes the physical ampoule and records it on the watch
-- item's modData; unloading spawns a fresh ampoule (single-dose
-- ampoules lose nothing in transit).
--
-- Trigger: OnPlayerUpdate -- the health check runs first so the worn
-- scan only happens in the emergency case. MP routes through the
-- AutoInject client command (the server re-validates everything and
-- consumes the physical ampoule); the local load is cleared
-- optimistically so the trigger fires once. Singleplayer calls
-- EMAutoInjector_TryInject directly. The injection sound (user-only)
-- plays in SP on a successful TryInject, in MP on the server's
-- AutoInjectSound echo command (see onServerCommand below).

local function onFillContextMenu(playerNum, context, items)
	local playerObj = getSpecificPlayer(playerNum)
	if playerObj == nil then
		return
	end
	local watch = nil
	if ISInventoryPane == nil or ISInventoryPane.getActualItems == nil then
		return
	end
	-- panel entries come in two shapes: raw InventoryItems (main
	-- inventory) and stack tables {items = {...}} (bag/loot panels) --
	-- the vanilla helper flattens both
	local flat = ISInventoryPane.getActualItems(items)
	for i = 1, #flat do
		local entry = flat[i]
		if EMAutoInjector_IsWatch(entry) then
			watch = entry
			break
		end
	end
	if watch == nil then
		return
	end
	-- recurse: the ampoules usually sit inside the equipped backpack,
	-- which the plain main-inventory scan would miss
	local inventory = playerObj:getInventory()
	local loaded = EMAutoInjector_GetLoaded(watch)

	-- mutually exclusive: loaded -> unload only; not loaded -> the load
	-- submenu, which lists ONLY the ampoule drugs actually present in
	-- the inventory (no greyed entries; nothing present = no menu at all)
	if loaded ~= nil then
		context:addOption(getText("IGUI_health_AutoInjectUnload"), playerObj, function(p, w)
			local drug = EMAutoInjector_GetLoaded(w)
			if drug == nil then
				return
			end
			w:getModData().EM_AutoInjectDrug = nil
			p:getInventory():AddItem(drug)
		end, watch)
		return
	end
	local present = {}
	for a = 1, #EM_AUTOINJECT_AMPOULES do
		local drug = EM_AUTOINJECT_AMPOULES[a]
		if inventory:getFirstTypeRecurse(drug) ~= nil then
			present[#present + 1] = drug
		end
	end
	if #present == 0 then
		return
	end
	local loadOption = context:addOption(getText("IGUI_health_AutoInjectLoad"), nil, nil)
	local loadMenu = ISContextMenu:getNew(context)
	context:addSubMenu(loadOption, loadMenu)
	for i = 1, #present do
		loadMenu:addOption(getItemNameFromFullType(present[i]), playerObj, function(p, w, d)
			local ampoule = p:getInventory():getFirstTypeRecurse(d)
			if ampoule == nil then
				return
			end
			ampoule:getContainer():Remove(ampoule)
			w:getModData().EM_AutoInjectDrug = d
		end, watch, present[i])
	end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillContextMenu)

-- the vanilla left/right wrist swap REPLACES the item (destroy +
-- create): carry the loaded drug across our own watch swaps, otherwise
-- a loaded dose silently vanishes on a wrist change. The vanilla
-- callback's third argument IS the player object (not a player number).
local origOnClothingItemExtra = ISInventoryPaneContextMenu.onClothingItemExtra
function ISInventoryPaneContextMenu.onClothingItemExtra(item, fullType, playerObj)
	local carriedDrug = nil
	if playerObj ~= nil and EMAutoInjector_IsWatch(item) then
		carriedDrug = EMAutoInjector_GetLoaded(item)
	end
	origOnClothingItemExtra(item, fullType, playerObj)
	if carriedDrug ~= nil and playerObj ~= nil then
		local newWatch = EMAutoInjector_GetEquipped(playerObj)
		if newWatch ~= nil and EMAutoInjector_GetLoaded(newWatch) == nil then
			newWatch:getModData().EM_AutoInjectDrug = carriedDrug
		end
	end
end

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
		sendClientCommand(player, "EmergencyMedicine", "AutoInject", { drug = drug })
		watch:getModData().EM_AutoInjectDrug = nil
	else
		-- singleplayer: the injection happens right here, play the sound
		-- only if the shot actually went in
		if EMAutoInjector_TryInject(player, drug) then
			EM_Inject_PlaySound(player)
		end
	end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)

-- MP: the server runs the injection, so the sound is played on the echo
-- command it sends back to the owning client on success (AutoInjectSound,
-- sent by the AutoInject command handler) -- a rejected trigger (no
-- physical ampoule left, watch taken off...) never plays a sound. The
-- handler runs on the owning client only, and EM_Inject_PlaySound stays
-- local to this client: nobody else hears it.
local function onServerCommand(module, command, args)
	if module ~= "EmergencyMedicine" then
		return
	end
	-- AutoInjectSound: the watch injection; InjectSound: an ampoule-pill
	-- injection (server-executed ISTakePillAction complete echoes it) --
	-- both play the user-only sound on the owning client only
	if command == "AutoInjectSound" or command == "InjectSound" then
		EM_Inject_PlaySound(getSpecificPlayer(0))
	end
end

Events.OnServerCommand.Add(onServerCommand)
