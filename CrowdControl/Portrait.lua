-- Shows the single highest-priority CC on a unit's portrait (player/target/pet/party/targettarget) as a
-- masked icon with a cooldown swipe. The shared finder + overlay factory + paint path live in Engine.lua;
-- this file owns only the portrait view: one overlay per portrait that exists at load, and the event
-- wiring that re-renders it. Most units render off UNIT_AURA; targettarget is the exception (see below) --
-- it's a virtual unit with no aura events, so it rides Blizzard's throttled TargetofTarget_Update hook.
--
-- Layering note (lives with this view; the factory is in Engine.lua): the overlay is parented to the
-- portrait's parent at EQUAL frame level, and the portrait is pushed to BACKGROUND. That keeps the icon
-- above the portrait but below the unit frame's texture frame (border/name/level text) -- matching
-- BigDebuffs. Floating the frame level higher would cover the level text.

local _, addon = ...

-- unit token -> overlay cooldown frame
local overlays = {}

local function Render(unit)
    addon.RenderOverlay(overlays[unit], unit)
end

-- assembly: one overlay per portrait that exists at load (base-UI frames; party frames exist
-- hidden). Every unit then renders through the same path on its aura updates.
local function AddOverlay(unit, portrait)
    if portrait then
        overlays[unit] = addon.CreatePortraitOverlay(portrait)
    end
end

local function RenderAll()
    for unit in pairs(overlays) do
        Render(unit)
    end
end

function addon.SetupCCPortrait()
    if not cfDurationsDB.CCPortrait then return end

    AddOverlay("player", PlayerPortrait)        -- NB: Blizzard names these inconsistently --
    AddOverlay("target", TargetFramePortrait)   -- player/pet are PlayerPortrait/PetPortrait,
    AddOverlay("pet", PetPortrait)              -- target/party are <Frame>Portrait
    AddOverlay("targettarget", TargetFrameToTPortrait)  -- target-of-target mini-portrait (trigger differs, below)
    for index = 1, MAX_PARTY_MEMBERS do
        AddOverlay("party" .. index, _G["PartyMemberFrame" .. index .. "Portrait"])
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

    -- "targettarget" is a virtual unit: no UNIT_AURA, and Blizzard only refreshes the ToT from a per-frame
    -- OnUpdate, so there's no event to hook here without running every frame. BuffSwirls already derives the
    -- ToT triggers (PLAYER_TARGET_CHANGED / UNIT_TARGET / PLAYER_ENTERING_WORLD) and exposes
    -- addon.totListeners (driven by target/ToT-change + UNIT_AURA-on-the-ToT); subscribe to it instead of
    -- re-deriving them. The main-target portrait still snaps via PLAYER_TARGET_CHANGED above; the ToT
    -- portrait rides this shared dispatch.
    if addon.totListeners then
        table.insert(addon.totListeners, function() Render("targettarget") end)
    end

    RenderAll()  -- seed now (we're already past the first PEW)
end
