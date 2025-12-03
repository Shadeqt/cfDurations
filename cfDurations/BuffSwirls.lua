local Lib = LibStub("LibClassicDurations")
Lib:Register("cfDurationsSimple")

local function updateTargetFrame(frame)
	local unit = frame.unit
	if not unit then return end

	for i = 1, MAX_TARGET_BUFFS do
		local _, _, _, _, duration, expirationTime = Lib.UnitAuraWrapper(unit, i, "HELPFUL")
		if not duration then break end

		local cooldown = _G["TargetFrameBuff" .. i .. "Cooldown"]
		if duration > 0 then
			cooldown:SetCooldown(expirationTime - duration, duration)
		else
			cooldown:Clear()
		end
	end
end

local function updateCompactFrame(buffFrame, unit, index)
	local _, _, _, _, duration, expirationTime = Lib.UnitAuraWrapper(unit, index, "HELPFUL")
	if duration and duration > 0 then
		buffFrame.cooldown:SetCooldown(expirationTime - duration, duration)
	else
		buffFrame.cooldown:Clear()
	end
end

hooksecurefunc("TargetFrame_UpdateAuras", updateTargetFrame)
hooksecurefunc("CompactUnitFrame_UtilSetBuff", updateCompactFrame)
