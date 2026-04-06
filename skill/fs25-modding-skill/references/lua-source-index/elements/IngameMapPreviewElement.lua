







---
local IngameMapPreviewElement_mt = Class(IngameMapPreviewElement, GuiElement)


















































---
function IngameMapPreviewElement:onClose()
    IngameMapPreviewElement:superClass().onClose(self)
    self.ingameMap:setCustomLayout(nil)
    self.ingameMap.clipHotspots = false
    self.ingameMap:setMapClipArea(nil, nil, nil, nil)
end
