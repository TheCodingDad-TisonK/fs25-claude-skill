




---Event for enter response
local VehicleEnterResponseEvent_mt = Class(VehicleEnterResponseEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleEnterResponseEvent.emptyNew()
    local self = Event.new(VehicleEnterResponseEvent_mt, NetworkNode.CHANNEL_MAIN)
    return self
end


---Create new instance of event
-- @param table id id
-- @param boolean isOwner is owner
-- @param table playerStyle
-- @param integer farmId
-- @param integer userId
-- @return VehicleEnterResponseEvent self
function VehicleEnterResponseEvent.new(id, isOwner, playerStyle, farmId, userId)
    local self = VehicleEnterResponseEvent.emptyNew()

    self.id = id
    self.isOwner = isOwner
    self.playerStyle = playerStyle
    self.farmId = farmId
    self.userId = userId

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleEnterResponseEvent:readStream(streamId, connection)
    --#debug Player.debugLog(nil, Player.DEBUG_DISPLAY_FLAG.NETWORK, "VehicleEnterResponseEvent:readStream")
    self.id = NetworkUtil.readNodeObjectId(streamId)
    self.isOwner = streamReadBool(streamId)

    if self.playerStyle == nil then
        self.playerStyle = PlayerStyle.new()
    end
    self.playerStyle:readStream(streamId, connection)

    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleEnterResponseEvent:writeStream(streamId, connection)
    --#debug Player.debugLog(nil, Player.DEBUG_DISPLAY_FLAG.NETWORK, "VehicleEnterResponseEvent:writeStream")
    NetworkUtil.writeNodeObjectId(streamId, self.id)
    streamWriteBool(streamId, self.isOwner)

    self.playerStyle:writeStream(streamId, connection)

    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    User.streamWriteUserId(streamId, self.userId)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleEnterResponseEvent:run(connection)

    local vehicle = NetworkUtil.getObject(self.id)
    if vehicle == nil then
        Logging.devWarning("VehicleEnterResponseEvent: Vehicle '%s' not found. Skip entering", self.id)
        return
    end

    if not vehicle:getIsSynchronized() then
        Logging.devWarning("VehicleEnterResponseEvent: Vehicle '%s' not synchronized. Skip entering", vehicle.configFileName)
        return
    end

    local player = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
    if player == nil then
        Logging.devWarning("VehicleEnterResponseEvent: Player '%s' not found. Skip entering", self.userId)
        return
    end

    player:onEnterVehicle(vehicle)
end
