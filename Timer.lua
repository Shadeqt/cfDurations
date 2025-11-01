-- cfDurations Timer: Timer display logic and formatting

-- Shared dependencies
cfDurations = cfDurations or {}

-- Module constants
local TIMER_FONT = "Fonts\\FRIZQT__.TTF"
local SAFETY_MARGIN = 0.05
local MIN_DURATION = 1 - SAFETY_MARGIN - SAFETY_MARGIN -- 0.9, minimum duration to display timer
local SECONDS_PER_MINUTE = 60 -- 60, seconds per minute
local SECONDS_PER_HOUR = 3600 -- 3600, seconds per hour
local SECONDS_PER_DAY = 86400 -- 86400, seconds per day

-- Module states
local TIMER_STYLES = {
    { threshold = 5,         scale = 1.5,  r = 1, g = 0.1, b = 0.1, a = 1 },  -- < 6s: Red
    { threshold = 59,        scale = 1.25, r = 1, g = 1,   b = 0.1, a = 1 },  -- < 60s: Yellow
    { threshold = math.huge, scale = 1.0,  r = 1, g = 1,   b = 1,   a = 1 },  -- Rest: White
}

local function getTimerStyle(remainingSeconds)
    for _, style in ipairs(TIMER_STYLES) do
        if remainingSeconds < style.threshold then
            return style
        end
    end
end

-- Calculate font size based on frame width and scale
local function calculateFontSize(frameWidth, scale)
    local baseSize = math.floor(frameWidth / 2)
    return math.floor(baseSize * scale)
end

-- Format time based on duration
local function formatTime(seconds)
    if seconds < SECONDS_PER_MINUTE - 1 then
        return string.format("%.0f", seconds)
    elseif seconds < SECONDS_PER_HOUR then
        return string.format("%.0fm", seconds / SECONDS_PER_MINUTE)
    elseif seconds < SECONDS_PER_DAY then
        return string.format("%.0fh", seconds / SECONDS_PER_HOUR)
    else
        return string.format("%.0fd", seconds / SECONDS_PER_DAY)
    end
end

-- Calculate delay until next display change
local function calculateNextUpdateDelay(remainingSeconds)
    if remainingSeconds < SECONDS_PER_MINUTE then
        return (remainingSeconds % 1) + SAFETY_MARGIN
    elseif remainingSeconds < SECONDS_PER_HOUR then
        return (remainingSeconds % SECONDS_PER_MINUTE) + SAFETY_MARGIN
    elseif remainingSeconds < SECONDS_PER_DAY then
        return (remainingSeconds % SECONDS_PER_HOUR) + SAFETY_MARGIN
    else
        return (remainingSeconds % SECONDS_PER_DAY) + SAFETY_MARGIN
    end
end

-- Public API: Clear timer text
function cfDurations.clearTimer(cooldownFrame)
    if not cooldownFrame.cfTimer then return end

    -- Only call SetText if font has been initialized (cfLastThreshold tracks this)
    if cooldownFrame.cfLastThreshold then
        cooldownFrame.cfTimer:SetText("")
    else
        -- Font never initialized, just hide the frame
        cooldownFrame.cfTimer:Hide()
    end

    cooldownFrame.cfLastThreshold = nil
end

-- Public API: Increment timer ID (invalidates existing timers)
function cfDurations.incrementTimerId(cooldownFrame)
    cooldownFrame.cfTimerId = (cooldownFrame.cfTimerId or 0) + 1
    return cooldownFrame.cfTimerId
end

-- Public API: Start timer (creates timer if needed, then updates)
function cfDurations.startTimer(cooldownFrame, startTime, duration, timerId)
    if cooldownFrame.cfTimerId ~= timerId then return end

    -- Create timer FontString on first call
    if not cooldownFrame.cfTimer then
        cooldownFrame.cfTimer = cooldownFrame:CreateFontString(nil, "OVERLAY")
        cooldownFrame.cfTimer:SetPoint("CENTER", 0, 0)
        cooldownFrame.cfLastThreshold = nil  -- Will trigger font setup below
    end

    local remainingSeconds = startTime + duration - GetTime()
    if remainingSeconds <= MIN_DURATION then
        cfDurations.clearTimer(cooldownFrame)
        return
    end

    local style = getTimerStyle(remainingSeconds)
    local currentThreshold = style.threshold

    -- Update font/color when crossing threshold boundaries (including first call)
    if cooldownFrame.cfLastThreshold ~= currentThreshold then
        local fontSize = calculateFontSize(cooldownFrame:GetWidth(), style.scale)
        cooldownFrame.cfTimer:SetFont(TIMER_FONT, fontSize, "OUTLINE")
        cooldownFrame.cfTimer:SetTextColor(style.r, style.g, style.b, style.a)
        cooldownFrame.cfLastThreshold = currentThreshold
    end

    -- Always update text (safe because font is set by threshold check above)
    cooldownFrame.cfTimer:SetText(formatTime(remainingSeconds))

    local updateDelay = calculateNextUpdateDelay(remainingSeconds)
    C_Timer.After(updateDelay, function()
        cfDurations.startTimer(cooldownFrame, startTime, duration, timerId)
    end)
end
