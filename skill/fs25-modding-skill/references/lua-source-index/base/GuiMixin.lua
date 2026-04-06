












---GuiElement mixin base class.
-- Implements base functionality for GUI element mixins. All other GUI mixins should be descendants of this class.
local GuiMixin_mt = Class(GuiMixin)


---Create a new GuiMixin instance.
-- Subclasses need to provide their class type table for identification.
-- @param class Class metatable
-- @param mixinType Class type table
-- @return New instance
function GuiMixin.new(class, mixinType)
    if class == nil then
        class = GuiMixin_mt
    end

    if mixinType == nil then
        mixinType = GuiMixin
    end

    local self = setmetatable({}, class)
    self.mixinType = mixinType

    return self
end


---Add a mixin to a GuiElement.
-- Adds mixin methods to the element which can then be used. A mixin's state is located in "element[mixinType]".
function GuiMixin:addTo(guiElement)
    if not guiElement[self.mixinType] then
        guiElement[self.mixinType] = self
        guiElement.hasIncluded = self.hasIncluded

        return true
    else
        return false
    end
end


---Determine if a GuiElement has a mixin type included.
-- @param guiElement GuiElement instance
-- @param mixinType GuiMixin class reference
function GuiMixin.hasIncluded(guiElement, mixinType)
    return guiElement[mixinType] ~= nil
end


---Clone mixin states for a mixin type from a source to a destination GuiElement instance.
function GuiMixin.cloneMixin(mixinType, srcGuiElement, dstGuiElement)
    mixinType:clone(srcGuiElement, dstGuiElement)
end


---Clone this mixin's state from a source to a destination GuiElement instance.
function GuiMixin:clone(srcGuiElement, dstGuiElement)
    -- implement in subclasses to copy mixin state between decorated GuiElement instances
end
