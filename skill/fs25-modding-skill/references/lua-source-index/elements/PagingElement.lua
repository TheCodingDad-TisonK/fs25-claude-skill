












---Paging control element.
-- 
-- Organizes grouped elements into pages to be displayed one at a time. To set it up, one defines several
-- same-sized container elements (e.g. bare GuiElement) as children of the PagingElement to hold the pages' contents.
-- The pages should be given #name properties which are resolved to a localization text with a prepended "ui_" prefix.
-- On loading, any named child element of this PagingElement will be added as a page.
local PagingElement_mt = Class(PagingElement, GuiElement)




---
function PagingElement.new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = PagingElement_mt
    end

    local self = GuiElement.new(target, custom_mt)
    self:include(IndexChangeSubjectMixin)-- add index change subject mixin for paging observers

    self.pageIdCount = 1

    self.pages = {} -- list of pages
    self.idPageHash = {} -- hash of page ID to actual page
    self.pageMapping = {} -- map of visible page indices to all page indices

    self.currentPageIndex = 1
    self.currentPageMappingIndex = 1

    return self
end


---
function PagingElement:loadFromXML(xmlFile, key)
    PagingElement:superClass().loadFromXML(self, xmlFile, key)

    self:addCallback(xmlFile, key .. "#onPageChange", "onPageChangeCallback")
    self:addCallback(xmlFile, key .. "#onPageUpdate", "onPageUpdateCallback")
end


---
function PagingElement:copyAttributes(src)
    PagingElement:superClass().copyAttributes(self, src)
    self.onPageChangeCallback = src.onPageChangeCallback
    self.onPageUpdateCallback = src.onPageUpdateCallback

    GuiMixin.cloneMixin(IndexChangeSubjectMixin, src, self)
end


---
function PagingElement:onGuiSetupFinished()
    PagingElement:superClass().onGuiSetupFinished(self)
    self:updatePageMapping()
end




























---
function PagingElement:addElement(element)
    PagingElement:superClass().addElement(self, element)
    if element.name ~= nil and g_i18n:hasText("ui_"..element.name) then
        self:addPage(string.upper(element.name), element, g_i18n:getText("ui_"..element.name))
    else
        self:addPage(tostring(element), element, "")
    end
end
























































































































---
function PagingElement:removeElement(element)
    PagingElement:superClass().removeElement(self, element)
    self:removePageByElement(element) -- also remove any page using that element as its root node
end


---Get the page ID of the currently displayed page.
function PagingElement:getCurrentPageId()
    return self.pages[self.currentPageIndex].id
end


---Get the index of a page in the page mappings (only visible pages) by page ID.
function PagingElement:getPageMappingIndex(pageId)
    return self.idPageHash[pageId].mappingIndex
end


---Determine if a page, identified by page ID, is disabled.
function PagingElement:getIsPageDisabled(pageId)
    return self.idPageHash[pageId].disabled
end


---Get a page by ID.
function PagingElement:getPageById(pageId)
    return self.idPageHash[pageId]
end


---
function PagingElement:setPageDisabled(page, disabled)
    if page ~= nil then
        page.disabled = disabled
        self:updatePageMapping()
        self:raiseCallback("onPageUpdateCallback", page, self)
    end
end











---
function PagingElement:updatePageMapping()
    self.pageMapping = {}
    self.pageTitles = {}
    local currentPage = self.pages[self.currentPageIndex]

    for i, page in ipairs(self.pages) do
        if not page.disabled then
            table.insert(self.pageMapping, i)
            table.insert(self.pageTitles, page.title)
            page.mappingIndex = #self.pageMapping
        else
            if page == currentPage then
                -- force page resetting
                currentPage = nil
            end
            page.mappingIndex = 1
        end
    end

    if currentPage == nil then
        if not self.neuterPageUpdates then
            if #self.pageMapping > 0 then
                self.currentPageMappingIndex = math.clamp(self.currentPageMappingIndex, 1, #self.pageMapping)
                self:setPage(self.currentPageMappingIndex)
            end
        end
    else
        self:notifyIndexChange(self.currentPageMappingIndex, #self.pageMapping) -- notify change in number of pages
    end
end
