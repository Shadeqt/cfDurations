-- cfDurations Auras: Apply cooldowns to all auras

-- Shared dependencies
local cfDurations = cfDurations
local LibClassicDurations = cfDurations.LibClassicDurations
local incrementTimerId = cfDurations.incrementTimerId
local clearTimer = cfDurations.clearTimer

-- Module constants
local BUFF = true -- true, represents buff aura type
local DEBUFF = false -- false, represents debuff aura type

-- Module states
local cooldownFrameCache = {}

-- Apply timer to aura frames
local function applyAuraTimer(cooldownFrame, unitId, slotIndex, isBuff)
    if not cooldownFrame then return end

    local auraFunc = isBuff and UnitBuff or UnitDebuff
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
        -- Permanent buff: stop old timers and clear swipe
        incrementTimerId(cooldownFrame)
        clearTimer(cooldownFrame)
        cooldownFrame:Clear()
    end
end

-- Update all timers on target frame
local function updateTargetAuraTimers(unitId, isBuff)
    local auraFunc = isBuff and UnitBuff or UnitDebuff
    local framename = isBuff and "TargetFrameBuff" or "TargetFrameDebuff"
    local maxAuraCount = isBuff and MAX_TARGET_BUFFS or MAX_TARGET_DEBUFFS

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
            -- Clear remaining slots
            if cooldownFrame then
                cooldownFrame:SetCooldown(0, 0)
            end
        end
    end
end

-- Target frame auras
hooksecurefunc("TargetFrame_UpdateAuras", function(targetFrame)
    if not targetFrame.unit then return end

    updateTargetAuraTimers(targetFrame.unit, BUFF)
    updateTargetAuraTimers(targetFrame.unit, DEBUFF)
end)

-- Compact frames (Party/Raid/Arena)
hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, unitId, i)
    applyAuraTimer(buffFrame.cooldown, unitId, i, BUFF)
end)

hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(debuffFrame, unitId, i)
    applyAuraTimer(debuffFrame.cooldown, unitId, i, DEBUFF)
end)
