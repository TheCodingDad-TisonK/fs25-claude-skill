









---Handles updating a human's graphical data (players, NPCs, etc.), like styles and physical position on the map.
local HumanGraphicsComponent_mt = Class(HumanGraphicsComponent)





---Creates a new instance of the player's graphics component.
-- @return HumanGraphicsComponent instance The created instance.
function HumanGraphicsComponent.new()

    -- Create the instance.
    local self = setmetatable({}, HumanGraphicsComponent_mt)

    -- The data used for foliage bending.
    self.foliageBendingId = nil
    self.foliageBendingNode = nil

    -- The node used to display the player model.
    self.graphicsRootNode = nil
    self.isGraphicsRootNodeVisible = true

    -- The node used to position the camera when talking to NPCs.
    self.rightShoulderCameraNode = nil

    self.style = PlayerStyle.new()
    self.baseStyle = PlayerStyle.new()

    -- The player's model, starting off empty.
    self.model = HumanModel.new()
    self.model:loadEmpty()

    self.nameTagOffsetY = 1.9

    self.facialAnimation = nil
    self.facialAnimationEnabled = false
    self.facialAnimationMinimumDistance = FacialAnimation.MINIMUM_VISIBLE_CAMERA_DISTANCE
    self.facialAnimationMaximumDistance = FacialAnimation.MAXIMUM_VISIBLE_CAMERA_DISTANCE

    self.postAnimationCallbackHandle = nil

    self.sounds = HumanSounds.new()
    self.soundsEnabled = true

    local animation = ConditionalAnimation.new()

    local parameters = {}
    parameters.absSpeed = animation:registerParameter("absSpeed", ConditionalAnimation.TYPE.FLOAT)
    parameters.relativeVelocityX = animation:registerParameter("relativeVelocityX", ConditionalAnimation.TYPE.FLOAT)
    parameters.relativeVelocityY = animation:registerParameter("relativeVelocityY", ConditionalAnimation.TYPE.FLOAT)
    parameters.relativeVelocityZ = animation:registerParameter("relativeVelocityZ", ConditionalAnimation.TYPE.FLOAT)
    parameters.rotationVelocity = animation:registerParameter("rotationVelocity", ConditionalAnimation.TYPE.FLOAT)
    parameters.movementDirX = animation:registerParameter("movementDirX", ConditionalAnimation.TYPE.FLOAT)
    parameters.movementDirZ = animation:registerParameter("movementDirZ", ConditionalAnimation.TYPE.FLOAT)
    parameters.distanceToGround = animation:registerParameter("distanceToGround", ConditionalAnimation.TYPE.FLOAT)
    parameters.isCloseToGround = animation:registerParameter("isCloseToGround", ConditionalAnimation.TYPE.BOOL)
    parameters.isIdling = animation:registerParameter("isIdling", ConditionalAnimation.TYPE.BOOL)
    parameters.isWalking = animation:registerParameter("isWalking", ConditionalAnimation.TYPE.BOOL)
    parameters.isRunning = animation:registerParameter("isRunning", ConditionalAnimation.TYPE.BOOL)
    parameters.isCrouching = animation:registerParameter("isCrouching", ConditionalAnimation.TYPE.BOOL)
    parameters.isGrounded = animation:registerParameter("isGrounded", ConditionalAnimation.TYPE.BOOL)
    parameters.isInWater = animation:registerParameter("isInWater", ConditionalAnimation.TYPE.BOOL)
    parameters.isSwimming = animation:registerParameter("isSwimming", ConditionalAnimation.TYPE.BOOL)
    parameters.isStrafeWalkMode = animation:registerParameter("isStrafeWalkMode", ConditionalAnimation.TYPE.BOOL)
    parameters.isFirstPerson = animation:registerParameter("isFirstPerson", ConditionalAnimation.TYPE.BOOL)
    parameters.isCutting = animation:registerParameter("isCutting", ConditionalAnimation.TYPE.BOOL)
    parameters.isVerticalCut = animation:registerParameter("isVerticalCut", ConditionalAnimation.TYPE.BOOL)
    parameters.isHoldingChainsaw = animation:registerParameter("isHoldingChainsaw", ConditionalAnimation.TYPE.BOOL)
    parameters.isNPC = animation:registerParameter("isNPC", ConditionalAnimation.TYPE.BOOL)

    animation:setSpecialParameterIds(parameters.absSpeed, parameters.rotationVelocity)

    self.animation = animation
    self.animationParameters = parameters

    self.defaultState = HumanGraphicsComponentState.new()
    self:defaultAllParameters()

    -- Return the created instance.
    return self
end


---Called when the player loads into the map for the first time. Creates the required nodes in the scene.
function HumanGraphicsComponent:initialize()

    -- Create the graphical node that shows where the player is.
    self.graphicsRootNode = createTransformGroup("player_graphicsRootNode")
    link(getRootNode(), self.graphicsRootNode)

    -- Create the shoulder camera node.
    self.rightShoulderCameraNode = createTransformGroup("player_rightShoulderCameraNode")
    link(self.graphicsRootNode, self.rightShoulderCameraNode)
    setTranslation(self.rightShoulderCameraNode, -0.35, 1.675, -0.35)

    -- Create the node used to bend foliage.
    self.foliageBendingNode = createTransformGroup("player_foliageBendingNode")
    link(self.graphicsRootNode, self.foliageBendingNode)
end


---Handles showing the graphical representation of the player in the world.
function HumanGraphicsComponent:show()
    self:setModelVisibility(true)
end


---Handles hiding the graphical representation of the player from the world.
function HumanGraphicsComponent:hide()
    self:setModelVisibility(false)
end


---Cleans up the graphical data when the player is deleted.
function HumanGraphicsComponent:delete()
    if self:getHasFacialAnimation() then
        self.facialAnimation:delete()
    end

    -- Delete the graphical data.
    self.sounds:delete()
    self.animation:delete()
    self.model:delete()

    -- Delete the graphical node.
    if self.graphicsRootNode ~= 0 and self.graphicsRootNode ~= nil then
        delete(self.graphicsRootNode)
        self.graphicsRootNode = nil
    end

    -- Delete the foliage bending data.
    local mission = g_currentMission
    if mission ~= nil and self.foliageBendingId ~= nil then
        mission.foliageBendingSystem:destroyObject(self.foliageBendingId)
        self.foliageBendingId = nil
    end
end






---Sets the player model to the given model.
-- @param HumanModel model The player model to use.
function HumanGraphicsComponent:setModel(model)

    -- Ensure the model has a root node.
    if model.rootNode == nil then
        printCallstack()
        Logging.error("New model is missing root node and cannot be used!")
        return
    end

    -- Delete the model and animation.
    if self.model ~= nil and self.model ~= model then
        self.model:delete()
    end

    -- Set the model to the given one and link it to the graphics node.
    self.model = model
    link(self.graphicsRootNode, model.rootNode)

    self:loadAnimation()
    self:loadSounds()

    -- Update the visibility.
    self:setModelVisibility(true)
end































































































































---Sets the visibility of the model to the given value.
-- @param boolean visibility The new visibility of the model.
function HumanGraphicsComponent:setModelVisibility(visibility, overrideFoliageBending)
    self.model:setVisibility(visibility)

    self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)

    local useFoliageBending = Utils.getNoNil(overrideFoliageBending, visibility)

    local mission = g_currentMission
    if useFoliageBending then
        -- If foilage bending can be set up, do so.
        if self.foliageBendingNode ~= nil and self.foliageBendingId == nil and mission ~= nil and mission.foliageBendingSystem then
            self.foliageBendingId = mission.foliageBendingSystem:createRectangle(-0.5, 0.5, -0.5, 0.5, 0.4, self.foliageBendingNode)
        end
    else
        if self.foliageBendingId ~= nil then
            mission.foliageBendingSystem:destroyObject(self.foliageBendingId)
            self.foliageBendingId = nil
        end
    end
end











































---Sets a custom work style preset.
-- @param string presetName The name of the preset to use.
function HumanGraphicsComponent:applyCustomWorkStyle(presetName, isOwner)

    -- Get the work style preset from its name.
    local preset
    if not string.isNilOrWhitespace(presetName) then
        preset = self.style:getPresetByName(presetName)
    end

    -- If the preset was found, apply it.
    if preset ~= nil then
        local tempStyle = PlayerStyle.new()
        tempStyle:copyConfigurationFrom(self.baseStyle)
        preset:applyToStyle(tempStyle)
        self:setStyleAsync(tempStyle, nil, nil, nil, true, nil, isOwner)
    -- Otherwise; fall back to the base style.
    else
        self:setStyleAsync(self.baseStyle, nil, nil, nil, false, nil, isOwner)
    end
end


---Returns the player's current style.
-- @param boolean? currentStyle If this is true, the player's current style is returned; otherwise it may fall back onto the base style if no style exists.
-- @return PlayerStyle style The player's current style.
function HumanGraphicsComponent:getStyle(currentStyle)
    if currentStyle then
        return self.style
    end

    return self.baseStyle or self.style
end













---Sets the style asynchronously, possibly loading a new model or using the network.
-- Callback is not guaranteed to run after player changes in MP game.
-- @param PlayerStyle style The style to use.
-- @param function? callback The callback function, not guaranteed to run in multiplayer.
-- @param table? callbackObject The optional target object for the callback function.
-- @param table? callbackArgs The optional arguments for the callback function.
-- @param boolean? isTempStyle Is true if this style is just temporary, e.g. a preview in the wardrobe; otherwise false.
-- @param XMLFile? xmlFile The pre-loaded xml file.
-- @param boolean? isOwner True if this graphics component is for the main player; otherwise false.
function HumanGraphicsComponent:setStyleAsync(style, callback, callbackObject, callbackArgs, isTempStyle, xmlFile, isOwner)

    local function onFinishedFacialAnimationCallback(target, success, args)
        if not success and self.facialAnimation ~= nil then
            self.facialAnimation:delete()
            self.facialAnimation = nil
        end

        local graphicsLoadingState = args.loadingState
        if graphicsLoadingState == HumanModelLoadingState.OK then
            if self.graphicsRootNode ~= nil then
                self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)
            end
        end

        if callback ~= nil then
            callback(callbackObject, graphicsLoadingState, args.loadedNewPlayerModel, callbackArgs)
        end
    end

    -- The callback used when the style is fully loaded.
    local function onStyleLoadedCallback(target, loadingState, args)

        args.loadingState = loadingState
        local isLoadingFacialAnimations = false
        if self:getIsFacialAnimationEnabled() then
            isLoadingFacialAnimations = self.facialAnimation:loadFromStyleAsync(style, self.model, onFinishedFacialAnimationCallback, target, args)
        end

        if not isLoadingFacialAnimations then
            if self.facialAnimation ~= nil then
                self.facialAnimation:delete()
                self.facialAnimation = nil
            end
            onFinishedFacialAnimationCallback(target, true, args)
        end
    end

    if self.graphicsRootNode ~= nil then
        self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)
    end

    -- If the style uses the currently used model, just set the style directly.
    if self.model.xmlFilename == style.xmlFilename then

        -- Set the style of the model.
        self:setStyle(style, isTempStyle)
        self.model:loadFromStyleAsync(self.style, onStyleLoadedCallback, nil, { loadedNewPlayerModel = false })
    else
        self:setStyle(style, isTempStyle)

        -- The callback for when the player's model is loaded.
        local function onModelLoadedCallback(_, loadingState, _)

            -- If the model could not be loaded, do nothing.
            if loadingState ~= HumanModelLoadingState.OK then
                Logging.warning("Player model could not be loaded from " .. style.xmlFilename)
                return
            end

            -- Set the model and the style of the player.
            self:setModel(self.model)
            self.model:loadFromStyleAsync(self.style, onStyleLoadedCallback, nil, { loadedNewPlayerModel = true })
        end

        -- Load the player's model.
        if xmlFile == nil then
            self.model:load(style.xmlFilename, true, isOwner, true, onModelLoadedCallback)
        else
            self.model:loadFromXMLFileAsync(xmlFile, true, isOwner, true, onModelLoadedCallback)
        end
    end
end



















---Updates the graphics every frame.
-- @param float dt Delta time in ms.
function HumanGraphicsComponent:update(dt)
--#profile     RemoteProfiler.zoneBeginN("HumanGraphicsComponent-updateAnimation")
    self.animation:update(dt)
--#profile     RemoteProfiler.zoneEnd()
--#profile     RemoteProfiler.zoneBeginN("HumanGraphicsComponent-updateSounds")
    self.sounds:update(dt)
--#profile     RemoteProfiler.zoneEnd()

    if self:getHasFacialAnimation() then
--#profile     RemoteProfiler.zoneBeginN("HumanGraphicsComponent-updateFacialAnim")
        self.facialAnimation:update(dt)
        self:updateFacialAnimationEmotions()
--#profile     RemoteProfiler.zoneEnd()
    end
end




















































---Displays the debug information.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float textSize The height of the text.
-- @param boolean? debugDrawModel If this is true or nil, the model and skeleton will be drawn.
-- @return float y The y position on the screen after the entire debug info was drawn.
function HumanGraphicsComponent:debugDraw(x, y, textSize, debugDrawModel)

    -- Draw the model.
    if (debugDrawModel or debugDrawModel == nil) and self.model ~= nil then
        self.model:debugDraw(x, y, textSize)
    end

    -- Draw the graphical root node.
    DebugUtil.drawDebugNode(self.graphicsRootNode, "Graphics", false, 0)
    DebugUtil.drawDebugNode(self.rightShoulderCameraNode, "ShoulderCam", false, 0)

    -- Render the header.
    y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "HumanGraphicsComponent", nil, true)

    local directionX, directionY, directionZ = localDirectionToWorld(self.graphicsRootNode, 0, 0, 1)
    local _, yaw = MathUtil.directionToPitchYaw(directionX, directionY, directionZ)

    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Rotation: %.4f", yaw), nil, true)

    y = self.style:debugDraw(x, y, textSize)

    -- Return the final y value.
    return y
end


---Draws debug information for this component's animations.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float textSize The height of the text.
function HumanGraphicsComponent:debugDrawAnimator(x, y, textSize)
    self.animation:debugDraw(x, y, textSize)
end
