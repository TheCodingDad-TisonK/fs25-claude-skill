









---Play UI sound sample mixin.
-- 
-- Add this mixin to a GuiElement to enable it to play UI sounds.
-- 
-- Added methods:
-- GuiElement:setPlaySampleCallback(callback): Set a callback for playing UI sound samples, signature: function(sampleName).
-- GuiElement:playSample(index, count): Called by the decorated GuiElement to play a sound sample using a name from GuiSoundPlayer.SOUND_SAMPLES.
-- GuiElement:disablePlaySample(): Permanently disables playing samples for special cases (i.e. separate sound logic)
local PlaySampleMixin_mt = Class(PlaySampleMixin, GuiMixin)




---
function PlaySampleMixin.new()
    return GuiMixin.new(PlaySampleMixin_mt, PlaySampleMixin)
end


---See GuiMixin:addTo().
function PlaySampleMixin:addTo(guiElement)
    if PlaySampleMixin:superClass().addTo(self, guiElement) then
        guiElement.setPlaySampleCallback = PlaySampleMixin.setPlaySampleCallback
        guiElement.playSample = PlaySampleMixin.playSample
        guiElement.disablePlaySample = PlaySampleMixin.disablePlaySample

        -- make sure an uninitialized call doesn't blow up by assigning an empty function:
        guiElement[PlaySampleMixin].playSampleCallback = NO_CALLBACK

        return true
    else
        return false
    end
end


---Set a callback to play a UI sound sample.
-- @param table guiElement GuiElement instance
-- @param function callback Play sample callback, signature: function(sampleName)
function PlaySampleMixin.setPlaySampleCallback(guiElement, callback)
    guiElement[PlaySampleMixin].playSampleCallback = callback
end


---Request playing a UI sound sample identified by name.
-- @param table guiElement GuiElement instance
-- @param string sampleName Sample name, use one of GuiSoundPlayer.SOUND_SAMPLES.
function PlaySampleMixin.playSample(guiElement, sampleName)
    if not guiElement.soundDisabled then
        guiElement[PlaySampleMixin].playSampleCallback(sampleName)
    end
end


---Permanently disable playing samples on the decorated GuiElement for special cases.
function PlaySampleMixin.disablePlaySample(guiElement)
    guiElement[PlaySampleMixin].playSampleCallback = NO_CALLBACK
end


---Clone this mixin's state from a source to a destination GuiElement instance.
function PlaySampleMixin:clone(srcGuiElement, dstGuiElement)
    dstGuiElement[PlaySampleMixin].playSampleCallback = srcGuiElement[PlaySampleMixin].playSampleCallback
end
