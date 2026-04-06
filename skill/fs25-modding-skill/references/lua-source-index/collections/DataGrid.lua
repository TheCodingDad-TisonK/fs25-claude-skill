









---A datagrid datastructure
local DataGrid_mt = Class(DataGrid)


---Creating data grid
-- @param integer numRows number of rows
-- @param integer numColumns number of columns
-- @param table? customMt custom metatable
-- @return table instance instance of object
function DataGrid.new(numRows, numColumns, customMt)
    local self = setmetatable({}, customMt or DataGrid_mt)

    self.grid = {}
    self.numRows = numRows
    self.numColumns = numColumns
    for _=1, numRows do
        table.insert(self.grid, {})
    end

    return self
end


---Deletes data grid
function DataGrid:delete()
    self.grid = nil
end


---Gets value at given row and column
-- @param integer rowIndex index of row
-- @param integer colIndex index of column
-- @return table value value at the given position
function DataGrid:getValue(rowIndex, colIndex)
    if rowIndex < 1 or rowIndex > self.numRows then
        Logging.error("rowIndex out of bounds!")
        printCallstack()
        return nil
    end
    if colIndex < 1 or colIndex > self.numColumns then
        Logging.error("colIndex out of bounds!")
        printCallstack()
        return nil
    end

    return self.grid[rowIndex][colIndex]
end


---Set value at given row and column
-- @param integer rowIndex index of row
-- @param integer colIndex index of column
-- @param table value value at the given position
function DataGrid:setValue(rowIndex, colIndex, value)
    if rowIndex < 1 or rowIndex > self.numRows then
        Logging.error("rowIndex out of bounds!")
        printCallstack()
        return false
    end
    if colIndex < 1 or colIndex > self.numColumns then
        Logging.error("colIndex out of bounds!")
        printCallstack()
        return false
    end

    self.grid[rowIndex][colIndex] = value
    return true
end
