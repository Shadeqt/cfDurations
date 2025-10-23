-- cfDurations Compact Module: Handles Party/Raid/Arena frame cooldowns
local addon = cfDurations

-- Update CompactUnitFrame buff
local function UpdateCompactBuff(buffFrame, unit, index, filter)
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(unit, index, filter)
    if name then
        addon.ApplyCooldown(buffFrame.cooldown, unit, spellId, caster, duration, expirationTime)
    end
end

-- Update CompactUnitFrame debuff
local function UpdateCompactDebuff(debuffFrame, unit, index, filter)
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitDebuff(unit, index, filter)
    if name then
        addon.ApplyCooldown(debuffFrame.cooldown, unit, spellId, caster, duration, expirationTime)
    end
end

-- Hook into Blizzard's CompactUnitFrame functions
hooksecurefunc("CompactUnitFrame_UtilSetBuff", UpdateCompactBuff)
hooksecurefunc("CompactUnitFrame_UtilSetDebuff", UpdateCompactDebuff)
