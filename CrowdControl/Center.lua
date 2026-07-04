-- Center-of-screen CC icon: shows the SAME crowd-control the player portrait shows, in the middle of
-- the screen. It's just another view of the "player" unit -- it calls the shared addon.FindBestCC via
-- RenderOverlay, so priority and tie-break are identical to the portrait by construction (no separate
-- logic to keep in sync). 32x32, 100px below center to clear the reticle. Carries the dispel-type
-- border from CreateIconOverlay (like the nameplate icon). Gated by cfDurationsDB.CCCenter.

local _, addon = ...

-- Positioned 100px below center to sit clear of the crosshair and other center-screen UI.
local SIZE = 32
local Y_OFFSET = -100

function addon.SetupCCCenter()
    if not cfDurationsDB.CCCenter then return end

    local center = addon.CreateIconOverlay(UIParent, SIZE)
    center:SetPoint("CENTER", UIParent, "CENTER", 0, Y_OFFSET)
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
    addon.RenderOverlay(center, "player")  -- seed now (we're already past the first PEW)
end
