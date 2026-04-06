




---Event for adding fence segment
local FenceSegmentEvent_mt = Class(FenceSegmentEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FenceSegmentEvent.emptyNew()
    return Event.new(FenceSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end


---Create new instance of event
-- @param Placeable fencePlaceable fencePlaceable object
-- @param Segment segment segment instance
-- @return FenceSegmentEvent self
function FenceSegmentEvent.new(fencePlaceable, segment)
    local self = FenceSegmentEvent.emptyNew()

    self.fencePlaceable = fencePlaceable
    self.segment = segment

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FenceSegmentEvent:readStream(streamId, connection)
    self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
    local templateIndex = streamReadUInt8(streamId)

    local fence = self.fencePlaceable:getFence()
    local templateId = fence:getSegmentTemplateIdByIndex(templateIndex)
    self.segment = fence:createNewSegment(templateId)

    self.segment:readStream(streamId, connection)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FenceSegmentEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)

    local segmentId = self.segment:getId()
    local fence = self.fencePlaceable:getFence()
    local fenceTemplateIndex = fence:getSegmentTemplateIndexById(segmentId)

    streamWriteUInt8(streamId, fenceTemplateIndex)
    self.segment:writeStream(streamId, connection)
end


---Run action on receiving side
-- @param integer connection connection
function FenceSegmentEvent:run(connection)
    if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then

        self.segment:updateMeshes(true)
        self.segment:finalize()
    end
end
