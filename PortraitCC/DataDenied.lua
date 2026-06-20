-- Denied ids -- discovery entries reviewed and judged NOT crowd control. Split out on purpose:
-- this list only grows (every DoT/debuff you ever get hit by lands here once denied) and you never
-- need to read it, so it stays out of the data files you actually edit. addon.Discover skips these
-- forever and Discovery.lua's load-prune drops them from the ledger. Grown at sync: a reviewed id
-- that isn't CC gets `[spellID] = true` here (see the SYNC notes in Data.lua).
--
-- Must load before Discovery.lua (it captures addon.Denied at file scope) -- see cfDurations.toc.

local _, addon = ...

addon.Denied = {
    [133]  = true,  -- Fireball (no slow; the auto-SLOW was a coincident-snare false positive)
    [143]  = true,  -- Fireball (periodic damage)
    [589]  = true,  -- Shadow Word: Pain (DoT)
    [594]  = true,  -- Shadow Word: Pain (DoT)
    [348]  = true,  -- Immolate (fire DoT)
    [772]  = true,  -- Rend (bleed DoT)
    [6016] = true,  -- Pierce Armor (armor -50%)
    [6788] = true,  -- Weakened Soul (shield-immunity lockout)
    [6343] = true,  -- Thunder Clap (-10% melee attack speed only, no movement slow)
    [744]   = true, -- Poison (pure Nature DoT; auto-SLOW was a coincident-drop false positive)
    [3436]  = true, -- Wandering Plague (disease debuff)
    [3429]  = true, -- Plague Mind (mana-drain disease)
    [11196] = true, -- Recently Bandaged (first-aid lockout)
    [7102]  = true, -- Contagion of Rot (attack/cast-speed slow, not movement)
    [8927]  = true, -- Moonfire (Arcane DoT)
    [20300] = true, -- Judgement of the Crusader (holy-damage-taken debuff)
    [21183] = true, -- Judgement of the Crusader (other rank)
    [3105]  = true, -- Curse of Stalvan (-5 all attributes)
    [17390] = true, -- Faerie Fire (Feral) (armor reduction / anti-stealth)
    [6546]  = true, -- Rend (bleed DoT, creature rank)
    [7386]  = true, -- Sunder Armor (armor reduction)
}
