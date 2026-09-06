-- Built-in wound state types for the EM_Wound_* manager. Register
-- additional limb states here; effects/display stay with the feature
-- that applies them.

EM_Wound_Register("Cauterized", {
    -- the cauterization scab marks the part for a year by default
    -- ("ScabDurationDays" sandbox option, resolved when the state is added)
    durationDays = function()
        return EM_Sandbox_Get("ScabDurationDays")
    end,
    -- shown as its own wound line on the health panel body part row
    panelLabelKey = "IGUI_health_CauterizedWound",
})

EM_Wound_Register("FentanylPatch", {
    -- the sufentanil patch sits on the right upper arm for 3 days by
    -- default ("SufentanilPatchDays" sandbox option); per-minute upkeep
    -- in BodyWoundSimulation.lua
    durationDays = function()
        return EM_Sandbox_Get("SufentanilPatchDays")
    end,
    panelLabelKey = "IGUI_health_FentanylPatch",
})

EM_Wound_Register("CrudeStitched", {
    -- glue / stapler field repair of a deep wound: the wound stays, but
    -- every wound on the part hurts +20% while the crude stitching lasts
    -- (pain floor in BodyWoundSimulation.lua). The default age-quartile
    -- levels drive the reopened wound severity on scalpel excision.
    -- ("CrudeStitchedDurationDays" sandbox option, resolved when the
    -- state is added)
    durationDays = function()
        return EM_Sandbox_Get("CrudeStitchedDurationDays")
    end,
    panelLabelKey = "IGUI_health_CrudeStitched",
})
