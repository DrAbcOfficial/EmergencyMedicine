-- Client-only: opioid addiction moodle glue.
-- The moodle type itself is registered officially in media/registries.lua
-- (EM.MoodleTypes.OpioidAddiction -> "EmergencyMedical:OpioidAddiction"),
-- so it is a first-class member of Registries.MOODLE_TYPE alongside the
-- vanilla types.
--
-- In 42.20.x the vanilla column still cannot render a mod-registered
-- MoodleType on its own: Moodle.Update() computes levels per hardcoded
-- base type and its updateMoodleLevel() is private (no Lua setter), and
-- MoodleTextureSet has no texture binding for modded types. So the
-- display keeps going through EMStatusIcons, which draws the icon inside
-- the vanilla moodle column with the vanilla background/border/tint.
-- If a future build exposes a level setter or texture registration, this
-- file is the place to switch to full native rendering.

if EMStatusIcons == nil then
    return
end

function EM_Addiction_GetMoodleType()
    return EM.MoodleTypes and EM.MoodleTypes.OpioidAddiction or nil
end

local tierDescKeys = {
    [1] = "IGUI_health_AddictionDescMild",
    [2] = "IGUI_health_AddictionDescModerate",
    [3] = "IGUI_health_AddictionDescSevere",
}

EMStatusIcons.RegisterStatus("OpioidAddiction", {
    moodleType = EM_Addiction_GetMoodleType(),
    icon = "media/ui/Moodles/OpioidAddictionIcon.png",
    tintColor = "bad",
    getLevel = function(playerObj)
        if EMStatusIcons.LocalPlayer(playerObj) == nil then
            return 0
        end
        return EM_Addiction_GetLevel(playerObj)
    end,
    getName = function(playerObj)
        return getText("IGUI_health_Addiction")
    end,
    getDesc = function(playerObj)
        local key = tierDescKeys[EM_Addiction_GetTier(playerObj)]
        if playerObj == nil or key == nil then
            return ""
        end
        return getText(key)
    end,
})
