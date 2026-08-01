# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2026-08-01

### 🔬 The Source-Verified Release

v1 answered from curated notes and live doc lookups. **v2 answers from the game's own
decompiled engine source** — 1,842 Lua files, ~411,000 lines of `dataS/scripts`. Every
claim below was checked against it, and several long-standing "facts" did not survive.

### ⚠️ Corrected — one of these was breaking mods

- **`descVersion` must be 90–111. v1's template said `83`.**
  Verified at `main.lua:29-30` (`g_minModDescVersion = 90`, `g_maxModDescVersion = 111`);
  `mods.lua` rejects anything outside the range *before your scripts load*, so the mod
  simply never appears in the list. A mod built from v1's skeleton would silently fail
  to load. **If you copied that template, change it to `104`.**
- **`PERIOD_CHANGED` is not the season change.** v1 annotated it as such. It is the
  *month* change; `SEASON_CHANGED` is separate. They are published on adjacent lines of
  `environment/Environment.lua`. Payloads differ too:
  `PERIOD_CHANGED(currentPeriod, currentVisualPeriod)` vs `SEASON_CHANGED(currentSeason)`.
- **`table.pack()` is not documented as unavailable any more.** The claim carried no
  validation evidence and the base game uses it in three places. Dropped rather than
  reversed — the sandbox is untested. `{...}` remains the safe choice. `table.move()`
  really is absent (0 hits).
- **GUI geometry** is against a **1920×1080 reference** (`main.lua:91-92`), not the
  "top of screen ≈ 600px" v1 described. `GuiUtils` accepts `Npx`, `Ndp`, or normalized.
- **`DialogElement` is not "wrong"** — it is the *parent* of `MessageDialog`. Extend
  `MessageDialog` for message-style dialogs; the old advice was directionally right but
  factually confused.
- **`SliderElement` exists and works.** The real guidance is to use
  `MultiTextOptionElement` for discrete settings options.
- **`goto` guidance kept, reasoning fixed.** The corpus contains 180 `goto`s — but as
  decompiler artifacts (`goto l19`, `::l12::`). The rule still stands on a real compiler
  error, and is now flagged so nobody "corrects" it from the source.

### Added — `references/giants-source/`

- **`CLASS-INDEX.md`** — 1,413 classes mapped to base class and source path.
- **`MESSAGE-TYPES.md`** — all **119** `MessageType` constants (v1 listed 6), with
  verified callback payloads and the full `MessageCenter` API.
- **`GLOBALS.md`** — every major global with reference count and definition site, plus
  a full writeup of **the mod sandbox** (`mods.lua`): the per-mod `_G` table, the
  `__index = _G` fallthrough, the mod-scoped `g_i18n`, and the auto-namespacing of
  `InitEventClass` / `InitObjectClass` / `registerObjectClassName` /
  `addSpecialization`. This explains a whole class of multiplayer event-name bugs.
- **`SOURCE-MAP.md`** — the 1,842-file tree by domain, so lookups start in the right place.
- **`GREP-RECIPES.md`** — ten query patterns that answer real API questions from source.
- **`DECOMPILED-CAVEATS.md`** — what is and is not trustworthy in decompiled output,
  with a worked example. **Local variable names are unreliable; never report a
  base-game defect on the strength of one.**
- **`VERIFIED-FACTS.md`** — the full audit trail: every v1 claim, its verdict, and the
  `path:line` evidence.

### Added — `references/game-data/`

- **`XML-DATA-FILES.md`** — the `dataS` XML corpus: 5,763 English l10n keys, 512 GUI
  profiles, 254 input actions, 66 placeable types, 66 placeable specializations, 152
  vehicle types — with the full lists of placeable types and specs inline. Check base
  keys before inventing your own; they arrive pre-translated in 28 languages.

### Changed

- **Lookup order inverted.** Local decompiled source is now rank 1; WebFetch is a
  fallback, not the primary path. Answers cite `path:line`.
- **Graceful degradation.** The corpus path is configurable via `$FS25_DECODED`, and
  the skill explicitly defines what to do when it is absent — falling back to the
  vendored source and LUADOC, and labelling answers doc-grade instead of stalling.
  **Everything extracted into `references/giants-source/` ships in the package, so all
  users get the verified facts whether or not they have their own decompiled copy.**
- `references/basics/modDesc.md` — documents the enforced 90–111 range and the silent
  load failure it causes.
- `references/patterns/message-center.md` — corrected period/season, added payloads,
  documented that `SETTING_CHANGED` is a table indexed by setting name.
- `references/pitfalls/what-doesnt-work.md` — `goto` entry now warns against
  "correcting" it from decompiled artifacts.

### Fixed

- **Release workflow would not have attached the package.** It looked for
  `skill/fs25-modding.skill`; the packager emits `skill/fs25-modding-skill.skill`.
- **`package_skill.py` crashed on Windows** with `UnicodeEncodeError` after writing a
  valid zip — a non-zero exit that would have failed the release step. It now degrades
  instead of dying.

### Not included

No Giants engine code is redistributed by the new reference files. `giants-source/`
contains derived metadata — class names, paths, counts, signatures — plus short
excerpts quoted for technical commentary.

---

## [1.1.0] - 2026-04-09

### Added
- **3 new pitfalls** in `references/pitfalls/what-doesnt-work.md`:
  - #18: Dialog callback naming conflict — `onClose`/`onOpen` clash with GUI system lifecycle
  - #19: HUD `mouseEvent` — must return `true` when consuming event, or clicks fall through
  - #20: Hook accumulation — `appendedFunction` hooks stack on savegame reload without cleanup
- **New pattern file** `references/patterns/field-detection.md`:
  - Field vs Farmland concepts explained
  - 4-tier player position detection with pcall safety (adopted from FS25_NPCFavor)
  - 3-tier field detection fallback via `g_fieldManager` → farmland → manual iteration
  - Timing warning: `g_fieldManager.fields` is empty at init — delayed retry pattern included
- Updated `SKILL.md` routing table to include the new `field-detection.md` pattern

- **WebFetch integration** for LUADOC and lua-source lookups:
  - `LUADOC-INDEX.md` — updated with base URL + WebFetch instructions; any user can now look up live LUADOC docs without local files
  - `LUA-SOURCE-INDEX.md` — same; live Giants source fetchable via WebFetch
  - `SKILL.md` — steps 2 & 3 now explicitly instruct Claude to use WebFetch
- **New index** `references/ai-coding-reference/AI-CODING-REFERENCE-INDEX.md` — documents all files from XelaNull's FS25 AI Coding Reference with live WebFetch URLs as fallback
- **Fixed attribution** — README.md and SKILL.md now properly credit [@XelaNull](https://github.com/XelaNull) for the pattern/pitfalls/basics/advanced reference files

### Validated In
- FS25_SoilFertilizer v1.5.1.0 (pitfalls #18, #19 from issue #130)
- FS25_SoilFertilizer v1.5+ and FS25_NPCFavor v2.6+ (field detection pattern)

---

## [1.0.0] - 2026-04-06

### 🎉 Initial Release

The first Claude skill for Farming Simulator 25 mod development!

### Added
- **SKILL.md** — Core skill with critical facts, pitfalls, and navigation guide
- **references/basics/** — 4 files covering modDesc, Lua patterns, localization, input bindings
- **references/patterns/** — 14 battle-tested patterns (GUI, Events, Save/Load, Economy, HUD, Shop...)
- **references/advanced/** — 8 advanced topics (Vehicles, Placeables, Triggers, HUD, Animations...)
- **references/pitfalls/** — 17 documented pitfalls from real mod development crashes
- **references/luadoc-index/** — Complete index of 1,661 LUADOC pages with quick lookup guide
- **references/lua-source-index/** — Index of 267 Giants Lua source files with directory guide
- **GitHub repo** — Full documentation, contributing guide, issue templates, CI workflow

### Knowledge Sources Bundled
- FS25_AI_Coding_Reference — patterns validated against 83-file production mod codebase
- FS25-Community-LUADOC index — 11,102+ function coverage
- FS25-lua-scripting index — Full Giants dataS source archive reference

---

## [Unreleased]

### Planned
- Giants SDK official docs integration
- Top 50 community mods index
- Separate specialized sub-skills (GUI, Vehicle, Economy)
- FS22 compatibility notes
