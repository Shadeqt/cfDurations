-- Per-class CC/slow classification. Private cc<Class> groups, merged into addon.ccClasses and
-- folded into addon.CCType. DATA ONLY -- see Data.lua for the TYPE VOCABULARY and SYNC notes.
-- One rank per line; each comment names the exact rank.

local _, addon = ...

-- Pull the shared type tokens (defined once in Data.lua) so entries read [id] = STUN.
local STUN, FEAR, CHARM, POSSESS, CONFUSE, BANISH, SILENCE, DISARM, ROOT, SLOW =
      addon.STUN, addon.FEAR, addon.CHARM, addon.POSSESS, addon.CONFUSE, addon.BANISH,
      addon.SILENCE, addon.DISARM, addon.ROOT, addon.SLOW

local ccDruid = {
    [5211]  = STUN,     -- Bash (Rank 1)
    [6798]  = STUN,     -- Bash (Rank 2)
    [8983]  = STUN,     -- Bash (Rank 3)
    [9005]  = STUN,     -- Pounce (Rank 1)
    [9823]  = STUN,     -- Pounce (Rank 2)
    [9827]  = STUN,     -- Pounce (Rank 3)
    [16922] = STUN,     -- Starfire Stun (Improved Starfire talent proc)
    [2637]  = CONFUSE,  -- Hibernate (Rank 1)
    [18657] = CONFUSE,  -- Hibernate (Rank 2)
    [18658] = CONFUSE,  -- Hibernate (Rank 3)
    [339]   = ROOT,     -- Entangling Roots (Rank 1)
    [1062]  = ROOT,     -- Entangling Roots (Rank 2)
    [5195]  = ROOT,     -- Entangling Roots (Rank 3)
    [5196]  = ROOT,     -- Entangling Roots (Rank 4)
    [9852]  = ROOT,     -- Entangling Roots (Rank 5)
    [9853]  = ROOT,     -- Entangling Roots (Rank 6)
    [19675] = ROOT,     -- Feral Charge Effect
}

local ccHunter = {
    [24394] = STUN,     -- Intimidation
    [19410] = STUN,     -- Concussive Shot (Improved Concussive stun proc)
    [1513]  = FEAR,     -- Scare Beast (Rank 1)
    [14326] = FEAR,     -- Scare Beast (Rank 2)
    [14327] = FEAR,     -- Scare Beast (Rank 3)
    [19386] = CONFUSE,  -- Wyvern Sting sleep (Rank 1)  (DoT 24131/24134/24135 excluded)
    [24132] = CONFUSE,  -- Wyvern Sting sleep (Rank 2)
    [24133] = CONFUSE,  -- Wyvern Sting sleep (Rank 3)
    [3355]  = CONFUSE,  -- Freezing Trap Effect (Rank 1)  (not trap-lay spell 1499)
    [14308] = CONFUSE,  -- Freezing Trap Effect (Rank 2)
    [14309] = CONFUSE,  -- Freezing Trap Effect (Rank 3)
    [19503] = CONFUSE,  -- Scatter Shot
    [19229] = ROOT,     -- Wing Clip (Improved Wing Clip root proc)
    [19306] = ROOT,     -- Counterattack (Rank 1)
    [20909] = ROOT,     -- Counterattack (Rank 2)
    [20910] = ROOT,     -- Counterattack (Rank 3)
    [19185] = ROOT,     -- Entrapment
    [25999] = ROOT,     -- Boar Charge (pet)
    [2974]  = SLOW,     -- Wing Clip (Rank 1)
    [14267] = SLOW,     -- Wing Clip (Rank 2)
    [14268] = SLOW,     -- Wing Clip (Rank 3)
    [5116]  = SLOW,     -- Concussive Shot
    [13810] = SLOW,     -- Frost Trap Aura
    [15571] = SLOW,     -- Aspect daze (Cheetah / Pack)
    [407548] = SLOW,    -- Freezing Arrow (SoD rune; -9% run-speed snare component -- the freeze incapacitate is a separate id) -- discovered 2026-07-04
}

local ccMage = {
    [118]   = CONFUSE,  -- Polymorph (Rank 1)
    [12824] = CONFUSE,  -- Polymorph (Rank 2)
    [12825] = CONFUSE,  -- Polymorph (Rank 3)
    [12826] = CONFUSE,  -- Polymorph (Rank 4)
    [28271] = CONFUSE,  -- Polymorph: Turtle
    [28272] = CONFUSE,  -- Polymorph: Pig
    [28270] = CONFUSE,  -- Polymorph: Cow (may be unobtainable in Era; harmless)
    [18469] = SILENCE,  -- Counterspell - Silenced (Improved Counterspell)
    [122]   = ROOT,     -- Frost Nova (Rank 1)
    [865]   = ROOT,     -- Frost Nova (Rank 2)
    [6131]  = ROOT,     -- Frost Nova (Rank 3)
    [10230] = ROOT,     -- Frost Nova (Rank 4)
    [12494] = ROOT,     -- Frostbite (talent proc)
    [116]   = SLOW,     -- Frostbolt (Rank 1)
    [205]   = SLOW,     -- Frostbolt (Rank 2)
    [837]   = SLOW,     -- Frostbolt (Rank 3)
    [7322]  = SLOW,     -- Frostbolt (Rank 4)
    [8406]  = SLOW,     -- Frostbolt (Rank 5)
    [8407]  = SLOW,     -- Frostbolt (Rank 6)
    [8408]  = SLOW,     -- Frostbolt (Rank 7)
    [10179] = SLOW,     -- Frostbolt (Rank 8)
    [10180] = SLOW,     -- Frostbolt (Rank 9)
    [10181] = SLOW,     -- Frostbolt (Rank 10)
    [25304] = SLOW,     -- Frostbolt (Rank 11)
    [120]   = SLOW,     -- Cone of Cold (Rank 1)
    [8492]  = SLOW,     -- Cone of Cold (Rank 2)
    [10159] = SLOW,     -- Cone of Cold (Rank 3)
    [10160] = SLOW,     -- Cone of Cold (Rank 4)
    [10161] = SLOW,     -- Cone of Cold (Rank 5)
    [11113] = SLOW,     -- Blast Wave (Rank 1, daze -50%)
    [13018] = SLOW,     -- Blast Wave (Rank 2)
    [13019] = SLOW,     -- Blast Wave (Rank 3)
    [13020] = SLOW,     -- Blast Wave (Rank 4)
    [13021] = SLOW,     -- Blast Wave (Rank 5)
    [6136]  = SLOW,     -- Chilled (Frost Armor proc)
    [7321]  = SLOW,     -- Chilled (Ice Armor proc)
    [12484] = SLOW,     -- Chilled (Improved Blizzard, Rank 1)
    [12485] = SLOW,     -- Chilled (Improved Blizzard, Rank 2)
    [12486] = SLOW,     -- Chilled (Improved Blizzard, Rank 3)
    [412532] = SLOW,    -- Spellfrost Bolt (SoD rune; -39% run-speed snare on target) -- discovered 2026-07-04
}

local ccPaladin = {
    [853]   = STUN,     -- Hammer of Justice (Rank 1)
    [5588]  = STUN,     -- Hammer of Justice (Rank 2)
    [5589]  = STUN,     -- Hammer of Justice (Rank 3)
    [10308] = STUN,     -- Hammer of Justice (Rank 4)
    [2878]  = FEAR,     -- Turn Undead (Rank 1)  (undead targets only)
    [5627]  = FEAR,     -- Turn Undead (Rank 2)
    [10326] = FEAR,     -- Turn Undead (Rank 3)
    [20066] = CONFUSE,  -- Repentance (incapacitate mechanic; Ret lvl-40 talent)
    [20170] = STUN,     -- Seal of Justice stun proc (2s)
}

local ccPriest = {
    [9484]  = STUN,     -- Shackle Undead (Rank 1)  (undead only; frozen in place)
    [9485]  = STUN,     -- Shackle Undead (Rank 2)
    [10955] = STUN,     -- Shackle Undead (Rank 3)
    [15269] = STUN,     -- Blackout (Shadow talent proc)
    [8122]  = FEAR,     -- Psychic Scream (Rank 1)
    [8124]  = FEAR,     -- Psychic Scream (Rank 2)
    [10888] = FEAR,     -- Psychic Scream (Rank 3)
    [10890] = FEAR,     -- Psychic Scream (Rank 4)
    [605]   = POSSESS,  -- Mind Control (Rank 1)
    [10911] = POSSESS,  -- Mind Control (Rank 2)
    [10912] = POSSESS,  -- Mind Control (Rank 3)
    [15487] = SILENCE,  -- Silence
    [15407] = SLOW,     -- Mind Flay (Rank 1, -50%)
    [17311] = SLOW,     -- Mind Flay (Rank 2)
    [17312] = SLOW,     -- Mind Flay (Rank 3)
    [17313] = SLOW,     -- Mind Flay (Rank 4)
    [17314] = SLOW,     -- Mind Flay (Rank 5)
    [18807] = SLOW,     -- Mind Flay (Rank 6)
}

local ccRogue = {
    [1833]  = STUN,     -- Cheap Shot
    [408]   = STUN,     -- Kidney Shot (Rank 1)
    [8643]  = STUN,     -- Kidney Shot (Rank 2)
    [6770]  = CONFUSE,  -- Sap (Rank 1, incapacitate)
    [2070]  = CONFUSE,  -- Sap (Rank 2)
    [11297] = CONFUSE,  -- Sap (Rank 3)
    [2094]  = CONFUSE,  -- Blind (disoriented)
    [1776]  = CONFUSE,  -- Gouge (Rank 1, incapacitate)
    [1777]  = CONFUSE,  -- Gouge (Rank 2)
    [8629]  = CONFUSE,  -- Gouge (Rank 3)
    [11285] = CONFUSE,  -- Gouge (Rank 4)
    [11286] = CONFUSE,  -- Gouge (Rank 5)
    [18425] = SILENCE,  -- Kick - Silenced (Improved Kick)
    [14251] = DISARM,   -- Riposte
    [3409]  = SLOW,     -- Crippling Poison (Rank 1, -50%)
    [11201] = SLOW,     -- Crippling Poison (Rank 2)
    [408699] = SLOW,    -- Waylay (SoD rune; -50% run-speed snare on target) -- discovered 2026-07-04
}

local ccShaman = {
    [8056]  = SLOW,     -- Frost Shock (Rank 1)  (player; creature 21030 lives in DataNpcs)
    [8058]  = SLOW,     -- Frost Shock (Rank 2)
    [10472] = SLOW,     -- Frost Shock (Rank 3)
    [10473] = SLOW,     -- Frost Shock (Rank 4)
    [8034]  = SLOW,     -- Frostbrand Attack (Rank 1, -25%)
    [8037]  = SLOW,     -- Frostbrand Attack (Rank 2)
    [10458] = SLOW,     -- Frostbrand Attack (Rank 3)
    [16352] = SLOW,     -- Frostbrand Attack (Rank 4)
    [16353] = SLOW,     -- Frostbrand Attack (Rank 5)
    [3600]  = SLOW,     -- Earthbind (Earthbind Totem, -50%)
}

local ccWarlock = {
    [5782]  = FEAR,     -- Fear (Rank 1)
    [6213]  = FEAR,     -- Fear (Rank 2)
    [6215]  = FEAR,     -- Fear (Rank 3)
    [5484]  = FEAR,     -- Howl of Terror (Rank 1)
    [17928] = FEAR,     -- Howl of Terror (Rank 2)
    [6789]  = FEAR,     -- Death Coil (Rank 1, horror)
    [17925] = FEAR,     -- Death Coil (Rank 2)
    [17926] = FEAR,     -- Death Coil (Rank 3)
    [6358]  = CONFUSE,  -- Seduction (Succubus; mez, breaks on damage)
    [710]   = BANISH,   -- Banish (Rank 1)  (Demons/Elementals only)
    [18647] = BANISH,   -- Banish (Rank 2)
    [24259] = SILENCE,  -- Spell Lock (Felhunter)
    [18223] = SLOW,     -- Curse of Exhaustion
}

local ccWarrior = {
    [7922]  = STUN,     -- Charge Stun
    [20253] = STUN,     -- Intercept Stun (Rank 1)
    [20614] = STUN,     -- Intercept Stun (Rank 2)
    [20615] = STUN,     -- Intercept Stun (Rank 3)
    [12809] = STUN,     -- Concussion Blow
    [12798] = STUN,     -- Revenge Stun (Improved Revenge proc)
    [5246]  = FEAR,     -- Intimidating Shout (main-target fear)
    [20511] = FEAR,     -- Intimidating Shout (cower AoE)
    [18498] = SILENCE,  -- Shield Bash - Silenced (Improved Shield Bash)
    [676]   = DISARM,   -- Disarm
    [23694] = ROOT,     -- Improved Hamstring (immobilize proc)
    [1715]  = SLOW,     -- Hamstring (Rank 1, -40%)
    [7372]  = SLOW,     -- Hamstring (Rank 2)
    [7373]  = SLOW,     -- Hamstring (Rank 3)
    [12323] = SLOW,     -- Piercing Howl (-50%)
}

-- Expose one merged table, then fold it into the shared CCType (see Data.lua).
addon.ccClasses = {}
for _, group in ipairs({ ccDruid, ccHunter, ccMage, ccPaladin, ccPriest,
                         ccRogue, ccShaman, ccWarlock, ccWarrior }) do
    for spellId, ccType in pairs(group) do addon.ccClasses[spellId] = ccType end
end
addon.RegisterCC(addon.ccClasses)
