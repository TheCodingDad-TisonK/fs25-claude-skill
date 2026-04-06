



---Event for bale unpacking
local BaleUnpackEvent_mt = Class(BaleUnpackEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BaleUnpackEvent.emptyNew()
    local self = Event.new(BaleUnpackEvent_mt)
    return self
end


---Create new instance of event
-- @param table bale bale
-- @return table instance instance of event
function BaleUnpackEvent.new(bale)
    local self = BaleUnpackEvent.emptyNew()
    self.bale = bale
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleUnpackEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.bale = NetworkUtil.readNodeObject(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleUnpackEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.bale)
    end
end


---Run action on receiving side
-- @param integer connection connection
function BaleUnpackEvent:run(connection)
    self.bale:unpack()
end
