-- EmergencyMedicine loot distribution: the drugs spawn in hospital,
-- pharmacy, police, prison, farm and bunker containers.
--
-- B42 pipeline (decompiled IsoWorld / ItemPickerJava): on world init the
-- game fires OnPreDistributionMerge -> OnDistributionMerge ->
-- OnPostDistributionMerge and THEN ItemPickerJava.Parse() bakes the Lua
-- globals "ProceduralDistributions" / "SuburbsDistributions" into Java --
-- all loot generation reads that bake. Mutations therefore belong in the
-- merge events: OnGameBoot-time changes are lost when B42 reloads the
-- Lua state on game enter (this file's original bug -- no error, just
-- silently never applied).
--   * container proc lists   -> OnPreDistributionMerge (ProceduralDistributions
--     is not touched by the vanilla merge, which only rebuilds room tables)
--   * room procList appends  -> OnPostDistributionMerge (SuburbsDistributions
--     is final there: vanilla's merge re-assigns it to Distributions[1]
--     and folds in mod addon tables)
-- Pattern proven by Workshop mods (Authentic Z #2335368829 does its
-- ProceduralDistributions work inside OnPreDistributionMerge).
--
-- Weights are SANDBOX-DRIVEN (应急医疗-刷新 tab): one integer weight
-- option per drug. The option value IS the drug's weight in its primary
-- location (hospital for the medical drugs, pharmacy counter for the
-- OTC syrup); every other location scales by the same factor so the
-- designed rarity tiers stay proportional (evidence room contraband is
-- 1/8 of hospital for the strong opioids, police desks 1/4 for
-- naloxone, ...). 0 disables the drug everywhere. Rounding is
-- half-up; tiny values can zero out the rare spots before the common
-- ones (documented in the tooltips).
--
-- TIMING CAVEAT (decompiled IsoWorld.init): the merge events fire
-- BEFORE SandboxOptions.load() applies the save's values in the
-- singleplayer LOAD path -- there the in-memory SandboxVars still hold
-- the process defaults. New games pushed the chosen values via the
-- sandbox screen's toLua() and dedicated servers load them at boot, so
-- those read correctly; only fresh-process SP save loads roll newly
-- generated cells with default weights. Nothing Lua-side can run
-- between load() and ItemPickerJava.Parse().

local OPIOIDS = { "EmergencyMedicine.morphine", "EmergencyMedicine.fentanyl", "EmergencyMedicine.sufentanil" }

-- per-drug loot spec: sandbox option (EmergencyMedicineLoot tab) and the
-- base = default weight in the drug's primary location (mirrors the
-- option default in sandbox-options.txt / EM_Sandbox.lua)
local SPAWN = {
    ["EmergencyMedicine.morphine"] = { option = "MorphineSpawnWeight", base = 8 },
    ["EmergencyMedicine.naloxone"] = { option = "NaloxoneSpawnWeight", base = 12 },
    ["EmergencyMedicine.fentanyl"] = { option = "FentanylSpawnWeight", base = 8 },
    ["EmergencyMedicine.oxycontin"] = { option = "OxycontinSpawnWeight", base = 15 },
    ["EmergencyMedicine.sufentanil"] = { option = "SufentanilSpawnWeight", base = 8 },
    ["EmergencyMedicine.methamphetamine"] = { option = "MethamphetamineSpawnWeight", base = 8 },
    ["EmergencyMedicine.tranexamicacid"] = { option = "TranexamicAcidSpawnWeight", base = 10 },
    ["EmergencyMedicine.sulfadimidine"] = { option = "SulfadimidineSpawnWeight", base = 8 },
    ["EmergencyMedicine.dexmedetomidine"] = { option = "DexmedetomidineSpawnWeight", base = 8 },
    ["EmergencyMedicine.dextromethorphan"] = { option = "DextromethorphanSpawnWeight", base = 12 },
}

-- sandbox-scaled weight for one add: the location default, scaled by
-- (option value / base); 0 kills the entry everywhere
local function scaledWeight(fullType, locationDefault)
    local spec = SPAWN[fullType]
    if spec == nil then
        return locationDefault
    end
    local value = EM_Sandbox_Get(spec.option)
    if value == nil or value <= 0 then
        return 0
    end
    return math.floor(locationDefault * value / spec.base + 0.5)
end

local function addItem(listName, fullType, weight)
    local list = ProceduralDistributions.list[listName]
    if list ~= nil and list.items ~= nil then
        local scaled = scaledWeight(fullType, weight)
        if scaled > 0 then
            table.insert(list.items, fullType)
            table.insert(list.items, scaled)
        end
    end
end

local function onPreDistributionMerge()
    -- hospital medical containers: all five opioids + tranexamic acid
    local hospitalLists = { "MedicalStorageDrugs", "HospitalLockers", "HospitalRoomCounter", "HospitalRoomShelves" }
    for i = 1, #hospitalLists do
        for j = 1, #OPIOIDS do
            addItem(hospitalLists[i], OPIOIDS[j], 8)
        end
        addItem(hospitalLists[i], "EmergencyMedicine.oxycontin", 15)
        addItem(hospitalLists[i], "EmergencyMedicine.naloxone", 12)
        addItem(hospitalLists[i], "EmergencyMedicine.tranexamicacid", 10)
    end

    -- pharmacy counter list (shared with medical clinic counters):
    -- oxycontin + tranexamic acid
    addItem("MedicalClinicDrugs", "EmergencyMedicine.oxycontin", 15)
    addItem("MedicalClinicDrugs", "EmergencyMedicine.tranexamicacid", 12)

    -- OTC cough syrup (dextromethorphan): the family bathroom cabinet
    -- is where it actually lives, plus the pharmacy counters/shelf
    addItem("BathroomCounter", "EmergencyMedicine.dextromethorphan", 15)
    addItem("MedicalClinicDrugs", "EmergencyMedicine.dextromethorphan", 12)

    -- pharmacy shelves: a dedicated list, appended to the pharmacy room's
    -- shelf procList below (onPostDistributionMerge) -- deliberately not
    -- StoreShelfMedical, which would leak into the supermarkets sharing it
    local shelfItems = {}
    local function addShelf(fullType, locationDefault)
        local scaled = scaledWeight(fullType, locationDefault)
        if scaled > 0 then
            shelfItems[#shelfItems + 1] = fullType
            shelfItems[#shelfItems + 1] = scaled
        end
    end
    addShelf("EmergencyMedicine.oxycontin", 15)
    addShelf("EmergencyMedicine.tranexamicacid", 12)
    addShelf("EmergencyMedicine.dextromethorphan", 12)
    if #shelfItems > 0 then
        ProceduralDistributions.list.EmergencyMedicinePharmacyShelf = {
            rolls = 1,
            items = shelfItems,
            junk = {
                rolls = 1,
                items = {},
            },
        }
    end

    -- ranches and farms: livestock drugs (sulfadimidine antibiotic,
    -- dexmedetomidine veterinary sedative)
    local farmLists = { "BarnTools", "FarmerTools", "CrateFarming" }
    for i = 1, #farmLists do
        addItem(farmLists[i], "EmergencyMedicine.sulfadimidine", 8)
        addItem(farmLists[i], "EmergencyMedicine.dexmedetomidine", 8)
    end

    -- police evidence: all five drugs, contraband rarity
    for j = 1, #OPIOIDS do
        addItem("PoliceEvidence", OPIOIDS[j], 1)
    end
    addItem("PoliceEvidence", "EmergencyMedicine.oxycontin", 3)
    addItem("PoliceEvidence", "EmergencyMedicine.naloxone", 3)

    -- army bunker medical station: methamphetamine, fentanyl rarity
    addItem("ArmyBunkerMedical", "EmergencyMedicine.methamphetamine", 8)
    addItem("PoliceEvidence", "EmergencyMedicine.methamphetamine", 1)

    -- police station desks / files, prison cells: naloxone only
    local naloxoneLists = {
        "PoliceDesk", "PoliceFileBox", "PoliceFilingCabinet",
        "PoliceCaptainCabinet", "PoliceCaptainDesk",
        "PrisonCellRandom",
    }
    for i = 1, #naloxoneLists do
        addItem(naloxoneLists[i], "EmergencyMedicine.naloxone", 3)
    end
end

local function onPostDistributionMerge()
    -- room tables are final here; append the dedicated shelf list to the
    -- pharmacy room's shelves (the list only exists if at least one of
    -- its drugs survived the sandbox weights)
    if ProceduralDistributions.list.EmergencyMedicinePharmacyShelf ~= nil
        and SuburbsDistributions ~= nil and SuburbsDistributions.pharmacy ~= nil
        and SuburbsDistributions.pharmacy.shelves ~= nil
        and SuburbsDistributions.pharmacy.shelves.procList ~= nil then
        table.insert(SuburbsDistributions.pharmacy.shelves.procList,
            { name = "EmergencyMedicinePharmacyShelf", min = 0, max = 1, weightChance = 30 })
    end
end

Events.OnPreDistributionMerge.Add(onPreDistributionMerge)
Events.OnPostDistributionMerge.Add(onPostDistributionMerge)
