











---Display a platform icon, depending on current and set platform.
local PlatformIconElement_mt = Class(PlatformIconElement, BitmapElement)




---
function PlatformIconElement.new(target, custom_mt)
    local self = PlatformIconElement:superClass().new(target, custom_mt or PlatformIconElement_mt)

    return self
end


---
function PlatformIconElement:delete()
    PlatformIconElement:superClass().delete(self)
end


---
function PlatformIconElement:copyAttributes(src)
    PlatformIconElement:superClass().copyAttributes(self, src)

    self.platformId = src.platformId
end


---Set the terrain layer to render
function PlatformIconElement:setPlatformId(platformId)
    local useOtherIcon = false

    -- On some platforms we can only show the icon for the same platform
    if GS_PLATFORM_ID == PlatformId.PS5 and platformId ~= PlatformId.PS5 then
        useOtherIcon = true
    elseif GS_PLATFORM_ID == PlatformId.XBOX_SERIES and platformId ~= PlatformId.XBOX_SERIES then
        useOtherIcon = true
    elseif GS_IS_MSSTORE_VERSION and (platformId ~= PlatformId.XBOX_SERIES and platformId ~= PlatformId.WIN) then
        useOtherIcon = true
    end

    if useOtherIcon then
        platformId = 0
    end

    if not PlatformIconElement.ALLOW_COLOR_CHANGE[platformId] then
        self.colorSelectedBackup = self.overlay.colorSelected
        self.overlay.colorSelected = self.overlay.color
    else
        if self.colorSelectedBackup ~= nil then
            self.overlay.colorSelected = self.colorSelectedBackup
            self.colorSelectedBackup = nil
        end
    end

    self:setImageSlice(nil, PlatformIconElement.SLICES[platformId])
end
