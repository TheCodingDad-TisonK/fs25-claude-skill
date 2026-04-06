









---
local DebugLine_mt = Class(DebugLine, DebugElement)


---new
-- @param table? customMt
-- @return DebugLine self
function DebugLine.new(customMt)
    local self = DebugLine:superClass().new(customMt or DebugLine_mt)

    self.solid = false
    self.colorStart = nil
    self.colorEnd = nil
    self.alignToGround = false

    self.nodeStart = nil
    self.nodeEnd = nil

    return self
end


---
function DebugLine:draw()
    if self.nodeStart ~= nil and self.nodeEnd ~= nil then
        if entityExists(self.nodeStart) and entityExists(self.nodeEnd) then
            self.xStart, self.yStart, self.zStart = getWorldTranslation(self.nodeStart)
            self.xEnd, self.yEnd, self.zEnd = getWorldTranslation(self.nodeEnd)
        end
    end

    DebugLine.renderBetweenPositions(self.xStart, self.yStart, self.zStart, self.xEnd, self.yEnd, self.zEnd, self.color, self.solid, self.text, self.textSize, self.colorStart, self.colorEnd, self.clipDistance, self.textClipDistance)
end
