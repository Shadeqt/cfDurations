-- cfDurationsLite.lua - Add missing buff duration swirls and timers

local LibClassicDurations = LibStub("LibClassicDurations")
LibClassicDurations:Register("cfDurationsLite")

-- Module constants
local SAFETY_MARGIN = 0.05
local MIN_FRAME_SIZE = 17 + SAFETY_MARGIN
local MIN_COOLDOWN_GCD = 1.5 + SAFETY_MARGIN

-- Timer formatting constants
local TIMER_FONT = "Fonts\\FRIZQT__.TTF"
local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400
local TIMER_STYLES = {
	{ threshold = 5,         scale = 1.5,  r = 1, g = 0.1, b = 0.1 },  -- < 5s: Red, larger
	{ threshold = 59,        scale = 1.25, r = 1, g = 1,   b = 0.1 },  -- < 60s: Yellow, medium
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
	local baseSize = math.floor(frameWidth / 2)
	return math.floor(baseSize * scale)
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

-- Central ticker system for all active timers
local activeTimers = {}  -- [cooldownFrame] = {expireTime, nextUpdate, frameName}
local ticker = CreateFrame("Frame")

-- Update a single timer display
local function updateTimerDisplay(cooldownFrame, remaining)
	local timerData = activeTimers[cooldownFrame]
	if not timerData then return end

	-- Update font and color when crossing thresholds (or first time)
	local style = getTimerStyle(remaining)
	if cooldownFrame.cfLastThreshold ~= style.threshold then
		local fontSize = calculateFontSize(cooldownFrame:GetWidth(), style.scale)
		cooldownFrame.cfTimer:SetFont(TIMER_FONT, fontSize, "OUTLINE")
		cooldownFrame.cfTimer:SetTextColor(style.r, style.g, style.b)
		cooldownFrame.cfLastThreshold = style.threshold

		print(string.format("[cfDurations] %s: Threshold changed to %.0fs (color updated)",
			timerData.frameName or "Unknown", style.threshold))
	end

	-- Update text (must be after SetFont to avoid "Font not set" error)
	cooldownFrame.cfTimer:SetText(formatTime(remaining))

	print(string.format("[cfDurations] %s: Updated to %s (%.1fs remaining)",
		timerData.frameName or "Unknown", formatTime(remaining), remaining))
end

-- Central ticker OnUpdate handler
ticker:SetScript("OnUpdate", function()
	local now = GetTime()

	for cooldownFrame, data in pairs(activeTimers) do
		if now >= data.nextUpdate then
			local remaining = data.expireTime - now

			if remaining <= 0 then
				-- Timer expired
				cooldownFrame.cfTimer:SetText("")
				cooldownFrame.cfLastThreshold = nil
				activeTimers[cooldownFrame] = nil

				print(string.format("[cfDurations] %s: Expired (removed from ticker)",
					data.frameName or "Unknown"))
			else
				-- Update timer display
				updateTimerDisplay(cooldownFrame, remaining)

				-- Schedule next update based on remaining time
				if remaining < SECONDS_PER_MINUTE then
					data.nextUpdate = now + 1      -- Every second
				elseif remaining < SECONDS_PER_HOUR then
					data.nextUpdate = now + SECONDS_PER_MINUTE     -- Every minute
				else
					data.nextUpdate = now + SECONDS_PER_HOUR   -- Every hour
				end
			end
		end
	end
end)

-- Metatable hook: Intercept SetCooldown to add timer text
local cooldownMT = getmetatable(ActionButton1Cooldown).__index
if cooldownMT and cooldownMT.SetCooldown then
	local original = cooldownMT.SetCooldown

	cooldownMT.SetCooldown = function(self, startTime, duration)
		original(self, startTime, duration)

		-- Get frame name for debug prints
		local frameName = self:GetName() or tostring(self)

		-- Only show timer for valid cooldowns
		if self:GetWidth() < MIN_FRAME_SIZE or startTime <= 0 or duration <= MIN_COOLDOWN_GCD then
			-- Remove from ticker if it was active
			if activeTimers[self] then
				activeTimers[self] = nil
				print(string.format("[cfDurations] %s: Removed (invalid cooldown)", frameName))
			end

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

		-- Calculate expiration time and first update time
		local expireTime = startTime + duration
		local now = GetTime()
		local remaining = expireTime - now

		-- Add to central ticker (or update if already present)
		local nextUpdate
		if remaining < SECONDS_PER_MINUTE then
			nextUpdate = now  -- Update immediately, then every second
		elseif remaining < SECONDS_PER_HOUR then
			nextUpdate = now  -- Update immediately, then every minute
		else
			nextUpdate = now  -- Update immediately, then every hour
		end

		activeTimers[self] = {
			expireTime = expireTime,
			nextUpdate = nextUpdate,
			frameName = frameName
		}

		print(string.format("[cfDurations] %s: Added to ticker (%.1fs duration, expires at %.1f)",
			frameName, duration, expireTime))

		-- Force immediate first update
		updateTimerDisplay(self, remaining)
	end
end

-- Apply duration to a buff cooldown frame
local function applyBuffDuration(cooldownFrame, unitId, slotIndex)
	local _, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(unitId, slotIndex)
	if not spellId then return end

	-- Get duration from LibClassicDurations if WoW API doesn't provide it
	if not duration or duration == 0 then
		duration, expirationTime = LibClassicDurations:GetAuraDurationByUnit(unitId, spellId, caster)
	end

	-- Clear cooldown for permanent buffs (no duration)
	if not duration or duration == 0 then
		cooldownFrame:Clear()
		return
	end

	-- Apply cooldown swirl
	cooldownFrame:SetCooldown(expirationTime - duration, duration)
end

-- Update target frame buffs (loop through all slots, lookup cooldown frames by name)
local function updateTargetFrame(targetFrame)
	if not targetFrame.unit then return end

	for i = 1, MAX_TARGET_BUFFS do
		local cooldownFrame = _G["TargetFrameBuff" .. i .. "Cooldown"]
		if cooldownFrame then
			applyBuffDuration(cooldownFrame, targetFrame.unit, i)
		end
	end
end

-- Update compact frame buff (single buff, cooldown frame provided as property)
local function updateCompactFrame(buffFrame, unitId, slotIndex)
	applyBuffDuration(buffFrame.cooldown, unitId, slotIndex)
end

-- Hook target frame buff updates
hooksecurefunc("TargetFrame_UpdateAuras", updateTargetFrame)

-- Hook party/raid buff frames
hooksecurefunc("CompactUnitFrame_UtilSetBuff", updateCompactFrame)
