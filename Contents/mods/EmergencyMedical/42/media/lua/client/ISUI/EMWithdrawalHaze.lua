-- Client-only: withdrawal screen haze (the status values themselves live
-- in shared/Opioid/). Purely local-player, no server side.
--
-- A fullscreen dark vignette (media/ui/EMWithdrawalBlur.png) fades in
-- with the raw withdrawal value, up to the "HazeMaxAlpha" sandbox option
-- (default 0.87) at full withdrawal -- deliberately dark enough to
-- hamper play; 0 disables the haze. B42 has no Lua-reachable
-- true-blur postprocess: the vanilla drunk shader runs off the
-- INTOXICATION stat (drunk moodle / stagger / fall-down side effects we
-- do not want) and the glasses blurFactor has no setter, so the vignette
-- is the approximation.
--
-- Drawing follows the NVFramework night-vision overlay pattern (workshop
-- 3684087856): the panel is NEVER added to the UI manager -- an added
-- fullscreen panel takes part in UI mouse routing and swallows clicks
-- meant for other UI -- instead its render() is invoked manually from
-- OnPostUIDraw, with the mouse handler stubs and capture flags kept
-- defensively, matching the reference implementation.
--
-- History: a heartbeat (Lua mirror of IsoPlayer.updateHeartSound) and a
-- limp (writing the WalkInjury animation variable) were also built here
-- and removed again -- neither took effect in game. WalkInjury is
-- rewritten by IsoGameCharacter.calculateWalkSpeed() every frame, later
-- than any Lua event can write it; the FMOD instance handle from
-- playSoundImpl() apparently does not survive the Lua round-trip. Do not
-- re-add either without a Java-side plan.

require "ISUI/ISPanel"

local BLUR_TEXTURE = "media/ui/EMWithdrawalBlur.png"

local EMWithdrawalOverlayPanel = ISPanel:derive("EMWithdrawalOverlayPanel")

function EMWithdrawalOverlayPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o:setAlwaysOnTop(true)
    o:setCapture(false)
    o:setWantKeyEvents(false)
    o.mouseOver = false
    return o
end

function EMWithdrawalOverlayPanel:onMouseDown(x, y) return false end
function EMWithdrawalOverlayPanel:onMouseUp(x, y) return false end
function EMWithdrawalOverlayPanel:onMouseMove(dx, dy) return false end
function EMWithdrawalOverlayPanel:onMouseMoveOutside(dx, dy) return false end
function EMWithdrawalOverlayPanel:onRightMouseDown(x, y) return false end
function EMWithdrawalOverlayPanel:onRightMouseUp(x, y) return false end
function EMWithdrawalOverlayPanel:isMouseOver() return false end
function EMWithdrawalOverlayPanel:getMouseX() return -1 end
function EMWithdrawalOverlayPanel:getMouseY() return -1 end

function EMWithdrawalOverlayPanel:render()
    local player = getSpecificPlayer(0)
    if player == nil or not player:isLocalPlayer() or player:isDead() then
        return
    end
    local value = EM_Withdrawal_Get(player)
    if value <= 0.15 then
        return
    end
    local alpha = (value - 0.15) / 0.85 * EM_Sandbox_Get("HazeMaxAlpha")
    local tex = getTexture(BLUR_TEXTURE)
    if tex == nil then
        return
    end
    self:drawTextureScaled(tex, 0, 0, self.width, self.height, alpha)
end

local overlayPanel = nil

local function renderOverlay()
    local width = getCore():getScreenWidth()
    local height = getCore():getScreenHeight()
    -- create on demand; recreate when the resolution changes
    if overlayPanel == nil or overlayPanel.width ~= width or overlayPanel.height ~= height then
        overlayPanel = EMWithdrawalOverlayPanel:new(0, 0, width, height)
        overlayPanel:initialise()
    end
    overlayPanel:render()
end

if EM_Withdrawal_Get ~= nil then
    Events.OnPostUIDraw.Add(renderOverlay)
end
