









---Box layout that supports smooth scrolling
-- If numFlows == 1 then keep adding elements to that one flow and scroll along the axis of that flow
-- If numFlows > 1 or numFlows == 0 (which means infinite/as many as needed) we fill a flow until an element does not fit the current one, then start a new flow until we reach numFlows
local ScrollingLayoutElement_mt = Class(ScrollingLayoutElement, BoxLayoutElement)




---
function ScrollingLayoutElement.new(target, custom_mt)
    local self = BoxLayoutElement.new(target, custom_mt or ScrollingLayoutElement_mt)

    self.clipping = true
    self.wrapAround = true -- needed for focus handling when scrolling
    --if numFlows == 1 then scrollDirection = flowDirection, if numFlows > 1 or numFlows == 0  then it is flipped in onGuiSetupFinished
    self.scrollDirection = self.flowDirection

    self.sliderElement = nil -- sliders register themselves with lists in this field if they point at them via configuration

    self.contentOffsetX = 0
    self.contentOffsetY = 0
    self.targetContentOffsetX = 0
    self.targetContentOffsetY = 0
    self.contentSize = 1 -- height only for now

    self.lastTouchPos = nil
    self.usedTouchId = nil
    self.currentTouchDelta = 0
    self.scrollSpeed = 0
    self.initialScrollSpeed = 0
    self.supportsTouchScrolling = false

    self.totalTouchMoveDistance = 0
    self.touchMoveDistanceThreshold = 30

    return self
end


---
function ScrollingLayoutElement:loadFromXML(xmlFile, key)
    ScrollingLayoutElement:superClass().loadFromXML(self, xmlFile, key)

    self.topClipperElementName = getXMLString(xmlFile, key.."#topClipperElementName")
    self.bottomClipperElementName = getXMLString(xmlFile, key.."#bottomClipperElementName")
    self.supportsTouchScrolling = Utils.getNoNil(getXMLBool(xmlFile, key.."#supportsTouchScrolling"), self.supportsTouchScrolling)
end









---
function ScrollingLayoutElement:copyAttributes(src)
    ScrollingLayoutElement:superClass().copyAttributes(self, src)

    self.topClipperElementName = src.topClipperElementName
    self.bottomClipperElementName = src.bottomClipperElementName
    self.supportsTouchScrolling = src.supportsTouchScrolling
end


---
function ScrollingLayoutElement:onGuiSetupFinished()
    ScrollingLayoutElement:superClass().onGuiSetupFinished(self)

    if self.topClipperElementName ~= nil then
        self.topClipperElement = self.parent:getDescendantByName(self.topClipperElementName)
    end
    if self.bottomClipperElementName ~= nil then
        self.bottomClipperElement = self.parent:getDescendantByName(self.bottomClipperElementName)
    end

    for _, e in pairs(self.elements) do
        self:addFocusListener(e)
    end

    if self.flowDirection == "vertical" and self.numFlows == 1 or self.flowDirection == "horizontal" and self.numFlows ~= 1 then
        self.scrollDirection = "vertical"
    else
        self.scrollDirection = "horizontal"
    end

    if self.scrollDirection == "horizontal" then
        self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeX
    else
        self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeY
    end
end










---Rebuild the layout. Adjusts start Y with our visible Y
function ScrollingLayoutElement:invalidateLayout(ignoreVisibility, blockLayoutUpdate)
    local needsUpdate = not blockLayoutUpdate
    if needsUpdate then
        self:updateLayoutCells(ignoreVisibility)
    end

    self:applyCellPositions(self.contentOffsetX, self.contentOffsetY)

    if self.handleFocus and self.focusDirection ~= BoxLayoutElement.FLOW_NONE and needsUpdate then
        self:focusLinkCells(self.cells)
    end

    if needsUpdate then
        self:updateContentSize()
    end

    self:updateScrollClippers()

    return self.maxFlowSize
end

























---
function ScrollingLayoutElement:onSliderValueChanged(slider, newValue)
    if self.scrollDirection == "vertical" then
        local newStartY = 0
        if slider.minValue ~= slider.maxValue then
            newStartY = ((self.contentSize - self.absSize[2]) / (slider.maxValue - slider.minValue)) * (newValue - slider.minValue)
        end

        self:scrollTo(newStartY, false)
    else
        local newStartX = 0
        if slider.minValue ~= slider.maxValue then
            newStartX = ((self.contentSize - self.absSize[1]) / (slider.maxValue - slider.minValue)) * (-newValue + slider.minValue)
        end

        self:scrollTo(newStartX, false)
    end
end


---Scroll to an X or Y position within the content
function ScrollingLayoutElement:scrollTo(startPos, updateSlider, noUpdateTarget)
    if self.scrollDirection == "vertical" then
        self.contentOffsetY = startPos

        if not noUpdateTarget then
            self.targetContentOffsetY = startPos
            self.isMovingToTarget = false
        end

        self:invalidateLayout(false, true)

        -- update scrolling
        if updateSlider == nil or updateSlider then
            if self.sliderElement ~= nil then
                local newValue = startPos / ((self.contentSize - self.absSize[2]) / self.sliderElement.maxValue)
                self.sliderElement:setValue(newValue, true)
            end
        end
    else
        self.contentOffsetX = startPos

        if not noUpdateTarget then
            self.targetContentOffsetX = startPos
            self.isMovingToTarget = false
        end

        self:invalidateLayout(false, true)

        -- update scrolling
        if updateSlider == nil or updateSlider then
            if self.sliderElement ~= nil then
                local endPos = ((-self.contentSize + self.absSize[1]) / self.sliderElement.maxValue)    --needed to avoid a divide by 0 if content size is exactly the elements size
                local newValue = startPos / (endPos ~= 0 and endPos or 1)
                self.sliderElement:setValue(newValue, true)
            end
        end
    end

    self:raiseCallback("onScrollCallback")
end






















































---
function ScrollingLayoutElement:raiseSliderUpdateEvent()
    if self.sliderElement ~= nil then
        self.sliderElement:onBindUpdate(self)
    end
end















---Update content size when an element is removed
function ScrollingLayoutElement:removeElement(element)
    ScrollingLayoutElement:superClass().removeElement(self, element)

    if element.scrollingFocusEnter_orig == nil then
        element.onFocusEnter = element.scrollingFocusEnter_orig
    end
end




























































































































































---Remove non-GUI input action events.
function ScrollingLayoutElement:removeActionEvents()
    g_inputBinding:removeActionEventsByTarget(self)
end


---Event function for vertical cursor input bound to InputAction.MENU_AXIS_UP_DOWN_SECONDARY.
function ScrollingLayoutElement:onVerticalCursorInput(_, inputValue)
    if not self.useMouse then
        self.sliderElement:setValue(self.sliderElement.currentValue + self.sliderElement.stepSize * inputValue)
    end
    self.useMouse = false
end
