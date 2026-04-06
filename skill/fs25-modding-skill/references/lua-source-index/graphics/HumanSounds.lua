








---
local HumanSounds_mt = Class(HumanSounds)






























---Creating manager
-- @return table instance instance of object
function HumanSounds.new(baseDirectory, customMt)
    local self = setmetatable({}, customMt or HumanSounds_mt)

    self.isLoaded = false
    self.baseDirectory = baseDirectory
    self.raycastMask = bit32.bor(CollisionFlag.STATIC_OBJECT, CollisionFlag.WATER,CollisionFlag.TERRAIN, CollisionFlag.TERRAIN_DELTA, CollisionFlag.ROAD, CollisionFlag.BUILDING)

    return self
end
