











---
local VehicleStateRecorder_mt = Class(VehicleStateRecorder)


---
function VehicleStateRecorder.new(vehicle, name, duration, animationName)
    local self = setmetatable({}, VehicleStateRecorder_mt)

    self.vehicle = vehicle
    self.name = name or animationName
    self.duration = (duration or math.huge) * 1000

    if self.name == nil then
        self.name = "vehicleState_" .. getDate("%Y_%m_%d_%H_%M")
    end

    self.nodeState = {}

    if animationName ~= nil then
        if VehicleStateRecorder.defaultRaiseEvent ~= nil then
            Logging.warning("VehicleStateRecorder is already active. Only one recording at a time is supported.")
            return
        end

        VehicleStateRecorder.defaultRaiseEvent = SpecializationUtil.raiseEvent
        SpecializationUtil.raiseEvent = function(_self, eventName, animName, ...)
            VehicleStateRecorder.defaultRaiseEvent(_self, eventName, animName, ...)

            if _self == self.vehicle and animName == animationName then
                if eventName == "onPlayAnimation" then
                    if not self.isActive then
                        g_currentMission:addUpdateable(self)
                        self.isActive = true
                        self.startTime = g_time

                        self:recordVehicle()
                        Logging.info("Start vehicle state recording for '%s'", self.vehicle.configFileNameClean)
                    end
                elseif eventName == "onFinishAnimation" then
                    if self.isActive then
                        self:finish()
                    end
                end
            end
        end
    else
        g_currentMission:addUpdateable(self)
        self.isActive = true
        self.startTime = g_time

        self:recordVehicle()
        Logging.info("Start vehicle state recording for '%s'", self.vehicle.configFileNameClean)
    end

    return self
end


---
function VehicleStateRecorder:update(dt)
    if g_time - self.startTime > self.duration then
        self:finish()
        return
    end

    self:recordVehicle()

    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextColor(1, 1, 1, 0.5)
    renderText(0.5, 0.03, 0.03, string.format("Vehicle State Recording for '%s' (%.1f sec)", self.vehicle.configFileNameClean, (g_time - self.startTime) * 0.001))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
end


---
function VehicleStateRecorder:finish()
    Logging.info("Finish vehicle state recording for '%s' (%.1fsec)", self.vehicle.configFileNameClean, (g_time - (self.startTime or 0)) * 0.001)

    local directory = Utils.getDirectory(self.vehicle.configFileName)
    if string.startsWith(directory, "data/") then
        directory = getAppBasePath() .. directory
    end
    directory = directory .. "giantsTools"

    createFolder(directory)

    local filename = string.format(directory .. "/%s.xml", self.name)
    local xmlFile = XMLFile.create("vehicleState", filename, "vehicleState", nil)

    local lineIndex = 0
    for indexPath, states in pairs(self.nodeState) do
        if #states > 0 then
            local key = string.format("vehicleState.node(%d)", lineIndex)

            xmlFile:setString(key .. "#name", states[1].name)
            xmlFile:setString(key .. "#className", states[1].className)
            xmlFile:setString(key .. "#indexPath", indexPath)

            for i, state in ipairs(states) do
                local stateKey = string.format("%s.s(%d)", key, i - 1)

                xmlFile:setFloat(stateKey .. "#t", state.time * 0.001)

                local lastState = states[i - 1]

                if lastState == nil
                or (lastState.translation[1] ~= state.translation[1] or lastState.translation[2] ~= state.translation[2] or lastState.translation[3] ~= state.translation[3]) then
                    xmlFile:setString(stateKey .. "#tr", string.format("%.5f %.5f %.5f", state.translation[1], state.translation[2], state.translation[3]))
                end

                if lastState == nil
                or (lastState.rotation[1] ~= state.rotation[1] or lastState.rotation[2] ~= state.rotation[2] or lastState.rotation[3] ~= state.rotation[3]) then
                    xmlFile:setString(stateKey .. "#ro", string.format("%.4f %.4f %.4f", math.deg(state.rotation[1]), math.deg(state.rotation[2]), math.deg(state.rotation[3])))
                end

                if lastState == nil
                or (lastState.visibility ~= state.visibility) then
                    xmlFile:setBool(stateKey .. "#vi", state.visibility)
                end
            end

            lineIndex = lineIndex + 1
        end
    end

    xmlFile:save()
    xmlFile:delete()

    Logging.info("Save recording to '%s'", filename)

    g_currentMission:removeUpdateable(VehicleStateRecorder.currentInstance)

    if VehicleStateRecorder.defaultRaiseEvent ~= nil then
        SpecializationUtil.raiseEvent = VehicleStateRecorder.defaultRaiseEvent
        VehicleStateRecorder.defaultRaiseEvent = nil
    end
end


---
function VehicleStateRecorder:recordVehicle()
    for i, component in ipairs(self.vehicle.components) do
        self:recordNode(component.node, tostring(i - 1), ">")
    end
end


---
function VehicleStateRecorder:recordNode(node, indexPath, separator)
    -- only record nodes inside the i3d mapping as they are the only ones that can change
    if self.vehicle.i3dMappings[getName(node)] ~= nil then
        local x, y, z = getTranslation(node)
        local rx, ry, rz = getRotation(node)
        local visibility = getVisibility(node)

        local doRecordState = false
        if self.nodeState[indexPath] == nil then
            doRecordState = true
            self.nodeState[indexPath] = {}
        else
            local states = self.nodeState[indexPath]
            local lastState = states[#states]
            if lastState.translation[1] ~= x
            or lastState.translation[2] ~= y
            or lastState.translation[3] ~= z then
                doRecordState = true
            end

            if lastState.rotation[1] ~= rx
            or lastState.rotation[2] ~= ry
            or lastState.rotation[3] ~= rz then
                doRecordState = true
            end

            if lastState.visibility ~= visibility then
                doRecordState = true
            end
        end

        if doRecordState then
            local newState = {}
            newState.translation = {x, y, z}
            newState.rotation = {rx, ry, rz}
            newState.visibility = visibility
            newState.time = g_time - self.startTime

            if #self.nodeState[indexPath] == 0 then
                newState.name = getName(node)

                for className, classId in pairs(ClassIds) do
                    if getHasClassId(node, classId) then
                        newState.className = className
                        break
                    end
                end
            end

            table.insert(self.nodeState[indexPath], newState)
        end
    end

    for i=1, getNumOfChildren(node) do
        local child = getChildAt(node, i - 1)
        local childPath = indexPath .. (separator or "|") .. (i - 1)
        self:recordNode(child, childPath)
    end
end


---
function VehicleStateRecorder.consoleCommand(unusedSelf, name, duration)
    if VehicleStateRecorder.currentInstance == nil then
        if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            local selectedVehicle = vehicle:getSelectedVehicle() or vehicle
            VehicleStateRecorder.currentInstance = VehicleStateRecorder.new(selectedVehicle, name, duration)
        end
    else
        VehicleStateRecorder.currentInstance:finish()
        VehicleStateRecorder.currentInstance = nil
    end
end


---
function VehicleStateRecorder.consoleCommandAnimation(unusedSelf, animationName)
    if VehicleStateRecorder.currentInstance == nil then
        if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            local selectedVehicle = vehicle:getSelectedVehicle() or vehicle
            VehicleStateRecorder.currentInstance = VehicleStateRecorder.new(selectedVehicle, nil, nil, animationName)
        end
    else
        VehicleStateRecorder.currentInstance:finish()
        VehicleStateRecorder.currentInstance = nil
    end
end
