






























---
local SmoothListElement_mt = Class(SmoothListElement, GuiElement)












---Create a new SmoothListElement instance.
-- @param table? target [optional] Target element
-- @param table? custom_mt [optional] Meta table of subclass
-- @return table self the new list instance
function SmoothListElement.new(target, custom_mt)
    local self = SmoothListElement:superClass().new(target, custom_mt or SmoothListElement_mt)
    self:include(IndexChangeSubjectMixin) -- add index change subject mixin for index state observers
    self:include(PlaySampleMixin) -- add sound playing

    self.dataSource = nil
    self.delegate = nil

    self.cellCache = {}
    self.sections = {}

    self.clipping = true
    self.isLoaded = false
    self.updateChildrenState = false

    self.sectionHeaderCellName = nil
    self.isHorizontalList = false
    self.useLateralFilling = false
    self.numLateralItems = 1
    self.listSectionSpacing = 0
    self.listItemSpacing = 0
    self.listItemLateralSpacing = 0
    self.listItemAlignment = SmoothListElement.ALIGN_START
    self.listItemAlignmentOffset = 0

    self.lengthAxis = 2
    self.widthAxis = 1

    self.viewOffset = 0
    self.targetViewOffset = 0
    self.contentSize = 0
    self.totalItemCount = 0
    self.scrollViewOffsetDelta = 0
    self.selectedIndex = 1
    self.selectedSectionIndex = 1

    self.supportsMouseScrolling = true
    self.doubleClickInterval = 400
    self.selectOnClick = false
    self.ignoreMouse = false
    self.showHighlights = false
    self.selectOnScroll = false
    self.itemizedScrollDelta = 0
    self.listSmoothingDisabled = false
    self.listSnappingEnabled = false
    self.selectedWithoutFocus = true -- whether selection is visible even without focus
    self.selectionMarginItems = 0   -- minimum number of items that are shown as a sort of margin before/after the selected item
    self.ignoreFocusActivate = false
    self.fillRowsWithEmptyItems = true
    self.canReceiveFocusWhileEmpty = false
    self.wrapAround = false

    self.lastTouchPosX = nil
    self.lastTouchPosY = nil
    self.usedTouchId = nil
    self.currentTouchDelta = 0
    self.scrollSpeed = 0
    self.initialScrollSpeed = 0
    if self.isHorizontalList then
        self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeX
    else
        self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeY
    end
    self.supportsTouchScrolling = false
    self.lastScrollDirection = 0

    self.emptyIndicatorElement = nil
    self.emptyIndicatorElementId = nil

    self.totalTouchMoveDistance = 0
    self.touchMoveDistanceThreshold = 30

    self.gamepadPageStartTime = nil --needed to register this event on gamepad
    self.gamepadPageStartTriggered = false
    self.gamepadPageEndTime = nil
    self.gamepadPageEndTriggered = false

    return self
end


---Loads list parameters from an XML file
-- @param integer xmlFile XML file handle for the file containing list parameters
-- @param string key XML node path to the list parameters
function SmoothListElement:loadFromXML(xmlFile, key)
    SmoothListElement:superClass().loadFromXML(self, xmlFile, key)

    self:addCallback(xmlFile, key.."#onScroll", "onScrollCallback")
    self:addCallback(xmlFile, key.."#onDoubleClick", "onDoubleClickCallback")
    self:addCallback(xmlFile, key.."#onClick", "onClickCallback")
    self:addCallback(xmlFile, key.."#onPressed", "onPressedCallback")

    self.isHorizontalList = Utils.getNoNil(getXMLBool(xmlFile, key.."#isHorizontalList"), self.isHorizontalList)
    self.lengthAxis = self.isHorizontalList and 1 or 2
    self.widthAxis = self.isHorizontalList and 2 or 1

    self.numLateralItems = getXMLInt(xmlFile, key.."#numLateralItems") or self.numLateralItems
    self.listSectionSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key.."#listSectionSpacing"), self.isHorizontalList, self.listSectionSpacing)
    self.listItemSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key.."#listItemSpacing"), self.isHorizontalList, self.listItemSpacing)
    self.listItemLateralSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key.."#listItemLateralSpacing"), not self.isHorizontalList, self.listItemLateralSpacing)
    self.useLateralFilling = Utils.getNoNil(getXMLBool(xmlFile, key.."#useLateralFilling"), self.useLateralFilling)

    local alignment = getXMLString(xmlFile, key.."#listItemAlignment")
    if alignment ~= nil then
        alignment = alignment:lower()
        if alignment == "end" then
            self.listItemAlignment = SmoothListElement.ALIGN_END
        elseif alignment == "middle" then
            self.listItemAlignment = SmoothListElement.ALIGN_MIDDLE
        else
            self.listItemAlignment = SmoothListElement.ALIGN_START
        end
    end

    self.supportsMouseScrolling = Utils.getNoNil(getXMLBool(xmlFile, key.."#supportsMouseScrolling"), self.supportsMouseScrolling)
    self.supportsTouchScrolling = Utils.getNoNil(getXMLBool(xmlFile, key.."#supportsTouchScrolling"), self.supportsTouchScrolling)
    self.doubleClickInterval = getXMLInt(xmlFile, key.."#doubleClickInterval") or self.doubleClickInterval
    self.selectOnClick = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectOnClick"), self.selectOnClick)
    self.ignoreMouse = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreMouse"), self.ignoreMouse)
    self.showHighlights = Utils.getNoNil(getXMLBool(xmlFile, key .. "#showHighlights"), self.showHighlights)
    self.selectOnScroll = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectOnScroll"), self.selectOnScroll)
    self.itemizedScrollDelta = getXMLInt(xmlFile, key .. "#itemizedScrollDelta") or self.itemizedScrollDelta
    self.listSmoothingDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#listSmoothingDisabled"), self.listSmoothingDisabled)
    self.selectedWithoutFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectedWithoutFocus"), self.selectedWithoutFocus)
    self.selectionMarginItems = getXMLInt(xmlFile, key .. "#selectionMarginItems") or self.selectionMarginItems
    self.listSnappingEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#listSnappingEnabled"), self.listSnappingEnabled)
    self.ignoreFocusActivate = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreFocusActivate"), self.ignoreFocusActivate)
    self.fillRowsWithEmptyItems = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fillRowsWithEmptyItems"), self.fillRowsWithEmptyItems)
    self.canReceiveFocusWhileEmpty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canReceiveFocusWhileEmpty"), self.canReceiveFocusWhileEmpty)
    self.wrapAround = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrapAround"), self.wrapAround)

    self.emptyIndicatorElementId = getXMLString(xmlFile, key .. "#emptyIndicatorId") or self.emptyIndicatorElementId

    local delegateName = getXMLString(xmlFile, key .. "#listDelegate")
    if delegateName == nil or delegateName == "self" then
        self.delegate = self.target
    elseif delegateName ~= "nil" then
        self.delegate = self.target[delegateName]
    end

    local dataSourceName = getXMLString(xmlFile, key .. "#listDataSource")
    if dataSourceName == nil or dataSourceName == "self" then
        self.dataSource = self.target
    elseif delegateName ~= "nil" then
        self.dataSource = self.target[dataSourceName]
    end

    self.sectionHeaderCellName = getXMLString(xmlFile, key .. "#listSectionHeader")
    self.startClipperElementName = getXMLString(xmlFile, key.."#startClipperElementName")
    self.endClipperElementName = getXMLString(xmlFile, key.."#endClipperElementName")
end


---Loads list parameters from a gui profile
-- @param table profile Profile containing list parameters
function SmoothListElement:loadProfile(profile, applyProfile)
    SmoothListElement:superClass().loadProfile(self, profile, applyProfile)

    self.isHorizontalList = profile:getBool("isHorizontalList", self.isHorizontalList)
    self.lengthAxis = self.isHorizontalList and 1 or 2
    self.widthAxis = self.isHorizontalList and 2 or 1

    self.numLateralItems = profile:getNumber("numLateralItems", self.numLateralItems)
    self.listSectionSpacing = GuiUtils.getNormalizedValue(profile:getValue("listSectionSpacing"), self.isHorizontalList, self.listSectionSpacing)
    self.listItemSpacing = GuiUtils.getNormalizedValue(profile:getValue("listItemSpacing"), self.isHorizontalList, self.listItemSpacing)
    self.listItemLateralSpacing = GuiUtils.getNormalizedValue(profile:getValue("listItemLateralSpacing"), not self.isHorizontalList, self.listItemLateralSpacing)
    self.useLateralFilling = profile:getBool("useLateralFilling", self.useLateralFilling)

    local alignment = profile:getValue("listItemAlignment")
    if alignment ~= nil then
        alignment = alignment:lower()
        if alignment == "end" then
            self.listItemAlignment = SmoothListElement.ALIGN_END
        elseif alignment == "middle" then
            self.listItemAlignment = SmoothListElement.ALIGN_MIDDLE
        else
            self.listItemAlignment = SmoothListElement.ALIGN_START
        end
    end

    self.supportsMouseScrolling = profile:getBool("supportsMouseScrolling", self.supportsMouseScrolling)
    self.doubleClickInterval = profile:getNumber("doubleClickInterval", self.doubleClickInterval)
    self.selectOnClick = profile:getBool("selectOnClick", self.selectOnClick)
    self.ignoreMouse = profile:getBool("ignoreMouse", self.ignoreMouse)
    self.showHighlights = profile:getBool("showHighlights", self.showHighlights)
    self.selectOnScroll = profile:getBool("selectOnScroll", self.selectOnScroll)
    self.itemizedScrollDelta = profile:getNumber("itemizedScrollDelta", self.itemizedScrollDelta)
    self.listSmoothingDisabled = profile:getBool("listSmoothingDisabled", self.listSmoothingDisabled)
    self.selectedWithoutFocus = profile:getBool("selectedWithoutFocus", self.selectedWithoutFocus)
    self.selectionMarginItems = profile:getNumber("selectionMarginItems", self.selectionMarginItems)
    self.supportsTouchScrolling = profile:getBool("supportsTouchScrolling", self.supportsTouchScrolling)
    self.listSnappingEnabled = profile:getBool("listSnappingEnabled", self.listSnappingEnabled)
    self.emptyIndicatorElementId = profile:getValue("emptyIndicatorId", self.emptyIndicatorElementId)
    self.fillRowsWithEmptyItems = profile:getBool("fillRowsWithEmptyItems", self.fillRowsWithEmptyItems)
    self.canReceiveFocusWhileEmpty = profile:getBool("canReceiveFocusWhileEmpty", self.canReceiveFocusWhileEmpty)
    self.wrapAround = profile:getBool("wrapAround", self.wrapAround)
end


---Create a deep copy clone of this SmoothListElement.
-- @param table parent Target parent element of the cloned element
-- @param boolean? includeId [optional, default=false] If true, will also clone ID values
-- @param boolean? suppressOnCreate [optional, default=false] If true, will not trigger the "onCreate" callback
-- @return table Cloned instance of this smooth list
function SmoothListElement:clone(parent, includeId, suppressOnCreate)
    local cloned = SmoothListElement:superClass().clone(self, parent, includeId, suppressOnCreate)

    -- Copy database
    cloned.cellDatabase = {}
    for name, cell in pairs(self.cellDatabase) do
        cloned.cellDatabase[name] = cell:clone(nil, nil, true)
    end

    -- Create empty cache
    for name, _ in pairs(self.cellCache) do
        cloned.cellCache[name] = {}
    end

    return cloned
end


---Copy all attributes from a source SmoothListElement to this SmoothListElement.
-- @param table src Source list that the parameters are copied from
function SmoothListElement:copyAttributes(src)
    SmoothListElement:superClass().copyAttributes(self, src)

    self.dataSource = src.dataSource
    self.delegate = src.delegate

    self.singularCellName = src.singularCellName

    self.sectionHeaderCellName = src.sectionHeaderCellName
    self.startClipperElementName = src.startClipperElementName
    self.endClipperElementName = src.endClipperElementName
    self.emptyIndicatorElementId = src.emptyIndicatorElementId

    self.isHorizontalList = src.isHorizontalList
    self.numLateralItems = src.numLateralItems
    self.listSectionSpacing = src.listSectionSpacing
    self.listItemSpacing = src.listItemSpacing
    self.listItemLateralSpacing = src.listItemLateralSpacing
    self.listItemAlignment = src.listItemAlignment
    self.useLateralFilling = src.useLateralFilling

    self.supportsMouseScrolling = src.supportsMouseScrolling
    self.doubleClickInterval = src.doubleClickInterval
    self.selectOnClick = src.selectOnClick
    self.ignoreMouse = src.ignoreMouse
    self.showHighlights = src.showHighlights
    self.itemizedScrollDelta = src.itemizedScrollDelta
    self.selectOnScroll = src.selectOnScroll
    self.listSmoothingDisabled = src.listSmoothingDisabled
    self.selectedWithoutFocus = src.selectedWithoutFocus
    self.selectionMarginItems = src.selectionMarginItems
    self.listSnappingEnabled = src.listSnappingEnabled
    self.fillRowsWithEmptyItems = src.fillRowsWithEmptyItems
    self.canReceiveFocusWhileEmpty = src.canReceiveFocusWhileEmpty
    self.wrapAround = src.wrapAround

    self.lengthAxis = src.lengthAxis
    self.widthAxis = src.widthAxis

    self.onScrollCallback = src.onScrollCallback
    self.onDoubleClickCallback = src.onDoubleClickCallback
    self.onClickCallback = src.onClickCallback
    self.onPressedCallback = src.onPressedCallback

    self.supportsTouchScrolling = src.supportsTouchScrolling

    self.isLoaded = src.isLoaded

    GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end


---Called on a screen view's root element when all elements in a screen view have been created. The event is propagated to all children, depth-first.
function SmoothListElement:onGuiSetupFinished()
    SmoothListElement:superClass().onGuiSetupFinished(self)

    if self.startClipperElementName ~= nil then
        self.startClipperElement = self.parent:getDescendantByName(self.startClipperElementName)
    end
    if self.endClipperElementName ~= nil then
        self.endClipperElement = self.parent:getDescendantByName(self.endClipperElementName)
    end

    if self.emptyIndicatorElementId ~= nil and self.target ~= nil then
        self.emptyIndicatorElement = self.target:getDescendantById(self.emptyIndicatorElementId)

        if self.emptyIndicatorElement ~= nil then
            self.emptyIndicatorElement:setVisible(true)
        end
    end

    if not self.isLoaded then
        self:buildCellDatabase()

        self.isLoaded = true
    end
end


---Creates a table that contains all different list items. Section headers are excluded and saved separately.
-- These cells are later cloned to form the completed list
function SmoothListElement:buildCellDatabase()
    self.cellDatabase = {}
    local numCellsInDatabase = 0

    for i = #self.elements, 1, -1 do
        local element = self.elements[i]

        local name = element.name
        if element:isa(ListItemElement) then
            if name == nil then
                element.name = "autoCell" .. i
                name = element.name
            end

            self.cellDatabase[name] = element
            self.cellCache[name] = {}

            numCellsInDatabase = numCellsInDatabase + 1
        end

        element:unlinkElement()
        FocusManager:removeElement(element)
    end

    if self.sectionHeaderCellName ~= nil and self.cellDatabase[self.sectionHeaderCellName] == nil then
        -- Header does not exist, ignore it
        Logging.warning("List section header with name '%s' does not exist on '%s'", self.sectionHeaderCellName, self.profile)
        self.sectionHeaderCellName = nil
    end

    if self.sectionHeaderCellName ~= nil then
        numCellsInDatabase = numCellsInDatabase - 1
    end

    if self.dataSource.getEmptyCellType ~= nil and self.cellDatabase[self.dataSource:getEmptyCellType(self)] ~= nil or self.cellDatabase["empty"] then
        numCellsInDatabase = numCellsInDatabase - 1
    end

    -- Used for optimized setups with only 1 cell
    if numCellsInDatabase == 1 then
        for name, cell in pairs(self.cellDatabase) do
            if name ~= self.sectionHeaderCellName then
                self.singularCellName = name
                break
            end
        end
    end
end


---Run over all items in cache and database and call the lambda with the element as value
-- @param function lambda Function that gets called for each cell, with the cell being the only parameter
function SmoothListElement:iterateOverDatabase(lambda)
    if self.cellDatabase ~= nil then
        for _, cell in pairs(self.cellDatabase) do
            lambda(cell)
        end
    end

    if self.cellCache ~= nil then
        for _, elements in pairs(self.cellCache) do
            for i = 1, #elements do
                lambda(elements[i])
            end
        end
    end
end


---Delete this SmoothListElement. Also deletes all child elements and removes itself from its parent and focus.
function SmoothListElement:delete()
    for name, elements in pairs(self.cellCache) do
        for _, element in ipairs(elements) do
            element:delete()
        end
    end

    for name, element in pairs(self.cellDatabase) do
        element:delete()
    end

    SmoothListElement:superClass().delete(self)
end






---Called on the root element of a screen view when it is opened.
-- This raises the "onOpenCallback" if defined and propagates to all children.
function SmoothListElement:onOpen()
    if self.setNextOpenIndex ~= nil then
        self:setSoundSuppressed(true)

        self:setSelectedItem(self.setNextOpenSectionIndex, self.setNextOpenIndex, true, true)
        self.setNextOpenIndex = nil
        self.setNextOpenSectionIndex = nil

        self:setSoundSuppressed(false)
    end
end


---Called on the root element of a screen view when it is closed.
function SmoothListElement:onClose()
    if self.isMovingToTarget then
        self:scrollTo(self.targetViewOffset)
    end
end






---Set the target that contains all necessary data and functions to populate the list. If list delegate is not yet set, dataSource will also be used as delegate target
-- @param table dataSource Target screen/frame
function SmoothListElement:setDataSource(dataSource)
    self.dataSource = dataSource

    if self.delegate == nil then
        self.delegate = dataSource
    end
end


---Set the delegate target that contains function callbacks for list events. If dataSource is not yet set, delegate will also be used as dataSource
-- @param table delegate Delegate screen/frame
function SmoothListElement:setDelegate(delegate)
    self.delegate = delegate

    if self.dataSource == nil then
        self.dataSource = delegate
    end
end






---Get a cell (ListElement) with given type name. If there are cells with the correct name in the cellCache, we use those, otherwise a new one is created
-- @param string name Name of the cell
-- @return table A ListItem instance with the requested name
function SmoothListElement:dequeueReusableCell(name)
    if self.cellDatabase[name] == nil then
        return nil
    end

    local cell

    local cache = self.cellCache[name]
    if #cache > 0 then
        cell = cache[#cache]
        cache[#cache] = nil

        self:addElement(cell)
    else
        cell = self.cellDatabase[name]:clone(self)
        cell.reusableName = name
    end

    FocusManager:loadElementFromCustomValues(cell)

    return cell
end


---Release a cell to the cache after resetting it
-- @param table cell The cell to be added to the cache
function SmoothListElement:queueReusableCell(cell)
    -- if section was removed we do not need to reset reference
    if self.sections[cell.sectionIndex] ~= nil then
        self.sections[cell.sectionIndex].cells[cell.indexInSection] = nil
    end

    cell.sectionIndex = nil
    cell.indexInSection = nil

    local cache = self.cellCache[cell.reusableName]
    cache[#cache + 1] = cell

    cell:unlinkElement()
    FocusManager:removeElement(cell)
end


---Set the target element of this element. This elements callbacks triggers will be called on the target
-- The target is only set if originalTarget equals this elements current target. This in then propagated to all children, as well as all current cells
-- Additionally, if delegate or dataSource are nil, target will be used for them as well
-- @param table target The target element
-- @param table? originalTarget New target is only set if this elements current target equals this parameter. Can be nil, which then requires the current target to also be nil to be set
-- @param boolean? callOnCreate If true, this elements onCreateCallback is called
function SmoothListElement:setTarget(target, originalTarget, callOnCreate)
    SmoothListElement:superClass().setTarget(self, target, originalTarget, callOnCreate)

    if self.delegate == originalTarget then
        self.delegate = target
    end

    if self.dataSource == originalTarget then
        self.dataSource = target
    end

    self:iterateOverDatabase(function (e)
        e:setTarget(target, originalTarget, callOnCreate)
    end)
end






---Reload the data into the list. Calls buildSectionInfo() and then updateView().
-- This has to be called every time the list data changes, if these changes should be shown
-- @param boolean forceCellTypeUpdate [optional] If true, we look up the cell types (names) for each cell again instead of only repopulating the data
function SmoothListElement:reloadData(forceCellTypeUpdate)
    if self.dataSource == nil then
        return
    end

    self:setSoundSuppressed(true)

    if forceCellTypeUpdate then
        for _, section in pairs(self.sections) do
            for i = #section.cells, 1, -1 do
                local cell = section.cells[i]
                if cell ~= nil then
                    self:queueReusableCell(cell)
                end
            end
        end
    end

    self:buildSectionInfo()
    self:updateView(nil, true)

    self:setSoundSuppressed(false)
end


---Reload given section into the list, trying to optimize (currently not working properly, just reloads entire list)
-- @param integer? section Section index of section to be reloaded
function SmoothListElement:reloadSection(section)
    -- TODO specialize
    self:reloadData()
end


---Creates a content cache with sections, titles, and number of items per section
function SmoothListElement:buildSectionInfo() -- startAt
    -- TODO: support rebuilding only 1 section
    local total = 0

    -- Default to 1
    local numberOfSections = self.dataSource.getNumberOfSections == nil and 1 or self.dataSource:getNumberOfSections(self)

    local itemWidth = self:getWidthOfItemFast(1, 1) + self.listItemLateralSpacing
    if self.useLateralFilling and itemWidth > 0 then
        self.numLateralItems = math.max(math.floor((self.absSize[self.widthAxis] + self.listItemLateralSpacing) / itemWidth), 1)
    else
        itemWidth = (self.absSize[self.widthAxis] - (self.numLateralItems - 1) * self.listItemLateralSpacing) / self.numLateralItems + self.listItemLateralSpacing
    end

    local totalRows = 0
    local currentLengthOffset = 0

    -- TODO: if startAt is set, start there
    for s = 1, numberOfSections do
        -- TODO: if startAt is set, see if a section already exists

        if self.sections[s] == nil then
            self.sections[s] = {
                cells = {}, -- Cell for each item + header at 0
            }
        end
        local section = self.sections[s]

        -- Reset these in case there are less items now than before
        section.itemOffsets = {}
        section.itemLateralOffsets = {}

        -- Get whether there is a header element
        local hasHeader = self.sectionHeaderCellName ~= nil
        if self.dataSource.getTitleForSectionHeader ~= nil and self.dataSource:getTitleForSectionHeader(self, s) == nil then
            hasHeader = false
        end

        local sectionOffset = s > 1 and self.listSectionSpacing or 0
        section.startOffset = currentLengthOffset

        if hasHeader then
            section.startOffset = currentLengthOffset + sectionOffset
            section.itemOffsets[0] = section.startOffset

            currentLengthOffset = currentLengthOffset + self.cellDatabase[self.sectionHeaderCellName].size[self.lengthAxis] + self.listItemSpacing + sectionOffset
        end

        -- Get number of items
        section.numItems = self.dataSource:getNumberOfItemsInSection(self, s)

        -- Get height for all items
        local lastRow = 1
        local rowMaxLength = 0
        for i = 1, section.numItems do
            local itemLength = self:getLengthOfItemFast(s, i)

            local row = math.floor((i - 1) / self.numLateralItems) + 1
            local column = (i - 1) % self.numLateralItems + 1

            -- Add spacing at end of every item except last one
            local needsAnotherRow = section.numItems / self.numLateralItems > row
            if needsAnotherRow or s < numberOfSections then
                itemLength = itemLength + self.listItemSpacing
            end

            -- Jump to next offset if this is a new row
            if row ~= lastRow then
                lastRow = row
                currentLengthOffset = currentLengthOffset + rowMaxLength

                totalRows = totalRows + 1

                rowMaxLength = itemLength
            else
                rowMaxLength = math.max(rowMaxLength, itemLength)
            end

            section.itemOffsets[i] = currentLengthOffset
            section.itemLateralOffsets[i] = itemWidth * (column - 1)

            local emptyCellName = self.dataSource.getEmptyCellType ~= nil and self.dataSource:getEmptyCellType(self) or "empty"
            if self.numLateralItems > 1 and i == section.numItems and self.fillRowsWithEmptyItems and self.cellDatabase[emptyCellName] ~= nil then
                local emptyIndex = i + 1
                while emptyIndex % self.numLateralItems ~= 1 do
                    column = (emptyIndex - 1) % self.numLateralItems + 1

                    section.itemOffsets[emptyIndex] = currentLengthOffset
                    section.itemLateralOffsets[emptyIndex] = itemWidth * (column - 1)

                    emptyIndex = emptyIndex + 1
                end
            end
        end

        -- Start new row with new section
        currentLengthOffset = currentLengthOffset + rowMaxLength
        totalRows = totalRows + 1

        -- TODO: if startAt is set, and this did not change, break
        section.endOffset = currentLengthOffset

        total = total + section.numItems

        self.sections[s] = section
    end

    -- Remove old sections
    for s = #self.sections, numberOfSections + 1, -1 do
        self.sections[s] = nil
    end

    local selectedSection = self.selectedSectionIndex
    local selectedIndex = self.selectedIndex

    if #self.sections > 0 then
        selectedSection = math.clamp(selectedSection, 1, #self.sections)

        if self.sections[selectedSection].numItems == 0 then
            -- Find first section with items
            for sectionIndex, section in ipairs(self.sections) do
                if section.numItems > 0 then
                    selectedIndex = math.clamp(selectedIndex, 1, section.numItems)
                    selectedSection = sectionIndex
                    break
                end
            end
        else
            selectedIndex = math.clamp(selectedIndex, 1, self.sections[selectedSection].numItems)
        end

        if selectedIndex ~= 0 then
            if not self:getIsVisible() then
                self.setNextOpenIndex = selectedIndex
                self.setNextOpenSectionIndex = selectedSection
            else
                self:setSelectedItem(selectedSection, selectedIndex, true)
            end
        else
            self.selectedSectionIndex = 0
            self.selectedIndex = 0
        end
    end

    if totalRows > 0 then
        if self.itemizedScrollDelta ~= nil and self.itemizedScrollDelta > 0 and #self.sections == 1 and self.singularCellName ~= nil then
            self.scrollViewOffsetDelta = (currentLengthOffset + self.listItemSpacing) / totalRows * self.itemizedScrollDelta
        else
            self.scrollViewOffsetDelta = math.max(currentLengthOffset / totalRows * 0.4, self.absSize[self.lengthAxis] / 5)
        end
    else
        self.scrollViewOffsetDelta = 0
    end
    self.contentSize = currentLengthOffset

    local contentOffset = self.absSize[self.lengthAxis] - currentLengthOffset
    if contentOffset > 0 then
        self.listItemAlignmentOffset = contentOffset * self.listItemAlignment

        if self.isHorizontalList then
            self.listItemAlignmentOffset  = self.listItemAlignmentOffset  * -1
        end
    end

    local oldTotalItemCount = self.totalItemCount
    self.totalItemCount = total

    if self.emptyIndicatorElement ~= nil and oldTotalItemCount == 0 and self.totalItemCount > 0 then
        self.emptyIndicatorElement:setVisible(false)
    elseif self.emptyIndicatorElement ~= nil and self.totalItemCount == 0 and oldTotalItemCount > 0 then
        self.emptyIndicatorElement:setVisible(true)
    end

    -- Content size changed
    self.viewOffset = math.max(math.min(self.viewOffset, self.contentSize - self.absSize[self.lengthAxis]), 0)
    self.targetViewOffset = math.max(math.min(self.targetViewOffset, self.contentSize - self.absSize[self.lengthAxis]), 0)
    self:updateScrollClippers()
end


---Get length of an item in the list
-- @param integer section Index of the section the item is in
-- @param integer index Index of the item in its section
-- @return float itemLength Length of the item in the lists length axis
function SmoothListElement:getLengthOfItemFast(section, index)
    local cellName = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, section, index)
    local cell = self.cellDatabase[cellName]

    return cell.size[self.lengthAxis]
end


---Get width of an item in the list
-- @param integer section Index of the section the item is in
-- @param integer index Index of the item in its section
-- @return float itemLength Width of the item in the lists width axis
function SmoothListElement:getWidthOfItemFast(section, index)
    local cellName = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, section, index)
    local cell = self.cellDatabase[cellName]

    return cell.size[self.widthAxis]
end


---Update the view, moving the cells, dequeueing and queuing when needed
-- @param boolean updateSlider If true, raiseSliderUpdateEvent() is called
-- @param any repopulate
function SmoothListElement:updateView(updateSlider, repopulate)
    -- Create new cells
    local viewEndOffset = self.viewOffset + self.absSize[self.lengthAxis]

    -- Find first cell we need to show
    local firstSection, firstIndex = 0, 0
    for s = 1, #self.sections do
        local section = self.sections[s]

        -- If view offset is after the end of this section the whole section is hidden
        if self.viewOffset < section.endOffset then
            firstSection = s

            for i = 0, section.numItems do
                local offset = section.itemOffsets[i] -- can be nil for no-header. start of item
                local itemLength = self:getLengthOfItemFast(s, i) or 0
                local endOffset = offset ~= nil and offset + itemLength or itemLength

                -- First item that has its end still in view should be visible
                if offset ~= nil and endOffset ~= nil and self.viewOffset + SmoothListElement.CHECK_OFFSET_EPSILON < endOffset then
                    firstIndex = i
                    break
                end
            end

            if firstIndex == nil then
                firstIndex = section.numItems
            end

            break
        end
    end

    -- Find last cell we need to show
    local lastSection, lastIndex = 0, 1
    for s = #self.sections, math.max(firstSection, 1), -1 do
        local section = self.sections[s]
        if viewEndOffset > section.startOffset then
            lastSection = s

            for i = section.numItems - 1, 0, -1 do
                local offset = section.itemOffsets[i + 1]
                if offset ~= nil and viewEndOffset > offset then
                    lastIndex = i + 1
                    break
                end
            end
            if lastIndex == nil then
                lastIndex = section.numItems
            end

            break
        end
    end

    -- Delete elements if they are before or after the viewable frame
    for e = #self.elements, 1, -1 do
        local element = self.elements[e]

        if element.sectionIndex < firstSection or element.sectionIndex > lastSection -- section not visible at all
            or (element.sectionIndex == firstSection and element.indexInSection < firstIndex) -- element in first visible section but before first item
            or (not element.isEmptyCell and element.sectionIndex == lastSection and element.indexInSection > lastIndex) -- element in last visible section but after last item
            or (not element.isEmptyCell and self.sections[element.sectionIndex].numItems < element.indexInSection) -- element should not be in section anymore
            or (element.isEmptyCell) then   -- always queue empty cells, since they will fill up the row at the end and mess up calculations before that

            self:queueReusableCell(element)
        end
    end

    -- No content
    if firstSection == 0 or lastSection == 0 then
        if updateSlider ~= false then
            self:raiseSliderUpdateEvent()
        end

        return
    end

    -- Go through all sections and items we need to show
    local s, i = firstSection, firstIndex
    local currentOffset = self.sections[s].itemOffsets[firstIndex]
    while currentOffset - self.viewOffset < self.absSize[self.lengthAxis] do
        local section = self.sections[s]

        -- if a cell was an empty cell but is now filled, we need to switch it out
        if i < section.numItems and section.cells[i] ~= nil and section.cells[i].isEmptyCell then
            self:queueReusableCell(section.cells[i])
            section.cells[i] = nil
        end

        -- Generate cells that do not exist yet
        if section.cells[i] == nil then
            local element
            if i == 0 then
                if self.sectionHeaderCellName ~= nil then
                    element = self:dequeueReusableCell(self.sectionHeaderCellName)
                    element.isHeader = true

                    local titleAttribute = element:getAttribute("title")
                    if titleAttribute ~= nil and self.dataSource.getTitleForSectionHeader ~= nil then
                        titleAttribute:setText(self.dataSource:getTitleForSectionHeader(self, s))
                    elseif self.dataSource.populateSectionHeader ~= nil then
                        self.dataSource:populateSectionHeader(self, s, element)
                    end
                end
            else
                local cellName = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, s, i)
                element = self:dequeueReusableCell(cellName)

                self.dataSource:populateCellForItemInSection(self, s, i, element)

                element:setAlternating(i % 2 == 0)
            end

            element.sectionIndex = s
            element.indexInSection = i

            -- Used when checking if element already exists. Cleared when queueing.
            section.cells[i] = element

            -- Update selected state because state might have been queued
            element:setSelected(s == self.selectedSectionIndex and i == self.selectedIndex and (self.selectedWithoutFocus or FocusManager:getFocusedElement() == self))

        -- Repopulating is useful when refreshing data
        elseif repopulate then
            local element = section.cells[i]

            if i == 0 then
                local titleAttribute = element:getAttribute("title")
                if titleAttribute ~= nil and self.dataSource.getTitleForSectionHeader ~= nil then
                    titleAttribute:setText(self.dataSource:getTitleForSectionHeader(self, s))
                elseif self.dataSource.populateSectionHeader ~= nil then
                    self.dataSource:populateSectionHeader(self, s, element)
                end
            elseif i <= section.numItems then
                self.dataSource:populateCellForItemInSection(self, s, i, element)
                element:setAlternating(i % 2 == 0)

                -- Update selected state because state might have been queued
                element:setSelected(s == self.selectedSectionIndex and i == self.selectedIndex and (self.selectedWithoutFocus or FocusManager:getFocusedElement() == self))
            end
        end

        -- Get next item index
        i = i + 1

        local emptyCellName = self.dataSource.getEmptyCellType ~= nil and self.dataSource:getEmptyCellType(self) or "empty"
        if self.fillRowsWithEmptyItems and self.cellDatabase[emptyCellName] ~= nil and i > section.numItems and self.numLateralItems > 1 then
            -- if fillRowsWithEmptyItems is true, we add empty cells at the end of the last row (if needed)
            local emptyIndex = i
            while emptyIndex % self.numLateralItems ~= 1 do
                local emptyCell = self:dequeueReusableCell(emptyCellName)
                emptyCell.sectionIndex = s
                emptyCell.indexInSection = emptyIndex
                emptyCell.isEmptyCell = true
                emptyCell.playHoverSoundOnFocus = false

                section.cells[emptyIndex] = emptyCell

                emptyIndex = emptyIndex + 1
            end
        end

        if s == lastSection and i > lastIndex then
            break
        elseif i > section.numItems then
            i = 0
            s = s + 1

            if s > lastSection then
                break
            end

            -- No header
            if self.sections[s].itemOffsets[i] == nil then
                i = 1
            end

            currentOffset = self.sections[s].startOffset
        else
            currentOffset = section.itemOffsets[i]
        end
    end

    self.numVisibleItems = #self.elements

    -- Update position of all cells
    for _, cell in pairs(self.elements) do
        self:updateCellPosition(cell)
    end

    if updateSlider ~= false then
        self:raiseSliderUpdateEvent()
    end

    self:updateScrollClippers()
end




































---
function SmoothListElement:scrollToStartGamepad()
    if self.gamepadPageStartTime == nil then
        self.gamepadPageStartTime = g_time + SmoothListElement.GAMEPAD_PAGE_START_END_TIME
    end

    self.gamepadPageStartTriggered = true

    if g_time >= self.gamepadPageStartTime then
        self:scrollToStart()
        self.gamepadPageStartTime = math.huge
    end
end


---
function SmoothListElement:scrollToEndGamepad()
    if self.gamepadPageEndTime == nil then
        self.gamepadPageEndTime = g_time + SmoothListElement.GAMEPAD_PAGE_START_END_TIME
    end

    self.gamepadPageEndTriggered = true

    if g_time >= self.gamepadPageEndTime then
        self:scrollToEnd()
        self.gamepadPageEndTime = math.huge
    end
end


---
function SmoothListElement:scrollToStart()
    if #self.sections == 1 or Input.isKeyPressed(Input.KEY_lctrl) or g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_KEYBOARD then
        self:setSelectedItem(1, 1)
    else
        self:setSelectedItem(self.selectedSectionIndex, 1)
    end
end


---
function SmoothListElement:scrollToEnd()
    local numSections = #self.sections
    local lastCellIndex = self.sections[numSections].numItems

    if numSections == 1 or Input.isKeyPressed(Input.KEY_lctrl) or g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_KEYBOARD then
        self:setSelectedItem(numSections, lastCellIndex)
    else
        lastCellIndex = self.sections[self.selectedSectionIndex].numItems
        self:setSelectedItem(self.selectedSectionIndex, lastCellIndex)
    end
end


---
function SmoothListElement:scrollToPrevPage()
    local spacing = self.isHorizontalList and self.listItemLateralSpacing or self.listItemSpacing
    local viewEndOffset = self.viewOffset - spacing

    if #self.sections == 1 or Input.isKeyPressed(Input.KEY_lctrl) then
        local targetOffset
        local foundTargetOffset = false

        for sectionIndex, section in pairs(self.sections) do
            if section.endOffset > viewEndOffset or MathUtil.equalEpsilon(section.endOffset, self.viewOffset, SmoothListElement.CHECK_OFFSET_EPSILON) then
                for cellIndex, cellOffset in pairs(section.itemOffsets) do
                    targetOffset = cellOffset + self:getLengthOfItemFast(sectionIndex, cellIndex) + spacing

                    if targetOffset > viewEndOffset + SmoothListElement.CHECK_OFFSET_EPSILON then
                        targetOffset = targetOffset  - self.absSize[self.lengthAxis] - spacing
                        targetOffset = math.max(math.min(targetOffset, self.contentSize - self.absSize[self.lengthAxis]), 0)
                        foundTargetOffset = true

                        break
                    end
                end

                if foundTargetOffset then
                    break
                end
            end
        end

        for sectionIndex, section in pairs(self.sections) do
            if section.endOffset > targetOffset or MathUtil.equalEpsilon(section.endOffset, targetOffset, SmoothListElement.CHECK_OFFSET_EPSILON) then
                for cellIndex, cellOffset in pairs(section.itemOffsets) do
                    if cellOffset > targetOffset or MathUtil.equalEpsilon(cellOffset, targetOffset, SmoothListElement.CHECK_OFFSET_EPSILON) then
                        self:setSelectedItem(sectionIndex, cellIndex)
                        return
                    end
                end
            end
        end
    else
        self:setSelectedItem(self.selectedSectionIndex - 1, 1)
    end
end


---
function SmoothListElement:scrollToNextPage()
    if #self.sections == 1 or Input.isKeyPressed(Input.KEY_lctrl) then
        local targetOffset
        local spacing = self.isHorizontalList and self.listItemLateralSpacing or self.listItemSpacing
        local viewEndOffset = self.viewOffset + self.absSize[self.lengthAxis] + spacing

        for sectionIndex, section in pairs(self.sections) do
            if section.endOffset > viewEndOffset or MathUtil.equalEpsilon(section.endOffset, viewEndOffset, SmoothListElement.CHECK_OFFSET_EPSILON) then
                for cellIndex, cellOffset in pairs(section.itemOffsets) do
                    targetOffset = cellOffset + self:getLengthOfItemFast(sectionIndex, cellIndex) + spacing

                    if targetOffset > viewEndOffset + SmoothListElement.CHECK_OFFSET_EPSILON then
                        if cellIndex - self.numLateralItems <= 0 and section.itemOffsets[0] ~= nil then
                            cellOffset = section.itemOffsets[0]
                        end

                        self:setSelectedItem(sectionIndex, cellIndex)
                        self:smoothScrollTo(cellOffset)

                        return
                    end
                end
            elseif sectionIndex == #self.sections then
                self:setSelectedItem(sectionIndex, self.sections[sectionIndex].numItems)
            end
        end
    else
        self:setSelectedItem(self.selectedSectionIndex + 1, 1)

        --we need to scroll again because at this point the selected item is only at the bottom of the visible list, we want it at the top
        local firstElementIndex = self.sections[self.selectedSectionIndex].itemOffsets[0] ~= nil and 0 or 1
        self:smoothScrollTo(self.sections[self.selectedSectionIndex].itemOffsets[firstElementIndex])
    end
end


---
-- @param any offset
function SmoothListElement:smoothScrollTo(offset)
    if self.listSmoothingDisabled then
        self:scrollTo(offset)
    end

    offset = math.max(math.min(offset, self.contentSize - self.absSize[self.lengthAxis]), 0)

    self.targetViewOffset = offset
    self.isMovingToTarget = true
end














































































---Apply visual list item selection state based on the current data selection.
function SmoothListElement:applyElementSelection()
    local focusAllowed = self.selectedWithoutFocus or FocusManager:getFocusedElement() == self

    for _, element in pairs(self.elements) do
        element:setSelected(focusAllowed and element.sectionIndex == self.selectedSectionIndex and element.indexInSection == self.selectedIndex)
    end
end


---Remove element selection state on all elements (e.g. when losing focus).
function SmoothListElement:clearElementSelection()
    for i = 1, #self.elements do
        local element = self.elements[i]

        if element.setSelected ~= nil then
            element:setSelected(false)
        end
    end
end



























































































































































---Get the number of list items in the list's data source. Includes section headers.
-- @return Number of list items in data source
function SmoothListElement:getItemCount()
    return self.totalItemCount
end


---Get the currently selected item within its section
function SmoothListElement:getSelectedIndexInSection()
    return self.selectedIndex
end








---Returns section and index in section
function SmoothListElement:getSelectedPath()
    return self.selectedSectionIndex, self.selectedIndex
end


---Get the element for given path
function SmoothListElement:getElementAtSectionIndex(section, index)
    if self.sections[section] == nil then
        return nil
    end

    return self.sections[section].cells[index]
end















































---Handles the activation event via mouse or touch input. for mouse, this is called with onInputDown(), for touch with onInputUp()
function SmoothListElement:activateInput()
    if self.inputOverElement ~= nil then
        local previousSection, previousIndex = self.selectedSectionIndex, self.selectedIndex
        local clickedSection, clickedIndex
        if self.listSnappingEnabled then
            clickedSection = self.inputOverElement.sectionIndex
            clickedIndex = MathUtil.round(previousIndex + 0.3 * self.lastScrollDirection, 0)
        else
            clickedSection, clickedIndex = self.inputOverElement.sectionIndex, self.inputOverElement.indexInSection
        end
        local notified = false

        if self.lastClickTime ~= nil and self.lastClickTime > self.target.time - self.doubleClickInterval then
            -- Only activate click if the target was hit
            if clickedSection == previousSection and clickedIndex == previousIndex then
                self:notifyDoubleClick(clickedSection, clickedIndex, self.inputOverElement)
                self.usedTouchId = nil
                notified = true
            end
            self.lastClickTime = nil
        else
            self.lastClickTime = self.target.time
        end

        local wasScrolling = self.totalTouchMoveDistance > self.touchMoveDistanceThreshold
        self.wasScrolling = wasScrolling
        local wasAlreadySelected = self.selectedIndex == clickedIndex

        if not wasScrolling or self.selectOnScroll then
            self:setSelectedItem(clickedSection, clickedIndex)
        end

        if not self.selectOnClick and not notified and not wasScrolling then
            self:notifyClick(clickedSection, clickedIndex, self.inputOverElement, wasAlreadySelected)
        end
    else
        self.lastClickTime = nil
    end
end


---Handles input down event
function SmoothListElement:onInputDown()
    self.inputDown = true
    self.inputDownTimer = 0

    FocusManager:setFocus(self)
end


---Handles input up (after down) event
function SmoothListElement:onInputUp()
    self.inputDown = false
    self.totalTouchMoveDistance = 0
end








---
function SmoothListElement:notifyDoubleClick(section, index, element)
    self:raiseCallback("onDoubleClickCallback", self, section, index, element, true)
end


---
function SmoothListElement:notifyClick(section, index, element, wasAlreadySelected)
    self:raiseCallback("onClickCallback", self, section, index, element, wasAlreadySelected)
end


---Handle mouse input
function SmoothListElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() and not self.ignoreMouse then
        if SmoothListElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
            eventUsed = true
        end

        if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
            local inputOverElement = self:getElementAtScreenPosition(posX, posY)
            if inputOverElement ~= nil and inputOverElement.indexInSection == 0 then
                inputOverElement = nil
            end

            -- Mouse over changed
            if self.inputOverElement ~= inputOverElement then
                self:setHighlightedItem(inputOverElement)
                self.inputOverElement = inputOverElement
            end

            if isDown then
                if button == Input.MOUSE_BUTTON_LEFT then
                    self:onInputDown()
                    self:activateInput()
                    eventUsed = self.inputOverElement ~= nil
                end

                if self.supportsMouseScrolling then
                    local deltaIndex = 0
                    if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
                        deltaIndex = -1
                    elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
                        deltaIndex = 1
                    end

                    if deltaIndex ~= 0 then
                        if self.selectOnScroll then
                            -- Fast code for just 1 section as it is easy. If need arises we can expand to support multiple sections
                            if #self.sections == 1 then
                                local newIndex = math.max(1, math.min(self.sections[1].numItems, self.selectedIndex + deltaIndex))
                                self:setSelectedItem(1, newIndex)
                            end
                        else
                            self:smoothScrollTo(self.targetViewOffset + deltaIndex * self.scrollViewOffsetDelta)
                        end

                        eventUsed = true
                    end
                end
            end

            if isUp and button == Input.MOUSE_BUTTON_LEFT and self.inputDown then
                self:onInputUp()
                eventUsed = self.inputOverElement ~= nil
            end
        elseif self.inputOverElement ~= nil then
            self.inputOverElement = nil
            self:setHighlightedItem(nil)
        end
    end

    return eventUsed
end


---
-- @param any posX
-- @param any posY
-- @param any isDown
-- @param any isUp
-- @param any touchId
-- @param any eventUsed
-- @return any eventUsed
function SmoothListElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self:getIsActive() then
        if SmoothListElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) then
            eventUsed = true
        end

        if not eventUsed and (self.usedTouchId == touchId or GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot)) then
            local inputOverElement = self:getElementAtScreenPosition(posX, posY)
            if inputOverElement ~= nil and inputOverElement.indexInSection == 0 then
                inputOverElement = nil
            end

            -- touch over changed
            if self.inputOverElement ~= inputOverElement then
                self:setHighlightedItem(inputOverElement)
                self.inputOverElement = inputOverElement
            end

            local wasScrolling = self.totalTouchMoveDistance > self.touchMoveDistanceThreshold
            self.wasScrolling = wasScrolling

            if self.supportsTouchScrolling then
                if self.usedTouchId == nil then
                    if not eventUsed and isDown then
                        self.currentTouchDelta = 0
                        self.lastTouchPosX = posX
                        self.lastTouchPosY = posY
                        self.usedTouchId = touchId
                        eventUsed = true
                    end
                elseif self.usedTouchId == touchId then
                    if isUp then
                        self:onInputUp()
                        self.usedTouchId = nil
                        self.initialScrollSpeed = self.scrollSpeed
                    else
                        local delta = 0
                        local lastTouchPosX = self.lastTouchPosX or posX
                        local lastTouchPosY = self.lastTouchPosY or posY

                        if self.isHorizontalList then
                            delta = posX - lastTouchPosX
                        else
                            delta = posY - lastTouchPosY
                        end
                        self.currentTouchDelta = (self.currentTouchDelta or 0) + delta

                        local distancePixels = MathUtil.vector2Length((lastTouchPosX - posX) * g_screenWidth, (lastTouchPosY - posY) * g_screenHeight)
                        self.totalTouchMoveDistance = self.totalTouchMoveDistance + distancePixels
                        self.lastTouchPosX = posX
                        self.lastTouchPosY = posY
                    end
                end
            end

            if isDown and not wasScrolling then
                self:onInputDown()
                eventUsed = true
            end

            if isUp and self.inputDown then
                self:activateInput()
                self:onInputUp()
                eventUsed = true
            end
        end
    end

    return eventUsed
end

























































































































































---
function SmoothListElement:canReceiveFocus()
    return self:getIsVisible() and self.handleFocus and not self.disabled and (self.canReceiveFocusWhileEmpty or self.totalItemCount > 0)
end


---
function SmoothListElement:onFocusActivate()
    if self.totalItemCount == 0 then
        return
    end

    if self.ignoreFocusActivate then
        return
    end

    if self.onClickCallback ~= nil then
        self:notifyClick(self.selectedSectionIndex, self.selectedIndex, self:getElementAtSectionIndex(self.selectedSectionIndex, self.selectedIndex))
        return
    end

    if self.onDoubleClickCallback ~= nil then   -- when is this triggered in conjunction with focus?
        self:notifyDoubleClick(self.selectedSectionIndex, self.selectedIndex, nil)
        return
    end
end


---
function SmoothListElement:onFocusEnter()
    self:applyElementSelection()

    if self.delegate.onListSelectionChanged ~= nil then
        self.delegate:onListSelectionChanged(self, self.selectedSectionIndex, self.selectedIndex)
    end
end


---
function SmoothListElement:onFocusLeave()
    if not self.selectedWithoutFocus then
        self:clearElementSelection()
    end

    SmoothListElement:superClass().onFocusLeave(self)
end
