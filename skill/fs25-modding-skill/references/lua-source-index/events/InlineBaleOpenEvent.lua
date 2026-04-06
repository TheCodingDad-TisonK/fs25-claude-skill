



---Event for inline bale opening
local InlineBaleOpenEvent_mt = Class(InlineBaleOpenEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function InlineBaleOpenEvent.emptyNew()
    local self = Event.new(InlineBaleOpenEvent_mt)
    return self
end


---Create new instance of event
-- @param table inlineBale inlineBale
-- @param float x x opening position
-- @param float y y opening position
-- @param float z z opening position
-- @return table instance instance of event
function InlineBaleOpenEvent.new(inlineBale, x,y,z)
    local self = InlineBaleOpenEvent.emptyNew()
    self.inlineBale = inlineBale
    self.x = x
    self.y = y
    self.z = z
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function InlineBaleOpenEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.inlineBale = NetworkUtil.readNodeObject(streamId)
        self.x = streamReadFloat32(streamId)
        self.y = streamReadFloat32(streamId)
        self.z = streamReadFloat32(streamId)
    end
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function InlineBaleOpenEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.inlineBale)
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.y)
        streamWriteFloat32(streamId, self.z)
    end
end


---Run action on receiving side
-- @param integer connection connection
function InlineBaleOpenEvent:run(connection)
    if not connection:getIsServer() then
        self.inlineBale:openBaleAtPosition(self.x, self.y, self.z)
    end
end
