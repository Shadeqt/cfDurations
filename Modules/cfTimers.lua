-- cfDurations Timer Module: Displays countdown text on cooldown frames

-- Localized API calls
local ipairs = ipairs
local format = format
local GetTime = GetTime
local min = min
local max = max
local floor = floor
local CreateFrame = CreateFrame
local pairs = pairs
local getmetatable = getmetatable
local hooksecurefunc = hooksecurefunc
local C_Timer = C_Timer

-- Active timers tracking
local activeTimers = {}

-- Timer configuration
local MIN_DURATION = 2			-- Minimum cooldown duration to show timer (filters GCD ~1.5s)
local MIN_SIZE = 20				-- Minimum frame size to show timer (based on LARGE_AURA_SIZE=21)
local MIN_REMAINING_TIME = 0.3	-- Hide timer when remaining time drops below this (prevents "0" display)
local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FONT_FLAGS = "OUTLINE"

-- Timer styles based on remaining time
local TIMER_STYLES = {
	{threshold = 6,			r = 1.0, g = 0.1, b = 0.1, fontAura = 16, fontCooldown = 26},	-- Red urgent
	{threshold = 10,		r = 1.0, g = 1.0, b = 0.1, fontAura = 14, fontCooldown = 22},	-- Yellow
	{threshold = 600,		r = 1.0, g = 1.0, b = 1.0, fontAura = 12, fontCooldown = 18},	-- White normal
	{threshold = math.huge,	r = 1.0, g = 1.0, b = 1.0, fontAura = 10, fontCooldown = 14},	-- White small (10m+)
}

-- Time format configuration
local TIME_FORMATS = {
	{threshold = 86400,	format = "%dd"},	-- Days
	{threshold = 3600,	format = "%dh"},	-- Hours
	{threshold = 60,	format = "%dm"},	-- Minutes
}

-- Format remaining time into human-readable string
local function FormatRemainingTime(seconds)
	for _, fmt in ipairs(TIME_FORMATS) do
		if seconds >= fmt.threshold then
			-- Round to nearest integer to avoid floating-point precision issues
			local value = floor((seconds / fmt.threshold) + 0.5)
			return format(fmt.format, value)
		end
	end
	-- For seconds display, use ceiling so each number shows for its full second
	-- (1.9s shows "2", 1.1s shows "2", 1.0s shows "1", 0.1s shows "1")
	local value = floor(seconds)
	if value < seconds then
		value = value + 1
	end
	return format("%d", value)
end

-- Get appropriate timer style based on remaining time
local function GetTimerStyle(remaining)
	for _, s in ipairs(TIMER_STYLES) do
		if remaining < s.threshold then
			return s
		end
	end
	return TIMER_STYLES[#TIMER_STYLES]
end

-- Create timer text for a cooldown frame
local function CreateTimerText(cooldown)
	local text = cooldown:CreateFontString(nil, "OVERLAY")
	text:SetPoint("CENTER", 0, 0)
	cooldown.cfTimerText = text
	return text
end

-- Remove timer from tracking
local function RemoveTimerTracking(cooldown)
	local text = cooldown.cfTimerText
	if text then text:Hide() end
	activeTimers[cooldown] = nil
	-- Invalidate all pending callbacks for this cooldown
	cooldown.cfTimerCallbackId = (cooldown.cfTimerCallbackId or 0) + 1
end

-- Calculate sleep time until next text change
local function CalculateSleepTime(remaining, cooldown)
	-- Calculate when the displayed text will actually change
	-- This prevents drift by calculating relative to absolute thresholds

	if remaining <= 60 then
		-- At or under 1 minute: update every second
		-- With ceiling, text changes at whole second boundaries (3→2 at 2.0s)
		-- Calculate which second is currently displayed
		local displayedSecond = floor(remaining)
		if displayedSecond < remaining then
			displayedSecond = displayedSecond + 1
		end
		-- Sleep until slightly past the next lower integer (when displayed value will decrease)
		-- Add 0.05s buffer to ensure we wake after the transition, not before
		local nextChange = max(displayedSecond - 1.05, 0.3)
		return max(remaining - nextChange, 0.1)
	elseif remaining < 600 then
		-- 1-10 minutes: update every 30 seconds
		-- Round to nearest 30s and sleep until halfway to next 30s boundary
		local rounded = floor((remaining + 15) / 30) * 30
		local nextChange = max(rounded - 15, 60)  -- Transition at halfway point or when entering <60s
		return max(remaining - nextChange, 0.1)
	else
		-- Over 10 minutes: update every minute
		-- Round to nearest minute and sleep until halfway to next minute boundary
		local rounded = floor((remaining + 30) / 60) * 60
		local nextChange = max(rounded - 30, 600)  -- Transition at halfway point or when entering <10m
		return max(remaining - nextChange, 0.1)
	end
end

-- Update a single timer display
local function UpdateTimerDisplay(cooldown)
	local expireTime = activeTimers[cooldown]
	if not expireTime then
		return
	end

	local remaining = expireTime - GetTime()

	-- Timer expired or below threshold
	if remaining <= MIN_REMAINING_TIME then
		RemoveTimerTracking(cooldown)
		return
	end

	-- Check frame size - too small to show timer
	local frameSize = cooldown:GetWidth()
	if not frameSize then
		RemoveTimerTracking(cooldown)
		return
	end

	if frameSize < MIN_SIZE then
		RemoveTimerTracking(cooldown)
		return
	end

	-- Get or create text
	local text = cooldown.cfTimerText
	if not text then
		text = CreateTimerText(cooldown)
	end

	-- Find appropriate style based on remaining time
	local style = GetTimerStyle(remaining)

	-- Apply font size based on frame size (cached)
	local fontSize = frameSize >= 30 and style.fontCooldown or style.fontAura
	if cooldown.cfTimerFontSize ~= fontSize then
		text:SetFont(FONT_PATH, fontSize, FONT_FLAGS)
		cooldown.cfTimerFontSize = fontSize
	end

	-- Apply color (cached)
	if cooldown.cfTimerStyle ~= style then
		text:SetTextColor(style.r, style.g, style.b)
		cooldown.cfTimerStyle = style
	end

	-- Adjust position for long timers (2+ minutes) using small font (cached)
	local xOffset = (remaining >= 120 and fontSize == style.fontAura) and 1 or 0
	if cooldown.cfTimerXOffset ~= xOffset then
		text:ClearAllPoints()
		text:SetPoint("CENTER", xOffset, 0)
		cooldown.cfTimerXOffset = xOffset
	end

	-- Update text
	local newText = FormatRemainingTime(remaining)
	text:SetText(newText)
	text:Show()

	-- Schedule next update with callback validation
	local sleepTime = CalculateSleepTime(remaining, cooldown)
	if sleepTime > 0 then
		-- Increment callback ID to invalidate all previous callbacks
		cooldown.cfTimerCallbackId = (cooldown.cfTimerCallbackId or 0) + 1
		local currentCallbackId = cooldown.cfTimerCallbackId

		C_Timer.After(sleepTime, function()
			-- Only execute if this callback is still valid
			if cooldown.cfTimerCallbackId == currentCallbackId then
				UpdateTimerDisplay(cooldown)
			end
		end)
	end
end

-- Handle cooldown set events
local function OnCooldownSet(cooldown, start, duration)
	if not cooldown then return end
	if start <= 0 then return end

	-- Clear timer if cooldown is being reset or too short
	if duration < MIN_DURATION then
		RemoveTimerTracking(cooldown)
		return
	end

	-- Track this timer (store expireTime)
	activeTimers[cooldown] = start + duration
	UpdateTimerDisplay(cooldown)
end

-- Hook the SetCooldown method on all cooldown frames
local cooldownMetatable = getmetatable(ActionButton1Cooldown).__index
if cooldownMetatable and cooldownMetatable.SetCooldown then
	hooksecurefunc(cooldownMetatable, "SetCooldown", OnCooldownSet)
end
