









---
local AIMessageErrorUnknown_mt = Class(AIMessageErrorUnknown, AIMessage)


---
function AIMessageErrorUnknown.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorUnknown_mt)
    return self
end


---
function AIMessageErrorUnknown:getI18NText()
    return g_i18n:getText("ai_messageErrorUnknown")
end
