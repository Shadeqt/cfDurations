-- cfDurations Compact Module: Handles Party/Raid/Arena frame cooldowns
local addon = cfDurations
local applyCooldown = addon.ApplyCooldown

-- Localized API calls (ordered by first usage)
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff

-- Update CompactUnitFrame buff
local function UpdateCompactBuff(buffFrame, unitId, buffIndex, filter)
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(unitId, buffIndex, filter)
    if name then
        applyCooldown(buffFrame.cooldown, unitId, spellId, caster, duration, expirationTime)
    end
end

-- Update CompactUnitFrame debuff
local function UpdateCompactDebuff(debuffFrame, unitId, debuffIndex, filter)
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitDebuff(unitId, debuffIndex, filter)
    if name then
        applyCooldown(debuffFrame.cooldown, unitId, spellId, caster, duration, expirationTime)
    end
end

-- Hook into Blizzard's CompactUnitFrame functions
hooksecurefunc("CompactUnitFrame_UtilSetBuff", UpdateCompactBuff)
hooksecurefunc("CompactUnitFrame_UtilSetDebuff", UpdateCompactDebuff)
