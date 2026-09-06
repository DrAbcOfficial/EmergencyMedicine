-- Client-only: register the opioid addiction as a generic status icon
-- in the vanilla moodle column (see ISUI/EMStatusIcons.lua). Add more
-- statuses later by calling EMStatusIcons.RegisterStatus here.

if EMStatusIcons == nil then
    return
end

local function player(playerObj)
    if playerObj == nil or not playerObj:isLocalPlayer() then
        return nil
    end
    return playerObj
end

EMStatusIcons.RegisterStatus("OpioidAddiction", {
    icon = "media/ui/Moodles/OpioidAddictionIcon.png",
    tintColor = "bad",
    getLevel = function(playerObj)
        if player(playerObj) == nil then
            return 0
        end
        return EM_Addiction_GetLevel(playerObj)
    end,
    getName = function(playerObj)
        if playerObj ~= nil and EM_Addiction_IsSevere(playerObj) then
            return getText("IGUI_health_AddictionSevere")
        end
        return getText("IGUI_health_Addiction")
    end,
    getDesc = function(playerObj)
        if playerObj ~= nil and EM_Addiction_IsSevere(playerObj) then
            return getText("IGUI_health_AddictionDescSevere")
        end
        return getText("IGUI_health_AddictionDesc")
    end,
})
