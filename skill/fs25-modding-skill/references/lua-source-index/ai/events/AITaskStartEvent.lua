








---
local AITaskStartEvent_mt = Class(AITaskStartEvent, Event)




---
function AITaskStartEvent.emptyNew()
    local self = Event.new(AITaskStartEvent_mt)
    return self
end


---
function AITaskStartEvent.new(job, task)
    local self = AITaskStartEvent.emptyNew()

    self.job = job
    self.task = task

    return self
end


---
function AITaskStartEvent:readStream(streamId, connection)
    local jobId = streamReadInt32(streamId)
    local taskId = streamReadUInt8(streamId)

    self.job = g_currentMission.aiSystem:getJobById(jobId)
    if self.job ~= nil then
        self.task = self.job:getTaskByIndex(taskId)
    end

    self:run(connection)
end


---
function AITaskStartEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.job.jobId)
    streamWriteUInt8(streamId, self.task.taskIndex)
end


---
function AITaskStartEvent:run(connection)
    if self.job == nil then
        Logging.devWarning("AITaskStartEvent: Job not defined")
        return
    end

    self.job:startTask(self.task)
end
