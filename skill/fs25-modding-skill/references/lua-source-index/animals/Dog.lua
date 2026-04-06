













---
local Dog_mt = Class(Dog, Object)







---Creating
-- @return table instance instance of object
function Dog.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or Dog_mt)

    self.dogInstance = nil
    self.animalId = nil
    self.spawner = nil
    self.xmlFilename = nil
    self.entityFollow = nil
    self.entityThrower = nil
    self.isStaying = false
    self.abandonTimer = 0.0
    self.abandonTimerDuration = 6000
    self.abandonRange = 100
    self.name = ""

    self.spawnX = 0
    self.spawnY = 0
    self.spawnZ = 0

    self.forcedClipDistance = 80

    self.activatable = DogPetActivatable.new(self)

    registerObjectClassName(self, "Dog")

    self.dirtyFlag = self:getNextDirtyFlag()
    return self
end


---
function Dog:load(spawner, xmlFilename, spawnX, spawnY, spawnZ)
    self.spawner = spawner
    self.animalId = 0
    self.spawnX = spawnX
    self.spawnY = spawnY
    self.spawnZ = spawnZ
    self.xmlFilename = xmlFilename
    self.name = g_currentMission.animalNameSystem:getRandomName()

    self.dogInstance = createAnimalCompanionManager(CompanionAnimalType.DOG, self.xmlFilename, "dog", self.spawnX, self.spawnY, self.spawnZ, g_terrainNode, self.isServer, self.isClient, 1, AudioGroup.ENVIRONMENT)
    if self.dogInstance == 0 then
        return false
    end

    setCompanionTrigger(self.dogInstance, self.animalId, "playerInteractionTriggerCallback", self)

    local groundMask = CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT
    local obstacleMask = CollisionFlag.STATIC_OBJECT +
                         CollisionFlag.DYNAMIC_OBJECT +
                         CollisionFlag.VEHICLE +
                         CollisionFlag.BUILDING
    setCompanionCollisionMask(self.dogInstance, groundMask, obstacleMask, CollisionFlag.WATER)

    g_soundManager:addIndoorStateChangedListener(self)
    setCompanionUseOutdoorAudioSetup(self.dogInstance, not g_soundManager:getIsIndoor())

    return true
end


---Delete
function Dog:delete()
    self.isDeleted = true -- mark as deleted so we can track it in Doghouse
    if self.dogInstance ~= nil then
        --#debug log("delete(self.dogInstance)")
        delete(self.dogInstance)
    end

    if self.isServer then
        g_messageCenter:unsubscribeAll(self)
    end

    unregisterObjectClassName(self)
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    g_soundManager:removeIndoorStateChangedListener(self)

    Dog:superClass().delete(self)
end


---Loading from attributes and nodes
-- @param integer xmlFile id of xml object
-- @param string key key
-- @param boolean resetVehicles reset vehicles
-- @return boolean success success
function Dog:loadFromXMLFile(xmlFile, key, resetVehicles)
    self:setName(xmlFile:getValue(key.."#name", ""))

    return true
end


---Get save attributes and nodes
-- @param table xmlFile
-- @param string key
-- @param table usedModNames
function Dog:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key.."#name", HTMLUtil.encodeToHTML(self.name))
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Dog:readStream(streamId, connection)
    if connection:getIsServer() then
        local spawner = NetworkUtil.readNodeObject(streamId)
            -- Note: the spawner can be when the doghouse not synced yet. The spawner will be set later on
        local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

        local spawnX = streamReadFloat32(streamId)
        local spawnY = streamReadFloat32(streamId)
        local spawnZ = streamReadFloat32(streamId)
        local name = streamReadString(streamId)

        local isNew = self.xmlFilename == nil
        if isNew then
            self:load(spawner, xmlFilename, spawnX, spawnY, spawnZ)
            if spawner ~= nil then
                spawner.dog = self
            end
        end

        self:setName(name)
    end
    Dog:superClass().readStream(self, streamId, connection)
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Dog:writeStream(streamId, connection)
    if not connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.spawner)
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))
        streamWriteFloat32(streamId, self.spawnX)
        streamWriteFloat32(streamId, self.spawnY)
        streamWriteFloat32(streamId, self.spawnZ)
        streamWriteString(streamId, self.name)
    end
    Dog:superClass().writeStream(self, streamId, connection)
end


---Write update network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
-- @param integer dirtyMask
function Dog:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        writeAnimalCompanionManagerToStream(self.dogInstance, streamId)
    end
end


---Read update network stream
-- @param integer streamId network stream identification
-- @param integer timestamp
-- @param table connection connection information
function Dog:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        readAnimalCompanionManagerFromStream(self.dogInstance, streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
    end
end


---Update
-- @param float dt time since last call in ms
function Dog:update(dt)
    -- companionDebugDraw(self.dogInstance, self.animalId, true, true, true)

    if self.isServer then
        if self.isStaying and self:isAbandoned(dt) then
            self:teleportToSpawn()
        end

        -- The dog is always active
        -- The only time when it could be disabled is when it is staying. But we don't care to optimize for that case
        self:raiseActive()
    end
    Dog:superClass().update(self, dt)
end


---Update network tick
-- @param float dt time since last call in ms
function Dog:updateTick(dt)
    if self.isServer and self.dogInstance ~= nil then
        if getAnimalCompanionNeedNetworkUpdate(self.dogInstance) then
            self:raiseDirtyFlags(self.dirtyFlag)
        end
    end
    Dog:superClass().updateTick(self, dt)
end


---Test scope
-- @param float x x position
-- @param float y y position
-- @param float z z position
-- @param float coeff coeff
-- @return boolean inScope in scope
function Dog:testScope(x,y,z, coeff, isGuiVisible)
    local distance, clipDistance = getCompanionClosestDistance(self.dogInstance, x, y, z)
    local clipDist = math.min(clipDistance * coeff, self.forcedClipDistance)

    return distance < clipDist
end


---Get update priority
-- @param float skipCount skip count
-- @param float x x position
-- @param float y y position
-- @param float z z position
-- @param float coeff coeff
-- @param table connection connection
-- @return float priority priority
function Dog:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
    local distance, clipDistance = getCompanionClosestDistance(self.dogInstance, x, y, z)
    if clipDistance == 0 then
        return 0
    end

    local clipDist = math.min(clipDistance * coeff, self.forcedClipDistance)
    local result = (1.0 - distance / clipDist) * 0.8 + 0.5 * skipCount * 0.2

    return result
end


---On ghost remove
function Dog:onGhostRemove()
    self:setVisibility(false)
end


---On ghost add
function Dog:onGhostAdd()
    self:setVisibility(true)
end


---Called by the environment when an hour has changed.
function Dog:hourChanged()
    if not self.isServer then
        return
    end

    if self.dogInstance ~= nil then
        setCompanionDaytime(self.dogInstance, g_currentMission.environment.dayTime)
    end
end


---
function Dog:setName(name)
    self.name = name or ""
end


---
function Dog:setVisibility(state)
    if self.dogInstance ~= nil then
        setCompanionsVisibility(self.dogInstance, state)
        setCompanionsPhysicsUpdate(self.dogInstance, state)
    end
end


---Callback when dog interaction trigger is activated
-- @param integer triggerId id of trigger
-- @param integer otherId id of actor
-- @param boolean onEnter on enter
-- @param boolean onLeave on leave
-- @param boolean onStay on stay
function Dog:playerInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if onEnter or onLeave then
        if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
            if onEnter then
                if g_currentMission.accessHandler:canFarmAccess(g_localPlayer.farmId, self, false) then
                    g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
                end
            else
                g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
            end
        end
    end
end


---Activate follow player
-- @param integer scenegraph node of the ball
function Dog:followEntity(player)
    -- Note: we also set entityFollow on the client side so that we can update the gui (it won't be 100% accurate if an other player interacts, but that should be good enough)
    self.entityFollow = player.rootNode
    self.entityThrower = nil
    if not self.isServer then
        g_client:getServerConnection():sendEvent(DogFollowEvent.new(self, player))
    else
        setCompanionBehaviorFollowEntity(self.dogInstance, self.animalId, self.entityFollow)
        self.isStaying = false
    end
end








---Activate fetch ball behavior
-- @param integer scenegraph node of the ball
function Dog:goToSpawn()
    self.entityFollow = nil
    self.entityThrower = nil

    if not self.isServer then
        g_client:getServerConnection():sendEvent(DogFollowEvent.new(self, nil))
    else
        setCompanionBehaviorGotoEntity(self.dogInstance, self.animalId, self.spawner:getSpawnNode())
    end
end


---
function Dog:onFoodBowlFilled(foodBowlNode)
    self.entityFollow = nil
    self.entityThrower = nil
    setCompanionBehaviorFeed(self.dogInstance, self.animalId, foodBowlNode)
end


---Activate fetch ball behavior
-- @param object object of type DogBall
function Dog:fetchItem(player, ball)
    if not self.isServer then
        g_client:getServerConnection():sendEvent(DogFetchItemEvent.new(self, player, ball))
    else
        local x, y, z = getWorldTranslation(ball.nodeId)
        ball.throwPos = {x, y, z}
        setCompanionBehaviorFetch(self.dogInstance, self.animalId, ball.nodeId, player.rootNode)
        self.entityThrower = player.rootNode
    end
end


---Activate dog petting response behavior
function Dog:pet()
    if not self.isServer then
        g_client:getServerConnection():sendEvent(DogPetEvent.new(self))
    else
        setCompanionBehaviorPet(self.dogInstance, self.animalId)

        local total, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "petDogCount", 1)
        if total ~= nil then
            g_achievementManager:tryUnlock("PetDog", total)
        end
    end
end


---Activate dog staying behavior (used when the currently followed player is switching vehicles or leaving the game)
function Dog:idleStay()
    -- This is only supposed to be called on the server
    self.entityFollow = nil
    self.entityThrower = nil
    setCompanionBehaviorDefault(self.dogInstance, self.animalId)
    self.isStaying = true
end


---
function Dog:idleWander()
    -- This is only supposed to be called on the server
    --setCompanionBehaviorIdleWander(self.dogInstance, self.animalId)
end


---
function Dog:isAbandoned(dt)
    local isEntityInRange = false
    for _, player in pairs(g_currentMission.players) do
        if player.isControlled then
            local entityX, entityY, entityZ = getWorldTranslation(player.rootNode)
            local distance, _ = getCompanionClosestDistance(self.dogInstance, entityX, entityY, entityZ)
            if distance < self.abandonRange then
                isEntityInRange = true
                break
            end
        end
    end

    if not isEntityInRange then
        for _, enterable in pairs(g_currentMission.vehicleSystem.enterables) do
            if enterable.spec_enterable ~= nil and enterable.spec_enterable.isControlled then
                local entityX, entityY, entityZ = getWorldTranslation(enterable.rootNode)
                local distance, _ = getCompanionClosestDistance(self.dogInstance, entityX, entityY, entityZ)
                if distance < self.abandonRange then
                    isEntityInRange = true
                    break
                end
            end
        end
    end

    if isEntityInRange then
        self.abandonTimer = self.abandonTimerDuration
    else
        self.abandonTimer = self.abandonTimer - dt
        if self.abandonTimer <= 0 then
            return true
        end
    end

    return false
end


---
function Dog:resetSteeringParms()
    -- This is only supposed to be called on the server

end


---
function Dog:teleportToSpawn()
    if self.isServer then
        setCompanionPosition(self.dogInstance, self.animalId, self.spawnX, self.spawnY, self.spawnZ)
        self:idleWander()
        self:resetSteeringParms()
        self.isStaying = false
        self.entityFollow = nil
        self.entityThrower = nil

        -- TODO sync notification
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ingameNotification_dogInDogHouse"))
    end
end


---
function Dog:playerFarmChanged(player)
    if self.isServer then
        if self.entityFollow == player.rootNode or self.entityThrower == player.rootNode then
            self:idleStay()
        end
    end
end


---Tells the dog to stay at the current place when we leave the currently followed player
function Dog:onPlayerLeave(player)
    -- return dog to it's house
    if self.isServer then
        if self.entityFollow == player.rootNode or self.entityThrower == player.rootNode then
            self:idleStay()
        end
    end
end


---
function Dog:finalizePlacement()
    self:setVisibility(true)

    if self.isServer then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
        g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, Dog.playerFarmChanged, self)
    end
end


---
function Dog:onIndoorStateChanged(isIndoor)
    setCompanionUseOutdoorAudioSetup(self.dogInstance, not g_soundManager:getIsIndoor())
end


---
function Dog.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#name", "Name of dog")
end
