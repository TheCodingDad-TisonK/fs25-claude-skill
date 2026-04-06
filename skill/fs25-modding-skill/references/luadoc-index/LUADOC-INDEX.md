# FS25 Community LUADOC — Complete Index

**Source:** [FS25-Community-LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC) by @umbraprior  
**Coverage:** 1,661 pages · 11,102+ script functions · Engine, Foundation, Script APIs

> Use this index to find the right LUADOC page, then read it from `docs/` in the LUADOC repo.
> When Claude is asked about a specific function or class, look it up here and reference the docs path.

---

## Script API Categories

### GUI (Most commonly needed)
| Class | Path | Key Functions |
|-------|------|---------------|
| Gui | `docs/script/GUI/Gui.md` | loadGui, showDialog, closeDialog, loadGuiRec |
| GuiElement | `docs/script/GUI/GuiElement.md` | setPosition, setSize, setVisible, setAlpha |
| ScreenElement | `docs/script/GUI/ScreenElement.md` | onOpen, onClose, onCreate, sendMenuAction |
| MessageDialog | `docs/script/GUI/MessageDialog.md` | **Base class for all custom dialogs** |
| DialogElement | `docs/script/GUI/DialogElement.md` | ⚠️ DO NOT USE as base — use MessageDialog |
| YesNoDialog | `docs/script/GUI/YesNoDialog.md` | YesNoDialog.show() (NOT g_gui:showYesNoDialog) |
| ButtonElement | `docs/script/GUI/ButtonElement.md` | onClick, setDisabled, setText |
| TextElement | `docs/script/GUI/TextElement.md` | setText, setTextColor, setFont |
| TextInputElement | `docs/script/GUI/TextInputElement.md` | getText, setMaxCharacters, onEnterPressed |
| MultiTextOptionElement | `docs/script/GUI/MultiTextOptionElement.md` | setTexts, setState, getState (use instead of Slider) |
| BoxLayoutElement | `docs/script/GUI/BoxLayoutElement.md` | setFlowDirection, invalidateLayout |
| ListElement | `docs/script/GUI/ListElement.md` | setDataSource, reloadData, getSelectedItem |
| BitmapElement | `docs/script/GUI/BitmapElement.md` | setImageFilename, setUVs |
| GuiProfile | `docs/script/GUI/GuiProfile.md` | Profile system, extends, traits |
| FocusManager | `docs/script/GUI/FocusManager.md` | Keyboard/controller navigation |
| ScrollingLayoutElement | `docs/script/GUI/ScrollingLayoutElement.md` | Scrollable containers |

### Vehicles
| Class | Path |
|-------|------|
| Vehicle | `docs/script/Vehicles/Vehicle.md` |
| VehicleMotor | `docs/script/Vehicles/VehicleMotor.md` |
| VehicleCamera | `docs/script/Vehicles/VehicleCamera.md` |
| VehicleSystem | `docs/script/Vehicles/VehicleSystem.md` |

### Specializations (150+)
- Path prefix: `docs/script/Specializations/`
- Key ones: `Attachable.md`, `Drivable.md`, `Fillable.md`, `Motorized.md`, `WorkArea.md`, `Foldable.md`, `Lights.md`, `Washable.md`

### Economy
| Class | Path |
|-------|------|
| EconomyManager | `docs/script/Economy/EconomyManager.md` |
| FarmManager | `docs/script/Economy/FarmManager.md` |
| Farm | `docs/script/Economy/Farm.md` |

### Events
- Path: `docs/script/Events/`
- Key: `NetworkEvent.md`, custom event patterns

### Utils
| Class | Path |
|-------|------|
| Utils | `docs/script/Utils/Utils.md` | appendedFunction, overwrittenFunction, prependedFunction |
| MathUtil | `docs/script/Utils/MathUtil.md` |
| StreamUtil | `docs/script/Utils/StreamUtil.md` |

### Placeables
- Path: `docs/script/Placeables/`
- Key: `Placeable.md`, `PlaceableProductionPoint.md`

### Animals
- Path: `docs/script/Animals/`
- Key: `AnimalHusbandryObject.md`, `AnimalSystem.md`

### Shop
- Path: `docs/script/Shop/`
- Key: `StoreManager.md`, `StoreItem.md`, `ShopConfigScreen.md`

### HUD
- Path: `docs/script/Hud/`
- Key: `GameInfoDisplay.md`, `HUDDisplayElement.md`, `InfoBox.md`, `VehicleHUDExtension.md`

### Triggers
- Path: `docs/script/Triggers/`
- Key: `TriggerMarker.md`, `AreaTrigger.md`

### Input
- Path: `docs/script/Input/`
- Key: `InputBinding.md`, `PlayerInputComponent.md`

### Missions / Contracts
- Path: `docs/script/Missions/`, `docs/script/Contracts/`

### AI
- Path: `docs/script/AI/`
- Key: `AIVehicleUtil.md`, `AISystem.md`

### Field / Fruits / FillTypes
- Paths: `docs/script/Field/`, `docs/script/Fruits/`, `docs/script/FillTypes/`

### Environment / Weather
- Path: `docs/script/Weather/`, `docs/script/Environment/`
- Key: `EnvironmentTime.md`, `WeatherObject.md`

---

## Engine API Categories

### Most Used Engine APIs
| Category | Path | Key Functions |
|----------|------|---------------|
| Node | `docs/engine/Node/` | createTransformGroup, setWorldPosition, getWorldPosition, link, delete |
| Entity | `docs/engine/Entity/` | getName, getObject, setUserAttribute |
| XML | `docs/engine/XML/` | loadXMLFile, getXMLString, getXMLInt, getXMLFloat, setXMLString |
| I3D | `docs/engine/I3D/` | loadI3DFile, releaseSharedI3DFile |
| Input | `docs/engine/Input/` | getInputButton, mouseEvent, keyEvent |
| Sound | `docs/engine/Sound/` | createSample, playSample, stopSample, deleteSample |
| Animation | `docs/engine/Animation/` | getAnimTrackTime, setAnimTrackTime, isAnimPlaying |
| Physics | `docs/engine/Physics/` | setRigidBodyType, setMass, addForce |
| Math | `docs/engine/Math/` | mathLerp, mathClamp, MathUtil functions |
| Overlays | `docs/engine/Overlays/` | createOverlay, setOverlayColor, renderOverlay |
| Rendering | `docs/engine/Rendering/` | setShaderParameter, getRenderTargetSize |
| Terrain | `docs/engine/Terrain/` | getTerrainHeightAtWorldPos, modifyTerrain |
| Foliage | `docs/engine/Foliage/` | getFoliageDensity, setFoliageDensity |
| Camera | `docs/engine/Camera/` | setCamera, getCamera, setCameraFov |
| Network | `docs/engine/Network/` | networkSendMessage, isServer, isClient |
| General | `docs/engine/General/` | getFrameIndex, getPerformanceClassId |
| String | `docs/engine/String/` | utf8Strlen, utf8Substr |
| Text Rendering | `docs/engine/Text Rendering/` | renderText, setTextColor, setTextBold |
| Debug | `docs/engine/Debug/` | drawDebugLine, print, printCallstack |
| Shape | `docs/engine/Shape/` | getMaterial, setMaterial, getShaderParameter |
| Spline | `docs/engine/Spline/` | getSplineLength, getSplinePosDir |
| Particle System | `docs/engine/Particle System/` | setEmittingState, setParticleSystemSpeed |

---

## Foundation API (Low-level)
- Path: `docs/foundation/`
- Core Lua extensions, table utilities, class system

---

## Quick Lookup Guide

**"How do I show a dialog?"** → `docs/script/GUI/Gui.md` (loadGui + showDialog)  
**"How do I read/write XML?"** → `docs/engine/XML/`  
**"How do I create a specialization?"** → `docs/script/Specializations/`  
**"How do I play a sound?"** → `docs/engine/Sound/`  
**"How do I use g_messageCenter?"** → `docs/script/Misc/` or `docs/script/Base/`  
**"How do I save data?"** → `docs/engine/XML/` + savegame patterns in patterns/save-load.md  
**"How do I add a vehicle HUD element?"** → `docs/script/Hud/VehicleHUDExtension.md`  
**"How do I network sync?"** → `docs/script/Events/NetworkEvent.md`  
