









---
local AIMessageErrorLoadingStationDeleted_mt = Class(AIMessageErrorLoadingStationDeleted, AIMessage)


---
function AIMessageErrorLoadingStationDeleted.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorLoadingStationDeleted_mt)
    return self
end


---
function AIMessageErrorLoadingStationDeleted:getI18NText()
    return g_i18n:getText("ai_messageErrorLoadingStationDeleted")
end
