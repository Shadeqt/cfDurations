-- Timer style thresholds: scale and color based on remaining time
local timerStyles = {
	{threshold = 5, 		scale = 1.5, 	r = 1, g = 0, b = 0},
	{threshold = 60, 		scale = 1.2, 	r = 1, g = 1, b = 0},
	{threshold = math.huge, scale = 1, 		r = 1, g = 1, b = 1},
}

-- Returns style table for the given remaining seconds
local function getTimerStyle(secs)
	for _, style in ipairs(timerStyles) do
		if secs <= style.threshold then
			return style
		end
	end
end

-- Formats seconds into readable text (e.g., 45, "2m", "3h", "1d")
local function getTimerText(secs)
	if secs <= 60 then
		return math.ceil(secs)
	elseif secs <= 3600 then
		return math.ceil(secs / 60) .. "m"
	elseif secs <= 86400 then
		return math.ceil(secs / 3600) .. "h"
	else
		return math.ceil(secs / 86400) .. "d"
	end
end

-- Timer font size is half the frame width
local function getFontSize(frame)
	return math.floor(frame:GetWidth() / 2)
end

-- Calculate delay until next text change based on time range
local function getUpdateDelay(remaining)
	if remaining <= 60 then
		return (remaining % 1) + 0.05
	elseif remaining <= 3600 then
		return (remaining % 60) + 0.05
	else
		return (remaining % 3600) + 0.05
	end
end

-- Recursive timer update scheduled via C_Timer.After
local function updateTimer(frame, endTime)
	-- Abort if timer was replaced by a newer cooldown
	if frame.timerEndTime ~= endTime then return end
	-- Stop updating if frame is hidden
	if not frame:IsVisible() then
		frame.timerEndTime = nil
		return
	end

	local remaining = endTime - GetTime()
	if remaining <= 0 then
		frame.timerText:SetText("")
		frame.lastThreshold = nil
		return
	end

	-- Only update font/color when crossing a threshold
	local style = getTimerStyle(remaining)
	if frame.lastThreshold ~= style.threshold then
		local fontSize = getFontSize(frame)
		frame.timerText:SetFont("Fonts\\FRIZQT__.TTF", fontSize * style.scale, "OUTLINE")
		frame.timerText:SetTextColor(style.r, style.g, style.b)
		frame.lastThreshold = style.threshold
	end

	frame.timerText:SetText(getTimerText(remaining))

	C_Timer.After(getUpdateDelay(remaining), function()
		updateTimer(frame, endTime)
	end)
end

-- Retry delays when frame isn't ready yet (0ms, 50ms, 100ms)
local retryDelays = {0, 0.05, 0.1}

-- Hook handler for SetCooldown - validates and starts timer
local function onSetCooldown(frame, startTime, duration, retries)
	if frame:IsForbidden() then return end
	if frame.noCooldownCount then return end
	if startTime <= 0 then return end
	if duration < 1.95 then return end

	local endTime = startTime + duration

	-- Retry if frame isn't ready yet
	local fontSize = getFontSize(frame)
	if fontSize == 0 or not frame:IsVisible() then
		retries = (retries or 0) + 1
		if retries <= 3 then
			C_Timer.After(retryDelays[retries], function()
				onSetCooldown(frame, startTime, duration, retries)
			end)
		end
		return
	end

	-- Skip if same cooldown is already being tracked
	if frame.timerEndTime == endTime then return end
	frame.timerEndTime = endTime

	-- Hide Blizzard's countdown numbers
	frame:SetHideCountdownNumbers(true)

	-- Create timer text on first use
	if not frame.timerText then
		frame.timerText = frame:CreateFontString(nil, "OVERLAY")
		frame.timerText:SetPoint("CENTER")
	end

	updateTimer(frame, endTime)
end

-- Hook into all cooldown frames via metatable
hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, "SetCooldown", onSetCooldown)
