

















---Stores all data that is required to load a Vehicle
-- Has also functionality to load the vehicle or multiple vehicles if the store item is a bundle of vehicles
local VehicleLoadingData_mt = Class(VehicleLoadingData)


---Creates a new instance of VehicleLoadingData
-- @return table vehicleLoadingData VehicleLoadingData instance
function VehicleLoadingData.new(customMt)
    local self = setmetatable({}, customMt or VehicleLoadingData_mt)

    self.isValid = false
    self.validLocation = true

    self.storeItem = nil
    self.vehicles = {}

    self.vehiclesToLoad = 0
    self.loadingVehicles = {}
    self.loadedVehicles = {}
    self.loadingState = nil

    self.savegameData = nil
    self.configurations = {}
    self.boughtConfigurations = {}
    self.configurationData = {}

    self.saleItem = nil

    self.propertyState = VehiclePropertyState.OWNED
    self.ownerFarmId = AccessHandler.EVERYONE

    self.isRegistered = true
    self.forceServer = false
    self.isSaved = true
    self.addToPhysics = true

    self.price = nil

    self.position = {0, 0, 0}
    self.rotation = {0, 0, 0}

    self.ignoreShopOffset = false -- ignore the defined shop translation and rotation offset in the xml file
    self.centerVehicle = true -- center the vehicle in X and Z translation around spawn position (based on width and length offset)

    self.customParameters = {}

    return self
end


---Sets the store data by given xml filename
-- @param string filename filename
function VehicleLoadingData:setFilename(filename)
    local storeItem = g_storeManager:getItemByXMLFilename(filename)
    if storeItem ~= nil then
        self:setStoreItem(storeItem)
    else
        Logging.error("Unable to find vehicle storeitem for '%s'", filename)
        printCallstack()
    end
end


---Sets the store item
-- @param table storeItem storeItem
function VehicleLoadingData:setStoreItem(storeItem)
    if storeItem ~= nil then
        self.storeItem = storeItem

        self.rotation[2] = storeItem.rotation

        self.vehicles = {}
        if self.storeItem.bundleInfo ~= nil then
            self.attacherInfo = self.storeItem.bundleInfo.attacherInfo
            for _, bundleItem in pairs(self.storeItem.bundleInfo.bundleItems) do
                table.insert(self.vehicles, {xmlFilename=bundleItem.xmlFilename, offset=bundleItem.offset, rotationOffset=bundleItem.rotationOffset})
            end
        else
            table.insert(self.vehicles, {xmlFilename=storeItem.xmlFilename})
        end
    end

    self.isValid = #self.vehicles > 0
end


---Sets the property state of the vheicle
-- @param integer propertyState propertyState
function VehicleLoadingData:setPropertyState(propertyState)
    self.propertyState = propertyState
end


---Sets the owner of the vehicle
-- @param integer ownerFarmId ownerFarmId
function VehicleLoadingData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end


---Sets the corresponding sale item
-- @param table saleItem saleItem
function VehicleLoadingData:setSaleItem(saleItem)
    self.saleItem = saleItem

    if saleItem ~= nil then
        for name, ids in pairs(saleItem.boughtConfigurations) do
            if self.boughtConfigurations[name] == nil then
                self.boughtConfigurations[name] = {}
            end

            for id, _ in pairs(ids) do
                self.boughtConfigurations[name][id] = true
            end
        end
    end
end


---Sets the savegame data for a vehicle if it's loaded from a savegame
-- @param table savegameData savegameData (table with the following attributes: xmlFile, key, ignoreFarmId, resetVehicles)
function VehicleLoadingData:setSavegameData(savegameData)
    self.savegameData = savegameData

    if self.storeItem ~= nil then
        -- load savegame configurations
        if savegameData ~= nil and savegameData.xmlFile ~= nil then
            self.configurations, self.boughtConfigurations, self.configurationData = ConfigurationUtil.loadConfigurationsFromXMLFile(self.storeItem.xmlFilename, savegameData.xmlFile, savegameData.key .. ".configuration")

            -- savegame backward compatibility
            for _, key in savegameData.xmlFile:iterator(savegameData.key .. ".boughtConfiguration") do
                local name = savegameData.xmlFile:getValue(key.."#name")
                local id = savegameData.xmlFile:getValue(key.."#id")
                if name ~= nil and id ~= nil then
                    if self.boughtConfigurations[name] == nil then
                        self.boughtConfigurations[name] = {}
                    end

                    local configIndex = ConfigurationUtil.getConfigIdBySaveId(self.storeItem.xmlFilename, name, id)
                    if configIndex ~= nil then
                        self.boughtConfigurations[name][configIndex] = true
                    end
                else
                    Logging.xmlWarning(savegameData.xmlFile, "Invalid bought configuration in '%s'!", savegameData.key)
                end
            end
        end
    end
end


---Sets the configurations for the vehicle
-- @param table configurations configurations
function VehicleLoadingData:setConfigurations(configurations)
    if configurations ~= nil then
        self.configurations = configurations
    else
        self.configurations = {}
    end
end


---Sets the bought configurations for the vehicle
-- @param table boughtConfigurations boughtConfigurations
function VehicleLoadingData:setBoughtConfigurations(boughtConfigurations)
    if boughtConfigurations ~= nil then
        self.boughtConfigurations = boughtConfigurations
    else
        self.boughtConfigurations = {}
    end
end


---Sets the configuration data
-- @param table boughtConfigurations boughtConfigurations
function VehicleLoadingData:setConfigurationData(configurationData)
    if configurationData ~= nil then
        self.configurationData = configurationData
    else
        self.configurationData = {}
    end
end


---Returns a cloned table of the configurations for the given configFileName
-- @param string configFileName path to xml file
-- @return table configurations configurations
-- @return table boughtConfigurations boughtConfigurations
function VehicleLoadingData:getConfigurations(configFileName)
    local configurations = table.clone(self.configurations, math.huge)
    local boughtConfigurations = table.clone(self.boughtConfigurations, math.huge)
    local configurationData = table.clone(self.configurationData, math.huge)

    -- remove configurations that are not present in the bundle items
    local storeItem = g_storeManager:getItemByXMLFilename(configFileName)
    if storeItem ~= nil and storeItem ~= self.storeItem then
        for configName, configId in pairs(configurations) do
            local isValid = true
            if storeItem.configurations == nil then
                isValid = false
            else
                if storeItem.configurations[configName] == nil then
                    isValid = false
                else
                    local configItems = storeItem.configurations[configName]
                    if configItems[configId] == nil then
                        -- in case one bundle item has less configs than the other
                        isValid = false
                    end
                end
            end

            if not isValid then
                configurations[configName] = nil
                boughtConfigurations[configName] = nil
            end
        end
    end

    if storeItem ~= nil and storeItem.configurations ~= nil then
        for configName, configItems in pairs(storeItem.configurations) do
            local configIndex = configurations[configName]
            if configIndex == nil then
                configIndex = ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
                configurations[configName] = configIndex
            end

            if configItems[configIndex] ~= nil then
                local configItem = configItems[configIndex]
                if configItem.dependentConfigurations ~= nil then
                    for _, dependentConfig in ipairs(configItem.dependentConfigurations) do
                        configurations[dependentConfig.name] = dependentConfig.index
                    end
                end
            end
        end
    end

    return configurations, boughtConfigurations, configurationData
end


---Sets if the vehicle is registered after loading
-- @param boolean isRegistered isRegistered
function VehicleLoadingData:setIsRegistered(isRegistered)
    self.isRegistered = isRegistered
end


---Sets if the vehicle is created as server vehicle also on client side (With dynamic physics etc.)
-- @param boolean forceServer forceServer
function VehicleLoadingData:setForceServer(forceServer)
    self.forceServer = forceServer
end


---Sets if the vehicle is saved
-- @param boolean isSaved isSaved
function VehicleLoadingData:setIsSaved(isSaved)
    self.isSaved = isSaved
end


---Sets if the vehicle is added to physics
-- @param boolean addToPhysics addToPhysics
function VehicleLoadingData:setAddToPhysics(addToPhysics)
    self.addToPhysics = addToPhysics
end


---Set custom parameter which is available inside the vehicle
-- @param string name name of parameter
-- @param any value parameter value
function VehicleLoadingData:setCustomParameter(name, value)
    self.customParameters[name] = value
end


---Returns custom parameter value by given name
-- @param string name name of parameter
-- @return any value parameter value
function VehicleLoadingData:getCustomParameter(name)
    return self.customParameters[name]
end


---Set spawn translation (World space)
-- @param float x x translation
-- @param float y y translation (if nil, the terrain height will be used)
-- @param float z z translation
-- @param float offset from terrain if y attribute is nil
function VehicleLoadingData:setPosition(x, y, z, terrainOffset)
    if y == nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + (terrainOffset or 0)
    end

    self.position[1], self.position[2], self.position[3] = x, y, z
end


---Set spawn rotation (World space)
-- @param float rx x rotation
-- @param float ry y rotation
-- @param float rz z rotation
function VehicleLoadingData:setRotation(rx, ry, rz)
    self.rotation[1], self.rotation[2], self.rotation[3] = rx, ry, rz
end


---Set the spawn translation and rotation based on the given node's position
-- @param entityId node node id
function VehicleLoadingData:setSpawnNode(node)
    self.position[1], self.position[2], self.position[3] = getWorldTranslation(node)
    self.rotation[1], self.rotation[2], self.rotation[3] = getWorldRotation(node)
end


---Defines if the shop offset will be used during loading or not
-- @param boolean ignoreShopOffset
function VehicleLoadingData:setIgnoreShopOffset(ignoreShopOffset)
    self.ignoreShopOffset = ignoreShopOffset
end


---Record the component position data of the given vehicle, which is applied on the loaded vehicle
-- @param table vehicle vehicle
function VehicleLoadingData:setComponentPositionData(vehicle)
    self.componentPositionData = {}

    for i, component in ipairs(vehicle.components) do
        self.componentPositionData[i] = {translation={getWorldTranslation(component.node)}, rotation={getWorldRotation(component.node)}}
    end
end


---Apply the position data to a given vehicle
-- @param table vehicle vehicle
-- @return boolean success position data was successfully applied (otherwise the vehicle was not correctly spawned and should be removed)
function VehicleLoadingData:applyPositionData(vehicle)
    if not self.validLocation then
        return false
    end

    if self.componentPositionData ~= nil then
        -- use component position data from previously loaded vehicle
        for i=1, #vehicle.components do
            local data = self.componentPositionData[i]
            if data ~= nil then
                vehicle:setWorldPosition(data.translation[1], data.translation[2], data.translation[3], data.rotation[1], data.rotation[2], data.rotation[3], i, true)
            else
                vehicle:setDefaultComponentPosition(i)
            end
        end

        return true
    elseif self.savegameData ~= nil then
        local savegame = self.savegameData

        if savegame.useNewPosition then
            return self:resetVehiclePosition(vehicle)
        end

        if savegame.resetVehicles and not savegame.keepPosition then
            return self:resetVehiclePosition(vehicle)
        end

        local componentPositions = {}
        for _componentIndex, componentKey in savegame.xmlFile:iterator(savegame.key..".component") do
            local componentIndex = savegame.xmlFile:getValue(componentKey.."#index")
            local x, y, z = savegame.xmlFile:getValue(componentKey.."#position")
            local xRot, yRot, zRot = savegame.xmlFile:getValue(componentKey.."#rotation")

            if not MathUtil.getIsValidTransformationValue(x, y, z) or not MathUtil.getIsValidTransformationValue(xRot, yRot, zRot) then
                Logging.xmlWarning(savegame.xmlFile, "Invalid component position in '%s' (%s)!", savegame.key, vehicle.configFileName)
                return self:resetVehiclePosition(vehicle)
            end

            if componentPositions[componentIndex] ~= nil then
                Logging.xmlWarning(savegame.xmlFile, "Duplicate component index '%s' in '%s' (%s)!", componentIndex, savegame.key, vehicle.configFileName)
            else
                componentPositions[componentIndex] = {x=x, y=y, z=z, xRot=xRot, yRot=yRot, zRot=zRot}
            end
        end

        -- if the vehicle is broken and no component positions have bveen saved, we reset the vehicle
        if next(componentPositions) == nil then
            return self:resetVehiclePosition(vehicle)
        end

        for i=1, #vehicle.components do
            local position = componentPositions[i]
            if position ~= nil then
                vehicle:setWorldPosition(position.x, position.y, position.z, position.xRot, position.yRot, position.zRot, i, true)
            else
                vehicle:setDefaultComponentPosition(i)
            end
        end

        return true
    end

    -- default position from store item + (store offset OR bundle item offset)
    local x, y, z, rx, ry, rz = self:getPositionAndRotation(vehicle)
    vehicle:setAbsolutePosition(x, y, z, rx, ry, rz)
    return true
end











































































---Set loading place for the vehicle in case it should spawn at the shop (Store item needs to be set first)
-- @param table places places
-- @param table usedPlaces usedPlaces
-- @param float spawnOffset offset between the each item to spawn (default: 1)
-- @param boolean ignoreMinSpawnItemSize Ignore the minimum dimensions for spawning and just use them items dimensions -> items closer to each other
function VehicleLoadingData:setLoadingPlace(places, usedPlaces, spawnOffset, ignoreMinSpawnItemSize)
    if self.storeItem ~= nil then
        local yRot = self.storeItem.rotation
        if self.storeItem.spawnRotationOffset ~= nil then
            yRot = yRot + self.storeItem.spawnRotationOffset[2]
        end

        local size = StoreItemUtil.getSizeValues(self.storeItem.xmlFilename, "vehicle", yRot, self.configurations)

        if ignoreMinSpawnItemSize ~= true then
            size.width = math.max(size.width, VehicleLoadingData.MIN_SPAWN_PLACE_WIDTH)
            size.length = math.max(size.length, VehicleLoadingData.MIN_SPAWN_PLACE_LENGTH)
            size.height = math.max(size.height, VehicleLoadingData.MIN_SPAWN_PLACE_HEIGHT)

            if self.storeItem.spawnSizeOffset ~= nil then
                size.width = size.width + self.storeItem.spawnSizeOffset[1]
                size.length = size.length + self.storeItem.spawnSizeOffset[2]
                size.height = size.height + self.storeItem.spawnSizeOffset[3]
            end
        end

        size.width = size.width + (spawnOffset or VehicleLoadingData.SPAWN_WIDTH_OFFSET)

        local x, y, z, place, width, _ = PlacementUtil.getPlace(places, size, usedPlaces, true, true, false, true)
        if x == nil then
            self.validLocation = false
            return false
        else
            PlacementUtil.markPlaceUsed(usedPlaces, place, width)
        end

        self.position[1], self.position[2], self.position[3] = x, y, z

        self.rotation[2] = self.rotation[2] + MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)

        if self.storeItem.spawnRotationOffset ~= nil then
            self.rotation[2] = self.rotation[2] + self.storeItem.spawnRotationOffset[2]
        end

        return true
    else
        Logging.error("No store item set before VehicleLoadingData:setLoadingPlace call")
        printCallstack()
    end

    return false
end


---Loads all vehicles from the set storeItem and calls the optional callback
-- @param function? callback callback to be called when all vehicles have been loaded
-- @param table? callbackTarget callback target
-- @param table? callbackArguments callback arguments
function VehicleLoadingData:load(callback, callbackTarget, callbackArguments)
    g_currentMission.vehicleSystem:addPendingVehicleLoad(self)

    self.callback, self.callbackTarget, self.callbackArguments = callback, callbackTarget, callbackArguments

    self.vehiclesToLoad = #self.vehicles
    self.loadingVehicles = {}
    self.loadedVehicles = {}
    self.loadingState = VehicleLoadingState.OK

    -- check if all vehicles have a valid vehicleType and vehicleClass
    for _, vehicleData in ipairs(self.vehicles) do
        vehicleData.vehicleType, vehicleData.vehicleClass = g_vehicleTypeManager:getObjectTypeFromXML(vehicleData.xmlFilename)
        if vehicleData.vehicleType == nil or vehicleData.vehicleClass == nil then
            self.loadingState = VehicleLoadingState.ERROR

            if self.callback ~= nil then
                self.callback(self.callbackTarget, self.loadedVehicles, self.loadingState, self.callbackArguments)
            end

            g_currentMission.vehicleSystem:removePendingVehicleLoad(self)
            return
        end
    end

    for _, vehicleData in ipairs(self.vehicles) do
        self:loadVehicle(vehicleData)
    end
end
