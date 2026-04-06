









---
local AIMessageErrorWrongSeason_mt = Class(AIMessageErrorWrongSeason, AIMessage)


---
function AIMessageErrorWrongSeason.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorWrongSeason_mt)
    return self
end


---
function AIMessageErrorWrongSeason:getI18NText()
    return g_i18n:getText("ai_messageErrorWrongSeason")
end
