








---
local NavigationSystem_mt = Class(NavigationSystem)












---
function NavigationSystem.new(customMt)
    local self = setmetatable({}, customMt or NavigationSystem_mt)

    self.navigationMarker = NavigationMarker.new()

    self.positionNode = nil
    self.directionNode = nil

    return self
end


---Load data on map load
-- @return boolean true if loading was successful else false
function NavigationSystem:loadMapData(xmlFile, missionInfo, baseDirectory)

    local filepath = Utils.getFilename("$data/shared/assets/marker/navigationMarker.i3d", baseDirectory)
    self.loadRequestId = g_i3DManager:loadI3DFileAsync(filepath, true, true, self.onNavigationMarkerLoaded, self, nil)

    return true
end


---
function NavigationSystem:onNavigationMarkerLoaded(i3dNode, failedReason, args)
    if failedReason == LoadI3DFailedReason.NONE then
        self.positionNode = getChildAt(i3dNode, 0)
        self.directionNode = getChildAt(self.positionNode, 0)
        setVisibility(self.positionNode, false)
        setVisibility(self.directionNode, false)
        link(getRootNode(), self.positionNode)

        self:updateMarker()

        delete(i3dNode)
    end

    self.loadRequestId = nil
end


---
function NavigationSystem:delete()
    if self.loadRequestId ~= nil then
        g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
        self.loadRequestId = nil
    end

    if self.positionNode ~= nil then
        delete(self.positionNode)
        self.positionNode = nil
    end

    self.navigationMarker:delete()
end


---
function NavigationSystem:saveToXMLFile(xmlFilename)
    local xmlFile = XMLFile.create("navigationSystem", xmlFilename, "navigationSystem", NavigationSystem.xmlSchema)

    if self.targetX ~= nil then
        xmlFile:setValue("navigationSystem.target#position", self.targetX, self.targetY, self.targetZ)

        if self.targetDirX ~= nil then
            xmlFile:setValue("navigationSystem.target#direction", self.targetDirX, self.targetDirY, self.targetDirZ)
        end
    end

    xmlFile:save()
    xmlFile:delete()
end


---
function NavigationSystem:updateMarker()
    local isActive = self.targetX ~= nil
    local isActiveDir = self.targetDirX ~= nil

    self.navigationMarker:setVisibility(isActive)

    if self.positionNode~= nil then
        setVisibility(self.positionNode, isActive)
        setVisibility(self.directionNode, isActiveDir)

        setWorldTranslation(self.positionNode, self.targetX or 0, self.targetY or 0, self.targetZ or 0)

        if self.targetDirX ~= nil then
            setVisibility(self.directionNode, true)
            setWorldDirection(self.directionNode, self.targetDirX, self.targetDirY, self.targetDirZ, 0, 1, 0)
        end
    end
end


---
function NavigationSystem:draw()
    self.navigationMarker:render()
end


---
function NavigationSystem:navigateTo(x, y, z, dirX, dirY, dirZ)
    self.navigationMarker:setWorldPosition(x, y + 1.4, z)
    self.navigationMarker:setVisibility(true)

    self.targetX = x
    self.targetY = y
    self.targetZ = z

    self.targetDirX = dirX
    self.targetDirY = dirY
    self.targetDirZ = dirZ

    g_currentMission:addDrawable(self)

    self:updateMarker()
end


---
function NavigationSystem:stop()
    self.targetX = nil
    self.targetY = nil
    self.targetZ = nil

    self.targetDirX = nil
    self.targetDirY = nil
    self.targetDirZ = nil

    g_currentMission:removeDrawable(self)

    self:updateMarker()
end
