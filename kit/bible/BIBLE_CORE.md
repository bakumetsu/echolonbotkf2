# UnrealScript core rules (KF2 / UE3). Follow every rule. Output ONE ```unrealscript block.

## NEVER
N1 `local` after any statement. All locals first. `A=1; local int B;` -> `local int A,B; A=1;`
N2 Initializers. `local int N=5;` / `var int N=5;` -> declare, then `N=5;` (var: defaultproperties).
N3 Latent calls (Sleep, MoveTo, MoveToward, FinishRotation, FinishAnim, WaitForLanding,
   MoveToDirectNonPathPos) outside state label code. `function F(){Sleep(1);}` -> put in `Begin:` code.
N4 `return` in label code. -> `Stop;` (functions declared inside a state MAY return).
N5 `null`, `?:` ternary, C casts. `(int)F` -> `int(F)`; `X==null` -> `X==None`; ternary -> if/else.
N6 `.Count .Size .Push .Contains` on arrays. -> `.Length`, `AddItem(x)`, `Find(x) >= 0`.
N7 Nested arrays `array<array<int>>`. -> `struct FRow{var array<int> V;}; var array<FRow> Rows;`
N8 Remove from an array while looping forward. -> loop `for(i=A.Length-1;i>=0;i--)`.
N9 Strings where a name is expected. `GotoState("Idle")` -> `GotoState('Idle')`.
N10 Invent states, labels, timers or functions. Every `'Name'` in GotoState/IsInState/SetTimer/
   ClearTimer/IsTimerActive must exist in the contract. If unsure, ask; do not guess.
N11 Re-parent the follow-nav class to KFAIController (W1). Never port dropped symbols (D5).
N12 Semicolons in defaultproperties. `Speed=1.0;` -> `Speed=1.0`.
N13 Copy decompiler style from legacy: `J0x17:` labels + `goto` loops, `// End:0x..` comments,
   `1.0000000` floats. -> write `for`/`while` loops and plain literals.

## ALWAYS
A1 Grammar: `function T Name(T A, optional T B, out T C) { locals; statements }`; `if(..){..}`
   `else`; `for(i=0;i<N;i++)`; `while(..)`; `switch(x){case 1: ...; break; default: ...}`.
A2 `None`, `true/false`, names `'Foo'`, strings `"foo"`, concat `$` (no space) / `@` (space).
A3 Casts are function style: `KFPawn(P)`, `int(F)`, `string(N)`, `name(S)`; check `!= None` after.
A4 Dynamic arrays: `.Length`, `AddItem`, `RemoveItem`, `Remove(i,n)`, `Insert(i,n)`, `Find(x)`.
   `byte` wraps at 255 (NumBots is a byte): compare as int, clamp before `--`/`++`.
A5 States: `state X extends Y { ignores E1, E2; event BeginState(Name Prev){} event EndState(Name Next){}
   Begin: ...latent code... }`. Inside a state, `global.F()` calls the class's non-state F.
   Use `super.F()` only in class-level functions (in-state super semantics: UNVERIFIED).
A6 Leaving label code: always `GotoState('X'); Stop;` (legacy convention, Nav:1293-1296).
A7 Iterators: `foreach WorldInfo.AllPawns(class'KFPawn_Monster', P, Loc, R)`;
   `foreach VisibleCollidingActors(class'KFPawn_Monster', M, R, Loc)`;
   `foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', N, Loc, R)`. 2nd arg is ONE
   out variable, not an array. RadiusNavigationPoints yields in no distance order.
A8 Timers: `SetTimer(Rate, bLoop, 'FuncName')`, `ClearTimer('FuncName')`; target must be a function.

## KF2 workarounds
W1 Follow-nav base extends AIController, never KFAIController. [DESIGN DECISION; rationale
   unverified] doc A4/D3.
W2 DirectMove steers with `Pawn.Acceleration`, not MoveToward. [SUSPECTED native crash when combat
   GotoState interrupts a latent move] doc C7, @SYS-NAV-STATE. Nav header rules Nav:19-27 are STALE.
W3 Call SetCharacterArch AFTER SetTeam. [Code comment Mut:2515-2518; SDK-unverified] doc C8/D5.
W4 WaitForLanding/MoveTo get an external deadline (bounded ~2s timer). [WaitForLanding: no SDK
   timeout, @SYS-BOT-HEAL; MoveTo: precaution].
W5 Hub funnel: PickCombatStyle returns early while a follower state is active; follower states never
   GotoState('PickNextMove') themselves. [Doc 6.4, @SYS-P6-BOUNDARY]
