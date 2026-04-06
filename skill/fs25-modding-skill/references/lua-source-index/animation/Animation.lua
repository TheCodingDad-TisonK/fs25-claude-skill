










---
local Animation_mt = Class(Animation)


---
function Animation.new(customMt)
    local self = setmetatable({}, customMt or Animation_mt)

    self.duplicates = {}

    self.allowUpdate = true
    self.lastUpdateTime = 0

    return self
end


---
function Animation:delete()
    for i=#self.duplicates, 1, -1 do
        self.duplicates[i] = nil
    end
end


---
function Animation:update(dt)
end


---
function Animation:isRunning()
    return false
end






















---
function Animation:start()
    return false
end


---
function Animation:stop()
    return false
end


---
function Animation:reset()
end


---
function Animation:setFillType(fillTypeIndex)
end


---
function Animation:isDuplicate(otherAnimation)
    return false
end


---
function Animation:addDuplicate(otherAnimation)
    table.insert(self.duplicates, otherAnimation)
end


---
function Animation:updateDuplicates()
    for i=1, #self.duplicates do
        self:updateDuplicate(self.duplicates[i])
    end
end


---
function Animation:updateDuplicate(otherAnimation)
end


---
function Animation.calculateTurnOffFadeTime(currentSpeedFactor, currentSpeed, direction, position, targetPosition, originalFadeOut, wrapPosition, subDivisions)
    wrapPosition = wrapPosition / subDivisions

    -- calculate final position after turn off (ms precision)
    local finalPos = position
    local speedChangePerMS = (1 / originalFadeOut)
    for i=1, originalFadeOut do
        currentSpeedFactor = math.max(currentSpeedFactor - speedChangePerMS, 0)
        finalPos = finalPos + (currentSpeed * currentSpeedFactor)
    end

    if math.abs(position - finalPos) < 0.00001 then
        return 1 -- 1ms as we are already at the target position
    end

    -- get next target position in range
    local int, fraction = math.modf((finalPos - targetPosition) / wrapPosition)
    local targetRad = int * wrapPosition + targetPosition
    if (direction > 0 and math.abs(fraction) > 0.2)
    or (direction < 0 and math.abs(fraction) < 0.2)
    or math.abs(targetRad - position) < wrapPosition * 0.5 then
        int = int + direction
    end

    -- adjust fade off time to hit target
    local targetPos = int * wrapPosition + targetPosition
    return (position - targetPos) / (position - finalPos) * originalFadeOut
end
