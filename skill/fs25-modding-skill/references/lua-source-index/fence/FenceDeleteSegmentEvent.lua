




---Event for removing a fence segment
local FenceDeleteSegmentEvent_mt = Class(FenceDeleteSegmentEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FenceDeleteSegmentEvent.emptyNew()
    return Event.new(FenceDeleteSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end












---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FenceDeleteSegmentEvent:readStream(streamId, connection)
    self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
    self.segmentId = streamReadUInt16(streamId)

    self:run(connection)
end


---
-- @param integer streamId streamId
-- @param Connection connection connection
function FenceDeleteSegmentEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
    streamWriteUInt16(streamId, self.segmentId)
end


---Run action on receiving side
-- @param Connection connection
function FenceDeleteSegmentEvent:run(connection)
    if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
        -- broadcast deletion to all clients
        if g_server ~= nil then
            g_server:broadcastEvent(self, false, nil)
        end

        local fence = self.fencePlaceable:getFence()
        local segment = fence:getSegmentById(self.segmentId)

        if segment ~= nil then
            fence:removeSegment(segment)
            segment:delete()

            g_messageCenter:publish(FenceDeleteSegmentEvent, self.fencePlaceable, segment)
        end

        -- TODO: delete placeable if it was the last segment
    end
end
