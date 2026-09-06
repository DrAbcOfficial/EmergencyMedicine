-- Client-only: display the Addiction status on the vanilla health
-- panel, right below the body part listbox (same column and style as the
-- vanilla fracture/symptom lines -- see ISHealthBodyPartListBox:doDrawItem).
-- NOTE: UI_BORDER_SPACING is a *local* in the vanilla ISHealthPanel.lua,
-- so define our own to avoid a nil addition crash.
if not ISHealthPanel then
    return
end

local UI_BORDER_SPACING = 10

local ISHealthPanel_render = ISHealthPanel.render
function ISHealthPanel:render()
    ISHealthPanel_render(self)
    if self.character == nil or not self.character:isLocalPlayer() then
        return
    end
    if self.healthPanel == nil or self.listbox == nil then
        return
    end
    local addiction = EM_Addiction_Get(self.character)
    if addiction <= 0 then
        return
    end
    local severe = EM_Addiction_IsSevere(self.character)
    local x = self.healthPanel:getRight() + UI_BORDER_SPACING
    local y = self.listbox:getY() + self.listbox:getHeight() + 2
    if severe then
        self:drawText("- " .. getText("IGUI_health_AddictionSevere"), x, y, 0.89, 0.28, 0.28, 1, UIFont.Small)
    else
        self:drawText("- " .. getText("IGUI_health_Addiction"), x, y, 1, 0.58, 0, 1, UIFont.Small)
    end
end
