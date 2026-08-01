# v1 Claims, Re-checked Against Source

Every "critical fact" the v1 skill asserted, re-tested against the decompiled corpus.
Each row cites where the answer came from. This file exists so the corrections are
auditable, not just applied.

`SRC = D:/FS25_Decoded/dataS/scripts_decompiled`

---

## ❌ Corrected — v1 was wrong

### 1. `modDesc descVersion` — v1 said `83`, the game rejects it

```lua
-- main.lua:29-30
g_minModDescVersion = 90
g_maxModDescVersion = 111
```

`mods.lua` enforces this and refuses to load the mod:

```lua
if revisionStr < g_minModDescVersion or g_maxModDescVersion < revisionStr then
    printError("Error: Unsupported mod description version in mod " .. modName)
```

**Use a descVersion between 90 and 111.** The v1 template's `descVersion="83"` would
have produced a mod the game silently refuses to load. *(All of tison's existing mods
use 92–108 and are unaffected — only the skill's template was wrong.)*

### 2. `PERIOD_CHANGED` is not the season change

v1 annotated `MessageType.PERIOD_CHANGED -- Season change`. They are distinct messages,
published on adjacent lines:

```lua
-- environment/Environment.lua:414,417
g_messageCenter:publish(MessageType.PERIOD_CHANGED, self.currentPeriod, self.currentVisualPeriod)
g_messageCenter:publish(MessageType.SEASON_CHANGED, self.currentSeason)
```

A period is a month. **Use `SEASON_CHANGED` for seasons.**

### 3. "GUI: top of screen = ~600px"

The reference resolution is **1920×1080**, not 600-anything:

```lua
-- main.lua:91-92
g_referenceScreenWidth  = 1920
g_referenceScreenHeight = 1080
```

`gui/base/GuiUtils.lua` accepts three unit forms: `Npx` (pixels against the 1920×1080
reference, then aspect-scaled by `g_aspectScaleX/Y`), `Ndp` (actual display pixels,
against `g_screenWidth/Height`), and bare numbers (already normalized 0–1). Convert
with `GuiUtils.getNormalizedScreenValues(values, default)`.

### 4. "`table.pack()` is not available" — unsupported, and contradicted

v1's fact table listed `table.pack()` as unavailable, alongside `table.move()`. Unlike
the `goto` rule, **no validation evidence was ever recorded for it** — it appears in no
pitfalls entry and cites no compiler error. The corpus contradicts it: base-game code
uses `table.pack` in three places that read as genuine authored source, not artifacts.

```lua
-- collections/ObjectPool.lua:13
self.objectConstructorArguments = table.pack(...)
-- utils/TargetedFunction.lua:8
self.arguments = table.pack(...)
-- utils/TargetedFunction.lua:23
return table.unpack(table.getListUnion(self.arguments, table.pack(...)))
```

**The claim has been dropped rather than reversed.** Three call sites prove the engine's
own Lua accepts it; they do not prove the mod sandbox does, and no one has tested that.
If you need varargs, `{...}` is universally safe and costs nothing — prefer it. By
contrast `table.move()` genuinely has **0 hits** and should be avoided.

*(Style note: bare `unpack` is used 566 times vs `table.unpack` 3 times. Match the
base game and use `unpack`.)*

### 5. "`Slider` widget — unreliable, never use"

Both `gui/elements/SliderElement.lua` and `gui/elements/OptionSliderElement.lua` exist
and are used by the base game. The useful version of this advice: **for a discrete
settings option use `MultiTextOptionElement`** (that is what the settings screens use);
`SliderElement` backs scrollbars. "Slider does not work" is too strong.

### 6. "`DialogElement` as a base class is wrong"

`DialogElement` is real and is the **parent of** `MessageDialog`:

```lua
-- gui/dialogs/MessageDialog.lua:2
local MessageDialog_mt = Class(MessageDialog, DialogElement)
```

Corpus-wide, 16 classes extend `MessageDialog` and 10 extend `DialogElement` directly.
Accurate guidance: **extend `MessageDialog`** for a message/confirm-style dialog — you
inherit the open/close lifecycle and callback plumbing. Extend `DialogElement` only if
you genuinely want to build that yourself.

---

## ✅ Confirmed — v1 was right

| Claim | Evidence |
|-------|----------|
| `g_gui:showYesNoDialog()` does not exist | **0 hits** across 1,842 files. |
| `YesNoDialog.show()` is the correct call | `gui/dialogs/YesNoDialog.lua:8`. Full signature below. |
| Do not use `os.time()` / `os.date()` | **0 references to any `os.*`** in the entire corpus. |
| Use `g_currentMission.time` | `BaseMission.lua:71` `self.time = 0`; `:770` `self.time = self.time + dt`. |
| Use `g_currentMission.environment.currentDay` | `environment/Environment.lua:127`. |
| `table.move()` unavailable | 0 hits. |
| No `goto` / `::label::` in mod code | Stands — on a real compiler error (`Incomplete statement: expected assignment or a function call`), **not** on the corpus. The corpus's 180 `goto`s are decompiler artifacts (`goto l19`, `::l12::`) and must not be used to overturn this rule. |
| `g_server` may be `nil` — always guard | `BaseMission.lua:116`; 754 refs, guarded throughout. |
| `local X_mt = Class(X, Base)` is the class pattern | `shared/class.lua` returns the metatable. |
| All 9 listed globals exist | See `GLOBALS.md` for refs + definition sites. |

### Exact signature now available

```lua
YesNoDialog.show(callback, target, text, title, yesText, noText,
                 dialogType, yesSound, noSound, callbackArgs, disableOpenSound)
```
— `gui/dialogs/YesNoDialog.lua:8`

### `Class()` — what it actually gives you

`shared/class.lua` (50 lines) returns the **metatable** and installs on every class:

| Member | Behaviour |
|--------|-----------|
| `members:class()` | returns the class table |
| `members:superClass()` | returns the base class (`nil` if none) |
| `members:isa(other)` | walks the chain — real `instanceof` |
| `members.new(init)` | default ctor, only if you did not define one |
| `members.copy(obj, ...)` | shallow copy, only if you did not define one |

`Class(X)` with a `nil` base prints an error and a callstack — so a typo'd base class
is loud, not silent.

---

## New in v2 — things v1 never covered

- **The mod sandbox** (`mods.lua` ~428–520): per-mod `_G` table, `__index = _G`
  fallthrough, auto-namespacing of `InitEventClass` / `InitObjectClass` /
  `registerObjectClassName` / `addSpecialization`, and the mod-scoped `g_i18n`.
  Full writeup in `GLOBALS.md`. This explains a whole class of "why is my event
  class name wrong in multiplayer" bugs.
- **119 `MessageType` constants** with verified payloads — v1 listed 6.
- **1,413 classes** indexed with base class and path (`CLASS-INDEX.md`).
- **`MessageType.SETTING_CHANGED` is a table**, indexed by setting name.
- **`internalMods/FS25_precisionFarming/`** — a complete Giants-authored shipping mod
  in the corpus, usable as a reference implementation.
