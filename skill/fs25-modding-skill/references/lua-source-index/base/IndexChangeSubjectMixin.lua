


















---Add this mixin to a GuiElement to implement an observer pattern for index changes (e.g. paging, options, lists).
local IndexChangeSubjectMixin_mt = Class(IndexChangeSubjectMixin, GuiMixin)


---
function IndexChangeSubjectMixin.new()
    local self = GuiMixin.new(IndexableElementMixin_mt, IndexChangeSubjectMixin)
    self.callbacks = {} -- {observer=callback}

    return self
end


---See GuiMixin:addTo()
function IndexChangeSubjectMixin:addTo(guiElement)
    if IndexChangeSubjectMixin:superClass().addTo(self, guiElement) then
        guiElement.addIndexChangeObserver = IndexChangeSubjectMixin.addIndexChangeObserver
        guiElement.notifyIndexChange = IndexChangeSubjectMixin.notifyIndexChange

        return true
    else
        return false
    end
end


---Add an index change observer with a callback.
-- @param guiElement Decorated GuiElement instance which has received this method
-- @param observer Observer object instance
-- @param indexChangeCallback Function(observer, index, count), where index is the new index and count the current number of indexable items
function IndexChangeSubjectMixin.addIndexChangeObserver(guiElement, observer, indexChangeCallback)
    guiElement[IndexChangeSubjectMixin].callbacks[observer] = indexChangeCallback
end


---Notify observers of an index change.
-- @param guiElement Decorated GuiElement instance which has received this method
-- @param index New index
-- @param count Indexable item count
function IndexChangeSubjectMixin.notifyIndexChange(guiElement, index, count)
    local callbacks = guiElement[IndexChangeSubjectMixin].callbacks

    for observer, callback in pairs(callbacks) do
        callback(observer, index, count)
    end
end


---Clone this mixin's state from a source to a destination GuiElement instance.
function IndexChangeSubjectMixin:clone(srcGuiElement, dstGuiElement)
    if srcGuiElement[IndexChangeSubjectMixin].callbacks ~= nil then
        dstGuiElement[IndexChangeSubjectMixin].callbacks = table.clone(srcGuiElement[IndexChangeSubjectMixin].callbacks)
    end
end
