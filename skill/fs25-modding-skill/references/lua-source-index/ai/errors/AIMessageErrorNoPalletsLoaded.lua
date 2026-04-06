









---
local AIMessageErrorNoPalletsLoaded_mt = Class(AIMessageErrorNoPalletsLoaded, AIMessage)


---
function AIMessageErrorNoPalletsLoaded.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorNoPalletsLoaded_mt)
    return self
end


---
function AIMessageErrorNoPalletsLoaded:getI18NText()
    return g_i18n:getText("ai_messageErrorNoPalletsLoaded")
end


---
function AIMessageErrorNoPalletsLoaded:getType()
    return AIMessageType.ERROR
end
