



























---Loads overlay data from XML or a profile into a table to turn it into an overlay.
-- @param table self
-- @param table overlay Table containing all necessary information to create and draw an element
-- @param string overlayName Defines the type of the overlay (e.g. "image", "icon", ...)
-- @param table imageSize Size of the source image we create the overlay from
-- @param table? profile Profile containing all relevant parameters to load the overlay. While this is optional, we need one of profile or XML file and key to load an overlay
-- @param integer? xmlFile XML file handle for the file containing all relevant parameters to load the overlay
-- @param string? key XML node path to the uv parameters
-- @return table overlay The created overlay
function GuiOverlay.loadOverlay(self, overlay, overlayName, imageSize, profile, xmlFile, key)
    if overlay.uvs == nil then
        overlay.uvs = Overlay.DEFAULT_UVS
    end

    if overlay.color == nil then
        overlay.color = {1, 1, 1, 1}
    end

    if xmlFile ~= nil then
        GuiOverlay.loadXMLFilenames(xmlFile, key, overlay, overlayName)
        GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
        GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)

        overlay.sdfWidth = getXMLInt(xmlFile, key .. "#" .. overlayName .. "SdfWidth") or overlay.sdfWidth
    elseif profile ~= nil then
        GuiOverlay.loadProfileFilenames(profile, overlay, overlayName)
        GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
        GuiOverlay.loadProfileColors(profile, overlay, overlayName)

        overlay.sdfWidth = profile:getNumber(overlayName .. "SdfWidth", overlay.sdfWidth)
    end

    if overlay.filename == nil then
        return nil
    end

    if overlay.previewFilename == nil then
        overlay.previewFilename = "dataS/menu/black.png"
    end

    return overlay
end


---Load overlay UV data from XML.
-- @param integer xmlFile XML file handle
-- @param string key XML node path to the uv parameters
-- @param table overlay Overlay table, see loadOverlay()
-- @param string overlayName Defines the type of the overlay (e.g. "image", "icon", ...)
-- @param table imageSize Size of the source image we create the overlay from
function GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local uvsStateName = overlayName .. stateName .. "UVs"
        local uvs = getXMLString(xmlFile, key .. "#" .. uvsStateName)
        local sliceIdStateName = overlayName .. stateName .. "SliceId"
        local sliceId = getXMLString(xmlFile, key .. "#" .. sliceIdStateName)

        if sliceId ~= nil and sliceId ~= "noSlice" then
            local slice = g_overlayManager:getSliceInfoById(sliceId)

            if slice ~= nil then
                overlay["uvs" .. stateName] = table.clone(slice.uvs)
                overlay["filename" .. stateName] = slice.filename
                overlay["sliceId" .. stateName] = sliceId

                local rotation = getXMLInt(xmlFile, key .. "#" .. overlayName .. stateName .. "UVRotation")
                if rotation ~= nil then
                    GuiUtils.rotateUVs(overlay["uvs" .. stateName], rotation)
                end

                local invertX = getXMLBool(xmlFile, key .. "#" .. overlayName .. stateName .. "InvertX")
                if invertX then
                    GuiUtils.invertUVs(overlay["uvs" .. stateName], true)
                end
            end
        elseif uvs ~= nil then
            overlay["uvs" .. stateName] = GuiUtils.getUVs(uvs, imageSize, overlay["uvs" .. stateName], getXMLInt(xmlFile, key .. "#" .. overlayName .. stateName .. "UVRotation"))
        end
    end
end


---Load overlay UV data from a profile.
-- @param table profile Profile containing all relevant uv parameters
-- @param table overlay Overlay table, see loadOverlay()
-- @param string overlayName Defines the type of the overlay (e.g. "image", "icon", ...)
-- @param table imageSize Size of the source image we create the overlay from
function GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local uvsStateName = overlayName .. stateName .. "UVs"
        local uvs = profile:getValue(uvsStateName)
        local sliceIdStateName = overlayName .. stateName .. "SliceId"
        local sliceId = profile:getValue(sliceIdStateName)

        if sliceId ~= nil and sliceId ~= "noSlice" then
            local slice = g_overlayManager:getSliceInfoById(sliceId)

            if slice ~= nil then
                overlay["uvs" .. stateName] = table.clone(slice.uvs)
                overlay["filename" .. stateName] = slice.filename
                overlay["sliceId" .. stateName] = sliceId

                local rotation = profile:getNumber(overlayName .. stateName .. "UVRotation")
                if rotation ~= nil then
                    GuiUtils.rotateUVs(overlay["uvs" .. stateName], rotation)
                end

                if profile:getBool(overlayName .. stateName .. "InvertX") == true then
                    GuiUtils.invertUVs(overlay["uvs" .. stateName], true)
                end
                if profile:getBool(overlayName .. stateName .. "InvertY") == true then
                    GuiUtils.invertUVs(overlay["uvs" .. stateName], false)
                end
            end
        elseif uvs ~= nil then
            overlay["uvs" .. stateName] = GuiUtils.getUVs(uvs, imageSize, overlay["uvs" .. stateName], profile:getNumber(overlayName .. "UVRotation"))

            if profile.filename == g_baseUIFilename then
                Logging.warning("Profile %s does not use new slice format", profile.name)
            end
        end
    end
end


---Load overlay color data from XML.
-- @param integer xmlFile XML file handle
-- @param string key XML node path to the color parameters
-- @param table overlay Overlay table, see loadOverlay()
-- @param string overlayName Defines the type of the overlay (e.g. "image", "icon", ...)
function GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local colorStateName = overlayName .. stateName .. "Color"
        local color = GuiUtils.getColorGradientArray(getXMLString(xmlFile, key .. "#" .. colorStateName))
        if color ~= nil then
            overlay["color" .. stateName] = color
        end
    end

    local rotation = getXMLFloat(xmlFile, key .. "#" .. overlayName .. "Rotation")
    if rotation ~= nil then
        overlay.rotation = math.rad(rotation)
    end

    local isWebOverlay = getXMLBool(xmlFile, key .. "#" .. overlayName .. "IsWebOverlay")
    if isWebOverlay ~= nil then
        overlay.isWebOverlay = isWebOverlay
    end
end


---Load overlay color data from a profile.
-- @param table profile Profile containing all relevant color parameters
-- @param table overlay Overlay table, see loadOverlay()
-- @param string overlayName Defines the type of the overlay (e.g. "image", "icon", ...)
function GuiOverlay.loadProfileColors(profile, overlay, overlayName)
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local colorStateName = overlayName .. stateName .. "Color"
        local color = GuiUtils.getColorGradientArray(profile:getValue(colorStateName))
        if color ~= nil then
            overlay["color" .. stateName] = color
        end
    end

    local rotation = profile:getNumber(overlayName .. "Rotation")
    if rotation ~= nil then
        overlay.rotation = math.rad(rotation)
    end

    local isWebOverlay = profile:getBool(overlayName .. "IsWebOverlay")
    if isWebOverlay ~= nil then
        overlay.isWebOverlay = isWebOverlay
    end
end


---Load overlay mask data from XML.
-- @param integer xmlFile XML file handle
-- @param string key XML node path to the filename parameters
-- @param table overlay Overlay table, see loadOverlay()
-- @param string overlayName Defines the type of the overlay (e.g. "image", "icon", ...)
function GuiOverlay.loadXMLFilenames(xmlFile, key, overlay, overlayName)
    local overlayFilename = overlayName .. "Filename"
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = getXMLString(xmlFile, key .. "#" .. overlayFilename .. stateName)
        if filename ~= nil then
            overlay["filename" .. stateName] = GuiOverlay.resolveFilename(filename)
        end
    end

    local previewFilename = overlayName .. "PreviewFilename"
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = getXMLString(xmlFile, key .. "#" .. previewFilename .. stateName)
        if filename ~= nil then
            overlay["previewFilename" .. stateName] = GuiOverlay.resolveFilename(filename)
        end
    end

    local maskFilename = overlayName .. "MaskFilename"
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = getXMLString(xmlFile, key .. "#" .. maskFilename .. stateName)
        if filename ~= nil then
            overlay["maskFilename" .. stateName] = GuiOverlay.resolveFilename(filename)
        end
    end
end


---Load overlay mask data from a profile.
-- @param table profile Profile containing all relevant filename parameters
-- @param table overlay Overlay table, see loadOverlay()
-- @param string overlayName Defines the type of the overlay (e.g. "image", "icon", ...)
function GuiOverlay.loadProfileFilenames(profile, overlay, overlayName)
    local overlayFilename = overlayName .. "Filename"
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = profile:getValue(overlayFilename .. stateName)
        if filename ~= nil then
            overlay["filename" .. stateName] = GuiOverlay.resolveFilename(filename)
        end
    end

    local previewFilename = overlayName .. "PreviewFilename"
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = profile:getValue(previewFilename .. stateName)
        if filename ~= nil then
            overlay["previewFilename" .. stateName] = GuiOverlay.resolveFilename(filename)
        end
    end

    local maskFilename = overlayName .. "MaskFilename"
    for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local filename = profile:getValue(maskFilename .. stateName)
        if filename ~= nil then
            overlay["maskFilename" .. stateName] = GuiOverlay.resolveFilename(filename)
        end
    end
end


---Resolves filenames that contain global string references or language suffixes
-- @param string filename String containing the filename to be resolved
-- @return string filename String containing the filename after resolving any global references
function GuiOverlay.resolveFilename(filename)
    if filename == "g_baseUIFilename" then
        filename = g_baseUIFilename
    elseif filename == "g_baseHUDFilename" then
        filename = g_baseHUDFilename
    elseif filename == "g_iconsUIFilename" then
        filename = g_iconsUIFilename
    end

    if filename ~= nil then
        filename =  string.gsub(filename, "$l10nSuffix", g_languageSuffix)
    end

    return filename
end


---(Re-)Create an overlay.
-- @param table overlay Overlay table, see loadOverlay()
-- @param string? filename [optional] Path to image file (can also be a URL for web images), if nil overlay.filename will be used
-- @return table overlay Table with added image data
function GuiOverlay.createOverlay(overlay, filename)
    if overlay.overlay ~= nil and (overlay.filename == filename or filename == nil) then
        return overlay -- already created / loaded
    end

    -- delete previously created overlay, if necessary
    GuiOverlay.deleteOverlay(overlay)

    if filename ~= nil then
        overlay.filename = filename
    end

    if overlay.filename ~= nil then
        local imageOverlay
        if overlay.isWebOverlay == nil or not overlay.isWebOverlay or (overlay.isWebOverlay and not overlay.filename:startsWith("http")) then
            imageOverlay = createImageOverlay(overlay.filename, overlay.sliceId)
        else
            imageOverlay = createWebImageOverlay(overlay.filename, overlay.previewFilename)
        end

        if imageOverlay ~= 0 then
            overlay.overlay = imageOverlay

            GuiOverlay.createStateOverlays(overlay)

            if overlay.sdfWidth ~= nil then
                setOverlaySignedDistanceFieldWidth(imageOverlay, overlay.sdfWidth)
            end
        end
    end

    overlay.rotation = overlay.rotation or 0
    overlay.alpha = overlay.alpha or 1

    return overlay
end


---Creates overlays and maskOverlays for all different states (check GuiOverlay.OVERLAY_STATE_SUFFIXES for state values), if the overlay has a filename for that state
-- @param table overlay Overlay table, see loadOverlay()
function GuiOverlay.createStateOverlays(overlay)
    for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        local imageOverlay, overlayMask
        if state ~= GuiOverlay.STATE_NORMAL then
            if overlay["filename" .. stateName] ~= nil then
                if overlay.isWebOverlay and overlay.filename:startsWith("http") and overlay["previewFilename" .. stateName]~= nil then
                    imageOverlay = createWebImageOverlay(overlay["filename" .. stateName], overlay["previewFilename" .. stateName])
                else
                    imageOverlay = createImageOverlay(overlay["filename" .. stateName])
                end
            end

            if imageOverlay ~= 0 then
                overlay["overlay" .. stateName] = imageOverlay
            end
        end

        if overlay["maskFilename" .. stateName] ~= nil then
            overlayMask = createOverlayTextureFromFile(overlay["maskFilename" .. stateName])
        end

        if overlayMask ~= nil and overlayMask ~= 0 then
            overlay["overlayMask" .. stateName] = overlayMask
        end
    end
end


---Copy an overlay. The actual overlays are not copied, instead a new one is created with the same parameters
-- @param table overlay Overlay table, see loadOverlay()
-- @param table overlaySrc Source overlay table, contains the parameters used to create the copy
-- @param string? overrideFilename [optional] Used instead of overlaySrc.filename if not nil
-- @return table overlay the new overlay, created with the parameters of the source
function GuiOverlay.copyOverlay(overlay, overlaySrc, overrideFilename)
    overlay.alpha = overlaySrc.alpha
    overlay.isWebOverlay = overlaySrc.isWebOverlay
    overlay.sdfWidth = overlaySrc.sdfWidth

    for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        overlay["filename" .. stateName] = overlaySrc["filename" .. stateName]
        overlay["maskFilename" .. stateName] = overlaySrc["maskFilename" .. stateName]
        overlay["previewFilename" .. stateName] = overlaySrc["previewFilename" .. stateName]
        overlay["rotation" .. stateName] = overlaySrc["rotation" .. stateName]
        overlay["uvs" .. stateName] = overlaySrc["uvs" .. stateName] and table.clone(overlaySrc["uvs" .. stateName])
        overlay["color" .. stateName] = overlaySrc["color" .. stateName] and table.copyIndex(overlaySrc["color" .. stateName])
    end

    overlay.sliceId = overlaySrc.sliceId
    overlay.filename = overrideFilename or overlay.filename

    return GuiOverlay.createOverlay(overlay)
end


---Delete an overlay. Primarily releases the associated image file handle.
-- @param table overlay Overlay table, see loadOverlay()
function GuiOverlay.deleteOverlay(overlay)
    if overlay ~= nil then
        for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
            if overlay["overlay" .. stateName] ~= nil then
                delete(overlay["overlay" .. stateName])
                overlay["overlay" .. stateName] = nil
            end

            if overlay["overlayMask" .. stateName] ~= nil then
                delete(overlay["overlayMask" .. stateName])
                overlay["overlayMask" .. stateName] = nil
            end
        end
    end
end


---Get an overlay's color for a given overlay state.
-- @param table overlay Overlay table, see loadOverlay()
-- @param integer state GuiOverlay.STATE_[...] constant value
-- @return Color as {red, green, blue, alpha} with all values in the range of [0, 1]
function GuiOverlay.getOverlayColor(overlay, state)
    local color = overlay.color

    if state == GuiOverlay.STATE_DISABLED then
        color = overlay.colorDisabled
    elseif state == GuiOverlay.STATE_FOCUSED then
        color = overlay.colorFocused
    elseif state == GuiOverlay.STATE_SELECTED then
        color = overlay.colorSelected
    elseif state == GuiOverlay.STATE_HIGHLIGHTED then
        color = overlay.colorHighlighted
    elseif state == GuiOverlay.STATE_PRESSED then
        color = overlay.colorPressed
        if color == nil then
            color = overlay.colorFocused
        end
    end

    if color == nil then
        color = overlay.color
    end

    return color
end


---Get an overlay's UV coordinates for a given overlay state.
-- @param Overlay overlay Overlay table
-- @param integer state GuiOverlay.STATE_[...] constant value
-- @return table UV coordinates as {u1, v1, u2, v2, u3, v3, u4x, v4} with all values in the range of [0, 1]
function GuiOverlay.getOverlayUVs(overlay, state)
    local uvs = overlay.uvs

    if state == GuiOverlay.STATE_DISABLED then
        uvs = overlay.uvsDisabled
    elseif state == GuiOverlay.STATE_PRESSED then
        uvs = overlay.uvsPressed
    elseif state == GuiOverlay.STATE_FOCUSED then
        uvs = overlay.uvsFocused
    elseif state == GuiOverlay.STATE_SELECTED then
        uvs = overlay.uvsSelected
    elseif state == GuiOverlay.STATE_HIGHLIGHTED then
        uvs = overlay.uvsHighlighted
    end

    if uvs == nil then
        uvs = overlay.uvs
    end

    return uvs
end


---Get the overlay for a given overlay state.
-- @param table overlay Overlay table, see loadOverlay()
-- @param integer currentState GuiOverlay.[...] constant value
-- @return table overlay for the current state
function GuiOverlay.getOverlay(overlay, currentState)
    local currentOverlay = overlay.overlay

    for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        if currentState == state then
            currentOverlay = overlay["overlay" .. stateName]

            if state == GuiOverlay.STATE_PRESSED and currentOverlay == nil then
                currentOverlay = overlay["overlay" .. GuiOverlay.OVERLAY_STATE_SUFFIXES[GuiOverlay.STATE_FOCUSED]]
            end

            break
        end
    end

    if currentOverlay == nil then
        currentOverlay = overlay.overlay
    end

    return currentOverlay
end


---Get the overlay for a given overlay state.
-- @param table overlay Overlay table, see loadOverlay()
-- @param integer currentState GuiOverlay.STATE_[...] constant value
-- @return table overlay for the current state
function GuiOverlay.getMaskOverlay(overlay, currentState)
    local currentOverlay

    for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
        if currentState == state then
            currentOverlay = overlay["overlayMask" .. stateName]

            if state == GuiOverlay.STATE_PRESSED and currentOverlay == nil then
                currentOverlay = overlay["overlayMask" .. GuiOverlay.OVERLAY_STATE_SUFFIXES[GuiOverlay.STATE_FOCUSED]]
            end

            break
        end
    end

    if currentOverlay == nil then
        currentOverlay = overlay.overlayMask
    end

    return currentOverlay
end


---Renders an overlay with the given parameters.
-- @param table overlay Overlay table, see loadOverlay()
-- @param float posX Screen x position
-- @param float posY Screen y position
-- @param float sizeX Screen x size
-- @param float sizeY Screen y size
-- @param integer state GuiOverlay.STATE_[...] constant for the required display state
-- @param float? clipX1 [optional] Minimal screen x value, anything smaller than this value will not be displayed
-- @param float? clipY1 [optional] Minimal screen y value, anything smaller than this value will not be displayed
-- @param float? clipX2 [optional] Maximal screen x value, anything higher than this value will not be displayed
-- @param float? clipY2 [optional] Maximal screen y value, anything higher than this value will not be displayed
-- @param float? maskPosX [optional] Position offset if X position of the overlay mask is different than the overlays
-- @param float? maskPosY [optional] Position offset if Y position of the overlay mask is different than the overlays
-- @param float? maskSizeX [optional] Used if the height of the overlay mask is different than the overlays size
-- @param float? maskSizeY [optional] Used if the width of the overlay mask is different than the overlays size
function GuiOverlay.renderOverlay(overlay, posX, posY, sizeX, sizeY, state, clipX1, clipY1, clipX2, clipY2, maskPosX, maskPosY, maskSizeX, maskSizeY)
    local currentOverlay = GuiOverlay.getOverlay(overlay, state)

    if currentOverlay ~= nil then
        local colors = GuiOverlay.getOverlayColor(overlay, state)

        -- if there is any alpha, draw.
        if colors[4] ~= 0 or (colors[8] ~= nil and (colors[8] ~= 0 or colors[12] ~= 0 or colors[16] ~= 0)) then
            if not overlay.hasCustomRotation then
                local pivotX, pivotY = sizeX / 2, sizeY / 2
                if overlay.customPivot ~= nil then
                    pivotX, pivotY = overlay.customPivot[1], overlay.customPivot[2]
                end

                setOverlayRotation(currentOverlay, overlay.rotation, pivotX, pivotY)
            end

            local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(GuiOverlay.getOverlayUVs(overlay, state))

            -- Needs clipping
            local oldX1, oldY1, oldX2, oldY2 = posX, posY, sizeX + posX, sizeY + posY
            local oldSizeX, oldSizeY = sizeX, sizeY

            if clipX1 ~= nil then
                local posX2 = posX + sizeX
                local posY2 = posY + sizeY

                posX = math.max(posX, clipX1)
                posY = math.max(posY, clipY1)

                sizeX = math.max(math.min(posX2, clipX2) - posX, 0)
                sizeY = math.max(math.min(posY2, clipY2) - posY, 0)

                if sizeX == 0 or sizeY == 0 then
                    return
                end

                local ou1, ov1, ou2, ov2, ou3, ov3, ou4, ov4 = u1, v1, u2, v2, u3, v3, u4, v4

                local p1 = (posX - oldX1) / (oldX2 - oldX1) -- start x
                local p2 = (posY - oldY1) / (oldY2 - oldY1) -- start y
                local p3 = ((posX + sizeX) - oldX1) / (oldX2 - oldX1) -- end x
                local p4 = ((posY + sizeY) - oldY1) / (oldY2 - oldY1) -- end y

                -- start x, start y
                u1 = (ou3-ou1)*p1 + ou1
                v1 = (ov2-ov1)*p2 + ov1

                -- start x, end y
                u2 = (ou3-ou1)*p1 + ou1
                v2 = (ov4-ov3)*p4 + ov3

                -- end x, start y
                u3 = (ou3-ou1)*p3 + ou1
                v3 = (ov2-ov1)*p2 + ov1

                -- end x, end y
                u4 = (ou4-ou2)*p3 + ou2
                v4 = (ov4-ov3)*p4 + ov3
            end

            setOverlayUVs(currentOverlay, u1, v1, u2, v2, u3, v3, u4, v4)

            local mask = GuiOverlay.getMaskOverlay(overlay, state)
            if mask ~= nil then
                maskPosX = maskPosX ~= nil and oldX1 + maskPosX or oldX1
                maskPosY = maskPosY ~= nil and oldY1 + maskPosY or oldY1
                maskSizeX = maskPosX ~= nil and maskSizeX or oldSizeX
                maskSizeY = maskPosY ~= nil and maskSizeY or oldSizeY

                set2DMaskFromTexture(mask, true, maskPosX, maskPosY, maskSizeX, maskSizeY)
            end

            if colors[5] ~= nil then
                setOverlayCornerColor(currentOverlay, 0, colors[1], colors[2], colors[3], colors[4] * overlay.alpha)
                setOverlayCornerColor(currentOverlay, 1, colors[5], colors[6], colors[7], colors[8] * overlay.alpha)
                setOverlayCornerColor(currentOverlay, 2, colors[9], colors[10], colors[11], colors[12] * overlay.alpha)
                setOverlayCornerColor(currentOverlay, 3, colors[13], colors[14], colors[15], colors[16] * overlay.alpha)
            else
                local r,g,b,a = unpack(colors)
                setOverlayColor(currentOverlay, r, g, b, a * overlay.alpha)
            end

            renderOverlay(currentOverlay, posX, posY, sizeX, sizeY)

            if mask ~= nil then
                set2DMaskFromTexture(0, true, 0, 0, 0, 0)
            end
        end
    end
end


---
-- @param table overlay Overlay table, see loadOverlay()
-- @param table source Overlay table with color parameters to be copied
function GuiOverlay.copyColors(overlay, source)
    overlay.color = source.color
    overlay.colorDisabled = source.colorDisabled
    overlay.colorFocused = source.colorFocused
    overlay.colorSelected = source.colorSelected
    overlay.colorHighlighted = source.colorHighlighted
    overlay.colorPressed = source.colorPressed
end


---Set this overlay's rotation.
-- @param table overlay Overlay table, see loadOverlay()
-- @param float rotation Rotation in radians
-- @param float centerX Rotation pivot X position offset from overlay position in screen space
-- @param float centerY Rotation pivot Y position offset from overlay position in screen space
function GuiOverlay.setRotation(overlay, rotation, centerX, centerY)
    if overlay.overlay ~= nil then
        setOverlayRotation(overlay.overlay, rotation, centerX, centerY)
        overlay.hasCustomRotation = true
    end
end


---Set this overlay's color.
-- @param table overlay Overlay table, see loadOverlay()
-- @param float r red component of the color
-- @param float g green component of the color
-- @param float b blue component of the color
-- @param float a alpha component of the color
function GuiOverlay.setColor(overlay, r, g, b, a)
    overlay.color = {r, g, b, a}
end


---Set this overlay's selected color.
-- @param table overlay Overlay table, see loadOverlay()
-- @param float r red component of the color
-- @param float g green component of the color
-- @param float b blue component of the color
-- @param float a alpha component of the color
function GuiOverlay.setSelectedColor(overlay, r, g, b, a)
    overlay.colorSelected = {r, g, b, a}
end
