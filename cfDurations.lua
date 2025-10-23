cfDurations = {}
local addon = cfDurations

local LibClassicDurations = LibStub("LibClassicDurations")
LibClassicDurations:Register("cfDurations")

-- Localize for performance
local CooldownFrame_Set = CooldownFrame_Set
local CooldownFrame_Clear = CooldownFrame_Clear

-- Shared helper function to apply cooldown with LibClassicDurations fallback
function addon.ApplyCooldown(cooldown, unit, spellId, caster, duration, expirationTime)
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
