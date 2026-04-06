# FS25 Lua Source Index

**Source:** [FS25-lua-scripting](https://github.com/Dukefarming/FS25-lua-scripting) by @Dukefarming  
**Coverage:** 267 Lua files — extracted from Giants' dataS folder  
**Status:** Archived April 2025 — definitive Giants implementation reference

> Use this when you need to understand *how Giants implements* something internally.
> This is not the API docs — it's the actual game source code.

---

## Top-Level Files (Core Systems)
| File | What it contains |
|------|-----------------|
| `Vehicle.lua` | Base vehicle class — all vehicle loading, syncing, specialization dispatch |
| `VehicleMotor.lua` | Engine, gear, RPM, fuel system |
| `VehicleCamera.lua` | First/third person camera system |
| `VehicleActionController.lua` | Player action binding to vehicles |
| `VehicleSystem.lua` | Vehicle registry and management |
| `VehicleCharacter.lua` | Player character on vehicles |
| `AnimCurve.lua` | Animation curve interpolation |
| `AnimationValueBool.lua` / `AnimationValueFloat.lua` | Animated property values |
| `DashboardValueType.lua` | Dashboard gauge types |
| `WheelsUtil.lua` | Wheel/tire calculations |
| `WorkAreaTypeManager.lua` | Field work area registry |
| `LicensePlate.lua` / `LicensePlateManager.lua` | License plate system |

## Subdirectory Index

### `ai/` — AI Driver System
- AISystem, AIJob, AITask, AITaskRoute, AIPlanner
- Use when building mods that interact with AI field workers

### `animals/` — Animal Husbandry
- AnimalSystem, AnimalHusbandryObject, AnimalFood, AnimalCleaning
- Use when modding animal pens, feeding, productivity

### `animation/` — Animation System
- AnimationManager, conditional animations, clip system

### `base/` — GUI Base Classes ⭐ Very Useful
- `GuiMixin.lua` — Mixin for GUI elements
- `TabbedMenu.lua` / `TabbedMenuWithDetails.lua` — Multi-tab menu base
- `GuiUtils.lua` — Utility functions for GUI
- `Overlay.lua` / `GuiOverlay.lua` / `ThreePartOverlay.lua` — Overlay types
- `StatusBar.lua` / `RoundStatusBar.lua` — Progress bar elements
- `Tween.lua` / `TweenSequence.lua` — Animation tweening
- `NavigationMarker.lua` — Map markers
- `SettingsModel.lua` — Settings data model

### `collections/` — Data Structures
- Queue, Set, and other data structures

### `configurations/` — Vehicle Configuration System
- `ConfigurationManager.lua` — Config registry
- `ConfigurationUtil.lua` — Config helpers
- Use when creating vehicle configs (wheel types, engine variants, etc.)

### `dataS/` — Giants dataS reference files
- Raw data definitions from the game's dataS directory

### `debug/` — Debug Tools
- Debug drawing, logging utilities

### `densityMaps/` — Terrain Density Maps
- Soil, stone, field state density map operations

### `dialogs/` — Built-in Dialog Implementations ⭐ Very Useful
- Source for all built-in dialogs (InGameMenu, ShopConfig, etc.)
- Study these to understand dialog structure

### `economy/` — Economy System
- EconomyManager, LeaseVehicleManager, production economics

### `elements/` — GUI Element Implementations ⭐ Very Useful
- Source implementations of ButtonElement, TextElement, ListElement, etc.
- Study when debugging GUI issues

### `environment/` — World/Environment
- Time, weather, seasons, lighting

### `events/` — Network Event Classes
- All built-in NetworkEvent subclasses
- Pattern reference for custom multiplayer events

### `fence/` — Fence System
- Fence, FenceGate, FenceSegment and their network events

### `field/` — Field System
- Field, FieldManager, field ownership, weed/stone systems

### `fillTypes/` — Fill Type System
- FillTypeManager, FillType definitions
- Use when adding custom fill types

### `forestry/` — Forestry
- Chainsaw, tree cutting, wood chipper systems

### `fruits/` — Crop/Fruit System
- FruitTypeManager, FruitTypeDesc
- Use when adding custom crops

### `graphics/` — Graphics Utilities
- Shader parameters, material systems

---

## Most Referenced Files for Mod Development

1. **`Vehicle.lua`** — understand `onLoad`, `onPostLoad`, `onUpdate`, `readStream`/`writeStream` lifecycle
2. **`base/TabbedMenu.lua`** — base for complex GUI screens
3. **`elements/`** — understand element APIs from source
4. **`events/`** — model custom events after built-in ones
5. **`economy/EconomyManager.lua`** — shop pricing, sell values
6. **`dialogs/`** — real-world dialog examples
7. **`configurations/ConfigurationUtil.lua`** — vehicle config helpers
