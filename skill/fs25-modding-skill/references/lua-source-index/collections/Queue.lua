











---
local Queue_mt = Class(Queue)




















































---Returns the element from the front of the queue without popping it.
-- @return table? value The element at the front of the queue, or nil if the queue is empty.
function Queue:peek()
    return self.first
end
