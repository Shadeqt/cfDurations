-- Debuff discovery -- logs unknown harmful auras on every watched unit (player/target/pet/party) to
-- the shared addon.Discover ledger (owned by Discovery.lua) for manual review. One per-unit
-- UNIT_AURA harmful scan feeds two paths: a slow typer and a generic catch-all.
--
--  * SLOW: a newly-applied harmful aura coinciding with a runSpeed-stat DROP to a nonzero value is a
--    movement slow (logged type "SLOW"). runSpeed (2nd return of GetUnitSpeed) is the behavior-free
--    run capability -- stable through walk/run/sprint, dropping only on a snare -- so this works on
--    any unit and catches slows you INFLICT on a target (which never hit you).
--  * catch-all: EVERY present harmful aura is logged untyped for manual review -- not just ones we saw
--    get applied. Both the per-event scan and the baseline reseed feed it, so a debuff already on a
--    unit when it became watched (e.g. you target an already-debuffed enemy) is captured too, not just
--    transitions we witnessed. addon.Discover is idempotent (bails on ids in CCType/Denied or already
--    logged), so re-logging the same aura every UNIT_AURA is cheap. No caster filter, so player-cast
--    CC on a target is caught; the cost is your own DoTs/debuffs land here until you Deny them.
--
-- Stuns/roots don't drop runSpeed (immobilize, not slow), so they never log as SLOW; they fall
-- through to the catch-all (untyped, you classify). See the SYNC notes in Data.lua.

local _, addon = ...

local UnitAura = UnitAura
local PARTY = { "party1", "party2", "party3", "party4" }

-- Aura scans run bound-free: the Classic Era / 20th Anniversary realms removed the buff/debuff limit,
-- so there's no fixed cap on a unit's debuffs. Each loop walks indices until the first nil name.

-- Per unit: run speed and the set of harmful spellIds present, as of that unit's last update.
local cachedRun = {}
local seen = {}

-- The run-speed stat (2nd return) -- stable per unit; reflects buffs/snares, ignores walk/sprint.
local function RunSpeed(unit)
    return select(2, GetUnitSpeed(unit))
end

local function ScanHarmful(unit)
    local set = {}
    local index = 1
    while true do
        local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL")
        if not name then break end
        set[spellId] = true
        index = index + 1
    end
    return set
end

-- (Re)seed a unit's baseline on swaps: reset the runSpeed reference so a new occupant isn't read as
-- a SLOW drop against the old occupant's baseline. It still LOGS every debuff already present (the
-- catch-all is idempotent), so a debuff that was on a unit BEFORE it became watched -- e.g. when you
-- target an already-debuffed enemy -- is captured immediately instead of staying invisible forever.
-- It only suppresses SLOW *typing* here (no runSpeed transition to trust), not logging.
local function Baseline(unit)
    cachedRun[unit] = RunSpeed(unit)
    local set = {}
    local index = 1
    while true do
        local name, _, _, _, _, _, source, _, _, spellId = UnitAura(unit, index, "HARMFUL")
        if not name then break end
        set[spellId] = true
        addon.Discover(spellId, nil, unit, source)
        index = index + 1
    end
    seen[unit] = set
end

-- Per unit on UNIT_AURA: a newly-applied harmful aura coinciding with a runSpeed drop = SLOW;
-- otherwise hand it to the catch-all (untyped). Compare then refresh the unit's cache.
--
-- SINGLE-AURA GUARD: a runSpeed drop only reliably implicates an aura when EXACTLY ONE new harmful
-- aura landed this event. When several land together (a real snare + a coincident DoT, say) we can't
-- tell which caused the drop, so none is auto-typed -- they all go to the untyped catch-all for
-- manual classification. This stops innocent DoTs inheriting a SLOW tag (e.g. Poison 744 did, beside
-- a known daze). runSpeed also drops when a speed buff (mount / aspect / sprint) fades, so even a
-- lone aura can be a false positive -- hence the type is only ever a hint, verified by hand at sync.
--
-- LAG: the drop often lags the aura by a frame or two (more while standing still), so for a lone
-- untyped aura we schedule one deferred re-check against the pre-aura baseline; a late drop while
-- it's still up upgrades it to SLOW. Same single-aura guard applies.
local function OnAura(unit)
    local prior = cachedRun[unit]
    local run = RunSpeed(unit)
    local slowed = prior and run > 0 and run < prior

    -- Scan every present harmful aura. Log them ALL untyped via the catch-all (addon.Discover is
    -- idempotent -- it bails on ids already handled or already logged), so coverage no longer depends
    -- on witnessing the absent->present transition: a debuff present before we started watching the
    -- unit is logged here too. `casterOf` keeps each aura's caster token (UnitAura's 7th return) for
    -- the SLOW upgrade below; `fresh` collects ids newly applied since last event -- needed ONLY to
    -- drive SLOW auto-typing, which requires the transition. `unit` is the target we log as `on`.
    local current, casterOf = {}, {}
    local fresh
    local index = 1
    while true do
        local name, _, _, _, _, _, source, _, _, spellId = UnitAura(unit, index, "HARMFUL")
        if not name then break end
        current[spellId] = true
        casterOf[spellId] = source
        addon.Discover(spellId, nil, unit, source)             -- catch-all: log EVERY unknown debuff
        if not (seen[unit] and seen[unit][spellId]) then       -- newly applied this event
            fresh = fresh or {}
            fresh[#fresh + 1] = spellId
        end
        index = index + 1
    end
    seen[unit] = current
    cachedRun[unit] = run

    if not fresh then return end

    -- SLOW auto-type only: a lone newly-applied aura coinciding with a runSpeed drop is a movement
    -- slow (see SINGLE-AURA GUARD). This upgrades the untyped entry the catch-all just logged.
    local single = #fresh == 1 and fresh[1]
    if single and slowed then
        addon.Discover(single, "SLOW", unit, casterOf[single])  -- lone aura + drop now -> a slow (incl. inflicted)
    end

    -- Lone aura, no drop yet: the drop may lag -- re-check once shortly after against the baseline.
    if single and prior and not slowed then
        C_Timer.After(0.1, function()
            local later = RunSpeed(unit)
            if later > 0 and later < prior and ScanHarmful(unit)[single] then
                addon.Discover(single, "SLOW", unit, casterOf[single])  -- still up + dropped -> upgrade untyped -> SLOW
            end
        end)
    end
end

-- No DB to init here (Discovery.lua owns the ledger) and the frames exist at load, so set up at
-- file scope. addon.Discover only runs at runtime, by when the ledger is initialised.
-- UNIT_AURA must be a plain RegisterEvent + filter, NOT RegisterUnitEvent: RegisterUnitEvent caps at
-- TWO unit tokens, so registering all seven silently dropped most of them -- the player included --
-- which is why player-only CC/slows never logged (cloc covers player loss-of-control but ignores
-- slows, and this scan never fired for "player"). RegisterEvent fires for every unit; we gate to the
-- watched set here. Portrait.lua already uses this same pattern.
local WATCHED = {
    player = true, target = true, pet = true,
    party1 = true, party2 = true, party3 = true, party4 = true,
}

local events = CreateFrame("Frame")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_PET")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        if WATCHED[unit] then OnAura(unit) end
    elseif event == "PLAYER_TARGET_CHANGED" then
        Baseline("target")
    elseif event == "UNIT_PET" then
        Baseline("pet")
    elseif event == "GROUP_ROSTER_UPDATE" then
        for _, member in ipairs(PARTY) do Baseline(member) end
    else -- PLAYER_ENTERING_WORLD: fresh baseline for every unit we watch
        Baseline("player")
        Baseline("target")
        Baseline("pet")
        for _, member in ipairs(PARTY) do Baseline(member) end
    end
end)
