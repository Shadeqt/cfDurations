-- Sorts the player's buff and debuff icons by remaining duration without
-- recreating any frames. Blizzard lays the buttons out (chained, with row
-- wrapping) in BuffFrame_UpdateAllBuffAnchors / DebuffButton_UpdateAnchors and
-- ClearAllPoints() every pass, so each pass rebuilds a clean canonical grid.
-- We hook *after* that pass: read the slot positions Blizzard just produced,
-- then re-anchor the existing buttons into those same slots in sorted order.
-- Because every slot is re-anchored relative to BuffFrame (a stable frame, not
-- the previous button), the original chaining is irrelevant and nothing drifts.
--
-- Player auras carry real durations from native UnitAura, so no
-- LibClassicDurations is needed here -- that's only required for the target frame.
--
-- Order: shortest remaining LAST. Permanent / unknown-duration auras are treated
-- as infinite remaining, so they sit at the front; ties keep Blizzard's order.

local _, addon = ...

local UnitAura = UnitAura
local sort = table.sort

local function Remaining(index, filter)
    local _, _, _, _, duration, expirationTime = UnitAura("player", index, filter)
    return addon.RemainingFrom(duration, expirationTime)
end

local function comparator(a, b)
    if a.remaining ~= b.remaining then
        return a.remaining > b.remaining
    end
    return a.slot < b.slot
end

local guard = false

local function Reorder(prefix, filter, max)
    if guard then return end
    if not BuffFrame then return end

    local anchorR, anchorT = BuffFrame:GetRight(), BuffFrame:GetTop()
    if not anchorR or not anchorT then return end

    local items, slots = {}, {}
    for i = 1, max do
        local btn = _G[prefix .. i]
        if btn and btn:IsShown() then
            local right, top = btn:GetRight(), btn:GetTop()
            if right and top then
                local n = #items + 1
                items[n] = { frame = btn, slot = n, remaining = Remaining(btn:GetID(), filter) }
                slots[n] = { dx = right - anchorR, dy = top - anchorT }
            end
        end
    end

    if #items < 2 then return end

    sort(items, comparator)

    guard = true
    for k = 1, #items do
        local f = items[k].frame
        f:ClearAllPoints()
        f:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", slots[k].dx, slots[k].dy)
    end
    guard = false
end

function addon.SetupPlayerAuraSort()
    if not cfDurationsDB.AuraSorting then return end
    hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
        Reorder("BuffButton", "HELPFUL", BUFF_MAX_DISPLAY or 32)
    end)

    hooksecurefunc("DebuffButton_UpdateAnchors", function(buttonName, index)
        if buttonName == "DebuffButton" and index == DEBUFF_ACTUAL_DISPLAY then
            Reorder("DebuffButton", "HARMFUL", DEBUFF_MAX_DISPLAY or 16)
        end
    end)
end
