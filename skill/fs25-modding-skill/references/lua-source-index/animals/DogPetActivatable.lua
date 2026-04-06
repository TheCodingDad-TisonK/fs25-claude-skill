








---
local DogPetActivatable_mt = Class(DogPetActivatable)


---
function DogPetActivatable.new(dog)
    local self = setmetatable({}, DogPetActivatable_mt)

    self.dog = dog

    self.activateText = g_i18n:getText("action_petAnimal")

    return self
end


---
function DogPetActivatable:getIsActivatable()
    return true
end


---
function DogPetActivatable:getDistance(posX, posY, posZ)
    local distance = self.dog:getDistanceTo(posX, posY, posZ)
    return distance
end


---
function DogPetActivatable:run()
    self.dog:pet()
end
