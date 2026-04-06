








---
local VehicleTeleportEvent_mt = Class(VehicleTeleportEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleTeleportEvent.emptyNew()
    local self = Event.new(VehicleTeleportEvent_mt, NetworkNode.CHANNEL_MAIN)
    return self
end





























---Run action on receiving side
-- @param integer connection connection
function VehicleTeleportEvent:run(connection)
    if not connection:getIsServer() then
        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
            g_currentMission:teleportVehicle(self.vehicle, self.x, self.z, self.rotY)
        end
    end
end
