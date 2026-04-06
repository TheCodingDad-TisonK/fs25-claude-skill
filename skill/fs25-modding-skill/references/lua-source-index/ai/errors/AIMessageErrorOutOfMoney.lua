









---
local AIMessageErrorOutOfMoney_mt = Class(AIMessageErrorOutOfMoney, AIMessage)


---
function AIMessageErrorOutOfMoney.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorOutOfMoney_mt)
    return self
end


---
function AIMessageErrorOutOfMoney:getI18NText()
    return g_i18n:getText("ai_messageErrorOutOfMoney")
end
