-- cfDurationsFresh Core: Minimal duration tracking with LibClassicDurations

local LibClassicDurations = LibStub("LibClassicDurations")
LibClassicDurations:Register("cfDurationsFresh")

-- Metatable hook: Intercepts ALL cooldown frames automatically
local cooldownMetatable = getmetatable(ActionButton1Cooldown).__index
if cooldownMetatable and cooldownMetatable.SetCooldown then
    local originalSetCooldown = cooldownMetatable.SetCooldown

    cooldownMetatable.SetCooldown = function(cooldownFrame, startTime, duration)
        -- Call original SetCooldown
        originalSetCooldown(cooldownFrame, startTime, duration)

        -- Enable Blizzard's countdown numbers for all cooldowns
        if startTime > 0 and duration > 0 then
            cooldownFrame:SetHideCountdownNumbers(false)
        end
    end
end
