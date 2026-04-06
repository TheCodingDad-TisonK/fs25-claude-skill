









---
local AIMessageErrorUnloadingStationDeleted_mt = Class(AIMessageErrorUnloadingStationDeleted, AIMessage)


---
function AIMessageErrorUnloadingStationDeleted.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorUnloadingStationDeleted_mt)
    return self
end


---
function AIMessageErrorUnloadingStationDeleted:getI18NText()
    return g_i18n:getText("ai_messageErrorUnloadingStationDeleted")
end
