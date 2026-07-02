-- Item CC -- engineering gadgets, trinkets, thrown items, etc. (the spell the item CASTS, by spellId
-- -- not the item id). Folded into addon.CCType via RegisterCCByType. DATA ONLY -- see Data.lua for
-- the TYPE VOCABULARY and SYNC notes. Grouped by type: one type block, spellIds + comments beneath it.
--
-- TODO (next pass): populate with engineering items / trinkets, e.g. Net-o-Matic, Gnomish Mind Control
--   Cap, more bomb/grenade ranks, Tidal Charm, etc. Verify each spellId + mechanic on classicdb before
--   adding, same standard as the class data.
--   NOTE: engineering bomb/grenade "stuns" BREAK ON DAMAGE -> classify them CONFUSE (like Gouge), not
--   STUN. STUN is reserved for hard stuns that don't break on damage.

local _, addon = ...

local STUN, FEAR, CHARM, POSSESS, CONFUSE, BANISH, SILENCE, DISARM, ROOT, SLOW =
      addon.STUN, addon.FEAR, addon.CHARM, addon.POSSESS, addon.CONFUSE, addon.BANISH,
      addon.SILENCE, addon.DISARM, addon.ROOT, addon.SLOW

addon.RegisterCCByType({
    [CONFUSE] = {  -- engineering bomb stuns break on damage -> CONFUSE, not STUN (see NOTE above)
        4064,   -- Rough Copper Bomb (engineering thrown bomb, 1s AoE stun, breaks on damage)
        4066,   -- Small Bronze Bomb (engineering thrown bomb, 2s AoE stun, breaks on damage)
        4068,   -- Iron Grenade (engineering thrown, 3s AoE stun, breaks on damage; item 4393)
    },
})
