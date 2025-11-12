-- Library dependency
local LibClassicDurations = LibStub("LibClassicDurations")
LibClassicDurations:Register("cfDurationsLite")

-- WoW constants
local MAX_TARGET_BUFFS = MAX_TARGET_BUFFS -- 32, maximum number of buffs on target frame

-- Module states

-- Apply duration to a buff cooldown frame
local function applyBuffDuration(cooldownFrame, unitId, duration, expirationTime, caster, spellId)
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
		local name, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(targetFrame.unit, i)
		if not spellId then break end

		local cooldownFrame = _G["TargetFrameBuff" .. i .. "Cooldown"]
		applyBuffDuration(cooldownFrame, targetFrame.unit, duration, expirationTime, caster, spellId)
	end
end

-- Update compact frame buff (single buff, cooldown frame provided as property)
local function updateCompactFrame(buffFrame, unitId, i)
	local _, _, _, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(unitId, i)
	if not spellId then return end

	applyBuffDuration(buffFrame.cooldown, unitId, duration, expirationTime, caster, spellId)
end

-- Hook target frame buff updates
hooksecurefunc("TargetFrame_UpdateAuras", updateTargetFrame)

-- Hook party/raid buff frames
hooksecurefunc("CompactUnitFrame_UtilSetBuff", updateCompactFrame)
