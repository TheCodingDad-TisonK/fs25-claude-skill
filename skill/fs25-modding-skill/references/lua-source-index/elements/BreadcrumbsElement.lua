









---Breadcrumbs for deeper layouts (shop, modhub)
local BreadcrumbsElement_mt = Class(BreadcrumbsElement, BoxLayoutElement)




---
function BreadcrumbsElement.new(target, custom_mt)
    local self = BoxLayoutElement.new(target, custom_mt or BreadcrumbsElement_mt)

    self.crumbs = {}

    return self
end


---
function BreadcrumbsElement:copyAttributes(src)
    BreadcrumbsElement:superClass().copyAttributes(self, src)

    self.textTemplate = src.textTemplate
    self.arrowTemplate = src.arrowTemplate
    self.ownsTemplates = false
end


---
function BreadcrumbsElement:onGuiSetupFinished()
    BreadcrumbsElement:superClass().onGuiSetupFinished(self)

    if self.textTemplate == nil or self.arrowTemplate == nil then
        self.ownsTemplates = true

        self.textTemplate = self:getFirstDescendant(function(element) return element:isa(TextBackdropElement) end)
        if self.textTemplate ~= nil then
            self.textTemplate:unlinkElement()
        end

        self.arrowTemplate = self:getFirstDescendant(function(element) return element:isa(BitmapElement) end)
        if self.arrowTemplate ~= nil then
            self.arrowTemplate:unlinkElement()
        end
    end
end


---
function BreadcrumbsElement:delete()
    if self.ownsTemplates then
        if self.textTemplate ~= nil then
            self.textTemplate:delete()
        end

        if self.arrowTemplate ~= nil then
            self.arrowTemplate:delete()
        end
    end

    BreadcrumbsElement:superClass().delete(self)
end
