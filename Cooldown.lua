-- cfDurations Cooldown: Cooldown frame interception

-- Shared dependencies
local cfDurations = cfDurations
local clearTimer = cfDurations.clearTimer
local incrementTimerId = cfDurations.incrementTimerId
local startTimer = cfDurations.startTimer

-- Module constants
local SAFETY_MARGIN = 0.05
local MIN_FRAME_SIZE = 17 + SAFETY_MARGIN -- 17.05, minimum frame size to display timers
local MIN_COOLDOWN_GCD = 1.5 + SAFETY_MARGIN -- 1.55, minimum duration to display (filters GCD)

-- Module states
local LibClassicDurations = LibStub("LibClassicDurations")
LibClassicDurations:Register("cfDurations")
cfDurations.LibClassicDurations = LibClassicDurations

-- Metatable hook: Intercepts ALL cooldown frames automatically
local cooldownFrameMetatable = getmetatable(ActionButton1Cooldown).__index
if cooldownFrameMetatable and cooldownFrameMetatable.SetCooldown then
    local originalSetCooldown = cooldownFrameMetatable.SetCooldown

    cooldownFrameMetatable.SetCooldown = function(cooldownFrame, startTime, duration)
        originalSetCooldown(cooldownFrame, startTime, duration)

        local currentTimerId = incrementTimerId(cooldownFrame)

        -- Don't create timers for tiny frames or short durations
        if cooldownFrame:GetWidth() < MIN_FRAME_SIZE or startTime <= 0 or duration <= MIN_COOLDOWN_GCD then
            clearTimer(cooldownFrame)
            return
        end

        startTimer(cooldownFrame, startTime, duration, currentTimerId)
    end
end
