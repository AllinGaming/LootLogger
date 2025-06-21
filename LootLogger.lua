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

local function PrintLootHistory()
    DEFAULT_CHAT_FRAME:AddMessage("---- Epic Loot/Trade History ----")
    for i = 1, table.getn(LootLoggerDB) do
        local e = LootLoggerDB[i]
        local line = string.format("[%s] %s %s %s: %s", e.timestamp, e.source, e.action, e.target, e.item)
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
    DEFAULT_CHAT_FRAME:AddMessage("---- End of Log ----")
end

local function ShowUI()
    if not LootLoggerUI or not LootLoggerEditBox then
        return
    end

    local lines = {}
    table.insert(lines, "Loot Winners:\n")

    -- Map item -> final owner
    local itemOwners = {}

    -- First pass: find who the item was traded to (most recent trade wins)
    for i = 1, table.getn(LootLoggerDB) do
        local e = LootLoggerDB[i]
        if e.action == "TRADED_TO" and e.item and e.target then
            itemOwners[e.item] = e.target
        end
    end

    -- Second pass: if not traded, owner is the original looter
    for i = 1, table.getn(LootLoggerDB) do
        local e = LootLoggerDB[i]
        if e.action == "LOOT" and e.item then
            if not itemOwners[e.item] then
                itemOwners[e.item] = e.target or "?"
            end
        end
    end

    -- Prepare the output
    for item, owner in pairs(itemOwners) do
        table.insert(lines, owner .. " - " .. item)
    end

    local text = table.concat(lines, "\n")
    LootLoggerEditBox:SetText(text)
    LootLoggerEditBox:ClearFocus()
    LootLoggerUI:Show()
end

SLASH_LOOTLOGGER1 = "/lootlog"
SlashCmdList["LOOTLOGGER"] = function(arg)
    if arg == "ui" then
        ShowUI()
    elseif arg == "reset" then
        LootLoggerDB = {}
        DEFAULT_CHAT_FRAME:AddMessage("LootLogger: History has been reset.")
    else
        PrintLootHistory()
        DEFAULT_CHAT_FRAME:AddMessage("Tip: Use /lootlog ui to open a scrollable window.")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("CHAT_MSG_SYSTEM")
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
