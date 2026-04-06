




---Event for request attaching
local VehicleAttachRequestEvent_mt = Class(VehicleAttachRequestEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleAttachRequestEvent.emptyNew()
    return Event.new(VehicleAttachRequestEvent_mt)
end


---Create new instance of event
-- @param table info attach info [attacherVehicle, attachable, attacherVehicleJointDescIndex, attachableJointDescIndex]
-- @return table instance instance of event
function VehicleAttachRequestEvent.new(info)
    local self = VehicleAttachRequestEvent.emptyNew()
    self.attacherVehicle = info.attacherVehicle
    self.attachable = info.attachable
    self.attacherVehicleJointDescIndex = info.attacherVehicleJointDescIndex
    self.attachableJointDescIndex = info.attachableJointDescIndex
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleAttachRequestEvent:readStream(streamId, connection)
    self.attacherVehicle = NetworkUtil.readNodeObject(streamId)
    self.attachable = NetworkUtil.readNodeObject(streamId)
    self.attacherVehicleJointDescIndex = streamReadUIntN(streamId, 7)
    self.attachableJointDescIndex = streamReadUIntN(streamId, 7)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleAttachRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.attacherVehicle)
    NetworkUtil.writeNodeObject(streamId, self.attachable)
    streamWriteUIntN(streamId, self.attacherVehicleJointDescIndex, 7)
    streamWriteUIntN(streamId, self.attachableJointDescIndex, 7)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleAttachRequestEvent:run(connection)
    if not connection:getIsServer() then
        if self.attacherVehicle ~= nil and self.attacherVehicle:getIsSynchronized() then
            self.attacherVehicle:attachImplementFromInfo(self)
        end
    end
end
