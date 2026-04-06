








---
local AIJobStartEvent_mt = Class(AIJobStartEvent, Event)




---
function AIJobStartEvent.emptyNew()
    local self = Event.new(AIJobStartEvent_mt)
    return self
end


---
function AIJobStartEvent.new(job, startFarmId)
    local self = AIJobStartEvent.emptyNew()

    self.job = job
    self.startFarmId = startFarmId

    return self
end


---
function AIJobStartEvent:readStream(streamId, connection)
    assert(connection:getIsServer(), "AIJobStartEvent is a server to client only event")

    self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    local jobTypeIndex = streamReadInt32(streamId)

    self.job = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
    self.job:readStream(streamId, connection)

    self:run(connection)
end


---
function AIJobStartEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
    streamWriteInt32(streamId, jobTypeIndex)
    self.job:writeStream(streamId, connection)
end


---
function AIJobStartEvent:run(connection)
    g_currentMission.aiSystem:startJobInternal(self.job, self.startFarmId)
end
