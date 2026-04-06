
























---Draggable viewport slider element.
-- 
-- If #hasButtons is true or not present, this element requires 2 ButtonElement instances as the first children, which
-- provide another way to scroll in addition to clicking the bar or dragging the handle.
-- 
-- Used layers: "image" for a background image, "sliderImage" for a slider handle background image.
-- 
-- Implicit callback:
-- onSliderValueChanged(element, newValue) is called on all children and the target data element when the slider value
-- changes, if those elements have the method defined.
local SliderElement_mt = Class(SliderElement, GuiElement)








---
function SliderElement.new(target, custom_mt)
    local self = GuiElement.new(target, custom_mt or SliderElement_mt)
    self:include(PlaySampleMixin) -- add sound playing

    self.mouseDown = false

    self.minValue = 0
    self.maxValue = 100
    self.currentValue = 0
    self.sliderValue = 0
    self.stepSize = 1.0
    self.direction = SliderElement.DIRECTION_Y

    self.hasButtons = true
    self.isThreePartBitmap = false

    self.overlay = {}
    self.sliderOverlay = {}
    self.startOverlay = {}
    self.endOverlay = {}

    self.startSize = {0, 0}
    self.endSize = {0, 0}
    self.sliderOffset = 0
    self.sliderSize = {0, 0}
    self.sliderPosition = {0,0}
    self.adjustSliderSize = true
    self.sliderBoxMargin = nil

    self.textElement = nil
    self.dataElementId = nil
    self.textElementId = nil

    self.minAbsSliderPos = 0.08
    self.maxAbsSliderPos = 0.92

    self.isSliderVisible = true
    self.needsSlider = true
    self.useStepRounding = false

    self.hideParentWhenEmpty = false

    return self
end


---
function SliderElement:delete()
    GuiOverlay.deleteOverlay(self.endOverlay)
    GuiOverlay.deleteOverlay(self.startOverlay)
    GuiOverlay.deleteOverlay(self.sliderOverlay)
    GuiOverlay.deleteOverlay(self.overlay)

    SliderElement:superClass().delete(self)
end


---
function SliderElement:loadFromXML(xmlFile, key)
    SliderElement:superClass().loadFromXML(self, xmlFile, key)

    GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)
    GuiOverlay.loadOverlay(self, self.sliderOverlay, "sliderImage", self.imageSize, nil, xmlFile, key)
    GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, nil, xmlFile, key)
    GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, nil, xmlFile, key)

    local direction = getXMLString(xmlFile, key.."#direction")
    if direction ~= nil then
        if direction == "y" then
            self.direction = SliderElement.DIRECTION_Y
        elseif direction == "x" then
            self.direction = SliderElement.DIRECTION_X
        end
    end

    self:addCallback(xmlFile, key.."#onClick", "onClickCallback")
    self:addCallback(xmlFile, key.."#onChanged", "onChangedCallback")

    self.hasButtons = Utils.getNoNil(getXMLBool(xmlFile, key.."#hasButtons"), self.hasButtons)
    self.minValue = getXMLFloat(xmlFile, key.."#minValue") or self.minValue
    self.maxValue = getXMLFloat(xmlFile, key.."#maxValue") or self.maxValue
    self.currentValue = getXMLFloat(xmlFile, key.."#currentValue") or self.currentValue
    self.stepSize = getXMLFloat(xmlFile, key.."#stepSize") or self.stepSize
    self.isThreePartBitmap = Utils.getNoNil(getXMLBool(xmlFile, key.."#isThreePartBitmap"), self.isThreePartBitmap)
    self.hideParentWhenEmpty = Utils.getNoNil(getXMLBool(xmlFile, key.."#hideParentWhenEmpty"), self.hideParentWhenEmpty)
    self.useStepRounding = Utils.getNoNil(getXMLBool(xmlFile, key.."#useStepRounding"), self.useStepRounding)
    self.sliderBoxMargin = GuiUtils.getNormalizedValue(getXMLFloat(xmlFile, key.."#sliderBoxMargin"), self.direction == SliderElement.DIRECTION_X, self.sliderBoxMargin)

    self.sliderOffset = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key.."#sliderOffset"), self.sliderOffset)
    self.sliderSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#sliderSize"), self.sliderSize)

    self.startSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#startImageSize"), self.startSize)
    self.endSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#endImageSize"), self.endSize)

    self.dataElementId = getXMLString(xmlFile, key.."#dataElementId")
    self.dataElementName = getXMLString(xmlFile, key.."#dataElementName")
    self.textElementId = getXMLString(xmlFile, key.."#textElementId")

    GuiOverlay.createOverlay(self.overlay)
    GuiOverlay.createOverlay(self.sliderOverlay)
    GuiOverlay.createOverlay(self.startOverlay)
    GuiOverlay.createOverlay(self.endOverlay)
end


---
function SliderElement:loadProfile(profile, applyProfile)
    SliderElement:superClass().loadProfile(self, profile, applyProfile)

    GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, nil)
    GuiOverlay.loadOverlay(self, self.sliderOverlay, "sliderImage", self.imageSize, profile, nil, nil)
    GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, profile, nil, nil)
    GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, profile, nil, nil)

    local direction = profile:getValue("direction")
    if direction ~= nil then
        if direction == "y" then
            self.direction = SliderElement.DIRECTION_Y
        elseif direction == "x" then
            self.direction = SliderElement.DIRECTION_X
        end
    end

    self.hasButtons = profile:getBool("hasButtons", self.hasButtons)
    self.minValue = profile:getNumber("minValue", self.minValue)
    self.maxValue = profile:getNumber("maxValue", self.maxValue)
    self.currentValue = profile:getNumber("currentValue", self.currentValue)
    self.stepSize = profile:getNumber("stepSize", self.stepSize)
    self.isThreePartBitmap = profile:getBool("isThreePartBitmap", self.isThreePartBitmap)
    self.hideParentWhenEmpty = profile:getBool("hideParentWhenEmpty", self.hideParentWhenEmpty)
    self.useStepRounding = profile:getBool("useStepRounding", self.useStepRounding)

    local isHorizontalSlider = self.direction == SliderElement.DIRECTION_X

    self.sliderSize = GuiUtils.getNormalizedScreenValues(profile:getValue("sliderSize"), self.sliderSize)
    self.sliderBoxMargin = GuiUtils.getNormalizedValue(profile:getValue("sliderBoxMargin"), isHorizontalSlider, self.sliderBoxMargin)
    self.sliderOffset = GuiUtils.getNormalizedValue(profile:getValue("sliderOffset"), isHorizontalSlider, self.sliderOffset)

    self.startSize = GuiUtils.getNormalizedScreenValues(profile:getValue("startImageSize"), self.startSize)
    self.endSize = GuiUtils.getNormalizedScreenValues(profile:getValue("endImageSize"), self.endSize)
end


---
function SliderElement:copyAttributes(src)
    SliderElement:superClass().copyAttributes(self, src)

    GuiOverlay.copyOverlay(self.overlay, src.overlay)
    GuiOverlay.copyOverlay(self.sliderOverlay, src.sliderOverlay)
    GuiOverlay.copyOverlay(self.startOverlay, src.startOverlay)
    GuiOverlay.copyOverlay(self.endOverlay, src.endOverlay)

    self.direction = src.direction
    self.hasButtons = src.hasButtons
    self.minValue = src.minValue
    self.maxValue = src.maxValue
    self.currentValue = src.currentValue
    self.stepSize = src.stepSize
    self.sliderOffset = src.sliderOffset
    self.sliderSize = table.clone(src.sliderSize)
    self.isThreePartBitmap = src.isThreePartBitmap
    self.hideParentWhenEmpty = src.hideParentWhenEmpty
    self.useStepRounding = src.useStepRounding
    self.sliderBoxMargin = src.sliderBoxMargin

    self.startSize = table.clone(src.startSize)
    self.endSize = table.clone(src.endSize)

    self.dataElementId = src.dataElementId
    self.dataElementName = src.dataElementName
    self.textElementId = src.textElementId

    self.onClickCallback = src.onClickCallback
    self.onChangedCallback = src.onChangedCallback

    GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end


---
function SliderElement:setSliderVisible(visible)
    self.isSliderVisible = visible
end


---
function SliderElement:onGuiSetupFinished()
    SliderElement:superClass().onGuiSetupFinished(self)

    if self.textElementId ~= nil then
        if self.target[self.textElementId] ~= nil then
            self.textElement = self.target[self.textElementId]
        else
            printWarning("Warning: TextElementId '"..self.textElementId.."' not found for '"..self.target.name.."'!")
        end
    end

    if self.dataElementId ~= nil then
        if self.target[self.dataElementId] ~= nil then
            local dataElement = self.target[self.dataElementId]
            self:setDataElement(dataElement)
        else
            printWarning("Warning: DataElementId '"..self.dataElementId.."' not found for '"..self.target.name.."'!")
        end
    elseif self.dataElementName ~= nil and self.parent then
        local findDataElement = function(element) return element.name and element.name == self.dataElementName end
        local dataElement = self.parent:getFirstDescendant(findDataElement)

        if dataElement then
            self:setDataElement(dataElement)
        else
            printWarning("Warning: DataElementName '"..self.dataElementName.."' not found as descendant of '"..tostring(self.parent).."'!")
        end
    end

    if self.sliderBoxMargin ~= nil then
        if self.direction == SliderElement.DIRECTION_X then
            self:setSize(self.size[1] - self.sliderBoxMargin * 2)
            self:setPosition(self.sliderBoxMargin)
        else
            self:setSize(nil, self.size[2] - self.sliderBoxMargin * 2)
            self:setPosition(nil, self.sliderBoxMargin)
        end
    end
end


---Automatically recognize slider buttons
function SliderElement:addElement(element)
    SliderElement:superClass().addElement(self, element)

    if self.hasButtons then
        if #self.elements == 1 then
            -- up button
            self.upButtonElement = element
            element.target = self

            if self.direction == SliderElement.DIRECTION_Y then
                element:setCallback("onClickCallback", "onScrollDown")
            else
                element:setCallback("onClickCallback", "onScrollUp")
            end

            self:setDisabled(self.disabled)
        elseif #self.elements == 2 then
            -- down button
            self.downButtonElement = element
            element.target = self

            if self.direction == SliderElement.DIRECTION_Y then
                element:setCallback("onClickCallback", "onScrollUp")
            else
                element:setCallback("onClickCallback", "onScrollDown")
            end

            self:setDisabled(self.disabled)
        end
    end
end


---
function SliderElement:setDataElement(element)
    if self.dataElement ~= nil then
        self.dataElement.sliderElement = nil
        self.dataElement = nil
    end

    if element ~= nil then
        element.sliderElement = self
        self.dataElement = element

        self:onBindUpdate(element, false)
    end
end


---Set current slider value
function SliderElement:setValue(newValue, doNotUpdateDataElement, immediateMode)
    self.sliderValue = math.min(math.max(newValue, self.minValue), self.maxValue)
    self:updateSliderPosition()

    if self.useStepRounding then
        local rem = (newValue-self.minValue) % self.stepSize

        -- round to the next step
        if rem >= self.stepSize - rem then
            newValue = newValue + self.stepSize - rem
        else
            newValue = newValue - rem
        end

        newValue = math.min(math.max(newValue, self.minValue), self.maxValue)
    end

    -- round to 5 decimal places
    local numDecimalPlaces = 5
    local mult = 10^numDecimalPlaces
    newValue = math.floor(newValue * mult + 0.5) / mult

    if newValue ~= self.currentValue then
        self.currentValue = newValue
        if self.textElement ~= nil then
            self.textElement:setText(self.currentValue)
        end

        self:callOnChanged()
        for _, element in pairs(self.elements) do
            if element.onSliderValueChanged ~= nil then
                element:onSliderValueChanged(self, newValue, immediateMode)
            end
        end

        if self.dataElement ~= nil and (doNotUpdateDataElement == nil or not doNotUpdateDataElement) then
            self.dataElement:onSliderValueChanged(self, newValue, immediateMode)
        end

        -- Disable buttons if needed
        self:updateSliderButtons()

        return true
    end

    return false
end


---Update the disabled-ness of the slider buttons depending on current state
function SliderElement:updateSliderButtons()
    if self.upButtonElement ~= nil then
        self.upButtonElement:setDisabled(self.disabled or self.currentValue == self.maxValue)
    end

    if self.downButtonElement ~= nil then
        self.downButtonElement:setDisabled(self.disabled or self.currentValue == self.minValue)
    end
end


---Set minimum slider value. Used to calculate the bar size.
function SliderElement:setMinValue(minValue)
    self.minValue = math.max(minValue, 1)
    if self.minValue > self.currentValue then
        self:setValue(self.minValue, nil, true)
    end

    self:updateSliderPosition()
end


---Set maximum slider value. Used to calculate the bar size.
function SliderElement:setMaxValue(maxValue)
    self.maxValue = math.max(maxValue, 1)
    if self.maxValue < self.currentValue then
        self:setValue(self.maxValue, nil, true)
    end

    self:updateSliderPosition()
end


---Get minimum slider value
function SliderElement:getMinValue()
    return self.minValue
end


---Set maximum slider value.
function SliderElement:getMaxValue()
    return self.maxValue
end


---Get current slider value
function SliderElement:getValue()
    return self.currentValue
end


---
function SliderElement:updateAbsolutePosition()
    SliderElement:superClass().updateAbsolutePosition(self)
    self:updateSliderLimits()
end


---
function SliderElement:setSize(x,y)
    SliderElement:superClass().setSize(self, x,y)
    self:updateSliderLimits()
end


---
function SliderElement:setSliderSize(visibleItems, maxItems)
    if self.adjustSliderSize then
        local axis = 1
        if self.direction == SliderElement.DIRECTION_Y then
            axis = 2
        end

        local visibleToMaxRatio = maxItems ~= 0 and math.min(1, visibleItems / maxItems) or 0
        self.sliderSize[axis] = visibleToMaxRatio > 0 and self.size[axis] * visibleToMaxRatio or self.size[axis]
        if self.isThreePartBitmap then
            self.sliderSize[axis] = GuiUtils.alignValueToScreenPixels(math.max(self.sliderSize[axis], self.startSize[axis] + self.endSize[axis], self.absSize[axis] * 0.025), axis == SliderElement.DIRECTION_X)
        else
            self.sliderSize[axis] = GuiUtils.alignValueToScreenPixels(math.max(self.sliderSize[axis], self.absSize[axis] * 0.05), axis == SliderElement.DIRECTION_X)
        end

        self:updateSliderLimits()
    end

    if not self.hasButtons then
        for _, child in pairs(self.elements) do
            child:setSize(self.sliderSize[1], self.sliderSize[2])
        end
    end
end


---
function SliderElement:updateSliderLimits()
    local axis = 1
    if self.direction == SliderElement.DIRECTION_Y then
        axis = 2
    end

    self.minAbsSliderPos = self.absPosition[axis]
    self.maxAbsSliderPos = self.absPosition[axis] + self.absSize[axis] - self.sliderSize[axis]
    self:updateSliderPosition()
end


---
function SliderElement:setAlpha(alpha)
    SliderElement:superClass().setAlpha(self, alpha)
    if self.overlay ~= nil then
        self.overlay.alpha = self.alpha
    end
    if self.sliderOverlay ~= nil then
        self.sliderOverlay.alpha = self.alpha
    end
end


---
function SliderElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() then
        if SliderElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
            eventUsed = true
        end

        if self.mouseDown and isUp and button == Input.MOUSE_BUTTON_LEFT then
            eventUsed = true
            self.clickedOnSlider = false
            self.mouseDown = false

            self:raiseCallback("onClickCallback", self.currentValue)
        end

        if not eventUsed and (GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) or GuiUtils.checkOverlayOverlap(posX, posY, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2])) then
            eventUsed = true
            if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
                self:setValue(self.currentValue - self.stepSize, nil, false)
            end

            if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
                self:setValue(self.currentValue + self.stepSize, nil, false)
            end

            if isDown and button == Input.MOUSE_BUTTON_LEFT then
                if not self.mouseDown and GuiUtils.checkOverlayOverlap(posX, posY, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2]) then
                    self.clickedOnSlider = true
                    self.lastMousePosX = posX
                    self.lastMousePosY = posY
                    self.lastSliderPosX = self.sliderPosition[1]
                    self.lastSliderPosY = self.sliderPosition[2]
                end
                self.mouseDown = true
            end
        end

        if self.mouseDown and self.needsSlider then
            eventUsed = true
            -- calculate slider value according to current mouse position
            local newValue
            local mousePos = posX
            if self.direction == SliderElement.DIRECTION_Y then
                mousePos = posY
                if self.clickedOnSlider then
                    local deltaY = posY - self.lastMousePosY
                    mousePos = self.lastSliderPosY + deltaY
                    newValue = self.minValue + (1-((mousePos - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos))) * (self.maxValue - self.minValue)
                else
                    if mousePos > self.sliderPosition[2]+self.sliderSize[2] then
                        mousePos = mousePos - self.sliderSize[2]
                    end
                    newValue = self.minValue + (1-((mousePos - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos))) * (self.maxValue - self.minValue)
                end
            else
                if self.clickedOnSlider then
                    local deltaX = posX - self.lastMousePosX
                    mousePos = self.lastSliderPosX + deltaX
                else
                    if mousePos > self.sliderPosition[1]+self.sliderSize[1] then
                        mousePos = mousePos - self.sliderSize[1]
                    end
                end

                newValue = self.minValue + ((mousePos - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos)) * (self.maxValue - self.minValue)
            end
            self:setValue(newValue, nil, true)
        end
    end

    return eventUsed
end


---
function SliderElement:updateSliderPosition()
    local state = (self.maxValue ~= self.minValue) and (self.sliderValue - self.minValue) / (self.maxValue - self.minValue) or 0

    if self.direction == SliderElement.DIRECTION_Y then
        self.sliderPosition[1] = self.absPosition[1] + self.sliderOffset
        self.sliderPosition[2] = MathUtil.lerp(self.minAbsSliderPos, self.maxAbsSliderPos, 1-state)
    else
        self.sliderPosition[1] = MathUtil.lerp(self.minAbsSliderPos, self.maxAbsSliderPos, state)
        self.sliderPosition[2] = self.absPosition[2] + self.sliderOffset
    end

    self:updateSliderButtons()

    if not self.hasButtons then
        for _, child in pairs(self.elements) do
            child:setAbsolutePosition(self.sliderPosition[1], self.sliderPosition[2])
        end
    end
end


---
function SliderElement:callOnChanged()
    self:raiseCallback("onChangedCallback", self.currentValue)
end


---
function SliderElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
    if self:getIsActive() then
        if SliderElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) then
            return true
        end
    end

    return false
end


---
function SliderElement:draw(clipX1, clipY1, clipX2, clipY2)
    local state = self:getOverlayState()

    GuiOverlay.renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], state, clipX1, clipY1, clipX2, clipY2)

    if self.isSliderVisible and self.needsSlider then
        if self.isThreePartBitmap then
            local x, y = self.sliderPosition[1], self.sliderPosition[2]
            if self.direction == SliderElement.DIRECTION_X then
                GuiOverlay.renderOverlay(self.startOverlay, x, y, self.startSize[1], self.sliderSize[2], state, clipX1, clipY1, clipX2, clipY2)
                GuiOverlay.renderOverlay(self.sliderOverlay, x + self.startSize[1], y, self.sliderSize[1] - self.startSize[1] - self.endSize[1], self.sliderSize[2], state, clipX1, clipY1, clipX2, clipY2)
                GuiOverlay.renderOverlay(self.endOverlay, x + self.sliderSize[1] - self.endSize[1], y, self.endSize[1], self.sliderSize[2], state, clipX1, clipY1, clipX2, clipY2)
            else
                GuiOverlay.renderOverlay(self.startOverlay, x, y + self.sliderSize[2] - self.startSize[2], self.sliderSize[1], self.startSize[2], state, clipX1, clipY1, clipX2, clipY2)
                GuiOverlay.renderOverlay(self.sliderOverlay, x, y + self.endSize[2], self.sliderSize[1], self.sliderSize[2] - self.startSize[2] - self.endSize[2], state, clipX1, clipY1, clipX2, clipY2)
                GuiOverlay.renderOverlay(self.endOverlay, x, y, self.sliderSize[1], self.endSize[2], state, clipX1, clipY1, clipX2, clipY2)
            end
        else
            GuiOverlay.renderOverlay(self.sliderOverlay, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2], state, clipX1, clipY1, clipX2, clipY2)
        end
    end

    SliderElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end


































---Determine if this SliderElement can receive focus.
function SliderElement:canReceiveFocus()
    return self.handleFocus and self.needsSlider
end


---
function SliderElement:onFocusActivate()
    self:raiseCallback("onClickCallback", self.currentValue)
end


---
function SliderElement:onScrollUp()
    self:setValue(self.currentValue + self.stepSize, nil, false)
end


---
function SliderElement:onScrollDown()
    self:setValue(self.currentValue - self.stepSize, nil, false)
end


---
function SliderElement:onBindUpdate(element)
    if element:isa(ScrollingLayoutElement) then
        self:setMinValue(1)

        self.useStepRounding = true

        if element:getNeedsScrolling() then
            self:setMaxValue(element.contentSize / element.absSize[2] * 20)
            self:setSliderSize(element.absSize[2], element.contentSize)
            self.needsSlider = true
        else
            self:setMaxValue(1)
            self:setSliderSize(10, 100)
            self.needsSlider = false
        end
    elseif element:isa(SmoothListElement) then
        -- round values on pixel level to avoid floating point issues
        local base = element.lengthAxis == 1 and g_screenWidth or g_screenHeight
        local contentSize = MathUtil.round(element.contentSize * base)
        local scrollViewOffsetDelta = MathUtil.round(element.scrollViewOffsetDelta * base)
        local size = MathUtil.round(element.absSize[element.lengthAxis] * base)

        local scrollSteps = scrollViewOffsetDelta ~= 0 and math.max(0, math.ceil((contentSize - size) / scrollViewOffsetDelta)) or 0

        self:setMinValue(1)
        self:setMaxValue(scrollSteps + 1)

        local viewSize = element.absSize[element.lengthAxis]
        self:setSliderSize(viewSize, element.contentSize)
        self.needsSlider = self.maxValue > self.minValue and element.contentSize ~= 0

        self:setValue(element:getViewOffsetPercentage() * (self.maxValue - self.minValue) + self.minValue, true, true)
    end

    if self.hideParentWhenEmpty then
        self.parent:setVisible(self.needsSlider)
    end
end
