




---Event for attaching
local VehicleAttachEvent_mt = Class(VehicleAttachEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleAttachEvent.emptyNew()
    local self = Event.new(VehicleAttachEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param table implement implement
-- @param integer inputJointIndex index of input attacher joint
-- @param integer jointIndex index of attacher joint
-- @param boolean startLowered start in lowered state
-- @return table instance instance of event
function VehicleAttachEvent.new(vehicle, implement, inputJointIndex, jointIndex, startLowered)
    local self = VehicleAttachEvent.emptyNew()
    self.jointIndex = jointIndex
    self.inputJointIndex = inputJointIndex
    self.vehicle = vehicle
    self.implement = implement
    self.startLowered = startLowered
    assert(self.jointIndex >= 0 and self.jointIndex < 127)
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleAttachEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.implement = NetworkUtil.readNodeObject(streamId)
    self.jointIndex = streamReadUIntN(streamId, 7)
    self.inputJointIndex = streamReadUIntN(streamId, 7)
    self.startLowered = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleAttachEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    NetworkUtil.writeNodeObject(streamId, self.implement)
    streamWriteUIntN(streamId, self.jointIndex, 7)
    streamWriteUIntN(streamId, self.inputJointIndex, 7)
    streamWriteBool(streamId, self.startLowered)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleAttachEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        if self.implement == nil then
            Logging.error("Failed to attach unknown implement to vehicle '%s' between joints '%d' and '%d'", self.vehicle.configFileName, self.jointIndex, self.inputJointIndex)
            return
        end

        self.vehicle:attachImplement(self.implement, self.inputJointIndex, self.jointIndex, true, nil, self.startLowered)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.object)
    end
end
