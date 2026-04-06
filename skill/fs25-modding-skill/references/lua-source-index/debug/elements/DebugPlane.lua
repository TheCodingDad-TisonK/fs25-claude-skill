









---
local DebugPlane_mt = Class(DebugPlane, DebugElement)












































































---
function DebugPlane:draw()
    DebugPlane.renderWithPositions(nil, nil, nil, nil, nil, nil, nil, nil, nil, self.color, self.alignToTerrain, self.filled, self.doubleSided, self.solid, self.text, self.cornerPositions)
end

















































































---createWithNodes
-- @param entityId startNode
-- @param entityId widthNode
-- @param entityId heightNode
-- @return DebugPlane self
function DebugPlane:createWithNodes(startNode, widthNode, heightNode)

--#debug     Assert.isType(startNode, "number")
--#debug     Assert.isType(widthNode, "number")
--#debug     Assert.isType(heightNode, "number")

    local startX, startY, startZ = getWorldTranslation(startNode)
    local widthX, widthY, widthZ = getWorldTranslation(widthNode)
    local heightX, heightY, heightZ = getWorldTranslation(heightNode)

    self:createWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)

    return self
end














































































































































































---createWithNode
-- @param entityId node
-- @param float sizeX
-- @param float sizeZ
-- @return DebugPlane self
function DebugPlane:createWithNode(node, sizeX, sizeZ)

--#debug     Assert.isType(node, "number")
--#debug     Assert.isType(sizeX, "number")
--#debug     Assert.isType(sizeZ, "number")

    local sizeXHalf = sizeX*0.5
    local sizeZHalf = sizeZ*0.5
    local pos = self.cornerPositions
    pos[1] = {localToWorld(node, -sizeXHalf, 0, -sizeZHalf)}
    pos[2] = {localToWorld(node, -sizeXHalf, 0,  sizeZHalf)}
    pos[3] = {localToWorld(node,  sizeXHalf, 0,  sizeZHalf)}
    pos[4] = {localToWorld(node,  sizeXHalf, 0, -sizeZHalf)}

    return self
end
