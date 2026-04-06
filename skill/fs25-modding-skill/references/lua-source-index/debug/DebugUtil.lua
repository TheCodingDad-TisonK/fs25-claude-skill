
























---Draws a debug node and optional a text at world position of given node
-- @param integer id node id
-- @param string text text
function DebugUtil.drawDebugNode(node, text, alignToGround, offsetY)
    offsetY = offsetY or 0
    local x, y, z = getWorldTranslation(node)
    local upX, upY, upZ    = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugUtil.drawDebugGizmoAtWorldPos(x,y + offsetY,z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround)
end








---
function DebugUtil.drawDebugGizmoAtWorldPos(x,y,z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround, color)
    local sideX, sideY, sideZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)

    if alignToGround then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x,0,z)+0.1
    end

    drawDebugLine(x,y,z,1,0,0, x+sideX*0.3,y+sideY*0.3,z+sideZ*0.3, 1,0,0)
    drawDebugLine(x,y,z,0,1,0, x+upX*0.3,  y+upY*0.3,  z+upZ*0.3,   0,1,0)
    drawDebugLine(x,y,z,0,0,1, x+dirX*0.3, y+dirY*0.3, z+dirZ*0.3,  0,0,1)

    if text ~= nil then
        Utils.renderTextAtWorldPosition(x,y,z, tostring(text), getCorrectTextSize(0.012), 0, color)
    end
end


---
function DebugUtil.drawDebugArea(start, width, height, r,g,b, alignToGround, drawNodes, drawCircle, offsetY)
    offsetY = offsetY or 0
    local x,y,z = getWorldTranslation(start)
    local x1,y1,z1 = getWorldTranslation(width)
    local x2,y2,z2 = getWorldTranslation(height)

    y = y + offsetY
    y1 = y1 + offsetY
    y2 = y2 + offsetY

    DebugUtil.drawDebugAreaRectangle(x,y,z, x1,y1,z1, x2,y2,z2, alignToGround, r,g,b)  -- TODO offset above ground

    if drawNodes == nil or drawNodes then
        DebugGizmo.renderAtNodeWithOffset(start,  0, offsetY, 0, getName(start),  false, 1, alignToGround)
        DebugGizmo.renderAtNodeWithOffset(width,  0, offsetY, 0, getName(width),  false, 1, alignToGround)
        DebugGizmo.renderAtNodeWithOffset(height, 0, offsetY, 0, getName(height), false, 1, alignToGround)
    end

    local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(start, width, height, 0.5)

    lsy = lsy + offsetY
    ley = ley + offsetY

    if alignToGround then
        lsy = getTerrainHeightAtWorldPos(g_terrainNode, lsx,0,lsz)+0.1
        ley = getTerrainHeightAtWorldPos(g_terrainNode, lex,0,lez)+0.1
    end

    if drawCircle == nil or drawCircle then
        drawDebugLine(lsx, lsy, lsz, 1,1,1, lex, ley, lez, 1,1,1)
        DebugUtil.drawDebugCircle((lsx+lex)*0.5, (lsy+ley)*0.5, (lsz+lez)*0.5, radius, 20, nil)
    end
end


---
function DebugUtil.drawDebugLine(x1, y1, z1, x2, y2, z2, r, g, b, radius, alignToGround)
    y1 = y1 or 0
    y2 = y2 or 0
    if alignToGround then
        y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1,0,z1)+0.1
        y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2,0,z2)+0.1
    end

    r = r or 1
    g = g or 1
    b = b or 1
    drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b)

    if radius ~= nil then
        DebugUtil.drawDebugCircle(x1, y1, z1, radius, 20, nil)
        DebugUtil.drawDebugCircle(x2, y2, z2, radius, 20, nil)
    end

    -- TODO: add dedicated class/functions for tipany
end


---
function DebugUtil.drawDebugAreaRectangle(x,y,z, x1,y1,z1, x2,y2,z2, alignToGround, r,g,b)
    if alignToGround then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x,0,z)+0.1
        y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1,0,z1)+0.1
        y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2,0,z2)+0.1
    end

    drawDebugLine(x,y,z, r,g,b, x1, y1, z1, r,g,b)
    drawDebugLine(x,y,z, r,g,b, x2, y2, z2, r,g,b)

    local dirX1, dirY1, dirZ1 = x1-x, y1-y, z1-z
    local dirX2, dirY2, dirZ2 = x2-x, y2-y, z2-z

    drawDebugLine(x2,y2,z2, r,g,b, x2+dirX1, y2+dirY1, z2+dirZ1, r,g,b)
    drawDebugLine(x1,y1,z1, r,g,b, x1+dirX2, y1+dirY2, z1+dirZ2, r,g,b)
end

















---
function DebugUtil.drawDebugAreaRectangleFilled(x,y,z, x1,y1,z1, x2,y2,z2, alignToGround, r,g,b,a)
    local x3, y3, z3 = x1, (y1+y2)/2, z2

    if alignToGround then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x,0,z)+0.1
        y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1,0,z1)+0.1
        y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2,0,z2)+0.1
        y3 = getTerrainHeightAtWorldPos(g_terrainNode, x3,0,z3)+0.1
    end

    drawDebugTriangle(x,y,z, x2,y2,z2, x1,y1,z1, r,g,b,a, false)
    drawDebugTriangle(x1,y1,z1, x2,y2,z2, x3,y3,z3, r,g,b,a, false)
end


---
function DebugUtil.drawDebugRectangle(node, minX, maxX, minZ, maxZ, yOffset, r, g, b, a, filled)
    local leftFrontX, leftFrontY, leftFrontZ = localToWorld(node, minX, yOffset, maxZ)
    local rightFrontX, rightFrontY, rightFrontZ = localToWorld(node, maxX, yOffset, maxZ)

    local leftBackX, leftBackY, leftBackZ = localToWorld(node, minX, yOffset, minZ)
    local rightBackX, rightBackY, rightBackZ = localToWorld(node, maxX, yOffset, minZ)

    drawDebugLine(leftFrontX, leftFrontY, leftFrontZ, r,g,b, rightFrontX, rightFrontY, rightFrontZ, r,g,b)
    drawDebugLine(rightFrontX, rightFrontY, rightFrontZ, r,g,b, rightBackX, rightBackY, rightBackZ, r,g,b)
    drawDebugLine(rightBackX, rightBackY, rightBackZ, r,g,b, leftBackX, leftBackY, leftBackZ, r,g,b)
    drawDebugLine(leftBackX, leftBackY, leftBackZ, r,g,b, leftFrontX, leftFrontY, leftFrontZ, r,g,b)

    if filled then
        drawDebugTriangle(leftFrontX, leftFrontY, leftFrontZ, rightFrontX, rightFrontY, rightFrontZ, rightBackX, rightBackY, rightBackZ, r,g,b,a, true)
        drawDebugTriangle(rightBackX, rightBackY, rightBackZ, leftBackX, leftBackY, leftBackZ, leftFrontX, leftFrontY, leftFrontZ, r,g,b,a, true)
    end
end









































































---Draw debug circle
-- @param float x world x position
-- @param float y world y position
-- @param float z world z position
-- @param float radius radius
-- @param integer steps steps
-- @param table? color color [r, g, b, a]
function DebugUtil.drawDebugCircle(x,y,z, radius, steps, color, alignToTerrain, filled, solid)
    local r, g, b = 1, 0, 0
    if color ~= nil then
        r, g, b = color[1], color[2], color[3]
    end
    local terrainNode = g_terrainNode

    for i=1,steps do
        local a1 = ((i-1)/steps)*2*math.pi
        local a2 = ((i)/steps)*2*math.pi

        local c = math.cos(a1) * radius
        local s = math.sin(a1) * radius
        local x1, y1, z1 = x+c, y, z+s

        c = math.cos(a2) * radius
        s = math.sin(a2) * radius
        local x2, y2, z2 = x+c, y, z+s

        if alignToTerrain then
            y = getTerrainHeightAtWorldPos(terrainNode, x, y, z) + 0.25
            y1 = getTerrainHeightAtWorldPos(terrainNode, x1, y, z1)  + 0.25
            y2 = getTerrainHeightAtWorldPos(terrainNode, x2, y, z2) + 0.25
        end

        drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, solid)

        if filled then
            drawDebugTriangle(x, y, z, x2, y2, z2, x1, y1, z1, r, g, b, 0.3, solid)
        end
    end
end


---Draw debug circle at node position
-- @param integer node node
-- @param float radius radius
-- @param integer steps steps
-- @param table? color color [r, g, b, a]
-- @param boolean? vertical circle is drawed vertically
-- @param table? offset offset from node to center [x, y, z]
function DebugUtil.drawDebugCircleAtNode(node, radius, steps, color, vertical, offset)
    local ox, oy, oz = 0, 0, 0
    if offset ~= nil then
        ox, oy, oz = offset[1], offset[2], offset[3]
    end

    for i=1,steps do
        local a1 = ((i-1)/steps)*2*math.pi
        local a2 = ((i)/steps)*2*math.pi

        local c = math.cos(a1) * radius
        local s = math.sin(a1) * radius
        local x1, y1, z1
        if vertical then
            x1, y1, z1 = localToWorld(node, ox + 0, oy + c, oz + s)
        else
            x1, y1, z1 = localToWorld(node, ox + c, oy + 0, oz + s)
        end

        c = math.cos(a2) * radius
        s = math.sin(a2) * radius
        local x2, y2, z2
        if vertical then
            x2, y2, z2 = localToWorld(node, ox + 0, oy + c, oz + s)
        else
            x2, y2, z2 = localToWorld(node, ox + c, oy + 0, oz + s)
        end

        if color == nil then
            drawDebugLine(x1,y1,z1, 1,0,0, x2,y2,z2, 1,0,0)
        else
            drawDebugLine(x1,y1,z1, color[1],color[2],color[3], x2,y2,z2, color[1],color[2],color[3])
        end
    end
end


---Draw debug cube at world position
-- @param float x world x center position
-- @param float y world y center position
-- @param float z world z center position
-- @param float dirX x direction
-- @param float dirY y direction
-- @param float dirZ z direction
-- @param float upX x up of vector
-- @param float upY y up of vector
-- @param float upZ z up of vector
-- @param float sizeX x size
-- @param float sizeY y size
-- @param float sizeZ z size
-- @param float r red value
-- @param float g green value
-- @param float b blue value
function DebugUtil.drawDebugCubeAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, sizeX, sizeY, sizeZ, r, g, b)
    local temp = createTransformGroup("temp_drawDebugCubeAtWorldPos")
    link(getRootNode(), temp)
    setTranslation(temp, x, y, z)
    setDirection(temp, dirX, dirY, dirZ, upX, upY, upZ)
    DebugUtil.drawDebugCube(temp, sizeX, sizeY, sizeZ, r, g, b)
    delete(temp)
end


---
function DebugUtil.drawOverlapBox(x, y, z, rotX, rotY, rotZ, extendX, extendY, extendZ, r, g, b)
    local temp = createTransformGroup("temp_drawDebugCubeAtWorldPos")
    link(getRootNode(), temp)
    setTranslation(temp, x, y, z)
    setRotation(temp, rotX, rotY, rotZ)
    DebugUtil.drawDebugCube(temp, extendX*2, extendY*2, extendZ*2, r, g, b)
    delete(temp)
end


---Draw debug cube at given node
-- @param integer id node id
-- @param float sizeX x size
-- @param float sizeY y size
-- @param float sizeZ z size
-- @param float r red value
-- @param float g green value
-- @param float b blue value
function DebugUtil.drawDebugCube(node, sizeX, sizeY, sizeZ, r, g, b, offsetX, offsetY, offsetZ)
    sizeX, sizeY, sizeZ = sizeX * 0.5, sizeY * 0.5, sizeZ * 0.5
    r = r or 1
    g = g or 1
    b = b or 1

    local x, y, z = localToWorld(node, offsetX or 0, offsetY or 0, offsetZ or 0)
    local up1X, up1Y, up1Z = localDirectionToWorld(node, 1, 0, 0)
    local upX, upY, upZ    = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)

    up1X, up1Y, up1Z = up1X*sizeX, up1Y*sizeX, up1Z*sizeX
    upX, upY, upZ    = upX*sizeY, upY*sizeY, upZ*sizeY
    dirX, dirY, dirZ = dirX*sizeZ, dirY*sizeZ, dirZ*sizeZ

    drawDebugLine(x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b, x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b)
    drawDebugLine(x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b, x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b)
    drawDebugLine(x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b, x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b)
    drawDebugLine(x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b, x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b)

    drawDebugLine(x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b, x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b)
    drawDebugLine(x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b, x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b)
    drawDebugLine(x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b, x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b)
    drawDebugLine(x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b, x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b)

    drawDebugLine(x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b, x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b)
    drawDebugLine(x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b, x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b)
    drawDebugLine(x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b, x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b)
    drawDebugLine(x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b, x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b)
end


---Draw debug cube
-- @param float x world x center position
-- @param float y world y center position
-- @param float z world z center position
-- @param float width
-- @param float red
-- @param float green
-- @param float blue
function DebugUtil.drawSimpleDebugCube(x, y, z, width, r, g, b)
    local halfWidth = width * 0.5

    drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y - halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x - halfWidth, y + halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x - halfWidth, y - halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y - halfWidth, z + halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y - halfWidth, z + halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y + halfWidth, z - halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y + halfWidth, z - halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
    drawDebugPoint(x, y, z, r, g, b, 1)
end



---Draw debug reference axis fom Node
-- @param entityId to draw a reference axis from
function DebugUtil.drawDebugReferenceAxisFromNode(node)
    if node ~= nil then
        local x, y, z = getWorldTranslation(node)
        local yx, yy, yz = localDirectionToWorld(node, 0,1,0) -- up
        local zx, zy, zz = localDirectionToWorld(node, 0,0,1) -- direction

        DebugUtil.drawDebugReferenceAxis(x, y, z, yx, yy, yz, zx, zy, zz )
    end
end


---Draw debug reference axis
-- @param float x world x center position
-- @param float y world y center position
-- @param float z world z center position
-- @param float up x
-- @param float up y
-- @param float up z
-- @param float dirX direction x
-- @param float dirY direction y
-- @param float dirZ direction z
function DebugUtil.drawDebugReferenceAxis(posX, posY, posZ, upX, upY, upZ, dirX, dirY, dirZ )
    local sideX, sideY, sideZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
    local length = 0.2

    drawDebugLine((posX - sideX * length), (posY - sideY * length), (posZ - sideZ * length), 1, 1, 1, (posX + sideX * length), (posY + sideY * length), (posZ + sideZ * length), 1, 0, 0)
    drawDebugLine((posX - upX * length),   (posY - upY * length),   (posZ - upZ * length),   1, 1, 1, (posX + upX * length),   (posY + upY * length),   (posZ + upZ * length),   0, 1, 0)
    drawDebugLine((posX - dirX * length),  (posY - dirY * length),  (posZ - dirZ * length),  1, 1, 1, (posX + dirX * length),  (posY + dirY * length),  (posZ + dirZ * length),  0, 0, 1)
end


---Draw debug parallelogram
-- @param float x world x center position
-- @param float z world z center position
-- @param float widthX widthX
-- @param float widthZ widthZ
-- @param float heightX heightX
-- @param float heightZ heightZ
-- @param float heightOffset heightOffset
-- @param float r red
-- @param float g green
-- @param float b blue
-- @param float a alpha
function DebugUtil.drawDebugParallelogram(x,z, widthX,widthZ, heightX,heightZ, heightOffset, r,g,b,a, fixedHeight)

    local x0, z0 = x, z
    local y0 = getTerrainHeightAtWorldPos(g_terrainNode, x0,0,z0) + heightOffset

    local x1 = x0 + widthX
    local z1 = z0 + widthZ
    local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1,0,z1) + heightOffset

    local x2 = x0 + heightX
    local z2 = z0 + heightZ
    local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2,0,z2) + heightOffset

    local x3 = x0 + widthX + heightX
    local z3 = z0 + widthZ + heightZ
    local y3 = getTerrainHeightAtWorldPos(g_terrainNode, x3,0,z3) + heightOffset

    if fixedHeight then
        y0, y1, y2, y3 = heightOffset, heightOffset, heightOffset, heightOffset
    end

    drawDebugTriangle(x0,y0,z0, x1,y1,z1, x2,y2,z2, r,g,b,a, false)
    drawDebugTriangle(x1,y1,z1, x3,y3,z3, x2,y2,z2, r,g,b,a, false)
    -- and reverse order
    drawDebugTriangle(x0,y0,z0, x2,y2,z2, x1,y1,z1, r,g,b,a, false)
    drawDebugTriangle(x2,y2,z2, x3,y3,z3, x1,y1,z1, r,g,b,a, false)

    drawDebugLine(x0,y0,z0, r,g,b, x1,y1,z1, r,g,b)
    drawDebugLine(x1,y1,z1, r,g,b, x2,y2,z2, r,g,b)
    drawDebugLine(x2,y2,z2, r,g,b, x0,y0,z0, r,g,b)

    drawDebugLine(x1,y1,z1, r,g,b, x3,y3,z3, r,g,b)
    drawDebugLine(x3,y3,z3, r,g,b, x2,y2,z2, r,g,b)

end


---Draw debug density map parallelogram
-- @param float x world x start position
-- @param float z world z start position
-- @param float widthX world x width position
-- @param float widthZ world z width position
-- @param float heightX world x height position
-- @param float heightZ world z height position
-- @param float heightOffset heightOffset
-- @param float r red
-- @param float g green
-- @param float b blue
-- @param float a alpha
function DebugUtil.drawDebugWorldParallelogram(x,z, widthX,widthZ, heightX,heightZ, heightOffset, r,g,b,a, fixedHeight)

    local x0, z0 = x, z
    local y0 = getTerrainHeightAtWorldPos(g_terrainNode, x0,0,z0) + heightOffset

    local x1 = widthX
    local z1 = widthZ
    local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1,0,z1) + heightOffset

    local x2 = heightX
    local z2 = heightZ
    local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2,0,z2) + heightOffset

    local x3 = x0 + (widthX-x) + (heightX-x)
    local z3 = z0 + (widthZ-z) + (heightZ-z)
    local y3 = getTerrainHeightAtWorldPos(g_terrainNode, x3,0,z3) + heightOffset

    if fixedHeight then
        y0, y1, y2, y3 = heightOffset, heightOffset, heightOffset, heightOffset
    end

    drawDebugTriangle(x0,y0,z0, x1,y1,z1, x2,y2,z2, r,g,b,a, false)
    drawDebugTriangle(x1,y1,z1, x3,y3,z3, x2,y2,z2, r,g,b,a, false)
    -- and reverse order
    drawDebugTriangle(x0,y0,z0, x2,y2,z2, x1,y1,z1, r,g,b,a, false)
    drawDebugTriangle(x2,y2,z2, x3,y3,z3, x1,y1,z1, r,g,b,a, false)

    drawDebugLine(x0,y0,z0, r,g,b, x1,y1,z1, r,g,b)
    drawDebugLine(x1,y1,z1, r,g,b, x2,y2,z2, r,g,b)
    drawDebugLine(x2,y2,z2, r,g,b, x0,y0,z0, r,g,b)

    drawDebugLine(x1,y1,z1, r,g,b, x3,y3,z3, r,g,b)
    drawDebugLine(x3,y3,z3, r,g,b, x2,y2,z2, r,g,b)

end


---
function DebugUtil.drawArea(area, r, g, b, a)
    local x0,_,z0 = getWorldTranslation(area.start)
    local x1,_,z1 = getWorldTranslation(area.width)
    local x2,_,z2 = getWorldTranslation(area.height)
    local x,z, widthX,widthZ, heightX,heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)
    DebugUtil.drawDebugParallelogram(x,z, widthX,widthZ, heightX,heightZ, r, g, b, a)
end


---Draws the cut node area with the given size
-- @param integer cutNode cut node
-- @param float sizeY size y
-- @param float sizeZ size z
-- @param float r r color value
-- @param float g g color value
-- @param float b b color value
function DebugUtil.drawCutNodeArea(node, sizeY, sizeZ, r, g, b)
    if node ~= nil then
        local x, y, z = getWorldTranslation(node)
        local x2, y2, z2 = localToWorld(node, 0, sizeY or 1, 0)
        local x3, y3, z3 = localToWorld(node, 0, 0, sizeZ or 1)
        DebugUtil.drawDebugAreaRectangle(x, y, z, x2, y2, z2, x3, y3, z3, false, r or 0, g or 1, b or 0)
    end
end


---Print a table recursively
-- @param table inputTable table to print
-- @param string inputIndent input indent
-- @param integer depth current depth
-- @param integer maxDepth max depth
function DebugUtil.printTableRecursively(inputTable, inputIndent, depth, maxDepth)
    inputIndent = inputIndent or "  "
    depth = depth or 0
    maxDepth = maxDepth or 3
    if depth > maxDepth then
        return
    end
    local debugString = ""
    for i,j in pairs(inputTable) do
        print(inputIndent..tostring(i).." :: "..tostring(j))
        --debugString = debugString .. string.format("%s %s :: %s\n", inputIndent, tostring(i), tostring(j))
        if type(j) == "table" then
            DebugUtil.printTableRecursively(j, inputIndent.."    ", depth+1, maxDepth)
            --local string2 = DebugUtil.printTableRecursively(j, inputIndent.."    ", depth+1, maxDepth)
            --if string2 ~= nil then
            --    debugString = debugString .. string2
            --end
        end
    end
    return debugString
end



---useless on large tables
function DebugUtil.debugTableToString(inputTable, inputIndent, depth, maxDepth)
    inputIndent = inputIndent or "  "
    depth = depth or 0
    maxDepth = maxDepth or 2
    if depth > maxDepth then
        return nil
    end
    local string1 = ""
    for i,j in pairs(inputTable) do
        string1 = string1 .. string.format("\n%s %s :: %s", inputIndent, tostring(i), tostring(j))

        if type(j) == "table" then
            local string2 = DebugUtil.debugTableToString(j, inputIndent .. "    ", depth+1, maxDepth)
            if string2 ~= nil then
                string1 = string1 .. string2
            end
        end
    end
    return string1
end


---
function DebugUtil.renderTable(posX, posY, textSize, data, nextColumnOffset)
    local i = 0
    setTextColor(1,1,1,1)
    setTextBold(false)
    textSize = getCorrectTextSize(textSize)
    for _, valuePair in ipairs(data) do
        local offset = i*textSize*1.05
        if valuePair.name ~= "" then
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(posX, posY-offset, textSize, tostring(valuePair.name) .. ":")
        end

        setTextAlignment(RenderText.ALIGN_LEFT)
        if type(valuePair.value) == "number" then
            renderText(posX, posY-offset, textSize, " " ..string.format("%.4f", valuePair.value))
        else
            renderText(posX, posY-offset, textSize, " " ..tostring(valuePair.value))
        end

        i = i + 1

        if valuePair.newColumn or valuePair.columnOffset then
            i = 0
            posX = posX + (valuePair.columnOffset or nextColumnOffset)
        end
    end
end










---Renders the given text at the given x and y position with the given text size. The y is then adjusted downwards by the given text size and spacing scalar and returned.
-- Usage:
-- local y = 0.5
-- y = DebugUtil.renderTextLine(0.5, y, 0.012, "line 1")
-- y = DebugUtil.renderTextLine(0.5, y, 0.012, "line 2")
-- @param float x The x position on the screen to begin drawing the text.
-- @param float y The y position on the screen to begin drawing the text.
-- @param float textSize The height of the text.
-- @param string text The text to render.
-- @param float? spacingScalar The optional scalar for spacing. At 1.0, the y will be adjusted by the text size. If this is nil, then a default value of DebugUtil.DEFAULT_RENDERLINE_SCALAR is used.
-- @param boolean? isBold The optional flag to set the text bold, defaulting to false.
-- @param Color? color The optional color of the text, defaulting to Color.PRESETS.WHITE.
-- @return float y The y value after being adjusted for a new line.
function DebugUtil.renderTextLine(x, y, textSize, text, spacingScalar, isBold, color)

    -- Set the bold, if one was given.
    setTextBold(isBold and isBold or false)

    setTextAlignment(RenderText.ALIGN_LEFT)

    setTextColor((color or Color.PRESETS.WHITE):unpack())

    -- Render the text.
    renderText(x, y, textSize, text)

    -- Start a new line and return the adjusted y value.
    return DebugUtil.renderNewLine(y, textSize, spacingScalar)
end


---Adjusts the given y value so that it starts a new line, using the given textSize multiplied by the given spacingScalar.
-- @param float y The y position on the screen from which to begin the new line.
-- @param float textSize The height of the text.
-- @param float? spacingScalar The optional scalar for spacing. At 1.0, the y will be adjusted by the text size. If this is nil, then a default value of DebugUtil.DEFAULT_RENDERLINE_SCALAR is used.
-- @return float y The y value after being adjusted for a new line.
function DebugUtil.renderNewLine(y, textSize, spacingScalar)

    -- Return the adjusted y value.
    return y - textSize * (spacingScalar and spacingScalar or DebugUtil.DEFAULT_RENDERLINE_SCALAR)
end


---
function DebugUtil.printNodeHierarchy(node, offset, appendType)
    offset = offset or ""

    if not appendType then
        log(string.format("%s%s", offset, getName(node)))
    else
        local classText = ""
        for className, classId in pairs(ClassIds) do
            if getHasClassId(node, classId) then
                classText = classText .. className .. " | "
            end
        end
        if not string.isNilOrWhitespace(classText) then
            classText = string.sub(classText, 1, #classText - 3)
        end

        log(string.format("%s%s (%s)", offset, getName(node), classText))
    end

    for i=0, getNumOfChildren(node)-1 do
        DebugUtil.printNodeHierarchy(getChildAt(node, i), offset.." ", appendType)
    end
end


---Print the script call location of a function call which uses this function.
function DebugUtil.printCallingFunctionLocation()
    local stackLevel = 3 -- = <this>() + <warning / debug code> + <calling function>
    local callerScript, callerLine = debug.info(stackLevel, "sl")  -- https://luau-lang.org/library#debug-library

    print(string.format("%s, line %d", tostring(callerScript), callerLine))
end
