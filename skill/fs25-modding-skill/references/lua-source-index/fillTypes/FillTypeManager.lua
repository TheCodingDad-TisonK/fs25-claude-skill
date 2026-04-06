
































































---
local FillTypeManager_mt = Class(FillTypeManager, AbstractManager)


---Creating manager
-- @param table? customMt
-- @return table instance instance of object
function FillTypeManager.new(customMt)
    local self = AbstractManager.new(customMt or FillTypeManager_mt)
    return self
end


---Initialize data structures
function FillTypeManager:initDataStructures()
    self.fillTypes = {}
    self.nameToFillType = {}
    self.indexToFillType = {}
    self.nameToIndex = {}
    self.indexToName = {}
    self.indexToTitle = {}

    self.fillTypeConverters = {}
    self.converterNameToIndex = {}
    self.nameToConverter = {}

    self.categories = {}
    self.nameToCategoryIndex = {}
    self.categoryIndexToFillTypes = {}
    self.categoryNameToFillTypes = {}
    self.fillTypeIndexToCategories = {}

    self.fillTypeSamples = {}
    self.fillTypeToSample = {}

    self.modsToLoad = {}

    FillType = self.nameToIndex
    FillTypeCategory = self.categories
end


---
function FillTypeManager:loadDefaultTypes()
    local xmlFile = loadXMLFile("fillTypes", "data/maps/maps_fillTypes.xml")
    self:loadFillTypes(xmlFile, nil, true, nil)
    delete(xmlFile)
end


---Load data on map load
-- @param integer xmlFile
-- @param table missionInfo
-- @param string baseDirectory
-- @return boolean true if loading was successful else false
function FillTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    FillTypeManager:superClass().loadMapData(self)

    self:loadDefaultTypes()

    if XMLUtil.loadDataFromMapXML(xmlFile, "fillTypes", baseDirectory, self, self.loadFillTypes, baseDirectory, false, missionInfo.customEnvironment) then
        -- Load additional fill types from mods
        for _, data in ipairs(self.modsToLoad) do
            local xmlFilename, baseDirectoryMod, customEnvironment = unpack(data)
            local fillTypesXMLFile = XMLFile.load("fillTypes", xmlFilename, FillTypeManager.xmlSchema)
            if fillTypesXMLFile ~= nil then
                g_fillTypeManager:loadFillTypes(fillTypesXMLFile, baseDirectoryMod, false, customEnvironment)
                fillTypesXMLFile:delete()
            end
        end

        for _, fruitType in ipairs(self.fillTypes) do
            fruitType:finalize()
        end

        return true
    end

    return false
end










---
function FillTypeManager:unloadMapData()
    for _, sample in pairs(self.fillTypeSamples) do
        g_soundManager:deleteSample(sample.sample)
    end

    for _, fillTypeDesc in pairs(self.fillTypes) do
        fillTypeDesc:delete()
    end

    FillTypeManager:superClass().unloadMapData(self)
end


---Loads fillTypes
-- @param table|integer xmlFile XMLFile instance or xml handle
-- @param string baseDirectory For sourcing textures and sounds
-- @param boolean isBaseType Is basegame type
-- @param string? customEnv Custom environment
-- @return boolean success success
function FillTypeManager:loadFillTypes(xmlFile, baseDirectory, isBaseType, customEnv)
    if xmlFile == nil or xmlFile == 0 then
        return false
    end

    if type(xmlFile) ~= "table" then
        xmlFile = XMLFile.wrap(xmlFile, FillTypeManager.xmlSchema)
    end

    local rootName = xmlFile:getRootName()

    if isBaseType then
        local unknownFillType = FillTypeDesc.new() -- FillType.UNKNOWN
        unknownFillType.economy.sychronizeData = false
        self:addFillType(unknownFillType)
    end

    for _, ftKey in xmlFile:iterator(rootName .. ".fillTypes.fillType") do
        local name = xmlFile:getValue(ftKey.."#name")
        if name ~= nil then
            name = string.upper(name)
            if isBaseType and self.nameToFillType[name] ~= nil then
                Logging.warning("FillType '%s' already exists. Ignoring fillType!", name)
                continue
            end

            local fillTypeDesc = self.nameToFillType[name]
            if fillTypeDesc == nil then
                fillTypeDesc = FillTypeDesc.new()
            end

            if fillTypeDesc:loadFromXMLFile(xmlFile, ftKey, baseDirectory, customEnv) then
                if self.nameToFillType[name] == nil then
                    self:addFillType(fillTypeDesc)
                end
            end
        end
    end

    for _, ftCategoryKey in xmlFile:iterator(rootName .. ".fillTypeCategories.fillTypeCategory") do
        local name = xmlFile:getValue(ftCategoryKey.."#name")
        local fillTypesList = xmlFile:getValue(ftCategoryKey)
        local fillTypeCategoryIndex = self:addFillTypeCategory(name, isBaseType)
        if fillTypesList ~= nil and fillTypeCategoryIndex ~= nil then
            for _, fillTypeName in ipairs(fillTypesList) do
                local fillType = self:getFillTypeByName(fillTypeName)
                if fillType ~= nil then
                    if not self:addFillTypeToCategory(fillType.index, fillTypeCategoryIndex) then
                        Logging.warning("Could not add fillType '"..tostring(fillTypeName).."' to fillTypeCategory '"..tostring(name).."'!")
                    end
                else
                    Logging.warning("Unknown FillType '"..tostring(fillTypeName).."' in fillTypeCategory '"..tostring(name).."'!")
                end
            end
        end
    end

    for _, ftConverterKey in xmlFile:iterator(rootName .. ".fillTypeConverters.fillTypeConverter") do
        local name = xmlFile:getValue(ftConverterKey.."#name")
        local converter = self:addFillTypeConverter(name, isBaseType)
        if converter ~= nil then
            for _, converterRuleKey in xmlFile:iterator(ftConverterKey .. ".converter") do
                local from = xmlFile:getValue(converterRuleKey.."#from")
                local to = xmlFile:getValue(converterRuleKey.."#to")
                local factor = xmlFile:getValue(converterRuleKey.."#factor")

                local sourceFillType = g_fillTypeManager:getFillTypeByName(from)
                local targetFillType = g_fillTypeManager:getFillTypeByName(to)

                if sourceFillType ~= nil and targetFillType ~= nil and factor ~= nil then
                    self:addFillTypeConversion(converter, sourceFillType.index, targetFillType.index, factor)
                end
            end
        end
    end

    for _, fillTypeSoundKey in xmlFile:iterator(rootName .. ".fillTypeSounds.fillTypeSound") do
        local sample = g_soundManager:loadSampleFromXML(xmlFile, fillTypeSoundKey, "sound", baseDirectory, getRootNode(), 0, AudioGroup.VEHICLE, nil, nil)
        if sample == nil then
            continue
        end

        local entry = {
            sample = sample,
            fillTypes = {},
        }

        local fillTypes = xmlFile:getValue(fillTypeSoundKey.."#fillTypes")
        if fillTypes ~= nil then

            for _, fillTypeName in ipairs(fillTypes) do
                local fillType = self:getFillTypeIndexByName(fillTypeName)
                if fillType ~= nil then
                    table.insert(entry.fillTypes, fillType)
                    self.fillTypeToSample[fillType] = sample
                else
                    Logging.xmlWarning(xmlFile, "Unable to load fill type '%s' for fillTypeSound '%s'", fillTypeName, fillTypeSoundKey)
                end
            end
        end

        if xmlFile:getValue(fillTypeSoundKey.."#isDefault") then
            for fillType, _ in ipairs(self.fillTypes) do
                if self.fillTypeToSample[fillType] == nil then
                    self.fillTypeToSample[fillType] = sample
                end
            end
        end

        table.insert(self.fillTypeSamples, entry)
    end

    return true
end


---Adds a new fillType
-- @param table fillTypeDesc Fill type description object
-- @return boolean success
function FillTypeManager:addFillType(fillTypeDesc)
    local maxNumFillTypes = 2 ^ FillTypeManager.SEND_NUM_BITS - 1
    if #self.fillTypes >= maxNumFillTypes then
        Logging.error("FillTypeManager.addFillType too many fill types. Only %d fill types are supported", maxNumFillTypes)
        return false
    end

    fillTypeDesc.index = #self.fillTypes + 1

    self.nameToFillType[fillTypeDesc.name] = fillTypeDesc
    self.nameToIndex[fillTypeDesc.name] = fillTypeDesc.index
    self.indexToName[fillTypeDesc.index] = fillTypeDesc.name
    self.indexToTitle[fillTypeDesc.index] = fillTypeDesc.title
    self.indexToFillType[fillTypeDesc.index] = fillTypeDesc
    table.insert(self.fillTypes, fillTypeDesc)

    return true
end


---Assigns fill type array textures to given node id
-- @param integer nodeId node id
-- @param integer terrainRootNodeId terrain root node id
-- @param boolean diffuse apply diffuse map (default is true)
-- @param boolean normal apply normal map (default is true)
-- @param boolean height apply height map (default is true)
function FillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, terrainRootNodeId, diffuse, normal, height)
    local material = getMaterial(nodeId, 0)

    material = setTerrainFillPlanesToMaterial(terrainRootNodeId, material, diffuse, normal, height)

    if material ~= nil then
        setMaterial(nodeId, material, 0)
    end
end


---Assigns fill type array textures to given node id using custom texture names
-- @param integer nodeId node id
-- @param integer terrainRootNodeId terrain root node id
-- @param string diffuse diffuse map custom texture name, or ""
-- @param string normal normal map custom texture name, or ""
-- @param string height height map custom texture name, or ""
function FillTypeManager:assignCustomFillTypeTextureArraysFromTerrain(nodeId, terrainRootNodeId, diffuse, normal, height)
    local material = getMaterial(nodeId, 0)

    material = setTerrainFillPlanesToMaterialCustom(terrainRootNodeId, material, diffuse, normal, height)

    if material ~= nil then
        setMaterial(nodeId, material, 0)
    end
end


---Constructs density map height type array textures to given node id
-- @param table heightTypes table of density height map types
-- @param entityId terrainRootNodeId
-- @return boolean success
function FillTypeManager:constructTerrainFillLayers(heightTypes, terrainRootNodeId)

    clearTerrainFillLayers(terrainRootNodeId)

    local curIndex = 1
    for i=1, #heightTypes do
        local heightType = heightTypes[i]

        local fillType = self.fillTypes[heightType.fillTypeIndex]
        if fillType ~= nil then
            if fillType:addTerrainFillLayer(terrainRootNodeId, curIndex) then
                curIndex = curIndex + 1

                if heightType.visualHeightMapping ~= nil then
                    for i=1, #heightType.visualHeightMapping do
                        local mapping, nextMapping = heightType.visualHeightMapping[i], heightType.visualHeightMapping[i + 1]
                        if nextMapping ~= nil then
                            setTerrainFillVisualHeight(g_currentMission.terrainDetailHeightId, fillType.textureArrayIndex, mapping.realValue, mapping.visualValue, nextMapping.realValue, nextMapping.visualValue)
                        else
                            setTerrainFillVisualHeight(g_currentMission.terrainDetailHeightId, fillType.textureArrayIndex, mapping.realValue, mapping.visualValue, nil, nil)
                        end
                    end
                end
            end
        end
    end

    finalizeTerrainFillLayers(terrainRootNodeId)

    return true
end


---Constructs fill types texture distance array
-- @param integer terrainDetailHeightId id of terrain detail height node
-- @param integer typeFirstChannel first type channel
-- @param integer typeNumChannels num type channels
-- @param table heightTypes list of heightTypes
-- @return boolean success
function FillTypeManager:constructFillTypeDistanceTextureArray(terrainDetailHeightId, typeFirstChannel, typeNumChannels, heightTypes)
    local distanceConstr = TerrainDetailDistanceConstructor.new(typeFirstChannel, typeNumChannels)

    for i=1, #heightTypes do
        local heightType = heightTypes[i]

        local fillType = self.fillTypes[heightType.fillTypeIndex]
        if fillType ~= nil then
            fillType:addDistanceTexture(distanceConstr, i - 1)
        end
    end

    return distanceConstr:finalize(terrainDetailHeightId)
end


---Returns texture array by fill type index (returns nil if not in texture array)
-- @param integer index the fillType index
-- @return integer textureArrayIndex index in texture array
function FillTypeManager:getTextureArrayIndexByFillTypeIndex(index)
    local fillType = self.fillTypes[index]
    return fillType and fillType.textureArrayIndex
end


---Returns the prioritized effect type by given fill type index
-- @param integer index the fillType index
-- @return string class name of effect type
function FillTypeManager:getPrioritizedEffectTypeByFillTypeIndex(index)
    local fillType = self.fillTypes[index]
    return fillType and fillType.prioritizedEffectType
end


---Returns the smoke color by fill type index
-- @param integer index the fillType index
-- @param boolean fruitColor use fruit color of defined
-- @return table color smoke color
function FillTypeManager:getSmokeColorByFillTypeIndex(index, fruitColor)
    local fillType = self.fillTypes[index]
    if fillType ~= nil then
        if not fruitColor then
            return fillType.fillSmokeColor
        else
            return fillType.fruitSmokeColor or fillType.fillSmokeColor
        end
    end

    return nil
end


---Gets a fillType by index
-- @param integer index the fillType index
-- @return table fillType the fillType object
function FillTypeManager:getFillTypeByIndex(index)
    return self.fillTypes[index]
end


---Gets a fillTypeName by index
-- @param integer index the fillType index
-- @return string fillTypeName the fillType name
function FillTypeManager:getFillTypeNameByIndex(index)
    return self.indexToName[index]
end


---Gets a fillType title by index
-- @param integer index the fillType index
-- @return string fillTypeTitle the localized fillType title
function FillTypeManager:getFillTypeTitleByIndex(index)
    return self.indexToTitle[index]
end


---Gets an array of fillType names from an array of fillType indices
-- @param table indices set of fillType indices (keys are the fillType indices)
-- @return table array of fillType names
function FillTypeManager:getFillTypeNamesByIndices(indices)
    local names = {}
    for fillTypeIndex in pairs(indices) do
        table.insert(names, self.indexToName[fillTypeIndex])
    end
    return names
end



---Gets a fillType index by name
-- @param string name the fillType index name
-- @return integer fillTypeIndex the fillType index
function FillTypeManager:getFillTypeIndexByName(name)
    return self.nameToIndex[name and name:upper()]
end


---Gets a fillType by index name
-- @param string name the fillType index name
-- @return table fillType the fillType object
function FillTypeManager:getFillTypeByName(name)
    if ClassUtil.getIsValidIndexName(name) then
        return self.nameToFillType[name:upper()]
    end
    return nil
end


---Gets a list of fillTypes
-- @return table fillTypes list of fillTypes
function FillTypeManager:getFillTypes()
    return self.fillTypes
end


---Adds a new fillType category
-- @param string name fillType category index name
-- @param boolean isBaseType if true overriding existing categories is not allowed
-- @return integer fillTypeCategoryIndex
function FillTypeManager:addFillTypeCategory(name, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: '"..tostring(name).."' is not a valid name for a fillTypeCategory. Ignoring fillTypeCategory!")
        return nil
    end

    name = name:upper()

    if isBaseType and self.nameToCategoryIndex[name] ~= nil then
        printWarning("Warning: FillTypeCategory '"..tostring(name).."' already exists. Ignoring fillTypeCategory!")
        return nil
    end

    local index = self.nameToCategoryIndex[name]
    if index == nil then
        local categoryFillTypes = {}
        index = #self.categories + 1
        table.insert(self.categories, name)
        self.categoryNameToFillTypes[name] = categoryFillTypes
        self.categoryIndexToFillTypes[index] = categoryFillTypes
        self.nameToCategoryIndex[name] = index
    end

    return index
end


---Add fillType to category
-- @param integer fillTypeIndex index of fillType
-- @param integer categoryIndex index of category
-- @return table success true if added else false
function FillTypeManager:addFillTypeToCategory(fillTypeIndex, categoryIndex)
    if categoryIndex ~= nil and fillTypeIndex ~= nil then
        if self.categoryIndexToFillTypes[categoryIndex] ~= nil then
            -- category -> fillType
            self.categoryIndexToFillTypes[categoryIndex][fillTypeIndex] = true

            -- fillType -> categories
            if self.fillTypeIndexToCategories[fillTypeIndex] == nil then
                self.fillTypeIndexToCategories[fillTypeIndex] = {}
            end
            self.fillTypeIndexToCategories[fillTypeIndex][categoryIndex] = true

            return true
        end
    end
    return false
end


---Gets a list of fillTypes of the given category names
-- @param string names string of space separated fillType category names
-- @param string? warning a warning text shown if a category is not found
-- @param table? fillTypes list of fillTypes to insert results to, if omitted new table is created
-- @return table fillTypes list of fillTypes
function FillTypeManager:getFillTypesByCategoryNames(names, warning, fillTypes)
    fillTypes = fillTypes or {}

    if names ~= nil then
        return self:getFillTypesByCategoryNamesList(string.split(names, " "), warning, fillTypes)
    end

    return fillTypes
end





























































---Gets if filltype is part of a category
-- @param string fillTypeIndex fillType index
-- @param string categoryName
-- @return boolean true if fillType is part of category
function FillTypeManager:getIsFillTypeInCategory(fillTypeIndex, categoryName)
    local catgegoy = self.nameToCategoryIndex[categoryName]
    if catgegoy ~= nil and self.fillTypeIndexToCategories[fillTypeIndex] then
        return self.fillTypeIndexToCategories[fillTypeIndex][catgegoy] ~= nil
    end
    return false
end



---Gets list of fillType indices from string of space separated fill type names
-- @param string names string of space separatated fill type names
-- @param string? warning warning if fill type not found
-- @param table? fillTypes list of fillTypes to insert results to, if omitted new table is created
-- @return table fillTypes list of fillTypes
function FillTypeManager:getFillTypesByNames(names, warning, fillTypes)
    fillTypes = fillTypes or {}

    if names ~= nil then
        local fillTypeNames = string.split(names, " ")
        for _, name in pairs(fillTypeNames) do
            name = name:upper()
            local fillTypeIndex = self.nameToIndex[name]
            if fillTypeIndex ~= nil then
                if fillTypeIndex ~= FillType.UNKNOWN then
                    if not table.hasElement(fillTypes, fillTypeIndex) then
                        table.insert(fillTypes, fillTypeIndex)
                    end
                end
            else
                if warning ~= nil then
                    printWarning(string.format(warning, name))
                end
            end
        end
    end

    return fillTypes
end



---
-- @param XMLFile xmlFile
-- @param string categoryKey
-- @param string namesKey
-- @param boolean? requiresFillTypes
-- @return table fillTypes
function FillTypeManager:getFillTypesFromXML(xmlFile, categoryKey, namesKey, requiresFillTypes)
    local fillTypes = {}
    local fillTypeCategories = xmlFile:getValue(categoryKey)
    local fillTypeNames = xmlFile:getValue(namesKey)
    if fillTypeCategories ~= nil and fillTypeNames == nil then
        fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '"..xmlFile:getFilename().. "' has invalid fillTypeCategory '%s'.")
    elseif fillTypeCategories == nil and fillTypeNames ~= nil then
        fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '"..xmlFile:getFilename().. "' has invalid fillType '%s'.")
    elseif fillTypeCategories ~= nil and fillTypeNames ~= nil then
        Logging.xmlWarning(xmlFile, "fillTypeCategories and fillTypeNames are both set, only one of the two allowed")
    elseif requiresFillTypes ~= nil and requiresFillTypes then
        Logging.xmlWarning(xmlFile, "either the '%s' or '%s' attribute has to be set", categoryKey, namesKey)
    end
    return fillTypes
end
















































---Adds a new  fill type converter
-- @param string name name
-- @param boolean isBaseType if true overriding existing converters is not allowed
-- @return any index
function FillTypeManager:addFillTypeConverter(name, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: '"..tostring(name).."' is not a valid name for a fillTypeConverter. Ignoring fillTypeConverter!")
        return nil
    end

    name = name:upper()

    if isBaseType and self.nameToConverter[name] ~= nil then
        printWarning("Warning: FillTypeConverter '"..tostring(name).."' already exists. Ignoring FillTypeConverter!")
        return nil
    end

    local index = self.converterNameToIndex[name]
    if index == nil then
        local converter = {}
        table.insert(self.fillTypeConverters, converter)
        self.converterNameToIndex[name] = #self.fillTypeConverters
        self.nameToConverter[name] = converter
        index = #self.fillTypeConverters
    end

    return index
end


---Add fill type to fill type conversion
-- @param integer converter index of converter
-- @param integer sourceFillTypeIndex source fill type index
-- @param integer targetFillTypeIndex target fill type index
-- @param float conversionFactor factor of conversion
function FillTypeManager:addFillTypeConversion(converter, sourceFillTypeIndex, targetFillTypeIndex, conversionFactor)
    if converter ~= nil and self.fillTypeConverters[converter] ~= nil and sourceFillTypeIndex ~= nil and targetFillTypeIndex ~= nil then
        self.fillTypeConverters[converter][sourceFillTypeIndex] = {targetFillTypeIndex=targetFillTypeIndex, conversionFactor=conversionFactor}
    end
end


---Returns converter data by given name
-- @param string converterName name of converter
-- @return table converterData converter data
function FillTypeManager:getConverterDataByName(converterName)
    return self.nameToConverter[converterName and converterName:upper()]
end


---Returns sound sample of fill type
-- @param integer fillType fill type index
-- @return table sample sample
function FillTypeManager:getSampleByFillType(fillType)
    return self.fillTypeToSample[fillType]
end
