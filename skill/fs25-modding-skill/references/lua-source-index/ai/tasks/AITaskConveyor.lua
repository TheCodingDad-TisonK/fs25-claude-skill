









---
local AITaskConveyor_mt = Class(AITaskConveyor, AITask)


---
function AITaskConveyor.new(isServer, job, customMt)
    local self = AITask.new(isServer, job, customMt or AITaskConveyor_mt)

    self.vehicle = nil

    return self
end


---
function AITaskConveyor:reset()
    self.vehicle = nil
    AITaskConveyor:superClass().reset(self)
end


---
function AITaskConveyor:setVehicle(vehicle)
    self.vehicle = vehicle
end


---
function AITaskConveyor:start()
    if self.vehicle ~= nil then
        self.vehicle:startFieldWorker()
    else
        Logging.devError("Could not start AITaskConveyor. No vehicle set")
    end

    AITaskConveyor:superClass().start(self)
end


---
function AITaskConveyor:stop(wasJobStopped)
    AITaskConveyor:superClass().stop(self, wasJobStopped)

    if self.vehicle ~= nil then
        self.vehicle:stopFieldWorker()
    else
        Logging.devError("Could not stop AITaskConveyor. No vehicle set")
    end
end
