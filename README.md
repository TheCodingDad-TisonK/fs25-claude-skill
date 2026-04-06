# 🚜 FS25 Claude Skill — AI-Powered Mod Development Assistant

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FS25](https://img.shields.io/badge/Farming%20Simulator-2025-green)](https://www.farming-simulator.com/)
[![Claude](https://img.shields.io/badge/Claude-Skill-orange)](https://claude.ai)
[![Community](https://img.shields.io/badge/Community-Driven-blue)]()

> **The first Claude skill built specifically for Farming Simulator 25 mod development.**  
> Supercharge your FS25 modding workflow with AI that actually knows the APIs, patterns, and pitfalls.

---

## What Is This?

This is a **Claude Skill** — a packaged knowledge base that makes Claude dramatically more useful for FS25 mod development. Instead of Claude hallucinating FS25 APIs or suggesting patterns that crash your game, this skill gives it:

- ✅ **Battle-tested code patterns** — validated against 164+ community mods
- ✅ **Complete API reference index** — 1,661 LUADOC pages, 11,102+ functions
- ✅ **Giants source code reference** — 267 Lua files from the game itself
- ✅ **Known pitfalls & fixes** — 17+ common mistakes that will crash your mod
- ✅ **FS25-specific Lua quirks** — sandboxed environment, Lua 5.1, no `os.time()`, etc.

---

## 🎬 Quick Demo

With this skill installed, ask Claude things like:

> *"Create a custom dialog that lets players take out a loan"*  
> *"How do I sync vehicle state in multiplayer?"*  
> *"What's the correct way to save custom data to savegames?"*  
> *"Why does my dialog crash when I open it?"*  
> *"Write a vehicle specialization that tracks fuel consumption"*  

Claude will respond with code that **actually works** in FS25.

---

## 📦 Installation

### Prerequisites
- [Claude.ai](https://claude.ai) account (Pro recommended for longer context)
- The `.skill` file from the [latest release](../../releases/latest)

### Steps

1. **Download** the `fs25-modding.skill` file from [Releases](../../releases/latest)

2. **Locate your skills folder** — typically:
   ```
   Windows: %APPDATA%\Claude\skills\
   macOS:   ~/Library/Application Support/Claude/skills/
   Linux:   ~/.config/Claude/skills/
   ```
   > 💡 You can also place it in your mod project folder and point Claude to it from there.

3. **Copy** `fs25-modding.skill` into the skills folder

4. **Restart Claude** (desktop app or refresh browser)

5. **Verify** — Ask Claude: *"What FS25 modding skills do you have?"*

### For Mod Projects (Recommended)
Place the skill file alongside your mods:
```
MyMods/
├── FS25_MyAwesomeMod/
│   ├── modDesc.xml
│   └── scripts/
├── FS25_AnotherMod/
└── fs25-modding.skill   ← put it here
```

---

## 📚 Knowledge Base Contents

This skill bundles three community knowledge sources:

### 1. FS25 AI Coding Reference (Patterns)
Validated patterns from the [UsedPlus](https://github.com/Farming-Simulator-Modding) team — built by analyzing 164+ working mods.

| Category | Files | Coverage |
|----------|-------|----------|
| Basics | 4 files | modDesc, Lua patterns, localization, input |
| Patterns | 14 files | GUI, Events, Managers, Save/Load, Economy... |
| Advanced | 8 files | Vehicles, Placeables, HUD, Animations... |
| Pitfalls | 1 file | 17 battle-tested crash fixes |

### 2. FS25 Community LUADOC Index
Full index of the [FS25-Community-LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC) by [@umbraprior](https://github.com/umbraprior).

| Metric | Value |
|--------|-------|
| Documentation pages | 1,661 |
| Script functions documented | 11,102+ |
| Categories | Engine, Foundation, Script APIs |

### 3. Giants Source Code Index
Index of [FS25-lua-scripting](https://github.com/Dukefarming/FS25-lua-scripting) by [@Dukefarming](https://github.com/Dukefarming).

| Metric | Value |
|--------|-------|
| Lua source files | 267 |
| Key systems covered | Vehicles, GUI, Economy, Animals, Triggers... |

---

## 🔧 What Claude Will Know

### Critical FS25 Facts (Built Into the Skill)

```lua
-- ✅ CORRECT: FS25 uses sandboxed Lua — no os.time()
local gameDay = g_currentMission.environment.currentDay

-- ✅ CORRECT: Dialog base class
MyDialog = Class(MyDialog, MessageDialog)  -- NOT DialogElement!

-- ✅ CORRECT: Yes/No dialog
YesNoDialog.show(callback, text, title)    -- NOT g_gui:showYesNoDialog()

-- ✅ CORRECT: Dropdown (not Slider!)
MultiTextOptionElement:setTexts({"Option 1", "Option 2"})

-- ✅ CORRECT: Always guard server code
if g_server ~= nil then
    -- server-only logic
end
```

### Pattern Library Highlights
- **GUI Dialogs** — Full MessageDialog pattern with XML, focus management, controller support
- **Network Events** — Multiplayer-safe read/writeStream pattern
- **Save/Load** — XMLElement savegame persistence
- **Vehicle Specializations** — Full registration, lifecycle, network sync
- **HUD Elements** — Custom vehicle info and overlay elements
- **Trigger Zones** — Collision triggers with timers
- **Economy** — Loan/depreciation calculations

---

## 🤝 Community Credits

This skill stands on the shoulders of incredible community work:

| Project | Creator | What it provides |
|---------|---------|-----------------|
| [FS25-Community-LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC) | [@umbraprior](https://github.com/umbraprior) | Complete API reference |
| [FS25-lua-scripting](https://github.com/Dukefarming/FS25-lua-scripting) | [@Dukefarming](https://github.com/Dukefarming) | Giants source archive |
| [FS25_AI_Coding_Reference](https://github.com/usedplus) | UsedPlus team | Battle-tested patterns |
| This skill | You + the community | Putting it all together |

---

## 🗺️ Roadmap

- [ ] v1.0 — Initial release with all three knowledge bases
- [ ] v1.1 — Add Giants SDK official docs index
- [ ] v1.2 — Add modDesc.xml schema validation helpers
- [ ] v1.3 — Add community mod examples index (top 50 mods)
- [ ] v2.0 — Separate specialized skills (GUI skill, Vehicle skill, etc.)
- [ ] Ongoing — Keep LUADOC index updated as community docs grow

---

## 🤔 FAQ

**Q: Does this work with FS22 mods?**  
A: Mostly yes — many patterns are similar. But some APIs changed between FS22 and FS25. The skill is validated against FS25.

**Q: Does Claude need internet access to use the LUADOC?**  
A: No! The LUADOC index is bundled inside the skill. Claude knows *where* things are in the docs, even offline.

**Q: Will this replace reading the actual docs?**  
A: No — it makes Claude smarter about pointing you to the right docs and writing better initial code. Always verify with the actual LUADOC for function signatures.

**Q: Can I contribute new patterns?**  
A: Yes! See [CONTRIBUTING.md](CONTRIBUTING.md). Pull requests welcome.

**Q: What Claude tier do I need?**  
A: Free tier works. Pro is recommended for longer mod files and complex questions.

---

## 📄 License

MIT License — see [LICENSE](LICENSE). The bundled community documentation retains its original licenses from the respective creators.

---

## ⭐ Show Your Support

If this skill saves you time debugging FS25 mods, give it a star! And share it with your modding community — the more people use it, the better the feedback loop for improvements.

---

<div align="center">

**Made with 🚜 for the FS25 modding community**

*First Claude skill for Farming Simulator 25 — April 2026*

</div>
