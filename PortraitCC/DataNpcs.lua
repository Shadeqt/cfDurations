-- NPC / creature ability CC (not class-bound; mostly fed by discovery). Private group merged into
-- addon.ccNpcs and folded into addon.CCType. DATA ONLY -- see Data.lua for vocabulary + SYNC notes.
-- One entry per line; comment names the source.

local _, addon = ...

local STUN, FEAR, CHARM, POSSESS, CONFUSE, BANISH, SILENCE, DISARM, ROOT, SLOW =
      addon.STUN, addon.FEAR, addon.CHARM, addon.POSSESS, addon.CONFUSE, addon.BANISH,
      addon.SILENCE, addon.DISARM, addon.ROOT, addon.SLOW

local ccNpc = {
    [5164]  = STUN,     -- Knockdown (creature 2s stun; cloc reported STUN_MECHANIC, same priority)
    [12024] = ROOT,     -- Net (synced from discovery)
    [6533]  = ROOT,     -- Net (creature; cloc-typed)
    [21030] = SLOW,     -- Frost Shock (creature; NOT Shaman 8056/8058/10472/10473)
    [13322] = SLOW,     -- Frostbolt (creature; NOT a Mage rank, -50%)
    [1604]  = SLOW,     -- Dazed (generic, -50%)
    [8716]  = SLOW,     -- Low Swipe (creature, -50%)
    [7992]  = SLOW,     -- Slowing Poison (creature/item, -30%)
}

addon.ccNpcs = ccNpc
addon.RegisterCC(addon.ccNpcs)
