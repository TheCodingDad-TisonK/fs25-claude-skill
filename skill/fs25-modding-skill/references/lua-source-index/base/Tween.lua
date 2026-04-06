









---Tween class which linearly interpolates a quantity from a start value to an end value over a given duration.
local Tween_mt = Class(Tween)


---Create a new Tween.
-- @param function setterFunction Value setter function. Signature: callback(value) or callback(target, value).
-- @param float startValue Original value
-- @param float endValue Target value
-- @param float duration Duration of tween in milliseconds
-- @param table? customMt Subclass metatable for inheritance
function Tween.new(setterFunction, startValue, endValue, duration, customMt)
    local self = setmetatable({}, customMt or Tween_mt)

    self.setter = setterFunction
    self.startValue = startValue
    self.endValue = endValue
    self.duration = duration
    self.elapsedTime = 0

    self.isFinished = duration == 0
    self.functionTarget = nil

    self.curveFunc = Tween.CURVE.LINEAR

    return self
end


---Get this tween's duration in milliseconds.
function Tween:getDuration()
    return self.duration
end


---Check if this tween has finished.
function Tween:getFinished()
    return self.isFinished
end


---Reset this tween to play it again.
function Tween:reset()
    self.elapsedTime = 0
    self.isFinished = self.duration == 0
end


---Set a callback target for this tween.
-- If a target has been set, the setter function must support receiving the target as its first argument.
function Tween:setTarget(target)
    self.functionTarget = target
end


---Update the tween's state.
function Tween:update(dt)
    if self.isFinished then
        return
    end

    self.elapsedTime = self.elapsedTime + dt

    local newValue
    if self.elapsedTime >= self.duration then
        self.isFinished = true
        newValue = self:tweenValue(1)
    else
        local t = self.elapsedTime / self.duration
        newValue = self:tweenValue(t)
    end

    self:applyValue(newValue)
end


---Get the current tween value.
function Tween:tweenValue(t)
    return MathUtil.lerp(self.startValue, self.endValue, self.curveFunc(t))
end


---Apply a value via the setter function.
function Tween:applyValue(newValue)
    if self.functionTarget ~= nil then
        self.setter(self.functionTarget, newValue)
    else
        self.setter(newValue)
    end
end


---Set the curve function. Defaults to Tween.CURVE.LINEAR
function Tween:setCurve(func)
    self.curveFunc = func or Tween.CURVE.LINEAR
end
