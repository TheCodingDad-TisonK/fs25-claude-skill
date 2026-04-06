












---
local FenceGate_mt = Class(FenceGate, FenceSegment)


---
function FenceGate.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".gate#node", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".gate#length", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".gate#depth", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".gate#depthOffset", "")
    AnimatedObject.registerXMLPaths(schema, basePath .. ".gate")
end








































































































---
-- @param XMLFile xmlFile
-- @param any key
function FenceGate:saveToXMLFile(xmlFile, key)
    if not FenceGate:superClass().saveToXMLFile(self, xmlFile, key) then
        return false
    end

    if self.isReversed then
        xmlFile:setValue(key .. "#reversed", self.isReversed)
    end

    if self.animatedObjects ~= nil then
        local index = 0
        for _, animatedObject in ipairs(self.animatedObjects) do
            local animatedObjectKey = string.format("%s.animatedObject(%d)", key, index)
            xmlFile:setValue(animatedObjectKey .. "#id", animatedObject.saveId)
            animatedObject:saveToXMLFile(xmlFile, animatedObjectKey)  -- TODO: usedModNames
            index = index + 1
        end
    end

    return true
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function FenceGate:readStream(streamId, connection)
    FenceGate:superClass().readStream(self, streamId, connection)

    self.isReversed = streamReadBool(streamId)

    if connection:getIsServer() then
        if self.animatedObjects ~= nil then
            for _, animatedObject in ipairs(self.animatedObjects) do
                local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
                animatedObject:readStream(streamId, connection)
                g_client:finishRegisterObject(animatedObject, animatedObjectId)
            end
        end
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function FenceGate:writeStream(streamId, connection)
    FenceGate:superClass().writeStream(self, streamId, connection)

    streamWriteBool(streamId, self.isReversed)

    if not connection:getIsServer() then
        if self.animatedObjects ~= nil then
            for _, animatedObject in ipairs(self.animatedObjects) do
                NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
                animatedObject:writeStream(streamId, connection)
                g_server:registerObjectInStream(connection, animatedObject)
            end
        end
    end
end
