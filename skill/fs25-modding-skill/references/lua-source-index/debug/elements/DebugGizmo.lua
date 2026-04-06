










---
local DebugGizmo_mt = Class(DebugGizmo, DebugElement)




































---dedicated function used by DebugManger to determine if draw() should be called or not
-- @return boolean shouldBeDrawn
function DebugGizmo:getShouldBeDrawn()
    if self.hideWhenGuiIsOpen and g_gui:getIsGuiVisible() then
        return false
    end

    if self.clipDistance and not DebugUtil.isPositionInCameraRange(self.x, self.y, self.z, self.clipDistance) then
        return false
    end

    return true
end


---
function DebugGizmo:draw()
    DebugGizmo.renderAtPosition(self.x,self.y,self.z, self.dirX,self.dirY,self.dirZ, self.upX,self.upY,self.upZ, self.text, self.solid, self.scale, self.textSize, self.textColor, self.textOffsets)
end
