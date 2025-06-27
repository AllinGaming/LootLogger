LootLoggerDB = LootLoggerDB or {}

local function GetTimeStamp()
    return date("%Y-%m-%d %H:%M:%S")
end

local function AddEntry(source, action, target, item)
    table.insert(LootLoggerDB, {
        timestamp = GetTimeStamp(),
        source = source or "UNKNOWN",
        action = action or "-",
        target = target or "-",
        item = item or "UNKNOWN ITEM"
    })
end
local function StripItemLink(item)
    if not item then
        return ""
    end
    -- Extract the item name from a full item link: |cffff...|Hitem:...|h[Item Name]|h|r
    local _, _, name = string.find(item, "|h%[(.-)%]|h")
    if name then
        return name
    end

    -- If it's not a link, maybe just brackets (e.g., [Item])
    _, _, name = string.find(item, "%[(.-)%]")
    if name then
        return name
    end

    -- Otherwise return raw (plain-text trade name)
    return item
end

local function ParseLootMessage(msg)
    local _, _, player, item = string.find(msg, "^(.-) receives loot: (.+)%.$")
    if not player then
        local _, _, item = string.find(msg, "^You receive loot: (.+)%.$")
        player = UnitName("player")
        if player and item and (string.find(item, "|cffa335ee") or string.find(item, "Bag of Vast")) then
            local cleanItem = StripItemLink(item)
            AddEntry(player, "LOOT", player, cleanItem)
        end
    else
        if player and item and (string.find(item, "|cffa335ee") or string.find(item, "Bag of Vast")) then
            local cleanItem = StripItemLink(item)
            AddEntry(player, "LOOT", player, cleanItem)
        end
    end
end
local function ParseTradeMessage(msg)
    if not msg or not string.find(msg, "trades") then
        return
    end

    -- Custom Turtle WoW format:
    local _, _, source, item, target = string.find(msg, "^(.-) trades item (.+) to (.+)%.$")
    if source and item and target then
        if item and target then
            AddEntry(source, "TRADED_TO", target, item)
        end
        return
    end
end

local function ClearLootLog()
  LootLoggerDB = {}
  DEFAULT_CHAT_FRAME:AddMessage("LootLogger: History cleared.")
end

local function PrintLootHistory()
    DEFAULT_CHAT_FRAME:AddMessage("---- Epic Loot/Trade History ----")
    for i = 1, table.getn(LootLoggerDB) do
        local e = LootLoggerDB[i]
        local line = string.format("[%s] %s %s %s: %s", e.timestamp, e.source, e.action, e.target, e.item)
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
    DEFAULT_CHAT_FRAME:AddMessage("---- End of Log ----")
end

local function ShowSummary()
    if not LootLoggerUI or not LootLoggerEditBox then
        return
    end

    local lines = {}
    table.insert(lines, "Final Loot Owners (in loot order):\n")

    local itemOwners = {}
    local itemSeenOrder = {}

    for i = 1, table.getn(LootLoggerDB) do
        local e = LootLoggerDB[i]
        if e.item then
            -- First time we see this item, record order
            if not itemOwners[e.item] then
                table.insert(itemSeenOrder, e.item)
            end

            -- Always assign latest known owner
            if e.action == "LOOT" then
                itemOwners[e.item] = e.source
            elseif e.action == "TRADED_TO" then
                itemOwners[e.item] = e.target
            end
        end
    end

    for _, item in ipairs(itemSeenOrder) do
        local owner = itemOwners[item] or "?"
        table.insert(lines, owner .. " - " .. item)
    end

    local text = table.concat(lines, "\n")
    LootLoggerEditBox:SetText(text)

    local _, lineCount = string.gsub(text, "\n", "\n")
    LootLoggerEditBox:SetHeight((lineCount + 1) * 25)

    LootLoggerEditBox:ClearFocus()
    LootLoggerScrollFrame:SetVerticalScroll(0)
    LootLoggerUI:Show()
end

local function ShowFullHistory()
    if not LootLoggerUI or not LootLoggerEditBox then
        return
    end

    local lines = {}
    table.insert(lines, "Loot History:\n")

    for i = 1, table.getn(LootLoggerDB) do
        local e = LootLoggerDB[i]
        local timestamp = e.timestamp or "?"
        local source = e.source or "?"
        local action = e.action or "?"
        local target = e.target or "-"
        local item = e.item or "[unknown item]"

        local line = string.format("[%s] %s %s %s: %s", timestamp, source, action, target, item)
        table.insert(lines, line)
    end

    local text = table.concat(lines, "\n")
    LootLoggerEditBox:SetText(text)

    local _, lineCount = string.gsub(text, "\n", "\n")
    LootLoggerEditBox:SetHeight((lineCount + 1) * 25)

    LootLoggerEditBox:ClearFocus()
    LootLoggerScrollFrame:SetVerticalScroll(0)
    LootLoggerUI:Show()
end

SLASH_LOOTLOGGER1 = "/lootlog"
SlashCmdList["LOOTLOGGER"] = function(arg)
    if arg == "full" then
        ShowFullHistory()
    elseif arg == "summary" then
        ShowSummary()
    elseif arg == "clear" then
        ClearLootLog()
    else
        DEFAULT_CHAT_FRAME:AddMessage("LootLogger commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/lootlog summary - Show final item owners")
        DEFAULT_CHAT_FRAME:AddMessage("/lootlog full - Show full loot & trade log")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("CHAT_MSG_SYSTEM")
-- Enable mousewheel scrolling
LootLoggerScrollFrame:EnableMouseWheel(true)

f:SetScript("OnEvent", function()
    if event == "CHAT_MSG_LOOT" then
        if arg1 then
            ParseLootMessage(arg1)
        end
    elseif event == "CHAT_MSG_SYSTEM" and arg1 then
        if arg1 then
            ParseTradeMessage(arg1)
        end
    end
end)
