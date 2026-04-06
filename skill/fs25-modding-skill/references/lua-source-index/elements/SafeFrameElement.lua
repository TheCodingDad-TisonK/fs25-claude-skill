










---Fully opaque black element in the background of certain screens, to prevent showing the game if UI is moved because of defined safe frames
local SafeFrameElement_mt = Class(SafeFrameElement, GuiElement)




---
function SafeFrameElement.new(target, custom_mt)
    local self = GuiElement.new(target, custom_mt or SafeFrameElement_mt)

    self.name = "safeFrame"

    return self
end


---
function SafeFrameElement:draw()
    drawFilledRect(0, 0, 1, 1, 0, 0, 0, 1)
end
