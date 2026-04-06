









---
local DebugShapeOutline_mt = Class(DebugShapeOutline, DebugElement)













---draw
function DebugShapeOutline:draw()
    DebugShapeOutline.render(
        self.node,
        self.recursive
    )
end
