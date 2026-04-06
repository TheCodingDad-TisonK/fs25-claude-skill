








---
local HusbandryCancelCreationEvent_mt = Class(HusbandryCancelCreationEvent, Event)




---
function HusbandryCancelCreationEvent.emptyNew()
    local self = Event.new(HusbandryCancelCreationEvent_mt)
    return self
end


---
function HusbandryCancelCreationEvent.new(placeableId)
    local self = HusbandryCancelCreationEvent.emptyNew()

    self.placeableId = placeableId

    return self
end


---
function HusbandryCancelCreationEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObjectId(streamId)

    self:run(connection)
end


---
function HusbandryCancelCreationEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, self.placeableId)
end


---
function HusbandryCancelCreationEvent:run(connection)
    assert(not connection:getIsServer(), "HusbandryCancelCreationEvent is a client to server event only")

    if self.placeable ~= nil and self.placeable.createMeadow ~= nil then
        -- do not create meadow to get the same result as canceling the create meadow dialog
        self.placeable:createMeadow(false)
    end
end
