# 🚜 FS25 Claude Skill — AI-Powered Mod Development Assistant

[![Release](https://img.shields.io/github/v/release/TheCodingDad-TisonK/fs25-claude-skill?include_prereleases&style=flat-square)](https://github.com/TheCodingDad-TisonK/fs25-claude-skill/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Farming Simulator 25](https://img.shields.io/badge/Farming%20Simulator-2025-green?style=flat-square)](https://www.farming-simulator.com/)
[![Claude Skill](https://img.shields.io/badge/Claude-Skill-orange?style=flat-square)](https://claude.ai)

> **"The first definitive Claude skill built specifically for Farming Simulator 25 mod development."**  
> Supercharge your FS25 modding workflow with AI that actually knows the APIs, patterns, and pitfalls.

---

## 🎩 Meet the Experts

When you use this skill, you aren't just talking to a generic AI. You're working with a specialized team:

- **Claude (Senior Software Engineer)**: 🎩 Focuses on technical mandates, Lua 5.1 sandboxing, and high-performance patterns. He ensures your code won't crash the Giants Engine.
- **Samantha (Project Manager)**: 🚀 Keeps your mod project on track, manages repo structure, and ensures you're following the best community standards.

---

## 📖 What Is This?

This is a **Claude Skill** — a modular, self-contained knowledge package that transforms Claude into an expert FS25 developer. It replaces "AI hallucinations" with battle-tested facts.

### The Knowledge Base At A Glance
| Resource | Content | Coverage |
|----------|---------|----------|
| **Engine Source** 🆕 | 1,413 classes · 119 MessageTypes · 392 globals | Extracted from the **full decompiled `dataS/scripts`** — 1,842 files, ~411k lines |
| **Game Data** 🆕 | 5,763 l10n keys · 512 GUI profiles · 254 input actions | Legal values straight from the shipped `dataS` XML |
| **LUADOC** | 1,661 Documentation Pages | 11,102+ Script Functions — bundled index + WebFetch |
| **Source Archive** | 267 Giants Lua Files | Internal engine implementation, vendored |
| **Patterns** | 30+ Validated Templates | GUI, Events, Save/Load, Vehicles, HUD, Field Detection |
| **Pitfalls** | 20+ Critical "Crash Traps" | os.time(), DialogElement, goto, hook accumulation, mouseEvent |

> **v2.0.0 is the source-verified release.** Every "critical fact" from v1 was re-checked
> against the game's own decompiled engine code. Several did not survive — including a
> `modDesc` template that produced mods the game silently refuses to load. See
> [CHANGELOG.md](CHANGELOG.md) and `references/giants-source/VERIFIED-FACTS.md` for the
> full audit trail with `path:line` citations.

---

## 🎬 Quick Demo

Ask Claude (or me!) anything about FS25 modding:

> 🎩 *"Claude, I need a multiplayer-safe event that syncs a custom 'damageLevel' variable."*  
> 🚀 *"Samantha, what's the correct directory structure for a vehicle specialization mod?"*  
> 🚜 *"How do I create a custom Yes/No dialog that actually works in FS25?"*  
> 🌾 *"What field is the player currently standing in, and how do I detect it reliably?"*

---

## 🔧 Technical Mandates (The "Ground Truth")

This skill enforces strict adherence to FS25's unique environment. Each mandate below
is verified against the decompiled engine source:

1. **`descVersion` must be 90–111** — `main.lua:29-30`. Outside that range `mods.lua`
   rejects the mod *before your scripts load* and it never appears in the mod list.
   Use `104`. ⚠️ *v1 of this skill shipped a template with `83`.*
2. **Sandboxed Lua**: No `os.time()` (zero `os.*` references in 411k lines of engine
   code), no `goto`, no `table.move()`.
3. **The mod sandbox rewrites your environment**: your globals are private to your mod,
   `g_i18n` is swapped for a mod-scoped instance, and `InitEventClass` /
   `InitObjectClass` / `addSpecialization` **auto-prefix with your mod name** — pass the
   short name or you get `MyMod.MyMod.MyEvent`.
4. **GUI geometry** is against a **1920×1080 reference** (`main.lua:91-92`); values may
   be `Npx`, `Ndp`, or normalized 0–1.
5. **Manager Safety**: Always nil-check `g_server` (it is `nil` on a pure client) and
   `g_client` (`nil` on a dedicated server).
6. **Base Classes**: Extend `MessageDialog` for message-style dialogs — it already
   extends `DialogElement` and gives you the open/close lifecycle.
7. **Hook Cleanup**: Always restore `appendedFunction` hooks on mod unload — they stack
   on savegame reload. Same for `g_messageCenter:unsubscribeAll(self)`.

---

## 📦 Installation & Setup

### 1. Download
Grab the latest `.skill` file from the [Releases](https://github.com/TheCodingDad-TisonK/fs25-claude-skill/releases) page.

### 2. Location
Place the `fs25-modding-skill.skill` file in your Claude skills folder:
- **Windows**: `%APPDATA%\Claude\skills\`
- **Mac/Linux**: `~/.claude/skills/`
- **Project-level**: Drop it in your mod project root

### 3. Activate
Restart your Claude session. The skill activates automatically whenever you mention "FS25", "Farming Simulator", paste Lua mod code, or reference Giants Engine APIs.

---

## 📚 Deep Dive: Knowledge Sources

This skill stands on the shoulders of the community's hardest workers:

### 0. Decompiled Engine Source (rank 1) 🆕 in v2.0.0
The complete `dataS/scripts` corpus — 1,842 Lua files, ~411,000 lines — decompiled from
your own game install. This outranks every other source, because the others are partial:
the vendored archive is a 267-file subset, and the LUADOC has no page at all for several
load-bearing classes (`Farm`, `HusbandrySystem`, `Storage`, `BaseMission`).

- **How it works**: point `$FS25_DECODED` at your decompiled `dataS` (default
  `D:\FS25_Decoded`). Claude greps it directly and cites `path:line`.
- **You do not need it to use this skill.** Everything already extracted —
  1,413 classes, 119 MessageTypes, the globals table, the mod sandbox rules, the
  corrections — is committed under `references/giants-source/` and ships in the
  `.skill` package. Without a local copy Claude falls back to the vendored source and
  LUADOC and labels those answers doc-grade.
- **Nothing from your game is redistributed here** — the committed files hold derived
  metadata (names, paths, counts, signatures) and short excerpts quoted for commentary.
- ⚠️ Decompiled output has artifacts. **Local variable names are unreliable** — see
  `references/giants-source/DECOMPILED-CAVEATS.md` before reporting an engine "bug".

### 1. FS25 Community LUADOC
Provided by [@umbraprior](https://github.com/umbraprior). Complete API coverage from Engine to Script.
- 1,661 pages · 11,102+ documented functions
- **How it works**: The skill indexes all paths locally; Claude uses **WebFetch** to retrieve full docs on demand — no local install required.
- Repo: [umbraprior/FS25-Community-LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC)

### 2. FS25 Lua Scripting (Source Archive)
Provided by [@Dukefarming](https://github.com/Dukefarming). The actual Giants source code (dataS) for reference.
- 267 Lua files — understand how Giants implements things internally
- **How it works**: Same WebFetch-on-demand pattern as the LUADOC.
- Repo: [Dukefarming/FS25-lua-scripting](https://github.com/Dukefarming/FS25-lua-scripting)

### 3. FS25 AI Coding Reference (Patterns)
Provided by [@XelaNull](https://github.com/XelaNull) (FS25_UsedPlus). Battle-tested patterns validated against an 83-file production mod with 30+ custom dialogs.
- Bundled directly in the skill — works offline, no fetching needed.
- Repo: [XelaNull/FS25_UsedPlus/FS25_AI_Coding_Reference](https://github.com/XelaNull/FS25_UsedPlus/tree/master/FS25_AI_Coding_Reference)

---

## 🗺️ Roadmap & Community

We're building this together. Join the effort!

- [x] **v1.0.0** — Initial release with full 3-way knowledge integration
- [x] **v1.1.0** — WebFetch live lookups (LUADOC + source, no local files needed), field detection pattern, 3 new pitfalls, proper attribution
- [x] **v2.0.0** — **Source-verified rebuild.** Decompiled engine corpus as rank-1
      authority; class/MessageType/globals indexes; mod sandbox documented; 6 v1 facts
      corrected; release pipeline fixed
- [ ] **v2.1.0** — Specialized sub-skills (e.g., "The GUI Expert", "The Vehicle Architect")
- [ ] **v2.2.0** — `modDesc.xml` schema validation helpers
- [ ] **v2.3.0** — Top 20 community mods indexed as pattern sources

### Contributing
Found a new pitfall? Have a pattern that's better than ours? 🎩 Claude and 🚀 Samantha love pull requests! See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📄 License

MIT License. Bundled community documentation retains its original licenses from the respective creators. See [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with 🚜 for the FS25 modding community**

*Senior Engineer: Claude · Project Manager: Samantha*

</div>
