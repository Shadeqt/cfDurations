-- Generic, UI-wide suppression of Blizzard's countdownForCooldowns text.
-- Every Cooldown frame shares one method table, so a single hook on SetCooldown
-- catches all of them -- Blizzard's, Questie's, RXP's, ours, and any addon's,
-- present or future. We hide the numbers everywhere EXCEPT a small allow-list
-- (action bars, bags, bank), which keep their countdown text. Spiral (the swirl)
-- is unaffected; only the text goes.

-- A cooldown keeps its numbers if itself or a nearby ancestor carries our explicit
-- opt-in flag (cfKeepNumbers -- set on the portrait CC swirls), an action-button
-- signature (a numeric .action slot set by Blizzard's ActionBarButtonTemplate, and by
-- Bartender/Dominos), or a known frame name -- action bars, plus default-UI bag and
-- bank item buttons.
local function KeepsCountdownNumbers(frame)
    for _ = 1, 3 do
        if not frame then return false end
        if frame.cfKeepNumbers then return true end
        if type(frame.action) == "number" then return true end
        local name = frame.GetName and frame:GetName()
        if name and (name:find("ActionButton")
                  or name:find("MultiBar")
                  or name:find("StanceButton")
                  or name:find("ShapeshiftButton")
                  or name:find("PetActionButton")
                  or name:find("ContainerFrame")   -- bags
                  or name:find("BankFrame")) then   -- bank
            return true
        end
        frame = frame:GetParent()
    end
    return false
end

local _, addon = ...

-- Grab the shared Cooldown method table from a throwaway frame.
local Cooldown = getmetatable(CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")).__index

function addon.SetupHideCooldownNumbers()
    if not cfDurationsDB.HideCooldownNumbers then return end
    hooksecurefunc(Cooldown, "SetCooldown", function(self)
        -- Decide once per frame. SetCooldown can fire every OnUpdate (e.g. Questie's
        -- item buttons), so caching avoids redundant work on the hot path.
        if self.cfNumbersHandled then return end
        self.cfNumbersHandled = true
        if not KeepsCountdownNumbers(self) then
            self:SetHideCountdownNumbers(true)
        end
    end)
end
