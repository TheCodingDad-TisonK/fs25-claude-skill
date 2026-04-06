



---
local HusbandryFenceUpdateEvent_mt = Class(HusbandryFenceUpdateEvent, Event)




---
function HusbandryFenceUpdateEvent.emptyNew()
    local self = Event.new(HusbandryFenceUpdateEvent_mt)
    return self
end


---
function HusbandryFenceUpdateEvent.new(placeable, deleteCustomizableSegments)
    local self = HusbandryFenceUpdateEvent.emptyNew()

    self.placeable = placeable
    self.deleteCustomizableSegments = deleteCustomizableSegments

    return self
end


---
function HusbandryFenceUpdateEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.deleteCustomizableSegments = streamReadBool(streamId)

    self:run(connection)
end


---
function HusbandryFenceUpdateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteBool(streamId, self.deleteCustomizableSegments)
end


---
function HusbandryFenceUpdateEvent:run(connection)
    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        if self.deleteCustomizableSegments then
            self.placeable:deleteCustomizableSegments()
        end
        self.placeable:finalizeHusbandryFence()
    end
end
