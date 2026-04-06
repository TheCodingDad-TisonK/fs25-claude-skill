



---
local AnimalCleanEvent_mt = Class(AnimalCleanEvent, Event)




---
function AnimalCleanEvent.emptyNew()
    local self = Event.new(AnimalCleanEvent_mt)
    return self
end


---
function AnimalCleanEvent.new(husbandry, clusterId, delta)
    local self = AnimalCleanEvent.emptyNew()

    self.husbandry = husbandry
    self.clusterId = clusterId
    self.delta = math.abs(math.floor(delta))

    return self
end


---
function AnimalCleanEvent:readStream(streamId, connection)
    self.husbandry = NetworkUtil.readNodeObject(streamId)
    self.clusterId = streamReadInt32(streamId)
    self.delta = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_DIRT)

    self:run(connection)
end


---
function AnimalCleanEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.husbandry)
    streamWriteInt32(streamId, self.clusterId)
    streamWriteUIntN(streamId, self.delta, AnimalClusterHorse.NUM_BITS_DIRT)
end


---
function AnimalCleanEvent:run(connection)
    if self.husbandry ~= nil then
        local cluster = self.husbandry:getClusterById(self.clusterId)
        if cluster ~= nil and cluster.changeDirt ~= nil then
            cluster:changeDirt(-self.delta)
        end
    end
end
