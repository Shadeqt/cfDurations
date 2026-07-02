local _, addon = ...

-- cfDurations settings page: one flat vertical-layout category, one checkbox per feature (the
-- target/raid/pet swirls are the always-on base, so they have no toggle). Every checkbox writes a
-- cfDurationsDB bool that its SetupX() reads at the next reload -- reload-gated, no live callbacks.
-- By request there is NO slash command: the page is reached only via Esc > Options > AddOns >
-- cfDurations (that entry exists purely from RegisterAddOnCategory).

-- Boolean setting bound to cfDurationsDB[key]; reload-gated (no value-changed callback).
local function Checkbox(category, key, label, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, "cfDurations_" .. key, key, cfDurationsDB,
        Settings.VarType.Boolean, label, addon.defaults[key])
    Settings.CreateCheckbox(category, setting, tooltip)
end

local function Header(layout, name)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(name))
end

-- Build the settings page. Called from Init's ADDON_LOADED handler, after InitDB(), so cfDurationsDB
-- is fully populated before any RegisterAddOnSetting reads cfDurationsDB[key] (registering against a
-- nil backing value hands back an unusable setting object).
function addon.SetupSettings()
    local category = Settings.RegisterVerticalLayoutCategory("cfDurations")
    local layout = SettingsPanel:GetLayout(category)

    Header(layout, "Changes apply after /reload.")

    Header(layout, "Swirls")
    Checkbox(category, "PlayerSwirls", "Player Buff/Debuff Swirls", "Cooldown spirals on your own buff and debuff icons (target/raid/pet swirls are always on)")
    Checkbox(category, "BuffTimers", "Buff Timer Text", "Custom countdown numbers on target/raid/pet swirls (white > 60s, yellow, red < 5s)")

    Header(layout, "Sorting")
    Checkbox(category, "AuraSorting", "Aura Sorting", "Sort your own and your target's aura icons by remaining time (shortest expiring first on the target)")

    Header(layout, "Crowd Control")
    Checkbox(category, "CCPortrait", "Portrait Icon", "Show the highest-priority crowd-control on unit portraits (player/target/pet/party/target-of-target)")
    Checkbox(category, "CCCenter", "Screen-Center Icon", "Show the crowd-control affecting you in the middle of the screen")
    Checkbox(category, "CCNameplate", "Nameplate Icon", "Show crowd-control icons over enemy nameplates")

    Header(layout, "Cooldown Numbers")
    Checkbox(category, "HideCooldownNumbers", "Hide Blizzard Cooldown Numbers", "Remove Blizzard's cooldown countdown text everywhere except action bars, bags, and bank (respects your interface setting -- only hides, never forces on)")

    Header(layout, "Discovery")
    Checkbox(category, "Discovery", "Log New CC Discoveries", "Log crowd-control and debuffs not yet in the database, for later review. Uncheck to stop the chat notices")
    -- Export button lives in DiscoveryShare.lua and self-registers here; the guard makes the whole
    -- sharing feature removable (delete that file) without editing this line. See DiscoveryShare.lua.
    if addon.AddExportButton then addon.AddExportButton(category, layout) end

    Settings.RegisterAddOnCategory(category)

    -- Raise the panel above high-strata world UI (matches the other cf addons' settings pages).
    SettingsPanel:SetFrameStrata("FULLSCREEN_DIALOG")

    -- Make the panel draggable by its empty areas (child controls still take their own clicks).
    SettingsPanel:SetMovable(true)
    SettingsPanel:EnableMouse(true)
    SettingsPanel:RegisterForDrag("LeftButton")
    SettingsPanel:SetScript("OnDragStart", SettingsPanel.StartMoving)
    SettingsPanel:SetScript("OnDragStop", SettingsPanel.StopMovingOrSizing)
end
