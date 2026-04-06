




---Event for bundle attaching
local VehicleBundleAttachEvent_mt = Class(VehicleBundleAttachEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleBundleAttachEvent.emptyNew()
    local self = Event.new(VehicleBundleAttachEvent_mt)
    return self
end


---Create new instance of event
-- @param table bundles bundles
-- @return table instance instance of event
function VehicleBundleAttachEvent.new(bundles)
    local self = VehicleBundleAttachEvent.emptyNew()
    self.bundles = bundles
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleBundleAttachEvent:readStream(streamId, connection)
    local numBundles = streamReadUInt8(streamId)
    for _=1, numBundles do
        local v1 = NetworkUtil.readNodeObjectId(streamId)
        local v2 = NetworkUtil.readNodeObjectId(streamId)
        local inputJointIndex = streamReadUIntN(streamId, 7)
        local jointIndex = streamReadUIntN(streamId, 7)
        table.insert(g_currentMission.vehicleSystem.vehiclesToAttach, {v1id=v1, v2id=v2, inputJointIndex=inputJointIndex, jointIndex=jointIndex})
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleBundleAttachEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, #self.bundles)
    for i=1, #self.bundles do
        local bundle = self.bundles[i]
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(bundle.v1))
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(bundle.v2))
        streamWriteUIntN(streamId, bundle.input, 7)
        streamWriteUIntN(streamId, bundle.attacher, 7)
    end
end


---Run action on receiving side
-- @param integer connection connection
function VehicleBundleAttachEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:attachImplement(self.implement, self.inputJointIndex,  self.jointIndex, true, nil, self.startLowered)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.object)
    end
end
