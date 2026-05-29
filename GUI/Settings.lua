local addon = cfDurations
local K = addon.KEYS
local F = addon.GUI

function addon.InitSettings()
	local panel = CreateFrame("Frame", "cfDurationsSettingsPanel")
	panel.name = "cfDurations"
	panel:Hide()

	local title = F.Title(panel, "cfDurations")

	local swirls = F.Checkbox(panel, title, "Buff Swirls (Target/Pet/Raid)", K.BUFF_SWIRLS, {
		onEnable = addon.EnableBuffSwirls, onDisable = addon.DisableBuffSwirls,
	})
	local playerSwirls = F.Checkbox(panel, swirls, "Player Buff Swirls", K.PLAYER_BUFF_SWIRLS, {
		onEnable = addon.EnablePlayerBuffSwirls, onDisable = addon.DisablePlayerBuffSwirls,
	})
	F.Checkbox(panel, playerSwirls, "Cooldown Timers", K.TIMERS, {
		onEnable = addon.EnableTimers, onDisable = addon.DisableTimers,
	})

	panel:SetScript("OnShow", F.MakeSettingsPanelDraggable)

	local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
	Settings.RegisterAddOnCategory(category)
end
