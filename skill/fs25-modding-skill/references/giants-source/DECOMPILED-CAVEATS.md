# What This Source Is — And What Not To Trust In It

The corpus at `D:\FS25_Decoded\dataS\scripts_decompiled` is **decompiled bytecode, not
Giants' original source files.** It is dramatically better than any documentation, but
it has known distortions. Read this before you report anything as a defect or infer a
language rule.

---

## Trustworthy

| Trustworthy | Why |
|---|---|
| **Function and method names** | Preserved in the bytecode as constants. |
| **Signatures / parameter counts** | Preserved. Parameter *names* usually survive too. |
| **String literals** | Exact — error messages, XML paths, i18n keys, console command names. |
| **Field names on tables** (`self.foo`) | Exact, they are string constants. |
| **Class and inheritance structure** | `Class(X, Base)` calls are real. |
| **Numeric constants and enum values** | Exact. |
| **Call graph — who calls what** | Reliable. |

## Not trustworthy

| Not trustworthy | What you see instead |
|---|---|
| **Local variable names** | Frequently wrong or duplicated. Two distinct locals can both render as `placeables` inside one function. This looks like a bug and is not one. |
| **`goto` / `::label::`** | 180 occurrences with auto-numbered labels (`goto l19`, `::l12::`). These are the decompiler's rendering of loops, `break`, and early exits — **not** hand-written source, and **not** proof you may use `goto` in a mod. |
| **Unused/placeholder parameters** | Render as `_`. The real name is lost. |
| **Control-flow shape** | `if/else` may be inverted or flattened relative to the original; semantics are preserved but the structure may read oddly. |
| **Comments** | All gone. Lines like `-- upvalues: (ref) modName` are decompiler annotations, not Giants comments. |
| **Local function names** | May be recycled — the same generated name can appear for unrelated locals in one file (e.g. `userProfilePath` used for two different closures in `mods.lua`). |

---

## A worked example of the variable-name artifact

`gui/base/GuiUtils.lua` around line 96 decompiles to:

```lua
local screenSizeValue = 1        -- shadows the value parsed a few lines above
local scalingValue = 1
if isPixelSize then
    screenSizeValue = isXValue and g_referenceScreenWidth or g_referenceScreenHeight
    scalingValue = isXValue and g_aspectScaleX or g_aspectScaleY
end
return screenSizeValue / screenSizeValue * scalingValue   -- reads as "x / x" = 1
```

Taken literally the function always returns `scalingValue`, which would be an obvious
engine bug. It is not. Two distinct locals both rendered as `screenSizeValue`; the
original divides the *parsed input value* by the reference dimension. The behaviour is
correct — the names are not.

**This is what you must not report as a defect.** The surrounding logic (px vs dp vs
normalized, and the 1920×1080 reference) is still completely reliable.

## Two rules that follow from this

**1. Never report a defect in base-game code on the strength of a decompiled variable
name.** If the logic looks wrong only because two variables share a name, it is an
artifact. Defects in the user's *own* mods are unaffected — that source is real.

**2. Never infer a language feature from decompiled syntax.** The corpus contains
`goto`, `table.pack`, `table.unpack`, and bare `unpack` — that mix reflects the
decompiler's output target, not a coherent statement about what the FS25 Lua runtime
accepts from mod code. To decide what you may *write*, look at what real mods do
(`internalMods/FS25_precisionFarming/` is Giants' own shipping mod) rather than at
decompiled base-game control flow.

---

## Empirically true about the runtime (measured, not inferred)

- **The `os` library is never touched.** Zero references to `os.time`, `os.date`,
  `os.clock` — or any `os.*` — across all 1,842 files. Use `g_currentMission.time`
  (accumulated in `BaseMission.lua:770`) and
  `g_currentMission.environment.currentDay`.
- **`table.move` is never used** (0 hits).
- **Bare `unpack` dominates** (566 hits) over `table.unpack` (3 hits). Prefer `unpack`
  to match base-game style.
- **`math.pow` is used** (58 hits) and is therefore available.

---

## Precedence

1. **This corpus** — raw-source-grade. Check it first, always.
2. FS25-Community-LUADOC — doc-grade; has no page at all for several load-bearing
   classes.
3. FS25-lua-scripting — a 267-file subset of the same scripts.
4. AI-reference — curated prose.

Only after searching this corpus may you say an API "cannot be verified." State the
grade of your evidence when it matters.
