-- Cooldown swirls on the player's own buffs and debuffs. Spiral only — no numbers
-- (countdown text is explicitly hidden so Blizzard's countdownForCooldowns CVar
-- doesn't render on these icons).

local _, addon = ...

hooksecurefunc("AuraButton_Update", function(buttonName, index)
    local buff = _G[buttonName .. index]
    if not buff then return end
    local filter = buttonName == "BuffButton" and "HELPFUL" or "HARMFUL"
    local _, _, _, _, duration, expirationTime = UnitAura("player", index, filter)
    if not duration then return end
    addon.ApplyCooldown(addon.GetSwirl(buff), duration, expirationTime)
end)
