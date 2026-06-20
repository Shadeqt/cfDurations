-- Item CC -- engineering gadgets, trinkets, thrown items, etc. (the spell the item CASTS, by
-- spellId -- not the item id). Private group merged into addon.ccItems and folded into CCType.
-- DATA ONLY -- see Data.lua for the TYPE VOCABULARY and SYNC notes. One entry per line.
--
-- TODO (next pass): populate with engineering items / trinkets, e.g.
--   Net-o-Matic, Gnomish Mind Control Cap, Iron/Big Iron Bomb stuns, Goblin/Gnomish grenades,
--   Net-o-Matic, Tidal Charm, Carrot on a Stick is a buff (skip), etc. Verify each spellId +
--   mechanic on classicdb before adding, same standard as the class data.

local _, addon = ...

local STUN, FEAR, CHARM, POSSESS, CONFUSE, BANISH, SILENCE, DISARM, ROOT, SLOW =
      addon.STUN, addon.FEAR, addon.CHARM, addon.POSSESS, addon.CONFUSE, addon.BANISH,
      addon.SILENCE, addon.DISARM, addon.ROOT, addon.SLOW

local ccItems = {
    -- (empty for now -- populated in the engineering-items pass)
}

addon.ccItems = ccItems
addon.RegisterCC(addon.ccItems)
