-- Displays EM_Wound_* states directly on the health panel: each body
-- part row gets one "- <label>" line per manager state the part carries,
-- drawn in the same style as the vanilla wound lines (Scratched /
-- Laceration / Bitten / ...). A wound type def opts in with
-- panelLabelKey; the manager state IS what the panel shows for custom
-- part wounds (expired states disappear on their own).
--
-- Vanilla advances each row via doDrawItem's RETURN value (item.height
-- is only the highlight / hit-test box), so appending lines after the
-- original call and returning the advanced y is the correct hook.
--
-- client/Wound sorts before client/XpSystem alphabetically, so the
-- vanilla health panel is not loaded yet at this point -- explicit
-- require below.
require "XpSystem/ISUI/ISHealthPanel"

-- FONT_HGT_* are per-file LOCALS in every vanilla UI file, NOT globals --
-- each file computes its own
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- the wound lines are indented like the vanilla ones and drawn in a
-- burnt-orange between the vanilla red wound lines and the green
-- cataplasm lines
local LINE_INDENT = 15
local WOUND_LINE_R, WOUND_LINE_G, WOUND_LINE_B = 0.90, 0.52, 0.13

local origDoDrawItem = ISHealthBodyPartListBox.doDrawItem
function ISHealthBodyPartListBox:doDrawItem(y, item, alt)
    y = origDoDrawItem(self, y, item, alt)
    if item == nil or item.item == nil then
        return y
    end
    local bodyPart = item.item.bodyPart
    local patient = self.parent and self.parent.character
    if bodyPart == nil or patient == nil or EM_Wound_GetForPart == nil then
        return y
    end
    local woundIds = EM_Wound_GetForPart(patient, bodyPart)
    if #woundIds == 0 then
        return y
    end
    local x = LINE_INDENT
    local fontHgt = FONT_HGT_SMALL
    for i = 1, #woundIds do
        local def = EM_Wound_GetType(woundIds[i])
        if def ~= nil and def.panelLabelKey ~= nil then
            self:drawText("- " .. getText(def.panelLabelKey), x, y, WOUND_LINE_R, WOUND_LINE_G, WOUND_LINE_B, 1, UIFont.Small)
            y = y + fontHgt
        end
    end
    return y
end
