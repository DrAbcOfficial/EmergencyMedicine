-- Client-only: generic moodle-column status icon manager.
-- Renders any number of registered status icons in the vanilla moodle
-- column (below the vanilla moodles, next to any Lifestyle statuses).
-- Icon size follows the vanilla moodle size option.
--
-- Registration API:
--   EMStatusIcons.RegisterStatus("MyStatus", {
--       icon = "media/ui/Moodles/MyStatusIcon.png",
--       getLevel = function(player) return 0..4 end,
--       getName = function(player) return string end,
--       getDesc = function(player) return string end,
--   })
-- The level 0 means hidden; badge tint follows the "bad" palettes
-- (level 1..4 draws the background in red-ish, good statuses can pass
-- tinteColor="green" instead).

if not ISPanelJoypad then
    return
end

require "ISUI/ISPanelJoypad"

EMStatusIcons = EMStatusIcons or {}
EMStatusIcons.statuses = {}

local moodleSizes = { 32, 48, 64, 80, 96, 128 }

local function getMoodleSize(optionValue)
    local index = (optionValue or 1) - 1
    if index < 0 then
        index = 0
    end
    if index >= #moodleSizes then
        index = #moodleSizes - 1
    end
    return moodleSizes[index + 1] or 32
end

local function getCurrentMoodleSize()
    if UIManager ~= nil and UIManager.getMoodleUI ~= nil then
        local moodleUI = UIManager.getMoodleUI(0)
        if moodleUI ~= nil then
            local ok, width = pcall(function() return moodleUI:getWidth() end)
            if ok and width ~= nil and width > 0 then
                return width
            end
        end
    end
    return getMoodleSize(getCore() and getCore():getOptionMoodleSize())
end

-- Mirror the vanilla MoodlesUI slot allocation exactly: iterate every
-- registered MoodleType (base + any mod-registered) and count those the
-- vanilla column would render. Vanilla hides FOOD_EATEN below level 3
-- (MoodlesUI.update: level < MoodleLevel.HighMoodleLevel.ordinal()).
local function countVanillaMoodles(player)
    local count = 0
    local moodles = player:getMoodles()
    local allTypes = Registries.MOODLE_TYPE:values()
    for i = 0, allTypes:size() - 1 do
        local moodleType = allTypes:get(i)
        local level = moodles:getMoodleLevel(moodleType)
        if level > 0 and not (moodleType == MoodleType.FOOD_EATEN and level < 3) then
            count = count + 1
        end
    end
    return count
end

local function countLifestyleMoodles(player)
    if not LSMoodleManager then
        return 0
    end
    local data = player:getModData().LSMoodles
    if data == nil then
        return 0
    end
    local count = 0
    for k, v in pairs(data) do
        if v ~= nil and v.Level ~= nil and v.Level ~= 0 then
            count = count + 1
        end
    end
    return count
end

EMStatusManager = ISPanelJoypad:derive("EMStatusManager")

function EMStatusManager:new()
    local o = ISPanelJoypad.new(self, 0, 0)
    o.width = 32
    o.height = 32
    o.backgroundColor = 0.0
    o.levelList = {}
    o.baseY = 120
    o.distY = 42
    o.size = 32
    return o
end

function EMStatusManager:update()
    local player = getSpecificPlayer(0)
    if player == nil or not player:isLocalPlayer() then
        self:setVisible(false)
        return
    end
    local size = getCurrentMoodleSize()
    self.size = size
    self.distY = 10 + size
    self.width = size
    self.height = size
    local statuses = EMStatusIcons.statuses
    local list = {}
    for i = 1, #statuses do
        local status = statuses[i]
        local level = status.getLevel and status.getLevel(player) or 0
        if level > 0 then
            list[#list + 1] = { status = status, level = level }
        end
    end
    self.levelList = list
    if #list == 0 then
        self:setVisible(false)
        return
    end
    self:setVisible(true)
    local count = countVanillaMoodles(player) + countLifestyleMoodles(player)
    local x = getCore():getScreenWidth() - 10 - size
    local y = getPlayerScreenTop(0) + 120 + (self.distY * count)
    self:setX(x)
    self:setY(y)
end

function EMStatusManager:render()
    local list = self.levelList
    if #list == 0 then
        return
    end
    local size = self.size
    local bgTex = getTexture("media/ui/Moodles/" .. size .. "/_Moodles_BGsolid.png")
    local borderTex = getTexture("media/ui/Moodles/" .. size .. "/_Moodles_BGoutline.png")
    if bgTex == nil then
        bgTex = getTexture("media/ui/Moodles/32/_Moodles_BGsolid.png")
    end
    if borderTex == nil then
        borderTex = getTexture("media/ui/Moodles/32/_Moodles_BGoutline.png")
    end
    if bgTex == nil or borderTex == nil then
        return
    end
    local badColor = getCore():getBadHighlitedColor()
    local goodColor = getCore():getGoodHighlitedColor()
    for i = 1, #list do
        local entry = list[i]
        local status = entry.status
        local colorLevel = entry.level / 4
        local baseColor = status.tintColor == "good" and goodColor or badColor
        local gray = Color.gray
        local r = gray:getRedFloat() * (1 - colorLevel) + baseColor:getR() * colorLevel
        local g = gray:getGreenFloat() * (1 - colorLevel) + baseColor:getG() * colorLevel
        local b = gray:getBlueFloat() * (1 - colorLevel) + baseColor:getB() * colorLevel
        local iconTex = getTexture(status.icon)
        local slot = self.distY * (i - 1)
        self:drawTextureScaled(bgTex, 0, slot, size, size, 1, r, g, b)
        self:drawTextureScaled(borderTex, 0, slot, size, size, 1)
        if iconTex ~= nil then
            self:drawTextureScaled(iconTex, 0, slot, size, size, 1, 1, 1, 1)
        end
    end
end

function EMStatusManager:renderTooltip()
    local list = self.levelList
    if #list == 0 then
        return
    end
    local size = self.size
    local mX, mY = getMouseX(), getMouseY()
    local idx = 0
    for i = 1, #list do
        local slotY = self:getY() + self.distY * (i - 1)
        if mX >= self:getX() and mX <= self:getX() + size and mY >= slotY and mY <= slotY + size then
            idx = i
            break
        end
    end
    if idx == 0 then
        return
    end
    local entry = list[idx]
    local player = getSpecificPlayer(0)
    local title = entry.status.getName and entry.status.getName(player) or ""
    local description = entry.status.getDesc and entry.status.getDesc(player) or ""
    local font = UIFont.Small
    local titleW = getTextManager():MeasureStringX(font, title) + 7
    local descW = getTextManager():MeasureStringX(font, description) + 7
    local boxW = math.max(titleW, descW)
    local fontHgt = getTextManager():getFontHeight(font)
    local h = (2 + fontHgt) * 2
    local slot = self.distY * (idx - 1)
    local y = slot + 1
    if size > h then
        y = y + math.floor((size - h) / 2)
    end
    self:drawRect(-10 - boxW - 6, y - 2, boxW + 12, h, 0.6, 0, 0, 0)
    self:drawTextRight(title, -10, y, 1, 1, 1, 1, font)
    self:drawTextRight(description, -10, y + fontHgt, 0.8, 0.8, 0.8, 1, font)
end

function EMStatusManager:prerender()
    self:renderTooltip()
end

function EMStatusIcons.RegisterStatus(id, options)
    if options == nil or (options.getLevel == nil) then
        return
    end
    for i = 1, #EMStatusIcons.statuses do
        if EMStatusIcons.statuses[i].id == id then
            EMStatusIcons.statuses[i] = options
            options.id = id
            return
        end
    end
    options.id = id
    EMStatusIcons.statuses[#EMStatusIcons.statuses + 1] = options
end

EMStatusManager.instance = nil

local function createStatusManager()
    if EMStatusManager.instance ~= nil then
        return
    end
    local player = getSpecificPlayer(0)
    if player == nil then
        return
    end
    local manager = EMStatusManager:new()
    manager:initialise()
    manager:addToUIManager()
    EMStatusManager.instance = manager
end

local function removeStatusManager()
    if EMStatusManager.instance ~= nil then
        EMStatusManager.instance:removeFromUIManager()
        EMStatusManager.instance = nil
    end
end

Events.OnCreatePlayer.Add(createStatusManager)
Events.OnPlayerDeath.Add(removeStatusManager)
