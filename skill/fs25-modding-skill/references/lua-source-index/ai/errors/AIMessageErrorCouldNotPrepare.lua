









---
local AIMessageErrorCouldNotPrepare_mt = Class(AIMessageErrorCouldNotPrepare, AIMessage)


---
function AIMessageErrorCouldNotPrepare.new(vehicle, customMt)
    local self = AIMessage.new(customMt or AIMessageErrorCouldNotPrepare_mt)

    self.vehicle = vehicle

    return self
end


---
function AIMessageErrorCouldNotPrepare:getMessage(job)
    local i18nText = self:getI18NText()
    local vehicleName = ""
    if self.vehicle ~= nil then
        vehicleName = self.vehicle:getName()
    end

    local helperName = "Unknown"
    if job ~= nil then
        helperName = job:getHelperName() or helperName
    else
--#debug             Logging.warning("AIMessageErrorCouldNotPrepare:getMessage() job was nil")
--#debug             printCallstack()
    end

    return string.format(i18nText, helperName, vehicleName)
end






---
function AIMessageErrorCouldNotPrepare:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
end


---
function AIMessageErrorCouldNotPrepare:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end
