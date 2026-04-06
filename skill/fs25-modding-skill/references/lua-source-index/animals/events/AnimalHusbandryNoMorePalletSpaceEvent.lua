

---
local AnimalHusbandryNoMorePalletSpaceEvent_mt = Class(AnimalHusbandryNoMorePalletSpaceEvent, Event)





---Creating empty instance
-- @return table instance instance of object
function AnimalHusbandryNoMorePalletSpaceEvent.emptyNew()
    local self = Event.new(AnimalHusbandryNoMorePalletSpaceEvent_mt)
    return self
end


---Creating instance
-- @param table animalHusbandry instance of animal husbandry
-- @param integer fillTypeIndex
-- @return AnimalHusbandryNoMorePalletSpaceEvent self
function AnimalHusbandryNoMorePalletSpaceEvent.new(animalHusbandry, fillTypeIndex)
    local self = AnimalHusbandryNoMorePalletSpaceEvent.emptyNew()

    self.animalHusbandry = animalHusbandry
    self.fillTypeIndex = fillTypeIndex

    return self
end



---Reads from network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function AnimalHusbandryNoMorePalletSpaceEvent:readStream(streamId, connection)
    self.animalHusbandry = NetworkUtil.readNodeObject(streamId)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

    self:run(connection)
end


---Writes in network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function AnimalHusbandryNoMorePalletSpaceEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.animalHusbandry)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end


---Run event
-- @param table connection connection information
function AnimalHusbandryNoMorePalletSpaceEvent:run(connection)
    if connection:getIsServer() then
        if self.animalHusbandry ~= nil then
            self.animalHusbandry:showPalletBlockedWarning(self.fillTypeIndex)
        end
    end
end
