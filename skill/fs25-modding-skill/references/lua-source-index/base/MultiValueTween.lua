








---Tween class which handles multiple values at the same time.
-- 
-- Start and end values must be passed in as arrays. The setter function must be able to handle as many arguments as
-- there were entries in the start and end values arrays: setter called as function(unpack(values)).
-- 
local MultiValueTween_mt = Class(MultiValueTween, Tween)


---Create a new Tween.
-- @param table subClass Subclass metatable for inheritance
-- @param function setterFunction Values setter function. Signature: callback(v1, ..., vn) or callback(target, v1, ..., vn).
-- @param table startValues Original values
-- @param table endValues Target values
-- @param float duration Duration of tween in milliseconds
function MultiValueTween.new(setterFunction, startValues, endValues, duration, customMt)
    local self = Tween.new(setterFunction, startValues, endValues, duration, customMt or MultiValueTween_mt)

    self.values = {unpack(startValues)}

    return self
end


---Set a callback target for this tween.
-- If a target has been set, the setter function must support receiving the target as its first argument.
function MultiValueTween:setTarget(target)
    local hadTarget = self.functionTarget ~= nil
    MultiValueTween:superClass().setTarget(self, target)

    if target ~= nil and not hadTarget then
        table.insert(self.values, 1, target)
    elseif target == nil and hadTarget then
        table.remove(self.values, 1)
    else
        self.values[1] = target
    end
end


---Get the current tween value.
function MultiValueTween:tweenValue(t)
    local targetOffset = self.functionTarget ~= nil and 1 or 0

    for i = 1, #self.startValue do
        local startValue = self.startValue[i]
        local endValue = self.endValue[i]
        self.values[i + targetOffset] = MathUtil.lerp(startValue, endValue, self.curveFunc(t))
    end

    return self.values
end


---Apply a value via the setter function.
function MultiValueTween:applyValue()
    self.setter(unpack(self.values)) -- includes target as first entry if it was set
end
