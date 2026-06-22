-- CC icon above enemy nameplates: the same highest-priority crowd-control shown on the portrait/center,
-- anchored over each hostile unit's nameplate. Enemy-only (UnitCanAttack). Uses the shared
-- addon.FindBestCC via RenderOverlay, so priority/tie-break match the other views by construction.
--
-- Pooled per unit token, mirroring cfCastbars/Features/Nameplate.lua: nameplate frames are recycled, so
-- an overlay is reused across occupants of the same token and re-parented + re-anchored to the live
-- plate on each attach. No runtime dependency on cfCastbars -- this only calls Blizzard C_NamePlate.

local _, addon = ...

local SIZE = 32

-- unit token (nameplateN) -> overlay; reused as the plate frame recycles.
local overlays = {}

-- Re-render a token's overlay (UNIT_AURA). Returns early for non-nameplate tokens (no pooled overlay)
-- and hides the icon if the token's unit is no longer hostile.
local function Render(unit)
    local overlay = overlays[unit]
    if not overlay then return end
    if not UnitCanAttack("player", unit) then
        overlay:Hide()
        return
    end
    addon.RenderOverlay(overlay, unit)
end

-- Attach (or reattach) an overlay to the live plate for `unit` and paint it. Enemy-only: a friendly or
-- neutral occupant hides any pooled overlay and bails.
local function Attach(unit)
    if not UnitCanAttack("player", unit) then
        if overlays[unit] then overlays[unit]:Hide() end
        return
    end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end

    local overlay = overlays[unit]
    if overlay then
        overlay:SetParent(plate.UnitFrame)  -- recycled plate: re-point at the live frame
    else
        overlay = addon.CreateIconOverlay(plate.UnitFrame, SIZE)
        overlays[unit] = overlay
    end
    overlay:ClearAllPoints()
    overlay:SetPoint("BOTTOM", plate.UnitFrame.healthBar, "TOP", 0, 6)
    addon.RenderOverlay(overlay, unit)
end

local f = CreateFrame("Frame")
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_AURA")
f:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        Render(unit)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        Attach(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        -- Hide AND keep pooled: the plate is about to be recycled for another unit; a frozen icon
        -- would flash onto its frame until the next render.
        if overlays[unit] then overlays[unit]:Hide() end
    else -- PLAYER_ENTERING_WORLD: attach to plates already up
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            Attach(plate.namePlateUnitToken)
        end
    end
end)
