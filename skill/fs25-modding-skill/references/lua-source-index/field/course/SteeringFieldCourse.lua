














---
local SteeringFieldCourse_mt = Class(SteeringFieldCourse)



























---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SteeringFieldCourse:writeStream(streamId, connection)
    self:writeSegmentStatesToStream(streamId, connection)

    self.fieldCourse:writeStream(streamId, connection)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SteeringFieldCourse.readStream(streamId, connection, callback)
    local segmentStates = {}
    local numSegmentStates = streamReadUIntN(streamId, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX)
    for i=1, numSegmentStates do
        segmentStates[i] = streamReadBool(streamId)
    end

    FieldCourse.readStream(streamId, connection, function(fieldCourse)
        if fieldCourse ~= nil then
            local steeringFieldCourse = SteeringFieldCourse.new(fieldCourse)

            for i=1, #steeringFieldCourse.segmentStates do
                steeringFieldCourse.segmentStates[i] = segmentStates[i] or false
            end

            callback(steeringFieldCourse)
        else
            callback(nil)
        end
    end)
end
