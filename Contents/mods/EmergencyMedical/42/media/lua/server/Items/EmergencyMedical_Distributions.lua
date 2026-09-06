-- EmergencyMedical loot distribution: the five drugs spawn in hospital,
-- pharmacy, police and prison containers. Runs from OnGameBoot because
-- this file loads alphabetically BEFORE ProceduralDistributions.lua /
-- SuburbsDistributions.lua -- those tables only exist once every lua
-- file has loaded. Loot generation itself happens later (map load), so
-- the inserted entries are picked up.
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

local function distribute()
    -- hospital medical containers: all five drugs
    local hospitalLists = { "MedicalStorageDrugs", "HospitalLockers", "HospitalRoomCounter", "HospitalRoomShelves" }
    for i = 1, #hospitalLists do
        for j = 1, #OPIOIDS do
            addItem(hospitalLists[i], OPIOIDS[j], 8)
        end
        addItem(hospitalLists[i], "EmergencyMedical.oxycontin", 15)
        addItem(hospitalLists[i], "EmergencyMedical.naloxone", 12)
    end

    -- pharmacy counter list (shared with medical clinic counters):
    -- oxycontin only
    addItem("MedicalClinicDrugs", "EmergencyMedical.oxycontin", 15)

    -- pharmacy shelves: a dedicated list injected into the pharmacy
    -- room's shelf procList, so it does NOT leak into the supermarkets
    -- that share the StoreShelfMedical list
    ProceduralDistributions.list.EmergencyMedicalPharmacyShelf = {
        rolls = 1,
        items = {
            "EmergencyMedical.oxycontin", 15,
        },
        junk = {
            rolls = 1,
            items = {},
        },
    }
    if SuburbsDistributions ~= nil and SuburbsDistributions.pharmacy ~= nil
        and SuburbsDistributions.pharmacy.shelves ~= nil
        and SuburbsDistributions.pharmacy.shelves.procList ~= nil then
        table.insert(SuburbsDistributions.pharmacy.shelves.procList,
            { name = "EmergencyMedicalPharmacyShelf", min = 0, max = 1, weightChance = 30 })
    end

    -- police evidence: all five drugs, contraband rarity
    for j = 1, #OPIOIDS do
        addItem("PoliceEvidence", OPIOIDS[j], 1)
    end
    addItem("PoliceEvidence", "EmergencyMedical.oxycontin", 3)
    addItem("PoliceEvidence", "EmergencyMedical.naloxone", 3)

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

Events.OnGameBoot.Add(distribute)
