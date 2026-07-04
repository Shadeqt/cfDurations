-- Cooldown swirls on the player's own buffs and debuffs. Spiral only — no numbers:
-- addon.ApplyCooldown hides Blizzard's countdownForCooldowns text on every swirl it
-- drives, so these stay number-free independent of the HideCooldownNumbers toggle.

local _, addon = ...

function addon.SetupPlayerSwirls()
    if not cfDurationsDB.PlayerSwirls then return end
    -- AuraButton_Update's second arg doubles as the button-name suffix and the UnitAura index,
    -- so the seed loop below can reuse this by walking that same index.
    local function Paint(buttonName, index)
        local buff = _G[buttonName .. index]
        if not buff then return end
        local filter = buttonName == "BuffButton" and "HELPFUL" or "HARMFUL"
        local _, _, _, _, duration, expirationTime = UnitAura("player", index, filter)
        if not duration then return end
        addon.ApplyCooldown(addon.GetSwirl(buff), duration, expirationTime)
    end
    -- Seed the buttons Blizzard already painted before this hook existed: setup is deferred to
    -- PLAYER_ENTERING_WORLD, by which point the login auras are already shown, so hooksecurefunc
    -- alone would leave them swirl-less until the next UNIT_AURA re-runs AuraButton_Update for all
    -- visible buttons. Walk each block to the first missing slot (buttons are created contiguously,
    -- same nil-terminated scan cfDarkMode uses); Paint's duration guard skips hidden trailing slots.
    for _, name in ipairs({ "BuffButton", "DebuffButton" }) do
        local i = 1
        while _G[name .. i] do
            Paint(name, i)
            i = i + 1
        end
    end
    hooksecurefunc("AuraButton_Update", Paint)
end
