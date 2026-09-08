-- Drug side-effect status icons: glue between the four EM_DrugFx
-- statuses (DrugHeadache / DrugFever / ShoddySedation / CoughSuppress
-- -- records in shared/Status/DrugEffect/DrugEffectStatus.lua, ticked
-- by DrugEffectSimulation.lua) and EMStatusIcons. The icon level IS
-- the status's progress quartile -- every dose stacks the sandbox
-- gain, so more pills = a worse level, matching the floor scaling in
-- the simulation. The file name sorts AFTER
-- EMStatusIcons.lua on purpose (alphabetical load order -- an "A"/"D"
-- prefix would load first and hit the nil guard). Icons are externally
-- provided assets (media/ui/Moodles/, with 128\ variants).

if EMStatusIcons == nil then
    return
end

local function localPlayer(playerObj)
    if playerObj == nil or not playerObj:isLocalPlayer() then
        return nil
    end
    return playerObj
end

local function registerDrugStatus(id, iconFile)
    local descKeys = {
        [1] = "IGUI_health_" .. id .. "DescMild",
        [2] = "IGUI_health_" .. id .. "DescModerate",
        [3] = "IGUI_health_" .. id .. "DescSevere",
        [4] = "IGUI_health_" .. id .. "DescExtreme",
    }
    EMStatusIcons.RegisterStatus(id, {
        icon = "media/ui/Moodles/" .. iconFile,
        tintColor = "bad",
        getLevel = function(playerObj)
            local p = localPlayer(playerObj)
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
registerDrugStatus("CoughSuppress", "SomnolenceIcon.png")
