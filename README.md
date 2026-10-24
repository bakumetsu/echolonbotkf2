# EcholonBot (KF2)

A ground-up rewrite of the KF2Bots single-player bot mod for Killing Floor 2 (UE3 UnrealScript), package `EcholonBot`.

## Layout

```
Classes/              the mod's UnrealScript source (20 classes)
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

Navigation settings in that file: `NavGridSquads` (default 0; 0 = the floor-is-lava grid may steer every squad, but only for a few seconds after a bot stalls; N = only squad N, -1 = off) and `bNavGridDebug` (default false; logs an ASCII map of the grid). At match start the bots scan every path link and block bad ones; nav cost is counted and shared per frame, and the logs show it as `NAV_COST`, `NAV_SCAN` and `NAV_GRID_*` lines. `bBotEmotes` (default false) lets bots answer emotes and do the victory dance.

Zone planner: at match start the mutator lists Dosh Hold zones and trader pods and rates each as usable or not, logged as `ZONE_*` lines. In normal waves the squads also hold a randomly picked usable zone (squad 1 core, squad 2 entry, others reserve). The zone is held for up to `ZoneHoldSecs` (90 s) after the first squad arrives, or abandoned after `ZoneArriveTimeout` (60 s) if nobody arrives; the hunt order defers until the hold has lasted `ZoneMinHoldSecs` (45 s) unless the squad is idle. After a `timer` or `no_arrive` end, a new zone is picked (if more than 15 zeds remain) or the hunt starts. The zone also ends if the wave ends, the trader opens, a boss appears, or a real Dosh Hold objective takes priority. Settings: `bZonePlanner` and the `Zone*` values in the same ini (a test run with it off needs `--ini ZoneConfigVer=2 --ini bZonePlanner=False`); see `docs/ARCHITECTURE.md`.

## Playtest mode

Add `?Playtest=1` to the map URL and the human becomes a spectator who watches the bots. Options: `PlaytestWaves` (wave cap) and `PlaytestBots` (bot count). `?SkipTrader=1` (only read with `?Playtest=1`) skips the rest of the trader time once every living bot has shopped. `?RemoteShop=1` makes the bots buy from where they stand when the trader opens (also works without `Playtest=1`; the ini key `bRemoteShop` does the same, and `?RemoteShop=0` forces it off). The game logs `PLAYTEST_` lines and quits when the run is done. Details are in `docs/ARCHITECTURE.md` (EcholonMut and EcholonSpectatorPC).

Spectator camera: left/right click is the previous/next bot, Space toggles free fly (WASD and mouse), middle click cycles third person, first person and orbit, and the mouse wheel zooms in third person and orbit. The camera only changes bot when the watched bot dies or on a click. `EcholonSpectatorPC` is now the player controller in every game, so a human who dies in normal play gets the same camera; a living player is unchanged. Known limitations are listed in `docs/ARCHITECTURE.md` under "Known limitations and open items".

With the local kit, run `python kit\tools\playtest_runner.py --map KF-BioticsLab --waves 2 --matches 2 --bots 6`. The runner adds `?SkipTrader=1` by default (`--no-skip-trader` turns it off); `--remote-shop` adds `?RemoteShop=1`.

## Map survey and bot trace

Add `?Survey=1` to the map URL and the match becomes a map survey: no zeds, a few survey bots (`?SurveyBots=N`, default 4) feel the map blind and record a tile grid, and the game ends after `?SurveyMinutes=N` minutes (default 60) or when nothing is left to explore. The grid is written to the log as `GRID_ROW` lines. The ini key `bNavTrace` (default off) logs the map's path nodes and links (`NAVDUMP_` lines) and each bot's position and route every 0.25 s (`TRACE_` lines). When the walking survey stalls, pass 2 tries the designer's links that it did not walk (jumps, drops, windows, narrow doorways) and logs each success as a link (`?SurveyPass2=0` turns it off, `mutate SurveyPass2` starts it now). With both off, none of this code runs. The viewer that draws the log lives in the local-only kit (`kit/tools/nav_viz.py`, see `kit/README.md`), not in GitHub. Details are in `docs/ARCHITECTURE.md` ("Survey mode, node dump and bot trace").

## Survey-based nav

`?SurveyNav=1` (or the ini key `bSurveyNav`, default off; `?SurveyNav=0` forces it off) makes the bots use a finished survey: bad links stay out of their routes and the survey grid saves traces. The data comes from `KFEcholonMapData.ini` (class `EcholonMapData`, one section per map), which the local kit writes from survey logs. Windows and shortcuts a survey bot walked are no longer refused as too narrow or forced, and a failed route search first lets trouble-spot links back in. Without data for the map nothing changes. Details are in `docs/ARCHITECTURE.md` ("Survey-based nav").

## Docs before every push

Every push that changes `Classes/` also updates the docs (`docs/ARCHITECTURE.md` or this README). If a change needs no doc update, add a line `Docs: none (<reason>)` to the last commit message.

Two checks enforce it:

- **Pre-push hook:** turn it on once per clone with `git config core.hooksPath .githooks`. It refuses such a push; `git push --no-verify` skips it once.
- **GitHub check:** `.github/workflows/docs-check.yml` runs the same script, `.githooks/check-docs.sh`, on pull requests into `playtest` and `main`.

## Status

The skeleton and Milestone 1 (mutator boot, spawning, perks, utilities) come next. Milestones M2 to M6 fill in navigation, the bot base, squad orders, combat systems and the bot states.
