local addon = cfDurations

local enabled
local inited
local tracked = {}

local function applyCooldown(buff, index, filter)
	local name, _, _, _, duration, expirationTime = UnitAura("player", index, filter)
	if not name then return end

	if not buff.cfCooldown then
		buff.cfCooldown = CreateFrame("Cooldown", nil, buff, "CooldownFrameTemplate")
		buff.cfCooldown:SetAllPoints()
		buff.cfCooldown:SetHideCountdownNumbers(true)
		buff.cfCooldown:SetReverse(true)
		tracked[buff] = true
	end

	if duration and duration > 0 then
		buff.cfCooldown:SetCooldown(expirationTime - duration, duration)
	else
		buff.cfCooldown:Clear()
	end
end

local function clearAll()
	for buff in pairs(tracked) do
		if buff.cfCooldown then buff.cfCooldown:Clear() end
	end
end

local function InitPlayerBuffSwirls()
	if inited then return end
	inited = true

	hooksecurefunc("AuraButton_Update", function(buttonName, index)
		if not enabled then return end
		local buff = _G[buttonName .. index]
		if not buff then return end
		local filter = buttonName == "BuffButton" and "HELPFUL" or "HARMFUL"
		applyCooldown(buff, index, filter)
	end)
end

function addon.EnablePlayerBuffSwirls()
	if enabled then return end
	InitPlayerBuffSwirls()
	enabled = true
end

function addon.DisablePlayerBuffSwirls()
	if not enabled then return end
	enabled = false
	clearAll()
end
