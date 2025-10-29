-- cfDurationsFresh Auras: Apply cooldowns to all auras

local LibClassicDurations = LibStub("LibClassicDurations")

-- Aura type constants
local BUFF = true
local DEBUFF = false

-- DRY helper: Apply cooldown to aura frames
local function applyDuration(cooldownFrame, unitId, i, isBuff)
    if not cooldownFrame then return end

    local auraFunc = isBuff and UnitBuff or UnitDebuff
    local name, _, _, _, duration, expirationTime, caster, _, _, spellId = auraFunc(unitId, i)

    if not name then return end

    -- Use LibClassicDurations if duration is missing
    if duration == 0 then
        local d, e = LibClassicDurations:GetAuraDurationByUnit(unitId, spellId, caster)
        if d then
            duration, expirationTime = d, e
        end
    end

    -- Apply cooldown (metatable hook will enable timer display)
    if expirationTime and expirationTime > 0 then
        cooldownFrame:SetCooldown(expirationTime - duration, duration)
    end
end

-- DRY helper: Update all auras on target frame
local function updateAuras(unit, isBuff)
    local auraFunc = isBuff and UnitBuff or UnitDebuff
    local frameName = isBuff and "TargetFrameBuff" or "TargetFrameDebuff"
    local maxCount = isBuff and MAX_TARGET_BUFFS or MAX_TARGET_DEBUFFS

    for i = 1, maxCount do
        if auraFunc(unit, i) then
            local cooldown = _G[frameName .. i .. "Cooldown"]
            applyDuration(cooldown, unit, i, isBuff)
        end
    end
end

-- Target frame auras
hooksecurefunc("TargetFrame_UpdateAuras", function(targetFrame)
    if not targetFrame.unit then return end

    updateAuras(targetFrame.unit, BUFF)
    updateAuras(targetFrame.unit, DEBUFF)
end)

-- Compact frames (Party/Raid/Arena)
hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(frame, unitId, i)
    applyDuration(frame.cooldown, unitId, i, BUFF)
end)

hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(frame, unitId, i)
    applyDuration(frame.cooldown, unitId, i, DEBUFF)
end)
