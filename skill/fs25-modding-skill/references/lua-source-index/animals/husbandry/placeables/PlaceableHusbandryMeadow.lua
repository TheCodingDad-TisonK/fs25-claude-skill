


















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableHusbandryMeadow.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryFood, specializations) and
           SpecializationUtil.hasSpecialization(PlaceableHusbandryFence, specializations)
end













---
function PlaceableHusbandryMeadow.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryMeadow.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getFoodInfos", PlaceableHusbandryMeadow.getFoodInfos)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getAvailableFood", PlaceableHusbandryMeadow.getAvailableFood)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "removeFood", PlaceableHusbandryMeadow.removeFood)
end


---
function PlaceableHusbandryMeadow.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onFinishedFeeding", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryFenceCustomizingUserLeft", PlaceableHusbandryMeadow)
end


---
function PlaceableHusbandryMeadow.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.meadow"
    schema:register(XMLValueType.STRING, basePath .. ".fruitType(?)#name", "Name of the supported fruitType")
    schema:register(XMLValueType.STRING, basePath .. ".fruitType(?)#eatableStartGrowthState", "Fruit type eatable start growth state name")
    schema:register(XMLValueType.STRING, basePath .. ".fruitType(?)#eatableEndGrowthState", "Fruit type eatable end growth state name")
    schema:register(XMLValueType.STRING, basePath .. ".fruitType(?)#eatenGrowthState", "Fruit type eaten growth state name")
    MeadowCreationTask.registerXMLPaths(schema, basePath .. ".createTask")
    MeadowCreationTask.registerXMLPaths(schema, basePath .. ".clearTask")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearTask.polygon.node(?)#node", "Polygon node", nil, false)
    schema:setXMLSpecializationType()
end


---
function PlaceableHusbandryMeadow.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    MeadowCreationTask.registerXMLPaths(schema, basePath .. ".createTask")
    MeadowCreationTask.registerXMLPaths(schema, basePath .. ".clearTask")
    schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Meadow filltype name")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#fillLevel", "Meadow fillevel")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#capacity", "Meadow capacity")
    schema:setXMLSpecializationType()
end


---
function PlaceableHusbandryMeadow:onLoad(savegame)
    local spec = self.spec_husbandryMeadow

    spec.canCreateMeadow = false

    spec.foodInfo = {
        title = "",
        value = 0,
        capacity = 0,
        ratio = 0,
        ignoreCapacity = true
    }
    spec.info = {
        title = g_i18n:getText("animals_husbandryMeadowFood"),
        value = 0,
        capacity = 0,
        ratio = 0
    }

    spec.fillLevels = {}
    spec.dirtyFillLevels = {}
    spec.capacities = {}
    spec.productionWeight = 0

    spec.dirtyFlag = self:getNextDirtyFlag()

    spec.fruitTypeInfos = {}
    spec.fruitTypeEatFilters = {}
    spec.eatFilterMaxValue = 10000

    for _, fruitTypeKey in self.xmlFile:iterator("placeable.husbandry.meadow.fruitType") do
        local name = self.xmlFile:getValue(fruitTypeKey .. "#name")
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(name)
        if fruitTypeDesc ~= nil then
            local windrowFillTypeIndex = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitTypeDesc.index)
            spec.fillLevels[windrowFillTypeIndex] = 0
            spec.capacities[windrowFillTypeIndex] = 0

            local eatableStartGrowthStateName = self.xmlFile:getValue(fruitTypeKey .. "#eatableStartGrowthState")
            if eatableStartGrowthStateName == nil then
                Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableStartGrowthState missing!")
                continue
            end
            local eatableStartGrowthState = fruitTypeDesc:getGrowthStateByName(eatableStartGrowthStateName)
            if eatableStartGrowthState == nil then
                Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableStartGrowthState '%s' not defined!", eatableStartGrowthStateName)
                continue
            end

            local eatableEndGrowthStateName = self.xmlFile:getValue(fruitTypeKey .. "#eatableEndGrowthState")
            if eatableEndGrowthStateName == nil then
                Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableEndGrowthState missing!")
                continue
            end
            local eatableEndGrowthState = fruitTypeDesc:getGrowthStateByName(eatableEndGrowthStateName)
            if eatableEndGrowthState == nil then
                Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableEndGrowthState '%s' not defined!", eatableEndGrowthStateName)
                continue
            end

            local eatenGrowthStateName = self.xmlFile:getValue(fruitTypeKey .. "#eatenGrowthState")
            if eatenGrowthStateName == nil then
                Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatenGrowthState missing!")
                continue
            end
            local eatenGrowthState = fruitTypeDesc:getGrowthStateByName(eatenGrowthStateName)
            if eatenGrowthState == nil then
                Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatenGrowthState '%s' not defined!", eatenGrowthStateName)
                continue
            end

            local fruitTypeInfo = {
                fruitType = fruitTypeDesc,
                eatableStartGrowthState = eatableStartGrowthState,
                eatableEndGrowthState = eatableEndGrowthState,
                eatenGrowthState = eatenGrowthState,
                fillTypeIndex = windrowFillTypeIndex,
            }

            table.insert(spec.fruitTypeInfos, fruitTypeInfo)
        end
    end

    if self.xmlFile:hasProperty("placeable.husbandry.meadow.createTask") then
        local createTask = MeadowCreationTask.new()
        if createTask:loadFromXMLFile(self.xmlFile, "placeable.husbandry.meadow.createTask") then
            createTask:setName("HusbandryMeadowCreate")
            createTask:setNeedsSaving(false)
            spec.createTask = createTask
        end

        spec.canCreateMeadow = true
    end

    if self.xmlFile:hasProperty("placeable.husbandry.meadow.clearTask") then
        local nodes = {}
        for _, nodeKey in self.xmlFile:iterator("placeable.husbandry.meadow.clearTask.polygon.node") do
            local node = self.xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)
            if node ~= nil then
                table.insert(nodes, node)
            end
        end

        local area = DensityMapPolygon.createFromNodes(nodes)
        if area ~= nil then
            local clearTask = MeadowCreationTask.new()
            clearTask:setArea(area)
            if clearTask:loadFromXMLFile(self.xmlFile, "placeable.husbandry.meadow.clearTask") then
                clearTask:setName("HusbandryMeadowClear")
                clearTask:setNeedsSaving(false)
                spec.clearTask = clearTask
                spec.canCreateMeadow = true
            end
        end
    end
end


























































---
function PlaceableHusbandryMeadow:onReadStream(streamId, connection)
    local spec = self.spec_husbandryMeadow
    local numBits = PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS
    for fillTypeIndex, filLLevel in pairs(spec.fillLevels) do
        spec.fillLevels[fillTypeIndex] = streamReadUIntN(streamId, numBits)
        spec.capacities[fillTypeIndex] = streamReadUIntN(streamId, numBits)
    end
    self:updateMeadowInfo()
end


---
function PlaceableHusbandryMeadow:onWriteStream(streamId, connection)
    local spec = self.spec_husbandryMeadow
    local numBits = PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS
    for fillTypeIndex, fillLevel in pairs(spec.fillLevels) do
        streamWriteUIntN(streamId, fillLevel, numBits)
        streamWriteUIntN(streamId, spec.capacities[fillTypeIndex], numBits)
    end
end


---
function PlaceableHusbandryMeadow:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        local spec = self.spec_husbandryMeadow
        if streamReadBool(streamId) then
            local numBits = PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS
            for fillTypeIndex, filLLevel in pairs(spec.fillLevels) do
                spec.fillLevels[fillTypeIndex] = streamReadUIntN(streamId, numBits)
                spec.capacities[fillTypeIndex] = streamReadUIntN(streamId, numBits)
            end
            self:updateMeadowInfo()
        end
    end
end


---
function PlaceableHusbandryMeadow:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_husbandryMeadow
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            local numBits = PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS
            for fillTypeIndex, fillLevel in pairs(spec.fillLevels) do
                streamWriteUIntN(streamId, fillLevel, numBits)
                streamWriteUIntN(streamId, spec.capacities[fillTypeIndex], numBits)
            end
        end
    end
end


---
function PlaceableHusbandryMeadow:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_husbandryMeadow
    local found = false
    for _, fillLevelKey in xmlFile:iterator(key .. ".fillType") do
        local fillTypeName = xmlFile:getValue(fillLevelKey .. "#name")
        if fillTypeName ~= nil  then
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            if fillTypeIndex ~= nil and spec.fillLevels[fillTypeIndex] ~= nil then
                local fillLevel = xmlFile:getValue(fillLevelKey .. "#fillLevel")
                local capacity = xmlFile:getValue(fillLevelKey .. "#capacity")
                spec.fillLevels[fillTypeIndex] = fillLevel or spec.fillLevels[fillTypeIndex]
                spec.capacities[fillTypeIndex] = capacity or spec.capacities[fillTypeIndex]
                found = true
            end
        end
    end

    spec.isMeadowInfoDirty = not found

    self:updateMeadowInfo()

    local fieldTaskKey = key .. ".createTask"
    if xmlFile:hasProperty(fieldTaskKey) then
        local createTask = MeadowCreationTask.new()
        if createTask:loadFromXMLFile(xmlFile, fieldTaskKey) then
            createTask:setNeedsSaving(false)
            createTask:enqueue()
            spec.pendingCreateTask = createTask
        end
    end
    local clearTaskKey = key .. ".clearTask"
    if xmlFile:hasProperty(clearTaskKey) then
        local clearTask = MeadowCreationTask.new()
        if clearTask:loadFromXMLFile(xmlFile, clearTaskKey) then
            clearTask:setNeedsSaving(false)
            clearTask:enqueue()
            spec.pendingClearTask = clearTask
        end
    end

    if spec.pendingCreateTask == nil and spec.pendingClearTask == nil then
        g_messageCenter:subscribe(MessageType.START_GROWTH_PERIOD, self.startMeadowGrowthUpdate, self)
        g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.finishMeadowGrowthUpdate, self)
    end
end


---
function PlaceableHusbandryMeadow:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_husbandryMeadow
    local index = 0
    for fillTypeIndex, fillLevel in pairs(spec.fillLevels) do
        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
        if fillTypeName ~= nil then
            local fillLevelKey = string.format("%s.fillType(%d)", key, index)
            xmlFile:setValue(fillLevelKey.."#name", fillTypeName)
            xmlFile:setValue(fillLevelKey.."#fillLevel", fillLevel)
            xmlFile:setValue(fillLevelKey.."#capacity", spec.capacities[fillTypeIndex] or 0)
            index = index + 1
        end
    end

    if spec.pendingCreateTask ~= nil then
        spec.pendingCreateTask:saveToXMLFile(xmlFile, key .. ".createTask")
    end
    if spec.pendingClearTask ~= nil then
        spec.pendingClearTask:saveToXMLFile(xmlFile, key .. ".clearTask")
    end
end
























































































































































































































































































































---
function PlaceableHusbandryMeadow:getFoodInfos(superFunc)
    local foodInfos = superFunc(self)
    local spec = self.spec_husbandryMeadow

    if #spec.fruitTypeInfos > 0 then
        table.insert(foodInfos, spec.foodInfo)
    end

    return foodInfos
end


---
function PlaceableHusbandryMeadow:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_husbandryMeadow

    if #spec.fruitTypeInfos > 0 then
        table.insert(infoTable, spec.info)
    end
end
