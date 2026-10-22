# Bot combat, retreat, headless and look fixes: plan

Status: approved by the user 2026-10-22. Order: N6 to N10 first (verify, docs, push), then C1 to C4, then C2 rule 7. Written 2026-10-22 against `playtest` @ f3c358d.
Findings behind it: `plans/bot-movement-combat-findings.md`. Navigation (point 2) is section N below; the grid's full design is `plans/lava-grid-design.md`.
KF2 scale: 50 uu = 1 m.

## Order
| Step | What | Commit scope |
|---|---|---|
| C1 | Combat loop and point-blank shooting | `combat` |
| C2 | Retreat that shoots, plus heavy-zed (Fleshpound/Scrake) rules | `combat` |
| C3 | Keep 2 m from headless zeds | `combat` |
| C4 | Look direction (a to f) | `bot` |
| N6 | Measure today's nav cost | `nav` |
| N7 | Shared nav budget per frame | `nav` |
| N8 | Start-of-match link scan, zed route rules | `nav` |
| N9 | Speed ramps, squadmate separation, off-screen teleport | `nav` |
| N10 | Lava grid: one-squad test, then all squads | `nav` |
| C2.7 | Emergency drop during retreat (needs N10) | `combat` |

Each step: compile clean, 2 matches max (KF-BurningParis, then KF-Dystopia2029), read logs with `log_reader.py`, docs, commit, push to `playtest`.

## C1. Combat loop and point-blank shooting
1. **Stay in `FightEnemy` between moves.** `FightEnemy.FinishedMove` must not call `PickCombatStyle()` (hub) every time. Instead re-run `PickStyle()` inside the state. Ask the hub (`PickCombatStyle()`) only when (a) the enemy is gone or headless, or (b) at least 0.5 s have passed since the last hub check (higher priorities like self-heal and retreat still get a turn).
   - Do it without latent code or `Sleep` in `FinishedMove` (the 0.3 s hold that crashed was in `FinishedMove`; before coding, find that crash's stack in the log if it is still there and note the cause).
   - Use a timer (`SetTimer(..., 'CombatRepick')`), never re-entrant calls from inside `BeginState`.
2. **Zero-length move guard.** In `MoveToX`: if the 2D distance to `Dest` is under 50 uu, do not start the move; log `COMBAT_ZERO_MOVE src=<caller tag>` and let the state hold and shoot. In `MoveTowardX`: same when `Pawn.ReachedDestination(Dest)` is already true. Fix the known sources too: `VRand()` with Z zeroed and normalised for random moves; `Normal2D` of a zero vector (zed straight above/below) in `CloseToEffectiveRange` and the grunt strafe.
3. **Point-blank shooting.** In `FireWeaponAt`, bash (`BOTFM_BASH`) only when the target is within 75 uu (1.5 m) and at most once per 1.5 s (reuse `NextBashTime`); otherwise shoot with primary fire, also at close range. Keep melee weapons as they are.
4. **Target switching.** Do not reset the aim delay (`AimReadyTime`) when switching to a target that is within 15 deg of the current aim.
5. **Log:** `COMBAT_REPICK reason=` (throttled), `COMBAT_ZERO_MOVE src=`, `COMBAT_BASH dist=`.
6. **Pass:** no bot has more than 5 `FightEnemy` entries in any one second; log_reader shows `P7_CombatEngagement` steps under 0.5 s dropped well below today (up to 484 of 658).

## C2. Retreat that shoots
Applies to `TacticalRetreat` (leaders through hub P4) and followers on `CMD_TacticalRetreat`.
1. **Shoot while backing off.** Add a 0.2 s fire timer in `TacticalRetreat`: pick the target (rule 3), `Focus` on it, `FireWeaponAt`. Walk backwards (no sprint) unless rule 6 says sprint.
2. **Pick the escape direction, not just "away".** Sample 8 directions around the bot, 300 to 500 uu out. Score each: fewer zeds in a 45 deg cone, walkable floor (trace), not a dead end (the target nav point has at least 2 reach specs out), not into a corner. Take the best; `MoveToX` there with `Focus` on the target.
3. **Target order while retreating:** the zed blocking the chosen gap first, then the nearest attacker. Never a headless zed. Never a calm Fleshpound during the calm sprint (rule 6).
4. **Fully surrounded (every direction scores blocked):** don't move. Shoot the zed in the weakest direction; bash only within 1.5 m; send a squad call so squadmates target that zed.
5. **Limits:** retreat at most 15 m (750 uu) from where it started or from its leader. Stay at least 1.5 s once in retreat; 2 s cooldown before re-entering. Followers take their leader's escape direction, offset sideways by their slot. A Clot grab escape wins over retreat. Reload only if the nearest zed is over 4 m away.
6. **Heavy zeds.**
   - **Fleshpound** (verified in `KFAIPluginRage_Fleshpound.uc`): rage ends when it lands a hit, then a new timer of 9 + rand(1..5) s starts (10 to 14 s calm), unless it takes about 276 damage, which re-enrages it early. Watch `IsEnraged()` per Fleshpound within 25 m. On rage on to off: if the escape path is clear, sprint to about 15 m from it, holding fire on it, then turn and shoot. If the path is not clear, walk back shooting other zeds, still not shooting it. If it re-enrages, the window is over: treat it as raging (sprint away if the path is clear, otherwise rule 4).
   - **Scrake:** check in the SDK (`KFPawn_ZedScrake` and its AI) whether rage ever ends. If not (expected: health-based), no calm window: when raging and within 10 m, keep distance and sprint if the path is clear.
   - With several heavies, sprint only if every raging one nearby is calm or far.
7. **Emergency drop (needs the lava grid's drop links).** A drop that causes fall damage becomes an escape option in rule 2's scoring only during retreat, and only when all of these hold:
   - the fall damage, computed from the game's fall formula in the SDK, is under 40% of current health and leaves at least 25 HP;
   - the bot is about to be trapped (rule 4 would trigger), or the zeds behind are worth more damage than the fall;
   - fewer than 2 zeds are within 3 m of the landing spot;
   - the landing is a scanned safe tile.
   **How:** walk backwards shooting to the ledge, then step off backwards so it lands facing the zeds. Sprint and drop only if rule 6 says sprint (raging heavy, path clear). After landing, move 4 to 6 m away from the landing spot (zeds may follow down), turn and shoot the drop spot. Send a squad call; followers drop only if their leader dropped. Log `RETREAT_DROP fall_dmg= hp= zeds_behind=`.
8. **Log:** `RETREAT_START dir= score= zeds=`, `RETREAT_SHOT target=`, `RETREAT_SURROUNDED`, `RETREAT_FP_CALM fp= window=`, `RETREAT_END reason=`.
9. **Pass:** `RETREAT_SHOT` lines appear in both matches; no retreat lasts more than 15 m; no bot re-enters retreat more than once per 2 s.

## C3. Keep 2 m from headless zeds
1. Every 0.25 s (throttled in `Tick`), find headless zeds within 150 uu (3 m) that are closing in (velocity toward the bot, or within 100 uu).
2. Step away to keep at least 100 uu (2 m), using the escape scoring from C2 rule 2, while the current state keeps shooting its target. Do this as a movement override that does not change state and does not go through the hub (no new loop).
3. Never target a headless zed. If fully surrounded, skip the step and keep fighting.
4. **Log:** `HEADLESS_AVOID dist=`. **Pass:** no bot takes damage from a headless zed in the logged matches, or each such hit has a `HEADLESS_AVOID` just before it.

## C4. Look direction
One owner of the view: a `UpdateLook()` called from `Tick`, outside combat only (in combat the enemy wins as today).
- **a. Facing while walking.** Look at a point about 150 uu (3 m) ahead along the route (`FollowSteerPoint` in the follow mover, `DestinationPosition` otherwise), smoothed so it does not snap at each node.
- **b. Idle looking.** Replace every random `VRand()` look (Roaming `Begin`, hub idle-near-leader branches, DoObjective) with a slow, level sweep of +-20 deg around a base direction (leader facing, or where zeds were last seen), about 5 s per sweep. Pitch 0.
- **c. Noise glances.** `HearNoise` glances only at zed noises; ignore teammates.
- **d. Zigzag walk.** Serpentine off outside combat (`bSerpent = false` by default in non-combat callers); keep it in `FightEnemy`.
- **e. Hold-area watch.** `UpdateSectorWatch`: about 4 s per direction; no faster panic sweep.
- **f. Turn speed.** Cap view turn rate outside combat (about 180 deg/s) so changes look smooth when spectating.
- **Log:** none per frame; one `LOOK_MODE mode=` on change, throttled.
- **Pass:** the user's spectate check (first-person view no longer flips every 1 to 2 s), plus no new script warnings.

## N. Navigation (user answers 2026-10-22)
User rules for this section:
- Optimise as far as possible **without** making the code hard to read: one new class per system (`EcholonNavBudget`, `EcholonNavGrid`), short functions, a header comment per class saying what it does and its cost.
- Minimal or no crash risk. The engine's latent mover experiment (`MoveToward` with `AdjustFromWall`) is **dropped** from this plan because of the W2 crash risk.
- Teleport only when the bot is off-screen for every human (rule N9.3).
- No clipping between squadmates.
- Cost targets, all bots together: average at most 0.1 ms per frame, worst frame at most 0.5 ms.

### N6. Measure today's nav cost
Wrap the nav code (follow mover update, `NavProgressCheck`, lookahead and feeler traces, route searches) with `Clock`/`UnClock`. Log `NAV_COST avg_us= max_us= traces= searches=` every 30 s. 1 match on each test map. This is the baseline every later step is compared to.

### N7. Shared nav budget per frame
`EcholonNavBudget` (one per game, on the mutator): each frame it hands out a trace budget (config, start at 8) and at most 1 route search. Priority: steering probes, then stuck recovery, then the start-of-match scan, then grid filling. A bot that didn't get a route search this frame keeps its old route and asks again next frame. Pass: N6 numbers within the targets.

### N8. Start-of-match link scan and zed route rules
1. Over the first seconds of the match, within the N7 budget, check every path link: body-sized trace along it, floor checks every 2 m. Mark failing links bad for the whole match (same `BlockedBy`-during-search method as N1). Links that drop down are "one-way, OK if the fall does no damage" (fall limit from the SDK's `KFPawn` fall settings and gravity). Check that today's walk-only planning doesn't throw away safe drop links.
2. Use the route rules zeds use where they apply to path nodes: read `AddBasePathConstraints` and the `Path_*` classes in the SDK, and add the ones that work for path-node searches (for example avoiding choke points) to our `FindPathToward` calls.
3. Log `NAV_SCAN links= bad= drops= ms=`. Pass: scan done within 5 s of match start, inside the budget.

### N9. Speed ramps, separation, off-screen teleport
1. **Speed ramps:** ease speed up from a stop and down when approaching a sharp corner node (angle over 60 deg), instead of full speed instantly.
2. **Separation (no clipping):** squadmates within 80 uu add a push apart; in a corridor too narrow to pass, the one further from the goal waits (existing Yield). Never turn off collision.
3. **Off-screen teleport:** after 5 s stuck (ladder level 4), teleport to the last good node or the nearest valid floor node (`KFPathnode.GetNearestValidFloorNavWithinRadiusToPawn`), but only if, for every human player, the bot is outside their view cone **and** not in line of sight **and** not their spectate view target, and the destination is off-screen too. Otherwise keep trying every 1 s. Check how today's level-5 "not seen" test works and fix it if it misses spectators.
4. Pass: `NAV_STUCK` level 2+ lower than the N6 baseline; no teleport logged while a human could see the bot or the spot.

### N10. Lava grid
Design and edge cases: `plans/lava-grid-design.md` (forward strip 10 x 5 m, 0.75 m tiles, sleeps in open space, step test for stairs, drop links, budget from N7).
1. **One-squad test:** config `NavGridSquads=1` turns the grid on for squad 1 only; other squads keep today's steering, so both run in the same match on the same map. A debug config draws the tiles (green safe, red lava, yellow drop links) around squad 1 when spectating. 2 matches. Compare squad 1 against the others: `NAV_STUCK` level 2+, longest idle, and the cost from N6.
2. If squad 1 does better and the cost is within the targets, turn it on for all squads (`NavGridSquads=0` means all). If not, report to the orchestrator before changing anything.
