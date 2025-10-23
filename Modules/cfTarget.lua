-- cfDurations Target Module: Handles TargetFrame cooldowns
local addon = cfDurations
local applyCooldown = addon.ApplyCooldown

-- Localize for performance
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff

-- Cache cooldown frame references
local buffCooldowns = {}
local debuffCooldowns = {}
for i = 1, MAX_TARGET_BUFFS do
    buffCooldowns[i] = _G["TargetFrameBuff" .. i .. "Cooldown"]
end
for i = 1, MAX_TARGET_DEBUFFS do
    debuffCooldowns[i] = _G["TargetFrameDebuff" .. i .. "Cooldown"]
end

-- Update TargetFrame buffs/debuffs
local function UpdateTargetFrame(self)
    if not self.unit then return end

    -- Buffs
    for i = 1, MAX_TARGET_BUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(self.unit, i)
        if not name then break end
        applyCooldown(buffCooldowns[i], self.unit, spellId, caster, duration, expirationTime)
    end

    -- Debuffs
    for i = 1, MAX_TARGET_DEBUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitDebuff(self.unit, i)
        if not name then break end
        applyCooldown(debuffCooldowns[i], self.unit, spellId, caster, duration, expirationTime)
    end
end

-- Hook into Blizzard's TargetFrame update function
hooksecurefunc("TargetFrame_UpdateAuras", UpdateTargetFrame)
