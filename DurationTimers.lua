-- Module constants
local SAFETY_MARGIN = 0.05
local MINIMUM_FRAME_WIDTH = 17 + SAFETY_MARGIN
local MINIMUM_DURATION = 3

-- Timer formatting constants
local TIMER_FONT = "Fonts\\FRIZQT__.TTF"
local TIMER_STYLES = {
	{ threshold = 5,         scale = 1.5, r = 1, g = 0.1, b = 0.1, divisor = 1,     suffix = "",  freq = 1    },  -- <5s: Red, large
	{ threshold = 59,        scale = 1.2, r = 1, g = 1,   b = 0.1, divisor = 1,     suffix = "",  freq = 1    },  -- <1m: Yellow
	{ threshold = 540,       scale = 1.0, r = 1, g = 1,   b = 1,   divisor = 60,    suffix = "m", freq = 60   },  -- <10m: Minutes
	{ threshold = 3599,      scale = 0.8, r = 1, g = 1,   b = 1,   divisor = 60,    suffix = "m", freq = 60   },  -- <1h: Minutes
	{ threshold = 86399,     scale = 0.8, r = 1, g = 1,   b = 1,   divisor = 3600,  suffix = "h", freq = 3600 },  -- <1d: Hours
	{ threshold = math.huge, scale = 0.8, r = 1, g = 1,   b = 1,   divisor = 86400, suffix = "d", freq = 3600 }   -- 1d+: Days
}

-- Get style (color/scale) based on remaining time
local function getTimerStyle(remaining)
	for _, style in ipairs(TIMER_STYLES) do
		if remaining < style.threshold then
			return style
		end
	end
end

-- Recursive timer update (sleeps between updates via C_Timer.After)
local function updateTimer(cooldownFrame, startTime, duration, timerId, frameWidth)
	-- Stop if this timer was replaced by a newer one
	if cooldownFrame.cfTimerId ~= timerId then return end

	local remaining = startTime + duration - GetTime()

	-- Stop if expired
	if remaining <= 0.5 then
		cooldownFrame.cfTimer:SetText("")
		cooldownFrame.cfLastThreshold = nil
		return
	end

	-- Update font and color when crossing thresholds (or first time)
	local timerStyle = getTimerStyle(remaining)
	if cooldownFrame.cfLastThreshold ~= timerStyle.threshold then
		local fontSize = (frameWidth / 2) * timerStyle.scale
		cooldownFrame.cfTimer:SetFont(TIMER_FONT, fontSize, "OUTLINE")
		cooldownFrame.cfTimer:SetTextColor(timerStyle.r, timerStyle.g, timerStyle.b)
		cooldownFrame.cfLastThreshold = timerStyle.threshold
	end

	-- Update text
	local displayText = math.ceil(remaining / timerStyle.divisor) .. timerStyle.suffix
	cooldownFrame.cfTimer:SetText(displayText)

	-- Schedule next update (recursive)
	C_Timer.After((remaining % timerStyle.freq) + SAFETY_MARGIN, function()
		updateTimer(cooldownFrame, startTime, duration, timerId, frameWidth)
	end)
end

-- Validate frame and start new timer
local function startTimer(self, startTime, duration, timerId, frameWidth)
	if self.cfTimerId ~= timerId then return end  -- Timer was replaced
	if frameWidth < MINIMUM_FRAME_WIDTH then return end  -- Too small

	-- Hide native Blizzard countdown numbers
	self:SetHideCountdownNumbers(true)

	-- Create timer text on first use
	if not self.cfTimer then
		self.cfTimer = self:CreateFontString(nil, "OVERLAY")
		self.cfTimer:SetPoint("CENTER", 0, 0)
	end

	-- Start new timer
	updateTimer(self, startTime, duration, timerId, frameWidth)
end

-- Metatable hook: Intercept SetCooldown to add timer text
local cooldownFrameMetatable = getmetatable(ActionButton1Cooldown).__index
if cooldownFrameMetatable and cooldownFrameMetatable.SetCooldown then
	hooksecurefunc(cooldownFrameMetatable, 'SetCooldown', function(self, startTime, duration)
		if self.noCooldownCount then return end
		if self:IsForbidden() then return end
		if startTime <= 0 then return end
		if duration <= MINIMUM_DURATION then return end

		-- Early width check to avoid processing tiny frames
		local frameWidth = self:GetWidth()
		if frameWidth ~= 0 and frameWidth < MINIMUM_FRAME_WIDTH then return end

		-- Invalidate old timer
		local timerId = (self.cfTimerId or 0) + 1
		self.cfTimerId = timerId

		-- Start timer immediately if frame is ready, otherwise defer one frame
		if frameWidth ~= 0 then
			startTimer(self, startTime, duration, timerId, frameWidth)
		else
			C_Timer.After(0, function()
				startTimer(self, startTime, duration, timerId, self:GetWidth())
			end)
		end
	end)
end
