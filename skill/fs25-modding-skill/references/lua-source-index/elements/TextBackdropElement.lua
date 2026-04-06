









---Element that sizes depending on the size of its child text element
local TextBackdropElement_mt = Class(TextBackdropElement, BitmapElement)




---
function TextBackdropElement.new(target, custom_mt)
    local self = BitmapElement.new(target, custom_mt or TextBackdropElement_mt)

    self.padding = {0, 0, 0, 0} -- left, top, right, bottom

    return self
end


---
function TextBackdropElement:loadFromXML(xmlFile, key)
    TextBackdropElement:superClass().loadFromXML(self, xmlFile, key)

    self.padding = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#padding"), self.padding)
end


---
function TextBackdropElement:loadProfile(profile, applyProfile)
    TextBackdropElement:superClass().loadProfile(self, profile, applyProfile)

    self.padding = GuiUtils.getNormalizedScreenValues(profile:getValue("padding"), self.padding)
end


---
function TextBackdropElement:copyAttributes(src)
    TextBackdropElement:superClass().copyAttributes(self, src)

    self.padding = table.clone(src.padding)
end
