








---
local Twister_mt = Class(Twister, Object)



























































































































































































































---Called on client side on join
-- @param integer streamId stream id
-- @param table connection connection
function Twister:readStream(streamId, connection)
    Twister:superClass().readStream(self, streamId, connection)

    if connection:getIsServer() then
        local mission = g_currentMission
        local paramsXZ = mission.vehicleXZPosCompressionParams
        local paramsY = mission.vehicleYPosCompressionParams
        local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
        local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        setWorldTranslation(self.rootNode, x, y, z)
        local fadeValue = streamReadFloat32(streamId)
        self:setFadeValue(fadeValue, true)

        self.networkTimeInterpolator:reset()
    end
end


---Called on server side on join
-- @param integer streamId stream id
-- @param table connection connection
function Twister:writeStream(streamId, connection)
    Twister:superClass().writeStream(self, streamId, connection)

    if not connection:getIsServer() then
        local mission = g_currentMission
        local x,y,z = getWorldTranslation(self.rootNode)
        local paramsXZ = mission.vehicleXZPosCompressionParams
        local paramsY = mission.vehicleYPosCompressionParams
        NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
        NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
        NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
        streamWriteFloat32(streamId, self.fadeValue)
    end
end



---Called on client side on update
-- @param integer streamId stream id
-- @param integer timestamp timestamp
-- @param table connection connection
function Twister:readUpdateStream(streamId, timestamp, connection)
    Twister:superClass().readUpdateStream(self, streamId, timestamp, connection)

    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local mission = g_currentMission
            local paramsXZ = mission.vehicleXZPosCompressionParams
            local paramsY = mission.vehicleYPosCompressionParams
            local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
            local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
            local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
            local fadeValue = streamReadFloat32(streamId)

            self.positionInterpolator:setTargetPosition(x, y, z)
            self.fadeInterpolator:setTargetValue(fadeValue)
            self.networkTimeInterpolator:startNewPhaseNetwork()
        end
    end
end


---Called on server side on update
-- @param integer streamId stream id
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function Twister:writeUpdateStream(streamId, connection, dirtyMask)
    Twister:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.dirtyFlag) ~= 0) then
            local mission = g_currentMission
            local paramsXZ = mission.vehicleXZPosCompressionParams
            local paramsY = mission.vehicleYPosCompressionParams
            NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosX, paramsXZ)
            NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosY, paramsY)
            NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosZ, paramsXZ)
            streamWriteFloat32(streamId, self.sendFadeValue)
        end
    end
end
