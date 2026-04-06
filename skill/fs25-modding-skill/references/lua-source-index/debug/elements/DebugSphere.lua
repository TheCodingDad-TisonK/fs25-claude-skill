









---
local DebugSphere_mt = Class(DebugSphere, DebugElement)





















---
function DebugSphere:draw()
    DebugSphere.renderAtPosition(
        self.x, self.y, self.z,
        self.radius,
        self.color,
        self.numSegments,
        self.solid,
        self.alignToGround,
        self.text,
        self.textSize
    )
end
