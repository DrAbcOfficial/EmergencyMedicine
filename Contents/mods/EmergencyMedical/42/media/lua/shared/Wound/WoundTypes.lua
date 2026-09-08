-- Built-in wound state types for the EM_Wound_* manager. Register
-- additional limb states here; effects/display stay with the feature
-- that applies them.

EM_Wound_Register("Cauterized", {
    -- the cauterization scab marks the part for a year by default
    -- ("ScabDurationDays" sandbox option, resolved when the state is
    -- added). Holds the burned-out scratch/cut/bite as custom params;
    -- a new wound on the part pops it (EMTreatment_PopCauterized).
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
    -- Holds the closed deep wound + its bleeding as custom params; a new
    -- deep wound on the part pops it (EMTreatment_PopCrudeStitch).
    -- ("CrudeStitchedDurationDays" sandbox option, resolved when the
    -- state is added)
    durationDays = function()
        return EM_Sandbox_Get("CrudeStitchedDurationDays")
    end,
    panelLabelKey = "IGUI_health_CrudeStitched",
})

EM_Wound_Register("EmergencyFixed", {
    -- improvised splint on a fracture (EmergencyMedical.TemporarySplint,
    -- applied from the health panel): the fracture is TEMPORARILY
    -- REMOVED from the body for the whole duration (severity zeroed, no
    -- vanilla fracture anywhere) and every wound on the part hurts +45%
    -- (BodyWoundSimulation.lua). No vanilla splint flags are set. The
    -- hidden severity travels as a custom param on the state itself
    -- (state.fractureTime, written by the applying treatment right
    -- after EM_Wound_Add). Removal restores the fracture from that
    -- stored value (worse by the days held); a fresh fracture while
    -- fixated pops it with the severities stacked
    -- (EMTreatment_PopEmergencyFix); natural expiry is spotted by the
    -- per-minute simulation reading the raw state's expire field -- see
    -- BodyWoundSimulation.lua.
    durationDays = function()
        return EM_Sandbox_Get("EmergencyFixDurationDays")
    end,
    panelLabelKey = "IGUI_health_EmergencyFixed",
})

-- Drug side-effect statuses (DrugHeadache / DrugFever / ShoddySedation /
-- CoughSuppress) are deliberately NOT wound states -- they are
-- player-level statuses in the EM_DrugFx engine
-- (shared/Drugs/DrugStatus.lua), displayed as abnormal-status icons in
-- the vanilla moodle column (client/ISUI/StatusDrugEffects.lua).
