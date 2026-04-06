









---base class for all Debug* classes
local DebugElement_mt = Class(DebugElement)


---Create new instance of a DebugElement
-- @param table? customMt
-- @return table self instance
function DebugElement.new(customMt)
    local self = setmetatable({}, customMt or DebugElement_mt)

    self.x, self.y, self.z = 0, 0, 0
    self.color = Color.new(1,1,1,1)
    self.text = nil
    self.textSize = nil
    self.textColor = nil
    self.textClipDistance = nil
    self.isVisible = true
    self.clipDistance = nil
    self.hideWhenGuiIsOpen = true

    return self
end




















---dedicated function used by DebugManger to determine if draw() should be called or not
-- @return boolean shouldBeDrawn
function DebugElement:getShouldBeDrawn()
    if not self.isVisible then
        return
    end

    if self.hideWhenGuiIsOpen and g_gui ~= nil and g_gui:getIsGuiVisible() and g_gui.currentGuiName ~= "ConstructionScreen" then
        return false
    end

    if self.clipDistance ~= nil then
        local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
        if MathUtil.vector3Length(x-self.x, y-self.y, z-self.z) > self.clipDistance then
            return false
        end
    end

    return true
end


---
function DebugElement:draw()
end



---
-- @param string? groupId arbitrary string to group debug elements into, used for visiblity toggle and removal of multiple elements (optional)
-- @param float? lifetime lifetime of the debug object in ms before being automatically removed (optional)
-- @param integer? maxCount maximum number of debug elements for the group, oldest element will be removed if limit is reached (optional)
-- @return DebugElement self
function DebugElement:addToManager(groupId, lifetime, maxCount)
    g_debugManager:addElement(self, groupId, lifetime, maxCount)

    return self
end


---Set color using r,g,b,(a)
-- @param float r 0 to 1
-- @param float g 0 to 1
-- @param float b 0 to 1
-- @param float? a 0 to 1
-- @return DebugElement self
function DebugElement:setColorRGBA(r, g, b, a)

--#debug     Assert.isNilOrType(r, "number")
--#debug     Assert.isNilOrType(g, "number")
--#debug     Assert.isNilOrType(b, "number")
--#debug     Assert.isNilOrType(a, "number")

    self.color = Color.new(r,g,b,a)
    return self
end


































































---setIsVisible
-- @param boolean isVisible
-- @return DebugElement self
function DebugElement:setIsVisible(isVisible)

--#debug     Assert.isType(isVisible, "boolean")

    self.isVisible = isVisible

    return self
end


---setVisbileWhenGUIOpen
-- @param boolean isVisible
-- @return DebugElement self
function DebugElement:setVisbileWhenGUIOpen(isVisible)

--#debug     Assert.isType(isVisible, "boolean")

    self.hideWhenGuiIsOpen = not isVisible

    return self
end


---setClipDistance
-- @param float? clipDistance
-- @return DebugElement self
function DebugElement:setClipDistance(clipDistance)

--#debug     Assert.isNilOrType(clipDistance, "number")

    self.clipDistance = clipDistance

    return self
end
