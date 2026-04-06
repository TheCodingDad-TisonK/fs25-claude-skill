









---
local DebugCylinder_mt = Class(DebugCylinder, DebugElement)























---
function DebugCylinder:draw()
    DebugCylinder.renderAtPosition(
        self.x, self.y, self.z,
        self.radius,
        self.height,
        self.axis,
        self.color,
        self.numSegments,
        self.solid,
        self.alignToGround,
        self.text
    )
end
