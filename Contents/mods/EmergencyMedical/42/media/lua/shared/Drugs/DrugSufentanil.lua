-- Sufentanil: applying it fixes a "fentanyl patch" (EM_Wound state
-- "FentanylPatch") onto the RIGHT UPPER ARM. While the patch lasts it is
-- maintained by BodyWoundSimulation.lua every game minute: +painkiller
-- dose, -withdrawal, +addiction, pain/panic/unhappiness/boredom pinned
-- at zero -- all rates sandbox-configurable, duration default 3 days
-- ("SufentanilPatchDays"). Re-applying refreshes the patch (EM_Wound_Add
-- overwrites the state, restarting its timer); it comes off via the
-- health panel right-click (RemovePatchHandler, no tool needed).
local PATCH_PART = "UpperArm_R"

function TakeSufentanil(player)
    EM_Wound_Add(player, PATCH_PART, "FentanylPatch")
end
