# FS25 Globals — Verified Against Decompiled Source

Every global below was confirmed present in the decompiled `dataS/scripts` corpus.
"Refs" is the raw occurrence count across all 1,842 files — a good proxy for how
central the global is. "Defined at" is the first Lua assignment site.

Root: `D:\FS25_Decoded\dataS\scripts_decompiled\`

---

## Tier 1 — You will use these constantly

| Global | Refs | Defined at | Notes |
|--------|------|-----------|-------|
| `g_currentMission` | 3894 | `menu.lua:13` | The session. Time, environment, farms, map, node ids. |
| `g_i18n` | 2798 | `main.lua:419` | Localization. **In a mod this is auto-replaced** — see sandbox note below. |
| `g_messageCenter` | 799 | `main.lua:241` | Pub/sub. Subscribe with `MessageType.*` (see `MESSAGE-TYPES.md`). |
| `g_server` | 754 | `BaseMission.lua:116` | **`nil` on a pure client.** Always nil-check before server-only logic. |
| `g_client` | 429 | `BaseMission.lua:120` | `nil` on a dedicated server. |
| `g_gui` | 733 | `main.lua:481` | GUI system: `loadGui`, `showGui`, `changeScreen`. |
| `g_inputBinding` | 1089 | `main.lua:474` | Action event registration / key bindings. |
| `g_soundManager` | 1130 | `game.lua:445` | Sample loading and playback. |

## Tier 2 — Domain managers

| Global | Refs | Defined at |
|--------|------|-----------|
| `g_settingsModel` | 702 | `main.lua:503` |
| `g_localPlayer` | 545 | `BaseMission.lua:272` |
| `g_gameSettings` | 410 | `main.lua:317` |
| `g_fillTypeManager` | 413 | `fillTypes/FillTypeManager.lua:509` |
| `g_time` | 303 | `main.lua:78` |
| `g_fruitTypeManager` | 298 | `fruits/FruitTypeManager.lua:1015` |
| `g_storeManager` | 206 | `shop/StoreManager.lua:1137` |
| `g_farmlandManager` | 202 | `economy/FarmlandManager.lua:512` |
| `g_farmManager` | 201 | `farms/FarmManager.lua:408` |
| `g_missionManager` | 191 | `missions/MissionManager.lua:790` |
| `g_asyncTaskManager` | 212 | `async/AsyncTaskManager.lua:129` |
| `g_xmlManager` | 128 | `xml/XMLManager.lua:175` |
| `g_savegameController` | 64 | `main.lua:499` |
| `g_fieldManager` | 70 | `field/FieldManager.lua:778` |
| `g_npcManager` | 79 | `ai/npcs/NPCManager.lua:373` |
| `g_dedicatedServer` | 96 | `main.lua:107` |
| `g_vehicleTypeManager` | 19 | `specialization/TypeManager.lua:292` |
| `g_specializationManager` | — | `specialization/SpecializationManager.lua:139` |

## Tier 3 — Mod-context globals

| Global | Defined at | Notes |
|--------|-----------|-------|
| `g_currentModDirectory` | `mods.lua:885` | Absolute path to *your* mod folder. Prefix asset paths with it. |
| `g_currentModName` | `mods.lua:886` | Your mod's folder name. Needed for i18n keys and event class names. |

> 392 distinct `g_*` globals are assigned somewhere in the corpus. To find any of
> them: `grep -rnE "^\s*g_yourGlobal *=" D:/FS25_Decoded/dataS/scripts_decompiled`

---

## The mod sandbox changes what these mean — read this

`mods.lua` builds a **per-mod environment table** before loading your scripts. This is
not folklore; it is lines ~428–520 of `mods.lua`. What it does:

```lua
local modEnv = {}
_G[modName] = modEnv
setmetatable(modEnv, { __index = _G })   -- reads fall through to _G
```

**Consequences that actually bite you:**

1. **Your globals are not global.** A bare `MyThing = {}` in your mod writes into
   `modEnv`, not `_G`. Other mods cannot see it, and it will not collide with the
   base game. This is why mods do not clobber each other.

2. **Reads still see everything.** Because of `__index = _G`, you can read
   `g_currentMission`, `Vehicle`, `Utils`, etc. normally.

3. **Your mod name must not already be a global.** `mods.lua` explicitly rejects the
   mod otherwise:
   ```
   if _G[modName] ~= nil then printError("Error: Invalid mod name '" .. modName .. "'")
   ```
   Do not name a mod `Vehicle`, `Utils`, `Player`, etc.

4. **`g_i18n` is swapped for a mod-scoped one:**
   ```lua
   modEnv.g_i18n = g_i18n:addModI18N(modName)
   ```
   So `g_i18n:getText("my_key")` resolves against *your* translation files.

5. **These four functions are silently rewritten to namespace by mod name:**

   | You call | Actually runs |
   |----------|---------------|
   | `InitEventClass(cls, "MyEvent")` | `InitEventClass(cls, modName .. ".MyEvent")` |
   | `InitObjectClass(cls, "MyObj")` | `InitObjectClass(cls, modName .. ".MyObj")` |
   | `registerObjectClassName(o, "X")` | `registerObjectClassName(o, modName .. ".X")` |
   | `g_specializationManager:addSpecialization(...)` | `customEnvironment` forced to `modName` |

   This is why you pass the **short** name in a mod and still get a unique global
   class name across mods. Do not pre-prefix it yourself — you would get
   `MyMod.MyMod.MyEvent`.

6. **`source()` is wrapped** to resolve relative to your mod directory, and
   `loadstring()` is wrapped to run the chunk inside your mod env.

7. **`g_constructionBrushTypeManager` is a wrapper table**, not the real manager.
   `addBrushType` injects your `customEnvironment`; `getClassObjectByTypeName` falls
   back to looking up `modName .. "." .. typeName`.

Verify any of this yourself:
```bash
sed -n '425,525p' D:/FS25_Decoded/dataS/scripts_decompiled/mods.lua
```
