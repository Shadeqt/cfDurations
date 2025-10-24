-- cfDurations Target Module: Handles TargetFrame cooldowns
local addon = cfDurations
local applyCooldown = addon.ApplyCooldown

-- Localize for performance
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local _G = _G

-- Cache cooldown frame references (lazy initialization)
local buffCooldowns = {}
local debuffCooldowns = {}

-- Update TargetFrame buffs/debuffs
local function UpdateTargetFrame(self)
    if not self.unit then return end

    -- Buffs
    for i = 1, MAX_TARGET_BUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(self.unit, i)
        if not name then break end

        -- Lazy cache: look up and cache on first access
        local cooldown = buffCooldowns[i]
        if not cooldown then
            cooldown = _G["TargetFrameBuff" .. i .. "Cooldown"]
            buffCooldowns[i] = cooldown
        end

        applyCooldown(cooldown, self.unit, spellId, caster, duration, expirationTime)
    end

    -- Debuffs
    for i = 1, MAX_TARGET_DEBUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitDebuff(self.unit, i)
        if not name then break end

        -- Lazy cache: look up and cache on first access
        local cooldown = debuffCooldowns[i]
        if not cooldown then
            cooldown = _G["TargetFrameDebuff" .. i .. "Cooldown"]
            debuffCooldowns[i] = cooldown
        end

        applyCooldown(cooldown, self.unit, spellId, caster, duration, expirationTime)
    end
end

-- Hook into Blizzard's TargetFrame update function
hooksecurefunc("TargetFrame_UpdateAuras", UpdateTargetFrame)
