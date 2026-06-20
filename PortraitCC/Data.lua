-- Crowd-control classification -- SHARED FOUNDATION. Loads first; the per-source data files
-- (DataClasses / DataItems / DataNpcs) pull the tokens below, define their entries, and fold
-- themselves into addon.CCType. DATA ONLY -- no logic (display lives in Display.lua; discovery in
-- Discovery.lua + DebuffDiscovery.lua).
--
-- CCType maps spellId -> CC type for every CC/slow aura we want to show on a portrait, built BY
-- HAND. Sources, cross-checked: LibClassicDurations (Libs/, all ranks + ids) and classicdb.ch
-- (clean vanilla 1.12) for classification. The discovery feeders log unrecognized spellIds to
-- cfDurationsDB.discovered as you play, to catch what the references miss. Match is by spellId only
-- -- localization-proof; all ranks are listed since UnitAura can return any rank.
--
-- TYPE VOCABULARY = Blizzard's C_LossOfControl `locType` strings (so a discovered spellId folds in
-- with no translation) plus two labels cloc never reports for the player, so we own them: SLOW
-- (cloc has no concept of slows; the runSpeed detector discovers them) and BANISH (no cloc locType,
-- and players can't be banished -- only enemy Demons/Elementals -- so cloc never surfaces it).
-- Everything else is a real cloc locType used verbatim. The tokens are defined ONCE here and
-- exposed on addon; each Data* file pulls them so the vocabulary lives in exactly one place.
--
-- ============================================================================================
-- SYNC ("sync abilities from db") -- promote discovered ids into the data files. The ledger is
-- never wiped; decisions live here in code, and the ledger self-prunes handled ids on load.
--   1. In-game: /reload   (flush cfDurationsDB to disk)
--   2. Read: _classic_era_\WTF\Account\100356320#1\SavedVariables\cfDurations.lua
--        cfDurationsDB.discovered[spellID] = { name=, type= }
--        `type` is provenance + classification: a locType (STUN/ROOT/...) = cloc; "SLOW" = the
--        runSpeed detector; nil = catch-all (any unknown debuff -- classify by name on Wowhead).
--   3. VERIFY EVERY id on Wowhead/classicdb first -- NO EXCEPTIONS, including the auto-typed ones.
--      The `type` field is only a hint: the slow detector mistypes (a coincident snare typed
--      Fireball as SLOW), and names don't tell you the source (creature Frost Shock 21030 is NOT
--      the Shaman spell). Look up name, effect/mechanic, and whether it's a player/creature/item
--      ability before deciding.
--   4. For each entry, decide:
--        keep -> add  [spellID] = <type>  to the matching file (DataClasses / DataItems / DataNpcs)
--        skip -> add  [spellID] = true    to addon.Denied in DataDenied.lua
--      No status, no wipe: on next load the ledger drops anything now in CCType or Denied.
-- ============================================================================================

local _, addon = ...

-- Strict priority order, highest shows; a tie (same rank active at once) breaks on longest
-- remaining (decided in Display.lua). Keyed by the type vocabulary; every cloc locType and our own
-- labels carry a rank, so any value discovered via C_LossOfControl always resolves.
addon.CCPriority = {
    STUN = 100, STUN_MECHANIC = 100,
    FEAR = 90, FEAR_MECHANIC = 90,
    CHARM = 80, POSSESS = 80,
    CONFUSE = 70,
    BANISH = 60,
    SILENCE = 50, PACIFY = 50, PACIFYSILENCE = 50,
    DISARM = 30,
    ROOT = 20,
    SLOW = 10,
}

-- Shared CC type tokens, exposed for the Data* files so entries read [id] = STUN with the
-- vocabulary defined in one place. (Value == name; CCPriority above keys on the same strings.)
addon.STUN    = "STUN"
addon.FEAR    = "FEAR"
addon.CHARM   = "CHARM"
addon.POSSESS = "POSSESS"
addon.CONFUSE = "CONFUSE"
addon.BANISH  = "BANISH"
addon.SILENCE = "SILENCE"
addon.DISARM  = "DISARM"
addon.ROOT    = "ROOT"
addon.SLOW    = "SLOW"

-- The single flat lookup the display + discovery read. The Data* files (loaded after this, see
-- cfDurations.toc) fold their per-source tables into it via addon.RegisterCC below.
addon.CCType = {}

-- Each Data* file calls this with its exposed table (addon.ccClasses / ccItems / ccNpcs) to merge
-- its entries into the shared CCType. Kept here so the merge rule lives in one place.
function addon.RegisterCC(source)
    for spellId, ccType in pairs(source) do
        addon.CCType[spellId] = ccType
    end
end
