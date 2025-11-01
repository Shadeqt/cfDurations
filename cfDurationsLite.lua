-- cfDurationsLite.lua - Add missing buff duration swirls

local LibClassicDurations = LibStub("LibClassicDurations")
LibClassicDurations:Register("cfDurationsLite")

-- Apply duration to a buff cooldown frame
local function applyBuffDuration(cooldownFrame, unitId, slotIndex)
	local _, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(unitId, slotIndex)
	if not spellId then return end

	-- Get duration from LibClassicDurations if WoW API doesn't provide it
	if not duration or duration == 0 then
		duration, expirationTime = LibClassicDurations:GetAuraDurationByUnit(unitId, spellId, caster)
		if not duration or duration == 0 then return end
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
