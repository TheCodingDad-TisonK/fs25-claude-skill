









---A player model with sounds
local HumanModel_mt = Class(HumanModel)


---Registers xml paths within the given schema.
-- @param XMLSchema xmlSchema The schema file to use.
-- @param string modelKey The root key of the data within the XML file.
function HumanModel.registerXMLPaths(xmlSchema, baseKey)

    -- Register i3d mappings node.
    I3DUtil.registerI3dMappingXMLPaths(xmlSchema, baseKey)

    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.mesh#node", "The index of the mesh node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.skeleton#node", "The index of the skeleton root node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.animationRoot#node", "The index of the animation root node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.hips#node", "The index of the hips node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.suspension#node", "The index of the suspension node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.leftHand#node", "The index of the left hand node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.rightHand#node","The index of the right hand node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.leftFoot#node", "The index of the left foot node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.rightFoot#node","The index of the right foot node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.head#node", "The index of the head node", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, baseKey .. ".model.spine#node","The index of the spine node", nil, true)
    xmlSchema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".model.spine#offset", "The offset of the spine to the link node while loaded in a vehicle", "0 0 0")

    xmlSchema:register(XMLValueType.STRING, baseKey .. ".sounds#filename", "The path of the xml file for the sounds", nil, true)
    xmlSchema:register(XMLValueType.STRING, baseKey .. ".animation#filename", "The path of the xml file for the animation", nil, true)
end


---Creating manager
-- @return table instance instance of object
function HumanModel.new(customMt)
    local self = setmetatable({}, customMt or HumanModel_mt)

    -- Is true after this model has been deleted.
    self.isDeleted = false

    self.isLoaded = false
    self.sharedLoadRequestIds = {}

    -- The table of model part node ids keyed by filename. This is only used for async loading, and is otherwise empty.
    self.modelParts = {}

    self.rootNode = nil

    self.skeleton = nil

    self.initIKChains = true

    self.mesh = nil

    self.isParentVisible = true
    self.isBaseFullyLoaded = false
    self.isStyleFullyLoaded = false
    self.isVisible = true

    self.thirdPersonHeadNode = nil
    self.thirdPersonHipsNode = nil
    self.thirdPersonSpineNode = nil
    self.thirdPersonLeftHandNode = nil
    self.thirdPersonRightHandNode = nil
    self.thirdPersonLeftFootNode = nil
    self.thirdPersonRightFootNode = nil
    self.thirdPersonSuspensionNode = nil

    -- The nodes for any style models.
    self.faceNode = nil
    self.hairNode = nil
    self.headgearNode = nil
    self.glassesNode = nil
    self.facegearNode = nil
    self.beardNode = nil
    self.topNode = nil
    self.glovesNode = nil
    self.bottomNode = nil
    self.footwearNode = nil
    self.onepieceNode = nil

    -- The mappings of animation clip names to source clip names.
    self.animationClipMappings = {}

    self.ikChains = {}

    self.i3dFilename = nil

    -- The i3d mappings into the root node.
    self.i3dMappings = {}

    -- The components of the node.
    self.components = {}

    -- PARTICLES
    self.particleSystemsInformation = {
        systems = {
            swim = {},
            plunge = {}
        },
        swimNode = nil,
        plungeNode = nil
    }

    return self
end









































































































---Load player model, async.
-- @param string xmlFilename XML filename
-- @param boolean isRealPlayer false if player is in a vehicle
-- @param boolean isOwner true if this is a client that owns the player
-- @param boolean isAnimated true if animations should be loaded
-- @param function asyncCallbackFunction function to call after loading success of failure. Arguments: object, result true/false, arguments
-- @param table asyncCallbackObject call receiver
-- @param table asyncCallbackArguments Arguments passed to the callback
function HumanModel:load(xmlFilename, isRealPlayer, isOwner, isAnimated, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)


    self.xmlFile = XMLFile.loadIfExists("playerXML", xmlFilename, PlayerSystem.xmlSchema)
    if self.xmlFile == nil then
        asyncCallbackFunction(asyncCallbackObject, false, asyncCallbackArguments)
        return
    end

    local function onModelLoadedCallback(_, loadingState)
        if self.xmlFile ~= nil then
            self.xmlFile:delete()
            self.xmlFile = nil
        end
        self:updateVisibility()

        if asyncCallbackFunction ~= nil then
            asyncCallbackFunction(asyncCallbackObject, loadingState, asyncCallbackArguments)
        end
    end
    self:loadFromXMLFileAsync(self.xmlFile, isRealPlayer, isOwner, isAnimated, onModelLoadedCallback)
end


---Asynchronously loads the player model from the given pre-opened xml file. Does not handle file closure.
-- @param XMLFile xmlFile The XML file to load from.
-- @param boolean isRealPlayer false if player is in a vehicle
-- @param boolean isOwner true if this is a client that owns the player
-- @param boolean isAnimated true if animations should be loaded
-- @param function asyncCallbackFunction function to call after loading success or failure. Arguments: object, result true/false, arguments
-- @param table asyncCallbackObject call receiver
-- @param table asyncCallbackArguments Arguments passed to the callback
function HumanModel:loadFromXMLFileAsync(xmlFile, isRealPlayer, isOwner, isAnimated, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

    self.xmlFilename = xmlFile:getFilename()
    self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFilename)

    -- Find the filename of the player
    local i3dFilename = xmlFile:getValue("player.filename", nil)
    self.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)

    self.isRealPlayer = isRealPlayer

    self.isStyleFullyLoaded = false
    self.isBaseFullyLoaded = false
    self:updateVisibility()

    -- Load the player i3d
    self.asyncLoadCallbackFunction, self.asyncLoadCallbackObject, self.asyncLoadCallbackArguments = asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments

    local oldSharedLoadRequestId = self.sharedLoadRequestId

    for _, sharedLoadRequestId  in pairs(self.sharedLoadRequestIds) do
        g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
    end
    table.clear(self.sharedLoadRequestIds)

    self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.loadFileFinished, self, { xmlFile = xmlFile, isRealPlayer = isRealPlayer, isOwner = isOwner, isAnimated = isAnimated})

    if oldSharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(oldSharedLoadRequestId)
    end
end


---Async result of i3d loading
function HumanModel:loadFileFinished(rootNode, failedReason, arguments)

    -- If no root node exists, it means the file failed to load, so log the error and call the callback.
    if rootNode == 0 then
        Logging.error("Unable to load player model %q", self.i3dFilename)
        self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.FAILED, self.asyncLoadCallbackArguments)
        return
    end

    -- Load the player xml file.
    local xmlFile = arguments.xmlFile
    if xmlFile == nil or g_xmlManager:getFileByHandle(xmlFile:getHandle()) == nil then
        Logging.error("Unable to load player xml %q", self.xmlFilename)
        self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.FAILED, self.asyncLoadCallbackArguments)
        return
    end

    self:reset()

    -- Load the components and mappings.
    I3DUtil.loadI3DComponents(rootNode, self.components)
    I3DUtil.loadI3DMapping(xmlFile, "player", self.components, self.i3dMappings)

    self.rootNode = rootNode

    -- Load the animation clips.
    local animationFilename = xmlFile:getValue("player.animation#filename")
    if animationFilename ~= nil then
        self.animationFilename = Utils.getFilename(animationFilename, self.baseDirectory)
    else
        Logging.xmlWarning(xmlFile, "No animation filename defined at %q", "player.animation#filename")
    end

    -- Load the animation clips.
    local soundFilename = xmlFile:getValue("player.sounds#filename")
    if soundFilename ~= nil then
        self.soundFilename = Utils.getFilename(soundFilename, self.baseDirectory)
    else
        Logging.xmlWarning(xmlFile, "No sounds filename defined at %q", "player.sound#filename")
    end

    -- Load the skeleton and mesh nodes.
    self.skeleton = xmlFile:getValue("player.model.skeleton#node", nil, self.components, self.i3dMappings)
    if self.skeleton == nil then
        Logging.devError("Failed to find skeleton root node in '%s'", self.i3dFilename)
    end

    self.mesh = xmlFile:getValue("player.model.mesh#node", nil, self.components, self.i3dMappings)
    if self.mesh == nil then
        Logging.devError("Failed to find player mesh in '%s'", self.i3dFilename)
    end

    -- Load the nodes needed for linking things together.
    self.thirdPersonHipsNode        = xmlFile:getValue("player.model.hips#node", nil, self.components, self.i3dMappings)
    self.thirdPersonSpineNode       = xmlFile:getValue("player.model.spine#node", nil, self.components, self.i3dMappings)
    self.thirdPersonSpineNodeOffset = xmlFile:getValue("player.model.spine#offset", nil, true)
    self.thirdPersonSuspensionNode  = xmlFile:getValue("player.model.suspension#node", nil, self.components, self.i3dMappings)
    self.thirdPersonLeftHandNode    = xmlFile:getValue("player.model.leftHand#node", nil, self.components, self.i3dMappings)
    self.thirdPersonRightHandNode   = xmlFile:getValue("player.model.rightHand#node", nil, self.components, self.i3dMappings)
    self.thirdPersonLeftFootNode    = xmlFile:getValue("player.model.leftFoot#node", nil, self.components, self.i3dMappings)
    self.thirdPersonRightFootNode   = xmlFile:getValue("player.model.rightFoot#node", nil, self.components, self.i3dMappings)
    self.thirdPersonHeadNode        = xmlFile:getValue("player.model.head#node", nil, self.components, self.i3dMappings)

    -- Relink only after the lights and cameras are loaded: indexing changes
    if self.mesh ~= nil then
        -- link(self.rootNode, self.mesh)
        setClipDistance(self.mesh, 200)
    end

    -- IK Chains
    if self.initIKChains then
        self:loadIKChains(xmlFile, rootNode, arguments.isRealPlayer)
    end

    if arguments.isRealPlayer then

        -- Load the animation root node.
        self.animRootThirdPerson = xmlFile:getValue("player.model.animationRoot#node", nil, self.components, self.i3dMappings)
        if self.animRootThirdPerson == nil then
            Logging.devError("Failed to find animation root node in '%s'", self.i3dFilename)
            self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.INVALID_CONTENT, self.asyncLoadCallbackArguments)
            return
        end

        self.skeletonRootNode = createTransformGroup("player_skeletonRootNode")

        link(getRootNode(), self.rootNode)
        link(self.rootNode, self.skeletonRootNode)

        if self.animRootThirdPerson ~= nil then
            link(self.skeletonRootNode, self.animRootThirdPerson)
            if self.skeleton ~= nil then
                link(self.animRootThirdPerson, self.skeleton)
            end
        end

        -- Fx
        self.particleSystemsInformation.systems = {
            swim = {},
            plunge = {}
        }

        self.particleSystemsInformation.swimNode   = createTransformGroup("swimFXNode")
        self.particleSystemsInformation.plungeNode = createTransformGroup("plungeFXNode")
        link(getRootNode(), self.particleSystemsInformation.swimNode)
        link(getRootNode(), self.particleSystemsInformation.plungeNode)

        ParticleUtil.loadParticleSystem(xmlFile:getHandle(), self.particleSystemsInformation.systems.swim, "player.particleSystems.swim", self.particleSystemsInformation.swimNode, false, nil, self.baseDirectory)
        ParticleUtil.loadParticleSystem(xmlFile:getHandle(), self.particleSystemsInformation.systems.plunge, "player.particleSystems.plunge", self.particleSystemsInformation.plungeNode, false, nil, self.baseDirectory)
    else
        -- Will be re-linked in linkTo:
        if not arguments.isAnimated then
            local linkNode = createTransformGroup("characterLinkNode")
            link(self.rootNode, linkNode)
            link(linkNode, self.skeleton)

            local ox, oy, oz = 0, 0, 0
            if self.thirdPersonSpineNodeOffset ~= nil then
                ox, oy, oz = -self.thirdPersonSpineNodeOffset[1], -self.thirdPersonSpineNodeOffset[2], -self.thirdPersonSpineNodeOffset[3]
            end

            local x, y, z = localToLocal(self.thirdPersonSpineNode, self.skeleton, ox, oy, oz)
            setTranslation(linkNode, -x, -y, -z)
        else
            link(self.rootNode, self.skeleton)
        end
    end

    self.faceFocusNode = createTransformGroup("player_faceFocusNode")
    setTranslation(self.faceFocusNode, 0, 1.8, 0)
    link(self.rootNode, self.faceFocusNode)

    self.isLoaded = true
    self.isBaseFullyLoaded = true
    self:updateVisibility()

    self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, HumanModelLoadingState.OK, self.asyncLoadCallbackArguments)
end




































































































---Called from setStyleAsync and onModelPartLoaded when all model parts have been loaded.
function HumanModel:onAllModelPartsLoaded(playerStyle)

    -- The load is only successful if the model was not deleted in the meantime.
    local loadSuccess = not self.isDeleted

    -- Apply the style to the model.
    if loadSuccess then
        self:applyFromStyle(playerStyle, false)
        self.isStyleFullyLoaded = true
        self:updateVisibility()
    end

    -- Delete the model parts, since the style makes copies of anything it needs.
    for filename, node in pairs(self.modelParts) do
        if node ~= 0 then
            delete(node)
        end
        self.modelParts[filename] = nil
    end

    -- If there is a callback for the style setting, call it.
    if self.setStyleFinishCallback ~= nil then
        local callbackTarget = self.setStyleFinishCallbackTarget
        local callback = self.setStyleFinishCallback
        local callbackArguments = self.setStyleFinishCallbackArguments

        self.setStyleFinishCallbackTarget = nil
        self.setStyleFinishCallback = nil
        self.setStyleFinishCallbackArguments = nil

        callback(callbackTarget, loadSuccess and HumanModelLoadingState.OK or HumanModelLoadingState.FAILED, callbackArguments)
    end

    self:updateVisibility()
end


































































































































































































































































































































































































---Gets the visibility of the model.
-- @return boolean isVisible True if the model is visible; otherwise false.
function HumanModel:getVisibility()
    return getVisibility(self.rootNode)
end









---Sets whether or not the model should be visible.
-- @param boolean isVisible True if the model should be visible; otherwise false.
function HumanModel:setVisibility(isVisible)
    self.isVisible = isVisible
    self:updateVisibility()
end








































































---Displays the debug information.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float textSize The height of the text.
-- @return float y The y position on the screen after the entire debug info was drawn.
function HumanModel:debugDraw(x, y, textSize)

    local function drawBones(boneNode, parentX, parentY, parentZ)

--         local boneName = getName(boneNode)
--         DebugUtil.drawDebugNode(boneNode, boneName, false, nil)
        local boneX, boneY, boneZ = getWorldTranslation(boneNode)
        drawDebugLine(parentX, parentY, parentZ, 0, 0, 0, boneX, boneY, boneZ, 1, 0, 0, false)

        for i = 0, getNumOfChildren(boneNode) - 1 do
            drawBones(getChildAt(boneNode, i), boneX, boneY, boneZ)
        end
    end

    if self.skeleton ~= nil then
        local boneX, boneY, boneZ = getWorldTranslation(getChildAt(self.skeleton, 0))
        drawBones(getChildAt(self.skeleton, 0), boneX, boneY, boneZ)
    end
end
