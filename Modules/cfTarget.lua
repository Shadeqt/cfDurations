-- cfDurations Target Module: Handles TargetFrame cooldowns
local addon = cfDurations
local applyCooldown = addon.ApplyCooldown

-- Localize for performance
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local _G = _G

-- Cached cooldown frame references: maps index to cooldown frame widget (lazy initialized)
local cachedBuffCooldownFrames = {}
local cachedDebuffCooldownFrames = {}

-- Update TargetFrame buffs/debuffs
local function UpdateTargetFrame(self)
    if not self.unit then return end

    for buffIndex = 1, MAX_TARGET_BUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(self.unit, buffIndex)
        if not name then break end

        local cooldownFrame = cachedBuffCooldownFrames[buffIndex]
        if not cooldownFrame then
            cooldownFrame = _G["TargetFrameBuff" .. buffIndex .. "Cooldown"]
            cachedBuffCooldownFrames[buffIndex] = cooldownFrame
        end

        applyCooldown(cooldownFrame, self.unit, spellId, caster, duration, expirationTime)
    end

    for debuffIndex = 1, MAX_TARGET_DEBUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitDebuff(self.unit, debuffIndex)
        if not name then break end

        local cooldownFrame = cachedDebuffCooldownFrames[debuffIndex]
        if not cooldownFrame then
            cooldownFrame = _G["TargetFrameDebuff" .. debuffIndex .. "Cooldown"]
            cachedDebuffCooldownFrames[debuffIndex] = cooldownFrame
        end

        applyCooldown(cooldownFrame, self.unit, spellId, caster, duration, expirationTime)
    end
end

-- Hook into Blizzard's TargetFrame update function
hooksecurefunc("TargetFrame_UpdateAuras", UpdateTargetFrame)
