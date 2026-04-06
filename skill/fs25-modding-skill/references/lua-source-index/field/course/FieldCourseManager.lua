






























---
local FieldCourseManager_mt = Class(FieldCourseManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function FieldCourseManager.new(customMt)
    local self = AbstractManager.new(customMt or FieldCourseManager_mt)

    self.updateables = {}
    self.sortedUpdateables = {}

    return self
end


---Initialize data structures
function FieldCourseManager:initDataStructures()
end


---Load data on map load
-- @return boolean true if loading was successful else false
function FieldCourseManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    self.terrainDetailMapSize = g_currentMission.terrainDetailMapSize
    self.terrainDetailResolution = g_currentMission.terrainSize / self.terrainDetailMapSize
    self.terrainDetailMapNumBits = 1
    for i=1, 16 do
        if 2 ^ i == self.terrainDetailMapSize then
            self.terrainDetailMapNumBits = i
        end
    end

    if g_fieldCourseTool == nil then
        self.fieldCourseVisual = FieldCourseVisual.new()
    end
end


---
function FieldCourseManager:unloadMapData()
    if self.fieldCourseVisual ~= nil then
        self.fieldCourseVisual:delete()
        self.fieldCourseVisual = nil
    end

    for k, updateable in pairs(self.updateables) do
        if updateable.delete ~= nil then
            updateable:delete()
        end
        table.removeElement(self.sortedUpdateables, updateable)
        self.updateables[k] = nil
    end
end























---
function FieldCourseManager:update(dt)
    for i=#self.sortedUpdateables, 1, -1 do
        -- check if the updateable is still valid - can be removed already in some cases with async callbacks
        if self.sortedUpdateables[i] ~= nil then
            self.sortedUpdateables[i]:update(dt)
        end
    end
end


---
function FieldCourseManager:generateFieldCourseAtWorldPos(wx, wz, fieldCourseSettings, callback, callbackTarget)
    FieldCourse.generateByFieldPosition(wx, wz, fieldCourseSettings, function(fieldCourse)
        if fieldCourse ~= nil then
            callback(callbackTarget, fieldCourse)
        else
            callback(callbackTarget)
        end
    end)
end


---
function FieldCourseManager:setActiveSteeringFieldCourse(steeringFieldCourse, vehicle)
    if self.fieldCourseVisual ~= nil then
        self.fieldCourseVisual:setActiveSteeringFieldCourse(steeringFieldCourse, vehicle)
    end
end


---
function FieldCourseManager:roundToTerrainDetailPixel(wx, wz)
    local terrainDetailResolution = self.terrainDetailResolution

    -- round to the center of every pixel
    wx = MathUtil.round((wx - terrainDetailResolution * 0.25) / terrainDetailResolution) * terrainDetailResolution + terrainDetailResolution * 0.5
    wz = MathUtil.round((wz - terrainDetailResolution * 0.25) / terrainDetailResolution) * terrainDetailResolution + terrainDetailResolution * 0.5

    return wx, wz
end


---
function FieldCourseManager:writeTerrainDetailPixel(streamId, x, z)
    streamWriteUIntN(streamId, (x - self.terrainDetailResolution * 0.5) / self.terrainDetailResolution + self.terrainDetailMapSize * 0.5, self.terrainDetailMapNumBits)
    streamWriteUIntN(streamId, (z - self.terrainDetailResolution * 0.5) / self.terrainDetailResolution + self.terrainDetailMapSize * 0.5, self.terrainDetailMapNumBits)
end


---
function FieldCourseManager:readTerrainDetailPixel(streamId)
    local x = (streamReadUIntN(streamId, self.terrainDetailMapNumBits) - self.terrainDetailMapSize * 0.5) * self.terrainDetailResolution + self.terrainDetailResolution * 0.5
    local z = (streamReadUIntN(streamId, self.terrainDetailMapNumBits) - self.terrainDetailMapSize * 0.5) * self.terrainDetailResolution + self.terrainDetailResolution * 0.5

    return x, z
end
