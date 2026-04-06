









---This class handles all configuration types
local ConfigurationManager_mt = Class(ConfigurationManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function ConfigurationManager.new(typeName, rootElementName, customMt)
    local self = AbstractManager.new(customMt or ConfigurationManager_mt)

    self.typeName = typeName
    self.rootElementName = rootElementName
    self:initDataStructures()

    return self
end


---Initialize data structures
function ConfigurationManager:initDataStructures()
    self.configurations = {}
    self.intToConfigurationName = {}
    self.configurationNameToInt = {}
    self.sortedConfigurationNames = {}
end





















































---Returns number of configuration types
-- @return integer numOfConfigurationTypes number of configuration types
function ConfigurationManager:getNumOfConfigurationTypes()
    return #self.intToConfigurationName
end


---Returns a table of the available configuration types
-- @return table List of configuration types (names)
function ConfigurationManager:getConfigurationTypes()
    return self.intToConfigurationName
end


---Returns a table of the available configuration types sorted by priority
-- @return table List of configuration types (names)
function ConfigurationManager:getSortedConfigurationTypes()
    return self.sortedConfigurationNames
end


---Returns configuration name by given index
-- @param integer index index of config
-- @return string name name of config
function ConfigurationManager:getConfigurationNameByIndex(index)
    return self.intToConfigurationName[index]
end


---Returns configuration index by given name
-- @param string name name of config
-- @return integer index index of config
function ConfigurationManager:getConfigurationIndexByName(name)
    return self.configurationNameToInt[name]
end


---Returns table with all available configurations
-- @return table configurations configurations
function ConfigurationManager:getConfigurations()
    return self.configurations
end


---Returns configuration desc by name
-- @param string name name of config
-- @return table configuration configuration
function ConfigurationManager:getConfigurationDescByName(name)
    return self.configurations[name]
end


---Returns configuration attribute by given name and attribute
-- @param string configurationName name of config
-- @param string attribute name of attribute
-- @return any value value of attribute
function ConfigurationManager:getConfigurationAttribute(configurationName, attribute)
    local config = self:getConfigurationDescByName(configurationName)
    return config[attribute]
end


---Returns the selector type for a given configuration name
-- @param string configurationName name of config
-- @return integer selectorType Selector type
function ConfigurationManager:getConfigurationSelectorType(configurationName)
    local config = self:getConfigurationDescByName(configurationName)
    if config ~= nil then
        return config.itemClass.SELECTOR
    end

    return ConfigurationUtil.SELECTOR_MULTIOPTION
end


---Returns the xml keys for a given configuration name
-- @param string configurationsKey Path to the main configuration element
-- @param string configurationKey Path to the individual configuration element
function ConfigurationManager:getConfigurationKeys(configurationName)
    local config = self:getConfigurationDescByName(configurationName)
    if config ~= nil then
        return config.configurationsKey, config.configurationKey
    end

    return nil, nil
end


---
function ConfigurationManager:configurationKeyIterator()
    local currentIndex = 0
    local numElements = #self.intToConfigurationName

    return function()
        if currentIndex >= numElements then
            return nil
        end

        currentIndex = currentIndex + 1

        local name = self.intToConfigurationName[currentIndex]

        local configurationsKey, configurationKey = self:getConfigurationKeys(name)
        return configurationsKey, configurationKey .. "(?)"
    end
end
