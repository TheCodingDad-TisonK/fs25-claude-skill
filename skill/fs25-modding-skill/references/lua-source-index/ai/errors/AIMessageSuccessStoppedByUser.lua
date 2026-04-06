









---
local AIMessageSuccessStoppedByUser_mt = Class(AIMessageSuccessStoppedByUser, AIMessage)


---
function AIMessageSuccessStoppedByUser.new(customMt)
    local self = AIMessage.new(customMt or AIMessageSuccessStoppedByUser_mt)
    return self
end


---
function AIMessageSuccessStoppedByUser:getI18NText()
    return g_i18n:getText("ai_messageSuccessStoppedByUser")
end


---
function AIMessageSuccessStoppedByUser:getType()
    return AIMessageType.OK
end
