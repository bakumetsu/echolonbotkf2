# EcholonBot (KF2)

A ground-up rewrite of the KF2Bots single-player bot mod for Killing Floor 2 (UE3 UnrealScript), package `EcholonBot`.

## Layout

```
Classes/              the mod's UnrealScript source (9 classes)
docs/ARCHITECTURE.md  class chain, milestone plan, every class's symbols, single-writer rules
```

The code is written with a local agent kit that stays on the developer's PC and is not part of this repo (`kit/` is gitignored).

## Building

The build follows the Steam guide [KF2 SDK: compiling a mod](https://steamcommunity.com/sharedfiles/filedetails/?id=1112644122):

1. Clone this repo to `Documents\My Games\KillingFloor2\KFGame\Src\EcholonBot`.
2. In `Documents\My Games\KillingFloor2\KFGame\Config\KFEditor.ini`, add `ModPackages=EcholonBot` under `[ModPackages]`.
3. Run `KFEditor.exe make -useunpublished` from `killingfloor2\Binaries\Win64`.

The compiled package lands in `KFGame\Unpublished\BrewedPC\Script\EcholonBot.u`, and settings go in `KFEcholonBot.ini`.

## Status

The skeleton and Milestone 1 (mutator boot, spawning, perks, utilities) come next. Milestones M2 to M6 fill in navigation, the bot base, squad orders, combat systems and the bot states.
