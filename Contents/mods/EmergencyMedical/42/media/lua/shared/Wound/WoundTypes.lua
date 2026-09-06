-- Built-in wound state types for the EM_Wound_* manager. Register
-- additional limb states here; effects/display stay with the feature
-- that applies them.

EM_Wound_Register("Cauterized", {
    -- the cauterization scab marks the part for a year by default
    durationDays = 365,
    -- shown as its own wound line on the health panel body part row
    panelLabelKey = "IGUI_health_CauterizedWound",
})
