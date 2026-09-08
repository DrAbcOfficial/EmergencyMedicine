-- Drug side-effect status icons: glue between the EM_DrugFx statuses
-- (DrugHeadache / DrugFever / ShoddySedation / Somnolence /
-- CoughSuppress -- records in shared/Status/DrugEffect/
-- DrugEffectStatus.lua, ticked by DrugEffectSimulation.lua) and
-- EMStatusIcons. The icon level IS the status's progress quartile --
-- every dose stacks the sandbox gain, so more pills = a higher level,
-- matching the floor scaling in the simulation. CoughSuppress is the
-- one GOOD status (green tint): its suppression is binary, the level
-- is informational. The file name sorts AFTER EMStatusIcons.lua on
-- purpose (alphabetical load order -- an "A"/"D" prefix would load
-- first and hit the nil guard). Icons are externally provided assets
-- (media/ui/Moodles/, with 128\ variants).

if EMStatusIcons == nil then
    return
end

local function registerDrugStatus(id, iconFile, tintColor)
    local descKeys = EMStatusIcons.LevelDescKeys("IGUI_health_" .. id .. "Desc")
    EMStatusIcons.RegisterStatus(id, {
        icon = "media/ui/Moodles/" .. iconFile,
        tintColor = tintColor or "bad",
        getLevel = function(playerObj)
            local p = EMStatusIcons.LocalPlayer(playerObj)
            if p == nil then
                return 0
            end
            return EM_DrugFx_GetLevel(p, id)
        end,
        getName = function()
            return getText("IGUI_health_" .. id)
        end,
        getDesc = function(playerObj)
            local key = descKeys[EM_DrugFx_GetLevel(playerObj, id)]
            if key == nil then
                return ""
            end
            return getText(key)
        end,
    })
end

registerDrugStatus("DrugHeadache", "HeadacheIcon.png")
registerDrugStatus("DrugFever", "FeverIcon.png")
registerDrugStatus("ShoddySedation", "InferiorSedativeIcon.png")
registerDrugStatus("Somnolence", "SomnolenceIcon.png")

-- the good status: the dextromethorphan cough suppression, split out of
-- somnolence. Binary effect (the simulation holds the sneeze countdown
-- while any progress remains), so one fixed description instead of the
-- level table.
EMStatusIcons.RegisterStatus("CoughSuppress", {
    icon = "media/ui/Moodles/CoughSuppressIcon.png",
    tintColor = "good",
    getLevel = function(playerObj)
        local p = EMStatusIcons.LocalPlayer(playerObj)
        if p == nil then
            return 0
        end
        return EM_DrugFx_GetLevel(p, "CoughSuppress")
    end,
    getName = function()
        return getText("IGUI_health_CoughSuppress")
    end,
    getDesc = function()
        return getText("IGUI_health_CoughSuppressDesc")
    end,
})
