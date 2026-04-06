








---
local AITaskStopEvent_mt = Class(AITaskStopEvent, Event)




---
function AITaskStopEvent.emptyNew()
    local self = Event.new(AITaskStopEvent_mt)
    return self
end


---
function AITaskStopEvent.new(job, task, wasJobStopped)
    local self = AITaskStopEvent.emptyNew()

    self.job = job
    self.wasJobStopped = wasJobStopped
    self.task = task

    return self
end


---
function AITaskStopEvent:readStream(streamId, connection)
    local jobId = streamReadInt32(streamId)
    local taskId = streamReadUInt8(streamId)
    local wasJobStopped = streamReadBool(streamId)

    self.job = g_currentMission.aiSystem:getJobById(jobId)
    if self.job ~= nil then
        self.task = self.job:getTaskByIndex(taskId)
    end

    self.wasJobStopped = wasJobStopped

    self:run(connection)
end


---
function AITaskStopEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.job.jobId)
    streamWriteUInt8(streamId, self.task.taskIndex)
    streamWriteBool(streamId, self.wasJobStopped)
end


---
function AITaskStopEvent:run(connection)
    if self.job == nil then
        Logging.devWarning("AITaskStopEvent: Job not defined")
        return
    end

    self.job:stopTask(self.task, self.wasJobStopped)
end
