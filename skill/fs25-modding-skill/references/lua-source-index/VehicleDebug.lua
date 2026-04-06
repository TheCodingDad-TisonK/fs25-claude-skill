















































































---
function VehicleDebug.setState(state)
    if VehicleDebug.state == 0 then
        VehicleDebug.debugActionEvents = {}
        for i=1, VehicleDebug.NUM_STATES do
            local _, actionEventId = g_inputBinding:registerActionEvent(InputAction["DEBUG_VEHICLE_"..i], VehicleDebug, VehicleDebug.debugActionCallback, false, true, false, true, i)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            table.insert(VehicleDebug.debugActionEvents, actionEventId)
        end
    elseif state == 0 then
        for i=1, #VehicleDebug.debugActionEvents do
            g_inputBinding:removeActionEvent(VehicleDebug.debugActionEvents[i])
        end
    end

    if state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
        if VehicleDebug.attacherJointUpperEventId == nil and VehicleDebug.attacherJointLowerEventId == nil then
            local _, upperEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_ARM, VehicleDebug, VehicleDebug.moveUpperRotation, false, false, true, true)
            g_inputBinding:setActionEventTextVisibility(upperEventId, false)
            VehicleDebug.attacherJointUpperEventId = upperEventId
            local _, lowerEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_TOOL, VehicleDebug, VehicleDebug.moveLowerRotation, false, false, true, true)
            g_inputBinding:setActionEventTextVisibility(lowerEventId, false)
            VehicleDebug.attacherJointLowerEventId = lowerEventId
        end
    else
        g_inputBinding:removeActionEvent(VehicleDebug.attacherJointUpperEventId)
        g_inputBinding:removeActionEvent(VehicleDebug.attacherJointLowerEventId)
        VehicleDebug.attacherJointUpperEventId = nil
        VehicleDebug.attacherJointLowerEventId = nil
    end

    if state == VehicleDebug.DEBUG_AI and g_currentMission ~= nil then
        for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            if vehicle.spec_aiDrivable ~= nil and vehicle:getIsActiveForInput(true, true) then
                if vehicle.spec_aiDrivable.agentId ~= nil then
                    enableVehicleNavigationAgentDebugRendering(vehicle.spec_aiDrivable.agentId, true)
                end
            end
        end
    end

    local wheelMaskUpdated = false
    if state == VehicleDebug.DEBUG_TUNING then
        -- disable displacement collision while tuning mode is active
        -- to get smooth motor values to set up the tools properly
        WheelPhysics.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN_DISPLACEMENT
        wheelMaskUpdated = true
    elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
        if WheelPhysics.COLLISION_MASK ~= CollisionMask.ALL then
            WheelPhysics.COLLISION_MASK = CollisionMask.ALL
            wheelMaskUpdated = true
        end
    end

    if wheelMaskUpdated then
        for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            if vehicle.getWheels ~= nil then
                for i, wheel in ipairs(vehicle:getWheels()) do
                    wheel.physics:updateBase()
                end
            end
        end
    end

    local ret = false
    if VehicleDebug.state == state then
        VehicleDebug.state = 0
    else
        VehicleDebug.state = state
        ret = true
    end

    if g_currentMission ~= nil then
        for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            vehicle:updateSelectableObjects()
            vehicle:updateActionEvents()
            vehicle:setSelectedVehicle(vehicle)
        end
    end

    return ret
end


---
function VehicleDebug.delete(self)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            if motor ~= nil then
                if motor.debugCurveOverlay ~= nil then
                    delete(motor.debugCurveOverlay)
                end
                if motor.debugTorqueGraph ~= nil then
                    motor.debugTorqueGraph:delete()
                end
                if motor.debugPowerGraph ~= nil then
                    motor.debugPowerGraph:delete()
                end
                if motor.debugGraphs ~= nil then
                    for _, graph in ipairs(motor.debugGraphs) do
                        graph:delete()
                    end
                end
                if motor.debugLoadGraph ~= nil then
                    motor.debugLoadGraph:delete()
                end
                if motor.debugLoadGraphSmooth ~= nil then
                    motor.debugLoadGraphSmooth:delete()
                end
                if motor.debugLoadGraphSound ~= nil then
                    motor.debugLoadGraphSound:delete()
                end
                if motor.debugRPMGraphSmooth ~= nil then
                    motor.debugRPMGraphSmooth:delete()
                end
                if motor.debugRPMGraphSound ~= nil then
                    motor.debugRPMGraphSound:delete()
                end
                if motor.debugRPMGraph ~= nil then
                    motor.debugRPMGraph:delete()
                end
                if motor.debugAccelerationGraph ~= nil then
                    motor.debugAccelerationGraph:delete()
                end
            end
        end
    end
end


---
function VehicleDebug.debugActionCallback(self, actionName, inputValue, callbackState, isAnalog)
    if VehicleDebug.state ~= callbackState then
        VehicleDebug.setState(callbackState)
        log(string.format("VehicleDebug set to '%s'", VehicleDebug.STATE_NAMES[VehicleDebug.state]))
    end
end


---
function VehicleDebug.updateDebug(vehicle, dt)
    if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
        VehicleDebug.drawDebugAttributeRendering(vehicle)
    elseif VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
        VehicleDebug.drawDebugAttacherJoints(vehicle)
    elseif VehicleDebug.state == VehicleDebug.DEBUG_AI then
        VehicleDebug.drawDebugAIRendering(vehicle)
    elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
        VehicleDebug.updateTuningDebugRendering(vehicle, dt)
    end

    if VehicleDebug.state == VehicleDebug.DEBUG then
        if vehicle:getIsActiveForInput() or vehicle.rootVehicle ~= g_localPlayer:getCurrentVehicle() then
            VehicleDebug.drawDebugValues(vehicle)
        end
    end
end


---
function VehicleDebug.drawDebug(vehicle)
    if vehicle.getIsEntered ~= nil and vehicle:getIsEntered() then
        local v = vehicle:getSelectedVehicle()
        if v == nil then
            v = vehicle
        end
        if VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS then
            VehicleDebug.drawDebugRendering(v)
        elseif VehicleDebug.state == VehicleDebug.DEBUG_SOUNDS then
            VehicleDebug.drawSoundDebugValues(v)
        elseif VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
            VehicleDebug.drawAnimationDebug(v)
        elseif VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
            VehicleDebug.drawTransmissionDebug(v)
        elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
            VehicleDebug.drawTuningDebug(v)
        end

        if VehicleDebug.state > 0 then
            setTextAlignment(RenderText.ALIGN_CENTER)

            for i=1, VehicleDebug.NUM_STATES do
                local partSize = 1 / (VehicleDebug.NUM_STATES + 1)
                local x = partSize * i

                if VehicleDebug.state == i then
                    setTextColor(0, 1, 0, 1)
                    renderText(x, 0.01, 0.03, string.format("%s", VehicleDebug.STATE_NAMES[i]))
                else
                    setTextColor(1, 1, 0, 1)
                    renderText(x, 0.01, 0.015, string.format("SHIFT + %d: '%s'", i, VehicleDebug.STATE_NAMES[i]))
                end
            end

            setTextColor(1,1,1,1)
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
    end
end


---
function VehicleDebug.registerActionEvents(vehicle)
    if vehicle.getIsEntered ~= nil and vehicle:getIsEntered() then
        if VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
            vehicle:addActionEvent(vehicle.actionEvents, InputAction.DEBUG_PLAYER_ENABLE, vehicle, function() VehicleDebug.selectedAnimation = VehicleDebug.selectedAnimation + 1 end, false, true, false, true, nil)
        end
    end

    if VehicleDebug.state > 0 then
        if VehicleDebug.debugActionEvents ~= nil then
            for i=1, #VehicleDebug.debugActionEvents do
                g_inputBinding:removeActionEvent(VehicleDebug.debugActionEvents[i])
            end
        end

        VehicleDebug.debugActionEvents = {}
        for i=1, 9 do
            local _, actionEventId = g_inputBinding:registerActionEvent(InputAction["DEBUG_VEHICLE_"..i], VehicleDebug, VehicleDebug.debugActionCallback, false, true, false, true, i)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            table.insert(VehicleDebug.debugActionEvents, actionEventId)
        end
    end
end


---
function VehicleDebug.drawBaseDebugRendering(self, x, y)
    local vx,_,vz = getWorldTranslation(self.components[1].node)
    local fieldOwned = g_farmlandManager:getIsOwnedByFarmAtWorldPosition(g_currentMission:getFarmId(), vx, vz)
    local str1, str2, str3, str4 = "", "", "", ""
    local motorSpec = self.spec_motorized
    local diffSpeed = nil
    if motorSpec ~= nil then
        local motor = motorSpec.motor
        local torque = motor:getMotorAvailableTorque() -- kNm
        local neededPtoTorque = motor:getMotorExternalTorque()
        local motorPower = motor:getMotorRotSpeed()* (torque - neededPtoTorque)*1000

        str1 = str1.."motor:\n"          ; str2 = str2..string.format("%1.2frpm\n", motor:getNonClampedMotorRpm())
        str1 = str1.."clutch:\n"         ; str2 = str2..string.format("%1.2frpm\n", motor:getClutchRotSpeed()*30/math.pi)
        str1 = str1.."available power:\n"; str2 = str2..string.format("%1.2fhp %1.2fkW\n", motorPower/735.49875, motorPower/1000) -- motor power reduced by current consumed pto power
        str1 = str1.."gear:\n"           ; str2 = str2..string.format("%d %d (%d, %1.2f)\n", motor.gear, motor.targetGear * motor.currentDirection, motor.activeGearGroupIndex or 0, motor:getGearRatio())
        str1 = str1.."motor load:\n"     ; str2 = str2..string.format("%1.2fkN %1.2fkN\n", torque, motor:getMotorAppliedTorque())

        local ptoPower = motor:getNonClampedMotorRpm()*math.pi/30 * neededPtoTorque
        local ptoLoad = neededPtoTorque / motor:getPeakTorque()
        str3 = str3.."pto load:\n"             ; str4 = str4..string.format("%.2f%% %.2fhp %.2fkW %1.2fkN\n", ptoLoad*100, ptoPower*1.359621, ptoPower, neededPtoTorque)
        str3 = str3.."motor load:\n"           ; str4 = str4..string.format("%.2f%%\n", motorSpec.smoothedLoadPercentage*100)
        str3 = str3.."motor rpm for sounds:\n" ; str4 = str4..string.format("%drpm\n", motor:getLastMotorRpm())
        str3 = str3.."brakeForce:\n"           ; str4 = str4..string.format("%.2f (max. %.2f)\n", (self.spec_wheels or {brakePedal=0}).brakePedal, self:getBrakeForce() * 0.5)

        local fuelFillUnitIndex = self:getConsumerFillUnitIndex(FillType.DIESEL) or self:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or self:getConsumerFillUnitIndex(FillType.METHANE)
        if fuelFillUnitIndex ~= nil then
            local fillLevel = self:getFillUnitFillLevel(fuelFillUnitIndex)
            local fillType = self:getFillUnitFillType(fuelFillUnitIndex)
            local unit = fillType == FillType.ELECTRICCHARGE and "kw" or (fillType == FillType.METHANE and "kg" or "l")
            str3 = str3..string.format("%s:\n", g_fillTypeManager:getFillTypeNameByIndex(fillType)) ; str4 = str4..string.format("%.2f%s/h (%.2f%s)\n", motorSpec.lastFuelUsage, unit, fillLevel, unit)
        end

        local defFillUnitIndex = self:getConsumerFillUnitIndex(FillType.DEF)
        if defFillUnitIndex ~= nil then
            local fillLevel = self:getFillUnitFillLevel(defFillUnitIndex)
            str3 = str3.."DEF:\n" ; str4 = str4..string.format("%.2fl/h (%.2fl)\n", motorSpec.lastDefUsage, fillLevel)
        end
        local airFillUnitIndex = self:getConsumerFillUnitIndex(FillType.AIR)
        if airFillUnitIndex ~= nil then
            local fillLevel = self:getFillUnitFillLevel(airFillUnitIndex)
            str3 = str3.."AIR:\n" ; str4 = str4..string.format("%.2fl/sec (%.2fl)\n", motorSpec.lastAirUsage, fillLevel)
        end

        diffSpeed = motor.differentialRotSpeed * 3.6
    end
    str1 = str1.."vel acc[m/s2]:\n"    ; str2 = str2..string.format("%1.4f\n", self.lastSpeedAcceleration*1000*1000)
    if diffSpeed ~= nil then
        str1 = str1.."vel[km/h]:\n"    ; str2 = str2..string.format("%1.3f\n", self:getLastSpeed())

        local lastSpeedReal = self.lastSpeedReal * 3600
        local slip = 0
        if diffSpeed > 0.01 and lastSpeedReal > 0.01 then
            slip = (diffSpeed / lastSpeedReal - 1) * 100
        end
        str1 = str1.."differential[km/h]:\n"    ; str2 = str2..string.format("%1.3f (slip: %d%%)\n", diffSpeed, slip)
    else
        str1 = str1.."vel[km/h]:\n"    ; str2 = str2..string.format("%1.3f\n", self:getLastSpeed())
    end
    str1 = str1.."field owned:\n"       ; str2 = str2..tostring(fieldOwned).."\n"
    str1 = str1.."mass:\n"              ; str2 = str2..string.format("%1.1fkg\n", self:getTotalMass(true)*1000)
    str1 = str1.."mass incl. attach:\n" ; str2 = str2..string.format("%1.1fkg\n", self:getTotalMass()*1000)

    if self.spec_attachable ~= nil then
        local brakePedal = 0
        if self.spec_wheels ~= nil then
            brakePedal = self.spec_wheels.brakePedal
        end

        local force = self:getBrakeForce() / 10
        str1 = str1.."brakeForce:\n" ; str2 = str2..string.format("%1.2f / %1.2f\n", force*brakePedal, force)
    end

    local textSize = getCorrectTextSize(0.02)
    Utils.renderMultiColumnText(x, y, textSize, {str1,str2}, 0.008, {RenderText.ALIGN_RIGHT,RenderText.ALIGN_LEFT})
    Utils.renderMultiColumnText(x + 0.22, y, textSize, {str3,str4}, 0.008, {RenderText.ALIGN_RIGHT,RenderText.ALIGN_LEFT})

    return getTextHeight(textSize, str1), getTextHeight(textSize, str3)
end


---
function VehicleDebug.drawWheelInfoRendering(self, x, y)
    if self.isServer then
        local specWheels = self.spec_wheels
        if specWheels ~= nil and #specWheels.wheels > 0 then
            local debugTable = WheelDebug.getDebugValueHeader()

            for i, wheel in ipairs(specWheels.wheels) do
                wheel.debug:fillDebugValues(debugTable)

                -- draw wheel indices and driveNodes for easier identification if more than 4
                if #specWheels.wheels > 4 and DebugUtil.isNodeInCameraRange(wheel.repr, 30) then
                    local wx,wy,wz = getWorldTranslation(wheel.repr)
                    Utils.renderTextAtWorldPosition(wx,wy,wz, string.format("%d\n%s", i, getName(wheel.driveNode or wheel.linkNode)), getCorrectTextSize(0.008))
                end
            end

            local textSize = getCorrectTextSize(0.02)
            Utils.renderMultiColumnText(x, y, textSize, debugTable, 0.008, {RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT})

            return getTextHeight(textSize, debugTable[1])
        end
    end

    return 0
end


---
function VehicleDebug.drawWheelSlipGraphs(self)
    if self.isServer then
        local specWheels = self.spec_wheels
        if specWheels ~= nil then
            for i, wheel in ipairs(specWheels.wheels) do
                wheel.debug:drawSlipGraphs()
            end
        end
    end
end


---
function VehicleDebug.drawDifferentialInfoRendering(self, x, y)
    local motorSpec = self.spec_motorized
    if motorSpec ~= nil and motorSpec.differentials ~= nil then
        local getSpeedsOfDifferential
        getSpeedsOfDifferential = function(diff)
            local specWheels = self.spec_wheels
            local speed1, speed2
            if diff.diffIndex1IsWheel then
                local wheel = specWheels.wheels[diff.diffIndex1]
                speed1 = 0
                if wheel.physics.wheelShapeCreated then
                    speed1 = getWheelShapeAxleSpeed(wheel.node, wheel.physics.wheelShape) * wheel.physics.radius
                end
            else
                local s1,s2 = getSpeedsOfDifferential(motorSpec.differentials[diff.diffIndex1+1])
                speed1 = (s1+s2)/2
            end
            if diff.diffIndex2IsWheel then
                local wheel = specWheels.wheels[diff.diffIndex2]
                speed2 = 0
                if wheel.physics.wheelShapeCreated then
                    speed2 = getWheelShapeAxleSpeed(wheel.node, wheel.physics.wheelShape) * wheel.physics.radius
                end
            else
                local s1,s2 = getSpeedsOfDifferential(motorSpec.differentials[diff.diffIndex2+1])
                speed2 = (s1+s2)/2
            end
            return speed1,speed2
        end

        local getRatioOfDifferential = function(speed1, speed2)
            -- Note: this is only correct if both rpm values have the same sign
            local ratio = math.max(math.abs(speed1),math.abs(speed2)) / math.max(math.min(math.abs(speed1),math.abs(speed2)), 0.001)
            return ratio
        end

        local diffStrs = {"\n", "torqueRatio\n", "maxSpeedRatio\n", "actualSpeedRatio\n" }
        for i,diff in pairs(motorSpec.differentials) do
            diffStrs[1] = diffStrs[1]..string.format("%d:\n", i)
            diffStrs[2] = diffStrs[2]..string.format("%2.2f\n", diff.torqueRatio)
            diffStrs[3] = diffStrs[3]..string.format("%2.2f\n", diff.maxSpeedRatio)
            local speed1, speed2 = getSpeedsOfDifferential(diff)
            local ratio = getRatioOfDifferential(speed1, speed2)
            diffStrs[4] = diffStrs[4]..string.format("%2.2f\n", ratio)
        end

        Utils.renderMultiColumnText(x, y, getCorrectTextSize(0.02), diffStrs, 0.008, {RenderText.ALIGN_RIGHT,RenderText.ALIGN_LEFT})
    end
end


---
function VehicleDebug.drawMotorGraphs(self, x, y, sizeX, sizeY, horizontal)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor

            local curveOverlay = motor.debugCurveOverlay
            if curveOverlay == nil then
                curveOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
                setOverlayColor(curveOverlay, 0, 1, 0, 0.2)
                motor.debugCurveOverlay = curveOverlay
            end

            local torqueCurve = motor:getTorqueCurve()
            local numTorqueValues = #torqueCurve.keyframes

            local minRpm = math.min(motor:getMinRpm(), torqueCurve.keyframes[1].time)
            local maxRpm = math.max(motor:getMaxRpm(), torqueCurve.keyframes[numTorqueValues].time)

            local torqueGraph = motor.debugTorqueGraph
            local powerGraph = motor.debugPowerGraph
            if torqueGraph == nil then
                local numValues = numTorqueValues * 32

                torqueGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)
                torqueGraph:setColor(1, 1, 1, 1)
                motor.debugTorqueGraph = torqueGraph

                powerGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
                powerGraph:setColor(1, 0, 0, 1)
                motor.debugPowerGraph = powerGraph

                torqueGraph.maxValue = 0.01
                powerGraph.maxValue = 0.01
                for s=1, numValues do
                    local rpm = (s-1)/(numValues-1) * (torqueCurve.keyframes[numTorqueValues].time - torqueCurve.keyframes[1].time) + torqueCurve.keyframes[1].time
                    local torque = motor:getTorqueCurveValue(rpm)
                    local power = torque*1000 * rpm*math.pi/30
                    local hpPower = power/735.49875
                    local posX = (rpm - minRpm) / (maxRpm-minRpm)

                    torqueGraph:setValue(s, torque)
                    torqueGraph.maxValue = math.max(torqueGraph.maxValue, torque)
                    torqueGraph:setXPosition(s, posX)

                    powerGraph:setValue(s, hpPower)
                    powerGraph.maxValue = math.max(powerGraph.maxValue, hpPower)
                    powerGraph:setXPosition(s, posX)
                end
            else
                torqueGraph.left, torqueGraph.bottom, torqueGraph.width, torqueGraph.height = x, y, sizeX, sizeY
                powerGraph.left, powerGraph.bottom, powerGraph.width, powerGraph.height = x, y, sizeX, sizeY
            end
            torqueGraph:draw()
            powerGraph:draw()
            renderOverlay(curveOverlay, x, y, sizeX*math.clamp((motor:getNonClampedMotorRpm()-minRpm)/(maxRpm-minRpm), 0, 1), sizeY)

            if horizontal then
                x = x + sizeX + 0.013
            else
                y = y - sizeY - 0.013
            end

            local maxSpeed = motor:getMaximumForwardSpeed()

            local debugGraphs = motor.debugGraphs
            if debugGraphs == nil then
                local numVelocityValues = 20

                local numGears = 1
                local gears = motor.forwardGears
                if motor.currentDirection < 0 then
                    gears = motor.backwardGears or gears
                end

                if motor.minForwardGearRatio == nil and gears ~= nil then
                    numGears = #gears
                end

                debugGraphs = {}
                motor.debugGraphs = debugGraphs

                for gear = 1, numGears do
                    local effTorqueGraph = Graph.new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)
                    effTorqueGraph:setColor(1, 1, 1, 1)
                    table.insert(debugGraphs, effTorqueGraph)

                    local effPowerGraph = Graph.new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
                    effPowerGraph:setColor(1, 0, 0, 1)
                    table.insert(debugGraphs, effPowerGraph)

                    local effGearRatioGraph = Graph.new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
                    effGearRatioGraph:setColor(0.35, 1, 0.85, 1)
                    table.insert(debugGraphs, effGearRatioGraph)

                    local effRpmGraph = Graph.new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
                    effRpmGraph:setColor(0.18, 0.18, 1, 1)
                    table.insert(debugGraphs, effRpmGraph)

                    effTorqueGraph.maxValue = 0.01
                    effPowerGraph.maxValue = 0.01
                    effGearRatioGraph.maxValue = 0.01
                    effRpmGraph.maxValue = 0.01

                    for s=1, numVelocityValues do
                        local speed = (s-1)/(numVelocityValues-1) * maxSpeed

                        local _, gearRatio
                        if numGears == 1 then
                            _, gearRatio = motor:getBestGear(1, speed*30/math.pi, 0, math.huge, 0)
                        else
                            gearRatio = gears[gear].ratio
                        end
                        local gearRpm = speed*30/math.pi * gearRatio

                        local torque = torqueCurve:get(gearRpm)
                        local power = torque*1000 * gearRpm*math.pi/30
                        local hpPower = power/735.49875

                        if gearRpm >= minRpm and gearRpm <= maxRpm then
                            effTorqueGraph:setValue(s, torque)
                            effTorqueGraph.maxValue = math.max(effTorqueGraph.maxValue, torque)

                            effPowerGraph:setValue(s, hpPower)
                            effPowerGraph.maxValue = math.max(effPowerGraph.maxValue, hpPower)

                            effGearRatioGraph:setValue(s, gearRatio)
                            effGearRatioGraph.maxValue = math.max(effGearRatioGraph.maxValue, gearRatio)

                            effRpmGraph:setValue(s, gearRpm)
                            effRpmGraph.maxValue = math.max(effRpmGraph.maxValue, gearRpm)
                        end
                    end
                end
            else
                for i=1, #debugGraphs do
                    local graph = debugGraphs[i]
                    graph.left, graph.bottom, graph.width, graph.height = x, y, sizeX, sizeY
                end
            end
            for _, graph in pairs(debugGraphs) do
                graph:draw()
            end
            renderOverlay(curveOverlay, x, y, sizeX*math.clamp(self.lastSpeedReal*1000/maxSpeed, 0, 1), sizeY)

            if horizontal then
                x = x + sizeX + 0.013
            else
                y = y - sizeY - 0.013
            end

            VehicleDebug.drawMotorLoadGraph(self, x, y, sizeX, sizeY)
        end
    end
end


---
function VehicleDebug.drawMotorLoadGraph(self, x, y, sizeX, sizeY)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            local numValues = 500
            local loadGraph = motor.debugLoadGraph
            local loadGraphSmooth = motor.debugLoadGraphSmooth
            local loadGraphSound = motor.debugLoadGraphSound
            if loadGraph == nil then
                loadGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 100, true, "%", Graph.STYLE_LINES, 0.1, "time")
                loadGraph:setColor(1, 1, 1, 0.3)
                motor.debugLoadGraph = loadGraph

                loadGraphSmooth = Graph.new(numValues, x, y, sizeX, sizeY, 0, 100, false, "", Graph.STYLE_LINES)
                loadGraphSmooth:setColor(0, 1, 0, 1)
                motor.debugLoadGraphSmooth = loadGraphSmooth

                loadGraphSound = Graph.new(numValues, x, y, sizeX, sizeY, 0, 100, false, "", Graph.STYLE_LINES)
                loadGraphSound:setColor(0, 1, 1, 1)
                motor.debugLoadGraphSound = loadGraphSound
            else
                loadGraph.left, loadGraph.bottom, loadGraph.width, loadGraph.height = x, y, sizeX, sizeY
                loadGraphSmooth.left, loadGraphSmooth.bottom, loadGraphSmooth.width, loadGraphSmooth.height = x, y, sizeX, sizeY
                loadGraphSound.left, loadGraphSound.bottom, loadGraphSound.width, loadGraphSound.height = x, y, sizeX, sizeY
            end

            if loadGraph ~= nil and loadGraphSmooth ~= nil and loadGraphSound ~= nil then
                local rawLoad = motor:getMotorAppliedTorque() / math.max(motor:getMotorAvailableTorque(), 0.0001)
                loadGraph:addValue(rawLoad * 100, nil, true)
                loadGraphSmooth:addValue(motorSpec.smoothedLoadPercentage * 100, nil, true)

                for i=1, #motorSpec.motorSamples do
                    local sample = motorSpec.motorSamples[i]
                    if sample.isGlsFile then
                        loadGraphSound:addValue(getSampleLoopSynthesisLoadFactor(sample.soundSample) * 100, nil, true)
                        break
                    end
                end
            end

            loadGraph:draw()
            loadGraphSmooth:draw()
            loadGraphSound:draw()
        end
    end
end


---
function VehicleDebug.drawMotorRPMGraph(self, x, y, sizeX, sizeY)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            local numValues = 500
            local rpmGraph = motor.debugRPMGraph
            local rpmGraphSmooth = motor.debugRPMGraphSmooth
            local rpmGraphSound = motor.debugRPMGraphSound
            if rpmGraph == nil then
                rpmGraph = Graph.new(numValues, x, y, sizeX, sizeY, motor:getMinRpm(), motor:getMaxRpm(), true, " RPM", Graph.STYLE_LINES, 0.1, "")
                rpmGraph:setColor(1, 1, 1, 0.3)
                motor.debugRPMGraph = rpmGraph

                rpmGraphSmooth = Graph.new(numValues, x, y, sizeX, sizeY, motor:getMinRpm(), motor:getMaxRpm(), false, "", Graph.STYLE_LINES)
                rpmGraphSmooth:setColor(0, 1, 0, 1)
                motor.debugRPMGraphSmooth = rpmGraphSmooth

                local minSoundRpm, maxSoundRpm = motor:getMinRpm(), motor:getMaxRpm()
                for i=1, #motorSpec.motorSamples do
                    local sample = motorSpec.motorSamples[i]
                    if sample.isGlsFile then
                         minSoundRpm, maxSoundRpm = getSampleLoopSynthesisMinRPM(sample.soundSample), getSampleLoopSynthesisMaxRPM(sample.soundSample)
                        break
                    end
                end

                rpmGraphSound = Graph.new(numValues, x, y, sizeX, sizeY, minSoundRpm, maxSoundRpm, false, "", Graph.STYLE_LINES)
                rpmGraphSound:setColor(0, 1, 1, 1)
                motor.debugRPMGraphSound = rpmGraphSound
            else
                rpmGraph.left, rpmGraph.bottom, rpmGraph.width, rpmGraph.height = x, y, sizeX, sizeY
                rpmGraphSmooth.left, rpmGraphSmooth.bottom, rpmGraphSmooth.width, rpmGraphSmooth.height = x, y, sizeX, sizeY
                rpmGraphSound.left, rpmGraphSound.bottom, rpmGraphSound.width, rpmGraphSound.height = x, y, sizeX, sizeY
            end

            if rpmGraph ~= nil and rpmGraphSmooth ~= nil and rpmGraphSound ~= nil then
                rpmGraph:addValue(motor:getLastRealMotorRpm(), nil, true)
                rpmGraphSmooth:addValue(motor:getLastModulatedMotorRpm(), nil, true)

                for i=1, #motorSpec.motorSamples do
                    local sample = motorSpec.motorSamples[i]
                    if sample.isGlsFile then
                        rpmGraphSound:addValue(getSampleLoopSynthesisRPM(sample.soundSample, false), nil, true)
                        break
                    end
                end
            end

            rpmGraph:draw()
            rpmGraphSmooth:draw()
            rpmGraphSound:draw()
        end
    end
end


---
function VehicleDebug.drawMotorAccelerationGraph(self, x, y, sizeX, sizeY)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            local numValues = 250
            local accGraph = motor.debugAccelerationGraph
            if accGraph == nil then
                accGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 1, true, " Load Factor", Graph.STYLE_LINES, 0.1, "")
                accGraph:setColor(1, 1, 1, 0.3)
                motor.debugAccelerationGraph = accGraph
                motor.debugAccelerationGraphAddValue = true
            else
                accGraph.left, accGraph.bottom, accGraph.width, accGraph.height = x, y, sizeX, sizeY
            end

            if accGraph ~= nil then
                if motor.debugAccelerationGraphAddValue then
                    accGraph:addValue(motor.constantAccelerationCharge, nil, true)
                end

                motor.debugAccelerationGraphAddValue = not motor.debugAccelerationGraphAddValue
            end

            accGraph:draw()
        end
    end
end


---
function VehicleDebug.drawDebugRendering(self)
    local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.65)

    local x, y = 0.015, 0.64 - textHeight1 - 0.005
    local height = VehicleDebug.drawWheelInfoRendering(self, x, y)
    VehicleDebug.drawDifferentialInfoRendering(self, x, y - (height + getCorrectTextSize(0.02)))
    VehicleDebug.drawWheelSlipGraphs(self)

    VehicleDebug.drawMotorGraphs(self, 0.65, 0.44, 0.25, 0.2, false)
end


---
function VehicleDebug.drawTuningDebug(self)
    local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.9)

    local x, y = 0.015, 0.89 - textHeight1 - 0.005
    local height = VehicleDebug.drawWheelInfoRendering(self, x, y)
    VehicleDebug.drawDifferentialInfoRendering(self, x, y - (height + getCorrectTextSize(0.02)))
end


---
function VehicleDebug.drawTransmissionDebug(self)
    local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.65)

    VehicleDebug.drawMotorGraphs(self, 0.01, 0.73, 0.25, 0.2, true)

    local str1, str2 = "", ""
    local motorSpec = self.spec_motorized
    if motorSpec ~= nil then
        local motor = motorSpec.motor

        str1 = str1.."\ngear start values:\n" ; str2 = str2.."\n\n"
        str1 = str1.."peakPower:\n"           ; str2 = str2..string.format("%d/%dkW\n", motor.startGearValues.availablePower, motor.peakMotorPower)
        str1 = str1.."maxForce:\n"            ; str2 = str2..string.format("%.2fkN\n", motor.startGearValues.maxForce)
        str1 = str1.."mass:\n"                ; str2 = str2..string.format("%.2fto\n", motor.startGearValues.mass)
        str1 = str1.."slope angle:\n"         ; str2 = str2..string.format("%.2f°\n", math.deg(motor.startGearValues.slope))
        str1 = str1.."slope percentage:\n"    ; str2 = str2..string.format("%.2f%%\n", math.atan(motor.startGearValues.slope) * 100)
        str1 = str1.."dirDiffXZ:\n"           ; str2 = str2..string.format("%.2f\n", motor.startGearValues.massDirectionDifferenceXZ)
        str1 = str1.."dirDiffY:\n"            ; str2 = str2..string.format("%.2f\n", motor.startGearValues.massDirectionDifferenceY)
        str1 = str1.."dirFac:\n"              ; str2 = str2..string.format("%.2f\n", motor.startGearValues.massDirectionFactor)
        str1 = str1.."massFac:\n"             ; str2 = str2..string.format("%.2f\n", motor.startGearValues.massFactor)
        str1 = str1.."speedLimit:\n"          ; str2 = str2..string.format("%.1f / %.1f \n", motor.speedLimit, self:getSpeedLimit(true))

        str1 = str1.."auto shift allowed:\n"        ; str2 = str2..string.format("%s\n", self:getIsAutomaticShiftingAllowed())
        str1 = str1.."gear/group change allowed:\n" ; str2 = str2..string.format("%s/%s\n", motor:getIsGearChangeAllowed(), motor:getIsGearGroupChangeAllowed())
        str1 = str1.."gear group shift timer:\n"    ; str2 = str2..string.format("%.1f/%.1f sec\n", motor.gearGroupUpShiftTimer / 1000, motor.gearGroupUpShiftTime / 1000)
        str1 = str1.."clutch slipping simer:\n"     ; str2 = str2..string.format("%d ms\n", motor.clutchSlippingTimer)
        str1 = str1.."motor can run:\n"             ; str2 = str2..string.format("%s\n", motor:getCanMotorRun())
        str1 = str1.."stall timer:\n"               ; str2 = str2..string.format("%.2f\n", motor.stallTimer)
        str1 = str1.."turbo scale:\n"               ; str2 = str2..string.format("%d%%\n", motor.lastTurboScale * 100)
        str1 = str1.."blowOffValveState:\n"         ; str2 = str2..string.format("%d%%\n", motor.blowOffValveState * 100)

        Utils.renderMultiColumnText(0.015, 0.65 - textHeight1, getCorrectTextSize(0.018), {str1,str2}, 0.008, {RenderText.ALIGN_RIGHT,RenderText.ALIGN_LEFT})

        if motor.forwardGears or motor.backwardGears then
            local x = 0.222
            local y = 0.15

            local infoWidth = 0.05
            local minWidthPerGear = 0.035
            local gears = motor.forwardGears
            if motor.currentDirection < 0 then
                gears = motor.backwardGears or gears
            end

            local width = #gears * minWidthPerGear + infoWidth
            local height = 0.35

            drawOutlineRect(x, y, width, height, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
            drawFilledRect(x, y, width, height, 0, 0, 0, 0.4)

            local gearAreaWidth = width - infoWidth

            drawFilledRect(x + infoWidth, y, g_pixelSizeX, height, 0, 0, 0, 1)
            drawFilledRect(x + infoWidth, y + height * 0.9, gearAreaWidth, g_pixelSizeY, 0, 0, 0, 1)
            drawFilledRect(x + infoWidth, y + height * 0.3, gearAreaWidth, g_pixelSizeY, 0, 0, 0, 1)

            local groupRatioReal = motor:getGearRatioMultiplier()
            local groupRatio = math.abs(motor:getGearRatioMultiplier())
            local numGears = #gears
            local gearWidth = gearAreaWidth / numGears
            local gearMaxHeight = height * 0.6
            local textOffset = 0.0075

            local maxDiffSpeed = 1
            for i=1, numGears do
                maxDiffSpeed = math.max(maxDiffSpeed, motor.maxRpm * math.pi / (30 * gears[i].ratio * groupRatio) * 3.6)
            end

            local numGearValues = 5
            local offsetPerValue = height * 0.3 / numGearValues

            local lastDiffSpeedAfterChange
            local lastMaxPower
            for i=1, numGears do
                local gear = gears[i]
                lastDiffSpeedAfterChange = lastDiffSpeedAfterChange or gear.lastDiffSpeedAfterChange
                lastMaxPower = lastMaxPower or gear.lastMaxPower
                local minGearSpeed = motor.minRpm * math.pi / (30 * gear.ratio * groupRatio) * 3.6
                local maxGearSpeed = motor.maxRpm * math.pi / (30 * gear.ratio * groupRatio) * 3.6
                local pos = (minGearSpeed / maxDiffSpeed) * gearMaxHeight
                local h = ((maxGearSpeed-minGearSpeed) / maxDiffSpeed) * gearMaxHeight

                local gearX = x + infoWidth + gearWidth * (i - 1)
                local posY = y + height * 0.3 + g_pixelSizeY + pos
                drawFilledRect(gearX, posY, gearWidth, h, (motor.gear ~= i and gear.lastHasPower) and 1 or 0.05, (motor.gear == i or gear.lastHasPower) and 1 or 0.05, 0.05, 0.85)

                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(gearX + gearWidth * 0.5, posY + textOffset * 0.5, 0.015, string.format("%.2f", gear.ratio * groupRatio))

                local factor = motor:getStartInGearFactor(gear.ratio * groupRatio)
                if factor < motor.startGearThreshold then
                    setTextColor(0, 1, 0, 1)
                else
                    setTextColor(1, 0, 0, 1)
                end
                renderText(gearX + gearWidth * 0.5, y + height * 0.3 + g_pixelSizeY + gearMaxHeight - textOffset * 2, 0.015, string.format("%.2f", factor))

                if groupRatioReal ~= groupRatio then
                    factor = motor:getStartInGearFactor(gear.ratio * groupRatioReal)
                    if factor < motor.startGearThreshold then
                        setTextColor(0, 1, 0, 1)
                    else
                        setTextColor(1, 0, 0, 1)
                    end
                    renderText(gearX + gearWidth * 0.5, y + height * 0.3 + g_pixelSizeY + gearMaxHeight - textOffset * 4, 0.012, string.format("%.2f", factor))
                end

                setTextColor(1, 1, 1, 1)
                renderText(gearX + gearWidth * 0.5, y + textOffset                     , 0.0125, string.format("%.2f %.2f", gear.lastPowerFactor or 0, gear.lastRpmFactor or 0))
                renderText(gearX + gearWidth * 0.5, y + textOffset + offsetPerValue * 1, 0.0125, string.format("%.2f %.2f", gear.lastGearChangeFactor or 0, gear.lastRpmPreferenceFactor or 0))

                if gear.nextPowerValid then
                    setTextColor(0, 1, 0, 1)
                else
                    setTextColor(1, 0, 0, 1)
                end
                renderText(gearX + gearWidth * 0.5, y + textOffset + offsetPerValue * 2, 0.015, string.format("%d", gear.lastNextPower or -1))

                if gear.nextRpmValid then
                    setTextColor(0, 1, 0, 1)
                else
                    setTextColor(1, 0, 0, 1)
                end
                renderText(gearX + gearWidth * 0.5, y + textOffset + offsetPerValue * 3, 0.015, string.format("%d", gear.lastNextRpm or -1))

                setTextColor(1, 1, 1, 1)
                renderText(gearX + gearWidth * 0.5, y + textOffset + offsetPerValue * 4, 0.015, string.format("%.2f", gear.lastTradeoff or 0))
            end

            setTextAlignment(RenderText.ALIGN_CENTER)
            renderText(x + (infoWidth * 0.5), y + height * 0.3 + g_pixelSizeY + gearMaxHeight - textOffset * 2, 0.015, "startFactor")

            local bestGear, maxFactorGroup = motor:getBestStartGear(motor.currentGears)
            renderText(x + (infoWidth * 0.5), y + height * 0.3 + g_pixelSizeY + gearMaxHeight - textOffset * 4, 0.015, string.format("best %d>%d", maxFactorGroup, bestGear))

            renderText(x + (infoWidth * 0.5), y + textOffset                     , 0.01, "pwr/rpm")
            renderText(x + (infoWidth * 0.5), y + textOffset + offsetPerValue * 1, 0.01, "gearC/rpmPref")
            renderText(x + (infoWidth * 0.5), y + textOffset + offsetPerValue * 2, 0.01, string.format("nextPwr (%d)", lastMaxPower or -1))
            renderText(x + (infoWidth * 0.5), y + textOffset + offsetPerValue * 3, 0.01, "nextRpm")
            renderText(x + (infoWidth * 0.5), y + textOffset + offsetPerValue * 4, 0.01, "tradeoff")


            local diffSpeed = math.abs(motor.differentialRotSpeed * 3.6)
            local speedHeight = y + height * 0.3 + ((diffSpeed/maxDiffSpeed) * (gearMaxHeight-g_pixelSizeY)) + g_pixelSizeY

            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_CENTER)
            renderText(x + infoWidth * 0.5, speedHeight - 0.005, 0.015, string.format("%.2f", diffSpeed))
            setTextBold(false)

            if lastDiffSpeedAfterChange ~= nil then
                setTextAlignment(RenderText.ALIGN_LEFT)
                renderText(x + infoWidth * 1.1,  y + height * 0.95-0.005, 0.01, string.format("Speed after change: %.2fkm/h (%.1f sec)", lastDiffSpeedAfterChange*3.6, motor.gearChangeTime / 1000))
            end

            drawFilledRect(x + infoWidth, speedHeight, gearAreaWidth, g_pixelSizeY, 0, 1, 0, 0.5)
        end
    end
end


---
function VehicleDebug.drawDebugAttributeRendering(vehicle)
    if vehicle.debugSizeOffsetNode == nil then
        vehicle.debugSizeOffsetNode = createTransformGroup("debugSizeOffsetNode")
        link(vehicle.rootNode, vehicle.debugSizeOffsetNode)

        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        if storeItem ~= nil then
            local shopTransOffset = storeItem.shopTranslationOffset
            if shopTransOffset ~= nil then
                setTranslation(vehicle.debugSizeOffsetNode, -shopTransOffset[1], -shopTransOffset[2], -shopTransOffset[3])
            end

            local rotOffset = storeItem.shopRotationOffset
            if rotOffset ~= nil then
                setRotation(vehicle.debugSizeOffsetNode, -rotOffset[1], -rotOffset[2], -rotOffset[3])
            end
        end
    end

    -- display vehicle size
    local offsetX, offsetY, offsetZ = vehicle.size.widthOffset, vehicle.size.heightOffset + vehicle.size.height/2, vehicle.size.lengthOffset
    DebugBox.renderAtNodeWithOffset(vehicle.debugSizeOffsetNode, offsetX, offsetY, offsetZ, vehicle.size.width, vehicle.size.height, vehicle.size.length, Color.PRESETS.BLUE, true, "size")

    -- display attacher joint height to ground
    if vehicle.spec_attacherJoints ~= nil then
        for _, implement in pairs(vehicle.spec_attacherJoints.attachedImplements) do
            if implement.object ~= nil then
                local jointDesc = vehicle.spec_attacherJoints.attacherJoints[implement.jointDescIndex]

                local x, y, z = getWorldTranslation(jointDesc.jointTransform)
                drawDebugPoint(x, y, z, 1, 0, 0, 1)
                local groundRaycastResult = {
                    raycastCallback = function(self, transformId, x, y, z, distance)
                        if vehicle.vehicleNodes[transformId] == nil and implement.object.vehicleNodes[transformId] == nil then
                            self.groundDistance = distance
                            return false
                        end
                        return true
                    end
                }
                groundRaycastResult.vehicle = vehicle
                groundRaycastResult.object = implement.object
                groundRaycastResult.groundDistance = 0
                raycastAll(x, y, z, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT)
                drawDebugLine(x, y, z, 0, 1, 0, x, y-groundRaycastResult.groundDistance, z, 0, 1, 0)
                drawDebugPoint(x, y-groundRaycastResult.groundDistance, z, 1, 0, 0, 1)

                Utils.renderTextAtWorldPosition(x, y+0.1, z, string.format("%.4f", groundRaycastResult.groundDistance), getCorrectTextSize(0.02), 0)

                local attacherJoint = implement.object:getActiveInputAttacherJoint()
                if #attacherJoint.heightNodes > 0 then
                    for i=1, #attacherJoint.heightNodes do
                        local heightNode = attacherJoint.heightNodes[i]
                        local hx, hy, hz = getWorldTranslation(heightNode.node)
                        local ht = getTerrainHeightAtWorldPos(g_terrainNode, hx, hy, hz)
                        DebugGizmo.renderAtNode(heightNode.node, string.format("HeightNode: %.3f", hy-ht))
                    end
                end
            end
        end

        for _, attacherJoint in pairs(vehicle:getAttacherJoints()) do
            DebugGizmo.renderAtNode(attacherJoint.jointTransform, getName(attacherJoint.jointTransform), false, 0.3)

            if attacherJoint.bottomArm ~= nil and attacherJoint.bottomArm.referenceDistance ~= nil then
                  for index, width in pairs(AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY) do
                    local color = VehicleDebug.DEBUG_COLORS[index + 1]

                    -- unsupported widths are greyed out
                    if width < attacherJoint.bottomArm.minWidth or width > attacherJoint.bottomArm.maxWidth then
                        color = VehicleDebug.COLOR.GREY
                    end

                    local r, g, b = color:unpack()

                    local x1, y1, z1 = localToWorld(attacherJoint.bottomArm.translationNode, width * 0.5, 0, attacherJoint.bottomArm.referenceDistance * attacherJoint.bottomArm.zScale)
                    local x2, y2, z2 = localToWorld(attacherJoint.bottomArm.translationNode, -width * 0.5, 0, attacherJoint.bottomArm.referenceDistance * attacherJoint.bottomArm.zScale)
                    drawDebugLine(x1, y1-0.1, z1, r, g, b, x1, y1 + 0.1, z1, r, g, b, true)
                    drawDebugLine(x2, y2-0.1, z2, r, g, b, x2, y2 + 0.1, z2, r, g, b, true)

                    local radius = AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[index] * 0.5
                    DebugSphere.renderAtPosition(x1, y1, z1, radius, color, 10, true, false, nil)
                    DebugSphere.renderAtPosition(x2, y2, z2, radius, color, 10, true, false, nil)
                end
            end

            if attacherJoint.transNode ~= nil then
                if getVisibility(attacherJoint.transNode) then
                    local x, y, z = getWorldTranslation(attacherJoint.transNode)
                    local upX, upY, upZ    = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
                    local dirX, dirY, dirZ = localDirectionToWorld(attacherJoint.jointTransform, 0, 0, 1)
                    x, y, z = x - dirZ * 0.05, y + dirY * 0.05, z + dirX * 0.05

                    DebugBox.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, 0.2, attacherJoint.transNodeHeight, 0.3, Color.PRESETS.GREEN, true, nil, false)
                end
            end
        end
    end

    if vehicle.spec_attachable ~= nil then
        for _, inputAttacherJoint in pairs(vehicle:getInputAttacherJoints()) do
            if inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
                if inputAttacherJoint.bottomArm ~= nil then
                    for _, width in ipairs(inputAttacherJoint.bottomArm.widths) do
                        -- use closest category width for color
                        local nearestCategory = AttacherJoints.getClosestLowerLinkCategoryIndex(width)
                        local r, g, b = VehicleDebug.DEBUG_COLORS[nearestCategory + 1]:unpack()

                        local x1, y1, z1 = localToWorld(inputAttacherJoint.node, 0, 0, width * 0.5)
                        local x2, y2, z2 = localToWorld(inputAttacherJoint.node, 0, 0, -width * 0.5)
                        drawDebugLine(x1, y1-0.1, z1, r, g, b, x1, y1 + 0.1, z1, r, g, b, true)
                        drawDebugLine(x2, y2-0.1, z2, r, g, b, x2, y2 + 0.1, z2, r, g, b, true)

                        local radius = AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[nearestCategory] * 0.5
                        DebugSphere.renderAtPosition(x1, y1, z1, radius, VehicleDebug.DEBUG_COLORS[nearestCategory + 1], 10, true, false, nil)
                        DebugSphere.renderAtPosition(x2, y2, z2, radius, VehicleDebug.DEBUG_COLORS[nearestCategory + 1], 10, true, false, nil)
                    end
                end
            end
        end
    end

    -- draw fruit destruction areas
    if vehicle.spec_wheels ~= nil then
        for i, wheel in ipairs(vehicle:getWheels()) do
            wheel.destruction:drawAreas()
        end
    end

    -- display work areas
    if vehicle.spec_workArea ~= nil then
        local typedColor = {}
        local numTypes = 0
        for _, workArea in pairs(vehicle.spec_workArea.workAreas) do
            local color = typedColor[workArea.type]
            if color == nil then
                numTypes = numTypes + 1
                color = VehicleDebug.DEBUG_COLORS[numTypes]
                typedColor[workArea.type] = color
            end

            local startX, startY, startZ = getWorldTranslation(workArea.start)
            if startY < 0 then
                startY = -100
            else
                startY = getTerrainHeightAtWorldPos(g_terrainNode, startX, 0, startZ) + 0.1
            end

            local widthX, widthY, widthZ = getWorldTranslation(workArea.width)
            if widthY < 0 then
                widthY = -100
            else
                widthY = getTerrainHeightAtWorldPos(g_terrainNode, widthX, 0, widthZ) + 0.1
            end

            local heightX, heightY, heightZ = getWorldTranslation(workArea.height)
            if heightY < 0 then
                heightY = -100
            else
                heightY = getTerrainHeightAtWorldPos(g_terrainNode, heightX, 0, heightZ) + 0.1
            end

            DebugPlane.renderWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ, color, false)

            local x1, _, z1 = getWorldTranslation(workArea.start)
            local x2, _, z2 = getWorldTranslation(workArea.width)
            local x3, _, z3 = getWorldTranslation(workArea.height)
            local x = x3 + (x2-x3)*0.5
            local z = z3 + (z2-z3)*0.5
            local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
            if y < 0 then
                y = -100
            end

            local isActive = vehicle:getIsWorkAreaActive(workArea)
            local textColor = isActive and VehicleDebug.COLOR.ACTIVE or VehicleDebug.COLOR.INACTIVE

            Utils.renderTextAtWorldPosition(x, y, z, tostring(g_workAreaTypeManager:getWorkAreaTypeNameByIndex(workArea.type)), getCorrectTextSize(0.015), -getCorrectTextSize(0.015)*0.5, textColor)

            -- draw parallel line as reference for the ridge markers, so we can set the width properly
            if vehicle.spec_ridgeMarker ~= nil then
                if #vehicle.spec_ridgeMarker.ridgeMarkers > 0 then
                    if workArea.type == WorkAreaType.SOWINGMACHINE then
                        local width = calcDistanceFrom(workArea.start, workArea.width)
                        local length = calcDistanceFrom(workArea.start, workArea.height)
                        local dir1X, dir1Z = MathUtil.vector2Normalize(x1-x2, z1-z2)
                        local dir2X, dir2Z = MathUtil.vector2Normalize(x3-x1, z3-z1)

                        local cx = (x1 + x2) * 0.5
                        local cz = (z1 + z2) * 0.5

                        drawDebugLine(cx + dir1X * width, y, cz + dir1Z * width, 0, 1, 1, cx + dir1X * width + dir2X * length, y, cz + dir1Z * width + dir2Z * length, 0, 1, 1, true)
                        drawDebugLine(cx - dir1X * width, y, cz - dir1Z * width, 0, 1, 1, cx - dir1X * width + dir2X * length, y, cz - dir1Z * width + dir2Z * length, 0, 1, 1, true)
                    end
                end
            end
        end
    end

    -- display tip occlusion areas
    if vehicle.getTipOcclusionAreas ~= nil then
        for _, occlusionArea in pairs(vehicle:getTipOcclusionAreas()) do
            DebugPlane.renderWithNodes(occlusionArea.start, occlusionArea.width, occlusionArea.height, Color.PRESETS.YELLOW, true)
        end
    end

    if vehicle.spec_foliageBending ~= nil then
        local offset = 0.25
        for _, bendingNode in ipairs(vehicle.spec_foliageBending.bendingNodes) do
            DebugUtil.drawDebugRectangle(bendingNode.node, bendingNode.minX, bendingNode.maxX, bendingNode.minZ, bendingNode.maxZ, bendingNode.yOffset, 1, 0, 0)
            DebugUtil.drawDebugRectangle(bendingNode.node, bendingNode.minX-offset, bendingNode.maxX+offset, bendingNode.minZ-offset, bendingNode.maxZ+offset, bendingNode.yOffset, 0, 1, 0)
        end
    end

    if vehicle.spec_licensePlates ~= nil then
        local function drawLine(licensePlate, d1, d2, d3, leftRight)
            if math.abs(d1) ~= math.huge then
                local r1, g1, b1, maxY = 1, 0, 0, d2
                if d2 == math.huge then
                    r1, g1, b1 = 0, 1, 0
                    maxY = 0.25
                end
                local r2, g2, b2, minY = 1, 0, 0, d3
                if d3 == math.huge then
                    r2, g2, b2 = 0, 1, 0
                    minY = 0.25
                end

                local x1, y1, z1, x2, y2, z2
                if leftRight then
                    x1, y1, z1 = localToWorld(licensePlate.node, d1, maxY, 0)
                    x2, y2, z2 = localToWorld(licensePlate.node, d1, -minY, 0)
                else
                    x1, y1, z1 = localToWorld(licensePlate.node, maxY, d1, 0)
                    x2, y2, z2 = localToWorld(licensePlate.node, -minY, d1, 0)
                end

                drawDebugLine(x1, y1, z1, r1, g1, b1, x2, y2, z2, r2, g2, b2)
            end
        end

        for _, licensePlate in ipairs(vehicle.spec_licensePlates.licensePlates) do
            DebugGizmo.renderAtNode(licensePlate.node)

            local top, right, bottom, left = licensePlate.placementArea[1], licensePlate.placementArea[2], licensePlate.placementArea[3], licensePlate.placementArea[4]

            drawLine(licensePlate, right, top, bottom, true)
            drawLine(licensePlate, -left, top, bottom, true)

            drawLine(licensePlate, top, right, left, false)
            drawLine(licensePlate, -bottom, right, left, false)
        end
    end

    -- auto aim target node debugging
    if vehicle.spec_fillUnit ~= nil then
        local fillUnits = vehicle:getFillUnits()
        for i=1, #fillUnits do
            local fillUnit = fillUnits[i]

            local autoAimTarget = fillUnit.autoAimTarget
            if autoAimTarget.node ~= nil then
                if autoAimTarget.startZ ~= nil and autoAimTarget.endZ ~= nil then
                    local startFillLevel = fillUnit.capacity * autoAimTarget.startPercentage
                    local percent = math.clamp((fillUnit.fillLevel-startFillLevel) / (fillUnit.capacity-startFillLevel), 0, 1)
                    if autoAimTarget.invert then
                        percent = 1 - percent
                    end
                    local curZ = (autoAimTarget.endZ-autoAimTarget.startZ) * percent + autoAimTarget.startZ

                    local x1, y1, z1 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1], autoAimTarget.baseTrans[2], autoAimTarget.startZ)
                    local x2, y2, z2 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1], autoAimTarget.baseTrans[2], autoAimTarget.endZ)
                    drawDebugLine(x1, y1, z1, 0, 1, 0, x2, y2, z2, 0, 1, 0, true)

                    drawDebugLine(x1, y1, z1, 1, 0, 0, x1, y1 + 0.2, z1, 1, 0, 0, true)
                    drawDebugLine(x2, y2, z2, 1, 0, 0, x2, y2 + 0.2, z2, 1, 0, 0, true)

                    local x3, y3, z3 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1], autoAimTarget.baseTrans[2], curZ)
                    drawDebugLine(x3, y3, z3, 0, 0, 1, x3, y3 - 0.5, z3, 0, 0, 1, true)

                    local x4, y4, z4 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1] - 0.5, autoAimTarget.baseTrans[2], autoAimTarget.startZ + 0.75)
                    local x5, y5, z5 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1] + 0.5, autoAimTarget.baseTrans[2], autoAimTarget.startZ + 0.75)
                    drawDebugLine(x4, y4, z4, 0, 1, 1, x5, y5, z5, 0, 1, 1, true)

                    x4, y4, z4 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1] - 0.5, autoAimTarget.baseTrans[2], autoAimTarget.endZ - 0.75)
                    x5, y5, z5 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1] + 0.5, autoAimTarget.baseTrans[2], autoAimTarget.endZ - 0.75)
                    drawDebugLine(x4, y4, z4, 0, 1, 1, x5, y5, z5, 0, 1, 1, true)
                end
            end
        end
    end

    if vehicle.spec_dischargeable ~= nil then
        local dischargeNodes = vehicle.spec_dischargeable.dischargeNodes
        for i=1, #dischargeNodes do
            local dischargeNode = dischargeNodes[i]
            local info = dischargeNode.info
            local sx,sy,sz = localToWorld(info.node, -info.width, 0, info.zOffset)
            local ex,ey,ez = localToWorld(info.node, info.width, 0, info.zOffset)
            drawDebugLine(sx, sy, sz, 1, 0, 1, ex, ey, ez, 1, 0, 1)
        end
    end

    -- camera rotation and position debug
    if vehicle:getIsActiveForInput() then
        if vehicle.spec_enterable ~= nil then
            local spec = vehicle.spec_enterable
            local camera = spec.cameras[spec.camIndex]
            if camera ~= nil then
                local name = getName(camera.cameraPositionNode)
                local x, y, z = getTranslation(camera.cameraPositionNode)
                local rotationNode = camera.cameraPositionNode
                if camera.rotateNode ~= nil then
                    rotationNode = camera.rotateNode
                end

                local rx, ry, rz = getRotation(rotationNode)
                if camera.hasExtraRotationNode then
                    rx = -((math.pi - rx) % (2*math.pi))
                    ry = (ry + math.pi) % (2*math.pi)
                    rz = (rz - math.pi) % (2*math.pi)
                end

                local text =  string.format("camera '%s': translation: %.2f %.2f %.2f  rotation: %.2f %.2f %.2f", name, x, y, z, math.deg(rx), math.deg(ry), math.deg(rz))
                -- debug line to have a orientation for the camera rotation (visible part of cabin needs to be at the line)
                setTextAlignment(RenderText.ALIGN_CENTER)
                setTextColor(0, 0, 0, 1)
                renderText(0.5+g_pixelSizeX, 0.95-g_pixelSizeY, 0.02, text)
                renderText(0.5+g_pixelSizeX, 0.98-g_pixelSizeY, 0.05, "______________________________________________________________________")

                setTextColor(1, 1, 1, 1)
                renderText(0.5, 0.95, 0.02, text)
                renderText(0.5, 0.98, 0.05, "______________________________________________________________________")

                setTextAlignment(RenderText.ALIGN_LEFT)

            end
        end
    end

    -- display center of mass
    for i,component in pairs(vehicle.components) do
        local x,y,z = getCenterOfMass(component.node)
        x, y, z = localToWorld(component.node, x, y, z)
        local dirX, dirY, dirZ = localDirectionToWorld(component.node, 0,0,1)
        local upX, upY, upZ = localDirectionToWorld(component.node, 0,1,0)
        DebugGizmo.renderAtPosition(x,y,z, dirX, dirY, dirZ, upX, upY, upZ, "CoM comp" .. i, false, 0.7)
    end

    if vehicle.spec_ikChains ~= nil then
        IKUtil.debugDrawChains(vehicle.spec_ikChains.chains, true)
    end

    if vehicle.spec_powerTakeOffs ~= nil then
        for i=1, #vehicle.spec_powerTakeOffs.outputPowerTakeOffs do
            local powerTakeOffOutput = vehicle.spec_powerTakeOffs.outputPowerTakeOffs[i]
            if powerTakeOffOutput.outputNode ~= nil then
                local size = 0.25
                local x, y, z = getWorldTranslation(powerTakeOffOutput.outputNode)
                local dirX, dirY, dirZ = localDirectionToWorld(powerTakeOffOutput.outputNode, 0, 0, 1)
                local upX, upY, upZ = localDirectionToWorld(powerTakeOffOutput.outputNode, 0, 1, 0)
                drawDebugLine(x, y, z, 0, 1, 0, x+upX*size, y+upY*size, z+upZ*size, 0, 1, 0)
                drawDebugLine(x, y, z, 0, 0, 1, x+dirX*size, y+dirY*size, z+dirZ*size, 0, 0, 1)

                if powerTakeOffOutput.connectedInput ~= nil then
                    local x, y, z = localToWorld(powerTakeOffOutput.outputNode, 0, 0, -0.05)
                    local upX, upY, upZ = localDirectionToWorld(powerTakeOffOutput.outputNode, 0, 1, 0)
                    local dirX, dirY, dirZ = localDirectionToWorld(powerTakeOffOutput.outputNode, 0, 0, -1)

                    DebugBox.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, powerTakeOffOutput.connectedInput.size, powerTakeOffOutput.connectedInput.size, 0.1, Color.PRESETS.YELLOW, true, nil, false)
                end
            end
        end
    end

    if vehicle.spec_connectionHoses ~= nil then
        for i=1, #vehicle.spec_connectionHoses.targetNodes do
            local targetNode = vehicle.spec_connectionHoses.targetNodes[i]

            local size = 0.1
            local x, y, z = getWorldTranslation(targetNode.node)
            local dirX, dirY, dirZ = localDirectionToWorld(targetNode.node, 0, 0, -1)
            local upX, upY, upZ = localDirectionToWorld(targetNode.node, 0, 1, 0)
            drawDebugLine(x, y, z, 0, 1, 0, x+upX*size, y+upY*size, z+upZ*size, 0, 1, 0)
            drawDebugLine(x, y, z, 0, 0, 1, x+dirX*size, y+dirY*size, z+dirZ*size, 0, 0, 1)
        end
    end

    if vehicle.spec_mountable ~= nil then
        if vehicle.spec_mountable.dynamicMountJointTransY ~= nil then
            DebugUtil.drawDebugRectangle(vehicle.rootNode, -vehicle.size.width * 0.5, vehicle.size.width * 0.5, -vehicle.size.length * 0.5, vehicle.size.length * 0.5, vehicle.spec_mountable.dynamicMountJointTransY, 0, 1, 0, 0.2, true)
        end

        if vehicle.spec_mountable.additionalMountDistance ~= 0 then
            DebugUtil.drawDebugRectangle(vehicle.rootNode, -vehicle.size.width * 0.5, vehicle.size.width * 0.5, -vehicle.size.length * 0.5, vehicle.size.length * 0.5, vehicle.spec_mountable.additionalMountDistance, 1, 1, 0, 0.2, true)
        end
    end
end


---
function VehicleDebug.drawDebugAIRendering(vehicle)
    local function formatNumber(value)
        if math.abs(value) < 0.001 then
            return "0.0"
        elseif math.abs(value) < 0.01 then
            return string.format("%.3f", value)
        elseif math.abs(value) < 0.1 then
            return string.format("%.2f", value)
        else
            return string.format("%.1f", value)
        end
    end

    local function getClosestOffset(node, useZOffset, useZOffsetFront)
        local aiRootNode = nil
        if vehicle.rootVehicle.getAIRootNode ~= nil then
            aiRootNode = vehicle.rootVehicle:getAIRootNode()
        else
            aiRootNode = vehicle.rootNode
        end

        local min, max = -math.huge, math.huge
        if vehicle.spec_workArea ~= nil then
            local nodeOffset, _, nodeOffsetZ  = localToLocal(node, aiRootNode, 0, 0, 0)

            for _, workArea in pairs(vehicle.spec_workArea.workAreas) do
                if useZOffset == true then
                    local _, _, offset = localToLocal(workArea.height, aiRootNode, 0, 0, 0)
                    offset = nodeOffsetZ - offset
                    if offset > 0 then
                        max = math.min(max, offset)
                    else
                        min = math.max(min, offset)
                    end
                elseif useZOffsetFront == true then
                    local _, _, offset1 = localToLocal(workArea.start, aiRootNode, 0, 0, 0)
                    offset1 = nodeOffsetZ - offset1
                    if offset1 > 0 then
                        max = math.min(max, offset1)
                    else
                        min = math.max(min, offset1)
                    end

                    local _, _, offset2 = localToLocal(workArea.width, aiRootNode, 0, 0, 0)
                    offset2 = nodeOffsetZ - offset2
                    if offset2 > 0 then
                        max = math.min(max, offset2)
                    else
                        min = math.max(min, offset2)
                    end
                else
                    local offset1, _, _ = localToLocal(workArea.start, aiRootNode, 0, 0, 0)
                    offset1 = nodeOffset - offset1
                    if offset1 > 0 then
                        max = math.min(max, offset1)
                    else
                        min = math.max(min, offset1)
                    end

                    local offset2, _, _ = localToLocal(workArea.width, aiRootNode, 0, 0, 0)
                    offset2 = nodeOffset - offset2
                    if offset2 > 0 then
                        max = math.min(max, offset2)
                    else
                        min = math.max(min, offset2)
                    end

                    local offset3, _, _ = localToLocal(workArea.height, aiRootNode, 0, 0, 0)
                    offset3 = nodeOffset - offset3
                    if offset3 > 0 then
                        max = math.min(max, offset3)
                    else
                        min = math.max(min, offset3)
                    end
                end
            end
        end

        if math.abs(min) < math.abs(max) then
            return formatNumber(min)
        else
            return formatNumber(max)
        end
    end

    local drawDebugNode = function(node, text, yOffset)
        local x, y, z = getWorldTranslation(node)
        local t = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
        if y < 0 then
            t = -100
        end
        local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
        local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
        DebugGizmo.renderAtPosition(x, t + (yOffset or 0), z, dirX, dirY, dirZ, upX, upY, upZ, text, false, 0.5)
    end

    if vehicle.getAIMarkers ~= nil then
        if vehicle:getCanImplementBeUsedForAI() then
            local leftMarker, rightMarker, backMarker = vehicle:getAIMarkers()

            drawDebugNode(leftMarker, string.format("%s (x%sm z%sm)", getName(leftMarker), getClosestOffset(leftMarker), getClosestOffset(leftMarker, false, true)))
            drawDebugNode(rightMarker, string.format("%s (x%sm z%sm)", getName(rightMarker), getClosestOffset(rightMarker), getClosestOffset(rightMarker, false, true)))
            drawDebugNode(backMarker, string.format("%s (z%sm)", getName(backMarker), getClosestOffset(backMarker, true)))

            local reverserNode = vehicle:getAIToolReverserDirectionNode()
            if reverserNode ~= nil then
                local sideOffset, _
                if vehicle.rootVehicle.getAIRootNode ~= nil then
                    local aiRootNode = vehicle.rootVehicle:getAIRootNode()
                    sideOffset, _, _ = localToLocal(reverserNode, aiRootNode, 0, 0, 0)
                end

                local name = ""
                if reverserNode ~= backMarker then
                    name = " " .. getName(reverserNode)
                end

                drawDebugNode(reverserNode, string.format("reverser%s (x%sm)", name, formatNumber(sideOffset or 0)), 0.3)
            end
        end

        if not vehicle:getIsAIActive() then
            local collisionTrigger = vehicle:getAIImplementCollisionTrigger()
            if collisionTrigger ~= nil and collisionTrigger.node ~= nil then
                local x, y, z = getWorldTranslation(collisionTrigger.node)
                local t = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
                if y < 0 then
                    t = -100
                end
                local offsetY = y - t - (collisionTrigger.height * 0.5)

                DebugUtil.drawDebugCube(collisionTrigger.node, collisionTrigger.width, collisionTrigger.height, collisionTrigger.length, 0, 0, 1, 0, -offsetY, collisionTrigger.length * 0.5)
            end
        end

        local IsOnlyAIImplement = true
        for _, vehicle2 in ipairs(vehicle.rootVehicle.childVehicles) do
            if vehicle2 ~= vehicle and vehicle2.getCanImplementBeUsedForAI ~= nil and vehicle2:getCanImplementBeUsedForAI() then
                IsOnlyAIImplement = false
                break
            end
        end

        if IsOnlyAIImplement or vehicle:getIsSelected() then
            if vehicle.spec_aiImplement ~= nil then
                if vehicle.spec_aiImplement.debugArea ~= nil then
                    g_debugManager:addFrameElement(vehicle.spec_aiImplement.debugArea)
                end
            end
        end
    end

    if vehicle.drawDebugAIAgent ~= nil then
        vehicle:drawDebugAIAgent()
    end

    if vehicle.drawAIAgentAttachments ~= nil then
        vehicle:drawAIAgentAttachments()
    end

    if Platform.gameplay.automaticVehicleControl then
        local root = vehicle.rootVehicle
        if root.getIsControlled ~= nil and root:getIsControlled() then
            if root.actionController ~= nil then
                root.actionController:drawDebugRendering()
            end
        end
    end
end


---
function VehicleDebug.drawDebugValues(vehicle)
    local information = {}
    for k,v in ipairs(vehicle.specializations) do
        if v.updateDebugValues ~= nil then
            local values = {}
            v.updateDebugValues(vehicle, values)
            if #values > 0 then
                local info = {}
                info.title = vehicle.specializationNames[k]
                info.content = values
                table.insert(information, info)
            end
        end
    end

    local d = DebugInfoTable.new()
    d:createWithNodeToCamera(vehicle.rootNode, information, 4, 0.05)
    g_debugManager:addFrameElement(d)
end


---
function VehicleDebug.drawSoundDebugValues(vehicle)
    local x = 0.15
    local y = 0.1
    local width = 0.7
    local height = 0.8

    local textSize = 0.015

    local xSectionWidth = 0.1 + g_pixelSizeX

    local lineHeight = 0.06

    local drawBar = function(x, y, w, h, value, fixedValue, text, r, g, b, a, textSizeFactor)
        drawOutlineRect(x, y, w, h, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
        drawFilledRect(x+g_pixelSizeX, y+g_pixelSizeY, w-g_pixelSizeX*2, h-g_pixelSizeY*2, 0, 0, 0, 0.4)

        drawFilledRect(x+g_pixelSizeX, y+g_pixelSizeY, w * value -g_pixelSizeX*2, h-g_pixelSizeY*2, r, g, b, a)

        if fixedValue ~= -1 then
            drawFilledRect(x + w * fixedValue, y, g_pixelSizeX, h, 1, 0, 0, 1)
        end

        setTextAlignment(RenderText.ALIGN_CENTER)

        renderText(x + w * 0.5, y + h - textSize * 0.5 - g_pixelSizeY * 4, textSize * 0.8 * (textSizeFactor or 1), text)
    end

    local drawModifiers = function(x, y, w, h, sample, attribute)
        local modifiers = {}

        for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
            local changeValue, t, available = g_soundManager:getSampleModifierValue(sample, attribute, typeIndex)

            if available then
                table.insert(modifiers, {changeValue=changeValue, t=t, name=type.name})
            end
        end

        if sample.maxValuePerModifier == nil then
            sample.maxValuePerModifier = {}
            for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
                sample.maxValuePerModifier[type.name] = 0
            end
        end

        local numModifiers = #modifiers
        if numModifiers > 0 then
            local widthPerModifier = w / numModifiers
            for i=1, numModifiers do
                local modifier = modifiers[i]
                sample.maxValuePerModifier[modifier.name] = math.max(sample.maxValuePerModifier[modifier.name], modifier.changeValue, 1)
                drawBar(x + widthPerModifier * (i - 1), y, widthPerModifier * (i<numModifiers and 0.95 or 1), h, modifier.changeValue / sample.maxValuePerModifier[modifier.name], -1, string.format("%s raw:%.2f mod:%.2f", modifier.name, modifier.t, modifier.changeValue), 0, 0.5, 0, 0.3, 0.7)
            end
        end
    end

    setTextColor(1, 1, 1, 1)

    local i = 1
    local lineY = y + height
    for _, sample in pairs(g_soundManager.orderedSamples) do
        local isSurfaceSound = false
        for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
            if surfaceSound.name == sample.sampleName then
                isSurfaceSound = true
            end
        end

        if sample.modifierTargetObject == vehicle and not isSurfaceSound then
            local showSample = sample.isGlsFile
            if not showSample then
                for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
                    for _, attribute in pairs({"volume", "pitch", "lowpassGain"}) do
                        local _, _, available = g_soundManager:getSampleModifierValue(sample, attribute, typeIndex)
                        showSample = showSample or available

                        if showSample then
                            break
                        end
                    end
                end
            end

            if showSample then
                lineY = lineY - lineHeight
                drawOutlineRect(x, lineY, xSectionWidth, lineHeight + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                drawOutlineRect(x, lineY, width, lineHeight + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                drawFilledRect(x, lineY, xSectionWidth, lineHeight, 0, g_soundManager:getIsSamplePlaying(sample) and 1 or 0, 0, 0.4)

                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(x + xSectionWidth * 0.5, lineY + lineHeight - (lineHeight * 0.2 * 1) - textSize * 0.5, textSize * 1.2, sample.sampleName)
                if sample.isGlsFile then
                    renderText(x + xSectionWidth * 0.5, lineY + lineHeight - (lineHeight * 0.2 * 2) - textSize * 0.5, textSize * 0.8, string.format("loopSyn: rpm=%d load=%d%%", getSampleLoopSynthesisRPM(sample.soundSample, false), getSampleLoopSynthesisLoadFactor(sample.soundSample) * 100))
                end

                setTextAlignment(RenderText.ALIGN_RIGHT)
                renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + lineHeight - (lineHeight * 0.25 * 1) - textSize * 0.5, textSize, "volume:")
                renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + lineHeight - (lineHeight * 0.25 * 2) - textSize * 0.5, textSize, "pitch:")
                renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + lineHeight - (lineHeight * 0.25 * 3) - textSize * 0.5, textSize, "lowpassGain:")

                local modVolume = g_soundManager:getModifierFactor(sample, "volume")
                sample.debugMaxVolume = math.max((sample.debugMaxVolume or 1), sample.current.volume * modVolume, sample.current.volume)
                local barX, barY, barW, barH = x + xSectionWidth + xSectionWidth * 0.7, lineY + lineHeight - (lineHeight * 0.25 * 1) - textSize * 0.5, xSectionWidth, textSize
                drawBar(barX, barY, barW, barH, (sample.current.volume * modVolume) / sample.debugMaxVolume, sample.current.volume / sample.debugMaxVolume, string.format("%.2f", sample.current.volume * modVolume), 0, 0.5, 0, 0.4)

                local startX = barX + barW + xSectionWidth * 0.1
                drawModifiers(startX, barY, 1 - startX - x - xSectionWidth * 0.1, barH, sample, "volume")

                local modPitch = g_soundManager:getModifierFactor(sample, "pitch")
                sample.debugMaxPitch = math.max((sample.debugMaxPitch or 1), sample.current.pitch * modPitch, sample.current.pitch)
                barX, barY, barW, barH = x + xSectionWidth + xSectionWidth * 0.7, lineY + lineHeight - (lineHeight * 0.25 * 2) - textSize * 0.5, xSectionWidth, textSize
                drawBar(barX, barY, barW, barH, (sample.current.pitch * modPitch) / sample.debugMaxPitch, sample.current.pitch / sample.debugMaxPitch, string.format("%.2f", sample.current.pitch * modPitch), 0.5, 0.5, 0, 0.4)

                startX = barX + barW + xSectionWidth * 0.1
                drawModifiers(startX, barY, 1 - startX - x, barH, sample, "pitch")

                local modLowPassGain = g_soundManager:getModifierFactor(sample, "lowpassGain")
                sample.debugMaxLowPass = math.max((sample.debugMaxLowPass or 1), sample.current.lowpassGain * modLowPassGain, sample.current.lowpassGain)
                barX, barY, barW, barH = x + xSectionWidth + xSectionWidth * 0.7, lineY + lineHeight - (lineHeight * 0.25 * 3) - textSize * 0.5, xSectionWidth, textSize
                drawBar(barX, barY, barW, barH, (sample.current.lowpassGain * modLowPassGain) / sample.debugMaxLowPass, sample.current.lowpassGain / sample.debugMaxLowPass, string.format("%.2f", sample.current.lowpassGain * modLowPassGain), 0, 0.5, 0.5, 0.4)

                startX = barX + barW + xSectionWidth * 0.1
                drawModifiers(startX, barY, 1 - startX - x, barH, sample, "lowpassGain")
            end

            i = i + 1
        end
    end

    local wheelsSpec = vehicle.spec_wheels
    if wheelsSpec then
        local wx,wy,wz = getWorldTranslation(vehicle.rootNode)
        Utils.renderTextAtWorldPosition(wx,wy,wz, string.format("surfaceSound: %s", wheelsSpec.currentSurfaceSound and wheelsSpec.currentSurfaceSound.sampleName or "none"), 0.01)
    end

    setTextAlignment(RenderText.ALIGN_LEFT)

    VehicleDebug.drawMotorLoadGraph(vehicle, 0.2, 0.05, 0.25, 0.2)
    VehicleDebug.drawMotorRPMGraph(vehicle, 0.55, 0.05, 0.25, 0.2)
    VehicleDebug.drawMotorAccelerationGraph(vehicle, 0.2, 0.28, 0.25, 0.1)
end


---
function VehicleDebug.drawAnimationDebug(vehicle)
    if vehicle.playAnimation ~= nil then
        local x = 0.15
        local y = 0.1
        local width = 0.7
        local height = 0.8

        local textSize = 0.015
        local textSize2 = 0.01

        local timeLineOffset = 0.1 + g_pixelSizeX
        local timeLineWidth = width - timeLineOffset - g_pixelSizeX * 2

        local lineHeight = 0.05
        local lineHeightPart = lineHeight * 0.25

        local numAnims = 0
        local spec = vehicle.spec_animatedVehicle
        for _, animation in pairs(spec.animations) do
            if #animation.parts > 0 then
                numAnims = numAnims + 1
            end
        end

        local selected = VehicleDebug.selectedAnimation % numAnims + 1

        setTextColor(1, 1, 1, 1)

        local i = 1
        local lineY = y + height
        for name, animation in pairs(spec.animations) do
            if #animation.parts > 0 then
                lineY = lineY - lineHeight
                drawOutlineRect(x, lineY, width, lineHeight + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                drawFilledRect(x, lineY, width, lineHeight, 0, 0, 0, 0.4)

                drawFilledRect(x + timeLineOffset - g_pixelSizeX, lineY, g_pixelSizeX, lineHeight, 0, 0, 0, 1)

                local widthPerMs = timeLineWidth / animation.duration

                local divider = 1000
                if animation.duration < 2000 then
                    divider = 500
                end
                if animation.duration < 1000 then
                    divider = 100
                end

                for j=1, math.floor(animation.duration / divider) do
                    if j * divider ~= animation.duration then
                        setTextAlignment(RenderText.ALIGN_CENTER)
                        renderText(x + timeLineOffset + widthPerMs * j * divider, lineY + lineHeight * 0.5 - textSize2 * 0.5, textSize2, string.format("%.1f", j * divider / 1000))
                        drawFilledRect(x + timeLineOffset + widthPerMs * j * divider, lineY, g_pixelSizeX, lineHeight * 0.3, 0, 0, 0, 1)
                    end
                end

                setTextBold(selected == i)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(x + timeLineOffset * 0.5, lineY + lineHeight * 0.5 - textSize * 0.5, textSize, name)
                setTextBold(false)

                local startLineY = lineY
                if selected == i then
                    if animation.lineHeightByPart == nil then
                        animation.lineHeightByPart = {}
                    else
                        for k, _ in pairs(animation.lineHeightByPart) do
                            animation.lineHeightByPart[k] = nil
                        end
                    end

                    for animPartIndex=1, #animation.parts do
                        local part = animation.parts[animPartIndex]

                        local animValue = part.animationValues[1]
                        local index = animValue.node or animValue.componentJoint
                        if index ~= nil and animation.lineHeightByPart[index] == nil then
                            lineY = lineY - lineHeightPart
                            drawOutlineRect(x, lineY, width, lineHeightPart + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                            drawFilledRect(x, lineY, width, lineHeightPart, 0, 0, 0, 0.2)

                            drawFilledRect(x + timeLineOffset - g_pixelSizeX, lineY, g_pixelSizeX, lineHeightPart, 0, 0, 0, 1)

                            local partName = "unknown"
                            if animValue.node ~= nil then
                                partName = string.format("node '%s'", getName(animValue.node))
                            elseif animValue.componentJoint ~= nil then
                                partName = string.format("compJoint '%d'", animValue.componentJoint.index)
                            end

                            setTextAlignment(RenderText.ALIGN_CENTER)
                            renderText(x + timeLineOffset * 0.5, lineY + lineHeightPart * 0.5 - textSize2 * 0.5 + g_pixelSizeY * 2, textSize2, partName)

                            animation.lineHeightByPart[index] = lineY
                        end
                    end

                    if #animation.samples > 0 then
                        local headTextSize = textSize2 * 1.5
                        local headLineHeight = lineHeightPart * 1.5
                        lineY = lineY - headLineHeight
                        drawOutlineRect(x, lineY, width, headLineHeight + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                        drawFilledRect(x, lineY, width, headLineHeight, 0, 0, 0, 0.2)

                        setTextAlignment(RenderText.ALIGN_CENTER)
                        renderText(x + width / 2, lineY + headLineHeight * 0.5 - headTextSize * 0.5 + g_pixelSizeY * 2, headTextSize, "Sounds:")
                    end

                    local sampleTimesPerSample = {}
                    for j=1, #animation.samples do
                        local sample = animation.samples[j]

                        if sampleTimesPerSample[sample.filename] == nil then
                            sampleTimesPerSample[sample.filename] = {}
                        end

                        table.insert(sampleTimesPerSample[sample.filename], {sample=sample, startTime=sample.startTime, endTime=sample.endTime, loops=sample.loops, direction=sample.direction})
                    end

                    for filename, times in pairs(sampleTimesPerSample) do
                        lineY = lineY - lineHeightPart
                        drawOutlineRect(x, lineY, width, lineHeightPart + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                        drawFilledRect(x, lineY, width, lineHeightPart, 0, 0, 0, 0.2)
                        drawFilledRect(x + timeLineOffset - g_pixelSizeX, lineY, g_pixelSizeX, lineHeightPart, 0, 0, 0, 1)

                        local sampleName = "unknown"

                        for timesIndex=1, #times do
                            local timeData = times[timesIndex]
                            sampleName = timeData.sample.templateName or timeData.sample.sampleName

                            local r, g, b, a = 0, 0, 0, 0.9
                            if g_soundManager:getIsSamplePlaying(timeData.sample) then
                                g = 1

                                if timeData.loops == 1 then
                                    r = 1
                                end
                            end

                            local minX, maxX = x + timeLineOffset, x + width
                            local rx, ry, rwidth, rheight = 0, lineY + (lineHeightPart * 0.1) + g_pixelSizeY, 0, lineHeightPart * 0.8 - g_pixelSizeY
                            if timeData.startTime ~= nil and timeData.endTime == nil then
                                rx = math.max(minX, x + timeLineOffset + widthPerMs * timeData.startTime - widthPerMs * 25)
                                rwidth = widthPerMs * 50
                                rwidth = rwidth + math.min(maxX - (rx + rwidth), 0)
                            elseif timeData.startTime ~= nil and timeData.endTime ~= nil and timeData.loops == 0 then
                                rx = x + timeLineOffset + widthPerMs * timeData.startTime + widthPerMs * 5
                                rwidth = widthPerMs * (timeData.endTime - timeData.startTime) - widthPerMs * 10
                            elseif timeData.startTime ~= nil and timeData.endTime ~= nil and timeData.loops == 1 then
                                rx = math.max(minX, x + timeLineOffset + widthPerMs * timeData.startTime - widthPerMs * 25)
                                rwidth = widthPerMs * 50
                                rwidth = rwidth + math.min(maxX - (rx + rwidth), 0)
                                drawFilledRect(rx, ry, rwidth, rheight, r, g, b, a)

                                rx = math.max(minX, x + timeLineOffset + widthPerMs * timeData.endTime - widthPerMs * 25)
                                rwidth = widthPerMs * 50
                                rwidth = rwidth + math.min(maxX - (rx + rwidth), 0)
                            end

                            drawFilledRect(rx, ry, rwidth, rheight, r, g, b, a)
                        end

                        setTextAlignment(RenderText.ALIGN_CENTER)
                        renderText(x + timeLineOffset * 0.5, lineY + lineHeightPart * 0.5 - textSize2 * 0.5 + g_pixelSizeY * 2, textSize2, sampleName)
                    end


                    for animPartIndex=1, #animation.parts do
                        local part = animation.parts[animPartIndex]
                        local animValue = part.animationValues[1]
                        local index = animValue.node or animValue.componentJoint
                        if index ~= nil then
                            drawFilledRect(x + timeLineOffset + widthPerMs * part.startTime, animation.lineHeightByPart[index] + (lineHeightPart * 0.1) + g_pixelSizeY, widthPerMs * part.duration, lineHeightPart * 0.8 - g_pixelSizeY, 0, 0, 0, 0.9)
                        end
                    end
                end

                drawFilledRect(x + timeLineOffset + widthPerMs * animation.currentTime, lineY, g_pixelSizeX, (startLineY - lineY) + lineHeight * 0.7, 0, 1, 0, 1)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(x + timeLineOffset + widthPerMs * animation.currentTime, lineY + (startLineY - lineY) + lineHeight * 0.9 - textSize2 * 0.5, textSize2, string.format("%.2f", animation.currentTime / 1000))

                i = i + 1
            end
        end

        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end


---
function VehicleDebug.updateTuningDebugRendering(vehicle, dt)
    if vehicle.propertyState == VehiclePropertyState.SHOP_CONFIG then
        local visualWheelIndex = 0
        local wheels = vehicle:getWheels()
        for i=1, #wheels do
            local wheel = wheels[i]

            local x, y, z = getWorldTranslation(wheels[i].driveNodeDirectionNode)
            local offset
            if y < 50 then
                offset = y + 100
            else
                offset = y - getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
            end

            -- height from the ground
            drawDebugLine(x, y - wheel.physics.radius, z, 0, 1, 0, x, y, z, 0, 1, 0, false)
            Utils.renderTextAtWorldPosition(x, y - wheel.physics.radius * 0.5, z, string.format("%.3f", offset), getCorrectTextSize(0.012), 0, 0, 1, 0, 1)

            for _, visualWheel in ipairs(wheel.visualWheels) do
                for _, visualWheelPart in ipairs(visualWheel.visualParts) do
                    if visualWheelPart:isa(WheelVisualPartTire) then
                        -- center width
                        local ox, oy, oz = localToLocal(visualWheelPart.node, wheel.node, 0, 0, 0)
                        local wx, wy, wz = localToWorld(visualWheelPart.node, 0, 0, 0)
                        local cx, cy, cz = localToWorld(wheel.node, 0, oy, oz)

                        drawDebugLine(wx, wy, wz, 1, 0, 0, cx, cy, cz, 1, 0, 0, false)
                        Utils.renderTextAtWorldPosition(wx, wy, wz, string.format("%.3f", math.abs(ox) * 2), getCorrectTextSize(0.012), 0, 1, 0, 0, 1)

                        -- outside width
                        local widthOffset = visualWheel.width * 0.5 * (wheel.isLeft and 1 or -1)
                        ox, oy, oz = localToLocal(visualWheelPart.node, wheel.node, widthOffset, 0, 0)
                        wx, wy, wz = localToWorld(visualWheelPart.node, widthOffset, 0, 0)
                        drawDebugLine(wx, wy - 0.1, wz, 0, 1, 1, wx, wy + 0.1, wz, 0, 1, 1, false)
                        Utils.renderTextAtWorldPosition(wx, wy, wz, string.format("%.3f", math.abs(ox) * 2), getCorrectTextSize(0.012), 0, 0, 1, 1, 1)
                    end
                end

                renderText(0.25, 0.1 + 0.02 * visualWheelIndex, 0.018, string.format("%d - %s (%s)", i, visualWheel.externalXMLFilename, visualWheel.externalConfigId))
                visualWheelIndex = visualWheelIndex + 1
            end
        end
    end
end


---
function VehicleDebug.consoleCommandAnalyze(unusedSelf)
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil and g_localPlayer:getCurrentVehicle().isServer then

        local self = g_localPlayer:getCurrentVehicle():getSelectedVehicle()
        if self == nil then
            self = g_localPlayer:getCurrentVehicle()
        end

        print("Analyzing vehicle '"..self.configFileName.."'. Make sure vehicle is standing on a flat plane parallel to xz-plane")

        local groundRaycastResult = {
            raycastCallback = function (self, transformId, x, y, z, distance, nx, ny, nz)
                if self.vehicle.vehicleNodes[transformId] ~= nil then
                    return true
                end
                if self.vehicle.aiTrafficCollisionTrigger == transformId then
                    return true
                end

                if transformId ~= g_terrainNode then
                    printWarning("Warning: Vehicle is not standing on ground! " .. getName(transformId))
                end

                self.groundDistance = distance
                return false
            end
        }
        if self.spec_attacherJoints ~= nil then
            for i, attacherJoint in ipairs(self.spec_attacherJoints.attacherJoints) do
                local trx, try, trz = getRotation(attacherJoint.jointTransform)
                setRotation(attacherJoint.jointTransform, unpack(attacherJoint.jointOrigRot))
                if attacherJoint.rotationNode ~= nil or attacherJoint.rotationNode2 ~= nil then
                    local rx,ry,rz
                    if attacherJoint.rotationNode ~= nil then
                        rx,ry,rz = getRotation(attacherJoint.rotationNode)
                    end
                    local rx2,ry2,rz2
                    if attacherJoint.rotationNode2 ~= nil then
                        rx2,ry2,rz2 = getRotation(attacherJoint.rotationNode2)
                    end

                    -- test max rot
                    if attacherJoint.rotationNode ~= nil then
                        setRotation(attacherJoint.rotationNode, unpack(attacherJoint.lowerRotation))
                    end
                    if attacherJoint.rotationNode2 ~= nil then
                        setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.lowerRotation2))
                    end
                    local x,y,z = getWorldTranslation(attacherJoint.jointTransform)
                    groundRaycastResult.groundDistance = 0
                    groundRaycastResult.vehicle = self
                    raycastAll(x, y, z, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, 0xFFFF_FFFF)
                    if math.abs(groundRaycastResult.groundDistance - attacherJoint.lowerDistanceToGround) > 0.01 then
                        print(string.format(" Issue found: Attacher joint %d has invalid lowerDistanceToGround. True value is: %.3f (Value in xml: %.3f)", i, MathUtil.round(groundRaycastResult.groundDistance, 3), attacherJoint.lowerDistanceToGround))
                    end
                    if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil then
                        local _,dy,_ = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
                        local angle = math.deg(math.acos(math.clamp(dy, -1, 1)))
                        local _,dxy,_ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)
                        if dxy < 0 then
                            angle = -angle
                        end
                        if math.abs(angle-math.deg(attacherJoint.lowerRotationOffset)) > 0.1 then
                            print(string.format(" Issue found: Attacher joint %d has invalid lowerRotationOffset. True value is: %.2f° (Value in xml: %.2f°)", i, angle, math.deg(attacherJoint.lowerRotationOffset)))
                        end
                    end

                    -- test min rot
                    if attacherJoint.rotationNode ~= nil then
                        setRotation(attacherJoint.rotationNode, unpack(attacherJoint.upperRotation))
                    end
                    if attacherJoint.rotationNode2 ~= nil then
                        setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.upperRotation2))
                    end
                    x,y,z = getWorldTranslation(attacherJoint.jointTransform)
                    groundRaycastResult.groundDistance = 0
                    raycastAll(x, y, z, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, 0xFFFF_FFFF)
                    if math.abs(groundRaycastResult.groundDistance - attacherJoint.upperDistanceToGround) > 0.01 then
                        print(string.format(" Issue found: Attacher joint %d has invalid upperDistanceToGround. True value is: %.3f (Value in xml: %.3f)", i, MathUtil.round(groundRaycastResult.groundDistance, 3), attacherJoint.upperDistanceToGround))
                    end
                    if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil then
                        local _,dy,_ = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
                        local angle = math.deg(math.acos(math.clamp(dy, -1, 1)))
                        local _,dxy,_ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)
                        if dxy < 0 then
                            angle = -angle
                        end
                        if math.abs(angle-math.deg(attacherJoint.upperRotationOffset)) > 0.1 then
                            print(string.format(" Issue found: Attacher joint %d has invalid upperRotationOffset. True value is: %.2f° (Value in xml: %.2f°)", i, angle, math.deg(attacherJoint.upperRotationOffset)))
                        end
                    end

                    -- reset rotations
                    if attacherJoint.rotationNode ~= nil then
                        setRotation(attacherJoint.rotationNode, rx,ry,rz)
                    end
                    if attacherJoint.rotationNode2 ~= nil then
                        setRotation(attacherJoint.rotationNode2, rx2,ry2,rz2)
                    end
                end
                setRotation(attacherJoint.jointTransform, trx, try, trz)

                if attacherJoint.transNode ~= nil then
                    local sx,sy,sz = getTranslation(attacherJoint.transNode)

                    local _, y, _ = localToLocal(self.rootNode, getParent(attacherJoint.transNode), 0, attacherJoint.transNodeMinY, 0)
                    setTranslation(attacherJoint.transNode, sx,y,sz)

                    groundRaycastResult.groundDistance = 0
                    groundRaycastResult.vehicle = self
                    local wx,wy,wz = getWorldTranslation(attacherJoint.transNode)
                    raycastAll(wx,wy,wz, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, 0xFFFF_FFFF)
                    if math.abs(groundRaycastResult.groundDistance - attacherJoint.lowerDistanceToGround) > 0.02 then
                        print(string.format(" Issue found: Attacher joint %d has invalid lowerDistanceToGround. True value is: %.3f (Value in xml: %.3f)", i, MathUtil.round(groundRaycastResult.groundDistance, 3), attacherJoint.lowerDistanceToGround))
                    end

                    _, y, _ = localToLocal(self.rootNode, getParent(attacherJoint.transNode), 0, attacherJoint.transNodeMaxY, 0)
                    setTranslation(attacherJoint.transNode, sx,y,sz)

                    groundRaycastResult.groundDistance = 0
                    wx,wy,wz = getWorldTranslation(attacherJoint.transNode)
                    raycastAll(wx,wy,wz, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, 0xFFFF_FFFF)
                    if math.abs(groundRaycastResult.groundDistance - attacherJoint.upperDistanceToGround) > 0.02 then
                        print(string.format(" Issue found: Attacher joint %d has invalid upperDistanceToGround. True value is: %.3f (Value in xml: %.3f)", i, MathUtil.round(groundRaycastResult.groundDistance, 3), attacherJoint.upperDistanceToGround))
                    end

                    setTranslation(attacherJoint.transNode, sx,sy,sz)
                end
            end
        end

        if self.spec_wheels ~= nil then
            for i, wheel in ipairs(self.spec_wheels.wheels) do
                if wheel.physics.wheelShapeCreated then
                    local _,comY,_ = getCenterOfMass(wheel.node)

                    local forcePointY = wheel.physics.positionY + wheel.physics.deltaY - wheel.physics.radius * wheel.physics.forcePointRatio
                    if forcePointY > comY then
                        print(string.format(" Issue found: Wheel %d has force point higher than center of mass. %.2f > %.2f. This can lead to undesired driving behavior (inward-leaning).", i, forcePointY, comY))
                    end

                    local tireLoad = getWheelShapeContactForce(wheel.node, wheel.physics.wheelShape)
                    if tireLoad ~= nil then
                        local nx,ny,nz = getWheelShapeContactNormal(wheel.node, wheel.physics.wheelShape)
                        local dx,dy,dz = localDirectionToWorld(wheel.node, 0,-1,0)
                        tireLoad = -tireLoad*MathUtil.dotProduct(dx,dy,dz, nx,ny,nz)

                        local gravity = 9.81
                        tireLoad = tireLoad + math.max(ny*gravity, 0.0) * wheel:getMass() -- add gravity force of tire

                        tireLoad = tireLoad / gravity

                        if math.abs(tireLoad - wheel.physics.restLoad) > 0.2 then
                            print(string.format(" Issue found: Wheel %d has wrong restLoad. %.2f vs. %.2f in XML. Verify that this leads to the desired behavior.", i, tireLoad, wheel.physics.restLoad))
                        end
                    end
                end
            end
        end

        return "Analyzed vehicle"
    end

    return "Failed to analyze vehicle. Invalid controlled vehicle"
end


---
function VehicleDebug.moveUpperRotation(self, actionName, inputValue, callbackState, isAnalog)
    if VehicleDebug.currentAttacherJointVehicle ~= nil then
        if inputValue ~= 0 then
            local vehicle = VehicleDebug.currentAttacherJointVehicle
            if vehicle.getAttacherVehicle ~= nil then
                local attacherVehicle = vehicle:getAttacherVehicle()
                if attacherVehicle ~= nil then
                    local implement = attacherVehicle:getImplementByObject(vehicle)
                    if implement ~= nil then
                        local jointDescIndex = implement.jointDescIndex
                        local jointDesc = attacherVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]
                        if jointDesc.rotationNode ~= nil then
                            jointDesc.upperRotation[1] = jointDesc.upperRotation[1] + math.rad(inputValue*(2/1000)*16)
                            jointDesc.moveAlpha = jointDesc.moveAlpha - 0.001
                            print("upperRotation: " ..math.deg(jointDesc.upperRotation[1]))
                        end
                    end
                end
            end
        end
    end
end


---
function VehicleDebug.moveLowerRotation(self, actionName, inputValue, callbackState, isAnalog)
    if VehicleDebug.currentAttacherJointVehicle ~= nil then
        if inputValue ~= 0 then
            local vehicle = VehicleDebug.currentAttacherJointVehicle
            if vehicle.getAttacherVehicle ~= nil then
                local attacherVehicle = vehicle:getAttacherVehicle()
                if attacherVehicle ~= nil then
                    local implement = attacherVehicle:getImplementByObject(vehicle)
                    if implement ~= nil then
                        local jointDescIndex = implement.jointDescIndex
                        local jointDesc = attacherVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]
                        if jointDesc.rotationNode ~= nil then
                            jointDesc.lowerRotation[1] = jointDesc.lowerRotation[1] + math.rad(inputValue*(2/1000)*16)
                            jointDesc.moveAlpha = jointDesc.moveAlpha - 0.001
                            print("lowerRotation: " ..math.deg(jointDesc.lowerRotation[1]))
                        end
                    end
                end
            end
        end
    end
end


---
function VehicleDebug.consoleCommandExportScenegraph(unusedSelf, animationName, animationTime, additionalName)
    local function exportVehicleScenegraph(vehicle)
        local startTime = getTimeSec()

        local filename = string.format(getUserProfileAppPath() .. "scenegraph_%s%s.xml", vehicle.configFileNameClean, tostring(additionalName or ""))
        local xmlFile = XMLFile.create("scenegraph", filename, "scenegraph", nil)

        local function exportScenegraph(node, indexPath, key, index, component)
            key = key .. string.format("(%d)", index)

            xmlFile:setString(key .. "#name", getName(node))
            xmlFile:setString(key .. "#indexPath", indexPath)

            local x, y, z = getTranslation(node)
            xmlFile:setString(key .. "#translation", x .. " " .. y .. " " .. z)

            local rx, ry, rz = getRotation(node)
            xmlFile:setString(key .. "#rotation", math.deg(rx) .. " " .. math.deg(ry) .. " " .. math.deg(rz))

            if component ~= nil then
                xmlFile:setFloat(key .. "#mass", vehicle:getComponentMass(component))
            end

            local numChildren = getNumOfChildren(node)
            if numChildren > 0 then
                local indexNode, indexShape, indexLight, indexTransform = 0, 0, 0, 0
                for i=1, numChildren do
                    local child = getChildAt(node, i - 1)
                    local childPath
                    if indexPath == nil then
                        childPath = "" .. (i - 1)
                    else
                        childPath = indexPath .. "|" .. (i - 1)
                    end

                    local keyIndex = i - 1
                    local keyName = ".Node"
                    if getHasClassId(child, ClassIds.SHAPE) then
                        keyName = ".Shape"
                        keyIndex = indexShape
                        indexShape = indexShape + 1
                    elseif getHasClassId(child, ClassIds.LIGHT_SOURCE) then
                        keyName = ".Light"
                        keyIndex = indexLight
                        indexLight = indexLight + 1
                    elseif getHasClassId(child, ClassIds.TRANSFORM_GROUP) then
                        keyName = ".TransformGroup"
                        keyIndex = indexTransform
                        indexTransform = indexTransform + 1
                    else
                        keyIndex = indexNode
                        indexNode = indexNode + 1
                    end

                    exportScenegraph(child, childPath, key .. keyName, keyIndex, nil)
                end
            end
        end

        for i, component in ipairs(vehicle.components) do
            exportScenegraph(component.node, tostring(i - 1) .. ">", "scenegraph.Shape", i - 1, component)
        end

        xmlFile:save()
        xmlFile:delete()

        local endTime = getTimeSec()
        Logging.info("Exported '%s' in %.1fms", filename, (endTime-startTime) * 1000)
    end

    if animationName ~= nil and animationTime ~= nil then
        animationTime = tonumber(animationTime)

        if VehicleDebug.defaultUpdateAnimationFunc == nil then
            VehicleDebug.defaultUpdateAnimationFunc = AnimatedVehicle.updateAnimation
        end

        AnimatedVehicle.updateAnimation = function(self, anim, dtToUse, stopAnim, fixedTimeUpdate, playSounds, ...)
            VehicleDebug.defaultUpdateAnimationFunc(self, anim, dtToUse, stopAnim, fixedTimeUpdate, playSounds, ...)

            if anim.name == animationName then
                if (anim.currentSpeed > 0 and anim.currentTime > animationTime) or (anim.currentSpeed < 0 and anim.currentTime < animationTime) then
                    exportVehicleScenegraph(self)
                    AnimatedVehicle.updateAnimation = VehicleDebug.defaultUpdateAnimationFunc
                    VehicleDebug.defaultUpdateAnimationFunc = nil
                    return
                end
            end
        end
    else
        if g_currentMission ~= nil and g_localPlayer ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            if vehicle ~= nil then
                for i=1, #vehicle.childVehicles do
                    exportVehicleScenegraph(vehicle.childVehicles[i])
                end
            else
                Logging.error("Please enter vehicle first!")
            end
        end
    end
end


---
function VehicleDebug.drawDebugAttacherJoints(vehicle)
    VehicleDebug.currentAttacherJointVehicle = vehicle
end


---
function VehicleDebug.consoleCommandMergeGroupDebug()
    local function visualizeMergeGroupsRec(node)
        if getHasClassId(node, ClassIds.SHAPE) then
            local _, isSkinnedSingleWeight = getShapeIsSkinned(node)
            if isSkinnedSingleWeight then
                if getHasShaderParameter(node, "colorScale") then
                    local material = VehicleMaterial.new()
                    material:setTemplateName("plasticPainted")
                    material:setColor(0, math.random(), math.random())
                    material:apply(node)
                end
            else
                if getHasShaderParameter(node, "colorScale") then
                    local material = VehicleMaterial.new()
                    material:setTemplateName("plasticPainted")
                    material:setColor(1, 0, 0)
                    material:apply(node)
                end
            end
        end

        local numChildren = getNumOfChildren(node)
        for i = 0, numChildren - 1 do
            visualizeMergeGroupsRec(getChildAt(node, i))
        end
    end

    if g_gui.currentGuiName == "ShopConfigScreen" then
        for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
            for _, component in ipairs(loadedVehicle.components) do
                visualizeMergeGroupsRec(component.node)
            end
        end
    end

    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for i=1, #vehicle.childVehicles do
            for _, component in ipairs(vehicle.childVehicles[i].components) do
                visualizeMergeGroupsRec(component.node)
            end
        end
    end
end


---
function VehicleDebug.consoleCommandCastShadow()
    local function visualizeCastShadowRec(node)
        if getHasClassId(node, ClassIds.SHAPE) then
            local materialId = getMaterial(node, 0)
            if materialId ~= 0 then
                if string.contains(getMaterialCustomShaderFilename(materialId), "vehicleShader.xml") then
                    local material = VehicleMaterial.new()
                    material:setTemplateName("plasticPainted")
                    material:setColor(0, 0, 0)
                    if getShapeCastShadowmap(node) then
                        material:setColor(1, 1, 1)
                    end
                    material.diffuseMap = "data/shared/white_diffuse.dds"
                    material:apply(node)
                end
            end
        end

        local numChildren = getNumOfChildren(node)
        for i = 0, numChildren - 1 do
            visualizeCastShadowRec(getChildAt(node, i))
        end
    end

    if g_gui.currentGuiName == "ShopConfigScreen" then
        for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
            for _, component in ipairs(loadedVehicle.components) do
                visualizeCastShadowRec(component.node)
            end
        end
    end

    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for i=1, #vehicle.childVehicles do
            for _, component in ipairs(vehicle.childVehicles[i].components) do
                visualizeCastShadowRec(component.node)
            end
        end
    end
end


---
function VehicleDebug.consoleCommandDecalLayer()
    local function visualizeDecalLayer(node)
        if getHasClassId(node, ClassIds.SHAPE) then
            local decalLayer = getShapeDecalLayer(node)

            local material = VehicleMaterial.new()
            material:setTemplateName("plasticPainted")
            material:setColor(1, 1, 1)
            if decalLayer == 1 then
                material:setColor(1, 0, 0)
            elseif decalLayer == 2 then
                material:setColor(0, 1, 0)
            elseif decalLayer > 2 then
                material:setColor(0, 0, 1)
            end

            material.diffuseMap = "data/shared/white_diffuse.dds"
            material:apply(node)
        end

        local numChildren = getNumOfChildren(node)
        for i = 0, numChildren - 1 do
            visualizeDecalLayer(getChildAt(node, i))
        end
    end

    if g_gui.currentGuiName == "ShopConfigScreen" then
        for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
            for _, component in ipairs(loadedVehicle.components) do
                visualizeDecalLayer(component.node)
            end
        end
    end

    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for i=1, #vehicle.childVehicles do
            for _, component in ipairs(vehicle.childVehicles[i].components) do
                visualizeDecalLayer(component.node)
            end
        end
    end
end




---
function VehicleDebug.consoleCommandDebugMaterial(_, materialTemplateName)
    local materialTemplate = g_vehicleMaterialManager:getMaterialTemplateByName(materialTemplateName)
    if materialTemplate == nil then
        Logging.error("Material template '%s' not found", materialTemplateName)
        return
    end

    local targetMaterial = VehicleMaterial.new()
    targetMaterial:setTemplateName(materialTemplateName)

    local function visualizeMaterialRec(node)
        if getHasClassId(node, ClassIds.SHAPE) then
            local numMaterial = getNumOfMaterials(node)
            for i=1, numMaterial do
                local materialId = getMaterial(node, i - 1)
                if targetMaterial:getIsApplied(node, materialId, false) then
                    local material = VehicleMaterial.new()
                    material:setTemplateName("plasticPainted")
                    material:setColor(0, 1, 0)
                    material:applyToMaterial(node, i - 1)
                else
                    local material = VehicleMaterial.new()
                    material:setTemplateName("plasticPainted")
                    material:setColor(1, 0, 0)
                    material:applyToMaterial(node, i - 1)
                end
            end
        end

        local numChildren = getNumOfChildren(node)
        for i = 0, numChildren - 1 do
            visualizeMaterialRec(getChildAt(node, i))
        end
    end

    if g_gui.currentGuiName == "ShopConfigScreen" then
        for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
            for _, component in ipairs(loadedVehicle.components) do
                visualizeMaterialRec(component.node)
            end
        end
    end

    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for i=1, #vehicle.childVehicles do
            for _, component in ipairs(vehicle.childVehicles[i].components) do
                visualizeMaterialRec(component.node)
            end
        end
    end
end


---
function VehicleDebug.consoleCommandAttacherJointConnections(_, attacherJointIndex)
    attacherJointIndex = tonumber(attacherJointIndex) or 1
    if VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX == attacherJointIndex then
        Logging.info("Disconnect to attacher joint '%s'", attacherJointIndex)
        attacherJointIndex = nil
        VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX = nil
    else
        Logging.info("Connect to attacher joint '%s'", attacherJointIndex)
        VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX = attacherJointIndex
    end

    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for i=1, #vehicle.childVehicles do
            local childVehicle = vehicle.childVehicles[i]

            if childVehicle.getAttacherJoints ~= nil then
                local str = ""
                for index, attacherJoint in ipairs(childVehicle:getAttacherJoints()) do
                    str = str .. string.format("%d-%s  ", index, getName(attacherJoint.jointTransform))
                end

                if str ~= "" then
                    Logging.info(childVehicle:getFullName() .. ": " .. str)
                end
            end

            if childVehicle.jointIndexDebugText ~= nil then
                g_debugManager:removeElement(childVehicle.jointIndexDebugText)
                childVehicle.jointIndexDebugText = nil
            end

            local attacherJointDesc = childVehicle:getAttacherJointByJointDescIndex(attacherJointIndex)
            if attacherJointDesc ~= nil then
                childVehicle.jointIndexDebugText = DebugText.new():createWithNode(attacherJointDesc.jointTransform, "j" .. tostring(attacherJointIndex), 0.02, true)
                g_debugManager:addElement(childVehicle.jointIndexDebugText, nil, nil, math.huge)
            end

            ConnectionHoses.consoleCommandTestSockets(childVehicle, attacherJointIndex)
            PowerTakeOffs.consoleCommandTestConnection(childVehicle, attacherJointIndex)
        end
    end
end


---
function VehicleDebug.consoleCommandWheelDisplacement()
    if WheelPhysics.COLLISION_MASK == CollisionMask.ALL then
        WheelPhysics.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN_DISPLACEMENT
        Logging.info("Disabled wheel interaction with displacement collision")
    else
        WheelPhysics.COLLISION_MASK = CollisionMask.ALL
        Logging.info("Enabled wheel interaction with displacement collision")
    end

    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.getWheels ~= nil then
            for i, wheel in ipairs(vehicle:getWheels()) do
                wheel.physics:updateBase()
            end
        end
    end
end




---
function VehicleDebug.consoleCommandCylinderedUpdate()
    VehicleDebug.cylinderedUpdateDebugState = not VehicleDebug.cylinderedUpdateDebugState
    print("Cylindered Update Debug: " .. tostring(VehicleDebug.cylinderedUpdateDebugState))
end




---
function VehicleDebug.consoleCommandWetnessDebug()
    VehicleDebug.wetnessDebugState = not VehicleDebug.wetnessDebugState
    print("Wetness Debug: " .. tostring(VehicleDebug.wetnessDebugState))


    local function visualizeWetness(vehicle)
        local debugMaterial = g_debugManager:getDebugMat()
        debugMaterial = setMaterialCustomShaderVariation(debugMaterial, "wetnessDebug", false)
        debugMaterial = setMaterialDiffuseMapFromFile(debugMaterial, "data/shared/default_diffuse.dds", true, true, false)

        local function visualizeWetnessRec(vehicle, node)
            if vehicle.spec_washable.wetnessIgnoreNodes[node] == true then
                return
            end

            if getHasClassId(node, ClassIds.SHAPE) then
                for i=1, getNumOfMaterials(node) do
                    local material = getMaterial(node, i - 1)
                    local shaderFilename = getMaterialCustomShaderFilename(material)
                    if string.contains(shaderFilename, "vehicleShader.xml") then
                        setMaterial(node, debugMaterial, i - 1)
                        setShaderParameter(node, "alpha", 1, 0, 0, 0, false, i - 1)
                    end
                end
            end

            local numChildren = getNumOfChildren(node)
            for i = 0, numChildren - 1 do
                visualizeWetnessRec(vehicle, getChildAt(node, i))
            end
        end

        for _, component in ipairs(vehicle.components) do
            visualizeWetnessRec(vehicle, component.node)
        end
    end

    if VehicleDebug.wetnessDebugState then
        if g_gui.currentGuiName == "ShopConfigScreen" then
            for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
                visualizeWetness(loadedVehicle)
            end
        else
            if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
                local vehicle = g_localPlayer:getCurrentVehicle()
                for i=1, #vehicle.childVehicles do
                    visualizeWetness(vehicle.childVehicles[i])
                end
            end
        end

        VehicleDebug.vehicleOnFinishedLoading = Vehicle.onFinishedLoading
        Vehicle.onFinishedLoading = function(self, ...)
            visualizeWetness(self)

            VehicleDebug.vehicleOnFinishedLoading(self, ...)
        end
    else
        if VehicleDebug.vehicleOnFinishedLoading ~= nil then
            Vehicle.onFinishedLoading = VehicleDebug.vehicleOnFinishedLoading
            VehicleDebug.vehicleOnFinishedLoading = nil
        end

        -- reload the vehicles to have proper materials again
        executeConsoleCommand("gsVehicleReload")
    end
end




---
function VehicleDebug.consoleCommandWheelEffectsDebug()
    VehicleDebug.wheelEffectDebugState = not VehicleDebug.wheelEffectDebugState
    print("Wheel Effects Debug: " .. (VehicleDebug.wheelEffectDebugState and "Enabled" or "Disabled"))
end
