function cfDurations.initPlayerSwirls()
	hooksecurefunc("AuraButton_Update", function(buttonName, index)
		local buff = _G[buttonName .. index]
		if not buff then return end

		local filter = buttonName == "BuffButton" and "HELPFUL" or "HARMFUL"
		local name, _, _, _, duration, expirationTime = UnitAura("player", index, filter)
		if not name then return end

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
	end)
end
