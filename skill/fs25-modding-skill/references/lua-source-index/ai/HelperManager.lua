
























---This class handles all helpers
local HelperManager_mt = Class(HelperManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function HelperManager.new(customMt)
    local self = AbstractManager.new(customMt or HelperManager_mt)
    return self
end


---Initialize data structures
function HelperManager:initDataStructures()
    self.numHelpers = 0
    self.helpers = {}
    self.nameToIndex = {}
    self.indexToHelper = {}
    self.availableHelpers = {}
end


---
function HelperManager:loadDefaultTypes(missionInfo, baseDirectory)
    local xmlFile = loadXMLFile("helpers", "data/maps/maps_helpers.xml")
    self:loadHelpers(xmlFile, missionInfo, baseDirectory, true, nil)
    delete(xmlFile)
end


---Load data on map load
-- @return boolean true if loading was successful else false
function HelperManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    HelperManager:superClass().loadMapData(self)

    self:loadDefaultTypes()
    return XMLUtil.loadDataFromMapXML(xmlFile, "helpers", baseDirectory, self, self.loadHelpers, missionInfo, baseDirectory, false, missionInfo.customEnvironment)
end


---Load data on map load
-- @return boolean true if loading was successful else false
function HelperManager:loadHelpers(xmlFileHandle, missionInfo, baseDirectory, isBaseType, customEnvironment)
    local xmlFile = XMLFile.wrap(xmlFileHandle, HelperManager.xmlSchema)
    if xmlFile == nil then
        return false
    end

    for _, key in xmlFile:iterator("map.helpers.helper") do
        local name = xmlFile:getValue(key .. "#name")
        local title = xmlFile:getValue(key .. "#title", nil, customEnvironment, false)
        local color = xmlFile:getValue(key .. "#color", {1, 1, 1})
        local playerStyle = PlayerStyle.new()
        playerStyle:loadFromXMLFile(xmlFile, key .. ".playerStyle")

        self:addHelper(name, title, color, playerStyle, baseDirectory, isBaseType)
    end

    xmlFile:delete()

    return true
end


---Adds a new helper
-- @param string name helper index name
-- @param string modelFilename helper model filename
-- @param string baseDir the base directory
-- @return boolean true if added successful else false
function HelperManager:addHelper(name, title, color, playerStyle, baseDir, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: '"..tostring(name).."' is not a valid name for a helper. Ignoring helper!")
        return nil
    end

    name = name:upper()

    if isBaseType and self.nameToIndex[name] ~= nil then
        printWarning("Warning: Helper '"..tostring(name).."' already exists. Ignoring helper!")
        return nil
    end

    local helper = self.helpers[name]
    if helper == nil then
        self.numHelpers = self.numHelpers + 1

        helper = {}
        helper.name = name
        helper.index = self.numHelpers
        helper.color = color
        helper.title = name
        if title ~= nil then
            helper.title = title
        end
        helper.playerStyle = playerStyle

        self.helpers[name] = helper
        self.nameToIndex[name] = self.numHelpers
        self.indexToHelper[self.numHelpers] = helper
        table.insert(self.availableHelpers, helper)
    else
        if title ~= nil then
            helper.title = g_i18n:convertText(title)
        end
        if playerStyle ~= nil then
            helper.playerStyle = playerStyle
        end
    end

    return helper
end


---Gets a random helper
-- @return table helper a random helper object
function HelperManager:getRandomHelper()
    return self.availableHelpers[math.random(1, #self.availableHelpers)]
end


---Gets a random helper
-- @return table helper a random helper style
function HelperManager:getRandomHelperStyle()
    return self.indexToHelper[math.random(1, self.numHelpers)].playerStyle
end


---Gets a random helper index
-- @return integer helperIndex a random helper index
function HelperManager:getRandomIndex()
    return math.random(1, self.numHelpers)
end


---Gets a helper by index
-- @param integer index the helper index
-- @return table helper the helper object
function HelperManager:getHelperByIndex(index)
    if index ~= nil then
        return self.indexToHelper[index]
    end
    return nil
end


---Gets a helper by index name
-- @param string name the helper index name
-- @return table helper the helper object
function HelperManager:getHelperByName(name)
    if name ~= nil then
        name = name:upper()
        return self.helpers[name]
    end
    return nil
end


---Marks a helper as 'in use'
-- @param table helper the helper object
-- @return boolean success true if helper is marked else false
function HelperManager:useHelper(helper)
    for k, h in pairs(self.availableHelpers) do
        if h == helper then
            table.remove(self.availableHelpers, k)
            return true
        end
    end
    return false
end


---Marks a helper as 'not in use'
-- @param table helper the helper object
function HelperManager:releaseHelper(helper)
    table.insert(self.availableHelpers, helper)
end


---Gets number of helpers
-- @return integer numOfHelpers total number of helpers
function HelperManager:getNumOfHelpers()
    return self.numHelpers
end
