-- Auto-injector watch: the craftable watch items (four styles -- black
-- / red / metal / luxury -- each in a right-wrist and a left-wrist
-- variant) share one behavior. They tell time, date and
-- temperature like any digital watch (vanilla alarmclockclothing item
-- type), hold ONE loaded ampoule drug (morphine / naloxone / fentanyl /
-- dexmedetomidine, recorded on the watch item's modData -- the mod is
-- unreleased, layouts are free), and while WORN they inject the loaded
-- drug automatically the moment overall health drops below a quarter.
--
-- Loading CONSUMES the physical ampoule and records its full type;
-- unloading spawns a fresh one (single-dose ampoules lose nothing in
-- transit). Injection runs the exact EMDrug_ApplyEffect pipeline the
-- pill flow uses and consumes one physical ampoule of that type from
-- the inventory -- the record alone can never duplicate a dose.
--
-- MP: the trigger is detected on the owning client (OnPlayerUpdate,
-- health-gated so it is cheap) and routed through the AutoInject client
-- command; the server re-validates everything (alive, health below the
-- threshold, watch worn, drug whitelisted, physical ampoule present)
-- and executes. Singleplayer calls EMAutoInjector_TryInject directly.

-- the eight watch items: four styles, each in a right-wrist and a
-- left-wrist variant (vanilla parity -- the worn swap between them is a
-- vanilla item replace, the load carries across via the menu wrap)
EM_AUTOINJECT_WATCH_TYPES = {
	"EmergencyMedical.AutoInjectorWatchBlack",
	"EmergencyMedical.AutoInjectorWatchBlackLeft",
	"EmergencyMedical.AutoInjectorWatchRed",
	"EmergencyMedical.AutoInjectorWatchRedLeft",
	"EmergencyMedical.AutoInjectorWatchMetal",
	"EmergencyMedical.AutoInjectorWatchMetalLeft",
	"EmergencyMedical.AutoInjectorWatchLuxury",
	"EmergencyMedical.AutoInjectorWatchLuxuryLeft",
}

-- the loadable ampoule drugs
EM_AUTOINJECT_AMPOULES = {
	"EmergencyMedical.morphine",
	"EmergencyMedical.naloxone",
	"EmergencyMedical.fentanyl",
	"EmergencyMedical.dexmedetomidine",
}

-- overall health (0..100): at/below this the watch injects
EM_AUTOINJECT_HEALTH_THRESHOLD = 25.0

function EMAutoInjector_IsWatch(item)
	if item == nil then
		return false
	end
	local fullType = item:getFullType()
	for w = 1, #EM_AUTOINJECT_WATCH_TYPES do
		if EM_AUTOINJECT_WATCH_TYPES[w] == fullType then
			return true
		end
	end
	return false
end

-- the first worn watch, or nil
function EMAutoInjector_GetEquipped(player)
	local worn = player:getWornItems()
	if worn == nil then
		return nil
	end
	for i = 0, worn:size() - 1 do
		local wornItem = worn:get(i)
		local item = wornItem ~= nil and wornItem:getItem() or nil
		if item ~= nil and EMAutoInjector_IsWatch(item) then
			return item
		end
	end
	return nil
end

-- the loaded drug type on a watch, or nil
function EMAutoInjector_GetLoaded(watch)
	local modData = watch and watch:getModData()
	return modData ~= nil and modData.EM_AutoInjectDrug or nil
end

-- full validation + injection. Server-side in MP (the AutoInject
-- command handler re-validates everything), direct in singleplayer.
function EMAutoInjector_TryInject(player, drug)
	if player == nil or not player:isAlive() then
		return false
	end
	-- whitelist first: the four ampoule drugs, nothing else
	local whitelisted = false
	for a = 1, #EM_AUTOINJECT_AMPOULES do
		if EM_AUTOINJECT_AMPOULES[a] == drug then
			whitelisted = true
			break
		end
	end
	if not whitelisted then
		return false
	end
	-- the watch must be worn
	local watch = EMAutoInjector_GetEquipped(player)
	if watch == nil then
		return false
	end
	-- the health gate: at/above the threshold the watch holds fire
	if player:getBodyDamage():getHealth() >= EM_AUTOINJECT_HEALTH_THRESHOLD then
		return false
	end
	-- a physical ampoule must be in the inventory (recurse -- it usually
	-- sits inside the equipped backpack): the injection consumes it, so
	-- the record alone can never duplicate a dose
	local inventory = player:getInventory()
	local ampoule = inventory:getFirstTypeRecurse(drug)
	if ampoule == nil then
		return false
	end
	EMDrug_ApplyEffect(player, drug)
	local container = ampoule:getContainer()
	if container ~= nil then
		container:Remove(ampoule)
	end
	if isServer() then
		sendRemoveItemFromContainer(container, ampoule)
	end
	-- the record is spent
	watch:getModData().EM_AutoInjectDrug = nil
	return true
end
