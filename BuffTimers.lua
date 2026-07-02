-- Optional custom countdown text on swirl frames, toggled by the cfDurationsDB.BuffTimers checkbox
-- (default off, reload-gated). Subscribes to BuffSwirls' ApplyCooldown listener; when enabled, draws
-- our own FontString to bypass Blizzard's CooldownFrameTemplate size cutoff (which hides numbers below
-- ~18px). Tier-styled: white > 60s, yellow ≤ 60s, red ≤ 5s, sized to half the icon's width.

local _, addon = ...

local showTimers = false  -- seeded from the DB in SetupBuffTimers (below)
local tracked    = {}

local timerStyles = {
    { threshold = 5,         scale = 1.5, r = 1, g = 0, b = 0 },
    { threshold = 60,        scale = 1.2, r = 1, g = 1, b = 0 },
    { threshold = math.huge, scale = 1,   r = 1, g = 1, b = 1 },
}

local function GetStyle(remaining)
    for _, style in ipairs(timerStyles) do
        if remaining <= style.threshold then return style end
    end
end

local function FormatTime(seconds)
    if seconds <= 60 then return math.ceil(seconds) end
    return math.ceil(seconds / 60) .. "m"
end

local function NextChange(remaining)
    if remaining <= 60 then return (remaining % 1) + 0.01 end
    return (remaining % 60) + 0.01
end

local function CreateText(cooldown)
    local text = cooldown:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    return text
end

local function Tick(cooldown)
    if not cooldown.cfEndTime then return end
    local remaining = cooldown.cfEndTime - GetTime()
    if remaining <= 0 then
        cooldown.cfText:SetText("")
        cooldown.cfEndTime = nil
        cooldown.cfTimer = nil
        return
    end
    local style = GetStyle(remaining)
    if cooldown.cfLastTier ~= style.threshold then
        local size = math.floor(cooldown:GetWidth() / 2) * style.scale
        cooldown.cfText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
        cooldown.cfText:SetTextColor(style.r, style.g, style.b)
        cooldown.cfLastTier = style.threshold
    end
    cooldown.cfText:SetText(FormatTime(remaining))
    -- Reuse one closure per frame instead of allocating a fresh one each tick.
    cooldown.cfTickFn = cooldown.cfTickFn or function() Tick(cooldown) end
    cooldown.cfTimer = C_Timer.NewTimer(NextChange(remaining), cooldown.cfTickFn)
end

local function AttachCountdown(cooldown, duration, expirationTime)
    if cooldown.cfTimer then
        cooldown.cfTimer:Cancel()
        cooldown.cfTimer = nil
    end
    if not duration or duration <= 0 then
        if cooldown.cfText then cooldown.cfText:SetText("") end
        cooldown.cfEndTime = nil
        return
    end
    if not cooldown.cfText then
        cooldown:SetHideCountdownNumbers(true)
        cooldown.cfText = CreateText(cooldown)
        cooldown.cfLastTier = nil
        tracked[cooldown] = true
    end
    cooldown.cfEndTime = expirationTime
    Tick(cooldown)
end

table.insert(addon.listeners, function(cooldown, duration, expirationTime)
    if showTimers then
        AttachCountdown(cooldown, duration, expirationTime)
    end
end)

-- Reload-gated: read the flag once, then repaint so text appears immediately (rather than waiting for
-- the next natural aura event). Controlled only by the settings checkbox -- no slash command.
function addon.SetupBuffTimers()
    showTimers = cfDurationsDB.BuffTimers and true or false
    if showTimers then addon.RefreshAll() end
end
