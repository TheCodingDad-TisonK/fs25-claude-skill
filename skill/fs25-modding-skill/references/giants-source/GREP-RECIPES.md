# Query Recipes — Answering FS25 API Questions From Source

```bash
SRC="${FS25_DECODED:-D:/FS25_Decoded}/dataS/scripts_decompiled"
```

> **No local corpus?** These recipes still work against the vendored
> `references/lua-source-index/` (~270 Giants files) — just label results doc-grade,
> and expect gaps. Facts already extracted into `references/giants-source/` are
> committed and need no local copy.

The whole point of v2: **you no longer guess or WebFetch — you look it up.** These are
the queries that answer the questions that actually come up. Prefer the `Grep` tool
(it takes the same regex) over shelling out.

---

## 1. "What is the exact signature of `X:someMethod()`?"

```bash
grep -rn "function ClassName[:.]methodName" $SRC
```
Then read the body. Never report a signature you have not seen on screen.

For every method a class exposes:
```bash
grep -n "^function ClassName" $SRC/path/to/ClassName.lua
```

## 2. "Where does class `X` live, and what does it extend?"

Check `CLASS-INDEX.md` first (1,413 classes, class → base → path). If it is not there:
```bash
grep -rn "_mt *= *Class(X" $SRC
```

To walk the inheritance chain upward, look up each base in `CLASS-INDEX.md` in turn.

## 3. "Does this function/global exist at all?"

```bash
grep -rn "\bfunctionName\b" $SRC | head
```
**Zero hits across 411k lines is strong evidence it does not exist.** That is how the
non-existence of `g_gui:showYesNoDialog` was established. State the count when you
report a negative result.

## 4. "What does this MessageType carry?"

```bash
grep -rn "publish(MessageType.THE_TYPE" $SRC
```
The publish site shows the exact payload. `MESSAGE-TYPES.md` has all 119 plus the
common payloads pre-extracted.

## 5. "How does the base game actually do <thing>?"

Find a real caller and read it. This beats any tutorial:
```bash
grep -rn "someApiCall" $SRC | head -20
```
Then open the two or three most relevant hits. Base-game usage is the spec.

## 6. "What are the valid values for this XML attribute / enum?"

```bash
grep -rn "EnumName\." $SRC | grep -oE "EnumName\.[A-Z_]+" | sort -u
```
For XML schema definitions, search the registration call:
```bash
grep -rn "register.*XMLPaths\|schema:register" $SRC/path/to/Relevant.lua
```

## 7. "Which specializations exist for vehicles / placeables?"

```bash
ls $SRC/vehicles/specializations/     # 100s
ls $SRC/placeables/specializations/
```

## 8. "How do I write a multiplayer event?"

Read the base class, then copy a small real one:
```bash
cat $SRC/network/Event.lua
ls $SRC/events/                       # 43 general-purpose examples
```
322 `Event` subclasses exist corpus-wide — find one closest to your use case:
```bash
grep -rn "_mt = Class(.*, Event)" $SRC | head -30
```

## 9. "Is this a real GUI profile / element?"

```bash
ls $SRC/gui/elements/                       # every widget class
grep -n 'name="profileName"' D:/FS25_Decoded/dataS/guiProfiles.xml
```

## 10. "What changed vs FS22?" / "Does this old API still exist?"

Run recipe 3 on the FS22 name. If it returns zero hits, it is gone — then search for
the likely replacement by concept, e.g. the FS22 `g_currentMission.player` is now
`g_localPlayer` (545 refs).

---

## Reporting standard

When you answer from this corpus, say so and cite the path and line:

> `YesNoDialog.show(callback, target, text, title, yesText, noText, dialogType,
> yesSound, noSound, callbackArgs, disableOpenSound)` —
> `gui/dialogs/YesNoDialog.lua:8`

That is **raw-source-grade** evidence, which outranks doc-grade. Only fall back to
LUADOC / FS25-lua-scripting / AI-reference when the corpus genuinely has no answer —
and say which one you used. Read `DECOMPILED-CAVEATS.md` before trusting variable
names or control flow.
