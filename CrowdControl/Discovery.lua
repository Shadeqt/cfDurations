-- Discovery ledger + cloc feeder. Owns cfDurationsDB.discovered -- the never-wiped ledger of CC
-- spellIds we've seen but don't yet have in CCType. Three feeders write it via addon.Discover (this
-- cloc feeder + the slow detector & catch-all in DebuffDiscovery.lua); a manual sync folds entries
-- into Data.lua. Decisions live in code: an id ends up in a CCType group (added) or in addon.Denied
-- (denied), and the ledger self-prunes those on load -- so it always holds just the un-reviewed
-- queue, no wipe needed.
--
-- An entry's `type` doubles as provenance: a locType (STUN/ROOT/...) = cloc; "SLOW" = the slow
-- detector; nil = the catch-all (any unknown debuff -- classify by name on Wowhead). See the SYNC notes in Data.lua.
--
-- Each entry also records two review aids, filled once and never overwritten:
--   * `on`   -- the unit the aura was first seen on (player/target/pet/partyN). cloc is always player.
--   * `from` -- the caster as { name=, id= }, resolved from UnitAura's caster token. BEST-EFFORT: the
--     token is nil whenever the caster isn't a known unit (not your target/nameplate), and cloc carries
--     no caster at all -- so `from` is often absent. When present it's decisive for the sync: id set =>
--     a creature/NPC ability (the Frost Shock 21030 trap, see Data.lua); from.name == your character =>
--     a self-cast debuff you'll likely Deny. A complete source would need a CLEU SPELL_AURA_APPLIED
--     feed; deferred until best-effort proves insufficient.

local addonName, addon = ...

local CCType = addon.CCType
local Denied = addon.Denied
local GetActiveLossOfControlData = C_LossOfControl.GetActiveLossOfControlData

-- Resolve a UnitAura caster token to { name, id }. id is the NPC id for creature-family casters
-- (Creature/Vehicle/Pet GUIDs carry it at field 6); players have no id, just a name. nil token -> nil.
local function ResolveCaster(token)
    if not token then return nil end
    local name = UnitName(token)
    local guid = UnitGUID(token)
    local id
    if guid then
        local kind, _, _, _, _, npcId = strsplit("-", guid)
        if kind == "Creature" or kind == "Vehicle" or kind == "Pet" then
            id = tonumber(npcId)
        end
    end
    return { name = name, id = id }
end

-- Shared ledger writer for every feeder. Skips ids already handled (in CCType or Denied) or already
-- logged. A typed feeder upgrades an existing untyped (catch-all) entry, so an id the catch-all
-- logged first still gets auto-typed once cloc/slow identifies it. `onUnit` is the target token the
-- aura was seen on; `fromToken` is the caster's unit token (resolved here). Both fill only if absent,
-- so the first good value wins regardless of which feeder/order saw the aura first (a later sighting
-- with a real caster still fills a `from` an earlier nil-caster sighting left empty).
function addon.Discover(spellId, ccType, onUnit, fromToken)
    if not spellId or CCType[spellId] or Denied[spellId] then return end

    local discovered = cfDurationsDB.discovered
    local entry = discovered[spellId]
    local from = ResolveCaster(fromToken)
    if entry then
        if ccType and not entry.type then entry.type = ccType end
        if from and not entry.from then entry.from = from end
        if onUnit and not entry.on then entry.on = onUnit end
        return
    end

    local info = C_Spell.GetSpellInfo(spellId)
    discovered[spellId] = { name = info and info.name, type = ccType, on = onUnit, from = from }
    print(string.format("|cff66ccffcfDurations|r discovered: %s (%d) — %s — on %s%s",
        (info and info.name) or "?", spellId, ccType or "?", onUnit or "?",
        from and (" from "..(from.name or "?")..(from.id and (" ("..from.id..")") or "")) or ""))
end

-- cloc fires only for the player and types its finds for free (locType). Target is always "player";
-- cloc data carries no caster, so `from` is left for the catch-all/slow feeder to fill if it can.
local function ScanLossOfControl()
    for index = 1, DEBUFF_MAX_DISPLAY do
        local data = GetActiveLossOfControlData(index)
        if not data then break end
        addon.Discover(data.spellID, data.locType, "player")
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
