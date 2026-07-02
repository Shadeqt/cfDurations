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
    },
    [FEAR] = {
        7399,   -- Terrify (creature, 4s; Skeletal Horror 202)
        19134,  -- Intimidating Shout (creature; NOT Warrior 5246)
        29544,  -- Intimidating Shout (creature cower/flee aura; NOT Warrior 20511)
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
    },
    [CONFUSE] = {
        228,    -- Polymorph: Chicken (NPC/special poly; not a learnable Mage rank)
        6728,   -- Enveloping Winds (creature cyclone, 10s, breaks on damage -> CONFUSE not STUN; Kolkar Windchaser 4635)
        25189,  -- Enveloping Winds (same effect, distinct id; Ossirian the Unscarred, AQ20)
        3636,   -- Crystalline Slumber (creature sleep, 15s, breaks on damage; Gritjaw Basilisk 4728)
    },
    [BANISH] = {
        8994,   -- Banish (creature incapacitate, 15s; e.g. Blackrock Shadowcaster on demon pet)
    },
    [SILENCE] = {
        6942,   -- Overwhelming Stench (creature, 6s silence; Felmusk Felsworn 3762)
        3589,   -- Deafening Screech (creature, 8s silence; Screeching Harpy 4100)
    },
    [PACIFY] = {
        10730,  -- Pacify (creature, 10s unable to attack; Peacekeeper Security Suit 6230, Gnomeregan)
    },
    [DISARM] = {
        6713,   -- Disarm (creature, 6s; NOT Warrior Disarm 676; e.g. Defias Prisoner 1706)
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
    },
})
