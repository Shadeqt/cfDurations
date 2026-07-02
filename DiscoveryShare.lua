local _, addon = ...

-- Discovery sharing (EXPORT ONLY). Self-contained so it can be removed with no trace if the addon
-- stays private: delete this file + its cfDurations.toc line and the guarded call in Settings.lua
-- (`if addon.AddExportButton then ...`) simply no-ops. Nothing else references anything here.
--
-- WoW addons are sandboxed: no internet, and no clipboard write access. So a player cannot send their
-- finds to the author automatically -- the best possible is an auto-highlighted text box they copy with
-- Ctrl+C and paste out-of-game (Discord/etc.). The text is a Lua-table dump mirroring the SavedVariables
-- `discovered` shape, so the author scans a contributor's paste exactly like their own ledger (no import
-- side needed -- their existing Wowhead-verify -> Data.lua pipeline applies unchanged).

-- Serialize cfDurationsDB.discovered to a Lua-table literal, one entry per line, sorted by spellId for
-- stable diffs. Shape matches the ledger: [id] = { name=, type=, on=, from={ name=, id= } }. Optional
-- fields are omitted when absent. string.format("%q") safely quotes/escapes names.
function addon.SerializeDiscovered()
    local discovered = (cfDurationsDB and cfDurationsDB.discovered) or {}

    local ids = {}
    for id in pairs(discovered) do ids[#ids + 1] = id end
    table.sort(ids)

    local header = string.format("-- cfDurations discoveries (%d) -- paste to the addon author", #ids)
    if #ids == 0 then
        return header .. "\n-- (nothing logged yet)"
    end

    local lines = { header }
    for _, id in ipairs(ids) do
        local e = discovered[id]
        local parts = {}
        if e.name then parts[#parts + 1] = "name = " .. string.format("%q", e.name) end
        if e.type then parts[#parts + 1] = "type = " .. string.format("%q", e.type) end
        if e.on   then parts[#parts + 1] = "on = "   .. string.format("%q", e.on)   end
        if e.from then
            local fp = {}
            if e.from.name then fp[#fp + 1] = "name = " .. string.format("%q", e.from.name) end
            if e.from.id   then fp[#fp + 1] = "id = "   .. tostring(e.from.id) end
            parts[#parts + 1] = "from = { " .. table.concat(fp, ", ") .. " }"
        end
        lines[#lines + 1] = string.format("[%d] = { %s },", id, table.concat(parts, ", "))
    end
    return table.concat(lines, "\n")
end

-- The copy window: a scrolling multiline EditBox, created lazily and reused. On open it's filled with
-- the current ledger and pre-selected + focused, so the whole flow is click -> Ctrl+C.
local frame
local function EnsureFrame()
    if frame then return frame end

    local f = CreateFrame("Frame", "cfDurationsExportFrame", UIParent, "BackdropTemplate")
    f:SetSize(520, 420)
    f:SetPoint("CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG")  -- above the settings panel (also FULLSCREEN_DIALOG); Raise() on open
    f:SetToplevel(true)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("cfDurations -- Copy my discoveries")

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -6)
    hint:SetText("Press Ctrl+C to copy, then send it to the addon author.")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local scroll = CreateFrame("ScrollFrame", "cfDurationsExportScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -56)
    scroll:SetPoint("BOTTOMRIGHT", -34, 16)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(460)
    edit:SetAutoFocus(false)
    edit:EnableMouse(true)
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    -- Keep the content stable: if the user edits/deletes, restore the ledger text so a copy is never
    -- half-deleted. Guarded so our own SetText doesn't recurse.
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(addon.SerializeDiscovered())
            self:HighlightText()
        end
    end)
    scroll:SetScrollChild(edit)

    f.edit = edit
    frame = f
    return f
end

function addon.OpenExportFrame()
    local f = EnsureFrame()
    f.edit:SetText(addon.SerializeDiscovered())
    f:Show()
    f:Raise()
    f.edit:SetFocus()
    f.edit:HighlightText()
    f.edit:SetCursorPosition(0)
end

-- Self-register the "Copy my discoveries" button into the settings page. Settings.lua calls this
-- guarded (so removing this file removes the whole feature). Added before RegisterAddOnCategory.
function addon.AddExportButton(category, layout)
    layout:AddInitializer(CreateSettingsButtonInitializer(
        "Discovery Sharing",                                    -- name
        "Copy my discoveries",                                  -- buttonText
        function() addon.OpenExportFrame() end,                 -- buttonClick
        "Open a window with your logged crowd-control discoveries as copyable text to send to the addon author.", -- tooltip
        true))                                                  -- addSearchTags (required; asserts if nil)
end
