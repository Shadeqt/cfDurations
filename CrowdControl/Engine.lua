-- Shared engine for every crowd-control view (portrait / center / nameplate). LOGIC ONLY -- the
-- spellId->type data lives in Data*.lua and the discovery loggers in Discovery.lua/DebuffDiscovery.lua.
--
-- Every view uses the SAME path: aura-scan UnitAura against addon.CCType, keep the highest-priority hit
-- (ties to longest remaining), and paint a per-view overlay (or hide). Detection is by spellId -- there
-- is no Classic API that flags an aura as CC. Durations for foreign-cast auras come from
-- LibClassicDurations (addon.Lib), since raw UnitAura reports 0 for them.
--
-- Two overlay shapes share the paint path. The portrait overlay is a round mask + SetPortraitToTexture;
-- the center/nameplate overlays are plain square icons + SetTexture. The ONLY per-view difference is the
-- texture setter, captured once per overlay as overlay.applyIcon -- so RenderOverlay is identical for all.

local _, addon = ...

local Lib = addon.Lib
local CCType = addon.CCType
local CCPriority = addon.CCPriority
local UnitAura = UnitAura
local SetPortraitToTexture = SetPortraitToTexture

-- Scan the unit's harmful auras for the highest-priority CC (ties to longest remaining) and return
-- its icon/start/duration, or nil if there's none. CC only ever lands as a harmful aura, so HELPFUL
-- is not scanned. Tracks the best in locals; nothing is allocated on the hot path.
--
-- Bound-free scan: the WoW Classic 20th Anniversary realms removed the buff/debuff limit, so there is
-- no fixed cap on a unit's debuffs (a heavily-focused boss can hold well past the old 40). A fixed
-- ceiling (40, or worse DEBUFF_MAX_DISPLAY=16) would silently miss CC in higher slots, so scan until
-- the first empty index -- correct whether the cap is 16, 40, or gone.
function addon.FindBestCC(unit)
    local bestPriority, bestRemaining = 0, 0
    local bestIcon, bestStart, bestDuration
    local index = 1
    while true do
        local name, icon, _, _, duration, expiration, caster, _, _, spellId = UnitAura(unit, index, "HARMFUL")
        if not name then break end
        local ccType = spellId and CCType[spellId]
        if ccType then
            if not duration or duration == 0 then
                local libDuration, libExpiration = Lib:GetAuraDurationByUnit(unit, spellId, caster)
                if libDuration then
                    duration, expiration = libDuration, libExpiration
                end
            end
            local priority = CCPriority[ccType]
            local remaining = addon.RemainingFrom(duration, expiration)
            if priority > bestPriority or (priority == bestPriority and remaining > bestRemaining) then
                bestPriority = priority
                bestRemaining = remaining
                bestIcon = icon
                bestDuration = duration
                bestStart = (duration and duration > 0 and expiration) and (expiration - duration) or nil
            end
        end
        index = index + 1
    end
    return bestIcon, bestStart, bestDuration
end

-- Portrait overlay: a reverse cooldown sized to the portrait, masked to its round shape, with an icon
-- texture above it. Parented to the portrait's parent at EQUAL frame level (not +N), and the portrait
-- is pushed to BACKGROUND. That keeps the icon above the portrait but below the unit frame's texture
-- frame (border/name/level text), so the level text stays on top -- matching BigDebuffs. Floating the
-- frame level higher would cover the level text.
function addon.CreatePortraitOverlay(portrait)
    local parent = portrait:GetParent()

    local overlay = addon.CreateSwirl(parent)
    overlay.cfKeepNumbers = true  -- opt back into countdown text (HideCooldownNumbers.lua hides it everywhere else)
    overlay:ClearAllPoints()
    overlay:SetAllPoints(portrait)
    overlay:SetFrameLevel(parent:GetFrameLevel())
    overlay:SetDrawEdge(false)
    overlay:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
    overlay:SetSwipeColor(0, 0, 0, 0.8)  -- the mask swipe texture has no dark art of its own; tint it

    portrait:SetDrawLayer("BACKGROUND", 0)

    -- BACKGROUND, not ARTWORK: the cooldown swipe draws above the frame's BACKGROUND layer but the
    -- opaque icon at ARTWORK was covering it (proven via debug: SetCooldown ran, frame shown, yet no
    -- visible swirl). Dropping the icon below the swipe layer lets the sweep show over it.
    local texture = overlay:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(portrait)
    overlay.texture = texture
    overlay.applyIcon = function(icon) SetPortraitToTexture(texture, icon) end

    overlay:Hide()
    return overlay
end

-- Square icon overlay shared by the center + nameplate views: a reverse cooldown sized size x size with
-- a plain icon texture trimmed of its border. cfKeepNumbers opts the timer text back in past
-- HideCooldownNumbers.lua. Anchoring is the caller's job (center -> UIParent, nameplate -> the plate).
function addon.CreateIconOverlay(parent, size)
    local overlay = addon.CreateSwirl(parent)
    overlay.cfKeepNumbers = true
    overlay:ClearAllPoints()
    overlay:SetSize(size, size)
    overlay:SetDrawEdge(false)

    local texture = overlay:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(overlay)
    texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)  -- trim the stock icon border
    overlay.texture = texture
    overlay.applyIcon = function(icon) texture:SetTexture(icon) end

    overlay:Hide()
    return overlay
end

-- Pick the top CC on the unit and paint it onto the overlay, or hide it if none. Shared by all views;
-- the round-vs-square texture difference lives entirely in overlay.applyIcon.
function addon.RenderOverlay(overlay, unit)
    if not overlay then return end

    local icon, start, duration = addon.FindBestCC(unit)

    if icon then
        overlay.applyIcon(icon)
        if start and duration and duration > 0 then
            overlay:SetCooldown(start, duration)
        else
            overlay:Clear() -- known CC, unknown/permanent duration: show icon, no swipe
        end
        overlay:Show()
    else
        overlay:Hide()
    end
end
