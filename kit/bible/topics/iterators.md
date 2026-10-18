# Topic: iterators (foreach)

Corpus-confirmed forms (counts from the legacy files):
- `foreach WorldInfo.AllPawns(class'KFPawn_Monster', P, Pawn.Location, Radius)` (13 uses; Base:794).
  Args: class, out Pawn, optional location, optional radius. SDK: WorldInfo.uc:1663.
- `foreach WorldInfo.AllControllers(class'KF2Bot', B)` (9 uses).
- `foreach VisibleCollidingActors(class'KFPawn_Monster', M, 800.0, Pawn.Location)` (Logic:605).
  Args: class, out Actor, radius, optional location, optional bIgnoreHidden. Called on an Actor
  (here the controller). SDK: Actor.uc:2365. Note: doc 1.1 writes `(Class, Arr, Radius)`; the
  2nd arg is a single out variable, not an array.
- `foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', N, Loc, Radius)` (Mut:681).
  Order is not by distance: track the best distance yourself (legacy C4 bug returned first hit).
- `foreach KFInvManager.InventoryActors(class'KFWeapon', W)` (4 uses).
- `foreach Pawn.TraceActors(...)` (1 use).
- `foreach DynamicActors(...)` / `AllActors(...)`: valid UE3 but unused in the corpus; avoid in
  per-tick code (cost).
Rules: the out variable must be a declared `local` of a compatible class; never `break` out of a
nested foreach and then use the variable without a `!= None` check; never GotoState inside a
foreach.
