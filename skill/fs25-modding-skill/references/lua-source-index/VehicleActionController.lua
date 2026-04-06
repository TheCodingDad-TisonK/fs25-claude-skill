





---Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.
local VehicleActionController_mt = Class(VehicleActionController)




---
function VehicleActionController.new(vehicle, customMt)
    local self = setmetatable({}, customMt or VehicleActionController_mt)

    self.vehicle = vehicle
    self.actions = {}
    self.actionsByPrio = {}
    self.sortedActions = {}
    self.sortedActionsRev = {}
    self.currentSequenceActions = {}
    self.actionEvents = {}

    self.lastDirection = -1
    self.pendingControllerReactivation = false

    self.loadedNumActions = 0

    return self
end


---
function VehicleActionController:saveToXMLFile(xmlFile, key, usedModNames)
    if #self.actions > 0 then
        xmlFile:setValue(key.."#lastDirection", self.lastDirection)
        xmlFile:setValue(key.."#numActions", #self.actions)

        local i = 0
        for _, action in ipairs(self.actions) do
            if action:getIsSaved() then
                local actionKey = string.format("%s.action(%d)", key, i)
                xmlFile:setValue(actionKey.."#name", action.name)
                xmlFile:setValue(actionKey.."#identifier", action.identifier)
                xmlFile:setValue(actionKey.."#lastDirection", action:getLastDirection())
                i = i + 1
            end
        end
    end
end


---
function VehicleActionController:load(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        self.lastDirection = savegame.xmlFile:getValue(savegame.key..".actionController#lastDirection", self.lastDirection)
        self.loadedNumActions = savegame.xmlFile:getValue(savegame.key..".actionController#numActions", 0)
        self.loadTime = g_time

        local needsToApply = false

        self.loadedActions = {}
        local i = 0
        while true do
            local baseKey = string.format("%s.actionController.action(%d)", savegame.key, i)
            if not savegame.xmlFile:hasProperty(baseKey) then
                break
            end

            local action = {}
            action.name = savegame.xmlFile:getValue(baseKey.."#name")
            action.identifier = savegame.xmlFile:getValue(baseKey.."#identifier")
            action.lastDirection = savegame.xmlFile:getValue(baseKey.."#lastDirection")
            if action.lastDirection > 0 then
                needsToApply = true
            end

            table.insert(self.loadedActions, action)

            i = i + 1
        end
        if not needsToApply then
            self.loadedNumActions = 0
            self.loadedActions = {}
        end
    end
end


---
function VehicleActionController:registerAction(name, inputAction, prio)
    local action = VehicleActionControllerAction.new(self, name, inputAction, prio)
    self:addAction(action)

    return action
end


---
function VehicleActionController:addAction(action)
    table.insert(self.actions, action)

    self:updateSortedActions()

    self.actionsDirty = true

    self.vehicle:requestActionEventUpdate()
end


---
function VehicleActionController:removeAction(action)
    if Platform.gameplay.automaticVehicleControl then
        if action:getLastDirection() == 1 then
            if action:getDoResetOnDeactivation() then
                action:doAction()
            end
        end
    end

    for i, v in ipairs(self.actions) do
        if v == action then
            table.remove(self.actions, i)
            break
        end
    end

    -- reset direction state if no actions connected
    if #self.actions == 0 then
        self.lastDirection = -1
    end

    self:updateSortedActions()
end


---
function VehicleActionController:updateSortedActions()
    local prioToActionTable = {}
    self.actionsByPrio = {}
    for _, action in ipairs(self.actions) do
        if prioToActionTable[action.priority] == nil then
            local prioTable = {action}
            table.insert(self.actionsByPrio, prioTable)

            prioToActionTable[action.priority] = prioTable
        else
            table.insert(prioToActionTable[action.priority], action)
        end
    end


    local sortFunc = function(a, b) return a[1].priority > b[1].priority end
    self.sortedActions = table.clone(self.actionsByPrio)
    table.sort(self.sortedActions, sortFunc)

    local sortFuncRev = function(a, b) return a[1].priority < b[1].priority end
    self.sortedActionsRev = table.clone(self.actionsByPrio)
    table.sort(self.sortedActionsRev, sortFuncRev)
end


---
function VehicleActionController:activate()
    if self.pendingControllerReactivation then
        if self.vehicle == self.vehicle.rootVehicle then
            -- reactivation of the controlled actions
            -- some of them might have been turned of by the deactivation of the vehicle (e.g. turnOn)
            -- we avoid a complete deactivation of the controlled actions in :deactivate() to keep the current folding and lowered state
            -- so it's not too annoying while just switching to another vehicle
            self.lastDirection = -self.lastDirection
            self:startActionSequence(true)
        end

        self.pendingControllerReactivation = false
    end
end


---
function VehicleActionController:deactivate()
    if self.vehicle == self.vehicle.rootVehicle then
        if self.lastDirection > 0 then
            self.pendingControllerReactivation = true
        end
    end
end


---
function VehicleActionController:registerActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if #self.actions > 0 and self.vehicle.rootVehicle == self.vehicle then
        self.vehicle:clearActionEventsTable(self.actionEvents)
        for _, action in ipairs(self.actions) do
            action:registerActionEvents(self, self.vehicle, self.actionEvents, isActiveForInput, isActiveForInputIgnoreSelection)
        end

        if self.actionEventId ~= nil then
            g_inputBinding:removeActionEvent(self.actionEventId)
        end

        local _, actionEventId, _ = g_inputBinding:registerActionEvent(InputAction.VEHICLE_ACTION_CONTROL, self, VehicleActionController.actionSequenceEvent, false, true, false, true)
        self.actionEventId = actionEventId
    end
end


---
function VehicleActionController:actionEvent(actionName, inputValue, actionIndex, isAnalog)
    self:doAction(actionIndex)
end


---
function VehicleActionController:doAction(actionIndex, customTable, direction)
    local actions = self:getActionsByIndex(actionIndex, customTable)

    if actions ~= nil then
        local retValue = false
        for _, action in ipairs(actions) do
            local success = action:doAction(direction)
            retValue = retValue or success
        end

        return retValue
    end

    return false
end


---
function VehicleActionController:actionSequenceEvent()
    if self.loadedNumActions ~= 0 then -- don't play the controlled action if pressed directly after loading since we first apply the last state
        return
    end

    if self.vehicle.getAreControlledActionsAccessible ~= nil then
        if not self.vehicle:getAreControlledActionsAccessible() then
            return
        end
    end

    if self.vehicle.getAreControlledActionsAvailable ~= nil then
        if not self.vehicle:getAreControlledActionsAvailable() then
            return
        end

        local allowed, warning = self.vehicle:getAreControlledActionsAllowed()
        if not allowed then
            if warning ~= nil then
                g_currentMission:showBlinkingWarning(warning, 2500)
            end

            return
        end
    end

    self:startActionSequence()
end


---
function VehicleActionController:startActionSequence(force)
    local direction = -self.lastDirection

    self.currentSequenceActions = self.sortedActionsRev
    if direction > 0 then
        self.currentSequenceActions = self.sortedActions
    end

    if not force then
        local alreadyFinished = true
        for _, actions in ipairs(self.currentSequenceActions) do
            for _, action in ipairs(actions) do
                local finished = action.lastValidDirection == direction
                alreadyFinished = alreadyFinished and finished
            end
        end

        -- if we are already in the target state we restart the sequence to flip the direction
        if alreadyFinished then
            self.lastDirection = direction
            self:startActionSequence(true)
            return
        end
    end

    if self.currentSequenceIndex ~= nil then
        self.currentSequenceIndex = self.currentMaxSequenceIndex - (self.currentSequenceIndex - 1)
    else
        self.currentSequenceIndex = 1
        self.currentMaxSequenceIndex = #self.currentSequenceActions
    end

    self.lastDirection = direction
    if not self:doAction(self.currentSequenceIndex, self.currentSequenceActions, self.lastDirection) then
        if self.currentMaxSequenceIndex == 1 then
            -- failed to even execute one action, so we keep the direction
            self.lastDirection = -direction
            self:stopActionSequence()
        else
            self:continueActionSequence()
        end
    end
end


---
function VehicleActionController:continueActionSequence()
    self.currentSequenceIndex = self.currentSequenceIndex + 1
    local success = self:doAction(self.currentSequenceIndex, self.currentSequenceActions, self.lastDirection)

    if self.currentSequenceIndex >= self.currentMaxSequenceIndex then
        self:stopActionSequence()
    else
        if not success then
            self:continueActionSequence()
        end
    end
end


---
function VehicleActionController:stopActionSequence()
    self.currentSequenceActions = nil
    self.currentSequenceIndex = nil
    self.currentMaxSequenceIndex = nil
end


---
function VehicleActionController:getActionsByIndex(actionIndex, customTable)
    if customTable ~= nil then
        return customTable[actionIndex]
    else
        return self.actionsByPrio[actionIndex]
    end
end


---
function VehicleActionController:getAreControlledActionsAvailable()
    for i=1, #self.actions do
        if not self.actions[i]:isAvailable() then
            return false
        end
    end

    return #self.actions > 0
end


---
function VehicleActionController:getAreControlledActionsAccessible()
    for i=1, #self.actions do
        if not self.actions[i]:isAccessible() then
            return false
        end
    end

    return #self.actions > 0
end


---
function VehicleActionController:getControlledActionIcons()
    for i=1, #self.actions do
        local iconPos, iconNeg, changeColor = self.actions[i]:getControlledActionIcons()
        if iconPos ~= nil then
            return iconPos, iconNeg, changeColor
        end
    end

    return nil
end


---
function VehicleActionController:playControlledActions()
    if self.loadedNumActions == 0 then -- don't play the controlled action if pressed directly after loading since we first apply the last state
        self:startActionSequence()
    end
end


---
function VehicleActionController:resetCurrentState()
    self.lastDirection = -1
end


---
function VehicleActionController:getActionControllerDirection()
    return -self.lastDirection
end


---
function VehicleActionController:update(dt)
    if self.currentSequenceIndex ~= nil then
        if self.currentSequenceIndex <= self.currentMaxSequenceIndex then
            local actions = self:getActionsByIndex(self.currentSequenceIndex, self.currentSequenceActions)
            if actions ~= nil then
                local allFinished = true
                for _, action in ipairs(actions) do
                    if not action:getIsFinished(self.lastDirection) then
                        allFinished = false
                        break
                    end
                end

                if allFinished then
                    if self.currentSequenceIndex < self.currentMaxSequenceIndex then
                        self:continueActionSequence()
                    else
                        self:stopActionSequence()
                    end
                end
            end
        end
    end

    for _, action in ipairs(self.actions) do
        action:update(dt)
    end

    -- apply the loaded state from savegame to the actions
    if self.loadedNumActions ~= 0 and self.loadedNumActions == #self.actions and self.loadTime + 500 < g_time then
        local isStarted = true
        if self.vehicle.getIsMotorStarted ~= nil then
            isStarted = self.vehicle:getIsMotorStarted()
        end

        if isStarted then
            for _, loadedAction in ipairs(self.loadedActions) do
                for _, actionToCheck in ipairs(self.actions) do
                    if actionToCheck.name == loadedAction.name then
                        if actionToCheck.identifier == loadedAction.identifier then
                            if actionToCheck:getLastDirection() ~= loadedAction.lastDirection then
                                actionToCheck:doAction()
                            end
                        end
                    end
                end
            end
            self.loadedNumActions = 0
            self.actionsDirty = false
        end
    end

    -- if a new action was added we check if the action has a different direction than the controller and if so, we execute the action
    if self.actionsDirty and self.loadedNumActions == 0 then
        for _, action in ipairs(self.actions) do
            if action:getLastDirection() ~= self.lastDirection then
                action:doAction()
            end
        end

        self.actionsDirty = nil
    end
end



---
function VehicleActionController:updateForAI(dt)
    for _, action in ipairs(self.actions) do
        action:updateForAI(dt)
    end
end


---
function VehicleActionController:onAIEvent(sourceVehicle, eventName)
    for _, action in ipairs(self.actions) do
        if action:getSourceVehicle() == sourceVehicle then
            action:onAIEvent(eventName)
        end
    end
end


---
function VehicleActionController:drawDebugRendering()
    local renderTextVAC = function(x, y, height, text, color)
        setTextColor(0.0, 0.0, 0.0, 0.75)
        renderText(x, y-0.0015, height, text)

        color = color or {1,1,1,1}
        setTextColor(unpack(color))
        renderText(x, y, height, text)
    end

    local drawActions = function(name, sequenceActions, highlightIndex, posX, posY)
        if sequenceActions ~= nil and #sequenceActions > 0 then
            setTextBold(false)
            setTextAlignment(RenderText.ALIGN_CENTER)
            local textHeight = 0.012
            local lineSpacing = 0.002
            local lineHeight = textHeight + lineSpacing

            local currentHeight = 0
            for i=#sequenceActions, 1, -1 do
                local actions = sequenceActions[i]

                setTextBold(highlightIndex == i)
                local color
                if i < highlightIndex then
                    color = {0,1,0,1}
                elseif i == highlightIndex then
                    color = {1,0.5,0,1}
                end

                for _, action in ipairs(actions) do
                    renderTextVAC(posX, posY+currentHeight, textHeight, action:getDebugText(), color)
                    currentHeight = currentHeight + lineHeight
                end

                renderTextVAC(posX, posY+currentHeight+lineHeight*0.5, textHeight, "__________________________")
                currentHeight = currentHeight + lineHeight
            end

            renderTextVAC(posX, posY+currentHeight+lineHeight*0.5, textHeight*1.5, name)

            setTextBold(false)
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
    end

    -- all actions
    drawActions(string.format("Controlled Actions (%s)", self.lastDirection == 1 and "On" or "Off"), self.sortedActions, -1, 0.2, 0.3)

    -- current action sequence
    local directionText = self.lastDirection == 1 and "TurnOn" or "TurnOff"
    drawActions(string.format("Current Action Sequence (%s)", directionText), self.currentSequenceActions, self.currentSequenceIndex, 0.4, 0.3)
end


---
function VehicleActionController.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#lastDirection", "Last action controller direction")
    schema:register(XMLValueType.INT, basePath .. "#numActions", "Action controller actions")
    schema:register(XMLValueType.STRING, basePath .. ".action(?)#name", "Action name")
    schema:register(XMLValueType.STRING, basePath .. ".action(?)#identifier", "Action identifier")
    schema:register(XMLValueType.INT, basePath .. ".action(?)#lastDirection", "Last action direction")
end
