














---Renders a scene to an overlay
local RenderElement_mt = Class(RenderElement, GuiElement)




---
-- @param table target
-- @param table? custom_mt
-- @return RenderElement self
function RenderElement.new(target, custom_mt)
    local self = GuiElement.new(target, custom_mt or RenderElement_mt)

    self.cameraPath = nil
    self.overlay = nil

    -- overlay attributes
    self.useAlpha = true
    self.shapesMask = 255 -- show all objects with bits 1-8 enabled
    self.lightMask = 67108864 -- per default only render lights with bit 26 enabled
    self.renderShadows = false
    self.bloomQuality = 0
    self.enableDof = false
    self.ssaoQuality = 0
    self.asyncShaderCompilation = false  -- flag to toggle async shader compilation for drawn overlay, if true overlay might not show anything after the first updateRenderOverlay() calls(s)

    self.isRenderDirty = false

    return self
end


---
function RenderElement:delete()
    self:destroyScene()

    RenderElement:superClass().delete(self)
end


---
-- @param entityId xmlFile
-- @param string key
function RenderElement:loadFromXML(xmlFile, key)
    RenderElement:superClass().loadFromXML(self, xmlFile, key)

    self.filename = getXMLString(xmlFile, key .. "#filename") or self.filename
    self.cameraPath = getXMLString(xmlFile, key .. "#cameraNode") or self.cameraPath
    self.superSamplingFactor = getXMLInt(xmlFile, key .. "#superSamplingFactor") or self.superSamplingFactor
    self.shapesMask = getXMLInt(xmlFile, key .. "#shapesMask") or self.shapesMask
    self.lightMask = getXMLInt(xmlFile, key .. "#lightMask") or self.lightMask
    self.renderShadows = Utils.getNoNil(getXMLBool(xmlFile, key .. "#renderShadows"), self.renderShadows)
    self.bloomQuality = getXMLInt(xmlFile, key .. "#bloomQuality") or self.bloomQuality
    self.enableDof = Utils.getNoNil(getXMLBool(xmlFile, key .. "#enableDof"), self.enableDof)
    self.ssaoQuality = getXMLInt(xmlFile, key .. "#ssaoQuality") or self.ssaoQuality
    self.asyncShaderCompilation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#asyncShaderCompilation"), self.asyncShaderCompilation)

    self:addCallback(xmlFile, key.."#onRenderLoad", "onRenderLoadCallback")
end


---
-- @param table profile
-- @param boolean applyProfile
function RenderElement:loadProfile(profile, applyProfile)
    RenderElement:superClass().loadProfile(self, profile, applyProfile)

    self.filename = profile:getValue("filename")
    self.cameraPath = profile:getValue("cameraNode")
    self.superSamplingFactor = profile:getNumber("superSamplingFactor")

    if applyProfile then
        self:setScene(self.filename)
    end
end


---
-- @param table src
function RenderElement:copyAttributes(src)
    RenderElement:superClass().copyAttributes(self, src)

    self.filename = src.filename
    self.cameraPath = src.cameraPath
    self.superSamplingFactor = src.superSamplingFactor

    self.onRenderLoadCallback = src.onRenderLoadCallback
end


---Create the scene and the overlay. Call destroyScene to clean up resources.
function RenderElement:createScene()
    self:setScene(self.filename)
end


---Destroy the scene and the overlay, cleaning up resources.
function RenderElement:destroyScene()
    if self.loadingRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.loadingRequestId)
        self.loadingRequestId = nil
    end

    if self.overlay ~= nil then
        delete(self.overlay)
        self.overlay = nil
    end

    if self.scene then
        delete(self.scene)
        self.scene = nil
    end
end


---Set and start async loading for provided scene
-- @param string i3dFilename path to scene i3d file
function RenderElement:setScene(i3dFilename)
    if self.scene ~= nil then
        delete(self.scene)
        self.scene = nil
    end

    if self.loadingRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.loadingRequestId)
        self.loadingRequestId = nil
    end

    self.isLoading = true
    self.filename = i3dFilename

    self.loadingRequestId = g_i3DManager:loadSharedI3DFileAsync(i3dFilename, false, false, RenderElement.onSceneLoaded, self, nil)
end


---
-- @param entityId node
-- @param integer failedReason
-- @param table? args
function RenderElement:onSceneLoaded(node, failedReason, args)
    self.isLoading = false

    if failedReason == LoadI3DFailedReason.FILE_NOT_FOUND or failedReason == LoadI3DFailedReason.UNKNOWN then
        Logging.error("Failed to load RenderElement scene from '%s'", self.filename)
    end

    if failedReason == LoadI3DFailedReason.NONE then
        self.scene = node
        link(getRootNode(), node)

        -- The overlay is bound to the scene, so we need to recreate the overlay
        self:createOverlay()

    elseif node ~= 0 then
        delete(node)
    end
end


---
function RenderElement:createOverlay()
    if self.overlay ~= nil then
        delete(self.overlay)
        self.overlay = nil
    end

    -- Use downsampling to imitate anti-aliasing, as the postFx for it is not available
    -- on render overlays
    local resolutionX = math.ceil(g_screenWidth * self.absSize[1]) * self.superSamplingFactor
    local resolutionY = math.ceil(g_screenHeight * self.absSize[2]) * self.superSamplingFactor

    local aspectRatio = resolutionX / resolutionY

    local camera = I3DUtil.indexToObject(self.scene, self.cameraPath)
    if camera == nil then
        Logging.error("Could not find camera node '%s' in render overlay scene '%s'", self.cameraPath, self.filename)
        return
    end

    local overlay = createRenderOverlay(self.scene, camera, aspectRatio, resolutionX, resolutionY, self.useAlpha, self.shapesMask, self.lightMask, self.renderShadows, self.bloomQuality, self.enableDof, self.ssaoQuality, self.asyncShaderCompilation)

    if overlay == 0 then
        Logging.error("Could not create render overlay for scene '%s'", self.filename)
--#debug         log(" Used args: ", camera, aspectRatio, resolutionX, resolutionY, self.useAlpha, self.shapesMask, self.lightMask, self.renderShadows, self.bloomQuality, self.enableDof, self.ssaoQuality, self.asyncShaderCompilation)
--#debug         printCallstack()
        return
    end

    self.overlay = overlay

    self.isRenderDirty = true
    self:raiseCallback("onRenderLoadCallback", self.scene, self.overlay)
end


---Redraws the scene to the overlay if set dirty
-- @param float dt
function RenderElement:update(dt)
    RenderElement:superClass().update(self, dt)

    if self.isRenderDirty and self.overlay ~= nil then
        updateRenderOverlay(self.overlay)
        self.isRenderDirty = false
    end
end


---Draws overlay with current content, to redraw/render the scene to the overlay it needs to be set dirty via setRenderDirty()
-- @param float? clipX1 [0..1]
-- @param float? clipY1 [0..1]
-- @param float? clipX2 [0..1]
-- @param float? clipY2 [0..1]
function RenderElement:draw(clipX1, clipY1, clipX2, clipY2)
    if not self.isLoading and self.overlay ~= nil then

        local posX, posY, sizeX, sizeY = self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]
        local u1, v1, u2, v2, u3, v3, u4, v4 = 0, 0, 0, 1, 1, 0, 1, 1

        -- Needs clipping
        if clipX1 ~= nil then
            local oldX1, oldY1, oldX2, oldY2 = posX, posY, sizeX + posX, sizeY + posY

            local posX2 = posX + sizeX
            local posY2 = posY + sizeY

            posX = math.max(posX, clipX1)
            posY = math.max(posY, clipY1)

            sizeX = math.max(math.min(posX2, clipX2) - posX, 0)
            sizeY = math.max(math.min(posY2, clipY2) - posY, 0)

            local p1 = (posX - oldX1) / (oldX2 - oldX1) -- start x
            local p2 = (posY - oldY1) / (oldY2 - oldY1) -- start y
            local p3 = ((posX + sizeX) - oldX1) / (oldX2 - oldX1) -- end x
            local p4 = ((posY + sizeY) - oldY1) / (oldY2 - oldY1) -- end y

            -- start x, start y
            u1 = p1
            v1 = p2

            -- start x, end y
            u2 = p1
            v2 = p4

            -- end x, start y
            u3 = p3
            v3 = p2

            -- end x, end y
            u4 = p3
            v4 = p4
        end

        if u1 ~= u3 and v1 ~= v2 then
            setOverlayUVs(self.overlay, u1, v1, u2, v2, u3, v3, u4, v4)
            renderOverlay(self.overlay, posX, posY, sizeX, sizeY)
        end
    end

    RenderElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end


---A render element can't get UI focus
-- @return boolean canReceiveFocus
function RenderElement:canReceiveFocus()
    return false
end


---
-- @return entityId scene
function RenderElement:getSceneRoot()
    return self.scene
end


---Set overlay dirty causing it to be updated / redrawn from current scene in the update loop
function RenderElement:setRenderDirty()
    self.isRenderDirty = true
end
