-- Cooldown swirls on other units' buffs and debuffs (target, compact raid, pet).
-- UnitAura returns no duration/expiration for non-player units in Classic, so we
-- ask LibClassicDurations for the spellID-based estimate it tracks via combat log.
-- Exposes addon.listeners and addon.RefreshAll so BuffTimers can opt into the
-- countdown-text feature without touching this file.

local _, addon = ...

addon.listeners = {}

local Lib = addon.Lib

-- Paint the swirl (via the shared Core primitive), then notify listeners so
-- BuffTimers can draw its optional countdown text on the same frame.
local function ApplyCooldown(cooldown, duration, expirationTime)
    addon.ApplyCooldown(cooldown, duration, expirationTime)
    for _, fn in ipairs(addon.listeners) do
        fn(cooldown, duration, expirationTime)
    end
end

local function UpdateAuraSlots(unit, filter, max, prefix)
    for i = 1, max do
        local _, _, _, _, duration, expirationTime = Lib.UnitAuraWrapper(unit, i, filter)
        if not duration then break end
        local cooldown = _G[prefix .. i .. "Cooldown"]
        if cooldown then
            ApplyCooldown(cooldown, duration, expirationTime)
        end
    end
end

local function UpdateTargetAuras(frame)
    local unit = frame.unit
    if not unit then return end
    UpdateAuraSlots(unit, "HELPFUL", MAX_TARGET_BUFFS, "TargetFrameBuff")
    UpdateAuraSlots(unit, "HARMFUL", MAX_TARGET_DEBUFFS, "TargetFrameDebuff")
end

-- Target-of-target debuffs. The ToT mini-frame shows up to 4 debuff icons (TargetFrameToTDebuff1..4,
-- each with a sibling <name>Cooldown global) -- the same shape as the main target frame, so the slot
-- loop above is reused as-is. ToT shows debuffs only (no buff buttons exist -- verified), so HELPFUL
-- isn't scanned. Triggering lives below (totEvents) -- "targettarget" has no UNIT_AURA.
local function UpdateToTDebuffs()
    UpdateAuraSlots("targettarget", "HARMFUL", 4, "TargetFrameToTDebuff")
end

local function UpdateCompactBuff(buffFrame, unit, index)
    local _, _, _, _, duration, expirationTime = Lib.UnitAuraWrapper(unit, index, "HELPFUL")
    ApplyCooldown(buffFrame.cooldown, duration, expirationTime)
end

local function UpdatePetBuffs()
    for i = 1, MAX_TARGET_BUFFS do
        local name, _, _, _, duration, expirationTime = Lib.UnitAuraWrapper("pet", i, "HELPFUL")
        if not name then break end
        local buff = _G["PetFrameBuff" .. i]
        if not buff then break end
        ApplyCooldown(addon.GetSwirl(buff), duration, expirationTime)
    end
end

-- Force-refresh every surface we paint. Called by BuffTimers' setup so the
-- newly-enabled countdown text appears immediately rather than waiting for natural
-- aura events.
addon.RefreshAll = function()
    if TargetFrame and TargetFrame.unit then UpdateTargetAuras(TargetFrame) end
    UpdateToTDebuffs()
    UpdatePetBuffs()
    if CompactRaidFrameContainer then
        for _, group in ipairs({ CompactRaidFrameContainer:GetChildren() }) do
            for _, member in ipairs({ group:GetChildren() }) do
                if member.unit and CompactUnitFrame_UpdateAuras then
                    CompactUnitFrame_UpdateAuras(member)
                end
            end
        end
    end
end

hooksecurefunc("TargetFrame_UpdateAuras", UpdateTargetAuras)
hooksecurefunc("CompactUnitFrame_UtilSetBuff", UpdateCompactBuff)

-- ToT refresh dispatch. "targettarget" gets no UNIT_AURA of its own, and Blizzard refreshes the ToT
-- only from a per-frame OnUpdate (TargetofTarget_UpdateDebuffs) -- there is no Blizzard event to hook
-- without running every frame. Drive it from discrete unit events instead -- matching how every other
-- view here triggers; no combat-log parsing:
--   * PLAYER_TARGET_CHANGED -- you picked a new target (new ToT, or none).
--   * UNIT_TARGET("target")  -- your target changed ITS target (the ToT identity changed).
--   * PLAYER_ENTERING_WORLD  -- initial state after login / reload.
--   * UNIT_AURA              -- an aura changed on some unit; repaint only if that unit IS the current
--                               ToT. Catches a debuff landing on an already-shown ToT for any unit the
--                               client tracks (you / party / pet / a nameplate). Plain RegisterEvent,
--                               not RegisterUnitEvent -- the ToT can be any of those tokens.
-- Residual gap (no event exists for it without CLEU/polling): a ToT that's an untracked mob (nameplates
-- off) only repaints on the identity events above. addon.totListeners lets the CrowdControl portrait
-- overlay ride this same dispatch instead of re-deriving the triggers (mirrors addon.listeners above).
addon.totListeners = {}
local function RefreshToT()
    UpdateToTDebuffs()
    for _, fn in ipairs(addon.totListeners) do fn() end
end

local totEvents = CreateFrame("Frame")
totEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
totEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
totEvents:RegisterUnitEvent("UNIT_TARGET", "target")
totEvents:RegisterEvent("UNIT_AURA")
totEvents:SetScript("OnEvent", function(_, event, unit)
    -- gate UNIT_AURA to the ToT's unit; the other events always mean "repaint"
    if event == "UNIT_AURA" and not UnitIsUnit(unit, "targettarget") then return end
    RefreshToT()
end)

local petFrame = CreateFrame("Frame")
petFrame:RegisterUnitEvent("UNIT_AURA", "pet")
petFrame:RegisterEvent("UNIT_PET")
petFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
petFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_PET" and unit ~= "player" then return end
    UpdatePetBuffs()
end)
