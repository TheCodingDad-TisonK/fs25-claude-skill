















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableHusbandryMilk.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandry, specializations) and SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end


---
function PlaceableHusbandryMilk.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onMilkingRobotLoaded", PlaceableHusbandryMilk.onMilkingRobotLoaded)
end


---
function PlaceableHusbandryMilk.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryMilk.updateOutput)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryMilk.updateProduction)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryMilk.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryMilk.getConditionInfos)
end


---
function PlaceableHusbandryMilk.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryMilk)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryMilk)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryMilk)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryMilk)
end


---
function PlaceableHusbandryMilk.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.milk"
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".milkingRobots.milkingRobot(?)#linkNode", "Milkingrobot link node")
    schema:register(XMLValueType.STRING, basePath .. ".milkingRobots.milkingRobot(?)#class", "Milkingrobot class name")
    schema:register(XMLValueType.STRING, basePath .. ".milkingRobots.milkingRobot(?)#filename", "Milkingrobot config file")
    schema:setXMLSpecializationType()
end


---
function PlaceableHusbandryMilk:onLoad(savegame)
    local spec = self.spec_husbandryMilk

    local animalTypeIndex = self:getAnimalTypeIndex()
    local animalType = g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex)
    spec.litersPerHour = {}
    spec.fillTypes = {}
    spec.infos = {}
    spec.activeFillTypes = {}

    if animalType ~= nil then
        for _, subTypeIndex in ipairs(animalType.subTypes) do
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
            if subType.output ~= nil then
                local milk = subType.output.milk
                if milk ~= nil then
                    spec.litersPerHour[milk.fillType] = 0
                    table.addElement(spec.fillTypes, milk.fillType)
                    spec.infos[milk.fillType] = {title=g_fillTypeManager:getFillTypeTitleByIndex(milk.fillType), text=""}
                end
            end
        end
    end

    spec.milkingRobots = {}

    for _, key in self.xmlFile:iterator("placeable.husbandry.milk.milkingRobots.milkingRobot") do
        local filename = Utils.getFilename(self.xmlFile:getValue(key .. "#filename", nil), self.baseDirectory)
        if filename == nil then
            Logging.xmlWarning(self.xmlFile, "Milkingrobot filename missing for '%s'", key)
            continue
        end

        local className = self.xmlFile:getValue(key .. "#class", "")
        local class = ClassUtil.getClassObject(className)
        if class == nil then
            Logging.xmlWarning(self.xmlFile, "Milkingrobot class '%s' not defined for '%s'", className, key)
            continue
        end

        local linkNode = self.xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
        if linkNode == nil then
            Logging.xmlWarning(self.xmlFile, "Milkingrobot linkNode not defined for '%s'", key)
            continue
        end

        local args = {}
        args.loadingTask = self:createLoadingTask(self)
        local robot = class.new(self, self.baseDirectory)
        if robot:load(linkNode, filename, self.onMilkingRobotLoaded, self, args) then
            table.insert(spec.milkingRobots, robot)
        else
            self:finishLoadingTask(args.loadingTask)
            robot:delete()
        end
    end
end


---
function PlaceableHusbandryMilk:onMilkingRobotLoaded(robot, args)
    self:finishLoadingTask(args.loadingTask)
end


---
function PlaceableHusbandryMilk:onDelete()
    local spec = self.spec_husbandryMilk
    if spec.milkingRobots ~= nil then
        for _, robot in ipairs(spec.milkingRobots) do
            robot:delete()
        end
        spec.milkingRobots = {}
    end
end


---
function PlaceableHusbandryMilk:onFinalizePlacement()
    local spec = self.spec_husbandryMilk
    for _, fillTypeIndex in ipairs(spec.fillTypes) do
        if not self:getHusbandryIsFillTypeSupported(fillTypeIndex) then
            local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
            Logging.warning("Missing filltype '%s' in husbandry storage!", fillTypeName)
        end
    end

    for _, robot in ipairs(spec.milkingRobots) do
        robot:finalizePlacement()
    end
end


---
function PlaceableHusbandryMilk:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    local spec = self.spec_husbandryMilk
    if self.isServer and #spec.fillTypes > 0 then
        for _, fillTypeIndex in ipairs(spec.fillTypes) do
            local litersPerHour = spec.litersPerHour[fillTypeIndex]
            local liters = productionFactor * globalProductionFactor * litersPerHour * g_currentMission.environment.timeAdjustment
            self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), liters, fillTypeIndex, nil, nil, nil)
        end
    end

    superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end


---
function PlaceableHusbandryMilk:updateProduction(superFunc, foodFactor)
    local spec = self.spec_husbandryMilk
    local factor = superFunc(self, foodFactor)

    for _, fillTypeIndex in ipairs(spec.fillTypes) do
        local freeCapacity = self:getHusbandryFreeCapacity(fillTypeIndex)
        if freeCapacity <= 0 then
            factor = 0
            break
        end
    end

    return factor
end


---
function PlaceableHusbandryMilk:onHusbandryAnimalsUpdate(clusters)
    local spec = self.spec_husbandryMilk

    for fillType, _ in pairs(spec.litersPerHour) do
        spec.litersPerHour[fillType] = 0
    end

    spec.activeFillTypes = {}

    for _, cluster in ipairs(clusters) do
        local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)
        if subType ~= nil then
            local milk = subType.output.milk
            if milk ~= nil then
                local age = cluster:getAge()
                local litersPerAnimals = milk.curve:get(age)
                local litersPerDay = litersPerAnimals * cluster:getNumAnimals()

                spec.litersPerHour[milk.fillType] = spec.litersPerHour[milk.fillType] + (litersPerDay / 24)

                table.addElement(spec.activeFillTypes, milk.fillType)
            end
        end
    end
end


---
function PlaceableHusbandryMilk:updateInfo(superFunc, infoTable)
    local spec = self.spec_husbandryMilk
    superFunc(self, infoTable)

    for k, fillTypeIndex in ipairs(spec.activeFillTypes) do
        local info = spec.infos[fillTypeIndex]
        local fillLevel = self:getHusbandryFillLevel(fillTypeIndex)
        info.text = string.format("%d l", fillLevel)
        table.insert(infoTable, info)
    end
end


---
function PlaceableHusbandryMilk:getConditionInfos(superFunc)
    local spec = self.spec_husbandryMilk
    local infos = superFunc(self)

    for _, fillTypeIndex in ipairs(spec.activeFillTypes) do
        local info = {}
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillType ~= nil then
            info.title = fillType.title
            info.value = self:getHusbandryFillLevel(fillTypeIndex)
            local capacity = self:getHusbandryCapacity(fillTypeIndex)
            local ratio = 0
            if capacity > 0 then
                ratio = info.value / capacity
            end
            info.ratio = math.clamp(ratio, 0, 1)
            info.invertedBar = true

            table.insert(infos, info)
        end
    end

    return infos
end
