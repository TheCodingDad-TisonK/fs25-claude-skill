










---Event for adding fence segment
local FenceNewSegmentEvent_mt = Class(FenceNewSegmentEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FenceNewSegmentEvent.emptyNew()
    return Event.new(FenceNewSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end
























---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FenceNewSegmentEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
        local fence = self.fencePlaceable:getFence()
        local templateIndex = streamReadUInt8(streamId)
        local templateId = fence:getSegmentTemplateIdByIndex(templateIndex)
        self.segment = fence:createNewSegment(templateId)
        self.segment:readStream(streamId, connection)

        self:run(connection)
    else
        local statusCode = streamReadUInt8(streamId)
        local segmentId = streamReadUInt16(streamId)
        local ex = streamReadFloat32(streamId)
        local ey = streamReadFloat32(streamId)
        local ez = streamReadFloat32(streamId)

        g_messageCenter:publish(FenceNewSegmentEvent, statusCode, segmentId, ex, ey, ez)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param Connection connection connection
function FenceNewSegmentEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)

        local segmentId = self.segment:getId()
        local fence = self.fencePlaceable:getFence()
        local fenceTemplateIndex = fence:getSegmentTemplateIndexById(segmentId)
        streamWriteUInt8(streamId, fenceTemplateIndex)
        self.segment:writeStream(streamId, connection)
    else
        streamWriteUInt8(streamId, self.statusCode)
        streamWriteUInt16(streamId, self.segmentId)
        streamWriteFloat32(streamId, self.ex)
        streamWriteFloat32(streamId, self.ey)
        streamWriteFloat32(streamId, self.ez)
    end
end


---Run action on receiving side
-- @param Connection connection
function FenceNewSegmentEvent:run(connection)
    if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
        local statusCode = FenceNewSegmentEvent.STATUS_CODE.SUCCESS

        if not self.segment:updateMeshes(true) then
            statusCode = FenceNewSegmentEvent.STATUS_CODE.ERROR
        else
            local price = self.segment:getPrice()
            g_currentMission:addMoney(-price, self.fencePlaceable:getOwnerFarmId(), MoneyType.SHOP_PROPERTY_BUY, true)
            self.segment:finalize()
        end

        if statusCode == FenceNewSegmentEvent.STATUS_CODE.SUCCESS then
            -- broadcase new segment to all clients
            g_server:broadcastEvent(FenceSegmentEvent.new(self.fencePlaceable, self.segment), false, nil, self.fencePlaceable)  -- last change
        end

        local ex, ey, ez = self.segment:getEndPos()

        -- send back info to client requesting new segment
        if not connection:getIsLocal() then
            connection:sendEvent(FenceNewSegmentEvent.newServerToClient(statusCode, self.segment.id, ex, ey, ez))
        else
            g_messageCenter:publish(FenceNewSegmentEvent, statusCode, self.segment.id, ex, ey, ez)
        end
    end
end
