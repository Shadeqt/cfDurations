-- NPC / creature ability CC (not class-bound; mostly fed by discovery). Private group merged into
-- addon.ccNpcs and folded into addon.CCType. DATA ONLY -- see Data.lua for vocabulary + SYNC notes.
-- One entry per line; comment names the source.

local _, addon = ...

local STUN, FEAR, CHARM, POSSESS, CONFUSE, BANISH, SILENCE, DISARM, ROOT, SLOW =
      addon.STUN, addon.FEAR, addon.CHARM, addon.POSSESS, addon.CONFUSE, addon.BANISH,
      addon.SILENCE, addon.DISARM, addon.ROOT, addon.SLOW

local ccNpc = {
    -- Stuns
    [5164]  = STUN,     -- Knockdown (creature 2s stun; cloc reported STUN_MECHANIC, same priority)
    [3242]  = STUN,     -- Ravage (creature 2s stun; NOT Druid Ravage 6785)
    [3109]  = STUN,     -- Presence of Death (engine aura is Stun; "fear" is flavor text only)
    [6432]  = STUN,     -- Smite Stomp (Deadmines / VanCleef stomp, 10s)
    [6466]  = STUN,     -- Axe Toss (creature/ogre, 3s)
    [6253]  = STUN,     -- Backhand (creature, 2s)
    [8242]  = STUN,     -- Shield Slam (creature, 2s; NOT Warrior 23922-23925; seen from Dragonmaw Grunt 2102)
    [3609]  = STUN,     -- Paralyzing Poison (creature, 8s "unable to move or attack"; Carrion Recluse 949)
    [7964]  = STUN,     -- Smoke Bomb (creature, 4s stun despite the name; Bazil Thredd 1716)
    -- Fears
    [7399]  = FEAR,     -- Terrify (creature, 4s; Skeletal Horror 202)
    [19134] = FEAR,     -- Intimidating Shout (creature; NOT Warrior 5246)
    [29544] = FEAR,     -- Intimidating Shout (creature cower/flee aura; NOT Warrior 20511)
    -- Roots
    [12024] = ROOT,     -- Net (synced from discovery)
    [6533]  = ROOT,     -- Net (creature; cloc-typed)
    [11831] = ROOT,     -- Frost Nova (creature, 8s; NOT Mage 122/865/6131/10230)
    [512]   = ROOT,     -- Chains of Ice (creature, 20s; the player DK spell doesn't exist in vanilla)
    -- Confuse / incapacitate
    [228]   = CONFUSE,  -- Polymorph: Chicken (NPC/special poly; not a learnable Mage rank)
    -- Banish
    [8994]  = BANISH,   -- Banish (creature incapacitate, 15s; e.g. Blackrock Shadowcaster on demon pet)
    -- Disarm
    [6713]  = DISARM,   -- Disarm (creature, 6s; NOT Warrior Disarm 676; e.g. Defias Prisoner 1706)
    -- Slows (movement)
    [21030] = SLOW,     -- Frost Shock (creature; NOT Shaman 8056/8058/10472/10473)
    [13322] = SLOW,     -- Frostbolt (creature; NOT a Mage rank, -50%)
    [20792] = SLOW,     -- Frostbolt (creature, -50%; NOT a Mage rank either)
    [1604]  = SLOW,     -- Dazed (generic, -50%)
    [8716]  = SLOW,     -- Low Swipe (creature, -50%)
    [7992]  = SLOW,     -- Slowing Poison (creature/item, -30%)
    [5159]  = SLOW,     -- Melt Ore (creature, -40% movement; also carries a fire DoT)
    [9080]  = SLOW,     -- Hamstring (creature, -60% movement; NOT Warrior 1715/7372/7373)
    [11436] = SLOW,     -- Slow (creature, -60% movement; the Mage "Slow" doesn't exist in vanilla)
    [3604]  = SLOW,     -- Tendon Rip (creature, -25% movement; a snare despite the "Rip" name)
}

addon.ccNpcs = ccNpc
addon.RegisterCC(addon.ccNpcs)
