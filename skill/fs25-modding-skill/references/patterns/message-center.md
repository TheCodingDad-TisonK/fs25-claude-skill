# Message Center Integration

**Subscribe to game events for periodic or event-driven operations**

Based on patterns from: EnhancedLoanSystem, BuyUsedEquipment, SeasonalPrices

---

## Related API Documentation

> 📖 For complete function signatures, see the [FS25 Community LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC)

| Class | API Reference | Description |
|-------|---------------|-------------|
| MessageCenter | [Instances/](https://github.com/umbraprior/FS25-Community-LUADOC/tree/main/docs/script/Instances) | `subscribe()`, `publish()`, `unsubscribe()` |
| Environment | [Environment.md](https://github.com/umbraprior/FS25-Community-LUADOC/blob/main/docs/script/Misc/Environment.md) | Time/weather state |

**Note:** MessageType constants are defined in the game but not separately documented. Common types: `HOUR_CHANGED`, `DAY_CHANGED`, `PERIOD_CHANGED`, `YEAR_CHANGED`, `MONEY_CHANGED`, `MINUTE_CHANGED`

---

## Overview

The Message Center provides pub/sub functionality for game events:
- Time-based events (hour, day, period, year)
- Economy events (money changed)
- Game state events (settings, properties)

---

## Basic Subscription

```lua
function MyMod:loadMap()
    -- Subscribe to various game events
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
    g_messageCenter:subscribe(MessageType.YEAR_CHANGED, self.onYearChanged, self)
    g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
end

function MyMod:onHourChanged()
    -- Called every in-game hour
    self:processHourlyTasks()
end

function MyMod:onPeriodChanged()
    -- Called when season changes
    self:updateSeasonalPrices()
end

function MyMod:onYearChanged()
    -- Called on new year
    self:generateAnnualReport()
end
```

---

## Server-Only Event Processing

```lua
-- From FarmExtension
function FarmExtension.new(isServer, superFunc, isClient, spectator, customMt, ...)
    local farm = superFunc(isServer, isClient, spectator, customMt, ...)

    farm.buyUsedVehicles = {}

    -- Subscribe only on server
    if g_server ~= nil then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, FarmExtension.onHourChanged, farm)
    end

    return farm
end
```

---

## Available MessageTypes

```lua
-- Time events                   (callback args in parentheses)
MessageType.MINUTE_CHANGED       -- (currentMinute)
MessageType.HOUR_CHANGED         -- (currentHour)
MessageType.DAY_CHANGED          -- (currentDay)
MessageType.PERIOD_CHANGED       -- (currentPeriod, currentVisualPeriod) — a PERIOD IS A MONTH
MessageType.SEASON_CHANGED       -- (currentSeason) — this is the season change
MessageType.YEAR_CHANGED         -- (currentYear)

-- Economy events
MessageType.MONEY_CHANGED        -- (farmId, money)
MessageType.FARM_PROPERTY_CHANGED -- Farm property purchased/sold

-- Game events
MessageType.SETTING_CHANGED      -- a TABLE, indexed by setting name (see below)
```

> ⚠️ **`PERIOD_CHANGED` is not the season change.** They are separate messages,
> published on adjacent lines of `environment/Environment.lua` (~414 / ~417). Earlier
> versions of this doc conflated them.

> ⚠️ **`SETTING_CHANGED` is a table, not a constant.** The game publishes
> `MessageType.SETTING_CHANGED[name]`, so subscribe with
> `MessageType.SETTING_CHANGED[GameSettings.SETTING.XXX]`.

**There are 119 MessageType constants in total** — see
`references/giants-source/MESSAGE-TYPES.md` for the complete list with verified
payloads.

---

## Conditional Processing

### Server Check

```lua
-- From SeasonalPrices
function SeasonalPrices:onHourChanged()
    if g_currentMission:getIsServer() then
        -- Update all loading stations
        for _, loadingStation in pairs(g_currentMission.storageSystem.loadingStations) do
            self:updateStationPrices(loadingStation)
        end
    end
end
```

### GUI Availability Check

```lua
-- Only process when GUI is available
function FarmExtension:onHourChanged()
    if not self.isServer then
        return
    end

    -- Only process if game allows GUI (not in menu, etc.)
    if g_currentMission:getAllowsGuiDisplay() then
        self:processQueue()
    end
end
```

---

## Unsubscribe Pattern

Always unsubscribe when cleaning up:

```lua
function MyMod:delete()
    -- Unsubscribe from events
    g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.PERIOD_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.YEAR_CHANGED, self)

    -- Cleanup
    self.data = nil
end
```

---

## Manager Pattern with Message Center

Complete integration example:

```lua
MyManager = {}
local MyManager_mt = Class(MyManager)

function MyManager.new()
    local self = setmetatable({}, MyManager_mt)
    self.data = {}
    return self
end

function MyManager:loadMap()
    -- Subscribe to hourly updates
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)

    -- Subscribe to money changes for financial tracking
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChanged, self)
end

function MyManager:onHourChanged()
    if g_server ~= nil then
        self:processHourlyUpdate()
    end
end

function MyManager:onMoneyChanged(farmId, amount, changeType)
    -- Track financial changes
    if self.data[farmId] == nil then
        self.data[farmId] = {}
    end
    table.insert(self.data[farmId], {amount = amount, type = changeType})
end

function MyManager:delete()
    g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
    g_messageCenter:unsubscribe(MessageType.MONEY_CHANGED, self)
    self.data = nil
end
```

---

## Common Pitfalls

### 1. Forgetting to Unsubscribe
Memory leaks occur if you don't unsubscribe in delete().

### 2. Processing on Client
Most hourly/daily logic should only run on server.

### 3. Heavy Processing
Don't do heavy work every minute - prefer HOUR_CHANGED.

### 4. Missing Self Parameter
Third parameter to subscribe() must be self for proper callback binding.
