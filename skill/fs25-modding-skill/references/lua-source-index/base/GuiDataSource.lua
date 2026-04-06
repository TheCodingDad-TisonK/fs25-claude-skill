









---Data source for UI elements.
-- Holds dynamic data and allows configuration of accessors.
local GuiDataSource_mt = Class(GuiDataSource)





---Create a new GuiDataSource instance.
function GuiDataSource.new(subclass_mt)
    local self = setmetatable({}, subclass_mt or GuiDataSource_mt)

    self.data = NO_DATA
    self.changeListeners = {} -- {<listener table> = <listener function>}

    return self
end


---Set the data source data array.
function GuiDataSource:setData(data)
    self.data = data or NO_DATA
    self:notifyChange()
end


---Add a listener with a member function which is called when this data source changes.
function GuiDataSource:addChangeListener(target, callback)
    self.changeListeners[target] = callback or NO_CALLBACK
end


---Remove a previously added change listener from the notification table.
function GuiDataSource:removeChangeListener(target)
    self.changeListeners[target] = nil
end


---Notify this data source that its data has been changed externally.
-- This will call the change callback if it has been set.
function GuiDataSource:notifyChange()
    for target, callback in pairs(self.changeListeners) do
        callback(target)
    end
end


---Get the number of data items.
function GuiDataSource:getCount()
    return #self.data
end


---Get a data item at a given index.
function GuiDataSource:getItem(index)
    return self.data[index]
end


---Set a data item at a given index.
-- If the index is out bounds of the data, this will have no effect.
function GuiDataSource:setItem(index, value, needsNotification)
    if index > 0 and index <= #self.data then
        self.data[index] = value
        if needsNotification then
            self:notifyChange()
        end
    end
end


---Iterate a data range within the given indices.
-- This is an iterator factory compatible with the default Lua for loop. E.g. "for _, item in source:iterateRange(1, 10) do"
-- will loop over data items 1 to 10.
function GuiDataSource:iterateRange(startIndex, endIndex)
    local iterator = function(data, iter)
        local item = data[iter]
        if iter <= endIndex and item ~= nil then
            return iter + 1, item
        else
            return nil, nil
        end
    end

    return iterator, self.data, startIndex
end
