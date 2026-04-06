










---A base, abstract state to be used with an implementation of the StateMachine class.
local BaseStateMachineState_mt = Class(BaseStateMachineState)









---Creates a base state machine state. This should only be done within a derived class, as this is an abstract class.
-- @param StateMachine stateMachine The state machine that manages this state.
-- @param table custom_mt The derived metatable to use.
-- @return BaseStateMachineState instance The created instance.
function BaseStateMachineState.new(stateMachine, custom_mt)

    -- Create the instance.
    local self = setmetatable({}, custom_mt or BaseStateMachineState_mt)

    -- Set the state machine.
    self.stateMachine = stateMachine

    -- Create the transitions table.
    self.transitions = {}

    -- The bounds of the state when debug-drawn to the screen.
    self.debugPositionX = nil
    self.debugPositionY = nil
    self.debugWidth = nil
    self.debugHeight = nil

    -- Return the created instance.
    return self
end









---Goes through each transition and runs the condition function. The first function that returns true will cause the state machine to switch to the associated state, and the state will be returned.
-- @return BaseStateMachineState? newState The state whose associated condition function returned true, and was successfully switched to in the state machine; otherwise nil.
function BaseStateMachineState:trySwitchToValidTransition()

    -- Go over each transition pair and check for validity.
    for state, binding in pairs(self.transitions) do

        -- If the condition passes, switch the state machine's current state to the state, if it successfully changes then return the state.
        if binding.conditionFunction(binding.context) then
            self.stateMachine:changeState(state)
            return state
        end
    end

    -- If no state was switched to, return nil.
    return nil
end


---Called just after the creation of all states, so that other states can be used to create transitions.
function BaseStateMachineState:createTransitions()

end


---Adds a transition to the given targetState whenever the given condition is true.
-- @param function conditionFunction The condition function that must return true for the target state to be switched to.
-- @param BaseStateMachineState targetState The state that will be transitioned to if the condition is true.
-- @param table contextObject The object used as the context to fire the condition function, if this is nil then the given targetState is used.
function BaseStateMachineState:addTransition(conditionFunction, targetState, contextObject)

    --#debug Assert.isType(conditionFunction, "function", "Transition must have a valid condition function!")
    --#debug Assert.isClass(targetState, BaseStateMachineState, "Transition's target state must inherit from BaseStateMachineState!")

    -- Add the transition object to the transitions table.
    self.transitions[targetState] = { context = contextObject or targetState, conditionFunction = conditionFunction }
    return self.transitions[targetState]
end


---Calculates if this state should be forced as the current state.
-- @return boolean isValid True if this state is valid and can be forced to be made current; otherwise false. False by default.
function BaseStateMachineState:calculateIfShouldBeForced()
    return false
end


---Calculates if this state is a valid state to enter back in on after a forced state.
-- @return boolean isValid True if this state is valid and can be made current; otherwise false. False by default.
function BaseStateMachineState:calculateIfValidEntryState()
    return false
end


---Fired when this state is entered.
-- @param BaseStateMachineState previousState The previous state the machine was in before entering this one.
function BaseStateMachineState:onStateEntered(previousState)

end


---Fired when this state is exited.
-- @param BaseStateMachineState nextState The state the machine will be in after exiting this one.
function BaseStateMachineState:onStateExited(nextState)

end


---Updates this state when it is currently the state machine's current state.
-- @param float dt Delta time in ms.
function BaseStateMachineState:updateAsCurrent(dt)

    -- Do nothing if the state machine is passive.
    if self.stateMachine:getIsPassive() then
        return
    end

    -- Go through the transitions and see if any are valid.
    self:trySwitchToValidTransition()
end


---Updates this state when it is currently NOT the state machine's current state.
-- @param float dt Delta time in ms.
function BaseStateMachineState:updateAsInactive(dt)

end


---Calculates the bounds in screen-space of the debug draw.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float width The total width of the whole state machine on the screen.
-- @param float height The total height of the whole state machine on the screen.
function BaseStateMachineState:caclulateDebugScreenBounds(x, y, width, height)

    -- No drawing can happen if there are no debug bound properties.
    if self.debugPositionX == nil or self.debugPositionY == nil or self.debugWidth == nil or self.debugHeight == nil then
        return nil, nil, nil, nil
    end

    return x + (self.debugPositionX * width), y + (self.debugPositionY * height), self.debugWidth * width, self.debugHeight * height
end


---Draws debug information for this state.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float width The total width of the whole state machine on the screen.
-- @param float height The total height of the whole state machine on the screen.
-- @param float textSize The height of the text.
function BaseStateMachineState:debugDraw(x, y, width, height, textSize, color)

    local frameX, frameY, frameWidth, frameHeight = self:caclulateDebugScreenBounds(x, y, width, height)
    if frameX == nil then
        return nil, nil, nil, nil
    end

    if color == nil then
        color = self.stateMachine.currentState == self and Color.PRESETS.GREEN or Color.PRESETS.GRAY
    end

    drawFilledRect(frameX, frameY, frameWidth, frameHeight, color:unpack())

    return frameX, frameY, frameWidth, frameHeight
end
