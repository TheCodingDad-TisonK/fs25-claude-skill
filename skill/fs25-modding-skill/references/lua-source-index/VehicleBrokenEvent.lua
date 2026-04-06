




---Event for enter request
local VehicleBrokenEvent_mt = Class(VehicleBrokenEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleBrokenEvent.emptyNew()
    local self = Event.new(VehicleBrokenEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function VehicleBrokenEvent.new(object)
    local self = VehicleBrokenEvent.emptyNew()
    self.object = object
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleBrokenEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleBrokenEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleBrokenEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBroken()
    end
end
