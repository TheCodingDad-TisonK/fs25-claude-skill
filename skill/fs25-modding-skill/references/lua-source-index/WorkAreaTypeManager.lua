











---This class handles all workArea types
local WorkAreaTypeManager_mt = Class(WorkAreaTypeManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function WorkAreaTypeManager.new(customMt)
    local self = AbstractManager.new(customMt or WorkAreaTypeManager_mt)

    return self
end


---Initialize data structures
function WorkAreaTypeManager:initDataStructures()
    self.workAreaTypes = {}
    self.workAreaTypeNameToInt = {}
    self.workAreaTypeNameToDesc = {}
    WorkAreaType = self.workAreaTypeNameToInt
end


---
function WorkAreaTypeManager:addWorkAreaType(name, attractWildlife, isAIArea, isSteeringAssistArea)
    if name == nil then
        Logging.error("WorkArea name missing!")
        return
    end
    if self.workAreaTypeNameToInt[name] ~= nil then
        Logging.error("WorkArea name '%s' is already in use!", name)
        return
    end

    name = name:upper()

    local entry = {}
    entry.name = name
    entry.index = #self.workAreaTypes + 1
    entry.attractWildlife = Utils.getNoNil(attractWildlife, false)
    entry.isAIArea = Utils.getNoNil(isAIArea, false)
    entry.isSteeringAssistArea = Utils.getNoNil(isSteeringAssistArea, false)

    self.workAreaTypeNameToInt[name] = entry.index
    self.workAreaTypeNameToDesc[name] = entry
    table.insert(self.workAreaTypes, entry)

    print("  Register workAreaType '" .. name .. "'")
end


---
function WorkAreaTypeManager:getWorkAreaTypeNameByIndex(index)
    local workAreaType = self.workAreaTypes[index]
    if workAreaType then
        return workAreaType.name
    end

    return nil
end


---
function WorkAreaTypeManager:getWorkAreaTypeIndexByName(name)
    if name ~= nil then
        return self.workAreaTypeNameToInt[name:upper()]
    end
    return nil
end


---
function WorkAreaTypeManager:getConfigurationDescByName(name)
    if name ~= nil then
        return self.workAreaTypeNameToDesc[name:upper()]
    end
    return nil
end


---
function WorkAreaTypeManager:getWorkAreaTypeByIndex(index)
    return self.workAreaTypes[index]
end


---
function WorkAreaTypeManager:getWorkAreaTypeIsAIArea(index)
    if self.workAreaTypes[index] ~= nil then
        return self.workAreaTypes[index].isAIArea
    end

    return false
end


---
function WorkAreaTypeManager:getWorkAreaTypeIsSteeringAssistArea(index)
    if self.workAreaTypes[index] ~= nil then
        return self.workAreaTypes[index].isSteeringAssistArea
    end

    return false
end
