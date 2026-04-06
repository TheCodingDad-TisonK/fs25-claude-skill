









---
local AIMessageErrorFieldNotReady_mt = Class(AIMessageErrorFieldNotReady, AIMessage)


---
function AIMessageErrorFieldNotReady.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorFieldNotReady_mt)
    return self
end


---
function AIMessageErrorFieldNotReady:getI18NText()
    return g_i18n:getText("ai_messageErrorFieldNotReady")
end
