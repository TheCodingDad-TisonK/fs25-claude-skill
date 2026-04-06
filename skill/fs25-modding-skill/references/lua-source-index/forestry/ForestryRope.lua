










---
local ForestryRope_mt = Class(ForestryRope)


---
function ForestryRope.new(vehicle, linkNode, customMt)
    local self = setmetatable({}, customMt or ForestryRope_mt)

    self.vehicle = vehicle
    self.linkNode = linkNode
    self.x, self.y, self.z = 0, 0, 0
    self.rx, self.ry, self.rz = 0, 0, 0

    self.visibility = true

    self.targetNode = nil
    self.tx, self.ty, self.tz = 0, 0, 0
    self.validTarget = false

    self.boundingRadius = 1

    return self
end


---
function ForestryRope.registerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.STRING, baseKey .. "#filename", "Path to rope i3d file", "$data/shared/forestry/ropes.i3d")
    schema:register(XMLValueType.STRING, baseKey .. "#ropeNode", "Path to rope i3d file", "0")
    schema:register(XMLValueType.FLOAT, baseKey .. "#diameter", "Diameter of the rope", 0.02)
    schema:register(XMLValueType.FLOAT, baseKey .. "#uvScale", "UV scale of the rope", 4)
    schema:register(XMLValueType.VECTOR_4, baseKey .. "#emissiveColor", "Emissive color", "0 0 0")
    schema:register(XMLValueType.VECTOR_4, baseKey .. "#invalidEmissiveColor", "Emissive color", "0 0 0")
end


---
function ForestryRope:loadFromXML(xmlFile, key, baseDirectory)
    self.i3dFilename = xmlFile:getValue(key .. "#filename", "$data/shared/forestry/ropes.i3d")
    self.i3dRopePath = xmlFile:getValue(key .. "#ropeNode", "0")
    self.diameter = xmlFile:getValue(key .. "#diameter", 0.02)
    self.uvScale = xmlFile:getValue(key .. "#uvScale", 4)
    self.emissiveColor = xmlFile:getValue(key .. "#emissiveColor", "0 0 0 0", true)
    self.invalidEmissiveColor = xmlFile:getValue(key .. "#invalidEmissiveColor", "0 0 0 0", true)

    if self.i3dFilename ~= nil then
        self.i3dFilename = Utils.getFilename(self.i3dFilename, baseDirectory)
        if self.vehicle ~= nil then
            self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
        else
            self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
        end
    end
end


---
function ForestryRope:loadFromConfigXML(xmlFile)
end


---
function ForestryRope:clone(linkNode)
    local ropeClone = ForestryRope.new(self.vehicle, linkNode or self.linkNode)
    ropeClone.i3dFilename = self.i3dFilename
    ropeClone.i3dRopePath = self.i3dRopePath
    ropeClone.diameter = self.diameter
    ropeClone.uvScale = self.uvScale
    ropeClone.emissiveColor = self.emissiveColor
    ropeClone.invalidEmissiveColor = self.invalidEmissiveColor

    if ropeClone.i3dFilename ~= nil then
        local i3dNode, sharedLoadRequestId, failedReason = g_i3DManager:loadSharedI3DFile(ropeClone.i3dFilename, false, false) -- load file in sync since it's cached already
        ropeClone.sharedLoadRequestId = sharedLoadRequestId
        ropeClone:onI3DLoaded(i3dNode, failedReason)
        return ropeClone
    end
end


---
function ForestryRope:delete()
    g_currentMission:removeUpdateable(self)

    -- do entityExists checks here in case the hook was deleted with the tree it was attached (e.g. cutting)
    if self.referenceFrame ~= nil then
        if entityExists(self.referenceFrame) then
            delete(self.referenceFrame)
        end

        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
    end
end


---
function ForestryRope:update(dt)
    if self.validTarget then
        if self.targetNode ~= nil then
            self.tx, self.ty, self.tz = getWorldTranslation(self.targetNode)
        end

        local dx, dy, dz = worldToLocal(self.referenceFrame, self.tx, self.ty, self.tz)
        local length = MathUtil.vector3Length(dx, dy, dz)
        dx, dy, dz = MathUtil.vector3Normalize(dx, dy, dz)
        setDirection(self.ropeId, dx, dy, dz, 0, 1, 0)
        self:setLength(length)
    end
end


---
function ForestryRope:setLength(length)
    if self.referenceFrame ~= nil then
        g_animationManager:setPrevShaderParameter(self.ropeId, "ropeLengthBendSizeUv", length, 0, self.diameter, self.uvScale, false, "prevRopeLengthBendSizeUv")

        local boundingRadius = math.max(math.ceil(length), 1) * 0.5
        if math.ceil(boundingRadius) ~= self.boundingRadius then
            setShapeBoundingSphere(self.ropeId, 0, 0, boundingRadius, boundingRadius)

            self.boundingRadius = boundingRadius
        end
    end
end


---
function ForestryRope:setTargetNode(nodeId, isActiveDirty)
    self.targetNode = nodeId
    self.tx, self.ty, self.tz = getWorldTranslation(self.targetNode)
    if isActiveDirty then
        g_currentMission:removeUpdateable(self)
        g_currentMission:addUpdateable(self)
    else
        g_currentMission:removeUpdateable(self)
    end

    self.validTarget = true
    self:update(9999)
end


---
function ForestryRope:setTargetPosition(x, y, z)
    self.tx, self.ty, self.tz = x, y, z
    self.validTarget = true
    self:update(9999)
end


---
function ForestryRope:link(node, x, y, z, rx, ry, rz)
    self.linkNode = node
    self.x, self.y, self.z = x or self.x, y or self.y, z or self.z
    self.rx, self.ry, self.rz = rx or self.rx, ry or self.ry, rz or self.rz

    if self.referenceFrame ~= nil then
        link(self.linkNode, self.referenceFrame)
        setVisibility(self.referenceFrame, self.visibility)
        setTranslation(self.referenceFrame, self.x, self.y, self.z)
        setRotation(self.referenceFrame, self.rx, self.ry, self.rz)
    end
end


---
function ForestryRope:setPositionAndDirection(x, y, z, dx, dz)
    self.x, self.y, self.z = worldToLocal(self.linkNode, x, y, z)
    if dx ~= nil and dz ~= nil then
        self.rx, self.ry, self.rz = worldRotationToLocal(self.linkNode, 0, MathUtil.getYRotationFromDirection(dx, dz), 0)
    end

    if self.referenceFrame ~= nil then
        link(self.linkNode, self.referenceFrame)
        setVisibility(self.referenceFrame, self.visibility)
        setTranslation(self.referenceFrame, self.x, self.y, self.z)
        setRotation(self.referenceFrame, self.rx, self.ry, self.rz)
    end
end


---
function ForestryRope:setVisibility(visibility)
    self.visibility = visibility
    if self.referenceFrame ~= nil then
        setVisibility(self.referenceFrame, self.visibility)
    end
end


---
function ForestryRope:setEmissiveColor(valid)
    if self.ropeId ~= nil then
        local color = valid and self.emissiveColor or self.invalidEmissiveColor
        setShaderParameter(self.ropeId, "ropeEmissiveColor", color[1], color[2], color[3], color[4], false)
    end
end


---
function ForestryRope:onI3DLoaded(i3dNode, failedReason)
    if i3dNode ~= 0 then
        self.ropeId = I3DUtil.indexToObject(i3dNode, self.i3dRopePath)
        if self.ropeId ~= nil then
            self.referenceFrame = createTransformGroup("ropeReferenceFrame")
            link(self.referenceFrame, self.ropeId)
            link(self.linkNode, self.referenceFrame)
            setVisibility(self.referenceFrame, self.visibility)
            setTranslation(self.referenceFrame, self.x, self.y, self.z)
            setRotation(self.referenceFrame, self.rx, self.ry, self.rz)

            setShaderParameter(self.ropeId, "ropeEmissiveColor", self.emissiveColor[1], self.emissiveColor[2], self.emissiveColor[3], self.emissiveColor[4], false)

            self:update(9999)
        end

        delete(i3dNode)
    end
end
