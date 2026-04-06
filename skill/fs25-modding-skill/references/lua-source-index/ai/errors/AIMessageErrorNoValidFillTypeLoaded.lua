









---
local AIMessageErrorNoValidFillTypeLoaded_mt = Class(AIMessageErrorNoValidFillTypeLoaded, AIMessage)


---
function AIMessageErrorNoValidFillTypeLoaded.new(customMt)
    local self = AIMessage.new(customMt or AIMessageErrorNoValidFillTypeLoaded_mt)
    return self
end


---
function AIMessageErrorNoValidFillTypeLoaded:getI18NText()
    return g_i18n:getText("ai_messageErrorNoValidFillTypeLoaded")
end
