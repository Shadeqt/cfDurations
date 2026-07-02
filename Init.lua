local addonName, addon = ...

-- DB schema + lifecycle, mirroring the sibling addons (cfFrames/cfPlates/cfItemColors): InitDB at
-- ADDON_LOADED (SavedVariables are loaded by then), register the settings GUI, then defer feature
-- setup to PLAYER_ENTERING_WORLD (some Blizzard frames -- compact-raid, portraits -- exist there).
-- Each feature reads its flag once inside its SetupX(), so a disabled feature installs nothing.

-- Single source of truth for cfDurationsDB setting keys (shared by InitDB and the checkboxes in
-- Settings.lua). The target/raid/pet swirls (BuffSwirls.lua) are the always-on base and have no key.
addon.defaults = {
    PlayerSwirls        = true,   -- swirls on the player's own buffs/debuffs
    BuffTimers          = false,  -- custom countdown text on target/raid/pet swirls
    AuraSorting         = true,   -- sort player + target aura icons by remaining time
    CCPortrait          = true,   -- crowd-control icon on unit portraits
    CCCenter            = true,   -- crowd-control icon at screen center
    CCNameplate         = true,   -- crowd-control icon over enemy nameplates
    HideCooldownNumbers = true,   -- suppress Blizzard's cooldown countdown text (outside action bars/bags/bank)
    Discovery           = true,   -- log unknown CC/debuffs to the discovery ledger
}

function addon.InitDB()
    cfDurationsDB = cfDurationsDB or {}
    -- The discovery ledger is not a setting; ensure it exists and never let the prune below touch it.
    cfDurationsDB.discovered = cfDurationsDB.discovered or {}
    -- Merge newly-added defaults.
    for key, value in pairs(addon.defaults) do
        if cfDurationsDB[key] == nil then
            cfDurationsDB[key] = value
        end
    end
    -- Prune keys no longer in the schema (but keep `discovered`, the non-setting ledger).
    for key in pairs(cfDurationsDB) do
        if key ~= "discovered" and addon.defaults[key] == nil then
            cfDurationsDB[key] = nil
        end
    end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    addon.InitDB()
    addon.SetupSettings()   -- register the GUI now that the DB is populated
    -- Defer feature setup to PLAYER_ENTERING_WORLD (compact-raid / portrait frames exist there).
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        addon.SetupHideCooldownNumbers()
        addon.SetupPlayerSwirls()
        addon.SetupBuffTimers()
        addon.SetupPlayerAuraSort()
        addon.SetupTargetAuraSort()
        addon.SetupCCPortrait()
        addon.SetupCCCenter()
        addon.SetupCCNameplate()
        addon.SetupDiscovery()
        addon.SetupDebuffDiscovery()
    end)
end)
