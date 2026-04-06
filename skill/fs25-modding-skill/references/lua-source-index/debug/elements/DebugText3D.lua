









---
local DebugText3D_mt = Class(DebugText3D, DebugElement)


---Create new instance of a DebugText3D
-- @param table? customMt
-- @return DebugText3D self instance
function DebugText3D.new(customMt)
    local self = DebugText3D:superClass().new(customMt or DebugText3D_mt)

    self.alignment = RenderText.ALIGN_CENTER
    self.verticalAlignment = RenderText.VERTICAL_ALIGN_MIDDLE
    self.size = 0.1

    return self
end


---
function DebugText3D:draw()
    DebugText3D.renderAtPosition(self.x, self.y, self.z, self.rx, self.ry, self.rz, self.text, self.color, self.size, self.alignment, self.verticalAlignment)
end


---renderAtPosition, use nil for y to enable terrain alignment
-- @param float x
-- @param float y
-- @param float z
-- @param float rx
-- @param float ry
-- @param float rz
-- @param string text
-- @param table? color Color instance
-- @param float? size (optional)
-- @param integer? alignment (optional) RenderText.ALIGN_*
-- @param integer? verticalAlignment (optional) RenderText.VERTICAL_ALIGN_*
function DebugText3D.renderAtPosition(x, y, z, rx, ry, rz, text, color, size, alignment, verticalAlignment)
    setTextAlignment(alignment or RenderText.ALIGN_CENTER)
    setTextVerticalAlignment(verticalAlignment or RenderText.VERTICAL_ALIGN_BASELINE)
    setTextBold(false)

    setTextColor((color or Color.PRESETS.WHITE):unpack())
    renderText3D(x, y, z, rx, ry, rz, size, text)

    -- reset
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
end


---renderAtNode
-- @param entityId node
-- @param string text
-- @param table? color Color instance
-- @param float? size (optional)
-- @param integer? alignment (optional) RenderText.ALIGN_*
-- @param integer? verticalAlignment (optional) RenderText.VERTICAL_ALIGN_*
function DebugText3D.renderAtNode(node, text, color, size, alignment, verticalAlignment)
    local x, y, z = getWorldTranslation(node)
    local rx, ry, rz = getWorldRotation(node)
    DebugText3D.renderAtPosition(x, y, z, rx, ry, rz, text, color, size, alignment, verticalAlignment)
end
