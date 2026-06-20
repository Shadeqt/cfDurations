-- Target frame: two-tier sort (mine first, then shortest expiration first) with
-- a faithful re-layout. Target auras are sized by caster (yours = 21px, others =
-- 17px), and Blizzard's row wrapping is width-based, so we can't just permute
-- captured positions like the player frame -- reordering changes where rows
-- break. Instead we re-run Blizzard's own wrapping algorithm over the sorted
-- order, preserving the exact look (mixed sizes, ToT-narrowed first rows).
--
-- Aura buttons are unprotected -> safe to re-anchor anytime, including combat.
-- The castbar (TargetFrameSpellBar) is secure/combat-locked, so we only call
-- Target_Spellbar_AdjustPosition out of combat (and again on PLAYER_REGEN_ENABLED).
--
-- Durations & caster come from LibClassicDurations (foreign auras report 0 via
-- the raw API). Unknown/permanent durations sort as infinite -> last per tier.

local _, addon = ...

local Lib = addon.Lib
local sort = table.sort

-- Layout constants copied from Blizzard_UnitFrame/Vanilla/TargetFrame.lua (they
-- are file-local there). Would only drift if Blizzard changes them.
local AURA_START_X      = 5
local AURA_START_Y      = 32
local AURA_OFFSET_X     = 3
local AURA_OFFSET_Y     = 1
local LARGE_AURA_SIZE   = 21
local SMALL_AURA_SIZE   = 17
local AURA_ROW_WIDTH    = 122
local TOT_AURA_ROW_WIDTH = 101
local NUM_TOT_AURA_ROWS = 2

local UnitIsFriend = UnitIsFriend
local UnitIsUnit = UnitIsUnit
local UnitIsOwnerOrControllerOfUnit = UnitIsOwnerOrControllerOfUnit
local PLAYER_UNITS = PLAYER_UNITS or { player = true, pet = true, vehicle = true }

-- "Mine" = cast by the player, pet, or a controlled guardian. Totem auras often
-- report caster == nil and fall through as not-mine (GUID tracking would be
-- needed to attribute them; left for later).
local function IsMine(caster)
    if not caster then return false end
    if PLAYER_UNITS[caster] then return true end
    if UnitIsUnit(caster, "player") or UnitIsUnit(caster, "pet") then return true end
    if UnitIsOwnerOrControllerOfUnit and UnitIsOwnerOrControllerOfUnit("player", caster) then return true end
    return false
end

-- Tier 1: mine before others. Tier 2: shortest remaining FIRST. Infinite last;
-- ties keep Blizzard's original order.
local function targetComparator(a, b)
    if a.mine ~= b.mine then
        return a.mine
    end
    if a.remaining ~= b.remaining then
        return a.remaining < b.remaining
    end
    return a.slot < b.slot
end

-- Gather shown <name><suffix><i> buttons with remaining time, caster, and size.
local function CollectTarget(self, suffix, filter, max, unit)
    local name = self:GetName()
    local list = {}
    for i = 1, max do
        local btn = _G[name .. suffix .. i]
        if btn and btn:IsShown() then
            local _, _, _, _, duration, expirationTime, caster = Lib.UnitAuraWrapper(unit, btn:GetID(), filter)
            local size = btn:GetWidth() or SMALL_AURA_SIZE
            local n = #list + 1
            list[n] = {
                frame = btn, slot = n,
                remaining = addon.RemainingFrom(duration, expirationTime),
                mine = IsMine(caster), size = size,
                isLarge = size >= LARGE_AURA_SIZE - 1,
            }
        end
    end
    return list
end

-- Re-run Blizzard's width-based wrapping (TargetFrame_UpdateAuraPositions plus
-- the buff/debuff anchor funcs) over `items` in sorted order. Mutates
-- self.auraRows / self.spellbarAnchor and the self.buffs/self.debuffs containers.
local function LayoutSection(self, items, isBuff, numOpposite, maxRowWidth, mirror, isFriend)
    local n = #items
    if n == 0 then return end

    local point, relativePoint, startY, auraOffsetY
    if mirror then
        point, relativePoint, startY, auraOffsetY = "BOTTOM", "TOP", -15, -AURA_OFFSET_Y
    else
        point, relativePoint, startY, auraOffsetY = "TOP", "BOTTOM", AURA_START_Y, AURA_OFFSET_Y
    end
    local container = isBuff and self.buffs or self.debuffs

    local offsetY = AURA_OFFSET_Y
    local rowWidth = 0
    local firstOnRow = 1

    for i = 1, n do
        local it = items[i]
        local buff = it.frame
        local size = it.size
        if it.isLarge then
            offsetY = AURA_OFFSET_Y + AURA_OFFSET_Y
        end

        local newRow = false
        if i == 1 then
            rowWidth = size
            self.auraRows = self.auraRows + 1
        else
            rowWidth = rowWidth + size + AURA_OFFSET_X
            if rowWidth > maxRowWidth then
                newRow = true
            end
        end

        local effOffsetY = mirror and -offsetY or offsetY
        buff:ClearAllPoints()

        if i == 1 then
            if isBuff then
                if isFriend or numOpposite == 0 then
                    buff:SetPoint(point .. "LEFT", self, relativePoint .. "LEFT", AURA_START_X, startY)
                else
                    buff:SetPoint(point .. "LEFT", self.debuffs, relativePoint .. "LEFT", 0, -effOffsetY)
                end
            else
                if isFriend and numOpposite > 0 then
                    buff:SetPoint(point .. "LEFT", self.buffs, relativePoint .. "LEFT", 0, -effOffsetY)
                else
                    buff:SetPoint(point .. "LEFT", self, relativePoint .. "LEFT", AURA_START_X, startY)
                end
            end
            container:SetPoint(point .. "LEFT", buff, point .. "LEFT", 0, 0)
            container:SetPoint(relativePoint .. "LEFT", buff, relativePoint .. "LEFT", 0, -auraOffsetY)
            if isBuff or isFriend or numOpposite == 0 then
                self.spellbarAnchor = buff
            end
        elseif newRow then
            buff:SetPoint(point .. "LEFT", items[firstOnRow].frame, relativePoint .. "LEFT", 0, -effOffsetY)
            container:SetPoint(relativePoint .. "LEFT", buff, relativePoint .. "LEFT", 0, -auraOffsetY)
            if isBuff or isFriend or numOpposite == 0 then
                self.spellbarAnchor = buff
            end
        else
            buff:SetPoint(point .. "LEFT", items[i - 1].frame, point .. "RIGHT", AURA_OFFSET_X, 0)
        end

        if newRow then
            rowWidth = size
            self.auraRows = self.auraRows + 1
            firstOnRow = i
            offsetY = AURA_OFFSET_Y
            if self.auraRows > NUM_TOT_AURA_ROWS then
                maxRowWidth = AURA_ROW_WIDTH
            end
        end
    end
end

local guard = false

local function ReorderTargetAuras(self)
    if guard then return end
    local unit = self.unit
    if not unit or not self:GetName() then return end
    if not self.buffs or not self.debuffs then return end

    local buffs = CollectTarget(self, "Buff", "HELPFUL", MAX_TARGET_BUFFS or 32, unit)
    local debuffs = CollectTarget(self, "Debuff", "HARMFUL", MAX_TARGET_DEBUFFS or 16, unit)
    if #buffs < 2 and #debuffs < 2 then return end

    sort(buffs, targetComparator)
    sort(debuffs, targetComparator)

    local isFriend = UnitIsFriend("player", unit)
    local mirror = self.buffsOnTop and true or false
    local haveToT = (self.totFrame and self.totFrame:IsShown()) or false
    local totWidth = self.TOT_AURA_ROW_WIDTH or TOT_AURA_ROW_WIDTH

    guard = true
    self.auraRows = 0
    self.spellbarAnchor = nil

    local maxRowWidth = (haveToT and totWidth) or AURA_ROW_WIDTH
    LayoutSection(self, buffs, true, #debuffs, maxRowWidth, mirror, isFriend)

    maxRowWidth = (haveToT and self.auraRows < NUM_TOT_AURA_ROWS and totWidth) or AURA_ROW_WIDTH
    LayoutSection(self, debuffs, false, #buffs, maxRowWidth, mirror, isFriend)

    if self.spellbar and Target_Spellbar_AdjustPosition and not InCombatLockdown() then
        Target_Spellbar_AdjustPosition(self.spellbar)
    end
    guard = false
end

hooksecurefunc("TargetFrame_UpdateAuras", function(self)
    if self == TargetFrame then
        ReorderTargetAuras(self)
    end
end)

-- Castbar can't be moved in combat; fix it up once combat ends.
local regen = CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")
regen:SetScript("OnEvent", function()
    if TargetFrame and TargetFrame.unit and UnitExists("target") then
        ReorderTargetAuras(TargetFrame)
    end
end)
