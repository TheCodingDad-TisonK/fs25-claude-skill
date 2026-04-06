



















---Two-value state input element with 2 buttons. Similar to CheckedOptionElement, except it uses a different method for the input.
-- Uses "On" and "Off" as default texts, but can be customized to use different texts.
local BinaryOptionElement_mt = Class(BinaryOptionElement, MultiTextOptionElement)





---
function BinaryOptionElement.new(target, custom_mt)
    local self = MultiTextOptionElement.new(target, custom_mt or BinaryOptionElement_mt)

    self.sliderElement = nil
    self.isSliderMoving = false
    self.sliderState = 0
    self.sliderMovingDirection = 0

    self.useYesNoTexts = false

    return self
end


---
function BinaryOptionElement:loadFromXML(xmlFile, key)
    BinaryOptionElement:superClass().loadFromXML(self, xmlFile, key)

    self.useYesNoTexts = Utils.getNoNil(getXMLBool(xmlFile, key.."#useYesNoTexts"), self.useYesNoTexts)
end


---
function BinaryOptionElement:loadProfile(profile, applyProfile)
    BinaryOptionElement:superClass().loadProfile(self, profile, applyProfile)

    self.useYesNoTexts = profile:getBool("useYesNoTexts", self.useYesNoTexts)

    self.sliderOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("sliderOffset"), self.sliderOffset)
    self.defaultProfileSlider = profile:getValue("defaultProfileSlider", self.defaultProfileSlider)
    self.defaultProfileSliderRound = profile:getValue("defaultProfileSliderRound", self.defaultProfileSliderRound)
    self.defaultProfileSliderThreePart = profile:getValue("defaultProfileSliderThreePart", self.defaultProfileSliderThreePart)
end


---
function BinaryOptionElement:copyAttributes(src)
    BinaryOptionElement:superClass().copyAttributes(self, src)

    self.useYesNoTexts = src.useYesNoTexts
    self.defaultProfileSlider = src.defaultProfileSlider
    self.defaultProfileSliderRound = src.defaultProfileSliderRound
    self.defaultProfileSliderThreePart = src.defaultProfileSliderThreePart
end


---We need to re-add all current elements, because they might not have had their name when they were first added
function BinaryOptionElement:setElementsByName()
    BinaryOptionElement:superClass().setElementsByName(self)

    for _, element in pairs(self.elements) do
        if element.name == "slider" then
            self.sliderElement = element
            element.target = self
            element:updateAbsolutePosition()
        end
    end

    if self.sliderElement == nil then
        Logging.warning("BinaryOptionElement: could not find a slider element for element with profile " .. self.profile)
    end

    --Set up the initial selected state of the buttons
    self.leftButtonElement:setSelected(true)
    self.leftButtonElement.getIsSelected = function() return self.state == BinaryOptionElement.STATE_LEFT end
    self.leftButtonElement.getIsScrollingAllowed = function() return self:getIsFocused() or self:getIsHighlighted() end

    self.rightButtonElement.getIsSelected = function() return self.state == BinaryOptionElement.STATE_RIGHT end
    self.rightButtonElement.getIsScrollingAllowed = function() return self:getIsFocused() or self:getIsHighlighted() end

    self.sliderDelta = (self.absSize[1] - self.sliderElement.absSize[1]) / BinaryOptionElement.NUM_SLIDER_STATES
end


---Adds the default slider element, if autoAddDefaultElements = true
function BinaryOptionElement:addDefaultElements()
    BinaryOptionElement:superClass().addDefaultElements(self)

    if self.autoAddDefaultElements then
        if self:getDescendantByName("slider") == nil then
            if self.defaultProfileSliderRound ~= nil then
                local baseElement = RoundCornerElement.new(self)
                baseElement.name = "slider"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileSliderRound)
            elseif self.defaultProfileSliderThreePart ~= nil then
                local baseElement = ThreePartBitmapElement.new(self)
                baseElement.name = "slider"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileSliderThreePart)
            elseif self.defaultProfileSlider ~= nil then
                local baseElement = BitmapElement.new(self)
                baseElement.name = "slider"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileSlider)
            end
        end
    end
end


---Assign default text values to buttons if they dont have any text yet
function BinaryOptionElement:onGuiSetupFinished()
    BinaryOptionElement:superClass().onGuiSetupFinished(self)

    if self.useYesNoTexts then
        self:setTexts({g_i18n:getText(BinaryOptionElement.STRING_NO), g_i18n:getText(BinaryOptionElement.STRING_YES)})
    else
        self:setTexts({g_i18n:getText(BinaryOptionElement.STRING_OFF), g_i18n:getText(BinaryOptionElement.STRING_ON)})
    end

    self.textElement:setVisible(false)
end


---Get whether the element is checked. Checked is true if the left state is currently selected, which by default is called "On"
function BinaryOptionElement:getIsChecked()
    return self.state == BinaryOptionElement.STATE_RIGHT
end


---Set whether the element is checked. Checked is true if the left state is currently selected, which by default is called "On"
function BinaryOptionElement:setIsChecked(isChecked, skipAnimation, forceEvent)
    if isChecked then
        self:setState(BinaryOptionElement.STATE_RIGHT, forceEvent)
    else
        self:setState(BinaryOptionElement.STATE_LEFT, forceEvent)
    end

    self.skipAnimation = skipAnimation
end


---Determine if this element is active (visible) without checking the parents. Binary option elements still need the update call even if they are disabled to properly resolve their sldier movement
function BinaryOptionElement:getIsActiveNonRec()
    return self:getIsVisibleNonRec()
end


---
function BinaryOptionElement:setTexts(texts)
    if #texts ~= 2 then
        Logging.warning("BinaryOption: called setTexts() with invalid number of texts, binary option requires exactly 2 texts")
        printCallstack()
    end

    BinaryOptionElement:superClass().setTexts(self, texts)

    self.leftButtonElement:setText(texts[1])
    self.rightButtonElement:setText(texts[2])
end


---Animate the moving slider if needed
function BinaryOptionElement:update(dt)
    BinaryOptionElement:superClass().update(self, dt)

    if self.sliderMovingDirection ~= 0 then
        if self.skipAnimation then
            self.sliderState = self.sliderMovingDirection > 0 and BinaryOptionElement.NUM_SLIDER_STATES or 0
        else
            self.sliderState = self.sliderState + self.sliderMovingDirection
        end

        if self.sliderState <= 0 or self.sliderState >= BinaryOptionElement.NUM_SLIDER_STATES then
            self.sliderMovingDirection = 0
        end

        self.sliderElement:setPosition(self.sliderDelta * self.sliderState)
    end

    self.skipAnimation = false
end


---Trigger a "left" input.
function BinaryOptionElement:inputLeft()
    if self.sliderMovingDirection == 0 and (self:getIsFocused() or self.leftButtonElement:getIsPressed()) then
        self:onLeftButtonClicked()

        return true
    else
        return false
    end
end


---Trigger a "right" input.
function BinaryOptionElement:inputRight()
    if self.sliderMovingDirection == 0 and (self:getIsFocused() or self.rightButtonElement:getIsPressed()) then
        self:onRightButtonClicked()

        return true
    else
        return false
    end
end


---
function BinaryOptionElement:setState(state, forceEvent, skipAnimation)
    if state ~= BinaryOptionElement.STATE_LEFT and state ~= BinaryOptionElement.STATE_RIGHT then
        Logging.warning("BinaryOption: invalid state input " .. state .. ", only 1 and 2 allowed")
        return
    end

    if state == self.state then
        return
    end

    state = math.clamp(state, BinaryOptionElement.STATE_LEFT, BinaryOptionElement.STATE_RIGHT)
    BinaryOptionElement:superClass().setState(self, state, forceEvent)

    self:updateSelection()

    self.skipAnimation = skipAnimation
end


---
function BinaryOptionElement:onRightButtonClicked()
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self)
    self:setSoundSuppressed(false)

    if self:getCanChangeState() and self.state ~= BinaryOptionElement.STATE_RIGHT then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

        self:setState(BinaryOptionElement.STATE_RIGHT)

        self:updateContentElement()
        self:raiseClickCallback(false)
        self:notifyIndexChange(self.state, #self.texts)
    end
end


---
function BinaryOptionElement:onLeftButtonClicked()
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self)
    self:setSoundSuppressed(false)

    if self:getCanChangeState() and self.state ~= BinaryOptionElement.STATE_LEFT then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

        self:setState(BinaryOptionElement.STATE_LEFT)

        self:updateContentElement()
        self:raiseClickCallback(true)
        self:notifyIndexChange(self.state, #self.texts)
    end
end


---
function BinaryOptionElement:updateSelection()
    self.leftButtonElement:setSelected(self.state == BinaryOptionElement.STATE_LEFT)
    self.rightButtonElement:setSelected(self.state == BinaryOptionElement.STATE_RIGHT)

    self.sliderMovingDirection = self.state == BinaryOptionElement.STATE_RIGHT and 1 or -1
end
