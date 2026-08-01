# FS25 Decompiled Source — Directory Map

**Root:** `$FS25_DECODED/dataS/scripts_decompiled/` — defaults to
`D:\FS25_Decoded\dataS\scripts_decompiled\`.
**Corpus:** 1,842 Lua files, ~411,000 lines — the full `dataS/scripts` tree.

> This map describes a local decompiled copy. If you do not have one, the directory
> layout below still tells you how the engine is organised, and the vendored
> `references/lua-source-index/` mirrors part of the same tree.

This is the ground truth for every FS25 API question. Find the right directory here,
then `grep` it. See `GREP-RECIPES.md` for query patterns.

---

## Where to look, by domain

| Directory | Files | What lives here |
|-----------|------:|-----------------|
| `vehicles/` | 375 | **Largest area.** Vehicle types and every specialization (`vehicles/specializations/`). Start here for anything drivable or attachable. |
| `gui/` | 253 | Screens, dialogs (`gui/dialogs/`), reusable widgets (`gui/elements/`), HUD (`gui/hud/`). |
| `ai/` | 121 | AI workers, job types, pathfinding, NPCs (`ai/npcs/`), AI error messages (`ai/errors/`). |
| `placeables/` | 118 | Placeable types and their specializations (`placeables/specializations/`). Buildings, silos, productions. |
| `animals/` | 89 | Husbandry system, animal types, food/clusters. `animals/husbandry/`. |
| `internalMods/` | 83 | **`FS25_precisionFarming` — a complete, shipping, Giants-authored mod.** The single best worked example of real mod structure. |
| `objects/` | 75 | World objects: `Bale`, `BunkerSilo`, `Storage`, pallets, sell stations, animated objects. |
| `guidedTour/` | 54 | Tutorial / guided-tour system. |
| `field/` | 52 | Field definition, field state, ground manipulation, `FieldManager`. |
| `events/` | 43 | **Base-game network event classes.** ~322 `Event` subclasses exist corpus-wide; this folder holds the general ones. Best place to copy MP event patterns from. |
| `environment/` | 39 | Weather, seasons, day/night, `Environment.lua` (time and period logic). |
| `debug/` | 38 | Debug drawing and console command helpers. |
| `missions/` | 38 | Contracts/missions, `missions/field/` for field missions. |
| `player/` | 38 | Player controller, states, movement. |
| `effects/` | 24 | Particle / visual effects. |
| `handTools/` | 24 | Chainsaw, hand tools. |
| `triggers/` | 22 | Trigger volumes and callbacks. |
| `utils/` | 22 | `MathUtil`, `ObjectChangeUtil`, `FSDensityMapUtil`, `ClassUtil`, string/table helpers. |
| `shop/` | 19 | Store items, `StoreManager`, shop screens. |
| `testing/` | 20 | Giants' own unit/game test harness. |
| `collections/` | 15 | Data structures: `Queue`, `RingBuffer`, `ObjectPool`, `StateMachine`, `DataGrid`. |
| `construction/` | 14 | Construction/build mode brushes. |
| `network/` | 13 | `Event.lua` (event base class), `Connection`, `NetworkUtil`, `Object.lua`. **Read `network/Event.lua` before writing any MP code.** |
| `farms/` | 13 | `Farm.lua`, `FarmManager`, farm properties and permissions. |
| `economy/` | 11 | `FarmlandManager`, finances, loans, price logic. |
| `sounds/`, `animation/`, `densityMaps/`, `input/` | ~10 ea | Audio samples, animation clips, density map ops, input handling. |
| `misc/` | 29 | `AbstractManager` (base of 49 managers), `MessageCenter` helpers, `Color`, `BaleManager`, autosave. |
| `shared/` | 6 | **`class.lua` — the `Class()` implementation itself.** Also `Enum`, `scenegraph`, `graph`. |
| `specialization/` | 4 | `SpecializationManager`, `SpecializationUtil`, `TypeManager`. The machinery behind vehicle/placeable specs. |
| `xml/` | 4 | `XMLFile`, `XMLManager`, `XMLValueType` — the modern XML API. |
| `async/` | 2 | `AsyncTaskManager`. |
| `placement/` | 5 | Placement grid, pallet spawning, `PlacementUtil`. |
| `fillTypes/`, `fruits/`, `growth/` | 2 ea | `FillTypeManager`, `FruitTypeManager`, growth system. |
| *(root, 48 files)* | 48 | `main.lua`, `mods.lua`, `game.lua`, `menu.lua`, `BaseMission.lua`, `FSBaseMission.lua`, `mission00.lua`, `MessageCenter.lua`, `Logging.lua`. |

---

## The root files that matter most

| File | Why you care |
|------|--------------|
| `mods.lua` | **The mod loader and sandbox.** Defines `modEnv`, the per-mod global table, the auto-namespacing of `InitEventClass`/`InitObjectClass`, and mod validation rules. See `GLOBALS.md`. |
| `main.lua` | Boot sequence. Defines `g_minModDescVersion` / `g_maxModDescVersion` (line 29–30) and instantiates most `g_*` managers. |
| `BaseMission.lua` | `g_server`, `g_client`, `g_localPlayer` assignment; `self.time` accumulation. |
| `FSBaseMission.lua` | Farming-specific mission layer. |
| `mission00.lua` | The actual gameplay mission class used by savegames. |
| `MessageCenter.lua` | `MessageType` table and pub/sub implementation. |
| `shared/class.lua` | `Class()` — read it once, it is only 50 lines and explains `:superClass()`, `:isa()`, `.new()`. |

---

## Companion data (not Lua)

`D:\FS25_Decoded\dataS\` also holds the **XML data** the scripts read. See
`../game-data/XML-DATA-FILES.md`. Highlights:

- `guiProfiles.xml` — every GUI profile name you can reference from your own XML
- `placeableTypes.xml` / `placeableSpecializations.xml` — valid placeable types & specs
- `inputActions.xml` — every built-in input action name
- `l10n/` — base-game translation keys (reuse these instead of inventing your own)
- `maps.xml`, `fillTypes`, `brands.xml`, `missionVehicles.xml`

`D:\FS25_Decoded\dataS2\npc\` holds NPC definitions.
