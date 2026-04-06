














---Animated image display element.
-- The animation is created by shifting UV texture coordinates per frame across a suitable texture.
-- 
-- Used layers: "image" for the display image.
local AnimationElement_mt = Class(AnimationElement, BitmapElement)









---
function AnimationElement.new(target, custom_mt)
    local self = BitmapElement.new(target, custom_mt or AnimationElement_mt)

    self.animationMode = AnimationElement.MODE.UV_SHIFT

    self.animationOffset = -1
    self.animationFrames = 8
    self.animationTimer = 0
    self.animationSpeed = 120
    self.animationFrameSize = 0
    self.animationStartPos = 0
    self.animationUVOffset = 0
    self.animationRotation = 0
    self.animationRotationPivot = nil

    return self
end


---
function AnimationElement:loadFromXML(xmlFile, key)
    AnimationElement:superClass().loadFromXML(self, xmlFile, key)

    self.animationOffset = getXMLInt(xmlFile, key.."#animationOffset") or self.animationOffset
    self.animationFrames = getXMLInt(xmlFile, key.."#animationFrames") or self.animationFrames
    self.animationSpeed = getXMLInt(xmlFile, key.."#animationSpeed") or self.animationSpeed
    self.animationRotationPivot = string.getVector(getXMLString(xmlFile, key .. "#animationRotationPivot"), 2) or self.animationRotationPivot

    local animationUVOffset = getXMLString(xmlFile, key.."#animationUVOffset")
    if animationUVOffset ~= nil then
        animationUVOffset = GuiUtils.getNormalizedValues(animationUVOffset, self.imageSize)
        self.animationUVOffset = animationUVOffset[1]
    end

    local uvs = GuiOverlay.getOverlayUVs(self.overlay, self:getOverlayState())
    self.animationDefaultUVs = table.clone(uvs)

    local mode = getXMLString(xmlFile, key .. "#animationMode")
    if mode ~= nil then
        if mode:lower() == "uvshift" then
            self.animationMode = AnimationElement.MODE.UV_SHIFT
        else
            self.animationMode = AnimationElement.MODE.ROTATE
        end
    end

    self:setAnimationData()
end


---
function AnimationElement:loadProfile(profile, applyProfile)
    AnimationElement:superClass().loadProfile(self, profile, applyProfile)

    self.animationOffset = profile:getNumber("animationOffset", self.animationOffset)
    self.animationFrames = profile:getNumber("animationFrames", self.animationFrames)
    self.animationSpeed = profile:getNumber("animationSpeed", self.animationSpeed)
    self.animationRotationPivot = string.getVector(profile:getValue("animationRotationPivot"), 2) or self.animationRotationPivot

    local animationUVOffset = profile:getValue("animationUVOffset")
    if animationUVOffset ~= nil then
        animationUVOffset = GuiUtils.getNormalizedValues(animationUVOffset, self.imageSize)
        self.animationUVOffset = animationUVOffset[1]
    end

    local mode = profile:getValue("animationMode")
    if mode ~= nil then
        if mode:lower() == "uvshift" then
            self.animationMode = AnimationElement.MODE.UV_SHIFT
        else
            self.animationMode = AnimationElement.MODE.ROTATE
        end
    end
end


---
function AnimationElement:copyAttributes(src)
    AnimationElement:superClass().copyAttributes(self, src)

    self.animationDefaultUVs = table.clone(src.animationDefaultUVs)
    self.animationOffset = src.animationOffset
    self.animationFrames = src.animationFrames
    self.animationSpeed = src.animationSpeed
    self.animationUVOffset = src.animationUVOffset
    self.animationMode = src.animationMode

    self:setImageUVs(nil, unpack(self.animationDefaultUVs))

    self:setAnimationData()
end


---
function AnimationElement:update(dt)
    AnimationElement:superClass().update(self, dt)

    if self.animationMode == AnimationElement.MODE.UV_SHIFT then
        self.animationTimer = self.animationTimer - dt
        if self.animationTimer < 0 then
            self.animationTimer = self.animationSpeed
            self.animationOffset = self.animationOffset + 1

            if self.animationOffset > self.animationFrames - 1 then
                self.animationOffset = 0
            end

            self:updateAnimationUVs()
        end
    elseif self.animationMode == AnimationElement.MODE.ROTATE then
        self.animationRotation = self.animationRotation - 2 * math.pi * (dt / self.animationSpeed)

        self:updateRotation()
    end
end


---
function AnimationElement:updateAnimationUVs()
    if self.animationMode == AnimationElement.MODE.UV_SHIFT then
        local frameOffset = self.animationStartPos + (self.animationFrameSize+self.animationUVOffset)*self.animationOffset
        self:setImageUVs(nil, frameOffset, nil, frameOffset, nil, frameOffset+self.animationFrameSize, nil, frameOffset+self.animationFrameSize, nil)
    end
end


---Update overlay rotation
function AnimationElement:updateRotation()
    local pivot = self.pivot
    if self.animationRotationPivot ~= nil then
        pivot = self.animationRotationPivot
    end
    local x = self.absSize[1] * pivot[1]
    local y = self.absSize[2] * pivot[2]
    GuiOverlay.setRotation(self.overlay, self.animationRotation, x, y)
end


---
function AnimationElement:setAnimationData()
    if self.overlay ~= nil then
        local uvs = GuiOverlay.getOverlayUVs(self.overlay, self:getOverlayState())
        self.animationFrameSize = ((uvs[5]-uvs[1]- self.animationUVOffset*(self.animationFrames-1)) / self.animationFrames)
        self.animationStartPos = uvs[1]
        self:updateAnimationUVs()
    end
end
