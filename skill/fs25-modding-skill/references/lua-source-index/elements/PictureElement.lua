













---Displays an image with content sizing constraints
local PictureElement_mt = Class(PictureElement, BitmapElement)













---
function PictureElement.new(target, custom_mt)
    local self = BitmapElement.new(target, custom_mt or PictureElement_mt)

    self.contentMode = PictureElement.CONTENT_MODE.SCALE_ASPECT_FIT

    self.imageSize = {2048, 2048}
    self.aspectRatio = 1

    return self
end


---
function PictureElement:loadFromXML(xmlFile, key)
    PictureElement:superClass().loadFromXML(self, xmlFile, key)

    self.imageSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key.."#imageSize"), self.imageSize)
    self.aspectRatio = self.imageSize[1] / self.imageSize[2]
end


---
function PictureElement:loadProfile(profile, applyProfile)
    PictureElement:superClass().loadProfile(self, profile, applyProfile)

    self.imageSize = GuiUtils.getNormalizedScreenValues(profile:getValue("imageSize"), self.imageSize)
    self.aspectRatio = self.imageSize[1] / self.imageSize[2]

    local mode = profile:getValue("pictureContentMode")
    if mode == "noScaling" then
        self.contentMode = PictureElement.CONTENT_MODE.NO_SCALING
    elseif mode == "scaleToFill" then
        self.contentMode = PictureElement.CONTENT_MODE.SCALE_TO_FILL
    elseif mode == "scaleAspectFit" then
        self.contentMode = PictureElement.CONTENT_MODE.SCALE_ASPECT_FIT
    end
end


---
function PictureElement:copyAttributes(src)
    PictureElement:superClass().copyAttributes(self, src)

    self.contentMode = src.contentMode
    self.aspectRatio = src.aspectRatio
    self.imageSize = src.imageSize
end




















































---
function PictureElement:draw(clipX1, clipY1, clipX2, clipY2)
    local x, y, width, height = self:getAdjustedPosition()

    GuiOverlay.renderOverlay(self.overlay, self.absPosition[1] + x, self.absPosition[2] + y, width, height, self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)

    if self.debugEnabled or g_uiDebugEnabled then
        drawFilledRect(self.absPosition[1] - g_pixelSizeX + x, self.absPosition[2] - g_pixelSizeY + y, width + 2 * g_pixelSizeX, g_pixelSizeY, 1, 1, 0, 1)
        drawFilledRect(self.absPosition[1] - g_pixelSizeX + x, self.absPosition[2] + height + y, width + 2 * g_pixelSizeX, g_pixelSizeY, 1, 1, 0, 1)
        drawFilledRect(self.absPosition[1] - g_pixelSizeX + x, self.absPosition[2] + y, g_pixelSizeX, height, 1, 1, 0, 1)
        drawFilledRect(self.absPosition[1] + width + x, self.absPosition[2] + y, g_pixelSizeX, height, 1, 1, 0, 1)
    end

    -- Skip over superclass
    PictureElement:superClass():superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
