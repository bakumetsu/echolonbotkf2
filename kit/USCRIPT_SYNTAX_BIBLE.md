# USCRIPT SYNTAX BIBLE (v1, Milestone 0a)

This is the human reference. Models never get this file. They get `bible/BIBLE_CORE.md` (~1k tokens, always injected) plus whichever `bible/topics/*.md` files a task's `bible_topics` names (each under 600 tokens).

| Tier | File | Budget | Measured |
|---|---|---|---|
| Core | `bible/BIBLE_CORE.md` | ≤1800 tok | ~1050 |
| Topic | `bible/topics/{states,arrays,iterators,strings,timers,sdk}.md` | ≤600 tok each | 290-380 |

Token counts use the D4 estimator (chars / 3.5); `kit/tests/test_bible.py` enforces them.

## [VERIFY] items, resolved against the corpus

| Spec item | Verdict | Evidence |
|---|---|---|
| U006: does `FollowExitState = "PickNextMove"` compile? | Yes, in defaultproperties a name var accepts a quoted string. In code, name params need `'Name'`, so U006 stays ERROR for code and is never applied inside defaultproperties. | Nav:1497. The corpus has no string arguments to GotoState/IsInState/SetTimer/ClearTimer. |
| U007: semicolon convention in defaultproperties | No semicolons: 74 of 75 corpus lines. The single exception is Nav:1543 `FollowEscapeDuration = 0.8;`. Since both forms compile, this is a WARN. | `kit/reports/validator_selftest.md` |
| U008: "no ternary" | **Spec correction: ternary compiles in KF2.** The corpus uses `?:` 16 times (for example Base:2312 and Base:2819). It remains banned as house style, but as a WARN, so the legacy self-test stays at 0 ERRORs. | Base x7 (e.g. 1185, 2312, 2599, 2819, 2836), Logic x5, Bot x4 |
| U008: `null` / `.Count` / nested arrays / C casts | None appear in the corpus, so these stay ERROR. | corpus self-test |
| Iterator forms | All confirmed in the corpus, with counts listed in `topics/iterators.md`. Doc 1.1 writes `VisibleCollidingActors(Class, Arr, Radius)`, but the second argument is one out variable, not an array. | Logic:605, Base:794, Mut:681 |
| U005: GotoState + Stop | Confirmed as the legacy convention. | Nav:1290-1296 |
| `None` vs `none` | UnrealScript is case-insensitive, and the corpus uses both. Write `None`. | Base:1185 |

## Spec findings from building M0a (no decision needed, recorded here)

1. **The legacy code is partly decompiler output.** Base, Logic, Bot and the inventory manager contain 31 `J0x..:` labels with `goto` loops, `// End:0x..` comments and floats like `1.0000000`. The new rule N13 bans that style, and validator U014 (an extension to the spec) warns on it.
2. **The doc's 943 count depends on its old extractor.** It counted 27 struct members as class vars and missed all 22 `var()` editor vars in Mut. The new indexer counts 938 real top-level symbols. Adjusting for those two documented quirks gives exactly 943, with 0 unexplained differences. All 375 line ranges in Part 0.3 match the source exactly.
3. **The legacy files mix line endings.** Nav is LF only and the other four are CRLF; Mut has no final newline (3036 `\n`, 3037 lines). Every tool reads files with .NET `ReadAllLines` semantics, so line numbers match the doc.
4. **`bFollowExitPending` has a clear single-writer split.** Nav clears it (FollowResetEpisode Nav:254, FollowingLeader EndState Nav:1308, FollowingLeaderBasic Nav:1440), and the hub sets it (FollowNotifyHub Base:1309, FollowCheckExit Logic:849/865). This goes into `single_writer.json` in M0b.
5. **`GetActiveBoss` is a stub in both Mut (Mut:2808) and Base (Base:2476),** and both return None. D5 drops both.

## KF2 workarounds (status + citation)

| # | Rule | Status | Citation |
|---|---|---|---|
| W1 | The follow-nav base extends AIController, never KFAIController | DESIGN DECISION; rationale unverified; never re-parent (validator U012 = ERROR) | doc A4, D3; SDK KFAIController.uc:984, 1016 |
| W2 | DirectMove uses `Pawn.Acceleration`, not MoveToward | SUSPECTED native crash when a combat GotoState interrupts a latent move | doc C7, @SYS-NAV-STATE; Nav:1264-1269; header rules Nav:19-27 are STALE |
| W3 | SetCharacterArch after SetTeam | Documented in a code comment; SDK-unverified | doc C8, D5; Mut:2512, 2515-2518, 2522; SDK Pawn.uc:1436 |
| W4 | WaitForLanding / MoveTo get an external ~2 s deadline timer | WaitForLanding has no SDK timeout; MoveTo = precaution | @SYS-BOT-HEAL; Bot:440, 476, 882; SDK Controller.uc:1344 |
| W5 | Hub funnel: PickCombatStyle returns early while a follower state is active; follower states never GotoState('PickNextMove') | Doc rule | doc 6.4 @SYS-P6-BOUNDARY |

## Legacy-bug policy (D5)

| Doc item | What it is | Policy | Validator |
|---|---|---|---|
| C3 | Stale defaults comment (NumBots 6 vs 7) | FIX: correct comment, keep value 7 | - |
| C4 | FindNearestNavPoint / FindNearestChokepoint return the first hit | FIX, tagged `BEHAVIOR-CHANGE`: real nearest by distance | - |
| C5 | CaptainPathTimer / CaptainPathLoop are log-only | DROP (and their timers at Base:448, 3073, 3219) | U013 |
| C6 | ShouldNadeEnemies `BestScore` uninitialised | FIX: explicit `BestScore = 0.0;` (no behavior change) | - |
| C9 | FollowMaxBlocksPerEpisode / FollowNextBlockTime / FollowBlockMinGap are dead config | DROP | U013 |
| A5 | PHASE_SHOPPING const, never read | DROP | U013 |
| - | RebuildHierarchy stub + its timer (Mut:266), GetActiveBoss stubs (Mut, Base) | DROP | U013 |
| D1 | GrenadeTarget state has no entry site | PORT as a thin state flagged `UNVERIFIED-ENTRY`; prune at the M6 gate | - |
| D2 | GetItem state, only an IsInState check | PORT as a thin state flagged `UNVERIFIED-ENTRY`; prune at the M6 gate | - |

## Validator rule table

| Rule | Severity | Checks |
|---|---|---|
| U001 | ERROR | `local` after a statement |
| U002 | ERROR | initializer on `local`/`var` (metadata `<...>` excluded) |
| U003 | ERROR | latent call outside state label code |
| U004 | ERROR | `return` in label code (state functions exempt) |
| U005 | WARN | GotoState in label code not followed by Stop/goto/latent/end |
| U006 | ERROR | string literal where a name API expects 'Name' (code only) |
| U007 | WARN | semicolon in defaultproperties |
| U008 | ERROR / WARN | `null`, `.Count/.Size/.Push/.Contains`, nested arrays, C casts = ERROR; ternary = WARN |
| U009 | ERROR | GotoState/IsInState/timer/goto targets must exist (symbols ∪ contracts ∪ sdk_seed) |
| U010 | WARN | unknown SDK member: **deferred to M0b** (needs sdk_index.py) |
| U011 | WARN | Remove/RemoveItem inside a forward `for` over `.Length` with no decrement |
| U012 | ERROR | file name = class name; parent matches class_chain.json; follow-nav never KFAIController |
| U013 | WARN | reference to a D5-dropped symbol |
| U014 | WARN | decompiler artifacts (extension) |
