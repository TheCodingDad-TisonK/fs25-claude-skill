









---
local AITaskFieldWork_mt = Class(AITaskFieldWork, AITask)


---
function AITaskFieldWork.new(isServer, job, customMt)
    local self = AITask.new(isServer, job, customMt or AITaskFieldWork_mt)

    self.vehicle = nil

    return self
end


---
function AITaskFieldWork:reset()
    self.vehicle = nil
    AITaskFieldWork:superClass().reset(self)
end


---
function AITaskFieldWork:update(dt)
end


---
function AITaskFieldWork:setVehicle(vehicle)
    self.vehicle = vehicle
end


---
function AITaskFieldWork:start()
    if self.vehicle ~= nil then
        self.vehicle:startFieldWorker()
    else
        Logging.devError("Could not start AITaskFieldWork. No vehicle set")
    end

    AITaskFieldWork:superClass().start(self)
end


---
function AITaskFieldWork:stop(wasJobStopped)
    AITaskFieldWork:superClass().stop(self, wasJobStopped)

    if self.vehicle ~= nil then
        self.vehicle:stopFieldWorker()
    else
        Logging.devError("Could not stop AITaskFieldWork. No vehicle set")
    end
end
