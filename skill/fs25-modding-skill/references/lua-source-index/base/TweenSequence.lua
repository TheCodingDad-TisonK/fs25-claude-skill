









---Allows setting up more complex tweening by defining sequences of tweens, intervals and callbacks. A sequence is
-- itself a Tween, so you may even define and add sub-sequences.
-- 
-- Before a sequence reacts to update() calls, it must be started with start(). This also applies after resetting.
-- 
-- Adding tweens, callbacks and intervals will append them to the current sequence. Insertion of tweens and callbacks
-- will insert them at the given relative instants, allowing for overlapping tweens and arbitrary callback times.
-- Inserting an interval will push pack all later instants by the given time.
local TweenSequence_mt = Class(TweenSequence, Tween)


---Create a new TweenSequence.
-- @param table? functionTarget [optional] Target table which is supplied by default to all tween setter functions and
callbacks as the first argument. If not specified, the setters and callbacks will be called with one value only.
function TweenSequence.new(functionTarget)
    local self = Tween.new(nil, nil, nil, nil, TweenSequence_mt)

    self.functionTarget = functionTarget
    self.callbackStates = {} -- callback -> callback state
    self.callbacksCalled = {} -- callback -> bool

    self.tweenUpdateRanges = {} -- tween -> {startInstant, endInstant}
    self.callbackInstants = {} -- callback -> instant

    self.isLooping = false
    self.totalDuration = 0
    self.isFinished = true

    return self
end


---Insert a tween at a given instant.
-- @param table tween Tween instance
-- @param float instant Time in milliseconds after sequence start
function TweenSequence:insertTween(tween, instant)
    self.tweenUpdateRanges[tween] = {instant, instant + tween:getDuration()}

    self.totalDuration = math.max(instant + tween:getDuration(), self.totalDuration)

    if self.functionTarget ~= nil then
        tween:setTarget(self.functionTarget)
    end
end


---Add a tween to the end of the sequence.
-- @param table tween Tween instance
function TweenSequence:addTween(tween)
    self:insertTween(tween, self.totalDuration)
end


---Insert an interval at the given instant.
-- This will push back all later instants by the interval. Use this to insert pauses into the sequence.
-- @param float interval Interval time in milliseconds
-- @param float instant Time in milliseconds after sequence start
function TweenSequence:insertInterval(interval, instant)
    for tween, range in pairs(self.tweenUpdateRanges) do
        local tweenStartInstant, tweenEndInstant = range[1], range[2]
        if tweenStartInstant >= instant then
            self.tweenUpdateRanges[tween][1] = tweenStartInstant + interval
            self.tweenUpdateRanges[tween][2] = tweenEndInstant + interval
        end
    end

    for callback, callbackInstant in pairs(self.callbackInstants) do
        if callbackInstant >= instant then
            self.callbackInstants[callback] = callbackInstant + interval
        end
    end

    self.totalDuration = self.totalDuration + interval
end


---Add an interval at the end of the sequence.
-- Use this to add a pause to the sequence.
function TweenSequence:addInterval(interval)
    self:insertInterval(interval, self.totalDuration)
end


---Insert a callback at the given instant.
-- @param function callback Callback function with signature of either callback(target, value) or callback(value)
-- @param table callbackState Any value which is passed to the callback as its first (no target) or second (with target) argument
-- @param float instant Time in milliseconds after sequence start
function TweenSequence:insertCallback(callback, callbackState, instant)
    self.callbackInstants[callback] = instant
    self.callbackStates[callback] = callbackState
    self.callbacksCalled[callback] = false
end


---Add a callback at the end of the sequence.
-- @param function callback Callback function with signature of either callback(target, value) or callback(value)
-- @param table callbackState Any value which is passed to the callback as its first (no target) or second (with target) argument
function TweenSequence:addCallback(callback, callbackState)
    self:insertCallback(callback, callbackState, self.totalDuration)
end


---Get this tween's duration in milliseconds.
function TweenSequence:getDuration()
    return self.totalDuration
end


---Set a callback target for this tween.
-- If a target has been set, the setter function must support receiving the target as its first argument.
function TweenSequence:setTarget(target)
    self.functionTarget = target
end


---Set the looping state for this sequence.
-- @param boolean isLooping If true, will restart the sequence when finished, including callbacks!
function TweenSequence:setLooping(isLooping)
    self.isLooping = isLooping
end


---Start the sequence.
-- A sequence will only update its state when it has been started.
function TweenSequence:start()
    self.isFinished = false
end


---Stop the sequence.
function TweenSequence:stop()
    self.isFinished = true
end


---Reset the sequence to its initial state.
function TweenSequence:reset()
    self.elapsedTime = 0
    self.isFinished = true

    for tween in pairs(self.tweenUpdateRanges) do
        tween:reset()
    end

    for callback in pairs(self.callbacksCalled) do
        self.callbacksCalled[callback] = false
    end
end


---Update the sequence state over time.
function TweenSequence:update(dt)
    if not self.isFinished then
        local lastUpdateInstant = self.elapsedTime
        self.elapsedTime = self.elapsedTime + dt

        local allFinished = self:updateTweens(lastUpdateInstant, dt)
        self:updateCallbacks()

        if self.elapsedTime >= self.totalDuration and allFinished then
            if self.isLooping then
                self:reset()
                self:start()
            else
                self.isFinished = true
            end
        end
    end
end


---Update active sequence tweens.
-- @param float lastInstant Last instant which received an update
-- @param float dt Delta time
function TweenSequence:updateTweens(lastInstant, dt)
    local allFinished = true

    for tween, range in pairs(self.tweenUpdateRanges) do
        local tweenStart = range[1]
        if not tween:getFinished() and self.elapsedTime >= tweenStart then
            local maxDt = math.min(self.elapsedTime - tweenStart, dt)
            tween:update(maxDt)
            allFinished = allFinished and tween:getFinished()
        end
    end

    return allFinished
end


---Update callback states.
function TweenSequence:updateCallbacks()
    for callback, instant in pairs(self.callbackInstants) do
        if not self.callbacksCalled[callback] and instant <= self.elapsedTime then
            if self.functionTarget ~= nil then
                callback(self.functionTarget, self.callbackStates[callback])
            else
                callback(self.callbackStates[callback])
            end

            self.callbacksCalled[callback] = true
        end
    end
end
