




---Event for removing a fence segment
local FenceRequestDeleteSegmentEvent_mt = Class(FenceRequestDeleteSegmentEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FenceRequestDeleteSegmentEvent.emptyNew()
    return Event.new(FenceRequestDeleteSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end




















---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FenceRequestDeleteSegmentEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
        self.segmentId = streamReadUInt16(streamId)
    else
        self.success = streamReadBool(streamId)
    end

    self:run(connection)
end


---
-- @param integer streamId streamId
-- @param Connection connection connection
function FenceRequestDeleteSegmentEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
        streamWriteUInt16(streamId, self.segmentId)
    else
        streamWriteBool(streamId, self.success)
    end
end


---Run action on receiving side
-- @param Connection connection
function FenceRequestDeleteSegmentEvent:run(connection)
    -- on client just publish the validate event
    if connection:getIsServer() then
        g_messageCenter:publish(FenceRequestDeleteSegmentEvent, self.success)
        return
    end

    if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
        local fence = self.fencePlaceable:getFence()
        local segment = fence:getSegmentById(self.segmentId)

        if segment == nil then
            connection:sendEvent(FenceRequestDeleteSegmentEvent.newServerToClient(false))
            return
        end

        fence:removeSegment(segment)
        segment:delete()
        connection:sendEvent(FenceRequestDeleteSegmentEvent.newServerToClient(true))

        -- broadcast deletion to all clients except sender
        g_server:broadcastEvent(FenceDeleteSegmentEvent.new(self.fencePlaceable, self.segmentId), false, connection)
    end
end
