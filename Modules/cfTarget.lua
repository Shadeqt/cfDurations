-- cfDurations Target Module: Handles TargetFrame cooldowns
local addon = cfDurations

-- Update TargetFrame buffs/debuffs
local function UpdateTargetFrame(self)
    if not self.unit then return end

    -- Buffs
    for i = 1, MAX_TARGET_BUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(self.unit, i)
        if not name then break end
        local cooldown = _G[self:GetName() .. "Buff" .. i .. "Cooldown"]
        addon.ApplyCooldown(cooldown, self.unit, spellId, caster, duration, expirationTime)
    end

    -- Debuffs
    for i = 1, MAX_TARGET_DEBUFFS do
        local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitDebuff(self.unit, i)
        if not name then break end
        local cooldown = _G[self:GetName() .. "Debuff" .. i .. "Cooldown"]
        addon.ApplyCooldown(cooldown, self.unit, spellId, caster, duration, expirationTime)
    end
end

-- Hook into Blizzard's TargetFrame update function
hooksecurefunc("TargetFrame_UpdateAuras", UpdateTargetFrame)
