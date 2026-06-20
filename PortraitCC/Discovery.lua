-- Discovery ledger + cloc feeder. Owns cfDurationsDB.discovered -- the never-wiped ledger of CC
-- spellIds we've seen but don't yet have in CCType. Three feeders write it via addon.Discover (this
-- cloc feeder + the slow detector & catch-all in DebuffDiscovery.lua); a manual sync folds entries
-- into Data.lua. Decisions live in code: an id ends up in a CCType group (added) or in addon.Denied
-- (denied), and the ledger self-prunes those on load -- so it always holds just the un-reviewed
-- queue, no wipe needed.
--
-- An entry's `type` doubles as provenance: a locType (STUN/ROOT/...) = cloc; "SLOW" = the slow
-- detector; nil = the catch-all (any unknown debuff -- classify by name on Wowhead). See the SYNC notes in Data.lua.

local addonName, addon = ...

local CCType = addon.CCType
local Denied = addon.Denied
local GetActiveLossOfControlData = C_LossOfControl.GetActiveLossOfControlData

-- Shared ledger writer for every feeder. Skips ids already handled (in CCType or Denied) or already
-- logged. A typed feeder upgrades an existing untyped (catch-all) entry, so an id the catch-all
-- logged first still gets auto-typed once cloc/slow identifies it.
function addon.Discover(spellId, ccType)
    if not spellId or CCType[spellId] or Denied[spellId] then return end

    local discovered = cfDurationsDB.discovered
    local entry = discovered[spellId]
    if entry then
        if ccType and not entry.type then entry.type = ccType end
        return
    end

    local info = C_Spell.GetSpellInfo(spellId)
    discovered[spellId] = { name = info and info.name, type = ccType }
    print(string.format("|cff66ccffcfDurations|r discovered: %s (%d) — %s",
        (info and info.name) or "?", spellId, ccType or "?"))
end

-- cloc fires only for the player and types its finds for free (locType).
local function ScanLossOfControl()
    for index = 1, DEBUFF_MAX_DISPLAY do
        local data = GetActiveLossOfControlData(index)
        if not data then break end
        addon.Discover(data.spellID, data.locType)
    end
end

-- SavedVariables load before ADDON_LOADED, so init + prune here, not at file scope.
EventUtil.ContinueOnAddOnLoaded(addonName, function()
    cfDurationsDB = cfDurationsDB or {}
    cfDurationsDB.discovered = cfDurationsDB.discovered or {}
    cfDurationsDB.discoveredSlows = nil  -- migrated: slows now share the one ledger

    -- Drop anything we've since handled, so the ledger holds only the un-reviewed queue.
    local pending = 0
    for spellId in pairs(cfDurationsDB.discovered) do
        if CCType[spellId] or Denied[spellId] then
            cfDurationsDB.discovered[spellId] = nil
        else
            pending = pending + 1
        end
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
    events:RegisterEvent("PLAYER_LOGIN")  -- chat frame is up by login, so the count is visible
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            if pending > 0 then
                print(string.format("|cff66ccffcfDurations|r %d debuff%s pending review -- see the SYNC notes in Data.lua",
                    pending, pending == 1 and "" or "s"))
            end
        else
            ScanLossOfControl()
        end
    end)
end)
