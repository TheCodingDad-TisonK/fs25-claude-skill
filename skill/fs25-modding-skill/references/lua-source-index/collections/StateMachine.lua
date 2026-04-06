










---A base, abstract state machine.
local StateMachine_mt = Class(StateMachine)





---Creates a base state machine. This should only be done within a derived class, as this is an abstract class.
-- @param table custom_mt The derived metatable to use.
-- @return StateMachine instance The created instance.
function StateMachine.new(custom_mt)

    -- Create the instance.
    local self = setmetatable({}, custom_mt or StateMachine_mt)

    -- Start with no state and no default state.
    self.currentState = nil
    self.defaultState = nil

    -- The passive value. If a state machine is passive, it never transitions between states during updates, it must be explicitly driven.
    self.isPassive = false

    -- The states table.
    self.states = {}

    -- The array of states by index, sorted by state name alphabetically.
    self.sortedStates = nil

    -- Return the created instance.
    return self
end





























---Copies all members from the BaseStateMachineState class into the class table used to call this function. Call this on the class table just after the Class() call to allow a state machine to also act as a state.
function StateMachine:implementStateInterface()

    -- Copy each value over from the base state class table over to this one. Don't overwrite anything.
    for name, value in pairs(BaseStateMachineState) do
        if not self[name] then
            self[name] = value
        end
    end
end


---Changes the current state of the machine to the given state.
-- @param BaseStateMachineState newState The state to switch to.
-- @param any ... The arguments passed into the onStateEntered function of the given state.
function StateMachine:changeState(newState, ...)
--     log("State change", self:getNameOfState(self.currentState), "to", self:getNameOfState(newState))

    -- Keep track of the old state.
    local previousState = self.currentState

    -- Switch the state and alert the states of the change.
    self.currentState = newState
    previousState:onStateExited(newState)
    newState:onStateEntered(previousState, ...)
end










---Goes over each state and calls the BaseStateMachineState.createTransitions function. This is not called by the base class by default.
-- @param any ... The arguments passed into the createTransitions function of the given state.
function StateMachine:initialiseStateTransitions(...)
    for _, state in pairs(self.states) do
        state:createTransitions(...)
    end
end


---Determines the best state to switch to based on the states' calculateIfValidEntryState function. Switches to the first state that returns true, defaulting to self.defaultState.
function StateMachine:determineState()

    -- Go over each state, the first one to be valid is the new state.
    for _, state in pairs(self.states) do
        if state:calculateIfValidEntryState() then
            self:changeState(state)
            return
        end
    end

    -- Since no state was chosen, use the default state.
    self:changeState(self.defaultState)
end


---Resolves the current state of this state machine. If this.currentState has a resolveCurrentState function, its result is returned; otherwise the state itself is returned.
-- @return BaseStateMachineState currentState The fully resolved current state.
function StateMachine:resolveCurrentState()

    -- If the current state has a function to resolve the current state (e.g. if it is a state machine), return the result of the function call; otherwise return the current state.
    return self.currentState.resolveCurrentState ~= nil and self.currentState:resolveCurrentState() or self.currentState
end


---Gets the name of the current state. Internally calls self:getNameOfState(self.currentState).
-- @return string name The name of the current state.
function StateMachine:getCurrentStateName()
    return self:getNameOfState(self.currentState)
end


---Gets the name of the given state.
-- @param BaseStateMachineState state The state whose name should be returned.
-- @return string name The name of the state, or nil if the state is not in the machine.
function StateMachine:getNameOfState(state)

    if state == nil then
        return "No state"
    end

    -- If the state is missing a name, initialise the state names.
    if string.isNilOrWhitespace(state.name) then
        self:initialiseStateNames()
    end

    -- Return the state's name,
    return state.name
end


---Gets the index of the current state. Internally calls self:getIndexOfState(self.currentState).
-- @return number index The index of the current state.
function StateMachine:getCurrentStateIndex()
    return self:getIndexOfState(self.currentState)
end


---Gets the index of the given state.
-- @param BaseStateMachineState state The state whose index should be returned.
-- @return integer index The index of the state, or nil if the state is not in the machine.
function StateMachine:getIndexOfState(state)

    --#debug Assert.isType(state, "table")

    -- If mappings have not yet been created, do so.
    if not self:getHasMappings() then
        self:createStateIndexNameMapping()
    end

    for i, otherState in ipairs(self.sortedStates) do
        if otherState == state then
            return i
        end
    end

    return nil
end


---Gets the state associated with the given index.
-- @param integer index The index of the state to get.
-- @return BaseStateMachineState state The state with the associated index, or nil if none exists.
function StateMachine:getStateByIndex(index)

    --#debug Assert.isType(index, "number")

    -- If mappings have not yet been created, do so.
    if not self:getHasMappings() then
        self:createStateIndexNameMapping()
    end

    local state = self.sortedStates[index]
    return state
end






---Gets the passive value for the state machine. Passive state machines do not change states during an update, and must be explicitly told when to change state.
-- @return boolean isPassive True if this state machine is passive; otherwise false.
function StateMachine:getIsPassive()
    return self.isPassive
end


---Sets the passive value for the state machine.
-- @param boolean isPassive If this state machine should be passive.
function StateMachine:setIsPassive(isPassive)
    self.isPassive = isPassive == true
end


---The update function which updates each state.
-- @param float dt Delta time in ms.
function StateMachine:update(dt)
--#profile     RemoteProfiler.zoneBeginN("StateMachine-update")
    -- Check to see if any state wants to be forced, if the state machine is not passive.
    if not self:getIsPassive() then
        for _, state in pairs(self.states) do

            -- If the state should be forced, switch to it and skip the other states.
            if state:calculateIfShouldBeForced() then
                if state ~= self.currentState then
--#profile     RemoteProfiler.zoneBeginN("StateMachine-stateChange: " .. (state.name or state.__CLASSNAME or ""))
                    self:changeState(state)
--#profile     RemoteProfiler.zoneEnd()
                    break
                end
            end
        end
    end

    -- Update the states based on if they're current or not.
    for _, state in pairs(self.states) do
--#profile     RemoteProfiler.zoneBeginN("StateMachine-stateUpdate: " .. (state.name or state.__CLASSNAME or ""))
        if state ~= self.currentState then
            state:updateAsInactive(dt)
        else
            state:updateAsCurrent(dt)
        end
--#profile     RemoteProfiler.zoneEnd()
    end
--#profile     RemoteProfiler.zoneEnd()
end


---Calls a function with the given name on every state.
-- @param string functionName The name of the function to call.
-- @param any ... The parameters to pass along.
function StateMachine:callStateFunction(functionName, ...)

    -- Push the call forwards to all states with the function.
    for _, state in pairs(self.states) do
        if state[functionName] ~= nil then
            state[functionName](state, ...)
        end
    end
end
