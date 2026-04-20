function cfDurations.initSwirls()
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

	local function updatePetBuffs()
		for i = 1, MAX_TARGET_BUFFS do
			local name, _, _, _, duration, expirationTime = Lib.UnitAuraWrapper("pet", i, "HELPFUL")
			if not name then break end

			local buff = _G["PetFrameBuff" .. i]
			if not buff then break end

			if not buff.cfCooldown then
				buff.cfCooldown = CreateFrame("Cooldown", nil, buff, "CooldownFrameTemplate")
				buff.cfCooldown:SetAllPoints()
				buff.cfCooldown:SetHideCountdownNumbers(true)
				buff.cfCooldown:SetReverse(true)
			end

			if duration and duration > 0 then
				buff.cfCooldown:SetCooldown(expirationTime - duration, duration)
			else
				buff.cfCooldown:Clear()
			end
		end
	end

	hooksecurefunc("TargetFrame_UpdateAuras", updateTargetFrame)
	hooksecurefunc("CompactUnitFrame_UtilSetBuff", updateCompactFrame)

	local petFrame = CreateFrame("Frame")
	petFrame:RegisterUnitEvent("UNIT_AURA", "pet")
	petFrame:RegisterEvent("UNIT_PET")
	petFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	petFrame:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_PET" and unit ~= "player" then return end
		updatePetBuffs()
	end)
end
