









---
local DebugCircle_mt = Class(DebugCircle, DebugElement)


















---draw
function DebugCircle:draw()
    DebugCircle.renderAtPosition(
        self.x, not self.alignToGround and self.y or nil, self.z,
        self.radius,
        self.color,
        self.numSegments,
        self.solid,
        self.filled,
        self.drawSectors,
        self.text
    )
end
