





---Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.
local VehicleActionControllerAction_mt = Class(VehicleActionControllerAction)


---
function VehicleActionControllerAction.new(parent, name, inputAction, priority, customMt)
    local self = setmetatable({}, customMt or VehicleActionControllerAction_mt)

    self.parent = parent
    self.name = name
    self.inputAction = inputAction
    self.priority = priority
    self.lastDirection = -1
    self.lastValidDirection = 0
    self.isSaved = false
    self.resetOnDeactivation = true
    self.identifier = ""

    self.aiEventListener = {}

    return self
end


---
function VehicleActionControllerAction:remove()
    self.parent:removeAction(self)
end


---
function VehicleActionControllerAction:updateParent(parent)
    if parent ~= self.parent then
        self.parent:removeAction(self)
        parent:addAction(self)
    end

    self.parent = parent
end


---
function VehicleActionControllerAction:setCallback(callbackTarget, inputCallback, inputCallbackRev)
    self.callbackTarget = callbackTarget
    self.inputCallback = inputCallback
    self.inputCallbackRev = inputCallbackRev

    self.identifier = callbackTarget.configFileName or ""
end


---
function VehicleActionControllerAction:setFinishedFunctions(finishedFunctionTarget, finishedFunc, finishedResult, finishedResultRev, finishedFuncRev)
    self.finishedFunctionTarget = finishedFunctionTarget
    self.finishedFunc = finishedFunc
    self.finishedFuncRev = finishedFuncRev
    self.finishedResult = finishedResult
    self.finishedResultRev = finishedResultRev
end


---
function VehicleActionControllerAction:setDeactivateFunction(deactivateFunctionTarget, deactivateFunc, inverseDeactivateFunc)
    self.deactivateFunctionTarget = deactivateFunctionTarget
    self.deactivateFunc = deactivateFunc
    self.inverseDeactivateFunc = Utils.getNoNil(inverseDeactivateFunc, false)
end


---
function VehicleActionControllerAction:setIsAvailableFunction(availableFunc)
    self.availableFunc = availableFunc
end


---
function VehicleActionControllerAction:setIsAccessibleFunction(accessibleFunc)
    self.accessibleFunc = accessibleFunc
end


---
function VehicleActionControllerAction:setActionIcons(iconPos, iconNeg, changeColor)
    self.iconPos = iconPos
    self.iconNeg = iconNeg
    self.iconChangeColor = changeColor
end


---
function VehicleActionControllerAction:setResetOnDeactivation(resetOnDeactivation)
    self.resetOnDeactivation = resetOnDeactivation
end


---
function VehicleActionControllerAction:setIsSaved(isSaved)
    self.isSaved = isSaved
end


---
function VehicleActionControllerAction:getIsSaved()
    return self.isSaved
end


---
function VehicleActionControllerAction:isAvailable()
    if self.availableFunc ~= nil then
        return self.availableFunc()
    end

    return true
end










---
function VehicleActionControllerAction:getControlledActionIcons()
    return self.iconPos, self.iconNeg, self.iconChangeColor
end


---
function VehicleActionControllerAction:getLastDirection()
    return self.lastDirection
end


---
function VehicleActionControllerAction:getDoResetOnDeactivation()
    return self.resetOnDeactivation
end


---
function VehicleActionControllerAction:addAIEventListener(sourceVehicle, eventName, direction, forceUntilFinished)
    self.sourceVehicle = sourceVehicle

    local listener = {}
    listener.eventName = eventName
    listener.direction = direction
    listener.forceUntilFinished = forceUntilFinished

    table.insert(self.aiEventListener, listener)
end



---
function VehicleActionControllerAction:registerActionEvents(target, vehicle, actionEvents, isActiveForInput, isActiveForInputIgnoreSelection)
    --local _, actionEventId = vehicle:addActionEvent(actionEvents, self.inputAction, target, VehicleActionControllerAction.onActionEvent, false, true, false, true)
    --g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
end


---
function VehicleActionControllerAction:actionEvent(actionName, inputValue, actionIndex, isAnalog)
    self:doAction()
end


---
function VehicleActionControllerAction:doAction(direction, isAIEvent)
    if direction == nil then
        direction = -self.lastDirection
    end
    self.lastDirection = direction

    local success = self.inputCallback(self.callbackTarget, direction, isAIEvent)
    if success then
        self.lastValidDirection = self.lastDirection
    end

    return success
end


---
function VehicleActionControllerAction:getIsFinished(direction)
    if self.finishedFunc ~= nil then
        if direction > 0 then
            return self.finishedFunc(self.finishedFunctionTarget) == self.finishedResult
        else
            return self.finishedFunc(self.finishedFunctionTarget) == self.finishedResultRev
        end
    end

    return true
end


---
function VehicleActionControllerAction:getSourceVehicle()
    return self.sourceVehicle
end


---
function VehicleActionControllerAction:onAIEvent(eventName)
    for _, listener in ipairs(self.aiEventListener) do
        if listener.eventName == eventName then
            if not self:doAction(listener.direction, true) and listener.forceUntilFinished then
                self.forceDirectionUntilFinished = listener.direction
            else
                if self.forceDirectionUntilFinished ~= nil then
                    if listener.direction ~= self.forceDirectionUntilFinished then
                        self.forceDirectionUntilFinished = nil
                    end
                end

                self.parent:stopActionSequence()
            end
        end
    end
end


---
function VehicleActionControllerAction:update(dt)
    if self.deactivateFunc ~= nil then
        if self.lastDirection == 1 then
            if self.deactivateFunc(self.deactivateFunctionTarget) == not self.inverseDeactivateFunc then
                if self.parent.currentSequenceIndex == nil and self.forceDirectionUntilFinished == nil then
                    self.parent:startActionSequence()
                end
            end
        end
    end
end


---
function VehicleActionControllerAction:updateForAI(dt)
    if self.forceDirectionUntilFinished ~= nil then
        if self:doAction(self.forceDirectionUntilFinished) then
            self.forceDirectionUntilFinished = nil
            self.parent:stopActionSequence()
        end
    end
end


---
function VehicleActionControllerAction:getDebugText()
    local finishedResult = "?"
    if self.finishedFunc ~= nil then
        finishedResult = self.finishedFunc(self.finishedFunctionTarget)
        if type(finishedResult) == "number" then
            finishedResult = string.format("%.1f", finishedResult)
        end
    end

    local vehicleName = "Unknown Vehicle"
    if self.callbackTarget ~= nil then
        vehicleName = self.callbackTarget:getName()
    end

    return string.format("Prio '%d' - Vehicle '%s' - Action '%s' (%s/%s)", self.priority, vehicleName, self.name, finishedResult, self.lastDirection == 1 and self.finishedResult or self.finishedResultRev)
end
