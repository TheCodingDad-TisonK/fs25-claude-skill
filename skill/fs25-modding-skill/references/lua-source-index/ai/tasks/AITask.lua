









---
local AITask_mt = Class(AITask)


---
function AITask.new(isServer, job, customMt)
    local self = setmetatable({}, customMt or AITask_mt)

    self.isServer = isServer
    self.job = job
    self.isFinished = false
    self.isRunning = false
    self.markAsFinished = false

    return self
end


---
function AITask:delete()
end


---
function AITask:update(dt)
end


---
function AITask:start()
--#debug     Logging.devInfo("%s:start()", ClassUtil.getClassNameByObject(self))
    self.isFinished = false
    self.isRunning = true

    if self.markAsFinished then
--#debug         Logging.devInfo("%s:start() mark as finished", ClassUtil.getClassNameByObject(self))
        self.isFinished = true
        self.markAsFinished = false
    end
end


---
function AITask:skip()
--#debug     Logging.devInfo("%s:skip() - IsRunning %s", ClassUtil.getClassNameByObject(self), tostring(self.isRunning))
    if self.isRunning then
        self.isFinished = true
    else
        self.markAsFinished = true
    end
end


---
function AITask:stop(wasJobStopped)
--#debug     Logging.devInfo("%s:stop()", ClassUtil.getClassNameByObject(self))
    self.isRunning = false
    self.markAsFinished = false
end


---
function AITask:reset()
    self.isFinished = false
end


---
function AITask:validate(ignoreUnsetParameters)
    return true, nil
end


---
function AITask:getIsFinished()
    return self.isFinished
end
