local panel = CreateFrame("Frame", "cfDurationsSettingsPanel")
panel.name = "cfDurations"
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("cfDurations")

local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
note:SetText("Changes require a /reload to take effect.")

local function CreateCheckbox(anchor, label, dbKey)
	local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
	checkbox.Text:SetText(label)
	checkbox:SetHitRectInsets(0, -checkbox.Text:GetStringWidth(), 0, 0)
	checkbox:SetScript("OnShow", function(self)
		self:SetChecked(cfDurationsDB and cfDurationsDB[dbKey])
	end)
	checkbox:SetScript("OnClick", function(self)
		cfDurationsDB[dbKey] = self:GetChecked()
	end)
	return checkbox
end

local swirls = CreateCheckbox(note, "Buff Swirls (Target/Pet/Raid)", "swirls")
local playerSwirls = CreateCheckbox(swirls, "Player Buff Swirls", "playerSwirls")
local timers = CreateCheckbox(playerSwirls, "Cooldown Timers", "timers")

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
Settings.RegisterAddOnCategory(category)
