









---
local DebugBitVectorMap_mt = Class(DebugBitVectorMap)


---
-- @param table? customMt
-- @return DebugBitVectorMap self
function DebugBitVectorMap.new(customMt)
    local self = setmetatable({}, customMt or DebugBitVectorMap_mt)

    self.radius = 15
    self.cellSize = 0.5
    self.vertexAligned = false

    self.opacity = 0.4  -- opacity if no custom opacity is defined for specfic value color
    self.valueToColor = {
        [0] = Color.PRESETS.RED:copy(),
        [1] = Color.PRESETS.GREEN:copy(),
        [2] = Color.PRESETS.BLUE:copy(),
        -- TODO: add more default, add setter
    }
    self.undefinedValueColor = Color.new(0.2, 0.2, 0.2)

    self.yOffset = 0.1
    self.solid = false
    self.pixelPaddingFactor = 0.02  -- factor applied to cellSize adding some padding to rendered pixels
    self.displayLegend = true

    return self
end





























---
function DebugBitVectorMap:draw()
    if self.aiVehicle ~= nil then
        if not self.aiVehicle.isDeleted and not self.aiVehicle.isDeleting then
            local cx, _, cz = getWorldTranslation(self.aiVehicle.rootNode)
            self:drawAroundCenter(cx, cz, DebugBitVectorMap.aiAreaCheck)
        end
    elseif self.customFunc ~= nil then
        local cx, _, cz = getWorldTranslation(g_cameraManager:getActiveCamera())
        self:drawAroundCenter(cx, cz, self.customFunc)
    end
end


---
-- @param table vehicle
-- @return DebugBitVectorMap self
function DebugBitVectorMap:createWithAIVehicle(vehicle)
    self.aiVehicle = vehicle

    return self
end


---
-- @param function customFunc
-- @return DebugBitVectorMap self
function DebugBitVectorMap:createWithCustomFunc(customFunc)
    self.customFunc = customFunc

    return self
end


---
-- @param function drawInfoFunc
-- @return DebugBitVectorMap self
function DebugBitVectorMap:setAdditionalDrawInfoFunc(drawInfoFunc)
    self.drawInfoFunc = drawInfoFunc

    return self
end


































































---
function DebugBitVectorMap:aiAreaCheck(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return AIVehicleUtil.getAIAreaOfVehicle(self.aiVehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end
