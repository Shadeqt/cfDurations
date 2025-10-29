-- cfDurationsFresh Auras: Apply cooldowns to all auras

-- Localize Lua APIs
local _G = _G

-- Localize WoW APIs
local _UnitBuff = UnitBuff
local _UnitDebuff = UnitDebuff
local _hooksecurefunc = hooksecurefunc
local _LibStub = LibStub

-- Localize WoW constants
local _MAX_TARGET_BUFFS = MAX_TARGET_BUFFS
local _MAX_TARGET_DEBUFFS = MAX_TARGET_DEBUFFS

local LibClassicDurations = _LibStub("LibClassicDurations")

-- Aura type constants
local BUFF = true
local DEBUFF = false

-- Lazy-loaded frame cache
local cooldownFrameCache = {}

-- DRY helper: Apply timer to aura frames
local function applyAuraTimer(cooldownFrame, unitId, slotIndex, isBuff)
    if not cooldownFrame then return end

    local auraFunc = isBuff and _UnitBuff or _UnitDebuff
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = auraFunc(unitId, slotIndex)

    if not name then return end

    -- Use LibClassicDurations if duration is missing
    if duration == 0 then
        local libDuration, libExpirationTime = LibClassicDurations:GetAuraDurationByUnit(unitId, spellId, caster)
        if libDuration then
            duration, expirationTime = libDuration, libExpirationTime
        end
    end

    -- Apply cooldown (metatable hook will enable timer display)
    if expirationTime and expirationTime > 0 then
        cooldownFrame:SetCooldown(expirationTime - duration, duration)
    else
        -- Permanent buff: Manually increment TimerId to stop old timers, then clear swipe
        cooldownFrame.cfTimerId = (cooldownFrame.cfTimerId or 0) + 1
        if cooldownFrame.cfTimer then
            cooldownFrame.cfTimer:SetText("")
        end
        cooldownFrame:Clear()  -- Clear swipe without flash
    end
end

-- DRY helper: Update all timers on target frame
local function updateTargetAuraTimers(unitId, isBuff)
    local auraFunc = isBuff and _UnitBuff or _UnitDebuff
    local framename = isBuff and "TargetFrameBuff" or "TargetFrameDebuff"
    local maxAuraCount = isBuff and _MAX_TARGET_BUFFS or _MAX_TARGET_DEBUFFS

    for i = 1, maxAuraCount do
        local frameName = framename .. i .. "Cooldown"
        local cooldownFrame = cooldownFrameCache[frameName]

        if not cooldownFrame then
            cooldownFrame = _G[frameName]
            cooldownFrameCache[frameName] = cooldownFrame
        end

        if auraFunc(unitId, i) then
            applyAuraTimer(cooldownFrame, unitId, i, isBuff)
        else
            -- Clear remaining slots (target switch or buff expired)
            if cooldownFrame then
                cooldownFrame:SetCooldown(0, 0)
            end
        end
    end
end

-- Target frame auras
_hooksecurefunc("TargetFrame_UpdateAuras", function(targetFrame)
    if not targetFrame.unit then return end

    updateTargetAuraTimers(targetFrame.unit, BUFF)
    updateTargetAuraTimers(targetFrame.unit, DEBUFF)
end)

-- Compact frames (Party/Raid/Arena)
_hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, unitId, slotIndex)
    applyAuraTimer(buffFrame.cooldown, unitId, slotIndex, BUFF)
end)

_hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(debuffFrame, unitId, slotIndex)
    applyAuraTimer(debuffFrame.cooldown, unitId, slotIndex, DEBUFF)
end)
