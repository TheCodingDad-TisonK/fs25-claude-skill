









---Holds and manages a collection of functions and target objects
local ListenerList_mt = Class(ListenerList)


---Creates a new listener list.
-- @param boolean? ignoreFirstArgument If this is true, the first argument is not passed along when invoking. Used to ignore the table instance when the listener list is a member of a table.
-- @return ListenerList instance The created instance.
function ListenerList.new(ignoreFirstArgument)

    -- Create the instance.
    local self = setmetatable({}, ListenerList_mt)

    -- The collection of listening functions.
    self.listeners = {}

    -- If this is true, the first argument is not passed to the invoked functions. This is useful to ignore the table instance when the listener list is a member of a table.
    self.ignoreFirstArgument = ignoreFirstArgument == true

    -- Return the created instance.
    return self
end


---Adds the given listener function and target object to the listeners list.
-- @param (function|TargetedFunction) listenerFunction The function or TargetedFunction to add to the list.
-- @param table? targetObject The optional target object.
function ListenerList:registerListener(listenerFunction, targetObject)

    -- Resolve the listener function.
    local listener = TargetedFunction.resolveListener(listenerFunction, targetObject)

    -- Add the listener function to the list.
    table.insert(self.listeners, listener)
end


---Calls the listeners with the given arguments.
-- @param any ... The collection of arguments to pass to the functions.
function ListenerList:invoke(targetObject, ...)

    -- Invoke each listener.
    if self.ignoreFirstArgument then
        for _, listener in ipairs(self.listeners) do
            listener:invoke(...)
        end
    else
        for _, listener in ipairs(self.listeners) do
            listener:invoke(targetObject, ...)
        end
    end
end


---Metamethod so the table itself can be called as a shortcut for :invoke().
-- @param ListenerList instance The instance of the listener list.
-- @param any ... The collection of arguments to pass to the functions.
function ListenerList_mt.__call(instance, ...)
    return instance:invoke(...)
end
