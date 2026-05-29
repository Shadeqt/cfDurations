-- Cooldown swirls on the player's own buffs and debuffs. Spiral only — no numbers
-- (countdown text is explicitly hidden so Blizzard's countdownForCooldowns CVar
-- doesn't render on these icons).

local function CreateSwirl(buff)
    local cooldown = CreateFrame("Cooldown", nil, buff, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetReverse(true)
    return cooldown
end

hooksecurefunc("AuraButton_Update", function(buttonName, index)
    local buff = _G[buttonName .. index]
    if not buff then return end
    local filter = buttonName == "BuffButton" and "HELPFUL" or "HARMFUL"
    local _, _, _, _, duration, expirationTime = UnitAura("player", index, filter)
    if not duration then return end
    buff.cfCooldown = buff.cfCooldown or CreateSwirl(buff)
    if duration > 0 then
        buff.cfCooldown:SetCooldown(expirationTime - duration, duration)
    else
        buff.cfCooldown:Clear()
    end
end)
