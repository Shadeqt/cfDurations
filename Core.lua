-- cfDurationsFresh Core: Minimal duration tracking with LibClassicDurations

-- Localize Lua APIs
local _string_format = string.format
local _getmetatable = getmetatable

-- Localize WoW APIs
local _GetTime = GetTime
local _C_Timer_After = C_Timer.After
local _LibStub = LibStub

-- Localize WoW globals
local _ActionButton1Cooldown = ActionButton1Cooldown

local LibClassicDurations = _LibStub("LibClassicDurations")
LibClassicDurations:Register("cfDurationsFresh")

-- Settings (easy to change later)
local TIMER_FONT = "Fonts\\FRIZQT__.TTF"
local TIMER_SIZE = 12
local UPDATE_SAFETY_MARGIN = 0.05  -- Safety margin for timer updates
local MIN_DURATION = 1.5 + UPDATE_SAFETY_MARGIN  -- Minimum duration before timer is shown
local MIN_FRAME_SIZE = 17 + UPDATE_SAFETY_MARGIN  -- Don't show timers on tiny frames

-- Time thresholds for formatting
local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400

-- Cached inverse constants (multiplication is faster than division)
local INV_SECONDS_PER_MINUTE = 1 / SECONDS_PER_MINUTE
local INV_SECONDS_PER_HOUR = 1 / SECONDS_PER_HOUR
local INV_SECONDS_PER_DAY = 1 / SECONDS_PER_DAY

-- Pre-cache common timer display strings (0-59 seconds and minutes)
local cachedTimerStrings = {}
for i = 0, 59 do
    cachedTimerStrings[i] = tostring(i)
    cachedTimerStrings[i + 100] = tostring(i) .. "m"  -- Store minute strings at offset 100
end

-- Format time based on duration
local function formatTime(seconds)
    if seconds < SECONDS_PER_MINUTE then
        local s = seconds - seconds % 1  -- Fast floor for positive numbers
        return cachedTimerStrings[s]
    elseif seconds < SECONDS_PER_HOUR then
        local m = (seconds * INV_SECONDS_PER_MINUTE) - (seconds * INV_SECONDS_PER_MINUTE) % 1
        return cachedTimerStrings[m + 100]
    elseif seconds < SECONDS_PER_DAY then
        return _string_format("%.0fh", seconds * INV_SECONDS_PER_HOUR)  -- "1-23h" hours
    else
        return _string_format("%.0fd", seconds * INV_SECONDS_PER_DAY)  -- "1d+" days
    end
end

-- Calculate delay until next display change
local function calculateNextUpdateDelay(remainingSeconds)
    if remainingSeconds < SECONDS_PER_MINUTE then
        return (remainingSeconds % 1) + UPDATE_SAFETY_MARGIN
    elseif remainingSeconds < SECONDS_PER_HOUR then
        return (remainingSeconds % SECONDS_PER_MINUTE) + UPDATE_SAFETY_MARGIN
    elseif remainingSeconds < SECONDS_PER_DAY then
        return (remainingSeconds % SECONDS_PER_HOUR) + UPDATE_SAFETY_MARGIN
    else
        return (remainingSeconds % SECONDS_PER_DAY) + UPDATE_SAFETY_MARGIN
    end
end

-- Recursive update function
local function updateTimer(cooldownFrame, startTime, duration, timerId)
    -- Check if this timer has been superseded
    if cooldownFrame.cfTimerId ~= timerId then
        return  -- This timer is obsolete, stop running
    end

    local remainingSeconds = startTime + duration - _GetTime()
    if remainingSeconds <= MIN_DURATION then
        cooldownFrame.cfTimer:SetText("")
        return
    end

    cooldownFrame.cfTimer:SetText(formatTime(remainingSeconds))

    -- Schedule next update
    local updateDelay = calculateNextUpdateDelay(remainingSeconds)
    _C_Timer_After(updateDelay, function()
        updateTimer(cooldownFrame, startTime, duration, timerId)
    end)
end

-- Metatable hook: Intercepts ALL cooldown frames automatically
local cooldownFrameMetatable = _getmetatable(_ActionButton1Cooldown).__index
if cooldownFrameMetatable and cooldownFrameMetatable.SetCooldown then
    local originalSetCooldown = cooldownFrameMetatable.SetCooldown

    cooldownFrameMetatable.SetCooldown = function(cooldownFrame, startTime, duration)
        -- Call original SetCooldown to handle the swipe
        originalSetCooldown(cooldownFrame, startTime, duration)

        -- Increment timer ID to invalidate any existing timers
        cooldownFrame.cfTimerId = (cooldownFrame.cfTimerId or 0) + 1
        local currentTimerId = cooldownFrame.cfTimerId

        -- Don't create timers for tiny frames or short durations
        if cooldownFrame:GetWidth() < MIN_FRAME_SIZE or startTime <= 0 or duration <= MIN_DURATION then
            if cooldownFrame.cfTimer then
                cooldownFrame.cfTimer:SetText("")
            end
            return
        end

        -- Create/get timer text
        if not cooldownFrame.cfTimer then
            cooldownFrame.cfTimer = cooldownFrame:CreateFontString(nil, "OVERLAY")
            cooldownFrame.cfTimer:SetFont(TIMER_FONT, TIMER_SIZE, "OUTLINE")
            cooldownFrame.cfTimer:SetPoint("CENTER", 0, 0)
        end

        -- Start the smart timer with the current ID
        updateTimer(cooldownFrame, startTime, duration, currentTimerId)
    end
end
