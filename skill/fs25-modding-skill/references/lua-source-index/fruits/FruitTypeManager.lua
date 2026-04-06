








































---This class handles all fruitTypes and fruitTypeCategories
local FruitTypeManager_mt = Class(FruitTypeManager, AbstractManager)


---Creating manager
-- @param table? customMt
-- @return any self
function FruitTypeManager.new(customMt)
    local self = AbstractManager.new(customMt or FruitTypeManager_mt)

    addConsoleCommand("gsFruitTypesExportStats", "Exports the fruit type stats into a text file", "consoleCommandExportStats", self)

    return self
end


---Initialize data structures
function FruitTypeManager:initDataStructures()
    self.fruitTypes = {}
    self.indexToFruitType = {}
    self.nameToIndex = {}
    self.nameToFruitType = {}
    self.fruitTypeIndexToFillType = {}
    self.fillTypeIndexToFruitTypeIndex = {}
    self.densityTypeIndexToFruitType = {}

    self.fruitTypeConverters = {}
    self.fruitTypeConverterLoadData = {}
    self.converterNameToIndex = {}
    self.nameToConverter = {}

    self.windrowFillTypes = {}
    self.fruitTypeIndexToWindrowFillTypeIndex = {}
    self.windrowCutFillTypeIndexToFruitTypeIndex = {}

    self.modFoliageTypesToLoad = {}

    self.numCategories = 0
    self.categories = {}
    self.indexToCategory = {}
    self.categoryIndexToFruitTypeIndex = {}

    FruitType = self.nameToIndex
    FruitType.UNKNOWN = 0
    FruitTypeCategory = self.categories
    FruitTypeConverter = self.converterNameToIndex

    self.defaultDataPlaneId = nil
end


---
function FruitTypeManager:loadDefaultTypes()
    local xmlFile = loadXMLFile("fuitTypes", "data/maps/maps_fruitTypes.xml")
    self:loadFruitTypes(xmlFile, nil, "", true)
    delete(xmlFile)
end


---Load data on map load
-- @param entityId xmlFileHandle
-- @param table missionInfo
-- @param string? baseDirectory
-- @return boolean true if loading was successful else false
function FruitTypeManager:loadMapData(xmlFileHandle, missionInfo, baseDirectory)
    FruitTypeManager:superClass().loadMapData(self)

    self:loadDefaultTypes()

    local success =  XMLUtil.loadDataFromMapXML(xmlFileHandle, "fruitTypes", baseDirectory, self, self.loadFruitTypes, missionInfo, baseDirectory, false)

    -- initialize the fruit type converters after all fruit types have been loaded
    for converter, converterData in pairs(self.fruitTypeConverterLoadData) do
        if self.fruitTypeConverters[converter] ~= nil then
            for _, data in ipairs(converterData) do
                local fruitType = self:getFruitTypeByName(data.fruitTypeName)
                local fillType = g_fillTypeManager:getFillTypeByName(data.fillTypeName)
                if fruitType ~= nil and fillType ~= nil then
                    self.fruitTypeConverters[converter][fruitType.index] = {fillTypeIndex=fillType.index, conversionFactor=data.conversionFactor}
                end
            end
        end
    end

    return success
end


---Loads fruitTypes
-- @param entityId xmlFileHandle
-- @param table missionInfo
-- @param string? baseDirectory
-- @param boolean? isBaseType
-- @return boolean success success
function FruitTypeManager:loadFruitTypes(xmlFileHandle, missionInfo, baseDirectory, isBaseType)
    local xmlFile = XMLFile.wrap(xmlFileHandle)
    local rootName = xmlFile:getRootName()

    local maxNumFruitTypes = 2^FruitTypeManager.SEND_NUM_BITS-1

    for _, key in xmlFile:iterator(rootName .. ".fruitTypes.fruitType") do
        if #self.fruitTypes >= maxNumFruitTypes then
            Logging.xmlError(xmlFile, "FruitTypeManager.loadFruitTypes: too many fruit types. Only %d fruit types are supported", maxNumFruitTypes)
            break
        end

        local filename = xmlFile:getString(key .. "#filename")
        if filename ~= nil then
            filename = Utils.getFilename(filename, baseDirectory)

            local fruitTypeDesc = FruitTypeDesc.new()
            if fruitTypeDesc:loadFromFoliageXMLFile(filename) then
                table.insert(self.fruitTypes, fruitTypeDesc)

                fruitTypeDesc.index = #self.fruitTypes

                self.nameToFruitType[fruitTypeDesc.name] = fruitTypeDesc
                self.nameToIndex[fruitTypeDesc.name] = fruitTypeDesc.index
                self.indexToFruitType[fruitTypeDesc.index] = fruitTypeDesc

                self.fillTypeIndexToFruitTypeIndex[fruitTypeDesc.fillType.index] = fruitTypeDesc.index
                self.fruitTypeIndexToFillType[fruitTypeDesc.index] = fruitTypeDesc.fillType

                local windrowFillType = fruitTypeDesc.windrowFillType
                if windrowFillType ~= nil then
                    self.windrowFillTypes[windrowFillType.index] = true
                    self.fruitTypeIndexToWindrowFillTypeIndex[fruitTypeDesc.index] = windrowFillType.index
                    self.fillTypeIndexToFruitTypeIndex[windrowFillType.index] = fruitTypeDesc.index
                end

                if fruitTypeDesc.windrowCutFillType ~= nil then
                    self.windrowCutFillTypeIndexToFruitTypeIndex[fruitTypeDesc.windrowCutFillType.index] = fruitTypeDesc.index
                end
            end
        else
            Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: Missing fruit type filename for '%s'", key)

--             FruitTypeManager.convert(xmlFile, key)
        end
    end

    for _, key in xmlFile:iterator(rootName .. ".fruitTypeCategories.fruitTypeCategory") do
        local name = xmlFile:getString(key .. "#name")
        local fruitTypesStr = xmlFile:getString(key)

        local fruitTypeCategoryIndex = self:addFruitTypeCategory(name, isBaseType)
        if fruitTypeCategoryIndex ~= nil then
            local fruitTypeNames = string.split(fruitTypesStr, " ")
            for _, fruitTypeName in ipairs(fruitTypeNames) do
                local fruitType = self:getFruitTypeByName(fruitTypeName)
                if fruitType ~= nil then
                    if not self:addFruitTypeToCategory(fruitType.index, fruitTypeCategoryIndex) then
                        Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: Could not add fruitType '%s' to fruitTypeCategory '%s'!", fruitTypeName, name)
                    end
                else
                    Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: FruitType '%s' referenced in fruitTypeCategory '%s' is not defined!", fruitTypeName, name)
                end
            end
        end
    end

    for _, key in xmlFile:iterator(rootName .. ".fruitTypeConverters.fruitTypeConverter") do
        local name = xmlFile:getString(key .. "#name")
        local converter = self:addFruitTypeConverter(name, isBaseType)
        if converter ~= nil then
            for _, converterKey in xmlFile:iterator(key .. ".converter") do
                local from = xmlFile:getString(converterKey .. "#from")
                local to = xmlFile:getString(converterKey .. "#to")
                local factor = xmlFile:getFloat(converterKey .. "#factor", 1)

                self:addFruitTypeConversion(converter, from, to, factor)
            end
        end
    end

    xmlFile:delete()

    return true
end


---Gets a fruitType by index
-- @param integer index the fruit index
-- @return table fruit the fruit object
function FruitTypeManager:getFruitTypeByIndex(index)
    return self.indexToFruitType[index]
end


---
-- @param integer index
-- @return string? fruitTypeName
function FruitTypeManager:getFruitTypeNameByIndex(index)
    local fruitType = self.indexToFruitType[index]
    if fruitType ~= nil then
        return fruitType.name
    end

    if index == FruitType.UNKNOWN then
        return "UNKNOWN"
    end

    return nil
end


---Gets a fruitType by index name
-- @param string name the fruit index name
-- @return table fruitType the fruit object
function FruitTypeManager:getFruitTypeByName(name)
    if name == nil then
        return nil
    end

    return self.nameToFruitType[string.upper(name)]
end















---Gets a list of fruitTypes
-- @return table fruitTypes a list of fruitTypes
function FruitTypeManager:getFruitTypes()
    return self.fruitTypes
end


---
-- @param integer index
-- @return integer? fruitTypeIndex
function FruitTypeManager:getFruitTypeIndexByFillTypeIndex(index)
--#debug     Assert.isInteger(index)
    return self.fillTypeIndexToFruitTypeIndex[index]
end


---
-- @param integer index
-- @return table? fruitType
function FruitTypeManager:getFruitTypeByFillTypeIndex(index)
--#debug     Assert.isInteger(index)
    return self.fruitTypes[self.fillTypeIndexToFruitTypeIndex[index]]
end


---
-- @param integer index
-- @return integer? fillTypeIndex
function FruitTypeManager:getFillTypeIndexByFruitTypeIndex(index)
--#debug     Assert.isInteger(index)
    local fillType = self.fruitTypeIndexToFillType[index]
    if fillType ~= nil then
        return fillType.index
    end
    return nil
end


---
-- @param integer index
-- @return table fillType
function FruitTypeManager:getFillTypeByFruitTypeIndex(index)
--#debug     Assert.isInteger(index)
    return self.fruitTypeIndexToFillType[index]
end


---
-- @param integer index
-- @return string? fillTypeName
function FruitTypeManager:getFillTypeNameByFruitTypeIndex(index)
--#debug     Assert.isInteger(index)
    local fillTypeIndex = self.fruitTypeIndexToFillType[index]
    return fillTypeIndex and fillTypeIndex.name or nil
end


---
-- @param integer index
-- @param boolean? isForageCutter
-- @return float cutHeight in m
function FruitTypeManager:getCutHeightByFruitTypeIndex(index, isForageCutter)
--#debug     Assert.isInteger(index)
    local fruitType = self.indexToFruitType[index]
    if isForageCutter then
        return (fruitType and (fruitType.forageCutHeight or fruitType.cutHeight)) or 0.15
    end

    return (fruitType and fruitType.cutHeight) or 0.15
end















---Adds a new fruitType category
-- @param string name fruit category index name
-- @param boolean isBaseType if true overwriting of existing category with the same name is prohibited
-- @return integer categoryIndex index of the added category
function FruitTypeManager:addFruitTypeCategory(name, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: '"..tostring(name).."' is not a valid name for a fruitTypeCategory. Ignoring fruitTypeCategory!")
        return nil
    end

    name = name:upper()

    if isBaseType and self.categories[name] ~= nil then
        printWarning("Warning: FruitTypeCategory '"..tostring(name).."' already exists. Ignoring fruitTypeCategory!")
        return nil
    end

    local index = self.categories[name]

    if index == nil then
        self.numCategories = self.numCategories + 1
        self.categories[name] = self.numCategories
        self.indexToCategory[self.numCategories] = name
        self.categoryIndexToFruitTypeIndex[self.numCategories] = {}
        index = self.numCategories
    end

    return index
end


---Add fruitType to category
-- @param integer fruitTypeIndex index of fruit type
-- @param integer categoryIndex index of category
-- @return table success true if added else false
function FruitTypeManager:addFruitTypeToCategory(fruitTypeIndex, categoryIndex)
    if categoryIndex ~= nil and fruitTypeIndex ~= nil then
        table.insert(self.categoryIndexToFruitTypeIndex[categoryIndex], fruitTypeIndex)
        return true
    end
    return false
end


---Gets a list of fruitTypes (tables/objects) of the given category names
-- @param string names string of space separated fruitType category index names
-- @param string warning a warning text shown if a category is not found
-- @return table fruitTypes list of fruitTypes (tables/objects)
function FruitTypeManager:getFruitTypesByCategoryNames(names, warning)
    local fruitTypes = {}
    local alreadyAdded = {}
    local categories = string.split(names, " ")
    for _, categoryName in pairs(categories) do
        categoryName = categoryName:upper()
        local categoryIndex = self.categories[categoryName]
        local categoryFruitTypeIndices = self.categoryIndexToFruitTypeIndex[categoryIndex]
        if categoryFruitTypeIndices ~= nil then
            for _, fruitTypeIndex in ipairs(categoryFruitTypeIndices) do
                local fruitType = self.indexToFruitType[fruitTypeIndex]
                if alreadyAdded[fruitType] == nil then
                    table.insert(fruitTypes, fruitType)
                    alreadyAdded[fruitType] = true
                end
            end
        else
            if warning ~= nil then
                printWarning(string.format(warning, categoryName))
            end
        end
    end
    return fruitTypes
end


---Gets a list of fruitTypesIndices of the given category names
-- @param string names string of space separated fruitType category index names
-- @param string warning a warning text shown if a category is not found
-- @return table fruitTypesIndices list of fruitTypeIndices
function FruitTypeManager:getFruitTypeIndicesByCategoryNames(names, warning)
    local fruitTypes = self:getFruitTypesByCategoryNames(names, warning)

    -- convert to list of indices
    for index, fruitType in ipairs(fruitTypes) do
        fruitTypes[index] = fruitType.index
    end

    return fruitTypes  -- indices
end


---Gets list of fruitTypes (tables/objects) from string with fruit type names
-- @param string names string of space separated fruit type names
-- @param string? warning warning if fruit type not found
-- @return list fruitTypes array of fruit types (tables/objects)
function FruitTypeManager:getFruitTypesByNames(names, warning)
    local fruitTypes = {}
    local alreadyAdded = {}
    local fruitTypeNames = string.split(names, " ")
    for _, name in pairs(fruitTypeNames) do
        name = name:upper()
        local fruitType = self.nameToFruitType[name]
        if fruitType ~= nil then
            if alreadyAdded[fruitType] == nil then
                table.insert(fruitTypes, fruitType)
                alreadyAdded[fruitType] = true
            end
        else
            if warning ~= nil then
                printWarning(string.format(warning, name))
            end
        end
    end

    return fruitTypes
end


---Gets list of fruitType indices from string with space separated fruit type names
-- @param string names string of space separated fruit type names
-- @param string? warning warning if fruit type not found
-- @return list fruitTypeIndices array of fruit type indices
function FruitTypeManager:getFruitTypeIndicesByNames(names, warning)
    local fruitTypes = self:getFruitTypesByNames(names, warning)

    -- convert to list of indices
    for index, fruitType in ipairs(fruitTypes) do
        fruitTypes[index] = fruitType.index
    end

    return fruitTypes  -- indices
end


---Gets a list of fillType from string with fruit type names
-- @param string names fruit type names
-- @param string? warning warning if fill type not found
-- @return table fillTypes fill types
function FruitTypeManager:getFillTypesByFruitTypeNames(names, warning)
    local fillTypes = {}
    local alreadyAdded = {}
    local fruitTypeNames = string.split(names, " ")
    for _, name in pairs(fruitTypeNames) do
        local fillType = nil
        local fruitType = self:getFruitTypeByName(name)
        if fruitType ~= nil then
            fillType = self:getFillTypeByFruitTypeIndex(fruitType.index)
        end
        if fillType ~= nil then
            if alreadyAdded[fillType] == nil then
                table.insert(fillTypes, fillType)
                alreadyAdded[fillType] = true
            end
        else
            if warning ~= nil then
                printWarning(string.format(warning, name))
            end
        end
    end

    return fillTypes
end


---Gets a list of fillType indices from string of space separated fruit type names
-- @param string names fruit type names
-- @param string? warning warning if fill type not found
-- @return table fillTypes fill types
function FruitTypeManager:getFillTypeIndicesByFruitTypeNames(names, warning)
    local fillTypes = self:getFillTypesByFruitTypeNames(names, warning)

    -- convert to list of indices
    for index, fillType in ipairs(fillTypes) do
        fillTypes[index] = fillType.index
    end

    return fillTypes  -- indices
end


---Gets a list of fillTypes from string of space separated fruit type category names
-- @param string fruitTypeCategoryNames fruit type categories
-- @param string? warning warning if category not found
-- @return table fillTypes fill types
function FruitTypeManager:getFillTypesByFruitTypeCategoryNames(fruitTypeCategoryNames, warning)
    local fillTypes = {}
    local alreadyAdded = {}
    local categories = string.split(fruitTypeCategoryNames, " ")
    for _, categoryName in pairs(categories) do
        categoryName = categoryName:upper()
        local category = self.categories[categoryName]
        if category ~= nil then
            for _, fruitTypeIndex in ipairs(self.categoryIndexToFruitTypeIndex[category]) do
                local fillType = self:getFillTypeByFruitTypeIndex(fruitTypeIndex)
                if fillType ~= nil then
                    if alreadyAdded[fillType] == nil then
                        table.insert(fillTypes, fillType)
                        alreadyAdded[fillType] = true
                    end
                end
            end
        else
            if warning ~= nil then
                printWarning(string.format(warning, categoryName))
            end
        end
    end
    return fillTypes
end


---Gets a list of fillType indices from string of space separated fruit type category names
-- @param string fruitTypeCategoryNames fruit type categories
-- @param string? warning warning if category not found
-- @return table fillTypes fill type indices
function FruitTypeManager:getFillTypeIndicesByFruitTypeCategoryName(fruitTypeCategoryNames, warning)
    local fillTypes = self:getFillTypesByFruitTypeCategoryNames(fruitTypeCategoryNames, warning)

    -- convert to list of indices
    for index, fillType in ipairs(fillTypes) do
        fillTypes[index] = fillType.index
    end

    return fillTypes  -- indices
end



---
-- @param integer index
-- @return boolean isFillTypeWindrow
function FruitTypeManager:isFillTypeWindrow(index)
    if index ~= nil then
--#debug         Assert.isInteger(index)
        return self.windrowFillTypes[index] == true
    end
    return false
end


---
-- @param integer index
-- @return integer? windrowFillTypeIndex
function FruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(index)
--#debug     Assert.isInteger(index)
    return self.fruitTypeIndexToWindrowFillTypeIndex[index]
end



---Get fill type liter per sqm
-- @param integer fillTypeIndex fill type index
-- @param float defaultValue default value if fill type not found
-- @return float literPerSqm liter per sqm
function FruitTypeManager:getFillTypeLiterPerSqm(fillTypeIndex, defaultValue)
--#debug     Assert.isInteger(fillTypeIndex)
    local fruitType = self.fruitTypes[self:getFruitTypeIndexByFillTypeIndex(fillTypeIndex)]
    if fruitType ~= nil then
        if fruitType.hasWindrow then
            return fruitType.windrowLiterPerSqm
        else
            return fruitType.literPerSqm
        end
    end
    return defaultValue
end























---Adds a new  ruit type converter
-- @param string name name
-- @param boolean isBaseType if true overwriting existing converter with the same name is prohibited
-- @return integer converterIndex index of converterIndex
function FruitTypeManager:addFruitTypeConverter(name, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: '"..tostring(name).."' is not a valid name for a fruitTypeConverter. Ignoring fruitTypeConverter!")
        return nil
    end

    name = name:upper()

    if isBaseType and self.converterNameToIndex[name] ~= nil then
        printWarning("Warning: FruitTypeConverter '"..tostring(name).."' already exists. Ignoring fruitTypeConverter!")
        return nil
    end

    local index = self.converterNameToIndex[name]
    if index == nil then
        local converter = {}
        table.insert(self.fruitTypeConverters, converter)
        self.converterNameToIndex[name] = #self.fruitTypeConverters
        self.nameToConverter[name] = converter
        index = #self.fruitTypeConverters
    end

    return index
end


---Add fruit type to fill type conversion
-- @param integer converter index of converter
-- @param integer fruitTypeIndex fruit type index
-- @param integer fillTypeIndex fill type index
-- @param float conversionFactor factor of conversion
function FruitTypeManager:addFruitTypeConversion(converter, fruitTypeName, fillTypeName, conversionFactor)
    if converter ~= nil then
        if self.fruitTypeConverterLoadData[converter] == nil then
            self.fruitTypeConverterLoadData[converter] = {}
        end

        table.insert(self.fruitTypeConverterLoadData[converter], {fruitTypeName=fruitTypeName, fillTypeName=fillTypeName, conversionFactor=conversionFactor})
    end
end


---Returns converter data by given name
-- @param string converterName name of converter
-- @return table converterData converter data
function FruitTypeManager:getConverterDataByName(converterName)
    return self.nameToConverter[converterName and converterName:upper()]
end


---Add additional foliage types that should be added
-- @param string name name of foliage type
-- @param string filename absolute path to the foliage xml
function FruitTypeManager:addModFoliageType(name, filename)
    table.insert(self.modFoliageTypesToLoad, {name=name, filename=filename})
end
