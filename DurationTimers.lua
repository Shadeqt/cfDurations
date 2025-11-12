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

-- Metatable hook: Intercept SetCooldown to add timer text
local cooldownFrameMetatable = getmetatable(ActionButton1Cooldown).__index
if cooldownFrameMetatable and cooldownFrameMetatable.SetCooldown then
	-- Hook Clear to automatically cleanup timer text
	hooksecurefunc(cooldownFrameMetatable, "Clear", function(self)
		if self.cfTimer then
			self.cfTimer:SetText("")
			self.cfLastThreshold = nil
		end
	end)

	-- Helper to start timer once width is known
	local function startTimerWithWidth(self, startTime, duration, timerId, frameWidth)
		-- Validate width (filter out small frames like other players' debuffs)
		if frameWidth < MINIMUM_FRAME_WIDTH then
			if self.cfTimer then
				self.cfTimer:SetText("")
			end
			return
		end

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

	hooksecurefunc(cooldownFrameMetatable, 'SetCooldown', function(self, startTime, duration)
		if self.noCooldownCount or self:IsForbidden() then return end
		if startTime <= 0 or duration <= MINIMUM_DURATION then return end

		-- Invalidate old timer
		self.cfTimerId = (self.cfTimerId or 0) + 1
		local timerId = self.cfTimerId
		local frameWidth = self:GetWidth()

		-- Defer if frame not yet laid out
		if frameWidth == 0 then
			C_Timer.After(0, function()
				if self.cfTimerId == timerId then
					startTimerWithWidth(self, startTime, duration, timerId, self:GetWidth())
				end
			end)
		else
			startTimerWithWidth(self, startTime, duration, timerId, frameWidth)
		end
	end)
end
