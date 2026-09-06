-- Amphetamine addiction/withdrawal status icons: glue between the
-- EM_Amph* values and EMStatusIcons (same 42.20.x limits as the opioid
-- statuses). The file name sorts AFTER EMStatusIcons.lua on purpose
-- (alphabetical load order -- "A" would load before it and bail on the
-- nil guard).
--
-- Icons are externally provided assets (media/ui/Moodles/). Withdrawal
-- desc tiers map straight onto the levels (mild/moderate/severe/extreme);
-- addiction tiers: mild (level 1) / moderate (levels 2-3) / severe
-- (level 4). The addiction itself has no gameplay effect.

if EMStatusIcons == nil then
    return
end

local function localPlayer(playerObj)
    if playerObj == nil or not playerObj:isLocalPlayer() then
        return nil
    end
    return playerObj
end

local addictionDescKeys = {
    [1] = "IGUI_health_AmphAddictionDescMild",
    [2] = "IGUI_health_AmphAddictionDescModerate",
    [3] = "IGUI_health_AmphAddictionDescSevere",
    [4] = "IGUI_health_AmphAddictionDescExtreme",
}

EMStatusIcons.RegisterStatus("AmphetamineAddiction", {
    icon = "media/ui/Moodles/AmphetamineAddictionIcon.png",
    tintColor = "bad",
    getLevel = function(playerObj)
        local p = localPlayer(playerObj)
        if p == nil then
            return 0
        end
        return EM_AmphAddiction_GetLevel(p)
    end,
    getName = function()
        return getText("IGUI_health_AmphAddiction")
    end,
    getDesc = function(playerObj)
        if playerObj == nil then
            return ""
        end
        -- addiction descriptions map 1:1 onto the levels (no tier collapse)
        local key = addictionDescKeys[EM_AmphAddiction_GetLevel(playerObj)]
        if key == nil then
            return ""
        end
        return getText(key)
    end,
})

local withdrawalDescKeys = {
    [1] = "IGUI_health_AmphWithdrawalDescMild",
    [2] = "IGUI_health_AmphWithdrawalDescModerate",
    [3] = "IGUI_health_AmphWithdrawalDescSevere",
    [4] = "IGUI_health_AmphWithdrawalDescExtreme",
}

EMStatusIcons.RegisterStatus("AmphetamineWithdrawal", {
    icon = "media/ui/Moodles/AmphetamineWithdrawal.png",
    tintColor = "bad",
    getLevel = function(playerObj)
        local p = localPlayer(playerObj)
        if p == nil then
            return 0
        end
        return EM_AmphWithdrawal_GetLevel(p)
    end,
    getName = function()
        return getText("IGUI_health_AmphWithdrawal")
    end,
    getDesc = function(playerObj)
        if playerObj == nil then
            return ""
        end
        local key = withdrawalDescKeys[EM_AmphWithdrawal_GetLevel(playerObj)]
        if key == nil then
            return ""
        end
        return getText(key)
    end,
})
