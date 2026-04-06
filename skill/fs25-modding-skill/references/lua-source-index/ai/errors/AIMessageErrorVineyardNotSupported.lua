









---
local AIMessageErrorVineyardNotSupported_mt = Class(AIMessageErrorVineyardNotSupported, AIMessage)


---
function AIMessageErrorVineyardNotSupported.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorVineyardNotSupported_mt)
    return self
end


---
function AIMessageErrorVineyardNotSupported:getI18NText()
    return g_i18n:getText("ai_messageErrorVineyardNotSupported")
end
