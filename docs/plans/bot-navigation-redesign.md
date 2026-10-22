# Bot navigation redesign (wall-stuck, wall-jumping, pathing)

Status: design only, nothing implemented. Written 2026-10-21 against `playtest` @ `dd7a7ac`.
Scope: how every Echolon bot moves from A to B (follow, hunt, roam, objective, retreat, relocation at spawn).

---

## 1. What goes wrong today (root causes, with code)

| # | Cause | Where | Symptom in logs |
|---|---|---|---|
| R1 | **Two movers with two stuck systems.** Follow uses raw `Pawn.Acceleration` + watchdog in `EcholonFollowNavBase`. Every other state uses `MoveToX`/`MoveTowardX` + `Tick` in `EcholonBotBase`. They disagree on what "stuck" is and how to recover. | `EcholonFollowNavBase.uc:1194-1335`, `EcholonBotBase.uc:1161-1280` | Different stuck behaviour per state; fixes in one mover never reach the other. |
| R2 | **Jumping is the default unstick.** `Tick` calls `Pawn.DoJump` after 0.5 s of no movement, and `NotifyHitWall` jumps 1 time in 3. With the boosted JumpZ this is the "wall-jumping". | `EcholonBotBase.uc:1251-1256`, `NotifyHitWall` (~`:1625-1637`) | Bots hop against walls and corners. |
| R3 | **No memory of failed edges.** `FollowTryBlockNode` always returns false ("Plan B"). After a stuck, the bot re-runs A* from the same spot and gets the same route through the same bad node, up to `FollowRetriesGiveUpAt`, then `GiveUpStep` resets retries to 0 and the loop starts again. | `EcholonFollowNavBase.uc:893-939`, `:1325-1331` | Burning Paris: Bot_1 stuck 23x and Bot_5 18x at nodes 651/680 on 11-18 node routes. Dystopia2029: 119 wall-stuck events, mostly at KFPathnode_460 (24) and KFPathnode_392 (22). |
| R4 | **Steering aims at node centres.** The bot accelerates straight at `FollowNode.Location`. When its anchor is on the far side of a corner or pillar, the straight line runs into geometry. There is no corner cutting, no "passed the node" check and no clearance check against the edge's `CollisionRadius`. | `PathMove` label, `FollowGetNextNode` | Wall-hugging at trader doors; bots orbit a node they already passed. |
| R5 | **Goal is a moving pawn.** Each follower runs its own A* to `FollowLeaderPawn` and replans whenever the leader moves `FollowRepathDistance`. The leader's anchor may sit on a ledge the follower can't walk to, and the first hop changes on every replan. | `FollowBuildPath`, `FollowOnNodeMoveEnd` | 5 bots wall-stuck at a trader opening, all in follow mode. |
| R6 | **Blocking is global.** `TempBlockPath` sets `NavigationPoint.bBlocked`, which also blocks zeds and the other bots. | `EcholonBotBase.uc:1227`, `:1333-1484` | Side effects, so the follow code avoided blocking at all (R3). |
| R7 | **Spawn relocation skips floor checks.** Bots are placed 60-120 uu from a crate without testing floor or clearance, so their first anchor can be bad. | `EcholonMut` relocation | Stuck from second 0 near crates. |

The 2026-10-19 fix (walk-only planning, special-edge exclusion in `FollowFindWalkablePath`) was right and stays. It just covers only special edges, not ordinary edges a bot fails to walk.

---

## 2. The new system in one picture

One locomotion layer, `EcholonNav`, used by every state. Three parts, each with one job:

```
 state code (Follow, Hunt, Roam, Objective, Retreat)
        |  NavRequest(goal)          ^  NavStatus (Moving / Arrived / Blocked)
        v                            |
 +--------------+   route   +-----------------+   accel   +-----------------+
 |   Planner    | --------> |  Path follower  | --------> |  Stuck ladder   |
 | A* + edge    | <-------- |  lookahead +    | <-------- |  progress check |
 | memory       |  bad edge |  feelers        |  level up |  + recovery     |
 +--------------+           +-----------------+           +-----------------+
```

Raw `Pawn.Acceleration` stays (Bible W2: latent `MoveToward` interrupted by `GotoState` is a suspected native crash).

---

## 3. Planner

**3.1 Per-bot bad-edge memory (fixes R3, R6).**
- Table of `{ReachSpec, BadUntil, Strikes}`, max 32 rows, per bot, plus a copy shared by the squad (see 3.3).
- An edge gets a strike when the stuck ladder reaches level 2 on it. Penalty time is 20 s, doubled per strike, capped at 120 s. Rows expire on their own; nothing is permanent.
- During a search only: set `BlockedBy = Pawn` on every live bad edge, run `FindPathToward`/`FindPathTo`, then clear it. This is the same pattern `FollowFindWalkablePath` already uses for special edges, so zeds and other bots are never affected.
- If the search returns None with bad edges excluded, retry once with only the edges that have 2+ strikes excluded, then report Blocked.
- `TempBlockPath` and the `bBlocked` writes in `BuildPath*` are replaced by this table (doors keep their own `bBlocked` logic).
- No soft costs (checked in the SDK 2026-10-22). `NavigationPoint.TransientCost` (`NavigationPoint.uc:144`) is native-managed ("added right before a path finding attempt, cleared afterward") and nothing in script uses it, so a value set from script may be wiped before the search runs. `ExtraCost` and `FearCost` are global and would steer zeds too. `ReachSpec.BlockedBy` is the safe tool: a blocked spec costs `BLOCKEDPATHCOST` (`ReachSpec.uc:11`, `IsBlockedFor`), so a hard block set only around the bot's own search is the plan.

**3.2 Plan to a fixed point, not a moving pawn (fixes R5).**
- The squad leader drops **breadcrumbs**: each `NavigationPoint` it actually reaches (its `Anchor` while walking), kept in a ring of 16 on the mutator per squad.
- A follower's goal is the newest breadcrumb it can reach, then its formation slot point once in the same area. A breadcrumb is ground the leader really walked, so it is walkable and on the same floor.
- Replan only when the goal breadcrumb changes, the route is used up, or the stuck ladder asks for it. No more replans just because the leader moved 300 uu.

**3.3 Squad sharing.**
- Followers whose start is near the leader's breadcrumb trail reuse the trail as their route (no A*).
- A strike recorded by any squad member is copied to the squad table, so Bot_5 never tries node 651 after Bot_1 failed it.

**3.4 Start anchor check.**
- Before planning, if `Pawn.Anchor` isn't walk-reachable (`WalkReachable`), clear it and let the engine pick a new one. If none is reachable, recover to the last good node (ladder level 3).

---

## 4. Path follower (fixes R2, R4)

Runs every 0.1 s (the current `FollowMinLoopSleep` loop).

1. **Lookahead (string pulling).** Steer at the furthest of the next 3 route nodes that passes a walk test from the pawn: an extent trace with the pawn's cylinder at knee height, plus a floor trace at the midpoint and end so it doesn't cut over a drop. Open floor gives smooth diagonal lines; at a corner the test fails and the bot aims at the corner node.
2. **Pass-through arrival.** A node counts as reached when within `max(CollisionRadius, 48)` uu, or when the bot has moved past it along the segment (projection > 1.0) while the next node is walk-visible. Stops the orbiting.
3. **Wall feelers.** Two short traces at +-35 deg, length 1.5 x pawn radius. A hit adds a small side push away from the wall to the steering direction. The bot slides off before it touches, so `NotifyHitWall` becomes a fallback, not the main signal.
4. **Separation.** Squadmates within 80 uu add a gentle push apart (replaces most of the `Yield` state, which stops the bot for `FollowYieldHold`).
5. **Edge clearance.** Skip edges whose `CollisionRadius` is smaller than the pawn's (narrow gaps zeds fit through) when picking routes; treat them like special edges.
6. **No jumping while walking.** `DoJump` is removed from `Tick` and `NotifyHitWall`. The only jump left is an explicit, logged one in the ladder (level 1b), and only if a trace shows a low obstacle (under MaxStepHeight + 24 uu) with clear space above.

---

## 5. Stuck ladder (one for all states)

**Progress, not movement:** the check is "remaining route distance went down by at least 48 uu in the last 0.75 s". Sliding along a wall moves the bot but doesn't count as progress, so it is caught early.

| Level | Trigger | Action |
|---|---|---|
| 0 | Progress OK | Reset level. Remember the current node as the **last good node**. |
| 1 | 0.75 s no progress | Back off 64 uu (toward the previous node, or along the wall normal), then retry the same edge once. 1b: low-obstacle hop if the trace allows it. |
| 2 | Edge fails again | Strike the edge (bot + squad table) and replan without it. |
| 3 | No route, or 3 strikes in 10 s | Walk back to the last good node, clear the anchor, replan from there. |
| 4 | Level 3 failed twice | Report `Blocked` up to the state. The hub picks something else: hold where it is, take a different slot, or switch to fighting. |
| 5 (approved by user 2026-10-22, config on by default) | Blocked for 15 s and not seen by any human | Teleport to the last good node or the leader's newest breadcrumb. Many KF bot mods use this as the last safety net. |

Counters are per edge, not one global `FollowRetries`, so there is no reset-to-0 loop.

---

## 6. Spawn and relocation (fixes R7)

`EcholonMut` relocation tries up to 8 spots around the crate (ring at 80-160 uu). A spot is accepted only if:
- a floor trace from 32 uu above finds floor within 96 uu below,
- an extent trace with the human pawn cylinder is clear,
- the nearest `NavigationPoint` within 400 uu is walk-reachable from the spot.

If no spot passes, use the nearest crate-adjacent `PathNode` itself.

---

## 7. Telemetry (so playtests can measure it)

- `NAV_STUCK bot= level= edge=<start>-><end> cause= state=`
- `NAV_STRIKE bot= edge= strikes= until=`
- `NAV_RECOVER bot= level= ok=`
- End of wave: `NAV_SUMMARY` with the top 5 struck edges per map. Edges that show up every game can go into an optional per-map config list (`BadEdges`) that is always excluded.

---

## 8. Rollout (each step is a separate PR into `playtest`)

| Step | Change | Fixes | Size |
|---|---|---|---|
| N1 | Remove `DoJump` from `Tick`/`NotifyHitWall`; add the bad-edge table and ladder levels 1-2 to the follow mover. | R2, R3 (the 651/680 loop) | Small, biggest win |
| N2 | Lookahead, pass-through arrival, feelers, edge clearance in the follow mover. | R4 | Medium |
| N3 | Breadcrumb goals and squad-shared routes and strikes. | R5 | Medium |
| N4 | Relocation floor checks. | R7 | Small |
| N5 | Move `MoveToX`/`MoveTowardX` users onto `EcholonNav`; delete the old `Tick` move code and `TempBlockPath`. Ladder levels 3-5. | R1, R6 | Large |

N1 and N4 can be done in parallel.

**Test on each step:** KF-BurningParis and one tight map (KF-Outpost or KF-BioticsLab), 2 waves, 6 bots.
Pass criteria: no bot strikes the same edge more than twice per wave; no `DoJump` while walking (log it); `NAV_STUCK` level 2+ under 5 per bot per wave; no follower more than 10 s without progress outside combat.

---

## 9. Open questions for the user

1. ~~Allow the level 5 teleport fallback?~~ Decided 2026-10-22: allow it (only when no human can see the bot).
2. ~~Should hunting and objective moves also use breadcrumbs?~~ Decided 2026-10-22: yes for now. Hunting and objective moves plan to the newest reachable breadcrumb of the squad leader too (step N3), and can be split out later.
3. ~~Verify `TransientCost` semantics in the SDK.~~ Done 2026-10-22: not usable from script; use `BlockedBy` only (see 3.1).
