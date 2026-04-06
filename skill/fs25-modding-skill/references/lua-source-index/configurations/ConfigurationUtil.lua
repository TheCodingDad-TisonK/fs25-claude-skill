


















---Add bought configuration
-- @param string name of bought configuration type
-- @param integer id id of bought configuration
function ConfigurationUtil.addBoughtConfiguration(manager, object, name, id)
    if manager:getConfigurationIndexByName(name) ~= nil then
        if object.boughtConfigurations[name] == nil then
            object.boughtConfigurations[name] = {}
        end
        object.boughtConfigurations[name][id] = true
    end
end


---Returns true if configuration has been bought
-- @param string name of bought configuration type
-- @param integer id id of bought configuration
-- @return boolean configurationHasBeenBought configuration has been bought
function ConfigurationUtil.hasBoughtConfiguration(object, name, id)
    if object.boughtConfigurations[name] ~= nil and object.boughtConfigurations[name][id] then
        return true
    end
    return false
end


---Set configuration value
-- @param string name name of configuration type
-- @param integer id id of configuration value
function ConfigurationUtil.setConfiguration(object, name, id)
    object.configurations[name] = id
end


---Returns color of config id
-- @param string configName name if config
-- @param integer configId id of config to get color
-- @return table color color and material(r, g, b, mat)
function ConfigurationUtil.getColorByConfigId(object, configName, configId)
    if configId ~= nil then
        local item = g_storeManager:getItemByXMLFilename(object.configFileName)
        if item.configurations ~= nil then
            local config = item.configurations[configName][configId]
            if config ~= nil and config:isa(VehicleConfigurationItemColor) then
                return config:getColor()
            end
        end
    end

    return nil
end


---Returns config item object of config id
-- @param string configFileName path to xml file of store item
-- @param string configName name if config
-- @param integer configId id of config
function ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
    if configId ~= nil then
        local item = g_storeManager:getItemByXMLFilename(configFileName)
        if item.configurations ~= nil then
            local configItems = item.configurations[configName]
            if configItems ~= nil and configItems[configId] ~= nil then
                return configItems[configId]
            end
        end
    end

    return nil
end


---Calls the given eventName function on all configItem objects
-- @param table object vehicle/placeable object
-- @param string eventName name of function to call
function ConfigurationUtil.raiseConfigurationItemEvent(object, eventName)
    for configName, configId in pairs(object.configurations) do
        local configItem = ConfigurationUtil.getConfigItemByConfigId(object.configFileName, configName, configId)
        if configItem ~= nil and configItem[eventName] ~= nil then
            configItem[eventName](configItem, object, configId)
        end
    end
end


---Returns save identifier from given config id
-- @param table object object
-- @param string configName name if config
-- @param integer configId id of config to get color
-- @return string saveId save identifier
function ConfigurationUtil.getSaveIdByConfigId(configFileName, configName, configId)
    local item = g_storeManager:getItemByXMLFilename(configFileName)
    if item.configurations ~= nil then
        local configs = item.configurations[configName]
        if configs ~= nil then
            local config = configs[configId]
            if config ~= nil then
                return config.saveId
            end
        end
    end

    return nil
end


---Save the given single configuration to the given xml file
-- @param table itemConfigurations item configurations
-- @param string configName name of configuration
-- @param integer configId id of configuration
-- @param table xmlFile xml file object
-- @param string key key
-- @param boolean isActive true if configuration is active
-- @param table configurationData configuration data
-- @param integer xmlIndex index of xml entry
-- @return integer xmlIndex new index of xml entry
function ConfigurationUtil.saveConfigurationToXMLFile(itemConfigurations, configName, configId, xmlFile, key, isActive, configurationData, xmlIndex)
    local configKey = string.format("%s(%d)", key, xmlIndex)

    local configurationItems = itemConfigurations[configName]
    if configurationItems ~= nil then
        local configurationItem = configurationItems[configId]
        if configurationItem ~= nil then
            local data = configurationData[configName]
            if data ~= nil then
                configurationItem:saveToXMLFile(xmlFile, configKey, isActive, data[configId])
                xmlIndex = xmlIndex + 1
            else
                configurationItem:saveToXMLFile(xmlFile, configKey, isActive)
                xmlIndex = xmlIndex + 1
            end
        end
    end

    return xmlIndex
end


---Saves the given configurations to the given xml file
-- @param string configFileName path to xml file of store item
-- @param table xmlFile xml file object
-- @param string key key
-- @param table configurations configurations
-- @param table configurationData configuration data
function ConfigurationUtil.saveConfigurationsToXMLFile(configFileName, xmlFile, key, configurations, boughtConfigurations, configurationData)
    local item = g_storeManager:getItemByXMLFilename(configFileName)
    if item.configurations ~= nil then
        local xmlIndex = 0
        for configName, configsToSave in pairs(boughtConfigurations) do
            for index, _ in pairs(configsToSave) do
                local isActive = configurations[configName] == index
                xmlIndex = ConfigurationUtil.saveConfigurationToXMLFile(item.configurations, configName, index, xmlFile, key, isActive, configurationData, xmlIndex)
            end
        end
    end
end


---Load all configurations from the given xml key
-- @param string configFileName path to xml file of store item
-- @param table xmlFile xml file object
-- @param string key key
-- @return table configurations configurations
-- @return table boughtConfigurations bought configurations
-- @return table configurationData configuration data
function ConfigurationUtil.loadConfigurationsFromXMLFile(configFileName, xmlFile, key)
    local configurations = {}
    local boughtConfigurations = {}
    local configurationData = {}

    local item = g_storeManager:getItemByXMLFilename(configFileName)
    if item.configurations ~= nil then
        for _, configKey in xmlFile:iterator(key) do
            local configName = xmlFile:getValue(configKey .. "#name")
            local configId = xmlFile:getValue(configKey .. "#id")
            local isActive = xmlFile:getValue(configKey .. "#isActive", true)

            local configurationItems = item.configurations[configName]
            if configurationItems ~= nil then
                local configurationItem = nil
                for j=1, #configurationItems do
                    if configurationItems[j].saveId == configId then
                        configurationItem = configurationItems[j]
                    end
                end

                if configurationItem == nil then
                    local configItemClass = ClassUtil.getClassObjectByObject(configurationItems[1])
                    if configItemClass ~= nil and configItemClass.getFallbackConfigId ~= nil then
                        local fallbackIndex, fallbackSaveId = configItemClass.getFallbackConfigId(configurationItems, configId, configName, configFileName)
                        if fallbackIndex ~= nil then
                            Logging.info("Unable to find %s configuration '%s' for object '%s'. Using config '%s' as closest match instead.", configName, configId, configFileName, fallbackSaveId)
                            configurationItem = configurationItems[fallbackIndex]
                        end
                    end
                end

                if configurationItem == nil then
                    -- return first selectable config as fallback
                    for j=1, #configurationItems do
                        if configurationItems[j].isSelectable ~= false then
                            Logging.info("Unable to find %s configuration '%s' for object '%s'. Using config '%s' instead.", configName, configId, configFileName, configurationItems[j].saveId)
                            configurationItem = configurationItems[j]
                            break
                        end
                    end
                end

                if configurationItem ~= nil then
                    if boughtConfigurations[configName] == nil then
                        boughtConfigurations[configName] = {}
                    end
                    boughtConfigurations[configName][configurationItem.index] = true

                    if isActive then
                        configurations[configName] = configurationItem.index
                    end

                    if configurationData[configName] == nil then
                        configurationData[configName] = {}
                    end

                    if configurationData[configName][configurationItem.index] == nil then
                        configurationData[configName][configurationItem.index] = {}
                    end

                    configurationItem:loadFromSavegameXMLFile(xmlFile, configKey, configurationData[configName][configurationItem.index])
                end
            end
        end
    end

    return configurations, boughtConfigurations, configurationData
end


---Reads all configurations from network stream
-- @param table manager configuration manager
-- @param integer streamId stream id
-- @param table connection connection
-- @param string configFileName path to xml file of store item
-- @return table configurations configurations
-- @return table boughtConfigurations bought configurations
-- @return table configurationData configuration data
function ConfigurationUtil.readConfigurationsFromStream(manager, streamId, connection, configFileName)
    local configurations = {}
    local boughtConfigurations = {}
    local configurationData = {}

    local numConfigs = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
    for _=1, numConfigs do
        local configNameId = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
        local configName = manager:getConfigurationNameByIndex(configNameId + 1)
        boughtConfigurations[configName] = {}

        local numConfigIds = streamReadUInt16(streamId)
        for _=1, numConfigIds do
            local configId = streamReadUInt16(streamId) + 1
            boughtConfigurations[configName][configId] = true

            if streamReadBool(streamId) then
                configurations[configName] = configId
            end

            if streamReadBool(streamId) then
                local configItem = ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
                if configItem ~= nil then
                    if configurationData[configName] == nil then
                        configurationData[configName] = {}
                    end

                    if configurationData[configName][configId] == nil then
                        configurationData[configName][configId] = {}
                    end

                    configItem:readFromStream(streamId, connection, configurationData[configName][configId])
                else
                    Logging.error("Unable to find configuration item for %s configuration '%s' with id %d on client side!", configFileName, configName, configId)
                end
            end
        end
    end

    return configurations, boughtConfigurations, configurationData
end


---Writes all configurations to network stream
-- @param table manager configuration manager
-- @param integer streamId stream id
-- @param table connection connection
-- @param string configFileName path to xml file of store item
-- @param table configurations configurations
-- @param table boughtConfigurations bought configurations
-- @param table configurationData configuration data
function ConfigurationUtil.writeConfigurationsToStream(manager, streamId, connection, configFileName, configurations, boughtConfigurations, configurationData)
    streamWriteUIntN(streamId, table.size(boughtConfigurations), ConfigurationUtil.SEND_NUM_BITS)
    for configName, configIds in pairs(boughtConfigurations) do
        local configNameId = manager:getConfigurationIndexByName(configName)
        streamWriteUIntN(streamId, configNameId - 1, ConfigurationUtil.SEND_NUM_BITS)

        streamWriteUInt16(streamId, table.size(configIds))
        for configId, _ in pairs(configIds) do
            streamWriteUInt16(streamId, configId - 1)
            streamWriteBool(streamId, configurations[configName] == configId)

            local configItem = ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
            if streamWriteBool(streamId, configItem ~= nil and configItem.writeToStream ~= nil) then
                local data = configurationData[configName]
                if data ~= nil then
                    configItem:writeToStream(streamId, connection, data[configId])
                else
                    configItem:writeToStream(streamId, connection)
                end
            end
        end
    end
end


---Returns true if configuration data has changed
-- @param string configFileName path to xml file of store item
-- @param table configurationData1 configuration data 1
-- @param table configurationData2 configuration data 2
-- @return boolean hasChanged configuration data has changed
function ConfigurationUtil.getConfigurationDataHasChanged(configFileName, configurationData1, configurationData2)
    if configurationData1 == nil and configurationData2 == nil then
        return false
    end

    if configurationData1 == nil or configurationData2 == nil then
        return true
    end

    for configName, data in pairs(configurationData1) do
        if configurationData2[configName] == nil then
            return true
        end

        for configId, configData in pairs(data) do
            if configurationData2[configName][configId] == nil then
                return true
            end

            local configItem = ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
            if configItem.hasDataChanged ~= nil and configItem:hasDataChanged(configData, configurationData2[configName][configId]) then
                return true
            end
        end
    end

    return false
end


---Returns config id from given save identifier
-- @param table object object
-- @param string configName name if config
-- @param string saveId save identifier
-- @return integer configId config id
function ConfigurationUtil.getConfigIdBySaveId(configFileName, configName, configId)
    local item = g_storeManager:getItemByXMLFilename(configFileName)
    if item.configurations ~= nil then
        local configs = item.configurations[configName]
        if configs ~= nil then
            for j=1, #configs do
                if configs[j].saveId == configId then
                    return configs[j].index
                end
            end

            local configItemClass = ClassUtil.getClassObjectByObject(configs[1])
            if configItemClass ~= nil and configItemClass.getFallbackConfigId ~= nil then
                local fallbackIndex, fallbackSaveId = configItemClass.getFallbackConfigId(configs, configId, configName, configFileName)
                if fallbackIndex ~= nil then
                    Logging.info("Unable to find %s configuration '%s' for object '%s'. Using config '%s' as closest match instead.", configName, configId, configFileName, fallbackSaveId)
                    return fallbackIndex
                end
            end

            -- return first selectable config as fallback
            for j=1, #configs do
                if configs[j].isSelectable ~= false then
                    Logging.info("Unable to find %s configuration '%s' for object '%s'. Using config '%s' instead.", configName, configId, configFileName, configs[j].saveId)
                    return configs[j].index
                end
            end
        end
    end

    return 1
end


---Get value of configuration
-- @param integer xmlFile id of xml object
-- @param string key key
-- @param string subKey sub key
-- @param string param parameter
-- @param any defaultValue default value
-- @param string? fallbackConfigKey fallback config key
-- @param string? fallbackOldgKey fallback old key
-- @return any value value of config
function ConfigurationUtil.getConfigurationValue(xmlFile, key, subKey, param, defaultValue, fallbackConfigKey, fallbackOldKey)
    if type(subKey) == "table" then
        printCallstack()
    end
    local value = nil
    if key ~= nil then
        value = xmlFile:getValue(key..subKey..param)
    end

    if value == nil and fallbackConfigKey ~= nil then
        value = xmlFile:getValue(fallbackConfigKey..subKey..param) -- Check for default configuration (xml index 0)
    end
    if value == nil and fallbackOldKey ~= nil then
        value = xmlFile:getValue(fallbackOldKey..subKey..param) -- Fallback to old xml setup
    end
    return Utils.getNoNil(value, defaultValue) -- using default value
end


---Get xml configuration key
-- @param integer xmlFile id of xml object
-- @param integer index index
-- @param string key key
-- @param string? defaultKey default key
-- @param string configurationKey configuration key
-- @return string? configKey key of configuration
-- @return integer configIndex index of configuration
function ConfigurationUtil.getXMLConfigurationKey(xmlFile, index, key, defaultKey, configurationKey)
    local configIndex = Utils.getNoNil(index, 1)
    local configKey = string.format(key.."(%d)", configIndex-1)
    if index ~= nil and not xmlFile:hasProperty(configKey) then
        printWarning("Warning: Invalid "..configurationKey.." index '"..tostring(index).."' in '"..key.."'. Using default "..configurationKey.." settings instead!")
    end

    if not xmlFile:hasProperty(configKey) then
        configKey = key.."(0)"
    end
    if not xmlFile:hasProperty(configKey) then
        configKey = defaultKey
    end

    return configKey, configIndex
end


---Gets the storeitem configurations from xml
-- @param integer xmlFile the xml handle
-- @param string key the name of the base xml element
-- @param string baseDir the base directory
-- @param string customEnvironment a custom environment
-- @param boolean isMod true if the storeitem is a mod, else false
-- @return table configurations a list of configurations
function ConfigurationUtil.getConfigurationsFromXML(manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
    local configurations = {}
    local defaultConfigurationIds = {}
    local numConfigs = 0
    -- try to load default configuration values (title (shown in shop), name, desc, price) - additional parameters can be loaded with loadFunc

    local configurationDescs = manager:getConfigurations()
    for _, configurationDesc in pairs(configurationDescs) do
        local configurationItems = {}

        if configurationDesc.itemClass.preLoad ~= nil then
            configurationDesc.itemClass.preLoad(xmlFile, configurationDesc.configurationsKey, baseDir, customEnvironment, isMod, configurationItems)
        end

        local i = 0
        while true do
            if i > 2 ^ ConfigurationUtil.SEND_NUM_BITS then
                Logging.xmlWarning(xmlFile, "Maximum number of configurations are reached for %s. Only %d configurations per type are allowed!", configurationDesc.name, 2 ^ ConfigurationUtil.SEND_NUM_BITS)
            end
            local configKey = string.format(configurationDesc.configurationKey .."(%d)", i)
            if not xmlFile:hasProperty(configKey) then
                break
            end

            local configItem = configurationDesc.itemClass.new(configurationDesc.name)
            configItem:setIndex(#configurationItems + 1)
            if configItem:loadFromXML(xmlFile, configurationDesc.configurationsKey, configKey, baseDir, customEnvironment) then
                table.insert(configurationItems, configItem)
            end

            i = i + 1
        end

        if configurationDesc.itemClass.postLoad ~= nil then
            configurationDesc.itemClass.postLoad(xmlFile, configurationDesc.configurationsKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configurationDesc.name)
        end

        if #configurationItems > 0 then
            defaultConfigurationIds[configurationDesc.name] = ConfigurationUtil.getDefaultConfigIdFromItems(configurationItems)

            configurations[configurationDesc.name] = configurationItems
            numConfigs = numConfigs + 1
        end
    end
    if numConfigs == 0 then
        return nil, nil
    end

    return configurations, defaultConfigurationIds
end


---Gets predefined configuration sets
-- @param table storeItem a storeItem
-- @param integer xmlFile the xml handle
-- @param string key the key of the base xml element
-- @param string baseDir the base directory
-- @param string customEnvironment a custom environment
-- @param boolean isMod true if the storeitem is a mod, else false
-- @return table configuration sets
function ConfigurationUtil.getConfigurationSetsFromXML(storeItem, xmlFile, key, baseDir, customEnvironment, isMod)
    local configurationSetsKey = string.format("%s.configurationSets", key)
    local overwrittenTitle = xmlFile:getValue(configurationSetsKey.."#title", nil, customEnvironment, false)
    local isYesNoOption = xmlFile:getValue(configurationSetsKey.."#isYesNoOption", false)

    local configurationsSets = {}
    local i = 0
    while true do
        local configSetKey = string.format("%s.configurationSet(%d)", configurationSetsKey, i)
        if not xmlFile:hasProperty(configSetKey) then
            break
        end

        local configSet = {}
        configSet.name = xmlFile:getValue(configSetKey.."#name", nil, customEnvironment, false)

        local params = xmlFile:getValue(configSetKey.."#params")
        if params ~= nil then
            configSet.name = g_i18n:insertTextParams(configSet.name, params, customEnvironment, xmlFile)
        end

        configSet.isDefault = xmlFile:getValue(configSetKey.."#isDefault", false)

        configSet.overwrittenTitle = overwrittenTitle
        configSet.isYesNoOption = isYesNoOption
        configSet.configurations = {}

        local j = 0
        while true do
            local configKey = string.format("%s.configuration(%d)", configSetKey, j)
            if not xmlFile:hasProperty(configKey) then
                break
            end

            local name = xmlFile:getValue(configKey.."#name")
            if name ~= nil then
                if storeItem.configurations[name] ~= nil then
                    local index = xmlFile:getValue(configKey.."#index")
                    if index ~= nil then
                        if storeItem.configurations[name][index] ~= nil then
                            configSet.configurations[name] = index
                        else
                            Logging.xmlWarning(xmlFile, "Index '%d' not defined for configuration '%s'!", index, name)
                        end
                    end
                else
                    Logging.xmlWarning(xmlFile, "Configuration name '%s' is not defined!", name)
                end
            else
                Logging.xmlWarning(xmlFile, "Missing name for configuration set item '%s'!", configSetKey)
            end

            j = j + 1
        end

        table.insert(configurationsSets, configSet)
        configSet.index = #configurationsSets

        i = i + 1
    end

    return configurationsSets
end


---
function ConfigurationUtil.getSubConfigurationsFromConfigurations(manager, configurations)
    local subConfigurations = nil

    if configurations ~= nil then
        subConfigurations = {}

        for name, items in pairs(configurations) do
            local config = manager:getConfigurationDescByName(name)
            if config.hasSubselection then
                local subConfigValues = config.getSubConfigurationValuesFunc(items)
                if #subConfigValues > 1 then
                    local subConfigItemMapping = {}
                    subConfigurations[name] = {subConfigValues=subConfigValues, subConfigItemMapping=subConfigItemMapping}

                    for k, value in ipairs(subConfigValues) do
                        subConfigItemMapping[value] = config.getItemsBySubConfigurationIdentifierFunc(items, value)
                    end
                end
            end
        end
    end

    return subConfigurations
end



---Get the default config id
-- @param table storeItem a storeitem object
-- @param string configurationName name of the configuration
-- @return integer configId the default config id
function ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
    if configItems ~= nil then
        for k, item in pairs(configItems) do
            if item.isDefault then
                if item.isSelectable ~= false then
                    return k
                end
            end
        end

        for k, item in pairs(configItems) do
            if item.isSelectable ~= false then
                return k
            end
        end
    end

    return 1
end


---
function ConfigurationUtil.getConfigurationsMatchConfigSets(configurations, configSets)
    for _, configSet in pairs(configSets) do
        local isMatch = true
        for configName, index in pairs(configSet.configurations) do
            if configurations[configName] ~= index then
                isMatch = false
                break
            end
        end

        if isMatch then
            return true
        end
    end

    return false
end


---
function ConfigurationUtil.getClosestConfigurationSet(configurations, configSets)
    local closestSet = nil
    local closestSetMatches = 0
    for _, configSet in pairs(configSets) do
        local numMatches = 0
        for configName, index in pairs(configSet.configurations) do
            if configurations[configName] == index then
                numMatches = numMatches + 1
            end
        end
        if numMatches > closestSetMatches then
            closestSet = configSet
            closestSetMatches = numMatches
        end
    end

    return closestSet, closestSetMatches
end


---Get whether a material is visualized as metallic in UI
function ConfigurationUtil.isColorMetallic(materialId)
    return materialId == 2
        or materialId == 3
        or materialId == 19
        or materialId == 30
        or materialId == 31
        or materialId == 35
end
