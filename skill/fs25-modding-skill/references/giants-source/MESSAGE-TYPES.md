# MessageType Reference — All 119 Constants

Extracted from the decompiled corpus. The v1 skill listed 6 of these; there are **119**.

`MessageType` is defined in `MessageCenter.lua` (repo root of the decompiled tree).

## MessageCenter API (exact signatures)

```lua
g_messageCenter:subscribe(messageType, callback, callbackTarget, argument, isOneShot)
g_messageCenter:subscribeOneshot(messageType, callback, callbackTarget, argument)
g_messageCenter:unsubscribe(messageType, callbackTarget, callback)
g_messageCenter:unsubscribeAll(callbackTarget)          -- call this in your delete()
g_messageCenter:publish(messageType, ...)
g_messageCenter:publishDelayed(messageType, ...)
g_messageCenter:publishDelayedAfterFrames(messageType, numFrames, ...)
```

`subscribe` warns and bails on a nil `messageType` or nil `callback`, and asserts that
`callback` is a function. **`unsubscribeAll(self)` on teardown** is the standard leak fix.

## Payloads for the common ones (verified at the publish site)

| MessageType | Callback receives |
|-------------|-------------------|
| `MINUTE_CHANGED` | `currentMinute` |
| `HOUR_CHANGED` | `currentHour` |
| `DAY_CHANGED` | `currentDay` |
| `PERIOD_CHANGED` | `currentPeriod, currentVisualPeriod` |
| `SEASON_CHANGED` | `currentSeason` |
| `YEAR_CHANGED` | `currentYear` |
| `MONEY_CHANGED` | `farmId, money` |
| `WEATHER_CHANGED` | `weatherObject` |
| `FARMLAND_OWNER_CHANGED` | `farmlandId, farmId, loadFromSavegame` |
| `PLACEABLE_ADDED` / `PLACEABLE_REMOVED` | `placeable` |
| `VEHICLE_ADDED` / `VEHICLE_REMOVED` | *(no arguments)* |
| `SAVEGAME_LOADED` | *(no arguments)* |
| `PLAYER_FARM_CHANGED` | `player` |
| `HUSBANDRY_ANIMALS_CHANGED` | `husbandry` (the publisher itself) |
| `FINISHED_GROWTH_PERIOD` | `finishedPeriod, hasPendingGrowth` |

> **`PERIOD_CHANGED` is not the season change.** They are separate messages published
> on adjacent lines of `environment/Environment.lua` (~414 and ~417). A period is a
> month; use `SEASON_CHANGED` for seasons. The v1 skill got this wrong.

> **`SETTING_CHANGED` is a table, not a constant.** It is indexed by setting name:
> `g_messageCenter:publish(MessageType.SETTING_CHANGED[name], value)`. Subscribe with
> `MessageType.SETTING_CHANGED[GameSettings.SETTING.XXX]`.

## Complete list

- `MessageType.ACHIEVEMENT_UNLOCKED`
- `MessageType.AI_JOB_REMOVED`
- `MessageType.AI_JOB_STARTED`
- `MessageType.AI_JOB_STOPPED`
- `MessageType.AI_SYSTEM_LOADED`
- `MessageType.AI_TASK_SKIPPED`
- `MessageType.AI_VEHICLE_STATE_CHANGE`
- `MessageType.APP_RESUMED`
- `MessageType.APP_SUSPENDED`
- `MessageType.APP_WINDOW_FOCUS_CHANGED`
- `MessageType.BLOCK_LIST_CHANGED`
- `MessageType.CURRENT_MISSION_LOADED`
- `MessageType.CURRENT_MISSION_START`
- `MessageType.DAY_CHANGED`
- `MessageType.DAY_NIGHT_CHANGED`
- `MessageType.DAYLIGHT_CHANGED`
- `MessageType.DEBUG_MODE_CHANGED`
- `MessageType.ENQUEUED_ALL_LOADINGS`
- `MessageType.ERROR`
- `MessageType.FARM_CREATED`
- `MessageType.FARM_DELETED`
- `MessageType.FARM_PROPERTY_CHANGED`
- `MessageType.FARM_SETTINGS_CHANGED`
- `MessageType.FARMLAND_OWNER_CHANGED`
- `MessageType.FINISHED_GROWTH_PERIOD`
- `MessageType.GAME_STATE_CHANGED`
- `MessageType.GUI_AFTER_CLOSE`
- `MessageType.GUI_AFTER_OPEN`
- `MessageType.GUI_BEFORE_CLOSE`
- `MessageType.GUI_BEFORE_OPEN`
- `MessageType.GUI_DIALOG_OPENED`
- `MessageType.GUI_INGAME_OPEN`
- `MessageType.GUI_INGAME_OPEN_AI_SCREEN`
- `MessageType.GUI_INGAME_OPEN_FARMS_SCREEN`
- `MessageType.GUI_INGAME_OPEN_FINANCES_SCREEN`
- `MessageType.GUI_INGAME_OPEN_HELP_SCREEN`
- `MessageType.GUI_INGAME_OPEN_PRODUCTION_SCREEN`
- `MessageType.GUI_MAIN_SCREEN_OPEN`
- `MessageType.GUIDED_TOUR_CHANGED`
- `MessageType.GUIDED_TOUR_DIALOG`
- `MessageType.GUIDED_TOUR_FINISHED`
- `MessageType.GUIDED_TOUR_STARTED`
- `MessageType.HANDTOOL_ADDED`
- `MessageType.HANDTOOL_LOADED`
- `MessageType.HANDTOOL_REMOVED`
- `MessageType.HOUR_CHANGED`
- `MessageType.HUSBANDRY_ANIMALS_CHANGED`
- `MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE`
- `MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE`
- `MessageType.INFO`
- `MessageType.INPUT_BINDINGS_CHANGED`
- `MessageType.INPUT_DEVICES_CHANGED`
- `MessageType.INPUT_HELP_MODE_CHANGED`
- `MessageType.INPUT_MODE_CHANGED`
- `MessageType.INSETS_CHANGED`
- `MessageType.LOADED_ALL_SAVEGAME_HANDTOOLS`
- `MessageType.LOADED_ALL_SAVEGAME_PLACEABLES`
- `MessageType.LOADED_ALL_SAVEGAME_VEHICLES`
- `MessageType.LOADING_STATIONS_CHANGED`
- `MessageType.MASTERUSER_ADDED`
- `MessageType.MINUTE_CHANGED`
- `MessageType.MISSION_DELETED`
- `MessageType.MISSION_GENERATED`
- `MessageType.MISSION_GENERATION_END`
- `MessageType.MISSION_GENERATION_START`
- `MessageType.MISSION_STATUS_CHANGED`
- `MessageType.MONEY_CHANGED`
- `MessageType.OK`
- `MessageType.ON_CLIENT_START_MISSION`
- `MessageType.OWN_PLAYER_ENTERED`
- `MessageType.OWN_PLAYER_LEFT`
- `MessageType.PAUSE`
- `MessageType.PEDESTRIAN_SYSTEM_LOADED`
- `MessageType.PERIOD_CHANGED`
- `MessageType.PERIOD_LENGTH_CHANGED`
- `MessageType.PLACEABLE_ADDED`
- `MessageType.PLACEABLE_REMOVED`
- `MessageType.PLAYER_CREATED`
- `MessageType.PLAYER_FARM_CHANGED`
- `MessageType.PLAYER_NICKNAME_CHANGED`
- `MessageType.PLAYER_PRE_TELEPORT`
- `MessageType.PLAYER_STYLE_CHANGED`
- `MessageType.PRECISION_FARMING_TRAMLINES_CHANGED`
- `MessageType.RADIO_CHANNEL_CHANGE`
- `MessageType.REALHOUR_CHANGED`
- `MessageType.SAVEGAME_LOADED`
- `MessageType.SAVEGAMES_LOADED`
- `MessageType.SEASON_CHANGED`
- `MessageType.SETTING_CHANGED`
- `MessageType.SLEEPING`
- `MessageType.SLOT_USAGE_CHANGED`
- `MessageType.SNOW_HEIGHT_CHANGED`
- `MessageType.SPLIT_SHAPE`
- `MessageType.START_GROWTH_PERIOD`
- `MessageType.STORAGE_ADDED_TO_LOADING_STATION`
- `MessageType.STORAGE_ADDED_TO_UNLOADING_STATION`
- `MessageType.STORAGE_REMOVED_FROM_LOADING_STATION`
- `MessageType.STORAGE_REMOVED_FROM_UNLOADING_STATION`
- `MessageType.STORE_ITEMS_RELOADED`
- `MessageType.TIMESCALE_CHANGED`
- `MessageType.TRAFFIC_SYSTEM_LOADED`
- `MessageType.TREE_SHAPE_CUT`
- `MessageType.TREE_SHAPE_MOUNTED`
- `MessageType.UNLOADING_STATIONS_CHANGED`
- `MessageType.USER_ADDED`
- `MessageType.USER_PROFILE_CHANGED`
- `MessageType.USER_REMOVED`
- `MessageType.VEHICLE_ADDED`
- `MessageType.VEHICLE_LOADED`
- `MessageType.VEHICLE_PLAYER_ENTERED`
- `MessageType.VEHICLE_PLAYER_LEFT`
- `MessageType.VEHICLE_REMOVED`
- `MessageType.VEHICLE_REPAINTED`
- `MessageType.VEHICLE_REPAIRED`
- `MessageType.VEHICLE_RESET`
- `MessageType.VEHICLE_SALES_CHANGED`
- `MessageType.WEATHER_CHANGED`
- `MessageType.WINDOW_SIZE_CHANGED`
- `MessageType.YEAR_CHANGED`

## Verify / re-generate

```bash
grep -rhoE "MessageType\.[A-Z_0-9]+" --include="*.lua" \
  D:/FS25_Decoded/dataS/scripts_decompiled | sort -u

# find what a message carries:
grep -rn "publish(MessageType.YOUR_TYPE" D:/FS25_Decoded/dataS/scripts_decompiled
```
