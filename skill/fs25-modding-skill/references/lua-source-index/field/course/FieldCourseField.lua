











---
local FieldCourseField_mt = Class(FieldCourseField)




























































































































































































---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FieldCourseField:readStream(streamId, connection)
    self.boundaryPositions = {}
    local numBoundaryPositions = streamReadUIntN(streamId, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
    for i=1, numBoundaryPositions do
        local x, z = g_fieldCourseManager:readTerrainDetailPixel(streamId)
        table.insert(self.boundaryPositions, {x, z})
    end

    self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)

    self.islands = {}
    local numIslands = streamReadUIntN(streamId, FieldCourseField.NUM_ISLANDS_SYNC_BITS)
    for i=1, numIslands do
        local island = {}
        island.boundaries = {}
        island.hasCutSegments = false

        local boundaryLine = {}
        numBoundaryPositions = streamReadUIntN(streamId, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
        for j=1, numBoundaryPositions do
            local x, z = g_fieldCourseManager:readTerrainDetailPixel(streamId)
            table.insert(boundaryLine, {x, z})
        end

        island.rootBoundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)

        table.insert(self.islands, island)
    end

    self.state = FieldCourseDetectionState.FINISHED
end
