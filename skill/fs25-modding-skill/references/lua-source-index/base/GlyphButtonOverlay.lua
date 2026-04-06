









---Gamepad button display overlay.
local GlyphButtonOverlay_mt = Class(GlyphButtonOverlay, ButtonOverlay)


---
function GlyphButtonOverlay.new(customMt)
    local self = ButtonOverlay.new(GlyphButtonOverlay_mt)

    return self
end
