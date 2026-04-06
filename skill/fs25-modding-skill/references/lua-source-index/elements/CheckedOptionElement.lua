












---Two-value on/off state input element.
local CheckedOptionElement_mt = Class(CheckedOptionElement, MultiTextOptionElement)





---
function CheckedOptionElement.new(target, custom_mt)
    local self = MultiTextOptionElement.new(target, custom_mt or CheckedOptionElement_mt)

    return self
end


---
function CheckedOptionElement:addElement(element)
    CheckedOptionElement:superClass().addElement(self, element)

    if #self.elements == 3 then
        self:setTexts({g_i18n:getText("ui_off"), g_i18n:getText("ui_on")})
        self:setIsChecked(self.isChecked)
    end
end


---Get whether the element is checked
function CheckedOptionElement:getIsChecked()
    return self.state == CheckedOptionElement.STATE_CHECKED
end


---Set whether the element is checked
function CheckedOptionElement:setIsChecked(isChecked)
    if isChecked then
        self:setState(CheckedOptionElement.STATE_CHECKED)
    else
        self:setState(CheckedOptionElement.STATE_UNCHECKED)
    end
end
