










---
local ForestryHook_mt = Class(ForestryHook)


---
function ForestryHook.new(vehicle, linkNode, customMt)
    local self = setmetatable({}, customMt or ForestryHook_mt)

    self.vehicle = vehicle
    self.linkNode = linkNode
    self.x, self.y, self.z = 0, 0, 0
    self.rx, self.ry, self.rz = 0, 0, 0

    self.visibility = true

    self.targetNode = nil
    self.validTarget = false
    self.tx, self.ty, self.tz = 0, 0, 0

    self.rotationNodes = {}

    return self
end


---
function ForestryHook.registerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.STRING, baseKey .. "#filename", "Path to hook xml file", "$data/shared/forestry/treeHook01.xml")
end


---
function ForestryHook:isValid()
    return self.i3dFilename ~= nil
end


---
function ForestryHook:loadFromXML(xmlFile, key, baseDirectory)
    self.xmlFilename = xmlFile:getValue(key .. "#filename", "$data/shared/forestry/treeHook01.xml")
    if self.xmlFilename ~= nil then
        self.xmlFilename = Utils.getFilename(self.xmlFilename, baseDirectory)

        self.hookXMLFile = XMLFile.load("hookXMLFile", self.xmlFilename)
        if self.hookXMLFile ~= nil then
            self.i3dFilename = self.hookXMLFile:getString("forestryHook.filename", "$data/shared/forestry/treeHook01.i3d")
            if self.i3dFilename ~= nil then
                self.i3dFilename = Utils.getFilename(self.i3dFilename, baseDirectory)
                if self.vehicle ~= nil then
                    self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
                else
                    self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
                end
            end
        end
    end
end


---
function ForestryHook:loadFromConfigXML(xmlFile)
    xmlFile:iterate("forestryHook.rotationNode", function(index, key)
        local rotationNode = {}
        rotationNode.node = XMLValueType.getXMLNode(xmlFile.handle, key .. "#node", nil, self.hookId, nil)
        if rotationNode.node ~= nil then
            rotationNode.alignYRot = xmlFile:getBool(key .. "#alignYRot", false)
            rotationNode.alignXRot = xmlFile:getBool(key .. "#alignXRot", false)
            rotationNode.minYRot = math.rad(xmlFile:getFloat(key .. "#minYRot", -180))
            rotationNode.maxYRot = math.rad(xmlFile:getFloat(key .. "#maxYRot", 180))
            rotationNode.minXRot = math.rad(xmlFile:getFloat(key .. "#minXRot", -180))
            rotationNode.maxXRot = math.rad(xmlFile:getFloat(key .. "#maxXRot", 180))
            rotationNode.alignToTarget = xmlFile:getBool(key .. "#alignToTarget", true)

            rotationNode.referenceFrame = createTransformGroup("hookNodeReferenceFrame")
            link(getParent(rotationNode.node), rotationNode.referenceFrame)
            setTranslation(rotationNode.referenceFrame, getTranslation(rotationNode.node))
            setRotation(rotationNode.referenceFrame, getRotation(rotationNode.node))

            table.insert(self.rotationNodes, rotationNode)
        end
    end)

    self.ropeTarget = XMLValueType.getXMLNode(xmlFile.handle, "forestryHook.ropeTarget#node", nil, self.hookId, nil)

    self.treeBelt = {}
    self.treeBelt.offset = xmlFile:getFloat("forestryHook.treeBelt#offset", 0.01)
    self.treeBelt.maxDeltaY = xmlFile:getFloat("forestryHook.treeBelt#maxDeltaY", 0.075)
    self.treeBelt.spacing = xmlFile:getFloat("forestryHook.treeBelt#spacing", 0.0025)
    self.treeBelt.tensionBeltType = xmlFile:getString("forestryHook.treeBelt#tensionBeltType", "forestryTreeBelt")
    self.treeBelt.beltData = g_tensionBeltManager:getBeltData(self.treeBelt.tensionBeltType)

    self.treeBelt.dynamicBeltSpacing = {}
    self.treeBelt.dynamicBeltSpacing.isActive = xmlFile:getBool("forestryHook.treeBelt.dynamicBeltSpacing#isActive", false)
    self.treeBelt.dynamicBeltSpacing.minRadius = xmlFile:getFloat("forestryHook.treeBelt.dynamicBeltSpacing#minRadius", 0.1)
    self.treeBelt.dynamicBeltSpacing.maxRadius = xmlFile:getFloat("forestryHook.treeBelt.dynamicBeltSpacing#maxRadius", 0.5)
    self.treeBelt.dynamicBeltSpacing.minSpacing = xmlFile:getFloat("forestryHook.treeBelt.dynamicBeltSpacing#minSpacing", 0.01)
    self.treeBelt.dynamicBeltSpacing.maxSpacing = xmlFile:getFloat("forestryHook.treeBelt.dynamicBeltSpacing#maxSpacing", 0.1)

    self.treeBelt.dynamicBeltSpacing.adjustmentNodes = {}
    xmlFile:iterate("forestryHook.treeBelt.dynamicBeltSpacing.adjustmentNode", function(index, key)
        local nodeData = {}
        nodeData.node = XMLValueType.getXMLNode(xmlFile.handle, key .. "#node", nil, self.hookId, nil)
        if nodeData.node ~= nil then
            nodeData.minRot = XMLValueType.getXMLVector3Angle(xmlFile.handle, key .. "#minRot", nil, true)
            nodeData.maxRot = XMLValueType.getXMLVector3Angle(xmlFile.handle, key .. "#maxRot", nil, true)

            nodeData.minTrans = XMLValueType.getXMLVector3(xmlFile.handle, key .. "#minTrans", nil, true)
            nodeData.maxTrans = XMLValueType.getXMLVector3(xmlFile.handle, key .. "#maxTrans", nil, true)

            table.insert(self.treeBelt.dynamicBeltSpacing.adjustmentNodes, nodeData)
        end
    end)

    xmlFile:delete()
end


---
function ForestryHook:clone()
    local hookClone = ForestryHook.new(self.vehicle, self.linkNode)
    hookClone.xmlFilename = self.xmlFilename
    hookClone.i3dFilename = self.i3dFilename

    if hookClone.i3dFilename ~= nil then
        hookClone.hookXMLFile = XMLFile.load("hookXMLFile", hookClone.xmlFilename)
        local i3dNode, sharedLoadRequestId, failedReason = g_i3DManager:loadSharedI3DFile(hookClone.i3dFilename, false, false) -- load file in sync since it's cached already
        hookClone.sharedLoadRequestId = sharedLoadRequestId
        hookClone:onI3DLoaded(i3dNode, failedReason)
        return hookClone
    end
end


---
function ForestryHook:delete()
    g_currentMission:removeUpdateable(self)

    if self.hookId ~= nil then
        -- do entityExists checks here in case the hook was deleted with the tree it was attached (e.g. cutting)
        if entityExists(self.hookId) then
            delete(self.hookId)
        end

        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
    end

    if self.beltShape ~= nil and entityExists(self.beltShape) then
        delete(self.beltShape)
    end

    if self.splitShapeId ~= nil and entityExists(self.splitShapeId) then
        if getRigidBodyType(self.splitShapeId) == RigidBodyType.STATIC then
            I3DUtil.setShaderParameterRec(self.splitShapeId, "windSnowLeafScale", 1, nil, nil, nil)
        end

        self.splitShapeId = nil
    end
end


---
function ForestryHook:update(dt)
    if self.targetNode ~= nil and entityExists(self.targetNode) then
        self.tx, self.ty, self.tz = getWorldTranslation(self.targetNode)
    end

    if entityExists(self.hookId) then
        if self.validTarget then
            local tx, ty, tz = self.tx, self.ty, self.tz
            for j=1, #self.rotationNodes do
                local rotationNode = self.rotationNodes[j]
                if rotationNode.alignYRot then
                    local x, _, z = worldToLocal(rotationNode.referenceFrame, tx, ty, tz)
                    x, z = MathUtil.vector2Normalize(x, z)
                    local angle = math.clamp(math.atan2(x, z), rotationNode.minYRot, rotationNode.maxYRot)
                    local rx, _, _ = getRotation(rotationNode.node)
                    setRotation(rotationNode.node, rx, angle, 0)
                end
                if rotationNode.alignXRot then
                    local _, y, z = worldToLocal(rotationNode.referenceFrame, tx, ty, tz)
                    y, z = MathUtil.vector2Normalize(y, z)
                    local angle = math.clamp(-math.atan2(y, z), rotationNode.minXRot, rotationNode.maxXRot)
                    local _, ry, _ = getRotation(rotationNode.node)
                    setRotation(rotationNode.node, angle, ry, 0)
                end

                if not rotationNode.alignYRot and not rotationNode.alignXRot and rotationNode.alignToTarget then
                    local x, y, z = worldToLocal(rotationNode.referenceFrame, tx, ty, tz)
                    x, y, z = MathUtil.vector3Normalize(x, y, z)
                    setDirection(rotationNode.node, x, y, z, 0, 1, 0)
                end
            end
        end
    else
        g_currentMission:removeUpdateable(self)
    end
end


---
function ForestryHook:setTargetNode(nodeId, isActiveDirty)
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
function ForestryHook:setTargetPosition(x, y, z)
    self.tx, self.ty, self.tz = x, y, z
    self.validTarget = true
    self:update(9999)
end


---
function ForestryHook:link(node, x, y, z, rx, ry, rz)
    self.linkNode = node
    self.x, self.y, self.z = x or self.x, y or self.y, z or self.z
    self.rx, self.ry, self.rz = rx or self.rx, ry or self.ry, rz or self.rz

    if self.hookId ~= nil then
        link(self.linkNode, self.hookId)
        setVisibility(self.hookId, self.visibility)
        setTranslation(self.hookId, self.x, self.y, self.z)
        setRotation(self.hookId, self.rx, self.ry, self.rz)
    end
end


---
function ForestryHook:setPositionAndDirection(x, y, z, dx, dz)
    self.x, self.y, self.z = worldToLocal(self.linkNode, x, y, z)
    self.rx, self.ry, self.rz = worldRotationToLocal(self.linkNode, 0, MathUtil.getYRotationFromDirection(dx, dz), 0)

    if self.hookId ~= nil then
        link(self.linkNode, self.hookId)
        setVisibility(self.hookId, self.visibility)
        setTranslation(self.hookId, self.x, self.y, self.z)
        setRotation(self.hookId, self.rx, self.ry, self.rz)
    end
end































---
function ForestryHook:mountToTree(splitShapeId, x, y, z, maxRadius, tx, ty, tz)
    local cx, cy, cz, upX, upY, upZ, radius = SplitShapeUtil.getTreeOffsetPosition(splitShapeId, x, y, z, 4)
    if cx == nil then
        return nil
    end

    tx, ty, tz = tx or x, ty or y, tz or z

    -- up right trees that are not split yet
    if getRigidBodyType(splitShapeId) == RigidBodyType.STATIC then
        local dx, dy, dz = MathUtil.vector3Normalize(tx-cx, ty-cy, tz-cz)
        tx, ty, tz = cx + dx * radius, cy + dy * radius, cz + dz * radius
        ty = math.clamp(ty, cy - self.treeBelt.maxDeltaY, cy + self.treeBelt.maxDeltaY)
        radius = radius + math.abs(cy - ty)

        I3DUtil.setShaderParameterRec(splitShapeId, "windSnowLeafScale", 0, nil, nil, nil)
    end

    local beltShape = SplitShapeUtil.createTreeBelt(self.treeBelt.beltData, splitShapeId, cx, cy, cz, tx, ty, tz, upX, upY, upZ, radius + self.treeBelt.offset, false, self:getBeltSpacing(radius))

    local wtx, wty, wtz = getWorldTranslation(beltShape)
    local wrx, wry, wrz = getWorldRotation(beltShape)
    link(splitShapeId, beltShape)
    setWorldTranslation(beltShape, wtx, wty, wtz)
    setWorldRotation(beltShape, wrx, wry, wrz)

    self:link(beltShape, 0, 0, 0, 0, 0, 0)
    self:updateDynamicSpacingNodes(radius)

    if self.beltShape ~= nil then
        delete(self.beltShape)
    end

    self.splitShapeId = splitShapeId
    self.beltShape = beltShape

    return cx, cy, cz
end


---
function ForestryHook:setVisibility(visibility)
    self.visibility = visibility
    if self.hookId ~= nil then
        setVisibility(self.hookId, self.visibility)
    end
end


---
function ForestryHook:getRopeTargetPosition()
    if self.ropeTarget ~= nil and entityExists(self.ropeTarget) then
        return getWorldTranslation(self.ropeTarget)
    end

    return 0, 0, 0
end


---
function ForestryHook:getRopeTarget()
    return self.ropeTarget or self.hookId or self.linkNode
end


---
function ForestryHook:onI3DLoaded(i3dNode, failedReason)
    if i3dNode ~= 0 then
        self.hookId = getChildAt(i3dNode, 0)
        link(self.linkNode, self.hookId)
        setVisibility(self.hookId, self.visibility)
        setTranslation(self.hookId, self.x, self.y, self.z)
        setRotation(self.hookId, self.rx, self.ry, self.rz)

        self:loadFromConfigXML(self.hookXMLFile)
        self:update(9999)

        delete(i3dNode)
    end
end
