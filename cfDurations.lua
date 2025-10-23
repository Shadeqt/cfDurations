-- cfDurations Core: Initialization and shared utilities
cfDurations = {}
local addon = cfDurations

local ADDON_NAME = "cfDurations"

-- Initialize LibClassicDurations
local LibClassicDurations = LibStub("LibClassicDurations", true)
if not LibClassicDurations then
    print(ADDON_NAME .. ": ERROR - LibClassicDurations not found!")
    return
end

LibClassicDurations:Register(ADDON_NAME)

-- Store library reference
addon.LibClassicDurations = LibClassicDurations

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
