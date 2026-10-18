# Topic: SDK facts the mod relies on

Verified in the doc's Part 1.1 (cite as SDK path:line):
- Latent: `MoveTo` Controller.uc:1193, `MoveToward` Controller.uc:1220, `WaitForLanding`
  Controller.uc:1344. Only in state code of Controller subclasses.
- `SetTimer` Actor.uc:2036; `VisibleCollidingActors` Actor.uc:2365; `RadiusNavigationPoints`
  WorldInfo.uc:1636; `AllPawns` WorldInfo.uc:1663; `SetCharacterArch` KFPawn.uc:1260.
- `NotifyTeamChanged` Pawn.uc:1436 is declared only (native); its archetype reset is UNVERIFIED (D5).
- `KFMutator` is absent from the local SDK tree: its behaviour is UNVERIFIED (doc D4).
- `KFAIController` blocked-reach API (KFAIController.uc:984, 1016) is unreachable by design (W1).
Rules:
- Before calling an SDK member, confirm it with `context_slicer.py sdk Class.Member` (M0b index).
  If not found, say so in a comment `// SDK-UNVERIFIED` rather than guessing a signature.
- Casting SDK objects: `KFPawn_Human(P)`, `KFWeapon(Pawn.Weapon)`; always check `!= None`.
- `WorldInfo.GetGameInfo()` then `KFGameInfo_Survival(...)` is the corpus way to reach the game.
