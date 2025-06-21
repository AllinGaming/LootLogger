# LootLogger (WoW 1.12 Addon)

LootLogger is a lightweight addon for World of Warcraft 1.12 (Vanilla) designed to track epic item looting and trading. It logs when a player receives a loot and if/when that item is later traded, showing the final owner of each item.

---

## 🔧 Features

- Logs epic item loot messages and select rare container loots (e.g. Bag of Vast Horizons).
- Tracks trades and resolves final item ownership.
- UI window to view the list of item winners.
- Slash commands for printing, resetting, or opening the UI.

---

## 💬 Chat Commands

| Command        | Description                                      |
|----------------|--------------------------------------------------|
| `/lootlog`     | Prints the full loot/trade history to chat.      |
| `/lootlog ui`  | Opens a scrollable UI showing item winners.      |
| `/lootlog reset` | Clears the entire stored loot history.         |

---

## 📦 How It Works

- **LOOT Events**: Logged when an epic item is looted.
- **TRADE Events**: Logged when an item is traded to another player.
- The UI uses a two-pass system:
  1. Checks all `TRADED_TO` events and maps item → latest recipient.
  2. Fills in missing owners with the original looter (`LOOT` event).
- Only the latest known owner is shown in the `/lootlog ui` window.