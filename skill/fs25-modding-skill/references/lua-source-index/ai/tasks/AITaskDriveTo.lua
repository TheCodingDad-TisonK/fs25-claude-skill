















---
local AITaskDriveTo_mt = Class(AITaskDriveTo, AITask)


---
function AITaskDriveTo.new(isServer, job, customMt)
    local self = AITask.new(isServer, job, customMt or AITaskDriveTo_mt)

    self.x = nil
    self.z = nil
    self.dirX = nil
    self.dirZ = nil
    self.vehicle = nil
    self.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
    self.maxSpeed = 10
    self.offset = 0

    self.prepareTimeout = 0

    return self
end


---
function AITaskDriveTo:reset()
    self.vehicle = nil
    self.x, self.z = nil, nil
    self.dirX, self.dirZ = nil, nil
    self.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
    self.maxSpeed = 10
    self.offset = 0
    AITaskDriveTo:superClass().reset(self)
end


---
function AITaskDriveTo:setVehicle(vehicle)
    self.vehicle = vehicle
end


---
function AITaskDriveTo:setTargetOffset(offset)
    self.offset = offset
end


---
function AITaskDriveTo:setTargetPosition(x, z)
    self.x = x
    self.z = z

    if self.isActive then
    -- update target
--        self.vehicle:
    end
end


---
function AITaskDriveTo:setTargetDirection(dirX, dirZ)
    self.dirX = dirX
    self.dirZ = dirZ

    if self.isActive then
    -- update target
    end
end


---
function AITaskDriveTo:update(dt)
    if self.isServer then
        if self.state == AITaskDriveTo.STATE_PREPARE_DRIVING then
            local isReadyToDrive, blockingVehicle = self.vehicle:getIsAIReadyToDrive()
            if isReadyToDrive then
                self:startDriving()
            else
                if not self.vehicle:getIsAIPreparingToDrive() then
                    self.prepareTimeout = self.prepareTimeout + dt
                    if self.prepareTimeout > AITaskDriveTo.PREPARE_TIMEOUT then
                        self.vehicle:stopCurrentAIJob(AIMessageErrorCouldNotPrepare.new(blockingVehicle or self.vehicle))
                    end
                end
            end
        end
    end
end


---
function AITaskDriveTo:start()
    if self.isServer then
        self.state = AITaskDriveTo.STATE_PREPARE_DRIVING
        self.vehicle:prepareForAIDriving()

        self.isActive = true

--#debug         log("AITaskDriveTo:start()")
    end

    AITaskDriveTo:superClass().start(self)
end


---
function AITaskDriveTo:stop(wasJobStopped)
    AITaskDriveTo:superClass().stop(self, wasJobStopped)

    if self.isServer then
        self.vehicle:unsetAITarget()

        self.isActive = false
    end
end


---
function AITaskDriveTo:startDriving()
    local y = getTerrainHeightAtWorldPos(g_terrainNode, self.x, 0, self.z)
    local dirY = 0

    self.state = AITaskDriveTo.STATE_DRIVE_TO_FINAL_POS
    local x = self.x
    local z = self.z

    if self.offset ~= 0 then
        self.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
        x = self.x + self.dirX * -self.offset
        z = self.z + self.dirZ * -self.offset
    end

--#debug         log("AITaskDriveTo:startDriving()", x, y, z, self.dirX, self.dirZ, "Drive to Offset", (self.state == AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS))
    self.vehicle:setAITarget(self, x, y, z, self.dirX, dirY, self.dirZ)
end


---
function AITaskDriveTo:onTargetReached()
    if self.state == AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS then
        local y = getTerrainHeightAtWorldPos(g_terrainNode, self.x, 0, self.z)
        self.vehicle:setAITarget(self, self.x, y, self.z, self.dirX, 0, self.dirZ, self.maxSpeed, true)
        self.state = AITaskDriveTo.STATE_DRIVE_TO_FINAL_POS
    else
        self.isFinished = true
    end
end


---
function AITaskDriveTo:onError(errorMessage)
end
