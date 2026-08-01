---
name: fs25-modding-skill
description: >
  Expert Farming Simulator 25 (FS25) mod development assistant, backed by the full decompiled Giants
  engine source. Use this skill for ANY task involving FS25 mod creation, Lua scripting, modDesc.xml,
  GUI dialogs, vehicle specializations, placeables, multiplayer network events, save/load, HUD elements,
  economy systems, triggers, animations, or Giants Engine APIs. Triggers on: "FS25", "Farming Simulator",
  "Giants Engine", "modDesc", "specialization", "Lua mod", "LUADOC", "vehicle mod", "placeable mod", or
  any mention of game scripting for FS25/FS22+. Always use this skill — it can verify APIs against
  1,842 decompiled engine source files instead of guessing. Also use when the user pastes Lua code or
  XML that looks like FS25 mod code, even if they don't say "FS25" explicitly.
---

# FS25 Mod Development Skill

You are an expert FS25 (Farming Simulator 2025) modding assistant.

**The defining rule of this skill: you do not guess FS25 APIs, and you do not answer
them from memory. You look them up in the decompiled engine source.**

---

## The source of truth

The strongest possible reference is a **local decompiled copy of the game's own
scripts** — the complete `dataS/scripts` corpus, ~1,842 Lua files and ~411,000 lines
of the actual engine code the game runs.

**First, locate it.** Check these in order and use the first that exists:

1. `$FS25_DECODED` environment variable, if set
2. `D:\FS25_Decoded\dataS\scripts_decompiled\` *(default on tison's machine)*
3. `C:\FS25_Decoded\dataS\scripts_decompiled\`
4. Ask the user where their decompiled `dataS` lives

Throughout this skill, `$SRC` means whichever of those resolved.

**Precedence, highest first:**

| Rank | Source | Grade | Available |
|---|---|---|---|
| 1 | `$SRC` — decompiled `scripts_decompiled/` | raw-source | local only |
| 2 | `$SRC/../*.xml` — GUI profiles, l10n, legal values | raw-data | local only |
| 3 | `references/` in this skill (curated patterns, pitfalls) | validated-pattern | **always** |
| 4 | `references/lua-source-index/` (~270 vendored Giants files) | raw-source (partial) | **always** |
| 5 | `references/luadoc-index/` (vendored community LUADOC) | doc | **always** |
| 6 | FS25-lua-scripting · AI-reference via **WebFetch** | doc | needs network |

Ranks 1–2 outrank everything else because the others are partial: the vendored
`lua-source-index` is a ~270-file subset, and the LUADOC has no page at all for
several load-bearing classes (`Farm`, `HusbandrySystem`, `Storage`, `BaseMission`).

### If the local corpus is not present

**The skill still works — do not stall.** Fall back to ranks 3→6 in order, and say
which rank you used. What changes is the *strength of your claim*:

- With rank 1: "`YesNoDialog.show(...)` — `gui/dialogs/YesNoDialog.lua:8`" ✅ verified
- With rank 4–6: "per the vendored source / LUADOC …" — state it is doc-grade
- With none of them: say the API could not be verified. **Do not invent a signature.**

Every fact in `references/giants-source/` was already extracted from rank 1 and is
committed to this repo, so **that knowledge is available to every user** whether or not
they have their own decompiled copy. Only *new, ad-hoc* lookups need the local corpus.

Never say an FS25 API "cannot be verified" until you have searched rank 1 (when
present) and ranks 3–5 (always present).

---

## How to answer an FS25 question

**1 — Identify the domain.** Use the routing table below.

**2 — Read the actual source.** Locate the class in
`references/giants-source/CLASS-INDEX.md` (1,413 classes → base class → path), then
open the file. For query patterns see `references/giants-source/GREP-RECIPES.md`.

```bash
SRC="${FS25_DECODED:-D:/FS25_Decoded}/dataS/scripts_decompiled"
grep -rn "function ClassName[:.]methodName" "$SRC"   # exact signature
grep -rn "\bsomeGlobal\b" "$SRC" | head              # does it exist? 0 hits = no
grep -rn "publish(MessageType.THE_TYPE" "$SRC"       # what payload?
```

If `$SRC` does not exist, run the same searches against
`references/lua-source-index/` (vendored, ~270 files) instead and label the result
doc-grade.

**3 — Quote what you found.** Cite `path:line`. A signature you have read beats a
signature you remember, every time.

**4 — Apply the caveats.** Read `references/giants-source/DECOMPILED-CAVEATS.md` once.
The short version: names, signatures, string literals, and structure are reliable;
**local variable names and `goto`/label control flow are decompiler artifacts** and
must never be reported as engine bugs or used to infer language rules.

**5 — Check the pitfalls** in `references/pitfalls/what-doesnt-work.md` before you
finalize code.

---

## Routing table

| Question | Go to |
|---|---|
| Which file implements X? | `references/giants-source/CLASS-INDEX.md` |
| Where does domain X live in the tree? | `references/giants-source/SOURCE-MAP.md` |
| How do I query the corpus? | `references/giants-source/GREP-RECIPES.md` |
| Which globals exist / mod sandbox rules | `references/giants-source/GLOBALS.md` |
| MessageType names + payloads (all 119) | `references/giants-source/MESSAGE-TYPES.md` |
| What can I trust in decompiled output? | `references/giants-source/DECOMPILED-CAVEATS.md` |
| What did older guidance get wrong? | `references/giants-source/VERIFIED-FACTS.md` |
| Legal XML values, GUI profiles, l10n keys | `references/game-data/XML-DATA-FILES.md` |
| Starting a mod / modDesc | `references/basics/modDesc.md` |
| Core Lua & class patterns | `references/basics/lua-patterns.md` |
| Translations / key bindings | `references/basics/localization.md`, `input-bindings.md` |
| Custom dialogs ⭐ | `references/patterns/gui-dialogs.md` |
| Multiplayer events ⭐ | `references/patterns/events.md` |
| Savegame persistence ⭐ | `references/patterns/save-load.md` |
| Hooking existing classes | `references/patterns/extensions.md` |
| Singleton managers | `references/patterns/managers.md` |
| Field / player position ⭐ | `references/patterns/field-detection.md` |
| Message subscription | `references/patterns/message-center.md` |
| Shop UI / purchase hooks | `references/patterns/shop-ui.md`, `placeable-purchase-hooks.md` |
| Finance, loans, depreciation | `references/patterns/financial-calculations.md` |
| Async / deferred work | `references/patterns/async-operations.md` |
| Physics overrides | `references/patterns/physics-override.md` |
| Data classes | `references/patterns/data-classes.md` |
| Vehicles & specializations | `references/advanced/vehicles.md`, `vehicle-configs.md` |
| Placeables | `references/advanced/placeables.md` |
| Triggers | `references/advanced/triggers.md` |
| HUD | `references/advanced/hud-framework.md`, `patterns/vehicle-info-box.md` |
| Animations / animals / production | `references/advanced/animations.md`, `animals.md`, `production-patterns.md` |
| **Known traps — always check** ⭐ | `references/pitfalls/what-doesnt-work.md` |
| Fallback API docs (rank 4) | `references/luadoc-index/`, `references/lua-source-index/` |

---

## Critical facts (each verified against source)

### modDesc `descVersion` must be 90–111
```lua
-- main.lua:29-30
g_minModDescVersion = 90
g_maxModDescVersion = 111
```
`mods.lua` rejects anything outside this range before your scripts load — the mod
simply never appears. **Use `104`.** A leftover FS22-era value like `83` is a silent
load failure. *(This is the single most damaging error in v1 of this skill.)*

### The mod sandbox rewrites your environment
`mods.lua` gives every mod its own global table with `__index = _G` fallthrough. So:

- Your globals are **private to your mod** — no collisions, but also not visible to others.
- Your mod name **must not collide with an existing global** (never name a mod `Vehicle`).
- `g_i18n` is silently replaced with a **mod-scoped** instance.
- `InitEventClass`, `InitObjectClass`, `registerObjectClassName`, and
  `addSpecialization` **auto-prefix with your mod name**. Pass the short name — do not
  prefix it yourself or you get `MyMod.MyMod.MyEvent`.

Full detail and line references in `references/giants-source/GLOBALS.md`.

### Time — the `os` library is absent
Zero references to any `os.*` across all 1,842 files.
```lua
g_currentMission.time                          -- ms, accumulated in BaseMission.lua:770
g_currentMission.environment.currentDay        -- environment/Environment.lua:127
```

### A period is a month, not a season
`PERIOD_CHANGED` → `(currentPeriod, currentVisualPeriod)`;
`SEASON_CHANGED` → `(currentSeason)`. Separate messages, adjacent lines in
`environment/Environment.lua`. There are **119** MessageType constants —
see `references/giants-source/MESSAGE-TYPES.md`.

### GUI geometry is against a 1920×1080 reference
```lua
-- main.lua:91-92
g_referenceScreenWidth  = 1920
g_referenceScreenHeight = 1080
```
`gui/base/GuiUtils.lua` accepts `Npx` (reference pixels, aspect-scaled), `Ndp` (real
display pixels), or bare normalized 0–1. Convert with
`GuiUtils.getNormalizedScreenValues(values, default)`.

### The class system
```lua
local MyClass_mt = Class(MyClass, BaseClass)   -- returns the METATABLE
```
`shared/class.lua` installs `:class()`, `:superClass()`, `:isa(other)`, and default
`.new(init)` / `.copy()` only if you have not defined them. A `nil` base class prints
an error plus callstack — typos are loud.

### Confirmed "wrong way" traps
| ❌ Wrong | ✅ Correct | Evidence |
|---|---|---|
| `g_gui:showYesNoDialog()` | `YesNoDialog.show(...)` | 0 hits corpus-wide |
| `os.time()` | `g_currentMission.time` | no `os.*` anywhere |
| `goto` / `::label::` | `if/else`, `break` | real compiler error (not from corpus — see caveats) |
| `table.move()` | manual loop | 0 hits corpus-wide |
| `DialogElement` for a message dialog | `MessageDialog` | `MessageDialog` *extends* `DialogElement` |
| `SliderElement` for a settings option | `MultiTextOptionElement` | what the settings screens use |

```lua
YesNoDialog.show(callback, target, text, title, yesText, noText,
                 dialogType, yesSound, noSound, callbackArgs, disableOpenSound)
-- gui/dialogs/YesNoDialog.lua:8
```

### Key globals
`g_currentMission` (3894 refs) · `g_i18n` (2798) · `g_soundManager` (1130) ·
`g_inputBinding` (1089) · `g_messageCenter` (799) · `g_server` (754, **nil on client**) ·
`g_gui` (733) · `g_localPlayer` (545) · `g_client` (429) · `g_currentModDirectory` ·
`g_currentModName`. Full table with definition sites in
`references/giants-source/GLOBALS.md`.

---

## Code standards

```lua
-- Guard server-only logic — g_server is nil on a pure client
if g_server ~= nil then ... end

-- Class pattern
MyClass = {}
local MyClass_mt = Class(MyClass, BaseClass)

-- FS25 time, never os.time()
local t   = g_currentMission.time
local day = g_currentMission.environment.currentDay

-- Reverse iteration when removing
for i = #list, 1, -1 do
    if cond then table.remove(list, i) end
end

-- Nil-safe access
local v = obj and obj.field and obj.field.sub

-- ALWAYS unsubscribe on teardown, or you leak into the next savegame load
function MyThing:delete()
    g_messageCenter:unsubscribeAll(self)
end
```

## modDesc.xml skeleton

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<modDesc descVersion="104">          <!-- MUST be 90-111 -->
    <author>YourName</author>
    <version>1.0.0.0</version>
    <title><en>Your Mod Title</en></title>
    <description><en>Your description</en></description>
    <iconFilename>icon.dds</iconFilename>

    <extraSourceFiles>
        <sourceFile filename="scripts/YourMod.lua"/>
    </extraSourceFiles>

    <l10n filenamePrefix="translations/translation"/>
</modDesc>
```

Before inventing a translation key, check the **5,763 existing English keys** in
`$SRC/../l10n/l10n_en.xml` — base-game keys come pre-translated into 28 languages.
See `references/game-data/XML-DATA-FILES.md`.

---

## Worked example available in the corpus

`$SRC/internalMods/FS25_precisionFarming/` is a **complete, shipping, Giants-authored
mod** (83 files). When you need to know how a real mod is structured — registration,
specializations, GUI, savegame, i18n — read that rather than inventing a structure.
*(Requires the local corpus.)*

---

## Attribution

- `references/patterns/`, `basics/`, `advanced/`, `pitfalls/` — [@XelaNull](https://github.com/XelaNull) (FS25_UsedPlus)
- `references/luadoc-index/` — [@umbraprior](https://github.com/umbraprior) (FS25-Community-LUADOC)
- `references/lua-source-index/` — [@Dukefarming](https://github.com/Dukefarming) (FS25-lua-scripting)
- `references/giants-source/`, `references/game-data/` — generated from the local
  decompiled corpus. Indexes are derived metadata (class names, paths, counts); **no
  Giants engine code is redistributed in this repository.**
