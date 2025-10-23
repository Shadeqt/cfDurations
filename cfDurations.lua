-- cfDurations: Shows cooldown swipes on buffs/debuffs

local LibClassicDurations = LibStub("LibClassicDurations", true)
if not LibClassicDurations then return end

LibClassicDurations:Register("cfDurations")

-- Helper function to apply cooldown with LibClassicDurations fallback
local function ApplyCooldown(cooldown, unit, spellId, caster, duration, expirationTime)
    if not cooldown then return end

    local d, e = LibClassicDurations:GetAuraDurationByUnit(unit, spellId, caster)
    if duration == 0 and d then
        duration, expirationTime = d, e
    end

    if expirationTime and expirationTime > 0 then
        CooldownFrame_Set(cooldown, expirationTime - duration, duration, duration > 0, true)
    else
        CooldownFrame_Clear(cooldown)
    end
end

-- Update TargetFrame buffs/debuffs
local function UpdateTargetFrame(self)
    if not self.unit then return end

    -- Buffs
    for i = 1, MAX_TARGET_BUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(self.unit, i)
        if not name then break end
        local cooldown = _G[self:GetName() .. "Buff" .. i .. "Cooldown"]
        ApplyCooldown(cooldown, self.unit, spellId, caster, duration, expirationTime)
    end

    -- Debuffs
    for i = 1, MAX_TARGET_DEBUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitDebuff(self.unit, i)
        if not name then break end
        local cooldown = _G[self:GetName() .. "Debuff" .. i .. "Cooldown"]
        ApplyCooldown(cooldown, self.unit, spellId, caster, duration, expirationTime)
    end
end

-- Update CompactUnitFrame buff
local function UpdateCompactBuff(buffFrame, unit, index, filter)
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(unit, index, filter)
    if name then
        ApplyCooldown(buffFrame.cooldown, unit, spellId, caster, duration, expirationTime)
    end
end

-- Update CompactUnitFrame debuff
local function UpdateCompactDebuff(debuffFrame, unit, index, filter)
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitDebuff(unit, index, filter)
    if name then
        ApplyCooldown(debuffFrame.cooldown, unit, spellId, caster, duration, expirationTime)
    end
end

-- Hook into Blizzard functions
hooksecurefunc("TargetFrame_UpdateAuras", UpdateTargetFrame)
hooksecurefunc("CompactUnitFrame_UtilSetBuff", UpdateCompactBuff)
hooksecurefunc("CompactUnitFrame_UtilSetDebuff", UpdateCompactDebuff)
