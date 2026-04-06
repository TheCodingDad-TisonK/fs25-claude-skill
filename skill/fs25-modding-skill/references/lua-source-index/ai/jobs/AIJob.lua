













---A job mainly runs on server only. Task starting, stopping and updating is server code only
-- Client gets notified by targets.
-- This avoids a lot of issues with async loading of vehicles e.g. if a vehicle is not available when job gets started or synced
local AIJob_mt = Class(AIJob)


---
function AIJob.new(isServer, customMt)
    local self = setmetatable({}, customMt or AIJob_mt)

    self.isServer = isServer
    self.tasks = {}
    self.namedParameters = {}
    self.groupedParameters = {}
    self.currentTaskIndex = 0
    self.jobId = nil
    self.startedFarmId = nil
    self.isDirectStart = false

    self.pendingCost = 0

    return self
end


---
function AIJob:delete()
    for _, namedParameter in ipairs(self.namedParameters) do
        namedParameter.parameter:delete()
    end
    for _, task in ipairs(self.tasks) do
        task:delete()
    end
end


---
function AIJob:saveToXMLFile(xmlFile, key, usedModNames)
    local index = 0
    for _, namedParameter in ipairs(self.namedParameters) do
        local parameter = namedParameter.parameter
        if parameter.saveToXMLFile ~= nil then
            local paramKey = string.format("%s.parameter(%d)", key, index)
            xmlFile:setString(paramKey .. "#name", namedParameter.name)
            namedParameter.parameter:saveToXMLFile(xmlFile, paramKey, usedModNames)
            index = index + 1
        end
    end

    return true
end


---
function AIJob:loadFromXMLFile(xmlFile, key)
    xmlFile:iterate(key .. ".parameter", function(_, paramKey)
        local name = xmlFile:getString(paramKey .. "#name")
        if name ~= nil then
            local parameter = self:getNamedParameter(name)
            if parameter ~= nil and parameter.loadFromXMLFile ~= nil then
                parameter:loadFromXMLFile(xmlFile, paramKey)
            end
        end
    end)
end


---
function AIJob:readStream(streamId, connection)
    self.isDirectStart = streamReadBool(streamId)

    if streamReadBool(streamId) then
        self.jobId = streamReadInt32(streamId)
    end

    for _, namedParameter in ipairs(self.namedParameters) do
        namedParameter.parameter:readStream(streamId, connection)
    end

    self:setValues()

    self.currentTaskIndex = streamReadUInt8(streamId)
end


---
function AIJob:writeStream(streamId, connection)
    streamWriteBool(streamId, self.isDirectStart)

    if streamWriteBool(streamId, self.jobId ~= nil) then
        streamWriteInt32(streamId, self.jobId)
    end

    for _, namedParameter in ipairs(self.namedParameters) do
        namedParameter.parameter:writeStream(streamId, connection)
    end

    streamWriteUInt8(streamId, self.currentTaskIndex)
end


---
function AIJob:update(dt)
    -- task update and handling is done on server side only
    if self.isServer then
        local currentTask
        if self.currentTaskIndex == 0 then
            local canStart, aiMessage = self:canStartWork()
            if canStart then
                local taskIndex = self:getStartTaskIndex()
                local task = self:getTaskByIndex(taskIndex)
                self:startTask(task)
            else
                g_currentMission.aiSystem:stopJob(self, aiMessage)
                return
            end
        else
            currentTask = self:getTaskByIndex(self.currentTaskIndex)
        end

        if currentTask ~= nil then
            currentTask:update(dt)

            if currentTask:getIsFinished() then
                local canContinue, aiMessage = self:canContinueWork()
                if not canContinue then
                    g_currentMission.aiSystem:stopJob(self, aiMessage)
                    return
                end


                local newTaskIndex = self:getNextTaskIndex()

                if newTaskIndex > #self.tasks then
                    if self:getIsLooping() then
                        newTaskIndex = 1
                    else
                        g_currentMission.aiSystem:stopJob(self, AIMessageSuccessFinishedJob.new())
                        return
                    end
                end

                self:stopTask(currentTask, false)

                local nextTask = self:getTaskByIndex(newTaskIndex)
                self:startTask(nextTask)
            end
        end
    end
end


---
function AIJob:updateCost(dt)
    local price = self:getPricePerMs()
    if price > 0 then
        price = price * dt * EconomyManager.getCostMultiplier()

        self.pendingCost = self.pendingCost + price

        local farm = g_farmManager:getFarmById(self.startedFarmId)
        if farm ~= nil then
            if farm:getBalance() - self.pendingCost < 0 then
                g_currentMission.aiSystem:stopJob(self, AIMessageErrorOutOfMoney.new())
            end
        end

        if self.pendingCost > 25 then
            g_currentMission:addMoney(-self.pendingCost, self.startedFarmId, MoneyType.AI, true)
            self.pendingCost = 0
        end
    end
end


---
function AIJob:canContinueWork()
    return true, nil
end


---
function AIJob:canStartWork()
    return true, nil
end


---
function AIJob:getPricePerMs()
    return 0.0004
end


---
function AIJob:getNextTaskIndex()
    return self.currentTaskIndex + 1
end


---
function AIJob:validate(farmId)
    return true, nil
end


---
function AIJob:getIsLooping()
    return false
end


---
function AIJob:setValues()
end


---
function AIJob:startTask(task)
    self.currentTaskIndex = task.taskIndex
    task:start()

    if self.isServer then
        g_server:broadcastEvent(AITaskStartEvent.new(self, task))
    end
end


---
function AIJob:stopTask(task, wasJobStopped)
    task:stop(wasJobStopped)

    if self.isServer then
        g_server:broadcastEvent(AITaskStopEvent.new(self, task, wasJobStopped))
    end
end


---
function AIJob:start(farmId)
    local helper = g_helperManager:getRandomHelper()
    self.helperIndex = helper.index
    self.startedFarmId = farmId
    self.isRunning = true

    if self.isServer then
        self.currentTaskIndex = 0
    end
end


---
function AIJob:getCanSkipTask()
    return false
end


---
function AIJob:skipCurrentTask()
end


---
function AIJob:stop(aiMessage)
    self.isRunning = false

    if self.isServer and self.currentTaskIndex ~= 0 then
        -- client will be notified in stopTask function
        local task = self:getTaskByIndex(self.currentTaskIndex)
        self:stopTask(task, true)
    end

    if self.pendingCost > 0 then
        g_currentMission:addMoney(-self.pendingCost, self.startedFarmId, MoneyType.AI, true)
        self.pendingCost = 0
    end

    self:showNotification(aiMessage)

    self:resetTasks()
end


---
function AIJob:addTask(task)
    assert(task.taskIndex == nil, "Task already added")
    table.insert(self.tasks, task)
    task.taskIndex = #self.tasks
end


---
function AIJob:resetTasks()
    for _, task in ipairs(self.tasks) do
        task:reset()
    end
end


---
function AIJob:getTaskByIndex(taskIndex)
    return self.tasks[taskIndex]
end


---
function AIJob:getTitle()
    local helper = g_helperManager:getHelperByIndex(self.helperIndex)
    return helper.title
end


---
function AIJob:getDescription()
    local jobType = g_currentMission.aiJobTypeManager:getJobTypeByIndex(self.jobTypeIndex)
    return jobType.title
end


---
function AIJob:getHelperName()
    local helper = g_helperManager:getHelperByIndex(self.helperIndex)
    return helper.title
end


---
function AIJob:showNotification(aiMessage)
    local helper = g_helperManager:getHelperByIndex(self.helperIndex)

    -- helper can be nil on game quit
    if helper ~= nil then
        local playerFarmId
        if g_currentMission ~= nil and g_localPlayer ~= nil then
            playerFarmId = g_localPlayer.farmId
        end

        if aiMessage ~= nil and self.startedFarmId == playerFarmId then
            local text = aiMessage:getMessage(self)
            local errorType = aiMessage:getType()
            local notificationType = FSBaseMission.INGAME_NOTIFICATION_CRITICAL

            if errorType == AIMessageType.OK then
                notificationType = FSBaseMission.INGAME_NOTIFICATION_OK
            elseif errorType == AIMessageType.INFO then
                notificationType = FSBaseMission.INGAME_NOTIFICATION_INFO
            end

            g_currentMission:addIngameNotification(notificationType, text)
        end
    end
end


---
function AIJob:getStartTaskIndex()
    return 1
end


---
function AIJob:addNamedParameter(name, parameter)
    table.insert(self.namedParameters, {name=name, parameter=parameter})
end


---
function AIJob:setParameterValid(isValid)
    for _, namedParameter in ipairs(self.namedParameters) do
        namedParameter.parameter:setIsValid(isValid)
    end
end


---
function AIJob:getNamedParameters()
    return self.namedParameters
end


---
function AIJob:getNamedParameter(name)
    if name == nil then
        return nil
    end

    name = name:upper()
    for _, data in ipairs(self.namedParameters) do
        if data.name:upper() == name then
            return data.parameter
        end
    end

    return nil
end


---
function AIJob:getGroupedParameters()
    return self.groupedParameters
end


---
function AIJob:applyCurrentState(vehicle, mission, farmId, isDirectStart)
    self.isDirectStart = isDirectStart
end


---
function AIJob:getIsAvailableForVehicle(vehicle)
    return true
end


---
function AIJob:setId(id)
    self.jobId = id
end


---
function AIJob:onParameterValueChanged(parameter)
end


---
function AIJob:getIsStartable(connection)
    return true, AIJob.START_SUCCESS
end
