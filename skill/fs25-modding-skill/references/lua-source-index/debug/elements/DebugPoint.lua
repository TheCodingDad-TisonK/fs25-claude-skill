









---
local DebugPoint_mt = Class(DebugPoint, DebugElement)


---new
-- @param table? customMt
-- @return DebugPoint self
function DebugPoint.new(customMt)
    local self = DebugPoint:superClass().new(customMt or DebugPoint_mt)

    self.solid = false

    self.alignToGround = false

    self.text = nil

    return self
end


---
function DebugPoint:draw()
    DebugPoint.renderAtPosition(self.x, self.y, self.z, self.color, self.solid, self.text, self.textSize, self.clipDistance, self.textClipDistance)
end
