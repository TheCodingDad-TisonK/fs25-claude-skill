













---
local FieldCourse_mt = Class(FieldCourse)

























































































---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FieldCourse:writeStream(streamId, connection)
    self.fieldCourseSettings:writeStream(streamId, connection)

    if streamWriteBool(streamId, self.courseField ~= nil) then
        self.courseField:writeStream(streamId, connection)
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FieldCourse.readStream(streamId, connection, callback)
    local fieldCourseSettings = FieldCourseSettings.new()
    local attributes = FieldCourseSettings.readStream(streamId, connection)
    fieldCourseSettings:applyAttributes(attributes)

    local courseField
    if streamReadBool(streamId) then
        courseField = FieldCourseField.new(fieldCourseSettings)
        courseField:readStream(streamId, connection)
    end

    local generator = FieldCourseSegmentGenerator.new(fieldCourseSettings, function(segments, _, isVineyardCourse)
        if #segments > 0 then
            local fieldCourse = FieldCourse.new(fieldCourseSettings, courseField, isVineyardCourse)
            fieldCourse:addSegments(segments)
            callback(fieldCourse)
        else
            callback()
        end
    end)

    generator:setFieldData(courseField)
    generator:generate()
end
