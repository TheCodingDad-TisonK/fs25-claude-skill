









---Base display frame element. All GUI views (partial and full screen) inherit from this.
-- 
-- This element provides the functionality to register control IDs, which are then exposed as fields of the concrete
-- descendant class (e.g. MainScreen or PasswordDialog). The control IDs must be assigned verbatim to any control
-- in the corresponding configuration XML file. If a registered ID is not used, the field will not be assigned and
-- access will fail. Available field IDs are documented as field properties per class. When creating a new view, take
local FrameElement_mt = Class(FrameElement, GuiElement)





---
function FrameElement.new(target, customMt)
    local self = GuiElement.new(target, customMt or FrameElement_mt)

    self.controlIDs = {} -- list of control element IDs to be resolved on loading
    self.changeScreenCallback = NO_CALLBACK -- change view callback
    self.toggleCustomInputContextCallback = NO_CALLBACK -- custom input context toggle callback
    self.playSampleCallback = NO_CALLBACK -- play sound sample callback
    self.hasCustomInputContext = false -- safety flag for input context stack handling

    self.time = 0
    self.inputDisableTime = 0

    self.playHoverSoundOnFocus = false

    return self
end


---Override of GuiElement:clone().
-- Also exposes registered control element fields.
function FrameElement:clone(parent, includeId, suppressOnCreate)
    local ret = FrameElement:superClass().clone(self, parent, includeId, suppressOnCreate)
    ret:exposeControlsAsFields(self.name)

    ret.changeScreenCallback = self.changeScreenCallback
    ret.toggleCustomInputContextCallback = self.toggleCustomInputContextCallback
    ret.playSampleCallback = self.playSampleCallback
    ret.hasCustomInputContext = self.hasCustomInputContext

    return ret
end


---Override of GuiElement:copyAttributes().
-- Also resets registered control IDs so they can be exposed as fields again.
function FrameElement:copyAttributes(src)
    FrameElement:superClass().copyAttributes(self, src)
    for k, _ in pairs(src.controlIDs) do
        self.controlIDs[k] = false
    end
end


---Override of GuiElement:copyAttributes().
-- Also resets registered control IDs so they can be exposed as fields again.
function FrameElement:delete()
    FrameElement:superClass().delete(self)

    for k, _ in pairs(self.controlIDs) do
        self.controlIDs[k] = nil
        self[k] = nil
    end
end


---Get the frame's root GuiElement instance.
-- This is the first and only direct child of a FrameElement, as defined by the GUI instantiation logic. This method
-- will always return a GuiElement instance, even if a new one must be created first.
function FrameElement:getRootElement()
    if #self.elements > 0 then
        return self.elements[1]
    else
        local newRoot = GuiElement.new()
        self:addElement(newRoot)
        return newRoot
    end
end


---Adds registered controls as fields to this FrameElement instance.
-- Called by the GUI system after loading.
-- The new fields will have the same name as the registered ID, so make sure there are no collision to avoid overrides
-- and that IDs are also valid as identifiers in Lua. If a control has been registered but no corresponding element is
-- available (e.g. when sub-classing and omitting some elements), the field will remain undefined. It's up to callers
-- to ensure that field configuration and usage in views matches.
-- @param viewName View name of this frame element
function FrameElement:exposeControlsAsFields(viewName)
    local allChildren = self:getDescendants()
    for _, element in pairs(allChildren) do
        if element.id and element.id ~= "" then
            local index, varName = GuiElement.extractIndexAndNameFromID(element.id)
            if index then -- indexed field, expose as a list
                if not self[varName] then
                    self[varName] = {}
                end

                self[varName][index] = element
            else -- regular field, just assign to the element table
                self[varName] = element
            end

            self.controlIDs[varName] = true -- mark as resolved
        end
    end

    --TODO: enable and check
    if self.debugEnabled or g_uiDebugEnabled then
        for id, isResolved in pairs(self.controlIDs) do
            if not isResolved then
                Logging.warning("FrameElement for GUI view '%s' could not resolve registered control element ID '%s'. Check configuration.", tostring(viewName), tostring(id))
            end
        end
    end
end


---Set input disabling to a given duration.
-- @param float duration Input disabling duration in milliseconds
function FrameElement:disableInputForDuration(duration)
    self.inputDisableTime = math.clamp(duration, 0, 10000) -- clamp to plausible range (up to 10s)
end


---Check if input is currently disabled.
function FrameElement:isInputDisabled()
    return self.inputDisableTime > 0
end


---
function FrameElement:update(dt)
    FrameElement:superClass().update(self, dt)

    self.time = self.time + dt
    if self.inputDisableTime > 0 then
        self.inputDisableTime = self.inputDisableTime - dt
    end
end


---Set a callback for requesting a view change from within a frame or screen view.
-- @param function callback Function reference, signature: function(sourceFrameElement, targetScreenClass, returnScreenClass)
function FrameElement:setChangeScreenCallback(callback)
    self.changeScreenCallback = callback or NO_CALLBACK
end


---Set a callback function for requesting a custom menu input context for this frame.
-- @param function callback Function reference, signature: function(isContextActive)
function FrameElement:setInputContextCallback(callback)
    self.toggleCustomInputContextCallback = callback or NO_CALLBACK
end


---Set a callback function for requesting to play a sound sample.
-- @param function callback Function reference, signature: function(sampleName)
function FrameElement:setPlaySampleCallback(callback)
    self.playSampleCallback = callback or NO_CALLBACK
end


---Request a view change via the callback defined by setChangeScreenCallback().
-- @param table targetScreenClass Class table of requested view (ScreenElement descendant, must be full view)
function FrameElement:changeScreen(targetScreenClass, returnScreenClass)
--#debug     if returnScreenClass ~= nil and targetScreenClass == nil then
--#debug         Logging.error("Changing to empty/nil screen with a return screen given. Trying to call g_gui:changeScreen instead?")
--#debug         printCallstack()
--#debug     end
    self.changeScreenCallback(self, targetScreenClass, returnScreenClass)
end


---Request toggling of a custom menu input context for this frame via the callback defined by setInputContextCallback().
-- @param boolean isContextActive If true, will activate a custom menu input context. Otherwise, will clear a previously
activated context.
-- @param string contextName Name of the custom input context. Use a unique identifier value.
function FrameElement:toggleCustomInputContext(isContextActive, contextName)
    if self.hasCustomInputContext and not isContextActive or not self.hasCustomInputContext and isContextActive then
        self.toggleCustomInputContextCallback(isContextActive, contextName)
        self.hasCustomInputContext = isContextActive
    end
end


---Request playing a sound sample identified by name.
-- @param string sampleName Sample name, use one of GuiSoundPlayer.SOUND_SAMPLES
function FrameElement:playSample(sampleName)
    if not self:getSoundSuppressed() then
        self.playSampleCallback(sampleName)
    end
end
