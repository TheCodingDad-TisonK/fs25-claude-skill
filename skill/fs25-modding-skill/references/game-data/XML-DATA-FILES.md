# FS25 Game Data (XML) — What Ships In `dataS`

**Root:** `D:\FS25_Decoded\dataS\`

The decompiled Lua tells you *how* the game works; these XML files tell you *what
values are legal*. All are minified to a single line — use `grep -o`, not `head`.

| File | Size | Contains |
|------|-----:|----------|
| `l10n/l10n_en.xml` | 417 KB | **5,763 English translation keys.** 28 languages in `l10n/`. |
| `guiProfiles.xml` | 141 KB | **512 GUI profiles + 111 colour/style presets.** |
| `vehicleTypes.xml` | 33 KB | **152 vehicle types** and their specialization lists. |
| `inputActions.xml` | 30 KB | **254 input actions.** |
| `placeableTypes.xml` | 9 KB | **66 placeable types.** |
| `placeableSpecializations.xml` | — | **66 placeable specializations.** |
| `maps.xml`, `brands.xml`, `missionVehicles.xml`, `storeItems.xml`, `helpLine.xml`, `achievements.xml` | — | Map registry, brands, contract vehicles, store, help, achievements. |
| `gui/` (56 files) | — | Screen layouts: `InGameMenu.xml`, `ShopScreen.xml`, `gui/dialogs/`. |
| `../dataS2/npc/` | — | NPC definitions. |

> `dataS/scripts/` holds the original `.l64` compiled bytecode. `scripts_decompiled/`
> is the readable form of exactly those files.

---

## Reuse base-game translations instead of inventing keys

5,763 keys already exist. Before adding your own, check:

```bash
grep -o '<e k="[^"]*yourword[^"]*" v="[^"]*"' D:/FS25_Decoded/dataS/l10n/l10n_en.xml
```

Base-game keys work in your mod for free and come pre-translated into 28 languages.

## Check a GUI profile exists before referencing it

```bash
grep -o '<Profile name="yourProfile"[^>]*' D:/FS25_Decoded/dataS/guiProfiles.xml
# list all:
grep -o '<Profile name="[^"]*"' D:/FS25_Decoded/dataS/guiProfiles.xml | sed 's/.*name="//;s/"//' | sort
```

A typo'd profile name fails silently or renders wrong — this check is cheap.

## Confirm an input action name

```bash
grep -o 'name="[^"]*"' D:/FS25_Decoded/dataS/inputActions.xml | sed 's/name="//;s/"//' | sort -u
```

Register your own in `modDesc.xml` under `<actions>` / `<inputBinding>` only if the
action you need is not already here.

---

## Placeable types (66)

`baseHusbandry` `beehive` `beehivePalletSpawner` `boatyard` `bunkerSilo` `bush` `buyingStation` 
`buyingStationManure` `buyingStationWindTurbine` `chargingStation` `chickenHusbandry` 
`chickenHusbandryPasture` `constructible` `constructibleCollectableSpot` `constructibleFarmhouse` 
`cowHusbandry` `cowHusbandryBarn` `cowHusbandryBarnMilk` `cowHusbandryBarnMilkFeedingRobot` 
`cowHusbandryPasture` `cowHusbandryPastureStraw` `decoObject` `destructible` `doghouse` `factory` 
`farmhouse` `fence` `foliage` `garageSolarPanels` `garageWorkshop` `garageWorkshopSolarPanels` 
`greenhouse` `heapSpawner` `heapSpawnerBuyingStation` `horseHusbandry` `horseHusbandryPasture` 
`incomePerHourObject` `manureHeap` `multiBunkerSilo` `newFence` `objectStorage` `pigHusbandry` 
`pigHusbandryPasture` `placeable` `placeableVehicle` `productionPoint` `productionPointWardrobe` 
`riceField` `rollercoaster` `sellingStation` `sheepHusbandry` `silo` `siloExtension` 
`simplePlaceable` `solarPanel` `toolShed` `trainSystem` `tree` `vine` `wardrobe` `warehouse` 
`weatherStation` `weighingStation` `weighingStationSolarPanels` `windTurbine` `workshop` 

## Placeable specializations (66)

`ai` `animatedObjects` `beehive` `beehivePalletSpawner` `boatyard` `bunkerSilo` `buyingStation` 
`cartridgePlayer` `chargingStation` `clearAreas` `constructible` `deletedNodes` `destructible` 
`doghouse` `dynamicallyLoadedParts` `factory` `farmhouse` `fence` `foliageAreas` `greenhouse` 
`handToolHolders` `heapSpawner` `hotspots` `husbandry` `husbandryAnimals` `husbandryFeedingRobot` 
`husbandryFence` `husbandryFood` `husbandryLiquidManure` `husbandryMeadow` `husbandryMilk` 
`husbandryPallets` `husbandryStraw` `husbandryWater` `incomePerHour` `indoorAreas` `infoTrigger` 
`ladders` `leveling` `lights` `manureHeap` `multiBunkerSilo` `newFence` `npcSpot` `objectStorage` 
`palletBuyingStation` `placement` `productionPoint` `riceField` `rollercoaster` `sellingStation` 
`shallowWaterSimulation` `silo` `siloExtension` `solarPanels` `tipOcclusionAreas` `trainSystem` 
`triggerMarkers` `vehicle` `vehicleBuyingStation` `vine` `wardrobe` `weatherStation` 
`weighingStation` `windTurbine` `workshop` 

## Vehicle types (152)

Listed in `vehicleTypes.xml`; each `<type>` names the specializations it composes.
To see what a type is made of:

```bash
grep -o '<type name="tractor".*\?</type>' D:/FS25_Decoded/dataS/vehicleTypes.xml
```

The specialization implementations live in
`D:/FS25_Decoded/dataS/scripts_decompiled/vehicles/specializations/`.
