












---
local Fence_mt = Class(Fence)


---
-- @param XMLSchema schema
-- @param string basePath
function Fence.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    schema:register(XMLValueType.STRING, basePath .. ".fence.segment(?)#id", "", nil, true)
    schema:register(XMLValueType.STRING, basePath .. ".fence.segment(?)#class", "", nil, true)
    FenceSegment.registerXMLPaths(schema, basePath .. ".fence.segment(?)")
    FenceGate.registerXMLPaths(schema, basePath .. ".fence.segment(?)")
end





---
-- @param XMLSchema schema
-- @param string basePath
function Fence.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".segment(?)#id", "Segment id from config xml")

    FenceSegment.registerSavegameXMLPaths(schema, basePath .. ".segment(?)")
    FenceGate.registerSavegameXMLPaths(schema, basePath .. ".segment(?)")
end




































































































---
function Fence:saveToXMLFile(xmlFile, key, usedModNames)
    local segmentXMLIndex = 0
    for _, segment in ipairs(self.segments) do
        if segment.needsSaving == nil or segment.needsSaving == true then
            local segmentKey = string.format("%s.segment(%d)", key, segmentXMLIndex)
            if segment:saveToXMLFile(xmlFile, segmentKey) then
                xmlFile:setValue(segmentKey .. "#id", segment:getId())
                segmentXMLIndex = segmentXMLIndex + 1
            end
        end
    end
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Fence:readStream(streamId, connection)
    local numSegments = streamReadUInt16(streamId)
    for i=1, numSegments do
        local segmentTemplateIndex = streamReadUInt8(streamId)
        local segment = self:createNewSegment(self.segmentTemplatesSorted[segmentTemplateIndex])

        segment:readStream(streamId, connection)
        segment:updateMeshes(true)
        segment:finalize()
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Fence:writeStream(streamId, connection)
    streamWriteUInt16(streamId, #self.segments)

    for _, segment in ipairs(self.segments) do
        local segmentTemplateIndex = self:getSegmentTemplateIndexById(segment:getId())
        streamWriteUInt8(streamId, segmentTemplateIndex)

        segment:writeStream(streamId, connection)
    end
end
