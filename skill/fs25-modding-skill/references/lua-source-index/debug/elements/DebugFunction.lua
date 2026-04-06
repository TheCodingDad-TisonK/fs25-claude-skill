









---
local DebugFunction_mt = Class(DebugFunction)











































---dedicated function used by DebugManger to determine if draw() should be called or not
-- @return boolean shouldBeDrawn
function DebugFunction:getShouldBeDrawn()
    return true
end


---
function DebugFunction:draw()
    if self.drawFunc ~= nil then
        self.drawFunc(self)
    end
end
