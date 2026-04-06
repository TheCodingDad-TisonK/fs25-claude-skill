









---
local TargetTreeMarker_mt = Class(TargetTreeMarker)


---
function TargetTreeMarker.new(vehicle, linkNode, customMt)
    local self = setmetatable({}, customMt or TargetTreeMarker_mt)

    self.vehicle = vehicle
    self.linkNode = linkNode

    self.isActive = false
    self.isFlashing = false
    self.flashingMinIntensity = 0.1
    self.flashingTime = 0

    return self
end


---
function TargetTreeMarker.registerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.STRING, baseKey .. "#filename", "Path to tree marker file", "$data/shared/forestry/targetTreeMarker.i3d")
    schema:register(XMLValueType.FLOAT, baseKey .. "#width", "Marker width", 0.05)
    schema:register(XMLValueType.FLOAT, baseKey .. "#offset", "Marker offset from tree", 0.01)
    schema:register(XMLValueType.COLOR, baseKey .. "#color", "Marker emissive color", "0 2 0")
end


---
function TargetTreeMarker:loadFromXML(xmlFile, key, baseDirectory)
    self.filename = xmlFile:getValue(key .. "#filename", "$data/shared/forestry/targetTreeMarker.i3d")
    self.width = xmlFile:getValue(key .. "#width", 0.05)
    self.offset = xmlFile:getValue(key .. "#offset", 0.01)
    self.color = xmlFile:getValue(key .. "#color", "0 2 0", true)

    if self.filename ~= nil then
        self.filename = Utils.getFilename(self.filename, baseDirectory)
        if self.vehicle ~= nil then
            self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onI3DLoaded, self, self)
        else
            self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.filename, false, false, self.onI3DLoaded, self, self)
        end
    end
end


---
function TargetTreeMarker:delete()
    if self.markerId ~= nil then
        delete(self.markerId)
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
    end

    g_currentMission:removeUpdateable(self)
end


---
function TargetTreeMarker:setIsActive(isActive)
    self.isActive = isActive
    if self.markerId ~= nil then
        setVisibility(self.markerId, isActive)
    end
end


---
function TargetTreeMarker:setColor(r, g, b, isFlashing, flashingMinIntensity)
    self.color[1], self.color[2], self.color[3] = r, g, b
    if self.markerId ~= nil then
        setShaderParameter(self.markerId, "ropeEmissiveColor", self.color[1], self.color[2], self.color[3], 1, false)
    end

    if isFlashing ~= nil and isFlashing ~= self.isFlashing then
        self.isFlashing = isFlashing
        self.flashingMinIntensity = flashingMinIntensity or self.flashingMinIntensity

        if self.isFlashing then
            self.flashingTime = 0
            g_currentMission:removeUpdateable(self)
            g_currentMission:addUpdateable(self)
        else
            g_currentMission:removeUpdateable(self)
        end
    end
end


---
function TargetTreeMarker:update(dt)
    if self.markerId ~= nil then
        self.flashingTime = self.flashingTime + dt
        local alpha = math.sin((self.flashingTime * 0.005) % math.pi) * (1-self.flashingMinIntensity) + self.flashingMinIntensity
        setShaderParameter(self.markerId, "ropeEmissiveColor", self.color[1] * alpha, self.color[2] * alpha, self.color[3] * alpha, alpha, false)
    end
end


---
function TargetTreeMarker:setPosition(x, y, z, dx, dy, dz, radius, offset)
    if self.markerId ~= nil then
        offset = offset or (-self.width * 0.5)
        setWorldTranslation(self.markerId, x + dx * offset, y + dy * offset, z + dz * offset)
        I3DUtil.setWorldDirection(self.markerId, dx, dy, dz, 0, 1, 0)
        g_animationManager:setPrevShaderParameter(self.markerId, "ropeLengthBendSizeUv", self.width, 0, radius * 2, 1, false, "prevRopeLengthBendSizeUv")
    end
end


---
function TargetTreeMarker:onI3DLoaded(i3dNode, failedReason)
    if i3dNode ~= 0 then
        self.markerId = getChildAt(getChildAt(i3dNode, 0), 0)
        link(self.linkNode, self.markerId)
        setVisibility(self.markerId, self.isActive)
        setShaderParameter(self.markerId, "ropeEmissiveColor", self.color[1], self.color[2], self.color[3], 1, false)

        delete(i3dNode)
    end
end
