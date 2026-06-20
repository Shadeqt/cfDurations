-- Debuff discovery -- logs unknown harmful auras on every watched unit (player/target/pet/party) to
-- the shared addon.Discover ledger (owned by Discovery.lua) for manual review. One per-unit
-- UNIT_AURA harmful scan feeds two paths: a slow typer and a generic catch-all.
--
--  * SLOW: a newly-applied harmful aura coinciding with a runSpeed-stat DROP to a nonzero value is a
--    movement slow (logged type "SLOW"). runSpeed (2nd return of GetUnitSpeed) is the behavior-free
--    run capability -- stable through walk/run/sprint, dropping only on a snare -- so this works on
--    any unit and catches slows you INFLICT on a target (which never hit you).
--  * catch-all: any OTHER newly-applied harmful aura is logged untyped for manual review -- the
--    long-tail net for CC we don't yet know, on any unit. No caster filter: the only auto-skip is
--    "already handled" (addon.Discover bails on ids in CCType/Denied), so player-cast CC on a target
--    is caught too. The cost is that your own DoTs/debuffs also land here until you Deny them.
--
-- Stuns/roots don't drop runSpeed (immobilize, not slow), so they never log as SLOW; they fall
-- through to the catch-all (untyped, you classify). See the SYNC notes in Data.lua.

local _, addon = ...

local UnitAura = UnitAura
local MAX_AURAS = addon.MAX_AURAS
local PARTY = { "party1", "party2", "party3", "party4" }

-- Per unit: run speed and the set of harmful spellIds present, as of that unit's last update.
local cachedRun = {}
local seen = {}

-- The run-speed stat (2nd return) -- stable per unit; reflects buffs/snares, ignores walk/sprint.
local function RunSpeed(unit)
    return select(2, GetUnitSpeed(unit))
end

local function ScanHarmful(unit)
    local set = {}
    for index = 1, MAX_AURAS do
        local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL")
        if not name then break end
        set[spellId] = true
    end
    return set
end

-- (Re)seed a unit's baseline WITHOUT logging -- on swaps, so a new occupant isn't read as a drop
-- against the old occupant's baseline.
local function Baseline(unit)
    cachedRun[unit] = RunSpeed(unit)
    seen[unit] = ScanHarmful(unit)
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

    -- Record the current harmful set and collect ids newly applied since last event.
    local current = {}
    local fresh
    for index = 1, MAX_AURAS do
        local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL")
        if not name then break end
        current[spellId] = true
        if not (seen[unit] and seen[unit][spellId]) then       -- newly applied this event
            fresh = fresh or {}
            fresh[#fresh + 1] = spellId
        end
    end
    seen[unit] = current
    cachedRun[unit] = run

    if not fresh then return end

    -- Only a lone new aura can be implicated by the drop (see SINGLE-AURA GUARD).
    local single = #fresh == 1 and fresh[1]
    for _, spellId in ipairs(fresh) do
        if spellId == single and slowed then
            addon.Discover(spellId, "SLOW")                    -- lone aura + drop now -> a slow (incl. inflicted)
        else
            addon.Discover(spellId)                            -- otherwise -> catch-all (untyped)
        end
    end

    -- Lone aura, no drop yet: the drop may lag -- re-check once shortly after against the baseline.
    if single and prior and not slowed then
        C_Timer.After(0.1, function()
            local later = RunSpeed(unit)
            if later > 0 and later < prior and ScanHarmful(unit)[single] then
                addon.Discover(single, "SLOW")                 -- still up + dropped -> upgrade untyped -> SLOW
            end
        end)
    end
end

-- No DB to init here (Discovery.lua owns the ledger) and the frames exist at load, so set up at
-- file scope. addon.Discover only runs at runtime, by when the ledger is initialised.
local events = CreateFrame("Frame")
events:RegisterUnitEvent("UNIT_AURA", "player", "target", "pet", "party1", "party2", "party3", "party4")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_PET")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        OnAura(unit)
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
