-- cfDurations Target Module: Handles TargetFrame cooldowns
local addon = cfDurations
local applyCooldown = addon.ApplyCooldown

-- Localized API calls
local _UnitBuff = UnitBuff
local _UnitDebuff = UnitDebuff

-- Cached cooldown frame references: maps index to cooldown frame widget (lazy initialized)
local cachedBuffCooldownFrames = {}
local cachedDebuffCooldownFrames = {}

-- Update TargetFrame buffs/debuffs
local function updateTargetFrame(self)
    if not self.unit then return end

    for buffIndex = 1, MAX_TARGET_BUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = _UnitBuff(self.unit, buffIndex)
        if not name then break end

        local cooldownFrame = cachedBuffCooldownFrames[buffIndex]
        if not cooldownFrame then
            cooldownFrame = _G["TargetFrameBuff" .. buffIndex .. "Cooldown"]
            cachedBuffCooldownFrames[buffIndex] = cooldownFrame
        end

        applyCooldown(cooldownFrame, self.unit, spellId, caster, duration, expirationTime)
    end

    for debuffIndex = 1, MAX_TARGET_DEBUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = _UnitDebuff(self.unit, debuffIndex)
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
hooksecurefunc("TargetFrame_UpdateAuras", updateTargetFrame)
