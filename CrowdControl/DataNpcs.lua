-- NPC / creature ability CC (not class-bound; mostly fed by discovery). Folded into addon.CCType via
-- RegisterCCByType. DATA ONLY -- see Data.lua for vocabulary + SYNC notes. Grouped by type: one type
-- block, spellIds + source comments beneath it.

local _, addon = ...

local STUN, FEAR, CHARM, POSSESS, CONFUSE, BANISH, SILENCE, PACIFY, DISARM, ROOT, SLOW =
      addon.STUN, addon.FEAR, addon.CHARM, addon.POSSESS, addon.CONFUSE, addon.BANISH,
      addon.SILENCE, addon.PACIFY, addon.DISARM, addon.ROOT, addon.SLOW

addon.RegisterCCByType({
    [STUN] = {
        5164,   -- Knockdown (creature 2s stun; cloc reported STUN_MECHANIC, same priority)
        3242,   -- Ravage (creature 2s stun; NOT Druid Ravage 6785)
        3109,   -- Presence of Death (engine aura is Stun; "fear" is flavor text only)
        6432,   -- Smite Stomp (Deadmines / VanCleef stomp, 10s)
        6466,   -- Axe Toss (creature/ogre, 3s)
        6253,   -- Backhand (creature, 2s)
        8242,   -- Shield Slam (creature, 2s; NOT Warrior 23922-23925; seen from Dragonmaw Grunt 2102)
        3609,   -- Paralyzing Poison (creature, 8s "unable to move or attack"; Carrion Recluse 949)
        7964,   -- Smoke Bomb (creature, 4s stun despite the name; Bazil Thredd 1716)
        18812,  -- Knockdown (creature 2s stun; Lesser Felguard 3772; distinct id from 5164)
        6945,   -- Chest Pains (creature 5s stun + shadow damage; Sif 1133)
        6730,   -- Head Butt (creature 2s hard stun; Sparkleshell Snapper 4143)
        5708,   -- Swoop (creature/bird 2s cone hard stun; seen on pet from a bird mob)
        8151,   -- Surprise Attack (creature, 3s stun from stealth; Crag Stalker 4126)
        -- discovered 2026-07-04
        6607,   -- Lash (creature 2s hard stun; Lashtail Raptor 686 / Sunscale Lashtail 3254; cloc STUN_MECHANIC)
        8150,   -- Thundercrack (creature 3s AoE hard stun; Mutanus the Devourer 3654; cloc STUN_MECHANIC)
        8391,   -- Ravage (creature 3s hard stun; Phantasmal Snapjaw 212463; NOT Druid Ravage 6785 / creature 3242)
        6524,   -- Ground Tremor (creature 2s hard stun; Rumbling Exile 2592; cloc STUN_MECHANIC)
        8817,   -- Smoke Bomb (creature 3s hard stun despite the name; Colonel Kurzen 813; cf. 7964)
        440586, -- Bash (generic creature 2s hard stun; level-1/no-cost NPC ability, NOT Druid Bash 5211/6798/8983)
        -- rank-family expansion 2026-07-04 (siblings verified on classicdb/wowhead)
        19128,  -- Knockdown (creature 2s AoE hard stun, up to 5 targets; distinct from 5164/18812)
        24333,  -- Ravage (creature 2s hard stun; NOT Druid Ravage 6785/9007; cf. 3242/8391)
        -- discovered 2026-07-04 (batch 2)
        8646,   -- Snap Kick (creature 2s hard stun, Aura #12; Ashenvale Outrunner 12856; a real stun, NOT an interrupt/silence)
        15618,  -- Snap Kick (creature 2s hard stun; higher-damage sibling of 8646)
        17276,  -- Scald (creature 4s hard stun, Aura #12, + Fire damage; Scalding Elemental 10756)
    },
    [FEAR] = {
        7399,   -- Terrify (creature, 4s; Skeletal Horror 202)
        19134,  -- Intimidating Shout (creature; NOT Warrior 5246)
        29544,  -- Intimidating Shout (creature cower/flee aura; NOT Warrior 20511)
        -- discovered 2026-07-04
        12542,  -- Fear (creature 4s flee; Blindlight Oracle 4820)
        7093,   -- Intimidation (creature 4s flee-in-terror; NOT Hunter Intimidation stun 24394)
        -- rank-family expansion 2026-07-04
        6605,   -- Terrifying Screech (creature 4s AoE flee)
        12096,  -- Fear (creature 8s flee; NOT Warlock Fear 5782/6213/6215)
        26580,  -- Fear (creature 8s AoE flee; e.g. Princess Yauj, AQ40)
    },
    [ROOT] = {
        12024,  -- Net (synced from discovery)
        12023,  -- Web (creature immobilize, 5s; Wildthorn Stalker 3819; NOT Net 12024)
        6533,   -- Net (creature; cloc-typed)
        11831,  -- Frost Nova (creature, 8s; NOT Mage 122/865/6131/10230)
        512,    -- Chains of Ice (creature, 20s; the player DK spell doesn't exist in vanilla)
        11264,  -- Ice Blast (creature, 10s freeze; Mechano-Frostwalker 6227, Gnomeregan)
        11820,  -- Electrified Net (creature, 10s; Mechanized Guardian 6234, Gnomeregan)
        10852,  -- Battle Net (creature, 10s; Techbot 6231, Gnomeregan)
        -- discovered 2026-07-04
        12747,  -- Entangling Roots (creature root + nature DoT; Bristleback Thornweaver 3261; NOT Druid 339..9853)
        12748,  -- Frost Nova (creature root; Bristleback Water Seeker 3260; NOT Mage 122/865/6131/10230; cf. 11831)
        14907,  -- Frost Nova (creature 8s root; Vengeful Surge 2776)
        745,    -- Web (creature 10s root/immobilize; Darkmist Silkspinner 4379; cf. 12023)
        4962,   -- Encasing Webs (creature root; Giant Plains Creeper 2565; attack-speed slow part is not movement)
        -- rank-family expansion 2026-07-04 (creature roots; some webs also silence + attack-slow -- tagged ROOT for the immobilize)
        15063,  -- Frost Nova (creature 8s root; cf. 11831/12748/14907)
        15531,  -- Frost Nova (creature 8s root)
        4167,   -- Web (creature/pet 8s root/immobilize)
        12252,  -- Web Spray (creature cone 10s root; NOT Maexxna stun 29484)
        15609,  -- Hooked Net (creature 10s root; Murloc Netter)
        28991,  -- Web (creature 10s root; higher-level twin of 745)
        15471,  -- Enveloping Web (creature 8s root + silence + attack-slow)
        24110,  -- Enveloping Webs (creature 8s root + silence + attack-slow; High Priestess Mar'li, ZG)
    },
    [CONFUSE] = {
        228,    -- Polymorph: Chicken (NPC/special poly; not a learnable Mage rank)
        6728,   -- Enveloping Winds (creature cyclone, 10s, breaks on damage -> CONFUSE not STUN; Kolkar Windchaser 4635)
        25189,  -- Enveloping Winds (same effect, distinct id; Ossirian the Unscarred, AQ20)
        3636,   -- Crystalline Slumber (creature sleep, 15s, breaks on damage; Gritjaw Basilisk 4728)
        -- discovered 2026-07-04 (sleeps break on damage -> CONFUSE not STUN, even when cloc reports STUN)
        700,    -- Sleep (creature sleep, breaks on damage; e.g. Sleeby 2764; cloc reported STUN)
        8040,   -- Druid's Slumber (creature sleep, breaks on damage; Druid of the Fang 3840; cloc reported STUN)
        15970,  -- Sleep (creature sleep, breaks on damage; Syndicate Conjuror 2590)
        -- rank-family expansion 2026-07-04 (AoE sleeps; break on damage)
        8399,   -- Sleep (creature AoE sleep, breaks on damage; Hakkari, ZG)
        9256,   -- Deep Sleep (creature AoE sleep, breaks on damage; Scarlet Monastery)
    },
    [BANISH] = {
        8994,   -- Banish (creature incapacitate, 15s; e.g. Blackrock Shadowcaster on demon pet)
    },
    [SILENCE] = {
        6942,   -- Overwhelming Stench (creature, 6s silence; Felmusk Felsworn 3762)
        3589,   -- Deafening Screech (creature, 8s silence; Screeching Harpy 4100)
        -- discovered 2026-07-04
        4320,   -- Trelane's Freezing Touch (creature silence + frost DoT; Kor'gresh Coldrage 2793; speed part is attack-speed, not movement)
    },
    [PACIFY] = {
        10730,  -- Pacify (creature, 10s unable to attack; Peacekeeper Security Suit 6230, Gnomeregan)
    },
    [DISARM] = {
        6713,   -- Disarm (creature, 6s; NOT Warrior Disarm 676; e.g. Defias Prisoner 1706)
        8379,   -- Disarm (creature weapon disarm; Muckrake 2421 / Blackfathom Myrmidon 4807; NOT Warrior 676) -- discovered 2026-07-04
    },
    [SLOW] = {
        21030,  -- Frost Shock (creature; NOT Shaman 8056/8058/10472/10473)
        13322,  -- Frostbolt (creature; NOT a Mage rank, -50%)
        20792,  -- Frostbolt (creature, -50%; NOT a Mage rank either)
        1604,   -- Dazed (generic, -50%)
        8716,   -- Low Swipe (creature, -50%)
        7992,   -- Slowing Poison (creature/item, -30%)
        5159,   -- Melt Ore (creature, -40% movement; also carries a fire DoT)
        9080,   -- Hamstring (creature, -60% movement; NOT Warrior 1715/7372/7373)
        11436,  -- Slow (creature, -60% movement; the Mage "Slow" doesn't exist in vanilla)
        3604,   -- Tendon Rip (creature, -25% movement; a snare despite the "Rip" name)
        6907,   -- Diseased Slime (creature, -25% movement + attack-speed slow; Rotting Slime 3928)
        10734,  -- Hail Storm (creature, -50% movement, 3s; Mechano-Frostwalker 6227, Gnomeregan)
        10855,  -- Lag (creature, -60% movement; Techbot 6231; "snared" mechanic, Gnomeregan)
        11638,  -- Radiation Poisoning (creature, -70% movement + Nature DoT, 25s; Gnomeregan)
        20819,  -- Frostbolt (creature, -50% movement, 4s; NOT a Mage rank; from npc 314)
        12548,  -- Frost Shock (creature, -50% movement, 8s; NOT Shaman 8056/8058/10472/10473; Drysnap Crawler 11562)
        20297,  -- Frostbolt (creature, -50% movement, 4s; NOT a Mage rank; distinct id from 13322/20792/20819)
        9462,   -- Mirefin Fungus (creature, -50% movement, 8s; Mirefin Murloc 4359)
        -- discovered 2026-07-04 (creature movement snares; run-speed decrease on target)
        9672,   -- Frostbolt (creature -50% run speed; Syndicate Magus 2591 / Twilight Aquamancer 4811)
        15043,  -- Frostbolt (creature -50% run speed; Blackfathom Tide Priestess 207358)
        20822,  -- Frostbolt (creature -50% run speed; Drywhisker Surveyor 2573)
        8398,   -- Frostbolt Volley (creature AoE -50% run speed; Phantasmal Servant 212461)
        404316, -- Greater Frostbolt (creature -40% run speed; Baron Aquanis 202699, BFD)
        406680, -- Frostbolt (creature run-speed snare; Fathom Elemental 202838, BFD)
        407819, -- Frost Arrow (creature -19% run speed; Lady Sarevess 204068, BFD)
        426495, -- Shadowy Chains (creature -59% run speed snare, NOT a root; Twilight Lord Kelris 209678, BFD)
        -- rank-family expansion 2026-07-04 (more creature Frostbolt/Frost Shock/Chilled movement snares)
        11538,  -- Frostbolt (creature -50% run speed, 4s)
        12675,  -- Frostbolt (creature -50% run speed, 4s)
        15497,  -- Frostbolt (creature -50% run speed, 4s)
        17503,  -- Frostbolt (creature -50% run speed, 4s)
        20806,  -- Frostbolt (creature -50% run speed, 4s; cf. 20792/20819/20822)
        21369,  -- Frostbolt (creature -50% run speed, 4s)
        24942,  -- Frostbolt (creature -50% run speed, 4s)
        28478,  -- Frostbolt (Kel'Thuzad single-target -65% run speed, 4s; Naxxramas)
        28479,  -- Frostbolt (Kel'Thuzad AoE -50% run speed, 4s; Naxxramas)
        15089,  -- Frost Shock (creature -50% run speed, 8s; cf. 12548/21030)
        19133,  -- Frost Shock (creature -50% run speed, 8s)
        23115,  -- Frost Shock (creature -50% run speed, 8s)
        20005,  -- Chilled (creature -30% run speed + attack-slow, 5s)
        -- discovered 2026-07-04 (batch 2)
        8078,   -- Thunderclap (creature -40% run speed, 10s; also carries an attack-speed slow -- the movement part qualifies; NOT damage-only Thunderclap 8732)
        23931,  -- Thunderclap (creature -60% run speed, 10s; slow-carrying sibling of 8078; NOT damage-only 8732)
    },
})
