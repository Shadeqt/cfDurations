cfDurations = cfDurations or {}
local addon = cfDurations

addon.KEYS = {
	BUFF_SWIRLS        = "swirls",
	PLAYER_BUFF_SWIRLS = "playerSwirls",
	TIMERS             = "timers",
}

local defaults = {
	[addon.KEYS.BUFF_SWIRLS]        = true,
	[addon.KEYS.PLAYER_BUFF_SWIRLS] = true,
	[addon.KEYS.TIMERS]             = true,
}

cfDurationsDB = cfDurationsDB or {}
for key, value in pairs(defaults) do
	if cfDurationsDB[key] == nil then
		cfDurationsDB[key] = value
	end
end
for key in pairs(cfDurationsDB) do
	if defaults[key] == nil then
		cfDurationsDB[key] = nil
	end
end

addon.db = cfDurationsDB

EventUtil.ContinueOnAddOnLoaded("cfDurations", function()
	addon.InitSettings()
	if addon.db[addon.KEYS.BUFF_SWIRLS]        then addon.EnableBuffSwirls()        end
	if addon.db[addon.KEYS.PLAYER_BUFF_SWIRLS] then addon.EnablePlayerBuffSwirls() end
	if addon.db[addon.KEYS.TIMERS]             then addon.EnableTimers()            end
end)
