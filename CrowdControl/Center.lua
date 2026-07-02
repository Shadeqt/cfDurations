-- Center-of-screen CC icon: shows the SAME crowd-control the player portrait shows, in the middle of
-- the screen. It's just another view of the "player" unit -- it calls the shared addon.FindBestCC via
-- RenderOverlay, so priority and tie-break are identical to the portrait by construction (no separate
-- logic to keep in sync). 32x32, slightly below center to clear the reticle. Carries the dispel-type
-- border from CreateIconOverlay (like the nameplate icon). Always on, no settings.

local _, addon = ...

-- Half the icon's height below center puts its top edge at screen-center -- just under the crosshair,
-- not covering it. Derived from SIZE so it stays correct if the icon is resized.
local SIZE = 32
local center = addon.CreateIconOverlay(UIParent, SIZE)
center:SetPoint("CENTER", UIParent, "CENTER", 0, -SIZE / 2)
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
