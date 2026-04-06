









---
local AIMessageErrorVehicleDeleted_mt = Class(AIMessageErrorVehicleDeleted, AIMessage)


---
function AIMessageErrorVehicleDeleted.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorVehicleDeleted_mt)
    return self
end


---
function AIMessageErrorVehicleDeleted:getI18NText()
    return g_i18n:getText("ai_messageErrorVehicleDeleted")
end
