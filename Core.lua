-- Shared helpers for cfDurations. Loaded first (see .toc) so every other file
-- can use addon.Lib, addon.CreateSwirl, and addon.RemainingFrom.

local _, addon = ...

-- LibClassicDurations: classic UnitAura returns no duration/expiration for auras
-- cast by other units, so the lib reconstructs them from the combat log. Shared
-- handle; Register is required once for combat-log tracking to switch on.
addon.Lib = LibStub("LibClassicDurations")
addon.Lib:Register("cfDurations")

-- A reverse cooldown spiral that fills the parent icon.
function addon.CreateSwirl(parent)
    local cooldown = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetReverse(true)
    return cooldown
end

-- Lazily attach (and reuse) a swirl on a frame that has no Blizzard cooldown
-- region of its own -- pet and player buff buttons. Target/compact frames ship
-- their own Cooldown child, so those paths don't use this.
function addon.GetSwirl(frame)
    frame.cfCooldown = frame.cfCooldown or addon.CreateSwirl(frame)
    return frame.cfCooldown
end

-- Drive a swirl from an aura's duration: fill it forward, or clear it when the
-- aura has no finite duration. Single source of truth for the SetCooldown/Clear
-- branch shared by every swirl-painting path.
function addon.ApplyCooldown(cooldown, duration, expirationTime)
    if duration and duration > 0 then
        cooldown:SetCooldown(expirationTime - duration, duration)
    else
        cooldown:Clear()
    end
end

-- Seconds left on an aura, or math.huge when it has no finite duration
-- (permanent auras, or foreign auras the lib can't identify).
function addon.RemainingFrom(duration, expirationTime)
    if not duration or duration == 0 or not expirationTime or expirationTime == 0 then
        return math.huge
    end
    return expirationTime - GetTime()
end
