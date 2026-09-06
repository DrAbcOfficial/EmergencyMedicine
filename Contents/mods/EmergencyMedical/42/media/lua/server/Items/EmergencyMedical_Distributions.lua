-- EmergencyMedical loot distribution: the five drugs spawn in hospital,
-- pharmacy, police and prison containers.
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
-- Rarity tiers (weights on the vanilla lists' own scale; the drug
-- family overall slightly more common than Antibiotics):
--   oxycontin 15 > naloxone 12 > morphine / fentanyl / sufentanil 8
-- evidence and police desks use lower weights (contraband, not stock).

local OPIOIDS = { "EmergencyMedical.morphine", "EmergencyMedical.fentanyl", "EmergencyMedical.sufentanil" }

local function addItem(listName, fullType, weight)
    local list = ProceduralDistributions.list[listName]
    if list ~= nil and list.items ~= nil then
        table.insert(list.items, fullType)
        table.insert(list.items, weight)
    end
end

local function onPreDistributionMerge()
    -- hospital medical containers: all five opioids + tranexamic acid
    local hospitalLists = { "MedicalStorageDrugs", "HospitalLockers", "HospitalRoomCounter", "HospitalRoomShelves" }
    for i = 1, #hospitalLists do
        for j = 1, #OPIOIDS do
            addItem(hospitalLists[i], OPIOIDS[j], 8)
        end
        addItem(hospitalLists[i], "EmergencyMedical.oxycontin", 15)
        addItem(hospitalLists[i], "EmergencyMedical.naloxone", 12)
        addItem(hospitalLists[i], "EmergencyMedical.tranexamicacid", 10)
    end

    -- pharmacy counter list (shared with medical clinic counters):
    -- oxycontin + tranexamic acid
    addItem("MedicalClinicDrugs", "EmergencyMedical.oxycontin", 15)
    addItem("MedicalClinicDrugs", "EmergencyMedical.tranexamicacid", 12)

    -- pharmacy shelves: a dedicated list, appended to the pharmacy room's
    -- shelf procList below (onPostDistributionMerge) -- deliberately not
    -- StoreShelfMedical, which would leak into the supermarkets sharing it
    ProceduralDistributions.list.EmergencyMedicalPharmacyShelf = {
        rolls = 1,
        items = {
            "EmergencyMedical.oxycontin", 15,
            "EmergencyMedical.tranexamicacid", 12,
        },
        junk = {
            rolls = 1,
            items = {},
        },
    }

    -- ranches and farms: livestock drugs (sulfadimidine antibiotic,
    -- dexmedetomidine veterinary sedative)
    local farmLists = { "BarnTools", "FarmerTools", "CrateFarming" }
    for i = 1, #farmLists do
        addItem(farmLists[i], "EmergencyMedical.sulfadimidine", 8)
        addItem(farmLists[i], "EmergencyMedical.dexmedetomidine", 8)
    end

    -- police evidence: all five drugs, contraband rarity
    for j = 1, #OPIOIDS do
        addItem("PoliceEvidence", OPIOIDS[j], 1)
    end
    addItem("PoliceEvidence", "EmergencyMedical.oxycontin", 3)
    addItem("PoliceEvidence", "EmergencyMedical.naloxone", 3)

    -- army bunker medical station: methamphetamine, fentanyl rarity
    addItem("ArmyBunkerMedical", "EmergencyMedical.methamphetamine", 8)
    addItem("PoliceEvidence", "EmergencyMedical.methamphetamine", 1)

    -- police station desks / files, prison cells: naloxone only
    local naloxoneLists = {
        "PoliceDesk", "PoliceFileBox", "PoliceFilingCabinet",
        "PoliceCaptainCabinet", "PoliceCaptainDesk",
        "PrisonCellRandom",
    }
    for i = 1, #naloxoneLists do
        addItem(naloxoneLists[i], "EmergencyMedical.naloxone", 3)
    end
end

local function onPostDistributionMerge()
    -- room tables are final here; append the dedicated shelf list to the
    -- pharmacy room's shelves
    if SuburbsDistributions ~= nil and SuburbsDistributions.pharmacy ~= nil
        and SuburbsDistributions.pharmacy.shelves ~= nil
        and SuburbsDistributions.pharmacy.shelves.procList ~= nil then
        table.insert(SuburbsDistributions.pharmacy.shelves.procList,
            { name = "EmergencyMedicalPharmacyShelf", min = 0, max = 1, weightChance = 30 })
    end
end

Events.OnPreDistributionMerge.Add(onPreDistributionMerge)
Events.OnPostDistributionMerge.Add(onPostDistributionMerge)
