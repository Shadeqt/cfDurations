-- Shows the single highest-priority CC on a unit's portrait (player/target/pet/party) as a
-- masked icon with a cooldown swipe. LOGIC ONLY — the spellId->type data lives in Data.lua,
-- and the C_LossOfControl discovery logger lives in Discovery.lua (this file never reads cloc).
--
-- Every unit uses the SAME path: aura-scan UnitAura against addon.CCType, keep the highest-
-- priority hit, paint it (or hide). Detection is by spellId — there is no Classic API that flags
-- an aura as CC. Durations for foreign-cast auras come from LibClassicDurations (addon.Lib),
-- since raw UnitAura reports 0 for them. HideCooldownNumbers.lua hides countdown text everywhere;
-- the overlay opts back in via overlay.cfKeepNumbers so the swirl shows a timer. CCType is in Data.lua
-- (fed by the discovery ledger); a unit with no matching aura simply shows nothing.
--
-- Layering: the overlay is parented to the portrait's parent at EQUAL frame level (not +N),
-- and the portrait is pushed to BACKGROUND. That keeps the icon above the portrait but below
-- the unit frame's texture frame (border/name/level text), so the level text stays on top --
-- matching BigDebuffs. Floating the frame level higher would cover the level text.

local _, addon = ...

local Lib = addon.Lib
local CCType = addon.CCType
local CCPriority = addon.CCPriority
local UnitAura = UnitAura
local SetPortraitToTexture = SetPortraitToTexture
local MAX_AURAS = addon.MAX_AURAS

-- unit token -> overlay cooldown frame
local overlays = {}

-- Create: a reverse cooldown sized to the portrait, masked to its round shape, with an icon
-- texture above it. Parented to the portrait's parent at equal frame level (see header).
local function CreatePortraitOverlay(portrait)
    local parent = portrait:GetParent()

    local overlay = addon.CreateSwirl(parent)
    overlay.cfKeepNumbers = true  -- opt back into countdown text (HideCooldownNumbers.lua hides it everywhere else)
    overlay:ClearAllPoints()
    overlay:SetAllPoints(portrait)
    overlay:SetFrameLevel(parent:GetFrameLevel())
    overlay:SetDrawEdge(false)
    overlay:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")

    portrait:SetDrawLayer("BACKGROUND", 0)

    local texture = overlay:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(portrait)
    overlay.texture = texture

    overlay:Hide()
    return overlay
end

-- Scan the unit's harmful auras for the highest-priority CC (ties to longest remaining) and return
-- its icon/start/duration, or nil if there's none. CC only ever lands as a harmful aura, so HELPFUL
-- is not scanned. Tracks the best in locals; nothing is allocated on the hot path.
local function FindBestCC(unit)
    local bestPriority, bestRemaining = 0, 0
    local bestIcon, bestStart, bestDuration
    for index = 1, MAX_AURAS do
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
    end
    return bestIcon, bestStart, bestDuration
end

-- Pick the top CC on the unit and paint it, or hide the overlay if none.
local function Render(unit)
    local overlay = overlays[unit]
    if not overlay then return end

    local icon, start, duration = FindBestCC(unit)

    if icon then
        SetPortraitToTexture(overlay.texture, icon)
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

-- assembly: one overlay per portrait that exists at load (base-UI frames; party frames exist
-- hidden). Every unit then renders through the same path on its aura updates.
local function AddOverlay(unit, portrait)
    if portrait then
        overlays[unit] = CreatePortraitOverlay(portrait)
    end
end

AddOverlay("player", PlayerPortrait)        -- NB: Blizzard names these inconsistently --
AddOverlay("target", TargetFramePortrait)   -- player/pet are PlayerPortrait/PetPortrait,
AddOverlay("pet", PetPortrait)              -- target/party are <Frame>Portrait
for index = 1, MAX_PARTY_MEMBERS do
    AddOverlay("party" .. index, _G["PartyMemberFrame" .. index .. "Portrait"])
end

local function RenderAll()
    for unit in pairs(overlays) do
        Render(unit)
    end
end

-- UNIT_AURA carries the affected unit, so a keyed dispatch covers player/pet/party directly.
-- Target needs PLAYER_TARGET_CHANGED (the new target's auras don't fire UNIT_AURA on switch);
-- pet needs UNIT_PET; party membership changes and initial state re-render everything.
local events = CreateFrame("Frame")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_PET")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        if overlays[unit] then Render(unit) end
    elseif event == "PLAYER_TARGET_CHANGED" then
        Render("target")
    elseif event == "UNIT_PET" then
        Render("pet")
    else
        RenderAll()
    end
end)
