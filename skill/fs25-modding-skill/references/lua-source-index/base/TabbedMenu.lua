








---
local TabbedMenu_mt = Class(TabbedMenu, ScreenElement)





























---
function TabbedMenu.new(target, custom_mt)
    local self = ScreenElement.new(target, custom_mt or TabbedMenu_mt)

    self.pageFrames = {} -- FrameElement instances array in order of display
    self.pageTabs = {} -- Page tabs in the header, {FrameElement -> ListItemElement}
    self.pageTypeControllers = {} -- Mapping of page FrameElement sub-classes to the controller instances
    self.pageRoots = {} -- Mapping of page controller instances to their original root GuiElements
    self.pageEnablingPredicates = {} -- Mapping of page controller instances to enabling predicate functions (if return true -> enable)
    self.disabledPages = {} -- hash of disabled paging controllers to avoid re-activation in updatePages()
    self.enabledPages = {} -- mapping from index of a page in all enabled pages to its index in pageTabs

    self.currentPageId = 1
    self.currentPageListIndex = 1
    self.currentPage = nil -- current page controller reference

    self.restorePageIndex = 1 -- memorized menu page mapping index (initialize on index 1 for the map overview)
    self.restorePageScrollOffset = 0

    self.buttonActionCallbacks = {} -- InputAction name -> function
    self.defaultButtonActionCallbacks = {} -- InputAction name -> function
    self.defaultMenuButtonInfoByActions = {}
    self.customButtonEvents = {} -- array of event IDs from InputBinding

    self.clickBackCallback = NO_CALLBACK

    self.frameClosePageNextCallback = self:makeSelfCallback(self.onPageNext)
    self.frameClosePagePreviousCallback = self:makeSelfCallback(self.onPagePrevious)

    -- Subclass configuration
    self.performBackgroundBlur = false

    return self
end


---
function TabbedMenu:delete()
    g_messageCenter:unsubscribeAll(self)

    TabbedMenu:superClass().delete(self)
end


---
function TabbedMenu:onGuiSetupFinished()
    TabbedMenu:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

    self:setupMenuButtonInfo()

    if self.pagingElement.profile == "uiInGameMenuPaging" then
        self.pagingElement:setSize(1 - self.header.absSize[1])
    end
end


---
function TabbedMenu:exitMenu()
    self:changeScreen(nil)
end


---
function TabbedMenu:reset()
    TabbedMenu:superClass().reset(self)

    self.currentPageId = 1
    self.currentPage = nil

    self.restorePageIndex = 1
    self.restorePageScrollOffset = 0
end


---Handle in-game menu opening event.
function TabbedMenu:onOpen(element)
    TabbedMenu:superClass().onOpen(self)

    if self.performBackgroundBlur then
        g_depthOfFieldManager:pushArea(0, 0, 1, 1)
    end

    if not self.muteSound then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
    end

    if self.gameState ~= nil then
        g_gameStateManager:setGameState(self.gameState)
    end

    -- Disable all focus sounds. We play our own for opening the menu
    self:setSoundSuppressed(true)

    -- setup menus
    self:updatePages()

    -- restore last selected page
    if self.restorePageIndex ~= nil then
        self.currentPage = self.restorePage
        self.pageSelector:setState(self.restorePageIndex, true)
        self.pagingTabList:scrollTo(self.restorePageScrollOffset)
    end

    self:setSoundSuppressed(false)

    self:onMenuOpened()
end


---Handle in-game menu closing event.
function TabbedMenu:onClose(element)
    if self.currentPage ~= nil then
        self.currentPage:onFrameClose() -- the current page gets its specific close event first
    end

    TabbedMenu:superClass().onClose(self)

    if self.performBackgroundBlur then
        g_depthOfFieldManager:popArea()
    end

    g_inputBinding:storeEventBindings() -- reset any disabled bindings for page custom input in menu context
    self:clearMenuButtonActions()

    self.restorePage = self.currentPage
    self.restorePageIndex = self.pageSelector:getState()
    self.restorePageScrollOffset = self.pagingTabList.viewOffset

    self.currentPage = nil
    self.currentPageId = nil

    if self.gameState ~= nil then
        g_currentMission:resetGameState()
    end
end


---Update the menu state each frame.
-- This uses a state machine approach for the game saving process.
function TabbedMenu:update(dt)
    TabbedMenu:superClass().update(self, dt)

    -- Enforce the current page as the focus context. This is required because dialogs on dialogs (e.g. during saving)
    -- can break reverting to a valid focus state in this menu.
    if self.currentPage ~= nil and FocusManager.currentGui ~= self.currentPage.name and not g_gui:getIsDialogVisible() then
        FocusManager:setGui(self.currentPage.name)
    end

    if self.currentPage ~= nil then
        --currentListener check is needed in case a dialog is opened, in which case these button actions would be registered for the dialog
        local listenerName = g_gui.currentListener ~= nil and g_gui.currentListener.name or nil
        if self.currentPage:isMenuButtonInfoDirty() and listenerName == self.name then
            self:assignMenuButtonInfo(self.currentPage:getMenuButtonInfo())
            self.currentPage:clearMenuButtonInfoDirty()
        end
        if self.currentPage:isTabbingMenuVisibleDirty() then
            self:updatePagingVisibility(self.currentPage:getTabbingMenuVisible())
        end
    end
end






---Setup the menu buttons. Override to initialize
function TabbedMenu:setupMenuButtonInfo()
end


---Add a page tab in the menu header.
-- Call this synchronously with TabbedMenu:registerPage() to ensure a correct order of pages and tabs.
function TabbedMenu:addPageTab(frameController, iconFilename, iconUVs, iconSliceId, soundId)
    local tab = {}
    self.pageTabs[frameController] = tab

    tab.iconFilename = iconFilename
    tab.iconUVs = iconUVs
    tab.iconSliceId = iconSliceId
    tab.soundId = soundId

    tab.onClickCallback = function()
        self:onPageClicked(self.activeDetailPage)

        local pageId = self.pagingElement:getPageIdByElement(frameController)
        local pageMappingIndex = self.pagingElement:getPageMappingIndex(pageId)

        if self.currentPage:requestClose(tab.onClickCallback) then
            self.pageSelector:setState(pageMappingIndex, true) -- set state with force event
        end
    end
end


---
function TabbedMenu:onPageClicked(oldPage)
end


---Set enabled state of a page tab in the header.
function TabbedMenu:setPageTabEnabled(pageController, isEnabled, blockListReload)
    self.pageTabs[pageController].isDisabled = not isEnabled

    if not blockListReload then
        self.pagingTabList:reloadData()
    end
end


---Rebuild page tab list in order.
function TabbedMenu:rebuildTabList()
    self.enabledPages = {}

    for i, page in ipairs(self.pageFrames) do
        local pageId = self.pagingElement:getPageIdByElement(page)
        local enabled = not self.pagingElement:getIsPageDisabled(pageId)

        -- Add any enabled item. List will scroll for us to keep selection in view
        if enabled then
            table.insert(self.enabledPages, page)
        end
    end

    self.pagingTabList:reloadData()

    self.pagingTabList:setSelectedIndex(self.currentPageListIndex)
end























---Update page enabled states.
function TabbedMenu:updatePages()
    for pageElement, predicate in pairs(self.pageEnablingPredicates) do
        local pageId = self.pagingElement:getPageIdByElement(pageElement)
        local enable = self.disabledPages[pageElement] == nil and predicate()

        self.pagingElement.neuterPageUpdates = true
        self.pagingElement:setPageIdDisabled(pageId, not enable)
        self.pagingElement.neuterPageUpdates = false

        self:setPageTabEnabled(pageElement, enable, true)
    end

    self:rebuildTabList()
    self:setPageSelectorTitles()
end


---Clear menu button actions, events and callbacks.
function TabbedMenu:clearMenuButtonActions()
    for k in pairs(self.buttonActionCallbacks) do
        self.buttonActionCallbacks[k] = nil
    end

    for i in ipairs(self.customButtonEvents) do
        g_inputBinding:removeActionEvent(self.customButtonEvents[i])
        self.customButtonEvents[i] = nil
    end
end


---Assign menu button information to the in-game menu buttons.
function TabbedMenu:assignMenuButtonInfo(menuButtonInfo)
    self:clearMenuButtonActions()

    for i, button in ipairs(self.menuButton) do
        local info = menuButtonInfo[i]
        local hasInfo = info ~= nil
        button:setVisible(hasInfo)

        -- Do not show actions when the game is paused unless specified
        if hasInfo and info.inputAction ~= nil and InputAction[info.inputAction] ~= nil then
            button:setInputAction(info.inputAction)

            if Platform.isMobile then
                if info.profile ~= nil then
                    button:applyProfile(info.profile)
                else
                    button:applyProfile("buttonBack")
                end
            end

            local buttonText = info.text
            if buttonText == nil and self.defaultMenuButtonInfoByActions[info.inputAction] ~= nil then
                buttonText = self.defaultMenuButtonInfoByActions[info.inputAction].text
            end
            button:setText(buttonText)

            local buttonClickCallback = info.callback or self.defaultButtonActionCallbacks[info.inputAction] or NO_CALLBACK

            local sound = GuiSoundPlayer.SOUND_SAMPLES.CLICK
            if info.inputAction == InputAction.MENU_BACK then
                sound = GuiSoundPlayer.SOUND_SAMPLES.BACK
            end

            if info.clickSound ~= nil and info.clickSound ~= sound then
                sound = info.clickSound

                -- We need to activate the sound by hand so that it is also played for gamepad and keyboard input
                -- as those are not triggered by the button
                local oldButtonClickCallback = buttonClickCallback
                buttonClickCallback = function (...)
                    self:playSample(sound)
                    self:setNextScreenClickSoundMuted()

                    return oldButtonClickCallback(...)
                end

                -- Deactivate sound on button to prevent double-sounds
                button:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.NONE)
            else
                button:setClickSound(sound)
            end

            local showForGameState = Platform.isMobile or (not self.paused or info.showWhenPaused)
            local showForCurrentState = showForGameState or TabbedMenu.PAUSE_ACTIONS[info.inputAction] ~= nil

            local disabled = info.disabled or not showForCurrentState
            if not disabled then
                if not TabbedMenu.DEFAULT_BUTTON_ACTIONS[info.inputAction] then
                    local _, eventId = g_inputBinding:registerActionEvent(info.inputAction, nil, buttonClickCallback, false, true, false, true)
                    g_inputBinding:setActionEventTextVisibility(eventId, false)
                    table.insert(self.customButtonEvents, eventId) -- store event ID to remove again on page change
                else
                    self.buttonActionCallbacks[info.inputAction] = buttonClickCallback
                end
            end

            button.onClickCallback = buttonClickCallback
            button:setDisabled(disabled)

            local separator = button:getDescendantByName("separator")
            if separator ~= nil then
                separator:setVisible(i ~= 1)
            end
        end
    end

    -- make sure that menu exit is always possible:
    if self.buttonActionCallbacks[InputAction.MENU_BACK] == nil then
        self.buttonActionCallbacks[InputAction.MENU_BACK] = self.clickBackCallback
    end

    self.buttonsPanel:invalidateLayout()
end


---Get page titles from currently visible pages and apply to the selector element.
function TabbedMenu:setPageSelectorTitles()
    local texts = self.pagingElement:getPageTitles()

    self.pageSelector:setTexts(texts)
    self.pageSelector:setDisabled(#texts == 1)

    -- Update state without triggering any events
    local id = self.pagingElement:getCurrentPageId()
    self.pageSelector.state = self.pagingElement:getPageMappingIndex(id)
end


---
function TabbedMenu:goToPage(page, muteSound)
    local oldMute = self.muteSound
    self.muteSound = muteSound

    local index = self.pagingElement:getPageMappingIndexByElement(page)
    if index ~= nil then
        self.pageSelector:setState(index, true)
    end

    self.muteSound = oldMute
end


---
function TabbedMenu:updatePagingVisibility(visible)
    self.header:setVisible(visible)
end






---Handle a menu action click by calling one of the menu button callbacks.
-- @return boolean True if no callback was present and no action was taken, false otherwise
function TabbedMenu:onMenuActionClick(menuActionName)
    local buttonCallback = self.buttonActionCallbacks[menuActionName]
    if buttonCallback ~= nil and buttonCallback ~= NO_CALLBACK then
        return buttonCallback() or false
    end

    return true
end


---Handle menu confirmation input event.
function TabbedMenu:onClickOk()
    -- do not call the super class event here so we can always handle this event any way we need
    local eventUnused = self:onMenuActionClick(InputAction.MENU_ACCEPT)
    return eventUnused
end


---Handle menu back input event.
function TabbedMenu:onClickBack()
    local eventUnused = true

    if self.currentPage == nil or self.currentPage:requestClose(self.clickBackCallback) then
        eventUnused = TabbedMenu:superClass().onClickBack(self)
        if eventUnused then
            eventUnused = self:onMenuActionClick(InputAction.MENU_BACK)
        end
    end

    return eventUnused
end


---Handle menu cancel input event.
-- Bound to quit the game to the main menu.
function TabbedMenu:onClickCancel()
    local eventUnused = TabbedMenu:superClass().onClickCancel(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_CANCEL)
    end

    return eventUnused
end


---Handle menu activate input event.
-- Bound to save the game.
function TabbedMenu:onClickActivate()
    local eventUnused = TabbedMenu:superClass().onClickActivate(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_ACTIVATE)
    end

    return eventUnused
end


---Handle menu extra 1 input event.
-- Used for various functions when convenient buttons run out.
function TabbedMenu:onClickMenuExtra1()
    local eventUnused = TabbedMenu:superClass().onClickMenuExtra1(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_EXTRA_1)
    end

    return eventUnused
end


---Handle menu extra 2 input event.
-- Used for various functions when convenient buttons run out.
function TabbedMenu:onClickMenuExtra2()
    local eventUnused = TabbedMenu:superClass().onClickMenuExtra2(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_EXTRA_2)
    end

    return eventUnused
end


---Handle activation of page selection.
function TabbedMenu:onClickPageSelection(state)
    -- Mobile uses the header for paging within the frame
    if self.pagingElement:setPage(state) and not self.muteSound then
        local soundId = GuiSoundPlayer.SOUND_SAMPLES.CLICK
        if self.pageTabs[self.currentPage] ~= nil and self.pageTabs[self.currentPage].soundId ~= nil then
            soundId = self.pageTabs[self.currentPage].soundId
        end

        self:playSample(soundId)
    end
end


---Handle previous page event.
function TabbedMenu:onPagePrevious()
    if Platform.isMobile then
        if self.currentPage:getHasPreviousPage() then
            self.currentPage:onPreviousPage()
        end
    else
        if self.currentPage:requestClose(self.frameClosePagePreviousCallback) then
            TabbedMenu:superClass().onPagePrevious(self)
        end
    end
end


---Handle next page event.
function TabbedMenu:onPageNext()
    if Platform.isMobile then
        if self.currentPage:getHasNextPage() then
            self.currentPage:onNextPage()
        end
    else
        if self.currentPage:requestClose(self.frameClosePageNextCallback) then
            TabbedMenu:superClass().onPageNext(self)
        end
    end
end


---Handle changing to another menu page.
function TabbedMenu:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
    if self.currentPage ~= nil then
        self.currentPage:onFrameClose()
        self.currentPage:setVisible(false)
    end

    g_inputBinding:storeEventBindings() -- reset any disabled bindings for page custom input in menu context

    local page = self.pagingElement:getPageElementByIndex(pageIndex)
    self.currentPage = page
    self.currentPageListIndex = pageMappingIndex

    if not skipTabVisualUpdate then
        self.currentPageId = pageIndex
        self.pagingTabList:setSelectedIndex(pageMappingIndex)
    end

    page:setVisible(true)
    page:setSoundSuppressed(true)
    FocusManager:setGui(page.name)
    page:setSoundSuppressed(false)

    self:updateButtonsPanel(page)
    self:updateTabDisplay()

    page:onFrameOpen()
end









---Update the buttons panel when a given page is visible.
function TabbedMenu:updateButtonsPanel(page)
    -- assign button info anyway to make at least MENU_BACK work in all cases:
    local buttonInfo = self:getPageButtonInfo(page)
    self:assignMenuButtonInfo(buttonInfo)

    if page.buttonBox ~= nil then
        page.buttonBox.parent:addElement(page.buttonBox) -- re-add (will remove first, does not copy) buttonBox as last child to draw on top
    end
end




































---Get button actions and display information for a given menu page.
function TabbedMenu:getPageButtonInfo(page)
    local buttonInfo

    if page:getHasCustomMenuButtons() then
        buttonInfo = page:getMenuButtonInfo()
    else
        buttonInfo = self.defaultMenuButtonInfo
    end

    return buttonInfo
end


---Handle a page being disabled.
function TabbedMenu:onPageUpdate()
end


---
function TabbedMenu:onButtonBack()
    self:exitMenu()
end


---Called when opening the menu, after changing the page
function TabbedMenu:onMenuOpened()
end

















---Register a page frame element in the menu.
-- This does not add the page to the paging component of the menu.
-- @param table pageFrameElement Page FrameElement instance
-- @param integer? position [optional] Page position index in menu
-- @param function? enablingPredicateFunction [optional] A function which returns the current enabling state of the page
at any time. If the function returns true, the page should be enabled. If no argument is given, the page is
always enabled.
function TabbedMenu:registerPage(pageFrameElement, position, enablingPredicateFunction)
    if position == nil then
        position = #self.pageFrames + 1
    else
        position = math.max(1, math.min(#self.pageFrames + 1, position))
    end

    table.insert(self.pageFrames, position, pageFrameElement)
    self.pageTypeControllers[pageFrameElement:class()] = pageFrameElement
    local pageRoot = pageFrameElement.elements[1]
    self.pageRoots[pageFrameElement] = pageRoot
    self.pageEnablingPredicates[pageFrameElement] = enablingPredicateFunction

    pageFrameElement:setVisible(false) -- set invisible at the start to allow visibility-based behavior for pages

    return pageRoot, position
end



---Unregister a page frame element identified by class from the menu.
-- This does not remove the page from the paging component of the menu or the corresponding page tab from the header.
-- @param table pageFrameClass FrameElement descendant class of a page which was previously registered
-- @return boolean True if there was a page of the given class and it was unregistered
-- @return table Unregistered page controller instance or nil
-- @return table Unregistered page root GuiElement instance or nil
-- @return table Unregistered page tab ListElement instance of nil
function TabbedMenu:unregisterPage(pageFrameClass)
    local pageController = self.pageTypeControllers[pageFrameClass]
    local pageTab = nil
    local pageRoot = nil
    if pageController ~= nil then
        local pageRemoveIndex = -1
        for i, page in ipairs(self.pageFrames) do
            if page == pageController then
                pageRemoveIndex = i
                break
            end
        end

        table.remove(self.pageFrames, pageRemoveIndex)

        pageRoot = self.pageRoots[pageController]
        self.pageRoots[pageController] = nil
        self.pageTypeControllers[pageFrameClass] = nil
        self.pageEnablingPredicates[pageController] = nil

        self.pageTabs[pageController] = nil
    end

    return pageController ~= nil, pageController, pageRoot, pageTab
end














---Add a page frame to be displayed in the menu at runtime.
-- The page will be part of the in-game menu until restarting the game or removing the page again.
-- 
-- @param table pageFrameElement FrameElement instance which is used as a page.
-- @param integer position Position index of added page, starting from left at 1 going to right.
-- @param string tabIconFilename Path to the texture file which contains the icon for the page tab in the header
-- @param table tabIconUVs UV array for the tab icon. Format: {x, y, width, height} in pixels on the texture.
-- @param function? enablingPredicateFunction [optional] A function which returns the current enabling state of the page
at any time. If the function returns true, the page should be enabled. If no argument is given, the page is
always enabled.
function TabbedMenu:addPage(pageFrameElement, position, tabIconFilename, tabIconUVs, enablingPredicateFunction)
    local pageRoot, actualPosition = self:registerPage(pageFrameElement, position, enablingPredicateFunction)
    self:addPageTab(pageFrameElement, tabIconFilename, GuiUtils.getUVs(tabIconUVs))

    local name = pageRoot.title
    if name == nil then
        name = g_i18n:getText("ui_" .. pageRoot.name)
    end

    self.pagingElement:addPage(string.upper(pageRoot.name), pageRoot, name, actualPosition)
end





---Remove a page from the menu at runtime by its class type.
-- The removed page is also deleted, including all of its children. Note that this method removes the page for an entire
-- game run, because the UI is loaded on game start. If you only need to disable a page, use TabbedMenu:setPageEnabled()
-- instead.
-- 
-- The method will not remove game default pages, but only disable them.
-- 
-- @param table pageFrameClass Class table of a FrameElement sub-class
function TabbedMenu:removePage(pageFrameClass)
    local defaultPage = self.pageTypeControllers[pageFrameClass]
    if self.defaultPageElementIDs[defaultPage] ~= nil then
        self:setPageEnabled(pageFrameClass, false)
    else
        local needDelete, pageController, pageRoot, pageTab = self:unregisterPage(pageFrameClass)
        if needDelete then
            self.pagingElement:removeElement(pageRoot)
            pageRoot:delete()
            pageController:delete()

            self.pagingTabList:removeElement(pageTab)
            pageTab:delete()
        end
    end
end


---Set the enabled state of a page identified by its controller class type.
-- This will also set the controller's state, so it can react to being enabled/disabled. The setting will persist
-- through calls to TabbedMenu:reset() and must be reverted manually, if necessary.
-- @param table pageFrameClass Class table of a FrameElement sub-class
-- @param boolean isEnabled True for enabled, false for disabled
function TabbedMenu:setPageEnabled(pageFrameClass, isEnabled)
    local pageController = self.pageTypeControllers[pageFrameClass]
    if pageController ~= nil then
        local pageId = self.pagingElement:getPageIdByElement(pageController)
        self.pagingElement:setPageIdDisabled(pageId, not isEnabled)

        pageController:setDisabled(not isEnabled)

        if not isEnabled then
            self.disabledPages[pageController] = pageController
        else
            self.disabledPages[pageController] = nil
        end

        self:setPageTabEnabled(pageController, isEnabled)
        self.pagingTabList:updateView()
    end
end


---
function TabbedMenu:makeSelfCallback(func)
    return function(...)
        return func(self, ...)
    end
end
