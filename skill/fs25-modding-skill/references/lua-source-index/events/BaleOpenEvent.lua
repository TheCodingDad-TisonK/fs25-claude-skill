



---Event for bale opening
local BaleOpenEvent_mt = Class(BaleOpenEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BaleOpenEvent.emptyNew()
    local self = Event.new(BaleOpenEvent_mt)
    return self
end


---Create new instance of event
-- @param table bale bale
-- @param float x x opening position
-- @param float y y opening position
-- @param float z z opening position
-- @return table instance instance of event
function BaleOpenEvent.new(bale)
    local self = BaleOpenEvent.emptyNew()
    self.bale = bale
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleOpenEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.bale = NetworkUtil.readNodeObject(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleOpenEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.bale)
    end
end


---Run action on receiving side
-- @param integer connection connection
function BaleOpenEvent:run(connection)
    if not connection:getIsServer() then
        self.bale:open()
    end
end
