










---A tabbed menu with support for detail pages for a hierarchy
-- 
-- Please note that this is a hack to make such a system work with the rest of the
-- UI system. Instead, the UI system should be hierarchycal top-down to begin with
-- automatically supporting something like this (by view controllers in tab controller)
-- 
-- TODO: A bug exists regarding pageIndex/pageMappingIndex.
-- When there is an invisible page between the tabs (pageIndex does not match pageMappingIndex),
-- and a player switches from a tab with detail open with Q to the tab that is not ordered 'right',
-- it does nothing and the tab is hidden. To 'fix': reorder tabs in xml if possible
local TabbedMenuWithDetails_mt = Class(TabbedMenuWithDetails, TabbedMenu)


---
function TabbedMenuWithDetails.new(target, custom_mt)
    local self = TabbedMenu.new(target, custom_mt or TabbedMenuWithDetails_mt)

    self.stacks = {}

    return self
end


---
function TabbedMenuWithDetails:reset()
    TabbedMenuWithDetails:superClass().reset(self)

    self.stacks = {}
end


---
function TabbedMenuWithDetails:getIsDetailMode()
    return not self:isAtRoot()
end


---Exit the menu if allowed.
function TabbedMenuWithDetails:exitMenu()
    -- Make sure that detail mode is off
    self:popToRoot()

    TabbedMenuWithDetails:superClass().exitMenu(self)
end


---
function TabbedMenuWithDetails:onOpen(element)
    -- HACK: Skip over any code in TabbedMenu. It causes a double blur context and too many sounds
    -- We still want its super class to be called
    TabbedMenu:superClass().onOpen(self)

    if self.performBackgroundBlur then
        g_depthOfFieldManager:pushArea(0, 0, 1, 1)
        -- popped by non-overwritten onClose
    end

    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)

    if self.gameState ~= nil then
        g_gameStateManager:setGameState(self.gameState)
    end

    -- Disable all focus sounds. We play our own for opening the menu
    self:setSoundSuppressed(true)

    self.currentPage = self.currentPage or self.restorePage
    local top = self:getTopFrame() -- also creates stack

    if self:isAtRoot() then
        self:updatePages()
        self.pageSelector:setState(self.restorePageIndex, true)
    else
        top:onFrameOpen()
        self:updateButtonsPanel(top)
    end

    self:setSoundSuppressed(false)

    self:onMenuOpened()
end


---Override action that happens when a paging tab is clicked
function TabbedMenuWithDetails:onPageClicked(oldPage)
    self:popToRoot()
end


---Abstract function called when a detail closed
function TabbedMenuWithDetails:onDetailClosed(detailPage)
end


---Abstract function called when a detail opened
function TabbedMenuWithDetails:onDetailOpened(detailPage)
end


---Button function for backing out of the menu.
function TabbedMenuWithDetails:onButtonBack()
    if self:isAtRoot() then
        self:exitMenu()
    else
        self:popDetail()
    end
end


---Callback form PagingElement
function TabbedMenuWithDetails:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
    -- If the new page is a detail page, then do not update
    if self.isChangingDetail then
        skipTabVisualUpdate = true
    else
        self:popToRoot()
    end

    TabbedMenuWithDetails:superClass().onPageChange(self, pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
end






---Get the frame stack of the current tab
function TabbedMenuWithDetails:getStack(page)
    local pageId = self.currentPageId or self.restorePageIndex
    if page ~= nil then
        pageId = self.pagingElement:getPageIndexByElement(page)
    else
        page = self.pagingElement:getPageElementByIndex(pageId)
    end

    if self.stacks[pageId] == nil then
        self.stacks[pageId] = {}

        local root = {
            page = page,
            pageId = pageId,
            isRoot = true,
        }

        table.insert(self.stacks[pageId], root)
    end

    return self.stacks[pageId]
end


---Get whether the current tab is showing its root page
function TabbedMenuWithDetails:isAtRoot()
    return #self:getStack() == 1
end


---Get the current top frame (page)
function TabbedMenuWithDetails:getTopFrame()
    local stack = self:getStack()
    return stack[#stack].page
end


---
function TabbedMenuWithDetails:setPageDisabled(page, disabled)
    local pageId = self.pagingElement:getPageIdByElement(page)
    self.pagingElement:setPageIdDisabled(pageId, disabled)
end


---Add a new detail and show it.
-- We push the detail onto the context stack, and update the visible frame
function TabbedMenuWithDetails:pushDetail(detailPage)
    local stack = self:getStack()

    self.isChangingDetail = true

    -- If already a detail visible, hide it first
    if not self:isAtRoot() then
        local closingPage = stack[#stack].page

        -- Disable details page
        detailPage:setVisible(false)
        detailPage:onFrameClose()

        self:setPageDisabled(detailPage, true)

        self:onDetailClosed(closingPage)
    end

    local context = {
        page = detailPage
    }
    table.insert(stack, context)

    self:setPageDisabled(detailPage, false)

    detailPage:setSoundSuppressed(true) -- avoid playing sound on page focus-triggered selection when opening
    self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(detailPage))
    detailPage:setSoundSuppressed(false)

    self:onDetailOpened(detailPage)

    self.isChangingDetail = false
end


---Remove current detail and go back to the previous one (or root)
-- We remove the detail onto the context stack, and update the visible frame.
function TabbedMenuWithDetails:popDetail()
    local stack = self:getStack()

    self.isChangingDetail = true

    if #stack == 1 then
        Logging.error("Cannot pop from view stack at root")
        return
    end

    local closingPage = stack[#stack].page
    table.remove(stack)

    -- Disable the popped page
    closingPage:setVisible(false)
    closingPage:onFrameClose()

    self.pagingElement.neuterPageUpdates = true
    self:setPageDisabled(closingPage, true)

    self:onDetailClosed(closingPage)
    self.pagingElement.neuterPageUpdates = false

    -- If not at root, show detail again
    if #stack ~= 1 then
        local detailPage = stack[#stack].page

        detailPage:onFrameOpen()

        self:setPageDisabled(detailPage, false)

        detailPage:setSoundSuppressed(true) -- avoid playing sound on page focus-triggered selection when opening
        self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(detailPage))
        detailPage:setSoundSuppressed(false)

        self:onDetailOpened(detailPage)
    else
        -- Set page
        self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(stack[1].page))
    end

    self.isChangingDetail = false
end


---Pop everything from the stack until only the root is kept. Used for resetting the hierarchy with clicking a tab
function TabbedMenuWithDetails:popToRoot()
    local stack = self:getStack()

    -- TODO: optimize. Can close all without opening them too (just close, remove all, open)
    if #stack > 1 then
        for _ = #stack, 2, -1 do
            self:popDetail()
        end
    end
end


---Replace current detail with the given. This is useful for keeping the back button behaviour
function TabbedMenuWithDetails:replaceDetail(detailPage)
    -- TODO optimize

    -- close
    -- remove
    -- add
    -- open

    self:popDetail()
    self:pushDetail(detailPage)
end






---Get a list of breadcrumbs for the current page
function TabbedMenuWithDetails:getBreadcrumbs(page)
    local list = {}

    for _, item in ipairs(self:getStack(page)) do
        table.insert(list, item.page.title or "")
    end

    return list
end
