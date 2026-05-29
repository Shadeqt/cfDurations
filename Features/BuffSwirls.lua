local addon = cfDurations

local enabled
local inited
local Lib

local function updateTargetFrame(frame)
	if not enabled then return end
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
	if not enabled then return end
	local _, _, _, _, duration, expirationTime = Lib.UnitAuraWrapper(unit, index, "HELPFUL")
	if duration and duration > 0 then
		buffFrame.cooldown:SetCooldown(expirationTime - duration, duration)
	else
		buffFrame.cooldown:Clear()
	end
end

local function updatePetBuffs()
	if not enabled then return end
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

local function clearTargetFrame()
	for i = 1, MAX_TARGET_BUFFS do
		local cooldown = _G["TargetFrameBuff" .. i .. "Cooldown"]
		if cooldown then cooldown:Clear() end
	end
end

local function clearPetBuffs()
	for i = 1, MAX_TARGET_BUFFS do
		local buff = _G["PetFrameBuff" .. i]
		if buff and buff.cfCooldown then buff.cfCooldown:Clear() end
	end
end

local function InitBuffSwirls()
	if inited then return end
	inited = true

	Lib = LibStub("LibClassicDurations")
	Lib:Register("cfDurationsSimple")

	hooksecurefunc("TargetFrame_UpdateAuras", updateTargetFrame)
	hooksecurefunc("CompactUnitFrame_UtilSetBuff", updateCompactFrame)

	local petFrame = CreateFrame("Frame")
	petFrame:RegisterUnitEvent("UNIT_AURA", "pet")
	petFrame:RegisterEvent("UNIT_PET")
	petFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	petFrame:SetScript("OnEvent", function(_, event, unit)
		if not enabled then return end
		if event == "UNIT_PET" and unit ~= "player" then return end
		updatePetBuffs()
	end)
end

function addon.EnableBuffSwirls()
	if enabled then return end
	InitBuffSwirls()
	enabled = true
	if TargetFrame and TargetFrame.unit then updateTargetFrame(TargetFrame) end
	updatePetBuffs()
end

function addon.DisableBuffSwirls()
	if not enabled then return end
	enabled = false
	clearTargetFrame()
	clearPetBuffs()
end
