









---Base class for frame elements for the in-game menu.
local TabbedMenuFrameElement_mt = Class(TabbedMenuFrameElement, FrameElement)




---Create a new TabbedMenuFrameElement instance.
function TabbedMenuFrameElement.new(target, customMt)
    local self = FrameElement.new(target, customMt or TabbedMenuFrameElement_mt)

    self.hasCustomMenuButtons = false
    self.menuButtonInfo = {}
    self.menuButtonsDirty = false
    self.title = nil
    self.tabbingMenuVisibleDirty = false
    self.tabbingMenuVisible = true
    self.currentPage = 1

    self:setNumberOfPages(1)

    self.requestCloseCallback = NO_CALLBACK -- close request accepted callback

    return self
end


---Late initialization of a menu frame.
-- Override in sub-classes.
function TabbedMenuFrameElement:initialize(...)
end


---Check if this menu frame requires menu button customization.
function TabbedMenuFrameElement:getHasCustomMenuButtons()
    return self.hasCustomMenuButtons
end


---Get custom menu button information.
-- @return table Array of button info as {i={inputAction=<action name>, text=<optional display text>, callback=<optional callback>}}
function TabbedMenuFrameElement:getMenuButtonInfo()
    return self.menuButtonInfo
end


---Set custom menu button information.
-- @param table? menuButtonInfo Array of button info as {i={inputAction=<action name>, text=<optional display text>, callback=<optional callback>}} or nil to reset.
function TabbedMenuFrameElement:setMenuButtonInfo(menuButtonInfo)
    self.menuButtonInfo = menuButtonInfo
    self.hasCustomMenuButtons = menuButtonInfo ~= nil
end


---Set the menu button info dirty flag which causes the menu to update the buttons from this element's information.
function TabbedMenuFrameElement:setMenuButtonInfoDirty()
    self.menuButtonsDirty = true
end


---Get the menu button info dirty state (has changed).
function TabbedMenuFrameElement:isMenuButtonInfoDirty()
    return self.menuButtonsDirty
end


---Clear menu button dirty flag.
function TabbedMenuFrameElement:clearMenuButtonInfoDirty()
    self.menuButtonsDirty = false
end


---Get the frame's main content element's screen size.
function TabbedMenuFrameElement:getMainElementSize()
    return {1, 1}
end


---Get the frame's main content element's screen position.
function TabbedMenuFrameElement:getMainElementPosition()
    return {0, 0}
end


---Request to close the frame.
-- Frames can contain logic (e.g. saving pending changes) which should be handled before closing. Use this method in
-- sub-classes request closing the frame so it can wrap up first. If a callback is provided and the initial request
-- could not close the frame, the callback will be called as soon as the frame can be closed.
function TabbedMenuFrameElement:requestClose(callback)
    self.requestCloseCallback = callback or NO_CALLBACK
    return true
end


---Called when this frame is opened by its container.
function TabbedMenuFrameElement:onFrameOpen()
    TabbedMenuFrameElement:superClass().onOpen(self)

    self:updatePagingButtons()
end


---Called when this frame is closed by its container.
function TabbedMenuFrameElement:onFrameClose()
    TabbedMenuFrameElement:superClass().onClose(self)
end




---Set a new title for the frame
function TabbedMenuFrameElement:setTitle(title)
    self.title = title
    if self.pagingTitle ~= nil then
        self.pagingTitle:setText(title)
    end
end
