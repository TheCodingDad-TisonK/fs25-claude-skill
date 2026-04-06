# FS25 Patterns Overview

This document gives a high-level overview of all patterns bundled in the skill.
For full details, read the individual files in `skill/fs25-modding-skill/references/`.

---

## Basics

### modDesc.xml Structure
Every FS25 mod needs a valid `modDesc.xml`. Key elements:
- `descVersion="83"` (FS25 current)
- `<extraSourceFiles>` for Lua files
- `<vehicleTypes>` for custom vehicles
- `<l10n>` for translations
- `<inputBinding>` for key bindings

→ Full doc: `references/basics/modDesc.md`

### Lua Patterns
FS25 uses **Luau** (Lua 5.1 compatible). Key patterns:
- `Class(MyClass, BaseClass)` — class inheritance
- `Utils.overwrittenFunction()` — replace Giants methods
- `Utils.appendedFunction()` — add to Giants methods after
- `Utils.prependedFunction()` — add to Giants methods before
- `Mod:init()` — optional mod initialization wrapper

→ Full doc: `references/basics/lua-patterns.md`

### Localization
- Translation files: `translations/translation_en.xml`
- Access via: `g_i18n:getText("key")`
- Dynamic: `g_i18n:formatText("key", value1, value2)`

→ Full doc: `references/basics/localization.md`

### Input Bindings
- Defined in `modDesc.xml` under `<inputBinding>`
- Accessed via `InputAction.MY_ACTION`
- Registered with `g_inputBinding:registerActionEventWithPriority()`

→ Full doc: `references/basics/input-bindings.md`

---

## Core Patterns

### GUI Dialogs ⭐
The most complex and pitfall-heavy area. Key rules:
1. Always use `MessageDialog` as base class (never `DialogElement`)
2. XML layout file required
3. `loadGui()` called in `loadMap()` or `onStartMission()`
4. `showDialog()` with callback pattern
5. `FocusManager` required for controller support

→ Full doc: `references/patterns/gui-dialogs.md`

### Network Events (Multiplayer) ⭐
For any value that must sync between players:
1. Create event class extending `Event`
2. Implement `readStream()` and `writeStream()`
3. Always check `g_server ~= nil` before server-only operations
4. Register with `addModEventListener()`

→ Full doc: `references/patterns/events.md`

### Save / Load ⭐
FS25 uses XML-based savegames:
- `saveToXMLFile(xmlFile, key)` — write your data
- `loadFromXMLFile(xmlFile, key)` — read your data
- Hook into `savegame` and `loadSavegame` events

→ Full doc: `references/patterns/save-load.md`

### Managers (Singleton State)
For global state accessible anywhere:
- Single global table pattern
- Initialize in `loadMap()` / `onStartMission()`
- Destroy in `deleteMap()` / `onEndMission()`

→ Full doc: `references/patterns/managers.md`

### Extensions (Hooking Giants Classes)
Three hook types via `Utils`:
- `Utils.overwrittenFunction(Class, "methodName", newFn)` — replace
- `Utils.appendedFunction(Class, "methodName", newFn)` — add after
- `Utils.prependedFunction(Class, "methodName", newFn)` — add before

→ Full doc: `references/patterns/extensions.md`

### Data Classes
OOP data containers with business logic:
- Extend `Object` or create standalone class
- Getters/setters pattern
- Use for: CreditAccount, DealRecord, VehicleCondition, etc.

→ Full doc: `references/patterns/data-classes.md`

### Financial Calculations
- Loan interest: compound or simple
- Depreciation: straight-line or declining balance  
- Use `math.floor()` for money (no floating point rounding)
- Never use `os.time()` for timestamps — use game day numbers

→ Full doc: `references/patterns/financial-calculations.md`

### Async Operations (Deferred Execution)
For operations that can't happen immediately:
- TTL queue pattern (Time-To-Live)
- TTS queue (Time-To-Send for network)
- Use `g_currentMission.time` for timing

→ Full doc: `references/patterns/async-operations.md`

### Message Center (Event Subscription)
Subscribe to game events:
```lua
g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
-- Always unsubscribe in delete/cleanup!
g_messageCenter:unsubscribeAll(self)
```

→ Full doc: `references/patterns/message-center.md`

### Physics Override
Modify vehicle/object physics properties:
- `setRigidBodyType(nodeId, type)` — change physics type
- `setMass(nodeId, mass)` — change mass
- Must be done at specific lifecycle points

→ Full doc: `references/patterns/physics-override.md`

### Shop UI Customization
Add buttons/elements to shop screens:
- Hook into `ShopConfigScreen` via extension
- Add custom `ButtonElement` nodes
- Use `onShopItemSelected` callback pattern

→ Full doc: `references/patterns/shop-ui.md`

### Placeable Purchase Hooks
Custom dialogs triggered on placeable purchase:
- Hook `PlacementUtil.buy()` or `Placeable:onBuy()`
- Show custom dialog before completing purchase
- Use callback to confirm/cancel purchase

→ Full doc: `references/patterns/placeable-purchase-hooks.md`

### Vehicle Info Box
Add custom info to the vehicle HUD info panel:
- Extend `VehicleHUDExtension`
- Register `InfoBox` entries
- Update values in `updateInfoBox()`

→ Full doc: `references/patterns/vehicle-info-box.md`

---

## Advanced Topics

### Vehicle Specializations
Full lifecycle: `prerequisitesPresent` → `registerFunctions` → `registerEventListeners` → `onLoad` → `onUpdate` → `onDelete` → `readStream`/`writeStream`

→ Full doc: `references/advanced/vehicles.md`

### Placeables
Production points, decoration objects, interactive placeables. Based on `Placeable` base class with production-specific extensions.

→ Full doc: `references/advanced/placeables.md`

### Trigger Zones
Collision triggers with enter/leave callbacks:
- `addTrigger(nodeId, callbackFn, self)`
- `removeTrigger(nodeId)`
- Timer patterns for delayed trigger actions

→ Full doc: `references/advanced/triggers.md`

### HUD Framework
Custom overlay HUD elements:
- Extend `HUDDisplayElement`
- Use `createOverlay()`, `setOverlayColor()`, `renderOverlay()`
- Coordinate system: bottom-left origin, normalized units

→ Full doc: `references/advanced/hud-framework.md`

### Animations
Multi-state animation control:
- `TweenSequence` for smooth value transitions
- `setAnimTrackTime()` for direct animation control
- Conditional animations via Giants' system

→ Full doc: `references/advanced/animations.md`

### Animal Husbandry Integration
Hook into animal productivity, feeding, cleaning systems:
- `AnimalHusbandryObject` extension points
- `AnimalSystem` for global animal state

→ Full doc: `references/advanced/animals.md`

### Production Chains
Multi-input, multi-output production:
- `PlaceableProductionPoint` as base
- Input fill type registration
- Output fill type configuration
- Production cycle timing

→ Full doc: `references/advanced/production-patterns.md`

### Vehicle Configurations
Custom equipment configs (wheel types, engine variants, etc.):
- `ConfigurationManager` registration
- `ConfigurationUtil` helpers
- Price modifier patterns

→ Full doc: `references/advanced/vehicle-configs.md`

---

## Pitfalls Reference

See `references/pitfalls/what-doesnt-work.md` for the complete list of 17+ documented pitfalls. The most critical ones:

1. **`os.time()` doesn't exist** — use `g_currentMission.time`
2. **`DialogElement` as base class crashes** — use `MessageDialog`
3. **`g_gui:showYesNoDialog()` doesn't exist** — use `YesNoDialog.show()`
4. **`Slider` widgets fire unreliable events** — use `MultiTextOptionElement`
5. **`goto` / `::labels::` are Lua 5.4** — not available in FS25
6. **Running server code on client** — always check `g_server ~= nil`
