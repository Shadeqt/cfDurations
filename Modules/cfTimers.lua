-- cfDurations Timer Module: Displays countdown text on cooldown frames

-- Localized calls
-- Lua built-ins (no underscore prefix)
local ipairs = ipairs
local floor = floor
local format = format
local ceil = math.ceil
local max = max
local getmetatable = getmetatable
local hooksecurefunc = hooksecurefunc

-- WoW API calls (underscore prefix)
local _GetTime = GetTime
local _C_Timer = C_Timer

-- Active timers: maps cooldown frame to its expiration timestamp
local activeCooldownTimers = {}

-- Timer configuration
local MIN_DURATION = 2						-- Minimum cooldown duration to show timer (filters GCD ~1.5s)
local LARGE_AURA_WIDTH = 21 - 1					-- Width of large aura/buff frames
local ACTION_BAR_WIDTH = 36 - 1					-- Width of action bar cooldown frames
local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FONT_FLAGS = "OUTLINE"

-- Timer styles based on remaining time
local TIMER_STYLES = {
	{threshold = 5,			r = 1.0, g = 0.1, b = 0.1, fontAura = 16, fontCooldown = 26},	-- Red big (1-5s)
	{threshold = 9,			r = 1.0, g = 1.0, b = 0.1, fontAura = 14, fontCooldown = 22},	-- Yellow large (6-9s)
	{threshold = 569,		r = 1.0, g = 1.0, b = 1.0, fontAura = 12, fontCooldown = 18},	-- White medium (10s-9m)
	{threshold = math.huge,	r = 1.0, g = 1.0, b = 1.0, fontAura = 10, fontCooldown = 14},	-- White small (10m+)
}

-- Time format configuration
local TIME_FORMATS = {
	{threshold = 86400,	format = "%dd"},	-- Days
	{threshold = 3600,	format = "%dh"},	-- Hours
	{threshold = 60,	format = "%dm"},	-- Minutes
}

-- Format remaining time into human-readable string
local function formatTimerText(seconds)
	-- Display seconds when at or under 60s for smooth transition from "2m" to "60"
	if seconds <= 60 then
		return format("%d", ceil(seconds))
	end

	for _, formatConfig in ipairs(TIME_FORMATS) do
		if seconds >= formatConfig.threshold then
			local value = ceil(seconds / formatConfig.threshold)
			return format(formatConfig.format, value)
		end
	end
end

-- Remove timer from tracking
local function removeTimerTracking(cooldownFrame)
	local timerText = cooldownFrame.cfTimerText
	if timerText then timerText:Hide() end
	activeCooldownTimers[cooldownFrame] = nil
end

-- Get appropriate timer text style based on remaining time
local function getTimerTextStyle(remaining)
	for _, style in ipairs(TIMER_STYLES) do
		if remaining <= style.threshold then
			return style
		end
	end
end

-- Create timer text for a cooldown frame
local function createTimerText(cooldownFrame)
	local timerText = cooldownFrame:CreateFontString(nil, "OVERLAY")
	timerText:SetPoint("CENTER", 0, 0)
	cooldownFrame.cfTimerText = timerText
	return timerText
end

-- Update timer text with style and content
local function updateTimerText(cooldownFrame, remainingTime, frameWidth)
	local timerText = cooldownFrame.cfTimerText or createTimerText(cooldownFrame)
	local timerStyle = getTimerTextStyle(remainingTime)

	-- Apply font size based on frame size (cached for performance)
	local fontSize = frameWidth >= ACTION_BAR_WIDTH and timerStyle.fontCooldown or timerStyle.fontAura
	if cooldownFrame.cfTimerFontSize ~= fontSize then
		timerText:SetFont(FONT_PATH, fontSize, FONT_FLAGS)
		cooldownFrame.cfTimerFontSize = fontSize
	end

	timerText:SetTextColor(timerStyle.r, timerStyle.g, timerStyle.b)
	timerText:SetText(formatTimerText(remainingTime))
	timerText:Show()
end

-- Calculate sleep time until next text change
local function calculateSleepTime(remaining)
	local sleepDuration
	if remaining <= 60 then
		-- Update every second for second-based display
		sleepDuration = remaining - (floor(remaining) - 0.05)
	else
		-- Update every minute for minute-based display (using ceil logic)
		-- Next change happens at the next minute boundary (e.g., 540s, 480s, 420s...)
		local currentMinute = ceil(remaining / 60)
		local nextMinute = currentMinute - 1
		local nextChange = max(nextMinute * 60, 60)
		sleepDuration = remaining - nextChange
	end
	return max(sleepDuration, 0.1)
end

-- Update a single timer display
local function updateTimerDisplay(cooldownFrame)
	local expirationTime = activeCooldownTimers[cooldownFrame]
	if not expirationTime then return end

	local remainingTime = expirationTime - _GetTime()

	if remainingTime <= 0 then
		removeTimerTracking(cooldownFrame)
		return
	end

	local parentFrame = cooldownFrame:GetParent()
	local frameWidth = cooldownFrame:GetWidth()
	if not parentFrame or not parentFrame:IsVisible() or not frameWidth or frameWidth < LARGE_AURA_WIDTH then
		removeTimerTracking(cooldownFrame)
		return
	end

	updateTimerText(cooldownFrame, remainingTime, frameWidth)

	-- Schedule next update with callback ID validation to prevent stale callbacks
	local sleepTime = calculateSleepTime(remainingTime)
	cooldownFrame.cfTimerCallbackId = (cooldownFrame.cfTimerCallbackId or 0) + 1
	local callbackId = cooldownFrame.cfTimerCallbackId

	_C_Timer.After(sleepTime, function()
		if cooldownFrame.cfTimerCallbackId == callbackId then
			updateTimerDisplay(cooldownFrame)
		end
	end)
end

-- Handle cooldown set events
local function onCooldownSet(cooldownFrame, startTime, duration)
	if startTime <= 0 then
		return
	end

	if duration < MIN_DURATION then
		removeTimerTracking(cooldownFrame)
		return
	end

	-- Skip if parent frame is hidden
	local parentFrame = cooldownFrame:GetParent()
	if not parentFrame or not parentFrame:IsVisible() then
		return
	end

	local expirationTime = startTime + duration
	activeCooldownTimers[cooldownFrame] = expirationTime
	updateTimerDisplay(cooldownFrame)
end

-- Hook the SetCooldown method on all cooldown frames
local cooldownMetatable = getmetatable(ActionButton1Cooldown).__index
if cooldownMetatable and cooldownMetatable.SetCooldown then
	hooksecurefunc(cooldownMetatable, "SetCooldown", onCooldownSet)
end
