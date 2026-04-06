

---
local PlayerPermissionsEvent_mt = Class(PlayerPermissionsEvent, Event)















































































---Create an instance
-- @param table player player instance
-- @param integer farmId farm identification
-- @param boolean noEventSend if false will send the event
function PlayerPermissionsEvent.sendEvent(userId, permissions, isFarmManager, noEventSend)
    if noEventSend == nil or noEventSend == false then
        local event = PlayerPermissionsEvent.new(userId, permissions, isFarmManager)

        if g_server ~= nil then
            local farm = g_farmManager:getFarmByUserId(userId)
            local player = farm.userIdToPlayer[userId]

            g_server:broadcastEvent(event, nil, nil, player)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
