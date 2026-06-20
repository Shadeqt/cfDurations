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

-- Force-refresh every surface we paint. Called by BuffTimers /cfd toggle so the
-- newly-enabled countdown text appears immediately rather than waiting for natural
-- aura events.
addon.RefreshAll = function()
    if TargetFrame and TargetFrame.unit then UpdateTargetAuras(TargetFrame) end
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

local petFrame = CreateFrame("Frame")
petFrame:RegisterUnitEvent("UNIT_AURA", "pet")
petFrame:RegisterEvent("UNIT_PET")
petFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
petFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_PET" and unit ~= "player" then return end
    UpdatePetBuffs()
end)
