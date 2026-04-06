




---Event for lowering implement
local VehicleLowerImplementEvent_mt = Class(VehicleLowerImplementEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleLowerImplementEvent.emptyNew()
    local self = Event.new(VehicleLowerImplementEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer jointIndex index of joint
-- @param boolean moveDown move down
-- @return table instance instance of event
function VehicleLowerImplementEvent.new(vehicle, jointIndex, moveDown)
    local self = VehicleLowerImplementEvent.emptyNew()
    self.jointIndex = jointIndex
    self.vehicle = vehicle
    self.moveDown = moveDown
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleLowerImplementEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.jointIndex = streamReadInt8(streamId)
    self.moveDown = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleLowerImplementEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteInt8(streamId, self.jointIndex)
    streamWriteBool(streamId, self.moveDown)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleLowerImplementEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setJointMoveDown(self.jointIndex, self.moveDown, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(VehicleLowerImplementEvent.new(self.vehicle, self.jointIndex, self.moveDown), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer jointIndex index of joint
-- @param boolean moveDown move down
-- @param boolean noEventSend no event send
function VehicleLowerImplementEvent.sendEvent(vehicle, jointIndex, moveDown, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(VehicleLowerImplementEvent.new(vehicle, jointIndex, moveDown), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(VehicleLowerImplementEvent.new(vehicle, jointIndex, moveDown))
        end
    end
end
