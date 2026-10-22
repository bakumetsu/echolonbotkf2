# EcholonBot (KF2)

A ground-up rewrite of the KF2Bots single-player bot mod for Killing Floor 2 (UE3 UnrealScript), package `EcholonBot`.

## Layout

```
Classes/              the mod's UnrealScript source (9 classes)
avatars/              bot avatar server and the KF2-Avatars launcher source (see avatars/README.md)
docs/ARCHITECTURE.md  class chain, milestone plan, every class's symbols, single-writer rules
```

The code is written with a local agent kit that stays on the developer's PC and is not part of this repo (`kit/` is gitignored).

## Building

The build follows the Steam guide [KF2 SDK: compiling a mod](https://steamcommunity.com/sharedfiles/filedetails/?id=1112644122):

1. Clone this repo to `Documents\My Games\KillingFloor2\KFGame\Src\EcholonBot`.
2. In `Documents\My Games\KillingFloor2\KFGame\Config\KFEditor.ini`, add `ModPackages=EcholonBot` under `[ModPackages]`.
3. Run `KFEditor.exe make -useunpublished` from `killingfloor2\Binaries\Win64`.

The compiled package lands in `KFGame\Unpublished\BrewedPC\Script\EcholonBot.u`, and settings go in `KFEcholonBot.ini`.

## Playtest mode

Add `?Playtest=1` to the map URL and the human becomes a spectator who watches the bots. Options: `PlaytestWaves` (wave cap) and `PlaytestBots` (bot count). The game logs `PLAYTEST_` lines and quits when the run is done. Details are in `docs/ARCHITECTURE.md` (EcholonMut and EcholonSpectatorPC).

With the local kit, run `python kit\tools\playtest_runner.py --map KF-BioticsLab --waves 2 --matches 2 --bots 6`.

## Docs before every push

Every push that changes `Classes/` also updates the docs (`docs/ARCHITECTURE.md` or this README). If a change needs no doc update, add a line `Docs: none (<reason>)` to the last commit message.

Two checks enforce it:

- **Pre-push hook:** turn it on once per clone with `git config core.hooksPath .githooks`. It refuses such a push; `git push --no-verify` skips it once.
- **GitHub check:** `.github/workflows/docs-check.yml` runs the same script, `.githooks/check-docs.sh`, on pull requests into `playtest` and `main`.

## Status

The skeleton and Milestone 1 (mutator boot, spawning, perks, utilities) come next. Milestones M2 to M6 fill in navigation, the bot base, squad orders, combat systems and the bot states.
