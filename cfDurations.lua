cfDurations = {}
local addon = cfDurations

local LibClassicDurations = LibStub("LibClassicDurations")
LibClassicDurations:Register("cfDurations")

-- Shared helper function to apply cooldown with LibClassicDurations fallback
function addon.ApplyCooldown(cooldown, unit, spellId, caster, duration, expirationTime)
    if not cooldown then return end

    local d, e = LibClassicDurations:GetAuraDurationByUnit(unit, spellId, caster)
    if duration == 0 and d then
        duration, expirationTime = d, e
    end

    if expirationTime and expirationTime > 0 then
        cooldown:SetCooldown(expirationTime - duration, duration)
    else
        cooldown:SetCooldown(0, 0)
    end
end
