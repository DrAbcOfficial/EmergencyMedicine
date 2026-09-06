-- Client-only: opioid withdrawal moodle glue.
-- The moodle type is registered officially in media/registries.lua
-- (EM.MoodleTypes.OpioidWithdrawal -> "EmergencyMedical:OpioidWithdrawal");
-- display goes through EMStatusIcons for the same 42.20.x limits as the
-- addiction status (see OpioidAddictionStatus.lua).
--
-- Withdrawal has four description tiers that map straight onto the
-- moodle levels (mild / moderate / severe / extreme).

if EMStatusIcons == nil then
    return
end

function EM_Withdrawal_GetMoodleType()
    return EM.MoodleTypes and EM.MoodleTypes.OpioidWithdrawal or nil
end

local function player(playerObj)
    if playerObj == nil or not playerObj:isLocalPlayer() then
        return nil
    end
    return playerObj
end

local levelDescKeys = {
    [1] = "IGUI_health_WithdrawalDescMild",
    [2] = "IGUI_health_WithdrawalDescModerate",
    [3] = "IGUI_health_WithdrawalDescSevere",
    [4] = "IGUI_health_WithdrawalDescExtreme",
}

EMStatusIcons.RegisterStatus("OpioidWithdrawal", {
    moodleType = EM_Withdrawal_GetMoodleType(),
    icon = "media/ui/Moodles/WithdrawalIcon.png",
    tintColor = "bad",
    getLevel = function(playerObj)
        if player(playerObj) == nil then
            return 0
        end
        return EM_Withdrawal_GetLevel(playerObj)
    end,
    getName = function(playerObj)
        return getText("IGUI_health_Withdrawal")
    end,
    getDesc = function(playerObj)
        local key = levelDescKeys[EM_Withdrawal_GetLevel(playerObj)]
        if playerObj == nil or key == nil then
            return ""
        end
        return getText(key)
    end,
})
