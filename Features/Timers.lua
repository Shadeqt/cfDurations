local addon = cfDurations

local enabled
local inited
local tracked = {}

local timerStyles = {
	{threshold = 5,         scale = 1.5, r = 1, g = 0, b = 0},
	{threshold = 60,        scale = 1.2, r = 1, g = 1, b = 0},
	{threshold = math.huge, scale = 1,   r = 1, g = 1, b = 1},
}

local function getTimerStyle(secs)
	for _, style in ipairs(timerStyles) do
		if secs <= style.threshold then
			return style
		end
	end
end

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

local function getFontSize(frame)
	return math.floor(frame:GetWidth() / 2)
end

local function getUpdateDelay(remaining)
	if remaining <= 60 then
		return (remaining % 1) + 0.05
	elseif remaining <= 3600 then
		return (remaining % 60) + 0.05
	else
		return (remaining % 3600) + 0.05
	end
end

local function updateTimer(frame)
	if not enabled then
		if frame.timerText then frame.timerText:SetText("") end
		frame.timerEndTime = nil
		frame.lastThreshold = nil
		return
	end

	local endTime = frame.timerEndTime
	if not endTime then return end
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

	local style = getTimerStyle(remaining)
	if frame.lastThreshold ~= style.threshold then
		local fontSize = getFontSize(frame)
		frame.timerText:SetFont("Fonts\\FRIZQT__.TTF", fontSize * style.scale, "OUTLINE")
		frame.timerText:SetTextColor(style.r, style.g, style.b)
		frame.lastThreshold = style.threshold
	end

	frame.timerText:SetText(getTimerText(remaining))

	if not frame.timerCallback then
		frame.timerCallback = function() updateTimer(frame) end
	end
	C_Timer.After(getUpdateDelay(remaining), frame.timerCallback)
end

local retryDelays = {0, 0.05, 0.1}

local function onSetCooldown(frame, startTime, duration, retries)
	if not enabled then return end
	if frame:IsForbidden() then return end
	if frame.noCooldownCount then return end
	if startTime <= 0 then return end
	if duration < 1.95 then return end

	local endTime = startTime + duration

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

	if frame.timerEndTime == endTime then return end
	frame.timerEndTime = endTime

	frame:SetHideCountdownNumbers(true)

	if not frame.timerText then
		frame.timerText = frame:CreateFontString(nil, "OVERLAY")
		frame.timerText:SetPoint("CENTER")
	end

	tracked[frame] = true
	updateTimer(frame)
end

local function clearAll()
	for frame in pairs(tracked) do
		if frame.timerText then frame.timerText:SetText("") end
		frame.timerEndTime = nil
		frame.lastThreshold = nil
	end
end

local function InitTimers()
	if inited then return end
	inited = true
	hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, "SetCooldown", onSetCooldown)
end

function addon.EnableTimers()
	if enabled then return end
	InitTimers()
	enabled = true
end

function addon.DisableTimers()
	if not enabled then return end
	enabled = false
	clearAll()
end
