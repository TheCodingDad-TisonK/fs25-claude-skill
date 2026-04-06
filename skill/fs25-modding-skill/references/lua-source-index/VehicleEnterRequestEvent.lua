




---Event for enter request
local VehicleEnterRequestEvent_mt = Class(VehicleEnterRequestEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleEnterRequestEvent.emptyNew()
    local self = Event.new(VehicleEnterRequestEvent_mt, NetworkNode.CHANNEL_MAIN)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @param integer farmId
-- @param boolean? force
-- @return VehicleEnterRequestEvent self
function VehicleEnterRequestEvent.new(object, playerStyle, farmId, force)
    local self = VehicleEnterRequestEvent.emptyNew()
    self.object = object
    self.objectId = NetworkUtil.getObjectId(self.object)
    self.farmId = farmId
    self.playerStyle = playerStyle
    self.force = Utils.getNoNil(force, false)
    return self
end


---Called by the player entering the vehicle, to be sent to the server.
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleEnterRequestEvent:writeStream(streamId, connection)
    --#debug Player.debugLog(nil, Player.DEBUG_DISPLAY_FLAG.NETWORK, "VehicleEnterRequestEvent:writeStream")
    NetworkUtil.writeNodeObjectId(streamId, self.objectId)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.playerStyle:writeStream(streamId, connection)
    streamWriteBool(streamId, self.force)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleEnterRequestEvent:readStream(streamId, connection)
    --#debug Player.debugLog(nil, Player.DEBUG_DISPLAY_FLAG.NETWORK, "VehicleEnterRequestEvent:readStream")
    self.objectId = NetworkUtil.readNodeObjectId(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

    if self.playerStyle == nil then
        self.playerStyle = PlayerStyle.new()
    end
    self.playerStyle:readStream(streamId, connection)
    self.force = streamReadBool(streamId)

    self.object = NetworkUtil.getObject(self.objectId)
    self:run(connection)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleEnterRequestEvent:run(connection)

    if self.object == nil or not self.object:getIsSynchronized() then
        return
    end

    -- check if vehicle is available on client
    if not self.force and not g_server:hasGhostObject(connection, self.object) then
        Logging.warning("Vehicle %q is not fully synchronized to on client", self.object.configFileName)
        return
    end

    local enterableSpec = self.object.spec_enterable
    if enterableSpec == nil or enterableSpec.isControlled then
        return
    end

    local userId = g_currentMission.userManager:getUserIdByConnection(connection)
    self.object:setOwnerConnection(connection)
    self.object.controllerFarmId = self.farmId
    self.object.controllerUserId = userId

    --#debug Player.debugLog(g_currentMission.playerSystem:getPlayerByUserId(userId), Player.DEBUG_DISPLAY_FLAG.NETWORK, "VehicleEnterRequestEvent:run")

    -- Broadcast the event to all clients except the client who made the request.
    g_server:broadcastEvent(VehicleEnterResponseEvent.new(self.objectId, false, self.playerStyle, self.farmId, userId), true, connection)

    -- Specifically send the event to the client who made the request to set them as the event owner.
    connection:sendEvent(VehicleEnterResponseEvent.new(self.objectId, true, self.playerStyle, self.farmId, userId))
end
