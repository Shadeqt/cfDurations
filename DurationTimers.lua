-- Module constants
local SAFETY_MARGIN = 0.05
local MINIMUM_FRAME_WIDTH = 17 + SAFETY_MARGIN
local MINIMUM_DURATION = 1.5 + SAFETY_MARGIN

-- Timer formatting constants
local TIMER_FONT = "Fonts\\FRIZQT__.TTF"
local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400
local TIMER_STYLES = {
	{ threshold = 5,         scale = 1.5,  r = 1, g = 0.1, b = 0.1 },  -- < 5s: Red, larger
	{ threshold = 59,        scale = 1.2,  r = 1, g = 1,   b = 0.1 },  -- < 60s: Yellow, medium
	{ threshold = math.huge, scale = 1.0,  r = 1, g = 1,   b = 1   },  -- Rest: White, normal
}

-- Get style (color/scale) based on remaining time
local function getTimerStyle(remainingSeconds)
	for _, style in ipairs(TIMER_STYLES) do
		if remainingSeconds < style.threshold then
			return style
		end
	end
end

-- Calculate font size based on frame width and scale
local function calculateFontSize(frameWidth, scale)
	local baseSize = frameWidth / 2
	return baseSize * scale
end

-- Format time display
local function formatTime(seconds)
	if seconds < SECONDS_PER_MINUTE - 1 then
		return string.format("%.0f", seconds)
	elseif seconds < SECONDS_PER_HOUR - 1 then
		return string.format("%.0fm", seconds / SECONDS_PER_MINUTE)
	elseif seconds < SECONDS_PER_DAY - 1 then
		return string.format("%.0fh", seconds / SECONDS_PER_HOUR)
	else
		return string.format("%.0fd", seconds / SECONDS_PER_DAY)
	end
end

-- Calculate delay until next update
local function calculateDelay(remaining)
	if remaining < SECONDS_PER_MINUTE then
		return (remaining % 1) + SAFETY_MARGIN  -- Wake just after each second
	elseif remaining < SECONDS_PER_HOUR then
		return (remaining % SECONDS_PER_MINUTE) + SAFETY_MARGIN  -- Wake just after each minute
	else
		return (remaining % SECONDS_PER_HOUR) + SAFETY_MARGIN  -- Wake just after each hour
	end
end

-- Recursive timer update (sleeps between updates via C_Timer.After)
local function updateTimer(cooldownFrame, startTime, duration, timerId, frameWidth)
	-- Stop if this timer was replaced by a newer one
	if cooldownFrame.cfTimerId ~= timerId then return end

	local remaining = startTime + duration - GetTime()

	-- Stop if expired
	if remaining <= 0 then
		cooldownFrame.cfTimer:SetText("")
		cooldownFrame.cfLastThreshold = nil
		return
	end

	-- Update font and color when crossing thresholds (or first time)
	local timerStyle = getTimerStyle(remaining)
	if cooldownFrame.cfLastThreshold ~= timerStyle.threshold then
		local fontSize = calculateFontSize(frameWidth, timerStyle.scale)
		cooldownFrame.cfTimer:SetFont(TIMER_FONT, fontSize, "OUTLINE")
		cooldownFrame.cfTimer:SetTextColor(timerStyle.r, timerStyle.g, timerStyle.b)
		cooldownFrame.cfLastThreshold = timerStyle.threshold
	end

	-- Update text
	cooldownFrame.cfTimer:SetText(formatTime(remaining))

	-- Schedule next update (recursive)
	local updateDelay = calculateDelay(remaining)
	C_Timer.After(updateDelay, function()
		updateTimer(cooldownFrame, startTime, duration, timerId, frameWidth)
	end)
end

-- Metatable hook: Intercept SetCooldown to add timer text
local cooldownFrameMetatable = getmetatable(ActionButton1Cooldown).__index
if cooldownFrameMetatable and cooldownFrameMetatable.SetCooldown then
	hooksecurefunc(cooldownFrameMetatable, 'SetCooldown', function(self, startTime, duration)
		if self.noCooldownCount then return end
		-- Hide native Blizzard countdown numbers
		self:SetHideCountdownNumbers(true)

		-- Always invalidate old timer first
		self.cfTimerId = (self.cfTimerId or 0) + 1

		-- Capture frame width once (avoid repeated GetWidth() calls in hot path)
		local frameWidth = self:GetWidth()

		-- Only show timer for valid cooldowns
		if frameWidth < MINIMUM_FRAME_WIDTH or startTime <= 0 or duration <= MINIMUM_DURATION then
			if self.cfTimer then
				self.cfTimer:SetText("")
				self.cfLastThreshold = nil
			end
			return
		end

		-- Create timer text on first use
		if not self.cfTimer then
			self.cfTimer = self:CreateFontString(nil, "OVERLAY")
			self.cfTimer:SetPoint("CENTER", 0, 0)
		end

		-- Start new timer
		updateTimer(self, startTime, duration, self.cfTimerId, frameWidth)
	end)
end
