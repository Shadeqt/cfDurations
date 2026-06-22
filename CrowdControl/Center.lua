-- Center-of-screen CC icon: shows the SAME crowd-control the player portrait shows, in the middle of
-- the screen. It's just another view of the "player" unit -- it calls the shared addon.FindBestCC via
-- RenderOverlay, so priority and tie-break are identical to the portrait by construction (no separate
-- logic to keep in sync). 64x64 maps 1:1 to native icon texels; slightly below center to clear the
-- reticle. Always on, no settings -- matching the portrait view.

local _, addon = ...

local center = addon.CreateIconOverlay(UIParent, 64)
center:SetPoint("CENTER", UIParent, "CENTER", 0, -27)
center:SetFrameStrata("HIGH")

-- UNIT_AURA carries the affected unit; we only care about the player. PLAYER_ENTERING_WORLD seeds the
-- initial state (e.g. /reload while CC'd). UNIT_AURA is a plain RegisterEvent + gate, not
-- RegisterUnitEvent (consistent with the other views).
local events = CreateFrame("Frame")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    addon.RenderOverlay(center, "player")
end)
