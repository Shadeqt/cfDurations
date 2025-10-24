-- cfDurations Compact Module: Handles Party/Raid/Arena frame cooldowns
local addon = cfDurations
local applyCooldown = addon.ApplyCooldown

-- Lua built-ins
local hooksecurefunc = hooksecurefunc

-- WoW API calls
local _UnitBuff = UnitBuff
local _UnitDebuff = UnitDebuff

-- Update CompactUnitFrame buff
local function updateCompactBuff(buffFrame, unitId, buffIndex, filter)
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = _UnitBuff(unitId, buffIndex, filter)
    if name then
        applyCooldown(buffFrame.cooldown, unitId, spellId, caster, duration, expirationTime)
    end
end

-- Update CompactUnitFrame debuff
local function updateCompactDebuff(debuffFrame, unitId, debuffIndex, filter)
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = _UnitDebuff(unitId, debuffIndex, filter)
    if name then
        applyCooldown(debuffFrame.cooldown, unitId, spellId, caster, duration, expirationTime)
    end
end

-- Hook into Blizzard's CompactUnitFrame functions
hooksecurefunc("CompactUnitFrame_UtilSetBuff", updateCompactBuff)
hooksecurefunc("CompactUnitFrame_UtilSetDebuff", updateCompactDebuff)
