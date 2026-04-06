









---Keyboard button display overlay.
-- 
-- Overlay type which displays a keyboard key button symbol.
local ButtonOverlay_mt = Class(ButtonOverlay)


---
function ButtonOverlay.new(customMt)
    local self = setmetatable({}, customMt or ButtonOverlay_mt)

    self.textSizeFactor = 0.55 -- ratio of text size to button height
    self.textYOffsetFactor = 0.17 -- compensates base line offset for size factor 0.5 TODO: get proper vertical alignment from engine in renderText()

    self.buttonScaleOverlay = g_overlayManager:createOverlay("gui.button_middle", 0, 0, 0, 0)
    self.buttonLeftOverlay = g_overlayManager:createOverlay("gui.button_left", 0, 0, 0, 0)
    self.buttonRightOverlay = g_overlayManager:createOverlay("gui.button_right", 0, 0, 0, 0)
    self.buttonLeftWidthToHeightRatio = 6 / 25 -- 6px width, 25px height
    self.leftRightPaddingHeightRatio = 12 / 25

    self:setColor(1, 1, 1, 1)

    self.minWidth = nil

    self.debugEnabled = nil

    return self
end


---Delete this button overlay.
function ButtonOverlay:delete()
    if self.buttonScaleOverlay ~= nil then
        self.buttonScaleOverlay:delete()
        self.buttonScaleOverlay = nil
    end
    if self.buttonLeftOverlay ~= nil then
        self.buttonLeftOverlay:delete()
        self.buttonLeftOverlay = nil
    end
    if self.buttonRightOverlay ~= nil then
        self.buttonRightOverlay:delete()
        self.buttonRightOverlay = nil
    end
end


---Set this overlay's background color.
-- @param float? r Red channel for text [0, 1]
-- @param float? g Green channel for text [0, 1]
-- @param float? b Blue channel for text [0, 1]
-- @param float? a Alpha (transparency) channel for text [0, 1], 0 is fully transparent, 1 is opaque
-- @param float? r2 Red channel for background [0, 1], if nil "r" will be used
-- @param float? g2 Green channel for background [0, 1], if nil "g" will be used
-- @param float? b2 Blue channel for background [0, 1], if nil "b" will be used
-- @param float? a2 Alpha (transparency) channel for background [0, 1], 0 is fully transparent, 1 is opaque, if nil "a" will be used
function ButtonOverlay:setColor(r, g, b, a, r2, g2, b2, a2)
    self.r = r or self.r
    self.g = g or self.g
    self.b = b or self.b
    self.a = a or self.a

    self.r2 = r2 or self.r2 or r
    self.g2 = g2 or self.g2 or g
    self.b2 = b2 or self.b2 or b
    self.a2 = a2 or self.a2 or a

    if self.buttonScaleOverlay ~= nil then
        self.buttonScaleOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
    end
    if self.buttonLeftOverlay ~= nil then
        self.buttonLeftOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
    end
    if self.buttonRightOverlay ~= nil then
        self.buttonRightOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
    end
end




















---Render this overlay with the given parameters.
-- @param buttonText Text to display as the key value, e.g. "A", "Space", "Ctrl", etc.
-- @param posX Screen x position
-- @param posY Screen y position
-- @param height Button display height
function ButtonOverlay:renderButton(buttonText, posX, posY, height, colorText, clipX1, clipY1, clipX2, clipY2, customOffsetLeft, customButtonInputText)
    customOffsetLeft = customOffsetLeft or 0
    buttonText = utf8ToUpper(tostring(buttonText))

    local width, widthNoOffset = self:getButtonWidth(buttonText, height, customOffsetLeft, customButtonInputText)
    self:renderBackground(posX, posY, width, height, clipX1, clipY1, clipX2, clipY2)

    local textSize = height * self.textSizeFactor
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
    if clipX1 ~= nil then
        setTextClipArea(clipX1, clipY1, clipX2, clipY2)
    end

    if colorText then
        setTextColor(self.r, self.g, self.b, self.a)
    else
        setTextColor(1, 1, 1, self.a)
    end

    local textPosX = self.buttonRightOverlay.x + self.buttonRightOverlay.width - widthNoOffset*0.5-- + customOffsetLeft
    local textPosY = posY + height * 0.5 + textSize * self.textYOffsetFactor
    renderText(textPosX, textPosY, textSize, buttonText)-- + textSize * self.textYOffsetFactor

    setTextAlignment(RenderText.ALIGN_LEFT)
    if customButtonInputText ~= nil then
        setTextColor(0.5, 0.5, 0.5, 1)
        renderText(self.buttonScaleOverlay.x, textPosY, textSize, customButtonInputText)
    end

    if clipX1 ~= nil then
        setTextClipArea(0, 0, 1, 1)
    end
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)

    local totalWidth = self.buttonRightOverlay.x + self.buttonRightOverlay.width - self.buttonLeftOverlay.x

    if self.debugEnabled or g_uiDebugEnabled then
        setOverlayColor(GuiElement.debugOverlay, 1, 0, 1, 0.5)

        renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY - g_pixelSizeY, totalWidth + 2 * g_pixelSizeX, g_pixelSizeY)
        renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY + height, totalWidth + 2 * g_pixelSizeX, g_pixelSizeY)
        renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY, g_pixelSizeX, height)
        renderOverlay(GuiElement.debugOverlay, posX + totalWidth, posY, g_pixelSizeX, height)
    end

    return totalWidth
end


---Get the total display width of this button overlay for a given button text and height
function ButtonOverlay:getButtonWidth(buttonText, height, customOffsetLeft, customButtonInputText)
    customOffsetLeft = customOffsetLeft or 0
    local textSize = height * self.textSizeFactor

    setTextBold(true)
    buttonText = utf8ToUpper(tostring(buttonText))
    local textWidth = getTextWidth(textSize, buttonText)
    local textWidthCustom = 0
    if customButtonInputText ~= nil then
        textWidthCustom = getTextWidth(textSize, customButtonInputText)
    end
    setTextBold(false)

    local leftRightPadding = (height*self.leftRightPaddingHeightRatio) / g_screenAspectRatio

    local widthNoOffset = textWidth + 2*leftRightPadding
    local width = widthNoOffset + customOffsetLeft + textWidthCustom

    if self.minWidth ~= nil then
        width = math.max(width, self.minWidth)
        widthNoOffset = math.max(widthNoOffset, self.minWidth)
    end

    return width, widthNoOffset
end
