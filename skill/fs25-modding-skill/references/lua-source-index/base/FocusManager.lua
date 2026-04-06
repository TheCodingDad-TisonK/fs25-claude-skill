









































































---Set the active GUI for focus input.
-- @param gui Screen root GuiElement
function FocusManager:setGui(gui)
    -- reset old gui focus
    if self.currentFocusData then
        local focusElement = self.currentFocusData.focusElement
        if focusElement then
            self:unsetFocus(focusElement)
        end

        local highlightElement = self.currentFocusData.highlightElement
        if highlightElement then
            self:unsetHighlight(highlightElement)
        end
    end

    -- set(up) new gui focus
    self.currentGui = gui
    self.currentFocusData = self.guiFocusData[gui]
    if not self.currentFocusData then
        self.guiFocusData[gui] = {}
        self.guiFocusData[gui].idToElementMapping = {} -- all elements
        self.currentFocusData = self.guiFocusData[gui]
    else
        local focusElement = self.currentFocusData.initialFocusElement or self.currentFocusData.focusElement
        if focusElement ~= nil then
            local oldSound = focusElement.soundDisabled
            focusElement.soundDisabled = true
            self:setFocus(focusElement)
            focusElement.soundDisabled = oldSound
        end
    end

    -- reset delay locks
    self:resetFocusInputLocks()
end


---
function FocusManager:setSoundPlayer(guiSoundPlayer)
    self.soundPlayer = guiSoundPlayer
end


---Get a focusable GuiElement in the current view by its ID.
function FocusManager:getElementById(id)
    return self.currentFocusData.idToElementMapping[id]
end


---Get the currently focused GuiElement
function FocusManager:getFocusedElement()
    return self.currentFocusData.focusElement
end


---Get a new automatic focus ID.
-- It's based on a simple integer increment and will be unique unless billions of elements require an ID.
function FocusManager.serveAutoFocusId()
    local focusId = string.format("focusAuto_%d", FocusManager.autoIDcount)
    FocusManager.autoIDcount = FocusManager.autoIDcount + 1
    return focusId
end


---Load GuiElement focus data from its XML definition.
-- This is called at the end of GuiElement:loadFromXML().
function FocusManager:loadElementFromXML(xmlFile, xmlBaseNode, element)
    local focusId = getXMLString(xmlFile, xmlBaseNode.."#focusId")
    if not focusId then
        focusId = FocusManager.serveAutoFocusId()
    end

    element.focusId = focusId
    element.focusChangeData = {}
    -- assign focus change data from configuration if it has not been set by code:
    if not element.focusChangeData[FocusManager.TOP] then
        element.focusChangeData[FocusManager.TOP] = getXMLString(xmlFile, xmlBaseNode.."#focusChangeTop")
    end

    if not element.focusChangeData[FocusManager.BOTTOM] then
        element.focusChangeData[FocusManager.BOTTOM] = getXMLString(xmlFile, xmlBaseNode.."#focusChangeBottom")
    end

    if not element.focusChangeData[FocusManager.LEFT] then
        element.focusChangeData[FocusManager.LEFT] = getXMLString(xmlFile, xmlBaseNode.."#focusChangeLeft")
    end

    if not element.focusChangeData[FocusManager.RIGHT] then
        element.focusChangeData[FocusManager.RIGHT] = getXMLString(xmlFile, xmlBaseNode.."#focusChangeRight")
    end

    -- Disabled: it is unused at time of writing but breaks special focus setups for the construction screen
    --[[
    if GS_IS_CONSOLE_VERSION then
        element.focusChangeData[FocusManager.TOP]    = Utils.getNoNil(getXMLString(xmlFile, xmlBaseNode.."#consoleFocusChangeTop"), element.focusChangeData[FocusManager.TOP])
        element.focusChangeData[FocusManager.BOTTOM] = Utils.getNoNil(getXMLString(xmlFile, xmlBaseNode.."#consoleFocusChangeBottom"), element.focusChangeData[FocusManager.BOTTOM])
        element.focusChangeData[FocusManager.LEFT]   = Utils.getNoNil(getXMLString(xmlFile, xmlBaseNode.."#consoleFocusChangeLeft"), element.focusChangeData[FocusManager.LEFT])
        element.focusChangeData[FocusManager.RIGHT]  = Utils.getNoNil(getXMLString(xmlFile, xmlBaseNode.."#consoleFocusChangeRight"), element.focusChangeData[FocusManager.RIGHT])

        if element.focusChangeData[FocusManager.TOP] == "nil" then
            element.focusChangeData[FocusManager.TOP] = nil
        end

        if element.focusChangeData[FocusManager.BOTTOM] == "nil" then
            element.focusChangeData[FocusManager.BOTTOM] = nil
        end

        if element.focusChangeData[FocusManager.LEFT] == "nil" then
            element.focusChangeData[FocusManager.LEFT] = nil
        end

        if element.focusChangeData[FocusManager.RIGHT] == "nil" then
            element.focusChangeData[FocusManager.RIGHT] = nil
        end
    end
    ]]

    element.focused = (getXMLString(xmlFile, xmlBaseNode.."#focusInit") ~= nil)
    local isAlwaysFocusedOnOpen = (getXMLString(xmlFile, xmlBaseNode.."#focusInit") == "onOpen")
    element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen

    local focusChangeOverride = getXMLString(xmlFile, xmlBaseNode.."#focusChangeOverride")
    if focusChangeOverride then
        if element.target and element.target.focusChangeOverride then
            element.focusChangeOverride = element.target[focusChangeOverride]
        else
            self.focusChangeOverride = ClassUtil.getFunction(focusChangeOverride)
        end
    end

    if FocusManager.allElements[element] == nil then
        FocusManager.allElements[element] = {}
    end
    table.insert(FocusManager.allElements[element], self.currentGui)
    self.currentFocusData.idToElementMapping[focusId] = element

    if isAlwaysFocusedOnOpen then
        self.currentFocusData.initialFocusElement = element

        -- Force disable any sounds when loading
        local old = element.soundDisabled
        element.soundDisabled = true
        self:setFocus(element)
        element.soundDisabled = old
    else
        if not self.currentFocusData.focusElement then
            self.currentFocusData.focusElement = element
        end
    end
end


---Add an element to the focus system with custom values.
-- The caller should ensure that explicitly set focus IDs are unique. If a duplicate ID is encountered, only the first
-- element with that focus ID is considered for focusing. The method returns a boolean value to indicate any problems
-- with data assignment. Callers can evaluate the value to check if the given parameters were valid. If in doubt or
-- when no elaborate focus navigation is needed, rely on automatic focus ID generation by omitting the ID parameter
-- (or set it to nil).
-- @param element Element to add to focus system
-- @param focusId Focus ID for element
-- @param focusChangeData Custom focus navigation data for the element (map of direction to focus ID)
-- @param focusActive If true, the element should be focused right now
-- @param isAlwaysFocusedOnOpen If true, the element is supposed to be focused when its parent view is opened.
-- @return True if the element and all of its children could be set up with the given values, false otherwise.
function FocusManager:loadElementFromCustomValues(element, focusId, focusChangeData, focusActive, isAlwaysFocusedOnOpen)
    if focusId and self.currentFocusData.idToElementMapping[focusId] then
        return false -- ignore element, caller is responsible for sensible ID assignment when specified
    end

    if not element.focusId then
        if not focusId then
            focusId = FocusManager.serveAutoFocusId()
        end

        element.focusId = focusId
    end

    element.focusChangeData = element.focusChangeData or focusChangeData or {}
    element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen

    if FocusManager.allElements[element] == nil then
        FocusManager.allElements[element] = {}
    end
    table.insert(FocusManager.allElements[element], self.currentGui)
    self.currentFocusData.idToElementMapping[element.focusId] = element

    if isAlwaysFocusedOnOpen then
        self.currentFocusData.initialFocusElement = element
    end

    if focusActive then
        self:setFocus(element)
    end

    local success = true
    for _, child in pairs(element.elements) do
        success = success and self:loadElementFromCustomValues(child, child.focusId, child.focusChangeData, child.focusActive, child.isAlwaysFocusedOnOpen)
    end

    return success
end


---Remove a GuiElement from the current focus context.
function FocusManager:removeElement(element)
    if not element.focusId then
        return
    end

    for _, child in pairs(element.elements) do
        self:removeElement(child)
    end

    if element:getIsFocused() then
        element:onFocusLeave()
        FocusManager:unsetFocus(element)
    end

    if FocusManager.allElements[element] ~= nil then
        for _, guiItWasAddedTo in ipairs(FocusManager.allElements[element]) do
            local data = self.guiFocusData[guiItWasAddedTo]
            data.idToElementMapping[element.focusId] = nil
            if data.focusElement == element then
                data.focusElement = nil
            end
        end

        FocusManager.allElements[element] = nil -- remove
    end

    self.currentFocusData.idToElementMapping[element.focusId] = nil
    element.focusId = nil
    element.focusChangeData = {}

    if self.currentFocusData.focusElement == element then
        self.currentFocusData.focusElement = nil
    end
end


---Links an element's focus navigation to another element for a given direction.
-- The link is unidirectional from source to target. If bi-directional links are desired, call this method again with
-- swapped arguments.
-- @param sourceElement Source element which receives the focus link.
-- @param direction Navigation direction for the link, is not required to be the actual visual direction.
-- @param targetElement Target element
function FocusManager:linkElements(sourceElement, direction, targetElement)
    if targetElement == nil then
        sourceElement.focusChangeData[direction] = "nil"
    else
        sourceElement.focusChangeData[direction] = targetElement.focusId
    end
end


---Handles input and changes focus if required and possible.
-- @param action Name of navigation action which triggered the event, see InputAction
-- @param value Input value [-1, 1]
-- @param eventUsed Usage flag, no action is taken if this is true
-- @return True if the input event has been consumed, false otherwise
function FocusManager:inputEvent(action, value, eventUsed)
    local element = self.currentFocusData.focusElement

    local pressedAccept = false

    local direction
    if action == InputAction.MENU_AXIS_UP_DOWN and value > g_analogStickVTolerance then
        direction = FocusManager.TOP
    elseif action == InputAction.MENU_AXIS_UP_DOWN and value < -g_analogStickVTolerance then
        direction = FocusManager.BOTTOM
    elseif action == InputAction.MENU_AXIS_LEFT_RIGHT and value < -g_analogStickHTolerance then
        direction = FocusManager.LEFT
    elseif action == InputAction.MENU_AXIS_LEFT_RIGHT and value > g_analogStickHTolerance then
        direction = FocusManager.RIGHT
    end

    if direction ~= nil then
        self:updateFocus(element, direction, eventUsed)
    end

    if not eventUsed and element ~= nil and not element.needExternalClick then
        pressedAccept = action == InputAction.MENU_ACCEPT
        if pressedAccept and not self:isFocusInputLocked(action) then
            -- elements can get unfocused, accept is only allowed for currently focused and visible elements
            if element:getIsFocused() and element:getIsVisible() then
                self.focusSystemMadeChanges = true
                element:onFocusActivate()
                self.focusSystemMadeChanges = false
            end
        end
    end

    return eventUsed or direction ~= nil or pressedAccept
end


---Get a direction value for a given menu input action and value
function FocusManager.getDirectionForAxisValue(inputAction, value)
    if value == nil then
        return nil
    end

    local direction = nil
    if inputAction == InputAction.MENU_AXIS_UP_DOWN then
        if value < 0 then
            direction = FocusManager.BOTTOM
        elseif value > 0 then
            direction = FocusManager.TOP
        end
    elseif inputAction == InputAction.MENU_AXIS_LEFT_RIGHT then
        if value < 0 then
            direction = FocusManager.LEFT
        elseif value > 0 then
            direction = FocusManager.RIGHT
        end
    end

    return direction
end


---Checks if the focus manager has an input lock on  input.
-- @param inputAxis InputAction axis or action code
-- @param value Axis value [-1, 1] or nil if not a directional axis
-- @return isLocked True if locked, false otherwise
function FocusManager:isFocusInputLocked(inputAxis, value)
    local key = FocusManager.getDirectionForAxisValue(inputAxis, value)
    if key == nil and inputAxis ~= InputAction.MENU_AXIS_UP_DOWN and inputAxis ~= InputAction.MENU_AXIS_LEFT_RIGHT then
        key = inputAxis
    end

    if self.lastInput[key] and self.lockUntil[key] > g_time then
        return true
    else
        return false
    end
end


---Locks a given input axis action's input for a time. Until the delay has passed, the focus manager will not react to
-- that input.
-- @param inputAxis InputAction axis or action code
-- @param delay Delay in ms
-- @param value Axis value [-1, 1], only relevant to identify directional axes
function FocusManager:lockFocusInput(axisAction, delay, value)
    local key = FocusManager.getDirectionForAxisValue(axisAction, value)
    if not key and axisAction ~= InputAction.MENU_AXIS_UP_DOWN and axisAction ~= InputAction.MENU_AXIS_LEFT_RIGHT then
        key = axisAction
    end

    self.lastInput[key] = g_time
    self.lockUntil[key] = g_time + delay
end


---Release a focus movement input lock on an action.
-- Called by the UI input handling code. Avoid calling this for anything else.
-- @param action Focus movement input action name
function FocusManager:releaseMovementFocusInput(action)
    -- on input release we do not have a direction input value, need to clear lock for both directions on axes:
    if action == InputAction.MENU_AXIS_LEFT_RIGHT then
        self.lastInput[FocusManager.LEFT] = nil
        self.lockUntil[FocusManager.LEFT] = nil
        self.lastInput[FocusManager.RIGHT] = nil
        self.lockUntil[FocusManager.RIGHT] = nil
    elseif action == InputAction.MENU_AXIS_UP_DOWN then
        self.lastInput[FocusManager.TOP] = nil
        self.lockUntil[FocusManager.TOP] = nil
        self.lastInput[FocusManager.BOTTOM] = nil
        self.lockUntil[FocusManager.BOTTOM] = nil
    end
end


---Reset all locks of focus input.
function FocusManager:resetFocusInputLocks()
    for k, _ in pairs(self.lastInput) do
        self.lastInput[k] = nil
    end
    for k, _ in pairs(self.lockUntil) do
        self.lockUntil[k] = 0
    end
end


---Given a point and bounding box, get the closest other point on the bounding box circumference. If the point lies
-- within the bounding box, it is returned unchanged.
-- @param x Point X
-- @param y Point Y
-- @param boxMinX Bounding box minimum point X
-- @param boxMinY Bounding box minimum point Y
-- @param boxMaxX Bounding box maximum point X
-- @param boxMaxY Bounding box maximum point Y
-- @return Closest point x, y
function FocusManager.getClosestPointOnBoundingBox(x, y, boxMinX, boxMinY, boxMaxX, boxMaxY)
    local px, py = x, y
    if x < boxMinX then
        px = boxMinX
    elseif x > boxMaxX then
        px = boxMaxX
    end

    if y < boxMinY then
        py = boxMinY
    elseif y > boxMaxY then
        py = boxMaxY
    end

    return px, py
end


---Calculate the shortest connecting line segment between two bounding boxes. Overlapping boxes will result in flipped
-- directions, so take care.
function FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY, otherCenterX, otherCenterY)
    local ePointX, ePointY = FocusManager.getClosestPointOnBoundingBox(otherCenterX, otherCenterY, minX, minY, maxX, maxY)

    -- use the previously calculated bounding box point here to get the closest boundary distance
    local oPointX, oPointY = FocusManager.getClosestPointOnBoundingBox(ePointX, ePointY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY)

    -- get vector between bounding box points
    local elementDirX = oPointX - ePointX
    local elementDirY = oPointY - ePointY

    return elementDirX, elementDirY
end


---Checks the distance between two GuiElements with the aim of incrementally finding the closest other element in a
-- direction within a screen view.
-- @param curElement Current checking GuiElement
-- @param other Other GuiElement to compare
-- @param dirX Scan direction vector x component, normalized to unit length
-- @param dirY Scan direction vector y component, normalized to unit length
-- @param curElementOffsetY Position y offset of current element's bounding volume, used when checking for wrap-around
-- @param closestOther Previously closest other GuiElement
-- @param closestDistanceSq Squared distance from the current checking element to the previously closest other GuiElement
function FocusManager.checkElementDistance(curElement, other, dirX, dirY, curElementOffsetY, closestOther, closestDistanceSq)
    local retOther = closestOther
    local retDistSq = closestDistanceSq

    local minX, minY, maxX, maxY = curElement:getBorders()
    minY = minY + curElementOffsetY
    maxY = maxY + curElementOffsetY

    local centerX, centerY = curElement:getCenter()
    centerY = centerY + curElementOffsetY

    if other ~= curElement and not other.disabled and other:getIsVisible() and other:canReceiveFocus() and not (other:isChildOf(curElement) or curElement:isChildOf(other)) then
        local otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY = other:getBorders()
        local otherCenterX, otherCenterY = other:getCenter()

        -- get vector between bounding box points
        local elementDirX, elementDirY = FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY, otherCenterX, otherCenterY)

        -- test direction and distance of bounding box points
        local boxDistanceSq = MathUtil.vector2LengthSq(elementDirX, elementDirY)
        local dot = MathUtil.dotProduct(elementDirX, elementDirY, 0, dirX, dirY, 0)
        if boxDistanceSq < FocusManager.EPSILON then -- boundaries touch, use center points for direction check
            dot = MathUtil.dotProduct(otherCenterX - centerX, otherCenterY - centerY, 0, dirX, dirY, 0)
        end

        if dot > 0 then -- other element lies in scanning direction
            local useOther = false

            -- when two elements are equally close, choose the one further up (-y) and/or further left (-x)
            if closestOther and math.abs(closestDistanceSq - boxDistanceSq) < FocusManager.EPSILON then
                -- also compare dot products
                local closestBoxMinX, closestBoxMinY, closestBoxMaxX, closestBoxMaxY = closestOther:getBorders()
                local closestCenterX, closestCenterY = closestOther:getCenter()
                local toClosestX, toClosestY = FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, closestBoxMinX, closestBoxMinY, closestBoxMaxX, closestBoxMaxY, closestCenterX, closestCenterY)
                local closestDot = MathUtil.dotProduct(toClosestX, toClosestY, 0, dirX, dirY, 0)

                if math.abs(closestDot - dot) < FocusManager.EPSILON then -- same distance and angle as previous best
                    -- when going up, go right first, etc. --> ensure symmetric paths in all directions
                    if dirY > 0 then
                        useOther = other.absPosition[1] > closestOther.absPosition[1]
                    elseif dirY < 0 then
                        useOther = other.absPosition[1] < closestOther.absPosition[1]
                    elseif dirX > 0 then
                        useOther = other.absPosition[2] > closestOther.absPosition[2]
                    elseif dirX < 0 then
                        useOther = other.absPosition[2] < closestOther.absPosition[2]
                    end
                elseif dot > closestDot then -- when distance is equal and angles differ, prefer the one closer to the movement direction
                    useOther = true
                end
            elseif boxDistanceSq < closestDistanceSq then
                useOther = true
            end

            if useOther then
                retOther = other
                retDistSq = boxDistanceSq
            end
        end
    end

    return retOther, retDistSq
end


---Find the next other element to the one provided in a given navigation direction
-- @param element GUI element which needs a focus link
-- @param direction Direction constant [TOP | BOTTOM | LEFT | RIGHT]
-- @return Next GUI element in given direction which can be linked, actual scanning direction used (may change in wrap around scenarios)
function FocusManager:getNextFocusElement(element, direction)
    -- if there is a configured next element, return that
    local nextFocusId = element.focusChangeData[direction]
    if nextFocusId then
        return self.currentFocusData.idToElementMapping[nextFocusId], direction
    end
    -- otherwise, find the next one based on proximity:
    local dirX, dirY = unpack(FocusManager.DIRECTION_VECTORS[direction])

    local closestOther = nil
    local closestDistance = math.huge

    for _, other in pairs(self.currentFocusData.idToElementMapping) do
        closestOther, closestDistance = FocusManager.checkElementDistance(element, other, dirX, dirY, 0, closestOther, closestDistance)
    end

    if closestOther == nil then
        -- wrap around
        if direction == FocusManager.LEFT then
            -- look up instead
            closestOther, direction = self:getNextFocusElement(element, FocusManager.TOP)
        elseif direction == FocusManager.RIGHT then
            -- look down instead
            closestOther, direction = self:getNextFocusElement(element, FocusManager.BOTTOM)
        else
            -- get the right test elements
            local validWrapElements = self.currentFocusData.idToElementMapping -- screen wrap around
            if element.parent and element.parent.wrapAround then -- local box/area wrap around if required
                validWrapElements = element.parent.elements
            end

            local wrapOffsetY = 0
            if direction == FocusManager.TOP then
                wrapOffsetY = -1.2 - element.size[2] -- below screen must be <-1 to work in all cases, even though screen space is defined within [0, 1]
            elseif direction == FocusManager.BOTTOM then
                wrapOffsetY = 1.2 + element.size[2] -- above screen
            end

            -- try wrapping around
            for _, other in pairs(validWrapElements) do
                closestOther, closestDistance = FocusManager.checkElementDistance(element, other, dirX, dirY, wrapOffsetY, closestOther, closestDistance)
            end
        end
    end

    return closestOther, direction
end


---Get an element's focus target at the deepest nesting depth, e.g. when multiple nested layouts point down to their
-- child elements until only a single element is left which points to itself.
-- @param element GuiElement whose focus target needs to be retrieved
-- @param direction Focus navigation direction
-- @return Focus target
function FocusManager.getNestedFocusTarget(element, direction)
    local target = element
    local prevTarget = nil
    while target and prevTarget ~= target do
        prevTarget = target
        target = target:getFocusTarget(FocusManager.OPPOSING_DIRECTIONS[direction], direction)
    end

    return target
end


---Update the current focus target.
-- @param element GuiElement which should be the new focus target
-- @param isFocusMoving Only move focus if this is true
-- @param direction Focus navigation movement direction, one of FocusManager.[TOP | BOTTOM | LEFT | RIGHT]
-- @param updateOnly If true, only updates the lock state of focus movement for the given parameters
function FocusManager:updateFocus(element, direction, updateOnly)
    if element == nil then
        return
    end

    if self.lastInput[direction] then
        -- input is still blocked
        if self.lockUntil[direction] > g_time then
            return
        end

        -- delay has passed but we are still holding the button. set a new delay
        self.lockUntil[direction] = g_time + self.SCROLL_DELAY_TIME
    else
        self.lockUntil[direction] = g_time + self.INITIAL_DELAY_TIME
    end

    if updateOnly then
        return
    end

    -- delay has passed, focus change is allowed, delay is set up
    self.lastInput[direction] = g_time


    -- used if more than one button was pressed, only the first one is handled    -- TODO: is needed?, also: button priority
    if self.currentFocusData.focusElement ~= element then
        return
    end

    -- give the element the chance to override the focus change
    if element:shouldFocusChange(direction) then
        -- change focus
        local nextElement, nextElementIsSet
        if element.focusChangeOverride then
            if element.target then
                nextElementIsSet, nextElement = element.focusChangeOverride(element.target, direction)
            else
                nextElementIsSet, nextElement = element:focusChangeOverride(direction)
            end
        end

        local actualDirection = direction
        if not nextElementIsSet then
            nextElement, actualDirection = self:getNextFocusElement(element, direction)
        end

        if nextElement and nextElement:canReceiveFocus() then
            self:setFocus(nextElement, actualDirection)
            return
        else
            local focusElement = element
            nextElement = element
            if not element.focusChangeOverride or not element:focusChangeOverride(direction) then
                local maxSteps = 30
                while maxSteps > 0 do
                    if nextElement == nil then
                        break
                    end

                    nextElement, actualDirection = self:getNextFocusElement(nextElement, direction)
                    if nextElement ~= nil and nextElement:canReceiveFocus() then
                        focusElement = nextElement
                        break
                    end

                    maxSteps = maxSteps - 1
                end
            end

            self:setFocus(focusElement, actualDirection)
        end
    end
end


---Activate a highlight on an element. Highlighted elements are only visually marked and do not receive focus activation.
-- Only one element will be highlighted at any time, usually corresponding to the current mouse over target.
-- @param element Element to be highlighted.
function FocusManager:setHighlight(element)
    -- check if element has highlight already
    if self.currentFocusData.highlightElement and self.currentFocusData.highlightElement == element or not element.handleFocus then
        return
    end

    -- unset highlight of currently highlighted element
    self:unsetHighlight(self.currentFocusData.highlightElement)

    if not element.disallowFocusedHighlight or not (self.currentFocusData.focusElement and self.currentFocusData.focusElement == element) then
        -- set highlight of new element
        self.currentFocusData.highlightElement = element
        element:onHighlight()

        if not element:getSoundSuppressed() and element:getIsVisible() and element.playHoverSoundOnFocus ~= false and not element.soundDisabled then
            self.soundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
        end
    end
end


---Remove highlight status from an element.
-- @param element Highlighted element to revert
function FocusManager:unsetHighlight(element)
    if self.currentFocusData.highlightElement and self.currentFocusData.highlightElement == element then
        self.currentFocusData.highlightElement = nil
        element:onHighlightRemove()
    end
end


---Set focus on a GuiElement or its focus target.
-- Applies overlay state and triggers onFocusEnter() on the target.
-- @param element Element whose focus target (usually itself) receives focus.
-- @param direction Focus navigation direction
-- @param ... Variable arguments to pass on to the onFocusEnter callback of the target element
-- @return True if focus has changed, false otherwise
function FocusManager:setFocus(element, direction, ...)
    if FocusManager.isFocusLocked or element == nil or not element:canReceiveFocus() then
        return false
    end

    -- get the element's focus target (or a descendant's) to return
    local targetElement = FocusManager.getNestedFocusTarget(element, direction)
    if targetElement.target == nil or targetElement.target.name ~= self.currentGui then
        return false
    end

    if self.currentFocusData.focusElement and
            self.currentFocusData.focusElement == targetElement and
            self.currentFocusData.focusElement:getIsFocused() then
        -- the passed element already has focus
        return false
    end

    -- clear focus and highlight on previous elements
    if self.currentFocusData.focusElement ~= nil then
        self:unsetFocus(self.currentFocusData.focusElement)
        self:unsetHighlight(self.currentFocusData.highlightElement)
    end

    -- set focus of newly focused element
    targetElement:setFocused(true)
    self.currentFocusData.focusElement = targetElement
    targetElement:onFocusEnter(...)

    if FocusManager.DEBUG then
        log("focus changed to element", targetElement, "; ID:", targetElement.id, "; profile:", targetElement.profile, "; type:", targetElement.typeName)
    end

    if not element:getSoundSuppressed() and element:getIsVisible() and (element.playHoverSoundOnFocus ~= false or targetElement.customFocusSample ~= nil) and not element.soundDisabled then
        self.soundPlayer:playSample(targetElement.customFocusSample or GuiSoundPlayer.SOUND_SAMPLES.HOVER)
    end

    return true
end


---Removes focus from an element.
-- Applies overlay state and triggers onFocusLeave() on the target.
-- @param element Element which should lose focus
-- @param ... Variable arguments to pass on to the onFocusLeave callback of the target element
function FocusManager:unsetFocus(element, ...)
    local prevFocusElement = self.currentFocusData.focusElement
    if prevFocusElement ~= element or prevFocusElement == nil then
        -- the element is not focused
        return
    end

    if not element:getIsFocused() then
        -- the element has already lost focus
        return
    end

    prevFocusElement:onFocusLeave(...) -- call focus leave last, can override overlay state if desired
end


---Globally lock focus input.
function FocusManager:requireLock()
    FocusManager.isFocusLocked = true
end


---Release the global focus input lock.
function FocusManager:releaseLock()
    FocusManager.isFocusLocked = false
end


---Check if focus input is locked.
function FocusManager:isLocked()
    return FocusManager.isFocusLocked
end


---Determine if focus navigation in a given direction is currently locked.
-- @param direction Navigation direction as defined in constants
-- @return True if navigation in given direction is locked
function FocusManager:isDirectionLocked(direction)
    return self.lastInput[direction] ~= nil
end


---Determine if a GuiElement is currently focused.
function FocusManager:hasFocus(element)
    return ((self.currentFocusData.focusElement == element) and (element:getIsFocused()))
end


---Get a closure override function for elements' getFocusOverride() methods.
-- @param forDirections List of directions to override
-- @param substitute Element to substitute as focus target in overridden direction
-- @param useSubstituteForFocus (Optional) If true, the substitute parameter will be used as the origin for finding the
next focus target in the overridden direction.
function FocusManager:getFocusOverrideFunction(forDirections, substitute, useSubstituteForFocus)
    if forDirections == nil or #forDirections < 1 then
        return function(elementSelf, dir) return false, nil end
    end

    local f = function(elementSelf, dir)
        for _, overrideDirection in pairs(forDirections) do
            if dir == overrideDirection then
                if useSubstituteForFocus then
                    local next = self:getNextFocusElement(substitute, dir)
                    if next then
                        return true, next
                    end
                else
                    return true, substitute
                end
            end
        end

        return false, nil
    end

    return f
end


---Deletes the saved focus data for a specific gui
-- @param guiName name of the gui
function FocusManager:deleteGuiFocusData(guiName)
    self.guiFocusData[guiName] = nil
end
