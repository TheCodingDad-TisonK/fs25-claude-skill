




---Event for leaving
local VehicleLeaveEvent_mt = Class(VehicleLeaveEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleLeaveEvent.emptyNew()
    local self = Event.new(VehicleLeaveEvent_mt, NetworkNode.CHANNEL_MAIN)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @return table instance instance of event
function VehicleLeaveEvent.new(vehicle, userId)
    local self = VehicleLeaveEvent.emptyNew()
    self.vehicle = vehicle
    self.userId = userId
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleLeaveEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleLeaveEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    User.streamWriteUserId(streamId, self.userId)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleLeaveEvent:run(connection)

    -- If the vehicle is not yet ready, do nothing.
    if self.vehicle == nil or not self.vehicle:getIsSynchronized() then
        Logging.devInfo("VehicleLeaveEvent.run: Vehicle not found or not synchronized yet")
        return
    end

    -- If this is the server, handle setting the owner.
    if not connection:getIsServer() then

        -- If the vehicle has an owner, unset it.
        if self.vehicle:getOwnerConnection() ~= nil then
            self.vehicle:setOwnerConnection(nil)
            self.vehicle.controllerFarmId = nil
        end

        -- Fire the leave event on all clients except the one who left the vehicle.
        g_server:broadcastEvent(VehicleLeaveEvent.new(self.vehicle, self.userId), nil, connection, self.vehicle)
    end

    local player = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
    if player ~= nil then
        player:leaveVehicle(self.vehicle, true)
    end
end


---
function VehicleLeaveEvent.sendEvent(vehicle, userId, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(VehicleLeaveEvent.new(vehicle, userId), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(VehicleLeaveEvent.new(vehicle, userId))
        end
    end
end
