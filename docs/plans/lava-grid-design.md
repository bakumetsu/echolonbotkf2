# Local "floor is lava" grid: edge cases, loopholes, performance

Status: design draft for the user's review (2026-10-22). Part of the navigation step (point 2), after the start-of-match link scan.
KF2 scale: 50 uu = 1 m. Tile = 0.75 m (about 38 uu). Patch = about 25 x 25 m around each squad leader (human leader included).

## Edge cases and how each is handled
| # | Case | Handling |
|---|---|---|
| E1 | Doors (open, closed, welded) | Tiles on a door are "door tiles", not lava. Re-check them when that door changes state. A welded door counts as lava for the grid. |
| E2 | Zeds and teammates standing on tiles | Ignored by the fill (they move). Crowds are handled by squadmates steering around each other. |
| E3 | Invisible player blockers (blocking volumes, zed-only gaps) | The body-fit check uses the pawn's own collision trace, which hits volumes that block players, so those tiles become lava. |
| E4 | Holes, kill or pain volumes, water | No floor within step height, or a pain/kill volume at the tile, means lava (but see E14 for safe drops). Steep slopes (floor steeper than the walkable limit) mean lava. |
| E5 | Stairs | Neighbor test samples the floor every ~0.4 m; each rise must be at most the pawn's step height. Normal stairs pass. Very steep stairs that fail fall back to path nodes. |
| E6 | Low ceilings, crouch-only gaps | Body-fit check at standing height. Bots don't crouch-walk, so these are lava. |
| E7 | Stacked floors, bridges over corridors | Each tile stores its floor height and a layer. The fill follows the current floor (traces start from the current tile's height), so it never jumps to the floor above or below. |
| E8 | Next path node outside the patch | Steer to the safe tile at the patch edge closest to that node. |
| E9 | Path node sits on a lava tile (node too close to a wall) | Snap the target to the nearest safe tile. |
| E10 | Follower more than ~12 m from its leader's patch | Use today's steering (lookahead + wall feelers) until it is back inside. |
| E11 | Teleport, respawn, leader change | Reset that squad's patch. |
| E12 | Moving platforms or elevators | Lava for the grid; path nodes and today's steering handle them. |
| E13 | Map props a trace can't see (bad collision) | The existing stuck ladder still runs; a tile where a bot got stuck is marked lava for 60 s. |

| E14 | Safe drops from a higher floor | A ledge tile gets a one-way "drop link" to the floor below when: the fall is short enough to take no fall damage (limit computed from `KFPawn` fall settings and world gravity in the SDK, not guessed); the landing tile is safe floor with room for the body and no kill/pain volume; the landing connects to the lower floor's tiles. Drop links are one-way: never planned in reverse. A bot only takes one when its next path node or leader is below. Outside retreat, skip a drop whose landing has 3+ zeds within 3 m. |
| E15 | Map path links that already are drops | The start-of-match scan classifies drop links (end node clearly lower, no floor between) as one-way "ok if safe fall" instead of failing them. Check that today's walk-only planning (`FollowFindWalkablePath` special-edge exclusion) doesn't throw away safe drop links; if it does, allow them when the fall is safe. |

## Loopholes (ways it could make things worse) and guards
| # | Risk | Guard |
|---|---|---|
| L1 | Too strict: a narrow door scores low, so the bot refuses it | Wall distance is a preference, never a ban. Any safe tile at least body-width wide is allowed. |
| L2 | "Stay in the middle" walks a bot into zeds or across a squadmate's line of fire | The grid only shapes walking. Combat positioning and retreat (C2) keep their own rules and only use the grid to avoid walls. |
| L3 | Grid and path nodes disagree | Trust the grid for the next few metres; if a node link crosses lava, strike that link (N1 memory). |
| L4 | Bot flips between two equally good paths | Keep the chosen tile path for at least 0.5 s unless it becomes blocked. |
| L5 | Patch is still filling when the bot needs it | Use today's steering until the tiles toward the next node are filled. |
| L7 | A bot drops down and can't get back up to its squad | Only drop toward a goal below. If the leader is above, never drop. |
| L6 | A trace bug marks a big area lava | If over 80% of the patch is lava, ignore the grid for that squad and log `NAV_GRID_SUSPECT`. |

## Performance (revised 2026-10-22 after the user's 0.1 ms target)
Unit costs are estimates, to be measured: a collision trace about 5 to 20 us (body-sized traces at the high end); a `FindPathToward` route search about 50 to 500 us; plain script logic a few us per bot per update. The current build is estimated at about 7 traces per frame (6 bots, lookahead + feelers every 0.1 s), about 0.05 to 0.15 ms per frame.
- **Targets (proposed to the user):** whole nav system, all bots together, average at most 0.1 ms per frame and worst frame at most 0.5 ms (one route search).
- **Step 0, measure first:** time the current nav code with `Clock`/`UnClock`; log `NAV_COST avg_us= max_us= traces=` every 30 s.
- **One shared nav budget per frame:** steering probes first, grid filling gets the rest (about 4 traces per frame), at most 1 route search per frame across all bots (others wait a frame).
- **Grid shape:** a forward corridor about 10 m ahead and 5 m wide in the walking direction, not a 25 x 25 m square. Scanned tiles are kept at fixed world positions and reused. A fresh area fills in about 1 to 2 s; today's steering is used until it is ready.
- **Drop checks:** one extra downward trace on ledge tiles only, inside the same budget.
- **Local route on tiles:** capped at 150 tiles, at most every 0.5 s per bot, one bot per frame.
- **Memory:** negligible. **Script limits:** far below the runaway-loop limit.
- **Safety valve:** config switch for the grid; per-frame trace budget is a config value.
- **Pass bar for the spike:** inside the targets above; fewer `NAV_STUCK` at level 2 or higher than the current build on BurningParis and Dystopia2029.

## Rollout
1. **Spike first.** One squad only, behind a config switch, with a debug view that draws the tiles in spectator mode, so the user can see what the bot "sees". 2 matches.
2. **Measure it against the pass bar.**
3. **Then** turn it on for all squads.

## Behaviour by space type (agreed in discussion 2026-10-22)
- **Open space:** the grid sleeps whenever the straight line from the bot to its next path node passes the lookahead walk test. No grid cost there.
- **Tight corridor:** the body-fit check uses the human cylinder (confirm the radius in the SDK), so only centre tiles are safe and the bot walks the centre line. Followers queue in single file.
- **Several floors, small and big obstacles:** path nodes pick the stairs, the tile step test climbs them. Obstacles under step height count as floor, taller ones as lava. If a big obstacle blocks the whole forward strip, widen the scan to 10 x 10 m for that spot (inside the budget), then the stuck ladder, then teleport. After any stuck, re-scan nearby tiles (props that moved when bumped).
