










---A map data grid that splits a map into multiple sections
local MapDataGrid_mt = Class(MapDataGrid, DataGrid)


---Creates a map grid instance with the given map size, cells per row/column, and optional custom metatable.
-- @param integer mapSize map size
-- @param integer blocksPerRowColumn blocks per row and column
-- @param table? customMt custom metatable
-- @return table instance instance of object
function MapDataGrid.new(mapSize, blocksPerRowColumn, customMt)
    local self = DataGrid.new(blocksPerRowColumn, blocksPerRowColumn, customMt or MapDataGrid_mt)

    self.blocksPerRowColumn = blocksPerRowColumn
    self.mapSize = mapSize
    self.blockSize = self.mapSize/self.blocksPerRowColumn

    return self
end


---Creates a new data grid from the given map size and block size.
-- @param integer mapSize The size of the map in metres.
-- @param integer blockSize The size of one cell in metres.
-- @param table? customMt The custom metatable to use, if any.
-- @return MapDataGrid instance The created instance.
function MapDataGrid.createFromBlockSize(mapSize, blockSize, customMt)

    -- Calculate the blocks per row, then return the result of the constructor with this value.
    local blocksPerRowColumn = math.ceil(mapSize / blockSize)
    return MapDataGrid.new(mapSize, blocksPerRowColumn, customMt)
end


---Get value at world position
-- @param float worldX world position x
-- @param float worldZ world position z
-- @return table value value at the given position
function MapDataGrid:getValueAtWorldPos(worldX, worldZ)
    local rowIndex, colIndex = self:getRowColumnFromWorldPos(worldX, worldZ)
    return self:getValue(rowIndex, colIndex), rowIndex, colIndex
end


---Set value at world position
-- @param float worldX world position x
-- @param float worldZ world position z
-- @param table value value at the given position
function MapDataGrid:setValueAtWorldPos(worldX, worldZ, value)
    local rowIndex, colIndex = self:getRowColumnFromWorldPos(worldX, worldZ)
    self:setValue(rowIndex, colIndex, value)
end


---Gets clamped row and column at given world position
-- @param float worldX world position x
-- @param float worldZ world position z
-- @return integer row row
-- @return integer column column
function MapDataGrid:getRowColumnFromWorldPos(worldX, worldZ)
    local mapSize = self.mapSize
    local blocksPerRowColumn = self.blocksPerRowColumn

    local x = (worldX + mapSize*0.5) / mapSize
    local z = (worldZ + mapSize*0.5) / mapSize

    local row = math.clamp(math.ceil(blocksPerRowColumn*z), 1, blocksPerRowColumn)
    local column = math.clamp(math.ceil(blocksPerRowColumn*x), 1, blocksPerRowColumn)

--    log(worldX, worldZ, " -> ", (worldX + self.mapSize*0.5), (worldZ + self.mapSize*0.5), z, x, row, column)

    return row, column
end


---Calculates if the given world position is in range of the data.
-- @param float worldX The x world position.
-- @param float worldZ The z world position.
-- @return boolean isInRange True if the position is in range of the data; otherwise false.
function MapDataGrid:isWorldPositionInRange(worldX, worldZ)
    return worldX > self.mapSize * -0.5 and worldX <= self.mapSize * 0.5 and worldZ > self.mapSize * -0.5 and worldZ <= self.mapSize * 0.5
end
