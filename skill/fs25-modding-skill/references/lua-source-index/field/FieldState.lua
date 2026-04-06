









---This class wraps all Field state
local FieldState_mt = Class(FieldState)


---Create ai field definition object
-- @return table instance Instance of object
function FieldState.new(customMt)
    local self = setmetatable({}, customMt or FieldState_mt)

    self.isValid = false
    self.fruitTypeIndex = FruitType.UNKNOWN
    self.growthState = 0
    self.lastGrowthState = 0
    self.weedState = 0
    self.weedFactor = 0
    self.stoneLevel = 0
    self.groundType = FieldGroundType.NONE
    self.sprayLevel = 0
    self.sprayType = 0
    self.limeLevel = 0
    self.rollerLevel = 0
    self.plowLevel = 0
    self.stubbleShredLevel = 0
    self.waterLevel = 0

    self.farmlandId = 0
    self.ownerFarmId = AccessHandler.NOBODY

    return self
end
