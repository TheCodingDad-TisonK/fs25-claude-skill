









---
local AIMessageErrorNoVineFound_mt = Class(AIMessageErrorNoVineFound, AIMessage)


---
function AIMessageErrorNoVineFound.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorNoVineFound_mt)
    return self
end


---
function AIMessageErrorNoVineFound:getI18NText()
    return g_i18n:getText("ai_messageErrorNoVineFound")
end
