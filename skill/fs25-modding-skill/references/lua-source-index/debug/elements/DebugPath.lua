









---
local DebugPath_mt = Class(DebugPath, DebugElement)


---
-- @param table? customMt
-- @return DebugPath self
function DebugPath.new(customMt)
    local self = DebugPath:superClass().new(customMt or DebugPath_mt)

    self.points = {}
    self.alignToGround = false
    self.minimumDistanceBetweenPoints = nil
    self.solid = true

    -- TODO: add option to reduce number of rendered points (after addition/without removing points) e.g. only render every other one

    return self
end






















---dedicated function used by DebugManger to determine if draw() should be called or not
-- @return boolean shouldBeDrawn
function DebugPath:getShouldBeDrawn()
    -- implements custom clipping itself
    return true
end


---
function DebugPath:draw()
    DebugPath.renderPath(self.points, self.color, self.alignToGround, self.forcedY, self.solid, self.clipDistance, self.text)
end































































































---Remove all points of the path
-- @return DebugPath self
function DebugPath:clear()
    self.points = {}

    return self
end


---
-- @param float forcedY set a fix world y height for drawing the path, use nil to unset
-- @return DebugPath self
function DebugPath:setForcedY(forcedY)

--#debug     Assert.isType(forcedY, "number")

    self.forcedY = forcedY

    return self
end
