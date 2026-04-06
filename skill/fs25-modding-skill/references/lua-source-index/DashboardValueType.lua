









---Animation value with one or multiple floats for AnimatedVehicle
local DashboardValueType_mt = Class(DashboardValueType)


---
function DashboardValueType.new(specName, name, customMt)
    local self = setmetatable({}, customMt or DashboardValueType_mt)

    self.specName = specName
    self.name = name
    self.fullName = specName .. "." .. name

    self.valueObject = nil

    self.loadFunction = nil
    self.stateFunction = nil

    self.valueFactor = 1
    self.valueCompare = nil
    self.idleValue = nil

    self.functions = {}

    self.value, self.min, self.max = 0, 0, 1

    return self
end


---
function DashboardValueType:setXMLKey(xmlKey)
    self.xmlKey = xmlKey
end


---
function DashboardValueType:loadFromXML(xmlFile, vehicle)
    if self.xmlKey ~= nil then
        vehicle:loadDashboardsFromXML(xmlFile, self.xmlKey, self)
    else
        local rootName = xmlFile:getRootName()
        vehicle:loadDashboardsFromXML(xmlFile, rootName .. "." .. self.specName .. ".dashboards", self)
    end
end


---
function DashboardValueType:setAdditionalFunctions(loadFunction, stateFunction)
    self.loadFunction = loadFunction
    self.stateFunction = stateFunction
end


---
function DashboardValueType:setValueFactor(valueFactor)
    self.valueFactor = valueFactor
end


---
function DashboardValueType:setValueCompare(...)
    self.valueCompare = {}

    for i = 1, select("#", ...) do
        self.valueCompare[select(i, ...)] = true
    end
end


---
function DashboardValueType:setIdleValue(idleValue)
    self.idleValue = idleValue
end


---
function DashboardValueType:setValue(object, func)
    self:setFunction("value", object, func)
end


---
function DashboardValueType:setCenter(centerFunc)
    self:setFunction("center", self.valueObject, centerFunc)
end


---
function DashboardValueType:setRange(min, max)
    self:setFunction("min", self.valueObject, min)
    self:setFunction("max", self.valueObject, max)
end


---
function DashboardValueType:setInterpolationSpeed(interpolationSpeed)
    self:setFunction("interpolationSpeed", self.valueObject, interpolationSpeed)
end


---
function DashboardValueType:getInterpolationSpeed(dashboard)
    return self:getFunctionValue("interpolationSpeed", dashboard)
end


---
function DashboardValueType:getValue(dashboard)
    local value = self:getFunctionValue("value", dashboard)

    if self.valueCompare ~= nil then
        value = self.valueCompare[value] == true
    end

    local isNumber = type(value) == "number"

    local min, max, center
    if isNumber then
        if self.valueFactor ~= nil then
            value = value * self.valueFactor
        end

        min = self:getFunctionValue("min", dashboard)
        max = self:getFunctionValue("max", dashboard)

        center = self:getFunctionValue("center", dashboard)
    end

    return value, min, max, center, isNumber
end


---
function DashboardValueType:setFunction(id, object, func)
    self.valueObject = object

    local data = {}

    data.valueObject = object
    data.valueFunction = func

    data.isValue = type(data.valueFunction) == "number" or type(data.valueFunction) == "boolean"
    data.isFunction = type(data.valueFunction) == "function"
    data.isString = type(data.valueFunction) == "string"

    if data.isString then
        data.isSubValue = type(data.valueObject[data.valueFunction]) == "number" or type(data.valueObject[data.valueFunction]) == "boolean"
        data.isSubFunction = type(data.valueObject[data.valueFunction]) == "function"
    end

    self.functions[id] = data
end


---
function DashboardValueType:getFunctionValue(id, dashboard)
    local data = self.functions[id]
    if data ~= nil then
        if data.isValue then
            return data.valueFunction
        elseif data.isFunction then
            return data.valueFunction(data.valueObject, dashboard)
        elseif data.isString then
            if data.isSubValue then
                return data.valueObject[data.valueFunction]
            elseif data.isSubFunction then
                return data.valueObject[data.valueFunction](data.valueObject, dashboard)
            end
        end
    end

    return nil
end
