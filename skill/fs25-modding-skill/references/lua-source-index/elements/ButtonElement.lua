

























---Clickable button element.
-- 
-- Used layers: "image" for the background, "icon" for a button glyph.
-- 
-- All button UI callbacks do not require or provide any arguments.
local ButtonElement_mt = Class(ButtonElement, TextElement)





---
function ButtonElement.new(target, custom_mt)
    local self = TextElement.new(target, custom_mt or ButtonElement_mt)
    self:include(PlaySampleMixin) -- add sound playing

    self.inputDown = false
    self.forceFocus = false
    self.overlay = {}
    self.icon = {}
    self.touchIcon = {}
    self.iconSize = {0,0}
    self.touchIconSize = {0,0}
    self.gamepadIconSize = {getNormalizedScreenValues(60, 60)}
    self.iconTextOffset = {0,0}
    self.focusedTextOffset = {0,0}
    self.needExternalClick = false -- used to override focus behaviour in special cases
    self.clickSoundName = GuiSoundPlayer.SOUND_SAMPLES.CLICK
    self.fitToContent = false
    self.fitExtraWidth = 0
    self.hideKeyboardGlyph = false
    self.isTouchButton = false
    self.isTouchButtonWithBg = false
    self.gamepadUsesTouchButton = false
    self.addTouchArea = true
    self.isTriggerableByGlobalAction = true
    self.ignorePressedOverlayState = false
    self.pressed = false
    self.sendActionOnRelease = true

    self.textAlignment = RenderText.ALIGN_CENTER
    self.textSeparator = nil

    self.inputActionName = nil -- name of input action whose primary input binding will be displayed as a glyph, if set
    self.hasLoadedInputGlyph = false
    self.isKeyboardMode = false
    self.keyDisplayText = nil -- resolved key display text for the input action
    self.keyOverlay = nil -- holds a shared keyboard key glyph display overlay, do not delete!
    self.keyGlyphOffsetX = 0 -- additional text offset when displaying keyboard key glyph
    self.keyGlyphSize = {0, 0}
    self.iconColors = {color={1, 1, 1, 1}} -- holds overlay color information for keyboard key glyph display
    self.iconImageSize = {2048, 2048}
    self.drawChildrenLast = false

    return self
end


---
function ButtonElement:delete()
    GuiOverlay.deleteOverlay(self.touchIcon)
    GuiOverlay.deleteOverlay(self.overlay)
    GuiOverlay.deleteOverlay(self.icon)

    ButtonElement:superClass().delete(self)
end


---
function ButtonElement:loadFromXML(xmlFile, key)
    ButtonElement:superClass().loadFromXML(self, xmlFile, key)

    self:addCallback(xmlFile, key.."#onClick", "onClickCallback")
    self:addCallback(xmlFile, key.."#onFocus", "onFocusCallback")
    self:addCallback(xmlFile, key.."#onLeave", "onLeaveCallback")
    self:addCallback(xmlFile, key.."#onHighlight", "onHighlightCallback")
    self:addCallback(xmlFile, key.."#onHighlightRemove", "onHighlightRemoveCallback")
    self:addCallback(xmlFile, key.."#onSizeChanged", "onSizeChangedCallback")

    GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)

    self.iconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#iconSize"), self.iconSize)
    self.touchIconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#touchIconSize"), self.touchIconSize)
    self.gamepadIconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#gamepadIconSize"), self.gamepadIconSize)
    self.iconTextOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#iconTextOffset"), self.iconTextOffset)
    self.forceFocus = Utils.getNoNil(getXMLBool(xmlFile, key.."#forceFocus"), self.forceFocus)
    self.needExternalClick = Utils.getNoNil(getXMLBool(xmlFile, key.."#needExternalClick"), self.needExternalClick)
    self.fitToContent = Utils.getNoNil(getXMLBool(xmlFile, key.."#fitToContent"), self.fitToContent)
    self.fitExtraWidth = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key.."#fitExtraWidth"), self.fitExtraWidth)
    self.hideKeyboardGlyph = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideKeyboardGlyph"), self.hideKeyboardGlyph)
    self.isTouchButton = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTouchButton"), self.isTouchButton)
    self.isTouchButtonWithBg = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTouchButtonWithBg"), self.isTouchButtonWithBg)
    self.gamepadUsesTouchButton = Utils.getNoNil(getXMLBool(xmlFile, key .. "#gamepadUsesTouchButton"), self.gamepadUsesTouchButton)
    self.addTouchArea = Utils.getNoNil(getXMLBool(xmlFile, key .. "#addTouchArea"), self.addTouchArea)
    self.touchAreaColor = GuiUtils.getColorArray(getXMLString(xmlFile, key.."#touchAreaColor"), self.touchAreaColor)
    self.isTriggerableByGlobalAction = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTriggerableByGlobalAction"), self.isTriggerableByGlobalAction)
    self.ignorePressedOverlayState = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignorePressedOverlayState"), self.ignorePressedOverlayState)
    self.sendActionOnRelease = Utils.getNoNil(getXMLBool(xmlFile, key .. "#sendActionOnRelease"), self.sendActionOnRelease)
    self.textSeparator = Utils.getNoNil(getXMLString(xmlFile, key .. "#textSeparator"), self.textSeparator)
    self.drawChildrenLast = Utils.getNoNil(getXMLBool(xmlFile, key .. "#drawChildrenLast"), self.drawChildrenLast)

    local inputActionName = getXMLString(xmlFile, key .. "#inputAction")
    if inputActionName ~= nil and InputAction[inputActionName] ~= nil then
        self.inputActionName = inputActionName
        self:loadInputGlyphColors(nil, xmlFile, key)
    else
        self.iconImageSize = string.getVector(getXMLString(xmlFile, key.."#iconImageSize"), 2) or self.iconImageSize
        GuiOverlay.loadOverlay(self, self.icon, "icon", self.iconImageSize, nil, xmlFile, key)
        GuiOverlay.createOverlay(self.icon)
    end

    if (self.isTouchButton or self.isTouchButtonWithBg or self.gamepadUsesTouchButton) and Platform.isMobile then
        GuiOverlay.loadOverlay(self, self.touchIcon, "touchIcon", self.imageSize, nil, xmlFile, key)
        GuiOverlay.createOverlay(self.touchIcon)
    end

    local sampleName = getXMLString(xmlFile, key .. "#clickSound") or self.clickSoundName
    local resolvedSampleName = GuiSoundPlayer.SOUND_SAMPLES[sampleName]
    if resolvedSampleName ~= nil then
        self.clickSoundName = resolvedSampleName
    end

    GuiOverlay.createOverlay(self.overlay)

    self:updateSize()
end


---
function ButtonElement:loadProfile(profile, applyProfile)
    ButtonElement:superClass().loadProfile(self, profile, applyProfile)

    GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, nil)

    local inputActionName = profile:getValue("inputAction", self.inputActionName)
    if inputActionName ~= nil and InputAction[inputActionName] ~= nil then
        self.inputActionName = inputActionName
        self:loadInputGlyphColors(profile, nil, nil)
    else
        local iconImageSizeStr = profile:getValue("iconImageSize")
        if not string.isNilOrWhitespace(iconImageSizeStr) then
            self.iconImageSize = string.getVector(iconImageSizeStr, 2)
        end
        GuiOverlay.loadOverlay(self, self.icon, "icon", self.iconImageSize, profile, nil, nil)
        GuiOverlay.createOverlay(self.icon)
    end

    if (self.isTouchButton or self.isTouchButtonWithBg or self.gamepadUsesTouchButton) and Platform.isMobile then
        GuiOverlay.loadOverlay(self, self.touchIcon, "touchIcon", self.imageSize, profile, nil, nil)
        GuiOverlay.createOverlay(self.touchIcon)
    end

    self.iconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("iconSize"), self.iconSize)
    self.touchIconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("touchIconSize"), self.touchIconSize)
    self.gamepadIconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("gamepadIconSize"), self.gamepadIconSize)
    self.iconTextOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("iconTextOffset"), self.iconTextOffset)

    self.forceFocus = profile:getBool("forceFocus", self.forceFocus)
    self.needExternalClick = profile:getBool("needExternalClick", self.needExternalClick)
    self.fitToContent = profile:getBool("fitToContent", self.fitToContent)
    self.fitExtraWidth = GuiUtils.getNormalizedXValue(profile:getValue("fitExtraWidth"), self.fitExtraWidth)
    self.hideKeyboardGlyph = profile:getBool("hideKeyboardGlyph", self.hideKeyboardGlyph)
    self.isTouchButton = profile:getBool("isTouchButton", self.isTouchButton)
    self.isTouchButtonWithBg = profile:getBool("isTouchButtonWithBg", self.isTouchButtonWithBg)
    self.gamepadUsesTouchButton = profile:getBool("gamepadUsesTouchButton", self.gamepadUsesTouchButton)
    self.addTouchArea = profile:getBool("addTouchArea", self.addTouchArea)
    self.touchAreaColor = GuiUtils.getColorArray(profile:getValue("touchAreaColor"))
    self.isTriggerableByGlobalAction = profile:getBool("isTriggerableByGlobalAction", self.isTriggerableByGlobalAction)
    self.ignorePressedOverlayState = profile:getBool("ignorePressedOverlayState", self.ignorePressedOverlayState)
    self.sendActionOnRelease = profile:getBool("sendActionOnRelease", self.sendActionOnRelease)
    self.textSeparator = profile:getValue("textSeparator", self.textSeparator)
    self.drawChildrenLast = profile:getBool("drawChildrenLast", self.drawChildrenLast)

    local sampleName = profile:getValue("clickSound", self.clickSoundName)
    local resolvedSampleName = GuiSoundPlayer.SOUND_SAMPLES[sampleName]
    if resolvedSampleName ~= nil then
        self.clickSoundName = resolvedSampleName
    end

    GuiOverlay.createOverlay(self.overlay)

    if applyProfile then
        self:updateSize()
    end
end


---
function ButtonElement:copyAttributes(src)
    ButtonElement:superClass().copyAttributes(self, src)

    GuiOverlay.copyOverlay(self.overlay, src.overlay)
    GuiOverlay.copyOverlay(self.icon, src.icon)
    if (src.isTouchButton or src.isTouchButtonWithBg or self.gamepadUsesTouchButton) and Platform.isMobile then
        GuiOverlay.copyOverlay(self.touchIcon, src.touchIcon)
        self.touchIconSize = table.clone(src.touchIconSize)
        self.gamepadIconSize = table.clone(src.gamepadIconSize)
    end

    self.iconSize = table.clone(src.iconSize)
    self.iconTextOffset = table.clone(src.iconTextOffset)
    self.forceFocus = src.forceFocus
    self.needExternalClick = src.needExternalClick
    self.inputActionName = src.inputActionName
    self.clickSoundName = src.clickSoundName
    self.hideKeyboardGlyph = src.hideKeyboardGlyph
    self.fitExtraWidth = src.fitExtraWidth
    self.fitToContent = src.fitToContent
    self.isTouchButton = src.isTouchButton
    self.isTouchButtonWithBg = src.isTouchButtonWithBg
    self.gamepadUsesTouchButton = src.gamepadUsesTouchButton
    self.addTouchArea = src.addTouchArea
    self.touchAreaColor = src.touchAreaColor
    self.isTriggerableByGlobalAction = src.isTriggerableByGlobalAction
    self.ignorePressedOverlayState = src.ignorePressedOverlayState
    self.sendActionOnRelease = src.sendActionOnRelease
    self.textSeparator = src.textSeparator
    self.drawChildrenLast = src.drawChildrenLast
    self.iconColors = src.iconColors
    self.pressed = src.pressed

    self.onClickCallback = src.onClickCallback
    self.onLeaveCallback = src.onLeaveCallback
    self.onFocusCallback = src.onFocusCallback
    self.onHighlightCallback = src.onHighlightCallback
    self.onHighlightRemoveCallback = src.onHighlightRemoveCallback
    self.onSizeChangedCallback = src.onSizeChangedCallback

    GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end


---Load glyph overlay colors.
-- @param profile If set, loads overlay properties from this button's GUI profile
-- @param xmlFile If set, loads overlay properties from this button's XML configuration
-- @param key XML base configuration node of this button
function ButtonElement:loadInputGlyphColors(profile, xmlFile, key)
    if xmlFile ~= nil then
        GuiOverlay.loadXMLColors(xmlFile, key, self.icon, "icon")
        GuiOverlay.loadXMLColors(xmlFile, key, self.iconColors, "iconBg")
    elseif profile ~= nil then
        GuiOverlay.loadProfileColors(profile, self.icon, "icon")
        GuiOverlay.loadProfileColors(profile, self.iconColors, "iconBg")
    end
end

































---Set the input mode flag.
function ButtonElement:setInputMode(isKeyboardMode, isTouchMode, isGamepadMode)
    local didChange = false

    if self.isKeyboardMode ~= isKeyboardMode then
        self.isKeyboardMode = isKeyboardMode
        didChange = true

        if not self.hasLoadedInputGlyph then
            self:loadInputGlyph()
        end
    end
    if self.isGamepadMode ~= isGamepadMode then
        self.isGamepadMode = isGamepadMode
        didChange = true

        if not self.hasLoadedInputGlyph then
            self:loadInputGlyph()
        end
    end
    if self.isTouchMode ~= isTouchMode and (self.isTouchButton or self.isTouchButtonWithBg) then
        self.isTouchMode = isTouchMode
        didChange = true
    end

    if didChange then
        self:updateSize()
    end
end


---
function ButtonElement:setAlpha(alpha)
    ButtonElement:superClass().setAlpha(self, alpha)
    if self.overlay ~= nil then
        self.overlay.alpha = self.alpha
    end
    if self.icon ~= nil then
        self.icon.alpha = self.alpha
    end
end


---
function ButtonElement:setDisabled(disabled)
    ButtonElement:superClass().setDisabled(self, disabled)

    if disabled then
        FocusManager:unsetFocus(self)
        self.inputEntered = false
        self:raiseCallback("onLeaveCallback", self)
        self.inputDown = false
    end
end


---Set the input action for the display glyph by name.
function ButtonElement:setInputAction(inputActionName)
    if inputActionName ~= nil and InputAction[inputActionName] ~= nil then
        self.inputActionName = inputActionName
        self:loadInputGlyph(true) -- true -> force reloading the overlay
    end
end


---
function ButtonElement:onOpen()
    ButtonElement:superClass().onOpen(self)

    -- deferred loading of input glyph, so that not having a controller plugged in does not break the UI on loading:
    if self.inputActionName ~= nil then
        self.hasLoadedInputGlyph = false
        self:loadInputGlyph(true)
    end
end


---
function ButtonElement:onClose()
    ButtonElement:superClass().onClose(self)
    self:reset()
end


---
function ButtonElement:reset()
    ButtonElement:superClass().reset(self)

    self:setPressed(false)
    self:setFocused(false)
    self:setHighlighted(false)
    self.inputDown = false
end


---
function ButtonElement:setImageFilename(filename, iconFilename)
    if filename ~= nil then
        self.overlay = GuiOverlay.createOverlay(self.overlay, filename)
    end
    if iconFilename ~= nil then
        self.icon = GuiOverlay.createOverlay(self.icon, iconFilename)
    end
end


---Set UV coordinates for the button background and/or icon.
function ButtonElement:setImageUVs(backgroundUVs, iconUVs)
    if backgroundUVs ~= nil then
        self.overlay.uvs = backgroundUVs
    end

    if iconUVs ~= nil then
        self.icon.uvs = iconUVs
    end
end


---Set slice id for the button background and/or icon.
function ButtonElement:setImageSlice(backgroundSliceId, iconSliceId)
    local backgroundSlice = g_overlayManager:getSliceInfoById(backgroundSliceId)
    local iconSlice = g_overlayManager:getSliceInfoById(iconSliceId)

    local backgroundUVs = backgroundSlice ~= nil and backgroundSlice.uvs or nil
    local backgroundFilename = backgroundSlice ~= nil and backgroundSlice.filename or nil
    local iconUVs = iconSlice ~= nil and iconSlice.uvs or nil
    local iconFilename = iconSlice ~= nil and iconSlice.filename or nil

    self:setImageUVs(backgroundUVs, iconUVs)
    self:setImageFilename(backgroundFilename, iconFilename)
end


---
function ButtonElement:getIsActive()
    local baseActive = ButtonElement:superClass().getIsActive(self)
    return baseActive and self.onClickCallback ~= nil
end


---
function ButtonElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() then
        eventUsed = eventUsed or ButtonElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)

        -- handle highlight regardless of event used state
        local clickInElement = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], self.hotspot)
        if clickInElement then
            if not self.inputEntered then     -- set highlight on mouse over without focus
                if self.handleFocus and not self:getIsHighlighted() then
                    FocusManager:setHighlight(self)
                end

                self.inputEntered = true
            end
        else -- mouse event outside button
            self.inputDown = false
            self.inputEntered = false

            if self:getIsHighlighted() and (self.parent == nil or not self.parent:getIsHighlighted()) then     --reset highlight
                FocusManager:unsetHighlight(self)
            end
        end

        -- handle click/activate only if event has not been consumed, yet
        if not eventUsed then
            if clickInElement and not FocusManager:isLocked() then
                if isDown and button == Input.MOUSE_BUTTON_LEFT then
                    if self.handleFocus and not self.forceFocus then
                        FocusManager:setFocus(self) -- focus on mouse down
                        eventUsed = true

                        --not sendActionOnRelease means we send event when isDown = true
                        if not self.sendActionOnRelease then
                            self:sendAction()
                        end
                    end

                    self.inputDown = true
                end

                if isUp and button == Input.MOUSE_BUTTON_LEFT and self.inputDown then
                    if self.sendActionOnRelease then
                        self:sendAction()
                    end

                    eventUsed = true
                end

                if self.inputDown then
                    self:setPressed(true)
                end
            end
        end
    end

    if isUp then
        self.inputDown = false
        self:setPressed(false)
    end

    return eventUsed
end


---
function ButtonElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self:getIsActive() then
        eventUsed = eventUsed or ButtonElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed)

        -- handle click/activate only if event has not been consumed, yet
        local clickInElement = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], self.hotspot)
        if clickInElement then
            if not self.inputEntered then     -- set highlight on mouse over without focus
                if self.handleFocus and not self:getIsHighlighted() then
                    FocusManager:setHighlight(self)
                end

                self.inputEntered = true
            end
        else -- touch event outside button
            self.inputDown = false
            self.inputEntered = false

            if self:getIsHighlighted() then
                -- reset highlight
                FocusManager:unsetHighlight(self)
            end
        end

        if not eventUsed then
            if clickInElement and not FocusManager:isLocked() then
                if isDown then
                    if self.handleFocus and not self.forceFocus then
                        FocusManager:setFocus(self) -- focus on mouse down
                        eventUsed = true

                        --not sendActionOnRelease means we send event when isDown = true
                        if not self.sendActionOnRelease then
                            self:sendAction()
                        end
                    end

                    self.inputDown = true
                end

                if isUp and self.inputDown then
                    if self.sendActionOnRelease then
                        self:sendAction()
                    end

                    eventUsed = true
                end

                if self.inputDown then
                    self:setPressed(true)
                end
            end
        end
    end

    if isUp then
        self.inputDown = false
        self:setPressed(false)
    end

    return eventUsed
end

---
function ButtonElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
    if self:getIsActive() then
        return ButtonElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
    end
    return false
end


---
function ButtonElement:getIconOffset(textWidth, textHeight)
    local iconSizeX, iconSizeY = self:getIconSize()
    local xOffset, yOffset = self.iconTextOffset[1], self.iconTextOffset[2]

    if self.textAlignment == RenderText.ALIGN_LEFT then
        xOffset = xOffset - iconSizeX
    elseif self.textAlignment == RenderText.ALIGN_CENTER then
        xOffset = xOffset - textWidth * 0.5 - iconSizeX
    elseif self.textAlignment == RenderText.ALIGN_RIGHT then
        xOffset = xOffset - textWidth - iconSizeX
    end

    if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.TOP then
        yOffset = yOffset - textHeight
    elseif self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.MIDDLE then
        yOffset = yOffset + (textHeight - iconSizeY) * 0.5
    end

    return xOffset, yOffset
end


---
function ButtonElement:draw(clipX1, clipY1, clipX2, clipY2)
    if not self.drawChildrenLast then
        ButtonElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
    end

    local overlayState = self:getOverlayState()
    local lastInputMode = g_inputBinding:getInputHelpMode()

    self:setInputMode(
        self.keyDisplayText ~= nil and g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_KEYBOARD,
        self.isTouchButton and lastInputMode == GS_INPUT_HELP_MODE_TOUCH or self.gamepadUsesTouchButton and lastInputMode == GS_INPUT_HELP_MODE_GAMEPAD and Platform.isMobile,
        g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD)
    GuiOverlay.renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], overlayState, clipX1, clipY1, clipX2, clipY2)

    local xPos, yPos = self:getTextPosition(self.text)
    local textOffsetX, textOffsetY = self:getTextOffset()
    local xOffset, yOffset = self:getIconOffset(self:getTextWidth(), getTextHeight(self.textSize, self.text))

    local iconXPos = xPos + textOffsetX + xOffset
    local iconYPos = yPos + textOffsetY + yOffset
    local iconSizeX, iconSizeY = self:getIconSize() -- includes modifications for key glyph (if necessary)

    if self.keyDisplayText ~= nil and self.isKeyboardMode then
        if not self.hideKeyboardGlyph then
            local textColor = GuiOverlay.getOverlayColor(self.icon, overlayState)
            local bgColor = GuiOverlay.getOverlayColor(self.iconColors, overlayState)
            local r, g, b, a = unpack(textColor)
            local r2, g2, b2, a2 = unpack(bgColor)
            self.keyOverlay:setColor(r, g, b, a, r2, g2, b2, a2)
            self.keyOverlay:renderButton(self.keyDisplayText, iconXPos, iconYPos, iconSizeY, true, clipX1, clipY1, clipX2, clipY2)
        end
    elseif self.isTouchMode then
        if self.addTouchArea then
            local r, g, b, a = 1, 1, 1, 1
            if self.touchAreaColor ~= nil then
                r, g, b, a = self.touchAreaColor[1], self.touchAreaColor[2], self.touchAreaColor[3], self.touchAreaColor[4]
            end

            drawTouchButton(self.absPosition[1], self.absPosition[2] + self.absSize[2] / 2, self.absSize[1], overlayState == GuiOverlay.STATE_PRESSED, self.isTouchButtonWithBg, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
        end

        local icon = self.touchIcon
        local iconSize = self.touchIconSize
        if self.isGamepadMode then
            icon = self.icon
            iconXPos = iconXPos - self.gamepadIconSize[1] * 0.25
            iconSize = self.gamepadIconSize
        end

        if icon ~= nil then
            -- Always position in center of button
            local touchIconYPos = self.absPosition[2] + self.absSize[2] / 2 - iconSize[2] / 2
            GuiOverlay.renderOverlay(icon, iconXPos, touchIconYPos, iconSize[1], iconSize[2], overlayState, clipX1, clipY1, clipX2, clipY2)
        end
    else
        GuiOverlay.renderOverlay(self.icon, iconXPos, iconYPos, iconSizeX, iconSizeY, overlayState, clipX1, clipY1, clipX2, clipY2)
    end

    if self.debugEnabled or g_uiDebugEnabled then
        local posX1 = self.absPosition[1]
        local posX2 = self.absPosition[1]+self.size[1]-g_pixelSizeX

        local posY1 = self.absPosition[2]
        local posY2 = self.absPosition[2]+self.size[2]-g_pixelSizeY

        drawFilledRect(posX1,             posY1, posX2-posX1,  g_pixelSizeY, 0, 1, 0, 0.7)
        drawFilledRect(posX1,             posY2, posX2-posX1,  g_pixelSizeY, 0, 1, 0, 0.7)
        drawFilledRect(posX1,             posY1, g_pixelSizeX, posY2-posY1,  0, 1, 0, 0.7)
        drawFilledRect(posX1+posX2-posX1, posY1, g_pixelSizeX, posY2-posY1,  0, 1, 0, 0.7)
    end

    if self.drawChildrenLast then
        ButtonElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
    end
end


---Get modified text offset including changes from icon position and dimensions.
-- @param float textOffsetX Screen space text X offset
-- @param float textOffsetY Screen space text Y offset
-- @return float Modified X offset
-- @return float Modified Y offset
function ButtonElement:getIconModifiedTextOffset(textOffsetX, textOffsetY)
    local xOffset, yOffset = textOffsetX, textOffsetY
    local iconWidth, _ = self:getIconSize()

    if self.textAlignment == RenderText.ALIGN_LEFT then
        xOffset = xOffset - self.iconTextOffset[1] + iconWidth
    elseif self.textAlignment == RenderText.ALIGN_CENTER then
        xOffset = xOffset + (iconWidth - self.iconTextOffset[1]) * 0.5
    end

    return xOffset, yOffset
end


---Get text offset from element position including modifications from icon.
function ButtonElement:getTextOffset()
    local xOffset, yOffset = ButtonElement:superClass().getTextOffset(self)

    if self.isTouchMode and self.addTouchArea then
        xOffset = xOffset + 40/1920
    end

    return self:getIconModifiedTextOffset(xOffset, yOffset)
end


---Get shadow text offset from element position including modifications from icon.
function ButtonElement:getText2Offset()
    local xOffset, yOffset = ButtonElement:superClass().getText2Offset(self)
    return self:getIconModifiedTextOffset(xOffset, yOffset)
end


---Get the current icon size in screen space.
function ButtonElement:getIconSize()
    if self.isKeyboardMode then
        return self.keyGlyphSize[1], self.keyGlyphSize[2]
    else
        return self.iconSize[1], self.iconSize[2]
    end
end


---
function ButtonElement:setIconSize(x,y)
    self.iconSize[1] = Utils.getNoNil(x, self.iconSize[1])
    self.iconSize[2] = Utils.getNoNil(y, self.iconSize[2])

    self:updateSize()
end



---
function ButtonElement:canReceiveFocus()
    return not (self.disabled or not self:getIsVisible()) and self:getHandleFocus()
end


---
function ButtonElement:onFocusLeave()
    ButtonElement:superClass().onFocusLeave(self)

    self:raiseCallback("onLeaveCallback", self)
end


---
function ButtonElement:onFocusEnter()
    ButtonElement:superClass().onFocusEnter(self)

    self:raiseCallback("onFocusCallback", self)
end


---
function ButtonElement:onHighlight()
    ButtonElement:superClass().onHighlight(self)

    self:raiseCallback("onHighlightCallback", self)
end


---
function ButtonElement:onHighlightRemove()
    ButtonElement:superClass().onHighlightRemove(self)

    self:raiseCallback("onHighlightRemoveCallback", self)
end


---
function ButtonElement:onFocusActivate()
    if self:getIsActive() then
        self:sendAction()
    end
end

















---Determine if this element is currently highlighted.
function ButtonElement:getIsPressed()
    return self.pressed
end


---Get this element's overlay state.
function ButtonElement:getOverlayState()
    if self:getIsDisabled() then
        return GuiOverlay.STATE_DISABLED
    elseif self:getIsPressed() and not self.ignorePressedOverlayState then
        return GuiOverlay.STATE_PRESSED
    elseif self:getIsSelected() then
        return GuiOverlay.STATE_SELECTED
    elseif self:getIsFocused() then
        return GuiOverlay.STATE_FOCUSED
    elseif self:getIsHighlighted() then
        return GuiOverlay.STATE_HIGHLIGHTED
    end

    return GuiOverlay.STATE_NORMAL
end


---Update size of element depending on content
function ButtonElement:updateSize(forceTextSize)
    local width, height
    local needsCallbackRaised = false
    local textHeight, _ = self:getTextHeight()
    local iconWidth, iconHeight = self:getIconSize()

    if (self.fitToContent or self.textAutoWidth) and not forceTextSize then
        -- Get width using the source text, as the element is supposed to fit all text (because textAutoWidth is enabled and max lines is 1)
        setTextBold(self.textBold)
        local textWidth = getTextWidth(self.textSize, self.sourceText) + 0.001
        setTextBold(false)

        width = iconWidth + textWidth + self.fitExtraWidth

        if (self.isTouchButton or self.isTouchButtonWithBg or self.gamepadUsesTouchButton) and self.isTouchMode and self.addTouchArea then
            width = width + (58/1920)
            height = 120/1280

            if self.originalHeight ~= nil then
                self.originalHeight = self.size[2]
            end

            needsCallbackRaised = true
        else
            height = self.originalHeight
            self.originalHeight = nil
        end
    end

    if (self.fitToContent or self.textAutoHeight) and not forceTextSize then
        height = math.max(textHeight, iconHeight)
    end

    if width ~= nil and not MathUtil.equalEpsilon(width, self.absSize[1]) or height ~= nil and not MathUtil.equalEpsilon(height, self.absSize[2]) then
        self:setSize(width, height) -- do not overwrite height

        if needsCallbackRaised then
            self:raiseCallback("onSizeChangedCallback", self)
        end

        if self.parent ~= nil and self.parent.invalidateLayout ~= nil and self.parent.autoValidateLayout then
            self.parent:invalidateLayout()
        end
    end
end


---Set the button text
function ButtonElement:setText(text, forceTextSize, isInitializing, forceScrollingParameterUpdate)
    if self.textSeparator ~= nil then
        text = self.textSeparator .. text
    end

    ButtonElement:superClass().setText(self, text, forceTextSize, isInitializing, forceScrollingParameterUpdate)

    self:updateSize()
end


---
function ButtonElement:setTextSize(size)
    ButtonElement:superClass().setTextSize(self, size)

    self:updateSize()
end


---
function ButtonElement:setClickSound(soundName)
    self.clickSoundName = soundName
end
