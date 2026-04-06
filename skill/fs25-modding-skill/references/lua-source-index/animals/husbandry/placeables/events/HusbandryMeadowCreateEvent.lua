








---
local HusbandryMeadowCreateEvent_mt = Class(HusbandryMeadowCreateEvent, Event)




---
function HusbandryMeadowCreateEvent.emptyNew()
    local self = Event.new(HusbandryMeadowCreateEvent_mt)
    return self
end


---
function HusbandryMeadowCreateEvent.new(placeable, createMeadow)
    local self = HusbandryMeadowCreateEvent.emptyNew()

    self.placeable = placeable
    self.createMeadow = createMeadow

    return self
end


---
function HusbandryMeadowCreateEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.createMeadow = streamReadBool(streamId)
    self:run(connection)
end


---
function HusbandryMeadowCreateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteBool(streamId, self.createMeadow)
end


---
function HusbandryMeadowCreateEvent:run(connection)
    if self.placeable ~= nil then
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection, self.placeable)
        end

        if self.placeable:getIsSynchronized() then
            self.placeable:createMeadow(self.createMeadow, true)
        end
    end
end
