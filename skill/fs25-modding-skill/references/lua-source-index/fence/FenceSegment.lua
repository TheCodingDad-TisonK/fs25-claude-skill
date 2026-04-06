





















---
local FenceSegment_mt = Class(FenceSegment)


---
function FenceSegment.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    schema:register(XMLValueType.ANGLE,      basePath .. "#maxVerticalAngle", "")
    schema:register(XMLValueType.FLOAT,      basePath .. "#price", "price per segment")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".poles.pole(?)#node", "")
    schema:register(XMLValueType.FLOAT,      basePath .. ".poles.pole(?)#radius", "")
    schema:register(XMLValueType.FLOAT,      basePath .. ".poles.pole(?)#height", "")
    schema:register(XMLValueType.FLOAT,      basePath .. ".panels#maxScale", "", 1)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".panels.panel(?)#node", "")
    schema:register(XMLValueType.FLOAT,      basePath .. ".panels.panel(?)#length", "")
    schema:register(XMLValueType.FLOAT,      basePath .. ".panels.panel(?)#width", "")
    schema:register(XMLValueType.FLOAT,      basePath .. ".panels.panel(?)#height", "")
end

















































































































































---
function FenceSegment:saveToXMLFile(xmlFile, key)
    if self.startPosX == nil or self.endPosX == nil then
        Logging.devInfo("FenceSegment:saveToXMLFile incomplete fence %s %s %s - %s %s %s", self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
        return false
    end

    xmlFile:setValue(key .. "#start", self.startPosX, self.startPosY, self.startPosZ)
    xmlFile:setValue(key .. "#end", self.endPosX, self.endPosY, self.endPosZ)

    return true
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function FenceSegment:readStream(streamId, connection)
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams

    if connection:getIsServer() then
        self.id = streamReadUInt16(streamId)
    end

    self.startPosX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
    self.startPosY = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
    self.startPosZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)

    self.endPosX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
    self.endPosY = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
    self.endPosZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function FenceSegment:writeStream(streamId, connection)
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams

    if not connection:getIsServer() then
        streamWriteUInt16(streamId, self.id)
    end

    NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosX, paramsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosY, paramsY)
    NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosZ, paramsXZ)

    NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosX, paramsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosY, paramsY)
    NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosZ, paramsXZ)
end
