










---
local InputGlyphElementUI_mt = Class(InputGlyphElementUI, GuiElement)




---
function InputGlyphElementUI.new(target, custom_mt)
    local self = GuiElement.new(target, custom_mt or InputGlyphElementUI_mt)

    self.glyphColor = {1, 1, 1, 1}
    self.buttonGlyphColor = {1, 1, 1, 1}
    self.glyphBackgroundColor = {0.00913, 0.01033, 0.00651, 1}
    self.isLeftAligned = false

    self.actionNames = {}

    return self
end


---
function InputGlyphElementUI:delete()
    if self.glyphElement ~= nil then
        self.glyphElement:delete()
        self.glyphElement = nil
    end

    InputGlyphElementUI:superClass().delete(self)
end


---
function InputGlyphElementUI:loadFromXML(xmlFile, key)
    InputGlyphElementUI:superClass().loadFromXML(self, xmlFile, key)

    self.glyphColor = GuiUtils.getColorArray(getXMLString(xmlFile, key.."#glyphColor"), self.glyphColor)
    self.buttonGlyphColor = GuiUtils.getColorArray(getXMLString(xmlFile, key.."#buttonGlyphColor"), self.buttonGlyphColor)
    self.glyphBackgroundColor = GuiUtils.getColorArray(getXMLString(xmlFile, key.."#glyphBackgroundColor"), self.glyphBackgroundColor)
    self.isLeftAligned = Utils.getNoNil(getXMLBool(xmlFile, key.."#isLeftAligned"), self.isLeftAligned)

    self:buildGlyph()

    local actionNames = {}

    local actionName = getXMLString(xmlFile, key .. "#inputAction")
    if actionName ~= nil and InputAction[actionName] ~= nil then
        table.insert(actionNames, actionName)

        local actionName2 = getXMLString(xmlFile, key .. "#inputAction2")
        if actionName2 ~= nil and InputAction[actionName2] ~= nil then
            table.insert(actionNames, actionName2)
        end

        self.actionNames = table.clone(actionNames)

        self:setActions(actionNames, nil, nil, nil)
    end
end


---
function InputGlyphElementUI:loadProfile(profile, applyProfile)
    InputGlyphElementUI:superClass().loadProfile(self, profile, applyProfile)

    self.glyphColor = GuiUtils.getColorArray(profile:getValue("glyphColor"), self.glyphColor)
    self.buttonGlyphColor = GuiUtils.getColorArray(profile:getValue("buttonGlyphColor"), self.buttonGlyphColor)
    self.glyphBackgroundColor = GuiUtils.getColorArray(profile:getValue("glyphBackgroundColor"), self.glyphBackgroundColor)
    self.isLeftAligned = Utils.getNoNil(profile:getBool("isLeftAligned"), self.isLeftAligned)

    self:buildGlyph()

    local actionNames = {}

    local actionName = profile:getValue("inputAction", self.inputActionName)
    if actionName ~= nil and InputAction[actionName] ~= nil then
        table.insert(actionNames, actionName)

        local actionName2 = profile:getValue("inputAction2", self.inputActionName)
        if actionName2 ~= nil and InputAction[actionName2] ~= nil then
            table.insert(actionNames, actionName2)
        end

        self.actionNames = table.clone(actionNames)

        self:setActions(actionNames, nil, nil, nil)
    end
end


---
function InputGlyphElementUI:copyAttributes(src)
    InputGlyphElementUI:superClass().copyAttributes(self, src)

    self.glyphColor = table.clone(src.glyphColor)
    self.buttonGlyphColor = table.clone(src.buttonGlyphColor)
    self.glyphBackgroundColor = table.clone(src.glyphBackgroundColor)
    self.isLeftAligned = src.isLeftAligned

    local actionNames = table.clone(src.actionNames)
    self.actionNames = table.clone(actionNames)

    if src.glyphElement ~= nil then
        self:buildGlyph()

        if #actionNames > 0 then
            self:setActions(actionNames, nil, nil, nil)
        end
    end
end































---Draw the glyph
function InputGlyphElementUI:draw(clipX1, clipY1, clipX2, clipY2)
    InputGlyphElementUI:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)

    if self.glyphElement ~= nil then
        self.glyphElement:draw(clipX1, clipY1, clipX2, clipY2)
    end
end


---Set glyph actions
function InputGlyphElementUI:setActions(actions, actionText, actionTextSize, noModifiers, customBinding)
    if self.glyphElement ~= nil then
        self.glyphElement:setActions(actions, actionText, actionTextSize, noModifiers, customBinding)

        if not self.didSetAbsolutePosition then
            self:updateAbsolutePosition()
        end

        if self.originalWidth == nil then
            self.originalWidth = self.absSize[1]
        end

        self.glyphElement:setBaseSize(self.originalWidth, self.absSize[2])

        self:setSize(self.glyphElement:getGlyphWidth())

        if self.parent ~= nil and self.parent.invalidateLayout ~= nil then
            self.parent:invalidateLayout()
        end
    end
end
