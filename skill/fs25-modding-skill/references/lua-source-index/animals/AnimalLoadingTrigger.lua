










---class to handle the animal load triggers
local AnimalLoadingTrigger_mt = Class(AnimalLoadingTrigger)




---Register xml paths
function AnimalLoadingTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Trigger node of animal loading trigger")
    schema:register(XMLValueType.BOOL, basePath .. "#isDealer", "Is dealer or not", false)
    schema:register(XMLValueType.STRING, basePath .. "#animalTypes", "List of supported animal types (only for dealer)")
    schema:register(XMLValueType.STRING, basePath .. "#title", "Title to show in the UI", "ui_farm")
end


---Callback of scenegraph object
-- @param integer id nodeid that the trigger is created from
function AnimalLoadingTrigger:onCreate(id)
    local trigger = AnimalLoadingTrigger.new(g_server ~= nil, g_client ~= nil)
    if trigger ~= nil then
        if trigger:load(id) then
            g_currentMission:addNonUpdateable(trigger)
        else
            trigger:delete()
        end
    end
end


---Creates an instance of the class
-- @param boolean isServer
-- @param boolean isClient
-- @return table self instance
function AnimalLoadingTrigger.new(isServer, isClient)
    local self = Object.new(isServer, isClient, AnimalLoadingTrigger_mt)

    self.customEnvironment = g_currentMission.loadingMapModName
    self.isDealer = false
    self.triggerNode = nil
    self.title = g_i18n:getText("ui_farm")

    self.animals = nil

    self.activatable = AnimalLoadingTriggerActivatable.new(self)
    self.isPlayerInRange = false

    self.isEnabled = false

    self.loadingVehicle = nil
    self.activatedTarget = nil

    return self
end


---Loads information from a xml file
-- @param integer id nodeid that the trigger is created from
-- @param integer xmlFile id of xml file
-- @param string key xml path to load from
function AnimalLoadingTrigger:loadFromXML(xmlFile, key, components, i3dMappings)
    self.triggerNode = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
    if self.triggerNode == nil then
        Logging.xmlWarning(xmlFile, "Missing trigger node for animalLoadingTrigger!")
        return false
    end

    self.husbandry = nil
    self.isDealer = xmlFile:getValue(key .. "#isDealer", false)

    if self.isDealer then
        local animalTypesString = xmlFile:getValue(key .. "#animalTypes")
        if animalTypesString ~= nil then
            local animalTypes = animalTypesString:split(" ")
            for _, animalTypeStr in pairs(animalTypes) do
                local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(animalTypeStr)
                if animalTypeIndex ~= nil then
                    if self.animalTypes == nil then
                        self.animalTypes = {}
                    end

                    table.insert(self.animalTypes, animalTypeIndex)
                else
                    Logging.xmlWarning(xmlFile, "Invalid animal type '%s' for animalLoadingTrigger!", animalTypeStr)
                end
            end
        end
    end

    addTrigger(self.triggerNode, "triggerCallback", self)

    self.title = g_i18n:convertText(xmlFile:getValue(key .. "#title", "ui_farm"), self.customEnvironment)
    self.isEnabled = true

    return true
end


---Loads information from scenegraph node.
-- @param integer id nodeid that the trigger is created from
function AnimalLoadingTrigger:load(node, husbandry)
    self.husbandry = husbandry
    self.isDealer = Utils.getNoNil(getUserAttribute(node, "isDealer"), false)

    if self.isDealer then
        local animalTypesString = getUserAttribute(node, "animalTypes")
        if animalTypesString ~= nil then
            local animalTypes = animalTypesString:split(" ")
            for _, animalTypeStr in pairs(animalTypes) do
                local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(animalTypeStr)
                if animalTypeIndex ~= nil then
                    if self.animalTypes == nil then
                        self.animalTypes = {}
                    end

                    table.insert(self.animalTypes, animalTypeIndex)
                else
                    Logging.warning("Invalid animal type '%s' for animalLoadingTrigger '%s'!", animalTypeStr, getName(node))
                end
            end
        end
    end

    self.triggerNode = node
    addTrigger(self.triggerNode, "triggerCallback", self)

    self.title = g_i18n:getText(Utils.getNoNil(getUserAttribute(node, "title"), "ui_farm"), self.customEnvironment)
    self.isEnabled = true

    return true
end


---Deletes instance
function AnimalLoadingTrigger:delete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
        self.triggerNode = nil
    end

    self.husbandry = nil
end


---Callback when trigger changes state
-- @param integer triggerId
-- @param integer otherId
-- @param boolean onEnter
-- @param boolean onLeave
-- @param boolean onStay
function AnimalLoadingTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if self.isEnabled and (onEnter or onLeave) then
        local vehicle = g_currentMission.nodeToObject[otherId]
        if vehicle ~= nil and vehicle.getSupportsAnimalType ~= nil then
            if onEnter then
                self:setLoadingTrailer(vehicle)

                if Platform.gameplay.autoActivateTrigger and self.activatable:getIsActivatable() then
                    self.activatable:run()
                    local rootVehicle = vehicle.rootVehicle
                    if rootVehicle.brakeToStop ~= nil then
                        rootVehicle:brakeToStop()
                    end

                    return
                end
            elseif onLeave then
                if vehicle == self.loadingVehicle then
                    self:setLoadingTrailer(nil)
                end
                if vehicle == self.activatedTarget then
                    -- close dialog!
                    g_animalScreen:onVehicleLeftTrigger()
                end
            end
        elseif g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
            if onEnter then
                self.isPlayerInRange = true

                if Platform.gameplay.autoActivateTrigger and self.activatable:getIsActivatable() then
                    self.activatable:run()
                end
            else
                self.isPlayerInRange = false
            end
            self:updateActivatableObject()
        end
    end
end


---Adds or removes the trigger as an activable object to the mission
function AnimalLoadingTrigger:updateActivatableObject()
    if self.loadingVehicle ~= nil or self.isPlayerInRange then
        g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
    elseif self.loadingVehicle == nil and not self.isPlayerInRange then
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
end


---Sets the loading trailer
-- @param table loadingVehicle
function AnimalLoadingTrigger:setLoadingTrailer(loadingVehicle)
    if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
        self.loadingVehicle:setLoadingTrigger(nil)
    end

    self.loadingVehicle = loadingVehicle

    if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
        self.loadingVehicle:setLoadingTrigger(self)
    end

    self:updateActivatableObject()
end


---
function AnimalLoadingTrigger:getAnimals()
    return self.animalTypes
end


---
function AnimalLoadingTrigger:openAnimalMenu()
    if self.husbandry == nil then
        self:updateActivatableObject()
    end

    AnimalScreen.show(self.husbandry, self.loadingVehicle, self.isDealer)
    self.activatedTarget = self.loadingVehicle
end




---
local AnimalLoadingTriggerActivatable_mt = Class(AnimalLoadingTriggerActivatable)


---
function AnimalLoadingTriggerActivatable.new(animalLoadingTrigger)
    local self = setmetatable({}, AnimalLoadingTriggerActivatable_mt)

    self.owner = animalLoadingTrigger
    self.activateText = g_i18n:getText("animals_openAnimalScreen", animalLoadingTrigger.customEnvironment)

    return self
end


---
function AnimalLoadingTriggerActivatable:getIsActivatable()
    local owner = self.owner
    if not owner.isEnabled then
        return false
    end

    if g_gui.currentGui ~= nil then
        return false
    end

    if not g_currentMission:getHasPlayerPermission("tradeAnimals") then
        return false
    end

    local canAccess = owner.husbandry == nil or owner.husbandry:getOwnerFarmId() == g_currentMission:getFarmId()
    if not canAccess then
        return false
    end

    local rootAttacherVehicle = nil
    if owner.loadingVehicle ~= nil then
        rootAttacherVehicle = owner.loadingVehicle.rootVehicle
    end

    return owner.isPlayerInRange or rootAttacherVehicle == g_localPlayer:getCurrentVehicle()
end


---Called on activate object
function AnimalLoadingTriggerActivatable:run()
    if g_guidedTourManager:getIsTourRunning() then
        InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
        return
    end

    self.owner:openAnimalMenu()
end


---
function AnimalLoadingTriggerActivatable:getDistance(x, y, z)
    if self.owner.triggerNode ~= nil then
        local tx, ty, tz = getWorldTranslation(self.owner.triggerNode)
        return MathUtil.vector3Length(x-tx, y-ty, z-tz)
    end

    return math.huge
end
