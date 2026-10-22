# Bot movement and combat: findings (2026-10-22)

Read against `playtest` @ f3c358d and the KF2 SDK (`Development/Src/KFGame/Classes`). KF2 scale: 50 uu = 1 m.

## 1. Look direction jumps left and right
No single owner of where a bot looks. Several systems write `Focus`/`FocalPoint`:
- **Follow mover never sets a look target** (`EcholonFollowNavBase.uc` `PathMove`, only `Pawn.Acceleration`). While following, the bot keeps whatever it last looked at, so it walks while facing sideways.
- **Random looks every 1 to 2 s**: `Roaming` `Begin` sets `SetFocalPoint(Pawn.Location + VRand()*1000)` then `Sleep(1.0 + FRand())` (`EcholonBot.uc:458`). Same in the hub's idle-near-leader branch 2 of 3 times (`EcholonBot.uc:331, 369`) and `DoObjective` (`:521`). `VRand()` also has a vertical part, so bots look at the floor or ceiling.
- **Noise glance**: `HearNoise` turns a grunt toward any non-hostile noise for 1.5 s (`EcholonBotBase.uc:4376`), so teammates' gunfire pulls heads around.
- **Sector watch** in `CMD_HoldArea`: a sine sweep of +-15 deg with a 4 s period (+-30 deg, 2 s in panic) (`UpdateSectorWatch`, `:4084`). That is exactly "2 s per direction".
- **Zigzag walk**: `MoveToX`/`MoveTowardX` default `bSerpent = true`; `StrafeTowardPoint` flips side every 0.3 s.

## 2. Wall bumping and corners; how zeds cope
Zeds are not better navigators. From `AICommand_MoveToGoal.uc` and `KFAIController.uc`:
- They use the engine's latent `MoveToward` with native `AdjustFromWall` (C++ wall sliding), "skip ahead" through route nodes, and KFAISteering separation.
- Failed nodes go in a `BlockedPathList` (temporary `bBlocked`, cleared after `MaxBlockedPathDuration`), plus `ForcePauseAndRepath` after many wall hits. Our N1 to N3 already do the same idea, more safely (`BlockedBy` only during our own search).
- **The real trick is cheating**: `EvaluateStuckPossibility` then `HandleStuck` teleports a stuck zed to the nearest valid floor path node within 512 uu (`StuckTeleportToPathNode`, using `KFPathnode.GetNearestValidFloorNavWithinRadiusToPawn`), or to a spawn volume, or kills it and puts it back in the spawn queue (`StuckSuicide`). Zeds nobody has seen for 5 s run at super speed and `RelocateTeleport` closer. Stuck checks are skipped near the enemy, after damage or melee.
- Zeds also shrink collision against other zeds when far from the enemy (`NavigationBumpTeamCollisionThreshholdSquared`), so crowds do not jam.

## 3. Combat "short-circuits" when surrounded
- **Every finished combat move goes back to the hub.** `FightEnemy.FinishedMove` calls `PickCombatStyle`, which does `GotoState('PickNextMove')`; the hub picks `FightEnemy` again. Any move that is already "arrived" when issued loops once per frame. Zero-length candidates: `MoveTowardX(Enemy)` while touching the zed (melee and `bGruntMeleeStyle`, `CloseToEffectiveRange` when `WalkReachable`), `MoveToX(Pawn.Location + VRand()*300)` when the random vector is mostly vertical, `Normal2D` of a zed straight above or below (`CloseToEffectiveRange`, grunt strafe). The earlier stack (`Tick -> ProcessMoveTo -> FinishedMove`) fits the `MoveToX` cases.
- **Bash instead of shoot inside 4 m.** `FireWeaponAt` uses `BOTFM_BASH` whenever the target is within 200 uu (`EcholonBotBase.uc:861`). Surrounded bots mostly bash (short reach, long animation, `IsFiring` blocks shooting meanwhile).
- **Aim delay resets on every target switch** (`AimReadyTime`, 0.08 to 0.25 s). With many zeds and frequent `PickNextEnemy`/`SyncLineFocus` switches, plus `NeedToTurn`, a bot can spend most of its time turning.

## 4. Tactical retreat does not shoot
`TacticalRetreat` (`EcholonBot.uc:848`) has no fire timer; it only calls `PickRetreatMove` (which already keeps `Focus = Enemy`). Hub P4 only lets **group leaders** enter it; followers get `CMD_TacticalRetreat` from `CheckObjectiveHazard`.

## 5. Headless zeds
Headless zeds are dropped everywhere (hub P7, `FightEnemy.Timer`, `AcquireHuntTarget`, `CountNearbyZeds`). Nothing keeps distance from them.
