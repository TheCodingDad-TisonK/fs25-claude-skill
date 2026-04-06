









---
local AIMessage_mt = Class(AIMessage)


---
function AIMessage.new(customMt)
    local self = setmetatable({}, customMt or AIMessage_mt)
    return self
end


---
function AIMessage:getMessage(job)
    local i18nText = self:getI18NText()
    if i18nText ~= nil then
        if job == nil then
--#debug             Logging.warning("AIMessage:getMessage() job was nil")
--#debug             printCallstack()
            return string.format(i18nText, "Unknown")
        end
        return string.format(i18nText, job:getHelperName() or "Unknown")
    end

    return ""
end






---
function AIMessage:getType()
    return AIMessageType.ERROR
end


---
function AIMessage:readStream(streamId, connection)
end


---
function AIMessage:writeStream(streamId, connection)
end
