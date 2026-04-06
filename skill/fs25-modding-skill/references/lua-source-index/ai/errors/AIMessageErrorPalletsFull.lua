









---
local AIMessageErrorPalletsFull_mt = Class(AIMessageErrorPalletsFull, AIMessage)


---
function AIMessageErrorPalletsFull.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorPalletsFull_mt)
    return self
end


---
function AIMessageErrorPalletsFull:getI18NText()
    return g_i18n:getText("ai_messageErrorPalletsFull")
end


---
function AIMessageErrorPalletsFull:getType()
    return AIMessageType.ERROR
end
