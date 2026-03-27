cfDurations = {}

local DEFAULTS = {
	swirls = true,
	playerSwirls = true,
	timers = true,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
	if loadedAddon ~= "cfDurations" then return end
	self:UnregisterEvent("ADDON_LOADED")

	cfDurationsDB = cfDurationsDB or {}

	for key, value in pairs(DEFAULTS) do
		if cfDurationsDB[key] == nil then
			cfDurationsDB[key] = value
		end
	end

	for key in pairs(cfDurationsDB) do
		if DEFAULTS[key] == nil then
			cfDurationsDB[key] = nil
		end
	end

	if cfDurationsDB.swirls then cfDurations.initSwirls() end
	if cfDurationsDB.playerSwirls then cfDurations.initPlayerSwirls() end
	if cfDurationsDB.timers then cfDurations.initTimers() end
end)
