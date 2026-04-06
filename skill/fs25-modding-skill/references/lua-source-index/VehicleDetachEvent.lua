








---Event for detaching
local VehicleDetachEvent_mt = Class(VehicleDetachEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleDetachEvent.emptyNew()
    local self = Event.new(VehicleDetachEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param table implement implement
-- @return table instance instance of event
function VehicleDetachEvent.new(vehicle, implement)
    local self = VehicleDetachEvent.emptyNew()
    self.implement = implement
    self.vehicle = vehicle
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleDetachEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.implement = NetworkUtil.readNodeObject(streamId)

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        if connection:getIsServer() then
            self.vehicle:detachImplementByObject(self.implement, true)
        else
            self.vehicle:detachImplementByObject(self.implement)
        end
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleDetachEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    NetworkUtil.writeNodeObject(streamId, self.implement)
end


---
function VehicleDetachEvent:run(connection)
end
