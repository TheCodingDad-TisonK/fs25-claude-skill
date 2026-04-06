# Getting Started with FS25 Claude Skill

This guide walks you through your first mod using Claude with this skill installed.

---

## Your First Mod in 5 Minutes

### Step 1 — Describe your mod to Claude

```
"I want to create an FS25 mod that shows a custom dialog when a player 
enters a trigger zone near a building. The dialog should ask them if they 
want to hire a worker, and if yes, charge them $500."
```

Claude will use the skill to generate a complete working scaffold.

### Step 2 — Let Claude generate the structure

With the skill installed, Claude will produce:
- `modDesc.xml` with correct `descVersion="83"`
- `scripts/MyMod.lua` with proper class structure
- `gui/MyDialog.xml` with the dialog layout
- `gui/MyDialog.lua` with `MessageDialog` base class
- `translations/translation_en.xml`

### Step 3 — Ask follow-up questions

```
"How do I make this work in multiplayer?"
"Add a cooldown so the dialog can only trigger once per game hour"
"How do I save whether the player has hired a worker today?"
```

The skill gives Claude the context to answer these correctly.

---

## Common Starting Prompts

### New mod from scratch
```
"Create the boilerplate for an FS25 mod called MyMod. 
It needs a global manager, one custom dialog, and save/load support."
```

### Debug an existing mod
```
"My FS25 mod crashes with this error: [paste error]
Here is my Lua file: [paste code]"
```

### Add a feature
```
"Add a button to the shop screen in FS25 that opens my custom dialog 
when the player selects a vehicle."
```

### Multiplayer sync question
```
"I have a variable myValue on the server that needs to sync to all clients 
when it changes. How do I do this in FS25?"
```

---

## Understanding the Output

Claude will often reference validation status in its answers:

| Claude says | Means |
|-------------|-------|
| "✅ Validated pattern" | Used in production mods, reliable |
| "⚠️ Partially validated" | Core works, verify edge cases |
| "📚 Reference only" | Extracted from mods, test carefully |
| "⚠️ Known pitfall" | Claude caught a trap before you hit it |

---

## Tips for Best Results

1. **Paste your existing code** — Claude gives better answers when it can see your current file
2. **Include error messages** — paste from `log.txt` (Documents/My Games/FarmingSimulator2025/log.txt)
3. **Specify multiplayer intent** — say "this needs to work in multiplayer" upfront
4. **Ask for the XML too** — Claude can generate both the Lua and the GUI XML
5. **Ask "what could go wrong?"** — Claude will check the pitfalls list

---

## File Locations Reference

| File | Location |
|------|----------|
| Game log | `Documents/My Games/FarmingSimulator2025/log.txt` |
| Mods folder | `Documents/My Games/FarmingSimulator2025/mods/` |
| Game data | `[Steam]\steamapps\common\Farming Simulator 25\data\` |
| Giants dataS | `[Steam]\steamapps\common\Farming Simulator 25\dataS\` |

---

## Debugging Workflow

When something goes wrong:

1. Open `log.txt` immediately after the crash
2. Search for `Error` or `LUA` 
3. Paste the error block into Claude: *"My FS25 mod crashed with this error:"*
4. Claude will diagnose against the pitfalls reference

Common error patterns:
```
LUA call stack:  attempt to index nil value   → nil check missing
LUA call stack:  attempt to call nil value    → wrong function name or API
LUA running:     Error: running function ...  → event/callback issue
```
