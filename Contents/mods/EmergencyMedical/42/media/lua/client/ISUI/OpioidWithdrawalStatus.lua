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

EMStatusIcons.RegisterStatus("OpioidWithdrawal", {
    moodleType = EM_Withdrawal_GetMoodleType(),
    icon = "media/ui/Moodles/WithdrawalIcon.png",
    tintColor = "bad",
    getLevel = function(playerObj)
        if EMStatusIcons.LocalPlayer(playerObj) == nil then
            return 0
        end
        return EM_Withdrawal_GetLevel(playerObj)
    end,
    getName = function(playerObj)
        return getText("IGUI_health_Withdrawal")
    end,
    getDesc = function(playerObj)
        local key = EMStatusIcons.LevelDescKeys("IGUI_health_WithdrawalDesc")[EM_Withdrawal_GetLevel(playerObj)]
        if playerObj == nil or key == nil then
            return ""
        end
        return getText(key)
    end,
})
